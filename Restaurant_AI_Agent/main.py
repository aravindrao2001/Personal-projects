from __future__ import annotations

import os
import asyncio
from typing import Dict, List

from fastapi import FastAPI, Request, BackgroundTasks
from fastapi.responses import PlainTextResponse
import uvicorn

# Optional tracing (Langfuse) and Agent SDK
from langfuse import Langfuse, get_client
from agents import Agent, Runner, trace

from prompts import main_agent_prompt
from tools import (
    # user branch context helpers (impls)
    _get_user_branch_impl,
    _save_user_branch_impl,
    _clear_user_branch_impl,
    # branch + menu impls
    _get_all_branches_impl,
    _get_full_menu_items_impl,
    _search_menu_by_branch_impl,
    _search_menu_item_by_branch_impl,
    _get_item_info_impl,
    _get_branch_info_impl,
    _get_branch_coords_impl,
    # WA senders (impls)
    _send_whatsapp_message_impl,
    _send_whatsapp_image_impl,
    _send_whatsapp_interactive_list_impl,
    _send_whatsapp_location_impl,
    _send_whatsapp_location_request_impl,
    # helpers
    build_branch_text_options,
    resolve_branch_from_reply,
    haversine_km,
    # decorated tool wrappers (for Agent SDK; LLM may call them)
    get_all_branches,
    get_full_menu_items,
    search_menu_by_branch,
    search_menu_item_by_branch,
    get_item_info,
    get_branch_info,
    send_whatsapp_message,
    send_whatsapp_image,
    send_whatsapp_interactive_list,
    send_whatsapp_location,
    send_whatsapp_location_request,
    get_user_branch,
    save_user_branch,
    clear_user_branch,
)

APP_NAME = "Grubginie WhatsApp Agent"
VERIFY_TOKEN = os.getenv("VERIFY_TOKEN", "Grub")
MAX_TURNS = 12  # keep short histories to reduce latency
user_histories: Dict[str, List[Dict[str, str]]] = {}

app = FastAPI(title=APP_NAME)


# -------------------- optional tracing --------------------
def initialize_langfuse():
    pk = os.getenv("LANGFUSE_PUBLIC_KEY")
    sk = os.getenv("LANGFUSE_SECRET_KEY")
    host = os.getenv("LANGFUSE_HOST", "https://cloud.langfuse.com")
    if not pk or not sk:
        print("ℹ️ Langfuse not configured; starting without tracing.")
        return
    Langfuse(secret_key=sk, public_key=pk, host=host)
    client = get_client()
    print("✅ Langfuse authenticated." if client.auth_check() else "❌ Langfuse auth failed.")


def cap_history(user: str) -> None:
    hist = user_histories.get(user, [])
    if len(hist) > 2 * MAX_TURNS:
        user_histories[user] = hist[-2 * MAX_TURNS :]


def looks_like_category(q: str) -> bool:
    ql = q.lower()
    keys = [
        "veg", "vegetarian", "vegan",
        "beverage", "drinks", "drink", "juice", "shake",
        "starter", "starters", "appetizer",
        "dessert", "sweet",
        "biryani", "rice", "noodles",
        "pizza", "burger", "wrap", "sandwich",
        "spicy", "mild",
    ]
    return any(k in ql for k in keys)


async def send_menu_picker_textlist(to_number: str, branch_id: str, user_query: str) -> None:
    """
    Build and send a 10-row interactive menu list based on query (title=name, description=price).
    """
    res = await _search_menu_by_branch_impl(branch_id, user_query)
    items = (res or {}).get("items", [])[:10]
    if not items:
        await _send_whatsapp_message_impl(to_number, "Sorry, I couldn't find matching items. Try another query?")
        return

    rows = []
    for it in items:
        iid = it.get("_id")
        title = (it.get("item_name") or "Item")[:24]
        price = it.get("price")
        rows.append({
            "id": f"item:{iid}",
            "title": title,
            "description": f"₹{price}" if price else "",
        })

    payload = {
        "type": "list",
        "header": {"type": "text", "text": "Top matches"},
        "body": {"text": "Pick an item to see details"},
        "footer": {"text": "Powered by Buckle Consult"},
        "action": {"button": "View", "sections": [{"title": "Menu", "rows": rows}]},
    }
    await _send_whatsapp_interactive_list_impl(to_number, payload)


# -------------------- WhatsApp webhook verification --------------------
@app.get("/webhook")
async def verify(request: Request):
    params = dict(request.query_params)
    if (
        params.get("hub.mode") == "subscribe"
        and params.get("hub.verify_token") == VERIFY_TOKEN
        and "hub.challenge" in params
    ):
        return PlainTextResponse(params["hub.challenge"])
    return PlainTextResponse("Verification failed", status_code=403)


# -------------------- WhatsApp webhook POST --------------------
@app.post("/webhook")
async def whatsapp_webhook(request: Request, background_tasks: BackgroundTasks):
    body = await request.json()
    try:
        entry = body.get("entry", [])
        if not entry:
            return {"status": "ignored"}
        changes = entry[0].get("changes", [])
        if not changes:
            return {"status": "ignored"}
        value = changes[0].get("value", {})
        messages = value.get("messages", [])
        if not messages:
            return {"status": "ignored"}

        background_tasks.add_task(process_whatsapp_event, value)
        return {"status": "ok"}
    except Exception as e:
        print(f"[❌ Webhook error] {e}")
        return {"status": "error", "message": str(e)}


# -------------------- core event processor --------------------
async def process_whatsapp_event(value: dict):
    try:
        msg = value["messages"][0]
        user_number = msg.get("from", "").strip()
        if not user_number:
            return

        # 1) user shared a location → compute distance immediately
        if msg.get("type") == "location":
            user_lat = msg["location"]["latitude"]
            user_lng = msg["location"]["longitude"]
            ctx = await _get_user_branch_impl(user_number)
            if not ctx or "id" not in ctx:
                # ask them to pick a branch (text list)
                text = await build_branch_text_options(user_number)
                await _send_whatsapp_message_impl(user_number, text)
                return
            branch_id = ctx["id"]
            b_lat, b_lng = await _get_branch_coords_impl(branch_id)
            km = haversine_km(b_lat, b_lng, user_lat, user_lng)
            await _send_whatsapp_message_impl(
                user_number, f"You're ~{km:.1f} km from {ctx.get('name','the branch')}."
            )
            return

        # 2) interactive reply (menu item selection)
        if msg.get("type") == "interactive":
            reply = msg.get("interactive", {}).get("list_reply", {}) or {}
            selection = reply.get("id", "")
            if not selection:
                return

            if selection.startswith("item:"):
                item_id = selection.split("item:", 1)[1]
                ctx = await _get_user_branch_impl(user_number)
                if not ctx or "id" not in ctx:
                    text = await build_branch_text_options(user_number)
                    await _send_whatsapp_message_impl(user_number, text)
                    return
                branch_id = ctx["id"]
                item = await _get_item_info_impl(branch_id, item_id)
                if not item:
                    await _send_whatsapp_message_impl(user_number, "Couldn't find that dish. Try another name?")
                    return
                caption = f"{item['item_name']} — ₹{item.get('price')}\n{item.get('desc','')}"
                await _send_whatsapp_image_impl(user_number, item.get("img"), caption)
                return

            return  # ignore unknown interactive ids

        # 3) plain text
        if msg.get("type") == "text":
            user_input = (msg.get("text", {}) or {}).get("body", "").strip()
            if not user_input:
                return

            # if no branch context, try to resolve from this message
            ctx = await _get_user_branch_impl(user_number)
            if not ctx or "id" not in ctx:
                chosen = await resolve_branch_from_reply(user_number, user_input)
                if chosen:
                    res = await _save_user_branch_impl(user_number, chosen)
                    if isinstance(res, dict) and res.get("ok"):
                        await _send_whatsapp_message_impl(
                            user_number,
                            f"Branch set to {res.get('branch_name','selected branch')}. What would you like?"
                        )
                    else:
                        await _send_whatsapp_message_impl(user_number, "Couldn't set the branch right now.")
                    return
                text = await build_branch_text_options(user_number)
                await _send_whatsapp_message_impl(user_number, text)
                return

            branch_id = ctx["id"]

            # category-like request? → interactive menu list (up to 10)
            if looks_like_category(user_input):
                await send_menu_picker_textlist(user_number, branch_id, user_input)
                return

            # looks like a dish name? → deterministic lookup + image
            item = await _search_menu_item_by_branch_impl(query=user_input, branch_id=branch_id)
            if item:
                caption = f"{item['item_name']} — ₹{item.get('price')}\n{item.get('desc','')}"
                await _send_whatsapp_image_impl(user_number, item.get("img"), caption)
                return

            # explicit location intent
            if any(k in user_input.lower() for k in ["location", "where", "near", "address", "map"]):
                b = await _get_branch_info_impl(branch_id)
                b_name = (b.get("branchName") or b.get("name") or "Branch").strip() if b else "Branch"
                lat, lng = await _get_branch_coords_impl(branch_id)
                await _send_whatsapp_location_impl(user_number, lat, lng, name=b_name)
                await _send_whatsapp_location_request_impl(user_number, "Share your location for distance")
                return

            # fallback → small talk via Agent (no tool use here)
            hist = user_histories.get(user_number, [])
            cap_history(user_number)
            formatted_history = "\n".join(f"{m['role']}: {m['content']}" for m in hist)
            agent_input = f"{formatted_history}\nuser: {user_input}"

            agent = Agent(
                name="GrubGenie Agent",
                model="gpt-4.1",
                instructions=main_agent_prompt(),
                reset_tool_choice=True,
                tools=[
                    # expose the tool wrappers in case LLM wants them
                    get_all_branches,
                    get_full_menu_items,
                    search_menu_by_branch,
                    search_menu_item_by_branch,
                    get_item_info,
                    get_branch_info,
                    get_branch_coords,
                    send_whatsapp_message,
                    send_whatsapp_image,
                    send_whatsapp_interactive_list,
                    send_whatsapp_location,
                    send_whatsapp_location_request,
                    get_user_branch,
                    save_user_branch,
                    clear_user_branch,
                ],
            )

            thread_id = f"whatsapp-{user_number}"
            with trace(workflow_name="Grubgenie", group_id=thread_id):
                try:
                    response = await asyncio.wait_for(Runner.run(agent, agent_input), timeout=6.0)
                except asyncio.TimeoutError:
                    response = "Hey! I’m here—tell me what you’d like to order, or ask for veg/beverages/etc."

            user_histories.setdefault(user_number, []).append({"role": "user", "content": user_input})
            user_histories[user_number].append({"role": "assistant", "content": response})
            await _send_whatsapp_message_impl(user_number, response)
            return

        return  # ignore other types

    except Exception as e:
        print(f"[❌ Background Task Error] {e}")


@app.get("/health")
async def health():
    return {"ok": True, "service": APP_NAME}


if __name__ == "__main__":
    initialize_langfuse()
    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", "8000")), reload=False)

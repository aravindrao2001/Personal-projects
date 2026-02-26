import os
import re
import math
import asyncio
from typing import Any, Dict, List, Optional, Tuple

import orjson
import httpx
import redis.asyncio as redis
from rapidfuzz import process, fuzz
from agents import function_tool

# ============================== CONFIG ==============================
API_VERSION       = os.getenv("WA_API_VERSION", "v22.0")
PHONE_NUMBER_ID   = os.getenv("WA_PHONE_NUMBER_ID", "338922035981221")
ACCESS_TOKEN      = os.getenv("WA_ACCESS_TOKEN", "EAA4Gus7lelwBPMUwmvhZBIeOk4oY6xWCGKnEpGzuC6eZClDAZBTNFQ1MGdBhzEeANnZAGecUJjGDAyqJywQmuyyjwxZCeZB4oEI739q5yBsasGUngL5NHxlscTBOErC4vzduVCyZBXqQHUWIIg9duKFsCrcxqUf5ZAzTCw0eZBZAl9kO27NrrVPpFhDs2brYak97VQNru2Kys6eFbsdNeJqH5u4hZCGDqFqBVWNpZABE7BRe1AZDZD")
PARTNER_ID        = os.getenv("GRUB_PARTNER_ID", "670f59dfcbbf43c36226b42c")
GRUB_BASE         = os.getenv("GRUB_BASE", "https://dev-backend.grubgenie.ai/v1/agents")
REDIS_URL         = os.getenv("REDIS_URL", "redis://localhost:6379/0")
CACHE_TTL_SECONDS = int(os.getenv("CACHE_TTL_SECONDS", str(24 * 3600)))  # 24h

BRANCHES_URL = f"{GRUB_BASE}/partner/{PARTNER_ID}"
MENU_URL     = f"{GRUB_BASE}/menu?partnerId={PARTNER_ID}&branchId={{branch_id}}"

WA_BASE    = f"https://graph.facebook.com/{API_VERSION}/{PHONE_NUMBER_ID}/messages"
WA_HEADERS = {
    "Authorization": f"Bearer {ACCESS_TOKEN}",
    "Content-Type": "application/json",
}

# ============================== SHARED CLIENTS ==============================
_http_client: Optional[httpx.AsyncClient] = None
async def get_client() -> httpx.AsyncClient:
    global _http_client
    if _http_client is None:
        _http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(8.0, connect=4.0),
            limits=httpx.Limits(max_connections=200, max_keepalive_connections=50),
            http2=False,
        )
    return _http_client

r = redis.from_url(REDIS_URL, decode_responses=False)  # store bytes (faster)

def dumps(o: Any) -> bytes:
    return orjson.dumps(o)

def loads(b: Optional[bytes]) -> Any:
    return orjson.loads(b) if b else None

async def set_json(key: bytes, value: Any, ex: Optional[int] = None):
    await r.set(key, dumps(value), ex=ex)

async def get_json(key: bytes) -> Any:
    return loads(await r.get(key))

# ============================== KEYS ==============================
K_BRANCHES       = b"grub:branches"
K_BRANCHES_TS    = b"grub:branches:ts"
K_BRANCH_MAP     = b"grub:branch_map"            # hash name_lower -> id
K_BRANCH_DETAIL  = b"grub:branch:%s"
K_MENU           = b"grub:menu:%s"
K_MENU_TS        = b"grub:menu:%s:ts"
K_USER_BRANCH    = b"user:branch:%s"             # {"id","name"}

BRANCH_CHOICES_KEY = b"user:branch_choices:%s"   # for text-only numbered list

# ============================== HTTP helpers ==============================
async def _http_get_json(url: str) -> Any:
    client = await get_client()
    resp = await client.get(url)
    resp.raise_for_status()
    data = resp.json()
    return data.get("result", data)

# ============================== Normalizers ==============================
def _normalize_menu(items: List[Dict]) -> List[Dict]:
    out = []
    for it in items:
        out.append({
            "_id": it.get("_id") or it.get("id"),
            "item_name": it.get("item_name"),
            "price": (it.get("dPrice") or 0) or (it.get("oPrice") or 0),
            "img": (it.get("image") or {}).get("url"),
            "desc": (it.get("description") or "")[:240],
            "cat": ((it.get("foodCategory") or {}).get("food_category") or ""),
            "type": ((it.get("foodType") or {}).get("food_type") or ""),
            "tags": " ".join(sum([t.get("items", []) for t in (it.get("tags") or [])], [])),
        })
    return out

# ============================== BRANCH IMPLS ==============================
async def _get_all_branches_impl() -> Dict:
    import time
    ts = await r.get(K_BRANCHES_TS)
    if ts and (time.time() - int(ts) < CACHE_TTL_SECONDS):
        cached = await get_json(K_BRANCHES)
        if cached:
            return {"branches": cached}

    # refresh
    data = await _http_get_json(BRANCHES_URL)
    branches = data.get("branches") if isinstance(data, dict) else data
    if not isinstance(branches, list):
        branches = []

    pipe = r.pipeline()
    pipe.set(K_BRANCHES, dumps(branches))
    pipe.set(K_BRANCHES_TS, str(int(time.time())).encode())
    pipe.delete(K_BRANCH_MAP)
    for b in branches:
        bid = b.get("branchId") or b.get("_id") or b.get("id")
        name = (b.get("branchName") or b.get("name") or b.get("title") or "").strip()
        if not bid:
            continue
        pipe.set(K_BRANCH_DETAIL % str(bid).encode(), dumps(b))
        if name:
            pipe.hset(K_BRANCH_MAP, name.lower().encode(), str(bid).encode())
    await pipe.execute()
    return {"branches": branches}

async def _get_branch_info_impl(branch_id: str) -> Optional[Dict]:
    b = await get_json(K_BRANCH_DETAIL % str(branch_id).encode())
    if b:
        return b
    await _get_all_branches_impl()
    return await get_json(K_BRANCH_DETAIL % str(branch_id).encode())

# ============================== USER BRANCH CONTEXT ==============================
async def _save_user_branch_impl(phone_number: str, branch_id: str) -> Dict:
    b = await _get_branch_info_impl(branch_id)
    if not b:
        return {"error": "branch not found"}
    name = (b.get("branchName") or b.get("name") or "Branch").strip()
    await set_json(K_USER_BRANCH % phone_number.encode(), {"id": branch_id, "name": name}, ex=CACHE_TTL_SECONDS)
    asyncio.create_task(_get_full_menu_items_impl(branch_id))  # warm menu
    return {"ok": True, "branch_name": name}

async def _get_user_branch_impl(phone_number: str) -> Optional[Dict]:
    return await get_json(K_USER_BRANCH % phone_number.encode())

async def _clear_user_branch_impl(phone_number: str) -> Dict:
    await r.delete(K_USER_BRANCH % phone_number.encode())
    return {"ok": True}

# ============================== MENU IMPLS ==============================
async def _get_full_menu_items_impl(branch_id: str) -> List[Dict]:
    import time
    key = K_MENU % str(branch_id).encode()
    ts_key = K_MENU_TS % str(branch_id).encode()
    ts = await r.get(ts_key)
    if ts and (time.time() - int(ts) < CACHE_TTL_SECONDS):
        cached = await get_json(key)
        if cached:
            return cached

    data = await _http_get_json(MENU_URL.format(branch_id=branch_id))
    items = data if isinstance(data, list) else data.get("result") or []
    min_items = _normalize_menu(items)

    pipe = r.pipeline()
    pipe.set(key, dumps(min_items))
    pipe.set(ts_key, str(int(time.time())).encode())
    await pipe.execute()
    return min_items

def _score_item(q: str, it: Dict) -> float:
    q = q.lower().strip()
    fields = " ".join([
        it.get("item_name") or "",
        it.get("desc") or "",
        it.get("cat") or "",
        it.get("type") or "",
        it.get("tags") or "",
    ]).lower()
    score = 0.0
    for t in q.split():
        if t in fields:
            score += 2.0
    score += fuzz.partial_ratio(q, (it.get("item_name") or "").lower()) / 20.0
    return score

async def _search_menu_by_branch_impl(branch_id: str, user_input: str) -> Dict:
    items = await _get_full_menu_items_impl(branch_id)
    scored = sorted(items, key=lambda it: _score_item(user_input, it), reverse=True)[:10]
    pairs = [f"{it['item_name']} - ₹{it['price']}" for it in scored if it.get("item_name")]
    return {"top": pairs, "items": scored}

async def _search_menu_item_by_branch_impl(query: str, branch_id: str) -> Optional[Dict]:
    items = await _get_full_menu_items_impl(branch_id)
    names = [it.get("item_name","") for it in items]
    if names:
        match = process.extractOne(query, names, scorer=fuzz.WRatio)
        if match and match[1] >= 70:
            return items[match[2]]
    # fallback flattened search
    flattened = [
        " ".join([it.get("item_name",""), it.get("desc",""), it.get("cat",""), it.get("type",""), it.get("tags","")]).lower()
        for it in items
    ]
    if flattened:
        fm = process.extractOne(query.lower(), flattened, scorer=fuzz.WRatio)
        if fm and fm[1] >= 70 and fm[2] is not None:
            return items[fm[2]]
    return None

async def _get_item_info_impl(branch_id: str, query_or_id: str) -> Optional[Dict]:
    items = await _get_full_menu_items_impl(branch_id)
    for it in items:
        if it.get("_id") == query_or_id:
            return it
    return await _search_menu_item_by_branch_impl(query_or_id, branch_id)

# ============================== WA SENDERS (IMPLS) ==============================
async def _wa_post(payload: Dict) -> Dict:
    client = await get_client()
    resp = await client.post(WA_BASE, headers=WA_HEADERS, json=payload)
    data = {}
    try:
        data = resp.json()
    except Exception:
        data = {"_raw": await resp.aread()}
    if resp.is_error:
        raise RuntimeError(f"WA send failed {resp.status_code}: {data}")
    return data

async def _send_whatsapp_message_impl(USER_PHONE_NUMBER: str, text: str, preview_url: bool = False) -> Dict:
    data = {
        "messaging_product": "whatsapp",
        "to": USER_PHONE_NUMBER,
        "type": "text",
        "text": {"preview_url": bool(preview_url), "body": text},
    }
    return await _wa_post(data)

async def _send_whatsapp_image_impl(to: str, media_url: str, caption: Optional[str] = None) -> Dict:
    image = {"link": media_url}
    if caption:
        image["caption"] = caption
    data = {
        "messaging_product": "whatsapp",
        "to": to,
        "type": "image",
        "image": image,
    }
    return await _wa_post(data)

async def _send_whatsapp_interactive_list_impl(to: str, interactive_payload: Dict) -> Dict:
    data = {
        "messaging_product": "whatsapp",
        "to": to,
        "type": "interactive",
        "interactive": interactive_payload,
    }
    return await _wa_post(data)

async def _send_whatsapp_location_impl(to: str, latitude: float, longitude: float, name: Optional[str] = None, address: Optional[str] = None) -> Dict:
    loc = {"latitude": float(latitude), "longitude": float(longitude)}
    if name: loc["name"] = name
    if address: loc["address"] = address
    data = {
        "messaging_product": "whatsapp",
        "to": to,
        "type": "location",
        "location": loc,
    }
    return await _wa_post(data)

async def _send_whatsapp_location_request_impl(to: str, body_text: str = "Please share your location") -> Dict:
    data = {
        "messaging_product": "whatsapp",
        "to": to,
        "type": "interactive",
        "interactive": {
            "type": "location_request_message",
            "body": {"text": body_text},
            "action": {"name": "send_location"},
        },
    }
    return await _wa_post(data)

# ============================== LOCATION HELPERS ==============================
def _extract_lat_lng_from_gmaps(url: str) -> Tuple[Optional[float], Optional[float]]:
    m = re.search(r"/@(-?\d+\.\d+),(-?\d+\.\d+)", url)
    if m:
        return float(m.group(1)), float(m.group(2))
    m = re.search(r"[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)", url)
    if m:
        return float(m.group(1)), float(m.group(2))
    return None, None

async def _get_branch_coords_impl(branch_id: str) -> Tuple[float, float]:
    b = await _get_branch_info_impl(branch_id)
    if not b:
        raise ValueError("branch not found")
    maps = b.get("googleMap") or b.get("googleMaps") or b.get("maps") or ""
    lat, lng = _extract_lat_lng_from_gmaps(maps)
    if lat is None or lng is None:
        lat = b.get("lat") or b.get("latitude")
        lng = b.get("lng") or b.get("longitude")
    if lat is None or lng is None:
        raise ValueError("coords not present")
    return float(lat), float(lng)

def haversine_km(lat1, lon1, lat2, lon2) -> float:
    R = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dlmb/2)**2
    return 2 * R * math.asin(math.sqrt(a))

# ============================== TEXT-ONLY BRANCH LIST ==============================
async def build_branch_text_options(phone: str, max_rows: int = 8) -> str:
    data = await _get_all_branches_impl()
    branches = data.get("branches", []) or []
    branches = branches[:max_rows]

    ids = []
    lines = ["Please choose your branch by number, or type its name:"]
    for i, b in enumerate(branches, start=1):
        bid = b.get("branchId") or b.get("_id") or b.get("id")
        name = (b.get("branchName") or b.get("name") or "Branch").strip()
        city = (b.get("city") or b.get("address") or "")
        if not bid:
            continue
        ids.append(str(bid))
        lines.append(f"{i}. {name} {f'({city})' if city else ''}".strip())

    await set_json(BRANCH_CHOICES_KEY % phone.encode(), ids, ex=900)  # 15 min TTL
    return "\n".join(lines)

async def resolve_branch_from_reply(phone: str, user_text: str) -> str | None:
    user_text = (user_text or "").strip()
    if user_text.isdigit():
        mapping = await get_json(BRANCH_CHOICES_KEY % phone.encode()) or []
        idx = int(user_text) - 1
        if 0 <= idx < len(mapping):
            return mapping[idx]

    data = await _get_all_branches_impl()
    branches = data.get("branches", []) or []
    name_to_id = {}
    names = []
    for b in branches:
        bid = b.get("branchId") or b.get("_id") or b.get("id")
        name = (b.get("branchName") or b.get("name") or "").strip()
        if bid and name:
            nm = name.lower()
            names.append(nm)
            name_to_id[nm] = str(bid)

    if not names:
        return None

    match = process.extractOne(user_text.lower(), names, scorer=fuzz.WRatio)
    if match and match[1] >= 65:
        return name_to_id.get(match[0])
    return None

# ============================== TOOL WRAPPERS ==============================
@function_tool(strict_mode=False)
async def get_all_branches() -> Dict:
    return await _get_all_branches_impl()

@function_tool(strict_mode=False)
async def get_branch_info(branch_id: str) -> Dict:
    return await _get_branch_info_impl(branch_id) or {}

@function_tool(strict_mode=False)
async def get_full_menu_items(branch_id: str) -> Dict:
    items = await _get_full_menu_items_impl(branch_id)
    return {"items": items}

@function_tool(strict_mode=False)
async def search_menu_by_branch(branch_id: str, user_input: str) -> Dict:
    return await _search_menu_by_branch_impl(branch_id, user_input)

@function_tool(strict_mode=False)
async def search_menu_item_by_branch(query: str, branch_id: str) -> Dict:
    return await (_search_menu_item_by_branch_impl(query, branch_id) or {})

@function_tool(strict_mode=False)
async def get_item_info(branch_id: str, query_or_id: str) -> Dict:
    return await (_get_item_info_impl(branch_id, query_or_id) or {})

@function_tool(strict_mode=False)
async def send_whatsapp_message(to: str, text: str, preview_url: bool = False) -> Dict:
    return await _send_whatsapp_message_impl(to, text, preview_url)

@function_tool(strict_mode=False)
async def send_whatsapp_image(to: str, media_url: str, caption: str = "") -> Dict:
    return await _send_whatsapp_image_impl(to, media_url, caption or None)

@function_tool(strict_mode=False)
async def send_whatsapp_interactive_list(to: str, payload: Dict) -> Dict:
    return await _send_whatsapp_interactive_list_impl(to, payload)

@function_tool(strict_mode=False)
async def send_whatsapp_location(to: str, latitude: float, longitude: float, name: str = "", address: str = "") -> Dict:
    return await _send_whatsapp_location_impl(to, latitude, longitude, name or None, address or None)

@function_tool(strict_mode=False)
async def send_whatsapp_location_request(to: str, body_text: str = "Please share your location") -> Dict:
    return await _send_whatsapp_location_request_impl(to, body_text)

@function_tool(strict_mode=False)
async def get_user_branch(user_id: str) -> Dict:
    return await (_get_user_branch_impl(user_id) or {})

@function_tool(strict_mode=False)
async def save_user_branch(user_id: str, branch_id: str) -> Dict:
    return await _save_user_branch_impl(user_id, branch_id)

@function_tool(strict_mode=False)
async def clear_user_branch(user_id: str) -> Dict:
    return await _clear_user_branch_impl(user_id)

#%pip install langfuse
#%pip install logfire
from agents import Agent, Runner, trace, gen_trace_id
from agents.mcp import MCPServer, MCPServerSse, create_static_tool_filter
from dotenv import load_dotenv
from langfuse import Langfuse, get_client
import logfire
import base64
import asyncio
from no_stream import RunContextWrapper
from no_stream import add_to_memory, search_memory, get_all_memory, get_partner_info, search_menu_by_branch, search_partner_branch_menu ,Mem0Context
import os
load_dotenv()

# Initialize Langfuse
LANGFUSE_SECRET_KEY = "sk-lf-b112dda3-8ec7-46d2-8580-d9e0f683c736"
LANGFUSE_PUBLIC_KEY = "pk-lf-9838920b-03b3-4847-9d66-4143bac88685"
LANGFUSE_HOST = "https://cloud.langfuse.com"

langfuse = Langfuse(
    secret_key=LANGFUSE_SECRET_KEY,
    public_key=LANGFUSE_PUBLIC_KEY,
    host=LANGFUSE_HOST
)

# Set environment variables for OTEL
os.environ["LANGFUSE_HOST"] = LANGFUSE_HOST
os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = f"{LANGFUSE_HOST}/api/public/otel"
LANGFUSE_AUTH = f"{LANGFUSE_PUBLIC_KEY}:{LANGFUSE_SECRET_KEY}"
os.environ["OTEL_EXPORTER_OTLP_HEADERS"] = f"Authorization=Basic {LANGFUSE_AUTH}"

# Base64 encode public:secret
raw_auth = f"{LANGFUSE_PUBLIC_KEY}:{LANGFUSE_SECRET_KEY}"
encoded_auth = base64.b64encode(raw_auth.encode()).decode()

# Set OTEL env vars
os.environ["LANGFUSE_HOST"] = LANGFUSE_HOST
os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"] = f"{LANGFUSE_HOST}/api/public/otel"
os.environ["OTEL_EXPORTER_OTLP_HEADERS"] = f"Authorization=Basic {encoded_auth}"

# Configure logfire
logfire.configure(
    service_name='grubginie',
    send_to_logfire=False,
)
logfire.instrument_openai_agents()

# Langfuse client auth check
langfuse_client = get_client()
if langfuse_client.auth_check():
    print("Langfuse client is authenticated and ready!")
else:
    print("Authentication failed. Please check your credentials and host.")


async def run(whatsapp_mcp: MCPServer, messages:str ,user_id: str):
    instruction="""
    You are GrubGenie, a memory-enabled restaurant assistant.


0) **Branch Context Check**
- First, call `search_memory` with query `"branchid:"`.
- If it returns a line starting with `branchid: X`, extract `X` and assign it to branch_id.
- Otherwise, branch_id is unset.

1) **Branch selection (if branch_id unset):**
a. Call `get_partner_info` with the user’s message.
b. From its `branches` list pick the first branch object.
c. Call `add_to_memory` with content `"branchid: {branch_id}"`.
d. Call `add_to_memory` with content `"branchname: {branch_name}"`.
e. Call `add_to_memory` with content `"user_id: {user_id}"`.
f. Tell the user: “Using {branch_name}.”

2) **Menu requests:**
a. Always use the in-memory `branch_id`.
b. Call `search_menu_by_branch` with that `branch_id` and `query=""` to load the full menu.
c. There is no query filter support — only show full menu results.
d. Always remember that you have the menu of all branches, so never tell the user you don’t have it.


3) **Branch change**
- If the user says “change branch”:
    a. Reset memory by calling `add_to_memory` with `"branchid: "` (empty).
    b. Call `get_partner_info` with the user’s message.
    c. From its `branches` list, pick the user’s intended branch object.
    d. Call `add_to_memory` with content `"branchid: {branch_id}"`.
    e. Call `add_to_memory` with content `"branchname: {branch_name}"`.
    f.Call `add_to_memory` with content `"user_id: {user_id}"`.
    g. Tell the user: “Using {branch_name}.”


**General Guidelines**
- Never expose branch IDs, tool names, or backend logic.
- Do not mention memory, APIs, or errors—just user-facing menu content.
- Only present data returned by the API; do not include anything not provided by the menu or partner endpoints.

📲 ALWAYS respond using WhatsApp MCP tools only:

- Use `send_message` for any text replies.

- Use `send_whatsapp_image` to send dish images.
  - The image caption must always include:
    - The dish **name**.
    - The **description**, or write `"No description available"` if missing.
    - The **price**, determined by:
      - If price is missing, display `"Price: Not Available"`.
      - Otherwise, determine the applicable currency symbol based on the **location_id** retrieved from `get_partner_info`.
      - Map the location to currency:
        - UAE → AED → د.إ
        - USA → USD → $
        - India → INR → ₹
        - Other locations → display the price followed by the currency code.
      - If currency is not provided, default to no currency.
      
After all dish images are displayed, use `send_message` to send:  
  “Would you like more details on any item, or shall I help you place an order?”  
  Do not repeat the item details again.      
    
- Use `send_whatsapp_location` to share branch addresses. Get the longitude and latitude from the location link provided by `get_partner_info` and ALWAYS use this tool.

- Use `send_template_message` only if a predefined WhatsApp template is needed (avoid unless explicitly necessary).

All responses must be sent to the fixed WhatsApp number: **+18573707830**.  
Console or non-MCP replies are strictly prohibited.
    """
    agent = Agent(
    name="Whatsapp Template",
    instructions=instruction,
    tools=[add_to_memory, search_memory, get_all_memory, get_partner_info, search_menu_by_branch, search_partner_branch_menu],
    mcp_servers=[whatsapp_mcp],
    model="gpt-4.1-mini",
    
)

    context = RunContextWrapper(context=Mem0Context(user_id=user_id))
    message=messages
    response = await Runner.run(agent, message, context=context)
    print(f"[run] context.context: {context.context}")  # Should show Mem0Context with user_id
    print(f"[run] context.context.user_id: {context.context.user_id}")  # Should be the number
    messages+f"'role': 'assistant', 'content': {response}"
    return response.final_output




async def main(messages):
    user_id = "+18573707830" 
    async with MCPServerSse(
        name="Whatsapp Business MCP",
        params={
            "url": "http://localhost:8030/sse",
        },
        cache_tools_list=True,
        tool_filter=create_static_tool_filter(
        allowed_tool_names=["send_whatsapp_image", "send_template_message", "send_message", "send_whatsapp_image", "send_whatsapp_location"]
    )
) as whatsapp_mcp:
        trace_id=gen_trace_id()
        with trace(workflow_name="SSE Example", trace_id=trace_id):
         await run(whatsapp_mcp, messages, user_id)



if __name__ =="__main__":
    while True:
       message=input(": ")
       asyncio.run(main(messages=message))
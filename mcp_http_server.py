#!/usr/bin/env python3
"""
OpenClaw MCP HTTP Server - Claude Web Compatible
Optimized for Claude web interface
"""

import asyncio
import json
import os
from typing import Dict, List
from aiohttp import web
import aiohttp_cors

class SimpleMCPBridge:
    def __init__(self):
        self.tools = [
            {
                "name": "get_user_info",
                "description": "Get information about Nick Cornelius",
                "inputSchema": {"type": "object", "properties": {}}
            },
            {
                "name": "list_active_projects", 
                "description": "List current active projects",
                "inputSchema": {"type": "object", "properties": {}}
            },
            {
                "name": "web_search",
                "description": "Search the web",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "count": {"type": "integer", "default": 10}
                    },
                    "required": ["query"]
                }
            }
        ]
    
    async def handle_initialize(self, params: Dict) -> Dict:
        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}, "logging": {}},
            "serverInfo": {"name": "openclaw-mcp", "version": "1.0.0"}
        }
    
    async def handle_tools_list(self, params: Dict) -> Dict:
        return {"tools": self.tools}
    
    async def handle_tools_call(self, params: Dict) -> Dict:
        tool_name = params.get("name", "")
        
        if tool_name == "get_user_info":
            result = {
                "name": "Nick Cornelius",
                "businesses": ["SimpliScale AI Studio", "AI Voice Company"],
                "revenue": "$70k/month",
                "location": "Texas (digital nomad)",
                "instagram": "@thenickcornelius",
                "contact": "admin@simpliscale.io"
            }
        elif tool_name == "list_active_projects":
            result = {
                "projects": [
                    {"name": "AI News Hub", "status": "In Development"},
                    {"name": "YouTube Thumbnail Generator", "status": "Complete"},
                    {"name": "Reddit Lead Bot", "status": "Ready"},
                    {"name": "Automation Academy", "status": "In Development"}
                ]
            }
        elif tool_name == "web_search":
            result = {"results": [], "note": "Web search not configured"}
        else:
            result = {"error": f"Unknown tool: {tool_name}"}
        
        return {
            "content": [{"type": "text", "text": json.dumps(result, indent=2)}],
            "isError": False
        }

bridge = SimpleMCPBridge()

async def handle_root(request):
    """Root endpoint"""
    return web.json_response({
        "name": "OpenClaw MCP Server",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "/sse": "SSE endpoint for Claude",
            "/messages": "MCP messages",
            "/health": "Health check"
        }
    })

async def handle_health(request):
    """Health check"""
    return web.json_response({"status": "healthy", "timestamp": str(asyncio.get_event_loop().time())})

async def handle_sse(request):
    """SSE endpoint - crucial for Claude"""
    response = web.StreamResponse()
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = '*'
    
    await response.prepare(request)
    
    # Send endpoint event immediately
    await response.write(b"event: endpoint\ndata: /messages\n\n")
    
    # Keep connection alive with heartbeats
    try:
        while True:
            await asyncio.sleep(25)
            await response.write(b": ping\n\n")
    except (asyncio.CancelledError, ConnectionResetError):
        pass
    
    return response

async def handle_message(request):
    """Handle MCP messages"""
    try:
        body = await request.json()
        method = body.get("method", "")
        params = body.get("params", {})
        request_id = body.get("id")
        
        if method == "initialize":
            result = await bridge.handle_initialize(params)
        elif method == "tools/list":
            result = await bridge.handle_tools_list(params)
        elif method == "tools/call":
            result = await bridge.handle_tools_call(params)
        else:
            result = {"error": f"Unknown method: {method}"}
        
        return web.json_response({
            "jsonrpc": "2.0",
            "id": request_id,
            "result": result
        })
    except Exception as e:
        return web.json_response({
            "jsonrpc": "2.0",
            "id": None,
            "error": {"code": -32603, "message": str(e)}
        }, status=500)

async def handle_options(request):
    """Handle CORS preflight"""
    return web.Response(
        status=200,
        headers={
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': '*',
            'Access-Control-Max-Age': '86400'
        }
    )

def main():
    app = web.Application()
    
    # Routes
    app.router.add_get('/', handle_root)
    app.router.add_get('/health', handle_health)
    app.router.add_get('/sse', handle_sse)
    app.router.add_post('/messages', handle_message)
    app.router.add_options('/messages', handle_options)
    app.router.add_options('/sse', handle_options)
    
    port = int(os.environ.get('PORT', 8001))
    print(f"🌐 OpenClaw MCP Server starting on port {port}")
    web.run_app(app, host='0.0.0.0', port=port, print=None)

if __name__ == "__main__":
    main()

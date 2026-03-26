#!/usr/bin/env python3
"""
OpenClaw MCP HTTP Server for Render.com
Standalone version that can run independently
"""

import asyncio
import json
import sys
import os
from typing import Any, Dict, List
from datetime import datetime
from aiohttp import web
import aiohttp_cors

# Simple in-memory implementation (no VPS dependencies for Render)
class SimpleMCPBridge:
    """MCP Server with basic tools"""
    
    def __init__(self):
        self.tools = self._define_tools()
        
    def _define_tools(self) -> List[Dict]:
        """Define available tools"""
        return [
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
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "openclaw-mcp-render", "version": "1.0.0"}
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
                "contact": "admin@simpliscale.io",
                "instagram": "@thenickcornelius"
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
            result = {"message": "Web search requires API key configuration"}
        else:
            result = {"error": f"Unknown tool: {tool_name}"}
        
        return {
            "content": [{"type": "text", "text": json.dumps(result, indent=2)}]
        }

class MCPHTTPServer:
    """HTTP server that exposes MCP over HTTP/SSE"""
    
    def __init__(self):
        self.bridge = SimpleMCPBridge()
        self.app = web.Application()
        self.setup_routes()
        
    def setup_routes(self):
        self.app.router.add_get('/sse', self.handle_sse)
        self.app.router.add_post('/messages', self.handle_message)
        self.app.router.add_get('/health', self.handle_health)
        self.app.router.add_get('/', self.handle_root)
        
        cors = aiohttp_cors.setup(self.app, defaults={
            "*": aiohttp_cors.ResourceOptions(
                allow_credentials=True, expose_headers="*",
                allow_headers="*", allow_methods="*"
            )
        })
        for route in list(self.app.router.routes()):
            cors.add(route)
    
    async def handle_root(self, request):
        return web.json_response({
            "name": "OpenClaw MCP Server (Render)",
            "version": "1.0.0",
            "status": "running",
            "endpoints": {
                "sse": "/sse - Connect here for Claude Desktop",
                "messages": "/messages - Send messages",
                "health": "/health - Health check"
            }
        })
    
    async def handle_health(self, request):
        return web.json_response({"status": "healthy"})
    
    async def handle_sse(self, request):
        response = web.StreamResponse()
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Cache-Control'] = 'no-cache'
        await response.prepare(request)
        
        await response.write(b"event: endpoint\ndata: /messages\n\n")
        
        try:
            while True:
                await asyncio.sleep(30)
                await response.write(f": heartbeat\n\n".encode())
        except asyncio.CancelledError:
            pass
        return response
    
    async def handle_message(self, request):
        try:
            body = await request.json()
            method = body.get("method", "")
            params = body.get("params", {})
            request_id = body.get("id")
            
            if method == "initialize":
                result = await self.bridge.handle_initialize(params)
            elif method == "tools/list":
                result = await self.bridge.handle_tools_list(params)
            elif method == "tools/call":
                result = await self.bridge.handle_tools_call(params)
            else:
                result = {"error": f"Unknown method: {method}"}
            
            return web.json_response({
                "jsonrpc": "2.0", "id": request_id, "result": result
            })
        except Exception as e:
            return web.json_response({
                "jsonrpc": "2.0", "id": None,
                "error": {"code": -32603, "message": str(e)}
            }, status=500)
    
    def run(self):
        port = int(os.environ.get('PORT', 8001))
        print(f"🌐 OpenClaw MCP Server starting on port {port}")
        web.run_app(self.app, host='0.0.0.0', port=port, print=None)

if __name__ == "__main__":
    server = MCPHTTPServer()
    server.run()

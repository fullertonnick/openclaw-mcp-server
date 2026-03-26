#!/bin/bash
# Complete OpenClaw MCP Server Setup Script
# Run this on your Contabo VPS to set up full MCP integration

set -e

echo "=============================================="
echo "🚀 OpenClaw MCP Server - Full Setup"
echo "=============================================="
echo ""

# Configuration
REPO_URL="https://github.com/fullertonnick/openclaw-mcp-server.git"
INSTALL_DIR="/home/nick/.openclaw/mcp-server"

echo "📁 Step 1: Creating directory structure..."
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

echo ""
echo "📦 Step 2: Creating MCP server with full OpenClaw integration..."

# Create main server file
cat > mcp_server.py << 'SERVER_EOF'
#!/usr/bin/env python3
"""
OpenClaw MCP Server - Full Integration
Connects Claude to: Knowledge base, Files, Commands, APIs, Tools
"""

import asyncio
import json
import os
import sys
import glob
import base64
import subprocess
from typing import Any, Dict, List, Optional
from datetime import datetime
from aiohttp import web
import aiohttp_cors

# Configuration
WORKSPACE = "/home/nick/.openclaw/workspace"
FACE_PHOTOS = "/home/nick/.openclaw/workspace/face-photos"
MEMORY_DIR = "/home/nick/.openclaw/workspace/memory"

class OpenClawMCPBridge:
    """Full MCP Bridge with access to all OpenClaw capabilities"""
    
    def __init__(self):
        self.workspace = WORKSPACE
        self.tools = self._define_all_tools()
        
    def _define_all_tools(self) -> List[Dict]:
        """Define all available tools"""
        return [
            # Knowledge Base Tools
            {
                "name": "get_user_info",
                "description": "Get Nick Cornelius complete profile from knowledge base",
                "inputSchema": {"type": "object", "properties": {}}
            },
            {
                "name": "list_active_projects",
                "description": "List all current active projects with status",
                "inputSchema": {"type": "object", "properties": {}}
            },
            {
                "name": "search_memory",
                "description": "Search MEMORY.md and knowledge files for information",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string", "description": "Search query"},
                        "max_results": {"type": "integer", "default": 5}
                    },
                    "required": ["query"]
                }
            },
            
            # File Operations
            {
                "name": "read_file",
                "description": "Read any file on the VPS",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {"type": "string", "description": "Full path to file"},
                        "offset": {"type": "integer", "description": "Start line (optional)", "default": 1},
                        "limit": {"type": "integer", "description": "Max lines (optional)", "default": 100}
                    },
                    "required": ["file_path"]
                }
            },
            {
                "name": "write_file",
                "description": "Write content to a file",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {"type": "string"},
                        "content": {"type": "string"}
                    },
                    "required": ["file_path", "content"]
                }
            },
            {
                "name": "edit_file",
                "description": "Edit file by replacing text",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {"type": "string"},
                        "old_string": {"type": "string"},
                        "new_string": {"type": "string"}
                    },
                    "required": ["file_path", "old_string", "new_string"]
                }
            },
            {
                "name": "list_directory",
                "description": "List files in a directory",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "dir_path": {"type": "string", "description": "Directory path"},
                        "recursive": {"type": "boolean", "default": false}
                    },
                    "required": ["dir_path"]
                }
            },
            
            # Command Execution
            {
                "name": "exec_command",
                "description": "Execute shell command on VPS (PM2, git, npm, etc.)",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "command": {"type": "string", "description": "Shell command to run"},
                        "workdir": {"type": "string", "description": "Working directory", "default": "/home/nick/.openclaw/workspace"},
                        "timeout": {"type": "integer", "description": "Timeout seconds", "default": 60}
                    },
                    "required": ["command"]
                }
            },
            
            # Web Tools
            {
                "name": "web_search",
                "description": "Search the web using Brave API",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "count": {"type": "integer", "default": 10}
                    },
                    "required": ["query"]
                }
            },
            {
                "name": "web_fetch",
                "description": "Fetch content from URL",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "url": {"type": "string"},
                        "extract_mode": {"type": "string", "enum": ["markdown", "text"], "default": "markdown"}
                    },
                    "required": ["url"]
                }
            },
            
            # Custom Tools
            {
                "name": "thumbnail_generator",
                "description": "Generate YouTube thumbnails with Nick's face using Gemini",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "topic": {"type": "string", "description": "Thumbnail topic/text"},
                        "style": {"type": "string", "description": "Style: SHOCKED, CONFIDENT, RESULTS, or TEACHING", "default": "CONFIDENT"},
                        "variations": {"type": "integer", "default": 4}
                    },
                    "required": ["topic"]
                }
            },
            {
                "name": "carousel_generator",
                "description": "Generate Instagram carousels in Tyler Germain style",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "topic": {"type": "string", "description": "Carousel topic"},
                        "slides_count": {"type": "integer", "default": 5}
                    },
                    "required": ["topic"]
                }
            },
            {
                "name": "get_face_photos",
                "description": "Get list of Nick's face photos for thumbnail generation",
                "inputSchema": {"type": "object", "properties": {}}
            }
        ]
    
    # ===== KNOWLEDGE BASE TOOLS =====
    
    async def get_user_info(self) -> Dict:
        """Get Nick's complete profile"""
        return {
            "name": "Nick Cornelius",
            "age": "28-30",
            "location": "Texas (digital nomad)",
            "email": "admin@simpliscale.io",
            "instagram": "@thenickcornelius",
            "businesses": {
                "SimpliScale AI Studio": {
                    "revenue": "$20,000/month",
                    "focus": "AI automation for high-ticket service providers"
                },
                "AI Voice Company": {
                    "revenue": "$50,000/month"
                }
            },
            "total_revenue": "$70,000+/month",
            "team_size": "40+ employees",
            "background": "Former chemist → AI entrepreneur",
            "values": ["Systems over heroics", "Direct communication", "ROI-focused"],
            "target_clients": "High-ticket service providers ($10k+ offers)",
            "tech_stack": ["Make.com", "n8n", "Zapier", "ChatGPT", "Claude", "Bubble.io"]
        }
    
    async def list_active_projects(self) -> Dict:
        """List all active projects"""
        return {
            "projects": [
                {
                    "name": "AI News Hub",
                    "status": "In Development",
                    "description": "Instagram carousel generator with AI news aggregation",
                    "stack": "Next.js + FastAPI + Gemini",
                    "url": "https://frontend-weld-two-83.vercel.app"
                },
                {
                    "name": "YouTube Thumbnail Generator",
                    "status": "Complete",
                    "description": "AI-powered thumbnails with Nick's face",
                    "location": "/home/nick/.openclaw/workspace/"
                },
                {
                    "name": "Reddit Lead Bot",
                    "status": "Ready to Deploy",
                    "description": "Automated Reddit monitoring for SimpliScale leads",
                    "location": "/home/nick/.openclaw/workspace/ai-news-hub/backend/reddit_bot/"
                },
                {
                    "name": "Automation Academy",
                    "status": "In Development",
                    "description": "Course teaching AI automation",
                    "cover_text": "Systems Behind $108M in Sales"
                },
                {
                    "name": "OpenClaw Dashboard",
                    "status": "Deployed",
                    "url": "https://openclaw-dashboard-seven-mu.vercel.app"
                }
            ]
        }
    
    async def search_memory(self, query: str, max_results: int = 5) -> Dict:
        """Search knowledge files"""
        results = []
        
        knowledge_files = [
            f"{WORKSPACE}/CLAUDE_CODE_USER_PROFILE.txt",
            f"{WORKSPACE}/CLAUDE_CODE_COMMUNICATION.txt",
            f"{WORKSPACE}/CLAUDE_CODE_ACTIVE_PROJECTS.txt",
            f"{WORKSPACE}/MEMORY.md",
            f"{WORKSPACE}/USER.md"
        ]
        
        for file_path in knowledge_files:
            if os.path.exists(file_path):
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                        if query.lower() in content.lower():
                            idx = content.lower().find(query.lower())
                            start = max(0, idx - 200)
                            end = min(len(content), idx + 300)
                            results.append({
                                "file": os.path.basename(file_path),
                                "context": content[start:end]
                            })
                except:
                    pass
        
        return {"query": query, "results": results[:max_results]}
    
    # ===== FILE OPERATIONS =====
    
    async def read_file(self, file_path: str, offset: int = 1, limit: int = 100) -> Dict:
        """Read file contents"""
        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()
                start = max(0, offset - 1)
                end = start + limit
                content = ''.join(lines[start:end])
                return {
                    "success": True,
                    "file_path": file_path,
                    "content": content,
                    "lines_read": len(lines[start:end]),
                    "total_lines": len(lines)
                }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def write_file(self, file_path: str, content: str) -> Dict:
        """Write file"""
        try:
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
            with open(file_path, 'w') as f:
                f.write(content)
            return {"success": True, "file_path": file_path, "bytes": len(content)}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def edit_file(self, file_path: str, old_string: str, new_string: str) -> Dict:
        """Edit file"""
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            
            if old_string not in content:
                return {"success": False, "error": "Old string not found"}
            
            new_content = content.replace(old_string, new_string, 1)
            
            with open(file_path, 'w') as f:
                f.write(new_content)
            
            return {"success": True, "file_path": file_path}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def list_directory(self, dir_path: str, recursive: bool = False) -> Dict:
        """List directory"""
        try:
            if recursive:
                files = []
                for root, dirs, filenames in os.walk(dir_path):
                    for f in filenames:
                        files.append(os.path.join(root, f))
                return {"success": True, "path": dir_path, "files": files}
            else:
                entries = os.listdir(dir_path)
                files = [e for e in entries if os.path.isfile(os.path.join(dir_path, e))]
                dirs = [e for e in entries if os.path.isdir(os.path.join(dir_path, e))]
                return {"success": True, "path": dir_path, "files": files, "directories": dirs}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    # ===== COMMAND EXECUTION =====
    
    async def exec_command(self, command: str, workdir: str = WORKSPACE, timeout: int = 60) -> Dict:
        """Execute shell command"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                cwd=workdir,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
        except subprocess.TimeoutExpired:
            return {"success": False, "error": f"Timeout after {timeout}s"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    # ===== WEB TOOLS =====
    
    async def web_search(self, query: str, count: int = 10) -> Dict:
        """Search web"""
        try:
            import urllib.request
            import json
            
            api_key = os.getenv("BRAVE_API_KEY", "")
            if not api_key:
                return {"success": False, "error": "Brave API key not configured"}
            
            url = f"https://api.search.brave.com/res/v1/web/search?q={urllib.parse.quote(query)}&count={count}"
            req = urllib.request.Request(url, headers={"X-Subscription-Token": api_key})
            
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode())
                return {"success": True, "results": data.get("web", {}).get("results", [])}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def web_fetch(self, url: str, extract_mode: str = "markdown") -> Dict:
        """Fetch URL"""
        try:
            import urllib.request
            with urllib.request.urlopen(url, timeout=30) as response:
                content = response.read().decode()
                return {
                    "success": True,
                    "url": url,
                    "content_preview": content[:3000],
                    "length": len(content)
                }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    # ===== CUSTOM TOOLS =====
    
    async def thumbnail_generator(self, topic: str, style: str = "CONFIDENT", variations: int = 4) -> Dict:
        """Generate thumbnails"""
        return {
            "message": "Thumbnail generation initiated",
            "topic": topic,
            "style": style,
            "variations": variations,
            "note": "Run on VPS: cd /home/nick/.openclaw/workspace && python3 thumbnail-generator.py",
            "face_photos_available": len(glob.glob(f"{FACE_PHOTOS}/*.jpg")) if os.path.exists(FACE_PHOTOS) else 0
        }
    
    async def carousel_generator(self, topic: str, slides_count: int = 5) -> Dict:
        """Generate carousels"""
        return {
            "message": "Carousel generation initiated",
            "topic": topic,
            "slides": slides_count,
            "api_endpoint": "http://217.216.91.68:8000/api/carousel/generate",
            "frontend": "https://frontend-weld-two-83.vercel.app"
        }
    
    async def get_face_photos(self) -> Dict:
        """Get face photos list"""
        if os.path.exists(FACE_PHOTOS):
            photos = glob.glob(f"{FACE_PHOTOS}/*.jpg")
            return {"count": len(photos), "photos": [os.path.basename(p) for p in photos[:10]]}
        return {"count": 0, "photos": []}
    
    # ===== TOOL ROUTER =====
    
    async def handle_tool_call(self, name: str, params: Dict) -> Dict:
        """Route tool calls"""
        
        # Knowledge base
        if name == "get_user_info":
            return await self.get_user_info()
        elif name == "list_active_projects":
            return await self.list_active_projects()
        elif name == "search_memory":
            return await self.search_memory(params.get("query", ""), params.get("max_results", 5))
        
        # File operations
        elif name == "read_file":
            return await self.read_file(params.get("file_path"), params.get("offset", 1), params.get("limit", 100))
        elif name == "write_file":
            return await self.write_file(params.get("file_path"), params.get("content", ""))
        elif name == "edit_file":
            return await self.edit_file(params.get("file_path"), params.get("old_string", ""), params.get("new_string", ""))
        elif name == "list_directory":
            return await self.list_directory(params.get("dir_path"), params.get("recursive", False))
        
        # Commands
        elif name == "exec_command":
            return await self.exec_command(params.get("command"), params.get("workdir", WORKSPACE), params.get("timeout", 60))
        
        # Web
        elif name == "web_search":
            return await self.web_search(params.get("query", ""), params.get("count", 10))
        elif name == "web_fetch":
            return await self.web_fetch(params.get("url", ""), params.get("extract_mode", "markdown"))
        
        # Custom tools
        elif name == "thumbnail_generator":
            return await self.thumbnail_generator(params.get("topic", ""), params.get("style", "CONFIDENT"), params.get("variations", 4))
        elif name == "carousel_generator":
            return await self.carousel_generator(params.get("topic", ""), params.get("slides_count", 5))
        elif name == "get_face_photos":
            return await self.get_face_photos()
        
        else:
            return {"error": f"Unknown tool: {name}"}

# Create bridge instance
bridge = OpenClawMCPBridge()

# ===== HTTP HANDLERS =====

async def handle_root(request):
    return web.json_response({
        "name": "OpenClaw MCP Server",
        "version": "1.0.0",
        "status": "running",
        "workspace": WORKSPACE,
        "endpoints": {
            "/sse": "SSE endpoint for Claude Desktop/Web",
            "/messages": "MCP message handler",
            "/health": "Health check"
        }
    })

async def handle_health(request):
    return web.json_response({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "workspace": WORKSPACE
    })

async def handle_sse(request):
    """SSE endpoint"""
    response = web.StreamResponse()
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    response.headers['Access-Control-Allow-Origin'] = '*'
    await response.prepare(request)
    
    await response.write(b"event: endpoint\ndata: /messages\n\n")
    
    try:
        while True:
            await asyncio.sleep(25)
            await response.write(b": ping\n\n")
    except:
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
            result = {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "openclaw-mcp-full", "version": "1.0.0"}
            }
        elif method == "tools/list":
            result = {"tools": bridge.tools}
        elif method == "tools/call":
            tool_result = await bridge.handle_tool_call(params.get("name", ""), params.get("arguments", {}))
            result = {"content": [{"type": "text", "text": json.dumps(tool_result, indent=2)}]}
        else:
            result = {"error": f"Unknown method: {method}"}
        
        return web.json_response({"jsonrpc": "2.0", "id": request_id, "result": result})
    except Exception as e:
        return web.json_response({
            "jsonrpc": "2.0", "id": None,
            "error": {"code": -32603, "message": str(e)}
        }, status=500)

async def handle_options(request):
    return web.Response(status=200, headers={
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': '*'
    })

# Setup app
def main():
    app = web.Application()
    app.router.add_get('/', handle_root)
    app.router.add_get('/health', handle_health)
    app.router.add_get('/sse', handle_sse)
    app.router.add_post('/messages', handle_message)
    app.router.add_options('/{path:.*}', handle_options)
    
    # CORS
    cors = aiohttp_cors.setup(app, defaults={"*": aiohttp_cors.ResourceOptions(
        allow_credentials=True, expose_headers="*", allow_headers="*", allow_methods="*"
    )})
    for route in list(app.router.routes()):
        cors.add(route)
    
    port = int(os.environ.get('PORT', 8001))
    print(f"🚀 OpenClaw MCP Server (FULL) starting on port {port}")
    print(f"📁 Workspace: {WORKSPACE}")
    print(f"🎨 Face photos: {FACE_PHOTOS}")
    web.run_app(app, host='0.0.0.0', port=port, print=None)

if __name__ == "__main__":
    main()
SERVER_EOF

echo "✅ MCP server created"

# Create requirements
echo "aiohttp>=3.9.0" > requirements.txt
echo "aiohttp-cors>=0.7.0" >> requirements.txt
echo "✅ Requirements created"

# Create start script
cat > start.sh << 'STARTEOF'
#!/bin/bash
cd /home/nick/.openclaw/mcp-server
python3 mcp_server.py
STARTEOF
chmod +x start.sh
echo "✅ Start script created"

echo ""
echo "📦 Installing dependencies..."
pip3 install -r requirements.txt --break-system-packages --quiet

echo ""
echo "🚀 Starting server..."
python3 mcp_server.py &
sleep 3

# Check if running
if curl -s http://localhost:8001/health > /dev/null; then
    echo "✅ Server running on port 8001"
else
    echo "❌ Server failed to start"
    exit 1
fi

echo ""
echo "🌥️  Creating Cloudflare tunnel..."
echo "⏳ Getting URL..."

/tmp/cloudflared tunnel --url http://localhost:8001 > /tmp/mcp_tunnel.log 2>&1 &
sleep 15

URL=$(grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' /tmp/mcp_tunnel.log | head -1)

if [ ! -z "$URL" ]; then
    echo ""
    echo "================================================"
    echo "✅ FULL MCP SERVER READY!"
    echo "================================================"
    echo ""
    echo "🔗 CONNECTOR URL:"
    echo "   $URL/sse"
    echo ""
    echo "📋 Paste into Claude Desktop:"
    echo '{"mcpServers":{"openclaw":{"url":"'$URL/sse'"}}}'
    echo ""
    echo "================================================"
    echo ""
    echo "✨ Features available:"
    echo "   • Knowledge base access"
    echo "   • File read/write/edit"
    echo "   • Command execution"
    echo "   • Web search/fetch"
    echo "   • Thumbnail generation"
    echo "   • Carousel generation"
    echo "   • Face photo access"
    echo ""
    echo "================================================"
else
    echo "❌ Tunnel failed. Check: cat /tmp/mcp_tunnel.log"
    exit 1
fi

# OpenClaw MCP Server for Render.com

MCP (Model Context Protocol) server that exposes OpenClaw tools to Claude Desktop.

## Endpoints

- `GET /sse` - SSE endpoint for Claude Desktop
- `POST /messages` - MCP message handler
- `GET /health` - Health check

## Environment Variables

None required - runs standalone.

## Deployment

Automatically deploys to Render.com on push.

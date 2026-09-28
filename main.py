#!/usr/bin/env python3
"""
Root entrypoint for the Instant Phone Search API.
Run directly with: python main.py
"""
import os
import sys

# Ensure api package and project root are discoverable
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
API_DIR = os.path.join(ROOT_DIR, "api")
if API_DIR not in sys.path:
    sys.path.insert(0, API_DIR)

from api.main import app

if __name__ == "__main__":
    import uvicorn
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", 8000))
    display_host = "127.0.0.1" if host == "0.0.0.0" else host
    print(f"[*] Starting API on http://{host}:{port} (Listening on all interfaces)")
    print(f"[*] Local Web UI:       http://{display_host}:{port}/ui")
    print(f"[*] API Docs:           http://{display_host}:{port}/docs")
    print(f"[*] Searches logged to: {os.path.join(ROOT_DIR, 'log.txt')}")
    uvicorn.run(app, host=host, port=port, reload=False, workers=1)

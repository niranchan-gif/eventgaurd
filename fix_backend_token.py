import os
import re

path = r'd:\vscode\enventguardai\backend_server.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace token check
content = content.replace('if token != "EVENTGUARD_DEMO_2026":', 'demo_token = os.environ.get("EVENTGUARD_DEMO_TOKEN")\n                        if not demo_token:\n                            print("WARNING: EVENTGUARD_DEMO_TOKEN environment variable not set. Rejecting connection.")\n                            await websocket.send(json.dumps({"type": "ERROR", "message": "Server configuration error."}))\n                            return\n                        if token != demo_token:')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

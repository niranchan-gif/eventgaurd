import os

path = r'd:\vscode\enventguardai\lib\services\backend_launcher.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace backend_server.py with demo_websocket_server.py
content = content.replace("'backend_server.py'", "'demo_websocket_server.py'")
content = content.replace("backend_server.py", "demo_websocket_server.py")

# Remove or bypass the HTTP check for isBackendResponding
# We can just change isBackendResponding to always return True immediately
content = content.replace("final req = await client.getUrl(Uri.parse('${EventGuardConfig.backendBaseUrl}/api/telemetry'));", "return True; // bypassed for demo")
content = content.replace("if (await isBackendResponding()) {", "if (false) { // bypassed for demo")

# change port 5000 to 8765
content = content.replace("5000", "8765")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

import os

path = r'd:\vscode\enventguardai\lib\services\backend_launcher.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("return True; // bypassed for demo", "return true; // bypassed for demo")
content = content.replace("final res = await req.close().timeout(const Duration(milliseconds: 500));", "// final res = await req.close().timeout(const Duration(milliseconds: 500));")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

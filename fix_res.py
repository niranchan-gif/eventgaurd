import os

path = r'd:\vscode\enventguardai\lib\services\backend_launcher.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final success = res.statusCode == 200;", "// final success = res.statusCode == 200;")
content = content.replace("client.close();", "// client.close();")
content = content.replace("return success;", "// return success;")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

import os

path = r'd:\vscode\enventguardai\lib\services\backend_launcher.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("output.split('\n')".replace('\\n', '\n'), "output.split('\\n')")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

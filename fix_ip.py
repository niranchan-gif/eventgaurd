import os

path = r'd:\vscode\enventguardai\staff_app\lib\main.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'127.0.0.1'", "'192.168.1.10'")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

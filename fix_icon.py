import os

path = r'd:\vscode\enventguardai\lib\screens\dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("Icons.Security_tech_rounded", "Icons.security")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

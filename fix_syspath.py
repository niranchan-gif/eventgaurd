import os

def patch_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "sys.path.insert" not in content:
        insert_code = """
import sys
import os
site_packages = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'venv', 'Lib', 'site-packages')
if site_packages not in sys.path:
    sys.path.insert(0, site_packages)
"""
        # Find first import statement
        import_idx = content.find("import ")
        if import_idx != -1:
            content = content[:import_idx] + insert_code + content[import_idx:]
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)

patch_file(r'd:\vscode\enventguardai\backend_server.py')
patch_file(r'd:\vscode\enventguardai\demo_websocket_server.py')

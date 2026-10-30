import os
import re

directories_to_skip = {'.git', 'dist', 'build', 'venv', '.dart_tool', '__pycache__', '.idea', 'windows', 'assets'}
extensions_to_process = {'.dart', '.py', '.txt', '.md', '.bat', '.yaml', '.json'}

terms = ['BorderGuard', 'Bordergaurd', 'Bordergaurdai', 'BG_', 'DEFCON', 'Defense', 'Commander', 'Tactical', 'Military', 'VANCE', 'Event2026', 'instantCommanderLogin', 'instantSupervisorLogin', r'D:\\vscode', 'EG_DEFAULT_FALLBACK', 'GitHub PAT', 'github_token']

root_dir = r'd:\vscode\enventguardai'
for root, dirs, files in os.walk(root_dir):
    dirs[:] = [d for d in dirs if d not in directories_to_skip]
    for file in files:
        if os.path.splitext(file)[1].lower() in extensions_to_process:
            filepath = os.path.join(root, file)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for term in terms:
                        if re.search(term, content, re.IGNORECASE):
                            print(f'Match found for {term} in {filepath}')
            except: pass

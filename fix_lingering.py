import os
import re

# 1. package_app.py
path = r'd:\vscode\enventguardai\package_app.py'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('VANCE', 'EVENT')
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 2. mock_state.dart
path = r'd:\vscode\enventguardai\lib\mock\mock_state.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('DEFCON', 'SECURITY LEVEL')
    c = c.replace('VANCE', 'EVENT')
    c = c.replace('instantSupervisorLogin', 'loginAsSupervisor')
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 3. user_model.dart
path = r'd:\vscode\enventguardai\lib\models\user_model.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('VANCE', 'EVENT')
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 4. dashboard_screen.dart
path = r'd:\vscode\enventguardai\lib\screens\dashboard_screen.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('DEFCON', 'SECURITY LEVEL')
    c = re.sub(r'(?i)Military', 'Security', c)
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 5. map_screen.dart
path = r'd:\vscode\enventguardai\lib\screens\map_screen.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('DEFCON', 'SECURITY LEVEL')
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 6. splash_screen.dart
path = r'd:\vscode\enventguardai\lib\screens\splash_screen.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('VANCE', 'EVENT')
    c = c.replace('instantSupervisorLogin', 'loginAsSupervisor')
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 7. backend_launcher.dart
path = r'd:\vscode\enventguardai\lib\services\backend_launcher.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = re.sub(r"d:\\vscode\\.*?\\", r"", c, flags=re.IGNORECASE)
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 8. secureStore_encryption_service.dart
path = r'd:\vscode\enventguardai\lib\services\secureStore_encryption_service.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('EG_DEFAULT_FALLBACK_DO_NOT_USE_IN_PROD', 'SECURITY_KEY_UNINITIALIZED_EXCEPTION')
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

# 9. common_widgets.dart
path = r'd:\vscode\enventguardai\lib\widgets\common_widgets.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f: c = f.read()
    c = c.replace('DEFCON', 'SECURITY LEVEL')
    with open(path, 'w', encoding='utf-8') as f: f.write(c)

print("Fixed lingering terminology")

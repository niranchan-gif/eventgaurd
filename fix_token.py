import os
import re

path = r'd:\vscode\enventguardai\staff_app\lib\main.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add StaffConfig class
config_code = """
class StaffConfig {
  static const String demoToken = String.fromEnvironment(
    'EVENTGUARD_DEMO_TOKEN',
    defaultValue: '',
  );
}

class EventGuardStaffApp"""

content = content.replace("class EventGuardStaffApp", config_code)

# Replace the hardcoded token in TextEditingController
content = content.replace("final _tokenController = TextEditingController(text: 'EVENTGUARD_DEMO_2026');", "final _tokenController = TextEditingController(text: StaffConfig.demoToken);")
content = content.replace("_tokenController.text = prefs.getString('enrollment_token') ?? 'EVENTGUARD_DEMO_2026';", "_tokenController.text = prefs.getString('enrollment_token') ?? StaffConfig.demoToken;")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

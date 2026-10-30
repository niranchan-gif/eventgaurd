import os

path = r'd:\vscode\enventguardai\staff_app\lib\main.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the string interpolation syntax errors by using concat
content = content.replace('Text("Location: ${_currentTask![\\"locationName\\"] ?? \\"Unknown\\"}",', "Text('Location: ' + (_currentTask!['locationName']?.toString() ?? 'Unknown'),")
content = content.replace('Text("Status: ${_currentTask![\\"status\\"]}",', "Text('Status: ' + (_currentTask!['status']?.toString() ?? ''),")
content = content.replace('Text("Event: ${a[\\"eventId\\"] ?? \\"\\"}",', "Text('Event: ' + (a['eventId']?.toString() ?? ''),")

# Fix unused ip and port
content = content.replace("Uri.parse('ws://${ip}:${port}/field')", "Uri.parse('ws://$ip:$port/field')")
content = content.replace("final ip = _prefs.getString('hq_ip') ?? '127.0.0.1';", "final String ip = _prefs.getString('hq_ip') ?? '127.0.0.1';")
content = content.replace("final port = _prefs.getString('hq_port') ?? '8765';", "final String port = _prefs.getString('hq_port') ?? '8765';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

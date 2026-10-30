import os
import re

path = r'd:\vscode\enventguardai\lib\screens\main_layout.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports if not present
if "import 'dart:io';" not in content:
    content = "import 'dart:io';\nimport 'dart:convert';\n" + content

# Add the dialog and FAB logic
deploy_code = """
  void _showDeployDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151722),
          title: const Text('DEPLOY TROOP', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Staff/Team: SECURITY-A', style: TextStyle(color: Colors.grey)),
              Text('Task: North Entrance Monitoring', style: TextStyle(color: Colors.white)),
              Text('Message: Proceed to North Entrance immediately.', style: TextStyle(color: Colors.white)),
              Text('Priority: HIGH', style: TextStyle(color: Colors.redAccent)),
              Text('Location: North Entrance', style: TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                _sendDeployCommand();
                Navigator.pop(context);
              },
              child: const Text('DEPLOY', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendDeployCommand() async {
    try {
      final ws = await WebSocket.connect('ws://127.0.0.1:8765/hq');
      ws.add(jsonEncode({
        "type": "DEPLOY_TROOP",
        "teamId": "SECURITY-A",
        "title": "North Entrance Monitoring",
        "description": "Proceed to North Entrance immediately.",
        "priority": "HIGH",
        "locationName": "North Entrance"
      }));
      await Future.delayed(const Duration(milliseconds: 500));
      ws.close();
    } catch (e) {
      debugPrint('Deploy error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
"""

content = content.replace("  @override\n  Widget build(BuildContext context) {", deploy_code)

# Add FloatingActionButton to Scaffold
scaffold_code = """    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.flash_on, color: Colors.white),
        label: const Text('DEPLOY TROOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showDeployDialog(context),
      ),
      body: Row("""

content = content.replace("    return Scaffold(\n      body: Row(", scaffold_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

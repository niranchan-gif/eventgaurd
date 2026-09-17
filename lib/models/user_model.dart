enum AuthProvider { password, github }

class UserModel {
  final String id;
  final String name;
  final String callsign;
  final String email;
  final String role;
  final String clearanceLevel;
  final String? avatarUrl;
  final AuthProvider provider;

  const UserModel({
    required this.id,
    required this.name,
    required this.callsign,
    required this.email,
    required this.role,
    required this.clearanceLevel,
    this.avatarUrl,
    this.provider = AuthProvider.password,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'OP';
  }

  // Default auto-initialized commander profile for zero-manual instant boot
  static const UserModel defaultCommander = UserModel(
    id: 'OP-COMMANDER-01',
    name: 'Commander Sarah Vance',
    callsign: 'VANCE-01',
    email: 'commander.vance@eventguard.mil',
    role: 'Chief Tactical Defense Officer',
    clearanceLevel: 'LEVEL 4 • COMMAND CLEARANCE',
    avatarUrl: null,
    provider: AuthProvider.password,
  );

  // Generic fallback if an unauthenticated widget requires a fallback instance
  static const UserModel unassigned = UserModel(
    id: 'OP-UNASSIGNED',
    name: 'Operator On-Duty',
    callsign: 'operator',
    email: 'c2@eventguard.mil',
    role: 'Defense Watch Officer',
    clearanceLevel: 'LEVEL 1 • STATION ACTIVE',
    avatarUrl: null,
    provider: AuthProvider.password,
  );
}

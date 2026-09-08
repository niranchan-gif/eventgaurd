enum AuthProvider { password, google }

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

  // Pre-configured default tactical and Google accounts
  static const UserModel commanderAlpha = UserModel(
    id: 'USR-CMD-01',
    name: 'Arun Kumar',
    callsign: 'commander_alpha',
    email: 'arun.kumar@borderguard.mil',
    role: 'Surveillance Commander',
    clearanceLevel: 'LEVEL 5 • DEFCON-1 COMMAND',
    avatarUrl: null,
    provider: AuthProvider.password,
  );

  static const UserModel tacticalOperator = UserModel(
    id: 'USR-OPS-02',
    name: 'Elena Rostova',
    callsign: 'operator_01',
    email: 'elena.rostova@borderguard.mil',
    role: 'Perimeter Tactical Specialist',
    clearanceLevel: 'LEVEL 3 • SENSOR OPERATOR',
    avatarUrl: null,
    provider: AuthProvider.password,
  );

  static const UserModel googleDemoUser1 = UserModel(
    id: 'GGL-8829104',
    name: 'Dr. Arjun Mehta',
    callsign: 'arjun.mehta',
    email: 'arjun.mehta.defense@gmail.com',
    role: 'Chief AI Defense Analyst',
    clearanceLevel: 'LEVEL 4 • DIRECT AI OVERSIGHT',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
    provider: AuthProvider.google,
  );

  static const UserModel googleDemoUser2 = UserModel(
    id: 'GGL-9301284',
    name: 'Sarah Connor',
    callsign: 's.connor',
    email: 'sarah.connor.sentinel@gmail.com',
    role: 'Perimeter Defense Officer',
    clearanceLevel: 'LEVEL 4 • RAPID RESPONSE',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop&q=80',
    provider: AuthProvider.google,
  );
}

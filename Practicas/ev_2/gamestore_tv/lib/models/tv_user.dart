/// Usuario de la sesión de GameStore TV. La API responde en snake_case
/// (nivel, xp_siguiente, juegos_poseidos), igual que la app móvil.
class TvUser {
  final String id;
  final String username;
  final String gamertag;
  final String email;
  final int level;
  final int xp;
  final int gamesOwned;

  const TvUser({
    required this.id,
    required this.username,
    required this.gamertag,
    required this.email,
    this.level = 1,
    this.xp = 0,
    this.gamesOwned = 0,
  });

  factory TvUser.fromJson(Map j) {
    return TvUser(
      id: j['id'].toString(),
      username: j['username']?.toString() ?? '',
      gamertag: j['gamertag']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      level: int.tryParse(j['nivel']?.toString() ?? '') ?? 1,
      xp: int.tryParse(j['xp']?.toString() ?? '') ?? 0,
      gamesOwned: int.tryParse(j['juegos_poseidos']?.toString() ?? '') ?? 0,
    );
  }

  TvUser copyWith({String? username, String? gamertag, String? email}) {
    return TvUser(
      id: id,
      username: username ?? this.username,
      gamertag: gamertag ?? this.gamertag,
      email: email ?? this.email,
      level: level,
      xp: xp,
      gamesOwned: gamesOwned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'gamertag': gamertag,
        'email': email,
        'nivel': level,
        'xp': xp,
        'juegos_poseidos': gamesOwned,
      };
}

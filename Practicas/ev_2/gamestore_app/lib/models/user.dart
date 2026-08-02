class UserModel {
  final String id;
  final String username;
  final String gamertag;
  final String email;
  final int level;
  final int xp;
  final int nextLevelXp;
  final int gamesOwned;
  final List<String> recentGames;

  const UserModel({
    required this.id,
    required this.username,
    required this.gamertag,
    required this.email,
    this.level = 1,
    this.xp = 0,
    this.nextLevelXp = 1000,
    this.gamesOwned = 0,
    this.recentGames = const [],
  });

  UserModel copyWith({
    String? username,
    String? gamertag,
    String? email,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      gamertag: gamertag ?? this.gamertag,
      email: email ?? this.email,
      level: level,
      xp: xp,
      nextLevelXp: nextLevelXp,
      gamesOwned: gamesOwned,
      recentGames: recentGames,
    );
  }
}

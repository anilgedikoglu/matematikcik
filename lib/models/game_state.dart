class GameState {
  final int unlockedLevel; // 1–60, şu an oynanabilir en yüksek level
  final Map<int, int> levelScores; // level → doğru sayısı
  final int lives; // 0–3, mevcut can sayısı (kaydedilmez, oturum içi)

  const GameState({
    required this.unlockedLevel,
    required this.levelScores,
    this.lives = 3,
  });

  GameState copyWith({int? unlockedLevel, Map<int, int>? levelScores, int? lives}) =>
      GameState(
        unlockedLevel: unlockedLevel ?? this.unlockedLevel,
        levelScores: levelScores ?? this.levelScores,
        lives: lives ?? this.lives,
      );

  static GameState fresh() =>
      const GameState(unlockedLevel: 1, levelScores: {}, lives: 3);
}

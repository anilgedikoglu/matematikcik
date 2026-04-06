class GameState {
  final int unlockedLevel; // 1–10, en son açılan level
  final Map<int, int> levelScores; // level → doğru sayısı

  const GameState({
    required this.unlockedLevel,
    required this.levelScores,
  });

  GameState copyWith({int? unlockedLevel, Map<int, int>? levelScores}) =>
      GameState(
        unlockedLevel: unlockedLevel ?? this.unlockedLevel,
        levelScores: levelScores ?? this.levelScores,
      );

  static GameState fresh() =>
      const GameState(unlockedLevel: 1, levelScores: {});
}

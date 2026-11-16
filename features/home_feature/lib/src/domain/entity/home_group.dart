typedef NewGroup = ({String name, String emoji, String currencyCode, List<String> participants});

final class HomeGroup {
  const HomeGroup({
    required this.id,
    required this.name,
    required this.emoji,
    required this.currencyCode,
    required this.participants,
  });

  final int id;
  final String name;
  final String emoji;
  final String currencyCode;
  final List<String> participants;
}

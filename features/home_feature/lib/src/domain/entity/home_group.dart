typedef NewGroup = ({String name, String emoji, String currencyCode, List<String> participants});

enum GroupRemoteState { localOnly, pending, uploaded, notConfirmed }

final class HomeGroup {
  const HomeGroup({
    required this.id,
    required this.name,
    required this.emoji,
    required this.currencyCode,
    required this.participants,
    this.stableId = '',
    this.remoteState = GroupRemoteState.localOnly,
  });

  final int id;
  final String name;
  final String emoji;
  final String currencyCode;
  final List<String> participants;
  final String stableId;
  final GroupRemoteState remoteState;
}

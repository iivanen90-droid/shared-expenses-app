final class GroupCurrency {
  const GroupCurrency({required this.code, required this.english, required this.ukrainian});

  final String code;
  final String english;
  final String ukrainian;

  String name(String languageCode) => languageCode == 'uk' ? ukrainian : english;
}

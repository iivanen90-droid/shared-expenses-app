import 'package:objectbox/objectbox.dart';

@Entity()
class HomeGroupRecord {
  HomeGroupRecord({
    this.id = 0,
    required this.name,
    required this.emoji,
    required this.currencyCode,
    required this.participants,
    this.stableId = '',
    this.ownerId = '',
    this.remoteState = 'localOnly',
  });

  @Id()
  int id;
  String name;
  String emoji;
  String currencyCode;
  List<String> participants;
  String stableId;
  String ownerId;
  String remoteState;
}

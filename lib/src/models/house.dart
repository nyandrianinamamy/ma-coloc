import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'house_settings.dart';

part 'house.freezed.dart';
part 'house.g.dart';

class TimestampConverter implements JsonConverter<Timestamp, Timestamp> {
  const TimestampConverter();

  @override
  Timestamp fromJson(Timestamp json) => json;

  @override
  Timestamp toJson(Timestamp object) => object;
}

@freezed
class House with _$House {
  @JsonSerializable(explicitToJson: true)
  const factory House({
    required String id,
    required String name,
    required String createdBy,
    @TimestampConverter() required Timestamp createdAt,
    required String inviteCode,
    required List<String> members,
    required List<String> rooms,
    required String timezone,
    String? lastResetDate,
    String? lastDeepCleanMonth,
    @Default(HouseSettings()) HouseSettings settings,
    @Default(false) bool isDemo,
  }) = _House;

  factory House.fromJson(Map<String, dynamic> json) => _$HouseFromJson(json);

  factory House.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return House.fromJson({...data, 'id': doc.id});
  }
}

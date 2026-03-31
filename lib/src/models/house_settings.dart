import 'package:freezed_annotation/freezed_annotation.dart';

part 'house_settings.freezed.dart';
part 'house_settings.g.dart';

@freezed
class HouseSettings with _$HouseSettings {
  const factory HouseSettings({
    @Default(1) int deepCleanDay,
    @Default(48) int volunteerWindowHours,
    @Default(48) int disputeWindowHours,
  }) = _HouseSettings;

  factory HouseSettings.fromJson(Map<String, dynamic> json) =>
      _$HouseSettingsFromJson(json);
}

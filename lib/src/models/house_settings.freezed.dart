// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'house_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HouseSettings _$HouseSettingsFromJson(Map<String, dynamic> json) {
  return _HouseSettings.fromJson(json);
}

/// @nodoc
mixin _$HouseSettings {
  int get deepCleanDay => throw _privateConstructorUsedError;
  int get volunteerWindowHours => throw _privateConstructorUsedError;
  int get disputeWindowHours => throw _privateConstructorUsedError;

  /// Serializes this HouseSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HouseSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HouseSettingsCopyWith<HouseSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HouseSettingsCopyWith<$Res> {
  factory $HouseSettingsCopyWith(
    HouseSettings value,
    $Res Function(HouseSettings) then,
  ) = _$HouseSettingsCopyWithImpl<$Res, HouseSettings>;
  @useResult
  $Res call({
    int deepCleanDay,
    int volunteerWindowHours,
    int disputeWindowHours,
  });
}

/// @nodoc
class _$HouseSettingsCopyWithImpl<$Res, $Val extends HouseSettings>
    implements $HouseSettingsCopyWith<$Res> {
  _$HouseSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HouseSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deepCleanDay = null,
    Object? volunteerWindowHours = null,
    Object? disputeWindowHours = null,
  }) {
    return _then(
      _value.copyWith(
            deepCleanDay: null == deepCleanDay
                ? _value.deepCleanDay
                : deepCleanDay // ignore: cast_nullable_to_non_nullable
                      as int,
            volunteerWindowHours: null == volunteerWindowHours
                ? _value.volunteerWindowHours
                : volunteerWindowHours // ignore: cast_nullable_to_non_nullable
                      as int,
            disputeWindowHours: null == disputeWindowHours
                ? _value.disputeWindowHours
                : disputeWindowHours // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HouseSettingsImplCopyWith<$Res>
    implements $HouseSettingsCopyWith<$Res> {
  factory _$$HouseSettingsImplCopyWith(
    _$HouseSettingsImpl value,
    $Res Function(_$HouseSettingsImpl) then,
  ) = __$$HouseSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int deepCleanDay,
    int volunteerWindowHours,
    int disputeWindowHours,
  });
}

/// @nodoc
class __$$HouseSettingsImplCopyWithImpl<$Res>
    extends _$HouseSettingsCopyWithImpl<$Res, _$HouseSettingsImpl>
    implements _$$HouseSettingsImplCopyWith<$Res> {
  __$$HouseSettingsImplCopyWithImpl(
    _$HouseSettingsImpl _value,
    $Res Function(_$HouseSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HouseSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deepCleanDay = null,
    Object? volunteerWindowHours = null,
    Object? disputeWindowHours = null,
  }) {
    return _then(
      _$HouseSettingsImpl(
        deepCleanDay: null == deepCleanDay
            ? _value.deepCleanDay
            : deepCleanDay // ignore: cast_nullable_to_non_nullable
                  as int,
        volunteerWindowHours: null == volunteerWindowHours
            ? _value.volunteerWindowHours
            : volunteerWindowHours // ignore: cast_nullable_to_non_nullable
                  as int,
        disputeWindowHours: null == disputeWindowHours
            ? _value.disputeWindowHours
            : disputeWindowHours // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HouseSettingsImpl implements _HouseSettings {
  const _$HouseSettingsImpl({
    this.deepCleanDay = 1,
    this.volunteerWindowHours = 48,
    this.disputeWindowHours = 48,
  });

  factory _$HouseSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$HouseSettingsImplFromJson(json);

  @override
  @JsonKey()
  final int deepCleanDay;
  @override
  @JsonKey()
  final int volunteerWindowHours;
  @override
  @JsonKey()
  final int disputeWindowHours;

  @override
  String toString() {
    return 'HouseSettings(deepCleanDay: $deepCleanDay, volunteerWindowHours: $volunteerWindowHours, disputeWindowHours: $disputeWindowHours)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HouseSettingsImpl &&
            (identical(other.deepCleanDay, deepCleanDay) ||
                other.deepCleanDay == deepCleanDay) &&
            (identical(other.volunteerWindowHours, volunteerWindowHours) ||
                other.volunteerWindowHours == volunteerWindowHours) &&
            (identical(other.disputeWindowHours, disputeWindowHours) ||
                other.disputeWindowHours == disputeWindowHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    deepCleanDay,
    volunteerWindowHours,
    disputeWindowHours,
  );

  /// Create a copy of HouseSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HouseSettingsImplCopyWith<_$HouseSettingsImpl> get copyWith =>
      __$$HouseSettingsImplCopyWithImpl<_$HouseSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HouseSettingsImplToJson(this);
  }
}

abstract class _HouseSettings implements HouseSettings {
  const factory _HouseSettings({
    final int deepCleanDay,
    final int volunteerWindowHours,
    final int disputeWindowHours,
  }) = _$HouseSettingsImpl;

  factory _HouseSettings.fromJson(Map<String, dynamic> json) =
      _$HouseSettingsImpl.fromJson;

  @override
  int get deepCleanDay;
  @override
  int get volunteerWindowHours;
  @override
  int get disputeWindowHours;

  /// Create a copy of HouseSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HouseSettingsImplCopyWith<_$HouseSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

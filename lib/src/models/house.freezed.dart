// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'house.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

House _$HouseFromJson(Map<String, dynamic> json) {
  return _House.fromJson(json);
}

/// @nodoc
mixin _$House {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get createdAt => throw _privateConstructorUsedError;
  String get inviteCode => throw _privateConstructorUsedError;
  List<String> get members => throw _privateConstructorUsedError;
  List<String> get rooms => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;
  String? get lastResetDate => throw _privateConstructorUsedError;
  String? get lastDeepCleanMonth => throw _privateConstructorUsedError;
  HouseSettings get settings => throw _privateConstructorUsedError;

  /// Serializes this House to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of House
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HouseCopyWith<House> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HouseCopyWith<$Res> {
  factory $HouseCopyWith(House value, $Res Function(House) then) =
      _$HouseCopyWithImpl<$Res, House>;
  @useResult
  $Res call({
    String id,
    String name,
    String createdBy,
    @TimestampConverter() Timestamp createdAt,
    String inviteCode,
    List<String> members,
    List<String> rooms,
    String timezone,
    String? lastResetDate,
    String? lastDeepCleanMonth,
    HouseSettings settings,
  });

  $HouseSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class _$HouseCopyWithImpl<$Res, $Val extends House>
    implements $HouseCopyWith<$Res> {
  _$HouseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of House
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? inviteCode = null,
    Object? members = null,
    Object? rooms = null,
    Object? timezone = null,
    Object? lastResetDate = freezed,
    Object? lastDeepCleanMonth = freezed,
    Object? settings = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp,
            inviteCode: null == inviteCode
                ? _value.inviteCode
                : inviteCode // ignore: cast_nullable_to_non_nullable
                      as String,
            members: null == members
                ? _value.members
                : members // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            rooms: null == rooms
                ? _value.rooms
                : rooms // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            timezone: null == timezone
                ? _value.timezone
                : timezone // ignore: cast_nullable_to_non_nullable
                      as String,
            lastResetDate: freezed == lastResetDate
                ? _value.lastResetDate
                : lastResetDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastDeepCleanMonth: freezed == lastDeepCleanMonth
                ? _value.lastDeepCleanMonth
                : lastDeepCleanMonth // ignore: cast_nullable_to_non_nullable
                      as String?,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as HouseSettings,
          )
          as $Val,
    );
  }

  /// Create a copy of House
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HouseSettingsCopyWith<$Res> get settings {
    return $HouseSettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HouseImplCopyWith<$Res> implements $HouseCopyWith<$Res> {
  factory _$$HouseImplCopyWith(
    _$HouseImpl value,
    $Res Function(_$HouseImpl) then,
  ) = __$$HouseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String createdBy,
    @TimestampConverter() Timestamp createdAt,
    String inviteCode,
    List<String> members,
    List<String> rooms,
    String timezone,
    String? lastResetDate,
    String? lastDeepCleanMonth,
    HouseSettings settings,
  });

  @override
  $HouseSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class __$$HouseImplCopyWithImpl<$Res>
    extends _$HouseCopyWithImpl<$Res, _$HouseImpl>
    implements _$$HouseImplCopyWith<$Res> {
  __$$HouseImplCopyWithImpl(
    _$HouseImpl _value,
    $Res Function(_$HouseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of House
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? inviteCode = null,
    Object? members = null,
    Object? rooms = null,
    Object? timezone = null,
    Object? lastResetDate = freezed,
    Object? lastDeepCleanMonth = freezed,
    Object? settings = null,
  }) {
    return _then(
      _$HouseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp,
        inviteCode: null == inviteCode
            ? _value.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String,
        members: null == members
            ? _value._members
            : members // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        rooms: null == rooms
            ? _value._rooms
            : rooms // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        timezone: null == timezone
            ? _value.timezone
            : timezone // ignore: cast_nullable_to_non_nullable
                  as String,
        lastResetDate: freezed == lastResetDate
            ? _value.lastResetDate
            : lastResetDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastDeepCleanMonth: freezed == lastDeepCleanMonth
            ? _value.lastDeepCleanMonth
            : lastDeepCleanMonth // ignore: cast_nullable_to_non_nullable
                  as String?,
        settings: null == settings
            ? _value.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as HouseSettings,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$HouseImpl implements _House {
  const _$HouseImpl({
    required this.id,
    required this.name,
    required this.createdBy,
    @TimestampConverter() required this.createdAt,
    required this.inviteCode,
    required final List<String> members,
    required final List<String> rooms,
    required this.timezone,
    this.lastResetDate,
    this.lastDeepCleanMonth,
    this.settings = const HouseSettings(),
  }) : _members = members,
       _rooms = rooms;

  factory _$HouseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HouseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String createdBy;
  @override
  @TimestampConverter()
  final Timestamp createdAt;
  @override
  final String inviteCode;
  final List<String> _members;
  @override
  List<String> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  final List<String> _rooms;
  @override
  List<String> get rooms {
    if (_rooms is EqualUnmodifiableListView) return _rooms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rooms);
  }

  @override
  final String timezone;
  @override
  final String? lastResetDate;
  @override
  final String? lastDeepCleanMonth;
  @override
  @JsonKey()
  final HouseSettings settings;

  @override
  String toString() {
    return 'House(id: $id, name: $name, createdBy: $createdBy, createdAt: $createdAt, inviteCode: $inviteCode, members: $members, rooms: $rooms, timezone: $timezone, lastResetDate: $lastResetDate, lastDeepCleanMonth: $lastDeepCleanMonth, settings: $settings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HouseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            const DeepCollectionEquality().equals(other._rooms, _rooms) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.lastResetDate, lastResetDate) ||
                other.lastResetDate == lastResetDate) &&
            (identical(other.lastDeepCleanMonth, lastDeepCleanMonth) ||
                other.lastDeepCleanMonth == lastDeepCleanMonth) &&
            (identical(other.settings, settings) ||
                other.settings == settings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    createdBy,
    createdAt,
    inviteCode,
    const DeepCollectionEquality().hash(_members),
    const DeepCollectionEquality().hash(_rooms),
    timezone,
    lastResetDate,
    lastDeepCleanMonth,
    settings,
  );

  /// Create a copy of House
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HouseImplCopyWith<_$HouseImpl> get copyWith =>
      __$$HouseImplCopyWithImpl<_$HouseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HouseImplToJson(this);
  }
}

abstract class _House implements House {
  const factory _House({
    required final String id,
    required final String name,
    required final String createdBy,
    @TimestampConverter() required final Timestamp createdAt,
    required final String inviteCode,
    required final List<String> members,
    required final List<String> rooms,
    required final String timezone,
    final String? lastResetDate,
    final String? lastDeepCleanMonth,
    final HouseSettings settings,
  }) = _$HouseImpl;

  factory _House.fromJson(Map<String, dynamic> json) = _$HouseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get createdBy;
  @override
  @TimestampConverter()
  Timestamp get createdAt;
  @override
  String get inviteCode;
  @override
  List<String> get members;
  @override
  List<String> get rooms;
  @override
  String get timezone;
  @override
  String? get lastResetDate;
  @override
  String? get lastDeepCleanMonth;
  @override
  HouseSettings get settings;

  /// Create a copy of House
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HouseImplCopyWith<_$HouseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

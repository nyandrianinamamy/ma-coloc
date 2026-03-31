// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deep_clean.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VolunteerIntent _$VolunteerIntentFromJson(Map<String, dynamic> json) {
  return _VolunteerIntent.fromJson(json);
}

/// @nodoc
mixin _$VolunteerIntent {
  String get uid => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get volunteeredAt => throw _privateConstructorUsedError;

  /// Serializes this VolunteerIntent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VolunteerIntent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VolunteerIntentCopyWith<VolunteerIntent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VolunteerIntentCopyWith<$Res> {
  factory $VolunteerIntentCopyWith(
    VolunteerIntent value,
    $Res Function(VolunteerIntent) then,
  ) = _$VolunteerIntentCopyWithImpl<$Res, VolunteerIntent>;
  @useResult
  $Res call({String uid, @TimestampConverter() Timestamp volunteeredAt});
}

/// @nodoc
class _$VolunteerIntentCopyWithImpl<$Res, $Val extends VolunteerIntent>
    implements $VolunteerIntentCopyWith<$Res> {
  _$VolunteerIntentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VolunteerIntent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? uid = null, Object? volunteeredAt = null}) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            volunteeredAt: null == volunteeredAt
                ? _value.volunteeredAt
                : volunteeredAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VolunteerIntentImplCopyWith<$Res>
    implements $VolunteerIntentCopyWith<$Res> {
  factory _$$VolunteerIntentImplCopyWith(
    _$VolunteerIntentImpl value,
    $Res Function(_$VolunteerIntentImpl) then,
  ) = __$$VolunteerIntentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String uid, @TimestampConverter() Timestamp volunteeredAt});
}

/// @nodoc
class __$$VolunteerIntentImplCopyWithImpl<$Res>
    extends _$VolunteerIntentCopyWithImpl<$Res, _$VolunteerIntentImpl>
    implements _$$VolunteerIntentImplCopyWith<$Res> {
  __$$VolunteerIntentImplCopyWithImpl(
    _$VolunteerIntentImpl _value,
    $Res Function(_$VolunteerIntentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VolunteerIntent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? uid = null, Object? volunteeredAt = null}) {
    return _then(
      _$VolunteerIntentImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        volunteeredAt: null == volunteeredAt
            ? _value.volunteeredAt
            : volunteeredAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VolunteerIntentImpl implements _VolunteerIntent {
  const _$VolunteerIntentImpl({
    required this.uid,
    @TimestampConverter() required this.volunteeredAt,
  });

  factory _$VolunteerIntentImpl.fromJson(Map<String, dynamic> json) =>
      _$$VolunteerIntentImplFromJson(json);

  @override
  final String uid;
  @override
  @TimestampConverter()
  final Timestamp volunteeredAt;

  @override
  String toString() {
    return 'VolunteerIntent(uid: $uid, volunteeredAt: $volunteeredAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VolunteerIntentImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.volunteeredAt, volunteeredAt) ||
                other.volunteeredAt == volunteeredAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uid, volunteeredAt);

  /// Create a copy of VolunteerIntent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VolunteerIntentImplCopyWith<_$VolunteerIntentImpl> get copyWith =>
      __$$VolunteerIntentImplCopyWithImpl<_$VolunteerIntentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VolunteerIntentImplToJson(this);
  }
}

abstract class _VolunteerIntent implements VolunteerIntent {
  const factory _VolunteerIntent({
    required final String uid,
    @TimestampConverter() required final Timestamp volunteeredAt,
  }) = _$VolunteerIntentImpl;

  factory _VolunteerIntent.fromJson(Map<String, dynamic> json) =
      _$VolunteerIntentImpl.fromJson;

  @override
  String get uid;
  @override
  @TimestampConverter()
  Timestamp get volunteeredAt;

  /// Create a copy of VolunteerIntent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VolunteerIntentImplCopyWith<_$VolunteerIntentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoomAssignment _$RoomAssignmentFromJson(Map<String, dynamic> json) {
  return _RoomAssignment.fromJson(json);
}

/// @nodoc
mixin _$RoomAssignment {
  String? get uid => throw _privateConstructorUsedError;
  bool get fromVolunteer => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;

  /// Serializes this RoomAssignment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoomAssignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomAssignmentCopyWith<RoomAssignment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomAssignmentCopyWith<$Res> {
  factory $RoomAssignmentCopyWith(
    RoomAssignment value,
    $Res Function(RoomAssignment) then,
  ) = _$RoomAssignmentCopyWithImpl<$Res, RoomAssignment>;
  @useResult
  $Res call({String? uid, bool fromVolunteer, bool completed});
}

/// @nodoc
class _$RoomAssignmentCopyWithImpl<$Res, $Val extends RoomAssignment>
    implements $RoomAssignmentCopyWith<$Res> {
  _$RoomAssignmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomAssignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = freezed,
    Object? fromVolunteer = null,
    Object? completed = null,
  }) {
    return _then(
      _value.copyWith(
            uid: freezed == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String?,
            fromVolunteer: null == fromVolunteer
                ? _value.fromVolunteer
                : fromVolunteer // ignore: cast_nullable_to_non_nullable
                      as bool,
            completed: null == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoomAssignmentImplCopyWith<$Res>
    implements $RoomAssignmentCopyWith<$Res> {
  factory _$$RoomAssignmentImplCopyWith(
    _$RoomAssignmentImpl value,
    $Res Function(_$RoomAssignmentImpl) then,
  ) = __$$RoomAssignmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? uid, bool fromVolunteer, bool completed});
}

/// @nodoc
class __$$RoomAssignmentImplCopyWithImpl<$Res>
    extends _$RoomAssignmentCopyWithImpl<$Res, _$RoomAssignmentImpl>
    implements _$$RoomAssignmentImplCopyWith<$Res> {
  __$$RoomAssignmentImplCopyWithImpl(
    _$RoomAssignmentImpl _value,
    $Res Function(_$RoomAssignmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoomAssignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = freezed,
    Object? fromVolunteer = null,
    Object? completed = null,
  }) {
    return _then(
      _$RoomAssignmentImpl(
        uid: freezed == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String?,
        fromVolunteer: null == fromVolunteer
            ? _value.fromVolunteer
            : fromVolunteer // ignore: cast_nullable_to_non_nullable
                  as bool,
        completed: null == completed
            ? _value.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomAssignmentImpl implements _RoomAssignment {
  const _$RoomAssignmentImpl({
    this.uid,
    this.fromVolunteer = false,
    this.completed = false,
  });

  factory _$RoomAssignmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomAssignmentImplFromJson(json);

  @override
  final String? uid;
  @override
  @JsonKey()
  final bool fromVolunteer;
  @override
  @JsonKey()
  final bool completed;

  @override
  String toString() {
    return 'RoomAssignment(uid: $uid, fromVolunteer: $fromVolunteer, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomAssignmentImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.fromVolunteer, fromVolunteer) ||
                other.fromVolunteer == fromVolunteer) &&
            (identical(other.completed, completed) ||
                other.completed == completed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uid, fromVolunteer, completed);

  /// Create a copy of RoomAssignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomAssignmentImplCopyWith<_$RoomAssignmentImpl> get copyWith =>
      __$$RoomAssignmentImplCopyWithImpl<_$RoomAssignmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomAssignmentImplToJson(this);
  }
}

abstract class _RoomAssignment implements RoomAssignment {
  const factory _RoomAssignment({
    final String? uid,
    final bool fromVolunteer,
    final bool completed,
  }) = _$RoomAssignmentImpl;

  factory _RoomAssignment.fromJson(Map<String, dynamic> json) =
      _$RoomAssignmentImpl.fromJson;

  @override
  String? get uid;
  @override
  bool get fromVolunteer;
  @override
  bool get completed;

  /// Create a copy of RoomAssignment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomAssignmentImplCopyWith<_$RoomAssignmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeepClean _$DeepCleanFromJson(Map<String, dynamic> json) {
  return _DeepClean.fromJson(json);
}

/// @nodoc
mixin _$DeepClean {
  String get id => throw _privateConstructorUsedError;
  String get month => throw _privateConstructorUsedError;
  DeepCleanStatus get status => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get volunteerDeadline => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get createdAt => throw _privateConstructorUsedError;
  Map<String, List<VolunteerIntent>> get volunteerIntents =>
      throw _privateConstructorUsedError;
  Map<String, RoomAssignment> get assignments =>
      throw _privateConstructorUsedError;

  /// Serializes this DeepClean to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeepClean
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeepCleanCopyWith<DeepClean> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeepCleanCopyWith<$Res> {
  factory $DeepCleanCopyWith(DeepClean value, $Res Function(DeepClean) then) =
      _$DeepCleanCopyWithImpl<$Res, DeepClean>;
  @useResult
  $Res call({
    String id,
    String month,
    DeepCleanStatus status,
    @TimestampConverter() Timestamp volunteerDeadline,
    @TimestampConverter() Timestamp createdAt,
    Map<String, List<VolunteerIntent>> volunteerIntents,
    Map<String, RoomAssignment> assignments,
  });
}

/// @nodoc
class _$DeepCleanCopyWithImpl<$Res, $Val extends DeepClean>
    implements $DeepCleanCopyWith<$Res> {
  _$DeepCleanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeepClean
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? month = null,
    Object? status = null,
    Object? volunteerDeadline = null,
    Object? createdAt = null,
    Object? volunteerIntents = null,
    Object? assignments = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            month: null == month
                ? _value.month
                : month // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as DeepCleanStatus,
            volunteerDeadline: null == volunteerDeadline
                ? _value.volunteerDeadline
                : volunteerDeadline // ignore: cast_nullable_to_non_nullable
                      as Timestamp,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp,
            volunteerIntents: null == volunteerIntents
                ? _value.volunteerIntents
                : volunteerIntents // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<VolunteerIntent>>,
            assignments: null == assignments
                ? _value.assignments
                : assignments // ignore: cast_nullable_to_non_nullable
                      as Map<String, RoomAssignment>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeepCleanImplCopyWith<$Res>
    implements $DeepCleanCopyWith<$Res> {
  factory _$$DeepCleanImplCopyWith(
    _$DeepCleanImpl value,
    $Res Function(_$DeepCleanImpl) then,
  ) = __$$DeepCleanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String month,
    DeepCleanStatus status,
    @TimestampConverter() Timestamp volunteerDeadline,
    @TimestampConverter() Timestamp createdAt,
    Map<String, List<VolunteerIntent>> volunteerIntents,
    Map<String, RoomAssignment> assignments,
  });
}

/// @nodoc
class __$$DeepCleanImplCopyWithImpl<$Res>
    extends _$DeepCleanCopyWithImpl<$Res, _$DeepCleanImpl>
    implements _$$DeepCleanImplCopyWith<$Res> {
  __$$DeepCleanImplCopyWithImpl(
    _$DeepCleanImpl _value,
    $Res Function(_$DeepCleanImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeepClean
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? month = null,
    Object? status = null,
    Object? volunteerDeadline = null,
    Object? createdAt = null,
    Object? volunteerIntents = null,
    Object? assignments = null,
  }) {
    return _then(
      _$DeepCleanImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        month: null == month
            ? _value.month
            : month // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DeepCleanStatus,
        volunteerDeadline: null == volunteerDeadline
            ? _value.volunteerDeadline
            : volunteerDeadline // ignore: cast_nullable_to_non_nullable
                  as Timestamp,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp,
        volunteerIntents: null == volunteerIntents
            ? _value._volunteerIntents
            : volunteerIntents // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<VolunteerIntent>>,
        assignments: null == assignments
            ? _value._assignments
            : assignments // ignore: cast_nullable_to_non_nullable
                  as Map<String, RoomAssignment>,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$DeepCleanImpl implements _DeepClean {
  const _$DeepCleanImpl({
    required this.id,
    required this.month,
    required this.status,
    @TimestampConverter() required this.volunteerDeadline,
    @TimestampConverter() required this.createdAt,
    required final Map<String, List<VolunteerIntent>> volunteerIntents,
    required final Map<String, RoomAssignment> assignments,
  }) : _volunteerIntents = volunteerIntents,
       _assignments = assignments;

  factory _$DeepCleanImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeepCleanImplFromJson(json);

  @override
  final String id;
  @override
  final String month;
  @override
  final DeepCleanStatus status;
  @override
  @TimestampConverter()
  final Timestamp volunteerDeadline;
  @override
  @TimestampConverter()
  final Timestamp createdAt;
  final Map<String, List<VolunteerIntent>> _volunteerIntents;
  @override
  Map<String, List<VolunteerIntent>> get volunteerIntents {
    if (_volunteerIntents is EqualUnmodifiableMapView) return _volunteerIntents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_volunteerIntents);
  }

  final Map<String, RoomAssignment> _assignments;
  @override
  Map<String, RoomAssignment> get assignments {
    if (_assignments is EqualUnmodifiableMapView) return _assignments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_assignments);
  }

  @override
  String toString() {
    return 'DeepClean(id: $id, month: $month, status: $status, volunteerDeadline: $volunteerDeadline, createdAt: $createdAt, volunteerIntents: $volunteerIntents, assignments: $assignments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeepCleanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.volunteerDeadline, volunteerDeadline) ||
                other.volunteerDeadline == volunteerDeadline) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
              other._volunteerIntents,
              _volunteerIntents,
            ) &&
            const DeepCollectionEquality().equals(
              other._assignments,
              _assignments,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    month,
    status,
    volunteerDeadline,
    createdAt,
    const DeepCollectionEquality().hash(_volunteerIntents),
    const DeepCollectionEquality().hash(_assignments),
  );

  /// Create a copy of DeepClean
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeepCleanImplCopyWith<_$DeepCleanImpl> get copyWith =>
      __$$DeepCleanImplCopyWithImpl<_$DeepCleanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeepCleanImplToJson(this);
  }
}

abstract class _DeepClean implements DeepClean {
  const factory _DeepClean({
    required final String id,
    required final String month,
    required final DeepCleanStatus status,
    @TimestampConverter() required final Timestamp volunteerDeadline,
    @TimestampConverter() required final Timestamp createdAt,
    required final Map<String, List<VolunteerIntent>> volunteerIntents,
    required final Map<String, RoomAssignment> assignments,
  }) = _$DeepCleanImpl;

  factory _DeepClean.fromJson(Map<String, dynamic> json) =
      _$DeepCleanImpl.fromJson;

  @override
  String get id;
  @override
  String get month;
  @override
  DeepCleanStatus get status;
  @override
  @TimestampConverter()
  Timestamp get volunteerDeadline;
  @override
  @TimestampConverter()
  Timestamp get createdAt;
  @override
  Map<String, List<VolunteerIntent>> get volunteerIntents;
  @override
  Map<String, RoomAssignment> get assignments;

  /// Create a copy of DeepClean
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeepCleanImplCopyWith<_$DeepCleanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

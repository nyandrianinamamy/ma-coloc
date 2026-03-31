// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Issue _$IssueFromJson(Map<String, dynamic> json) {
  return _Issue.fromJson(json);
}

/// @nodoc
mixin _$Issue {
  String get id => throw _privateConstructorUsedError;
  IssueType get type => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  bool get anonymous => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get createdAt => throw _privateConstructorUsedError; // Assignment
  String? get assignedTo => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  Timestamp? get assignedAt => throw _privateConstructorUsedError; // Resolution
  IssueStatus get status => throw _privateConstructorUsedError;
  String? get resolvedBy => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  Timestamp? get resolvedAt => throw _privateConstructorUsedError;
  String? get resolutionPhotoUrl => throw _privateConstructorUsedError;
  String? get resolutionNote => throw _privateConstructorUsedError; // Dispute
  String? get disputedBy => throw _privateConstructorUsedError;
  String? get disputeAgainst => throw _privateConstructorUsedError;
  String? get disputeReason => throw _privateConstructorUsedError;
  Map<String, String> get reactions => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  Timestamp? get autoCloseAt => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  Timestamp? get closedAt => throw _privateConstructorUsedError; // Categorization
  List<String> get tags => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;

  /// Serializes this Issue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Issue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IssueCopyWith<Issue> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IssueCopyWith<$Res> {
  factory $IssueCopyWith(Issue value, $Res Function(Issue) then) =
      _$IssueCopyWithImpl<$Res, Issue>;
  @useResult
  $Res call({
    String id,
    IssueType type,
    String? title,
    String? description,
    String? photoUrl,
    String createdBy,
    bool anonymous,
    @TimestampConverter() Timestamp createdAt,
    String? assignedTo,
    @NullableTimestampConverter() Timestamp? assignedAt,
    IssueStatus status,
    String? resolvedBy,
    @NullableTimestampConverter() Timestamp? resolvedAt,
    String? resolutionPhotoUrl,
    String? resolutionNote,
    String? disputedBy,
    String? disputeAgainst,
    String? disputeReason,
    Map<String, String> reactions,
    @NullableTimestampConverter() Timestamp? autoCloseAt,
    @NullableTimestampConverter() Timestamp? closedAt,
    List<String> tags,
    int points,
  });
}

/// @nodoc
class _$IssueCopyWithImpl<$Res, $Val extends Issue>
    implements $IssueCopyWith<$Res> {
  _$IssueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Issue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? photoUrl = freezed,
    Object? createdBy = null,
    Object? anonymous = null,
    Object? createdAt = null,
    Object? assignedTo = freezed,
    Object? assignedAt = freezed,
    Object? status = null,
    Object? resolvedBy = freezed,
    Object? resolvedAt = freezed,
    Object? resolutionPhotoUrl = freezed,
    Object? resolutionNote = freezed,
    Object? disputedBy = freezed,
    Object? disputeAgainst = freezed,
    Object? disputeReason = freezed,
    Object? reactions = null,
    Object? autoCloseAt = freezed,
    Object? closedAt = freezed,
    Object? tags = null,
    Object? points = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as IssueType,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoUrl: freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            anonymous: null == anonymous
                ? _value.anonymous
                : anonymous // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp,
            assignedTo: freezed == assignedTo
                ? _value.assignedTo
                : assignedTo // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedAt: freezed == assignedAt
                ? _value.assignedAt
                : assignedAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as IssueStatus,
            resolvedBy: freezed == resolvedBy
                ? _value.resolvedBy
                : resolvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp?,
            resolutionPhotoUrl: freezed == resolutionPhotoUrl
                ? _value.resolutionPhotoUrl
                : resolutionPhotoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            resolutionNote: freezed == resolutionNote
                ? _value.resolutionNote
                : resolutionNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            disputedBy: freezed == disputedBy
                ? _value.disputedBy
                : disputedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            disputeAgainst: freezed == disputeAgainst
                ? _value.disputeAgainst
                : disputeAgainst // ignore: cast_nullable_to_non_nullable
                      as String?,
            disputeReason: freezed == disputeReason
                ? _value.disputeReason
                : disputeReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            reactions: null == reactions
                ? _value.reactions
                : reactions // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            autoCloseAt: freezed == autoCloseAt
                ? _value.autoCloseAt
                : autoCloseAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp?,
            closedAt: freezed == closedAt
                ? _value.closedAt
                : closedAt // ignore: cast_nullable_to_non_nullable
                      as Timestamp?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IssueImplCopyWith<$Res> implements $IssueCopyWith<$Res> {
  factory _$$IssueImplCopyWith(
    _$IssueImpl value,
    $Res Function(_$IssueImpl) then,
  ) = __$$IssueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    IssueType type,
    String? title,
    String? description,
    String? photoUrl,
    String createdBy,
    bool anonymous,
    @TimestampConverter() Timestamp createdAt,
    String? assignedTo,
    @NullableTimestampConverter() Timestamp? assignedAt,
    IssueStatus status,
    String? resolvedBy,
    @NullableTimestampConverter() Timestamp? resolvedAt,
    String? resolutionPhotoUrl,
    String? resolutionNote,
    String? disputedBy,
    String? disputeAgainst,
    String? disputeReason,
    Map<String, String> reactions,
    @NullableTimestampConverter() Timestamp? autoCloseAt,
    @NullableTimestampConverter() Timestamp? closedAt,
    List<String> tags,
    int points,
  });
}

/// @nodoc
class __$$IssueImplCopyWithImpl<$Res>
    extends _$IssueCopyWithImpl<$Res, _$IssueImpl>
    implements _$$IssueImplCopyWith<$Res> {
  __$$IssueImplCopyWithImpl(
    _$IssueImpl _value,
    $Res Function(_$IssueImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Issue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? title = freezed,
    Object? description = freezed,
    Object? photoUrl = freezed,
    Object? createdBy = null,
    Object? anonymous = null,
    Object? createdAt = null,
    Object? assignedTo = freezed,
    Object? assignedAt = freezed,
    Object? status = null,
    Object? resolvedBy = freezed,
    Object? resolvedAt = freezed,
    Object? resolutionPhotoUrl = freezed,
    Object? resolutionNote = freezed,
    Object? disputedBy = freezed,
    Object? disputeAgainst = freezed,
    Object? disputeReason = freezed,
    Object? reactions = null,
    Object? autoCloseAt = freezed,
    Object? closedAt = freezed,
    Object? tags = null,
    Object? points = null,
  }) {
    return _then(
      _$IssueImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as IssueType,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoUrl: freezed == photoUrl
            ? _value.photoUrl
            : photoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        anonymous: null == anonymous
            ? _value.anonymous
            : anonymous // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp,
        assignedTo: freezed == assignedTo
            ? _value.assignedTo
            : assignedTo // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedAt: freezed == assignedAt
            ? _value.assignedAt
            : assignedAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as IssueStatus,
        resolvedBy: freezed == resolvedBy
            ? _value.resolvedBy
            : resolvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp?,
        resolutionPhotoUrl: freezed == resolutionPhotoUrl
            ? _value.resolutionPhotoUrl
            : resolutionPhotoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        resolutionNote: freezed == resolutionNote
            ? _value.resolutionNote
            : resolutionNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        disputedBy: freezed == disputedBy
            ? _value.disputedBy
            : disputedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        disputeAgainst: freezed == disputeAgainst
            ? _value.disputeAgainst
            : disputeAgainst // ignore: cast_nullable_to_non_nullable
                  as String?,
        disputeReason: freezed == disputeReason
            ? _value.disputeReason
            : disputeReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        reactions: null == reactions
            ? _value._reactions
            : reactions // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        autoCloseAt: freezed == autoCloseAt
            ? _value.autoCloseAt
            : autoCloseAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp?,
        closedAt: freezed == closedAt
            ? _value.closedAt
            : closedAt // ignore: cast_nullable_to_non_nullable
                  as Timestamp?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IssueImpl extends _Issue {
  const _$IssueImpl({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.photoUrl,
    required this.createdBy,
    this.anonymous = false,
    @TimestampConverter() required this.createdAt,
    this.assignedTo,
    @NullableTimestampConverter() this.assignedAt,
    this.status = IssueStatus.open,
    this.resolvedBy,
    @NullableTimestampConverter() this.resolvedAt,
    this.resolutionPhotoUrl,
    this.resolutionNote,
    this.disputedBy,
    this.disputeAgainst,
    this.disputeReason,
    final Map<String, String> reactions = const {},
    @NullableTimestampConverter() this.autoCloseAt,
    @NullableTimestampConverter() this.closedAt,
    final List<String> tags = const [],
    required this.points,
  }) : _reactions = reactions,
       _tags = tags,
       super._();

  factory _$IssueImpl.fromJson(Map<String, dynamic> json) =>
      _$$IssueImplFromJson(json);

  @override
  final String id;
  @override
  final IssueType type;
  @override
  final String? title;
  @override
  final String? description;
  @override
  final String? photoUrl;
  @override
  final String createdBy;
  @override
  @JsonKey()
  final bool anonymous;
  @override
  @TimestampConverter()
  final Timestamp createdAt;
  // Assignment
  @override
  final String? assignedTo;
  @override
  @NullableTimestampConverter()
  final Timestamp? assignedAt;
  // Resolution
  @override
  @JsonKey()
  final IssueStatus status;
  @override
  final String? resolvedBy;
  @override
  @NullableTimestampConverter()
  final Timestamp? resolvedAt;
  @override
  final String? resolutionPhotoUrl;
  @override
  final String? resolutionNote;
  // Dispute
  @override
  final String? disputedBy;
  @override
  final String? disputeAgainst;
  @override
  final String? disputeReason;
  final Map<String, String> _reactions;
  @override
  @JsonKey()
  Map<String, String> get reactions {
    if (_reactions is EqualUnmodifiableMapView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_reactions);
  }

  @override
  @NullableTimestampConverter()
  final Timestamp? autoCloseAt;
  @override
  @NullableTimestampConverter()
  final Timestamp? closedAt;
  // Categorization
  final List<String> _tags;
  // Categorization
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final int points;

  @override
  String toString() {
    return 'Issue(id: $id, type: $type, title: $title, description: $description, photoUrl: $photoUrl, createdBy: $createdBy, anonymous: $anonymous, createdAt: $createdAt, assignedTo: $assignedTo, assignedAt: $assignedAt, status: $status, resolvedBy: $resolvedBy, resolvedAt: $resolvedAt, resolutionPhotoUrl: $resolutionPhotoUrl, resolutionNote: $resolutionNote, disputedBy: $disputedBy, disputeAgainst: $disputeAgainst, disputeReason: $disputeReason, reactions: $reactions, autoCloseAt: $autoCloseAt, closedAt: $closedAt, tags: $tags, points: $points)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IssueImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.anonymous, anonymous) ||
                other.anonymous == anonymous) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.assignedAt, assignedAt) ||
                other.assignedAt == assignedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.resolutionPhotoUrl, resolutionPhotoUrl) ||
                other.resolutionPhotoUrl == resolutionPhotoUrl) &&
            (identical(other.resolutionNote, resolutionNote) ||
                other.resolutionNote == resolutionNote) &&
            (identical(other.disputedBy, disputedBy) ||
                other.disputedBy == disputedBy) &&
            (identical(other.disputeAgainst, disputeAgainst) ||
                other.disputeAgainst == disputeAgainst) &&
            (identical(other.disputeReason, disputeReason) ||
                other.disputeReason == disputeReason) &&
            const DeepCollectionEquality().equals(
              other._reactions,
              _reactions,
            ) &&
            (identical(other.autoCloseAt, autoCloseAt) ||
                other.autoCloseAt == autoCloseAt) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.points, points) || other.points == points));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    type,
    title,
    description,
    photoUrl,
    createdBy,
    anonymous,
    createdAt,
    assignedTo,
    assignedAt,
    status,
    resolvedBy,
    resolvedAt,
    resolutionPhotoUrl,
    resolutionNote,
    disputedBy,
    disputeAgainst,
    disputeReason,
    const DeepCollectionEquality().hash(_reactions),
    autoCloseAt,
    closedAt,
    const DeepCollectionEquality().hash(_tags),
    points,
  ]);

  /// Create a copy of Issue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IssueImplCopyWith<_$IssueImpl> get copyWith =>
      __$$IssueImplCopyWithImpl<_$IssueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IssueImplToJson(this);
  }
}

abstract class _Issue extends Issue {
  const factory _Issue({
    required final String id,
    required final IssueType type,
    final String? title,
    final String? description,
    final String? photoUrl,
    required final String createdBy,
    final bool anonymous,
    @TimestampConverter() required final Timestamp createdAt,
    final String? assignedTo,
    @NullableTimestampConverter() final Timestamp? assignedAt,
    final IssueStatus status,
    final String? resolvedBy,
    @NullableTimestampConverter() final Timestamp? resolvedAt,
    final String? resolutionPhotoUrl,
    final String? resolutionNote,
    final String? disputedBy,
    final String? disputeAgainst,
    final String? disputeReason,
    final Map<String, String> reactions,
    @NullableTimestampConverter() final Timestamp? autoCloseAt,
    @NullableTimestampConverter() final Timestamp? closedAt,
    final List<String> tags,
    required final int points,
  }) = _$IssueImpl;
  const _Issue._() : super._();

  factory _Issue.fromJson(Map<String, dynamic> json) = _$IssueImpl.fromJson;

  @override
  String get id;
  @override
  IssueType get type;
  @override
  String? get title;
  @override
  String? get description;
  @override
  String? get photoUrl;
  @override
  String get createdBy;
  @override
  bool get anonymous;
  @override
  @TimestampConverter()
  Timestamp get createdAt; // Assignment
  @override
  String? get assignedTo;
  @override
  @NullableTimestampConverter()
  Timestamp? get assignedAt; // Resolution
  @override
  IssueStatus get status;
  @override
  String? get resolvedBy;
  @override
  @NullableTimestampConverter()
  Timestamp? get resolvedAt;
  @override
  String? get resolutionPhotoUrl;
  @override
  String? get resolutionNote; // Dispute
  @override
  String? get disputedBy;
  @override
  String? get disputeAgainst;
  @override
  String? get disputeReason;
  @override
  Map<String, String> get reactions;
  @override
  @NullableTimestampConverter()
  Timestamp? get autoCloseAt;
  @override
  @NullableTimestampConverter()
  Timestamp? get closedAt; // Categorization
  @override
  List<String> get tags;
  @override
  int get points;

  /// Create a copy of Issue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IssueImplCopyWith<_$IssueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

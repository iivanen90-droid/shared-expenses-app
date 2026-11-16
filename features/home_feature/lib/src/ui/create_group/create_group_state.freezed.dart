// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_group_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateGroupState {
  String get emoji;
  String get name;
  GroupCurrency? get currency;
  List<ParticipantDraft> get participants;
  bool get showValidationErrors;
  CreateGroupStatus get status;
  int? get groupId;

  /// Create a copy of CreateGroupState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CreateGroupStateCopyWith<CreateGroupState> get copyWith =>
      _$CreateGroupStateCopyWithImpl<CreateGroupState>(this as CreateGroupState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CreateGroupState &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.currency, currency) || other.currency == currency) &&
            const DeepCollectionEquality().equals(other.participants, participants) &&
            (identical(other.showValidationErrors, showValidationErrors) ||
                other.showValidationErrors == showValidationErrors) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    emoji,
    name,
    currency,
    const DeepCollectionEquality().hash(participants),
    showValidationErrors,
    status,
    groupId,
  );

  @override
  String toString() {
    return 'CreateGroupState(emoji: $emoji, name: $name, currency: $currency, participants: $participants, showValidationErrors: $showValidationErrors, status: $status, groupId: $groupId)';
  }
}

/// @nodoc
abstract mixin class $CreateGroupStateCopyWith<$Res> {
  factory $CreateGroupStateCopyWith(CreateGroupState value, $Res Function(CreateGroupState) _then) =
      _$CreateGroupStateCopyWithImpl;
  @useResult
  $Res call({
    String emoji,
    String name,
    GroupCurrency? currency,
    List<ParticipantDraft> participants,
    bool showValidationErrors,
    CreateGroupStatus status,
    int? groupId,
  });
}

/// @nodoc
class _$CreateGroupStateCopyWithImpl<$Res> implements $CreateGroupStateCopyWith<$Res> {
  _$CreateGroupStateCopyWithImpl(this._self, this._then);

  final CreateGroupState _self;
  final $Res Function(CreateGroupState) _then;

  /// Create a copy of CreateGroupState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? emoji = null,
    Object? name = null,
    Object? currency = freezed,
    Object? participants = null,
    Object? showValidationErrors = null,
    Object? status = null,
    Object? groupId = freezed,
  }) {
    return _then(
      _self.copyWith(
        emoji: null == emoji
            ? _self.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: freezed == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as GroupCurrency?,
        participants: null == participants
            ? _self.participants
            : participants // ignore: cast_nullable_to_non_nullable
                  as List<ParticipantDraft>,
        showValidationErrors: null == showValidationErrors
            ? _self.showValidationErrors
            : showValidationErrors // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as CreateGroupStatus,
        groupId: freezed == groupId
            ? _self.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CreateGroupState].
extension CreateGroupStatePatterns on CreateGroupState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CreateGroupState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CreateGroupState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(TResult Function(_CreateGroupState value) $default) {
    final _that = this;
    switch (_that) {
      case _CreateGroupState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(TResult? Function(_CreateGroupState value)? $default) {
    final _that = this;
    switch (_that) {
      case _CreateGroupState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String emoji,
      String name,
      GroupCurrency? currency,
      List<ParticipantDraft> participants,
      bool showValidationErrors,
      CreateGroupStatus status,
      int? groupId,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CreateGroupState() when $default != null:
        return $default(
          _that.emoji,
          _that.name,
          _that.currency,
          _that.participants,
          _that.showValidationErrors,
          _that.status,
          _that.groupId,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String emoji,
      String name,
      GroupCurrency? currency,
      List<ParticipantDraft> participants,
      bool showValidationErrors,
      CreateGroupStatus status,
      int? groupId,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateGroupState():
        return $default(
          _that.emoji,
          _that.name,
          _that.currency,
          _that.participants,
          _that.showValidationErrors,
          _that.status,
          _that.groupId,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String emoji,
      String name,
      GroupCurrency? currency,
      List<ParticipantDraft> participants,
      bool showValidationErrors,
      CreateGroupStatus status,
      int? groupId,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateGroupState() when $default != null:
        return $default(
          _that.emoji,
          _that.name,
          _that.currency,
          _that.participants,
          _that.showValidationErrors,
          _that.status,
          _that.groupId,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CreateGroupState extends CreateGroupState {
  const _CreateGroupState({
    this.emoji = '\u{1f4b8}',
    this.name = '',
    this.currency,
    this.participants = const <ParticipantDraft>[],
    this.showValidationErrors = false,
    this.status = CreateGroupStatus.idle,
    this.groupId,
  }) : super._();

  @override
  @JsonKey()
  final String emoji;
  @override
  @JsonKey()
  final String name;
  @override
  final GroupCurrency? currency;
  @override
  @JsonKey()
  final List<ParticipantDraft> participants;
  @override
  @JsonKey()
  final bool showValidationErrors;
  @override
  @JsonKey()
  final CreateGroupStatus status;
  @override
  final int? groupId;

  /// Create a copy of CreateGroupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CreateGroupStateCopyWith<_CreateGroupState> get copyWith =>
      __$CreateGroupStateCopyWithImpl<_CreateGroupState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CreateGroupState &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.currency, currency) || other.currency == currency) &&
            const DeepCollectionEquality().equals(other.participants, participants) &&
            (identical(other.showValidationErrors, showValidationErrors) ||
                other.showValidationErrors == showValidationErrors) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    emoji,
    name,
    currency,
    const DeepCollectionEquality().hash(participants),
    showValidationErrors,
    status,
    groupId,
  );

  @override
  String toString() {
    return 'CreateGroupState(emoji: $emoji, name: $name, currency: $currency, participants: $participants, showValidationErrors: $showValidationErrors, status: $status, groupId: $groupId)';
  }
}

/// @nodoc
abstract mixin class _$CreateGroupStateCopyWith<$Res> implements $CreateGroupStateCopyWith<$Res> {
  factory _$CreateGroupStateCopyWith(_CreateGroupState value, $Res Function(_CreateGroupState) _then) =
      __$CreateGroupStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    String emoji,
    String name,
    GroupCurrency? currency,
    List<ParticipantDraft> participants,
    bool showValidationErrors,
    CreateGroupStatus status,
    int? groupId,
  });
}

/// @nodoc
class __$CreateGroupStateCopyWithImpl<$Res> implements _$CreateGroupStateCopyWith<$Res> {
  __$CreateGroupStateCopyWithImpl(this._self, this._then);

  final _CreateGroupState _self;
  final $Res Function(_CreateGroupState) _then;

  /// Create a copy of CreateGroupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? emoji = null,
    Object? name = null,
    Object? currency = freezed,
    Object? participants = null,
    Object? showValidationErrors = null,
    Object? status = null,
    Object? groupId = freezed,
  }) {
    return _then(
      _CreateGroupState(
        emoji: null == emoji
            ? _self.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: freezed == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as GroupCurrency?,
        participants: null == participants
            ? _self.participants
            : participants // ignore: cast_nullable_to_non_nullable
                  as List<ParticipantDraft>,
        showValidationErrors: null == showValidationErrors
            ? _self.showValidationErrors
            : showValidationErrors // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as CreateGroupStatus,
        groupId: freezed == groupId
            ? _self.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

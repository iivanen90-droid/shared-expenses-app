// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_details_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupDetailsState {
  GroupDetailsStatus get status;
  HomeGroup? get group;

  /// Create a copy of GroupDetailsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupDetailsStateCopyWith<GroupDetailsState> get copyWith =>
      _$GroupDetailsStateCopyWithImpl<GroupDetailsState>(this as GroupDetailsState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupDetailsState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.group, group) || other.group == group));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, group);

  @override
  String toString() {
    return 'GroupDetailsState(status: $status, group: $group)';
  }
}

/// @nodoc
abstract mixin class $GroupDetailsStateCopyWith<$Res> {
  factory $GroupDetailsStateCopyWith(GroupDetailsState value, $Res Function(GroupDetailsState) _then) =
      _$GroupDetailsStateCopyWithImpl;
  @useResult
  $Res call({GroupDetailsStatus status, HomeGroup? group});
}

/// @nodoc
class _$GroupDetailsStateCopyWithImpl<$Res> implements $GroupDetailsStateCopyWith<$Res> {
  _$GroupDetailsStateCopyWithImpl(this._self, this._then);

  final GroupDetailsState _self;
  final $Res Function(GroupDetailsState) _then;

  /// Create a copy of GroupDetailsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? status = null, Object? group = freezed}) {
    return _then(
      _self.copyWith(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GroupDetailsStatus,
        group: freezed == group
            ? _self.group
            : group // ignore: cast_nullable_to_non_nullable
                  as HomeGroup?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [GroupDetailsState].
extension GroupDetailsStatePatterns on GroupDetailsState {
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
    TResult Function(_GroupDetailsState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupDetailsState() when $default != null:
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
  TResult map<TResult extends Object?>(TResult Function(_GroupDetailsState value) $default) {
    final _that = this;
    switch (_that) {
      case _GroupDetailsState():
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
  TResult? mapOrNull<TResult extends Object?>(TResult? Function(_GroupDetailsState value)? $default) {
    final _that = this;
    switch (_that) {
      case _GroupDetailsState() when $default != null:
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
    TResult Function(GroupDetailsStatus status, HomeGroup? group)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupDetailsState() when $default != null:
        return $default(_that.status, _that.group);
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
  TResult when<TResult extends Object?>(TResult Function(GroupDetailsStatus status, HomeGroup? group) $default) {
    final _that = this;
    switch (_that) {
      case _GroupDetailsState():
        return $default(_that.status, _that.group);
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
    TResult? Function(GroupDetailsStatus status, HomeGroup? group)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupDetailsState() when $default != null:
        return $default(_that.status, _that.group);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _GroupDetailsState implements GroupDetailsState {
  const _GroupDetailsState({this.status = GroupDetailsStatus.loading, this.group});

  @override
  @JsonKey()
  final GroupDetailsStatus status;
  @override
  final HomeGroup? group;

  /// Create a copy of GroupDetailsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupDetailsStateCopyWith<_GroupDetailsState> get copyWith =>
      __$GroupDetailsStateCopyWithImpl<_GroupDetailsState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupDetailsState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.group, group) || other.group == group));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, group);

  @override
  String toString() {
    return 'GroupDetailsState(status: $status, group: $group)';
  }
}

/// @nodoc
abstract mixin class _$GroupDetailsStateCopyWith<$Res> implements $GroupDetailsStateCopyWith<$Res> {
  factory _$GroupDetailsStateCopyWith(_GroupDetailsState value, $Res Function(_GroupDetailsState) _then) =
      __$GroupDetailsStateCopyWithImpl;
  @override
  @useResult
  $Res call({GroupDetailsStatus status, HomeGroup? group});
}

/// @nodoc
class __$GroupDetailsStateCopyWithImpl<$Res> implements _$GroupDetailsStateCopyWith<$Res> {
  __$GroupDetailsStateCopyWithImpl(this._self, this._then);

  final _GroupDetailsState _self;
  final $Res Function(_GroupDetailsState) _then;

  /// Create a copy of GroupDetailsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? status = null, Object? group = freezed}) {
    return _then(
      _GroupDetailsState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GroupDetailsStatus,
        group: freezed == group
            ? _self.group
            : group // ignore: cast_nullable_to_non_nullable
                  as HomeGroup?,
      ),
    );
  }
}

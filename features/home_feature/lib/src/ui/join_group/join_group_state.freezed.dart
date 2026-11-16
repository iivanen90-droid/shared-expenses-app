// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_group_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoinGroupState {
  JoinGroupStatus get status;

  /// Create a copy of JoinGroupState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JoinGroupStateCopyWith<JoinGroupState> get copyWith =>
      _$JoinGroupStateCopyWithImpl<JoinGroupState>(this as JoinGroupState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JoinGroupState &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status);

  @override
  String toString() {
    return 'JoinGroupState(status: $status)';
  }
}

/// @nodoc
abstract mixin class $JoinGroupStateCopyWith<$Res> {
  factory $JoinGroupStateCopyWith(JoinGroupState value, $Res Function(JoinGroupState) _then) =
      _$JoinGroupStateCopyWithImpl;
  @useResult
  $Res call({JoinGroupStatus status});
}

/// @nodoc
class _$JoinGroupStateCopyWithImpl<$Res> implements $JoinGroupStateCopyWith<$Res> {
  _$JoinGroupStateCopyWithImpl(this._self, this._then);

  final JoinGroupState _self;
  final $Res Function(JoinGroupState) _then;

  /// Create a copy of JoinGroupState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? status = null}) {
    return _then(
      _self.copyWith(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as JoinGroupStatus,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [JoinGroupState].
extension JoinGroupStatePatterns on JoinGroupState {
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
    TResult Function(_JoinGroupState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JoinGroupState() when $default != null:
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
  TResult map<TResult extends Object?>(TResult Function(_JoinGroupState value) $default) {
    final _that = this;
    switch (_that) {
      case _JoinGroupState():
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
  TResult? mapOrNull<TResult extends Object?>(TResult? Function(_JoinGroupState value)? $default) {
    final _that = this;
    switch (_that) {
      case _JoinGroupState() when $default != null:
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
    TResult Function(JoinGroupStatus status)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _JoinGroupState() when $default != null:
        return $default(_that.status);
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
  TResult when<TResult extends Object?>(TResult Function(JoinGroupStatus status) $default) {
    final _that = this;
    switch (_that) {
      case _JoinGroupState():
        return $default(_that.status);
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
  TResult? whenOrNull<TResult extends Object?>(TResult? Function(JoinGroupStatus status)? $default) {
    final _that = this;
    switch (_that) {
      case _JoinGroupState() when $default != null:
        return $default(_that.status);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _JoinGroupState extends JoinGroupState {
  const _JoinGroupState({this.status = JoinGroupStatus.empty}) : super._();

  @override
  @JsonKey()
  final JoinGroupStatus status;

  /// Create a copy of JoinGroupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JoinGroupStateCopyWith<_JoinGroupState> get copyWith =>
      __$JoinGroupStateCopyWithImpl<_JoinGroupState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JoinGroupState &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status);

  @override
  String toString() {
    return 'JoinGroupState(status: $status)';
  }
}

/// @nodoc
abstract mixin class _$JoinGroupStateCopyWith<$Res> implements $JoinGroupStateCopyWith<$Res> {
  factory _$JoinGroupStateCopyWith(_JoinGroupState value, $Res Function(_JoinGroupState) _then) =
      __$JoinGroupStateCopyWithImpl;
  @override
  @useResult
  $Res call({JoinGroupStatus status});
}

/// @nodoc
class __$JoinGroupStateCopyWithImpl<$Res> implements _$JoinGroupStateCopyWith<$Res> {
  __$JoinGroupStateCopyWithImpl(this._self, this._then);

  final _JoinGroupState _self;
  final $Res Function(_JoinGroupState) _then;

  /// Create a copy of JoinGroupState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? status = null}) {
    return _then(
      _JoinGroupState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as JoinGroupStatus,
      ),
    );
  }
}

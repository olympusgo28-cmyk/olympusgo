// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingCode {

 CodeChannel get channel; String get destination;
/// Create a copy of PendingCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingCodeCopyWith<PendingCode> get copyWith => _$PendingCodeCopyWithImpl<PendingCode>(this as PendingCode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PendingCode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingCode&&(identical(other.channel, _this.channel) || other.channel == _this.channel)&&(identical(other.destination, _this.destination) || other.destination == _this.destination));
}


@override
int get hashCode {
  final _this = this as PendingCode;
  return Object.hash(runtimeType,_this.channel,_this.destination);
}

@override
String toString() {
  final _this = this as PendingCode;
  return 'PendingCode(channel: ${_this.channel}, destination: ${_this.destination})';
}


}

/// @nodoc
abstract mixin class $PendingCodeCopyWith<$Res>  {
  factory $PendingCodeCopyWith(PendingCode value, $Res Function(PendingCode) _then) = _$PendingCodeCopyWithImpl;
@useResult
$Res call({
 CodeChannel channel, String destination
});




}
/// @nodoc
class _$PendingCodeCopyWithImpl<$Res>
    implements $PendingCodeCopyWith<$Res> {
  _$PendingCodeCopyWithImpl(this._self, this._then);

  final PendingCode _self;
  final $Res Function(PendingCode) _then;

/// Create a copy of PendingCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channel = null,Object? destination = null,}) {
  return _then(PendingCode(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as CodeChannel,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingCode].
extension PendingCodePatterns on PendingCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingCode() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingCode value)  $default,){
final _that = this;
switch (_that) {
case _PendingCode():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingCode value)?  $default,){
final _that = this;
switch (_that) {
case _PendingCode() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CodeChannel channel,  String destination)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingCode() when $default != null:
return $default(_that.channel,_that.destination);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CodeChannel channel,  String destination)  $default,) {final _that = this;
switch (_that) {
case _PendingCode():
return $default(_that.channel,_that.destination);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CodeChannel channel,  String destination)?  $default,) {final _that = this;
switch (_that) {
case _PendingCode() when $default != null:
return $default(_that.channel,_that.destination);case _:
  return null;

}
}

}

/// @nodoc


class _PendingCode implements PendingCode {
  const _PendingCode({required this.channel, required this.destination});
  

@override final  CodeChannel channel;
@override final  String destination;

/// Create a copy of PendingCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingCodeCopyWith<_PendingCode> get copyWith => __$PendingCodeCopyWithImpl<_PendingCode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingCode&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode {
    return Object.hash(runtimeType,channel,destination);
}

@override
String toString() {
    return 'PendingCode(channel: $channel, destination: $destination)';
}


}

/// @nodoc
abstract mixin class _$PendingCodeCopyWith<$Res> implements $PendingCodeCopyWith<$Res> {
  factory _$PendingCodeCopyWith(_PendingCode value, $Res Function(_PendingCode) _then) = __$PendingCodeCopyWithImpl;
@override @useResult
$Res call({
 CodeChannel channel, String destination
});




}
/// @nodoc
class __$PendingCodeCopyWithImpl<$Res>
    implements _$PendingCodeCopyWith<$Res> {
  __$PendingCodeCopyWithImpl(this._self, this._then);

  final _PendingCode _self;
  final $Res Function(_PendingCode) _then;

/// Create a copy of PendingCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channel = null,Object? destination = null,}) {
  return _then(_PendingCode(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as CodeChannel,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

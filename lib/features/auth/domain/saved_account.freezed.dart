// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedAccount {

 String get userId; String get displayName; String? get avatarUrl; String get maskedIdentifier;
/// Create a copy of SavedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedAccountCopyWith<SavedAccount> get copyWith => _$SavedAccountCopyWithImpl<SavedAccount>(this as SavedAccount, _$identity);

  /// Serializes this SavedAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SavedAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedAccount&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.maskedIdentifier, _this.maskedIdentifier) || other.maskedIdentifier == _this.maskedIdentifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SavedAccount;
  return Object.hash(runtimeType,_this.userId,_this.displayName,_this.avatarUrl,_this.maskedIdentifier);
}

@override
String toString() {
  final _this = this as SavedAccount;
  return 'SavedAccount(userId: ${_this.userId}, displayName: ${_this.displayName}, avatarUrl: ${_this.avatarUrl}, maskedIdentifier: ${_this.maskedIdentifier})';
}


}

/// @nodoc
abstract mixin class $SavedAccountCopyWith<$Res>  {
  factory $SavedAccountCopyWith(SavedAccount value, $Res Function(SavedAccount) _then) = _$SavedAccountCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String? avatarUrl, String maskedIdentifier
});




}
/// @nodoc
class _$SavedAccountCopyWithImpl<$Res>
    implements $SavedAccountCopyWith<$Res> {
  _$SavedAccountCopyWithImpl(this._self, this._then);

  final SavedAccount _self;
  final $Res Function(SavedAccount) _then;

/// Create a copy of SavedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? avatarUrl = freezed,Object? maskedIdentifier = null,}) {
  return _then(SavedAccount(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,maskedIdentifier: null == maskedIdentifier ? _self.maskedIdentifier : maskedIdentifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedAccount].
extension SavedAccountPatterns on SavedAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedAccount value)  $default,){
final _that = this;
switch (_that) {
case _SavedAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _SavedAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String? avatarUrl,  String maskedIdentifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedAccount() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarUrl,_that.maskedIdentifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String? avatarUrl,  String maskedIdentifier)  $default,) {final _that = this;
switch (_that) {
case _SavedAccount():
return $default(_that.userId,_that.displayName,_that.avatarUrl,_that.maskedIdentifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String? avatarUrl,  String maskedIdentifier)?  $default,) {final _that = this;
switch (_that) {
case _SavedAccount() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarUrl,_that.maskedIdentifier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedAccount implements SavedAccount {
  const _SavedAccount({required this.userId, required this.displayName, this.avatarUrl, required this.maskedIdentifier});
  factory _SavedAccount.fromJson(Map<String, dynamic> json) => _$SavedAccountFromJson(json);

@override final  String userId;
@override final  String displayName;
@override final  String? avatarUrl;
@override final  String maskedIdentifier;

/// Create a copy of SavedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedAccountCopyWith<_SavedAccount> get copyWith => __$SavedAccountCopyWithImpl<_SavedAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedAccount&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.maskedIdentifier, maskedIdentifier) || other.maskedIdentifier == maskedIdentifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,displayName,avatarUrl,maskedIdentifier);
}

@override
String toString() {
    return 'SavedAccount(userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, maskedIdentifier: $maskedIdentifier)';
}


}

/// @nodoc
abstract mixin class _$SavedAccountCopyWith<$Res> implements $SavedAccountCopyWith<$Res> {
  factory _$SavedAccountCopyWith(_SavedAccount value, $Res Function(_SavedAccount) _then) = __$SavedAccountCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String? avatarUrl, String maskedIdentifier
});




}
/// @nodoc
class __$SavedAccountCopyWithImpl<$Res>
    implements _$SavedAccountCopyWith<$Res> {
  __$SavedAccountCopyWithImpl(this._self, this._then);

  final _SavedAccount _self;
  final $Res Function(_SavedAccount) _then;

/// Create a copy of SavedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? avatarUrl = freezed,Object? maskedIdentifier = null,}) {
  return _then(_SavedAccount(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,maskedIdentifier: null == maskedIdentifier ? _self.maskedIdentifier : maskedIdentifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

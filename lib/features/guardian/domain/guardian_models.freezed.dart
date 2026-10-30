// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guardian_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Restrictions {

 String get audience; bool get restricted; bool get suspended; bool get pendingParent; bool get canScan; bool get canChat; bool get canDiscover; bool get canShop; bool get canHost;
/// Create a copy of Restrictions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestrictionsCopyWith<Restrictions> get copyWith => _$RestrictionsCopyWithImpl<Restrictions>(this as Restrictions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Restrictions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Restrictions&&(identical(other.audience, _this.audience) || other.audience == _this.audience)&&(identical(other.restricted, _this.restricted) || other.restricted == _this.restricted)&&(identical(other.suspended, _this.suspended) || other.suspended == _this.suspended)&&(identical(other.pendingParent, _this.pendingParent) || other.pendingParent == _this.pendingParent)&&(identical(other.canScan, _this.canScan) || other.canScan == _this.canScan)&&(identical(other.canChat, _this.canChat) || other.canChat == _this.canChat)&&(identical(other.canDiscover, _this.canDiscover) || other.canDiscover == _this.canDiscover)&&(identical(other.canShop, _this.canShop) || other.canShop == _this.canShop)&&(identical(other.canHost, _this.canHost) || other.canHost == _this.canHost));
}


@override
int get hashCode {
  final _this = this as Restrictions;
  return Object.hash(runtimeType,_this.audience,_this.restricted,_this.suspended,_this.pendingParent,_this.canScan,_this.canChat,_this.canDiscover,_this.canShop,_this.canHost);
}

@override
String toString() {
  final _this = this as Restrictions;
  return 'Restrictions(audience: ${_this.audience}, restricted: ${_this.restricted}, suspended: ${_this.suspended}, pendingParent: ${_this.pendingParent}, canScan: ${_this.canScan}, canChat: ${_this.canChat}, canDiscover: ${_this.canDiscover}, canShop: ${_this.canShop}, canHost: ${_this.canHost})';
}


}

/// @nodoc
abstract mixin class $RestrictionsCopyWith<$Res>  {
  factory $RestrictionsCopyWith(Restrictions value, $Res Function(Restrictions) _then) = _$RestrictionsCopyWithImpl;
@useResult
$Res call({
 String audience, bool restricted, bool suspended, bool pendingParent, bool canScan, bool canChat, bool canDiscover, bool canShop, bool canHost
});




}
/// @nodoc
class _$RestrictionsCopyWithImpl<$Res>
    implements $RestrictionsCopyWith<$Res> {
  _$RestrictionsCopyWithImpl(this._self, this._then);

  final Restrictions _self;
  final $Res Function(Restrictions) _then;

/// Create a copy of Restrictions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audience = null,Object? restricted = null,Object? suspended = null,Object? pendingParent = null,Object? canScan = null,Object? canChat = null,Object? canDiscover = null,Object? canShop = null,Object? canHost = null,}) {
  return _then(Restrictions(
audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as String,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,suspended: null == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool,pendingParent: null == pendingParent ? _self.pendingParent : pendingParent // ignore: cast_nullable_to_non_nullable
as bool,canScan: null == canScan ? _self.canScan : canScan // ignore: cast_nullable_to_non_nullable
as bool,canChat: null == canChat ? _self.canChat : canChat // ignore: cast_nullable_to_non_nullable
as bool,canDiscover: null == canDiscover ? _self.canDiscover : canDiscover // ignore: cast_nullable_to_non_nullable
as bool,canShop: null == canShop ? _self.canShop : canShop // ignore: cast_nullable_to_non_nullable
as bool,canHost: null == canHost ? _self.canHost : canHost // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Restrictions].
extension RestrictionsPatterns on Restrictions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Restrictions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Restrictions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Restrictions value)  $default,){
final _that = this;
switch (_that) {
case _Restrictions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Restrictions value)?  $default,){
final _that = this;
switch (_that) {
case _Restrictions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String audience,  bool restricted,  bool suspended,  bool pendingParent,  bool canScan,  bool canChat,  bool canDiscover,  bool canShop,  bool canHost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Restrictions() when $default != null:
return $default(_that.audience,_that.restricted,_that.suspended,_that.pendingParent,_that.canScan,_that.canChat,_that.canDiscover,_that.canShop,_that.canHost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String audience,  bool restricted,  bool suspended,  bool pendingParent,  bool canScan,  bool canChat,  bool canDiscover,  bool canShop,  bool canHost)  $default,) {final _that = this;
switch (_that) {
case _Restrictions():
return $default(_that.audience,_that.restricted,_that.suspended,_that.pendingParent,_that.canScan,_that.canChat,_that.canDiscover,_that.canShop,_that.canHost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String audience,  bool restricted,  bool suspended,  bool pendingParent,  bool canScan,  bool canChat,  bool canDiscover,  bool canShop,  bool canHost)?  $default,) {final _that = this;
switch (_that) {
case _Restrictions() when $default != null:
return $default(_that.audience,_that.restricted,_that.suspended,_that.pendingParent,_that.canScan,_that.canChat,_that.canDiscover,_that.canShop,_that.canHost);case _:
  return null;

}
}

}

/// @nodoc


class _Restrictions extends Restrictions {
  const _Restrictions({this.audience = 'adult', this.restricted = false, this.suspended = false, this.pendingParent = false, this.canScan = true, this.canChat = true, this.canDiscover = true, this.canShop = true, this.canHost = true}): super._();
  

@override@JsonKey() final  String audience;
@override@JsonKey() final  bool restricted;
@override@JsonKey() final  bool suspended;
@override@JsonKey() final  bool pendingParent;
@override@JsonKey() final  bool canScan;
@override@JsonKey() final  bool canChat;
@override@JsonKey() final  bool canDiscover;
@override@JsonKey() final  bool canShop;
@override@JsonKey() final  bool canHost;

/// Create a copy of Restrictions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestrictionsCopyWith<_Restrictions> get copyWith => __$RestrictionsCopyWithImpl<_Restrictions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Restrictions&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.restricted, restricted) || other.restricted == restricted)&&(identical(other.suspended, suspended) || other.suspended == suspended)&&(identical(other.pendingParent, pendingParent) || other.pendingParent == pendingParent)&&(identical(other.canScan, canScan) || other.canScan == canScan)&&(identical(other.canChat, canChat) || other.canChat == canChat)&&(identical(other.canDiscover, canDiscover) || other.canDiscover == canDiscover)&&(identical(other.canShop, canShop) || other.canShop == canShop)&&(identical(other.canHost, canHost) || other.canHost == canHost));
}


@override
int get hashCode {
    return Object.hash(runtimeType,audience,restricted,suspended,pendingParent,canScan,canChat,canDiscover,canShop,canHost);
}

@override
String toString() {
    return 'Restrictions(audience: $audience, restricted: $restricted, suspended: $suspended, pendingParent: $pendingParent, canScan: $canScan, canChat: $canChat, canDiscover: $canDiscover, canShop: $canShop, canHost: $canHost)';
}


}

/// @nodoc
abstract mixin class _$RestrictionsCopyWith<$Res> implements $RestrictionsCopyWith<$Res> {
  factory _$RestrictionsCopyWith(_Restrictions value, $Res Function(_Restrictions) _then) = __$RestrictionsCopyWithImpl;
@override @useResult
$Res call({
 String audience, bool restricted, bool suspended, bool pendingParent, bool canScan, bool canChat, bool canDiscover, bool canShop, bool canHost
});




}
/// @nodoc
class __$RestrictionsCopyWithImpl<$Res>
    implements _$RestrictionsCopyWith<$Res> {
  __$RestrictionsCopyWithImpl(this._self, this._then);

  final _Restrictions _self;
  final $Res Function(_Restrictions) _then;

/// Create a copy of Restrictions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? audience = null,Object? restricted = null,Object? suspended = null,Object? pendingParent = null,Object? canScan = null,Object? canChat = null,Object? canDiscover = null,Object? canShop = null,Object? canHost = null,}) {
  return _then(_Restrictions(
audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as String,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,suspended: null == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool,pendingParent: null == pendingParent ? _self.pendingParent : pendingParent // ignore: cast_nullable_to_non_nullable
as bool,canScan: null == canScan ? _self.canScan : canScan // ignore: cast_nullable_to_non_nullable
as bool,canChat: null == canChat ? _self.canChat : canChat // ignore: cast_nullable_to_non_nullable
as bool,canDiscover: null == canDiscover ? _self.canDiscover : canDiscover // ignore: cast_nullable_to_non_nullable
as bool,canShop: null == canShop ? _self.canShop : canShop // ignore: cast_nullable_to_non_nullable
as bool,canHost: null == canHost ? _self.canHost : canHost // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ParentCode {

 String get code; DateTime get expiresAt;
/// Create a copy of ParentCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParentCodeCopyWith<ParentCode> get copyWith => _$ParentCodeCopyWithImpl<ParentCode>(this as ParentCode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ParentCode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParentCode&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}


@override
int get hashCode {
  final _this = this as ParentCode;
  return Object.hash(runtimeType,_this.code,_this.expiresAt);
}

@override
String toString() {
  final _this = this as ParentCode;
  return 'ParentCode(code: ${_this.code}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $ParentCodeCopyWith<$Res>  {
  factory $ParentCodeCopyWith(ParentCode value, $Res Function(ParentCode) _then) = _$ParentCodeCopyWithImpl;
@useResult
$Res call({
 String code, DateTime expiresAt
});




}
/// @nodoc
class _$ParentCodeCopyWithImpl<$Res>
    implements $ParentCodeCopyWith<$Res> {
  _$ParentCodeCopyWithImpl(this._self, this._then);

  final ParentCode _self;
  final $Res Function(ParentCode) _then;

/// Create a copy of ParentCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? expiresAt = null,}) {
  return _then(ParentCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ParentCode].
extension ParentCodePatterns on ParentCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParentCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParentCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParentCode value)  $default,){
final _that = this;
switch (_that) {
case _ParentCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParentCode value)?  $default,){
final _that = this;
switch (_that) {
case _ParentCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParentCode() when $default != null:
return $default(_that.code,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ParentCode():
return $default(_that.code,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ParentCode() when $default != null:
return $default(_that.code,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _ParentCode implements ParentCode {
  const _ParentCode({required this.code, required this.expiresAt});
  

@override final  String code;
@override final  DateTime expiresAt;

/// Create a copy of ParentCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParentCodeCopyWith<_ParentCode> get copyWith => __$ParentCodeCopyWithImpl<_ParentCode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParentCode&&(identical(other.code, code) || other.code == code)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,expiresAt);
}

@override
String toString() {
    return 'ParentCode(code: $code, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ParentCodeCopyWith<$Res> implements $ParentCodeCopyWith<$Res> {
  factory _$ParentCodeCopyWith(_ParentCode value, $Res Function(_ParentCode) _then) = __$ParentCodeCopyWithImpl;
@override @useResult
$Res call({
 String code, DateTime expiresAt
});




}
/// @nodoc
class __$ParentCodeCopyWithImpl<$Res>
    implements _$ParentCodeCopyWith<$Res> {
  __$ParentCodeCopyWithImpl(this._self, this._then);

  final _ParentCode _self;
  final $Res Function(_ParentCode) _then;

/// Create a copy of ParentCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? expiresAt = null,}) {
  return _then(_ParentCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$GuardianLink {

 String get linkId; String get name; LinkStatus get status; String? get childId; String? get avatarUrl;
/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuardianLinkCopyWith<GuardianLink> get copyWith => _$GuardianLinkCopyWithImpl<GuardianLink>(this as GuardianLink, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GuardianLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuardianLink&&(identical(other.linkId, _this.linkId) || other.linkId == _this.linkId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.childId, _this.childId) || other.childId == _this.childId)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}


@override
int get hashCode {
  final _this = this as GuardianLink;
  return Object.hash(runtimeType,_this.linkId,_this.name,_this.status,_this.childId,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as GuardianLink;
  return 'GuardianLink(linkId: ${_this.linkId}, name: ${_this.name}, status: ${_this.status}, childId: ${_this.childId}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $GuardianLinkCopyWith<$Res>  {
  factory $GuardianLinkCopyWith(GuardianLink value, $Res Function(GuardianLink) _then) = _$GuardianLinkCopyWithImpl;
@useResult
$Res call({
 String linkId, String name, LinkStatus status, String? childId, String? avatarUrl
});




}
/// @nodoc
class _$GuardianLinkCopyWithImpl<$Res>
    implements $GuardianLinkCopyWith<$Res> {
  _$GuardianLinkCopyWithImpl(this._self, this._then);

  final GuardianLink _self;
  final $Res Function(GuardianLink) _then;

/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? linkId = null,Object? name = null,Object? status = null,Object? childId = freezed,Object? avatarUrl = freezed,}) {
  return _then(GuardianLink(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LinkStatus,childId: freezed == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuardianLink].
extension GuardianLinkPatterns on GuardianLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuardianLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuardianLink value)  $default,){
final _that = this;
switch (_that) {
case _GuardianLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuardianLink value)?  $default,){
final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String linkId,  String name,  LinkStatus status,  String? childId,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
return $default(_that.linkId,_that.name,_that.status,_that.childId,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String linkId,  String name,  LinkStatus status,  String? childId,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _GuardianLink():
return $default(_that.linkId,_that.name,_that.status,_that.childId,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String linkId,  String name,  LinkStatus status,  String? childId,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
return $default(_that.linkId,_that.name,_that.status,_that.childId,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _GuardianLink implements GuardianLink {
  const _GuardianLink({required this.linkId, required this.name, required this.status, this.childId, this.avatarUrl});
  

@override final  String linkId;
@override final  String name;
@override final  LinkStatus status;
@override final  String? childId;
@override final  String? avatarUrl;

/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuardianLinkCopyWith<_GuardianLink> get copyWith => __$GuardianLinkCopyWithImpl<_GuardianLink>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuardianLink&&(identical(other.linkId, linkId) || other.linkId == linkId)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.childId, childId) || other.childId == childId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,linkId,name,status,childId,avatarUrl);
}

@override
String toString() {
    return 'GuardianLink(linkId: $linkId, name: $name, status: $status, childId: $childId, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$GuardianLinkCopyWith<$Res> implements $GuardianLinkCopyWith<$Res> {
  factory _$GuardianLinkCopyWith(_GuardianLink value, $Res Function(_GuardianLink) _then) = __$GuardianLinkCopyWithImpl;
@override @useResult
$Res call({
 String linkId, String name, LinkStatus status, String? childId, String? avatarUrl
});




}
/// @nodoc
class __$GuardianLinkCopyWithImpl<$Res>
    implements _$GuardianLinkCopyWith<$Res> {
  __$GuardianLinkCopyWithImpl(this._self, this._then);

  final _GuardianLink _self;
  final $Res Function(_GuardianLink) _then;

/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? linkId = null,Object? name = null,Object? status = null,Object? childId = freezed,Object? avatarUrl = freezed,}) {
  return _then(_GuardianLink(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LinkStatus,childId: freezed == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PendingLink {

 String get linkId; String get childName;
/// Create a copy of PendingLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingLinkCopyWith<PendingLink> get copyWith => _$PendingLinkCopyWithImpl<PendingLink>(this as PendingLink, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PendingLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingLink&&(identical(other.linkId, _this.linkId) || other.linkId == _this.linkId)&&(identical(other.childName, _this.childName) || other.childName == _this.childName));
}


@override
int get hashCode {
  final _this = this as PendingLink;
  return Object.hash(runtimeType,_this.linkId,_this.childName);
}

@override
String toString() {
  final _this = this as PendingLink;
  return 'PendingLink(linkId: ${_this.linkId}, childName: ${_this.childName})';
}


}

/// @nodoc
abstract mixin class $PendingLinkCopyWith<$Res>  {
  factory $PendingLinkCopyWith(PendingLink value, $Res Function(PendingLink) _then) = _$PendingLinkCopyWithImpl;
@useResult
$Res call({
 String linkId, String childName
});




}
/// @nodoc
class _$PendingLinkCopyWithImpl<$Res>
    implements $PendingLinkCopyWith<$Res> {
  _$PendingLinkCopyWithImpl(this._self, this._then);

  final PendingLink _self;
  final $Res Function(PendingLink) _then;

/// Create a copy of PendingLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? linkId = null,Object? childName = null,}) {
  return _then(PendingLink(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,childName: null == childName ? _self.childName : childName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingLink].
extension PendingLinkPatterns on PendingLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingLink value)  $default,){
final _that = this;
switch (_that) {
case _PendingLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingLink value)?  $default,){
final _that = this;
switch (_that) {
case _PendingLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String linkId,  String childName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingLink() when $default != null:
return $default(_that.linkId,_that.childName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String linkId,  String childName)  $default,) {final _that = this;
switch (_that) {
case _PendingLink():
return $default(_that.linkId,_that.childName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String linkId,  String childName)?  $default,) {final _that = this;
switch (_that) {
case _PendingLink() when $default != null:
return $default(_that.linkId,_that.childName);case _:
  return null;

}
}

}

/// @nodoc


class _PendingLink implements PendingLink {
  const _PendingLink({required this.linkId, required this.childName});
  

@override final  String linkId;
@override final  String childName;

/// Create a copy of PendingLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingLinkCopyWith<_PendingLink> get copyWith => __$PendingLinkCopyWithImpl<_PendingLink>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingLink&&(identical(other.linkId, linkId) || other.linkId == linkId)&&(identical(other.childName, childName) || other.childName == childName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,linkId,childName);
}

@override
String toString() {
    return 'PendingLink(linkId: $linkId, childName: $childName)';
}


}

/// @nodoc
abstract mixin class _$PendingLinkCopyWith<$Res> implements $PendingLinkCopyWith<$Res> {
  factory _$PendingLinkCopyWith(_PendingLink value, $Res Function(_PendingLink) _then) = __$PendingLinkCopyWithImpl;
@override @useResult
$Res call({
 String linkId, String childName
});




}
/// @nodoc
class __$PendingLinkCopyWithImpl<$Res>
    implements _$PendingLinkCopyWith<$Res> {
  __$PendingLinkCopyWithImpl(this._self, this._then);

  final _PendingLink _self;
  final $Res Function(_PendingLink) _then;

/// Create a copy of PendingLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? linkId = null,Object? childName = null,}) {
  return _then(_PendingLink(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,childName: null == childName ? _self.childName : childName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ChildPost {

 String get kind; String get id; String get body; DateTime get createdAt;
/// Create a copy of ChildPost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChildPostCopyWith<ChildPost> get copyWith => _$ChildPostCopyWithImpl<ChildPost>(this as ChildPost, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChildPost;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChildPost&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as ChildPost;
  return Object.hash(runtimeType,_this.kind,_this.id,_this.body,_this.createdAt);
}

@override
String toString() {
  final _this = this as ChildPost;
  return 'ChildPost(kind: ${_this.kind}, id: ${_this.id}, body: ${_this.body}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ChildPostCopyWith<$Res>  {
  factory $ChildPostCopyWith(ChildPost value, $Res Function(ChildPost) _then) = _$ChildPostCopyWithImpl;
@useResult
$Res call({
 String kind, String id, String body, DateTime createdAt
});




}
/// @nodoc
class _$ChildPostCopyWithImpl<$Res>
    implements $ChildPostCopyWith<$Res> {
  _$ChildPostCopyWithImpl(this._self, this._then);

  final ChildPost _self;
  final $Res Function(ChildPost) _then;

/// Create a copy of ChildPost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? id = null,Object? body = null,Object? createdAt = null,}) {
  return _then(ChildPost(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChildPost].
extension ChildPostPatterns on ChildPost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChildPost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChildPost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChildPost value)  $default,){
final _that = this;
switch (_that) {
case _ChildPost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChildPost value)?  $default,){
final _that = this;
switch (_that) {
case _ChildPost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String id,  String body,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChildPost() when $default != null:
return $default(_that.kind,_that.id,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String id,  String body,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ChildPost():
return $default(_that.kind,_that.id,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String id,  String body,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ChildPost() when $default != null:
return $default(_that.kind,_that.id,_that.body,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChildPost extends ChildPost {
  const _ChildPost({required this.kind, required this.id, required this.body, required this.createdAt}): super._();
  

@override final  String kind;
@override final  String id;
@override final  String body;
@override final  DateTime createdAt;

/// Create a copy of ChildPost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChildPostCopyWith<_ChildPost> get copyWith => __$ChildPostCopyWithImpl<_ChildPost>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChildPost&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,id,body,createdAt);
}

@override
String toString() {
    return 'ChildPost(kind: $kind, id: $id, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ChildPostCopyWith<$Res> implements $ChildPostCopyWith<$Res> {
  factory _$ChildPostCopyWith(_ChildPost value, $Res Function(_ChildPost) _then) = __$ChildPostCopyWithImpl;
@override @useResult
$Res call({
 String kind, String id, String body, DateTime createdAt
});




}
/// @nodoc
class __$ChildPostCopyWithImpl<$Res>
    implements _$ChildPostCopyWith<$Res> {
  __$ChildPostCopyWithImpl(this._self, this._then);

  final _ChildPost _self;
  final $Res Function(_ChildPost) _then;

/// Create a copy of ChildPost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_ChildPost(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

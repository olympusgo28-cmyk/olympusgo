// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MyProfile {

 String get fullName; String get username; String get bio; Gender get gender; String? get avatarUrl; List<PlayerSport> get sports;
/// Create a copy of MyProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyProfileCopyWith<MyProfile> get copyWith => _$MyProfileCopyWithImpl<MyProfile>(this as MyProfile, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MyProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyProfile&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.gender, _this.gender) || other.gender == _this.gender)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&const DeepCollectionEquality().equals(other.sports, _this.sports));
}


@override
int get hashCode {
  final _this = this as MyProfile;
  return Object.hash(runtimeType,_this.fullName,_this.username,_this.bio,_this.gender,_this.avatarUrl,const DeepCollectionEquality().hash(_this.sports));
}



}

/// @nodoc
abstract mixin class $MyProfileCopyWith<$Res>  {
  factory $MyProfileCopyWith(MyProfile value, $Res Function(MyProfile) _then) = _$MyProfileCopyWithImpl;
@useResult
$Res call({
 String fullName, String username, String bio, Gender gender, String? avatarUrl, List<PlayerSport> sports
});




}
/// @nodoc
class _$MyProfileCopyWithImpl<$Res>
    implements $MyProfileCopyWith<$Res> {
  _$MyProfileCopyWithImpl(this._self, this._then);

  final MyProfile _self;
  final $Res Function(MyProfile) _then;

/// Create a copy of MyProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? username = null,Object? bio = null,Object? gender = null,Object? avatarUrl = freezed,Object? sports = null,}) {
  return _then(MyProfile(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self.sports : sports // ignore: cast_nullable_to_non_nullable
as List<PlayerSport>,
  ));
}

}


/// Adds pattern-matching-related methods to [MyProfile].
extension MyProfilePatterns on MyProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyProfile value)  $default,){
final _that = this;
switch (_that) {
case _MyProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyProfile value)?  $default,){
final _that = this;
switch (_that) {
case _MyProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String username,  String bio,  Gender gender,  String? avatarUrl,  List<PlayerSport> sports)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyProfile() when $default != null:
return $default(_that.fullName,_that.username,_that.bio,_that.gender,_that.avatarUrl,_that.sports);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String username,  String bio,  Gender gender,  String? avatarUrl,  List<PlayerSport> sports)  $default,) {final _that = this;
switch (_that) {
case _MyProfile():
return $default(_that.fullName,_that.username,_that.bio,_that.gender,_that.avatarUrl,_that.sports);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String username,  String bio,  Gender gender,  String? avatarUrl,  List<PlayerSport> sports)?  $default,) {final _that = this;
switch (_that) {
case _MyProfile() when $default != null:
return $default(_that.fullName,_that.username,_that.bio,_that.gender,_that.avatarUrl,_that.sports);case _:
  return null;

}
}

}

/// @nodoc


class _MyProfile extends MyProfile {
  const _MyProfile({this.fullName = '', this.username = '', this.bio = '', this.gender = Gender.preferNotToSay, this.avatarUrl,  List<PlayerSport> sports = const <PlayerSport>[]}): _sports = sports,super._();
  

@override@JsonKey() final  String fullName;
@override@JsonKey() final  String username;
@override@JsonKey() final  String bio;
@override@JsonKey() final  Gender gender;
@override final  String? avatarUrl;
 final  List<PlayerSport> _sports;
@override@JsonKey() List<PlayerSport> get sports {
  if (_sports is EqualUnmodifiableListView) return _sports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sports);
}


/// Create a copy of MyProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyProfileCopyWith<_MyProfile> get copyWith => __$MyProfileCopyWithImpl<_MyProfile>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyProfile&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other.sports, _sports));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fullName,username,bio,gender,avatarUrl,const DeepCollectionEquality().hash(_sports));
}



}

/// @nodoc
abstract mixin class _$MyProfileCopyWith<$Res> implements $MyProfileCopyWith<$Res> {
  factory _$MyProfileCopyWith(_MyProfile value, $Res Function(_MyProfile) _then) = __$MyProfileCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String username, String bio, Gender gender, String? avatarUrl, List<PlayerSport> sports
});




}
/// @nodoc
class __$MyProfileCopyWithImpl<$Res>
    implements _$MyProfileCopyWith<$Res> {
  __$MyProfileCopyWithImpl(this._self, this._then);

  final _MyProfile _self;
  final $Res Function(_MyProfile) _then;

/// Create a copy of MyProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? username = null,Object? bio = null,Object? gender = null,Object? avatarUrl = freezed,Object? sports = null,}) {
  return _then(_MyProfile(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self._sports : sports // ignore: cast_nullable_to_non_nullable
as List<PlayerSport>,
  ));
}


}

// dart format on

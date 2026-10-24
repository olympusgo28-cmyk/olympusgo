// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerSummary {

 String get id; String? get username; String? get fullName; String? get avatarUrl;
/// Create a copy of PlayerSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<PlayerSummary> get copyWith => _$PlayerSummaryCopyWithImpl<PlayerSummary>(this as PlayerSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}


@override
int get hashCode {
  final _this = this as PlayerSummary;
  return Object.hash(runtimeType,_this.id,_this.username,_this.fullName,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as PlayerSummary;
  return 'PlayerSummary(id: ${_this.id}, username: ${_this.username}, fullName: ${_this.fullName}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $PlayerSummaryCopyWith<$Res>  {
  factory $PlayerSummaryCopyWith(PlayerSummary value, $Res Function(PlayerSummary) _then) = _$PlayerSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String? username, String? fullName, String? avatarUrl
});




}
/// @nodoc
class _$PlayerSummaryCopyWithImpl<$Res>
    implements $PlayerSummaryCopyWith<$Res> {
  _$PlayerSummaryCopyWithImpl(this._self, this._then);

  final PlayerSummary _self;
  final $Res Function(PlayerSummary) _then;

/// Create a copy of PlayerSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = freezed,Object? fullName = freezed,Object? avatarUrl = freezed,}) {
  return _then(PlayerSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerSummary].
extension PlayerSummaryPatterns on PlayerSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerSummary value)  $default,){
final _that = this;
switch (_that) {
case _PlayerSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? username,  String? fullName,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerSummary() when $default != null:
return $default(_that.id,_that.username,_that.fullName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? username,  String? fullName,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _PlayerSummary():
return $default(_that.id,_that.username,_that.fullName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? username,  String? fullName,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _PlayerSummary() when $default != null:
return $default(_that.id,_that.username,_that.fullName,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerSummary extends PlayerSummary {
  const _PlayerSummary({required this.id, this.username, this.fullName, this.avatarUrl}): super._();
  

@override final  String id;
@override final  String? username;
@override final  String? fullName;
@override final  String? avatarUrl;

/// Create a copy of PlayerSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerSummaryCopyWith<_PlayerSummary> get copyWith => __$PlayerSummaryCopyWithImpl<_PlayerSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,username,fullName,avatarUrl);
}

@override
String toString() {
    return 'PlayerSummary(id: $id, username: $username, fullName: $fullName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$PlayerSummaryCopyWith<$Res> implements $PlayerSummaryCopyWith<$Res> {
  factory _$PlayerSummaryCopyWith(_PlayerSummary value, $Res Function(_PlayerSummary) _then) = __$PlayerSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username, String? fullName, String? avatarUrl
});




}
/// @nodoc
class __$PlayerSummaryCopyWithImpl<$Res>
    implements _$PlayerSummaryCopyWith<$Res> {
  __$PlayerSummaryCopyWithImpl(this._self, this._then);

  final _PlayerSummary _self;
  final $Res Function(_PlayerSummary) _then;

/// Create a copy of PlayerSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? fullName = freezed,Object? avatarUrl = freezed,}) {
  return _then(_PlayerSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PlayerSocial {

 int get followers; int get following; bool get iFollow; bool get followsMe;
/// Create a copy of PlayerSocial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerSocialCopyWith<PlayerSocial> get copyWith => _$PlayerSocialCopyWithImpl<PlayerSocial>(this as PlayerSocial, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerSocial;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerSocial&&(identical(other.followers, _this.followers) || other.followers == _this.followers)&&(identical(other.following, _this.following) || other.following == _this.following)&&(identical(other.iFollow, _this.iFollow) || other.iFollow == _this.iFollow)&&(identical(other.followsMe, _this.followsMe) || other.followsMe == _this.followsMe));
}


@override
int get hashCode {
  final _this = this as PlayerSocial;
  return Object.hash(runtimeType,_this.followers,_this.following,_this.iFollow,_this.followsMe);
}

@override
String toString() {
  final _this = this as PlayerSocial;
  return 'PlayerSocial(followers: ${_this.followers}, following: ${_this.following}, iFollow: ${_this.iFollow}, followsMe: ${_this.followsMe})';
}


}

/// @nodoc
abstract mixin class $PlayerSocialCopyWith<$Res>  {
  factory $PlayerSocialCopyWith(PlayerSocial value, $Res Function(PlayerSocial) _then) = _$PlayerSocialCopyWithImpl;
@useResult
$Res call({
 int followers, int following, bool iFollow, bool followsMe
});




}
/// @nodoc
class _$PlayerSocialCopyWithImpl<$Res>
    implements $PlayerSocialCopyWith<$Res> {
  _$PlayerSocialCopyWithImpl(this._self, this._then);

  final PlayerSocial _self;
  final $Res Function(PlayerSocial) _then;

/// Create a copy of PlayerSocial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? followers = null,Object? following = null,Object? iFollow = null,Object? followsMe = null,}) {
  return _then(PlayerSocial(
followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,iFollow: null == iFollow ? _self.iFollow : iFollow // ignore: cast_nullable_to_non_nullable
as bool,followsMe: null == followsMe ? _self.followsMe : followsMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerSocial].
extension PlayerSocialPatterns on PlayerSocial {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerSocial value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerSocial() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerSocial value)  $default,){
final _that = this;
switch (_that) {
case _PlayerSocial():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerSocial value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerSocial() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int followers,  int following,  bool iFollow,  bool followsMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerSocial() when $default != null:
return $default(_that.followers,_that.following,_that.iFollow,_that.followsMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int followers,  int following,  bool iFollow,  bool followsMe)  $default,) {final _that = this;
switch (_that) {
case _PlayerSocial():
return $default(_that.followers,_that.following,_that.iFollow,_that.followsMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int followers,  int following,  bool iFollow,  bool followsMe)?  $default,) {final _that = this;
switch (_that) {
case _PlayerSocial() when $default != null:
return $default(_that.followers,_that.following,_that.iFollow,_that.followsMe);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerSocial implements PlayerSocial {
  const _PlayerSocial({this.followers = 0, this.following = 0, this.iFollow = false, this.followsMe = false});
  

@override@JsonKey() final  int followers;
@override@JsonKey() final  int following;
@override@JsonKey() final  bool iFollow;
@override@JsonKey() final  bool followsMe;

/// Create a copy of PlayerSocial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerSocialCopyWith<_PlayerSocial> get copyWith => __$PlayerSocialCopyWithImpl<_PlayerSocial>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerSocial&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.following, following) || other.following == following)&&(identical(other.iFollow, iFollow) || other.iFollow == iFollow)&&(identical(other.followsMe, followsMe) || other.followsMe == followsMe));
}


@override
int get hashCode {
    return Object.hash(runtimeType,followers,following,iFollow,followsMe);
}

@override
String toString() {
    return 'PlayerSocial(followers: $followers, following: $following, iFollow: $iFollow, followsMe: $followsMe)';
}


}

/// @nodoc
abstract mixin class _$PlayerSocialCopyWith<$Res> implements $PlayerSocialCopyWith<$Res> {
  factory _$PlayerSocialCopyWith(_PlayerSocial value, $Res Function(_PlayerSocial) _then) = __$PlayerSocialCopyWithImpl;
@override @useResult
$Res call({
 int followers, int following, bool iFollow, bool followsMe
});




}
/// @nodoc
class __$PlayerSocialCopyWithImpl<$Res>
    implements _$PlayerSocialCopyWith<$Res> {
  __$PlayerSocialCopyWithImpl(this._self, this._then);

  final _PlayerSocial _self;
  final $Res Function(_PlayerSocial) _then;

/// Create a copy of PlayerSocial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? followers = null,Object? following = null,Object? iFollow = null,Object? followsMe = null,}) {
  return _then(_PlayerSocial(
followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,iFollow: null == iFollow ? _self.iFollow : iFollow // ignore: cast_nullable_to_non_nullable
as bool,followsMe: null == followsMe ? _self.followsMe : followsMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PlayerDetail {

 PlayerSummary get player; String? get bio; Country get country; List<PlayerSport> get sports; PlayerSocial get social; int get played; bool get showLevel;
/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerDetailCopyWith<PlayerDetail> get copyWith => _$PlayerDetailCopyWithImpl<PlayerDetail>(this as PlayerDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerDetail&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.country, _this.country) || other.country == _this.country)&&const DeepCollectionEquality().equals(other.sports, _this.sports)&&(identical(other.social, _this.social) || other.social == _this.social)&&(identical(other.played, _this.played) || other.played == _this.played)&&(identical(other.showLevel, _this.showLevel) || other.showLevel == _this.showLevel));
}


@override
int get hashCode {
  final _this = this as PlayerDetail;
  return Object.hash(runtimeType,_this.player,_this.bio,_this.country,const DeepCollectionEquality().hash(_this.sports),_this.social,_this.played,_this.showLevel);
}

@override
String toString() {
  final _this = this as PlayerDetail;
  return 'PlayerDetail(player: ${_this.player}, bio: ${_this.bio}, country: ${_this.country}, sports: ${_this.sports}, social: ${_this.social}, played: ${_this.played}, showLevel: ${_this.showLevel})';
}


}

/// @nodoc
abstract mixin class $PlayerDetailCopyWith<$Res>  {
  factory $PlayerDetailCopyWith(PlayerDetail value, $Res Function(PlayerDetail) _then) = _$PlayerDetailCopyWithImpl;
@useResult
$Res call({
 PlayerSummary player, String? bio, Country country, List<PlayerSport> sports, PlayerSocial social, int played, bool showLevel
});


$PlayerSummaryCopyWith<$Res> get player;$PlayerSocialCopyWith<$Res> get social;

}
/// @nodoc
class _$PlayerDetailCopyWithImpl<$Res>
    implements $PlayerDetailCopyWith<$Res> {
  _$PlayerDetailCopyWithImpl(this._self, this._then);

  final PlayerDetail _self;
  final $Res Function(PlayerDetail) _then;

/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? bio = freezed,Object? country = null,Object? sports = null,Object? social = null,Object? played = null,Object? showLevel = null,}) {
  return _then(PlayerDetail(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as Country,sports: null == sports ? _self.sports : sports // ignore: cast_nullable_to_non_nullable
as List<PlayerSport>,social: null == social ? _self.social : social // ignore: cast_nullable_to_non_nullable
as PlayerSocial,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as int,showLevel: null == showLevel ? _self.showLevel : showLevel // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSocialCopyWith<$Res> get social {
  
  return $PlayerSocialCopyWith<$Res>(_self.social, (value) {
    return _then(_self.copyWith(social: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayerDetail].
extension PlayerDetailPatterns on PlayerDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerDetail value)  $default,){
final _that = this;
switch (_that) {
case _PlayerDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerSummary player,  String? bio,  Country country,  List<PlayerSport> sports,  PlayerSocial social,  int played,  bool showLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerDetail() when $default != null:
return $default(_that.player,_that.bio,_that.country,_that.sports,_that.social,_that.played,_that.showLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerSummary player,  String? bio,  Country country,  List<PlayerSport> sports,  PlayerSocial social,  int played,  bool showLevel)  $default,) {final _that = this;
switch (_that) {
case _PlayerDetail():
return $default(_that.player,_that.bio,_that.country,_that.sports,_that.social,_that.played,_that.showLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerSummary player,  String? bio,  Country country,  List<PlayerSport> sports,  PlayerSocial social,  int played,  bool showLevel)?  $default,) {final _that = this;
switch (_that) {
case _PlayerDetail() when $default != null:
return $default(_that.player,_that.bio,_that.country,_that.sports,_that.social,_that.played,_that.showLevel);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerDetail implements PlayerDetail {
  const _PlayerDetail({required this.player, this.bio, this.country = Country.singapore,  List<PlayerSport> sports = const [], this.social = const PlayerSocial(), this.played = 0, this.showLevel = true}): _sports = sports;
  

@override final  PlayerSummary player;
@override final  String? bio;
@override@JsonKey() final  Country country;
 final  List<PlayerSport> _sports;
@override@JsonKey() List<PlayerSport> get sports {
  if (_sports is EqualUnmodifiableListView) return _sports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sports);
}

@override@JsonKey() final  PlayerSocial social;
@override@JsonKey() final  int played;
@override@JsonKey() final  bool showLevel;

/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerDetailCopyWith<_PlayerDetail> get copyWith => __$PlayerDetailCopyWithImpl<_PlayerDetail>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerDetail&&(identical(other.player, player) || other.player == player)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.country, country) || other.country == country)&&const DeepCollectionEquality().equals(other.sports, _sports)&&(identical(other.social, social) || other.social == social)&&(identical(other.played, played) || other.played == played)&&(identical(other.showLevel, showLevel) || other.showLevel == showLevel));
}


@override
int get hashCode {
    return Object.hash(runtimeType,player,bio,country,const DeepCollectionEquality().hash(_sports),social,played,showLevel);
}

@override
String toString() {
    return 'PlayerDetail(player: $player, bio: $bio, country: $country, sports: $sports, social: $social, played: $played, showLevel: $showLevel)';
}


}

/// @nodoc
abstract mixin class _$PlayerDetailCopyWith<$Res> implements $PlayerDetailCopyWith<$Res> {
  factory _$PlayerDetailCopyWith(_PlayerDetail value, $Res Function(_PlayerDetail) _then) = __$PlayerDetailCopyWithImpl;
@override @useResult
$Res call({
 PlayerSummary player, String? bio, Country country, List<PlayerSport> sports, PlayerSocial social, int played, bool showLevel
});


@override $PlayerSummaryCopyWith<$Res> get player;@override $PlayerSocialCopyWith<$Res> get social;

}
/// @nodoc
class __$PlayerDetailCopyWithImpl<$Res>
    implements _$PlayerDetailCopyWith<$Res> {
  __$PlayerDetailCopyWithImpl(this._self, this._then);

  final _PlayerDetail _self;
  final $Res Function(_PlayerDetail) _then;

/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? bio = freezed,Object? country = null,Object? sports = null,Object? social = null,Object? played = null,Object? showLevel = null,}) {
  return _then(_PlayerDetail(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as Country,sports: null == sports ? _self._sports : sports // ignore: cast_nullable_to_non_nullable
as List<PlayerSport>,social: null == social ? _self.social : social // ignore: cast_nullable_to_non_nullable
as PlayerSocial,played: null == played ? _self.played : played // ignore: cast_nullable_to_non_nullable
as int,showLevel: null == showLevel ? _self.showLevel : showLevel // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}/// Create a copy of PlayerDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSocialCopyWith<$Res> get social {
  
  return $PlayerSocialCopyWith<$Res>(_self.social, (value) {
    return _then(_self.copyWith(social: value));
  });
}
}

/// @nodoc
mixin _$SuggestedPlayer {

 PlayerSummary get player; double? get level; String get note;
/// Create a copy of SuggestedPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuggestedPlayerCopyWith<SuggestedPlayer> get copyWith => _$SuggestedPlayerCopyWithImpl<SuggestedPlayer>(this as SuggestedPlayer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SuggestedPlayer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SuggestedPlayer&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as SuggestedPlayer;
  return Object.hash(runtimeType,_this.player,_this.level,_this.note);
}

@override
String toString() {
  final _this = this as SuggestedPlayer;
  return 'SuggestedPlayer(player: ${_this.player}, level: ${_this.level}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $SuggestedPlayerCopyWith<$Res>  {
  factory $SuggestedPlayerCopyWith(SuggestedPlayer value, $Res Function(SuggestedPlayer) _then) = _$SuggestedPlayerCopyWithImpl;
@useResult
$Res call({
 PlayerSummary player, double? level, String note
});


$PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class _$SuggestedPlayerCopyWithImpl<$Res>
    implements $SuggestedPlayerCopyWith<$Res> {
  _$SuggestedPlayerCopyWithImpl(this._self, this._then);

  final SuggestedPlayer _self;
  final $Res Function(SuggestedPlayer) _then;

/// Create a copy of SuggestedPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? level = freezed,Object? note = null,}) {
  return _then(SuggestedPlayer(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as double?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SuggestedPlayer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [SuggestedPlayer].
extension SuggestedPlayerPatterns on SuggestedPlayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SuggestedPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SuggestedPlayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SuggestedPlayer value)  $default,){
final _that = this;
switch (_that) {
case _SuggestedPlayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SuggestedPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _SuggestedPlayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerSummary player,  double? level,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SuggestedPlayer() when $default != null:
return $default(_that.player,_that.level,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerSummary player,  double? level,  String note)  $default,) {final _that = this;
switch (_that) {
case _SuggestedPlayer():
return $default(_that.player,_that.level,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerSummary player,  double? level,  String note)?  $default,) {final _that = this;
switch (_that) {
case _SuggestedPlayer() when $default != null:
return $default(_that.player,_that.level,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _SuggestedPlayer implements SuggestedPlayer {
  const _SuggestedPlayer({required this.player, this.level, this.note = ''});
  

@override final  PlayerSummary player;
@override final  double? level;
@override@JsonKey() final  String note;

/// Create a copy of SuggestedPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuggestedPlayerCopyWith<_SuggestedPlayer> get copyWith => __$SuggestedPlayerCopyWithImpl<_SuggestedPlayer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SuggestedPlayer&&(identical(other.player, player) || other.player == player)&&(identical(other.level, level) || other.level == level)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,player,level,note);
}

@override
String toString() {
    return 'SuggestedPlayer(player: $player, level: $level, note: $note)';
}


}

/// @nodoc
abstract mixin class _$SuggestedPlayerCopyWith<$Res> implements $SuggestedPlayerCopyWith<$Res> {
  factory _$SuggestedPlayerCopyWith(_SuggestedPlayer value, $Res Function(_SuggestedPlayer) _then) = __$SuggestedPlayerCopyWithImpl;
@override @useResult
$Res call({
 PlayerSummary player, double? level, String note
});


@override $PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class __$SuggestedPlayerCopyWithImpl<$Res>
    implements _$SuggestedPlayerCopyWith<$Res> {
  __$SuggestedPlayerCopyWithImpl(this._self, this._then);

  final _SuggestedPlayer _self;
  final $Res Function(_SuggestedPlayer) _then;

/// Create a copy of SuggestedPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? level = freezed,Object? note = null,}) {
  return _then(_SuggestedPlayer(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as double?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SuggestedPlayer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}

/// @nodoc
mixin _$Conversation {

 String get id; PlayerSummary get other; String? get lastBody; DateTime? get lastAt; bool get unread;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Conversation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.other, _this.other) || other.other == _this.other)&&(identical(other.lastBody, _this.lastBody) || other.lastBody == _this.lastBody)&&(identical(other.lastAt, _this.lastAt) || other.lastAt == _this.lastAt)&&(identical(other.unread, _this.unread) || other.unread == _this.unread));
}


@override
int get hashCode {
  final _this = this as Conversation;
  return Object.hash(runtimeType,_this.id,_this.other,_this.lastBody,_this.lastAt,_this.unread);
}

@override
String toString() {
  final _this = this as Conversation;
  return 'Conversation(id: ${_this.id}, other: ${_this.other}, lastBody: ${_this.lastBody}, lastAt: ${_this.lastAt}, unread: ${_this.unread})';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String id, PlayerSummary other, String? lastBody, DateTime? lastAt, bool unread
});


$PlayerSummaryCopyWith<$Res> get other;

}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? other = null,Object? lastBody = freezed,Object? lastAt = freezed,Object? unread = null,}) {
  return _then(Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,other: null == other ? _self.other : other // ignore: cast_nullable_to_non_nullable
as PlayerSummary,lastBody: freezed == lastBody ? _self.lastBody : lastBody // ignore: cast_nullable_to_non_nullable
as String?,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get other {
  
  return $PlayerSummaryCopyWith<$Res>(_self.other, (value) {
    return _then(_self.copyWith(other: value));
  });
}
}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PlayerSummary other,  String? lastBody,  DateTime? lastAt,  bool unread)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.other,_that.lastBody,_that.lastAt,_that.unread);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PlayerSummary other,  String? lastBody,  DateTime? lastAt,  bool unread)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.id,_that.other,_that.lastBody,_that.lastAt,_that.unread);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PlayerSummary other,  String? lastBody,  DateTime? lastAt,  bool unread)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.other,_that.lastBody,_that.lastAt,_that.unread);case _:
  return null;

}
}

}

/// @nodoc


class _Conversation implements Conversation {
  const _Conversation({required this.id, required this.other, this.lastBody, this.lastAt, this.unread = false});
  

@override final  String id;
@override final  PlayerSummary other;
@override final  String? lastBody;
@override final  DateTime? lastAt;
@override@JsonKey() final  bool unread;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.other, this.other) || other.other == this.other)&&(identical(other.lastBody, lastBody) || other.lastBody == lastBody)&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt)&&(identical(other.unread, unread) || other.unread == unread));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,other,lastBody,lastAt,unread);
}

@override
String toString() {
    return 'Conversation(id: $id, other: $other, lastBody: $lastBody, lastAt: $lastAt, unread: $unread)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String id, PlayerSummary other, String? lastBody, DateTime? lastAt, bool unread
});


@override $PlayerSummaryCopyWith<$Res> get other;

}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? other = null,Object? lastBody = freezed,Object? lastAt = freezed,Object? unread = null,}) {
  return _then(_Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,other: null == other ? _self.other : other // ignore: cast_nullable_to_non_nullable
as PlayerSummary,lastBody: freezed == lastBody ? _self.lastBody : lastBody // ignore: cast_nullable_to_non_nullable
as String?,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get other {
  
  return $PlayerSummaryCopyWith<$Res>(_self.other, (value) {
    return _then(_self.copyWith(other: value));
  });
}
}

/// @nodoc
mixin _$ChatMessage {

 String get id; String get senderId; String get body; DateTime get createdAt;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.senderId, _this.senderId) || other.senderId == _this.senderId)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as ChatMessage;
  return Object.hash(runtimeType,_this.id,_this.senderId,_this.body,_this.createdAt);
}

@override
String toString() {
  final _this = this as ChatMessage;
  return 'ChatMessage(id: ${_this.id}, senderId: ${_this.senderId}, body: ${_this.body}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String senderId, String body, DateTime createdAt
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? body = null,Object? createdAt = null,}) {
  return _then(ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String senderId,  String body,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.senderId,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String senderId,  String body,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.senderId,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String senderId,  String body,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.senderId,_that.body,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.senderId, required this.body, required this.createdAt});
  

@override final  String id;
@override final  String senderId;
@override final  String body;
@override final  DateTime createdAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,senderId,body,createdAt);
}

@override
String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String senderId, String body, DateTime createdAt
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

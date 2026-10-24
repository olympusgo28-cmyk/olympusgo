// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {

 String get id; String? get username;@JsonKey(name: 'full_name') String? get fullName; String? get bio;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'onboarding_completed') bool get onboardingCompleted;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Profile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.onboardingCompleted, _this.onboardingCompleted) || other.onboardingCompleted == _this.onboardingCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Profile;
  return Object.hash(runtimeType,_this.id,_this.username,_this.fullName,_this.bio,_this.avatarUrl,_this.onboardingCompleted);
}

@override
String toString() {
  final _this = this as Profile;
  return 'Profile(id: ${_this.id}, username: ${_this.username}, fullName: ${_this.fullName}, bio: ${_this.bio}, avatarUrl: ${_this.avatarUrl}, onboardingCompleted: ${_this.onboardingCompleted})';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String? username,@JsonKey(name: 'full_name') String? fullName, String? bio,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = freezed,Object? fullName = freezed,Object? bio = freezed,Object? avatarUrl = freezed,Object? onboardingCompleted = null,}) {
  return _then(Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? username, @JsonKey(name: 'full_name')  String? fullName,  String? bio, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.fullName,_that.bio,_that.avatarUrl,_that.onboardingCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? username, @JsonKey(name: 'full_name')  String? fullName,  String? bio, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.username,_that.fullName,_that.bio,_that.avatarUrl,_that.onboardingCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? username, @JsonKey(name: 'full_name')  String? fullName,  String? bio, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.fullName,_that.bio,_that.avatarUrl,_that.onboardingCompleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile extends Profile {
  const _Profile({required this.id, this.username, @JsonKey(name: 'full_name') this.fullName, this.bio, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'onboarding_completed') this.onboardingCompleted = false}): super._();
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String id;
@override final  String? username;
@override@JsonKey(name: 'full_name') final  String? fullName;
@override final  String? bio;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'onboarding_completed') final  bool onboardingCompleted;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,username,fullName,bio,avatarUrl,onboardingCompleted);
}

@override
String toString() {
    return 'Profile(id: $id, username: $username, fullName: $fullName, bio: $bio, avatarUrl: $avatarUrl, onboardingCompleted: $onboardingCompleted)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String? username,@JsonKey(name: 'full_name') String? fullName, String? bio,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = freezed,Object? fullName = freezed,Object? bio = freezed,Object? avatarUrl = freezed,Object? onboardingCompleted = null,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PlayerSport {

 String get sport; double get level;@JsonKey(name: 'play_min') double get playMin;@JsonKey(name: 'play_max') double get playMax;
/// Create a copy of PlayerSport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerSportCopyWith<PlayerSport> get copyWith => _$PlayerSportCopyWithImpl<PlayerSport>(this as PlayerSport, _$identity);

  /// Serializes this PlayerSport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlayerSport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerSport&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.playMin, _this.playMin) || other.playMin == _this.playMin)&&(identical(other.playMax, _this.playMax) || other.playMax == _this.playMax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlayerSport;
  return Object.hash(runtimeType,_this.sport,_this.level,_this.playMin,_this.playMax);
}

@override
String toString() {
  final _this = this as PlayerSport;
  return 'PlayerSport(sport: ${_this.sport}, level: ${_this.level}, playMin: ${_this.playMin}, playMax: ${_this.playMax})';
}


}

/// @nodoc
abstract mixin class $PlayerSportCopyWith<$Res>  {
  factory $PlayerSportCopyWith(PlayerSport value, $Res Function(PlayerSport) _then) = _$PlayerSportCopyWithImpl;
@useResult
$Res call({
 String sport, double level,@JsonKey(name: 'play_min') double playMin,@JsonKey(name: 'play_max') double playMax
});




}
/// @nodoc
class _$PlayerSportCopyWithImpl<$Res>
    implements $PlayerSportCopyWith<$Res> {
  _$PlayerSportCopyWithImpl(this._self, this._then);

  final PlayerSport _self;
  final $Res Function(PlayerSport) _then;

/// Create a copy of PlayerSport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sport = null,Object? level = null,Object? playMin = null,Object? playMax = null,}) {
  return _then(PlayerSport(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as double,playMin: null == playMin ? _self.playMin : playMin // ignore: cast_nullable_to_non_nullable
as double,playMax: null == playMax ? _self.playMax : playMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerSport].
extension PlayerSportPatterns on PlayerSport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerSport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerSport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerSport value)  $default,){
final _that = this;
switch (_that) {
case _PlayerSport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerSport value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerSport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sport,  double level, @JsonKey(name: 'play_min')  double playMin, @JsonKey(name: 'play_max')  double playMax)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerSport() when $default != null:
return $default(_that.sport,_that.level,_that.playMin,_that.playMax);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sport,  double level, @JsonKey(name: 'play_min')  double playMin, @JsonKey(name: 'play_max')  double playMax)  $default,) {final _that = this;
switch (_that) {
case _PlayerSport():
return $default(_that.sport,_that.level,_that.playMin,_that.playMax);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sport,  double level, @JsonKey(name: 'play_min')  double playMin, @JsonKey(name: 'play_max')  double playMax)?  $default,) {final _that = this;
switch (_that) {
case _PlayerSport() when $default != null:
return $default(_that.sport,_that.level,_that.playMin,_that.playMax);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerSport implements PlayerSport {
  const _PlayerSport({required this.sport, required this.level, @JsonKey(name: 'play_min') required this.playMin, @JsonKey(name: 'play_max') required this.playMax});
  factory _PlayerSport.fromJson(Map<String, dynamic> json) => _$PlayerSportFromJson(json);

@override final  String sport;
@override final  double level;
@override@JsonKey(name: 'play_min') final  double playMin;
@override@JsonKey(name: 'play_max') final  double playMax;

/// Create a copy of PlayerSport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerSportCopyWith<_PlayerSport> get copyWith => __$PlayerSportCopyWithImpl<_PlayerSport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerSportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerSport&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.level, level) || other.level == level)&&(identical(other.playMin, playMin) || other.playMin == playMin)&&(identical(other.playMax, playMax) || other.playMax == playMax));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sport,level,playMin,playMax);
}

@override
String toString() {
    return 'PlayerSport(sport: $sport, level: $level, playMin: $playMin, playMax: $playMax)';
}


}

/// @nodoc
abstract mixin class _$PlayerSportCopyWith<$Res> implements $PlayerSportCopyWith<$Res> {
  factory _$PlayerSportCopyWith(_PlayerSport value, $Res Function(_PlayerSport) _then) = __$PlayerSportCopyWithImpl;
@override @useResult
$Res call({
 String sport, double level,@JsonKey(name: 'play_min') double playMin,@JsonKey(name: 'play_max') double playMax
});




}
/// @nodoc
class __$PlayerSportCopyWithImpl<$Res>
    implements _$PlayerSportCopyWith<$Res> {
  __$PlayerSportCopyWithImpl(this._self, this._then);

  final _PlayerSport _self;
  final $Res Function(_PlayerSport) _then;

/// Create a copy of PlayerSport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sport = null,Object? level = null,Object? playMin = null,Object? playMax = null,}) {
  return _then(_PlayerSport(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as double,playMin: null == playMin ? _self.playMin : playMin // ignore: cast_nullable_to_non_nullable
as double,playMax: null == playMax ? _self.playMax : playMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ProfileBadge {

 String get mark; String get name; int get color; int get ink;
/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileBadgeCopyWith<ProfileBadge> get copyWith => _$ProfileBadgeCopyWithImpl<ProfileBadge>(this as ProfileBadge, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProfileBadge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileBadge&&(identical(other.mark, _this.mark) || other.mark == _this.mark)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.ink, _this.ink) || other.ink == _this.ink));
}


@override
int get hashCode {
  final _this = this as ProfileBadge;
  return Object.hash(runtimeType,_this.mark,_this.name,_this.color,_this.ink);
}

@override
String toString() {
  final _this = this as ProfileBadge;
  return 'ProfileBadge(mark: ${_this.mark}, name: ${_this.name}, color: ${_this.color}, ink: ${_this.ink})';
}


}

/// @nodoc
abstract mixin class $ProfileBadgeCopyWith<$Res>  {
  factory $ProfileBadgeCopyWith(ProfileBadge value, $Res Function(ProfileBadge) _then) = _$ProfileBadgeCopyWithImpl;
@useResult
$Res call({
 String mark, String name, int color, int ink
});




}
/// @nodoc
class _$ProfileBadgeCopyWithImpl<$Res>
    implements $ProfileBadgeCopyWith<$Res> {
  _$ProfileBadgeCopyWithImpl(this._self, this._then);

  final ProfileBadge _self;
  final $Res Function(ProfileBadge) _then;

/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mark = null,Object? name = null,Object? color = null,Object? ink = null,}) {
  return _then(ProfileBadge(
mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileBadge].
extension ProfileBadgePatterns on ProfileBadge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileBadge value)  $default,){
final _that = this;
switch (_that) {
case _ProfileBadge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileBadge value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mark,  String name,  int color,  int ink)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
return $default(_that.mark,_that.name,_that.color,_that.ink);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mark,  String name,  int color,  int ink)  $default,) {final _that = this;
switch (_that) {
case _ProfileBadge():
return $default(_that.mark,_that.name,_that.color,_that.ink);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mark,  String name,  int color,  int ink)?  $default,) {final _that = this;
switch (_that) {
case _ProfileBadge() when $default != null:
return $default(_that.mark,_that.name,_that.color,_that.ink);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileBadge implements ProfileBadge {
  const _ProfileBadge({required this.mark, required this.name, this.color = 0xFFFFE8CC, this.ink = 0xFF7A3B00});
  

@override final  String mark;
@override final  String name;
@override@JsonKey() final  int color;
@override@JsonKey() final  int ink;

/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileBadgeCopyWith<_ProfileBadge> get copyWith => __$ProfileBadgeCopyWithImpl<_ProfileBadge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileBadge&&(identical(other.mark, mark) || other.mark == mark)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.ink, ink) || other.ink == ink));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mark,name,color,ink);
}

@override
String toString() {
    return 'ProfileBadge(mark: $mark, name: $name, color: $color, ink: $ink)';
}


}

/// @nodoc
abstract mixin class _$ProfileBadgeCopyWith<$Res> implements $ProfileBadgeCopyWith<$Res> {
  factory _$ProfileBadgeCopyWith(_ProfileBadge value, $Res Function(_ProfileBadge) _then) = __$ProfileBadgeCopyWithImpl;
@override @useResult
$Res call({
 String mark, String name, int color, int ink
});




}
/// @nodoc
class __$ProfileBadgeCopyWithImpl<$Res>
    implements _$ProfileBadgeCopyWith<$Res> {
  __$ProfileBadgeCopyWithImpl(this._self, this._then);

  final _ProfileBadge _self;
  final $Res Function(_ProfileBadge) _then;

/// Create a copy of ProfileBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mark = null,Object? name = null,Object? color = null,Object? ink = null,}) {
  return _then(_ProfileBadge(
mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ProfileSummary {

/// Past sessions played.
 int get sessions;/// Rank in their best club's leaderboard, when they have one.
 int? get clubRank;/// Rank among players nearby, and where.
 int? get localRank; String? get area; List<ProfileBadge> get badges;/// All badges earned; [badges] holds the latest few.
 int get badgeCount;/// Who sees their next sessions: "Circle", "Followers", "Only me".
 String get sessionsShownTo;
/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileSummaryCopyWith<ProfileSummary> get copyWith => _$ProfileSummaryCopyWithImpl<ProfileSummary>(this as ProfileSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProfileSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileSummary&&(identical(other.sessions, _this.sessions) || other.sessions == _this.sessions)&&(identical(other.clubRank, _this.clubRank) || other.clubRank == _this.clubRank)&&(identical(other.localRank, _this.localRank) || other.localRank == _this.localRank)&&(identical(other.area, _this.area) || other.area == _this.area)&&const DeepCollectionEquality().equals(other.badges, _this.badges)&&(identical(other.badgeCount, _this.badgeCount) || other.badgeCount == _this.badgeCount)&&(identical(other.sessionsShownTo, _this.sessionsShownTo) || other.sessionsShownTo == _this.sessionsShownTo));
}


@override
int get hashCode {
  final _this = this as ProfileSummary;
  return Object.hash(runtimeType,_this.sessions,_this.clubRank,_this.localRank,_this.area,const DeepCollectionEquality().hash(_this.badges),_this.badgeCount,_this.sessionsShownTo);
}

@override
String toString() {
  final _this = this as ProfileSummary;
  return 'ProfileSummary(sessions: ${_this.sessions}, clubRank: ${_this.clubRank}, localRank: ${_this.localRank}, area: ${_this.area}, badges: ${_this.badges}, badgeCount: ${_this.badgeCount}, sessionsShownTo: ${_this.sessionsShownTo})';
}


}

/// @nodoc
abstract mixin class $ProfileSummaryCopyWith<$Res>  {
  factory $ProfileSummaryCopyWith(ProfileSummary value, $Res Function(ProfileSummary) _then) = _$ProfileSummaryCopyWithImpl;
@useResult
$Res call({
 int sessions, int? clubRank, int? localRank, String? area, List<ProfileBadge> badges, int badgeCount, String sessionsShownTo
});




}
/// @nodoc
class _$ProfileSummaryCopyWithImpl<$Res>
    implements $ProfileSummaryCopyWith<$Res> {
  _$ProfileSummaryCopyWithImpl(this._self, this._then);

  final ProfileSummary _self;
  final $Res Function(ProfileSummary) _then;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessions = null,Object? clubRank = freezed,Object? localRank = freezed,Object? area = freezed,Object? badges = null,Object? badgeCount = null,Object? sessionsShownTo = null,}) {
  return _then(ProfileSummary(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,clubRank: freezed == clubRank ? _self.clubRank : clubRank // ignore: cast_nullable_to_non_nullable
as int?,localRank: freezed == localRank ? _self.localRank : localRank // ignore: cast_nullable_to_non_nullable
as int?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<ProfileBadge>,badgeCount: null == badgeCount ? _self.badgeCount : badgeCount // ignore: cast_nullable_to_non_nullable
as int,sessionsShownTo: null == sessionsShownTo ? _self.sessionsShownTo : sessionsShownTo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileSummary].
extension ProfileSummaryPatterns on ProfileSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProfileSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sessions,  int? clubRank,  int? localRank,  String? area,  List<ProfileBadge> badges,  int badgeCount,  String sessionsShownTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that.sessions,_that.clubRank,_that.localRank,_that.area,_that.badges,_that.badgeCount,_that.sessionsShownTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sessions,  int? clubRank,  int? localRank,  String? area,  List<ProfileBadge> badges,  int badgeCount,  String sessionsShownTo)  $default,) {final _that = this;
switch (_that) {
case _ProfileSummary():
return $default(_that.sessions,_that.clubRank,_that.localRank,_that.area,_that.badges,_that.badgeCount,_that.sessionsShownTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sessions,  int? clubRank,  int? localRank,  String? area,  List<ProfileBadge> badges,  int badgeCount,  String sessionsShownTo)?  $default,) {final _that = this;
switch (_that) {
case _ProfileSummary() when $default != null:
return $default(_that.sessions,_that.clubRank,_that.localRank,_that.area,_that.badges,_that.badgeCount,_that.sessionsShownTo);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileSummary implements ProfileSummary {
  const _ProfileSummary({this.sessions = 0, this.clubRank, this.localRank, this.area,  List<ProfileBadge> badges = const [], this.badgeCount = 0, this.sessionsShownTo = 'Followers'}): _badges = badges;
  

/// Past sessions played.
@override@JsonKey() final  int sessions;
/// Rank in their best club's leaderboard, when they have one.
@override final  int? clubRank;
/// Rank among players nearby, and where.
@override final  int? localRank;
@override final  String? area;
 final  List<ProfileBadge> _badges;
@override@JsonKey() List<ProfileBadge> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

/// All badges earned; [badges] holds the latest few.
@override@JsonKey() final  int badgeCount;
/// Who sees their next sessions: "Circle", "Followers", "Only me".
@override@JsonKey() final  String sessionsShownTo;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileSummaryCopyWith<_ProfileSummary> get copyWith => __$ProfileSummaryCopyWithImpl<_ProfileSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileSummary&&(identical(other.sessions, sessions) || other.sessions == sessions)&&(identical(other.clubRank, clubRank) || other.clubRank == clubRank)&&(identical(other.localRank, localRank) || other.localRank == localRank)&&(identical(other.area, area) || other.area == area)&&const DeepCollectionEquality().equals(other.badges, _badges)&&(identical(other.badgeCount, badgeCount) || other.badgeCount == badgeCount)&&(identical(other.sessionsShownTo, sessionsShownTo) || other.sessionsShownTo == sessionsShownTo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sessions,clubRank,localRank,area,const DeepCollectionEquality().hash(_badges),badgeCount,sessionsShownTo);
}

@override
String toString() {
    return 'ProfileSummary(sessions: $sessions, clubRank: $clubRank, localRank: $localRank, area: $area, badges: $badges, badgeCount: $badgeCount, sessionsShownTo: $sessionsShownTo)';
}


}

/// @nodoc
abstract mixin class _$ProfileSummaryCopyWith<$Res> implements $ProfileSummaryCopyWith<$Res> {
  factory _$ProfileSummaryCopyWith(_ProfileSummary value, $Res Function(_ProfileSummary) _then) = __$ProfileSummaryCopyWithImpl;
@override @useResult
$Res call({
 int sessions, int? clubRank, int? localRank, String? area, List<ProfileBadge> badges, int badgeCount, String sessionsShownTo
});




}
/// @nodoc
class __$ProfileSummaryCopyWithImpl<$Res>
    implements _$ProfileSummaryCopyWith<$Res> {
  __$ProfileSummaryCopyWithImpl(this._self, this._then);

  final _ProfileSummary _self;
  final $Res Function(_ProfileSummary) _then;

/// Create a copy of ProfileSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessions = null,Object? clubRank = freezed,Object? localRank = freezed,Object? area = freezed,Object? badges = null,Object? badgeCount = null,Object? sessionsShownTo = null,}) {
  return _then(_ProfileSummary(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,clubRank: freezed == clubRank ? _self.clubRank : clubRank // ignore: cast_nullable_to_non_nullable
as int?,localRank: freezed == localRank ? _self.localRank : localRank // ignore: cast_nullable_to_non_nullable
as int?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<ProfileBadge>,badgeCount: null == badgeCount ? _self.badgeCount : badgeCount // ignore: cast_nullable_to_non_nullable
as int,sessionsShownTo: null == sessionsShownTo ? _self.sessionsShownTo : sessionsShownTo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

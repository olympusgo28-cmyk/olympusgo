// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'club_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClubSportLevel {

 ClubSport get sport; LevelRange get range;
/// Create a copy of ClubSportLevel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubSportLevelCopyWith<ClubSportLevel> get copyWith => _$ClubSportLevelCopyWithImpl<ClubSportLevel>(this as ClubSportLevel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubSportLevel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubSportLevel&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.range, _this.range) || other.range == _this.range));
}


@override
int get hashCode {
  final _this = this as ClubSportLevel;
  return Object.hash(runtimeType,_this.sport,_this.range);
}

@override
String toString() {
  final _this = this as ClubSportLevel;
  return 'ClubSportLevel(sport: ${_this.sport}, range: ${_this.range})';
}


}

/// @nodoc
abstract mixin class $ClubSportLevelCopyWith<$Res>  {
  factory $ClubSportLevelCopyWith(ClubSportLevel value, $Res Function(ClubSportLevel) _then) = _$ClubSportLevelCopyWithImpl;
@useResult
$Res call({
 ClubSport sport, LevelRange range
});




}
/// @nodoc
class _$ClubSportLevelCopyWithImpl<$Res>
    implements $ClubSportLevelCopyWith<$Res> {
  _$ClubSportLevelCopyWithImpl(this._self, this._then);

  final ClubSportLevel _self;
  final $Res Function(ClubSportLevel) _then;

/// Create a copy of ClubSportLevel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sport = null,Object? range = null,}) {
  return _then(ClubSportLevel(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as ClubSport,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as LevelRange,
  ));
}

}


/// Adds pattern-matching-related methods to [ClubSportLevel].
extension ClubSportLevelPatterns on ClubSportLevel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubSportLevel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubSportLevel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubSportLevel value)  $default,){
final _that = this;
switch (_that) {
case _ClubSportLevel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubSportLevel value)?  $default,){
final _that = this;
switch (_that) {
case _ClubSportLevel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ClubSport sport,  LevelRange range)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubSportLevel() when $default != null:
return $default(_that.sport,_that.range);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ClubSport sport,  LevelRange range)  $default,) {final _that = this;
switch (_that) {
case _ClubSportLevel():
return $default(_that.sport,_that.range);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ClubSport sport,  LevelRange range)?  $default,) {final _that = this;
switch (_that) {
case _ClubSportLevel() when $default != null:
return $default(_that.sport,_that.range);case _:
  return null;

}
}

}

/// @nodoc


class _ClubSportLevel implements ClubSportLevel {
  const _ClubSportLevel({required this.sport, this.range = const LevelRange.all()});
  

@override final  ClubSport sport;
@override@JsonKey() final  LevelRange range;

/// Create a copy of ClubSportLevel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubSportLevelCopyWith<_ClubSportLevel> get copyWith => __$ClubSportLevelCopyWithImpl<_ClubSportLevel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubSportLevel&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.range, range) || other.range == range));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sport,range);
}

@override
String toString() {
    return 'ClubSportLevel(sport: $sport, range: $range)';
}


}

/// @nodoc
abstract mixin class _$ClubSportLevelCopyWith<$Res> implements $ClubSportLevelCopyWith<$Res> {
  factory _$ClubSportLevelCopyWith(_ClubSportLevel value, $Res Function(_ClubSportLevel) _then) = __$ClubSportLevelCopyWithImpl;
@override @useResult
$Res call({
 ClubSport sport, LevelRange range
});




}
/// @nodoc
class __$ClubSportLevelCopyWithImpl<$Res>
    implements _$ClubSportLevelCopyWith<$Res> {
  __$ClubSportLevelCopyWithImpl(this._self, this._then);

  final _ClubSportLevel _self;
  final $Res Function(_ClubSportLevel) _then;

/// Create a copy of ClubSportLevel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sport = null,Object? range = null,}) {
  return _then(_ClubSportLevel(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as ClubSport,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as LevelRange,
  ));
}


}

/// @nodoc
mixin _$Club {

 String get id; String get name; String get description; List<String> get rules; String get area; String? get homeVenue; List<ClubSportLevel> get sports; ClubVisibility get visibility; JoinMode get joinMode; int get memberCount; double? get rating; int get ratingCount; List<int> get ratingSpread;/// The viewer's own stars, once they have rated the club.
 int? get myStars; int get logoColor; int get logoInk; int get coverColor; DateTime? get createdAt; int get meetsPerWeek; ClubStanding get standing; bool get isOwner; Set<ClubPermission> get myPermissions; String? get myRoleName; int get pendingRequests; int get unreadChat; int get roleCount; int get banCount; int get activeInvites; Map<String, String> get playRules; String? get inviteCode;
/// Create a copy of Club
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubCopyWith<Club> get copyWith => _$ClubCopyWithImpl<Club>(this as Club, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Club;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Club&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.rules, _this.rules)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.homeVenue, _this.homeVenue) || other.homeVenue == _this.homeVenue)&&const DeepCollectionEquality().equals(other.sports, _this.sports)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&(identical(other.joinMode, _this.joinMode) || other.joinMode == _this.joinMode)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&const DeepCollectionEquality().equals(other.ratingSpread, _this.ratingSpread)&&(identical(other.myStars, _this.myStars) || other.myStars == _this.myStars)&&(identical(other.logoColor, _this.logoColor) || other.logoColor == _this.logoColor)&&(identical(other.logoInk, _this.logoInk) || other.logoInk == _this.logoInk)&&(identical(other.coverColor, _this.coverColor) || other.coverColor == _this.coverColor)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.meetsPerWeek, _this.meetsPerWeek) || other.meetsPerWeek == _this.meetsPerWeek)&&(identical(other.standing, _this.standing) || other.standing == _this.standing)&&(identical(other.isOwner, _this.isOwner) || other.isOwner == _this.isOwner)&&const DeepCollectionEquality().equals(other.myPermissions, _this.myPermissions)&&(identical(other.myRoleName, _this.myRoleName) || other.myRoleName == _this.myRoleName)&&(identical(other.pendingRequests, _this.pendingRequests) || other.pendingRequests == _this.pendingRequests)&&(identical(other.unreadChat, _this.unreadChat) || other.unreadChat == _this.unreadChat)&&(identical(other.roleCount, _this.roleCount) || other.roleCount == _this.roleCount)&&(identical(other.banCount, _this.banCount) || other.banCount == _this.banCount)&&(identical(other.activeInvites, _this.activeInvites) || other.activeInvites == _this.activeInvites)&&const DeepCollectionEquality().equals(other.playRules, _this.playRules)&&(identical(other.inviteCode, _this.inviteCode) || other.inviteCode == _this.inviteCode));
}


@override
int get hashCode {
  final _this = this as Club;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.description,const DeepCollectionEquality().hash(_this.rules),_this.area,_this.homeVenue,const DeepCollectionEquality().hash(_this.sports),_this.visibility,_this.joinMode,_this.memberCount,_this.rating,_this.ratingCount,const DeepCollectionEquality().hash(_this.ratingSpread),_this.myStars,_this.logoColor,_this.logoInk,_this.coverColor,_this.createdAt,_this.meetsPerWeek,_this.standing,_this.isOwner,const DeepCollectionEquality().hash(_this.myPermissions),_this.myRoleName,_this.pendingRequests,_this.unreadChat,_this.roleCount,_this.banCount,_this.activeInvites,const DeepCollectionEquality().hash(_this.playRules),_this.inviteCode]);
}

@override
String toString() {
  final _this = this as Club;
  return 'Club(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, rules: ${_this.rules}, area: ${_this.area}, homeVenue: ${_this.homeVenue}, sports: ${_this.sports}, visibility: ${_this.visibility}, joinMode: ${_this.joinMode}, memberCount: ${_this.memberCount}, rating: ${_this.rating}, ratingCount: ${_this.ratingCount}, ratingSpread: ${_this.ratingSpread}, myStars: ${_this.myStars}, logoColor: ${_this.logoColor}, logoInk: ${_this.logoInk}, coverColor: ${_this.coverColor}, createdAt: ${_this.createdAt}, meetsPerWeek: ${_this.meetsPerWeek}, standing: ${_this.standing}, isOwner: ${_this.isOwner}, myPermissions: ${_this.myPermissions}, myRoleName: ${_this.myRoleName}, pendingRequests: ${_this.pendingRequests}, unreadChat: ${_this.unreadChat}, roleCount: ${_this.roleCount}, banCount: ${_this.banCount}, activeInvites: ${_this.activeInvites}, playRules: ${_this.playRules}, inviteCode: ${_this.inviteCode})';
}


}

/// @nodoc
abstract mixin class $ClubCopyWith<$Res>  {
  factory $ClubCopyWith(Club value, $Res Function(Club) _then) = _$ClubCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, List<String> rules, String area, String? homeVenue, List<ClubSportLevel> sports, ClubVisibility visibility, JoinMode joinMode, int memberCount, double? rating, int ratingCount, List<int> ratingSpread, int? myStars, int logoColor, int logoInk, int coverColor, DateTime? createdAt, int meetsPerWeek, ClubStanding standing, bool isOwner, Set<ClubPermission> myPermissions, String? myRoleName, int pendingRequests, int unreadChat, int roleCount, int banCount, int activeInvites, Map<String, String> playRules, String? inviteCode
});




}
/// @nodoc
class _$ClubCopyWithImpl<$Res>
    implements $ClubCopyWith<$Res> {
  _$ClubCopyWithImpl(this._self, this._then);

  final Club _self;
  final $Res Function(Club) _then;

/// Create a copy of Club
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? rules = null,Object? area = null,Object? homeVenue = freezed,Object? sports = null,Object? visibility = null,Object? joinMode = null,Object? memberCount = null,Object? rating = freezed,Object? ratingCount = null,Object? ratingSpread = null,Object? myStars = freezed,Object? logoColor = null,Object? logoInk = null,Object? coverColor = null,Object? createdAt = freezed,Object? meetsPerWeek = null,Object? standing = null,Object? isOwner = null,Object? myPermissions = null,Object? myRoleName = freezed,Object? pendingRequests = null,Object? unreadChat = null,Object? roleCount = null,Object? banCount = null,Object? activeInvites = null,Object? playRules = null,Object? inviteCode = freezed,}) {
  return _then(Club(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<String>,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,homeVenue: freezed == homeVenue ? _self.homeVenue : homeVenue // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self.sports : sports // ignore: cast_nullable_to_non_nullable
as List<ClubSportLevel>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ClubVisibility,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as JoinMode,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,ratingSpread: null == ratingSpread ? _self.ratingSpread : ratingSpread // ignore: cast_nullable_to_non_nullable
as List<int>,myStars: freezed == myStars ? _self.myStars : myStars // ignore: cast_nullable_to_non_nullable
as int?,logoColor: null == logoColor ? _self.logoColor : logoColor // ignore: cast_nullable_to_non_nullable
as int,logoInk: null == logoInk ? _self.logoInk : logoInk // ignore: cast_nullable_to_non_nullable
as int,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,meetsPerWeek: null == meetsPerWeek ? _self.meetsPerWeek : meetsPerWeek // ignore: cast_nullable_to_non_nullable
as int,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as ClubStanding,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,myPermissions: null == myPermissions ? _self.myPermissions : myPermissions // ignore: cast_nullable_to_non_nullable
as Set<ClubPermission>,myRoleName: freezed == myRoleName ? _self.myRoleName : myRoleName // ignore: cast_nullable_to_non_nullable
as String?,pendingRequests: null == pendingRequests ? _self.pendingRequests : pendingRequests // ignore: cast_nullable_to_non_nullable
as int,unreadChat: null == unreadChat ? _self.unreadChat : unreadChat // ignore: cast_nullable_to_non_nullable
as int,roleCount: null == roleCount ? _self.roleCount : roleCount // ignore: cast_nullable_to_non_nullable
as int,banCount: null == banCount ? _self.banCount : banCount // ignore: cast_nullable_to_non_nullable
as int,activeInvites: null == activeInvites ? _self.activeInvites : activeInvites // ignore: cast_nullable_to_non_nullable
as int,playRules: null == playRules ? _self.playRules : playRules // ignore: cast_nullable_to_non_nullable
as Map<String, String>,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Club].
extension ClubPatterns on Club {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Club value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Club() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Club value)  $default,){
final _that = this;
switch (_that) {
case _Club():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Club value)?  $default,){
final _that = this;
switch (_that) {
case _Club() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> rules,  String area,  String? homeVenue,  List<ClubSportLevel> sports,  ClubVisibility visibility,  JoinMode joinMode,  int memberCount,  double? rating,  int ratingCount,  List<int> ratingSpread,  int? myStars,  int logoColor,  int logoInk,  int coverColor,  DateTime? createdAt,  int meetsPerWeek,  ClubStanding standing,  bool isOwner,  Set<ClubPermission> myPermissions,  String? myRoleName,  int pendingRequests,  int unreadChat,  int roleCount,  int banCount,  int activeInvites,  Map<String, String> playRules,  String? inviteCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Club() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.rules,_that.area,_that.homeVenue,_that.sports,_that.visibility,_that.joinMode,_that.memberCount,_that.rating,_that.ratingCount,_that.ratingSpread,_that.myStars,_that.logoColor,_that.logoInk,_that.coverColor,_that.createdAt,_that.meetsPerWeek,_that.standing,_that.isOwner,_that.myPermissions,_that.myRoleName,_that.pendingRequests,_that.unreadChat,_that.roleCount,_that.banCount,_that.activeInvites,_that.playRules,_that.inviteCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> rules,  String area,  String? homeVenue,  List<ClubSportLevel> sports,  ClubVisibility visibility,  JoinMode joinMode,  int memberCount,  double? rating,  int ratingCount,  List<int> ratingSpread,  int? myStars,  int logoColor,  int logoInk,  int coverColor,  DateTime? createdAt,  int meetsPerWeek,  ClubStanding standing,  bool isOwner,  Set<ClubPermission> myPermissions,  String? myRoleName,  int pendingRequests,  int unreadChat,  int roleCount,  int banCount,  int activeInvites,  Map<String, String> playRules,  String? inviteCode)  $default,) {final _that = this;
switch (_that) {
case _Club():
return $default(_that.id,_that.name,_that.description,_that.rules,_that.area,_that.homeVenue,_that.sports,_that.visibility,_that.joinMode,_that.memberCount,_that.rating,_that.ratingCount,_that.ratingSpread,_that.myStars,_that.logoColor,_that.logoInk,_that.coverColor,_that.createdAt,_that.meetsPerWeek,_that.standing,_that.isOwner,_that.myPermissions,_that.myRoleName,_that.pendingRequests,_that.unreadChat,_that.roleCount,_that.banCount,_that.activeInvites,_that.playRules,_that.inviteCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  List<String> rules,  String area,  String? homeVenue,  List<ClubSportLevel> sports,  ClubVisibility visibility,  JoinMode joinMode,  int memberCount,  double? rating,  int ratingCount,  List<int> ratingSpread,  int? myStars,  int logoColor,  int logoInk,  int coverColor,  DateTime? createdAt,  int meetsPerWeek,  ClubStanding standing,  bool isOwner,  Set<ClubPermission> myPermissions,  String? myRoleName,  int pendingRequests,  int unreadChat,  int roleCount,  int banCount,  int activeInvites,  Map<String, String> playRules,  String? inviteCode)?  $default,) {final _that = this;
switch (_that) {
case _Club() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.rules,_that.area,_that.homeVenue,_that.sports,_that.visibility,_that.joinMode,_that.memberCount,_that.rating,_that.ratingCount,_that.ratingSpread,_that.myStars,_that.logoColor,_that.logoInk,_that.coverColor,_that.createdAt,_that.meetsPerWeek,_that.standing,_that.isOwner,_that.myPermissions,_that.myRoleName,_that.pendingRequests,_that.unreadChat,_that.roleCount,_that.banCount,_that.activeInvites,_that.playRules,_that.inviteCode);case _:
  return null;

}
}

}

/// @nodoc


class _Club extends Club {
  const _Club({required this.id, required this.name, this.description = '',  List<String> rules = const [], this.area = '', this.homeVenue,  List<ClubSportLevel> sports = const [], this.visibility = ClubVisibility.public, this.joinMode = JoinMode.request, this.memberCount = 0, this.rating, this.ratingCount = 0,  List<int> ratingSpread = const [0, 0, 0, 0, 0], this.myStars, this.logoColor = 0xFF1C1F23, this.logoInk = 0xFFF2C14E, this.coverColor = 0xFFE8590C, this.createdAt, this.meetsPerWeek = 0, this.standing = ClubStanding.outsider, this.isOwner = false,  Set<ClubPermission> myPermissions = const {}, this.myRoleName, this.pendingRequests = 0, this.unreadChat = 0, this.roleCount = 0, this.banCount = 0, this.activeInvites = 0,  Map<String, String> playRules = const {}, this.inviteCode}): _rules = rules,_sports = sports,_ratingSpread = ratingSpread,_myPermissions = myPermissions,_playRules = playRules,super._();
  

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
 final  List<String> _rules;
@override@JsonKey() List<String> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

@override@JsonKey() final  String area;
@override final  String? homeVenue;
 final  List<ClubSportLevel> _sports;
@override@JsonKey() List<ClubSportLevel> get sports {
  if (_sports is EqualUnmodifiableListView) return _sports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sports);
}

@override@JsonKey() final  ClubVisibility visibility;
@override@JsonKey() final  JoinMode joinMode;
@override@JsonKey() final  int memberCount;
@override final  double? rating;
@override@JsonKey() final  int ratingCount;
 final  List<int> _ratingSpread;
@override@JsonKey() List<int> get ratingSpread {
  if (_ratingSpread is EqualUnmodifiableListView) return _ratingSpread;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ratingSpread);
}

/// The viewer's own stars, once they have rated the club.
@override final  int? myStars;
@override@JsonKey() final  int logoColor;
@override@JsonKey() final  int logoInk;
@override@JsonKey() final  int coverColor;
@override final  DateTime? createdAt;
@override@JsonKey() final  int meetsPerWeek;
@override@JsonKey() final  ClubStanding standing;
@override@JsonKey() final  bool isOwner;
 final  Set<ClubPermission> _myPermissions;
@override@JsonKey() Set<ClubPermission> get myPermissions {
  if (_myPermissions is EqualUnmodifiableSetView) return _myPermissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_myPermissions);
}

@override final  String? myRoleName;
@override@JsonKey() final  int pendingRequests;
@override@JsonKey() final  int unreadChat;
@override@JsonKey() final  int roleCount;
@override@JsonKey() final  int banCount;
@override@JsonKey() final  int activeInvites;
 final  Map<String, String> _playRules;
@override@JsonKey() Map<String, String> get playRules {
  if (_playRules is EqualUnmodifiableMapView) return _playRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playRules);
}

@override final  String? inviteCode;

/// Create a copy of Club
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubCopyWith<_Club> get copyWith => __$ClubCopyWithImpl<_Club>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Club&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.rules, _rules)&&(identical(other.area, area) || other.area == area)&&(identical(other.homeVenue, homeVenue) || other.homeVenue == homeVenue)&&const DeepCollectionEquality().equals(other.sports, _sports)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&const DeepCollectionEquality().equals(other.ratingSpread, _ratingSpread)&&(identical(other.myStars, myStars) || other.myStars == myStars)&&(identical(other.logoColor, logoColor) || other.logoColor == logoColor)&&(identical(other.logoInk, logoInk) || other.logoInk == logoInk)&&(identical(other.coverColor, coverColor) || other.coverColor == coverColor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.meetsPerWeek, meetsPerWeek) || other.meetsPerWeek == meetsPerWeek)&&(identical(other.standing, standing) || other.standing == standing)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&const DeepCollectionEquality().equals(other.myPermissions, _myPermissions)&&(identical(other.myRoleName, myRoleName) || other.myRoleName == myRoleName)&&(identical(other.pendingRequests, pendingRequests) || other.pendingRequests == pendingRequests)&&(identical(other.unreadChat, unreadChat) || other.unreadChat == unreadChat)&&(identical(other.roleCount, roleCount) || other.roleCount == roleCount)&&(identical(other.banCount, banCount) || other.banCount == banCount)&&(identical(other.activeInvites, activeInvites) || other.activeInvites == activeInvites)&&const DeepCollectionEquality().equals(other.playRules, _playRules)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,description,const DeepCollectionEquality().hash(_rules),area,homeVenue,const DeepCollectionEquality().hash(_sports),visibility,joinMode,memberCount,rating,ratingCount,const DeepCollectionEquality().hash(_ratingSpread),myStars,logoColor,logoInk,coverColor,createdAt,meetsPerWeek,standing,isOwner,const DeepCollectionEquality().hash(_myPermissions),myRoleName,pendingRequests,unreadChat,roleCount,banCount,activeInvites,const DeepCollectionEquality().hash(_playRules),inviteCode]);
}

@override
String toString() {
    return 'Club(id: $id, name: $name, description: $description, rules: $rules, area: $area, homeVenue: $homeVenue, sports: $sports, visibility: $visibility, joinMode: $joinMode, memberCount: $memberCount, rating: $rating, ratingCount: $ratingCount, ratingSpread: $ratingSpread, myStars: $myStars, logoColor: $logoColor, logoInk: $logoInk, coverColor: $coverColor, createdAt: $createdAt, meetsPerWeek: $meetsPerWeek, standing: $standing, isOwner: $isOwner, myPermissions: $myPermissions, myRoleName: $myRoleName, pendingRequests: $pendingRequests, unreadChat: $unreadChat, roleCount: $roleCount, banCount: $banCount, activeInvites: $activeInvites, playRules: $playRules, inviteCode: $inviteCode)';
}


}

/// @nodoc
abstract mixin class _$ClubCopyWith<$Res> implements $ClubCopyWith<$Res> {
  factory _$ClubCopyWith(_Club value, $Res Function(_Club) _then) = __$ClubCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, List<String> rules, String area, String? homeVenue, List<ClubSportLevel> sports, ClubVisibility visibility, JoinMode joinMode, int memberCount, double? rating, int ratingCount, List<int> ratingSpread, int? myStars, int logoColor, int logoInk, int coverColor, DateTime? createdAt, int meetsPerWeek, ClubStanding standing, bool isOwner, Set<ClubPermission> myPermissions, String? myRoleName, int pendingRequests, int unreadChat, int roleCount, int banCount, int activeInvites, Map<String, String> playRules, String? inviteCode
});




}
/// @nodoc
class __$ClubCopyWithImpl<$Res>
    implements _$ClubCopyWith<$Res> {
  __$ClubCopyWithImpl(this._self, this._then);

  final _Club _self;
  final $Res Function(_Club) _then;

/// Create a copy of Club
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? rules = null,Object? area = null,Object? homeVenue = freezed,Object? sports = null,Object? visibility = null,Object? joinMode = null,Object? memberCount = null,Object? rating = freezed,Object? ratingCount = null,Object? ratingSpread = null,Object? myStars = freezed,Object? logoColor = null,Object? logoInk = null,Object? coverColor = null,Object? createdAt = freezed,Object? meetsPerWeek = null,Object? standing = null,Object? isOwner = null,Object? myPermissions = null,Object? myRoleName = freezed,Object? pendingRequests = null,Object? unreadChat = null,Object? roleCount = null,Object? banCount = null,Object? activeInvites = null,Object? playRules = null,Object? inviteCode = freezed,}) {
  return _then(_Club(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<String>,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,homeVenue: freezed == homeVenue ? _self.homeVenue : homeVenue // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self._sports : sports // ignore: cast_nullable_to_non_nullable
as List<ClubSportLevel>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ClubVisibility,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as JoinMode,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,ratingSpread: null == ratingSpread ? _self._ratingSpread : ratingSpread // ignore: cast_nullable_to_non_nullable
as List<int>,myStars: freezed == myStars ? _self.myStars : myStars // ignore: cast_nullable_to_non_nullable
as int?,logoColor: null == logoColor ? _self.logoColor : logoColor // ignore: cast_nullable_to_non_nullable
as int,logoInk: null == logoInk ? _self.logoInk : logoInk // ignore: cast_nullable_to_non_nullable
as int,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,meetsPerWeek: null == meetsPerWeek ? _self.meetsPerWeek : meetsPerWeek // ignore: cast_nullable_to_non_nullable
as int,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as ClubStanding,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,myPermissions: null == myPermissions ? _self._myPermissions : myPermissions // ignore: cast_nullable_to_non_nullable
as Set<ClubPermission>,myRoleName: freezed == myRoleName ? _self.myRoleName : myRoleName // ignore: cast_nullable_to_non_nullable
as String?,pendingRequests: null == pendingRequests ? _self.pendingRequests : pendingRequests // ignore: cast_nullable_to_non_nullable
as int,unreadChat: null == unreadChat ? _self.unreadChat : unreadChat // ignore: cast_nullable_to_non_nullable
as int,roleCount: null == roleCount ? _self.roleCount : roleCount // ignore: cast_nullable_to_non_nullable
as int,banCount: null == banCount ? _self.banCount : banCount // ignore: cast_nullable_to_non_nullable
as int,activeInvites: null == activeInvites ? _self.activeInvites : activeInvites // ignore: cast_nullable_to_non_nullable
as int,playRules: null == playRules ? _self._playRules : playRules // ignore: cast_nullable_to_non_nullable
as Map<String, String>,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ClubListItem {

 Club get club; String get note;
/// Create a copy of ClubListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubListItemCopyWith<ClubListItem> get copyWith => _$ClubListItemCopyWithImpl<ClubListItem>(this as ClubListItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubListItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubListItem&&(identical(other.club, _this.club) || other.club == _this.club)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as ClubListItem;
  return Object.hash(runtimeType,_this.club,_this.note);
}

@override
String toString() {
  final _this = this as ClubListItem;
  return 'ClubListItem(club: ${_this.club}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $ClubListItemCopyWith<$Res>  {
  factory $ClubListItemCopyWith(ClubListItem value, $Res Function(ClubListItem) _then) = _$ClubListItemCopyWithImpl;
@useResult
$Res call({
 Club club, String note
});


$ClubCopyWith<$Res> get club;

}
/// @nodoc
class _$ClubListItemCopyWithImpl<$Res>
    implements $ClubListItemCopyWith<$Res> {
  _$ClubListItemCopyWithImpl(this._self, this._then);

  final ClubListItem _self;
  final $Res Function(ClubListItem) _then;

/// Create a copy of ClubListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? club = null,Object? note = null,}) {
  return _then(ClubListItem(
club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as Club,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ClubListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClubCopyWith<$Res> get club {
  
  return $ClubCopyWith<$Res>(_self.club, (value) {
    return _then(_self.copyWith(club: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClubListItem].
extension ClubListItemPatterns on ClubListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubListItem value)  $default,){
final _that = this;
switch (_that) {
case _ClubListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubListItem value)?  $default,){
final _that = this;
switch (_that) {
case _ClubListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Club club,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubListItem() when $default != null:
return $default(_that.club,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Club club,  String note)  $default,) {final _that = this;
switch (_that) {
case _ClubListItem():
return $default(_that.club,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Club club,  String note)?  $default,) {final _that = this;
switch (_that) {
case _ClubListItem() when $default != null:
return $default(_that.club,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _ClubListItem implements ClubListItem {
  const _ClubListItem({required this.club, this.note = ''});
  

@override final  Club club;
@override@JsonKey() final  String note;

/// Create a copy of ClubListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubListItemCopyWith<_ClubListItem> get copyWith => __$ClubListItemCopyWithImpl<_ClubListItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubListItem&&(identical(other.club, club) || other.club == club)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,club,note);
}

@override
String toString() {
    return 'ClubListItem(club: $club, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ClubListItemCopyWith<$Res> implements $ClubListItemCopyWith<$Res> {
  factory _$ClubListItemCopyWith(_ClubListItem value, $Res Function(_ClubListItem) _then) = __$ClubListItemCopyWithImpl;
@override @useResult
$Res call({
 Club club, String note
});


@override $ClubCopyWith<$Res> get club;

}
/// @nodoc
class __$ClubListItemCopyWithImpl<$Res>
    implements _$ClubListItemCopyWith<$Res> {
  __$ClubListItemCopyWithImpl(this._self, this._then);

  final _ClubListItem _self;
  final $Res Function(_ClubListItem) _then;

/// Create a copy of ClubListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? club = null,Object? note = null,}) {
  return _then(_ClubListItem(
club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as Club,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ClubListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClubCopyWith<$Res> get club {
  
  return $ClubCopyWith<$Res>(_self.club, (value) {
    return _then(_self.copyWith(club: value));
  });
}
}

/// @nodoc
mixin _$ClubRole {

 String get id; String get name; int get color; RoleLevel get level; Set<ClubPermission> get permissions; int get memberCount; bool get showBadge; bool get isOwner; int get position;
/// Create a copy of ClubRole
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubRoleCopyWith<ClubRole> get copyWith => _$ClubRoleCopyWithImpl<ClubRole>(this as ClubRole, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubRole;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubRole&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.level, _this.level) || other.level == _this.level)&&const DeepCollectionEquality().equals(other.permissions, _this.permissions)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.showBadge, _this.showBadge) || other.showBadge == _this.showBadge)&&(identical(other.isOwner, _this.isOwner) || other.isOwner == _this.isOwner)&&(identical(other.position, _this.position) || other.position == _this.position));
}


@override
int get hashCode {
  final _this = this as ClubRole;
  return Object.hash(runtimeType,_this.id,_this.name,_this.color,_this.level,const DeepCollectionEquality().hash(_this.permissions),_this.memberCount,_this.showBadge,_this.isOwner,_this.position);
}

@override
String toString() {
  final _this = this as ClubRole;
  return 'ClubRole(id: ${_this.id}, name: ${_this.name}, color: ${_this.color}, level: ${_this.level}, permissions: ${_this.permissions}, memberCount: ${_this.memberCount}, showBadge: ${_this.showBadge}, isOwner: ${_this.isOwner}, position: ${_this.position})';
}


}

/// @nodoc
abstract mixin class $ClubRoleCopyWith<$Res>  {
  factory $ClubRoleCopyWith(ClubRole value, $Res Function(ClubRole) _then) = _$ClubRoleCopyWithImpl;
@useResult
$Res call({
 String id, String name, int color, RoleLevel level, Set<ClubPermission> permissions, int memberCount, bool showBadge, bool isOwner, int position
});




}
/// @nodoc
class _$ClubRoleCopyWithImpl<$Res>
    implements $ClubRoleCopyWith<$Res> {
  _$ClubRoleCopyWithImpl(this._self, this._then);

  final ClubRole _self;
  final $Res Function(ClubRole) _then;

/// Create a copy of ClubRole
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? color = null,Object? level = null,Object? permissions = null,Object? memberCount = null,Object? showBadge = null,Object? isOwner = null,Object? position = null,}) {
  return _then(ClubRole(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as RoleLevel,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as Set<ClubPermission>,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,showBadge: null == showBadge ? _self.showBadge : showBadge // ignore: cast_nullable_to_non_nullable
as bool,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ClubRole].
extension ClubRolePatterns on ClubRole {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubRole value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubRole() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubRole value)  $default,){
final _that = this;
switch (_that) {
case _ClubRole():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubRole value)?  $default,){
final _that = this;
switch (_that) {
case _ClubRole() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int color,  RoleLevel level,  Set<ClubPermission> permissions,  int memberCount,  bool showBadge,  bool isOwner,  int position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubRole() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.level,_that.permissions,_that.memberCount,_that.showBadge,_that.isOwner,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int color,  RoleLevel level,  Set<ClubPermission> permissions,  int memberCount,  bool showBadge,  bool isOwner,  int position)  $default,) {final _that = this;
switch (_that) {
case _ClubRole():
return $default(_that.id,_that.name,_that.color,_that.level,_that.permissions,_that.memberCount,_that.showBadge,_that.isOwner,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int color,  RoleLevel level,  Set<ClubPermission> permissions,  int memberCount,  bool showBadge,  bool isOwner,  int position)?  $default,) {final _that = this;
switch (_that) {
case _ClubRole() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.level,_that.permissions,_that.memberCount,_that.showBadge,_that.isOwner,_that.position);case _:
  return null;

}
}

}

/// @nodoc


class _ClubRole extends ClubRole {
  const _ClubRole({required this.id, required this.name, this.color = 0xFF7A8088, this.level = RoleLevel.member,  Set<ClubPermission> permissions = const {}, this.memberCount = 0, this.showBadge = true, this.isOwner = false, this.position = 0}): _permissions = permissions,super._();
  

@override final  String id;
@override final  String name;
@override@JsonKey() final  int color;
@override@JsonKey() final  RoleLevel level;
 final  Set<ClubPermission> _permissions;
@override@JsonKey() Set<ClubPermission> get permissions {
  if (_permissions is EqualUnmodifiableSetView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_permissions);
}

@override@JsonKey() final  int memberCount;
@override@JsonKey() final  bool showBadge;
@override@JsonKey() final  bool isOwner;
@override@JsonKey() final  int position;

/// Create a copy of ClubRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubRoleCopyWith<_ClubRole> get copyWith => __$ClubRoleCopyWithImpl<_ClubRole>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubRole&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.permissions, _permissions)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.showBadge, showBadge) || other.showBadge == showBadge)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,color,level,const DeepCollectionEquality().hash(_permissions),memberCount,showBadge,isOwner,position);
}

@override
String toString() {
    return 'ClubRole(id: $id, name: $name, color: $color, level: $level, permissions: $permissions, memberCount: $memberCount, showBadge: $showBadge, isOwner: $isOwner, position: $position)';
}


}

/// @nodoc
abstract mixin class _$ClubRoleCopyWith<$Res> implements $ClubRoleCopyWith<$Res> {
  factory _$ClubRoleCopyWith(_ClubRole value, $Res Function(_ClubRole) _then) = __$ClubRoleCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int color, RoleLevel level, Set<ClubPermission> permissions, int memberCount, bool showBadge, bool isOwner, int position
});




}
/// @nodoc
class __$ClubRoleCopyWithImpl<$Res>
    implements _$ClubRoleCopyWith<$Res> {
  __$ClubRoleCopyWithImpl(this._self, this._then);

  final _ClubRole _self;
  final $Res Function(_ClubRole) _then;

/// Create a copy of ClubRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? color = null,Object? level = null,Object? permissions = null,Object? memberCount = null,Object? showBadge = null,Object? isOwner = null,Object? position = null,}) {
  return _then(_ClubRole(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as RoleLevel,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as Set<ClubPermission>,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,showBadge: null == showBadge ? _self.showBadge : showBadge // ignore: cast_nullable_to_non_nullable
as bool,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ClubMember {

 PlayerSummary get player; double? get rating; List<String> get roleIds; DateTime? get joinedAt; int get meetsPlayed; int get noShows; int get paidCents;
/// Create a copy of ClubMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubMemberCopyWith<ClubMember> get copyWith => _$ClubMemberCopyWithImpl<ClubMember>(this as ClubMember, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubMember&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&const DeepCollectionEquality().equals(other.roleIds, _this.roleIds)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.meetsPlayed, _this.meetsPlayed) || other.meetsPlayed == _this.meetsPlayed)&&(identical(other.noShows, _this.noShows) || other.noShows == _this.noShows)&&(identical(other.paidCents, _this.paidCents) || other.paidCents == _this.paidCents));
}


@override
int get hashCode {
  final _this = this as ClubMember;
  return Object.hash(runtimeType,_this.player,_this.rating,const DeepCollectionEquality().hash(_this.roleIds),_this.joinedAt,_this.meetsPlayed,_this.noShows,_this.paidCents);
}

@override
String toString() {
  final _this = this as ClubMember;
  return 'ClubMember(player: ${_this.player}, rating: ${_this.rating}, roleIds: ${_this.roleIds}, joinedAt: ${_this.joinedAt}, meetsPlayed: ${_this.meetsPlayed}, noShows: ${_this.noShows}, paidCents: ${_this.paidCents})';
}


}

/// @nodoc
abstract mixin class $ClubMemberCopyWith<$Res>  {
  factory $ClubMemberCopyWith(ClubMember value, $Res Function(ClubMember) _then) = _$ClubMemberCopyWithImpl;
@useResult
$Res call({
 PlayerSummary player, double? rating, List<String> roleIds, DateTime? joinedAt, int meetsPlayed, int noShows, int paidCents
});


$PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class _$ClubMemberCopyWithImpl<$Res>
    implements $ClubMemberCopyWith<$Res> {
  _$ClubMemberCopyWithImpl(this._self, this._then);

  final ClubMember _self;
  final $Res Function(ClubMember) _then;

/// Create a copy of ClubMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? rating = freezed,Object? roleIds = null,Object? joinedAt = freezed,Object? meetsPlayed = null,Object? noShows = null,Object? paidCents = null,}) {
  return _then(ClubMember(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,roleIds: null == roleIds ? _self.roleIds : roleIds // ignore: cast_nullable_to_non_nullable
as List<String>,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,meetsPlayed: null == meetsPlayed ? _self.meetsPlayed : meetsPlayed // ignore: cast_nullable_to_non_nullable
as int,noShows: null == noShows ? _self.noShows : noShows // ignore: cast_nullable_to_non_nullable
as int,paidCents: null == paidCents ? _self.paidCents : paidCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ClubMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClubMember].
extension ClubMemberPatterns on ClubMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubMember value)  $default,){
final _that = this;
switch (_that) {
case _ClubMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubMember value)?  $default,){
final _that = this;
switch (_that) {
case _ClubMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerSummary player,  double? rating,  List<String> roleIds,  DateTime? joinedAt,  int meetsPlayed,  int noShows,  int paidCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubMember() when $default != null:
return $default(_that.player,_that.rating,_that.roleIds,_that.joinedAt,_that.meetsPlayed,_that.noShows,_that.paidCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerSummary player,  double? rating,  List<String> roleIds,  DateTime? joinedAt,  int meetsPlayed,  int noShows,  int paidCents)  $default,) {final _that = this;
switch (_that) {
case _ClubMember():
return $default(_that.player,_that.rating,_that.roleIds,_that.joinedAt,_that.meetsPlayed,_that.noShows,_that.paidCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerSummary player,  double? rating,  List<String> roleIds,  DateTime? joinedAt,  int meetsPlayed,  int noShows,  int paidCents)?  $default,) {final _that = this;
switch (_that) {
case _ClubMember() when $default != null:
return $default(_that.player,_that.rating,_that.roleIds,_that.joinedAt,_that.meetsPlayed,_that.noShows,_that.paidCents);case _:
  return null;

}
}

}

/// @nodoc


class _ClubMember extends ClubMember {
  const _ClubMember({required this.player, this.rating,  List<String> roleIds = const [], this.joinedAt, this.meetsPlayed = 0, this.noShows = 0, this.paidCents = 0}): _roleIds = roleIds,super._();
  

@override final  PlayerSummary player;
@override final  double? rating;
 final  List<String> _roleIds;
@override@JsonKey() List<String> get roleIds {
  if (_roleIds is EqualUnmodifiableListView) return _roleIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roleIds);
}

@override final  DateTime? joinedAt;
@override@JsonKey() final  int meetsPlayed;
@override@JsonKey() final  int noShows;
@override@JsonKey() final  int paidCents;

/// Create a copy of ClubMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubMemberCopyWith<_ClubMember> get copyWith => __$ClubMemberCopyWithImpl<_ClubMember>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubMember&&(identical(other.player, player) || other.player == player)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.roleIds, _roleIds)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.meetsPlayed, meetsPlayed) || other.meetsPlayed == meetsPlayed)&&(identical(other.noShows, noShows) || other.noShows == noShows)&&(identical(other.paidCents, paidCents) || other.paidCents == paidCents));
}


@override
int get hashCode {
    return Object.hash(runtimeType,player,rating,const DeepCollectionEquality().hash(_roleIds),joinedAt,meetsPlayed,noShows,paidCents);
}

@override
String toString() {
    return 'ClubMember(player: $player, rating: $rating, roleIds: $roleIds, joinedAt: $joinedAt, meetsPlayed: $meetsPlayed, noShows: $noShows, paidCents: $paidCents)';
}


}

/// @nodoc
abstract mixin class _$ClubMemberCopyWith<$Res> implements $ClubMemberCopyWith<$Res> {
  factory _$ClubMemberCopyWith(_ClubMember value, $Res Function(_ClubMember) _then) = __$ClubMemberCopyWithImpl;
@override @useResult
$Res call({
 PlayerSummary player, double? rating, List<String> roleIds, DateTime? joinedAt, int meetsPlayed, int noShows, int paidCents
});


@override $PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class __$ClubMemberCopyWithImpl<$Res>
    implements _$ClubMemberCopyWith<$Res> {
  __$ClubMemberCopyWithImpl(this._self, this._then);

  final _ClubMember _self;
  final $Res Function(_ClubMember) _then;

/// Create a copy of ClubMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? rating = freezed,Object? roleIds = null,Object? joinedAt = freezed,Object? meetsPlayed = null,Object? noShows = null,Object? paidCents = null,}) {
  return _then(_ClubMember(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,roleIds: null == roleIds ? _self._roleIds : roleIds // ignore: cast_nullable_to_non_nullable
as List<String>,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,meetsPlayed: null == meetsPlayed ? _self.meetsPlayed : meetsPlayed // ignore: cast_nullable_to_non_nullable
as int,noShows: null == noShows ? _self.noShows : noShows // ignore: cast_nullable_to_non_nullable
as int,paidCents: null == paidCents ? _self.paidCents : paidCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ClubMember
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
mixin _$JoinRequest {

 String get id; PlayerSummary get player; DateTime get createdAt; double? get rating; int get sessions; int get mutual; bool get provisional; bool get belowRange; String get message; RequestStatus get status;
/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinRequestCopyWith<JoinRequest> get copyWith => _$JoinRequestCopyWithImpl<JoinRequest>(this as JoinRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JoinRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.sessions, _this.sessions) || other.sessions == _this.sessions)&&(identical(other.mutual, _this.mutual) || other.mutual == _this.mutual)&&(identical(other.provisional, _this.provisional) || other.provisional == _this.provisional)&&(identical(other.belowRange, _this.belowRange) || other.belowRange == _this.belowRange)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.status, _this.status) || other.status == _this.status));
}


@override
int get hashCode {
  final _this = this as JoinRequest;
  return Object.hash(runtimeType,_this.id,_this.player,_this.createdAt,_this.rating,_this.sessions,_this.mutual,_this.provisional,_this.belowRange,_this.message,_this.status);
}

@override
String toString() {
  final _this = this as JoinRequest;
  return 'JoinRequest(id: ${_this.id}, player: ${_this.player}, createdAt: ${_this.createdAt}, rating: ${_this.rating}, sessions: ${_this.sessions}, mutual: ${_this.mutual}, provisional: ${_this.provisional}, belowRange: ${_this.belowRange}, message: ${_this.message}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $JoinRequestCopyWith<$Res>  {
  factory $JoinRequestCopyWith(JoinRequest value, $Res Function(JoinRequest) _then) = _$JoinRequestCopyWithImpl;
@useResult
$Res call({
 String id, PlayerSummary player, DateTime createdAt, double? rating, int sessions, int mutual, bool provisional, bool belowRange, String message, RequestStatus status
});


$PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class _$JoinRequestCopyWithImpl<$Res>
    implements $JoinRequestCopyWith<$Res> {
  _$JoinRequestCopyWithImpl(this._self, this._then);

  final JoinRequest _self;
  final $Res Function(JoinRequest) _then;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? player = null,Object? createdAt = null,Object? rating = freezed,Object? sessions = null,Object? mutual = null,Object? provisional = null,Object? belowRange = null,Object? message = null,Object? status = null,}) {
  return _then(JoinRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,mutual: null == mutual ? _self.mutual : mutual // ignore: cast_nullable_to_non_nullable
as int,provisional: null == provisional ? _self.provisional : provisional // ignore: cast_nullable_to_non_nullable
as bool,belowRange: null == belowRange ? _self.belowRange : belowRange // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,
  ));
}
/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [JoinRequest].
extension JoinRequestPatterns on JoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _JoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PlayerSummary player,  DateTime createdAt,  double? rating,  int sessions,  int mutual,  bool provisional,  bool belowRange,  String message,  RequestStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
return $default(_that.id,_that.player,_that.createdAt,_that.rating,_that.sessions,_that.mutual,_that.provisional,_that.belowRange,_that.message,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PlayerSummary player,  DateTime createdAt,  double? rating,  int sessions,  int mutual,  bool provisional,  bool belowRange,  String message,  RequestStatus status)  $default,) {final _that = this;
switch (_that) {
case _JoinRequest():
return $default(_that.id,_that.player,_that.createdAt,_that.rating,_that.sessions,_that.mutual,_that.provisional,_that.belowRange,_that.message,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PlayerSummary player,  DateTime createdAt,  double? rating,  int sessions,  int mutual,  bool provisional,  bool belowRange,  String message,  RequestStatus status)?  $default,) {final _that = this;
switch (_that) {
case _JoinRequest() when $default != null:
return $default(_that.id,_that.player,_that.createdAt,_that.rating,_that.sessions,_that.mutual,_that.provisional,_that.belowRange,_that.message,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _JoinRequest implements JoinRequest {
  const _JoinRequest({required this.id, required this.player, required this.createdAt, this.rating, this.sessions = 0, this.mutual = 0, this.provisional = false, this.belowRange = false, this.message = '', this.status = RequestStatus.pending});
  

@override final  String id;
@override final  PlayerSummary player;
@override final  DateTime createdAt;
@override final  double? rating;
@override@JsonKey() final  int sessions;
@override@JsonKey() final  int mutual;
@override@JsonKey() final  bool provisional;
@override@JsonKey() final  bool belowRange;
@override@JsonKey() final  String message;
@override@JsonKey() final  RequestStatus status;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinRequestCopyWith<_JoinRequest> get copyWith => __$JoinRequestCopyWithImpl<_JoinRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.player, player) || other.player == player)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.sessions, sessions) || other.sessions == sessions)&&(identical(other.mutual, mutual) || other.mutual == mutual)&&(identical(other.provisional, provisional) || other.provisional == provisional)&&(identical(other.belowRange, belowRange) || other.belowRange == belowRange)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,player,createdAt,rating,sessions,mutual,provisional,belowRange,message,status);
}

@override
String toString() {
    return 'JoinRequest(id: $id, player: $player, createdAt: $createdAt, rating: $rating, sessions: $sessions, mutual: $mutual, provisional: $provisional, belowRange: $belowRange, message: $message, status: $status)';
}


}

/// @nodoc
abstract mixin class _$JoinRequestCopyWith<$Res> implements $JoinRequestCopyWith<$Res> {
  factory _$JoinRequestCopyWith(_JoinRequest value, $Res Function(_JoinRequest) _then) = __$JoinRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, PlayerSummary player, DateTime createdAt, double? rating, int sessions, int mutual, bool provisional, bool belowRange, String message, RequestStatus status
});


@override $PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class __$JoinRequestCopyWithImpl<$Res>
    implements _$JoinRequestCopyWith<$Res> {
  __$JoinRequestCopyWithImpl(this._self, this._then);

  final _JoinRequest _self;
  final $Res Function(_JoinRequest) _then;

/// Create a copy of JoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? player = null,Object? createdAt = null,Object? rating = freezed,Object? sessions = null,Object? mutual = null,Object? provisional = null,Object? belowRange = null,Object? message = null,Object? status = null,}) {
  return _then(_JoinRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,mutual: null == mutual ? _self.mutual : mutual // ignore: cast_nullable_to_non_nullable
as int,provisional: null == provisional ? _self.provisional : provisional // ignore: cast_nullable_to_non_nullable
as bool,belowRange: null == belowRange ? _self.belowRange : belowRange // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,
  ));
}

/// Create a copy of JoinRequest
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
mixin _$ClubBan {

 PlayerSummary get player; String get bannedBy; DateTime get at; String get reason;
/// Create a copy of ClubBan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubBanCopyWith<ClubBan> get copyWith => _$ClubBanCopyWithImpl<ClubBan>(this as ClubBan, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubBan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubBan&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.bannedBy, _this.bannedBy) || other.bannedBy == _this.bannedBy)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}


@override
int get hashCode {
  final _this = this as ClubBan;
  return Object.hash(runtimeType,_this.player,_this.bannedBy,_this.at,_this.reason);
}

@override
String toString() {
  final _this = this as ClubBan;
  return 'ClubBan(player: ${_this.player}, bannedBy: ${_this.bannedBy}, at: ${_this.at}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $ClubBanCopyWith<$Res>  {
  factory $ClubBanCopyWith(ClubBan value, $Res Function(ClubBan) _then) = _$ClubBanCopyWithImpl;
@useResult
$Res call({
 PlayerSummary player, String bannedBy, DateTime at, String reason
});


$PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class _$ClubBanCopyWithImpl<$Res>
    implements $ClubBanCopyWith<$Res> {
  _$ClubBanCopyWithImpl(this._self, this._then);

  final ClubBan _self;
  final $Res Function(ClubBan) _then;

/// Create a copy of ClubBan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? bannedBy = null,Object? at = null,Object? reason = null,}) {
  return _then(ClubBan(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,bannedBy: null == bannedBy ? _self.bannedBy : bannedBy // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ClubBan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClubBan].
extension ClubBanPatterns on ClubBan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubBan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubBan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubBan value)  $default,){
final _that = this;
switch (_that) {
case _ClubBan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubBan value)?  $default,){
final _that = this;
switch (_that) {
case _ClubBan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerSummary player,  String bannedBy,  DateTime at,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubBan() when $default != null:
return $default(_that.player,_that.bannedBy,_that.at,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerSummary player,  String bannedBy,  DateTime at,  String reason)  $default,) {final _that = this;
switch (_that) {
case _ClubBan():
return $default(_that.player,_that.bannedBy,_that.at,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerSummary player,  String bannedBy,  DateTime at,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _ClubBan() when $default != null:
return $default(_that.player,_that.bannedBy,_that.at,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _ClubBan implements ClubBan {
  const _ClubBan({required this.player, required this.bannedBy, required this.at, this.reason = ''});
  

@override final  PlayerSummary player;
@override final  String bannedBy;
@override final  DateTime at;
@override@JsonKey() final  String reason;

/// Create a copy of ClubBan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubBanCopyWith<_ClubBan> get copyWith => __$ClubBanCopyWithImpl<_ClubBan>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubBan&&(identical(other.player, player) || other.player == player)&&(identical(other.bannedBy, bannedBy) || other.bannedBy == bannedBy)&&(identical(other.at, at) || other.at == at)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,player,bannedBy,at,reason);
}

@override
String toString() {
    return 'ClubBan(player: $player, bannedBy: $bannedBy, at: $at, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ClubBanCopyWith<$Res> implements $ClubBanCopyWith<$Res> {
  factory _$ClubBanCopyWith(_ClubBan value, $Res Function(_ClubBan) _then) = __$ClubBanCopyWithImpl;
@override @useResult
$Res call({
 PlayerSummary player, String bannedBy, DateTime at, String reason
});


@override $PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class __$ClubBanCopyWithImpl<$Res>
    implements _$ClubBanCopyWith<$Res> {
  __$ClubBanCopyWithImpl(this._self, this._then);

  final _ClubBan _self;
  final $Res Function(_ClubBan) _then;

/// Create a copy of ClubBan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? bannedBy = null,Object? at = null,Object? reason = null,}) {
  return _then(_ClubBan(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,bannedBy: null == bannedBy ? _self.bannedBy : bannedBy // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ClubBan
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
mixin _$AuditEntry {

 String get id; AuditCategory get category; String get actor; String get action; String get detail; DateTime get at;
/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditEntryCopyWith<AuditEntry> get copyWith => _$AuditEntryCopyWithImpl<AuditEntry>(this as AuditEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuditEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.actor, _this.actor) || other.actor == _this.actor)&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.at, _this.at) || other.at == _this.at));
}


@override
int get hashCode {
  final _this = this as AuditEntry;
  return Object.hash(runtimeType,_this.id,_this.category,_this.actor,_this.action,_this.detail,_this.at);
}

@override
String toString() {
  final _this = this as AuditEntry;
  return 'AuditEntry(id: ${_this.id}, category: ${_this.category}, actor: ${_this.actor}, action: ${_this.action}, detail: ${_this.detail}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $AuditEntryCopyWith<$Res>  {
  factory $AuditEntryCopyWith(AuditEntry value, $Res Function(AuditEntry) _then) = _$AuditEntryCopyWithImpl;
@useResult
$Res call({
 String id, AuditCategory category, String actor, String action, String detail, DateTime at
});




}
/// @nodoc
class _$AuditEntryCopyWithImpl<$Res>
    implements $AuditEntryCopyWith<$Res> {
  _$AuditEntryCopyWithImpl(this._self, this._then);

  final AuditEntry _self;
  final $Res Function(AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? actor = null,Object? action = null,Object? detail = null,Object? at = null,}) {
  return _then(AuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AuditCategory,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditEntry].
extension AuditEntryPatterns on AuditEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditEntry value)  $default,){
final _that = this;
switch (_that) {
case _AuditEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditEntry value)?  $default,){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AuditCategory category,  String actor,  String action,  String detail,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.category,_that.actor,_that.action,_that.detail,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AuditCategory category,  String actor,  String action,  String detail,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _AuditEntry():
return $default(_that.id,_that.category,_that.actor,_that.action,_that.detail,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AuditCategory category,  String actor,  String action,  String detail,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.category,_that.actor,_that.action,_that.detail,_that.at);case _:
  return null;

}
}

}

/// @nodoc


class _AuditEntry implements AuditEntry {
  const _AuditEntry({required this.id, required this.category, required this.actor, required this.action, this.detail = '', required this.at});
  

@override final  String id;
@override final  AuditCategory category;
@override final  String actor;
@override final  String action;
@override@JsonKey() final  String detail;
@override final  DateTime at;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditEntryCopyWith<_AuditEntry> get copyWith => __$AuditEntryCopyWithImpl<_AuditEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.action, action) || other.action == action)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,category,actor,action,detail,at);
}

@override
String toString() {
    return 'AuditEntry(id: $id, category: $category, actor: $actor, action: $action, detail: $detail, at: $at)';
}


}

/// @nodoc
abstract mixin class _$AuditEntryCopyWith<$Res> implements $AuditEntryCopyWith<$Res> {
  factory _$AuditEntryCopyWith(_AuditEntry value, $Res Function(_AuditEntry) _then) = __$AuditEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, AuditCategory category, String actor, String action, String detail, DateTime at
});




}
/// @nodoc
class __$AuditEntryCopyWithImpl<$Res>
    implements _$AuditEntryCopyWith<$Res> {
  __$AuditEntryCopyWithImpl(this._self, this._then);

  final _AuditEntry _self;
  final $Res Function(_AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? actor = null,Object? action = null,Object? detail = null,Object? at = null,}) {
  return _then(_AuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AuditCategory,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$Announcement {

 String get id; String get author; String get authorRole; String get title; String get body; bool get pinned; DateTime get at;
/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnnouncementCopyWith<Announcement> get copyWith => _$AnnouncementCopyWithImpl<Announcement>(this as Announcement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Announcement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Announcement&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.authorRole, _this.authorRole) || other.authorRole == _this.authorRole)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.pinned, _this.pinned) || other.pinned == _this.pinned)&&(identical(other.at, _this.at) || other.at == _this.at));
}


@override
int get hashCode {
  final _this = this as Announcement;
  return Object.hash(runtimeType,_this.id,_this.author,_this.authorRole,_this.title,_this.body,_this.pinned,_this.at);
}

@override
String toString() {
  final _this = this as Announcement;
  return 'Announcement(id: ${_this.id}, author: ${_this.author}, authorRole: ${_this.authorRole}, title: ${_this.title}, body: ${_this.body}, pinned: ${_this.pinned}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $AnnouncementCopyWith<$Res>  {
  factory $AnnouncementCopyWith(Announcement value, $Res Function(Announcement) _then) = _$AnnouncementCopyWithImpl;
@useResult
$Res call({
 String id, String author, String authorRole, String title, String body, bool pinned, DateTime at
});




}
/// @nodoc
class _$AnnouncementCopyWithImpl<$Res>
    implements $AnnouncementCopyWith<$Res> {
  _$AnnouncementCopyWithImpl(this._self, this._then);

  final Announcement _self;
  final $Res Function(Announcement) _then;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? authorRole = null,Object? title = null,Object? body = null,Object? pinned = null,Object? at = null,}) {
  return _then(Announcement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,authorRole: null == authorRole ? _self.authorRole : authorRole // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Announcement].
extension AnnouncementPatterns on Announcement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Announcement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Announcement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Announcement value)  $default,){
final _that = this;
switch (_that) {
case _Announcement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Announcement value)?  $default,){
final _that = this;
switch (_that) {
case _Announcement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String author,  String authorRole,  String title,  String body,  bool pinned,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Announcement() when $default != null:
return $default(_that.id,_that.author,_that.authorRole,_that.title,_that.body,_that.pinned,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String author,  String authorRole,  String title,  String body,  bool pinned,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _Announcement():
return $default(_that.id,_that.author,_that.authorRole,_that.title,_that.body,_that.pinned,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String author,  String authorRole,  String title,  String body,  bool pinned,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _Announcement() when $default != null:
return $default(_that.id,_that.author,_that.authorRole,_that.title,_that.body,_that.pinned,_that.at);case _:
  return null;

}
}

}

/// @nodoc


class _Announcement implements Announcement {
  const _Announcement({required this.id, required this.author, required this.authorRole, required this.title, required this.body, this.pinned = false, required this.at});
  

@override final  String id;
@override final  String author;
@override final  String authorRole;
@override final  String title;
@override final  String body;
@override@JsonKey() final  bool pinned;
@override final  DateTime at;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnnouncementCopyWith<_Announcement> get copyWith => __$AnnouncementCopyWithImpl<_Announcement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Announcement&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.authorRole, authorRole) || other.authorRole == authorRole)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,author,authorRole,title,body,pinned,at);
}

@override
String toString() {
    return 'Announcement(id: $id, author: $author, authorRole: $authorRole, title: $title, body: $body, pinned: $pinned, at: $at)';
}


}

/// @nodoc
abstract mixin class _$AnnouncementCopyWith<$Res> implements $AnnouncementCopyWith<$Res> {
  factory _$AnnouncementCopyWith(_Announcement value, $Res Function(_Announcement) _then) = __$AnnouncementCopyWithImpl;
@override @useResult
$Res call({
 String id, String author, String authorRole, String title, String body, bool pinned, DateTime at
});




}
/// @nodoc
class __$AnnouncementCopyWithImpl<$Res>
    implements _$AnnouncementCopyWith<$Res> {
  __$AnnouncementCopyWithImpl(this._self, this._then);

  final _Announcement _self;
  final $Res Function(_Announcement) _then;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? authorRole = null,Object? title = null,Object? body = null,Object? pinned = null,Object? at = null,}) {
  return _then(_Announcement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,authorRole: null == authorRole ? _self.authorRole : authorRole // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$SharedMeet {

 String get activityId; String get title; DateTime get startsAt; String get detail;
/// Create a copy of SharedMeet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedMeetCopyWith<SharedMeet> get copyWith => _$SharedMeetCopyWithImpl<SharedMeet>(this as SharedMeet, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SharedMeet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedMeet&&(identical(other.activityId, _this.activityId) || other.activityId == _this.activityId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.detail, _this.detail) || other.detail == _this.detail));
}


@override
int get hashCode {
  final _this = this as SharedMeet;
  return Object.hash(runtimeType,_this.activityId,_this.title,_this.startsAt,_this.detail);
}

@override
String toString() {
  final _this = this as SharedMeet;
  return 'SharedMeet(activityId: ${_this.activityId}, title: ${_this.title}, startsAt: ${_this.startsAt}, detail: ${_this.detail})';
}


}

/// @nodoc
abstract mixin class $SharedMeetCopyWith<$Res>  {
  factory $SharedMeetCopyWith(SharedMeet value, $Res Function(SharedMeet) _then) = _$SharedMeetCopyWithImpl;
@useResult
$Res call({
 String activityId, String title, DateTime startsAt, String detail
});




}
/// @nodoc
class _$SharedMeetCopyWithImpl<$Res>
    implements $SharedMeetCopyWith<$Res> {
  _$SharedMeetCopyWithImpl(this._self, this._then);

  final SharedMeet _self;
  final $Res Function(SharedMeet) _then;

/// Create a copy of SharedMeet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activityId = null,Object? title = null,Object? startsAt = null,Object? detail = null,}) {
  return _then(SharedMeet(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedMeet].
extension SharedMeetPatterns on SharedMeet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedMeet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedMeet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedMeet value)  $default,){
final _that = this;
switch (_that) {
case _SharedMeet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedMeet value)?  $default,){
final _that = this;
switch (_that) {
case _SharedMeet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String activityId,  String title,  DateTime startsAt,  String detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedMeet() when $default != null:
return $default(_that.activityId,_that.title,_that.startsAt,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String activityId,  String title,  DateTime startsAt,  String detail)  $default,) {final _that = this;
switch (_that) {
case _SharedMeet():
return $default(_that.activityId,_that.title,_that.startsAt,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String activityId,  String title,  DateTime startsAt,  String detail)?  $default,) {final _that = this;
switch (_that) {
case _SharedMeet() when $default != null:
return $default(_that.activityId,_that.title,_that.startsAt,_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class _SharedMeet implements SharedMeet {
  const _SharedMeet({required this.activityId, required this.title, required this.startsAt, required this.detail});
  

@override final  String activityId;
@override final  String title;
@override final  DateTime startsAt;
@override final  String detail;

/// Create a copy of SharedMeet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedMeetCopyWith<_SharedMeet> get copyWith => __$SharedMeetCopyWithImpl<_SharedMeet>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedMeet&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.title, title) || other.title == title)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activityId,title,startsAt,detail);
}

@override
String toString() {
    return 'SharedMeet(activityId: $activityId, title: $title, startsAt: $startsAt, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$SharedMeetCopyWith<$Res> implements $SharedMeetCopyWith<$Res> {
  factory _$SharedMeetCopyWith(_SharedMeet value, $Res Function(_SharedMeet) _then) = __$SharedMeetCopyWithImpl;
@override @useResult
$Res call({
 String activityId, String title, DateTime startsAt, String detail
});




}
/// @nodoc
class __$SharedMeetCopyWithImpl<$Res>
    implements _$SharedMeetCopyWith<$Res> {
  __$SharedMeetCopyWithImpl(this._self, this._then);

  final _SharedMeet _self;
  final $Res Function(_SharedMeet) _then;

/// Create a copy of SharedMeet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activityId = null,Object? title = null,Object? startsAt = null,Object? detail = null,}) {
  return _then(_SharedMeet(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$GroupMessage {

 String get id; PlayerSummary get sender; String get body; MessageKind get kind; String? get roleName; int? get roleColor; SharedMeet? get meet;/// A shared photo: a storage URL, or a local file path in demo mode.
 String? get photo; bool get removed; String? get removedBy; DateTime get at;
/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupMessageCopyWith<GroupMessage> get copyWith => _$GroupMessageCopyWithImpl<GroupMessage>(this as GroupMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sender, _this.sender) || other.sender == _this.sender)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.roleName, _this.roleName) || other.roleName == _this.roleName)&&(identical(other.roleColor, _this.roleColor) || other.roleColor == _this.roleColor)&&(identical(other.meet, _this.meet) || other.meet == _this.meet)&&(identical(other.photo, _this.photo) || other.photo == _this.photo)&&(identical(other.removed, _this.removed) || other.removed == _this.removed)&&(identical(other.removedBy, _this.removedBy) || other.removedBy == _this.removedBy)&&(identical(other.at, _this.at) || other.at == _this.at));
}


@override
int get hashCode {
  final _this = this as GroupMessage;
  return Object.hash(runtimeType,_this.id,_this.sender,_this.body,_this.kind,_this.roleName,_this.roleColor,_this.meet,_this.photo,_this.removed,_this.removedBy,_this.at);
}

@override
String toString() {
  final _this = this as GroupMessage;
  return 'GroupMessage(id: ${_this.id}, sender: ${_this.sender}, body: ${_this.body}, kind: ${_this.kind}, roleName: ${_this.roleName}, roleColor: ${_this.roleColor}, meet: ${_this.meet}, photo: ${_this.photo}, removed: ${_this.removed}, removedBy: ${_this.removedBy}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $GroupMessageCopyWith<$Res>  {
  factory $GroupMessageCopyWith(GroupMessage value, $Res Function(GroupMessage) _then) = _$GroupMessageCopyWithImpl;
@useResult
$Res call({
 String id, PlayerSummary sender, String body, MessageKind kind, String? roleName, int? roleColor, SharedMeet? meet, String? photo, bool removed, String? removedBy, DateTime at
});


$PlayerSummaryCopyWith<$Res> get sender;$SharedMeetCopyWith<$Res>? get meet;

}
/// @nodoc
class _$GroupMessageCopyWithImpl<$Res>
    implements $GroupMessageCopyWith<$Res> {
  _$GroupMessageCopyWithImpl(this._self, this._then);

  final GroupMessage _self;
  final $Res Function(GroupMessage) _then;

/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sender = null,Object? body = null,Object? kind = null,Object? roleName = freezed,Object? roleColor = freezed,Object? meet = freezed,Object? photo = freezed,Object? removed = null,Object? removedBy = freezed,Object? at = null,}) {
  return _then(GroupMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as PlayerSummary,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MessageKind,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String?,roleColor: freezed == roleColor ? _self.roleColor : roleColor // ignore: cast_nullable_to_non_nullable
as int?,meet: freezed == meet ? _self.meet : meet // ignore: cast_nullable_to_non_nullable
as SharedMeet?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as bool,removedBy: freezed == removedBy ? _self.removedBy : removedBy // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get sender {
  
  return $PlayerSummaryCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SharedMeetCopyWith<$Res>? get meet {
    if (_self.meet == null) {
    return null;
  }

  return $SharedMeetCopyWith<$Res>(_self.meet!, (value) {
    return _then(_self.copyWith(meet: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupMessage].
extension GroupMessagePatterns on GroupMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupMessage value)  $default,){
final _that = this;
switch (_that) {
case _GroupMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupMessage value)?  $default,){
final _that = this;
switch (_that) {
case _GroupMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PlayerSummary sender,  String body,  MessageKind kind,  String? roleName,  int? roleColor,  SharedMeet? meet,  String? photo,  bool removed,  String? removedBy,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupMessage() when $default != null:
return $default(_that.id,_that.sender,_that.body,_that.kind,_that.roleName,_that.roleColor,_that.meet,_that.photo,_that.removed,_that.removedBy,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PlayerSummary sender,  String body,  MessageKind kind,  String? roleName,  int? roleColor,  SharedMeet? meet,  String? photo,  bool removed,  String? removedBy,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _GroupMessage():
return $default(_that.id,_that.sender,_that.body,_that.kind,_that.roleName,_that.roleColor,_that.meet,_that.photo,_that.removed,_that.removedBy,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PlayerSummary sender,  String body,  MessageKind kind,  String? roleName,  int? roleColor,  SharedMeet? meet,  String? photo,  bool removed,  String? removedBy,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _GroupMessage() when $default != null:
return $default(_that.id,_that.sender,_that.body,_that.kind,_that.roleName,_that.roleColor,_that.meet,_that.photo,_that.removed,_that.removedBy,_that.at);case _:
  return null;

}
}

}

/// @nodoc


class _GroupMessage implements GroupMessage {
  const _GroupMessage({required this.id, required this.sender, this.body = '', this.kind = MessageKind.text, this.roleName, this.roleColor, this.meet, this.photo, this.removed = false, this.removedBy, required this.at});
  

@override final  String id;
@override final  PlayerSummary sender;
@override@JsonKey() final  String body;
@override@JsonKey() final  MessageKind kind;
@override final  String? roleName;
@override final  int? roleColor;
@override final  SharedMeet? meet;
/// A shared photo: a storage URL, or a local file path in demo mode.
@override final  String? photo;
@override@JsonKey() final  bool removed;
@override final  String? removedBy;
@override final  DateTime at;

/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupMessageCopyWith<_GroupMessage> get copyWith => __$GroupMessageCopyWithImpl<_GroupMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.body, body) || other.body == body)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.roleColor, roleColor) || other.roleColor == roleColor)&&(identical(other.meet, meet) || other.meet == meet)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.removedBy, removedBy) || other.removedBy == removedBy)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,sender,body,kind,roleName,roleColor,meet,photo,removed,removedBy,at);
}

@override
String toString() {
    return 'GroupMessage(id: $id, sender: $sender, body: $body, kind: $kind, roleName: $roleName, roleColor: $roleColor, meet: $meet, photo: $photo, removed: $removed, removedBy: $removedBy, at: $at)';
}


}

/// @nodoc
abstract mixin class _$GroupMessageCopyWith<$Res> implements $GroupMessageCopyWith<$Res> {
  factory _$GroupMessageCopyWith(_GroupMessage value, $Res Function(_GroupMessage) _then) = __$GroupMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, PlayerSummary sender, String body, MessageKind kind, String? roleName, int? roleColor, SharedMeet? meet, String? photo, bool removed, String? removedBy, DateTime at
});


@override $PlayerSummaryCopyWith<$Res> get sender;@override $SharedMeetCopyWith<$Res>? get meet;

}
/// @nodoc
class __$GroupMessageCopyWithImpl<$Res>
    implements _$GroupMessageCopyWith<$Res> {
  __$GroupMessageCopyWithImpl(this._self, this._then);

  final _GroupMessage _self;
  final $Res Function(_GroupMessage) _then;

/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sender = null,Object? body = null,Object? kind = null,Object? roleName = freezed,Object? roleColor = freezed,Object? meet = freezed,Object? photo = freezed,Object? removed = null,Object? removedBy = freezed,Object? at = null,}) {
  return _then(_GroupMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as PlayerSummary,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MessageKind,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String?,roleColor: freezed == roleColor ? _self.roleColor : roleColor // ignore: cast_nullable_to_non_nullable
as int?,meet: freezed == meet ? _self.meet : meet // ignore: cast_nullable_to_non_nullable
as SharedMeet?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as bool,removedBy: freezed == removedBy ? _self.removedBy : removedBy // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get sender {
  
  return $PlayerSummaryCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of GroupMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SharedMeetCopyWith<$Res>? get meet {
    if (_self.meet == null) {
    return null;
  }

  return $SharedMeetCopyWith<$Res>(_self.meet!, (value) {
    return _then(_self.copyWith(meet: value));
  });
}
}

/// @nodoc
mixin _$LeaderboardEntry {

 PlayerSummary get player; String get score; String get sub;/// "up 2", "down 1", "same" or "new".
 String get move;
/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaderboardEntryCopyWith<LeaderboardEntry> get copyWith => _$LeaderboardEntryCopyWithImpl<LeaderboardEntry>(this as LeaderboardEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LeaderboardEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaderboardEntry&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.sub, _this.sub) || other.sub == _this.sub)&&(identical(other.move, _this.move) || other.move == _this.move));
}


@override
int get hashCode {
  final _this = this as LeaderboardEntry;
  return Object.hash(runtimeType,_this.player,_this.score,_this.sub,_this.move);
}

@override
String toString() {
  final _this = this as LeaderboardEntry;
  return 'LeaderboardEntry(player: ${_this.player}, score: ${_this.score}, sub: ${_this.sub}, move: ${_this.move})';
}


}

/// @nodoc
abstract mixin class $LeaderboardEntryCopyWith<$Res>  {
  factory $LeaderboardEntryCopyWith(LeaderboardEntry value, $Res Function(LeaderboardEntry) _then) = _$LeaderboardEntryCopyWithImpl;
@useResult
$Res call({
 PlayerSummary player, String score, String sub, String move
});


$PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class _$LeaderboardEntryCopyWithImpl<$Res>
    implements $LeaderboardEntryCopyWith<$Res> {
  _$LeaderboardEntryCopyWithImpl(this._self, this._then);

  final LeaderboardEntry _self;
  final $Res Function(LeaderboardEntry) _then;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? score = null,Object? sub = null,Object? move = null,}) {
  return _then(LeaderboardEntry(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as String,sub: null == sub ? _self.sub : sub // ignore: cast_nullable_to_non_nullable
as String,move: null == move ? _self.move : move // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [LeaderboardEntry].
extension LeaderboardEntryPatterns on LeaderboardEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaderboardEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaderboardEntry value)  $default,){
final _that = this;
switch (_that) {
case _LeaderboardEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaderboardEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerSummary player,  String score,  String sub,  String move)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that.player,_that.score,_that.sub,_that.move);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerSummary player,  String score,  String sub,  String move)  $default,) {final _that = this;
switch (_that) {
case _LeaderboardEntry():
return $default(_that.player,_that.score,_that.sub,_that.move);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerSummary player,  String score,  String sub,  String move)?  $default,) {final _that = this;
switch (_that) {
case _LeaderboardEntry() when $default != null:
return $default(_that.player,_that.score,_that.sub,_that.move);case _:
  return null;

}
}

}

/// @nodoc


class _LeaderboardEntry implements LeaderboardEntry {
  const _LeaderboardEntry({required this.player, required this.score, this.sub = '', this.move = 'same'});
  

@override final  PlayerSummary player;
@override final  String score;
@override@JsonKey() final  String sub;
/// "up 2", "down 1", "same" or "new".
@override@JsonKey() final  String move;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaderboardEntryCopyWith<_LeaderboardEntry> get copyWith => __$LeaderboardEntryCopyWithImpl<_LeaderboardEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaderboardEntry&&(identical(other.player, player) || other.player == player)&&(identical(other.score, score) || other.score == score)&&(identical(other.sub, sub) || other.sub == sub)&&(identical(other.move, move) || other.move == move));
}


@override
int get hashCode {
    return Object.hash(runtimeType,player,score,sub,move);
}

@override
String toString() {
    return 'LeaderboardEntry(player: $player, score: $score, sub: $sub, move: $move)';
}


}

/// @nodoc
abstract mixin class _$LeaderboardEntryCopyWith<$Res> implements $LeaderboardEntryCopyWith<$Res> {
  factory _$LeaderboardEntryCopyWith(_LeaderboardEntry value, $Res Function(_LeaderboardEntry) _then) = __$LeaderboardEntryCopyWithImpl;
@override @useResult
$Res call({
 PlayerSummary player, String score, String sub, String move
});


@override $PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class __$LeaderboardEntryCopyWithImpl<$Res>
    implements _$LeaderboardEntryCopyWith<$Res> {
  __$LeaderboardEntryCopyWithImpl(this._self, this._then);

  final _LeaderboardEntry _self;
  final $Res Function(_LeaderboardEntry) _then;

/// Create a copy of LeaderboardEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? score = null,Object? sub = null,Object? move = null,}) {
  return _then(_LeaderboardEntry(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as String,sub: null == sub ? _self.sub : sub // ignore: cast_nullable_to_non_nullable
as String,move: null == move ? _self.move : move // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of LeaderboardEntry
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
mixin _$ClubLeaderboard {

 String get period; List<LeaderboardEntry> get rows; LeaderboardEntry? get me; int? get myRank; String get myNote;
/// Create a copy of ClubLeaderboard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubLeaderboardCopyWith<ClubLeaderboard> get copyWith => _$ClubLeaderboardCopyWithImpl<ClubLeaderboard>(this as ClubLeaderboard, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubLeaderboard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubLeaderboard&&(identical(other.period, _this.period) || other.period == _this.period)&&const DeepCollectionEquality().equals(other.rows, _this.rows)&&(identical(other.me, _this.me) || other.me == _this.me)&&(identical(other.myRank, _this.myRank) || other.myRank == _this.myRank)&&(identical(other.myNote, _this.myNote) || other.myNote == _this.myNote));
}


@override
int get hashCode {
  final _this = this as ClubLeaderboard;
  return Object.hash(runtimeType,_this.period,const DeepCollectionEquality().hash(_this.rows),_this.me,_this.myRank,_this.myNote);
}

@override
String toString() {
  final _this = this as ClubLeaderboard;
  return 'ClubLeaderboard(period: ${_this.period}, rows: ${_this.rows}, me: ${_this.me}, myRank: ${_this.myRank}, myNote: ${_this.myNote})';
}


}

/// @nodoc
abstract mixin class $ClubLeaderboardCopyWith<$Res>  {
  factory $ClubLeaderboardCopyWith(ClubLeaderboard value, $Res Function(ClubLeaderboard) _then) = _$ClubLeaderboardCopyWithImpl;
@useResult
$Res call({
 String period, List<LeaderboardEntry> rows, LeaderboardEntry? me, int? myRank, String myNote
});


$LeaderboardEntryCopyWith<$Res>? get me;

}
/// @nodoc
class _$ClubLeaderboardCopyWithImpl<$Res>
    implements $ClubLeaderboardCopyWith<$Res> {
  _$ClubLeaderboardCopyWithImpl(this._self, this._then);

  final ClubLeaderboard _self;
  final $Res Function(ClubLeaderboard) _then;

/// Create a copy of ClubLeaderboard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? rows = null,Object? me = freezed,Object? myRank = freezed,Object? myNote = null,}) {
  return _then(ClubLeaderboard(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<LeaderboardEntry>,me: freezed == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as LeaderboardEntry?,myRank: freezed == myRank ? _self.myRank : myRank // ignore: cast_nullable_to_non_nullable
as int?,myNote: null == myNote ? _self.myNote : myNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ClubLeaderboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeaderboardEntryCopyWith<$Res>? get me {
    if (_self.me == null) {
    return null;
  }

  return $LeaderboardEntryCopyWith<$Res>(_self.me!, (value) {
    return _then(_self.copyWith(me: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClubLeaderboard].
extension ClubLeaderboardPatterns on ClubLeaderboard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubLeaderboard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubLeaderboard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubLeaderboard value)  $default,){
final _that = this;
switch (_that) {
case _ClubLeaderboard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubLeaderboard value)?  $default,){
final _that = this;
switch (_that) {
case _ClubLeaderboard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String period,  List<LeaderboardEntry> rows,  LeaderboardEntry? me,  int? myRank,  String myNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubLeaderboard() when $default != null:
return $default(_that.period,_that.rows,_that.me,_that.myRank,_that.myNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String period,  List<LeaderboardEntry> rows,  LeaderboardEntry? me,  int? myRank,  String myNote)  $default,) {final _that = this;
switch (_that) {
case _ClubLeaderboard():
return $default(_that.period,_that.rows,_that.me,_that.myRank,_that.myNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String period,  List<LeaderboardEntry> rows,  LeaderboardEntry? me,  int? myRank,  String myNote)?  $default,) {final _that = this;
switch (_that) {
case _ClubLeaderboard() when $default != null:
return $default(_that.period,_that.rows,_that.me,_that.myRank,_that.myNote);case _:
  return null;

}
}

}

/// @nodoc


class _ClubLeaderboard implements ClubLeaderboard {
  const _ClubLeaderboard({required this.period,  List<LeaderboardEntry> rows = const [], this.me, this.myRank, this.myNote = ''}): _rows = rows;
  

@override final  String period;
 final  List<LeaderboardEntry> _rows;
@override@JsonKey() List<LeaderboardEntry> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

@override final  LeaderboardEntry? me;
@override final  int? myRank;
@override@JsonKey() final  String myNote;

/// Create a copy of ClubLeaderboard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubLeaderboardCopyWith<_ClubLeaderboard> get copyWith => __$ClubLeaderboardCopyWithImpl<_ClubLeaderboard>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubLeaderboard&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other.rows, _rows)&&(identical(other.me, me) || other.me == me)&&(identical(other.myRank, myRank) || other.myRank == myRank)&&(identical(other.myNote, myNote) || other.myNote == myNote));
}


@override
int get hashCode {
    return Object.hash(runtimeType,period,const DeepCollectionEquality().hash(_rows),me,myRank,myNote);
}

@override
String toString() {
    return 'ClubLeaderboard(period: $period, rows: $rows, me: $me, myRank: $myRank, myNote: $myNote)';
}


}

/// @nodoc
abstract mixin class _$ClubLeaderboardCopyWith<$Res> implements $ClubLeaderboardCopyWith<$Res> {
  factory _$ClubLeaderboardCopyWith(_ClubLeaderboard value, $Res Function(_ClubLeaderboard) _then) = __$ClubLeaderboardCopyWithImpl;
@override @useResult
$Res call({
 String period, List<LeaderboardEntry> rows, LeaderboardEntry? me, int? myRank, String myNote
});


@override $LeaderboardEntryCopyWith<$Res>? get me;

}
/// @nodoc
class __$ClubLeaderboardCopyWithImpl<$Res>
    implements _$ClubLeaderboardCopyWith<$Res> {
  __$ClubLeaderboardCopyWithImpl(this._self, this._then);

  final _ClubLeaderboard _self;
  final $Res Function(_ClubLeaderboard) _then;

/// Create a copy of ClubLeaderboard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? rows = null,Object? me = freezed,Object? myRank = freezed,Object? myNote = null,}) {
  return _then(_ClubLeaderboard(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<LeaderboardEntry>,me: freezed == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as LeaderboardEntry?,myRank: freezed == myRank ? _self.myRank : myRank // ignore: cast_nullable_to_non_nullable
as int?,myNote: null == myNote ? _self.myNote : myNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ClubLeaderboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeaderboardEntryCopyWith<$Res>? get me {
    if (_self.me == null) {
    return null;
  }

  return $LeaderboardEntryCopyWith<$Res>(_self.me!, (value) {
    return _then(_self.copyWith(me: value));
  });
}
}

/// @nodoc
mixin _$RewardMeet {

 String get title; DateTime get at; int get paidPresent;
/// Create a copy of RewardMeet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardMeetCopyWith<RewardMeet> get copyWith => _$RewardMeetCopyWithImpl<RewardMeet>(this as RewardMeet, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RewardMeet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardMeet&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.paidPresent, _this.paidPresent) || other.paidPresent == _this.paidPresent));
}


@override
int get hashCode {
  final _this = this as RewardMeet;
  return Object.hash(runtimeType,_this.title,_this.at,_this.paidPresent);
}

@override
String toString() {
  final _this = this as RewardMeet;
  return 'RewardMeet(title: ${_this.title}, at: ${_this.at}, paidPresent: ${_this.paidPresent})';
}


}

/// @nodoc
abstract mixin class $RewardMeetCopyWith<$Res>  {
  factory $RewardMeetCopyWith(RewardMeet value, $Res Function(RewardMeet) _then) = _$RewardMeetCopyWithImpl;
@useResult
$Res call({
 String title, DateTime at, int paidPresent
});




}
/// @nodoc
class _$RewardMeetCopyWithImpl<$Res>
    implements $RewardMeetCopyWith<$Res> {
  _$RewardMeetCopyWithImpl(this._self, this._then);

  final RewardMeet _self;
  final $Res Function(RewardMeet) _then;

/// Create a copy of RewardMeet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? at = null,Object? paidPresent = null,}) {
  return _then(RewardMeet(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,paidPresent: null == paidPresent ? _self.paidPresent : paidPresent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardMeet].
extension RewardMeetPatterns on RewardMeet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardMeet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardMeet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardMeet value)  $default,){
final _that = this;
switch (_that) {
case _RewardMeet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardMeet value)?  $default,){
final _that = this;
switch (_that) {
case _RewardMeet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  DateTime at,  int paidPresent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardMeet() when $default != null:
return $default(_that.title,_that.at,_that.paidPresent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  DateTime at,  int paidPresent)  $default,) {final _that = this;
switch (_that) {
case _RewardMeet():
return $default(_that.title,_that.at,_that.paidPresent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  DateTime at,  int paidPresent)?  $default,) {final _that = this;
switch (_that) {
case _RewardMeet() when $default != null:
return $default(_that.title,_that.at,_that.paidPresent);case _:
  return null;

}
}

}

/// @nodoc


class _RewardMeet implements RewardMeet {
  const _RewardMeet({required this.title, required this.at, required this.paidPresent});
  

@override final  String title;
@override final  DateTime at;
@override final  int paidPresent;

/// Create a copy of RewardMeet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardMeetCopyWith<_RewardMeet> get copyWith => __$RewardMeetCopyWithImpl<_RewardMeet>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardMeet&&(identical(other.title, title) || other.title == title)&&(identical(other.at, at) || other.at == at)&&(identical(other.paidPresent, paidPresent) || other.paidPresent == paidPresent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,at,paidPresent);
}

@override
String toString() {
    return 'RewardMeet(title: $title, at: $at, paidPresent: $paidPresent)';
}


}

/// @nodoc
abstract mixin class _$RewardMeetCopyWith<$Res> implements $RewardMeetCopyWith<$Res> {
  factory _$RewardMeetCopyWith(_RewardMeet value, $Res Function(_RewardMeet) _then) = __$RewardMeetCopyWithImpl;
@override @useResult
$Res call({
 String title, DateTime at, int paidPresent
});




}
/// @nodoc
class __$RewardMeetCopyWithImpl<$Res>
    implements _$RewardMeetCopyWith<$Res> {
  __$RewardMeetCopyWithImpl(this._self, this._then);

  final _RewardMeet _self;
  final $Res Function(_RewardMeet) _then;

/// Create a copy of RewardMeet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? at = null,Object? paidPresent = null,}) {
  return _then(_RewardMeet(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,paidPresent: null == paidPresent ? _self.paidPresent : paidPresent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ClubReward {

 int get target; int get minPlayers; String get prize; List<RewardMeet> get meets; List<(String, String,)> get past;
/// Create a copy of ClubReward
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubRewardCopyWith<ClubReward> get copyWith => _$ClubRewardCopyWithImpl<ClubReward>(this as ClubReward, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubReward;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubReward&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.minPlayers, _this.minPlayers) || other.minPlayers == _this.minPlayers)&&(identical(other.prize, _this.prize) || other.prize == _this.prize)&&const DeepCollectionEquality().equals(other.meets, _this.meets)&&const DeepCollectionEquality().equals(other.past, _this.past));
}


@override
int get hashCode {
  final _this = this as ClubReward;
  return Object.hash(runtimeType,_this.target,_this.minPlayers,_this.prize,const DeepCollectionEquality().hash(_this.meets),const DeepCollectionEquality().hash(_this.past));
}

@override
String toString() {
  final _this = this as ClubReward;
  return 'ClubReward(target: ${_this.target}, minPlayers: ${_this.minPlayers}, prize: ${_this.prize}, meets: ${_this.meets}, past: ${_this.past})';
}


}

/// @nodoc
abstract mixin class $ClubRewardCopyWith<$Res>  {
  factory $ClubRewardCopyWith(ClubReward value, $Res Function(ClubReward) _then) = _$ClubRewardCopyWithImpl;
@useResult
$Res call({
 int target, int minPlayers, String prize, List<RewardMeet> meets, List<(String, String,)> past
});




}
/// @nodoc
class _$ClubRewardCopyWithImpl<$Res>
    implements $ClubRewardCopyWith<$Res> {
  _$ClubRewardCopyWithImpl(this._self, this._then);

  final ClubReward _self;
  final $Res Function(ClubReward) _then;

/// Create a copy of ClubReward
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? minPlayers = null,Object? prize = null,Object? meets = null,Object? past = null,}) {
  return _then(ClubReward(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,prize: null == prize ? _self.prize : prize // ignore: cast_nullable_to_non_nullable
as String,meets: null == meets ? _self.meets : meets // ignore: cast_nullable_to_non_nullable
as List<RewardMeet>,past: null == past ? _self.past : past // ignore: cast_nullable_to_non_nullable
as List<(String, String,)>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClubReward].
extension ClubRewardPatterns on ClubReward {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubReward value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubReward() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubReward value)  $default,){
final _that = this;
switch (_that) {
case _ClubReward():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubReward value)?  $default,){
final _that = this;
switch (_that) {
case _ClubReward() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int target,  int minPlayers,  String prize,  List<RewardMeet> meets,  List<(String, String,)> past)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubReward() when $default != null:
return $default(_that.target,_that.minPlayers,_that.prize,_that.meets,_that.past);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int target,  int minPlayers,  String prize,  List<RewardMeet> meets,  List<(String, String,)> past)  $default,) {final _that = this;
switch (_that) {
case _ClubReward():
return $default(_that.target,_that.minPlayers,_that.prize,_that.meets,_that.past);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int target,  int minPlayers,  String prize,  List<RewardMeet> meets,  List<(String, String,)> past)?  $default,) {final _that = this;
switch (_that) {
case _ClubReward() when $default != null:
return $default(_that.target,_that.minPlayers,_that.prize,_that.meets,_that.past);case _:
  return null;

}
}

}

/// @nodoc


class _ClubReward extends ClubReward {
  const _ClubReward({this.target = 4, this.minPlayers = 6, this.prize = 'S\$20 shuttle voucher',  List<RewardMeet> meets = const [],  List<(String, String,)> past = const []}): _meets = meets,_past = past,super._();
  

@override@JsonKey() final  int target;
@override@JsonKey() final  int minPlayers;
@override@JsonKey() final  String prize;
 final  List<RewardMeet> _meets;
@override@JsonKey() List<RewardMeet> get meets {
  if (_meets is EqualUnmodifiableListView) return _meets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_meets);
}

 final  List<(String, String,)> _past;
@override@JsonKey() List<(String, String,)> get past {
  if (_past is EqualUnmodifiableListView) return _past;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_past);
}


/// Create a copy of ClubReward
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubRewardCopyWith<_ClubReward> get copyWith => __$ClubRewardCopyWithImpl<_ClubReward>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubReward&&(identical(other.target, target) || other.target == target)&&(identical(other.minPlayers, minPlayers) || other.minPlayers == minPlayers)&&(identical(other.prize, prize) || other.prize == prize)&&const DeepCollectionEquality().equals(other.meets, _meets)&&const DeepCollectionEquality().equals(other.past, _past));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,minPlayers,prize,const DeepCollectionEquality().hash(_meets),const DeepCollectionEquality().hash(_past));
}

@override
String toString() {
    return 'ClubReward(target: $target, minPlayers: $minPlayers, prize: $prize, meets: $meets, past: $past)';
}


}

/// @nodoc
abstract mixin class _$ClubRewardCopyWith<$Res> implements $ClubRewardCopyWith<$Res> {
  factory _$ClubRewardCopyWith(_ClubReward value, $Res Function(_ClubReward) _then) = __$ClubRewardCopyWithImpl;
@override @useResult
$Res call({
 int target, int minPlayers, String prize, List<RewardMeet> meets, List<(String, String,)> past
});




}
/// @nodoc
class __$ClubRewardCopyWithImpl<$Res>
    implements _$ClubRewardCopyWith<$Res> {
  __$ClubRewardCopyWithImpl(this._self, this._then);

  final _ClubReward _self;
  final $Res Function(_ClubReward) _then;

/// Create a copy of ClubReward
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? minPlayers = null,Object? prize = null,Object? meets = null,Object? past = null,}) {
  return _then(_ClubReward(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,prize: null == prize ? _self.prize : prize // ignore: cast_nullable_to_non_nullable
as String,meets: null == meets ? _self._meets : meets // ignore: cast_nullable_to_non_nullable
as List<RewardMeet>,past: null == past ? _self._past : past // ignore: cast_nullable_to_non_nullable
as List<(String, String,)>,
  ));
}


}

/// @nodoc
mixin _$InviteCandidate {

 PlayerSummary get player; double? get rating; int get meetsTogether; String get club; String get age;
/// Create a copy of InviteCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCandidateCopyWith<InviteCandidate> get copyWith => _$InviteCandidateCopyWithImpl<InviteCandidate>(this as InviteCandidate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InviteCandidate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteCandidate&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.meetsTogether, _this.meetsTogether) || other.meetsTogether == _this.meetsTogether)&&(identical(other.club, _this.club) || other.club == _this.club)&&(identical(other.age, _this.age) || other.age == _this.age));
}


@override
int get hashCode {
  final _this = this as InviteCandidate;
  return Object.hash(runtimeType,_this.player,_this.rating,_this.meetsTogether,_this.club,_this.age);
}

@override
String toString() {
  final _this = this as InviteCandidate;
  return 'InviteCandidate(player: ${_this.player}, rating: ${_this.rating}, meetsTogether: ${_this.meetsTogether}, club: ${_this.club}, age: ${_this.age})';
}


}

/// @nodoc
abstract mixin class $InviteCandidateCopyWith<$Res>  {
  factory $InviteCandidateCopyWith(InviteCandidate value, $Res Function(InviteCandidate) _then) = _$InviteCandidateCopyWithImpl;
@useResult
$Res call({
 PlayerSummary player, double? rating, int meetsTogether, String club, String age
});


$PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class _$InviteCandidateCopyWithImpl<$Res>
    implements $InviteCandidateCopyWith<$Res> {
  _$InviteCandidateCopyWithImpl(this._self, this._then);

  final InviteCandidate _self;
  final $Res Function(InviteCandidate) _then;

/// Create a copy of InviteCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? rating = freezed,Object? meetsTogether = null,Object? club = null,Object? age = null,}) {
  return _then(InviteCandidate(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,meetsTogether: null == meetsTogether ? _self.meetsTogether : meetsTogether // ignore: cast_nullable_to_non_nullable
as int,club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as String,age: null == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of InviteCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [InviteCandidate].
extension InviteCandidatePatterns on InviteCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteCandidate value)  $default,){
final _that = this;
switch (_that) {
case _InviteCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _InviteCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerSummary player,  double? rating,  int meetsTogether,  String club,  String age)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteCandidate() when $default != null:
return $default(_that.player,_that.rating,_that.meetsTogether,_that.club,_that.age);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerSummary player,  double? rating,  int meetsTogether,  String club,  String age)  $default,) {final _that = this;
switch (_that) {
case _InviteCandidate():
return $default(_that.player,_that.rating,_that.meetsTogether,_that.club,_that.age);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerSummary player,  double? rating,  int meetsTogether,  String club,  String age)?  $default,) {final _that = this;
switch (_that) {
case _InviteCandidate() when $default != null:
return $default(_that.player,_that.rating,_that.meetsTogether,_that.club,_that.age);case _:
  return null;

}
}

}

/// @nodoc


class _InviteCandidate implements InviteCandidate {
  const _InviteCandidate({required this.player, this.rating, this.meetsTogether = 0, this.club = '', this.age = ''});
  

@override final  PlayerSummary player;
@override final  double? rating;
@override@JsonKey() final  int meetsTogether;
@override@JsonKey() final  String club;
@override@JsonKey() final  String age;

/// Create a copy of InviteCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCandidateCopyWith<_InviteCandidate> get copyWith => __$InviteCandidateCopyWithImpl<_InviteCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteCandidate&&(identical(other.player, player) || other.player == player)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.meetsTogether, meetsTogether) || other.meetsTogether == meetsTogether)&&(identical(other.club, club) || other.club == club)&&(identical(other.age, age) || other.age == age));
}


@override
int get hashCode {
    return Object.hash(runtimeType,player,rating,meetsTogether,club,age);
}

@override
String toString() {
    return 'InviteCandidate(player: $player, rating: $rating, meetsTogether: $meetsTogether, club: $club, age: $age)';
}


}

/// @nodoc
abstract mixin class _$InviteCandidateCopyWith<$Res> implements $InviteCandidateCopyWith<$Res> {
  factory _$InviteCandidateCopyWith(_InviteCandidate value, $Res Function(_InviteCandidate) _then) = __$InviteCandidateCopyWithImpl;
@override @useResult
$Res call({
 PlayerSummary player, double? rating, int meetsTogether, String club, String age
});


@override $PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class __$InviteCandidateCopyWithImpl<$Res>
    implements _$InviteCandidateCopyWith<$Res> {
  __$InviteCandidateCopyWithImpl(this._self, this._then);

  final _InviteCandidate _self;
  final $Res Function(_InviteCandidate) _then;

/// Create a copy of InviteCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? rating = freezed,Object? meetsTogether = null,Object? club = null,Object? age = null,}) {
  return _then(_InviteCandidate(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,meetsTogether: null == meetsTogether ? _self.meetsTogether : meetsTogether // ignore: cast_nullable_to_non_nullable
as int,club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as String,age: null == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of InviteCandidate
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
mixin _$ClubDraft {

 String get name; String get description; String? get venueId; String? get venueName; String get area; ClubVisibility get visibility; JoinMode get joinMode; List<ClubSport> get sports; Map<ClubSport, LevelRange> get ranges; Set<String> get invite;
/// Create a copy of ClubDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClubDraftCopyWith<ClubDraft> get copyWith => _$ClubDraftCopyWithImpl<ClubDraft>(this as ClubDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClubDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClubDraft&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.venueId, _this.venueId) || other.venueId == _this.venueId)&&(identical(other.venueName, _this.venueName) || other.venueName == _this.venueName)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&(identical(other.joinMode, _this.joinMode) || other.joinMode == _this.joinMode)&&const DeepCollectionEquality().equals(other.sports, _this.sports)&&const DeepCollectionEquality().equals(other.ranges, _this.ranges)&&const DeepCollectionEquality().equals(other.invite, _this.invite));
}


@override
int get hashCode {
  final _this = this as ClubDraft;
  return Object.hash(runtimeType,_this.name,_this.description,_this.venueId,_this.venueName,_this.area,_this.visibility,_this.joinMode,const DeepCollectionEquality().hash(_this.sports),const DeepCollectionEquality().hash(_this.ranges),const DeepCollectionEquality().hash(_this.invite));
}

@override
String toString() {
  final _this = this as ClubDraft;
  return 'ClubDraft(name: ${_this.name}, description: ${_this.description}, venueId: ${_this.venueId}, venueName: ${_this.venueName}, area: ${_this.area}, visibility: ${_this.visibility}, joinMode: ${_this.joinMode}, sports: ${_this.sports}, ranges: ${_this.ranges}, invite: ${_this.invite})';
}


}

/// @nodoc
abstract mixin class $ClubDraftCopyWith<$Res>  {
  factory $ClubDraftCopyWith(ClubDraft value, $Res Function(ClubDraft) _then) = _$ClubDraftCopyWithImpl;
@useResult
$Res call({
 String name, String description, String? venueId, String? venueName, String area, ClubVisibility visibility, JoinMode joinMode, List<ClubSport> sports, Map<ClubSport, LevelRange> ranges, Set<String> invite
});




}
/// @nodoc
class _$ClubDraftCopyWithImpl<$Res>
    implements $ClubDraftCopyWith<$Res> {
  _$ClubDraftCopyWithImpl(this._self, this._then);

  final ClubDraft _self;
  final $Res Function(ClubDraft) _then;

/// Create a copy of ClubDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? venueId = freezed,Object? venueName = freezed,Object? area = null,Object? visibility = null,Object? joinMode = null,Object? sports = null,Object? ranges = null,Object? invite = null,}) {
  return _then(ClubDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,venueId: freezed == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String?,venueName: freezed == venueName ? _self.venueName : venueName // ignore: cast_nullable_to_non_nullable
as String?,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ClubVisibility,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as JoinMode,sports: null == sports ? _self.sports : sports // ignore: cast_nullable_to_non_nullable
as List<ClubSport>,ranges: null == ranges ? _self.ranges : ranges // ignore: cast_nullable_to_non_nullable
as Map<ClubSport, LevelRange>,invite: null == invite ? _self.invite : invite // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClubDraft].
extension ClubDraftPatterns on ClubDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClubDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClubDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClubDraft value)  $default,){
final _that = this;
switch (_that) {
case _ClubDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClubDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ClubDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  String? venueId,  String? venueName,  String area,  ClubVisibility visibility,  JoinMode joinMode,  List<ClubSport> sports,  Map<ClubSport, LevelRange> ranges,  Set<String> invite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClubDraft() when $default != null:
return $default(_that.name,_that.description,_that.venueId,_that.venueName,_that.area,_that.visibility,_that.joinMode,_that.sports,_that.ranges,_that.invite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  String? venueId,  String? venueName,  String area,  ClubVisibility visibility,  JoinMode joinMode,  List<ClubSport> sports,  Map<ClubSport, LevelRange> ranges,  Set<String> invite)  $default,) {final _that = this;
switch (_that) {
case _ClubDraft():
return $default(_that.name,_that.description,_that.venueId,_that.venueName,_that.area,_that.visibility,_that.joinMode,_that.sports,_that.ranges,_that.invite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  String? venueId,  String? venueName,  String area,  ClubVisibility visibility,  JoinMode joinMode,  List<ClubSport> sports,  Map<ClubSport, LevelRange> ranges,  Set<String> invite)?  $default,) {final _that = this;
switch (_that) {
case _ClubDraft() when $default != null:
return $default(_that.name,_that.description,_that.venueId,_that.venueName,_that.area,_that.visibility,_that.joinMode,_that.sports,_that.ranges,_that.invite);case _:
  return null;

}
}

}

/// @nodoc


class _ClubDraft implements ClubDraft {
  const _ClubDraft({this.name = '', this.description = '', this.venueId, this.venueName, this.area = '', this.visibility = ClubVisibility.public, this.joinMode = JoinMode.request,  List<ClubSport> sports = const [],  Map<ClubSport, LevelRange> ranges = const {},  Set<String> invite = const {}}): _sports = sports,_ranges = ranges,_invite = invite;
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override final  String? venueId;
@override final  String? venueName;
@override@JsonKey() final  String area;
@override@JsonKey() final  ClubVisibility visibility;
@override@JsonKey() final  JoinMode joinMode;
 final  List<ClubSport> _sports;
@override@JsonKey() List<ClubSport> get sports {
  if (_sports is EqualUnmodifiableListView) return _sports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sports);
}

 final  Map<ClubSport, LevelRange> _ranges;
@override@JsonKey() Map<ClubSport, LevelRange> get ranges {
  if (_ranges is EqualUnmodifiableMapView) return _ranges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ranges);
}

 final  Set<String> _invite;
@override@JsonKey() Set<String> get invite {
  if (_invite is EqualUnmodifiableSetView) return _invite;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_invite);
}


/// Create a copy of ClubDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClubDraftCopyWith<_ClubDraft> get copyWith => __$ClubDraftCopyWithImpl<_ClubDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClubDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.venueName, venueName) || other.venueName == venueName)&&(identical(other.area, area) || other.area == area)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&const DeepCollectionEquality().equals(other.sports, _sports)&&const DeepCollectionEquality().equals(other.ranges, _ranges)&&const DeepCollectionEquality().equals(other.invite, _invite));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,description,venueId,venueName,area,visibility,joinMode,const DeepCollectionEquality().hash(_sports),const DeepCollectionEquality().hash(_ranges),const DeepCollectionEquality().hash(_invite));
}

@override
String toString() {
    return 'ClubDraft(name: $name, description: $description, venueId: $venueId, venueName: $venueName, area: $area, visibility: $visibility, joinMode: $joinMode, sports: $sports, ranges: $ranges, invite: $invite)';
}


}

/// @nodoc
abstract mixin class _$ClubDraftCopyWith<$Res> implements $ClubDraftCopyWith<$Res> {
  factory _$ClubDraftCopyWith(_ClubDraft value, $Res Function(_ClubDraft) _then) = __$ClubDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, String? venueId, String? venueName, String area, ClubVisibility visibility, JoinMode joinMode, List<ClubSport> sports, Map<ClubSport, LevelRange> ranges, Set<String> invite
});




}
/// @nodoc
class __$ClubDraftCopyWithImpl<$Res>
    implements _$ClubDraftCopyWith<$Res> {
  __$ClubDraftCopyWithImpl(this._self, this._then);

  final _ClubDraft _self;
  final $Res Function(_ClubDraft) _then;

/// Create a copy of ClubDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? venueId = freezed,Object? venueName = freezed,Object? area = null,Object? visibility = null,Object? joinMode = null,Object? sports = null,Object? ranges = null,Object? invite = null,}) {
  return _then(_ClubDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,venueId: freezed == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String?,venueName: freezed == venueName ? _self.venueName : venueName // ignore: cast_nullable_to_non_nullable
as String?,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ClubVisibility,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as JoinMode,sports: null == sports ? _self._sports : sports // ignore: cast_nullable_to_non_nullable
as List<ClubSport>,ranges: null == ranges ? _self._ranges : ranges // ignore: cast_nullable_to_non_nullable
as Map<ClubSport, LevelRange>,invite: null == invite ? _self._invite : invite // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc
mixin _$SubTeam {

 String get name; String get rule; bool get enabled; int get players;
/// Create a copy of SubTeam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubTeamCopyWith<SubTeam> get copyWith => _$SubTeamCopyWithImpl<SubTeam>(this as SubTeam, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubTeam;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubTeam&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.rule, _this.rule) || other.rule == _this.rule)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.players, _this.players) || other.players == _this.players));
}


@override
int get hashCode {
  final _this = this as SubTeam;
  return Object.hash(runtimeType,_this.name,_this.rule,_this.enabled,_this.players);
}

@override
String toString() {
  final _this = this as SubTeam;
  return 'SubTeam(name: ${_this.name}, rule: ${_this.rule}, enabled: ${_this.enabled}, players: ${_this.players})';
}


}

/// @nodoc
abstract mixin class $SubTeamCopyWith<$Res>  {
  factory $SubTeamCopyWith(SubTeam value, $Res Function(SubTeam) _then) = _$SubTeamCopyWithImpl;
@useResult
$Res call({
 String name, String rule, bool enabled, int players
});




}
/// @nodoc
class _$SubTeamCopyWithImpl<$Res>
    implements $SubTeamCopyWith<$Res> {
  _$SubTeamCopyWithImpl(this._self, this._then);

  final SubTeam _self;
  final $Res Function(SubTeam) _then;

/// Create a copy of SubTeam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? rule = null,Object? enabled = null,Object? players = null,}) {
  return _then(SubTeam(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SubTeam].
extension SubTeamPatterns on SubTeam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubTeam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubTeam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubTeam value)  $default,){
final _that = this;
switch (_that) {
case _SubTeam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubTeam value)?  $default,){
final _that = this;
switch (_that) {
case _SubTeam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String rule,  bool enabled,  int players)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubTeam() when $default != null:
return $default(_that.name,_that.rule,_that.enabled,_that.players);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String rule,  bool enabled,  int players)  $default,) {final _that = this;
switch (_that) {
case _SubTeam():
return $default(_that.name,_that.rule,_that.enabled,_that.players);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String rule,  bool enabled,  int players)?  $default,) {final _that = this;
switch (_that) {
case _SubTeam() when $default != null:
return $default(_that.name,_that.rule,_that.enabled,_that.players);case _:
  return null;

}
}

}

/// @nodoc


class _SubTeam implements SubTeam {
  const _SubTeam({required this.name, this.rule = '', this.enabled = false, this.players = 0});
  

@override final  String name;
@override@JsonKey() final  String rule;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int players;

/// Create a copy of SubTeam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubTeamCopyWith<_SubTeam> get copyWith => __$SubTeamCopyWithImpl<_SubTeam>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubTeam&&(identical(other.name, name) || other.name == name)&&(identical(other.rule, rule) || other.rule == rule)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.players, players) || other.players == players));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,rule,enabled,players);
}

@override
String toString() {
    return 'SubTeam(name: $name, rule: $rule, enabled: $enabled, players: $players)';
}


}

/// @nodoc
abstract mixin class _$SubTeamCopyWith<$Res> implements $SubTeamCopyWith<$Res> {
  factory _$SubTeamCopyWith(_SubTeam value, $Res Function(_SubTeam) _then) = __$SubTeamCopyWithImpl;
@override @useResult
$Res call({
 String name, String rule, bool enabled, int players
});




}
/// @nodoc
class __$SubTeamCopyWithImpl<$Res>
    implements _$SubTeamCopyWith<$Res> {
  __$SubTeamCopyWithImpl(this._self, this._then);

  final _SubTeam _self;
  final $Res Function(_SubTeam) _then;

/// Create a copy of SubTeam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? rule = null,Object? enabled = null,Object? players = null,}) {
  return _then(_SubTeam(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Team {

 String get id; String get name; String get represents; ClubSport get sport; String get season; int get logoColor; int get logoInk; List<SubTeam> get subTeams; List<Club> get linkedClubs; int get playerCount; int get reserveCount; int get staffCount; TeamRole get myRole; int get unreadChat;
/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamCopyWith<Team> get copyWith => _$TeamCopyWithImpl<Team>(this as Team, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Team;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Team&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.represents, _this.represents) || other.represents == _this.represents)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.season, _this.season) || other.season == _this.season)&&(identical(other.logoColor, _this.logoColor) || other.logoColor == _this.logoColor)&&(identical(other.logoInk, _this.logoInk) || other.logoInk == _this.logoInk)&&const DeepCollectionEquality().equals(other.subTeams, _this.subTeams)&&const DeepCollectionEquality().equals(other.linkedClubs, _this.linkedClubs)&&(identical(other.playerCount, _this.playerCount) || other.playerCount == _this.playerCount)&&(identical(other.reserveCount, _this.reserveCount) || other.reserveCount == _this.reserveCount)&&(identical(other.staffCount, _this.staffCount) || other.staffCount == _this.staffCount)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.unreadChat, _this.unreadChat) || other.unreadChat == _this.unreadChat));
}


@override
int get hashCode {
  final _this = this as Team;
  return Object.hash(runtimeType,_this.id,_this.name,_this.represents,_this.sport,_this.season,_this.logoColor,_this.logoInk,const DeepCollectionEquality().hash(_this.subTeams),const DeepCollectionEquality().hash(_this.linkedClubs),_this.playerCount,_this.reserveCount,_this.staffCount,_this.myRole,_this.unreadChat);
}

@override
String toString() {
  final _this = this as Team;
  return 'Team(id: ${_this.id}, name: ${_this.name}, represents: ${_this.represents}, sport: ${_this.sport}, season: ${_this.season}, logoColor: ${_this.logoColor}, logoInk: ${_this.logoInk}, subTeams: ${_this.subTeams}, linkedClubs: ${_this.linkedClubs}, playerCount: ${_this.playerCount}, reserveCount: ${_this.reserveCount}, staffCount: ${_this.staffCount}, myRole: ${_this.myRole}, unreadChat: ${_this.unreadChat})';
}


}

/// @nodoc
abstract mixin class $TeamCopyWith<$Res>  {
  factory $TeamCopyWith(Team value, $Res Function(Team) _then) = _$TeamCopyWithImpl;
@useResult
$Res call({
 String id, String name, String represents, ClubSport sport, String season, int logoColor, int logoInk, List<SubTeam> subTeams, List<Club> linkedClubs, int playerCount, int reserveCount, int staffCount, TeamRole myRole, int unreadChat
});




}
/// @nodoc
class _$TeamCopyWithImpl<$Res>
    implements $TeamCopyWith<$Res> {
  _$TeamCopyWithImpl(this._self, this._then);

  final Team _self;
  final $Res Function(Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? represents = null,Object? sport = null,Object? season = null,Object? logoColor = null,Object? logoInk = null,Object? subTeams = null,Object? linkedClubs = null,Object? playerCount = null,Object? reserveCount = null,Object? staffCount = null,Object? myRole = null,Object? unreadChat = null,}) {
  return _then(Team(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,represents: null == represents ? _self.represents : represents // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as ClubSport,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String,logoColor: null == logoColor ? _self.logoColor : logoColor // ignore: cast_nullable_to_non_nullable
as int,logoInk: null == logoInk ? _self.logoInk : logoInk // ignore: cast_nullable_to_non_nullable
as int,subTeams: null == subTeams ? _self.subTeams : subTeams // ignore: cast_nullable_to_non_nullable
as List<SubTeam>,linkedClubs: null == linkedClubs ? _self.linkedClubs : linkedClubs // ignore: cast_nullable_to_non_nullable
as List<Club>,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,reserveCount: null == reserveCount ? _self.reserveCount : reserveCount // ignore: cast_nullable_to_non_nullable
as int,staffCount: null == staffCount ? _self.staffCount : staffCount // ignore: cast_nullable_to_non_nullable
as int,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as TeamRole,unreadChat: null == unreadChat ? _self.unreadChat : unreadChat // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Team].
extension TeamPatterns on Team {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Team value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Team() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Team value)  $default,){
final _that = this;
switch (_that) {
case _Team():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Team value)?  $default,){
final _that = this;
switch (_that) {
case _Team() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String represents,  ClubSport sport,  String season,  int logoColor,  int logoInk,  List<SubTeam> subTeams,  List<Club> linkedClubs,  int playerCount,  int reserveCount,  int staffCount,  TeamRole myRole,  int unreadChat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.id,_that.name,_that.represents,_that.sport,_that.season,_that.logoColor,_that.logoInk,_that.subTeams,_that.linkedClubs,_that.playerCount,_that.reserveCount,_that.staffCount,_that.myRole,_that.unreadChat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String represents,  ClubSport sport,  String season,  int logoColor,  int logoInk,  List<SubTeam> subTeams,  List<Club> linkedClubs,  int playerCount,  int reserveCount,  int staffCount,  TeamRole myRole,  int unreadChat)  $default,) {final _that = this;
switch (_that) {
case _Team():
return $default(_that.id,_that.name,_that.represents,_that.sport,_that.season,_that.logoColor,_that.logoInk,_that.subTeams,_that.linkedClubs,_that.playerCount,_that.reserveCount,_that.staffCount,_that.myRole,_that.unreadChat);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String represents,  ClubSport sport,  String season,  int logoColor,  int logoInk,  List<SubTeam> subTeams,  List<Club> linkedClubs,  int playerCount,  int reserveCount,  int staffCount,  TeamRole myRole,  int unreadChat)?  $default,) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.id,_that.name,_that.represents,_that.sport,_that.season,_that.logoColor,_that.logoInk,_that.subTeams,_that.linkedClubs,_that.playerCount,_that.reserveCount,_that.staffCount,_that.myRole,_that.unreadChat);case _:
  return null;

}
}

}

/// @nodoc


class _Team extends Team {
  const _Team({required this.id, required this.name, this.represents = '', this.sport = ClubSport.badminton, this.season = '', this.logoColor = 0xFFE8590C, this.logoInk = 0xFFFFFFFF,  List<SubTeam> subTeams = const [],  List<Club> linkedClubs = const [], this.playerCount = 0, this.reserveCount = 0, this.staffCount = 0, this.myRole = TeamRole.player, this.unreadChat = 0}): _subTeams = subTeams,_linkedClubs = linkedClubs,super._();
  

@override final  String id;
@override final  String name;
@override@JsonKey() final  String represents;
@override@JsonKey() final  ClubSport sport;
@override@JsonKey() final  String season;
@override@JsonKey() final  int logoColor;
@override@JsonKey() final  int logoInk;
 final  List<SubTeam> _subTeams;
@override@JsonKey() List<SubTeam> get subTeams {
  if (_subTeams is EqualUnmodifiableListView) return _subTeams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subTeams);
}

 final  List<Club> _linkedClubs;
@override@JsonKey() List<Club> get linkedClubs {
  if (_linkedClubs is EqualUnmodifiableListView) return _linkedClubs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_linkedClubs);
}

@override@JsonKey() final  int playerCount;
@override@JsonKey() final  int reserveCount;
@override@JsonKey() final  int staffCount;
@override@JsonKey() final  TeamRole myRole;
@override@JsonKey() final  int unreadChat;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamCopyWith<_Team> get copyWith => __$TeamCopyWithImpl<_Team>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Team&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.represents, represents) || other.represents == represents)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.season, season) || other.season == season)&&(identical(other.logoColor, logoColor) || other.logoColor == logoColor)&&(identical(other.logoInk, logoInk) || other.logoInk == logoInk)&&const DeepCollectionEquality().equals(other.subTeams, _subTeams)&&const DeepCollectionEquality().equals(other.linkedClubs, _linkedClubs)&&(identical(other.playerCount, playerCount) || other.playerCount == playerCount)&&(identical(other.reserveCount, reserveCount) || other.reserveCount == reserveCount)&&(identical(other.staffCount, staffCount) || other.staffCount == staffCount)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.unreadChat, unreadChat) || other.unreadChat == unreadChat));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,represents,sport,season,logoColor,logoInk,const DeepCollectionEquality().hash(_subTeams),const DeepCollectionEquality().hash(_linkedClubs),playerCount,reserveCount,staffCount,myRole,unreadChat);
}

@override
String toString() {
    return 'Team(id: $id, name: $name, represents: $represents, sport: $sport, season: $season, logoColor: $logoColor, logoInk: $logoInk, subTeams: $subTeams, linkedClubs: $linkedClubs, playerCount: $playerCount, reserveCount: $reserveCount, staffCount: $staffCount, myRole: $myRole, unreadChat: $unreadChat)';
}


}

/// @nodoc
abstract mixin class _$TeamCopyWith<$Res> implements $TeamCopyWith<$Res> {
  factory _$TeamCopyWith(_Team value, $Res Function(_Team) _then) = __$TeamCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String represents, ClubSport sport, String season, int logoColor, int logoInk, List<SubTeam> subTeams, List<Club> linkedClubs, int playerCount, int reserveCount, int staffCount, TeamRole myRole, int unreadChat
});




}
/// @nodoc
class __$TeamCopyWithImpl<$Res>
    implements _$TeamCopyWith<$Res> {
  __$TeamCopyWithImpl(this._self, this._then);

  final _Team _self;
  final $Res Function(_Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? represents = null,Object? sport = null,Object? season = null,Object? logoColor = null,Object? logoInk = null,Object? subTeams = null,Object? linkedClubs = null,Object? playerCount = null,Object? reserveCount = null,Object? staffCount = null,Object? myRole = null,Object? unreadChat = null,}) {
  return _then(_Team(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,represents: null == represents ? _self.represents : represents // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as ClubSport,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String,logoColor: null == logoColor ? _self.logoColor : logoColor // ignore: cast_nullable_to_non_nullable
as int,logoInk: null == logoInk ? _self.logoInk : logoInk // ignore: cast_nullable_to_non_nullable
as int,subTeams: null == subTeams ? _self._subTeams : subTeams // ignore: cast_nullable_to_non_nullable
as List<SubTeam>,linkedClubs: null == linkedClubs ? _self._linkedClubs : linkedClubs // ignore: cast_nullable_to_non_nullable
as List<Club>,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,reserveCount: null == reserveCount ? _self.reserveCount : reserveCount // ignore: cast_nullable_to_non_nullable
as int,staffCount: null == staffCount ? _self.staffCount : staffCount // ignore: cast_nullable_to_non_nullable
as int,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as TeamRole,unreadChat: null == unreadChat ? _self.unreadChat : unreadChat // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TeamListItem {

 Team get team; String get meta; String get note; String get tag;
/// Create a copy of TeamListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamListItemCopyWith<TeamListItem> get copyWith => _$TeamListItemCopyWithImpl<TeamListItem>(this as TeamListItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamListItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamListItem&&(identical(other.team, _this.team) || other.team == _this.team)&&(identical(other.meta, _this.meta) || other.meta == _this.meta)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.tag, _this.tag) || other.tag == _this.tag));
}


@override
int get hashCode {
  final _this = this as TeamListItem;
  return Object.hash(runtimeType,_this.team,_this.meta,_this.note,_this.tag);
}

@override
String toString() {
  final _this = this as TeamListItem;
  return 'TeamListItem(team: ${_this.team}, meta: ${_this.meta}, note: ${_this.note}, tag: ${_this.tag})';
}


}

/// @nodoc
abstract mixin class $TeamListItemCopyWith<$Res>  {
  factory $TeamListItemCopyWith(TeamListItem value, $Res Function(TeamListItem) _then) = _$TeamListItemCopyWithImpl;
@useResult
$Res call({
 Team team, String meta, String note, String tag
});


$TeamCopyWith<$Res> get team;

}
/// @nodoc
class _$TeamListItemCopyWithImpl<$Res>
    implements $TeamListItemCopyWith<$Res> {
  _$TeamListItemCopyWithImpl(this._self, this._then);

  final TeamListItem _self;
  final $Res Function(TeamListItem) _then;

/// Create a copy of TeamListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? team = null,Object? meta = null,Object? note = null,Object? tag = null,}) {
  return _then(TeamListItem(
team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Team,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of TeamListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamCopyWith<$Res> get team {
  
  return $TeamCopyWith<$Res>(_self.team, (value) {
    return _then(_self.copyWith(team: value));
  });
}
}


/// Adds pattern-matching-related methods to [TeamListItem].
extension TeamListItemPatterns on TeamListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamListItem value)  $default,){
final _that = this;
switch (_that) {
case _TeamListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamListItem value)?  $default,){
final _that = this;
switch (_that) {
case _TeamListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Team team,  String meta,  String note,  String tag)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamListItem() when $default != null:
return $default(_that.team,_that.meta,_that.note,_that.tag);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Team team,  String meta,  String note,  String tag)  $default,) {final _that = this;
switch (_that) {
case _TeamListItem():
return $default(_that.team,_that.meta,_that.note,_that.tag);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Team team,  String meta,  String note,  String tag)?  $default,) {final _that = this;
switch (_that) {
case _TeamListItem() when $default != null:
return $default(_that.team,_that.meta,_that.note,_that.tag);case _:
  return null;

}
}

}

/// @nodoc


class _TeamListItem implements TeamListItem {
  const _TeamListItem({required this.team, this.meta = '', this.note = '', this.tag = ''});
  

@override final  Team team;
@override@JsonKey() final  String meta;
@override@JsonKey() final  String note;
@override@JsonKey() final  String tag;

/// Create a copy of TeamListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamListItemCopyWith<_TeamListItem> get copyWith => __$TeamListItemCopyWithImpl<_TeamListItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamListItem&&(identical(other.team, team) || other.team == team)&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.note, note) || other.note == note)&&(identical(other.tag, tag) || other.tag == tag));
}


@override
int get hashCode {
    return Object.hash(runtimeType,team,meta,note,tag);
}

@override
String toString() {
    return 'TeamListItem(team: $team, meta: $meta, note: $note, tag: $tag)';
}


}

/// @nodoc
abstract mixin class _$TeamListItemCopyWith<$Res> implements $TeamListItemCopyWith<$Res> {
  factory _$TeamListItemCopyWith(_TeamListItem value, $Res Function(_TeamListItem) _then) = __$TeamListItemCopyWithImpl;
@override @useResult
$Res call({
 Team team, String meta, String note, String tag
});


@override $TeamCopyWith<$Res> get team;

}
/// @nodoc
class __$TeamListItemCopyWithImpl<$Res>
    implements _$TeamListItemCopyWith<$Res> {
  __$TeamListItemCopyWithImpl(this._self, this._then);

  final _TeamListItem _self;
  final $Res Function(_TeamListItem) _then;

/// Create a copy of TeamListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? team = null,Object? meta = null,Object? note = null,Object? tag = null,}) {
  return _then(_TeamListItem(
team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Team,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of TeamListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamCopyWith<$Res> get team {
  
  return $TeamCopyWith<$Res>(_self.team, (value) {
    return _then(_self.copyWith(team: value));
  });
}
}

/// @nodoc
mixin _$TeamMember {

 PlayerSummary get player; double? get rating; String get club;/// "Captain" or "Vice-captain".
 String? get captain; Availability get availability; bool get reserve; bool get staff; String get staffTitle;
/// Create a copy of TeamMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamMemberCopyWith<TeamMember> get copyWith => _$TeamMemberCopyWithImpl<TeamMember>(this as TeamMember, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamMember&&(identical(other.player, _this.player) || other.player == _this.player)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.club, _this.club) || other.club == _this.club)&&(identical(other.captain, _this.captain) || other.captain == _this.captain)&&(identical(other.availability, _this.availability) || other.availability == _this.availability)&&(identical(other.reserve, _this.reserve) || other.reserve == _this.reserve)&&(identical(other.staff, _this.staff) || other.staff == _this.staff)&&(identical(other.staffTitle, _this.staffTitle) || other.staffTitle == _this.staffTitle));
}


@override
int get hashCode {
  final _this = this as TeamMember;
  return Object.hash(runtimeType,_this.player,_this.rating,_this.club,_this.captain,_this.availability,_this.reserve,_this.staff,_this.staffTitle);
}

@override
String toString() {
  final _this = this as TeamMember;
  return 'TeamMember(player: ${_this.player}, rating: ${_this.rating}, club: ${_this.club}, captain: ${_this.captain}, availability: ${_this.availability}, reserve: ${_this.reserve}, staff: ${_this.staff}, staffTitle: ${_this.staffTitle})';
}


}

/// @nodoc
abstract mixin class $TeamMemberCopyWith<$Res>  {
  factory $TeamMemberCopyWith(TeamMember value, $Res Function(TeamMember) _then) = _$TeamMemberCopyWithImpl;
@useResult
$Res call({
 PlayerSummary player, double? rating, String club, String? captain, Availability availability, bool reserve, bool staff, String staffTitle
});


$PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class _$TeamMemberCopyWithImpl<$Res>
    implements $TeamMemberCopyWith<$Res> {
  _$TeamMemberCopyWithImpl(this._self, this._then);

  final TeamMember _self;
  final $Res Function(TeamMember) _then;

/// Create a copy of TeamMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? player = null,Object? rating = freezed,Object? club = null,Object? captain = freezed,Object? availability = null,Object? reserve = null,Object? staff = null,Object? staffTitle = null,}) {
  return _then(TeamMember(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as String,captain: freezed == captain ? _self.captain : captain // ignore: cast_nullable_to_non_nullable
as String?,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as Availability,reserve: null == reserve ? _self.reserve : reserve // ignore: cast_nullable_to_non_nullable
as bool,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as bool,staffTitle: null == staffTitle ? _self.staffTitle : staffTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of TeamMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get player {
  
  return $PlayerSummaryCopyWith<$Res>(_self.player, (value) {
    return _then(_self.copyWith(player: value));
  });
}
}


/// Adds pattern-matching-related methods to [TeamMember].
extension TeamMemberPatterns on TeamMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamMember value)  $default,){
final _that = this;
switch (_that) {
case _TeamMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamMember value)?  $default,){
final _that = this;
switch (_that) {
case _TeamMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerSummary player,  double? rating,  String club,  String? captain,  Availability availability,  bool reserve,  bool staff,  String staffTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamMember() when $default != null:
return $default(_that.player,_that.rating,_that.club,_that.captain,_that.availability,_that.reserve,_that.staff,_that.staffTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerSummary player,  double? rating,  String club,  String? captain,  Availability availability,  bool reserve,  bool staff,  String staffTitle)  $default,) {final _that = this;
switch (_that) {
case _TeamMember():
return $default(_that.player,_that.rating,_that.club,_that.captain,_that.availability,_that.reserve,_that.staff,_that.staffTitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerSummary player,  double? rating,  String club,  String? captain,  Availability availability,  bool reserve,  bool staff,  String staffTitle)?  $default,) {final _that = this;
switch (_that) {
case _TeamMember() when $default != null:
return $default(_that.player,_that.rating,_that.club,_that.captain,_that.availability,_that.reserve,_that.staff,_that.staffTitle);case _:
  return null;

}
}

}

/// @nodoc


class _TeamMember extends TeamMember {
  const _TeamMember({required this.player, this.rating, this.club = '', this.captain, this.availability = Availability.noReply, this.reserve = false, this.staff = false, this.staffTitle = ''}): super._();
  

@override final  PlayerSummary player;
@override final  double? rating;
@override@JsonKey() final  String club;
/// "Captain" or "Vice-captain".
@override final  String? captain;
@override@JsonKey() final  Availability availability;
@override@JsonKey() final  bool reserve;
@override@JsonKey() final  bool staff;
@override@JsonKey() final  String staffTitle;

/// Create a copy of TeamMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamMemberCopyWith<_TeamMember> get copyWith => __$TeamMemberCopyWithImpl<_TeamMember>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamMember&&(identical(other.player, player) || other.player == player)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.club, club) || other.club == club)&&(identical(other.captain, captain) || other.captain == captain)&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.reserve, reserve) || other.reserve == reserve)&&(identical(other.staff, staff) || other.staff == staff)&&(identical(other.staffTitle, staffTitle) || other.staffTitle == staffTitle));
}


@override
int get hashCode {
    return Object.hash(runtimeType,player,rating,club,captain,availability,reserve,staff,staffTitle);
}

@override
String toString() {
    return 'TeamMember(player: $player, rating: $rating, club: $club, captain: $captain, availability: $availability, reserve: $reserve, staff: $staff, staffTitle: $staffTitle)';
}


}

/// @nodoc
abstract mixin class _$TeamMemberCopyWith<$Res> implements $TeamMemberCopyWith<$Res> {
  factory _$TeamMemberCopyWith(_TeamMember value, $Res Function(_TeamMember) _then) = __$TeamMemberCopyWithImpl;
@override @useResult
$Res call({
 PlayerSummary player, double? rating, String club, String? captain, Availability availability, bool reserve, bool staff, String staffTitle
});


@override $PlayerSummaryCopyWith<$Res> get player;

}
/// @nodoc
class __$TeamMemberCopyWithImpl<$Res>
    implements _$TeamMemberCopyWith<$Res> {
  __$TeamMemberCopyWithImpl(this._self, this._then);

  final _TeamMember _self;
  final $Res Function(_TeamMember) _then;

/// Create a copy of TeamMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? player = null,Object? rating = freezed,Object? club = null,Object? captain = freezed,Object? availability = null,Object? reserve = null,Object? staff = null,Object? staffTitle = null,}) {
  return _then(_TeamMember(
player: null == player ? _self.player : player // ignore: cast_nullable_to_non_nullable
as PlayerSummary,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,club: null == club ? _self.club : club // ignore: cast_nullable_to_non_nullable
as String,captain: freezed == captain ? _self.captain : captain // ignore: cast_nullable_to_non_nullable
as String?,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as Availability,reserve: null == reserve ? _self.reserve : reserve // ignore: cast_nullable_to_non_nullable
as bool,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as bool,staffTitle: null == staffTitle ? _self.staffTitle : staffTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of TeamMember
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
mixin _$TeamSession {

 String get id; String get title; DateTime get startsAt; DateTime? get endsAt; String get venue; bool get fixture; int get attending; int get squad;
/// Create a copy of TeamSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamSessionCopyWith<TeamSession> get copyWith => _$TeamSessionCopyWithImpl<TeamSession>(this as TeamSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.endsAt, _this.endsAt) || other.endsAt == _this.endsAt)&&(identical(other.venue, _this.venue) || other.venue == _this.venue)&&(identical(other.fixture, _this.fixture) || other.fixture == _this.fixture)&&(identical(other.attending, _this.attending) || other.attending == _this.attending)&&(identical(other.squad, _this.squad) || other.squad == _this.squad));
}


@override
int get hashCode {
  final _this = this as TeamSession;
  return Object.hash(runtimeType,_this.id,_this.title,_this.startsAt,_this.endsAt,_this.venue,_this.fixture,_this.attending,_this.squad);
}

@override
String toString() {
  final _this = this as TeamSession;
  return 'TeamSession(id: ${_this.id}, title: ${_this.title}, startsAt: ${_this.startsAt}, endsAt: ${_this.endsAt}, venue: ${_this.venue}, fixture: ${_this.fixture}, attending: ${_this.attending}, squad: ${_this.squad})';
}


}

/// @nodoc
abstract mixin class $TeamSessionCopyWith<$Res>  {
  factory $TeamSessionCopyWith(TeamSession value, $Res Function(TeamSession) _then) = _$TeamSessionCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime startsAt, DateTime? endsAt, String venue, bool fixture, int attending, int squad
});




}
/// @nodoc
class _$TeamSessionCopyWithImpl<$Res>
    implements $TeamSessionCopyWith<$Res> {
  _$TeamSessionCopyWithImpl(this._self, this._then);

  final TeamSession _self;
  final $Res Function(TeamSession) _then;

/// Create a copy of TeamSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? startsAt = null,Object? endsAt = freezed,Object? venue = null,Object? fixture = null,Object? attending = null,Object? squad = null,}) {
  return _then(TeamSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,fixture: null == fixture ? _self.fixture : fixture // ignore: cast_nullable_to_non_nullable
as bool,attending: null == attending ? _self.attending : attending // ignore: cast_nullable_to_non_nullable
as int,squad: null == squad ? _self.squad : squad // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamSession].
extension TeamSessionPatterns on TeamSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamSession value)  $default,){
final _that = this;
switch (_that) {
case _TeamSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamSession value)?  $default,){
final _that = this;
switch (_that) {
case _TeamSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime startsAt,  DateTime? endsAt,  String venue,  bool fixture,  int attending,  int squad)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamSession() when $default != null:
return $default(_that.id,_that.title,_that.startsAt,_that.endsAt,_that.venue,_that.fixture,_that.attending,_that.squad);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime startsAt,  DateTime? endsAt,  String venue,  bool fixture,  int attending,  int squad)  $default,) {final _that = this;
switch (_that) {
case _TeamSession():
return $default(_that.id,_that.title,_that.startsAt,_that.endsAt,_that.venue,_that.fixture,_that.attending,_that.squad);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime startsAt,  DateTime? endsAt,  String venue,  bool fixture,  int attending,  int squad)?  $default,) {final _that = this;
switch (_that) {
case _TeamSession() when $default != null:
return $default(_that.id,_that.title,_that.startsAt,_that.endsAt,_that.venue,_that.fixture,_that.attending,_that.squad);case _:
  return null;

}
}

}

/// @nodoc


class _TeamSession implements TeamSession {
  const _TeamSession({required this.id, required this.title, required this.startsAt, this.endsAt, this.venue = '', this.fixture = false, this.attending = 0, this.squad = 0});
  

@override final  String id;
@override final  String title;
@override final  DateTime startsAt;
@override final  DateTime? endsAt;
@override@JsonKey() final  String venue;
@override@JsonKey() final  bool fixture;
@override@JsonKey() final  int attending;
@override@JsonKey() final  int squad;

/// Create a copy of TeamSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamSessionCopyWith<_TeamSession> get copyWith => __$TeamSessionCopyWithImpl<_TeamSession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamSession&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.fixture, fixture) || other.fixture == fixture)&&(identical(other.attending, attending) || other.attending == attending)&&(identical(other.squad, squad) || other.squad == squad));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,startsAt,endsAt,venue,fixture,attending,squad);
}

@override
String toString() {
    return 'TeamSession(id: $id, title: $title, startsAt: $startsAt, endsAt: $endsAt, venue: $venue, fixture: $fixture, attending: $attending, squad: $squad)';
}


}

/// @nodoc
abstract mixin class _$TeamSessionCopyWith<$Res> implements $TeamSessionCopyWith<$Res> {
  factory _$TeamSessionCopyWith(_TeamSession value, $Res Function(_TeamSession) _then) = __$TeamSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime startsAt, DateTime? endsAt, String venue, bool fixture, int attending, int squad
});




}
/// @nodoc
class __$TeamSessionCopyWithImpl<$Res>
    implements _$TeamSessionCopyWith<$Res> {
  __$TeamSessionCopyWithImpl(this._self, this._then);

  final _TeamSession _self;
  final $Res Function(_TeamSession) _then;

/// Create a copy of TeamSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? startsAt = null,Object? endsAt = freezed,Object? venue = null,Object? fixture = null,Object? attending = null,Object? squad = null,}) {
  return _then(_TeamSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,fixture: null == fixture ? _self.fixture : fixture // ignore: cast_nullable_to_non_nullable
as bool,attending: null == attending ? _self.attending : attending // ignore: cast_nullable_to_non_nullable
as int,squad: null == squad ? _self.squad : squad // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TeamResult {

 String get opponent; DateTime get at; String get competition; bool get won; String get score;
/// Create a copy of TeamResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamResultCopyWith<TeamResult> get copyWith => _$TeamResultCopyWithImpl<TeamResult>(this as TeamResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamResult&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.competition, _this.competition) || other.competition == _this.competition)&&(identical(other.won, _this.won) || other.won == _this.won)&&(identical(other.score, _this.score) || other.score == _this.score));
}


@override
int get hashCode {
  final _this = this as TeamResult;
  return Object.hash(runtimeType,_this.opponent,_this.at,_this.competition,_this.won,_this.score);
}

@override
String toString() {
  final _this = this as TeamResult;
  return 'TeamResult(opponent: ${_this.opponent}, at: ${_this.at}, competition: ${_this.competition}, won: ${_this.won}, score: ${_this.score})';
}


}

/// @nodoc
abstract mixin class $TeamResultCopyWith<$Res>  {
  factory $TeamResultCopyWith(TeamResult value, $Res Function(TeamResult) _then) = _$TeamResultCopyWithImpl;
@useResult
$Res call({
 String opponent, DateTime at, String competition, bool won, String score
});




}
/// @nodoc
class _$TeamResultCopyWithImpl<$Res>
    implements $TeamResultCopyWith<$Res> {
  _$TeamResultCopyWithImpl(this._self, this._then);

  final TeamResult _self;
  final $Res Function(TeamResult) _then;

/// Create a copy of TeamResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opponent = null,Object? at = null,Object? competition = null,Object? won = null,Object? score = null,}) {
  return _then(TeamResult(
opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as String,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamResult].
extension TeamResultPatterns on TeamResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamResult value)  $default,){
final _that = this;
switch (_that) {
case _TeamResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamResult value)?  $default,){
final _that = this;
switch (_that) {
case _TeamResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String opponent,  DateTime at,  String competition,  bool won,  String score)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamResult() when $default != null:
return $default(_that.opponent,_that.at,_that.competition,_that.won,_that.score);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String opponent,  DateTime at,  String competition,  bool won,  String score)  $default,) {final _that = this;
switch (_that) {
case _TeamResult():
return $default(_that.opponent,_that.at,_that.competition,_that.won,_that.score);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String opponent,  DateTime at,  String competition,  bool won,  String score)?  $default,) {final _that = this;
switch (_that) {
case _TeamResult() when $default != null:
return $default(_that.opponent,_that.at,_that.competition,_that.won,_that.score);case _:
  return null;

}
}

}

/// @nodoc


class _TeamResult implements TeamResult {
  const _TeamResult({required this.opponent, required this.at, this.competition = '', required this.won, required this.score});
  

@override final  String opponent;
@override final  DateTime at;
@override@JsonKey() final  String competition;
@override final  bool won;
@override final  String score;

/// Create a copy of TeamResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamResultCopyWith<_TeamResult> get copyWith => __$TeamResultCopyWithImpl<_TeamResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamResult&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.at, at) || other.at == at)&&(identical(other.competition, competition) || other.competition == competition)&&(identical(other.won, won) || other.won == won)&&(identical(other.score, score) || other.score == score));
}


@override
int get hashCode {
    return Object.hash(runtimeType,opponent,at,competition,won,score);
}

@override
String toString() {
    return 'TeamResult(opponent: $opponent, at: $at, competition: $competition, won: $won, score: $score)';
}


}

/// @nodoc
abstract mixin class _$TeamResultCopyWith<$Res> implements $TeamResultCopyWith<$Res> {
  factory _$TeamResultCopyWith(_TeamResult value, $Res Function(_TeamResult) _then) = __$TeamResultCopyWithImpl;
@override @useResult
$Res call({
 String opponent, DateTime at, String competition, bool won, String score
});




}
/// @nodoc
class __$TeamResultCopyWithImpl<$Res>
    implements _$TeamResultCopyWith<$Res> {
  __$TeamResultCopyWithImpl(this._self, this._then);

  final _TeamResult _self;
  final $Res Function(_TeamResult) _then;

/// Create a copy of TeamResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opponent = null,Object? at = null,Object? competition = null,Object? won = null,Object? score = null,}) {
  return _then(_TeamResult(
opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as String,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as bool,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LineupSlot {

 String get key; String get label; int get size;
/// Create a copy of LineupSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineupSlotCopyWith<LineupSlot> get copyWith => _$LineupSlotCopyWithImpl<LineupSlot>(this as LineupSlot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LineupSlot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineupSlot&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.size, _this.size) || other.size == _this.size));
}


@override
int get hashCode {
  final _this = this as LineupSlot;
  return Object.hash(runtimeType,_this.key,_this.label,_this.size);
}

@override
String toString() {
  final _this = this as LineupSlot;
  return 'LineupSlot(key: ${_this.key}, label: ${_this.label}, size: ${_this.size})';
}


}

/// @nodoc
abstract mixin class $LineupSlotCopyWith<$Res>  {
  factory $LineupSlotCopyWith(LineupSlot value, $Res Function(LineupSlot) _then) = _$LineupSlotCopyWithImpl;
@useResult
$Res call({
 String key, String label, int size
});




}
/// @nodoc
class _$LineupSlotCopyWithImpl<$Res>
    implements $LineupSlotCopyWith<$Res> {
  _$LineupSlotCopyWithImpl(this._self, this._then);

  final LineupSlot _self;
  final $Res Function(LineupSlot) _then;

/// Create a copy of LineupSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? size = null,}) {
  return _then(LineupSlot(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LineupSlot].
extension LineupSlotPatterns on LineupSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LineupSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LineupSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LineupSlot value)  $default,){
final _that = this;
switch (_that) {
case _LineupSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LineupSlot value)?  $default,){
final _that = this;
switch (_that) {
case _LineupSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LineupSlot() when $default != null:
return $default(_that.key,_that.label,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  int size)  $default,) {final _that = this;
switch (_that) {
case _LineupSlot():
return $default(_that.key,_that.label,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  int size)?  $default,) {final _that = this;
switch (_that) {
case _LineupSlot() when $default != null:
return $default(_that.key,_that.label,_that.size);case _:
  return null;

}
}

}

/// @nodoc


class _LineupSlot extends LineupSlot {
  const _LineupSlot({required this.key, required this.label, this.size = 1}): super._();
  

@override final  String key;
@override final  String label;
@override@JsonKey() final  int size;

/// Create a copy of LineupSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LineupSlotCopyWith<_LineupSlot> get copyWith => __$LineupSlotCopyWithImpl<_LineupSlot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LineupSlot&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,label,size);
}

@override
String toString() {
    return 'LineupSlot(key: $key, label: $label, size: $size)';
}


}

/// @nodoc
abstract mixin class _$LineupSlotCopyWith<$Res> implements $LineupSlotCopyWith<$Res> {
  factory _$LineupSlotCopyWith(_LineupSlot value, $Res Function(_LineupSlot) _then) = __$LineupSlotCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, int size
});




}
/// @nodoc
class __$LineupSlotCopyWithImpl<$Res>
    implements _$LineupSlotCopyWith<$Res> {
  __$LineupSlotCopyWithImpl(this._self, this._then);

  final _LineupSlot _self;
  final $Res Function(_LineupSlot) _then;

/// Create a copy of LineupSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? size = null,}) {
  return _then(_LineupSlot(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Fixture {

 String get id; String get teamId; String get teamName; String get opponent; DateTime get startsAt; String get competition; String get venue; DateTime? get lineupLocksAt; List<String> get notes; String get setBy; String get lineupRule; Availability get myAvailability; List<LineupSlot> get slots; Map<String, List<String?>> get lineup; bool get published;
/// Create a copy of Fixture
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FixtureCopyWith<Fixture> get copyWith => _$FixtureCopyWithImpl<Fixture>(this as Fixture, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Fixture;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Fixture&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teamId, _this.teamId) || other.teamId == _this.teamId)&&(identical(other.teamName, _this.teamName) || other.teamName == _this.teamName)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.competition, _this.competition) || other.competition == _this.competition)&&(identical(other.venue, _this.venue) || other.venue == _this.venue)&&(identical(other.lineupLocksAt, _this.lineupLocksAt) || other.lineupLocksAt == _this.lineupLocksAt)&&const DeepCollectionEquality().equals(other.notes, _this.notes)&&(identical(other.setBy, _this.setBy) || other.setBy == _this.setBy)&&(identical(other.lineupRule, _this.lineupRule) || other.lineupRule == _this.lineupRule)&&(identical(other.myAvailability, _this.myAvailability) || other.myAvailability == _this.myAvailability)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&const DeepCollectionEquality().equals(other.lineup, _this.lineup)&&(identical(other.published, _this.published) || other.published == _this.published));
}


@override
int get hashCode {
  final _this = this as Fixture;
  return Object.hash(runtimeType,_this.id,_this.teamId,_this.teamName,_this.opponent,_this.startsAt,_this.competition,_this.venue,_this.lineupLocksAt,const DeepCollectionEquality().hash(_this.notes),_this.setBy,_this.lineupRule,_this.myAvailability,const DeepCollectionEquality().hash(_this.slots),const DeepCollectionEquality().hash(_this.lineup),_this.published);
}

@override
String toString() {
  final _this = this as Fixture;
  return 'Fixture(id: ${_this.id}, teamId: ${_this.teamId}, teamName: ${_this.teamName}, opponent: ${_this.opponent}, startsAt: ${_this.startsAt}, competition: ${_this.competition}, venue: ${_this.venue}, lineupLocksAt: ${_this.lineupLocksAt}, notes: ${_this.notes}, setBy: ${_this.setBy}, lineupRule: ${_this.lineupRule}, myAvailability: ${_this.myAvailability}, slots: ${_this.slots}, lineup: ${_this.lineup}, published: ${_this.published})';
}


}

/// @nodoc
abstract mixin class $FixtureCopyWith<$Res>  {
  factory $FixtureCopyWith(Fixture value, $Res Function(Fixture) _then) = _$FixtureCopyWithImpl;
@useResult
$Res call({
 String id, String teamId, String teamName, String opponent, DateTime startsAt, String competition, String venue, DateTime? lineupLocksAt, List<String> notes, String setBy, String lineupRule, Availability myAvailability, List<LineupSlot> slots, Map<String, List<String?>> lineup, bool published
});




}
/// @nodoc
class _$FixtureCopyWithImpl<$Res>
    implements $FixtureCopyWith<$Res> {
  _$FixtureCopyWithImpl(this._self, this._then);

  final Fixture _self;
  final $Res Function(Fixture) _then;

/// Create a copy of Fixture
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teamId = null,Object? teamName = null,Object? opponent = null,Object? startsAt = null,Object? competition = null,Object? venue = null,Object? lineupLocksAt = freezed,Object? notes = null,Object? setBy = null,Object? lineupRule = null,Object? myAvailability = null,Object? slots = null,Object? lineup = null,Object? published = null,}) {
  return _then(Fixture(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as String,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,lineupLocksAt: freezed == lineupLocksAt ? _self.lineupLocksAt : lineupLocksAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<String>,setBy: null == setBy ? _self.setBy : setBy // ignore: cast_nullable_to_non_nullable
as String,lineupRule: null == lineupRule ? _self.lineupRule : lineupRule // ignore: cast_nullable_to_non_nullable
as String,myAvailability: null == myAvailability ? _self.myAvailability : myAvailability // ignore: cast_nullable_to_non_nullable
as Availability,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<LineupSlot>,lineup: null == lineup ? _self.lineup : lineup // ignore: cast_nullable_to_non_nullable
as Map<String, List<String?>>,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Fixture].
extension FixturePatterns on Fixture {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Fixture value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Fixture() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Fixture value)  $default,){
final _that = this;
switch (_that) {
case _Fixture():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Fixture value)?  $default,){
final _that = this;
switch (_that) {
case _Fixture() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String teamId,  String teamName,  String opponent,  DateTime startsAt,  String competition,  String venue,  DateTime? lineupLocksAt,  List<String> notes,  String setBy,  String lineupRule,  Availability myAvailability,  List<LineupSlot> slots,  Map<String, List<String?>> lineup,  bool published)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Fixture() when $default != null:
return $default(_that.id,_that.teamId,_that.teamName,_that.opponent,_that.startsAt,_that.competition,_that.venue,_that.lineupLocksAt,_that.notes,_that.setBy,_that.lineupRule,_that.myAvailability,_that.slots,_that.lineup,_that.published);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String teamId,  String teamName,  String opponent,  DateTime startsAt,  String competition,  String venue,  DateTime? lineupLocksAt,  List<String> notes,  String setBy,  String lineupRule,  Availability myAvailability,  List<LineupSlot> slots,  Map<String, List<String?>> lineup,  bool published)  $default,) {final _that = this;
switch (_that) {
case _Fixture():
return $default(_that.id,_that.teamId,_that.teamName,_that.opponent,_that.startsAt,_that.competition,_that.venue,_that.lineupLocksAt,_that.notes,_that.setBy,_that.lineupRule,_that.myAvailability,_that.slots,_that.lineup,_that.published);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String teamId,  String teamName,  String opponent,  DateTime startsAt,  String competition,  String venue,  DateTime? lineupLocksAt,  List<String> notes,  String setBy,  String lineupRule,  Availability myAvailability,  List<LineupSlot> slots,  Map<String, List<String?>> lineup,  bool published)?  $default,) {final _that = this;
switch (_that) {
case _Fixture() when $default != null:
return $default(_that.id,_that.teamId,_that.teamName,_that.opponent,_that.startsAt,_that.competition,_that.venue,_that.lineupLocksAt,_that.notes,_that.setBy,_that.lineupRule,_that.myAvailability,_that.slots,_that.lineup,_that.published);case _:
  return null;

}
}

}

/// @nodoc


class _Fixture implements Fixture {
  const _Fixture({required this.id, required this.teamId, required this.teamName, required this.opponent, required this.startsAt, this.competition = '', this.venue = '', this.lineupLocksAt,  List<String> notes = const [], this.setBy = '', this.lineupRule = '', this.myAvailability = Availability.noReply,  List<LineupSlot> slots = const [],  Map<String, List<String?>> lineup = const {}, this.published = false}): _notes = notes,_slots = slots,_lineup = lineup;
  

@override final  String id;
@override final  String teamId;
@override final  String teamName;
@override final  String opponent;
@override final  DateTime startsAt;
@override@JsonKey() final  String competition;
@override@JsonKey() final  String venue;
@override final  DateTime? lineupLocksAt;
 final  List<String> _notes;
@override@JsonKey() List<String> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

@override@JsonKey() final  String setBy;
@override@JsonKey() final  String lineupRule;
@override@JsonKey() final  Availability myAvailability;
 final  List<LineupSlot> _slots;
@override@JsonKey() List<LineupSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}

 final  Map<String, List<String?>> _lineup;
@override@JsonKey() Map<String, List<String?>> get lineup {
  if (_lineup is EqualUnmodifiableMapView) return _lineup;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lineup);
}

@override@JsonKey() final  bool published;

/// Create a copy of Fixture
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FixtureCopyWith<_Fixture> get copyWith => __$FixtureCopyWithImpl<_Fixture>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Fixture&&(identical(other.id, id) || other.id == id)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.competition, competition) || other.competition == competition)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.lineupLocksAt, lineupLocksAt) || other.lineupLocksAt == lineupLocksAt)&&const DeepCollectionEquality().equals(other.notes, _notes)&&(identical(other.setBy, setBy) || other.setBy == setBy)&&(identical(other.lineupRule, lineupRule) || other.lineupRule == lineupRule)&&(identical(other.myAvailability, myAvailability) || other.myAvailability == myAvailability)&&const DeepCollectionEquality().equals(other.slots, _slots)&&const DeepCollectionEquality().equals(other.lineup, _lineup)&&(identical(other.published, published) || other.published == published));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,teamId,teamName,opponent,startsAt,competition,venue,lineupLocksAt,const DeepCollectionEquality().hash(_notes),setBy,lineupRule,myAvailability,const DeepCollectionEquality().hash(_slots),const DeepCollectionEquality().hash(_lineup),published);
}

@override
String toString() {
    return 'Fixture(id: $id, teamId: $teamId, teamName: $teamName, opponent: $opponent, startsAt: $startsAt, competition: $competition, venue: $venue, lineupLocksAt: $lineupLocksAt, notes: $notes, setBy: $setBy, lineupRule: $lineupRule, myAvailability: $myAvailability, slots: $slots, lineup: $lineup, published: $published)';
}


}

/// @nodoc
abstract mixin class _$FixtureCopyWith<$Res> implements $FixtureCopyWith<$Res> {
  factory _$FixtureCopyWith(_Fixture value, $Res Function(_Fixture) _then) = __$FixtureCopyWithImpl;
@override @useResult
$Res call({
 String id, String teamId, String teamName, String opponent, DateTime startsAt, String competition, String venue, DateTime? lineupLocksAt, List<String> notes, String setBy, String lineupRule, Availability myAvailability, List<LineupSlot> slots, Map<String, List<String?>> lineup, bool published
});




}
/// @nodoc
class __$FixtureCopyWithImpl<$Res>
    implements _$FixtureCopyWith<$Res> {
  __$FixtureCopyWithImpl(this._self, this._then);

  final _Fixture _self;
  final $Res Function(_Fixture) _then;

/// Create a copy of Fixture
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teamId = null,Object? teamName = null,Object? opponent = null,Object? startsAt = null,Object? competition = null,Object? venue = null,Object? lineupLocksAt = freezed,Object? notes = null,Object? setBy = null,Object? lineupRule = null,Object? myAvailability = null,Object? slots = null,Object? lineup = null,Object? published = null,}) {
  return _then(_Fixture(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as String,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,lineupLocksAt: freezed == lineupLocksAt ? _self.lineupLocksAt : lineupLocksAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<String>,setBy: null == setBy ? _self.setBy : setBy // ignore: cast_nullable_to_non_nullable
as String,lineupRule: null == lineupRule ? _self.lineupRule : lineupRule // ignore: cast_nullable_to_non_nullable
as String,myAvailability: null == myAvailability ? _self.myAvailability : myAvailability // ignore: cast_nullable_to_non_nullable
as Availability,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<LineupSlot>,lineup: null == lineup ? _self._lineup : lineup // ignore: cast_nullable_to_non_nullable
as Map<String, List<String?>>,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$TeamDraft {

 String get name; String get represents; Set<String> get subTeams; String? get ownSubTeam; ClubSport get sport; List<String> get staff; Set<String> get players;
/// Create a copy of TeamDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamDraftCopyWith<TeamDraft> get copyWith => _$TeamDraftCopyWithImpl<TeamDraft>(this as TeamDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamDraft&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.represents, _this.represents) || other.represents == _this.represents)&&const DeepCollectionEquality().equals(other.subTeams, _this.subTeams)&&(identical(other.ownSubTeam, _this.ownSubTeam) || other.ownSubTeam == _this.ownSubTeam)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&const DeepCollectionEquality().equals(other.staff, _this.staff)&&const DeepCollectionEquality().equals(other.players, _this.players));
}


@override
int get hashCode {
  final _this = this as TeamDraft;
  return Object.hash(runtimeType,_this.name,_this.represents,const DeepCollectionEquality().hash(_this.subTeams),_this.ownSubTeam,_this.sport,const DeepCollectionEquality().hash(_this.staff),const DeepCollectionEquality().hash(_this.players));
}

@override
String toString() {
  final _this = this as TeamDraft;
  return 'TeamDraft(name: ${_this.name}, represents: ${_this.represents}, subTeams: ${_this.subTeams}, ownSubTeam: ${_this.ownSubTeam}, sport: ${_this.sport}, staff: ${_this.staff}, players: ${_this.players})';
}


}

/// @nodoc
abstract mixin class $TeamDraftCopyWith<$Res>  {
  factory $TeamDraftCopyWith(TeamDraft value, $Res Function(TeamDraft) _then) = _$TeamDraftCopyWithImpl;
@useResult
$Res call({
 String name, String represents, Set<String> subTeams, String? ownSubTeam, ClubSport sport, List<String> staff, Set<String> players
});




}
/// @nodoc
class _$TeamDraftCopyWithImpl<$Res>
    implements $TeamDraftCopyWith<$Res> {
  _$TeamDraftCopyWithImpl(this._self, this._then);

  final TeamDraft _self;
  final $Res Function(TeamDraft) _then;

/// Create a copy of TeamDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? represents = null,Object? subTeams = null,Object? ownSubTeam = freezed,Object? sport = null,Object? staff = null,Object? players = null,}) {
  return _then(TeamDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,represents: null == represents ? _self.represents : represents // ignore: cast_nullable_to_non_nullable
as String,subTeams: null == subTeams ? _self.subTeams : subTeams // ignore: cast_nullable_to_non_nullable
as Set<String>,ownSubTeam: freezed == ownSubTeam ? _self.ownSubTeam : ownSubTeam // ignore: cast_nullable_to_non_nullable
as String?,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as ClubSport,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as List<String>,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamDraft].
extension TeamDraftPatterns on TeamDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamDraft value)  $default,){
final _that = this;
switch (_that) {
case _TeamDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamDraft value)?  $default,){
final _that = this;
switch (_that) {
case _TeamDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String represents,  Set<String> subTeams,  String? ownSubTeam,  ClubSport sport,  List<String> staff,  Set<String> players)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamDraft() when $default != null:
return $default(_that.name,_that.represents,_that.subTeams,_that.ownSubTeam,_that.sport,_that.staff,_that.players);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String represents,  Set<String> subTeams,  String? ownSubTeam,  ClubSport sport,  List<String> staff,  Set<String> players)  $default,) {final _that = this;
switch (_that) {
case _TeamDraft():
return $default(_that.name,_that.represents,_that.subTeams,_that.ownSubTeam,_that.sport,_that.staff,_that.players);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String represents,  Set<String> subTeams,  String? ownSubTeam,  ClubSport sport,  List<String> staff,  Set<String> players)?  $default,) {final _that = this;
switch (_that) {
case _TeamDraft() when $default != null:
return $default(_that.name,_that.represents,_that.subTeams,_that.ownSubTeam,_that.sport,_that.staff,_that.players);case _:
  return null;

}
}

}

/// @nodoc


class _TeamDraft implements TeamDraft {
  const _TeamDraft({this.name = '', this.represents = '',  Set<String> subTeams = const {'Under 15', 'Under 17'}, this.ownSubTeam, this.sport = ClubSport.badminton,  List<String> staff = const [],  Set<String> players = const {}}): _subTeams = subTeams,_staff = staff,_players = players;
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String represents;
 final  Set<String> _subTeams;
@override@JsonKey() Set<String> get subTeams {
  if (_subTeams is EqualUnmodifiableSetView) return _subTeams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_subTeams);
}

@override final  String? ownSubTeam;
@override@JsonKey() final  ClubSport sport;
 final  List<String> _staff;
@override@JsonKey() List<String> get staff {
  if (_staff is EqualUnmodifiableListView) return _staff;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_staff);
}

 final  Set<String> _players;
@override@JsonKey() Set<String> get players {
  if (_players is EqualUnmodifiableSetView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_players);
}


/// Create a copy of TeamDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamDraftCopyWith<_TeamDraft> get copyWith => __$TeamDraftCopyWithImpl<_TeamDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.represents, represents) || other.represents == represents)&&const DeepCollectionEquality().equals(other.subTeams, _subTeams)&&(identical(other.ownSubTeam, ownSubTeam) || other.ownSubTeam == ownSubTeam)&&(identical(other.sport, sport) || other.sport == sport)&&const DeepCollectionEquality().equals(other.staff, _staff)&&const DeepCollectionEquality().equals(other.players, _players));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,represents,const DeepCollectionEquality().hash(_subTeams),ownSubTeam,sport,const DeepCollectionEquality().hash(_staff),const DeepCollectionEquality().hash(_players));
}

@override
String toString() {
    return 'TeamDraft(name: $name, represents: $represents, subTeams: $subTeams, ownSubTeam: $ownSubTeam, sport: $sport, staff: $staff, players: $players)';
}


}

/// @nodoc
abstract mixin class _$TeamDraftCopyWith<$Res> implements $TeamDraftCopyWith<$Res> {
  factory _$TeamDraftCopyWith(_TeamDraft value, $Res Function(_TeamDraft) _then) = __$TeamDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, String represents, Set<String> subTeams, String? ownSubTeam, ClubSport sport, List<String> staff, Set<String> players
});




}
/// @nodoc
class __$TeamDraftCopyWithImpl<$Res>
    implements _$TeamDraftCopyWith<$Res> {
  __$TeamDraftCopyWithImpl(this._self, this._then);

  final _TeamDraft _self;
  final $Res Function(_TeamDraft) _then;

/// Create a copy of TeamDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? represents = null,Object? subTeams = null,Object? ownSubTeam = freezed,Object? sport = null,Object? staff = null,Object? players = null,}) {
  return _then(_TeamDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,represents: null == represents ? _self.represents : represents // ignore: cast_nullable_to_non_nullable
as String,subTeams: null == subTeams ? _self._subTeams : subTeams // ignore: cast_nullable_to_non_nullable
as Set<String>,ownSubTeam: freezed == ownSubTeam ? _self.ownSubTeam : ownSubTeam // ignore: cast_nullable_to_non_nullable
as String?,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as ClubSport,staff: null == staff ? _self._staff : staff // ignore: cast_nullable_to_non_nullable
as List<String>,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on

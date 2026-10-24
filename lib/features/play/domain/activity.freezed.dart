// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Venue {

 String get id; String get name; String get address; String get distance;
/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueCopyWith<Venue> get copyWith => _$VenueCopyWithImpl<Venue>(this as Venue, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Venue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Venue&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.distance, _this.distance) || other.distance == _this.distance));
}


@override
int get hashCode {
  final _this = this as Venue;
  return Object.hash(runtimeType,_this.id,_this.name,_this.address,_this.distance);
}

@override
String toString() {
  final _this = this as Venue;
  return 'Venue(id: ${_this.id}, name: ${_this.name}, address: ${_this.address}, distance: ${_this.distance})';
}


}

/// @nodoc
abstract mixin class $VenueCopyWith<$Res>  {
  factory $VenueCopyWith(Venue value, $Res Function(Venue) _then) = _$VenueCopyWithImpl;
@useResult
$Res call({
 String id, String name, String address, String distance
});




}
/// @nodoc
class _$VenueCopyWithImpl<$Res>
    implements $VenueCopyWith<$Res> {
  _$VenueCopyWithImpl(this._self, this._then);

  final Venue _self;
  final $Res Function(Venue) _then;

/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = null,Object? distance = null,}) {
  return _then(Venue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Venue].
extension VenuePatterns on Venue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Venue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Venue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Venue value)  $default,){
final _that = this;
switch (_that) {
case _Venue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Venue value)?  $default,){
final _that = this;
switch (_that) {
case _Venue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String distance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Venue() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.distance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String distance)  $default,) {final _that = this;
switch (_that) {
case _Venue():
return $default(_that.id,_that.name,_that.address,_that.distance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String address,  String distance)?  $default,) {final _that = this;
switch (_that) {
case _Venue() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.distance);case _:
  return null;

}
}

}

/// @nodoc


class _Venue implements Venue {
  const _Venue({required this.id, required this.name, required this.address, this.distance = ''});
  

@override final  String id;
@override final  String name;
@override final  String address;
@override@JsonKey() final  String distance;

/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueCopyWith<_Venue> get copyWith => __$VenueCopyWithImpl<_Venue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Venue&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.distance, distance) || other.distance == distance));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,address,distance);
}

@override
String toString() {
    return 'Venue(id: $id, name: $name, address: $address, distance: $distance)';
}


}

/// @nodoc
abstract mixin class _$VenueCopyWith<$Res> implements $VenueCopyWith<$Res> {
  factory _$VenueCopyWith(_Venue value, $Res Function(_Venue) _then) = __$VenueCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String address, String distance
});




}
/// @nodoc
class __$VenueCopyWithImpl<$Res>
    implements _$VenueCopyWith<$Res> {
  __$VenueCopyWithImpl(this._self, this._then);

  final _Venue _self;
  final $Res Function(_Venue) _then;

/// Create a copy of Venue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = null,Object? distance = null,}) {
  return _then(_Venue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SocialProof {

 String get mark; int get color; int get ink; String get name; String get text; String? get playerId;
/// Create a copy of SocialProof
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialProofCopyWith<SocialProof> get copyWith => _$SocialProofCopyWithImpl<SocialProof>(this as SocialProof, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SocialProof;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialProof&&(identical(other.mark, _this.mark) || other.mark == _this.mark)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.ink, _this.ink) || other.ink == _this.ink)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId));
}


@override
int get hashCode {
  final _this = this as SocialProof;
  return Object.hash(runtimeType,_this.mark,_this.color,_this.ink,_this.name,_this.text,_this.playerId);
}

@override
String toString() {
  final _this = this as SocialProof;
  return 'SocialProof(mark: ${_this.mark}, color: ${_this.color}, ink: ${_this.ink}, name: ${_this.name}, text: ${_this.text}, playerId: ${_this.playerId})';
}


}

/// @nodoc
abstract mixin class $SocialProofCopyWith<$Res>  {
  factory $SocialProofCopyWith(SocialProof value, $Res Function(SocialProof) _then) = _$SocialProofCopyWithImpl;
@useResult
$Res call({
 String mark, int color, int ink, String name, String text, String? playerId
});




}
/// @nodoc
class _$SocialProofCopyWithImpl<$Res>
    implements $SocialProofCopyWith<$Res> {
  _$SocialProofCopyWithImpl(this._self, this._then);

  final SocialProof _self;
  final $Res Function(SocialProof) _then;

/// Create a copy of SocialProof
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mark = null,Object? color = null,Object? ink = null,Object? name = null,Object? text = null,Object? playerId = freezed,}) {
  return _then(SocialProof(
mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,playerId: freezed == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialProof].
extension SocialProofPatterns on SocialProof {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialProof value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialProof() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialProof value)  $default,){
final _that = this;
switch (_that) {
case _SocialProof():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialProof value)?  $default,){
final _that = this;
switch (_that) {
case _SocialProof() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mark,  int color,  int ink,  String name,  String text,  String? playerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialProof() when $default != null:
return $default(_that.mark,_that.color,_that.ink,_that.name,_that.text,_that.playerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mark,  int color,  int ink,  String name,  String text,  String? playerId)  $default,) {final _that = this;
switch (_that) {
case _SocialProof():
return $default(_that.mark,_that.color,_that.ink,_that.name,_that.text,_that.playerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mark,  int color,  int ink,  String name,  String text,  String? playerId)?  $default,) {final _that = this;
switch (_that) {
case _SocialProof() when $default != null:
return $default(_that.mark,_that.color,_that.ink,_that.name,_that.text,_that.playerId);case _:
  return null;

}
}

}

/// @nodoc


class _SocialProof implements SocialProof {
  const _SocialProof({required this.mark, required this.color, this.ink = 0xFFFFFFFF, required this.name, required this.text, this.playerId});
  

@override final  String mark;
@override final  int color;
@override@JsonKey() final  int ink;
@override final  String name;
@override final  String text;
@override final  String? playerId;

/// Create a copy of SocialProof
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialProofCopyWith<_SocialProof> get copyWith => __$SocialProofCopyWithImpl<_SocialProof>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialProof&&(identical(other.mark, mark) || other.mark == mark)&&(identical(other.color, color) || other.color == color)&&(identical(other.ink, ink) || other.ink == ink)&&(identical(other.name, name) || other.name == name)&&(identical(other.text, text) || other.text == text)&&(identical(other.playerId, playerId) || other.playerId == playerId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mark,color,ink,name,text,playerId);
}

@override
String toString() {
    return 'SocialProof(mark: $mark, color: $color, ink: $ink, name: $name, text: $text, playerId: $playerId)';
}


}

/// @nodoc
abstract mixin class _$SocialProofCopyWith<$Res> implements $SocialProofCopyWith<$Res> {
  factory _$SocialProofCopyWith(_SocialProof value, $Res Function(_SocialProof) _then) = __$SocialProofCopyWithImpl;
@override @useResult
$Res call({
 String mark, int color, int ink, String name, String text, String? playerId
});




}
/// @nodoc
class __$SocialProofCopyWithImpl<$Res>
    implements _$SocialProofCopyWith<$Res> {
  __$SocialProofCopyWithImpl(this._self, this._then);

  final _SocialProof _self;
  final $Res Function(_SocialProof) _then;

/// Create a copy of SocialProof
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mark = null,Object? color = null,Object? ink = null,Object? name = null,Object? text = null,Object? playerId = freezed,}) {
  return _then(_SocialProof(
mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,playerId: freezed == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Activity {

 String get id; ActivityKind get kind; String get title; String? get description; List<Sport> get sports; GameType? get gameType; ActivityFormat get format; double? get levelMin; double? get levelMax; DateTime get startsAt; DateTime get endsAt; Venue get venue; String? get court; int get capacity; int get spotsTaken; int get waitlistCount; int get feeCents; bool get allowGuests; bool get approvalRequired; DateTime? get registrationClosesAt; PlayerSummary get host; int get hostMeetCount; MyStatus get myStatus; int get myWaitlistPosition; bool get iAmHost;/// The organizer holds a spot too, rather than organizing only.
 bool get hostPlaying; List<PlayerSummary> get going;/// Set when a club runs this session.
 String? get clubId;/// Ranked sessions count toward ratings and leaderboards.
 bool get ranked; int get men; int get women;/// "Every Tue and Fri".
 String? get recurrence;/// The line under the date ("Men's doubles final on Court 1 now").
 String? get subtitle;/// Tournaments and events carry a cover: a colour and a title on it.
 String? get coverTitle; int get coverColor; int get coverInk;/// "Regional" on tournament cards.
 String? get tier;/// Events streaming now, and events also shown online.
 bool get live; bool get online; int get watching;/// "All ages" on event cards.
 String? get audience; SocialProof? get proof;/// On a free Meet, players pay the S\$2 platform fee themselves.
 bool get playersPayFee; bool get levelAsNumbers; int get minPlayers;/// A tournament's events, by key (MS, WS, MD, WD, XD).
 List<String> get divisionKeys;/// The event showing this tournament, or the tournament an event shows.
 String? get linkedId;
/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityCopyWith<Activity> get copyWith => _$ActivityCopyWithImpl<Activity>(this as Activity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Activity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Activity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.sports, _this.sports)&&(identical(other.gameType, _this.gameType) || other.gameType == _this.gameType)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.levelMin, _this.levelMin) || other.levelMin == _this.levelMin)&&(identical(other.levelMax, _this.levelMax) || other.levelMax == _this.levelMax)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.endsAt, _this.endsAt) || other.endsAt == _this.endsAt)&&(identical(other.venue, _this.venue) || other.venue == _this.venue)&&(identical(other.court, _this.court) || other.court == _this.court)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.spotsTaken, _this.spotsTaken) || other.spotsTaken == _this.spotsTaken)&&(identical(other.waitlistCount, _this.waitlistCount) || other.waitlistCount == _this.waitlistCount)&&(identical(other.feeCents, _this.feeCents) || other.feeCents == _this.feeCents)&&(identical(other.allowGuests, _this.allowGuests) || other.allowGuests == _this.allowGuests)&&(identical(other.approvalRequired, _this.approvalRequired) || other.approvalRequired == _this.approvalRequired)&&(identical(other.registrationClosesAt, _this.registrationClosesAt) || other.registrationClosesAt == _this.registrationClosesAt)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.hostMeetCount, _this.hostMeetCount) || other.hostMeetCount == _this.hostMeetCount)&&(identical(other.myStatus, _this.myStatus) || other.myStatus == _this.myStatus)&&(identical(other.myWaitlistPosition, _this.myWaitlistPosition) || other.myWaitlistPosition == _this.myWaitlistPosition)&&(identical(other.iAmHost, _this.iAmHost) || other.iAmHost == _this.iAmHost)&&(identical(other.hostPlaying, _this.hostPlaying) || other.hostPlaying == _this.hostPlaying)&&const DeepCollectionEquality().equals(other.going, _this.going)&&(identical(other.clubId, _this.clubId) || other.clubId == _this.clubId)&&(identical(other.ranked, _this.ranked) || other.ranked == _this.ranked)&&(identical(other.men, _this.men) || other.men == _this.men)&&(identical(other.women, _this.women) || other.women == _this.women)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.coverTitle, _this.coverTitle) || other.coverTitle == _this.coverTitle)&&(identical(other.coverColor, _this.coverColor) || other.coverColor == _this.coverColor)&&(identical(other.coverInk, _this.coverInk) || other.coverInk == _this.coverInk)&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&(identical(other.live, _this.live) || other.live == _this.live)&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.watching, _this.watching) || other.watching == _this.watching)&&(identical(other.audience, _this.audience) || other.audience == _this.audience)&&(identical(other.proof, _this.proof) || other.proof == _this.proof)&&(identical(other.playersPayFee, _this.playersPayFee) || other.playersPayFee == _this.playersPayFee)&&(identical(other.levelAsNumbers, _this.levelAsNumbers) || other.levelAsNumbers == _this.levelAsNumbers)&&(identical(other.minPlayers, _this.minPlayers) || other.minPlayers == _this.minPlayers)&&const DeepCollectionEquality().equals(other.divisionKeys, _this.divisionKeys)&&(identical(other.linkedId, _this.linkedId) || other.linkedId == _this.linkedId));
}


@override
int get hashCode {
  final _this = this as Activity;
  return Object.hashAll([runtimeType,_this.id,_this.kind,_this.title,_this.description,const DeepCollectionEquality().hash(_this.sports),_this.gameType,_this.format,_this.levelMin,_this.levelMax,_this.startsAt,_this.endsAt,_this.venue,_this.court,_this.capacity,_this.spotsTaken,_this.waitlistCount,_this.feeCents,_this.allowGuests,_this.approvalRequired,_this.registrationClosesAt,_this.host,_this.hostMeetCount,_this.myStatus,_this.myWaitlistPosition,_this.iAmHost,_this.hostPlaying,const DeepCollectionEquality().hash(_this.going),_this.clubId,_this.ranked,_this.men,_this.women,_this.recurrence,_this.subtitle,_this.coverTitle,_this.coverColor,_this.coverInk,_this.tier,_this.live,_this.online,_this.watching,_this.audience,_this.proof,_this.playersPayFee,_this.levelAsNumbers,_this.minPlayers,const DeepCollectionEquality().hash(_this.divisionKeys),_this.linkedId]);
}

@override
String toString() {
  final _this = this as Activity;
  return 'Activity(id: ${_this.id}, kind: ${_this.kind}, title: ${_this.title}, description: ${_this.description}, sports: ${_this.sports}, gameType: ${_this.gameType}, format: ${_this.format}, levelMin: ${_this.levelMin}, levelMax: ${_this.levelMax}, startsAt: ${_this.startsAt}, endsAt: ${_this.endsAt}, venue: ${_this.venue}, court: ${_this.court}, capacity: ${_this.capacity}, spotsTaken: ${_this.spotsTaken}, waitlistCount: ${_this.waitlistCount}, feeCents: ${_this.feeCents}, allowGuests: ${_this.allowGuests}, approvalRequired: ${_this.approvalRequired}, registrationClosesAt: ${_this.registrationClosesAt}, host: ${_this.host}, hostMeetCount: ${_this.hostMeetCount}, myStatus: ${_this.myStatus}, myWaitlistPosition: ${_this.myWaitlistPosition}, iAmHost: ${_this.iAmHost}, hostPlaying: ${_this.hostPlaying}, going: ${_this.going}, clubId: ${_this.clubId}, ranked: ${_this.ranked}, men: ${_this.men}, women: ${_this.women}, recurrence: ${_this.recurrence}, subtitle: ${_this.subtitle}, coverTitle: ${_this.coverTitle}, coverColor: ${_this.coverColor}, coverInk: ${_this.coverInk}, tier: ${_this.tier}, live: ${_this.live}, online: ${_this.online}, watching: ${_this.watching}, audience: ${_this.audience}, proof: ${_this.proof}, playersPayFee: ${_this.playersPayFee}, levelAsNumbers: ${_this.levelAsNumbers}, minPlayers: ${_this.minPlayers}, divisionKeys: ${_this.divisionKeys}, linkedId: ${_this.linkedId})';
}


}

/// @nodoc
abstract mixin class $ActivityCopyWith<$Res>  {
  factory $ActivityCopyWith(Activity value, $Res Function(Activity) _then) = _$ActivityCopyWithImpl;
@useResult
$Res call({
 String id, ActivityKind kind, String title, String? description, List<Sport> sports, GameType? gameType, ActivityFormat format, double? levelMin, double? levelMax, DateTime startsAt, DateTime endsAt, Venue venue, String? court, int capacity, int spotsTaken, int waitlistCount, int feeCents, bool allowGuests, bool approvalRequired, DateTime? registrationClosesAt, PlayerSummary host, int hostMeetCount, MyStatus myStatus, int myWaitlistPosition, bool iAmHost, bool hostPlaying, List<PlayerSummary> going, String? clubId, bool ranked, int men, int women, String? recurrence, String? subtitle, String? coverTitle, int coverColor, int coverInk, String? tier, bool live, bool online, int watching, String? audience, SocialProof? proof, bool playersPayFee, bool levelAsNumbers, int minPlayers, List<String> divisionKeys, String? linkedId
});


$VenueCopyWith<$Res> get venue;$PlayerSummaryCopyWith<$Res> get host;$SocialProofCopyWith<$Res>? get proof;

}
/// @nodoc
class _$ActivityCopyWithImpl<$Res>
    implements $ActivityCopyWith<$Res> {
  _$ActivityCopyWithImpl(this._self, this._then);

  final Activity _self;
  final $Res Function(Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? description = freezed,Object? sports = null,Object? gameType = freezed,Object? format = null,Object? levelMin = freezed,Object? levelMax = freezed,Object? startsAt = null,Object? endsAt = null,Object? venue = null,Object? court = freezed,Object? capacity = null,Object? spotsTaken = null,Object? waitlistCount = null,Object? feeCents = null,Object? allowGuests = null,Object? approvalRequired = null,Object? registrationClosesAt = freezed,Object? host = null,Object? hostMeetCount = null,Object? myStatus = null,Object? myWaitlistPosition = null,Object? iAmHost = null,Object? hostPlaying = null,Object? going = null,Object? clubId = freezed,Object? ranked = null,Object? men = null,Object? women = null,Object? recurrence = freezed,Object? subtitle = freezed,Object? coverTitle = freezed,Object? coverColor = null,Object? coverInk = null,Object? tier = freezed,Object? live = null,Object? online = null,Object? watching = null,Object? audience = freezed,Object? proof = freezed,Object? playersPayFee = null,Object? levelAsNumbers = null,Object? minPlayers = null,Object? divisionKeys = null,Object? linkedId = freezed,}) {
  return _then(Activity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self.sports : sports // ignore: cast_nullable_to_non_nullable
as List<Sport>,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ActivityFormat,levelMin: freezed == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double?,levelMax: freezed == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double?,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as Venue,court: freezed == court ? _self.court : court // ignore: cast_nullable_to_non_nullable
as String?,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,spotsTaken: null == spotsTaken ? _self.spotsTaken : spotsTaken // ignore: cast_nullable_to_non_nullable
as int,waitlistCount: null == waitlistCount ? _self.waitlistCount : waitlistCount // ignore: cast_nullable_to_non_nullable
as int,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,allowGuests: null == allowGuests ? _self.allowGuests : allowGuests // ignore: cast_nullable_to_non_nullable
as bool,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,registrationClosesAt: freezed == registrationClosesAt ? _self.registrationClosesAt : registrationClosesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PlayerSummary,hostMeetCount: null == hostMeetCount ? _self.hostMeetCount : hostMeetCount // ignore: cast_nullable_to_non_nullable
as int,myStatus: null == myStatus ? _self.myStatus : myStatus // ignore: cast_nullable_to_non_nullable
as MyStatus,myWaitlistPosition: null == myWaitlistPosition ? _self.myWaitlistPosition : myWaitlistPosition // ignore: cast_nullable_to_non_nullable
as int,iAmHost: null == iAmHost ? _self.iAmHost : iAmHost // ignore: cast_nullable_to_non_nullable
as bool,hostPlaying: null == hostPlaying ? _self.hostPlaying : hostPlaying // ignore: cast_nullable_to_non_nullable
as bool,going: null == going ? _self.going : going // ignore: cast_nullable_to_non_nullable
as List<PlayerSummary>,clubId: freezed == clubId ? _self.clubId : clubId // ignore: cast_nullable_to_non_nullable
as String?,ranked: null == ranked ? _self.ranked : ranked // ignore: cast_nullable_to_non_nullable
as bool,men: null == men ? _self.men : men // ignore: cast_nullable_to_non_nullable
as int,women: null == women ? _self.women : women // ignore: cast_nullable_to_non_nullable
as int,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as String?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverTitle: freezed == coverTitle ? _self.coverTitle : coverTitle // ignore: cast_nullable_to_non_nullable
as String?,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,coverInk: null == coverInk ? _self.coverInk : coverInk // ignore: cast_nullable_to_non_nullable
as int,tier: freezed == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String?,live: null == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as bool,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,watching: null == watching ? _self.watching : watching // ignore: cast_nullable_to_non_nullable
as int,audience: freezed == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as String?,proof: freezed == proof ? _self.proof : proof // ignore: cast_nullable_to_non_nullable
as SocialProof?,playersPayFee: null == playersPayFee ? _self.playersPayFee : playersPayFee // ignore: cast_nullable_to_non_nullable
as bool,levelAsNumbers: null == levelAsNumbers ? _self.levelAsNumbers : levelAsNumbers // ignore: cast_nullable_to_non_nullable
as bool,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,divisionKeys: null == divisionKeys ? _self.divisionKeys : divisionKeys // ignore: cast_nullable_to_non_nullable
as List<String>,linkedId: freezed == linkedId ? _self.linkedId : linkedId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueCopyWith<$Res> get venue {
  
  return $VenueCopyWith<$Res>(_self.venue, (value) {
    return _then(_self.copyWith(venue: value));
  });
}/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get host {
  
  return $PlayerSummaryCopyWith<$Res>(_self.host, (value) {
    return _then(_self.copyWith(host: value));
  });
}/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocialProofCopyWith<$Res>? get proof {
    if (_self.proof == null) {
    return null;
  }

  return $SocialProofCopyWith<$Res>(_self.proof!, (value) {
    return _then(_self.copyWith(proof: value));
  });
}
}


/// Adds pattern-matching-related methods to [Activity].
extension ActivityPatterns on Activity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Activity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Activity value)  $default,){
final _that = this;
switch (_that) {
case _Activity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Activity value)?  $default,){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ActivityKind kind,  String title,  String? description,  List<Sport> sports,  GameType? gameType,  ActivityFormat format,  double? levelMin,  double? levelMax,  DateTime startsAt,  DateTime endsAt,  Venue venue,  String? court,  int capacity,  int spotsTaken,  int waitlistCount,  int feeCents,  bool allowGuests,  bool approvalRequired,  DateTime? registrationClosesAt,  PlayerSummary host,  int hostMeetCount,  MyStatus myStatus,  int myWaitlistPosition,  bool iAmHost,  bool hostPlaying,  List<PlayerSummary> going,  String? clubId,  bool ranked,  int men,  int women,  String? recurrence,  String? subtitle,  String? coverTitle,  int coverColor,  int coverInk,  String? tier,  bool live,  bool online,  int watching,  String? audience,  SocialProof? proof,  bool playersPayFee,  bool levelAsNumbers,  int minPlayers,  List<String> divisionKeys,  String? linkedId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.description,_that.sports,_that.gameType,_that.format,_that.levelMin,_that.levelMax,_that.startsAt,_that.endsAt,_that.venue,_that.court,_that.capacity,_that.spotsTaken,_that.waitlistCount,_that.feeCents,_that.allowGuests,_that.approvalRequired,_that.registrationClosesAt,_that.host,_that.hostMeetCount,_that.myStatus,_that.myWaitlistPosition,_that.iAmHost,_that.hostPlaying,_that.going,_that.clubId,_that.ranked,_that.men,_that.women,_that.recurrence,_that.subtitle,_that.coverTitle,_that.coverColor,_that.coverInk,_that.tier,_that.live,_that.online,_that.watching,_that.audience,_that.proof,_that.playersPayFee,_that.levelAsNumbers,_that.minPlayers,_that.divisionKeys,_that.linkedId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ActivityKind kind,  String title,  String? description,  List<Sport> sports,  GameType? gameType,  ActivityFormat format,  double? levelMin,  double? levelMax,  DateTime startsAt,  DateTime endsAt,  Venue venue,  String? court,  int capacity,  int spotsTaken,  int waitlistCount,  int feeCents,  bool allowGuests,  bool approvalRequired,  DateTime? registrationClosesAt,  PlayerSummary host,  int hostMeetCount,  MyStatus myStatus,  int myWaitlistPosition,  bool iAmHost,  bool hostPlaying,  List<PlayerSummary> going,  String? clubId,  bool ranked,  int men,  int women,  String? recurrence,  String? subtitle,  String? coverTitle,  int coverColor,  int coverInk,  String? tier,  bool live,  bool online,  int watching,  String? audience,  SocialProof? proof,  bool playersPayFee,  bool levelAsNumbers,  int minPlayers,  List<String> divisionKeys,  String? linkedId)  $default,) {final _that = this;
switch (_that) {
case _Activity():
return $default(_that.id,_that.kind,_that.title,_that.description,_that.sports,_that.gameType,_that.format,_that.levelMin,_that.levelMax,_that.startsAt,_that.endsAt,_that.venue,_that.court,_that.capacity,_that.spotsTaken,_that.waitlistCount,_that.feeCents,_that.allowGuests,_that.approvalRequired,_that.registrationClosesAt,_that.host,_that.hostMeetCount,_that.myStatus,_that.myWaitlistPosition,_that.iAmHost,_that.hostPlaying,_that.going,_that.clubId,_that.ranked,_that.men,_that.women,_that.recurrence,_that.subtitle,_that.coverTitle,_that.coverColor,_that.coverInk,_that.tier,_that.live,_that.online,_that.watching,_that.audience,_that.proof,_that.playersPayFee,_that.levelAsNumbers,_that.minPlayers,_that.divisionKeys,_that.linkedId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ActivityKind kind,  String title,  String? description,  List<Sport> sports,  GameType? gameType,  ActivityFormat format,  double? levelMin,  double? levelMax,  DateTime startsAt,  DateTime endsAt,  Venue venue,  String? court,  int capacity,  int spotsTaken,  int waitlistCount,  int feeCents,  bool allowGuests,  bool approvalRequired,  DateTime? registrationClosesAt,  PlayerSummary host,  int hostMeetCount,  MyStatus myStatus,  int myWaitlistPosition,  bool iAmHost,  bool hostPlaying,  List<PlayerSummary> going,  String? clubId,  bool ranked,  int men,  int women,  String? recurrence,  String? subtitle,  String? coverTitle,  int coverColor,  int coverInk,  String? tier,  bool live,  bool online,  int watching,  String? audience,  SocialProof? proof,  bool playersPayFee,  bool levelAsNumbers,  int minPlayers,  List<String> divisionKeys,  String? linkedId)?  $default,) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.description,_that.sports,_that.gameType,_that.format,_that.levelMin,_that.levelMax,_that.startsAt,_that.endsAt,_that.venue,_that.court,_that.capacity,_that.spotsTaken,_that.waitlistCount,_that.feeCents,_that.allowGuests,_that.approvalRequired,_that.registrationClosesAt,_that.host,_that.hostMeetCount,_that.myStatus,_that.myWaitlistPosition,_that.iAmHost,_that.hostPlaying,_that.going,_that.clubId,_that.ranked,_that.men,_that.women,_that.recurrence,_that.subtitle,_that.coverTitle,_that.coverColor,_that.coverInk,_that.tier,_that.live,_that.online,_that.watching,_that.audience,_that.proof,_that.playersPayFee,_that.levelAsNumbers,_that.minPlayers,_that.divisionKeys,_that.linkedId);case _:
  return null;

}
}

}

/// @nodoc


class _Activity extends Activity {
  const _Activity({required this.id, required this.kind, required this.title, this.description, required  List<Sport> sports, this.gameType, required this.format, this.levelMin, this.levelMax, required this.startsAt, required this.endsAt, required this.venue, this.court, required this.capacity, this.spotsTaken = 0, this.waitlistCount = 0, this.feeCents = 0, this.allowGuests = false, this.approvalRequired = false, this.registrationClosesAt, required this.host, this.hostMeetCount = 0, this.myStatus = MyStatus.none, this.myWaitlistPosition = 0, this.iAmHost = false, this.hostPlaying = true,  List<PlayerSummary> going = const [], this.clubId, this.ranked = false, this.men = 0, this.women = 0, this.recurrence, this.subtitle, this.coverTitle, this.coverColor = 0xFF16181B, this.coverInk = 0xFFFFFFFF, this.tier, this.live = false, this.online = false, this.watching = 0, this.audience, this.proof, this.playersPayFee = false, this.levelAsNumbers = false, this.minPlayers = 0,  List<String> divisionKeys = const [], this.linkedId}): _sports = sports,_going = going,_divisionKeys = divisionKeys,super._();
  

@override final  String id;
@override final  ActivityKind kind;
@override final  String title;
@override final  String? description;
 final  List<Sport> _sports;
@override List<Sport> get sports {
  if (_sports is EqualUnmodifiableListView) return _sports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sports);
}

@override final  GameType? gameType;
@override final  ActivityFormat format;
@override final  double? levelMin;
@override final  double? levelMax;
@override final  DateTime startsAt;
@override final  DateTime endsAt;
@override final  Venue venue;
@override final  String? court;
@override final  int capacity;
@override@JsonKey() final  int spotsTaken;
@override@JsonKey() final  int waitlistCount;
@override@JsonKey() final  int feeCents;
@override@JsonKey() final  bool allowGuests;
@override@JsonKey() final  bool approvalRequired;
@override final  DateTime? registrationClosesAt;
@override final  PlayerSummary host;
@override@JsonKey() final  int hostMeetCount;
@override@JsonKey() final  MyStatus myStatus;
@override@JsonKey() final  int myWaitlistPosition;
@override@JsonKey() final  bool iAmHost;
/// The organizer holds a spot too, rather than organizing only.
@override@JsonKey() final  bool hostPlaying;
 final  List<PlayerSummary> _going;
@override@JsonKey() List<PlayerSummary> get going {
  if (_going is EqualUnmodifiableListView) return _going;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_going);
}

/// Set when a club runs this session.
@override final  String? clubId;
/// Ranked sessions count toward ratings and leaderboards.
@override@JsonKey() final  bool ranked;
@override@JsonKey() final  int men;
@override@JsonKey() final  int women;
/// "Every Tue and Fri".
@override final  String? recurrence;
/// The line under the date ("Men's doubles final on Court 1 now").
@override final  String? subtitle;
/// Tournaments and events carry a cover: a colour and a title on it.
@override final  String? coverTitle;
@override@JsonKey() final  int coverColor;
@override@JsonKey() final  int coverInk;
/// "Regional" on tournament cards.
@override final  String? tier;
/// Events streaming now, and events also shown online.
@override@JsonKey() final  bool live;
@override@JsonKey() final  bool online;
@override@JsonKey() final  int watching;
/// "All ages" on event cards.
@override final  String? audience;
@override final  SocialProof? proof;
/// On a free Meet, players pay the S\$2 platform fee themselves.
@override@JsonKey() final  bool playersPayFee;
@override@JsonKey() final  bool levelAsNumbers;
@override@JsonKey() final  int minPlayers;
/// A tournament's events, by key (MS, WS, MD, WD, XD).
 final  List<String> _divisionKeys;
/// A tournament's events, by key (MS, WS, MD, WD, XD).
@override@JsonKey() List<String> get divisionKeys {
  if (_divisionKeys is EqualUnmodifiableListView) return _divisionKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_divisionKeys);
}

/// The event showing this tournament, or the tournament an event shows.
@override final  String? linkedId;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityCopyWith<_Activity> get copyWith => __$ActivityCopyWithImpl<_Activity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Activity&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.sports, _sports)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.format, format) || other.format == format)&&(identical(other.levelMin, levelMin) || other.levelMin == levelMin)&&(identical(other.levelMax, levelMax) || other.levelMax == levelMax)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.court, court) || other.court == court)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.spotsTaken, spotsTaken) || other.spotsTaken == spotsTaken)&&(identical(other.waitlistCount, waitlistCount) || other.waitlistCount == waitlistCount)&&(identical(other.feeCents, feeCents) || other.feeCents == feeCents)&&(identical(other.allowGuests, allowGuests) || other.allowGuests == allowGuests)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.registrationClosesAt, registrationClosesAt) || other.registrationClosesAt == registrationClosesAt)&&(identical(other.host, host) || other.host == host)&&(identical(other.hostMeetCount, hostMeetCount) || other.hostMeetCount == hostMeetCount)&&(identical(other.myStatus, myStatus) || other.myStatus == myStatus)&&(identical(other.myWaitlistPosition, myWaitlistPosition) || other.myWaitlistPosition == myWaitlistPosition)&&(identical(other.iAmHost, iAmHost) || other.iAmHost == iAmHost)&&(identical(other.hostPlaying, hostPlaying) || other.hostPlaying == hostPlaying)&&const DeepCollectionEquality().equals(other.going, _going)&&(identical(other.clubId, clubId) || other.clubId == clubId)&&(identical(other.ranked, ranked) || other.ranked == ranked)&&(identical(other.men, men) || other.men == men)&&(identical(other.women, women) || other.women == women)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverTitle, coverTitle) || other.coverTitle == coverTitle)&&(identical(other.coverColor, coverColor) || other.coverColor == coverColor)&&(identical(other.coverInk, coverInk) || other.coverInk == coverInk)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.live, live) || other.live == live)&&(identical(other.online, online) || other.online == online)&&(identical(other.watching, watching) || other.watching == watching)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.proof, proof) || other.proof == proof)&&(identical(other.playersPayFee, playersPayFee) || other.playersPayFee == playersPayFee)&&(identical(other.levelAsNumbers, levelAsNumbers) || other.levelAsNumbers == levelAsNumbers)&&(identical(other.minPlayers, minPlayers) || other.minPlayers == minPlayers)&&const DeepCollectionEquality().equals(other.divisionKeys, _divisionKeys)&&(identical(other.linkedId, linkedId) || other.linkedId == linkedId));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,kind,title,description,const DeepCollectionEquality().hash(_sports),gameType,format,levelMin,levelMax,startsAt,endsAt,venue,court,capacity,spotsTaken,waitlistCount,feeCents,allowGuests,approvalRequired,registrationClosesAt,host,hostMeetCount,myStatus,myWaitlistPosition,iAmHost,hostPlaying,const DeepCollectionEquality().hash(_going),clubId,ranked,men,women,recurrence,subtitle,coverTitle,coverColor,coverInk,tier,live,online,watching,audience,proof,playersPayFee,levelAsNumbers,minPlayers,const DeepCollectionEquality().hash(_divisionKeys),linkedId]);
}

@override
String toString() {
    return 'Activity(id: $id, kind: $kind, title: $title, description: $description, sports: $sports, gameType: $gameType, format: $format, levelMin: $levelMin, levelMax: $levelMax, startsAt: $startsAt, endsAt: $endsAt, venue: $venue, court: $court, capacity: $capacity, spotsTaken: $spotsTaken, waitlistCount: $waitlistCount, feeCents: $feeCents, allowGuests: $allowGuests, approvalRequired: $approvalRequired, registrationClosesAt: $registrationClosesAt, host: $host, hostMeetCount: $hostMeetCount, myStatus: $myStatus, myWaitlistPosition: $myWaitlistPosition, iAmHost: $iAmHost, hostPlaying: $hostPlaying, going: $going, clubId: $clubId, ranked: $ranked, men: $men, women: $women, recurrence: $recurrence, subtitle: $subtitle, coverTitle: $coverTitle, coverColor: $coverColor, coverInk: $coverInk, tier: $tier, live: $live, online: $online, watching: $watching, audience: $audience, proof: $proof, playersPayFee: $playersPayFee, levelAsNumbers: $levelAsNumbers, minPlayers: $minPlayers, divisionKeys: $divisionKeys, linkedId: $linkedId)';
}


}

/// @nodoc
abstract mixin class _$ActivityCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory _$ActivityCopyWith(_Activity value, $Res Function(_Activity) _then) = __$ActivityCopyWithImpl;
@override @useResult
$Res call({
 String id, ActivityKind kind, String title, String? description, List<Sport> sports, GameType? gameType, ActivityFormat format, double? levelMin, double? levelMax, DateTime startsAt, DateTime endsAt, Venue venue, String? court, int capacity, int spotsTaken, int waitlistCount, int feeCents, bool allowGuests, bool approvalRequired, DateTime? registrationClosesAt, PlayerSummary host, int hostMeetCount, MyStatus myStatus, int myWaitlistPosition, bool iAmHost, bool hostPlaying, List<PlayerSummary> going, String? clubId, bool ranked, int men, int women, String? recurrence, String? subtitle, String? coverTitle, int coverColor, int coverInk, String? tier, bool live, bool online, int watching, String? audience, SocialProof? proof, bool playersPayFee, bool levelAsNumbers, int minPlayers, List<String> divisionKeys, String? linkedId
});


@override $VenueCopyWith<$Res> get venue;@override $PlayerSummaryCopyWith<$Res> get host;@override $SocialProofCopyWith<$Res>? get proof;

}
/// @nodoc
class __$ActivityCopyWithImpl<$Res>
    implements _$ActivityCopyWith<$Res> {
  __$ActivityCopyWithImpl(this._self, this._then);

  final _Activity _self;
  final $Res Function(_Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? description = freezed,Object? sports = null,Object? gameType = freezed,Object? format = null,Object? levelMin = freezed,Object? levelMax = freezed,Object? startsAt = null,Object? endsAt = null,Object? venue = null,Object? court = freezed,Object? capacity = null,Object? spotsTaken = null,Object? waitlistCount = null,Object? feeCents = null,Object? allowGuests = null,Object? approvalRequired = null,Object? registrationClosesAt = freezed,Object? host = null,Object? hostMeetCount = null,Object? myStatus = null,Object? myWaitlistPosition = null,Object? iAmHost = null,Object? hostPlaying = null,Object? going = null,Object? clubId = freezed,Object? ranked = null,Object? men = null,Object? women = null,Object? recurrence = freezed,Object? subtitle = freezed,Object? coverTitle = freezed,Object? coverColor = null,Object? coverInk = null,Object? tier = freezed,Object? live = null,Object? online = null,Object? watching = null,Object? audience = freezed,Object? proof = freezed,Object? playersPayFee = null,Object? levelAsNumbers = null,Object? minPlayers = null,Object? divisionKeys = null,Object? linkedId = freezed,}) {
  return _then(_Activity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self._sports : sports // ignore: cast_nullable_to_non_nullable
as List<Sport>,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ActivityFormat,levelMin: freezed == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double?,levelMax: freezed == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double?,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as Venue,court: freezed == court ? _self.court : court // ignore: cast_nullable_to_non_nullable
as String?,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,spotsTaken: null == spotsTaken ? _self.spotsTaken : spotsTaken // ignore: cast_nullable_to_non_nullable
as int,waitlistCount: null == waitlistCount ? _self.waitlistCount : waitlistCount // ignore: cast_nullable_to_non_nullable
as int,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,allowGuests: null == allowGuests ? _self.allowGuests : allowGuests // ignore: cast_nullable_to_non_nullable
as bool,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,registrationClosesAt: freezed == registrationClosesAt ? _self.registrationClosesAt : registrationClosesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PlayerSummary,hostMeetCount: null == hostMeetCount ? _self.hostMeetCount : hostMeetCount // ignore: cast_nullable_to_non_nullable
as int,myStatus: null == myStatus ? _self.myStatus : myStatus // ignore: cast_nullable_to_non_nullable
as MyStatus,myWaitlistPosition: null == myWaitlistPosition ? _self.myWaitlistPosition : myWaitlistPosition // ignore: cast_nullable_to_non_nullable
as int,iAmHost: null == iAmHost ? _self.iAmHost : iAmHost // ignore: cast_nullable_to_non_nullable
as bool,hostPlaying: null == hostPlaying ? _self.hostPlaying : hostPlaying // ignore: cast_nullable_to_non_nullable
as bool,going: null == going ? _self._going : going // ignore: cast_nullable_to_non_nullable
as List<PlayerSummary>,clubId: freezed == clubId ? _self.clubId : clubId // ignore: cast_nullable_to_non_nullable
as String?,ranked: null == ranked ? _self.ranked : ranked // ignore: cast_nullable_to_non_nullable
as bool,men: null == men ? _self.men : men // ignore: cast_nullable_to_non_nullable
as int,women: null == women ? _self.women : women // ignore: cast_nullable_to_non_nullable
as int,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as String?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,coverTitle: freezed == coverTitle ? _self.coverTitle : coverTitle // ignore: cast_nullable_to_non_nullable
as String?,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,coverInk: null == coverInk ? _self.coverInk : coverInk // ignore: cast_nullable_to_non_nullable
as int,tier: freezed == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String?,live: null == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as bool,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,watching: null == watching ? _self.watching : watching // ignore: cast_nullable_to_non_nullable
as int,audience: freezed == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as String?,proof: freezed == proof ? _self.proof : proof // ignore: cast_nullable_to_non_nullable
as SocialProof?,playersPayFee: null == playersPayFee ? _self.playersPayFee : playersPayFee // ignore: cast_nullable_to_non_nullable
as bool,levelAsNumbers: null == levelAsNumbers ? _self.levelAsNumbers : levelAsNumbers // ignore: cast_nullable_to_non_nullable
as bool,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,divisionKeys: null == divisionKeys ? _self._divisionKeys : divisionKeys // ignore: cast_nullable_to_non_nullable
as List<String>,linkedId: freezed == linkedId ? _self.linkedId : linkedId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueCopyWith<$Res> get venue {
  
  return $VenueCopyWith<$Res>(_self.venue, (value) {
    return _then(_self.copyWith(venue: value));
  });
}/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerSummaryCopyWith<$Res> get host {
  
  return $PlayerSummaryCopyWith<$Res>(_self.host, (value) {
    return _then(_self.copyWith(host: value));
  });
}/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocialProofCopyWith<$Res>? get proof {
    if (_self.proof == null) {
    return null;
  }

  return $SocialProofCopyWith<$Res>(_self.proof!, (value) {
    return _then(_self.copyWith(proof: value));
  });
}
}

/// @nodoc
mixin _$Receipt {

 String get activityId; ActivityKind get activityKind; String get receiptNo; String get activityTitle; DateTime get activityStartsAt; String get paidWith; int get feeCents; int get platformFeeCents; String get email;
/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCopyWith<Receipt> get copyWith => _$ReceiptCopyWithImpl<Receipt>(this as Receipt, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Receipt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Receipt&&(identical(other.activityId, _this.activityId) || other.activityId == _this.activityId)&&(identical(other.activityKind, _this.activityKind) || other.activityKind == _this.activityKind)&&(identical(other.receiptNo, _this.receiptNo) || other.receiptNo == _this.receiptNo)&&(identical(other.activityTitle, _this.activityTitle) || other.activityTitle == _this.activityTitle)&&(identical(other.activityStartsAt, _this.activityStartsAt) || other.activityStartsAt == _this.activityStartsAt)&&(identical(other.paidWith, _this.paidWith) || other.paidWith == _this.paidWith)&&(identical(other.feeCents, _this.feeCents) || other.feeCents == _this.feeCents)&&(identical(other.platformFeeCents, _this.platformFeeCents) || other.platformFeeCents == _this.platformFeeCents)&&(identical(other.email, _this.email) || other.email == _this.email));
}


@override
int get hashCode {
  final _this = this as Receipt;
  return Object.hash(runtimeType,_this.activityId,_this.activityKind,_this.receiptNo,_this.activityTitle,_this.activityStartsAt,_this.paidWith,_this.feeCents,_this.platformFeeCents,_this.email);
}

@override
String toString() {
  final _this = this as Receipt;
  return 'Receipt(activityId: ${_this.activityId}, activityKind: ${_this.activityKind}, receiptNo: ${_this.receiptNo}, activityTitle: ${_this.activityTitle}, activityStartsAt: ${_this.activityStartsAt}, paidWith: ${_this.paidWith}, feeCents: ${_this.feeCents}, platformFeeCents: ${_this.platformFeeCents}, email: ${_this.email})';
}


}

/// @nodoc
abstract mixin class $ReceiptCopyWith<$Res>  {
  factory $ReceiptCopyWith(Receipt value, $Res Function(Receipt) _then) = _$ReceiptCopyWithImpl;
@useResult
$Res call({
 String activityId, ActivityKind activityKind, String receiptNo, String activityTitle, DateTime activityStartsAt, String paidWith, int feeCents, int platformFeeCents, String email
});




}
/// @nodoc
class _$ReceiptCopyWithImpl<$Res>
    implements $ReceiptCopyWith<$Res> {
  _$ReceiptCopyWithImpl(this._self, this._then);

  final Receipt _self;
  final $Res Function(Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activityId = null,Object? activityKind = null,Object? receiptNo = null,Object? activityTitle = null,Object? activityStartsAt = null,Object? paidWith = null,Object? feeCents = null,Object? platformFeeCents = null,Object? email = null,}) {
  return _then(Receipt(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,activityKind: null == activityKind ? _self.activityKind : activityKind // ignore: cast_nullable_to_non_nullable
as ActivityKind,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,activityTitle: null == activityTitle ? _self.activityTitle : activityTitle // ignore: cast_nullable_to_non_nullable
as String,activityStartsAt: null == activityStartsAt ? _self.activityStartsAt : activityStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,paidWith: null == paidWith ? _self.paidWith : paidWith // ignore: cast_nullable_to_non_nullable
as String,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,platformFeeCents: null == platformFeeCents ? _self.platformFeeCents : platformFeeCents // ignore: cast_nullable_to_non_nullable
as int,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Receipt].
extension ReceiptPatterns on Receipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Receipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Receipt value)  $default,){
final _that = this;
switch (_that) {
case _Receipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Receipt value)?  $default,){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String activityId,  ActivityKind activityKind,  String receiptNo,  String activityTitle,  DateTime activityStartsAt,  String paidWith,  int feeCents,  int platformFeeCents,  String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.activityId,_that.activityKind,_that.receiptNo,_that.activityTitle,_that.activityStartsAt,_that.paidWith,_that.feeCents,_that.platformFeeCents,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String activityId,  ActivityKind activityKind,  String receiptNo,  String activityTitle,  DateTime activityStartsAt,  String paidWith,  int feeCents,  int platformFeeCents,  String email)  $default,) {final _that = this;
switch (_that) {
case _Receipt():
return $default(_that.activityId,_that.activityKind,_that.receiptNo,_that.activityTitle,_that.activityStartsAt,_that.paidWith,_that.feeCents,_that.platformFeeCents,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String activityId,  ActivityKind activityKind,  String receiptNo,  String activityTitle,  DateTime activityStartsAt,  String paidWith,  int feeCents,  int platformFeeCents,  String email)?  $default,) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.activityId,_that.activityKind,_that.receiptNo,_that.activityTitle,_that.activityStartsAt,_that.paidWith,_that.feeCents,_that.platformFeeCents,_that.email);case _:
  return null;

}
}

}

/// @nodoc


class _Receipt extends Receipt {
  const _Receipt({required this.activityId, this.activityKind = ActivityKind.meet, required this.receiptNo, required this.activityTitle, required this.activityStartsAt, required this.paidWith, required this.feeCents, required this.platformFeeCents, required this.email}): super._();
  

@override final  String activityId;
@override@JsonKey() final  ActivityKind activityKind;
@override final  String receiptNo;
@override final  String activityTitle;
@override final  DateTime activityStartsAt;
@override final  String paidWith;
@override final  int feeCents;
@override final  int platformFeeCents;
@override final  String email;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptCopyWith<_Receipt> get copyWith => __$ReceiptCopyWithImpl<_Receipt>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Receipt&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.activityKind, activityKind) || other.activityKind == activityKind)&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.activityTitle, activityTitle) || other.activityTitle == activityTitle)&&(identical(other.activityStartsAt, activityStartsAt) || other.activityStartsAt == activityStartsAt)&&(identical(other.paidWith, paidWith) || other.paidWith == paidWith)&&(identical(other.feeCents, feeCents) || other.feeCents == feeCents)&&(identical(other.platformFeeCents, platformFeeCents) || other.platformFeeCents == platformFeeCents)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activityId,activityKind,receiptNo,activityTitle,activityStartsAt,paidWith,feeCents,platformFeeCents,email);
}

@override
String toString() {
    return 'Receipt(activityId: $activityId, activityKind: $activityKind, receiptNo: $receiptNo, activityTitle: $activityTitle, activityStartsAt: $activityStartsAt, paidWith: $paidWith, feeCents: $feeCents, platformFeeCents: $platformFeeCents, email: $email)';
}


}

/// @nodoc
abstract mixin class _$ReceiptCopyWith<$Res> implements $ReceiptCopyWith<$Res> {
  factory _$ReceiptCopyWith(_Receipt value, $Res Function(_Receipt) _then) = __$ReceiptCopyWithImpl;
@override @useResult
$Res call({
 String activityId, ActivityKind activityKind, String receiptNo, String activityTitle, DateTime activityStartsAt, String paidWith, int feeCents, int platformFeeCents, String email
});




}
/// @nodoc
class __$ReceiptCopyWithImpl<$Res>
    implements _$ReceiptCopyWith<$Res> {
  __$ReceiptCopyWithImpl(this._self, this._then);

  final _Receipt _self;
  final $Res Function(_Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activityId = null,Object? activityKind = null,Object? receiptNo = null,Object? activityTitle = null,Object? activityStartsAt = null,Object? paidWith = null,Object? feeCents = null,Object? platformFeeCents = null,Object? email = null,}) {
  return _then(_Receipt(
activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,activityKind: null == activityKind ? _self.activityKind : activityKind // ignore: cast_nullable_to_non_nullable
as ActivityKind,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,activityTitle: null == activityTitle ? _self.activityTitle : activityTitle // ignore: cast_nullable_to_non_nullable
as String,activityStartsAt: null == activityStartsAt ? _self.activityStartsAt : activityStartsAt // ignore: cast_nullable_to_non_nullable
as DateTime,paidWith: null == paidWith ? _self.paidWith : paidWith // ignore: cast_nullable_to_non_nullable
as String,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,platformFeeCents: null == platformFeeCents ? _self.platformFeeCents : platformFeeCents // ignore: cast_nullable_to_non_nullable
as int,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PlayFilters {

 String get when; GameType? get gameType; double get levelMin; double get levelMax; String get fee; String get distance; ActivityFormat? get format; String get registration;
/// Create a copy of PlayFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayFiltersCopyWith<PlayFilters> get copyWith => _$PlayFiltersCopyWithImpl<PlayFilters>(this as PlayFilters, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayFilters;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayFilters&&(identical(other.when, _this.when) || other.when == _this.when)&&(identical(other.gameType, _this.gameType) || other.gameType == _this.gameType)&&(identical(other.levelMin, _this.levelMin) || other.levelMin == _this.levelMin)&&(identical(other.levelMax, _this.levelMax) || other.levelMax == _this.levelMax)&&(identical(other.fee, _this.fee) || other.fee == _this.fee)&&(identical(other.distance, _this.distance) || other.distance == _this.distance)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.registration, _this.registration) || other.registration == _this.registration));
}


@override
int get hashCode {
  final _this = this as PlayFilters;
  return Object.hash(runtimeType,_this.when,_this.gameType,_this.levelMin,_this.levelMax,_this.fee,_this.distance,_this.format,_this.registration);
}

@override
String toString() {
  final _this = this as PlayFilters;
  return 'PlayFilters(when: ${_this.when}, gameType: ${_this.gameType}, levelMin: ${_this.levelMin}, levelMax: ${_this.levelMax}, fee: ${_this.fee}, distance: ${_this.distance}, format: ${_this.format}, registration: ${_this.registration})';
}


}

/// @nodoc
abstract mixin class $PlayFiltersCopyWith<$Res>  {
  factory $PlayFiltersCopyWith(PlayFilters value, $Res Function(PlayFilters) _then) = _$PlayFiltersCopyWithImpl;
@useResult
$Res call({
 String when, GameType? gameType, double levelMin, double levelMax, String fee, String distance, ActivityFormat? format, String registration
});




}
/// @nodoc
class _$PlayFiltersCopyWithImpl<$Res>
    implements $PlayFiltersCopyWith<$Res> {
  _$PlayFiltersCopyWithImpl(this._self, this._then);

  final PlayFilters _self;
  final $Res Function(PlayFilters) _then;

/// Create a copy of PlayFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? when = null,Object? gameType = freezed,Object? levelMin = null,Object? levelMax = null,Object? fee = null,Object? distance = null,Object? format = freezed,Object? registration = null,}) {
  return _then(PlayFilters(
when: null == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as String,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,levelMin: null == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double,levelMax: null == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ActivityFormat?,registration: null == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayFilters].
extension PlayFiltersPatterns on PlayFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayFilters value)  $default,){
final _that = this;
switch (_that) {
case _PlayFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayFilters value)?  $default,){
final _that = this;
switch (_that) {
case _PlayFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String when,  GameType? gameType,  double levelMin,  double levelMax,  String fee,  String distance,  ActivityFormat? format,  String registration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayFilters() when $default != null:
return $default(_that.when,_that.gameType,_that.levelMin,_that.levelMax,_that.fee,_that.distance,_that.format,_that.registration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String when,  GameType? gameType,  double levelMin,  double levelMax,  String fee,  String distance,  ActivityFormat? format,  String registration)  $default,) {final _that = this;
switch (_that) {
case _PlayFilters():
return $default(_that.when,_that.gameType,_that.levelMin,_that.levelMax,_that.fee,_that.distance,_that.format,_that.registration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String when,  GameType? gameType,  double levelMin,  double levelMax,  String fee,  String distance,  ActivityFormat? format,  String registration)?  $default,) {final _that = this;
switch (_that) {
case _PlayFilters() when $default != null:
return $default(_that.when,_that.gameType,_that.levelMin,_that.levelMax,_that.fee,_that.distance,_that.format,_that.registration);case _:
  return null;

}
}

}

/// @nodoc


class _PlayFilters implements PlayFilters {
  const _PlayFilters({this.when = 'any', this.gameType, this.levelMin = 1.0, this.levelMax = 8.0, this.fee = 'any', this.distance = 'anywhere', this.format, this.registration = 'open'});
  

@override@JsonKey() final  String when;
@override final  GameType? gameType;
@override@JsonKey() final  double levelMin;
@override@JsonKey() final  double levelMax;
@override@JsonKey() final  String fee;
@override@JsonKey() final  String distance;
@override final  ActivityFormat? format;
@override@JsonKey() final  String registration;

/// Create a copy of PlayFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayFiltersCopyWith<_PlayFilters> get copyWith => __$PlayFiltersCopyWithImpl<_PlayFilters>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayFilters&&(identical(other.when, when) || other.when == when)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.levelMin, levelMin) || other.levelMin == levelMin)&&(identical(other.levelMax, levelMax) || other.levelMax == levelMax)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.format, format) || other.format == format)&&(identical(other.registration, registration) || other.registration == registration));
}


@override
int get hashCode {
    return Object.hash(runtimeType,when,gameType,levelMin,levelMax,fee,distance,format,registration);
}

@override
String toString() {
    return 'PlayFilters(when: $when, gameType: $gameType, levelMin: $levelMin, levelMax: $levelMax, fee: $fee, distance: $distance, format: $format, registration: $registration)';
}


}

/// @nodoc
abstract mixin class _$PlayFiltersCopyWith<$Res> implements $PlayFiltersCopyWith<$Res> {
  factory _$PlayFiltersCopyWith(_PlayFilters value, $Res Function(_PlayFilters) _then) = __$PlayFiltersCopyWithImpl;
@override @useResult
$Res call({
 String when, GameType? gameType, double levelMin, double levelMax, String fee, String distance, ActivityFormat? format, String registration
});




}
/// @nodoc
class __$PlayFiltersCopyWithImpl<$Res>
    implements _$PlayFiltersCopyWith<$Res> {
  __$PlayFiltersCopyWithImpl(this._self, this._then);

  final _PlayFilters _self;
  final $Res Function(_PlayFilters) _then;

/// Create a copy of PlayFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? when = null,Object? gameType = freezed,Object? levelMin = null,Object? levelMax = null,Object? fee = null,Object? distance = null,Object? format = freezed,Object? registration = null,}) {
  return _then(_PlayFilters(
when: null == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as String,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,levelMin: null == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double,levelMax: null == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ActivityFormat?,registration: null == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PlaySportPref {

 Sport get sport; GameType? get gameType; double get levelMin; double get levelMax;
/// Create a copy of PlaySportPref
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaySportPrefCopyWith<PlaySportPref> get copyWith => _$PlaySportPrefCopyWithImpl<PlaySportPref>(this as PlaySportPref, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaySportPref;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaySportPref&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.gameType, _this.gameType) || other.gameType == _this.gameType)&&(identical(other.levelMin, _this.levelMin) || other.levelMin == _this.levelMin)&&(identical(other.levelMax, _this.levelMax) || other.levelMax == _this.levelMax));
}


@override
int get hashCode {
  final _this = this as PlaySportPref;
  return Object.hash(runtimeType,_this.sport,_this.gameType,_this.levelMin,_this.levelMax);
}

@override
String toString() {
  final _this = this as PlaySportPref;
  return 'PlaySportPref(sport: ${_this.sport}, gameType: ${_this.gameType}, levelMin: ${_this.levelMin}, levelMax: ${_this.levelMax})';
}


}

/// @nodoc
abstract mixin class $PlaySportPrefCopyWith<$Res>  {
  factory $PlaySportPrefCopyWith(PlaySportPref value, $Res Function(PlaySportPref) _then) = _$PlaySportPrefCopyWithImpl;
@useResult
$Res call({
 Sport sport, GameType? gameType, double levelMin, double levelMax
});




}
/// @nodoc
class _$PlaySportPrefCopyWithImpl<$Res>
    implements $PlaySportPrefCopyWith<$Res> {
  _$PlaySportPrefCopyWithImpl(this._self, this._then);

  final PlaySportPref _self;
  final $Res Function(PlaySportPref) _then;

/// Create a copy of PlaySportPref
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sport = null,Object? gameType = freezed,Object? levelMin = null,Object? levelMax = null,}) {
  return _then(PlaySportPref(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,levelMin: null == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double,levelMax: null == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaySportPref].
extension PlaySportPrefPatterns on PlaySportPref {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaySportPref value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaySportPref() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaySportPref value)  $default,){
final _that = this;
switch (_that) {
case _PlaySportPref():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaySportPref value)?  $default,){
final _that = this;
switch (_that) {
case _PlaySportPref() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Sport sport,  GameType? gameType,  double levelMin,  double levelMax)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaySportPref() when $default != null:
return $default(_that.sport,_that.gameType,_that.levelMin,_that.levelMax);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Sport sport,  GameType? gameType,  double levelMin,  double levelMax)  $default,) {final _that = this;
switch (_that) {
case _PlaySportPref():
return $default(_that.sport,_that.gameType,_that.levelMin,_that.levelMax);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Sport sport,  GameType? gameType,  double levelMin,  double levelMax)?  $default,) {final _that = this;
switch (_that) {
case _PlaySportPref() when $default != null:
return $default(_that.sport,_that.gameType,_that.levelMin,_that.levelMax);case _:
  return null;

}
}

}

/// @nodoc


class _PlaySportPref implements PlaySportPref {
  const _PlaySportPref({required this.sport, this.gameType, this.levelMin = 1.0, this.levelMax = 8.0});
  

@override final  Sport sport;
@override final  GameType? gameType;
@override@JsonKey() final  double levelMin;
@override@JsonKey() final  double levelMax;

/// Create a copy of PlaySportPref
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaySportPrefCopyWith<_PlaySportPref> get copyWith => __$PlaySportPrefCopyWithImpl<_PlaySportPref>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaySportPref&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.levelMin, levelMin) || other.levelMin == levelMin)&&(identical(other.levelMax, levelMax) || other.levelMax == levelMax));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sport,gameType,levelMin,levelMax);
}

@override
String toString() {
    return 'PlaySportPref(sport: $sport, gameType: $gameType, levelMin: $levelMin, levelMax: $levelMax)';
}


}

/// @nodoc
abstract mixin class _$PlaySportPrefCopyWith<$Res> implements $PlaySportPrefCopyWith<$Res> {
  factory _$PlaySportPrefCopyWith(_PlaySportPref value, $Res Function(_PlaySportPref) _then) = __$PlaySportPrefCopyWithImpl;
@override @useResult
$Res call({
 Sport sport, GameType? gameType, double levelMin, double levelMax
});




}
/// @nodoc
class __$PlaySportPrefCopyWithImpl<$Res>
    implements _$PlaySportPrefCopyWith<$Res> {
  __$PlaySportPrefCopyWithImpl(this._self, this._then);

  final _PlaySportPref _self;
  final $Res Function(_PlaySportPref) _then;

/// Create a copy of PlaySportPref
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sport = null,Object? gameType = freezed,Object? levelMin = null,Object? levelMax = null,}) {
  return _then(_PlaySportPref(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,levelMin: null == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double,levelMax: null == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ActivityDraft {

 ActivityKind get kind; List<Sport> get sports; String get title; String get description; GameType? get gameType; ActivityFormat? get format; double get levelMin; double get levelMax; DateTime? get date; DateTime? get endDate; int get hour; int get minute; int get durationMinutes; Venue? get venue; int get capacity; int get courts; bool get approvalRequired; bool get chargeFee; int get feeCents; bool get allowGuests; String get scoring; bool get seedByLevel; bool get umpireScores; bool get allowRefunds; DateTime? get registrationCloses;/// Set when the session is created from a club page.
 String? get clubId;/// The banner: a short title on a colour. Tournaments must have one.
 String? get coverTitle; int get coverColor;/// How often it runs: once, weekly or every other week.
 Repeat get repeat;/// Weekdays it runs on (1 is Monday), when it repeats.
 List<int> get repeatDays; int get repeatCount;/// Below this many sign-ups a day before, the host decides to cancel.
 int get minPlayers;/// Off: every level can join.
 bool get restrictLevel;/// Show the level as "3.0–5.9" instead of "LI–HI".
 bool get levelAsNumbers; bool get ranked;/// A free Meet still has the S\$2 platform fee: false means the host
/// pays it for each player.
 bool get playersPayFee; bool get hostInvitesOnly; bool get listPublicly;/// Club, Regional or National.
 String get tier;/// Teams enter with a roster instead of players and pairs.
 bool get teamEntry;/// The events inside it, by key: MS, WS, MD, WD, XD.
 List<String> get divisionKeys; List<String> get ageDivisions;/// Below this many entries at close, an event is cancelled and refunded.
 int get minEntries; bool get verifiedOnly; bool get matchCheckIn; bool get waitlistWhenFull;/// The event that shows this tournament (or the tournament an event
/// shows).
 String? get linkedId; bool get online;/// Set when changing a published activity rather than creating one.
 String? get editingId;
/// Create a copy of ActivityDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityDraftCopyWith<ActivityDraft> get copyWith => _$ActivityDraftCopyWithImpl<ActivityDraft>(this as ActivityDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActivityDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityDraft&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.sports, _this.sports)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.gameType, _this.gameType) || other.gameType == _this.gameType)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.levelMin, _this.levelMin) || other.levelMin == _this.levelMin)&&(identical(other.levelMax, _this.levelMax) || other.levelMax == _this.levelMax)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.hour, _this.hour) || other.hour == _this.hour)&&(identical(other.minute, _this.minute) || other.minute == _this.minute)&&(identical(other.durationMinutes, _this.durationMinutes) || other.durationMinutes == _this.durationMinutes)&&(identical(other.venue, _this.venue) || other.venue == _this.venue)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.courts, _this.courts) || other.courts == _this.courts)&&(identical(other.approvalRequired, _this.approvalRequired) || other.approvalRequired == _this.approvalRequired)&&(identical(other.chargeFee, _this.chargeFee) || other.chargeFee == _this.chargeFee)&&(identical(other.feeCents, _this.feeCents) || other.feeCents == _this.feeCents)&&(identical(other.allowGuests, _this.allowGuests) || other.allowGuests == _this.allowGuests)&&(identical(other.scoring, _this.scoring) || other.scoring == _this.scoring)&&(identical(other.seedByLevel, _this.seedByLevel) || other.seedByLevel == _this.seedByLevel)&&(identical(other.umpireScores, _this.umpireScores) || other.umpireScores == _this.umpireScores)&&(identical(other.allowRefunds, _this.allowRefunds) || other.allowRefunds == _this.allowRefunds)&&(identical(other.registrationCloses, _this.registrationCloses) || other.registrationCloses == _this.registrationCloses)&&(identical(other.clubId, _this.clubId) || other.clubId == _this.clubId)&&(identical(other.coverTitle, _this.coverTitle) || other.coverTitle == _this.coverTitle)&&(identical(other.coverColor, _this.coverColor) || other.coverColor == _this.coverColor)&&(identical(other.repeat, _this.repeat) || other.repeat == _this.repeat)&&const DeepCollectionEquality().equals(other.repeatDays, _this.repeatDays)&&(identical(other.repeatCount, _this.repeatCount) || other.repeatCount == _this.repeatCount)&&(identical(other.minPlayers, _this.minPlayers) || other.minPlayers == _this.minPlayers)&&(identical(other.restrictLevel, _this.restrictLevel) || other.restrictLevel == _this.restrictLevel)&&(identical(other.levelAsNumbers, _this.levelAsNumbers) || other.levelAsNumbers == _this.levelAsNumbers)&&(identical(other.ranked, _this.ranked) || other.ranked == _this.ranked)&&(identical(other.playersPayFee, _this.playersPayFee) || other.playersPayFee == _this.playersPayFee)&&(identical(other.hostInvitesOnly, _this.hostInvitesOnly) || other.hostInvitesOnly == _this.hostInvitesOnly)&&(identical(other.listPublicly, _this.listPublicly) || other.listPublicly == _this.listPublicly)&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&(identical(other.teamEntry, _this.teamEntry) || other.teamEntry == _this.teamEntry)&&const DeepCollectionEquality().equals(other.divisionKeys, _this.divisionKeys)&&const DeepCollectionEquality().equals(other.ageDivisions, _this.ageDivisions)&&(identical(other.minEntries, _this.minEntries) || other.minEntries == _this.minEntries)&&(identical(other.verifiedOnly, _this.verifiedOnly) || other.verifiedOnly == _this.verifiedOnly)&&(identical(other.matchCheckIn, _this.matchCheckIn) || other.matchCheckIn == _this.matchCheckIn)&&(identical(other.waitlistWhenFull, _this.waitlistWhenFull) || other.waitlistWhenFull == _this.waitlistWhenFull)&&(identical(other.linkedId, _this.linkedId) || other.linkedId == _this.linkedId)&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.editingId, _this.editingId) || other.editingId == _this.editingId));
}


@override
int get hashCode {
  final _this = this as ActivityDraft;
  return Object.hashAll([runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.sports),_this.title,_this.description,_this.gameType,_this.format,_this.levelMin,_this.levelMax,_this.date,_this.endDate,_this.hour,_this.minute,_this.durationMinutes,_this.venue,_this.capacity,_this.courts,_this.approvalRequired,_this.chargeFee,_this.feeCents,_this.allowGuests,_this.scoring,_this.seedByLevel,_this.umpireScores,_this.allowRefunds,_this.registrationCloses,_this.clubId,_this.coverTitle,_this.coverColor,_this.repeat,const DeepCollectionEquality().hash(_this.repeatDays),_this.repeatCount,_this.minPlayers,_this.restrictLevel,_this.levelAsNumbers,_this.ranked,_this.playersPayFee,_this.hostInvitesOnly,_this.listPublicly,_this.tier,_this.teamEntry,const DeepCollectionEquality().hash(_this.divisionKeys),const DeepCollectionEquality().hash(_this.ageDivisions),_this.minEntries,_this.verifiedOnly,_this.matchCheckIn,_this.waitlistWhenFull,_this.linkedId,_this.online,_this.editingId]);
}

@override
String toString() {
  final _this = this as ActivityDraft;
  return 'ActivityDraft(kind: ${_this.kind}, sports: ${_this.sports}, title: ${_this.title}, description: ${_this.description}, gameType: ${_this.gameType}, format: ${_this.format}, levelMin: ${_this.levelMin}, levelMax: ${_this.levelMax}, date: ${_this.date}, endDate: ${_this.endDate}, hour: ${_this.hour}, minute: ${_this.minute}, durationMinutes: ${_this.durationMinutes}, venue: ${_this.venue}, capacity: ${_this.capacity}, courts: ${_this.courts}, approvalRequired: ${_this.approvalRequired}, chargeFee: ${_this.chargeFee}, feeCents: ${_this.feeCents}, allowGuests: ${_this.allowGuests}, scoring: ${_this.scoring}, seedByLevel: ${_this.seedByLevel}, umpireScores: ${_this.umpireScores}, allowRefunds: ${_this.allowRefunds}, registrationCloses: ${_this.registrationCloses}, clubId: ${_this.clubId}, coverTitle: ${_this.coverTitle}, coverColor: ${_this.coverColor}, repeat: ${_this.repeat}, repeatDays: ${_this.repeatDays}, repeatCount: ${_this.repeatCount}, minPlayers: ${_this.minPlayers}, restrictLevel: ${_this.restrictLevel}, levelAsNumbers: ${_this.levelAsNumbers}, ranked: ${_this.ranked}, playersPayFee: ${_this.playersPayFee}, hostInvitesOnly: ${_this.hostInvitesOnly}, listPublicly: ${_this.listPublicly}, tier: ${_this.tier}, teamEntry: ${_this.teamEntry}, divisionKeys: ${_this.divisionKeys}, ageDivisions: ${_this.ageDivisions}, minEntries: ${_this.minEntries}, verifiedOnly: ${_this.verifiedOnly}, matchCheckIn: ${_this.matchCheckIn}, waitlistWhenFull: ${_this.waitlistWhenFull}, linkedId: ${_this.linkedId}, online: ${_this.online}, editingId: ${_this.editingId})';
}


}

/// @nodoc
abstract mixin class $ActivityDraftCopyWith<$Res>  {
  factory $ActivityDraftCopyWith(ActivityDraft value, $Res Function(ActivityDraft) _then) = _$ActivityDraftCopyWithImpl;
@useResult
$Res call({
 ActivityKind kind, List<Sport> sports, String title, String description, GameType? gameType, ActivityFormat? format, double levelMin, double levelMax, DateTime? date, DateTime? endDate, int hour, int minute, int durationMinutes, Venue? venue, int capacity, int courts, bool approvalRequired, bool chargeFee, int feeCents, bool allowGuests, String scoring, bool seedByLevel, bool umpireScores, bool allowRefunds, DateTime? registrationCloses, String? clubId, String? coverTitle, int coverColor, Repeat repeat, List<int> repeatDays, int repeatCount, int minPlayers, bool restrictLevel, bool levelAsNumbers, bool ranked, bool playersPayFee, bool hostInvitesOnly, bool listPublicly, String tier, bool teamEntry, List<String> divisionKeys, List<String> ageDivisions, int minEntries, bool verifiedOnly, bool matchCheckIn, bool waitlistWhenFull, String? linkedId, bool online, String? editingId
});


$VenueCopyWith<$Res>? get venue;

}
/// @nodoc
class _$ActivityDraftCopyWithImpl<$Res>
    implements $ActivityDraftCopyWith<$Res> {
  _$ActivityDraftCopyWithImpl(this._self, this._then);

  final ActivityDraft _self;
  final $Res Function(ActivityDraft) _then;

/// Create a copy of ActivityDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? sports = null,Object? title = null,Object? description = null,Object? gameType = freezed,Object? format = freezed,Object? levelMin = null,Object? levelMax = null,Object? date = freezed,Object? endDate = freezed,Object? hour = null,Object? minute = null,Object? durationMinutes = null,Object? venue = freezed,Object? capacity = null,Object? courts = null,Object? approvalRequired = null,Object? chargeFee = null,Object? feeCents = null,Object? allowGuests = null,Object? scoring = null,Object? seedByLevel = null,Object? umpireScores = null,Object? allowRefunds = null,Object? registrationCloses = freezed,Object? clubId = freezed,Object? coverTitle = freezed,Object? coverColor = null,Object? repeat = null,Object? repeatDays = null,Object? repeatCount = null,Object? minPlayers = null,Object? restrictLevel = null,Object? levelAsNumbers = null,Object? ranked = null,Object? playersPayFee = null,Object? hostInvitesOnly = null,Object? listPublicly = null,Object? tier = null,Object? teamEntry = null,Object? divisionKeys = null,Object? ageDivisions = null,Object? minEntries = null,Object? verifiedOnly = null,Object? matchCheckIn = null,Object? waitlistWhenFull = null,Object? linkedId = freezed,Object? online = null,Object? editingId = freezed,}) {
  return _then(ActivityDraft(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,sports: null == sports ? _self.sports : sports // ignore: cast_nullable_to_non_nullable
as List<Sport>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ActivityFormat?,levelMin: null == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double,levelMax: null == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,minute: null == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as Venue?,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,courts: null == courts ? _self.courts : courts // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,chargeFee: null == chargeFee ? _self.chargeFee : chargeFee // ignore: cast_nullable_to_non_nullable
as bool,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,allowGuests: null == allowGuests ? _self.allowGuests : allowGuests // ignore: cast_nullable_to_non_nullable
as bool,scoring: null == scoring ? _self.scoring : scoring // ignore: cast_nullable_to_non_nullable
as String,seedByLevel: null == seedByLevel ? _self.seedByLevel : seedByLevel // ignore: cast_nullable_to_non_nullable
as bool,umpireScores: null == umpireScores ? _self.umpireScores : umpireScores // ignore: cast_nullable_to_non_nullable
as bool,allowRefunds: null == allowRefunds ? _self.allowRefunds : allowRefunds // ignore: cast_nullable_to_non_nullable
as bool,registrationCloses: freezed == registrationCloses ? _self.registrationCloses : registrationCloses // ignore: cast_nullable_to_non_nullable
as DateTime?,clubId: freezed == clubId ? _self.clubId : clubId // ignore: cast_nullable_to_non_nullable
as String?,coverTitle: freezed == coverTitle ? _self.coverTitle : coverTitle // ignore: cast_nullable_to_non_nullable
as String?,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as Repeat,repeatDays: null == repeatDays ? _self.repeatDays : repeatDays // ignore: cast_nullable_to_non_nullable
as List<int>,repeatCount: null == repeatCount ? _self.repeatCount : repeatCount // ignore: cast_nullable_to_non_nullable
as int,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,restrictLevel: null == restrictLevel ? _self.restrictLevel : restrictLevel // ignore: cast_nullable_to_non_nullable
as bool,levelAsNumbers: null == levelAsNumbers ? _self.levelAsNumbers : levelAsNumbers // ignore: cast_nullable_to_non_nullable
as bool,ranked: null == ranked ? _self.ranked : ranked // ignore: cast_nullable_to_non_nullable
as bool,playersPayFee: null == playersPayFee ? _self.playersPayFee : playersPayFee // ignore: cast_nullable_to_non_nullable
as bool,hostInvitesOnly: null == hostInvitesOnly ? _self.hostInvitesOnly : hostInvitesOnly // ignore: cast_nullable_to_non_nullable
as bool,listPublicly: null == listPublicly ? _self.listPublicly : listPublicly // ignore: cast_nullable_to_non_nullable
as bool,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,teamEntry: null == teamEntry ? _self.teamEntry : teamEntry // ignore: cast_nullable_to_non_nullable
as bool,divisionKeys: null == divisionKeys ? _self.divisionKeys : divisionKeys // ignore: cast_nullable_to_non_nullable
as List<String>,ageDivisions: null == ageDivisions ? _self.ageDivisions : ageDivisions // ignore: cast_nullable_to_non_nullable
as List<String>,minEntries: null == minEntries ? _self.minEntries : minEntries // ignore: cast_nullable_to_non_nullable
as int,verifiedOnly: null == verifiedOnly ? _self.verifiedOnly : verifiedOnly // ignore: cast_nullable_to_non_nullable
as bool,matchCheckIn: null == matchCheckIn ? _self.matchCheckIn : matchCheckIn // ignore: cast_nullable_to_non_nullable
as bool,waitlistWhenFull: null == waitlistWhenFull ? _self.waitlistWhenFull : waitlistWhenFull // ignore: cast_nullable_to_non_nullable
as bool,linkedId: freezed == linkedId ? _self.linkedId : linkedId // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,editingId: freezed == editingId ? _self.editingId : editingId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ActivityDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueCopyWith<$Res>? get venue {
    if (_self.venue == null) {
    return null;
  }

  return $VenueCopyWith<$Res>(_self.venue!, (value) {
    return _then(_self.copyWith(venue: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivityDraft].
extension ActivityDraftPatterns on ActivityDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityDraft value)  $default,){
final _that = this;
switch (_that) {
case _ActivityDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ActivityKind kind,  List<Sport> sports,  String title,  String description,  GameType? gameType,  ActivityFormat? format,  double levelMin,  double levelMax,  DateTime? date,  DateTime? endDate,  int hour,  int minute,  int durationMinutes,  Venue? venue,  int capacity,  int courts,  bool approvalRequired,  bool chargeFee,  int feeCents,  bool allowGuests,  String scoring,  bool seedByLevel,  bool umpireScores,  bool allowRefunds,  DateTime? registrationCloses,  String? clubId,  String? coverTitle,  int coverColor,  Repeat repeat,  List<int> repeatDays,  int repeatCount,  int minPlayers,  bool restrictLevel,  bool levelAsNumbers,  bool ranked,  bool playersPayFee,  bool hostInvitesOnly,  bool listPublicly,  String tier,  bool teamEntry,  List<String> divisionKeys,  List<String> ageDivisions,  int minEntries,  bool verifiedOnly,  bool matchCheckIn,  bool waitlistWhenFull,  String? linkedId,  bool online,  String? editingId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityDraft() when $default != null:
return $default(_that.kind,_that.sports,_that.title,_that.description,_that.gameType,_that.format,_that.levelMin,_that.levelMax,_that.date,_that.endDate,_that.hour,_that.minute,_that.durationMinutes,_that.venue,_that.capacity,_that.courts,_that.approvalRequired,_that.chargeFee,_that.feeCents,_that.allowGuests,_that.scoring,_that.seedByLevel,_that.umpireScores,_that.allowRefunds,_that.registrationCloses,_that.clubId,_that.coverTitle,_that.coverColor,_that.repeat,_that.repeatDays,_that.repeatCount,_that.minPlayers,_that.restrictLevel,_that.levelAsNumbers,_that.ranked,_that.playersPayFee,_that.hostInvitesOnly,_that.listPublicly,_that.tier,_that.teamEntry,_that.divisionKeys,_that.ageDivisions,_that.minEntries,_that.verifiedOnly,_that.matchCheckIn,_that.waitlistWhenFull,_that.linkedId,_that.online,_that.editingId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ActivityKind kind,  List<Sport> sports,  String title,  String description,  GameType? gameType,  ActivityFormat? format,  double levelMin,  double levelMax,  DateTime? date,  DateTime? endDate,  int hour,  int minute,  int durationMinutes,  Venue? venue,  int capacity,  int courts,  bool approvalRequired,  bool chargeFee,  int feeCents,  bool allowGuests,  String scoring,  bool seedByLevel,  bool umpireScores,  bool allowRefunds,  DateTime? registrationCloses,  String? clubId,  String? coverTitle,  int coverColor,  Repeat repeat,  List<int> repeatDays,  int repeatCount,  int minPlayers,  bool restrictLevel,  bool levelAsNumbers,  bool ranked,  bool playersPayFee,  bool hostInvitesOnly,  bool listPublicly,  String tier,  bool teamEntry,  List<String> divisionKeys,  List<String> ageDivisions,  int minEntries,  bool verifiedOnly,  bool matchCheckIn,  bool waitlistWhenFull,  String? linkedId,  bool online,  String? editingId)  $default,) {final _that = this;
switch (_that) {
case _ActivityDraft():
return $default(_that.kind,_that.sports,_that.title,_that.description,_that.gameType,_that.format,_that.levelMin,_that.levelMax,_that.date,_that.endDate,_that.hour,_that.minute,_that.durationMinutes,_that.venue,_that.capacity,_that.courts,_that.approvalRequired,_that.chargeFee,_that.feeCents,_that.allowGuests,_that.scoring,_that.seedByLevel,_that.umpireScores,_that.allowRefunds,_that.registrationCloses,_that.clubId,_that.coverTitle,_that.coverColor,_that.repeat,_that.repeatDays,_that.repeatCount,_that.minPlayers,_that.restrictLevel,_that.levelAsNumbers,_that.ranked,_that.playersPayFee,_that.hostInvitesOnly,_that.listPublicly,_that.tier,_that.teamEntry,_that.divisionKeys,_that.ageDivisions,_that.minEntries,_that.verifiedOnly,_that.matchCheckIn,_that.waitlistWhenFull,_that.linkedId,_that.online,_that.editingId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ActivityKind kind,  List<Sport> sports,  String title,  String description,  GameType? gameType,  ActivityFormat? format,  double levelMin,  double levelMax,  DateTime? date,  DateTime? endDate,  int hour,  int minute,  int durationMinutes,  Venue? venue,  int capacity,  int courts,  bool approvalRequired,  bool chargeFee,  int feeCents,  bool allowGuests,  String scoring,  bool seedByLevel,  bool umpireScores,  bool allowRefunds,  DateTime? registrationCloses,  String? clubId,  String? coverTitle,  int coverColor,  Repeat repeat,  List<int> repeatDays,  int repeatCount,  int minPlayers,  bool restrictLevel,  bool levelAsNumbers,  bool ranked,  bool playersPayFee,  bool hostInvitesOnly,  bool listPublicly,  String tier,  bool teamEntry,  List<String> divisionKeys,  List<String> ageDivisions,  int minEntries,  bool verifiedOnly,  bool matchCheckIn,  bool waitlistWhenFull,  String? linkedId,  bool online,  String? editingId)?  $default,) {final _that = this;
switch (_that) {
case _ActivityDraft() when $default != null:
return $default(_that.kind,_that.sports,_that.title,_that.description,_that.gameType,_that.format,_that.levelMin,_that.levelMax,_that.date,_that.endDate,_that.hour,_that.minute,_that.durationMinutes,_that.venue,_that.capacity,_that.courts,_that.approvalRequired,_that.chargeFee,_that.feeCents,_that.allowGuests,_that.scoring,_that.seedByLevel,_that.umpireScores,_that.allowRefunds,_that.registrationCloses,_that.clubId,_that.coverTitle,_that.coverColor,_that.repeat,_that.repeatDays,_that.repeatCount,_that.minPlayers,_that.restrictLevel,_that.levelAsNumbers,_that.ranked,_that.playersPayFee,_that.hostInvitesOnly,_that.listPublicly,_that.tier,_that.teamEntry,_that.divisionKeys,_that.ageDivisions,_that.minEntries,_that.verifiedOnly,_that.matchCheckIn,_that.waitlistWhenFull,_that.linkedId,_that.online,_that.editingId);case _:
  return null;

}
}

}

/// @nodoc


class _ActivityDraft extends ActivityDraft {
  const _ActivityDraft({this.kind = ActivityKind.meet,  List<Sport> sports = const [Sport.badminton], this.title = '', this.description = '', this.gameType, this.format, this.levelMin = 3.0, this.levelMax = 5.0, this.date, this.endDate, this.hour = 19, this.minute = 30, this.durationMinutes = 120, this.venue, this.capacity = 12, this.courts = 3, this.approvalRequired = false, this.chargeFee = true, this.feeCents = 800, this.allowGuests = true, this.scoring = 'Best of 3 to 21', this.seedByLevel = true, this.umpireScores = false, this.allowRefunds = true, this.registrationCloses, this.clubId, this.coverTitle, this.coverColor = 0xFF16181B, this.repeat = Repeat.once,  List<int> repeatDays = const <int>[], this.repeatCount = 8, this.minPlayers = 4, this.restrictLevel = true, this.levelAsNumbers = false, this.ranked = false, this.playersPayFee = false, this.hostInvitesOnly = false, this.listPublicly = false, this.tier = 'Regional', this.teamEntry = false,  List<String> divisionKeys = const <String>['MS', 'WS', 'MD', 'XD'],  List<String> ageDivisions = const <String>['Open'], this.minEntries = 8, this.verifiedOnly = true, this.matchCheckIn = true, this.waitlistWhenFull = true, this.linkedId, this.online = false, this.editingId}): _sports = sports,_repeatDays = repeatDays,_divisionKeys = divisionKeys,_ageDivisions = ageDivisions,super._();
  

@override@JsonKey() final  ActivityKind kind;
 final  List<Sport> _sports;
@override@JsonKey() List<Sport> get sports {
  if (_sports is EqualUnmodifiableListView) return _sports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sports);
}

@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override final  GameType? gameType;
@override final  ActivityFormat? format;
@override@JsonKey() final  double levelMin;
@override@JsonKey() final  double levelMax;
@override final  DateTime? date;
@override final  DateTime? endDate;
@override@JsonKey() final  int hour;
@override@JsonKey() final  int minute;
@override@JsonKey() final  int durationMinutes;
@override final  Venue? venue;
@override@JsonKey() final  int capacity;
@override@JsonKey() final  int courts;
@override@JsonKey() final  bool approvalRequired;
@override@JsonKey() final  bool chargeFee;
@override@JsonKey() final  int feeCents;
@override@JsonKey() final  bool allowGuests;
@override@JsonKey() final  String scoring;
@override@JsonKey() final  bool seedByLevel;
@override@JsonKey() final  bool umpireScores;
@override@JsonKey() final  bool allowRefunds;
@override final  DateTime? registrationCloses;
/// Set when the session is created from a club page.
@override final  String? clubId;
/// The banner: a short title on a colour. Tournaments must have one.
@override final  String? coverTitle;
@override@JsonKey() final  int coverColor;
/// How often it runs: once, weekly or every other week.
@override@JsonKey() final  Repeat repeat;
/// Weekdays it runs on (1 is Monday), when it repeats.
 final  List<int> _repeatDays;
/// Weekdays it runs on (1 is Monday), when it repeats.
@override@JsonKey() List<int> get repeatDays {
  if (_repeatDays is EqualUnmodifiableListView) return _repeatDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_repeatDays);
}

@override@JsonKey() final  int repeatCount;
/// Below this many sign-ups a day before, the host decides to cancel.
@override@JsonKey() final  int minPlayers;
/// Off: every level can join.
@override@JsonKey() final  bool restrictLevel;
/// Show the level as "3.0–5.9" instead of "LI–HI".
@override@JsonKey() final  bool levelAsNumbers;
@override@JsonKey() final  bool ranked;
/// A free Meet still has the S\$2 platform fee: false means the host
/// pays it for each player.
@override@JsonKey() final  bool playersPayFee;
@override@JsonKey() final  bool hostInvitesOnly;
@override@JsonKey() final  bool listPublicly;
/// Club, Regional or National.
@override@JsonKey() final  String tier;
/// Teams enter with a roster instead of players and pairs.
@override@JsonKey() final  bool teamEntry;
/// The events inside it, by key: MS, WS, MD, WD, XD.
 final  List<String> _divisionKeys;
/// The events inside it, by key: MS, WS, MD, WD, XD.
@override@JsonKey() List<String> get divisionKeys {
  if (_divisionKeys is EqualUnmodifiableListView) return _divisionKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_divisionKeys);
}

 final  List<String> _ageDivisions;
@override@JsonKey() List<String> get ageDivisions {
  if (_ageDivisions is EqualUnmodifiableListView) return _ageDivisions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ageDivisions);
}

/// Below this many entries at close, an event is cancelled and refunded.
@override@JsonKey() final  int minEntries;
@override@JsonKey() final  bool verifiedOnly;
@override@JsonKey() final  bool matchCheckIn;
@override@JsonKey() final  bool waitlistWhenFull;
/// The event that shows this tournament (or the tournament an event
/// shows).
@override final  String? linkedId;
@override@JsonKey() final  bool online;
/// Set when changing a published activity rather than creating one.
@override final  String? editingId;

/// Create a copy of ActivityDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityDraftCopyWith<_ActivityDraft> get copyWith => __$ActivityDraftCopyWithImpl<_ActivityDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityDraft&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.sports, _sports)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.format, format) || other.format == format)&&(identical(other.levelMin, levelMin) || other.levelMin == levelMin)&&(identical(other.levelMax, levelMax) || other.levelMax == levelMax)&&(identical(other.date, date) || other.date == date)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.minute, minute) || other.minute == minute)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.courts, courts) || other.courts == courts)&&(identical(other.approvalRequired, approvalRequired) || other.approvalRequired == approvalRequired)&&(identical(other.chargeFee, chargeFee) || other.chargeFee == chargeFee)&&(identical(other.feeCents, feeCents) || other.feeCents == feeCents)&&(identical(other.allowGuests, allowGuests) || other.allowGuests == allowGuests)&&(identical(other.scoring, scoring) || other.scoring == scoring)&&(identical(other.seedByLevel, seedByLevel) || other.seedByLevel == seedByLevel)&&(identical(other.umpireScores, umpireScores) || other.umpireScores == umpireScores)&&(identical(other.allowRefunds, allowRefunds) || other.allowRefunds == allowRefunds)&&(identical(other.registrationCloses, registrationCloses) || other.registrationCloses == registrationCloses)&&(identical(other.clubId, clubId) || other.clubId == clubId)&&(identical(other.coverTitle, coverTitle) || other.coverTitle == coverTitle)&&(identical(other.coverColor, coverColor) || other.coverColor == coverColor)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&const DeepCollectionEquality().equals(other.repeatDays, _repeatDays)&&(identical(other.repeatCount, repeatCount) || other.repeatCount == repeatCount)&&(identical(other.minPlayers, minPlayers) || other.minPlayers == minPlayers)&&(identical(other.restrictLevel, restrictLevel) || other.restrictLevel == restrictLevel)&&(identical(other.levelAsNumbers, levelAsNumbers) || other.levelAsNumbers == levelAsNumbers)&&(identical(other.ranked, ranked) || other.ranked == ranked)&&(identical(other.playersPayFee, playersPayFee) || other.playersPayFee == playersPayFee)&&(identical(other.hostInvitesOnly, hostInvitesOnly) || other.hostInvitesOnly == hostInvitesOnly)&&(identical(other.listPublicly, listPublicly) || other.listPublicly == listPublicly)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.teamEntry, teamEntry) || other.teamEntry == teamEntry)&&const DeepCollectionEquality().equals(other.divisionKeys, _divisionKeys)&&const DeepCollectionEquality().equals(other.ageDivisions, _ageDivisions)&&(identical(other.minEntries, minEntries) || other.minEntries == minEntries)&&(identical(other.verifiedOnly, verifiedOnly) || other.verifiedOnly == verifiedOnly)&&(identical(other.matchCheckIn, matchCheckIn) || other.matchCheckIn == matchCheckIn)&&(identical(other.waitlistWhenFull, waitlistWhenFull) || other.waitlistWhenFull == waitlistWhenFull)&&(identical(other.linkedId, linkedId) || other.linkedId == linkedId)&&(identical(other.online, online) || other.online == online)&&(identical(other.editingId, editingId) || other.editingId == editingId));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,kind,const DeepCollectionEquality().hash(_sports),title,description,gameType,format,levelMin,levelMax,date,endDate,hour,minute,durationMinutes,venue,capacity,courts,approvalRequired,chargeFee,feeCents,allowGuests,scoring,seedByLevel,umpireScores,allowRefunds,registrationCloses,clubId,coverTitle,coverColor,repeat,const DeepCollectionEquality().hash(_repeatDays),repeatCount,minPlayers,restrictLevel,levelAsNumbers,ranked,playersPayFee,hostInvitesOnly,listPublicly,tier,teamEntry,const DeepCollectionEquality().hash(_divisionKeys),const DeepCollectionEquality().hash(_ageDivisions),minEntries,verifiedOnly,matchCheckIn,waitlistWhenFull,linkedId,online,editingId]);
}

@override
String toString() {
    return 'ActivityDraft(kind: $kind, sports: $sports, title: $title, description: $description, gameType: $gameType, format: $format, levelMin: $levelMin, levelMax: $levelMax, date: $date, endDate: $endDate, hour: $hour, minute: $minute, durationMinutes: $durationMinutes, venue: $venue, capacity: $capacity, courts: $courts, approvalRequired: $approvalRequired, chargeFee: $chargeFee, feeCents: $feeCents, allowGuests: $allowGuests, scoring: $scoring, seedByLevel: $seedByLevel, umpireScores: $umpireScores, allowRefunds: $allowRefunds, registrationCloses: $registrationCloses, clubId: $clubId, coverTitle: $coverTitle, coverColor: $coverColor, repeat: $repeat, repeatDays: $repeatDays, repeatCount: $repeatCount, minPlayers: $minPlayers, restrictLevel: $restrictLevel, levelAsNumbers: $levelAsNumbers, ranked: $ranked, playersPayFee: $playersPayFee, hostInvitesOnly: $hostInvitesOnly, listPublicly: $listPublicly, tier: $tier, teamEntry: $teamEntry, divisionKeys: $divisionKeys, ageDivisions: $ageDivisions, minEntries: $minEntries, verifiedOnly: $verifiedOnly, matchCheckIn: $matchCheckIn, waitlistWhenFull: $waitlistWhenFull, linkedId: $linkedId, online: $online, editingId: $editingId)';
}


}

/// @nodoc
abstract mixin class _$ActivityDraftCopyWith<$Res> implements $ActivityDraftCopyWith<$Res> {
  factory _$ActivityDraftCopyWith(_ActivityDraft value, $Res Function(_ActivityDraft) _then) = __$ActivityDraftCopyWithImpl;
@override @useResult
$Res call({
 ActivityKind kind, List<Sport> sports, String title, String description, GameType? gameType, ActivityFormat? format, double levelMin, double levelMax, DateTime? date, DateTime? endDate, int hour, int minute, int durationMinutes, Venue? venue, int capacity, int courts, bool approvalRequired, bool chargeFee, int feeCents, bool allowGuests, String scoring, bool seedByLevel, bool umpireScores, bool allowRefunds, DateTime? registrationCloses, String? clubId, String? coverTitle, int coverColor, Repeat repeat, List<int> repeatDays, int repeatCount, int minPlayers, bool restrictLevel, bool levelAsNumbers, bool ranked, bool playersPayFee, bool hostInvitesOnly, bool listPublicly, String tier, bool teamEntry, List<String> divisionKeys, List<String> ageDivisions, int minEntries, bool verifiedOnly, bool matchCheckIn, bool waitlistWhenFull, String? linkedId, bool online, String? editingId
});


@override $VenueCopyWith<$Res>? get venue;

}
/// @nodoc
class __$ActivityDraftCopyWithImpl<$Res>
    implements _$ActivityDraftCopyWith<$Res> {
  __$ActivityDraftCopyWithImpl(this._self, this._then);

  final _ActivityDraft _self;
  final $Res Function(_ActivityDraft) _then;

/// Create a copy of ActivityDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? sports = null,Object? title = null,Object? description = null,Object? gameType = freezed,Object? format = freezed,Object? levelMin = null,Object? levelMax = null,Object? date = freezed,Object? endDate = freezed,Object? hour = null,Object? minute = null,Object? durationMinutes = null,Object? venue = freezed,Object? capacity = null,Object? courts = null,Object? approvalRequired = null,Object? chargeFee = null,Object? feeCents = null,Object? allowGuests = null,Object? scoring = null,Object? seedByLevel = null,Object? umpireScores = null,Object? allowRefunds = null,Object? registrationCloses = freezed,Object? clubId = freezed,Object? coverTitle = freezed,Object? coverColor = null,Object? repeat = null,Object? repeatDays = null,Object? repeatCount = null,Object? minPlayers = null,Object? restrictLevel = null,Object? levelAsNumbers = null,Object? ranked = null,Object? playersPayFee = null,Object? hostInvitesOnly = null,Object? listPublicly = null,Object? tier = null,Object? teamEntry = null,Object? divisionKeys = null,Object? ageDivisions = null,Object? minEntries = null,Object? verifiedOnly = null,Object? matchCheckIn = null,Object? waitlistWhenFull = null,Object? linkedId = freezed,Object? online = null,Object? editingId = freezed,}) {
  return _then(_ActivityDraft(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,sports: null == sports ? _self._sports : sports // ignore: cast_nullable_to_non_nullable
as List<Sport>,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ActivityFormat?,levelMin: null == levelMin ? _self.levelMin : levelMin // ignore: cast_nullable_to_non_nullable
as double,levelMax: null == levelMax ? _self.levelMax : levelMax // ignore: cast_nullable_to_non_nullable
as double,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,minute: null == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as Venue?,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,courts: null == courts ? _self.courts : courts // ignore: cast_nullable_to_non_nullable
as int,approvalRequired: null == approvalRequired ? _self.approvalRequired : approvalRequired // ignore: cast_nullable_to_non_nullable
as bool,chargeFee: null == chargeFee ? _self.chargeFee : chargeFee // ignore: cast_nullable_to_non_nullable
as bool,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,allowGuests: null == allowGuests ? _self.allowGuests : allowGuests // ignore: cast_nullable_to_non_nullable
as bool,scoring: null == scoring ? _self.scoring : scoring // ignore: cast_nullable_to_non_nullable
as String,seedByLevel: null == seedByLevel ? _self.seedByLevel : seedByLevel // ignore: cast_nullable_to_non_nullable
as bool,umpireScores: null == umpireScores ? _self.umpireScores : umpireScores // ignore: cast_nullable_to_non_nullable
as bool,allowRefunds: null == allowRefunds ? _self.allowRefunds : allowRefunds // ignore: cast_nullable_to_non_nullable
as bool,registrationCloses: freezed == registrationCloses ? _self.registrationCloses : registrationCloses // ignore: cast_nullable_to_non_nullable
as DateTime?,clubId: freezed == clubId ? _self.clubId : clubId // ignore: cast_nullable_to_non_nullable
as String?,coverTitle: freezed == coverTitle ? _self.coverTitle : coverTitle // ignore: cast_nullable_to_non_nullable
as String?,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as Repeat,repeatDays: null == repeatDays ? _self._repeatDays : repeatDays // ignore: cast_nullable_to_non_nullable
as List<int>,repeatCount: null == repeatCount ? _self.repeatCount : repeatCount // ignore: cast_nullable_to_non_nullable
as int,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,restrictLevel: null == restrictLevel ? _self.restrictLevel : restrictLevel // ignore: cast_nullable_to_non_nullable
as bool,levelAsNumbers: null == levelAsNumbers ? _self.levelAsNumbers : levelAsNumbers // ignore: cast_nullable_to_non_nullable
as bool,ranked: null == ranked ? _self.ranked : ranked // ignore: cast_nullable_to_non_nullable
as bool,playersPayFee: null == playersPayFee ? _self.playersPayFee : playersPayFee // ignore: cast_nullable_to_non_nullable
as bool,hostInvitesOnly: null == hostInvitesOnly ? _self.hostInvitesOnly : hostInvitesOnly // ignore: cast_nullable_to_non_nullable
as bool,listPublicly: null == listPublicly ? _self.listPublicly : listPublicly // ignore: cast_nullable_to_non_nullable
as bool,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,teamEntry: null == teamEntry ? _self.teamEntry : teamEntry // ignore: cast_nullable_to_non_nullable
as bool,divisionKeys: null == divisionKeys ? _self._divisionKeys : divisionKeys // ignore: cast_nullable_to_non_nullable
as List<String>,ageDivisions: null == ageDivisions ? _self._ageDivisions : ageDivisions // ignore: cast_nullable_to_non_nullable
as List<String>,minEntries: null == minEntries ? _self.minEntries : minEntries // ignore: cast_nullable_to_non_nullable
as int,verifiedOnly: null == verifiedOnly ? _self.verifiedOnly : verifiedOnly // ignore: cast_nullable_to_non_nullable
as bool,matchCheckIn: null == matchCheckIn ? _self.matchCheckIn : matchCheckIn // ignore: cast_nullable_to_non_nullable
as bool,waitlistWhenFull: null == waitlistWhenFull ? _self.waitlistWhenFull : waitlistWhenFull // ignore: cast_nullable_to_non_nullable
as bool,linkedId: freezed == linkedId ? _self.linkedId : linkedId // ignore: cast_nullable_to_non_nullable
as String?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,editingId: freezed == editingId ? _self.editingId : editingId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ActivityDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueCopyWith<$Res>? get venue {
    if (_self.venue == null) {
    return null;
  }

  return $VenueCopyWith<$Res>(_self.venue!, (value) {
    return _then(_self.copyWith(venue: value));
  });
}
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CourtType {

 Sport get sport; int get count; int get offPeakCents; int get peakCents;/// "lights till 10 PM", "outdoor".
 String get note;
/// Create a copy of CourtType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourtTypeCopyWith<CourtType> get copyWith => _$CourtTypeCopyWithImpl<CourtType>(this as CourtType, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CourtType;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourtType&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.offPeakCents, _this.offPeakCents) || other.offPeakCents == _this.offPeakCents)&&(identical(other.peakCents, _this.peakCents) || other.peakCents == _this.peakCents)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as CourtType;
  return Object.hash(runtimeType,_this.sport,_this.count,_this.offPeakCents,_this.peakCents,_this.note);
}

@override
String toString() {
  final _this = this as CourtType;
  return 'CourtType(sport: ${_this.sport}, count: ${_this.count}, offPeakCents: ${_this.offPeakCents}, peakCents: ${_this.peakCents}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $CourtTypeCopyWith<$Res>  {
  factory $CourtTypeCopyWith(CourtType value, $Res Function(CourtType) _then) = _$CourtTypeCopyWithImpl;
@useResult
$Res call({
 Sport sport, int count, int offPeakCents, int peakCents, String note
});




}
/// @nodoc
class _$CourtTypeCopyWithImpl<$Res>
    implements $CourtTypeCopyWith<$Res> {
  _$CourtTypeCopyWithImpl(this._self, this._then);

  final CourtType _self;
  final $Res Function(CourtType) _then;

/// Create a copy of CourtType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sport = null,Object? count = null,Object? offPeakCents = null,Object? peakCents = null,Object? note = null,}) {
  return _then(CourtType(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,offPeakCents: null == offPeakCents ? _self.offPeakCents : offPeakCents // ignore: cast_nullable_to_non_nullable
as int,peakCents: null == peakCents ? _self.peakCents : peakCents // ignore: cast_nullable_to_non_nullable
as int,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CourtType].
extension CourtTypePatterns on CourtType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourtType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourtType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourtType value)  $default,){
final _that = this;
switch (_that) {
case _CourtType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourtType value)?  $default,){
final _that = this;
switch (_that) {
case _CourtType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Sport sport,  int count,  int offPeakCents,  int peakCents,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourtType() when $default != null:
return $default(_that.sport,_that.count,_that.offPeakCents,_that.peakCents,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Sport sport,  int count,  int offPeakCents,  int peakCents,  String note)  $default,) {final _that = this;
switch (_that) {
case _CourtType():
return $default(_that.sport,_that.count,_that.offPeakCents,_that.peakCents,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Sport sport,  int count,  int offPeakCents,  int peakCents,  String note)?  $default,) {final _that = this;
switch (_that) {
case _CourtType() when $default != null:
return $default(_that.sport,_that.count,_that.offPeakCents,_that.peakCents,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _CourtType implements CourtType {
  const _CourtType({required this.sport, required this.count, required this.offPeakCents, required this.peakCents, this.note = ''});
  

@override final  Sport sport;
@override final  int count;
@override final  int offPeakCents;
@override final  int peakCents;
/// "lights till 10 PM", "outdoor".
@override@JsonKey() final  String note;

/// Create a copy of CourtType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourtTypeCopyWith<_CourtType> get copyWith => __$CourtTypeCopyWithImpl<_CourtType>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourtType&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.count, count) || other.count == count)&&(identical(other.offPeakCents, offPeakCents) || other.offPeakCents == offPeakCents)&&(identical(other.peakCents, peakCents) || other.peakCents == peakCents)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sport,count,offPeakCents,peakCents,note);
}

@override
String toString() {
    return 'CourtType(sport: $sport, count: $count, offPeakCents: $offPeakCents, peakCents: $peakCents, note: $note)';
}


}

/// @nodoc
abstract mixin class _$CourtTypeCopyWith<$Res> implements $CourtTypeCopyWith<$Res> {
  factory _$CourtTypeCopyWith(_CourtType value, $Res Function(_CourtType) _then) = __$CourtTypeCopyWithImpl;
@override @useResult
$Res call({
 Sport sport, int count, int offPeakCents, int peakCents, String note
});




}
/// @nodoc
class __$CourtTypeCopyWithImpl<$Res>
    implements _$CourtTypeCopyWith<$Res> {
  __$CourtTypeCopyWithImpl(this._self, this._then);

  final _CourtType _self;
  final $Res Function(_CourtType) _then;

/// Create a copy of CourtType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sport = null,Object? count = null,Object? offPeakCents = null,Object? peakCents = null,Object? note = null,}) {
  return _then(_CourtType(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,offPeakCents: null == offPeakCents ? _self.offPeakCents : offPeakCents // ignore: cast_nullable_to_non_nullable
as int,peakCents: null == peakCents ? _self.peakCents : peakCents // ignore: cast_nullable_to_non_nullable
as int,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$VenueDetail {

 String get id; String get name; String get address; String get distance; int get opensHour; int get closesHour; List<CourtType> get courts; List<String> get amenities; bool get verified; double? get rating; int get ratingCount; bool get autoCheckIn; int get color; int get ink;
/// Create a copy of VenueDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueDetailCopyWith<VenueDetail> get copyWith => _$VenueDetailCopyWithImpl<VenueDetail>(this as VenueDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VenueDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.distance, _this.distance) || other.distance == _this.distance)&&(identical(other.opensHour, _this.opensHour) || other.opensHour == _this.opensHour)&&(identical(other.closesHour, _this.closesHour) || other.closesHour == _this.closesHour)&&const DeepCollectionEquality().equals(other.courts, _this.courts)&&const DeepCollectionEquality().equals(other.amenities, _this.amenities)&&(identical(other.verified, _this.verified) || other.verified == _this.verified)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.autoCheckIn, _this.autoCheckIn) || other.autoCheckIn == _this.autoCheckIn)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.ink, _this.ink) || other.ink == _this.ink));
}


@override
int get hashCode {
  final _this = this as VenueDetail;
  return Object.hash(runtimeType,_this.id,_this.name,_this.address,_this.distance,_this.opensHour,_this.closesHour,const DeepCollectionEquality().hash(_this.courts),const DeepCollectionEquality().hash(_this.amenities),_this.verified,_this.rating,_this.ratingCount,_this.autoCheckIn,_this.color,_this.ink);
}

@override
String toString() {
  final _this = this as VenueDetail;
  return 'VenueDetail(id: ${_this.id}, name: ${_this.name}, address: ${_this.address}, distance: ${_this.distance}, opensHour: ${_this.opensHour}, closesHour: ${_this.closesHour}, courts: ${_this.courts}, amenities: ${_this.amenities}, verified: ${_this.verified}, rating: ${_this.rating}, ratingCount: ${_this.ratingCount}, autoCheckIn: ${_this.autoCheckIn}, color: ${_this.color}, ink: ${_this.ink})';
}


}

/// @nodoc
abstract mixin class $VenueDetailCopyWith<$Res>  {
  factory $VenueDetailCopyWith(VenueDetail value, $Res Function(VenueDetail) _then) = _$VenueDetailCopyWithImpl;
@useResult
$Res call({
 String id, String name, String address, String distance, int opensHour, int closesHour, List<CourtType> courts, List<String> amenities, bool verified, double? rating, int ratingCount, bool autoCheckIn, int color, int ink
});




}
/// @nodoc
class _$VenueDetailCopyWithImpl<$Res>
    implements $VenueDetailCopyWith<$Res> {
  _$VenueDetailCopyWithImpl(this._self, this._then);

  final VenueDetail _self;
  final $Res Function(VenueDetail) _then;

/// Create a copy of VenueDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = null,Object? distance = null,Object? opensHour = null,Object? closesHour = null,Object? courts = null,Object? amenities = null,Object? verified = null,Object? rating = freezed,Object? ratingCount = null,Object? autoCheckIn = null,Object? color = null,Object? ink = null,}) {
  return _then(VenueDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,opensHour: null == opensHour ? _self.opensHour : opensHour // ignore: cast_nullable_to_non_nullable
as int,closesHour: null == closesHour ? _self.closesHour : closesHour // ignore: cast_nullable_to_non_nullable
as int,courts: null == courts ? _self.courts : courts // ignore: cast_nullable_to_non_nullable
as List<CourtType>,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,autoCheckIn: null == autoCheckIn ? _self.autoCheckIn : autoCheckIn // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueDetail].
extension VenueDetailPatterns on VenueDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueDetail value)  $default,){
final _that = this;
switch (_that) {
case _VenueDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueDetail value)?  $default,){
final _that = this;
switch (_that) {
case _VenueDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String distance,  int opensHour,  int closesHour,  List<CourtType> courts,  List<String> amenities,  bool verified,  double? rating,  int ratingCount,  bool autoCheckIn,  int color,  int ink)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueDetail() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.distance,_that.opensHour,_that.closesHour,_that.courts,_that.amenities,_that.verified,_that.rating,_that.ratingCount,_that.autoCheckIn,_that.color,_that.ink);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String address,  String distance,  int opensHour,  int closesHour,  List<CourtType> courts,  List<String> amenities,  bool verified,  double? rating,  int ratingCount,  bool autoCheckIn,  int color,  int ink)  $default,) {final _that = this;
switch (_that) {
case _VenueDetail():
return $default(_that.id,_that.name,_that.address,_that.distance,_that.opensHour,_that.closesHour,_that.courts,_that.amenities,_that.verified,_that.rating,_that.ratingCount,_that.autoCheckIn,_that.color,_that.ink);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String address,  String distance,  int opensHour,  int closesHour,  List<CourtType> courts,  List<String> amenities,  bool verified,  double? rating,  int ratingCount,  bool autoCheckIn,  int color,  int ink)?  $default,) {final _that = this;
switch (_that) {
case _VenueDetail() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.distance,_that.opensHour,_that.closesHour,_that.courts,_that.amenities,_that.verified,_that.rating,_that.ratingCount,_that.autoCheckIn,_that.color,_that.ink);case _:
  return null;

}
}

}

/// @nodoc


class _VenueDetail extends VenueDetail {
  const _VenueDetail({required this.id, required this.name, required this.address, this.distance = '', this.opensHour = 7, this.closesHour = 23,  List<CourtType> courts = const [],  List<String> amenities = const [], this.verified = false, this.rating, this.ratingCount = 0, this.autoCheckIn = false, this.color = 0xFF16181B, this.ink = 0xFFC6FF00}): _courts = courts,_amenities = amenities,super._();
  

@override final  String id;
@override final  String name;
@override final  String address;
@override@JsonKey() final  String distance;
@override@JsonKey() final  int opensHour;
@override@JsonKey() final  int closesHour;
 final  List<CourtType> _courts;
@override@JsonKey() List<CourtType> get courts {
  if (_courts is EqualUnmodifiableListView) return _courts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courts);
}

 final  List<String> _amenities;
@override@JsonKey() List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

@override@JsonKey() final  bool verified;
@override final  double? rating;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  bool autoCheckIn;
@override@JsonKey() final  int color;
@override@JsonKey() final  int ink;

/// Create a copy of VenueDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueDetailCopyWith<_VenueDetail> get copyWith => __$VenueDetailCopyWithImpl<_VenueDetail>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.opensHour, opensHour) || other.opensHour == opensHour)&&(identical(other.closesHour, closesHour) || other.closesHour == closesHour)&&const DeepCollectionEquality().equals(other.courts, _courts)&&const DeepCollectionEquality().equals(other.amenities, _amenities)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.autoCheckIn, autoCheckIn) || other.autoCheckIn == autoCheckIn)&&(identical(other.color, color) || other.color == color)&&(identical(other.ink, ink) || other.ink == ink));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,address,distance,opensHour,closesHour,const DeepCollectionEquality().hash(_courts),const DeepCollectionEquality().hash(_amenities),verified,rating,ratingCount,autoCheckIn,color,ink);
}

@override
String toString() {
    return 'VenueDetail(id: $id, name: $name, address: $address, distance: $distance, opensHour: $opensHour, closesHour: $closesHour, courts: $courts, amenities: $amenities, verified: $verified, rating: $rating, ratingCount: $ratingCount, autoCheckIn: $autoCheckIn, color: $color, ink: $ink)';
}


}

/// @nodoc
abstract mixin class _$VenueDetailCopyWith<$Res> implements $VenueDetailCopyWith<$Res> {
  factory _$VenueDetailCopyWith(_VenueDetail value, $Res Function(_VenueDetail) _then) = __$VenueDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String address, String distance, int opensHour, int closesHour, List<CourtType> courts, List<String> amenities, bool verified, double? rating, int ratingCount, bool autoCheckIn, int color, int ink
});




}
/// @nodoc
class __$VenueDetailCopyWithImpl<$Res>
    implements _$VenueDetailCopyWith<$Res> {
  __$VenueDetailCopyWithImpl(this._self, this._then);

  final _VenueDetail _self;
  final $Res Function(_VenueDetail) _then;

/// Create a copy of VenueDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = null,Object? distance = null,Object? opensHour = null,Object? closesHour = null,Object? courts = null,Object? amenities = null,Object? verified = null,Object? rating = freezed,Object? ratingCount = null,Object? autoCheckIn = null,Object? color = null,Object? ink = null,}) {
  return _then(_VenueDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,opensHour: null == opensHour ? _self.opensHour : opensHour // ignore: cast_nullable_to_non_nullable
as int,closesHour: null == closesHour ? _self.closesHour : closesHour // ignore: cast_nullable_to_non_nullable
as int,courts: null == courts ? _self._courts : courts // ignore: cast_nullable_to_non_nullable
as List<CourtType>,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,autoCheckIn: null == autoCheckIn ? _self.autoCheckIn : autoCheckIn // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$CourtSlot {

 DateTime get start; int get rateCents; bool get free;
/// Create a copy of CourtSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourtSlotCopyWith<CourtSlot> get copyWith => _$CourtSlotCopyWithImpl<CourtSlot>(this as CourtSlot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CourtSlot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourtSlot&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.rateCents, _this.rateCents) || other.rateCents == _this.rateCents)&&(identical(other.free, _this.free) || other.free == _this.free));
}


@override
int get hashCode {
  final _this = this as CourtSlot;
  return Object.hash(runtimeType,_this.start,_this.rateCents,_this.free);
}

@override
String toString() {
  final _this = this as CourtSlot;
  return 'CourtSlot(start: ${_this.start}, rateCents: ${_this.rateCents}, free: ${_this.free})';
}


}

/// @nodoc
abstract mixin class $CourtSlotCopyWith<$Res>  {
  factory $CourtSlotCopyWith(CourtSlot value, $Res Function(CourtSlot) _then) = _$CourtSlotCopyWithImpl;
@useResult
$Res call({
 DateTime start, int rateCents, bool free
});




}
/// @nodoc
class _$CourtSlotCopyWithImpl<$Res>
    implements $CourtSlotCopyWith<$Res> {
  _$CourtSlotCopyWithImpl(this._self, this._then);

  final CourtSlot _self;
  final $Res Function(CourtSlot) _then;

/// Create a copy of CourtSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? rateCents = null,Object? free = null,}) {
  return _then(CourtSlot(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,rateCents: null == rateCents ? _self.rateCents : rateCents // ignore: cast_nullable_to_non_nullable
as int,free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CourtSlot].
extension CourtSlotPatterns on CourtSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourtSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourtSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourtSlot value)  $default,){
final _that = this;
switch (_that) {
case _CourtSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourtSlot value)?  $default,){
final _that = this;
switch (_that) {
case _CourtSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime start,  int rateCents,  bool free)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourtSlot() when $default != null:
return $default(_that.start,_that.rateCents,_that.free);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime start,  int rateCents,  bool free)  $default,) {final _that = this;
switch (_that) {
case _CourtSlot():
return $default(_that.start,_that.rateCents,_that.free);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime start,  int rateCents,  bool free)?  $default,) {final _that = this;
switch (_that) {
case _CourtSlot() when $default != null:
return $default(_that.start,_that.rateCents,_that.free);case _:
  return null;

}
}

}

/// @nodoc


class _CourtSlot extends CourtSlot {
  const _CourtSlot({required this.start, required this.rateCents, required this.free}): super._();
  

@override final  DateTime start;
@override final  int rateCents;
@override final  bool free;

/// Create a copy of CourtSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourtSlotCopyWith<_CourtSlot> get copyWith => __$CourtSlotCopyWithImpl<_CourtSlot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourtSlot&&(identical(other.start, start) || other.start == start)&&(identical(other.rateCents, rateCents) || other.rateCents == rateCents)&&(identical(other.free, free) || other.free == free));
}


@override
int get hashCode {
    return Object.hash(runtimeType,start,rateCents,free);
}

@override
String toString() {
    return 'CourtSlot(start: $start, rateCents: $rateCents, free: $free)';
}


}

/// @nodoc
abstract mixin class _$CourtSlotCopyWith<$Res> implements $CourtSlotCopyWith<$Res> {
  factory _$CourtSlotCopyWith(_CourtSlot value, $Res Function(_CourtSlot) _then) = __$CourtSlotCopyWithImpl;
@override @useResult
$Res call({
 DateTime start, int rateCents, bool free
});




}
/// @nodoc
class __$CourtSlotCopyWithImpl<$Res>
    implements _$CourtSlotCopyWith<$Res> {
  __$CourtSlotCopyWithImpl(this._self, this._then);

  final _CourtSlot _self;
  final $Res Function(_CourtSlot) _then;

/// Create a copy of CourtSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? rateCents = null,Object? free = null,}) {
  return _then(_CourtSlot(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,rateCents: null == rateCents ? _self.rateCents : rateCents // ignore: cast_nullable_to_non_nullable
as int,free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CourtBooking {

 String get id; String get venueId; String get venueName; String get venueAddress; Sport get sport; String get court; DateTime get start; DateTime get end; int get courtCents; int get feeCents;/// Opens the court door, from 10 minutes before.
 String get doorCode; String get code; BookingStatus get status; int get refundCents;
/// Create a copy of CourtBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourtBookingCopyWith<CourtBooking> get copyWith => _$CourtBookingCopyWithImpl<CourtBooking>(this as CourtBooking, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CourtBooking;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourtBooking&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.venueId, _this.venueId) || other.venueId == _this.venueId)&&(identical(other.venueName, _this.venueName) || other.venueName == _this.venueName)&&(identical(other.venueAddress, _this.venueAddress) || other.venueAddress == _this.venueAddress)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.court, _this.court) || other.court == _this.court)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.courtCents, _this.courtCents) || other.courtCents == _this.courtCents)&&(identical(other.feeCents, _this.feeCents) || other.feeCents == _this.feeCents)&&(identical(other.doorCode, _this.doorCode) || other.doorCode == _this.doorCode)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.refundCents, _this.refundCents) || other.refundCents == _this.refundCents));
}


@override
int get hashCode {
  final _this = this as CourtBooking;
  return Object.hash(runtimeType,_this.id,_this.venueId,_this.venueName,_this.venueAddress,_this.sport,_this.court,_this.start,_this.end,_this.courtCents,_this.feeCents,_this.doorCode,_this.code,_this.status,_this.refundCents);
}

@override
String toString() {
  final _this = this as CourtBooking;
  return 'CourtBooking(id: ${_this.id}, venueId: ${_this.venueId}, venueName: ${_this.venueName}, venueAddress: ${_this.venueAddress}, sport: ${_this.sport}, court: ${_this.court}, start: ${_this.start}, end: ${_this.end}, courtCents: ${_this.courtCents}, feeCents: ${_this.feeCents}, doorCode: ${_this.doorCode}, code: ${_this.code}, status: ${_this.status}, refundCents: ${_this.refundCents})';
}


}

/// @nodoc
abstract mixin class $CourtBookingCopyWith<$Res>  {
  factory $CourtBookingCopyWith(CourtBooking value, $Res Function(CourtBooking) _then) = _$CourtBookingCopyWithImpl;
@useResult
$Res call({
 String id, String venueId, String venueName, String venueAddress, Sport sport, String court, DateTime start, DateTime end, int courtCents, int feeCents, String doorCode, String code, BookingStatus status, int refundCents
});




}
/// @nodoc
class _$CourtBookingCopyWithImpl<$Res>
    implements $CourtBookingCopyWith<$Res> {
  _$CourtBookingCopyWithImpl(this._self, this._then);

  final CourtBooking _self;
  final $Res Function(CourtBooking) _then;

/// Create a copy of CourtBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? venueId = null,Object? venueName = null,Object? venueAddress = null,Object? sport = null,Object? court = null,Object? start = null,Object? end = null,Object? courtCents = null,Object? feeCents = null,Object? doorCode = null,Object? code = null,Object? status = null,Object? refundCents = null,}) {
  return _then(CourtBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,venueName: null == venueName ? _self.venueName : venueName // ignore: cast_nullable_to_non_nullable
as String,venueAddress: null == venueAddress ? _self.venueAddress : venueAddress // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,court: null == court ? _self.court : court // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,courtCents: null == courtCents ? _self.courtCents : courtCents // ignore: cast_nullable_to_non_nullable
as int,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,doorCode: null == doorCode ? _self.doorCode : doorCode // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,refundCents: null == refundCents ? _self.refundCents : refundCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CourtBooking].
extension CourtBookingPatterns on CourtBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourtBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourtBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourtBooking value)  $default,){
final _that = this;
switch (_that) {
case _CourtBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourtBooking value)?  $default,){
final _that = this;
switch (_that) {
case _CourtBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String venueId,  String venueName,  String venueAddress,  Sport sport,  String court,  DateTime start,  DateTime end,  int courtCents,  int feeCents,  String doorCode,  String code,  BookingStatus status,  int refundCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourtBooking() when $default != null:
return $default(_that.id,_that.venueId,_that.venueName,_that.venueAddress,_that.sport,_that.court,_that.start,_that.end,_that.courtCents,_that.feeCents,_that.doorCode,_that.code,_that.status,_that.refundCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String venueId,  String venueName,  String venueAddress,  Sport sport,  String court,  DateTime start,  DateTime end,  int courtCents,  int feeCents,  String doorCode,  String code,  BookingStatus status,  int refundCents)  $default,) {final _that = this;
switch (_that) {
case _CourtBooking():
return $default(_that.id,_that.venueId,_that.venueName,_that.venueAddress,_that.sport,_that.court,_that.start,_that.end,_that.courtCents,_that.feeCents,_that.doorCode,_that.code,_that.status,_that.refundCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String venueId,  String venueName,  String venueAddress,  Sport sport,  String court,  DateTime start,  DateTime end,  int courtCents,  int feeCents,  String doorCode,  String code,  BookingStatus status,  int refundCents)?  $default,) {final _that = this;
switch (_that) {
case _CourtBooking() when $default != null:
return $default(_that.id,_that.venueId,_that.venueName,_that.venueAddress,_that.sport,_that.court,_that.start,_that.end,_that.courtCents,_that.feeCents,_that.doorCode,_that.code,_that.status,_that.refundCents);case _:
  return null;

}
}

}

/// @nodoc


class _CourtBooking extends CourtBooking {
  const _CourtBooking({required this.id, required this.venueId, required this.venueName, required this.venueAddress, required this.sport, required this.court, required this.start, required this.end, required this.courtCents, required this.feeCents, required this.doorCode, required this.code, this.status = BookingStatus.confirmed, this.refundCents = 0}): super._();
  

@override final  String id;
@override final  String venueId;
@override final  String venueName;
@override final  String venueAddress;
@override final  Sport sport;
@override final  String court;
@override final  DateTime start;
@override final  DateTime end;
@override final  int courtCents;
@override final  int feeCents;
/// Opens the court door, from 10 minutes before.
@override final  String doorCode;
@override final  String code;
@override@JsonKey() final  BookingStatus status;
@override@JsonKey() final  int refundCents;

/// Create a copy of CourtBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourtBookingCopyWith<_CourtBooking> get copyWith => __$CourtBookingCopyWithImpl<_CourtBooking>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourtBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.venueName, venueName) || other.venueName == venueName)&&(identical(other.venueAddress, venueAddress) || other.venueAddress == venueAddress)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.court, court) || other.court == court)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.courtCents, courtCents) || other.courtCents == courtCents)&&(identical(other.feeCents, feeCents) || other.feeCents == feeCents)&&(identical(other.doorCode, doorCode) || other.doorCode == doorCode)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.refundCents, refundCents) || other.refundCents == refundCents));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,venueId,venueName,venueAddress,sport,court,start,end,courtCents,feeCents,doorCode,code,status,refundCents);
}

@override
String toString() {
    return 'CourtBooking(id: $id, venueId: $venueId, venueName: $venueName, venueAddress: $venueAddress, sport: $sport, court: $court, start: $start, end: $end, courtCents: $courtCents, feeCents: $feeCents, doorCode: $doorCode, code: $code, status: $status, refundCents: $refundCents)';
}


}

/// @nodoc
abstract mixin class _$CourtBookingCopyWith<$Res> implements $CourtBookingCopyWith<$Res> {
  factory _$CourtBookingCopyWith(_CourtBooking value, $Res Function(_CourtBooking) _then) = __$CourtBookingCopyWithImpl;
@override @useResult
$Res call({
 String id, String venueId, String venueName, String venueAddress, Sport sport, String court, DateTime start, DateTime end, int courtCents, int feeCents, String doorCode, String code, BookingStatus status, int refundCents
});




}
/// @nodoc
class __$CourtBookingCopyWithImpl<$Res>
    implements _$CourtBookingCopyWith<$Res> {
  __$CourtBookingCopyWithImpl(this._self, this._then);

  final _CourtBooking _self;
  final $Res Function(_CourtBooking) _then;

/// Create a copy of CourtBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? venueId = null,Object? venueName = null,Object? venueAddress = null,Object? sport = null,Object? court = null,Object? start = null,Object? end = null,Object? courtCents = null,Object? feeCents = null,Object? doorCode = null,Object? code = null,Object? status = null,Object? refundCents = null,}) {
  return _then(_CourtBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,venueName: null == venueName ? _self.venueName : venueName // ignore: cast_nullable_to_non_nullable
as String,venueAddress: null == venueAddress ? _self.venueAddress : venueAddress // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,court: null == court ? _self.court : court // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,courtCents: null == courtCents ? _self.courtCents : courtCents // ignore: cast_nullable_to_non_nullable
as int,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,doorCode: null == doorCode ? _self.doorCode : doorCode // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,refundCents: null == refundCents ? _self.refundCents : refundCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

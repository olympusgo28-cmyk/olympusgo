// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discover_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoverFilter {

 Sport? get sport; DateTime? get day;/// Start of the time of day, as an hour, with [hourTo].
 int? get hourFrom; int? get hourTo; double? get maxKm;
/// Create a copy of DiscoverFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoverFilterCopyWith<DiscoverFilter> get copyWith => _$DiscoverFilterCopyWithImpl<DiscoverFilter>(this as DiscoverFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscoverFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoverFilter&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.day, _this.day) || other.day == _this.day)&&(identical(other.hourFrom, _this.hourFrom) || other.hourFrom == _this.hourFrom)&&(identical(other.hourTo, _this.hourTo) || other.hourTo == _this.hourTo)&&(identical(other.maxKm, _this.maxKm) || other.maxKm == _this.maxKm));
}


@override
int get hashCode {
  final _this = this as DiscoverFilter;
  return Object.hash(runtimeType,_this.sport,_this.day,_this.hourFrom,_this.hourTo,_this.maxKm);
}

@override
String toString() {
  final _this = this as DiscoverFilter;
  return 'DiscoverFilter(sport: ${_this.sport}, day: ${_this.day}, hourFrom: ${_this.hourFrom}, hourTo: ${_this.hourTo}, maxKm: ${_this.maxKm})';
}


}

/// @nodoc
abstract mixin class $DiscoverFilterCopyWith<$Res>  {
  factory $DiscoverFilterCopyWith(DiscoverFilter value, $Res Function(DiscoverFilter) _then) = _$DiscoverFilterCopyWithImpl;
@useResult
$Res call({
 Sport? sport, DateTime? day, int? hourFrom, int? hourTo, double? maxKm
});




}
/// @nodoc
class _$DiscoverFilterCopyWithImpl<$Res>
    implements $DiscoverFilterCopyWith<$Res> {
  _$DiscoverFilterCopyWithImpl(this._self, this._then);

  final DiscoverFilter _self;
  final $Res Function(DiscoverFilter) _then;

/// Create a copy of DiscoverFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sport = freezed,Object? day = freezed,Object? hourFrom = freezed,Object? hourTo = freezed,Object? maxKm = freezed,}) {
  return _then(DiscoverFilter(
sport: freezed == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport?,day: freezed == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime?,hourFrom: freezed == hourFrom ? _self.hourFrom : hourFrom // ignore: cast_nullable_to_non_nullable
as int?,hourTo: freezed == hourTo ? _self.hourTo : hourTo // ignore: cast_nullable_to_non_nullable
as int?,maxKm: freezed == maxKm ? _self.maxKm : maxKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoverFilter].
extension DiscoverFilterPatterns on DiscoverFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoverFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoverFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoverFilter value)  $default,){
final _that = this;
switch (_that) {
case _DiscoverFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoverFilter value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoverFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Sport? sport,  DateTime? day,  int? hourFrom,  int? hourTo,  double? maxKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoverFilter() when $default != null:
return $default(_that.sport,_that.day,_that.hourFrom,_that.hourTo,_that.maxKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Sport? sport,  DateTime? day,  int? hourFrom,  int? hourTo,  double? maxKm)  $default,) {final _that = this;
switch (_that) {
case _DiscoverFilter():
return $default(_that.sport,_that.day,_that.hourFrom,_that.hourTo,_that.maxKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Sport? sport,  DateTime? day,  int? hourFrom,  int? hourTo,  double? maxKm)?  $default,) {final _that = this;
switch (_that) {
case _DiscoverFilter() when $default != null:
return $default(_that.sport,_that.day,_that.hourFrom,_that.hourTo,_that.maxKm);case _:
  return null;

}
}

}

/// @nodoc


class _DiscoverFilter implements DiscoverFilter {
  const _DiscoverFilter({this.sport, this.day, this.hourFrom, this.hourTo, this.maxKm});
  

@override final  Sport? sport;
@override final  DateTime? day;
/// Start of the time of day, as an hour, with [hourTo].
@override final  int? hourFrom;
@override final  int? hourTo;
@override final  double? maxKm;

/// Create a copy of DiscoverFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoverFilterCopyWith<_DiscoverFilter> get copyWith => __$DiscoverFilterCopyWithImpl<_DiscoverFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoverFilter&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.day, day) || other.day == day)&&(identical(other.hourFrom, hourFrom) || other.hourFrom == hourFrom)&&(identical(other.hourTo, hourTo) || other.hourTo == hourTo)&&(identical(other.maxKm, maxKm) || other.maxKm == maxKm));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sport,day,hourFrom,hourTo,maxKm);
}

@override
String toString() {
    return 'DiscoverFilter(sport: $sport, day: $day, hourFrom: $hourFrom, hourTo: $hourTo, maxKm: $maxKm)';
}


}

/// @nodoc
abstract mixin class _$DiscoverFilterCopyWith<$Res> implements $DiscoverFilterCopyWith<$Res> {
  factory _$DiscoverFilterCopyWith(_DiscoverFilter value, $Res Function(_DiscoverFilter) _then) = __$DiscoverFilterCopyWithImpl;
@override @useResult
$Res call({
 Sport? sport, DateTime? day, int? hourFrom, int? hourTo, double? maxKm
});




}
/// @nodoc
class __$DiscoverFilterCopyWithImpl<$Res>
    implements _$DiscoverFilterCopyWith<$Res> {
  __$DiscoverFilterCopyWithImpl(this._self, this._then);

  final _DiscoverFilter _self;
  final $Res Function(_DiscoverFilter) _then;

/// Create a copy of DiscoverFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sport = freezed,Object? day = freezed,Object? hourFrom = freezed,Object? hourTo = freezed,Object? maxKm = freezed,}) {
  return _then(_DiscoverFilter(
sport: freezed == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport?,day: freezed == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime?,hourFrom: freezed == hourFrom ? _self.hourFrom : hourFrom // ignore: cast_nullable_to_non_nullable
as int?,hourTo: freezed == hourTo ? _self.hourTo : hourTo // ignore: cast_nullable_to_non_nullable
as int?,maxKm: freezed == maxKm ? _self.maxKm : maxKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$FoundSession {

 Activity get activity; double? get km; double? get latitude; double? get longitude; bool get fitsMe;
/// Create a copy of FoundSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoundSessionCopyWith<FoundSession> get copyWith => _$FoundSessionCopyWithImpl<FoundSession>(this as FoundSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FoundSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoundSession&&(identical(other.activity, _this.activity) || other.activity == _this.activity)&&(identical(other.km, _this.km) || other.km == _this.km)&&(identical(other.latitude, _this.latitude) || other.latitude == _this.latitude)&&(identical(other.longitude, _this.longitude) || other.longitude == _this.longitude)&&(identical(other.fitsMe, _this.fitsMe) || other.fitsMe == _this.fitsMe));
}


@override
int get hashCode {
  final _this = this as FoundSession;
  return Object.hash(runtimeType,_this.activity,_this.km,_this.latitude,_this.longitude,_this.fitsMe);
}

@override
String toString() {
  final _this = this as FoundSession;
  return 'FoundSession(activity: ${_this.activity}, km: ${_this.km}, latitude: ${_this.latitude}, longitude: ${_this.longitude}, fitsMe: ${_this.fitsMe})';
}


}

/// @nodoc
abstract mixin class $FoundSessionCopyWith<$Res>  {
  factory $FoundSessionCopyWith(FoundSession value, $Res Function(FoundSession) _then) = _$FoundSessionCopyWithImpl;
@useResult
$Res call({
 Activity activity, double? km, double? latitude, double? longitude, bool fitsMe
});


$ActivityCopyWith<$Res> get activity;

}
/// @nodoc
class _$FoundSessionCopyWithImpl<$Res>
    implements $FoundSessionCopyWith<$Res> {
  _$FoundSessionCopyWithImpl(this._self, this._then);

  final FoundSession _self;
  final $Res Function(FoundSession) _then;

/// Create a copy of FoundSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activity = null,Object? km = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? fitsMe = null,}) {
  return _then(FoundSession(
activity: null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as Activity,km: freezed == km ? _self.km : km // ignore: cast_nullable_to_non_nullable
as double?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,fitsMe: null == fitsMe ? _self.fitsMe : fitsMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of FoundSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityCopyWith<$Res> get activity {
  
  return $ActivityCopyWith<$Res>(_self.activity, (value) {
    return _then(_self.copyWith(activity: value));
  });
}
}


/// Adds pattern-matching-related methods to [FoundSession].
extension FoundSessionPatterns on FoundSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoundSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoundSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoundSession value)  $default,){
final _that = this;
switch (_that) {
case _FoundSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoundSession value)?  $default,){
final _that = this;
switch (_that) {
case _FoundSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Activity activity,  double? km,  double? latitude,  double? longitude,  bool fitsMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoundSession() when $default != null:
return $default(_that.activity,_that.km,_that.latitude,_that.longitude,_that.fitsMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Activity activity,  double? km,  double? latitude,  double? longitude,  bool fitsMe)  $default,) {final _that = this;
switch (_that) {
case _FoundSession():
return $default(_that.activity,_that.km,_that.latitude,_that.longitude,_that.fitsMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Activity activity,  double? km,  double? latitude,  double? longitude,  bool fitsMe)?  $default,) {final _that = this;
switch (_that) {
case _FoundSession() when $default != null:
return $default(_that.activity,_that.km,_that.latitude,_that.longitude,_that.fitsMe);case _:
  return null;

}
}

}

/// @nodoc


class _FoundSession implements FoundSession {
  const _FoundSession({required this.activity, this.km, this.latitude, this.longitude, this.fitsMe = false});
  

@override final  Activity activity;
@override final  double? km;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey() final  bool fitsMe;

/// Create a copy of FoundSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoundSessionCopyWith<_FoundSession> get copyWith => __$FoundSessionCopyWithImpl<_FoundSession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoundSession&&(identical(other.activity, activity) || other.activity == activity)&&(identical(other.km, km) || other.km == km)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.fitsMe, fitsMe) || other.fitsMe == fitsMe));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activity,km,latitude,longitude,fitsMe);
}

@override
String toString() {
    return 'FoundSession(activity: $activity, km: $km, latitude: $latitude, longitude: $longitude, fitsMe: $fitsMe)';
}


}

/// @nodoc
abstract mixin class _$FoundSessionCopyWith<$Res> implements $FoundSessionCopyWith<$Res> {
  factory _$FoundSessionCopyWith(_FoundSession value, $Res Function(_FoundSession) _then) = __$FoundSessionCopyWithImpl;
@override @useResult
$Res call({
 Activity activity, double? km, double? latitude, double? longitude, bool fitsMe
});


@override $ActivityCopyWith<$Res> get activity;

}
/// @nodoc
class __$FoundSessionCopyWithImpl<$Res>
    implements _$FoundSessionCopyWith<$Res> {
  __$FoundSessionCopyWithImpl(this._self, this._then);

  final _FoundSession _self;
  final $Res Function(_FoundSession) _then;

/// Create a copy of FoundSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activity = null,Object? km = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? fitsMe = null,}) {
  return _then(_FoundSession(
activity: null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as Activity,km: freezed == km ? _self.km : km // ignore: cast_nullable_to_non_nullable
as double?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,fitsMe: null == fitsMe ? _self.fitsMe : fitsMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of FoundSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityCopyWith<$Res> get activity {
  
  return $ActivityCopyWith<$Res>(_self.activity, (value) {
    return _then(_self.copyWith(activity: value));
  });
}
}

// dart format on

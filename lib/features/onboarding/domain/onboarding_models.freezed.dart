// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SportSkill {

 Sport get sport; double get level; double get playMin; double get playMax;
/// Create a copy of SportSkill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SportSkillCopyWith<SportSkill> get copyWith => _$SportSkillCopyWithImpl<SportSkill>(this as SportSkill, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SportSkill;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SportSkill&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.playMin, _this.playMin) || other.playMin == _this.playMin)&&(identical(other.playMax, _this.playMax) || other.playMax == _this.playMax));
}


@override
int get hashCode {
  final _this = this as SportSkill;
  return Object.hash(runtimeType,_this.sport,_this.level,_this.playMin,_this.playMax);
}

@override
String toString() {
  final _this = this as SportSkill;
  return 'SportSkill(sport: ${_this.sport}, level: ${_this.level}, playMin: ${_this.playMin}, playMax: ${_this.playMax})';
}


}

/// @nodoc
abstract mixin class $SportSkillCopyWith<$Res>  {
  factory $SportSkillCopyWith(SportSkill value, $Res Function(SportSkill) _then) = _$SportSkillCopyWithImpl;
@useResult
$Res call({
 Sport sport, double level, double playMin, double playMax
});




}
/// @nodoc
class _$SportSkillCopyWithImpl<$Res>
    implements $SportSkillCopyWith<$Res> {
  _$SportSkillCopyWithImpl(this._self, this._then);

  final SportSkill _self;
  final $Res Function(SportSkill) _then;

/// Create a copy of SportSkill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sport = null,Object? level = null,Object? playMin = null,Object? playMax = null,}) {
  return _then(SportSkill(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as double,playMin: null == playMin ? _self.playMin : playMin // ignore: cast_nullable_to_non_nullable
as double,playMax: null == playMax ? _self.playMax : playMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SportSkill].
extension SportSkillPatterns on SportSkill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SportSkill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SportSkill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SportSkill value)  $default,){
final _that = this;
switch (_that) {
case _SportSkill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SportSkill value)?  $default,){
final _that = this;
switch (_that) {
case _SportSkill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Sport sport,  double level,  double playMin,  double playMax)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SportSkill() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Sport sport,  double level,  double playMin,  double playMax)  $default,) {final _that = this;
switch (_that) {
case _SportSkill():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Sport sport,  double level,  double playMin,  double playMax)?  $default,) {final _that = this;
switch (_that) {
case _SportSkill() when $default != null:
return $default(_that.sport,_that.level,_that.playMin,_that.playMax);case _:
  return null;

}
}

}

/// @nodoc


class _SportSkill extends SportSkill {
  const _SportSkill({required this.sport, this.level = 4.0, this.playMin = 3.0, this.playMax = 5.0}): super._();
  

@override final  Sport sport;
@override@JsonKey() final  double level;
@override@JsonKey() final  double playMin;
@override@JsonKey() final  double playMax;

/// Create a copy of SportSkill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SportSkillCopyWith<_SportSkill> get copyWith => __$SportSkillCopyWithImpl<_SportSkill>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SportSkill&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.level, level) || other.level == level)&&(identical(other.playMin, playMin) || other.playMin == playMin)&&(identical(other.playMax, playMax) || other.playMax == playMax));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sport,level,playMin,playMax);
}

@override
String toString() {
    return 'SportSkill(sport: $sport, level: $level, playMin: $playMin, playMax: $playMax)';
}


}

/// @nodoc
abstract mixin class _$SportSkillCopyWith<$Res> implements $SportSkillCopyWith<$Res> {
  factory _$SportSkillCopyWith(_SportSkill value, $Res Function(_SportSkill) _then) = __$SportSkillCopyWithImpl;
@override @useResult
$Res call({
 Sport sport, double level, double playMin, double playMax
});




}
/// @nodoc
class __$SportSkillCopyWithImpl<$Res>
    implements _$SportSkillCopyWith<$Res> {
  __$SportSkillCopyWithImpl(this._self, this._then);

  final _SportSkill _self;
  final $Res Function(_SportSkill) _then;

/// Create a copy of SportSkill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sport = null,Object? level = null,Object? playMin = null,Object? playMax = null,}) {
  return _then(_SportSkill(
sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as double,playMin: null == playMin ? _self.playMin : playMin // ignore: cast_nullable_to_non_nullable
as double,playMax: null == playMax ? _self.playMax : playMax // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$OnboardingDraft {

 String get fullName; DateTime? get birthday; Country get country; String? get parentEmail; List<Sport> get sports; Map<Sport, SportSkill> get skills; String get username; Country get phoneCountry; String get phoneNumber;
/// Create a copy of OnboardingDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingDraftCopyWith<OnboardingDraft> get copyWith => _$OnboardingDraftCopyWithImpl<OnboardingDraft>(this as OnboardingDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OnboardingDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingDraft&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.birthday, _this.birthday) || other.birthday == _this.birthday)&&(identical(other.country, _this.country) || other.country == _this.country)&&(identical(other.parentEmail, _this.parentEmail) || other.parentEmail == _this.parentEmail)&&const DeepCollectionEquality().equals(other.sports, _this.sports)&&const DeepCollectionEquality().equals(other.skills, _this.skills)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.phoneCountry, _this.phoneCountry) || other.phoneCountry == _this.phoneCountry)&&(identical(other.phoneNumber, _this.phoneNumber) || other.phoneNumber == _this.phoneNumber));
}


@override
int get hashCode {
  final _this = this as OnboardingDraft;
  return Object.hash(runtimeType,_this.fullName,_this.birthday,_this.country,_this.parentEmail,const DeepCollectionEquality().hash(_this.sports),const DeepCollectionEquality().hash(_this.skills),_this.username,_this.phoneCountry,_this.phoneNumber);
}

@override
String toString() {
  final _this = this as OnboardingDraft;
  return 'OnboardingDraft(fullName: ${_this.fullName}, birthday: ${_this.birthday}, country: ${_this.country}, parentEmail: ${_this.parentEmail}, sports: ${_this.sports}, skills: ${_this.skills}, username: ${_this.username}, phoneCountry: ${_this.phoneCountry}, phoneNumber: ${_this.phoneNumber})';
}


}

/// @nodoc
abstract mixin class $OnboardingDraftCopyWith<$Res>  {
  factory $OnboardingDraftCopyWith(OnboardingDraft value, $Res Function(OnboardingDraft) _then) = _$OnboardingDraftCopyWithImpl;
@useResult
$Res call({
 String fullName, DateTime? birthday, Country country, String? parentEmail, List<Sport> sports, Map<Sport, SportSkill> skills, String username, Country phoneCountry, String phoneNumber
});




}
/// @nodoc
class _$OnboardingDraftCopyWithImpl<$Res>
    implements $OnboardingDraftCopyWith<$Res> {
  _$OnboardingDraftCopyWithImpl(this._self, this._then);

  final OnboardingDraft _self;
  final $Res Function(OnboardingDraft) _then;

/// Create a copy of OnboardingDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? birthday = freezed,Object? country = null,Object? parentEmail = freezed,Object? sports = null,Object? skills = null,Object? username = null,Object? phoneCountry = null,Object? phoneNumber = null,}) {
  return _then(OnboardingDraft(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as Country,parentEmail: freezed == parentEmail ? _self.parentEmail : parentEmail // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self.sports : sports // ignore: cast_nullable_to_non_nullable
as List<Sport>,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as Map<Sport, SportSkill>,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,phoneCountry: null == phoneCountry ? _self.phoneCountry : phoneCountry // ignore: cast_nullable_to_non_nullable
as Country,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingDraft].
extension OnboardingDraftPatterns on OnboardingDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingDraft value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingDraft value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  DateTime? birthday,  Country country,  String? parentEmail,  List<Sport> sports,  Map<Sport, SportSkill> skills,  String username,  Country phoneCountry,  String phoneNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingDraft() when $default != null:
return $default(_that.fullName,_that.birthday,_that.country,_that.parentEmail,_that.sports,_that.skills,_that.username,_that.phoneCountry,_that.phoneNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  DateTime? birthday,  Country country,  String? parentEmail,  List<Sport> sports,  Map<Sport, SportSkill> skills,  String username,  Country phoneCountry,  String phoneNumber)  $default,) {final _that = this;
switch (_that) {
case _OnboardingDraft():
return $default(_that.fullName,_that.birthday,_that.country,_that.parentEmail,_that.sports,_that.skills,_that.username,_that.phoneCountry,_that.phoneNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  DateTime? birthday,  Country country,  String? parentEmail,  List<Sport> sports,  Map<Sport, SportSkill> skills,  String username,  Country phoneCountry,  String phoneNumber)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingDraft() when $default != null:
return $default(_that.fullName,_that.birthday,_that.country,_that.parentEmail,_that.sports,_that.skills,_that.username,_that.phoneCountry,_that.phoneNumber);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingDraft extends OnboardingDraft {
  const _OnboardingDraft({this.fullName = '', this.birthday, this.country = Country.singapore, this.parentEmail,  List<Sport> sports = const [Sport.badminton, Sport.pickleball],  Map<Sport, SportSkill> skills = const {}, this.username = '', this.phoneCountry = Country.singapore, this.phoneNumber = ''}): _sports = sports,_skills = skills,super._();
  

@override@JsonKey() final  String fullName;
@override final  DateTime? birthday;
@override@JsonKey() final  Country country;
@override final  String? parentEmail;
 final  List<Sport> _sports;
@override@JsonKey() List<Sport> get sports {
  if (_sports is EqualUnmodifiableListView) return _sports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sports);
}

 final  Map<Sport, SportSkill> _skills;
@override@JsonKey() Map<Sport, SportSkill> get skills {
  if (_skills is EqualUnmodifiableMapView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skills);
}

@override@JsonKey() final  String username;
@override@JsonKey() final  Country phoneCountry;
@override@JsonKey() final  String phoneNumber;

/// Create a copy of OnboardingDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingDraftCopyWith<_OnboardingDraft> get copyWith => __$OnboardingDraftCopyWithImpl<_OnboardingDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingDraft&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.country, country) || other.country == country)&&(identical(other.parentEmail, parentEmail) || other.parentEmail == parentEmail)&&const DeepCollectionEquality().equals(other.sports, _sports)&&const DeepCollectionEquality().equals(other.skills, _skills)&&(identical(other.username, username) || other.username == username)&&(identical(other.phoneCountry, phoneCountry) || other.phoneCountry == phoneCountry)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fullName,birthday,country,parentEmail,const DeepCollectionEquality().hash(_sports),const DeepCollectionEquality().hash(_skills),username,phoneCountry,phoneNumber);
}

@override
String toString() {
    return 'OnboardingDraft(fullName: $fullName, birthday: $birthday, country: $country, parentEmail: $parentEmail, sports: $sports, skills: $skills, username: $username, phoneCountry: $phoneCountry, phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class _$OnboardingDraftCopyWith<$Res> implements $OnboardingDraftCopyWith<$Res> {
  factory _$OnboardingDraftCopyWith(_OnboardingDraft value, $Res Function(_OnboardingDraft) _then) = __$OnboardingDraftCopyWithImpl;
@override @useResult
$Res call({
 String fullName, DateTime? birthday, Country country, String? parentEmail, List<Sport> sports, Map<Sport, SportSkill> skills, String username, Country phoneCountry, String phoneNumber
});




}
/// @nodoc
class __$OnboardingDraftCopyWithImpl<$Res>
    implements _$OnboardingDraftCopyWith<$Res> {
  __$OnboardingDraftCopyWithImpl(this._self, this._then);

  final _OnboardingDraft _self;
  final $Res Function(_OnboardingDraft) _then;

/// Create a copy of OnboardingDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? birthday = freezed,Object? country = null,Object? parentEmail = freezed,Object? sports = null,Object? skills = null,Object? username = null,Object? phoneCountry = null,Object? phoneNumber = null,}) {
  return _then(_OnboardingDraft(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as Country,parentEmail: freezed == parentEmail ? _self.parentEmail : parentEmail // ignore: cast_nullable_to_non_nullable
as String?,sports: null == sports ? _self._sports : sports // ignore: cast_nullable_to_non_nullable
as List<Sport>,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as Map<Sport, SportSkill>,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,phoneCountry: null == phoneCountry ? _self.phoneCountry : phoneCountry // ignore: cast_nullable_to_non_nullable
as Country,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

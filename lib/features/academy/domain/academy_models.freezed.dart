// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'academy_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AcademyCoach {

 String get name; String get initials; String get role; bool get nroc;
/// Create a copy of AcademyCoach
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademyCoachCopyWith<AcademyCoach> get copyWith => _$AcademyCoachCopyWithImpl<AcademyCoach>(this as AcademyCoach, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AcademyCoach;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcademyCoach&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.initials, _this.initials) || other.initials == _this.initials)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.nroc, _this.nroc) || other.nroc == _this.nroc));
}


@override
int get hashCode {
  final _this = this as AcademyCoach;
  return Object.hash(runtimeType,_this.name,_this.initials,_this.role,_this.nroc);
}

@override
String toString() {
  final _this = this as AcademyCoach;
  return 'AcademyCoach(name: ${_this.name}, initials: ${_this.initials}, role: ${_this.role}, nroc: ${_this.nroc})';
}


}

/// @nodoc
abstract mixin class $AcademyCoachCopyWith<$Res>  {
  factory $AcademyCoachCopyWith(AcademyCoach value, $Res Function(AcademyCoach) _then) = _$AcademyCoachCopyWithImpl;
@useResult
$Res call({
 String name, String initials, String role, bool nroc
});




}
/// @nodoc
class _$AcademyCoachCopyWithImpl<$Res>
    implements $AcademyCoachCopyWith<$Res> {
  _$AcademyCoachCopyWithImpl(this._self, this._then);

  final AcademyCoach _self;
  final $Res Function(AcademyCoach) _then;

/// Create a copy of AcademyCoach
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? initials = null,Object? role = null,Object? nroc = null,}) {
  return _then(AcademyCoach(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initials: null == initials ? _self.initials : initials // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,nroc: null == nroc ? _self.nroc : nroc // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AcademyCoach].
extension AcademyCoachPatterns on AcademyCoach {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcademyCoach value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcademyCoach() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcademyCoach value)  $default,){
final _that = this;
switch (_that) {
case _AcademyCoach():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcademyCoach value)?  $default,){
final _that = this;
switch (_that) {
case _AcademyCoach() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String initials,  String role,  bool nroc)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcademyCoach() when $default != null:
return $default(_that.name,_that.initials,_that.role,_that.nroc);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String initials,  String role,  bool nroc)  $default,) {final _that = this;
switch (_that) {
case _AcademyCoach():
return $default(_that.name,_that.initials,_that.role,_that.nroc);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String initials,  String role,  bool nroc)?  $default,) {final _that = this;
switch (_that) {
case _AcademyCoach() when $default != null:
return $default(_that.name,_that.initials,_that.role,_that.nroc);case _:
  return null;

}
}

}

/// @nodoc


class _AcademyCoach implements AcademyCoach {
  const _AcademyCoach({required this.name, required this.initials, required this.role, this.nroc = true});
  

@override final  String name;
@override final  String initials;
@override final  String role;
@override@JsonKey() final  bool nroc;

/// Create a copy of AcademyCoach
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademyCoachCopyWith<_AcademyCoach> get copyWith => __$AcademyCoachCopyWithImpl<_AcademyCoach>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcademyCoach&&(identical(other.name, name) || other.name == name)&&(identical(other.initials, initials) || other.initials == initials)&&(identical(other.role, role) || other.role == role)&&(identical(other.nroc, nroc) || other.nroc == nroc));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,initials,role,nroc);
}

@override
String toString() {
    return 'AcademyCoach(name: $name, initials: $initials, role: $role, nroc: $nroc)';
}


}

/// @nodoc
abstract mixin class _$AcademyCoachCopyWith<$Res> implements $AcademyCoachCopyWith<$Res> {
  factory _$AcademyCoachCopyWith(_AcademyCoach value, $Res Function(_AcademyCoach) _then) = __$AcademyCoachCopyWithImpl;
@override @useResult
$Res call({
 String name, String initials, String role, bool nroc
});




}
/// @nodoc
class __$AcademyCoachCopyWithImpl<$Res>
    implements _$AcademyCoachCopyWith<$Res> {
  __$AcademyCoachCopyWithImpl(this._self, this._then);

  final _AcademyCoach _self;
  final $Res Function(_AcademyCoach) _then;

/// Create a copy of AcademyCoach
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? initials = null,Object? role = null,Object? nroc = null,}) {
  return _then(_AcademyCoach(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initials: null == initials ? _self.initials : initials // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,nroc: null == nroc ? _self.nroc : nroc // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AcademyClass {

 String get id; String get academyId; String get name;/// 1, 2, 3; "Rally Builders".
 int get level; String get levelName;/// DateTime.monday … DateTime.sunday.
 List<int> get weekdays; int get hour; int get minute; int get minutes; String get ages; int get feeCents; int get capacity; int get enrolled; String get coach; String get court; int get week; int get termWeeks;/// This week's lesson, and the skill it works on (a [Skill.id]).
 String get lesson; String get focusSkill;
/// Create a copy of AcademyClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademyClassCopyWith<AcademyClass> get copyWith => _$AcademyClassCopyWithImpl<AcademyClass>(this as AcademyClass, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AcademyClass;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcademyClass&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.academyId, _this.academyId) || other.academyId == _this.academyId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.levelName, _this.levelName) || other.levelName == _this.levelName)&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays)&&(identical(other.hour, _this.hour) || other.hour == _this.hour)&&(identical(other.minute, _this.minute) || other.minute == _this.minute)&&(identical(other.minutes, _this.minutes) || other.minutes == _this.minutes)&&(identical(other.ages, _this.ages) || other.ages == _this.ages)&&(identical(other.feeCents, _this.feeCents) || other.feeCents == _this.feeCents)&&(identical(other.capacity, _this.capacity) || other.capacity == _this.capacity)&&(identical(other.enrolled, _this.enrolled) || other.enrolled == _this.enrolled)&&(identical(other.coach, _this.coach) || other.coach == _this.coach)&&(identical(other.court, _this.court) || other.court == _this.court)&&(identical(other.week, _this.week) || other.week == _this.week)&&(identical(other.termWeeks, _this.termWeeks) || other.termWeeks == _this.termWeeks)&&(identical(other.lesson, _this.lesson) || other.lesson == _this.lesson)&&(identical(other.focusSkill, _this.focusSkill) || other.focusSkill == _this.focusSkill));
}


@override
int get hashCode {
  final _this = this as AcademyClass;
  return Object.hashAll([runtimeType,_this.id,_this.academyId,_this.name,_this.level,_this.levelName,const DeepCollectionEquality().hash(_this.weekdays),_this.hour,_this.minute,_this.minutes,_this.ages,_this.feeCents,_this.capacity,_this.enrolled,_this.coach,_this.court,_this.week,_this.termWeeks,_this.lesson,_this.focusSkill]);
}

@override
String toString() {
  final _this = this as AcademyClass;
  return 'AcademyClass(id: ${_this.id}, academyId: ${_this.academyId}, name: ${_this.name}, level: ${_this.level}, levelName: ${_this.levelName}, weekdays: ${_this.weekdays}, hour: ${_this.hour}, minute: ${_this.minute}, minutes: ${_this.minutes}, ages: ${_this.ages}, feeCents: ${_this.feeCents}, capacity: ${_this.capacity}, enrolled: ${_this.enrolled}, coach: ${_this.coach}, court: ${_this.court}, week: ${_this.week}, termWeeks: ${_this.termWeeks}, lesson: ${_this.lesson}, focusSkill: ${_this.focusSkill})';
}


}

/// @nodoc
abstract mixin class $AcademyClassCopyWith<$Res>  {
  factory $AcademyClassCopyWith(AcademyClass value, $Res Function(AcademyClass) _then) = _$AcademyClassCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String name, int level, String levelName, List<int> weekdays, int hour, int minute, int minutes, String ages, int feeCents, int capacity, int enrolled, String coach, String court, int week, int termWeeks, String lesson, String focusSkill
});




}
/// @nodoc
class _$AcademyClassCopyWithImpl<$Res>
    implements $AcademyClassCopyWith<$Res> {
  _$AcademyClassCopyWithImpl(this._self, this._then);

  final AcademyClass _self;
  final $Res Function(AcademyClass) _then;

/// Create a copy of AcademyClass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? name = null,Object? level = null,Object? levelName = null,Object? weekdays = null,Object? hour = null,Object? minute = null,Object? minutes = null,Object? ages = null,Object? feeCents = null,Object? capacity = null,Object? enrolled = null,Object? coach = null,Object? court = null,Object? week = null,Object? termWeeks = null,Object? lesson = null,Object? focusSkill = null,}) {
  return _then(AcademyClass(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,levelName: null == levelName ? _self.levelName : levelName // ignore: cast_nullable_to_non_nullable
as String,weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,minute: null == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,ages: null == ages ? _self.ages : ages // ignore: cast_nullable_to_non_nullable
as String,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,coach: null == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as String,court: null == court ? _self.court : court // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,termWeeks: null == termWeeks ? _self.termWeeks : termWeeks // ignore: cast_nullable_to_non_nullable
as int,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,focusSkill: null == focusSkill ? _self.focusSkill : focusSkill // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AcademyClass].
extension AcademyClassPatterns on AcademyClass {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcademyClass value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcademyClass() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcademyClass value)  $default,){
final _that = this;
switch (_that) {
case _AcademyClass():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcademyClass value)?  $default,){
final _that = this;
switch (_that) {
case _AcademyClass() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String name,  int level,  String levelName,  List<int> weekdays,  int hour,  int minute,  int minutes,  String ages,  int feeCents,  int capacity,  int enrolled,  String coach,  String court,  int week,  int termWeeks,  String lesson,  String focusSkill)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcademyClass() when $default != null:
return $default(_that.id,_that.academyId,_that.name,_that.level,_that.levelName,_that.weekdays,_that.hour,_that.minute,_that.minutes,_that.ages,_that.feeCents,_that.capacity,_that.enrolled,_that.coach,_that.court,_that.week,_that.termWeeks,_that.lesson,_that.focusSkill);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String name,  int level,  String levelName,  List<int> weekdays,  int hour,  int minute,  int minutes,  String ages,  int feeCents,  int capacity,  int enrolled,  String coach,  String court,  int week,  int termWeeks,  String lesson,  String focusSkill)  $default,) {final _that = this;
switch (_that) {
case _AcademyClass():
return $default(_that.id,_that.academyId,_that.name,_that.level,_that.levelName,_that.weekdays,_that.hour,_that.minute,_that.minutes,_that.ages,_that.feeCents,_that.capacity,_that.enrolled,_that.coach,_that.court,_that.week,_that.termWeeks,_that.lesson,_that.focusSkill);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String name,  int level,  String levelName,  List<int> weekdays,  int hour,  int minute,  int minutes,  String ages,  int feeCents,  int capacity,  int enrolled,  String coach,  String court,  int week,  int termWeeks,  String lesson,  String focusSkill)?  $default,) {final _that = this;
switch (_that) {
case _AcademyClass() when $default != null:
return $default(_that.id,_that.academyId,_that.name,_that.level,_that.levelName,_that.weekdays,_that.hour,_that.minute,_that.minutes,_that.ages,_that.feeCents,_that.capacity,_that.enrolled,_that.coach,_that.court,_that.week,_that.termWeeks,_that.lesson,_that.focusSkill);case _:
  return null;

}
}

}

/// @nodoc


class _AcademyClass extends AcademyClass {
  const _AcademyClass({required this.id, required this.academyId, required this.name, required this.level, this.levelName = '', required  List<int> weekdays, required this.hour, this.minute = 0, this.minutes = 90, this.ages = '', required this.feeCents, required this.capacity, this.enrolled = 0, required this.coach, this.court = '', this.week = 1, this.termWeeks = 10, this.lesson = '', this.focusSkill = ''}): _weekdays = weekdays,super._();
  

@override final  String id;
@override final  String academyId;
@override final  String name;
/// 1, 2, 3; "Rally Builders".
@override final  int level;
@override@JsonKey() final  String levelName;
/// DateTime.monday … DateTime.sunday.
 final  List<int> _weekdays;
/// DateTime.monday … DateTime.sunday.
@override List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}

@override final  int hour;
@override@JsonKey() final  int minute;
@override@JsonKey() final  int minutes;
@override@JsonKey() final  String ages;
@override final  int feeCents;
@override final  int capacity;
@override@JsonKey() final  int enrolled;
@override final  String coach;
@override@JsonKey() final  String court;
@override@JsonKey() final  int week;
@override@JsonKey() final  int termWeeks;
/// This week's lesson, and the skill it works on (a [Skill.id]).
@override@JsonKey() final  String lesson;
@override@JsonKey() final  String focusSkill;

/// Create a copy of AcademyClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademyClassCopyWith<_AcademyClass> get copyWith => __$AcademyClassCopyWithImpl<_AcademyClass>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcademyClass&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.level, level) || other.level == level)&&(identical(other.levelName, levelName) || other.levelName == levelName)&&const DeepCollectionEquality().equals(other.weekdays, _weekdays)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.minute, minute) || other.minute == minute)&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.ages, ages) || other.ages == ages)&&(identical(other.feeCents, feeCents) || other.feeCents == feeCents)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.coach, coach) || other.coach == coach)&&(identical(other.court, court) || other.court == court)&&(identical(other.week, week) || other.week == week)&&(identical(other.termWeeks, termWeeks) || other.termWeeks == termWeeks)&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.focusSkill, focusSkill) || other.focusSkill == focusSkill));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,academyId,name,level,levelName,const DeepCollectionEquality().hash(_weekdays),hour,minute,minutes,ages,feeCents,capacity,enrolled,coach,court,week,termWeeks,lesson,focusSkill]);
}

@override
String toString() {
    return 'AcademyClass(id: $id, academyId: $academyId, name: $name, level: $level, levelName: $levelName, weekdays: $weekdays, hour: $hour, minute: $minute, minutes: $minutes, ages: $ages, feeCents: $feeCents, capacity: $capacity, enrolled: $enrolled, coach: $coach, court: $court, week: $week, termWeeks: $termWeeks, lesson: $lesson, focusSkill: $focusSkill)';
}


}

/// @nodoc
abstract mixin class _$AcademyClassCopyWith<$Res> implements $AcademyClassCopyWith<$Res> {
  factory _$AcademyClassCopyWith(_AcademyClass value, $Res Function(_AcademyClass) _then) = __$AcademyClassCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String name, int level, String levelName, List<int> weekdays, int hour, int minute, int minutes, String ages, int feeCents, int capacity, int enrolled, String coach, String court, int week, int termWeeks, String lesson, String focusSkill
});




}
/// @nodoc
class __$AcademyClassCopyWithImpl<$Res>
    implements _$AcademyClassCopyWith<$Res> {
  __$AcademyClassCopyWithImpl(this._self, this._then);

  final _AcademyClass _self;
  final $Res Function(_AcademyClass) _then;

/// Create a copy of AcademyClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? name = null,Object? level = null,Object? levelName = null,Object? weekdays = null,Object? hour = null,Object? minute = null,Object? minutes = null,Object? ages = null,Object? feeCents = null,Object? capacity = null,Object? enrolled = null,Object? coach = null,Object? court = null,Object? week = null,Object? termWeeks = null,Object? lesson = null,Object? focusSkill = null,}) {
  return _then(_AcademyClass(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,levelName: null == levelName ? _self.levelName : levelName // ignore: cast_nullable_to_non_nullable
as String,weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,minute: null == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,ages: null == ages ? _self.ages : ages // ignore: cast_nullable_to_non_nullable
as String,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,coach: null == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as String,court: null == court ? _self.court : court // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,termWeeks: null == termWeeks ? _self.termWeeks : termWeeks // ignore: cast_nullable_to_non_nullable
as int,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,focusSkill: null == focusSkill ? _self.focusSkill : focusSkill // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Academy {

 String get id; String get name; Sport get sport; String get area; String get blurb; String get audience; double? get rating; int get ratingCount; int get students; bool get verified; Billing get billing; int get makeupsPerMonth; List<AcademyCoach> get coaches; List<AcademyClass> get classes; int get color; int get ink;/// The banner on the academy page, like a club's cover colour.
 int get coverColor; AcademyRole get myRole; int get pendingRequests;
/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademyCopyWith<Academy> get copyWith => _$AcademyCopyWithImpl<Academy>(this as Academy, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Academy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Academy&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.blurb, _this.blurb) || other.blurb == _this.blurb)&&(identical(other.audience, _this.audience) || other.audience == _this.audience)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.students, _this.students) || other.students == _this.students)&&(identical(other.verified, _this.verified) || other.verified == _this.verified)&&(identical(other.billing, _this.billing) || other.billing == _this.billing)&&(identical(other.makeupsPerMonth, _this.makeupsPerMonth) || other.makeupsPerMonth == _this.makeupsPerMonth)&&const DeepCollectionEquality().equals(other.coaches, _this.coaches)&&const DeepCollectionEquality().equals(other.classes, _this.classes)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.ink, _this.ink) || other.ink == _this.ink)&&(identical(other.coverColor, _this.coverColor) || other.coverColor == _this.coverColor)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.pendingRequests, _this.pendingRequests) || other.pendingRequests == _this.pendingRequests));
}


@override
int get hashCode {
  final _this = this as Academy;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.sport,_this.area,_this.blurb,_this.audience,_this.rating,_this.ratingCount,_this.students,_this.verified,_this.billing,_this.makeupsPerMonth,const DeepCollectionEquality().hash(_this.coaches),const DeepCollectionEquality().hash(_this.classes),_this.color,_this.ink,_this.coverColor,_this.myRole,_this.pendingRequests]);
}

@override
String toString() {
  final _this = this as Academy;
  return 'Academy(id: ${_this.id}, name: ${_this.name}, sport: ${_this.sport}, area: ${_this.area}, blurb: ${_this.blurb}, audience: ${_this.audience}, rating: ${_this.rating}, ratingCount: ${_this.ratingCount}, students: ${_this.students}, verified: ${_this.verified}, billing: ${_this.billing}, makeupsPerMonth: ${_this.makeupsPerMonth}, coaches: ${_this.coaches}, classes: ${_this.classes}, color: ${_this.color}, ink: ${_this.ink}, coverColor: ${_this.coverColor}, myRole: ${_this.myRole}, pendingRequests: ${_this.pendingRequests})';
}


}

/// @nodoc
abstract mixin class $AcademyCopyWith<$Res>  {
  factory $AcademyCopyWith(Academy value, $Res Function(Academy) _then) = _$AcademyCopyWithImpl;
@useResult
$Res call({
 String id, String name, Sport sport, String area, String blurb, String audience, double? rating, int ratingCount, int students, bool verified, Billing billing, int makeupsPerMonth, List<AcademyCoach> coaches, List<AcademyClass> classes, int color, int ink, int coverColor, AcademyRole myRole, int pendingRequests
});




}
/// @nodoc
class _$AcademyCopyWithImpl<$Res>
    implements $AcademyCopyWith<$Res> {
  _$AcademyCopyWithImpl(this._self, this._then);

  final Academy _self;
  final $Res Function(Academy) _then;

/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? area = null,Object? blurb = null,Object? audience = null,Object? rating = freezed,Object? ratingCount = null,Object? students = null,Object? verified = null,Object? billing = null,Object? makeupsPerMonth = null,Object? coaches = null,Object? classes = null,Object? color = null,Object? ink = null,Object? coverColor = null,Object? myRole = null,Object? pendingRequests = null,}) {
  return _then(Academy(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as String,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,billing: null == billing ? _self.billing : billing // ignore: cast_nullable_to_non_nullable
as Billing,makeupsPerMonth: null == makeupsPerMonth ? _self.makeupsPerMonth : makeupsPerMonth // ignore: cast_nullable_to_non_nullable
as int,coaches: null == coaches ? _self.coaches : coaches // ignore: cast_nullable_to_non_nullable
as List<AcademyCoach>,classes: null == classes ? _self.classes : classes // ignore: cast_nullable_to_non_nullable
as List<AcademyClass>,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as AcademyRole,pendingRequests: null == pendingRequests ? _self.pendingRequests : pendingRequests // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Academy].
extension AcademyPatterns on Academy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Academy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Academy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Academy value)  $default,){
final _that = this;
switch (_that) {
case _Academy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Academy value)?  $default,){
final _that = this;
switch (_that) {
case _Academy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Sport sport,  String area,  String blurb,  String audience,  double? rating,  int ratingCount,  int students,  bool verified,  Billing billing,  int makeupsPerMonth,  List<AcademyCoach> coaches,  List<AcademyClass> classes,  int color,  int ink,  int coverColor,  AcademyRole myRole,  int pendingRequests)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Academy() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.area,_that.blurb,_that.audience,_that.rating,_that.ratingCount,_that.students,_that.verified,_that.billing,_that.makeupsPerMonth,_that.coaches,_that.classes,_that.color,_that.ink,_that.coverColor,_that.myRole,_that.pendingRequests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Sport sport,  String area,  String blurb,  String audience,  double? rating,  int ratingCount,  int students,  bool verified,  Billing billing,  int makeupsPerMonth,  List<AcademyCoach> coaches,  List<AcademyClass> classes,  int color,  int ink,  int coverColor,  AcademyRole myRole,  int pendingRequests)  $default,) {final _that = this;
switch (_that) {
case _Academy():
return $default(_that.id,_that.name,_that.sport,_that.area,_that.blurb,_that.audience,_that.rating,_that.ratingCount,_that.students,_that.verified,_that.billing,_that.makeupsPerMonth,_that.coaches,_that.classes,_that.color,_that.ink,_that.coverColor,_that.myRole,_that.pendingRequests);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Sport sport,  String area,  String blurb,  String audience,  double? rating,  int ratingCount,  int students,  bool verified,  Billing billing,  int makeupsPerMonth,  List<AcademyCoach> coaches,  List<AcademyClass> classes,  int color,  int ink,  int coverColor,  AcademyRole myRole,  int pendingRequests)?  $default,) {final _that = this;
switch (_that) {
case _Academy() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.area,_that.blurb,_that.audience,_that.rating,_that.ratingCount,_that.students,_that.verified,_that.billing,_that.makeupsPerMonth,_that.coaches,_that.classes,_that.color,_that.ink,_that.coverColor,_that.myRole,_that.pendingRequests);case _:
  return null;

}
}

}

/// @nodoc


class _Academy extends Academy {
  const _Academy({required this.id, required this.name, required this.sport, required this.area, this.blurb = '', this.audience = '', this.rating, this.ratingCount = 0, this.students = 0, this.verified = false, this.billing = Billing.month, this.makeupsPerMonth = 2,  List<AcademyCoach> coaches = const [],  List<AcademyClass> classes = const [], this.color = 0xFF16181B, this.ink = 0xFFF2C14E, this.coverColor = 0xFFE8590C, this.myRole = AcademyRole.none, this.pendingRequests = 0}): _coaches = coaches,_classes = classes,super._();
  

@override final  String id;
@override final  String name;
@override final  Sport sport;
@override final  String area;
@override@JsonKey() final  String blurb;
@override@JsonKey() final  String audience;
@override final  double? rating;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  int students;
@override@JsonKey() final  bool verified;
@override@JsonKey() final  Billing billing;
@override@JsonKey() final  int makeupsPerMonth;
 final  List<AcademyCoach> _coaches;
@override@JsonKey() List<AcademyCoach> get coaches {
  if (_coaches is EqualUnmodifiableListView) return _coaches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coaches);
}

 final  List<AcademyClass> _classes;
@override@JsonKey() List<AcademyClass> get classes {
  if (_classes is EqualUnmodifiableListView) return _classes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_classes);
}

@override@JsonKey() final  int color;
@override@JsonKey() final  int ink;
/// The banner on the academy page, like a club's cover colour.
@override@JsonKey() final  int coverColor;
@override@JsonKey() final  AcademyRole myRole;
@override@JsonKey() final  int pendingRequests;

/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademyCopyWith<_Academy> get copyWith => __$AcademyCopyWithImpl<_Academy>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Academy&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.area, area) || other.area == area)&&(identical(other.blurb, blurb) || other.blurb == blurb)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.students, students) || other.students == students)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.billing, billing) || other.billing == billing)&&(identical(other.makeupsPerMonth, makeupsPerMonth) || other.makeupsPerMonth == makeupsPerMonth)&&const DeepCollectionEquality().equals(other.coaches, _coaches)&&const DeepCollectionEquality().equals(other.classes, _classes)&&(identical(other.color, color) || other.color == color)&&(identical(other.ink, ink) || other.ink == ink)&&(identical(other.coverColor, coverColor) || other.coverColor == coverColor)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.pendingRequests, pendingRequests) || other.pendingRequests == pendingRequests));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,sport,area,blurb,audience,rating,ratingCount,students,verified,billing,makeupsPerMonth,const DeepCollectionEquality().hash(_coaches),const DeepCollectionEquality().hash(_classes),color,ink,coverColor,myRole,pendingRequests]);
}

@override
String toString() {
    return 'Academy(id: $id, name: $name, sport: $sport, area: $area, blurb: $blurb, audience: $audience, rating: $rating, ratingCount: $ratingCount, students: $students, verified: $verified, billing: $billing, makeupsPerMonth: $makeupsPerMonth, coaches: $coaches, classes: $classes, color: $color, ink: $ink, coverColor: $coverColor, myRole: $myRole, pendingRequests: $pendingRequests)';
}


}

/// @nodoc
abstract mixin class _$AcademyCopyWith<$Res> implements $AcademyCopyWith<$Res> {
  factory _$AcademyCopyWith(_Academy value, $Res Function(_Academy) _then) = __$AcademyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Sport sport, String area, String blurb, String audience, double? rating, int ratingCount, int students, bool verified, Billing billing, int makeupsPerMonth, List<AcademyCoach> coaches, List<AcademyClass> classes, int color, int ink, int coverColor, AcademyRole myRole, int pendingRequests
});




}
/// @nodoc
class __$AcademyCopyWithImpl<$Res>
    implements _$AcademyCopyWith<$Res> {
  __$AcademyCopyWithImpl(this._self, this._then);

  final _Academy _self;
  final $Res Function(_Academy) _then;

/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? area = null,Object? blurb = null,Object? audience = null,Object? rating = freezed,Object? ratingCount = null,Object? students = null,Object? verified = null,Object? billing = null,Object? makeupsPerMonth = null,Object? coaches = null,Object? classes = null,Object? color = null,Object? ink = null,Object? coverColor = null,Object? myRole = null,Object? pendingRequests = null,}) {
  return _then(_Academy(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as String,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,billing: null == billing ? _self.billing : billing // ignore: cast_nullable_to_non_nullable
as Billing,makeupsPerMonth: null == makeupsPerMonth ? _self.makeupsPerMonth : makeupsPerMonth // ignore: cast_nullable_to_non_nullable
as int,coaches: null == coaches ? _self._coaches : coaches // ignore: cast_nullable_to_non_nullable
as List<AcademyCoach>,classes: null == classes ? _self._classes : classes // ignore: cast_nullable_to_non_nullable
as List<AcademyClass>,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,coverColor: null == coverColor ? _self.coverColor : coverColor // ignore: cast_nullable_to_non_nullable
as int,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as AcademyRole,pendingRequests: null == pendingRequests ? _self.pendingRequests : pendingRequests // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Skill {

 String get id; String get group; String get name; SkillStatus get status;/// "Week 4" when it was last updated.
 String get week;
/// Create a copy of Skill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCopyWith<Skill> get copyWith => _$SkillCopyWithImpl<Skill>(this as Skill, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Skill;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Skill&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.group, _this.group) || other.group == _this.group)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.week, _this.week) || other.week == _this.week));
}


@override
int get hashCode {
  final _this = this as Skill;
  return Object.hash(runtimeType,_this.id,_this.group,_this.name,_this.status,_this.week);
}

@override
String toString() {
  final _this = this as Skill;
  return 'Skill(id: ${_this.id}, group: ${_this.group}, name: ${_this.name}, status: ${_this.status}, week: ${_this.week})';
}


}

/// @nodoc
abstract mixin class $SkillCopyWith<$Res>  {
  factory $SkillCopyWith(Skill value, $Res Function(Skill) _then) = _$SkillCopyWithImpl;
@useResult
$Res call({
 String id, String group, String name, SkillStatus status, String week
});




}
/// @nodoc
class _$SkillCopyWithImpl<$Res>
    implements $SkillCopyWith<$Res> {
  _$SkillCopyWithImpl(this._self, this._then);

  final Skill _self;
  final $Res Function(Skill) _then;

/// Create a copy of Skill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? group = null,Object? name = null,Object? status = null,Object? week = null,}) {
  return _then(Skill(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SkillStatus,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Skill].
extension SkillPatterns on Skill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Skill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Skill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Skill value)  $default,){
final _that = this;
switch (_that) {
case _Skill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Skill value)?  $default,){
final _that = this;
switch (_that) {
case _Skill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String group,  String name,  SkillStatus status,  String week)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Skill() when $default != null:
return $default(_that.id,_that.group,_that.name,_that.status,_that.week);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String group,  String name,  SkillStatus status,  String week)  $default,) {final _that = this;
switch (_that) {
case _Skill():
return $default(_that.id,_that.group,_that.name,_that.status,_that.week);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String group,  String name,  SkillStatus status,  String week)?  $default,) {final _that = this;
switch (_that) {
case _Skill() when $default != null:
return $default(_that.id,_that.group,_that.name,_that.status,_that.week);case _:
  return null;

}
}

}

/// @nodoc


class _Skill implements Skill {
  const _Skill({required this.id, required this.group, required this.name, this.status = SkillStatus.notYet, this.week = ''});
  

@override final  String id;
@override final  String group;
@override final  String name;
@override@JsonKey() final  SkillStatus status;
/// "Week 4" when it was last updated.
@override@JsonKey() final  String week;

/// Create a copy of Skill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCopyWith<_Skill> get copyWith => __$SkillCopyWithImpl<_Skill>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Skill&&(identical(other.id, id) || other.id == id)&&(identical(other.group, group) || other.group == group)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.week, week) || other.week == week));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,group,name,status,week);
}

@override
String toString() {
    return 'Skill(id: $id, group: $group, name: $name, status: $status, week: $week)';
}


}

/// @nodoc
abstract mixin class _$SkillCopyWith<$Res> implements $SkillCopyWith<$Res> {
  factory _$SkillCopyWith(_Skill value, $Res Function(_Skill) _then) = __$SkillCopyWithImpl;
@override @useResult
$Res call({
 String id, String group, String name, SkillStatus status, String week
});




}
/// @nodoc
class __$SkillCopyWithImpl<$Res>
    implements _$SkillCopyWith<$Res> {
  __$SkillCopyWithImpl(this._self, this._then);

  final _Skill _self;
  final $Res Function(_Skill) _then;

/// Create a copy of Skill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? group = null,Object? name = null,Object? status = null,Object? week = null,}) {
  return _then(_Skill(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SkillStatus,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CoachNote {

 String get coach; DateTime get at; String get text; String get lesson; bool get present; String? get got; String? get practising;
/// Create a copy of CoachNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachNoteCopyWith<CoachNote> get copyWith => _$CoachNoteCopyWithImpl<CoachNote>(this as CoachNote, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachNote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachNote&&(identical(other.coach, _this.coach) || other.coach == _this.coach)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.lesson, _this.lesson) || other.lesson == _this.lesson)&&(identical(other.present, _this.present) || other.present == _this.present)&&(identical(other.got, _this.got) || other.got == _this.got)&&(identical(other.practising, _this.practising) || other.practising == _this.practising));
}


@override
int get hashCode {
  final _this = this as CoachNote;
  return Object.hash(runtimeType,_this.coach,_this.at,_this.text,_this.lesson,_this.present,_this.got,_this.practising);
}

@override
String toString() {
  final _this = this as CoachNote;
  return 'CoachNote(coach: ${_this.coach}, at: ${_this.at}, text: ${_this.text}, lesson: ${_this.lesson}, present: ${_this.present}, got: ${_this.got}, practising: ${_this.practising})';
}


}

/// @nodoc
abstract mixin class $CoachNoteCopyWith<$Res>  {
  factory $CoachNoteCopyWith(CoachNote value, $Res Function(CoachNote) _then) = _$CoachNoteCopyWithImpl;
@useResult
$Res call({
 String coach, DateTime at, String text, String lesson, bool present, String? got, String? practising
});




}
/// @nodoc
class _$CoachNoteCopyWithImpl<$Res>
    implements $CoachNoteCopyWith<$Res> {
  _$CoachNoteCopyWithImpl(this._self, this._then);

  final CoachNote _self;
  final $Res Function(CoachNote) _then;

/// Create a copy of CoachNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? coach = null,Object? at = null,Object? text = null,Object? lesson = null,Object? present = null,Object? got = freezed,Object? practising = freezed,}) {
  return _then(CoachNote(
coach: null == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,present: null == present ? _self.present : present // ignore: cast_nullable_to_non_nullable
as bool,got: freezed == got ? _self.got : got // ignore: cast_nullable_to_non_nullable
as String?,practising: freezed == practising ? _self.practising : practising // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachNote].
extension CoachNotePatterns on CoachNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachNote value)  $default,){
final _that = this;
switch (_that) {
case _CoachNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachNote value)?  $default,){
final _that = this;
switch (_that) {
case _CoachNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String coach,  DateTime at,  String text,  String lesson,  bool present,  String? got,  String? practising)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachNote() when $default != null:
return $default(_that.coach,_that.at,_that.text,_that.lesson,_that.present,_that.got,_that.practising);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String coach,  DateTime at,  String text,  String lesson,  bool present,  String? got,  String? practising)  $default,) {final _that = this;
switch (_that) {
case _CoachNote():
return $default(_that.coach,_that.at,_that.text,_that.lesson,_that.present,_that.got,_that.practising);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String coach,  DateTime at,  String text,  String lesson,  bool present,  String? got,  String? practising)?  $default,) {final _that = this;
switch (_that) {
case _CoachNote() when $default != null:
return $default(_that.coach,_that.at,_that.text,_that.lesson,_that.present,_that.got,_that.practising);case _:
  return null;

}
}

}

/// @nodoc


class _CoachNote implements CoachNote {
  const _CoachNote({required this.coach, required this.at, required this.text, this.lesson = '', this.present = true, this.got, this.practising});
  

@override final  String coach;
@override final  DateTime at;
@override final  String text;
@override@JsonKey() final  String lesson;
@override@JsonKey() final  bool present;
@override final  String? got;
@override final  String? practising;

/// Create a copy of CoachNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachNoteCopyWith<_CoachNote> get copyWith => __$CoachNoteCopyWithImpl<_CoachNote>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachNote&&(identical(other.coach, coach) || other.coach == coach)&&(identical(other.at, at) || other.at == at)&&(identical(other.text, text) || other.text == text)&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.present, present) || other.present == present)&&(identical(other.got, got) || other.got == got)&&(identical(other.practising, practising) || other.practising == practising));
}


@override
int get hashCode {
    return Object.hash(runtimeType,coach,at,text,lesson,present,got,practising);
}

@override
String toString() {
    return 'CoachNote(coach: $coach, at: $at, text: $text, lesson: $lesson, present: $present, got: $got, practising: $practising)';
}


}

/// @nodoc
abstract mixin class _$CoachNoteCopyWith<$Res> implements $CoachNoteCopyWith<$Res> {
  factory _$CoachNoteCopyWith(_CoachNote value, $Res Function(_CoachNote) _then) = __$CoachNoteCopyWithImpl;
@override @useResult
$Res call({
 String coach, DateTime at, String text, String lesson, bool present, String? got, String? practising
});




}
/// @nodoc
class __$CoachNoteCopyWithImpl<$Res>
    implements _$CoachNoteCopyWith<$Res> {
  __$CoachNoteCopyWithImpl(this._self, this._then);

  final _CoachNote _self;
  final $Res Function(_CoachNote) _then;

/// Create a copy of CoachNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? coach = null,Object? at = null,Object? text = null,Object? lesson = null,Object? present = null,Object? got = freezed,Object? practising = freezed,}) {
  return _then(_CoachNote(
coach: null == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,present: null == present ? _self.present : present // ignore: cast_nullable_to_non_nullable
as bool,got: freezed == got ? _self.got : got // ignore: cast_nullable_to_non_nullable
as String?,practising: freezed == practising ? _self.practising : practising // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Student {

 String get id; String get name; int? get age; String get academyId; String get classId; String get parent; List<Skill> get skills; int get attendancePct; int get attended; int get held; int get makeupCredits; DateTime? get creditUseBy; String get flag; List<CoachNote> get notes; bool get filmingConsent;/// A change the coach sent ("Saturday's class is now 10:30 AM"), and
/// the parent's answer once given.
 String? get notice; bool? get noticeComing;
/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentCopyWith<Student> get copyWith => _$StudentCopyWithImpl<Student>(this as Student, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Student;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Student&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.age, _this.age) || other.age == _this.age)&&(identical(other.academyId, _this.academyId) || other.academyId == _this.academyId)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&(identical(other.parent, _this.parent) || other.parent == _this.parent)&&const DeepCollectionEquality().equals(other.skills, _this.skills)&&(identical(other.attendancePct, _this.attendancePct) || other.attendancePct == _this.attendancePct)&&(identical(other.attended, _this.attended) || other.attended == _this.attended)&&(identical(other.held, _this.held) || other.held == _this.held)&&(identical(other.makeupCredits, _this.makeupCredits) || other.makeupCredits == _this.makeupCredits)&&(identical(other.creditUseBy, _this.creditUseBy) || other.creditUseBy == _this.creditUseBy)&&(identical(other.flag, _this.flag) || other.flag == _this.flag)&&const DeepCollectionEquality().equals(other.notes, _this.notes)&&(identical(other.filmingConsent, _this.filmingConsent) || other.filmingConsent == _this.filmingConsent)&&(identical(other.notice, _this.notice) || other.notice == _this.notice)&&(identical(other.noticeComing, _this.noticeComing) || other.noticeComing == _this.noticeComing));
}


@override
int get hashCode {
  final _this = this as Student;
  return Object.hash(runtimeType,_this.id,_this.name,_this.age,_this.academyId,_this.classId,_this.parent,const DeepCollectionEquality().hash(_this.skills),_this.attendancePct,_this.attended,_this.held,_this.makeupCredits,_this.creditUseBy,_this.flag,const DeepCollectionEquality().hash(_this.notes),_this.filmingConsent,_this.notice,_this.noticeComing);
}

@override
String toString() {
  final _this = this as Student;
  return 'Student(id: ${_this.id}, name: ${_this.name}, age: ${_this.age}, academyId: ${_this.academyId}, classId: ${_this.classId}, parent: ${_this.parent}, skills: ${_this.skills}, attendancePct: ${_this.attendancePct}, attended: ${_this.attended}, held: ${_this.held}, makeupCredits: ${_this.makeupCredits}, creditUseBy: ${_this.creditUseBy}, flag: ${_this.flag}, notes: ${_this.notes}, filmingConsent: ${_this.filmingConsent}, notice: ${_this.notice}, noticeComing: ${_this.noticeComing})';
}


}

/// @nodoc
abstract mixin class $StudentCopyWith<$Res>  {
  factory $StudentCopyWith(Student value, $Res Function(Student) _then) = _$StudentCopyWithImpl;
@useResult
$Res call({
 String id, String name, int? age, String academyId, String classId, String parent, List<Skill> skills, int attendancePct, int attended, int held, int makeupCredits, DateTime? creditUseBy, String flag, List<CoachNote> notes, bool filmingConsent, String? notice, bool? noticeComing
});




}
/// @nodoc
class _$StudentCopyWithImpl<$Res>
    implements $StudentCopyWith<$Res> {
  _$StudentCopyWithImpl(this._self, this._then);

  final Student _self;
  final $Res Function(Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? age = freezed,Object? academyId = null,Object? classId = null,Object? parent = null,Object? skills = null,Object? attendancePct = null,Object? attended = null,Object? held = null,Object? makeupCredits = null,Object? creditUseBy = freezed,Object? flag = null,Object? notes = null,Object? filmingConsent = null,Object? notice = freezed,Object? noticeComing = freezed,}) {
  return _then(Student(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,parent: null == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<Skill>,attendancePct: null == attendancePct ? _self.attendancePct : attendancePct // ignore: cast_nullable_to_non_nullable
as int,attended: null == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as int,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as int,makeupCredits: null == makeupCredits ? _self.makeupCredits : makeupCredits // ignore: cast_nullable_to_non_nullable
as int,creditUseBy: freezed == creditUseBy ? _self.creditUseBy : creditUseBy // ignore: cast_nullable_to_non_nullable
as DateTime?,flag: null == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<CoachNote>,filmingConsent: null == filmingConsent ? _self.filmingConsent : filmingConsent // ignore: cast_nullable_to_non_nullable
as bool,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,noticeComing: freezed == noticeComing ? _self.noticeComing : noticeComing // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [Student].
extension StudentPatterns on Student {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Student value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Student value)  $default,){
final _that = this;
switch (_that) {
case _Student():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Student value)?  $default,){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int? age,  String academyId,  String classId,  String parent,  List<Skill> skills,  int attendancePct,  int attended,  int held,  int makeupCredits,  DateTime? creditUseBy,  String flag,  List<CoachNote> notes,  bool filmingConsent,  String? notice,  bool? noticeComing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.name,_that.age,_that.academyId,_that.classId,_that.parent,_that.skills,_that.attendancePct,_that.attended,_that.held,_that.makeupCredits,_that.creditUseBy,_that.flag,_that.notes,_that.filmingConsent,_that.notice,_that.noticeComing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int? age,  String academyId,  String classId,  String parent,  List<Skill> skills,  int attendancePct,  int attended,  int held,  int makeupCredits,  DateTime? creditUseBy,  String flag,  List<CoachNote> notes,  bool filmingConsent,  String? notice,  bool? noticeComing)  $default,) {final _that = this;
switch (_that) {
case _Student():
return $default(_that.id,_that.name,_that.age,_that.academyId,_that.classId,_that.parent,_that.skills,_that.attendancePct,_that.attended,_that.held,_that.makeupCredits,_that.creditUseBy,_that.flag,_that.notes,_that.filmingConsent,_that.notice,_that.noticeComing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int? age,  String academyId,  String classId,  String parent,  List<Skill> skills,  int attendancePct,  int attended,  int held,  int makeupCredits,  DateTime? creditUseBy,  String flag,  List<CoachNote> notes,  bool filmingConsent,  String? notice,  bool? noticeComing)?  $default,) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.name,_that.age,_that.academyId,_that.classId,_that.parent,_that.skills,_that.attendancePct,_that.attended,_that.held,_that.makeupCredits,_that.creditUseBy,_that.flag,_that.notes,_that.filmingConsent,_that.notice,_that.noticeComing);case _:
  return null;

}
}

}

/// @nodoc


class _Student extends Student {
  const _Student({required this.id, required this.name, this.age, required this.academyId, required this.classId, this.parent = '',  List<Skill> skills = const [], this.attendancePct = 100, this.attended = 0, this.held = 0, this.makeupCredits = 0, this.creditUseBy, this.flag = '',  List<CoachNote> notes = const [], this.filmingConsent = false, this.notice, this.noticeComing}): _skills = skills,_notes = notes,super._();
  

@override final  String id;
@override final  String name;
@override final  int? age;
@override final  String academyId;
@override final  String classId;
@override@JsonKey() final  String parent;
 final  List<Skill> _skills;
@override@JsonKey() List<Skill> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

@override@JsonKey() final  int attendancePct;
@override@JsonKey() final  int attended;
@override@JsonKey() final  int held;
@override@JsonKey() final  int makeupCredits;
@override final  DateTime? creditUseBy;
@override@JsonKey() final  String flag;
 final  List<CoachNote> _notes;
@override@JsonKey() List<CoachNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

@override@JsonKey() final  bool filmingConsent;
/// A change the coach sent ("Saturday's class is now 10:30 AM"), and
/// the parent's answer once given.
@override final  String? notice;
@override final  bool? noticeComing;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentCopyWith<_Student> get copyWith => __$StudentCopyWithImpl<_Student>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Student&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.age, age) || other.age == age)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.parent, parent) || other.parent == parent)&&const DeepCollectionEquality().equals(other.skills, _skills)&&(identical(other.attendancePct, attendancePct) || other.attendancePct == attendancePct)&&(identical(other.attended, attended) || other.attended == attended)&&(identical(other.held, held) || other.held == held)&&(identical(other.makeupCredits, makeupCredits) || other.makeupCredits == makeupCredits)&&(identical(other.creditUseBy, creditUseBy) || other.creditUseBy == creditUseBy)&&(identical(other.flag, flag) || other.flag == flag)&&const DeepCollectionEquality().equals(other.notes, _notes)&&(identical(other.filmingConsent, filmingConsent) || other.filmingConsent == filmingConsent)&&(identical(other.notice, notice) || other.notice == notice)&&(identical(other.noticeComing, noticeComing) || other.noticeComing == noticeComing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,age,academyId,classId,parent,const DeepCollectionEquality().hash(_skills),attendancePct,attended,held,makeupCredits,creditUseBy,flag,const DeepCollectionEquality().hash(_notes),filmingConsent,notice,noticeComing);
}

@override
String toString() {
    return 'Student(id: $id, name: $name, age: $age, academyId: $academyId, classId: $classId, parent: $parent, skills: $skills, attendancePct: $attendancePct, attended: $attended, held: $held, makeupCredits: $makeupCredits, creditUseBy: $creditUseBy, flag: $flag, notes: $notes, filmingConsent: $filmingConsent, notice: $notice, noticeComing: $noticeComing)';
}


}

/// @nodoc
abstract mixin class _$StudentCopyWith<$Res> implements $StudentCopyWith<$Res> {
  factory _$StudentCopyWith(_Student value, $Res Function(_Student) _then) = __$StudentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int? age, String academyId, String classId, String parent, List<Skill> skills, int attendancePct, int attended, int held, int makeupCredits, DateTime? creditUseBy, String flag, List<CoachNote> notes, bool filmingConsent, String? notice, bool? noticeComing
});




}
/// @nodoc
class __$StudentCopyWithImpl<$Res>
    implements _$StudentCopyWith<$Res> {
  __$StudentCopyWithImpl(this._self, this._then);

  final _Student _self;
  final $Res Function(_Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? age = freezed,Object? academyId = null,Object? classId = null,Object? parent = null,Object? skills = null,Object? attendancePct = null,Object? attended = null,Object? held = null,Object? makeupCredits = null,Object? creditUseBy = freezed,Object? flag = null,Object? notes = null,Object? filmingConsent = null,Object? notice = freezed,Object? noticeComing = freezed,}) {
  return _then(_Student(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,parent: null == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<Skill>,attendancePct: null == attendancePct ? _self.attendancePct : attendancePct // ignore: cast_nullable_to_non_nullable
as int,attended: null == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as int,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as int,makeupCredits: null == makeupCredits ? _self.makeupCredits : makeupCredits // ignore: cast_nullable_to_non_nullable
as int,creditUseBy: freezed == creditUseBy ? _self.creditUseBy : creditUseBy // ignore: cast_nullable_to_non_nullable
as DateTime?,flag: null == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<CoachNote>,filmingConsent: null == filmingConsent ? _self.filmingConsent : filmingConsent // ignore: cast_nullable_to_non_nullable
as bool,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,noticeComing: freezed == noticeComing ? _self.noticeComing : noticeComing // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$LessonWeek {

 int get week; String get title; bool get attended;
/// Create a copy of LessonWeek
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonWeekCopyWith<LessonWeek> get copyWith => _$LessonWeekCopyWithImpl<LessonWeek>(this as LessonWeek, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LessonWeek;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonWeek&&(identical(other.week, _this.week) || other.week == _this.week)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.attended, _this.attended) || other.attended == _this.attended));
}


@override
int get hashCode {
  final _this = this as LessonWeek;
  return Object.hash(runtimeType,_this.week,_this.title,_this.attended);
}

@override
String toString() {
  final _this = this as LessonWeek;
  return 'LessonWeek(week: ${_this.week}, title: ${_this.title}, attended: ${_this.attended})';
}


}

/// @nodoc
abstract mixin class $LessonWeekCopyWith<$Res>  {
  factory $LessonWeekCopyWith(LessonWeek value, $Res Function(LessonWeek) _then) = _$LessonWeekCopyWithImpl;
@useResult
$Res call({
 int week, String title, bool attended
});




}
/// @nodoc
class _$LessonWeekCopyWithImpl<$Res>
    implements $LessonWeekCopyWith<$Res> {
  _$LessonWeekCopyWithImpl(this._self, this._then);

  final LessonWeek _self;
  final $Res Function(LessonWeek) _then;

/// Create a copy of LessonWeek
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? week = null,Object? title = null,Object? attended = null,}) {
  return _then(LessonWeek(
week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,attended: null == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonWeek].
extension LessonWeekPatterns on LessonWeek {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonWeek value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonWeek() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonWeek value)  $default,){
final _that = this;
switch (_that) {
case _LessonWeek():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonWeek value)?  $default,){
final _that = this;
switch (_that) {
case _LessonWeek() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int week,  String title,  bool attended)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonWeek() when $default != null:
return $default(_that.week,_that.title,_that.attended);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int week,  String title,  bool attended)  $default,) {final _that = this;
switch (_that) {
case _LessonWeek():
return $default(_that.week,_that.title,_that.attended);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int week,  String title,  bool attended)?  $default,) {final _that = this;
switch (_that) {
case _LessonWeek() when $default != null:
return $default(_that.week,_that.title,_that.attended);case _:
  return null;

}
}

}

/// @nodoc


class _LessonWeek implements LessonWeek {
  const _LessonWeek({required this.week, required this.title, this.attended = false});
  

@override final  int week;
@override final  String title;
@override@JsonKey() final  bool attended;

/// Create a copy of LessonWeek
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonWeekCopyWith<_LessonWeek> get copyWith => __$LessonWeekCopyWithImpl<_LessonWeek>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonWeek&&(identical(other.week, week) || other.week == week)&&(identical(other.title, title) || other.title == title)&&(identical(other.attended, attended) || other.attended == attended));
}


@override
int get hashCode {
    return Object.hash(runtimeType,week,title,attended);
}

@override
String toString() {
    return 'LessonWeek(week: $week, title: $title, attended: $attended)';
}


}

/// @nodoc
abstract mixin class _$LessonWeekCopyWith<$Res> implements $LessonWeekCopyWith<$Res> {
  factory _$LessonWeekCopyWith(_LessonWeek value, $Res Function(_LessonWeek) _then) = __$LessonWeekCopyWithImpl;
@override @useResult
$Res call({
 int week, String title, bool attended
});




}
/// @nodoc
class __$LessonWeekCopyWithImpl<$Res>
    implements _$LessonWeekCopyWith<$Res> {
  __$LessonWeekCopyWithImpl(this._self, this._then);

  final _LessonWeek _self;
  final $Res Function(_LessonWeek) _then;

/// Create a copy of LessonWeek
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? week = null,Object? title = null,Object? attended = null,}) {
  return _then(_LessonWeek(
week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,attended: null == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Invoice {

 String get id; String get title; int get feeCents; int get platformCents; DateTime get due; DateTime? get paidOn;
/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceCopyWith<Invoice> get copyWith => _$InvoiceCopyWithImpl<Invoice>(this as Invoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Invoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.feeCents, _this.feeCents) || other.feeCents == _this.feeCents)&&(identical(other.platformCents, _this.platformCents) || other.platformCents == _this.platformCents)&&(identical(other.due, _this.due) || other.due == _this.due)&&(identical(other.paidOn, _this.paidOn) || other.paidOn == _this.paidOn));
}


@override
int get hashCode {
  final _this = this as Invoice;
  return Object.hash(runtimeType,_this.id,_this.title,_this.feeCents,_this.platformCents,_this.due,_this.paidOn);
}

@override
String toString() {
  final _this = this as Invoice;
  return 'Invoice(id: ${_this.id}, title: ${_this.title}, feeCents: ${_this.feeCents}, platformCents: ${_this.platformCents}, due: ${_this.due}, paidOn: ${_this.paidOn})';
}


}

/// @nodoc
abstract mixin class $InvoiceCopyWith<$Res>  {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) _then) = _$InvoiceCopyWithImpl;
@useResult
$Res call({
 String id, String title, int feeCents, int platformCents, DateTime due, DateTime? paidOn
});




}
/// @nodoc
class _$InvoiceCopyWithImpl<$Res>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._self, this._then);

  final Invoice _self;
  final $Res Function(Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? feeCents = null,Object? platformCents = null,Object? due = null,Object? paidOn = freezed,}) {
  return _then(Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,platformCents: null == platformCents ? _self.platformCents : platformCents // ignore: cast_nullable_to_non_nullable
as int,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as DateTime,paidOn: freezed == paidOn ? _self.paidOn : paidOn // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invoice].
extension InvoicePatterns on Invoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invoice value)  $default,){
final _that = this;
switch (_that) {
case _Invoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invoice value)?  $default,){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  int feeCents,  int platformCents,  DateTime due,  DateTime? paidOn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.title,_that.feeCents,_that.platformCents,_that.due,_that.paidOn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  int feeCents,  int platformCents,  DateTime due,  DateTime? paidOn)  $default,) {final _that = this;
switch (_that) {
case _Invoice():
return $default(_that.id,_that.title,_that.feeCents,_that.platformCents,_that.due,_that.paidOn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  int feeCents,  int platformCents,  DateTime due,  DateTime? paidOn)?  $default,) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.title,_that.feeCents,_that.platformCents,_that.due,_that.paidOn);case _:
  return null;

}
}

}

/// @nodoc


class _Invoice extends Invoice {
  const _Invoice({required this.id, required this.title, required this.feeCents, required this.platformCents, required this.due, this.paidOn}): super._();
  

@override final  String id;
@override final  String title;
@override final  int feeCents;
@override final  int platformCents;
@override final  DateTime due;
@override final  DateTime? paidOn;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceCopyWith<_Invoice> get copyWith => __$InvoiceCopyWithImpl<_Invoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.feeCents, feeCents) || other.feeCents == feeCents)&&(identical(other.platformCents, platformCents) || other.platformCents == platformCents)&&(identical(other.due, due) || other.due == due)&&(identical(other.paidOn, paidOn) || other.paidOn == paidOn));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,feeCents,platformCents,due,paidOn);
}

@override
String toString() {
    return 'Invoice(id: $id, title: $title, feeCents: $feeCents, platformCents: $platformCents, due: $due, paidOn: $paidOn)';
}


}

/// @nodoc
abstract mixin class _$InvoiceCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$InvoiceCopyWith(_Invoice value, $Res Function(_Invoice) _then) = __$InvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, int feeCents, int platformCents, DateTime due, DateTime? paidOn
});




}
/// @nodoc
class __$InvoiceCopyWithImpl<$Res>
    implements _$InvoiceCopyWith<$Res> {
  __$InvoiceCopyWithImpl(this._self, this._then);

  final _Invoice _self;
  final $Res Function(_Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? feeCents = null,Object? platformCents = null,Object? due = null,Object? paidOn = freezed,}) {
  return _then(_Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,feeCents: null == feeCents ? _self.feeCents : feeCents // ignore: cast_nullable_to_non_nullable
as int,platformCents: null == platformCents ? _self.platformCents : platformCents // ignore: cast_nullable_to_non_nullable
as int,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as DateTime,paidOn: freezed == paidOn ? _self.paidOn : paidOn // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MakeupSlot {

 String get classId; String get className; DateTime get at; String get coach; String get lesson; int get spots;
/// Create a copy of MakeupSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MakeupSlotCopyWith<MakeupSlot> get copyWith => _$MakeupSlotCopyWithImpl<MakeupSlot>(this as MakeupSlot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MakeupSlot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MakeupSlot&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&(identical(other.className, _this.className) || other.className == _this.className)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.coach, _this.coach) || other.coach == _this.coach)&&(identical(other.lesson, _this.lesson) || other.lesson == _this.lesson)&&(identical(other.spots, _this.spots) || other.spots == _this.spots));
}


@override
int get hashCode {
  final _this = this as MakeupSlot;
  return Object.hash(runtimeType,_this.classId,_this.className,_this.at,_this.coach,_this.lesson,_this.spots);
}

@override
String toString() {
  final _this = this as MakeupSlot;
  return 'MakeupSlot(classId: ${_this.classId}, className: ${_this.className}, at: ${_this.at}, coach: ${_this.coach}, lesson: ${_this.lesson}, spots: ${_this.spots})';
}


}

/// @nodoc
abstract mixin class $MakeupSlotCopyWith<$Res>  {
  factory $MakeupSlotCopyWith(MakeupSlot value, $Res Function(MakeupSlot) _then) = _$MakeupSlotCopyWithImpl;
@useResult
$Res call({
 String classId, String className, DateTime at, String coach, String lesson, int spots
});




}
/// @nodoc
class _$MakeupSlotCopyWithImpl<$Res>
    implements $MakeupSlotCopyWith<$Res> {
  _$MakeupSlotCopyWithImpl(this._self, this._then);

  final MakeupSlot _self;
  final $Res Function(MakeupSlot) _then;

/// Create a copy of MakeupSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classId = null,Object? className = null,Object? at = null,Object? coach = null,Object? lesson = null,Object? spots = null,}) {
  return _then(MakeupSlot(
classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,coach: null == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as String,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,spots: null == spots ? _self.spots : spots // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MakeupSlot].
extension MakeupSlotPatterns on MakeupSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MakeupSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MakeupSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MakeupSlot value)  $default,){
final _that = this;
switch (_that) {
case _MakeupSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MakeupSlot value)?  $default,){
final _that = this;
switch (_that) {
case _MakeupSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String classId,  String className,  DateTime at,  String coach,  String lesson,  int spots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MakeupSlot() when $default != null:
return $default(_that.classId,_that.className,_that.at,_that.coach,_that.lesson,_that.spots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String classId,  String className,  DateTime at,  String coach,  String lesson,  int spots)  $default,) {final _that = this;
switch (_that) {
case _MakeupSlot():
return $default(_that.classId,_that.className,_that.at,_that.coach,_that.lesson,_that.spots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String classId,  String className,  DateTime at,  String coach,  String lesson,  int spots)?  $default,) {final _that = this;
switch (_that) {
case _MakeupSlot() when $default != null:
return $default(_that.classId,_that.className,_that.at,_that.coach,_that.lesson,_that.spots);case _:
  return null;

}
}

}

/// @nodoc


class _MakeupSlot implements MakeupSlot {
  const _MakeupSlot({required this.classId, required this.className, required this.at, required this.coach, required this.lesson, required this.spots});
  

@override final  String classId;
@override final  String className;
@override final  DateTime at;
@override final  String coach;
@override final  String lesson;
@override final  int spots;

/// Create a copy of MakeupSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MakeupSlotCopyWith<_MakeupSlot> get copyWith => __$MakeupSlotCopyWithImpl<_MakeupSlot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MakeupSlot&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.className, className) || other.className == className)&&(identical(other.at, at) || other.at == at)&&(identical(other.coach, coach) || other.coach == coach)&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.spots, spots) || other.spots == spots));
}


@override
int get hashCode {
    return Object.hash(runtimeType,classId,className,at,coach,lesson,spots);
}

@override
String toString() {
    return 'MakeupSlot(classId: $classId, className: $className, at: $at, coach: $coach, lesson: $lesson, spots: $spots)';
}


}

/// @nodoc
abstract mixin class _$MakeupSlotCopyWith<$Res> implements $MakeupSlotCopyWith<$Res> {
  factory _$MakeupSlotCopyWith(_MakeupSlot value, $Res Function(_MakeupSlot) _then) = __$MakeupSlotCopyWithImpl;
@override @useResult
$Res call({
 String classId, String className, DateTime at, String coach, String lesson, int spots
});




}
/// @nodoc
class __$MakeupSlotCopyWithImpl<$Res>
    implements _$MakeupSlotCopyWith<$Res> {
  __$MakeupSlotCopyWithImpl(this._self, this._then);

  final _MakeupSlot _self;
  final $Res Function(_MakeupSlot) _then;

/// Create a copy of MakeupSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classId = null,Object? className = null,Object? at = null,Object? coach = null,Object? lesson = null,Object? spots = null,}) {
  return _then(_MakeupSlot(
classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,coach: null == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as String,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,spots: null == spots ? _self.spots : spots // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$EnrolRequest {

 String get id; String get academyId; String get student; int? get age; String get parent; String get classId; String get className; String get note; RequestState get state;
/// Create a copy of EnrolRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrolRequestCopyWith<EnrolRequest> get copyWith => _$EnrolRequestCopyWithImpl<EnrolRequest>(this as EnrolRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EnrolRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrolRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.academyId, _this.academyId) || other.academyId == _this.academyId)&&(identical(other.student, _this.student) || other.student == _this.student)&&(identical(other.age, _this.age) || other.age == _this.age)&&(identical(other.parent, _this.parent) || other.parent == _this.parent)&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&(identical(other.className, _this.className) || other.className == _this.className)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.state, _this.state) || other.state == _this.state));
}


@override
int get hashCode {
  final _this = this as EnrolRequest;
  return Object.hash(runtimeType,_this.id,_this.academyId,_this.student,_this.age,_this.parent,_this.classId,_this.className,_this.note,_this.state);
}

@override
String toString() {
  final _this = this as EnrolRequest;
  return 'EnrolRequest(id: ${_this.id}, academyId: ${_this.academyId}, student: ${_this.student}, age: ${_this.age}, parent: ${_this.parent}, classId: ${_this.classId}, className: ${_this.className}, note: ${_this.note}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $EnrolRequestCopyWith<$Res>  {
  factory $EnrolRequestCopyWith(EnrolRequest value, $Res Function(EnrolRequest) _then) = _$EnrolRequestCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String student, int? age, String parent, String classId, String className, String note, RequestState state
});




}
/// @nodoc
class _$EnrolRequestCopyWithImpl<$Res>
    implements $EnrolRequestCopyWith<$Res> {
  _$EnrolRequestCopyWithImpl(this._self, this._then);

  final EnrolRequest _self;
  final $Res Function(EnrolRequest) _then;

/// Create a copy of EnrolRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? student = null,Object? age = freezed,Object? parent = null,Object? classId = null,Object? className = null,Object? note = null,Object? state = null,}) {
  return _then(EnrolRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,parent: null == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RequestState,
  ));
}

}


/// Adds pattern-matching-related methods to [EnrolRequest].
extension EnrolRequestPatterns on EnrolRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrolRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrolRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrolRequest value)  $default,){
final _that = this;
switch (_that) {
case _EnrolRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrolRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EnrolRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String student,  int? age,  String parent,  String classId,  String className,  String note,  RequestState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrolRequest() when $default != null:
return $default(_that.id,_that.academyId,_that.student,_that.age,_that.parent,_that.classId,_that.className,_that.note,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String student,  int? age,  String parent,  String classId,  String className,  String note,  RequestState state)  $default,) {final _that = this;
switch (_that) {
case _EnrolRequest():
return $default(_that.id,_that.academyId,_that.student,_that.age,_that.parent,_that.classId,_that.className,_that.note,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String student,  int? age,  String parent,  String classId,  String className,  String note,  RequestState state)?  $default,) {final _that = this;
switch (_that) {
case _EnrolRequest() when $default != null:
return $default(_that.id,_that.academyId,_that.student,_that.age,_that.parent,_that.classId,_that.className,_that.note,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _EnrolRequest implements EnrolRequest {
  const _EnrolRequest({required this.id, required this.academyId, required this.student, this.age, this.parent = '', required this.classId, required this.className, this.note = '', this.state = RequestState.pending});
  

@override final  String id;
@override final  String academyId;
@override final  String student;
@override final  int? age;
@override@JsonKey() final  String parent;
@override final  String classId;
@override final  String className;
@override@JsonKey() final  String note;
@override@JsonKey() final  RequestState state;

/// Create a copy of EnrolRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrolRequestCopyWith<_EnrolRequest> get copyWith => __$EnrolRequestCopyWithImpl<_EnrolRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrolRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.student, student) || other.student == student)&&(identical(other.age, age) || other.age == age)&&(identical(other.parent, parent) || other.parent == parent)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.className, className) || other.className == className)&&(identical(other.note, note) || other.note == note)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,academyId,student,age,parent,classId,className,note,state);
}

@override
String toString() {
    return 'EnrolRequest(id: $id, academyId: $academyId, student: $student, age: $age, parent: $parent, classId: $classId, className: $className, note: $note, state: $state)';
}


}

/// @nodoc
abstract mixin class _$EnrolRequestCopyWith<$Res> implements $EnrolRequestCopyWith<$Res> {
  factory _$EnrolRequestCopyWith(_EnrolRequest value, $Res Function(_EnrolRequest) _then) = __$EnrolRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String student, int? age, String parent, String classId, String className, String note, RequestState state
});




}
/// @nodoc
class __$EnrolRequestCopyWithImpl<$Res>
    implements _$EnrolRequestCopyWith<$Res> {
  __$EnrolRequestCopyWithImpl(this._self, this._then);

  final _EnrolRequest _self;
  final $Res Function(_EnrolRequest) _then;

/// Create a copy of EnrolRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? student = null,Object? age = freezed,Object? parent = null,Object? classId = null,Object? className = null,Object? note = null,Object? state = null,}) {
  return _then(_EnrolRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as String,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,parent: null == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RequestState,
  ));
}


}

/// @nodoc
mixin _$CoachAlert {

 String get title; String get body; String get tone; String? get action;
/// Create a copy of CoachAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachAlertCopyWith<CoachAlert> get copyWith => _$CoachAlertCopyWithImpl<CoachAlert>(this as CoachAlert, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachAlert;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachAlert&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.tone, _this.tone) || other.tone == _this.tone)&&(identical(other.action, _this.action) || other.action == _this.action));
}


@override
int get hashCode {
  final _this = this as CoachAlert;
  return Object.hash(runtimeType,_this.title,_this.body,_this.tone,_this.action);
}

@override
String toString() {
  final _this = this as CoachAlert;
  return 'CoachAlert(title: ${_this.title}, body: ${_this.body}, tone: ${_this.tone}, action: ${_this.action})';
}


}

/// @nodoc
abstract mixin class $CoachAlertCopyWith<$Res>  {
  factory $CoachAlertCopyWith(CoachAlert value, $Res Function(CoachAlert) _then) = _$CoachAlertCopyWithImpl;
@useResult
$Res call({
 String title, String body, String tone, String? action
});




}
/// @nodoc
class _$CoachAlertCopyWithImpl<$Res>
    implements $CoachAlertCopyWith<$Res> {
  _$CoachAlertCopyWithImpl(this._self, this._then);

  final CoachAlert _self;
  final $Res Function(CoachAlert) _then;

/// Create a copy of CoachAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? body = null,Object? tone = null,Object? action = freezed,}) {
  return _then(CoachAlert(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as String,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachAlert].
extension CoachAlertPatterns on CoachAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachAlert value)  $default,){
final _that = this;
switch (_that) {
case _CoachAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachAlert value)?  $default,){
final _that = this;
switch (_that) {
case _CoachAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String body,  String tone,  String? action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachAlert() when $default != null:
return $default(_that.title,_that.body,_that.tone,_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String body,  String tone,  String? action)  $default,) {final _that = this;
switch (_that) {
case _CoachAlert():
return $default(_that.title,_that.body,_that.tone,_that.action);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String body,  String tone,  String? action)?  $default,) {final _that = this;
switch (_that) {
case _CoachAlert() when $default != null:
return $default(_that.title,_that.body,_that.tone,_that.action);case _:
  return null;

}
}

}

/// @nodoc


class _CoachAlert implements CoachAlert {
  const _CoachAlert({required this.title, required this.body, this.tone = 'navy', this.action});
  

@override final  String title;
@override final  String body;
@override@JsonKey() final  String tone;
@override final  String? action;

/// Create a copy of CoachAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachAlertCopyWith<_CoachAlert> get copyWith => __$CoachAlertCopyWithImpl<_CoachAlert>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachAlert&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,body,tone,action);
}

@override
String toString() {
    return 'CoachAlert(title: $title, body: $body, tone: $tone, action: $action)';
}


}

/// @nodoc
abstract mixin class _$CoachAlertCopyWith<$Res> implements $CoachAlertCopyWith<$Res> {
  factory _$CoachAlertCopyWith(_CoachAlert value, $Res Function(_CoachAlert) _then) = __$CoachAlertCopyWithImpl;
@override @useResult
$Res call({
 String title, String body, String tone, String? action
});




}
/// @nodoc
class __$CoachAlertCopyWithImpl<$Res>
    implements _$CoachAlertCopyWith<$Res> {
  __$CoachAlertCopyWithImpl(this._self, this._then);

  final _CoachAlert _self;
  final $Res Function(_CoachAlert) _then;

/// Create a copy of CoachAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? body = null,Object? tone = null,Object? action = freezed,}) {
  return _then(_CoachAlert(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as String,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SessionRecord {

 String get classId; Set<String> get absent; Map<String, SkillStatus> get focusSkill; String get note;
/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionRecordCopyWith<SessionRecord> get copyWith => _$SessionRecordCopyWithImpl<SessionRecord>(this as SessionRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SessionRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionRecord&&(identical(other.classId, _this.classId) || other.classId == _this.classId)&&const DeepCollectionEquality().equals(other.absent, _this.absent)&&const DeepCollectionEquality().equals(other.focusSkill, _this.focusSkill)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as SessionRecord;
  return Object.hash(runtimeType,_this.classId,const DeepCollectionEquality().hash(_this.absent),const DeepCollectionEquality().hash(_this.focusSkill),_this.note);
}

@override
String toString() {
  final _this = this as SessionRecord;
  return 'SessionRecord(classId: ${_this.classId}, absent: ${_this.absent}, focusSkill: ${_this.focusSkill}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $SessionRecordCopyWith<$Res>  {
  factory $SessionRecordCopyWith(SessionRecord value, $Res Function(SessionRecord) _then) = _$SessionRecordCopyWithImpl;
@useResult
$Res call({
 String classId, Set<String> absent, Map<String, SkillStatus> focusSkill, String note
});




}
/// @nodoc
class _$SessionRecordCopyWithImpl<$Res>
    implements $SessionRecordCopyWith<$Res> {
  _$SessionRecordCopyWithImpl(this._self, this._then);

  final SessionRecord _self;
  final $Res Function(SessionRecord) _then;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classId = null,Object? absent = null,Object? focusSkill = null,Object? note = null,}) {
  return _then(SessionRecord(
classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,absent: null == absent ? _self.absent : absent // ignore: cast_nullable_to_non_nullable
as Set<String>,focusSkill: null == focusSkill ? _self.focusSkill : focusSkill // ignore: cast_nullable_to_non_nullable
as Map<String, SkillStatus>,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionRecord].
extension SessionRecordPatterns on SessionRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionRecord value)  $default,){
final _that = this;
switch (_that) {
case _SessionRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String classId,  Set<String> absent,  Map<String, SkillStatus> focusSkill,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
return $default(_that.classId,_that.absent,_that.focusSkill,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String classId,  Set<String> absent,  Map<String, SkillStatus> focusSkill,  String note)  $default,) {final _that = this;
switch (_that) {
case _SessionRecord():
return $default(_that.classId,_that.absent,_that.focusSkill,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String classId,  Set<String> absent,  Map<String, SkillStatus> focusSkill,  String note)?  $default,) {final _that = this;
switch (_that) {
case _SessionRecord() when $default != null:
return $default(_that.classId,_that.absent,_that.focusSkill,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _SessionRecord implements SessionRecord {
  const _SessionRecord({required this.classId,  Set<String> absent = const {},  Map<String, SkillStatus> focusSkill = const {}, this.note = ''}): _absent = absent,_focusSkill = focusSkill;
  

@override final  String classId;
 final  Set<String> _absent;
@override@JsonKey() Set<String> get absent {
  if (_absent is EqualUnmodifiableSetView) return _absent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_absent);
}

 final  Map<String, SkillStatus> _focusSkill;
@override@JsonKey() Map<String, SkillStatus> get focusSkill {
  if (_focusSkill is EqualUnmodifiableMapView) return _focusSkill;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_focusSkill);
}

@override@JsonKey() final  String note;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionRecordCopyWith<_SessionRecord> get copyWith => __$SessionRecordCopyWithImpl<_SessionRecord>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionRecord&&(identical(other.classId, classId) || other.classId == classId)&&const DeepCollectionEquality().equals(other.absent, _absent)&&const DeepCollectionEquality().equals(other.focusSkill, _focusSkill)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,classId,const DeepCollectionEquality().hash(_absent),const DeepCollectionEquality().hash(_focusSkill),note);
}

@override
String toString() {
    return 'SessionRecord(classId: $classId, absent: $absent, focusSkill: $focusSkill, note: $note)';
}


}

/// @nodoc
abstract mixin class _$SessionRecordCopyWith<$Res> implements $SessionRecordCopyWith<$Res> {
  factory _$SessionRecordCopyWith(_SessionRecord value, $Res Function(_SessionRecord) _then) = __$SessionRecordCopyWithImpl;
@override @useResult
$Res call({
 String classId, Set<String> absent, Map<String, SkillStatus> focusSkill, String note
});




}
/// @nodoc
class __$SessionRecordCopyWithImpl<$Res>
    implements _$SessionRecordCopyWith<$Res> {
  __$SessionRecordCopyWithImpl(this._self, this._then);

  final _SessionRecord _self;
  final $Res Function(_SessionRecord) _then;

/// Create a copy of SessionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classId = null,Object? absent = null,Object? focusSkill = null,Object? note = null,}) {
  return _then(_SessionRecord(
classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,absent: null == absent ? _self._absent : absent // ignore: cast_nullable_to_non_nullable
as Set<String>,focusSkill: null == focusSkill ? _self._focusSkill : focusSkill // ignore: cast_nullable_to_non_nullable
as Map<String, SkillStatus>,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AcademyDraft {

 String get name; String get blurb; Set<String> get audience; List<String> get venues; Sport get sport; bool get template; Billing get billing; int get makeups; Set<String> get documents; List<String> get coachEmails;
/// Create a copy of AcademyDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademyDraftCopyWith<AcademyDraft> get copyWith => _$AcademyDraftCopyWithImpl<AcademyDraft>(this as AcademyDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AcademyDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcademyDraft&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.blurb, _this.blurb) || other.blurb == _this.blurb)&&const DeepCollectionEquality().equals(other.audience, _this.audience)&&const DeepCollectionEquality().equals(other.venues, _this.venues)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.template, _this.template) || other.template == _this.template)&&(identical(other.billing, _this.billing) || other.billing == _this.billing)&&(identical(other.makeups, _this.makeups) || other.makeups == _this.makeups)&&const DeepCollectionEquality().equals(other.documents, _this.documents)&&const DeepCollectionEquality().equals(other.coachEmails, _this.coachEmails));
}


@override
int get hashCode {
  final _this = this as AcademyDraft;
  return Object.hash(runtimeType,_this.name,_this.blurb,const DeepCollectionEquality().hash(_this.audience),const DeepCollectionEquality().hash(_this.venues),_this.sport,_this.template,_this.billing,_this.makeups,const DeepCollectionEquality().hash(_this.documents),const DeepCollectionEquality().hash(_this.coachEmails));
}

@override
String toString() {
  final _this = this as AcademyDraft;
  return 'AcademyDraft(name: ${_this.name}, blurb: ${_this.blurb}, audience: ${_this.audience}, venues: ${_this.venues}, sport: ${_this.sport}, template: ${_this.template}, billing: ${_this.billing}, makeups: ${_this.makeups}, documents: ${_this.documents}, coachEmails: ${_this.coachEmails})';
}


}

/// @nodoc
abstract mixin class $AcademyDraftCopyWith<$Res>  {
  factory $AcademyDraftCopyWith(AcademyDraft value, $Res Function(AcademyDraft) _then) = _$AcademyDraftCopyWithImpl;
@useResult
$Res call({
 String name, String blurb, Set<String> audience, List<String> venues, Sport sport, bool template, Billing billing, int makeups, Set<String> documents, List<String> coachEmails
});




}
/// @nodoc
class _$AcademyDraftCopyWithImpl<$Res>
    implements $AcademyDraftCopyWith<$Res> {
  _$AcademyDraftCopyWithImpl(this._self, this._then);

  final AcademyDraft _self;
  final $Res Function(AcademyDraft) _then;

/// Create a copy of AcademyDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? blurb = null,Object? audience = null,Object? venues = null,Object? sport = null,Object? template = null,Object? billing = null,Object? makeups = null,Object? documents = null,Object? coachEmails = null,}) {
  return _then(AcademyDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as Set<String>,venues: null == venues ? _self.venues : venues // ignore: cast_nullable_to_non_nullable
as List<String>,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,template: null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as bool,billing: null == billing ? _self.billing : billing // ignore: cast_nullable_to_non_nullable
as Billing,makeups: null == makeups ? _self.makeups : makeups // ignore: cast_nullable_to_non_nullable
as int,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as Set<String>,coachEmails: null == coachEmails ? _self.coachEmails : coachEmails // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AcademyDraft].
extension AcademyDraftPatterns on AcademyDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcademyDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcademyDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcademyDraft value)  $default,){
final _that = this;
switch (_that) {
case _AcademyDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcademyDraft value)?  $default,){
final _that = this;
switch (_that) {
case _AcademyDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String blurb,  Set<String> audience,  List<String> venues,  Sport sport,  bool template,  Billing billing,  int makeups,  Set<String> documents,  List<String> coachEmails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcademyDraft() when $default != null:
return $default(_that.name,_that.blurb,_that.audience,_that.venues,_that.sport,_that.template,_that.billing,_that.makeups,_that.documents,_that.coachEmails);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String blurb,  Set<String> audience,  List<String> venues,  Sport sport,  bool template,  Billing billing,  int makeups,  Set<String> documents,  List<String> coachEmails)  $default,) {final _that = this;
switch (_that) {
case _AcademyDraft():
return $default(_that.name,_that.blurb,_that.audience,_that.venues,_that.sport,_that.template,_that.billing,_that.makeups,_that.documents,_that.coachEmails);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String blurb,  Set<String> audience,  List<String> venues,  Sport sport,  bool template,  Billing billing,  int makeups,  Set<String> documents,  List<String> coachEmails)?  $default,) {final _that = this;
switch (_that) {
case _AcademyDraft() when $default != null:
return $default(_that.name,_that.blurb,_that.audience,_that.venues,_that.sport,_that.template,_that.billing,_that.makeups,_that.documents,_that.coachEmails);case _:
  return null;

}
}

}

/// @nodoc


class _AcademyDraft implements AcademyDraft {
  const _AcademyDraft({this.name = '', this.blurb = '',  Set<String> audience = const {'Kids'},  List<String> venues = const [], this.sport = Sport.badminton, this.template = true, this.billing = Billing.month, this.makeups = 2,  Set<String> documents = const {},  List<String> coachEmails = const []}): _audience = audience,_venues = venues,_documents = documents,_coachEmails = coachEmails;
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String blurb;
 final  Set<String> _audience;
@override@JsonKey() Set<String> get audience {
  if (_audience is EqualUnmodifiableSetView) return _audience;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_audience);
}

 final  List<String> _venues;
@override@JsonKey() List<String> get venues {
  if (_venues is EqualUnmodifiableListView) return _venues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_venues);
}

@override@JsonKey() final  Sport sport;
@override@JsonKey() final  bool template;
@override@JsonKey() final  Billing billing;
@override@JsonKey() final  int makeups;
 final  Set<String> _documents;
@override@JsonKey() Set<String> get documents {
  if (_documents is EqualUnmodifiableSetView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_documents);
}

 final  List<String> _coachEmails;
@override@JsonKey() List<String> get coachEmails {
  if (_coachEmails is EqualUnmodifiableListView) return _coachEmails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coachEmails);
}


/// Create a copy of AcademyDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademyDraftCopyWith<_AcademyDraft> get copyWith => __$AcademyDraftCopyWithImpl<_AcademyDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcademyDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.blurb, blurb) || other.blurb == blurb)&&const DeepCollectionEquality().equals(other.audience, _audience)&&const DeepCollectionEquality().equals(other.venues, _venues)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.template, template) || other.template == template)&&(identical(other.billing, billing) || other.billing == billing)&&(identical(other.makeups, makeups) || other.makeups == makeups)&&const DeepCollectionEquality().equals(other.documents, _documents)&&const DeepCollectionEquality().equals(other.coachEmails, _coachEmails));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,blurb,const DeepCollectionEquality().hash(_audience),const DeepCollectionEquality().hash(_venues),sport,template,billing,makeups,const DeepCollectionEquality().hash(_documents),const DeepCollectionEquality().hash(_coachEmails));
}

@override
String toString() {
    return 'AcademyDraft(name: $name, blurb: $blurb, audience: $audience, venues: $venues, sport: $sport, template: $template, billing: $billing, makeups: $makeups, documents: $documents, coachEmails: $coachEmails)';
}


}

/// @nodoc
abstract mixin class _$AcademyDraftCopyWith<$Res> implements $AcademyDraftCopyWith<$Res> {
  factory _$AcademyDraftCopyWith(_AcademyDraft value, $Res Function(_AcademyDraft) _then) = __$AcademyDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, String blurb, Set<String> audience, List<String> venues, Sport sport, bool template, Billing billing, int makeups, Set<String> documents, List<String> coachEmails
});




}
/// @nodoc
class __$AcademyDraftCopyWithImpl<$Res>
    implements _$AcademyDraftCopyWith<$Res> {
  __$AcademyDraftCopyWithImpl(this._self, this._then);

  final _AcademyDraft _self;
  final $Res Function(_AcademyDraft) _then;

/// Create a copy of AcademyDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? blurb = null,Object? audience = null,Object? venues = null,Object? sport = null,Object? template = null,Object? billing = null,Object? makeups = null,Object? documents = null,Object? coachEmails = null,}) {
  return _then(_AcademyDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,audience: null == audience ? _self._audience : audience // ignore: cast_nullable_to_non_nullable
as Set<String>,venues: null == venues ? _self._venues : venues // ignore: cast_nullable_to_non_nullable
as List<String>,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,template: null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as bool,billing: null == billing ? _self.billing : billing // ignore: cast_nullable_to_non_nullable
as Billing,makeups: null == makeups ? _self.makeups : makeups // ignore: cast_nullable_to_non_nullable
as int,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as Set<String>,coachEmails: null == coachEmails ? _self._coachEmails : coachEmails // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

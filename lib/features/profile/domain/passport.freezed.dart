// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'passport.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PassportStats {

 int get winRate; int get matches; int get meets; String get streak; List<bool> get form; List<StatCard> get cards; List<(String, int,)> get breakdown; List<MonthPoint> get months;
/// Create a copy of PassportStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PassportStatsCopyWith<PassportStats> get copyWith => _$PassportStatsCopyWithImpl<PassportStats>(this as PassportStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PassportStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PassportStats&&(identical(other.winRate, _this.winRate) || other.winRate == _this.winRate)&&(identical(other.matches, _this.matches) || other.matches == _this.matches)&&(identical(other.meets, _this.meets) || other.meets == _this.meets)&&(identical(other.streak, _this.streak) || other.streak == _this.streak)&&const DeepCollectionEquality().equals(other.form, _this.form)&&const DeepCollectionEquality().equals(other.cards, _this.cards)&&const DeepCollectionEquality().equals(other.breakdown, _this.breakdown)&&const DeepCollectionEquality().equals(other.months, _this.months));
}


@override
int get hashCode {
  final _this = this as PassportStats;
  return Object.hash(runtimeType,_this.winRate,_this.matches,_this.meets,_this.streak,const DeepCollectionEquality().hash(_this.form),const DeepCollectionEquality().hash(_this.cards),const DeepCollectionEquality().hash(_this.breakdown),const DeepCollectionEquality().hash(_this.months));
}

@override
String toString() {
  final _this = this as PassportStats;
  return 'PassportStats(winRate: ${_this.winRate}, matches: ${_this.matches}, meets: ${_this.meets}, streak: ${_this.streak}, form: ${_this.form}, cards: ${_this.cards}, breakdown: ${_this.breakdown}, months: ${_this.months})';
}


}

/// @nodoc
abstract mixin class $PassportStatsCopyWith<$Res>  {
  factory $PassportStatsCopyWith(PassportStats value, $Res Function(PassportStats) _then) = _$PassportStatsCopyWithImpl;
@useResult
$Res call({
 int winRate, int matches, int meets, String streak, List<bool> form, List<StatCard> cards, List<(String, int,)> breakdown, List<MonthPoint> months
});




}
/// @nodoc
class _$PassportStatsCopyWithImpl<$Res>
    implements $PassportStatsCopyWith<$Res> {
  _$PassportStatsCopyWithImpl(this._self, this._then);

  final PassportStats _self;
  final $Res Function(PassportStats) _then;

/// Create a copy of PassportStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? winRate = null,Object? matches = null,Object? meets = null,Object? streak = null,Object? form = null,Object? cards = null,Object? breakdown = null,Object? months = null,}) {
  return _then(PassportStats(
winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as int,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as int,meets: null == meets ? _self.meets : meets // ignore: cast_nullable_to_non_nullable
as int,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as String,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as List<bool>,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<StatCard>,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as List<(String, int,)>,months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as List<MonthPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [PassportStats].
extension PassportStatsPatterns on PassportStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PassportStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PassportStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PassportStats value)  $default,){
final _that = this;
switch (_that) {
case _PassportStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PassportStats value)?  $default,){
final _that = this;
switch (_that) {
case _PassportStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int winRate,  int matches,  int meets,  String streak,  List<bool> form,  List<StatCard> cards,  List<(String, int,)> breakdown,  List<MonthPoint> months)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PassportStats() when $default != null:
return $default(_that.winRate,_that.matches,_that.meets,_that.streak,_that.form,_that.cards,_that.breakdown,_that.months);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int winRate,  int matches,  int meets,  String streak,  List<bool> form,  List<StatCard> cards,  List<(String, int,)> breakdown,  List<MonthPoint> months)  $default,) {final _that = this;
switch (_that) {
case _PassportStats():
return $default(_that.winRate,_that.matches,_that.meets,_that.streak,_that.form,_that.cards,_that.breakdown,_that.months);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int winRate,  int matches,  int meets,  String streak,  List<bool> form,  List<StatCard> cards,  List<(String, int,)> breakdown,  List<MonthPoint> months)?  $default,) {final _that = this;
switch (_that) {
case _PassportStats() when $default != null:
return $default(_that.winRate,_that.matches,_that.meets,_that.streak,_that.form,_that.cards,_that.breakdown,_that.months);case _:
  return null;

}
}

}

/// @nodoc


class _PassportStats implements PassportStats {
  const _PassportStats({required this.winRate, required this.matches, required this.meets, required this.streak, required  List<bool> form, required  List<StatCard> cards, required  List<(String, int,)> breakdown, required  List<MonthPoint> months}): _form = form,_cards = cards,_breakdown = breakdown,_months = months;
  

@override final  int winRate;
@override final  int matches;
@override final  int meets;
@override final  String streak;
 final  List<bool> _form;
@override List<bool> get form {
  if (_form is EqualUnmodifiableListView) return _form;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_form);
}

 final  List<StatCard> _cards;
@override List<StatCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

 final  List<(String, int,)> _breakdown;
@override List<(String, int,)> get breakdown {
  if (_breakdown is EqualUnmodifiableListView) return _breakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breakdown);
}

 final  List<MonthPoint> _months;
@override List<MonthPoint> get months {
  if (_months is EqualUnmodifiableListView) return _months;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_months);
}


/// Create a copy of PassportStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PassportStatsCopyWith<_PassportStats> get copyWith => __$PassportStatsCopyWithImpl<_PassportStats>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PassportStats&&(identical(other.winRate, winRate) || other.winRate == winRate)&&(identical(other.matches, matches) || other.matches == matches)&&(identical(other.meets, meets) || other.meets == meets)&&(identical(other.streak, streak) || other.streak == streak)&&const DeepCollectionEquality().equals(other.form, _form)&&const DeepCollectionEquality().equals(other.cards, _cards)&&const DeepCollectionEquality().equals(other.breakdown, _breakdown)&&const DeepCollectionEquality().equals(other.months, _months));
}


@override
int get hashCode {
    return Object.hash(runtimeType,winRate,matches,meets,streak,const DeepCollectionEquality().hash(_form),const DeepCollectionEquality().hash(_cards),const DeepCollectionEquality().hash(_breakdown),const DeepCollectionEquality().hash(_months));
}

@override
String toString() {
    return 'PassportStats(winRate: $winRate, matches: $matches, meets: $meets, streak: $streak, form: $form, cards: $cards, breakdown: $breakdown, months: $months)';
}


}

/// @nodoc
abstract mixin class _$PassportStatsCopyWith<$Res> implements $PassportStatsCopyWith<$Res> {
  factory _$PassportStatsCopyWith(_PassportStats value, $Res Function(_PassportStats) _then) = __$PassportStatsCopyWithImpl;
@override @useResult
$Res call({
 int winRate, int matches, int meets, String streak, List<bool> form, List<StatCard> cards, List<(String, int,)> breakdown, List<MonthPoint> months
});




}
/// @nodoc
class __$PassportStatsCopyWithImpl<$Res>
    implements _$PassportStatsCopyWith<$Res> {
  __$PassportStatsCopyWithImpl(this._self, this._then);

  final _PassportStats _self;
  final $Res Function(_PassportStats) _then;

/// Create a copy of PassportStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? winRate = null,Object? matches = null,Object? meets = null,Object? streak = null,Object? form = null,Object? cards = null,Object? breakdown = null,Object? months = null,}) {
  return _then(_PassportStats(
winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as int,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as int,meets: null == meets ? _self.meets : meets // ignore: cast_nullable_to_non_nullable
as int,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as String,form: null == form ? _self._form : form // ignore: cast_nullable_to_non_nullable
as List<bool>,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<StatCard>,breakdown: null == breakdown ? _self._breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as List<(String, int,)>,months: null == months ? _self._months : months // ignore: cast_nullable_to_non_nullable
as List<MonthPoint>,
  ));
}


}

/// @nodoc
mixin _$StatCard {

 String get label; String get value; String get note;
/// Create a copy of StatCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatCardCopyWith<StatCard> get copyWith => _$StatCardCopyWithImpl<StatCard>(this as StatCard, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StatCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatCard&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as StatCard;
  return Object.hash(runtimeType,_this.label,_this.value,_this.note);
}

@override
String toString() {
  final _this = this as StatCard;
  return 'StatCard(label: ${_this.label}, value: ${_this.value}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $StatCardCopyWith<$Res>  {
  factory $StatCardCopyWith(StatCard value, $Res Function(StatCard) _then) = _$StatCardCopyWithImpl;
@useResult
$Res call({
 String label, String value, String note
});




}
/// @nodoc
class _$StatCardCopyWithImpl<$Res>
    implements $StatCardCopyWith<$Res> {
  _$StatCardCopyWithImpl(this._self, this._then);

  final StatCard _self;
  final $Res Function(StatCard) _then;

/// Create a copy of StatCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,Object? note = null,}) {
  return _then(StatCard(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StatCard].
extension StatCardPatterns on StatCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatCard value)  $default,){
final _that = this;
switch (_that) {
case _StatCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatCard value)?  $default,){
final _that = this;
switch (_that) {
case _StatCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String value,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatCard() when $default != null:
return $default(_that.label,_that.value,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String value,  String note)  $default,) {final _that = this;
switch (_that) {
case _StatCard():
return $default(_that.label,_that.value,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String value,  String note)?  $default,) {final _that = this;
switch (_that) {
case _StatCard() when $default != null:
return $default(_that.label,_that.value,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _StatCard implements StatCard {
  const _StatCard({required this.label, required this.value, required this.note});
  

@override final  String label;
@override final  String value;
@override final  String note;

/// Create a copy of StatCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatCardCopyWith<_StatCard> get copyWith => __$StatCardCopyWithImpl<_StatCard>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatCard&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,value,note);
}

@override
String toString() {
    return 'StatCard(label: $label, value: $value, note: $note)';
}


}

/// @nodoc
abstract mixin class _$StatCardCopyWith<$Res> implements $StatCardCopyWith<$Res> {
  factory _$StatCardCopyWith(_StatCard value, $Res Function(_StatCard) _then) = __$StatCardCopyWithImpl;
@override @useResult
$Res call({
 String label, String value, String note
});




}
/// @nodoc
class __$StatCardCopyWithImpl<$Res>
    implements _$StatCardCopyWith<$Res> {
  __$StatCardCopyWithImpl(this._self, this._then);

  final _StatCard _self;
  final $Res Function(_StatCard) _then;

/// Create a copy of StatCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,Object? note = null,}) {
  return _then(_StatCard(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MonthPoint {

 String get label; String get year; int get winRate; int get matches;
/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthPointCopyWith<MonthPoint> get copyWith => _$MonthPointCopyWithImpl<MonthPoint>(this as MonthPoint, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MonthPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthPoint&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.winRate, _this.winRate) || other.winRate == _this.winRate)&&(identical(other.matches, _this.matches) || other.matches == _this.matches));
}


@override
int get hashCode {
  final _this = this as MonthPoint;
  return Object.hash(runtimeType,_this.label,_this.year,_this.winRate,_this.matches);
}

@override
String toString() {
  final _this = this as MonthPoint;
  return 'MonthPoint(label: ${_this.label}, year: ${_this.year}, winRate: ${_this.winRate}, matches: ${_this.matches})';
}


}

/// @nodoc
abstract mixin class $MonthPointCopyWith<$Res>  {
  factory $MonthPointCopyWith(MonthPoint value, $Res Function(MonthPoint) _then) = _$MonthPointCopyWithImpl;
@useResult
$Res call({
 String label, String year, int winRate, int matches
});




}
/// @nodoc
class _$MonthPointCopyWithImpl<$Res>
    implements $MonthPointCopyWith<$Res> {
  _$MonthPointCopyWithImpl(this._self, this._then);

  final MonthPoint _self;
  final $Res Function(MonthPoint) _then;

/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? year = null,Object? winRate = null,Object? matches = null,}) {
  return _then(MonthPoint(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as String,winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as int,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthPoint].
extension MonthPointPatterns on MonthPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthPoint value)  $default,){
final _that = this;
switch (_that) {
case _MonthPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthPoint value)?  $default,){
final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String year,  int winRate,  int matches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
return $default(_that.label,_that.year,_that.winRate,_that.matches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String year,  int winRate,  int matches)  $default,) {final _that = this;
switch (_that) {
case _MonthPoint():
return $default(_that.label,_that.year,_that.winRate,_that.matches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String year,  int winRate,  int matches)?  $default,) {final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
return $default(_that.label,_that.year,_that.winRate,_that.matches);case _:
  return null;

}
}

}

/// @nodoc


class _MonthPoint implements MonthPoint {
  const _MonthPoint({required this.label, required this.year, required this.winRate, required this.matches});
  

@override final  String label;
@override final  String year;
@override final  int winRate;
@override final  int matches;

/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthPointCopyWith<_MonthPoint> get copyWith => __$MonthPointCopyWithImpl<_MonthPoint>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthPoint&&(identical(other.label, label) || other.label == label)&&(identical(other.year, year) || other.year == year)&&(identical(other.winRate, winRate) || other.winRate == winRate)&&(identical(other.matches, matches) || other.matches == matches));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,year,winRate,matches);
}

@override
String toString() {
    return 'MonthPoint(label: $label, year: $year, winRate: $winRate, matches: $matches)';
}


}

/// @nodoc
abstract mixin class _$MonthPointCopyWith<$Res> implements $MonthPointCopyWith<$Res> {
  factory _$MonthPointCopyWith(_MonthPoint value, $Res Function(_MonthPoint) _then) = __$MonthPointCopyWithImpl;
@override @useResult
$Res call({
 String label, String year, int winRate, int matches
});




}
/// @nodoc
class __$MonthPointCopyWithImpl<$Res>
    implements _$MonthPointCopyWith<$Res> {
  __$MonthPointCopyWithImpl(this._self, this._then);

  final _MonthPoint _self;
  final $Res Function(_MonthPoint) _then;

/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? year = null,Object? winRate = null,Object? matches = null,}) {
  return _then(_MonthPoint(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as String,winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as int,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$UpcomingGame {

 String get when; String get title; String get place; bool get waitlist;
/// Create a copy of UpcomingGame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpcomingGameCopyWith<UpcomingGame> get copyWith => _$UpcomingGameCopyWithImpl<UpcomingGame>(this as UpcomingGame, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UpcomingGame;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpcomingGame&&(identical(other.when, _this.when) || other.when == _this.when)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.place, _this.place) || other.place == _this.place)&&(identical(other.waitlist, _this.waitlist) || other.waitlist == _this.waitlist));
}


@override
int get hashCode {
  final _this = this as UpcomingGame;
  return Object.hash(runtimeType,_this.when,_this.title,_this.place,_this.waitlist);
}

@override
String toString() {
  final _this = this as UpcomingGame;
  return 'UpcomingGame(when: ${_this.when}, title: ${_this.title}, place: ${_this.place}, waitlist: ${_this.waitlist})';
}


}

/// @nodoc
abstract mixin class $UpcomingGameCopyWith<$Res>  {
  factory $UpcomingGameCopyWith(UpcomingGame value, $Res Function(UpcomingGame) _then) = _$UpcomingGameCopyWithImpl;
@useResult
$Res call({
 String when, String title, String place, bool waitlist
});




}
/// @nodoc
class _$UpcomingGameCopyWithImpl<$Res>
    implements $UpcomingGameCopyWith<$Res> {
  _$UpcomingGameCopyWithImpl(this._self, this._then);

  final UpcomingGame _self;
  final $Res Function(UpcomingGame) _then;

/// Create a copy of UpcomingGame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? when = null,Object? title = null,Object? place = null,Object? waitlist = null,}) {
  return _then(UpcomingGame(
when: null == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,waitlist: null == waitlist ? _self.waitlist : waitlist // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UpcomingGame].
extension UpcomingGamePatterns on UpcomingGame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpcomingGame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpcomingGame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpcomingGame value)  $default,){
final _that = this;
switch (_that) {
case _UpcomingGame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpcomingGame value)?  $default,){
final _that = this;
switch (_that) {
case _UpcomingGame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String when,  String title,  String place,  bool waitlist)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpcomingGame() when $default != null:
return $default(_that.when,_that.title,_that.place,_that.waitlist);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String when,  String title,  String place,  bool waitlist)  $default,) {final _that = this;
switch (_that) {
case _UpcomingGame():
return $default(_that.when,_that.title,_that.place,_that.waitlist);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String when,  String title,  String place,  bool waitlist)?  $default,) {final _that = this;
switch (_that) {
case _UpcomingGame() when $default != null:
return $default(_that.when,_that.title,_that.place,_that.waitlist);case _:
  return null;

}
}

}

/// @nodoc


class _UpcomingGame implements UpcomingGame {
  const _UpcomingGame({required this.when, required this.title, required this.place, this.waitlist = false});
  

@override final  String when;
@override final  String title;
@override final  String place;
@override@JsonKey() final  bool waitlist;

/// Create a copy of UpcomingGame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpcomingGameCopyWith<_UpcomingGame> get copyWith => __$UpcomingGameCopyWithImpl<_UpcomingGame>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpcomingGame&&(identical(other.when, when) || other.when == when)&&(identical(other.title, title) || other.title == title)&&(identical(other.place, place) || other.place == place)&&(identical(other.waitlist, waitlist) || other.waitlist == waitlist));
}


@override
int get hashCode {
    return Object.hash(runtimeType,when,title,place,waitlist);
}

@override
String toString() {
    return 'UpcomingGame(when: $when, title: $title, place: $place, waitlist: $waitlist)';
}


}

/// @nodoc
abstract mixin class _$UpcomingGameCopyWith<$Res> implements $UpcomingGameCopyWith<$Res> {
  factory _$UpcomingGameCopyWith(_UpcomingGame value, $Res Function(_UpcomingGame) _then) = __$UpcomingGameCopyWithImpl;
@override @useResult
$Res call({
 String when, String title, String place, bool waitlist
});




}
/// @nodoc
class __$UpcomingGameCopyWithImpl<$Res>
    implements _$UpcomingGameCopyWith<$Res> {
  __$UpcomingGameCopyWithImpl(this._self, this._then);

  final _UpcomingGame _self;
  final $Res Function(_UpcomingGame) _then;

/// Create a copy of UpcomingGame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? when = null,Object? title = null,Object? place = null,Object? waitlist = null,}) {
  return _then(_UpcomingGame(
when: null == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,waitlist: null == waitlist ? _self.waitlist : waitlist // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$GearItem {

 String get name; String get type; GearKind get kind; List<String> get tags; String? get price;
/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearItemCopyWith<GearItem> get copyWith => _$GearItemCopyWithImpl<GearItem>(this as GearItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GearItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearItem&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.price, _this.price) || other.price == _this.price));
}


@override
int get hashCode {
  final _this = this as GearItem;
  return Object.hash(runtimeType,_this.name,_this.type,_this.kind,const DeepCollectionEquality().hash(_this.tags),_this.price);
}

@override
String toString() {
  final _this = this as GearItem;
  return 'GearItem(name: ${_this.name}, type: ${_this.type}, kind: ${_this.kind}, tags: ${_this.tags}, price: ${_this.price})';
}


}

/// @nodoc
abstract mixin class $GearItemCopyWith<$Res>  {
  factory $GearItemCopyWith(GearItem value, $Res Function(GearItem) _then) = _$GearItemCopyWithImpl;
@useResult
$Res call({
 String name, String type, GearKind kind, List<String> tags, String? price
});




}
/// @nodoc
class _$GearItemCopyWithImpl<$Res>
    implements $GearItemCopyWith<$Res> {
  _$GearItemCopyWithImpl(this._self, this._then);

  final GearItem _self;
  final $Res Function(GearItem) _then;

/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? kind = null,Object? tags = null,Object? price = freezed,}) {
  return _then(GearItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GearKind,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GearItem].
extension GearItemPatterns on GearItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearItem value)  $default,){
final _that = this;
switch (_that) {
case _GearItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearItem value)?  $default,){
final _that = this;
switch (_that) {
case _GearItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String type,  GearKind kind,  List<String> tags,  String? price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearItem() when $default != null:
return $default(_that.name,_that.type,_that.kind,_that.tags,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String type,  GearKind kind,  List<String> tags,  String? price)  $default,) {final _that = this;
switch (_that) {
case _GearItem():
return $default(_that.name,_that.type,_that.kind,_that.tags,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String type,  GearKind kind,  List<String> tags,  String? price)?  $default,) {final _that = this;
switch (_that) {
case _GearItem() when $default != null:
return $default(_that.name,_that.type,_that.kind,_that.tags,_that.price);case _:
  return null;

}
}

}

/// @nodoc


class _GearItem implements GearItem {
  const _GearItem({required this.name, required this.type, required this.kind,  List<String> tags = const [], this.price}): _tags = tags;
  

@override final  String name;
@override final  String type;
@override final  GearKind kind;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String? price;

/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearItemCopyWith<_GearItem> get copyWith => __$GearItemCopyWithImpl<_GearItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearItem&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.price, price) || other.price == price));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,type,kind,const DeepCollectionEquality().hash(_tags),price);
}

@override
String toString() {
    return 'GearItem(name: $name, type: $type, kind: $kind, tags: $tags, price: $price)';
}


}

/// @nodoc
abstract mixin class _$GearItemCopyWith<$Res> implements $GearItemCopyWith<$Res> {
  factory _$GearItemCopyWith(_GearItem value, $Res Function(_GearItem) _then) = __$GearItemCopyWithImpl;
@override @useResult
$Res call({
 String name, String type, GearKind kind, List<String> tags, String? price
});




}
/// @nodoc
class __$GearItemCopyWithImpl<$Res>
    implements _$GearItemCopyWith<$Res> {
  __$GearItemCopyWithImpl(this._self, this._then);

  final _GearItem _self;
  final $Res Function(_GearItem) _then;

/// Create a copy of GearItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? kind = null,Object? tags = null,Object? price = freezed,}) {
  return _then(_GearItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GearKind,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

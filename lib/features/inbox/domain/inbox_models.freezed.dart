// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inbox_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InboxUpdate {

 String get id; String get title; String get body;/// Two letters (or "!") on the round tile.
 String get mark; int get color; int get ink;/// A square tile, for academies and clubs.
 bool get square;/// App path the row opens, e.g. `/activities/t-open`.
 String? get link; DateTime get at; bool get read;
/// Create a copy of InboxUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxUpdateCopyWith<InboxUpdate> get copyWith => _$InboxUpdateCopyWithImpl<InboxUpdate>(this as InboxUpdate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InboxUpdate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxUpdate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.mark, _this.mark) || other.mark == _this.mark)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.ink, _this.ink) || other.ink == _this.ink)&&(identical(other.square, _this.square) || other.square == _this.square)&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.read, _this.read) || other.read == _this.read));
}


@override
int get hashCode {
  final _this = this as InboxUpdate;
  return Object.hash(runtimeType,_this.id,_this.title,_this.body,_this.mark,_this.color,_this.ink,_this.square,_this.link,_this.at,_this.read);
}

@override
String toString() {
  final _this = this as InboxUpdate;
  return 'InboxUpdate(id: ${_this.id}, title: ${_this.title}, body: ${_this.body}, mark: ${_this.mark}, color: ${_this.color}, ink: ${_this.ink}, square: ${_this.square}, link: ${_this.link}, at: ${_this.at}, read: ${_this.read})';
}


}

/// @nodoc
abstract mixin class $InboxUpdateCopyWith<$Res>  {
  factory $InboxUpdateCopyWith(InboxUpdate value, $Res Function(InboxUpdate) _then) = _$InboxUpdateCopyWithImpl;
@useResult
$Res call({
 String id, String title, String body, String mark, int color, int ink, bool square, String? link, DateTime at, bool read
});




}
/// @nodoc
class _$InboxUpdateCopyWithImpl<$Res>
    implements $InboxUpdateCopyWith<$Res> {
  _$InboxUpdateCopyWithImpl(this._self, this._then);

  final InboxUpdate _self;
  final $Res Function(InboxUpdate) _then;

/// Create a copy of InboxUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? body = null,Object? mark = null,Object? color = null,Object? ink = null,Object? square = null,Object? link = freezed,Object? at = null,Object? read = null,}) {
  return _then(InboxUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,square: null == square ? _self.square : square // ignore: cast_nullable_to_non_nullable
as bool,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxUpdate].
extension InboxUpdatePatterns on InboxUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxUpdate value)  $default,){
final _that = this;
switch (_that) {
case _InboxUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _InboxUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String body,  String mark,  int color,  int ink,  bool square,  String? link,  DateTime at,  bool read)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxUpdate() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.mark,_that.color,_that.ink,_that.square,_that.link,_that.at,_that.read);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String body,  String mark,  int color,  int ink,  bool square,  String? link,  DateTime at,  bool read)  $default,) {final _that = this;
switch (_that) {
case _InboxUpdate():
return $default(_that.id,_that.title,_that.body,_that.mark,_that.color,_that.ink,_that.square,_that.link,_that.at,_that.read);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String body,  String mark,  int color,  int ink,  bool square,  String? link,  DateTime at,  bool read)?  $default,) {final _that = this;
switch (_that) {
case _InboxUpdate() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.mark,_that.color,_that.ink,_that.square,_that.link,_that.at,_that.read);case _:
  return null;

}
}

}

/// @nodoc


class _InboxUpdate implements InboxUpdate {
  const _InboxUpdate({required this.id, required this.title, this.body = '', required this.mark, this.color = 0xFF16181B, this.ink = 0xFFC6FF00, this.square = false, this.link, required this.at, this.read = false});
  

@override final  String id;
@override final  String title;
@override@JsonKey() final  String body;
/// Two letters (or "!") on the round tile.
@override final  String mark;
@override@JsonKey() final  int color;
@override@JsonKey() final  int ink;
/// A square tile, for academies and clubs.
@override@JsonKey() final  bool square;
/// App path the row opens, e.g. `/activities/t-open`.
@override final  String? link;
@override final  DateTime at;
@override@JsonKey() final  bool read;

/// Create a copy of InboxUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxUpdateCopyWith<_InboxUpdate> get copyWith => __$InboxUpdateCopyWithImpl<_InboxUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.mark, mark) || other.mark == mark)&&(identical(other.color, color) || other.color == color)&&(identical(other.ink, ink) || other.ink == ink)&&(identical(other.square, square) || other.square == square)&&(identical(other.link, link) || other.link == link)&&(identical(other.at, at) || other.at == at)&&(identical(other.read, read) || other.read == read));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,body,mark,color,ink,square,link,at,read);
}

@override
String toString() {
    return 'InboxUpdate(id: $id, title: $title, body: $body, mark: $mark, color: $color, ink: $ink, square: $square, link: $link, at: $at, read: $read)';
}


}

/// @nodoc
abstract mixin class _$InboxUpdateCopyWith<$Res> implements $InboxUpdateCopyWith<$Res> {
  factory _$InboxUpdateCopyWith(_InboxUpdate value, $Res Function(_InboxUpdate) _then) = __$InboxUpdateCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String body, String mark, int color, int ink, bool square, String? link, DateTime at, bool read
});




}
/// @nodoc
class __$InboxUpdateCopyWithImpl<$Res>
    implements _$InboxUpdateCopyWith<$Res> {
  __$InboxUpdateCopyWithImpl(this._self, this._then);

  final _InboxUpdate _self;
  final $Res Function(_InboxUpdate) _then;

/// Create a copy of InboxUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? body = null,Object? mark = null,Object? color = null,Object? ink = null,Object? square = null,Object? link = freezed,Object? at = null,Object? read = null,}) {
  return _then(_InboxUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,square: null == square ? _self.square : square // ignore: cast_nullable_to_non_nullable
as bool,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

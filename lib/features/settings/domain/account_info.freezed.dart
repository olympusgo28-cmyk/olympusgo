// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountInfo {

 String get email; String get phone; DateTime? get birthday; Country get region;
/// Create a copy of AccountInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountInfoCopyWith<AccountInfo> get copyWith => _$AccountInfoCopyWithImpl<AccountInfo>(this as AccountInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AccountInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountInfo&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.birthday, _this.birthday) || other.birthday == _this.birthday)&&(identical(other.region, _this.region) || other.region == _this.region));
}


@override
int get hashCode {
  final _this = this as AccountInfo;
  return Object.hash(runtimeType,_this.email,_this.phone,_this.birthday,_this.region);
}



}

/// @nodoc
abstract mixin class $AccountInfoCopyWith<$Res>  {
  factory $AccountInfoCopyWith(AccountInfo value, $Res Function(AccountInfo) _then) = _$AccountInfoCopyWithImpl;
@useResult
$Res call({
 String email, String phone, DateTime? birthday, Country region
});




}
/// @nodoc
class _$AccountInfoCopyWithImpl<$Res>
    implements $AccountInfoCopyWith<$Res> {
  _$AccountInfoCopyWithImpl(this._self, this._then);

  final AccountInfo _self;
  final $Res Function(AccountInfo) _then;

/// Create a copy of AccountInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? phone = null,Object? birthday = freezed,Object? region = null,}) {
  return _then(AccountInfo(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Country,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountInfo].
extension AccountInfoPatterns on AccountInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountInfo value)  $default,){
final _that = this;
switch (_that) {
case _AccountInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AccountInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String phone,  DateTime? birthday,  Country region)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountInfo() when $default != null:
return $default(_that.email,_that.phone,_that.birthday,_that.region);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String phone,  DateTime? birthday,  Country region)  $default,) {final _that = this;
switch (_that) {
case _AccountInfo():
return $default(_that.email,_that.phone,_that.birthday,_that.region);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String phone,  DateTime? birthday,  Country region)?  $default,) {final _that = this;
switch (_that) {
case _AccountInfo() when $default != null:
return $default(_that.email,_that.phone,_that.birthday,_that.region);case _:
  return null;

}
}

}

/// @nodoc


class _AccountInfo extends AccountInfo {
  const _AccountInfo({this.email = '', this.phone = '', this.birthday, this.region = Country.singapore}): super._();
  

@override@JsonKey() final  String email;
@override@JsonKey() final  String phone;
@override final  DateTime? birthday;
@override@JsonKey() final  Country region;

/// Create a copy of AccountInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountInfoCopyWith<_AccountInfo> get copyWith => __$AccountInfoCopyWithImpl<_AccountInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountInfo&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.region, region) || other.region == region));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,phone,birthday,region);
}



}

/// @nodoc
abstract mixin class _$AccountInfoCopyWith<$Res> implements $AccountInfoCopyWith<$Res> {
  factory _$AccountInfoCopyWith(_AccountInfo value, $Res Function(_AccountInfo) _then) = __$AccountInfoCopyWithImpl;
@override @useResult
$Res call({
 String email, String phone, DateTime? birthday, Country region
});




}
/// @nodoc
class __$AccountInfoCopyWithImpl<$Res>
    implements _$AccountInfoCopyWith<$Res> {
  __$AccountInfoCopyWithImpl(this._self, this._then);

  final _AccountInfo _self;
  final $Res Function(_AccountInfo) _then;

/// Create a copy of AccountInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? phone = null,Object? birthday = freezed,Object? region = null,}) {
  return _then(_AccountInfo(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as Country,
  ));
}


}

// dart format on

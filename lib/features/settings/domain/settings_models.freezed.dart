// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountDetails {

 String get fullName; String get username; String get bio; Gender get gender; String? get avatarUrl;
/// Create a copy of AccountDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDetailsCopyWith<AccountDetails> get copyWith => _$AccountDetailsCopyWithImpl<AccountDetails>(this as AccountDetails, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AccountDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDetails&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.gender, _this.gender) || other.gender == _this.gender)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}


@override
int get hashCode {
  final _this = this as AccountDetails;
  return Object.hash(runtimeType,_this.fullName,_this.username,_this.bio,_this.gender,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as AccountDetails;
  return 'AccountDetails(fullName: ${_this.fullName}, username: ${_this.username}, bio: ${_this.bio}, gender: ${_this.gender}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $AccountDetailsCopyWith<$Res>  {
  factory $AccountDetailsCopyWith(AccountDetails value, $Res Function(AccountDetails) _then) = _$AccountDetailsCopyWithImpl;
@useResult
$Res call({
 String fullName, String username, String bio, Gender gender, String? avatarUrl
});




}
/// @nodoc
class _$AccountDetailsCopyWithImpl<$Res>
    implements $AccountDetailsCopyWith<$Res> {
  _$AccountDetailsCopyWithImpl(this._self, this._then);

  final AccountDetails _self;
  final $Res Function(AccountDetails) _then;

/// Create a copy of AccountDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? username = null,Object? bio = null,Object? gender = null,Object? avatarUrl = freezed,}) {
  return _then(AccountDetails(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountDetails].
extension AccountDetailsPatterns on AccountDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDetails value)  $default,){
final _that = this;
switch (_that) {
case _AccountDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDetails value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String username,  String bio,  Gender gender,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDetails() when $default != null:
return $default(_that.fullName,_that.username,_that.bio,_that.gender,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String username,  String bio,  Gender gender,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _AccountDetails():
return $default(_that.fullName,_that.username,_that.bio,_that.gender,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String username,  String bio,  Gender gender,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _AccountDetails() when $default != null:
return $default(_that.fullName,_that.username,_that.bio,_that.gender,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _AccountDetails implements AccountDetails {
  const _AccountDetails({this.fullName = '', this.username = '', this.bio = '', this.gender = Gender.preferNotToSay, this.avatarUrl});
  

@override@JsonKey() final  String fullName;
@override@JsonKey() final  String username;
@override@JsonKey() final  String bio;
@override@JsonKey() final  Gender gender;
@override final  String? avatarUrl;

/// Create a copy of AccountDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDetailsCopyWith<_AccountDetails> get copyWith => __$AccountDetailsCopyWithImpl<_AccountDetails>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDetails&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fullName,username,bio,gender,avatarUrl);
}

@override
String toString() {
    return 'AccountDetails(fullName: $fullName, username: $username, bio: $bio, gender: $gender, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$AccountDetailsCopyWith<$Res> implements $AccountDetailsCopyWith<$Res> {
  factory _$AccountDetailsCopyWith(_AccountDetails value, $Res Function(_AccountDetails) _then) = __$AccountDetailsCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String username, String bio, Gender gender, String? avatarUrl
});




}
/// @nodoc
class __$AccountDetailsCopyWithImpl<$Res>
    implements _$AccountDetailsCopyWith<$Res> {
  __$AccountDetailsCopyWithImpl(this._self, this._then);

  final _AccountDetails _self;
  final $Res Function(_AccountDetails) _then;

/// Create a copy of AccountDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? username = null,Object? bio = null,Object? gender = null,Object? avatarUrl = freezed,}) {
  return _then(_AccountDetails(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PrivateInfo {

 String get email; String get phone; DateTime? get birthday; Country get country;/// Checked by the review team; needed to run paid tournaments and
/// receive payouts.
 bool get identityVerified;
/// Create a copy of PrivateInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivateInfoCopyWith<PrivateInfo> get copyWith => _$PrivateInfoCopyWithImpl<PrivateInfo>(this as PrivateInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PrivateInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivateInfo&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.birthday, _this.birthday) || other.birthday == _this.birthday)&&(identical(other.country, _this.country) || other.country == _this.country)&&(identical(other.identityVerified, _this.identityVerified) || other.identityVerified == _this.identityVerified));
}


@override
int get hashCode {
  final _this = this as PrivateInfo;
  return Object.hash(runtimeType,_this.email,_this.phone,_this.birthday,_this.country,_this.identityVerified);
}

@override
String toString() {
  final _this = this as PrivateInfo;
  return 'PrivateInfo(email: ${_this.email}, phone: ${_this.phone}, birthday: ${_this.birthday}, country: ${_this.country}, identityVerified: ${_this.identityVerified})';
}


}

/// @nodoc
abstract mixin class $PrivateInfoCopyWith<$Res>  {
  factory $PrivateInfoCopyWith(PrivateInfo value, $Res Function(PrivateInfo) _then) = _$PrivateInfoCopyWithImpl;
@useResult
$Res call({
 String email, String phone, DateTime? birthday, Country country, bool identityVerified
});




}
/// @nodoc
class _$PrivateInfoCopyWithImpl<$Res>
    implements $PrivateInfoCopyWith<$Res> {
  _$PrivateInfoCopyWithImpl(this._self, this._then);

  final PrivateInfo _self;
  final $Res Function(PrivateInfo) _then;

/// Create a copy of PrivateInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? phone = null,Object? birthday = freezed,Object? country = null,Object? identityVerified = null,}) {
  return _then(PrivateInfo(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as Country,identityVerified: null == identityVerified ? _self.identityVerified : identityVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PrivateInfo].
extension PrivateInfoPatterns on PrivateInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrivateInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrivateInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrivateInfo value)  $default,){
final _that = this;
switch (_that) {
case _PrivateInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrivateInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PrivateInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String phone,  DateTime? birthday,  Country country,  bool identityVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrivateInfo() when $default != null:
return $default(_that.email,_that.phone,_that.birthday,_that.country,_that.identityVerified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String phone,  DateTime? birthday,  Country country,  bool identityVerified)  $default,) {final _that = this;
switch (_that) {
case _PrivateInfo():
return $default(_that.email,_that.phone,_that.birthday,_that.country,_that.identityVerified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String phone,  DateTime? birthday,  Country country,  bool identityVerified)?  $default,) {final _that = this;
switch (_that) {
case _PrivateInfo() when $default != null:
return $default(_that.email,_that.phone,_that.birthday,_that.country,_that.identityVerified);case _:
  return null;

}
}

}

/// @nodoc


class _PrivateInfo implements PrivateInfo {
  const _PrivateInfo({this.email = '', this.phone = '', this.birthday, this.country = Country.singapore, this.identityVerified = false});
  

@override@JsonKey() final  String email;
@override@JsonKey() final  String phone;
@override final  DateTime? birthday;
@override@JsonKey() final  Country country;
/// Checked by the review team; needed to run paid tournaments and
/// receive payouts.
@override@JsonKey() final  bool identityVerified;

/// Create a copy of PrivateInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrivateInfoCopyWith<_PrivateInfo> get copyWith => __$PrivateInfoCopyWithImpl<_PrivateInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrivateInfo&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.country, country) || other.country == country)&&(identical(other.identityVerified, identityVerified) || other.identityVerified == identityVerified));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,phone,birthday,country,identityVerified);
}

@override
String toString() {
    return 'PrivateInfo(email: $email, phone: $phone, birthday: $birthday, country: $country, identityVerified: $identityVerified)';
}


}

/// @nodoc
abstract mixin class _$PrivateInfoCopyWith<$Res> implements $PrivateInfoCopyWith<$Res> {
  factory _$PrivateInfoCopyWith(_PrivateInfo value, $Res Function(_PrivateInfo) _then) = __$PrivateInfoCopyWithImpl;
@override @useResult
$Res call({
 String email, String phone, DateTime? birthday, Country country, bool identityVerified
});




}
/// @nodoc
class __$PrivateInfoCopyWithImpl<$Res>
    implements _$PrivateInfoCopyWith<$Res> {
  __$PrivateInfoCopyWithImpl(this._self, this._then);

  final _PrivateInfo _self;
  final $Res Function(_PrivateInfo) _then;

/// Create a copy of PrivateInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? phone = null,Object? birthday = freezed,Object? country = null,Object? identityVerified = null,}) {
  return _then(_PrivateInfo(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as Country,identityVerified: null == identityVerified ? _self.identityVerified : identityVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$NotificationPrefs {

 bool get meetReminders; bool get courtCalls; bool get messages; bool get newFollowers; bool get offersAndNews;
/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPrefsCopyWith<NotificationPrefs> get copyWith => _$NotificationPrefsCopyWithImpl<NotificationPrefs>(this as NotificationPrefs, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NotificationPrefs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPrefs&&(identical(other.meetReminders, _this.meetReminders) || other.meetReminders == _this.meetReminders)&&(identical(other.courtCalls, _this.courtCalls) || other.courtCalls == _this.courtCalls)&&(identical(other.messages, _this.messages) || other.messages == _this.messages)&&(identical(other.newFollowers, _this.newFollowers) || other.newFollowers == _this.newFollowers)&&(identical(other.offersAndNews, _this.offersAndNews) || other.offersAndNews == _this.offersAndNews));
}


@override
int get hashCode {
  final _this = this as NotificationPrefs;
  return Object.hash(runtimeType,_this.meetReminders,_this.courtCalls,_this.messages,_this.newFollowers,_this.offersAndNews);
}

@override
String toString() {
  final _this = this as NotificationPrefs;
  return 'NotificationPrefs(meetReminders: ${_this.meetReminders}, courtCalls: ${_this.courtCalls}, messages: ${_this.messages}, newFollowers: ${_this.newFollowers}, offersAndNews: ${_this.offersAndNews})';
}


}

/// @nodoc
abstract mixin class $NotificationPrefsCopyWith<$Res>  {
  factory $NotificationPrefsCopyWith(NotificationPrefs value, $Res Function(NotificationPrefs) _then) = _$NotificationPrefsCopyWithImpl;
@useResult
$Res call({
 bool meetReminders, bool courtCalls, bool messages, bool newFollowers, bool offersAndNews
});




}
/// @nodoc
class _$NotificationPrefsCopyWithImpl<$Res>
    implements $NotificationPrefsCopyWith<$Res> {
  _$NotificationPrefsCopyWithImpl(this._self, this._then);

  final NotificationPrefs _self;
  final $Res Function(NotificationPrefs) _then;

/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meetReminders = null,Object? courtCalls = null,Object? messages = null,Object? newFollowers = null,Object? offersAndNews = null,}) {
  return _then(NotificationPrefs(
meetReminders: null == meetReminders ? _self.meetReminders : meetReminders // ignore: cast_nullable_to_non_nullable
as bool,courtCalls: null == courtCalls ? _self.courtCalls : courtCalls // ignore: cast_nullable_to_non_nullable
as bool,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as bool,newFollowers: null == newFollowers ? _self.newFollowers : newFollowers // ignore: cast_nullable_to_non_nullable
as bool,offersAndNews: null == offersAndNews ? _self.offersAndNews : offersAndNews // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPrefs].
extension NotificationPrefsPatterns on NotificationPrefs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPrefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPrefs value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPrefs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPrefs value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool meetReminders,  bool courtCalls,  bool messages,  bool newFollowers,  bool offersAndNews)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
return $default(_that.meetReminders,_that.courtCalls,_that.messages,_that.newFollowers,_that.offersAndNews);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool meetReminders,  bool courtCalls,  bool messages,  bool newFollowers,  bool offersAndNews)  $default,) {final _that = this;
switch (_that) {
case _NotificationPrefs():
return $default(_that.meetReminders,_that.courtCalls,_that.messages,_that.newFollowers,_that.offersAndNews);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool meetReminders,  bool courtCalls,  bool messages,  bool newFollowers,  bool offersAndNews)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPrefs() when $default != null:
return $default(_that.meetReminders,_that.courtCalls,_that.messages,_that.newFollowers,_that.offersAndNews);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationPrefs implements NotificationPrefs {
  const _NotificationPrefs({this.meetReminders = true, this.courtCalls = true, this.messages = true, this.newFollowers = true, this.offersAndNews = false});
  

@override@JsonKey() final  bool meetReminders;
@override@JsonKey() final  bool courtCalls;
@override@JsonKey() final  bool messages;
@override@JsonKey() final  bool newFollowers;
@override@JsonKey() final  bool offersAndNews;

/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPrefsCopyWith<_NotificationPrefs> get copyWith => __$NotificationPrefsCopyWithImpl<_NotificationPrefs>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPrefs&&(identical(other.meetReminders, meetReminders) || other.meetReminders == meetReminders)&&(identical(other.courtCalls, courtCalls) || other.courtCalls == courtCalls)&&(identical(other.messages, messages) || other.messages == messages)&&(identical(other.newFollowers, newFollowers) || other.newFollowers == newFollowers)&&(identical(other.offersAndNews, offersAndNews) || other.offersAndNews == offersAndNews));
}


@override
int get hashCode {
    return Object.hash(runtimeType,meetReminders,courtCalls,messages,newFollowers,offersAndNews);
}

@override
String toString() {
    return 'NotificationPrefs(meetReminders: $meetReminders, courtCalls: $courtCalls, messages: $messages, newFollowers: $newFollowers, offersAndNews: $offersAndNews)';
}


}

/// @nodoc
abstract mixin class _$NotificationPrefsCopyWith<$Res> implements $NotificationPrefsCopyWith<$Res> {
  factory _$NotificationPrefsCopyWith(_NotificationPrefs value, $Res Function(_NotificationPrefs) _then) = __$NotificationPrefsCopyWithImpl;
@override @useResult
$Res call({
 bool meetReminders, bool courtCalls, bool messages, bool newFollowers, bool offersAndNews
});




}
/// @nodoc
class __$NotificationPrefsCopyWithImpl<$Res>
    implements _$NotificationPrefsCopyWith<$Res> {
  __$NotificationPrefsCopyWithImpl(this._self, this._then);

  final _NotificationPrefs _self;
  final $Res Function(_NotificationPrefs) _then;

/// Create a copy of NotificationPrefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meetReminders = null,Object? courtCalls = null,Object? messages = null,Object? newFollowers = null,Object? offersAndNews = null,}) {
  return _then(_NotificationPrefs(
meetReminders: null == meetReminders ? _self.meetReminders : meetReminders // ignore: cast_nullable_to_non_nullable
as bool,courtCalls: null == courtCalls ? _self.courtCalls : courtCalls // ignore: cast_nullable_to_non_nullable
as bool,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as bool,newFollowers: null == newFollowers ? _self.newFollowers : newFollowers // ignore: cast_nullable_to_non_nullable
as bool,offersAndNews: null == offersAndNews ? _self.offersAndNews : offersAndNews // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PrivacyPrefs {

 ProfileVisibility get visibility; bool get showLevel; bool get findableByPhone; bool get shareLocationAtMeets;
/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacyPrefsCopyWith<PrivacyPrefs> get copyWith => _$PrivacyPrefsCopyWithImpl<PrivacyPrefs>(this as PrivacyPrefs, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PrivacyPrefs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacyPrefs&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&(identical(other.showLevel, _this.showLevel) || other.showLevel == _this.showLevel)&&(identical(other.findableByPhone, _this.findableByPhone) || other.findableByPhone == _this.findableByPhone)&&(identical(other.shareLocationAtMeets, _this.shareLocationAtMeets) || other.shareLocationAtMeets == _this.shareLocationAtMeets));
}


@override
int get hashCode {
  final _this = this as PrivacyPrefs;
  return Object.hash(runtimeType,_this.visibility,_this.showLevel,_this.findableByPhone,_this.shareLocationAtMeets);
}

@override
String toString() {
  final _this = this as PrivacyPrefs;
  return 'PrivacyPrefs(visibility: ${_this.visibility}, showLevel: ${_this.showLevel}, findableByPhone: ${_this.findableByPhone}, shareLocationAtMeets: ${_this.shareLocationAtMeets})';
}


}

/// @nodoc
abstract mixin class $PrivacyPrefsCopyWith<$Res>  {
  factory $PrivacyPrefsCopyWith(PrivacyPrefs value, $Res Function(PrivacyPrefs) _then) = _$PrivacyPrefsCopyWithImpl;
@useResult
$Res call({
 ProfileVisibility visibility, bool showLevel, bool findableByPhone, bool shareLocationAtMeets
});




}
/// @nodoc
class _$PrivacyPrefsCopyWithImpl<$Res>
    implements $PrivacyPrefsCopyWith<$Res> {
  _$PrivacyPrefsCopyWithImpl(this._self, this._then);

  final PrivacyPrefs _self;
  final $Res Function(PrivacyPrefs) _then;

/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? visibility = null,Object? showLevel = null,Object? findableByPhone = null,Object? shareLocationAtMeets = null,}) {
  return _then(PrivacyPrefs(
visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ProfileVisibility,showLevel: null == showLevel ? _self.showLevel : showLevel // ignore: cast_nullable_to_non_nullable
as bool,findableByPhone: null == findableByPhone ? _self.findableByPhone : findableByPhone // ignore: cast_nullable_to_non_nullable
as bool,shareLocationAtMeets: null == shareLocationAtMeets ? _self.shareLocationAtMeets : shareLocationAtMeets // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PrivacyPrefs].
extension PrivacyPrefsPatterns on PrivacyPrefs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrivacyPrefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrivacyPrefs value)  $default,){
final _that = this;
switch (_that) {
case _PrivacyPrefs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrivacyPrefs value)?  $default,){
final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProfileVisibility visibility,  bool showLevel,  bool findableByPhone,  bool shareLocationAtMeets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
return $default(_that.visibility,_that.showLevel,_that.findableByPhone,_that.shareLocationAtMeets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProfileVisibility visibility,  bool showLevel,  bool findableByPhone,  bool shareLocationAtMeets)  $default,) {final _that = this;
switch (_that) {
case _PrivacyPrefs():
return $default(_that.visibility,_that.showLevel,_that.findableByPhone,_that.shareLocationAtMeets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProfileVisibility visibility,  bool showLevel,  bool findableByPhone,  bool shareLocationAtMeets)?  $default,) {final _that = this;
switch (_that) {
case _PrivacyPrefs() when $default != null:
return $default(_that.visibility,_that.showLevel,_that.findableByPhone,_that.shareLocationAtMeets);case _:
  return null;

}
}

}

/// @nodoc


class _PrivacyPrefs implements PrivacyPrefs {
  const _PrivacyPrefs({this.visibility = ProfileVisibility.followers, this.showLevel = true, this.findableByPhone = false, this.shareLocationAtMeets = true});
  

@override@JsonKey() final  ProfileVisibility visibility;
@override@JsonKey() final  bool showLevel;
@override@JsonKey() final  bool findableByPhone;
@override@JsonKey() final  bool shareLocationAtMeets;

/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrivacyPrefsCopyWith<_PrivacyPrefs> get copyWith => __$PrivacyPrefsCopyWithImpl<_PrivacyPrefs>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrivacyPrefs&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.showLevel, showLevel) || other.showLevel == showLevel)&&(identical(other.findableByPhone, findableByPhone) || other.findableByPhone == findableByPhone)&&(identical(other.shareLocationAtMeets, shareLocationAtMeets) || other.shareLocationAtMeets == shareLocationAtMeets));
}


@override
int get hashCode {
    return Object.hash(runtimeType,visibility,showLevel,findableByPhone,shareLocationAtMeets);
}

@override
String toString() {
    return 'PrivacyPrefs(visibility: $visibility, showLevel: $showLevel, findableByPhone: $findableByPhone, shareLocationAtMeets: $shareLocationAtMeets)';
}


}

/// @nodoc
abstract mixin class _$PrivacyPrefsCopyWith<$Res> implements $PrivacyPrefsCopyWith<$Res> {
  factory _$PrivacyPrefsCopyWith(_PrivacyPrefs value, $Res Function(_PrivacyPrefs) _then) = __$PrivacyPrefsCopyWithImpl;
@override @useResult
$Res call({
 ProfileVisibility visibility, bool showLevel, bool findableByPhone, bool shareLocationAtMeets
});




}
/// @nodoc
class __$PrivacyPrefsCopyWithImpl<$Res>
    implements _$PrivacyPrefsCopyWith<$Res> {
  __$PrivacyPrefsCopyWithImpl(this._self, this._then);

  final _PrivacyPrefs _self;
  final $Res Function(_PrivacyPrefs) _then;

/// Create a copy of PrivacyPrefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? visibility = null,Object? showLevel = null,Object? findableByPhone = null,Object? shareLocationAtMeets = null,}) {
  return _then(_PrivacyPrefs(
visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ProfileVisibility,showLevel: null == showLevel ? _self.showLevel : showLevel // ignore: cast_nullable_to_non_nullable
as bool,findableByPhone: null == findableByPhone ? _self.findableByPhone : findableByPhone // ignore: cast_nullable_to_non_nullable
as bool,shareLocationAtMeets: null == shareLocationAtMeets ? _self.shareLocationAtMeets : shareLocationAtMeets // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

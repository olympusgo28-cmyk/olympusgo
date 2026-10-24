// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Mall {

 String get id; String get name; String get initials; String get blurb; int get color; int get ink; bool get pointsAccepted;
/// Create a copy of Mall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MallCopyWith<Mall> get copyWith => _$MallCopyWithImpl<Mall>(this as Mall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Mall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Mall&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.initials, _this.initials) || other.initials == _this.initials)&&(identical(other.blurb, _this.blurb) || other.blurb == _this.blurb)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.ink, _this.ink) || other.ink == _this.ink)&&(identical(other.pointsAccepted, _this.pointsAccepted) || other.pointsAccepted == _this.pointsAccepted));
}


@override
int get hashCode {
  final _this = this as Mall;
  return Object.hash(runtimeType,_this.id,_this.name,_this.initials,_this.blurb,_this.color,_this.ink,_this.pointsAccepted);
}

@override
String toString() {
  final _this = this as Mall;
  return 'Mall(id: ${_this.id}, name: ${_this.name}, initials: ${_this.initials}, blurb: ${_this.blurb}, color: ${_this.color}, ink: ${_this.ink}, pointsAccepted: ${_this.pointsAccepted})';
}


}

/// @nodoc
abstract mixin class $MallCopyWith<$Res>  {
  factory $MallCopyWith(Mall value, $Res Function(Mall) _then) = _$MallCopyWithImpl;
@useResult
$Res call({
 String id, String name, String initials, String blurb, int color, int ink, bool pointsAccepted
});




}
/// @nodoc
class _$MallCopyWithImpl<$Res>
    implements $MallCopyWith<$Res> {
  _$MallCopyWithImpl(this._self, this._then);

  final Mall _self;
  final $Res Function(Mall) _then;

/// Create a copy of Mall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? initials = null,Object? blurb = null,Object? color = null,Object? ink = null,Object? pointsAccepted = null,}) {
  return _then(Mall(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initials: null == initials ? _self.initials : initials // ignore: cast_nullable_to_non_nullable
as String,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,pointsAccepted: null == pointsAccepted ? _self.pointsAccepted : pointsAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Mall].
extension MallPatterns on Mall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Mall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Mall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Mall value)  $default,){
final _that = this;
switch (_that) {
case _Mall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Mall value)?  $default,){
final _that = this;
switch (_that) {
case _Mall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String initials,  String blurb,  int color,  int ink,  bool pointsAccepted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Mall() when $default != null:
return $default(_that.id,_that.name,_that.initials,_that.blurb,_that.color,_that.ink,_that.pointsAccepted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String initials,  String blurb,  int color,  int ink,  bool pointsAccepted)  $default,) {final _that = this;
switch (_that) {
case _Mall():
return $default(_that.id,_that.name,_that.initials,_that.blurb,_that.color,_that.ink,_that.pointsAccepted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String initials,  String blurb,  int color,  int ink,  bool pointsAccepted)?  $default,) {final _that = this;
switch (_that) {
case _Mall() when $default != null:
return $default(_that.id,_that.name,_that.initials,_that.blurb,_that.color,_that.ink,_that.pointsAccepted);case _:
  return null;

}
}

}

/// @nodoc


class _Mall implements Mall {
  const _Mall({required this.id, required this.name, required this.initials, this.blurb = '', this.color = 0xFFFBE7B0, this.ink = 0xFF5A4300, this.pointsAccepted = true});
  

@override final  String id;
@override final  String name;
@override final  String initials;
@override@JsonKey() final  String blurb;
@override@JsonKey() final  int color;
@override@JsonKey() final  int ink;
@override@JsonKey() final  bool pointsAccepted;

/// Create a copy of Mall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MallCopyWith<_Mall> get copyWith => __$MallCopyWithImpl<_Mall>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Mall&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.initials, initials) || other.initials == initials)&&(identical(other.blurb, blurb) || other.blurb == blurb)&&(identical(other.color, color) || other.color == color)&&(identical(other.ink, ink) || other.ink == ink)&&(identical(other.pointsAccepted, pointsAccepted) || other.pointsAccepted == pointsAccepted));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,initials,blurb,color,ink,pointsAccepted);
}

@override
String toString() {
    return 'Mall(id: $id, name: $name, initials: $initials, blurb: $blurb, color: $color, ink: $ink, pointsAccepted: $pointsAccepted)';
}


}

/// @nodoc
abstract mixin class _$MallCopyWith<$Res> implements $MallCopyWith<$Res> {
  factory _$MallCopyWith(_Mall value, $Res Function(_Mall) _then) = __$MallCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String initials, String blurb, int color, int ink, bool pointsAccepted
});




}
/// @nodoc
class __$MallCopyWithImpl<$Res>
    implements _$MallCopyWith<$Res> {
  __$MallCopyWithImpl(this._self, this._then);

  final _Mall _self;
  final $Res Function(_Mall) _then;

/// Create a copy of Mall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? initials = null,Object? blurb = null,Object? color = null,Object? ink = null,Object? pointsAccepted = null,}) {
  return _then(_Mall(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initials: null == initials ? _self.initials : initials // ignore: cast_nullable_to_non_nullable
as String,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,ink: null == ink ? _self.ink : ink // ignore: cast_nullable_to_non_nullable
as int,pointsAccepted: null == pointsAccepted ? _self.pointsAccepted : pointsAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Product {

 String get id; String get name; String get mallId; String get mallName; int get priceCents;/// Points the buyer can spend on it.
 int get maxPoints; ProductArt get art;/// The price before a deal, when there is one.
 int? get oldPriceCents; double get rating; int get sold;/// "Coach Ravi", the creator who plays with it.
 String? get usedBy;/// A service is booked (restringing), not shipped.
 bool get service; int get stock;/// For the seller: draft, live.
 bool get published;/// What the seller wrote about it.
 String get description;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Product;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.mallId, _this.mallId) || other.mallId == _this.mallId)&&(identical(other.mallName, _this.mallName) || other.mallName == _this.mallName)&&(identical(other.priceCents, _this.priceCents) || other.priceCents == _this.priceCents)&&(identical(other.maxPoints, _this.maxPoints) || other.maxPoints == _this.maxPoints)&&(identical(other.art, _this.art) || other.art == _this.art)&&(identical(other.oldPriceCents, _this.oldPriceCents) || other.oldPriceCents == _this.oldPriceCents)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.sold, _this.sold) || other.sold == _this.sold)&&(identical(other.usedBy, _this.usedBy) || other.usedBy == _this.usedBy)&&(identical(other.service, _this.service) || other.service == _this.service)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.published, _this.published) || other.published == _this.published)&&(identical(other.description, _this.description) || other.description == _this.description));
}


@override
int get hashCode {
  final _this = this as Product;
  return Object.hash(runtimeType,_this.id,_this.name,_this.mallId,_this.mallName,_this.priceCents,_this.maxPoints,_this.art,_this.oldPriceCents,_this.rating,_this.sold,_this.usedBy,_this.service,_this.stock,_this.published,_this.description);
}

@override
String toString() {
  final _this = this as Product;
  return 'Product(id: ${_this.id}, name: ${_this.name}, mallId: ${_this.mallId}, mallName: ${_this.mallName}, priceCents: ${_this.priceCents}, maxPoints: ${_this.maxPoints}, art: ${_this.art}, oldPriceCents: ${_this.oldPriceCents}, rating: ${_this.rating}, sold: ${_this.sold}, usedBy: ${_this.usedBy}, service: ${_this.service}, stock: ${_this.stock}, published: ${_this.published}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String name, String mallId, String mallName, int priceCents, int maxPoints, ProductArt art, int? oldPriceCents, double rating, int sold, String? usedBy, bool service, int stock, bool published, String description
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? mallId = null,Object? mallName = null,Object? priceCents = null,Object? maxPoints = null,Object? art = null,Object? oldPriceCents = freezed,Object? rating = null,Object? sold = null,Object? usedBy = freezed,Object? service = null,Object? stock = null,Object? published = null,Object? description = null,}) {
  return _then(Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mallId: null == mallId ? _self.mallId : mallId // ignore: cast_nullable_to_non_nullable
as String,mallName: null == mallName ? _self.mallName : mallName // ignore: cast_nullable_to_non_nullable
as String,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,maxPoints: null == maxPoints ? _self.maxPoints : maxPoints // ignore: cast_nullable_to_non_nullable
as int,art: null == art ? _self.art : art // ignore: cast_nullable_to_non_nullable
as ProductArt,oldPriceCents: freezed == oldPriceCents ? _self.oldPriceCents : oldPriceCents // ignore: cast_nullable_to_non_nullable
as int?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,sold: null == sold ? _self.sold : sold // ignore: cast_nullable_to_non_nullable
as int,usedBy: freezed == usedBy ? _self.usedBy : usedBy // ignore: cast_nullable_to_non_nullable
as String?,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as bool,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String mallId,  String mallName,  int priceCents,  int maxPoints,  ProductArt art,  int? oldPriceCents,  double rating,  int sold,  String? usedBy,  bool service,  int stock,  bool published,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.mallId,_that.mallName,_that.priceCents,_that.maxPoints,_that.art,_that.oldPriceCents,_that.rating,_that.sold,_that.usedBy,_that.service,_that.stock,_that.published,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String mallId,  String mallName,  int priceCents,  int maxPoints,  ProductArt art,  int? oldPriceCents,  double rating,  int sold,  String? usedBy,  bool service,  int stock,  bool published,  String description)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.name,_that.mallId,_that.mallName,_that.priceCents,_that.maxPoints,_that.art,_that.oldPriceCents,_that.rating,_that.sold,_that.usedBy,_that.service,_that.stock,_that.published,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String mallId,  String mallName,  int priceCents,  int maxPoints,  ProductArt art,  int? oldPriceCents,  double rating,  int sold,  String? usedBy,  bool service,  int stock,  bool published,  String description)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.mallId,_that.mallName,_that.priceCents,_that.maxPoints,_that.art,_that.oldPriceCents,_that.rating,_that.sold,_that.usedBy,_that.service,_that.stock,_that.published,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _Product extends Product {
  const _Product({required this.id, required this.name, required this.mallId, required this.mallName, required this.priceCents, this.maxPoints = 0, this.art = ProductArt.bag, this.oldPriceCents, this.rating = 0, this.sold = 0, this.usedBy, this.service = false, this.stock = 10, this.published = true, this.description = ''}): super._();
  

@override final  String id;
@override final  String name;
@override final  String mallId;
@override final  String mallName;
@override final  int priceCents;
/// Points the buyer can spend on it.
@override@JsonKey() final  int maxPoints;
@override@JsonKey() final  ProductArt art;
/// The price before a deal, when there is one.
@override final  int? oldPriceCents;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int sold;
/// "Coach Ravi", the creator who plays with it.
@override final  String? usedBy;
/// A service is booked (restringing), not shipped.
@override@JsonKey() final  bool service;
@override@JsonKey() final  int stock;
/// For the seller: draft, live.
@override@JsonKey() final  bool published;
/// What the seller wrote about it.
@override@JsonKey() final  String description;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mallId, mallId) || other.mallId == mallId)&&(identical(other.mallName, mallName) || other.mallName == mallName)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.maxPoints, maxPoints) || other.maxPoints == maxPoints)&&(identical(other.art, art) || other.art == art)&&(identical(other.oldPriceCents, oldPriceCents) || other.oldPriceCents == oldPriceCents)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.sold, sold) || other.sold == sold)&&(identical(other.usedBy, usedBy) || other.usedBy == usedBy)&&(identical(other.service, service) || other.service == service)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.published, published) || other.published == published)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,mallId,mallName,priceCents,maxPoints,art,oldPriceCents,rating,sold,usedBy,service,stock,published,description);
}

@override
String toString() {
    return 'Product(id: $id, name: $name, mallId: $mallId, mallName: $mallName, priceCents: $priceCents, maxPoints: $maxPoints, art: $art, oldPriceCents: $oldPriceCents, rating: $rating, sold: $sold, usedBy: $usedBy, service: $service, stock: $stock, published: $published, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String mallId, String mallName, int priceCents, int maxPoints, ProductArt art, int? oldPriceCents, double rating, int sold, String? usedBy, bool service, int stock, bool published, String description
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? mallId = null,Object? mallName = null,Object? priceCents = null,Object? maxPoints = null,Object? art = null,Object? oldPriceCents = freezed,Object? rating = null,Object? sold = null,Object? usedBy = freezed,Object? service = null,Object? stock = null,Object? published = null,Object? description = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mallId: null == mallId ? _self.mallId : mallId // ignore: cast_nullable_to_non_nullable
as String,mallName: null == mallName ? _self.mallName : mallName // ignore: cast_nullable_to_non_nullable
as String,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,maxPoints: null == maxPoints ? _self.maxPoints : maxPoints // ignore: cast_nullable_to_non_nullable
as int,art: null == art ? _self.art : art // ignore: cast_nullable_to_non_nullable
as ProductArt,oldPriceCents: freezed == oldPriceCents ? _self.oldPriceCents : oldPriceCents // ignore: cast_nullable_to_non_nullable
as int?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,sold: null == sold ? _self.sold : sold // ignore: cast_nullable_to_non_nullable
as int,usedBy: freezed == usedBy ? _self.usedBy : usedBy // ignore: cast_nullable_to_non_nullable
as String?,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as bool,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

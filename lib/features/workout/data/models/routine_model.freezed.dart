part of 'routine_model.dart';

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoutineModel {

 String get id; String get name; String get description; int get estimatedDurationMinutes; List<MuscleGroup> get muscleGroupsTargeted; List<RoutineExerciseModel> get exercises; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of RoutineModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutineModelCopyWith<RoutineModel> get copyWith => _$RoutineModelCopyWithImpl<RoutineModel>(this as RoutineModel, _$identity);

  /// Serializes this RoutineModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutineModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&const DeepCollectionEquality().equals(other.muscleGroupsTargeted, muscleGroupsTargeted)&&const DeepCollectionEquality().equals(other.exercises, exercises)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,estimatedDurationMinutes,const DeepCollectionEquality().hash(muscleGroupsTargeted),const DeepCollectionEquality().hash(exercises),createdAt,updatedAt);

@override
String toString() {
  return 'RoutineModel(id: $id, name: $name, description: $description, estimatedDurationMinutes: $estimatedDurationMinutes, muscleGroupsTargeted: $muscleGroupsTargeted, exercises: $exercises, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RoutineModelCopyWith<$Res>  {
  factory $RoutineModelCopyWith(RoutineModel value, $Res Function(RoutineModel) _then) = _$RoutineModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, int estimatedDurationMinutes, List<MuscleGroup> muscleGroupsTargeted, List<RoutineExerciseModel> exercises, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$RoutineModelCopyWithImpl<$Res>
    implements $RoutineModelCopyWith<$Res> {
  _$RoutineModelCopyWithImpl(this._self, this._then);

  final RoutineModel _self;
  final $Res Function(RoutineModel) _then;

/// Create a copy of RoutineModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? estimatedDurationMinutes = null,Object? muscleGroupsTargeted = null,Object? exercises = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,estimatedDurationMinutes: null == estimatedDurationMinutes ? _self.estimatedDurationMinutes : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,muscleGroupsTargeted: null == muscleGroupsTargeted ? _self.muscleGroupsTargeted : muscleGroupsTargeted // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<RoutineExerciseModel>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutineModel].
extension RoutineModelPatterns on RoutineModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutineModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutineModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutineModel value)  $default,){
final _that = this;
switch (_that) {
case _RoutineModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutineModel value)?  $default,){
final _that = this;
switch (_that) {
case _RoutineModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int estimatedDurationMinutes,  List<MuscleGroup> muscleGroupsTargeted,  List<RoutineExerciseModel> exercises,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutineModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.estimatedDurationMinutes,_that.muscleGroupsTargeted,_that.exercises,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int estimatedDurationMinutes,  List<MuscleGroup> muscleGroupsTargeted,  List<RoutineExerciseModel> exercises,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RoutineModel():
return $default(_that.id,_that.name,_that.description,_that.estimatedDurationMinutes,_that.muscleGroupsTargeted,_that.exercises,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  int estimatedDurationMinutes,  List<MuscleGroup> muscleGroupsTargeted,  List<RoutineExerciseModel> exercises,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoutineModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.estimatedDurationMinutes,_that.muscleGroupsTargeted,_that.exercises,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoutineModel implements RoutineModel {
  const _RoutineModel({required this.id, required this.name, required this.description, required this.estimatedDurationMinutes, final  List<MuscleGroup> muscleGroupsTargeted = const [], final  List<RoutineExerciseModel> exercises = const [], this.createdAt, this.updatedAt}): _muscleGroupsTargeted = muscleGroupsTargeted,_exercises = exercises;
  factory _RoutineModel.fromJson(Map<String, dynamic> json) => _$RoutineModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  int estimatedDurationMinutes;
 final  List<MuscleGroup> _muscleGroupsTargeted;
@override@JsonKey() List<MuscleGroup> get muscleGroupsTargeted {
  if (_muscleGroupsTargeted is EqualUnmodifiableListView) return _muscleGroupsTargeted;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_muscleGroupsTargeted);
}

 final  List<RoutineExerciseModel> _exercises;
@override@JsonKey() List<RoutineExerciseModel> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of RoutineModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutineModelCopyWith<_RoutineModel> get copyWith => __$RoutineModelCopyWithImpl<_RoutineModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoutineModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutineModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&const DeepCollectionEquality().equals(other._muscleGroupsTargeted, _muscleGroupsTargeted)&&const DeepCollectionEquality().equals(other._exercises, _exercises)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,estimatedDurationMinutes,const DeepCollectionEquality().hash(_muscleGroupsTargeted),const DeepCollectionEquality().hash(_exercises),createdAt,updatedAt);

@override
String toString() {
  return 'RoutineModel(id: $id, name: $name, description: $description, estimatedDurationMinutes: $estimatedDurationMinutes, muscleGroupsTargeted: $muscleGroupsTargeted, exercises: $exercises, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RoutineModelCopyWith<$Res> implements $RoutineModelCopyWith<$Res> {
  factory _$RoutineModelCopyWith(_RoutineModel value, $Res Function(_RoutineModel) _then) = __$RoutineModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, int estimatedDurationMinutes, List<MuscleGroup> muscleGroupsTargeted, List<RoutineExerciseModel> exercises, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$RoutineModelCopyWithImpl<$Res>
    implements _$RoutineModelCopyWith<$Res> {
  __$RoutineModelCopyWithImpl(this._self, this._then);

  final _RoutineModel _self;
  final $Res Function(_RoutineModel) _then;

/// Create a copy of RoutineModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? estimatedDurationMinutes = null,Object? muscleGroupsTargeted = null,Object? exercises = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_RoutineModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,estimatedDurationMinutes: null == estimatedDurationMinutes ? _self.estimatedDurationMinutes : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,muscleGroupsTargeted: null == muscleGroupsTargeted ? _self._muscleGroupsTargeted : muscleGroupsTargeted // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<RoutineExerciseModel>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

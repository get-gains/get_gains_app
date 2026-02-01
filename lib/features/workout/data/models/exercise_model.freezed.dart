part of 'exercise_model.dart';

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseModel {

 String get id; String get name; String get description; MuscleGroup get primaryMuscleGroup; List<String> get equipmentNeeded; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseModelCopyWith<ExerciseModel> get copyWith => _$ExerciseModelCopyWithImpl<ExerciseModel>(this as ExerciseModel, _$identity);

  /// Serializes this ExerciseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.primaryMuscleGroup, primaryMuscleGroup) || other.primaryMuscleGroup == primaryMuscleGroup)&&const DeepCollectionEquality().equals(other.equipmentNeeded, equipmentNeeded)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,primaryMuscleGroup,const DeepCollectionEquality().hash(equipmentNeeded),createdAt,updatedAt);

@override
String toString() {
  return 'ExerciseModel(id: $id, name: $name, description: $description, primaryMuscleGroup: $primaryMuscleGroup, equipmentNeeded: $equipmentNeeded, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ExerciseModelCopyWith<$Res>  {
  factory $ExerciseModelCopyWith(ExerciseModel value, $Res Function(ExerciseModel) _then) = _$ExerciseModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, MuscleGroup primaryMuscleGroup, List<String> equipmentNeeded, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ExerciseModelCopyWithImpl<$Res>
    implements $ExerciseModelCopyWith<$Res> {
  _$ExerciseModelCopyWithImpl(this._self, this._then);

  final ExerciseModel _self;
  final $Res Function(ExerciseModel) _then;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? primaryMuscleGroup = null,Object? equipmentNeeded = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,primaryMuscleGroup: null == primaryMuscleGroup ? _self.primaryMuscleGroup : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,equipmentNeeded: null == equipmentNeeded ? _self.equipmentNeeded : equipmentNeeded // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseModel].
extension ExerciseModelPatterns on ExerciseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseModel value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  MuscleGroup primaryMuscleGroup,  List<String> equipmentNeeded,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.primaryMuscleGroup,_that.equipmentNeeded,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  MuscleGroup primaryMuscleGroup,  List<String> equipmentNeeded,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ExerciseModel():
return $default(_that.id,_that.name,_that.description,_that.primaryMuscleGroup,_that.equipmentNeeded,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  MuscleGroup primaryMuscleGroup,  List<String> equipmentNeeded,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.primaryMuscleGroup,_that.equipmentNeeded,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseModel implements ExerciseModel {
  const _ExerciseModel({required this.id, required this.name, required this.description, required this.primaryMuscleGroup, final  List<String> equipmentNeeded = const [], this.createdAt, this.updatedAt}): _equipmentNeeded = equipmentNeeded;
  factory _ExerciseModel.fromJson(Map<String, dynamic> json) => _$ExerciseModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  MuscleGroup primaryMuscleGroup;
 final  List<String> _equipmentNeeded;
@override@JsonKey() List<String> get equipmentNeeded {
  if (_equipmentNeeded is EqualUnmodifiableListView) return _equipmentNeeded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_equipmentNeeded);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseModelCopyWith<_ExerciseModel> get copyWith => __$ExerciseModelCopyWithImpl<_ExerciseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.primaryMuscleGroup, primaryMuscleGroup) || other.primaryMuscleGroup == primaryMuscleGroup)&&const DeepCollectionEquality().equals(other._equipmentNeeded, _equipmentNeeded)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,primaryMuscleGroup,const DeepCollectionEquality().hash(_equipmentNeeded),createdAt,updatedAt);

@override
String toString() {
  return 'ExerciseModel(id: $id, name: $name, description: $description, primaryMuscleGroup: $primaryMuscleGroup, equipmentNeeded: $equipmentNeeded, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ExerciseModelCopyWith<$Res> implements $ExerciseModelCopyWith<$Res> {
  factory _$ExerciseModelCopyWith(_ExerciseModel value, $Res Function(_ExerciseModel) _then) = __$ExerciseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, MuscleGroup primaryMuscleGroup, List<String> equipmentNeeded, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ExerciseModelCopyWithImpl<$Res>
    implements _$ExerciseModelCopyWith<$Res> {
  __$ExerciseModelCopyWithImpl(this._self, this._then);

  final _ExerciseModel _self;
  final $Res Function(_ExerciseModel) _then;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? primaryMuscleGroup = null,Object? equipmentNeeded = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ExerciseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,primaryMuscleGroup: null == primaryMuscleGroup ? _self.primaryMuscleGroup : primaryMuscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,equipmentNeeded: null == equipmentNeeded ? _self._equipmentNeeded : equipmentNeeded // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$RoutineExerciseModel {

 String get id; String get routineId; String get exerciseId; int get sets; int get repsMin; int get repsMax; int get restSeconds; int get orderInRoutine; String? get notes; ExerciseModel? get exercise; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of RoutineExerciseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutineExerciseModelCopyWith<RoutineExerciseModel> get copyWith => _$RoutineExerciseModelCopyWithImpl<RoutineExerciseModel>(this as RoutineExerciseModel, _$identity);

  /// Serializes this RoutineExerciseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutineExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.orderInRoutine, orderInRoutine) || other.orderInRoutine == orderInRoutine)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.exercise, exercise) || other.exercise == exercise)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,routineId,exerciseId,sets,repsMin,repsMax,restSeconds,orderInRoutine,notes,exercise,createdAt,updatedAt);

@override
String toString() {
  return 'RoutineExerciseModel(id: $id, routineId: $routineId, exerciseId: $exerciseId, sets: $sets, repsMin: $repsMin, repsMax: $repsMax, restSeconds: $restSeconds, orderInRoutine: $orderInRoutine, notes: $notes, exercise: $exercise, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RoutineExerciseModelCopyWith<$Res>  {
  factory $RoutineExerciseModelCopyWith(RoutineExerciseModel value, $Res Function(RoutineExerciseModel) _then) = _$RoutineExerciseModelCopyWithImpl;
@useResult
$Res call({
 String id, String routineId, String exerciseId, int sets, int repsMin, int repsMax, int restSeconds, int orderInRoutine, String? notes, ExerciseModel? exercise, DateTime? createdAt, DateTime? updatedAt
});


$ExerciseModelCopyWith<$Res>? get exercise;

}
/// @nodoc
class _$RoutineExerciseModelCopyWithImpl<$Res>
    implements $RoutineExerciseModelCopyWith<$Res> {
  _$RoutineExerciseModelCopyWithImpl(this._self, this._then);

  final RoutineExerciseModel _self;
  final $Res Function(RoutineExerciseModel) _then;

/// Create a copy of RoutineExerciseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? routineId = null,Object? exerciseId = null,Object? sets = null,Object? repsMin = null,Object? repsMax = null,Object? restSeconds = null,Object? orderInRoutine = null,Object? notes = freezed,Object? exercise = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,orderInRoutine: null == orderInRoutine ? _self.orderInRoutine : orderInRoutine // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,exercise: freezed == exercise ? _self.exercise : exercise // ignore: cast_nullable_to_non_nullable
as ExerciseModel?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of RoutineExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseModelCopyWith<$Res>? get exercise {
    if (_self.exercise == null) {
    return null;
  }

  return $ExerciseModelCopyWith<$Res>(_self.exercise!, (value) {
    return _then(_self.copyWith(exercise: value));
  });
}
}


/// Adds pattern-matching-related methods to [RoutineExerciseModel].
extension RoutineExerciseModelPatterns on RoutineExerciseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutineExerciseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutineExerciseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutineExerciseModel value)  $default,){
final _that = this;
switch (_that) {
case _RoutineExerciseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutineExerciseModel value)?  $default,){
final _that = this;
switch (_that) {
case _RoutineExerciseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String routineId,  String exerciseId,  int sets,  int repsMin,  int repsMax,  int restSeconds,  int orderInRoutine,  String? notes,  ExerciseModel? exercise,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutineExerciseModel() when $default != null:
return $default(_that.id,_that.routineId,_that.exerciseId,_that.sets,_that.repsMin,_that.repsMax,_that.restSeconds,_that.orderInRoutine,_that.notes,_that.exercise,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String routineId,  String exerciseId,  int sets,  int repsMin,  int repsMax,  int restSeconds,  int orderInRoutine,  String? notes,  ExerciseModel? exercise,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RoutineExerciseModel():
return $default(_that.id,_that.routineId,_that.exerciseId,_that.sets,_that.repsMin,_that.repsMax,_that.restSeconds,_that.orderInRoutine,_that.notes,_that.exercise,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String routineId,  String exerciseId,  int sets,  int repsMin,  int repsMax,  int restSeconds,  int orderInRoutine,  String? notes,  ExerciseModel? exercise,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoutineExerciseModel() when $default != null:
return $default(_that.id,_that.routineId,_that.exerciseId,_that.sets,_that.repsMin,_that.repsMax,_that.restSeconds,_that.orderInRoutine,_that.notes,_that.exercise,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoutineExerciseModel implements RoutineExerciseModel {
  const _RoutineExerciseModel({required this.id, required this.routineId, required this.exerciseId, required this.sets, required this.repsMin, required this.repsMax, required this.restSeconds, required this.orderInRoutine, this.notes, this.exercise, this.createdAt, this.updatedAt});
  factory _RoutineExerciseModel.fromJson(Map<String, dynamic> json) => _$RoutineExerciseModelFromJson(json);

@override final  String id;
@override final  String routineId;
@override final  String exerciseId;
@override final  int sets;
@override final  int repsMin;
@override final  int repsMax;
@override final  int restSeconds;
@override final  int orderInRoutine;
@override final  String? notes;
@override final  ExerciseModel? exercise;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of RoutineExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutineExerciseModelCopyWith<_RoutineExerciseModel> get copyWith => __$RoutineExerciseModelCopyWithImpl<_RoutineExerciseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoutineExerciseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutineExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.orderInRoutine, orderInRoutine) || other.orderInRoutine == orderInRoutine)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.exercise, exercise) || other.exercise == exercise)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,routineId,exerciseId,sets,repsMin,repsMax,restSeconds,orderInRoutine,notes,exercise,createdAt,updatedAt);

@override
String toString() {
  return 'RoutineExerciseModel(id: $id, routineId: $routineId, exerciseId: $exerciseId, sets: $sets, repsMin: $repsMin, repsMax: $repsMax, restSeconds: $restSeconds, orderInRoutine: $orderInRoutine, notes: $notes, exercise: $exercise, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RoutineExerciseModelCopyWith<$Res> implements $RoutineExerciseModelCopyWith<$Res> {
  factory _$RoutineExerciseModelCopyWith(_RoutineExerciseModel value, $Res Function(_RoutineExerciseModel) _then) = __$RoutineExerciseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String routineId, String exerciseId, int sets, int repsMin, int repsMax, int restSeconds, int orderInRoutine, String? notes, ExerciseModel? exercise, DateTime? createdAt, DateTime? updatedAt
});


@override $ExerciseModelCopyWith<$Res>? get exercise;

}
/// @nodoc
class __$RoutineExerciseModelCopyWithImpl<$Res>
    implements _$RoutineExerciseModelCopyWith<$Res> {
  __$RoutineExerciseModelCopyWithImpl(this._self, this._then);

  final _RoutineExerciseModel _self;
  final $Res Function(_RoutineExerciseModel) _then;

/// Create a copy of RoutineExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? routineId = null,Object? exerciseId = null,Object? sets = null,Object? repsMin = null,Object? repsMax = null,Object? restSeconds = null,Object? orderInRoutine = null,Object? notes = freezed,Object? exercise = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_RoutineExerciseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,orderInRoutine: null == orderInRoutine ? _self.orderInRoutine : orderInRoutine // ignore: cast_nullable_to_non_nullable
as int,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,exercise: freezed == exercise ? _self.exercise : exercise // ignore: cast_nullable_to_non_nullable
as ExerciseModel?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of RoutineExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseModelCopyWith<$Res>? get exercise {
    if (_self.exercise == null) {
    return null;
  }

  return $ExerciseModelCopyWith<$Res>(_self.exercise!, (value) {
    return _then(_self.copyWith(exercise: value));
  });
}
}

// dart format on

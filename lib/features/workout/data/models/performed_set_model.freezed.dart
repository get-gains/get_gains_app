part of 'performed_set_model.dart';

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PerformedSetModel {

 String get id; String get workoutSessionId; String get routineExerciseId; int get setNumber; int get repsCompleted; double? get weightKg; int? get rpe; String? get notes; bool get isCompleted; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of PerformedSetModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerformedSetModelCopyWith<PerformedSetModel> get copyWith => _$PerformedSetModelCopyWithImpl<PerformedSetModel>(this as PerformedSetModel, _$identity);

  /// Serializes this PerformedSetModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerformedSetModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutSessionId, workoutSessionId) || other.workoutSessionId == workoutSessionId)&&(identical(other.routineExerciseId, routineExerciseId) || other.routineExerciseId == routineExerciseId)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.repsCompleted, repsCompleted) || other.repsCompleted == repsCompleted)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workoutSessionId,routineExerciseId,setNumber,repsCompleted,weightKg,rpe,notes,isCompleted,createdAt,updatedAt);

@override
String toString() {
  return 'PerformedSetModel(id: $id, workoutSessionId: $workoutSessionId, routineExerciseId: $routineExerciseId, setNumber: $setNumber, repsCompleted: $repsCompleted, weightKg: $weightKg, rpe: $rpe, notes: $notes, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PerformedSetModelCopyWith<$Res>  {
  factory $PerformedSetModelCopyWith(PerformedSetModel value, $Res Function(PerformedSetModel) _then) = _$PerformedSetModelCopyWithImpl;
@useResult
$Res call({
 String id, String workoutSessionId, String routineExerciseId, int setNumber, int repsCompleted, double? weightKg, int? rpe, String? notes, bool isCompleted, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PerformedSetModelCopyWithImpl<$Res>
    implements $PerformedSetModelCopyWith<$Res> {
  _$PerformedSetModelCopyWithImpl(this._self, this._then);

  final PerformedSetModel _self;
  final $Res Function(PerformedSetModel) _then;

/// Create a copy of PerformedSetModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workoutSessionId = null,Object? routineExerciseId = null,Object? setNumber = null,Object? repsCompleted = null,Object? weightKg = freezed,Object? rpe = freezed,Object? notes = freezed,Object? isCompleted = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutSessionId: null == workoutSessionId ? _self.workoutSessionId : workoutSessionId // ignore: cast_nullable_to_non_nullable
as String,routineExerciseId: null == routineExerciseId ? _self.routineExerciseId : routineExerciseId // ignore: cast_nullable_to_non_nullable
as String,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,repsCompleted: null == repsCompleted ? _self.repsCompleted : repsCompleted // ignore: cast_nullable_to_non_nullable
as int,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PerformedSetModel].
extension PerformedSetModelPatterns on PerformedSetModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerformedSetModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerformedSetModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerformedSetModel value)  $default,){
final _that = this;
switch (_that) {
case _PerformedSetModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerformedSetModel value)?  $default,){
final _that = this;
switch (_that) {
case _PerformedSetModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workoutSessionId,  String routineExerciseId,  int setNumber,  int repsCompleted,  double? weightKg,  int? rpe,  String? notes,  bool isCompleted,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerformedSetModel() when $default != null:
return $default(_that.id,_that.workoutSessionId,_that.routineExerciseId,_that.setNumber,_that.repsCompleted,_that.weightKg,_that.rpe,_that.notes,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workoutSessionId,  String routineExerciseId,  int setNumber,  int repsCompleted,  double? weightKg,  int? rpe,  String? notes,  bool isCompleted,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PerformedSetModel():
return $default(_that.id,_that.workoutSessionId,_that.routineExerciseId,_that.setNumber,_that.repsCompleted,_that.weightKg,_that.rpe,_that.notes,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workoutSessionId,  String routineExerciseId,  int setNumber,  int repsCompleted,  double? weightKg,  int? rpe,  String? notes,  bool isCompleted,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PerformedSetModel() when $default != null:
return $default(_that.id,_that.workoutSessionId,_that.routineExerciseId,_that.setNumber,_that.repsCompleted,_that.weightKg,_that.rpe,_that.notes,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerformedSetModel implements PerformedSetModel {
  const _PerformedSetModel({required this.id, required this.workoutSessionId, required this.routineExerciseId, required this.setNumber, required this.repsCompleted, this.weightKg, this.rpe, this.notes, this.isCompleted = false, this.createdAt, this.updatedAt});
  factory _PerformedSetModel.fromJson(Map<String, dynamic> json) => _$PerformedSetModelFromJson(json);

@override final  String id;
@override final  String workoutSessionId;
@override final  String routineExerciseId;
@override final  int setNumber;
@override final  int repsCompleted;
@override final  double? weightKg;
@override final  int? rpe;
@override final  String? notes;
@override@JsonKey() final  bool isCompleted;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of PerformedSetModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerformedSetModelCopyWith<_PerformedSetModel> get copyWith => __$PerformedSetModelCopyWithImpl<_PerformedSetModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerformedSetModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerformedSetModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutSessionId, workoutSessionId) || other.workoutSessionId == workoutSessionId)&&(identical(other.routineExerciseId, routineExerciseId) || other.routineExerciseId == routineExerciseId)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.repsCompleted, repsCompleted) || other.repsCompleted == repsCompleted)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workoutSessionId,routineExerciseId,setNumber,repsCompleted,weightKg,rpe,notes,isCompleted,createdAt,updatedAt);

@override
String toString() {
  return 'PerformedSetModel(id: $id, workoutSessionId: $workoutSessionId, routineExerciseId: $routineExerciseId, setNumber: $setNumber, repsCompleted: $repsCompleted, weightKg: $weightKg, rpe: $rpe, notes: $notes, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PerformedSetModelCopyWith<$Res> implements $PerformedSetModelCopyWith<$Res> {
  factory _$PerformedSetModelCopyWith(_PerformedSetModel value, $Res Function(_PerformedSetModel) _then) = __$PerformedSetModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String workoutSessionId, String routineExerciseId, int setNumber, int repsCompleted, double? weightKg, int? rpe, String? notes, bool isCompleted, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PerformedSetModelCopyWithImpl<$Res>
    implements _$PerformedSetModelCopyWith<$Res> {
  __$PerformedSetModelCopyWithImpl(this._self, this._then);

  final _PerformedSetModel _self;
  final $Res Function(_PerformedSetModel) _then;

/// Create a copy of PerformedSetModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workoutSessionId = null,Object? routineExerciseId = null,Object? setNumber = null,Object? repsCompleted = null,Object? weightKg = freezed,Object? rpe = freezed,Object? notes = freezed,Object? isCompleted = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PerformedSetModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutSessionId: null == workoutSessionId ? _self.workoutSessionId : workoutSessionId // ignore: cast_nullable_to_non_nullable
as String,routineExerciseId: null == routineExerciseId ? _self.routineExerciseId : routineExerciseId // ignore: cast_nullable_to_non_nullable
as String,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,repsCompleted: null == repsCompleted ? _self.repsCompleted : repsCompleted // ignore: cast_nullable_to_non_nullable
as int,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$EditableSetModel {

 String? get id; int get setNumber; int get reps; double get weight; int? get rpe; String? get notes; bool get isCompleted;
/// Create a copy of EditableSetModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditableSetModelCopyWith<EditableSetModel> get copyWith => _$EditableSetModelCopyWithImpl<EditableSetModel>(this as EditableSetModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditableSetModel&&(identical(other.id, id) || other.id == id)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,setNumber,reps,weight,rpe,notes,isCompleted);

@override
String toString() {
  return 'EditableSetModel(id: $id, setNumber: $setNumber, reps: $reps, weight: $weight, rpe: $rpe, notes: $notes, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class $EditableSetModelCopyWith<$Res>  {
  factory $EditableSetModelCopyWith(EditableSetModel value, $Res Function(EditableSetModel) _then) = _$EditableSetModelCopyWithImpl;
@useResult
$Res call({
 String? id, int setNumber, int reps, double weight, int? rpe, String? notes, bool isCompleted
});




}
/// @nodoc
class _$EditableSetModelCopyWithImpl<$Res>
    implements $EditableSetModelCopyWith<$Res> {
  _$EditableSetModelCopyWithImpl(this._self, this._then);

  final EditableSetModel _self;
  final $Res Function(EditableSetModel) _then;

/// Create a copy of EditableSetModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? setNumber = null,Object? reps = null,Object? weight = null,Object? rpe = freezed,Object? notes = freezed,Object? isCompleted = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EditableSetModel].
extension EditableSetModelPatterns on EditableSetModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditableSetModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditableSetModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditableSetModel value)  $default,){
final _that = this;
switch (_that) {
case _EditableSetModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditableSetModel value)?  $default,){
final _that = this;
switch (_that) {
case _EditableSetModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  int setNumber,  int reps,  double weight,  int? rpe,  String? notes,  bool isCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditableSetModel() when $default != null:
return $default(_that.id,_that.setNumber,_that.reps,_that.weight,_that.rpe,_that.notes,_that.isCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  int setNumber,  int reps,  double weight,  int? rpe,  String? notes,  bool isCompleted)  $default,) {final _that = this;
switch (_that) {
case _EditableSetModel():
return $default(_that.id,_that.setNumber,_that.reps,_that.weight,_that.rpe,_that.notes,_that.isCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  int setNumber,  int reps,  double weight,  int? rpe,  String? notes,  bool isCompleted)?  $default,) {final _that = this;
switch (_that) {
case _EditableSetModel() when $default != null:
return $default(_that.id,_that.setNumber,_that.reps,_that.weight,_that.rpe,_that.notes,_that.isCompleted);case _:
  return null;

}
}

}

/// @nodoc


class _EditableSetModel implements EditableSetModel {
  const _EditableSetModel({this.id, required this.setNumber, this.reps = 0, this.weight = 0.0, this.rpe, this.notes, this.isCompleted = false});
  

@override final  String? id;
@override final  int setNumber;
@override@JsonKey() final  int reps;
@override@JsonKey() final  double weight;
@override final  int? rpe;
@override final  String? notes;
@override@JsonKey() final  bool isCompleted;

/// Create a copy of EditableSetModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditableSetModelCopyWith<_EditableSetModel> get copyWith => __$EditableSetModelCopyWithImpl<_EditableSetModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditableSetModel&&(identical(other.id, id) || other.id == id)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,setNumber,reps,weight,rpe,notes,isCompleted);

@override
String toString() {
  return 'EditableSetModel(id: $id, setNumber: $setNumber, reps: $reps, weight: $weight, rpe: $rpe, notes: $notes, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class _$EditableSetModelCopyWith<$Res> implements $EditableSetModelCopyWith<$Res> {
  factory _$EditableSetModelCopyWith(_EditableSetModel value, $Res Function(_EditableSetModel) _then) = __$EditableSetModelCopyWithImpl;
@override @useResult
$Res call({
 String? id, int setNumber, int reps, double weight, int? rpe, String? notes, bool isCompleted
});




}
/// @nodoc
class __$EditableSetModelCopyWithImpl<$Res>
    implements _$EditableSetModelCopyWith<$Res> {
  __$EditableSetModelCopyWithImpl(this._self, this._then);

  final _EditableSetModel _self;
  final $Res Function(_EditableSetModel) _then;

/// Create a copy of EditableSetModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? setNumber = null,Object? reps = null,Object? weight = null,Object? rpe = freezed,Object? notes = freezed,Object? isCompleted = null,}) {
  return _then(_EditableSetModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,rpe: freezed == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

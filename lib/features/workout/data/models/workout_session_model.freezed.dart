part of 'workout_session_model.dart';

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutSessionModel {

 String get id; String get userId; String? get assignedProgramId; String? get routineId; DateTime get startedAt; DateTime? get completedAt; String? get notes; List<PerformedSetModel> get performedSets; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of WorkoutSessionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSessionModelCopyWith<WorkoutSessionModel> get copyWith => _$WorkoutSessionModelCopyWithImpl<WorkoutSessionModel>(this as WorkoutSessionModel, _$identity);

  /// Serializes this WorkoutSessionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.assignedProgramId, assignedProgramId) || other.assignedProgramId == assignedProgramId)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.performedSets, performedSets)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,assignedProgramId,routineId,startedAt,completedAt,notes,const DeepCollectionEquality().hash(performedSets),createdAt,updatedAt);

@override
String toString() {
  return 'WorkoutSessionModel(id: $id, userId: $userId, assignedProgramId: $assignedProgramId, routineId: $routineId, startedAt: $startedAt, completedAt: $completedAt, notes: $notes, performedSets: $performedSets, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorkoutSessionModelCopyWith<$Res>  {
  factory $WorkoutSessionModelCopyWith(WorkoutSessionModel value, $Res Function(WorkoutSessionModel) _then) = _$WorkoutSessionModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? assignedProgramId, String? routineId, DateTime startedAt, DateTime? completedAt, String? notes, List<PerformedSetModel> performedSets, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$WorkoutSessionModelCopyWithImpl<$Res>
    implements $WorkoutSessionModelCopyWith<$Res> {
  _$WorkoutSessionModelCopyWithImpl(this._self, this._then);

  final WorkoutSessionModel _self;
  final $Res Function(WorkoutSessionModel) _then;

/// Create a copy of WorkoutSessionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? assignedProgramId = freezed,Object? routineId = freezed,Object? startedAt = null,Object? completedAt = freezed,Object? notes = freezed,Object? performedSets = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,assignedProgramId: freezed == assignedProgramId ? _self.assignedProgramId : assignedProgramId // ignore: cast_nullable_to_non_nullable
as String?,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,performedSets: null == performedSets ? _self.performedSets : performedSets // ignore: cast_nullable_to_non_nullable
as List<PerformedSetModel>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutSessionModel].
extension WorkoutSessionModelPatterns on WorkoutSessionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSessionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSessionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSessionModel value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSessionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSessionModel value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSessionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? assignedProgramId,  String? routineId,  DateTime startedAt,  DateTime? completedAt,  String? notes,  List<PerformedSetModel> performedSets,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSessionModel() when $default != null:
return $default(_that.id,_that.userId,_that.assignedProgramId,_that.routineId,_that.startedAt,_that.completedAt,_that.notes,_that.performedSets,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? assignedProgramId,  String? routineId,  DateTime startedAt,  DateTime? completedAt,  String? notes,  List<PerformedSetModel> performedSets,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSessionModel():
return $default(_that.id,_that.userId,_that.assignedProgramId,_that.routineId,_that.startedAt,_that.completedAt,_that.notes,_that.performedSets,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? assignedProgramId,  String? routineId,  DateTime startedAt,  DateTime? completedAt,  String? notes,  List<PerformedSetModel> performedSets,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSessionModel() when $default != null:
return $default(_that.id,_that.userId,_that.assignedProgramId,_that.routineId,_that.startedAt,_that.completedAt,_that.notes,_that.performedSets,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutSessionModel implements WorkoutSessionModel {
  const _WorkoutSessionModel({required this.id, required this.userId, this.assignedProgramId, this.routineId, required this.startedAt, this.completedAt, this.notes, final  List<PerformedSetModel> performedSets = const [], this.createdAt, this.updatedAt}): _performedSets = performedSets;
  factory _WorkoutSessionModel.fromJson(Map<String, dynamic> json) => _$WorkoutSessionModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String? assignedProgramId;
@override final  String? routineId;
@override final  DateTime startedAt;
@override final  DateTime? completedAt;
@override final  String? notes;
 final  List<PerformedSetModel> _performedSets;
@override@JsonKey() List<PerformedSetModel> get performedSets {
  if (_performedSets is EqualUnmodifiableListView) return _performedSets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_performedSets);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of WorkoutSessionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSessionModelCopyWith<_WorkoutSessionModel> get copyWith => __$WorkoutSessionModelCopyWithImpl<_WorkoutSessionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutSessionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.assignedProgramId, assignedProgramId) || other.assignedProgramId == assignedProgramId)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._performedSets, _performedSets)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,assignedProgramId,routineId,startedAt,completedAt,notes,const DeepCollectionEquality().hash(_performedSets),createdAt,updatedAt);

@override
String toString() {
  return 'WorkoutSessionModel(id: $id, userId: $userId, assignedProgramId: $assignedProgramId, routineId: $routineId, startedAt: $startedAt, completedAt: $completedAt, notes: $notes, performedSets: $performedSets, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSessionModelCopyWith<$Res> implements $WorkoutSessionModelCopyWith<$Res> {
  factory _$WorkoutSessionModelCopyWith(_WorkoutSessionModel value, $Res Function(_WorkoutSessionModel) _then) = __$WorkoutSessionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? assignedProgramId, String? routineId, DateTime startedAt, DateTime? completedAt, String? notes, List<PerformedSetModel> performedSets, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$WorkoutSessionModelCopyWithImpl<$Res>
    implements _$WorkoutSessionModelCopyWith<$Res> {
  __$WorkoutSessionModelCopyWithImpl(this._self, this._then);

  final _WorkoutSessionModel _self;
  final $Res Function(_WorkoutSessionModel) _then;

/// Create a copy of WorkoutSessionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? assignedProgramId = freezed,Object? routineId = freezed,Object? startedAt = null,Object? completedAt = freezed,Object? notes = freezed,Object? performedSets = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WorkoutSessionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,assignedProgramId: freezed == assignedProgramId ? _self.assignedProgramId : assignedProgramId // ignore: cast_nullable_to_non_nullable
as String?,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,performedSets: null == performedSets ? _self._performedSets : performedSets // ignore: cast_nullable_to_non_nullable
as List<PerformedSetModel>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

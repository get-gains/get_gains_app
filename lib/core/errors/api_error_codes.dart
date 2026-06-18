// GENERATED FILE — DO NOT EDIT
// Re-generate via:  npm run codegen:errors  (in server/)
//
// Source: src/lib/errors/codes.ts  (108 codes)

/// Machine-readable error codes returned by the Get Gains API.
///
/// Each value maps 1-to-1 with the `code` field in the
/// `{ data, errors: [{ code, message, field? }] }` envelope.
enum ApiErrorCode {
  /// `VALIDATION_ERROR`
  validationError('VALIDATION_ERROR'),

  /// `UNAUTHENTICATED`
  unauthenticated('UNAUTHENTICATED'),

  /// `FORBIDDEN`
  forbidden('FORBIDDEN'),

  /// `ROUTE_NOT_FOUND`
  routeNotFound('ROUTE_NOT_FOUND'),

  /// `UNEXPECTED_EXCEPTION`
  unexpectedException('UNEXPECTED_EXCEPTION'),

  /// `RATE_LIMITED`
  rateLimited('RATE_LIMITED'),

  /// `PAYLOAD_TOO_LARGE`
  payloadTooLarge('PAYLOAD_TOO_LARGE'),

  /// `UPLOAD_FILE_TOO_LARGE`
  uploadFileTooLarge('UPLOAD_FILE_TOO_LARGE'),

  /// `UPLOAD_INVALID_FILE_TYPE`
  uploadInvalidFileType('UPLOAD_INVALID_FILE_TYPE'),

  /// `UPLOAD_FAILED`
  uploadFailed('UPLOAD_FAILED'),

  /// `AUTH_TOKEN_MISSING`
  authTokenMissing('AUTH_TOKEN_MISSING'),

  /// `AUTH_TOKEN_INVALID`
  authTokenInvalid('AUTH_TOKEN_INVALID'),

  /// `AUTH_TOKEN_EXPIRED`
  authTokenExpired('AUTH_TOKEN_EXPIRED'),

  /// `AUTH_USER_NOT_FOUND`
  authUserNotFound('AUTH_USER_NOT_FOUND'),

  /// `AUTH_APP_USER_NOT_FOUND`
  authAppUserNotFound('AUTH_APP_USER_NOT_FOUND'),

  /// `AUTH_COACH_REQUIRED`
  authCoachRequired('AUTH_COACH_REQUIRED'),

  /// `AUTH_INVALID_CREDENTIALS`
  authInvalidCredentials('AUTH_INVALID_CREDENTIALS'),

  /// `AUTH_EMAIL_NOT_VERIFIED`
  authEmailNotVerified('AUTH_EMAIL_NOT_VERIFIED'),

  /// `AUTH_EMAIL_ALREADY_EXISTS`
  authEmailAlreadyExists('AUTH_EMAIL_ALREADY_EXISTS'),

  /// `AUTH_USER_BANNED`
  authUserBanned('AUTH_USER_BANNED'),

  /// `AUTH_SIGNUP_DISABLED`
  authSignupDisabled('AUTH_SIGNUP_DISABLED'),

  /// `AUTH_WEAK_PASSWORD`
  authWeakPassword('AUTH_WEAK_PASSWORD'),

  /// `AUTH_SAME_PASSWORD`
  authSamePassword('AUTH_SAME_PASSWORD'),

  /// `AUTH_RATE_LIMITED`
  authRateLimited('AUTH_RATE_LIMITED'),

  /// `AUTH_SESSION_EXPIRED`
  authSessionExpired('AUTH_SESSION_EXPIRED'),

  /// `AUTH_BAD_JWT`
  authBadJwt('AUTH_BAD_JWT'),

  /// `AUTH_OAUTH_FAILED`
  authOauthFailed('AUTH_OAUTH_FAILED'),

  /// `AUTH_PROVIDER_ERROR`
  authProviderError('AUTH_PROVIDER_ERROR'),

  /// `AUTH_REFRESH_FAILED`
  authRefreshFailed('AUTH_REFRESH_FAILED'),

  /// `AUTH_CODE_EXCHANGE_FAILED`
  authCodeExchangeFailed('AUTH_CODE_EXCHANGE_FAILED'),

  /// `AUTH_TOKEN_GENERATION_FAILED`
  authTokenGenerationFailed('AUTH_TOKEN_GENERATION_FAILED'),

  /// `AUTH_ID_TOKEN_REQUIRED`
  authIdTokenRequired('AUTH_ID_TOKEN_REQUIRED'),

  /// `AUTH_ID_TOKEN_INVALID`
  authIdTokenInvalid('AUTH_ID_TOKEN_INVALID'),

  /// `SUBSCRIPTION_REQUIRED`
  subscriptionRequired('SUBSCRIPTION_REQUIRED'),

  /// `SUBSCRIPTION_TIER_INSUFFICIENT`
  subscriptionTierInsufficient('SUBSCRIPTION_TIER_INSUFFICIENT'),

  /// `SUBSCRIPTION_INVALID_SESSION`
  subscriptionInvalidSession('SUBSCRIPTION_INVALID_SESSION'),

  /// `USER_NOT_FOUND`
  userNotFound('USER_NOT_FOUND'),

  /// `USER_USERNAME_TAKEN`
  userUsernameTaken('USER_USERNAME_TAKEN'),

  /// `USER_EMAIL_TAKEN`
  userEmailTaken('USER_EMAIL_TAKEN'),

  /// `USER_ALREADY_EXISTS`
  userAlreadyExists('USER_ALREADY_EXISTS'),

  /// `USER_COACH_NOT_FOUND`
  userCoachNotFound('USER_COACH_NOT_FOUND'),

  /// `USER_COACH_ALREADY_SUBSCRIBED`
  userCoachAlreadySubscribed('USER_COACH_ALREADY_SUBSCRIBED'),

  /// `USER_COACH_NOT_ACCEPTING`
  userCoachNotAccepting('USER_COACH_NOT_ACCEPTING'),

  /// `USER_COACH_AT_CAPACITY`
  userCoachAtCapacity('USER_COACH_AT_CAPACITY'),

  /// `USER_COACH_NOT_SUBSCRIBED`
  userCoachNotSubscribed('USER_COACH_NOT_SUBSCRIBED'),

  /// `USER_COACH_ALREADY_UNSUBSCRIBED`
  userCoachAlreadyUnsubscribed('USER_COACH_ALREADY_UNSUBSCRIBED'),

  /// `PROFILE_NOT_FOUND`
  profileNotFound('PROFILE_NOT_FOUND'),

  /// `PROFILE_CREATE_FAILED`
  profileCreateFailed('PROFILE_CREATE_FAILED'),

  /// `PROFILE_UPDATE_FAILED`
  profileUpdateFailed('PROFILE_UPDATE_FAILED'),

  /// `PROFILE_AVATAR_UPLOAD_FAILED`
  profileAvatarUploadFailed('PROFILE_AVATAR_UPLOAD_FAILED'),

  /// `PROFILE_CLIENT_NOT_SUBSCRIBED`
  profileClientNotSubscribed('PROFILE_CLIENT_NOT_SUBSCRIBED'),

  /// `PROFILE_CLIENT_NOT_FOUND`
  profileClientNotFound('PROFILE_CLIENT_NOT_FOUND'),

  /// `GENERIC_UNIQUE_CONSTRAINT`
  genericUniqueConstraint('GENERIC_UNIQUE_CONSTRAINT'),

  /// `GENERIC_NOT_FOUND`
  genericNotFound('GENERIC_NOT_FOUND'),

  /// `GENERIC_FOREIGN_KEY`
  genericForeignKey('GENERIC_FOREIGN_KEY'),

  /// `WORKOUT_EXERCISE_NOT_FOUND`
  workoutExerciseNotFound('WORKOUT_EXERCISE_NOT_FOUND'),

  /// `WORKOUT_EXERCISE_DUPLICATE_NAME`
  workoutExerciseDuplicateName('WORKOUT_EXERCISE_DUPLICATE_NAME'),

  /// `WORKOUT_EXERCISE_FORBIDDEN`
  workoutExerciseForbidden('WORKOUT_EXERCISE_FORBIDDEN'),

  /// `WORKOUT_ROUTINE_NOT_FOUND`
  workoutRoutineNotFound('WORKOUT_ROUTINE_NOT_FOUND'),

  /// `WORKOUT_SESSION_NOT_FOUND`
  workoutSessionNotFound('WORKOUT_SESSION_NOT_FOUND'),

  /// `WORKOUT_SESSION_ALREADY_ACTIVE`
  workoutSessionAlreadyActive('WORKOUT_SESSION_ALREADY_ACTIVE'),

  /// `WORKOUT_SESSION_NOT_ACTIVE`
  workoutSessionNotActive('WORKOUT_SESSION_NOT_ACTIVE'),

  /// `WORKOUT_SESSION_ALREADY_COMPLETED`
  workoutSessionAlreadyCompleted('WORKOUT_SESSION_ALREADY_COMPLETED'),

  /// `WORKOUT_SET_NOT_FOUND`
  workoutSetNotFound('WORKOUT_SET_NOT_FOUND'),

  /// `WORKOUT_SET_ORDER_CONFLICT`
  workoutSetOrderConflict('WORKOUT_SET_ORDER_CONFLICT'),

  /// `WORKOUT_BATCH_SYNC_FAILED`
  workoutBatchSyncFailed('WORKOUT_BATCH_SYNC_FAILED'),

  /// `WORKOUT_WEEKLY_STATS_UNAVAILABLE`
  workoutWeeklyStatsUnavailable('WORKOUT_WEEKLY_STATS_UNAVAILABLE'),

  /// `PROGRAM_NOT_FOUND`
  programNotFound('PROGRAM_NOT_FOUND'),

  /// `PROGRAM_DUPLICATE_NAME`
  programDuplicateName('PROGRAM_DUPLICATE_NAME'),

  /// `PROGRAM_FORBIDDEN`
  programForbidden('PROGRAM_FORBIDDEN'),

  /// `ASSIGNMENT_NOT_FOUND`
  assignmentNotFound('ASSIGNMENT_NOT_FOUND'),

  /// `ASSIGNMENT_ALREADY_EXISTS`
  assignmentAlreadyExists('ASSIGNMENT_ALREADY_EXISTS'),

  /// `ASSIGNMENT_CLIENT_MISMATCH`
  assignmentClientMismatch('ASSIGNMENT_CLIENT_MISMATCH'),

  /// `COACH_ALREADY_EXISTS`
  coachAlreadyExists('COACH_ALREADY_EXISTS'),

  /// `COACH_CLIENT_NOT_LINKED`
  coachClientNotLinked('COACH_CLIENT_NOT_LINKED'),

  /// `COACH_CLIENT_NOT_FOUND`
  coachClientNotFound('COACH_CLIENT_NOT_FOUND'),

  /// `COACH_PROGRAM_LOCKED`
  coachProgramLocked('COACH_PROGRAM_LOCKED'),

  /// `COACH_DEACTIVATED`
  coachDeactivated('COACH_DEACTIVATED'),

  /// `COACH_MAX_CLIENTS_BELOW_ACTIVE`
  coachMaxClientsBelowActive('COACH_MAX_CLIENTS_BELOW_ACTIVE'),

  /// `PROGRAM_ROUTINE_NOT_FOUND`
  programRoutineNotFound('PROGRAM_ROUTINE_NOT_FOUND'),

  /// `PROGRAM_ROUTINE_DAY_CONFLICT`
  programRoutineDayConflict('PROGRAM_ROUTINE_DAY_CONFLICT'),

  /// `PROGRAM_REQUIRED`
  programRequired('PROGRAM_REQUIRED'),

  /// `SUBSCRIPTION_NOT_FOUND`
  subscriptionNotFound('SUBSCRIPTION_NOT_FOUND'),

  /// `SUBSCRIPTION_SYNC_FAILED`
  subscriptionSyncFailed('SUBSCRIPTION_SYNC_FAILED'),

  /// `SUBSCRIPTION_HISTORY_FETCH_FAILED`
  subscriptionHistoryFetchFailed('SUBSCRIPTION_HISTORY_FETCH_FAILED'),

  /// `REVENUECAT_INVALID_SIGNATURE`
  revenuecatInvalidSignature('REVENUECAT_INVALID_SIGNATURE'),

  /// `REVENUECAT_UNKNOWN_EVENT`
  revenuecatUnknownEvent('REVENUECAT_UNKNOWN_EVENT'),

  /// `REVENUECAT_USER_MISMATCH`
  revenuecatUserMismatch('REVENUECAT_USER_MISMATCH'),

  /// `REVENUECAT_DUPLICATE_EVENT`
  revenuecatDuplicateEvent('REVENUECAT_DUPLICATE_EVENT'),

  /// `STANDALONE_NOT_FOUND`
  standaloneNotFound('STANDALONE_NOT_FOUND'),

  /// `STANDALONE_ALREADY_COMPLETED`
  standaloneAlreadyCompleted('STANDALONE_ALREADY_COMPLETED'),

  /// `SESSION_NOT_FOUND`
  sessionNotFound('SESSION_NOT_FOUND'),

  /// `SESSION_PERMISSION_DENIED`
  sessionPermissionDenied('SESSION_PERMISSION_DENIED'),

  /// `TODAY_NO_ASSIGNED_WORKOUT`
  todayNoAssignedWorkout('TODAY_NO_ASSIGNED_WORKOUT'),

  /// `STATS_RANGE_INVALID`
  statsRangeInvalid('STATS_RANGE_INVALID'),

  /// `CLASS_NOT_FOUND`
  classNotFound('CLASS_NOT_FOUND'),

  /// `CLASS_CLIENT_ALREADY_REMOVED`
  classClientAlreadyRemoved('CLASS_CLIENT_ALREADY_REMOVED'),

  /// `COIN_INSUFFICIENT_BALANCE`
  coinInsufficientBalance('COIN_INSUFFICIENT_BALANCE'),

  /// `COIN_HISTORY_FETCH_FAILED`
  coinHistoryFetchFailed('COIN_HISTORY_FETCH_FAILED'),

  /// `SHOP_ITEM_NOT_FOUND`
  shopItemNotFound('SHOP_ITEM_NOT_FOUND'),

  /// `SHOP_ITEM_ALREADY_OWNED`
  shopItemAlreadyOwned('SHOP_ITEM_ALREADY_OWNED'),

  /// `SHOP_ITEM_OUT_OF_STOCK`
  shopItemOutOfStock('SHOP_ITEM_OUT_OF_STOCK'),

  /// `COSMETIC_NOT_FOUND`
  cosmeticNotFound('COSMETIC_NOT_FOUND'),

  /// `COSMETIC_NOT_OWNED`
  cosmeticNotOwned('COSMETIC_NOT_OWNED'),

  /// `COSMETIC_NOT_EQUIPPABLE`
  cosmeticNotEquippable('COSMETIC_NOT_EQUIPPABLE'),

  /// `LEADERBOARD_FETCH_FAILED`
  leaderboardFetchFailed('LEADERBOARD_FETCH_FAILED'),

  /// `LEADERBOARD_PERIOD_INVALID`
  leaderboardPeriodInvalid('LEADERBOARD_PERIOD_INVALID'),

  /// `POSE_IMAGE_INVALID`
  poseImageInvalid('POSE_IMAGE_INVALID'),

  /// `POSE_ANALYSIS_FAILED`
  poseAnalysisFailed('POSE_ANALYSIS_FAILED'),

  /// `POSE_FORM_NOT_FOUND`
  poseFormNotFound('POSE_FORM_NOT_FOUND'),

  /// Fallback for codes added server-side but not yet in this enum.
  unknown('UNKNOWN');

  const ApiErrorCode(this.value);

  /// The raw SCREAMING_SNAKE_CASE string from the API.
  final String value;

  /// Parse a raw code string into the enum, falling back to [unknown].
  static ApiErrorCode fromString(String raw) {
    for (final code in values) {
      if (code.value == raw) return code;
    }
    return unknown;
  }
}

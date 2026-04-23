# Error Codes — Client Consumption Guide

> How the Flutter app consumes the server's typed error codes.

---

## Envelope shape

Every API response follows the `{ data, errors }` envelope:

```json
{
  "data": { "id": "abc", "name": "..." },
  "errors": []
}
```

On failure:

```json
{
  "data": null,
  "errors": [
    {
      "code": "AUTH_INVALID_CREDENTIALS",
      "message": "Invalid email or password.",
      "field": null
    }
  ]
}
```

The `code` field is a `SCREAMING_SNAKE_CASE` constant from a fixed catalogue
(108 codes at time of writing). The generated Dart enum lives at
`lib/core/errors/api_error_codes.dart` — **do not hand-edit it**. Regenerate
via `npm run codegen:errors` in `server/`.

---

## Where `ApiErrorCode` comes from

1. `ApiClient._parseResponse` / `_tryParseServerErrors` reads `errors[0].code`.
2. It routes through `ApiErrorCode.fromString(raw)`, which returns `ApiErrorCode.unknown` for unrecognised strings and `null` for missing/empty codes.
3. The resulting `AppError` carries the typed code in `AppError.code` (`ApiErrorCode?`).

Transport-layer failures (timeout, no connection, cancelled) have `code == null`
and use `AppError.transportCode` (`String?`) instead.

---

## `errorMessageFor(error)` pattern

Import from `lib/core/errors/error_messages.dart`:

```dart
import 'package:get_gains_app/core/errors/error_messages.dart';

// In a listener, provider, or screen callback:
final message = errorMessageFor(appError);
AppToast.error(context, message);
```

The helper:

1. Checks `error.code`.
2. If it matches a curated entry in `_messageForCode`, returns the hardcoded
   English string (stable even if the server's copy changes).
3. Otherwise falls back to `error.message` (the raw server message).

### When to branch on `code`

Branch on `error.code` **only when the UX diverges** from "show an error
toast":

```dart
if (error.code == ApiErrorCode.authEmailNotVerified) {
  // Show "Resend verification" CTA
} else if (error.code == ApiErrorCode.userUsernameTaken) {
  // Highlight the username form field
} else {
  AppToast.error(context, errorMessageFor(error));
}
```

If you just need to show a message, call `errorMessageFor(error)` and be
done.

### `errorToastFor(error)` — title + body

For screens that show titled toasts:

```dart
final (:title, :body) = errorToastFor(error);
AppToast.error(context, body, title: title);
```

---

## AuthInterceptor refresh rules

The interceptor at `lib/services/api/interceptors.dart` only attempts a token
refresh for **recoverable** 401 codes:

| Code                                                                  | Action                        |
| --------------------------------------------------------------------- | ----------------------------- |
| `AUTH_TOKEN_EXPIRED`                                                  | Refresh token                 |
| `AUTH_SESSION_EXPIRED`                                                | Refresh token                 |
| `null` (legacy / no code)                                             | Refresh token (safe default)  |
| `UNKNOWN`                                                             | Refresh token (safe default)  |
| Anything else (e.g. `AUTH_INVALID_CREDENTIALS`, `AUTH_TOKEN_INVALID`) | Skip refresh, propagate error |

Auth endpoints (`/auth/login`, `/auth/register`, etc.) never trigger a forced
logout on failure — the error propagates to the caller so the screen can show
inline feedback.

---

## Adding a new code

1. Add the code in `server/src/lib/errors/codes.ts`.
2. Run `npm run codegen:errors` in `server/` — this regenerates `api_error_codes.dart`.
3. **Optional:** add a curated message in `error_messages.dart` `_messageForCode` switch. Only
   needed if the server's own message isn't good enough for UX.
4. **Optional:** add a branch in a screen if the UX should diverge (show a CTA, highlight a
   field, etc.).

---

## l10n handoff

When the app localises:

1. Replace the `switch` body in `_messageForCode` with `intl` lookups keyed by `code.value`.
2. No other file needs to change — every screen already flows through
   `errorMessageFor`.

---

_See also: `server/docs/error-codes.md` for the server-side catalogue._

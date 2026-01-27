# Auth Feature - Presentation Layer

> **Status**: ✅ Implemented  
> **Last Updated**: January 27, 2026

---

## Structure

```
lib/features/auth/presentation/
├── presentation.dart       # Barrel export
├── providers/
│   ├── providers.dart      # Provider exports
│   └── register_provider.dart
├── screens/
│   ├── screens.dart        # Screen exports
│   ├── login_screen.dart   # Placeholder → navigates to register
│   ├── register_screen.dart
│   └── complete_profile_screen.dart
└── widgets/
    └── widgets.dart        # Auth-specific widgets (if needed)
```

---

## Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| `LoginScreen` | `/login` | Placeholder, links to register |
| `RegisterScreen` | `/register` | Email/password + Google sign-up |
| `CompleteProfileScreen` | `/complete-profile` | Google sign-up step 2 |

---

## Components Used

| Component | Usage |
|-----------|-------|
| `AppTextField` | Email, password, name, nickname inputs |
| `AppTextField.password` | Password with visibility toggle |
| `AppButton.primary` | Main CTA (Register, Continue) |
| `AppButton.outline` | Secondary actions (Google sign-in) |
| `AppButton.link` | Navigation links (Already have account?) |
| `AppCard` | Form containers (optional) |
| `AppProgress` | Loading states |
| `AppSnackbar` | Error/success feedback |

---

## State Flow

```
RegisterInitial → User fills form
       ↓
RegisterLoading → API call
       ↓
RegisterSuccess → Navigate to /home
       OR
RegisterError → Show error snackbar
       OR
RegisterGooglePendingProfile → Navigate to /complete-profile
```

---

## Key Patterns

- **Form validation**: Client-side before submission
- **Loading states**: `AppButton.isLoading` + disabled inputs
- **Error handling**: `AppSnackbar.error` for API errors
- **Navigation**: `context.go()` after success

---

*See [REGISTER.md](REGISTER.md) for data layer details.*

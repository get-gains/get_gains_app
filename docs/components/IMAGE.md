# AppImage

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Optimized image loading component with built-in placeholders, error states, and loading animations. Handles network images, assets, and file images with consistent styling and graceful fallbacks.

---

## Variants

| Component | Purpose |
|-----------|---------|
| `AppImage` | Base image component with loading/error handling |
| `AppNetworkImage` | Network image with caching support |
| `AppCachedImage` | Cached network image with memory/disk caching |
| `AppImagePlaceholder` | Shimmer loading placeholder |

---

## Specifications

### Shape Variants

| Shape | BorderRadius | Usage |
|-------|--------------|-------|
| `rectangle` | `radiusNone` (0) | Full-bleed images |
| `rounded` | `radiusMd` (12px) | Cards, thumbnails |
| `roundedLg` | `radiusLg` (16px) | Feature images |
| `circle` | `radiusFull` | Avatars, profile images |

### Size Presets

| Size | Dimensions | Usage |
|------|------------|-------|
| `thumbnail` | 48×48 | List icons, small previews |
| `small` | 64×64 | Compact thumbnails |
| `medium` | 120×120 | Grid items, cards |
| `large` | 200×200 | Feature images |
| `hero` | Full width, 200h | Banner images |
| `custom` | User defined | Flexible sizing |

### Fit Options

| Fit | Behavior |
|-----|----------|
| `cover` | Fills container, may crop (default) |
| `contain` | Fits within container, may letterbox |
| `fill` | Stretches to fill exactly |
| `fitWidth` | Scales to match width |
| `fitHeight` | Scales to match height |

### States

| State | Visual |
|-------|--------|
| Loading | Shimmer placeholder animation |
| Loaded | Image displayed with fade-in |
| Error | Error icon with optional retry |
| Empty | Placeholder icon |

### Styling

- **Placeholder background**: `surface2` color
- **Shimmer base**: `surface1` color
- **Shimmer highlight**: `surface3` color
- **Error icon**: `mutedForeground` color
- **Fade duration**: `durationNormal` (200ms)
- **Border**: Optional, 1px `border` color

---

## Implementation

```dart
// lib/widgets/app_image.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Image shape variants
enum AppImageShape { rectangle, rounded, roundedLg, circle }

/// Predefined image sizes
enum AppImageSize { thumbnail, small, medium, large, hero, custom }

/// A customizable image component with loading states and error handling.
///
/// Example usage:
/// ```dart
/// AppImage.network(
///   url: 'https://example.com/image.jpg',
///   size: AppImageSize.medium,
///   shape: AppImageShape.rounded,
/// )
///
/// AppImage.asset(
///   path: 'assets/images/logo.png',
///   width: 100,
///   height: 100,
/// )
/// ```
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imageProvider,
    this.width,
    this.height,
    this.size = AppImageSize.custom,
    this.shape = AppImageShape.rectangle,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1,
    this.fadeInDuration = AppTheme.durationNormal,
    this.backgroundColor,
    this.semanticLabel,
  });

  /// Creates an AppImage from a network URL
  factory AppImage.network({
    Key? key,
    required String url,
    double? width,
    double? height,
    AppImageSize size = AppImageSize.custom,
    AppImageShape shape = AppImageShape.rectangle,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 1,
    Duration fadeInDuration = AppTheme.durationNormal,
    Color? backgroundColor,
    String? semanticLabel,
    Map<String, String>? headers,
  }) {
    return AppImage(
      key: key,
      imageProvider: NetworkImage(url, headers: headers),
      width: width,
      height: height,
      size: size,
      shape: shape,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
      fadeInDuration: fadeInDuration,
      backgroundColor: backgroundColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates an AppImage from an asset path
  factory AppImage.asset({
    Key? key,
    required String path,
    double? width,
    double? height,
    AppImageSize size = AppImageSize.custom,
    AppImageShape shape = AppImageShape.rectangle,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 1,
    Color? backgroundColor,
    String? semanticLabel,
  }) {
    return AppImage(
      key: key,
      imageProvider: AssetImage(path),
      width: width,
      height: height,
      size: size,
      shape: shape,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
      fadeInDuration: Duration.zero, // Assets load instantly
      backgroundColor: backgroundColor,
      semanticLabel: semanticLabel,
    );
  }

  /// Creates an AppImage from a file
  factory AppImage.file({
    Key? key,
    required File file,
    double? width,
    double? height,
    AppImageSize size = AppImageSize.custom,
    AppImageShape shape = AppImageShape.rectangle,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 1,
    Color? backgroundColor,
    String? semanticLabel,
  }) {
    return AppImage(
      key: key,
      imageProvider: FileImage(file),
      width: width,
      height: height,
      size: size,
      shape: shape,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
      fadeInDuration: Duration.zero,
      backgroundColor: backgroundColor,
      semanticLabel: semanticLabel,
    );
  }

  final ImageProvider imageProvider;
  final double? width;
  final double? height;
  final AppImageSize size;
  final AppImageShape shape;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final Duration fadeInDuration;
  final Color? backgroundColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context);
}
```

---

## Usage Examples

### Basic Network Image

```dart
AppImage.network(
  url: 'https://example.com/workout.jpg',
  width: 200,
  height: 200,
)
```

### Rounded Image with Size Preset

```dart
AppImage.network(
  url: profileImageUrl,
  size: AppImageSize.medium,
  shape: AppImageShape.rounded,
)
```

### Circular Image (Avatar Style)

```dart
AppImage.network(
  url: userAvatarUrl,
  size: AppImageSize.small,
  shape: AppImageShape.circle,
  showBorder: true,
  borderColor: AppColors.primary,
  borderWidth: 2,
)
```

### Hero Banner Image

```dart
AppImage.network(
  url: bannerUrl,
  size: AppImageSize.hero,
  shape: AppImageShape.roundedLg,
  fit: BoxFit.cover,
)
```

### Asset Image

```dart
AppImage.asset(
  path: 'assets/images/exercise_placeholder.png',
  width: 120,
  height: 120,
  shape: AppImageShape.rounded,
)
```

### Custom Placeholder & Error

```dart
AppImage.network(
  url: exerciseImageUrl,
  width: 150,
  height: 150,
  shape: AppImageShape.rounded,
  placeholder: Container(
    color: AppColors.surface2Dark,
    child: Icon(Icons.fitness_center, color: AppColors.mutedForegroundDark),
  ),
  errorWidget: Container(
    color: AppColors.surface2Dark,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, color: AppColors.mutedForegroundDark),
        SizedBox(height: 8),
        Text('Failed to load', style: AppTextStyles.labelSmall),
      ],
    ),
  ),
)
```

### Image in Card

```dart
AppCard(
  padding: EdgeInsets.zero,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppImage.network(
        url: workoutCoverUrl,
        width: double.infinity,
        height: 180,
        shape: AppImageShape.rectangle,
        fit: BoxFit.cover,
      ),
      Padding(
        padding: AppTheme.cardPadding,
        child: Text('Leg Day Workout', style: AppTextStyles.titleLarge),
      ),
    ],
  ),
)
```

### Grid of Images

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: AppTheme.spacing2,
    mainAxisSpacing: AppTheme.spacing2,
  ),
  itemCount: exercises.length,
  itemBuilder: (context, index) {
    return AppImage.network(
      url: exercises[index].imageUrl,
      shape: AppImageShape.rounded,
      fit: BoxFit.cover,
    );
  },
)
```

---

## Shimmer Placeholder

The `AppImagePlaceholder` provides a shimmer loading animation:

```dart
class AppImagePlaceholder extends StatefulWidget {
  const AppImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.shape = AppImageShape.rectangle,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final AppImageShape shape;
  final BorderRadius? borderRadius;
}
```

### Usage

```dart
// Default shimmer placeholder
AppImagePlaceholder(
  width: 120,
  height: 120,
  shape: AppImageShape.rounded,
)

// In a loading state
isLoading
  ? AppImagePlaceholder(width: 200, height: 200)
  : AppImage.network(url: imageUrl, width: 200, height: 200)
```

---

## Accessibility

### Semantic Labels

Always provide `semanticLabel` for meaningful images:

```dart
AppImage.network(
  url: exerciseImageUrl,
  semanticLabel: 'Demonstration of proper squat form',
)
```

### Decorative Images

For purely decorative images, use `excludeFromSemantics`:

```dart
Image(
  image: imageProvider,
  semanticLabel: null,
  excludeFromSemantics: true,
)
```

### Considerations

- **Content images**: Always include descriptive `semanticLabel`
- **Icon images**: Describe the action or meaning
- **Decorative images**: Exclude from semantics tree
- **Error states**: Provide text description of failure
- **Loading states**: Announce loading status via semantics

---

## Best Practices

1. **Always specify dimensions** when possible to prevent layout shifts
2. **Use size presets** for consistency across the app
3. **Provide placeholder** for network images to improve perceived performance
4. **Handle errors gracefully** with meaningful fallback UI
5. **Use appropriate fit** - `cover` for backgrounds, `contain` for logos
6. **Add semantic labels** for accessibility
7. **Consider memory** - use appropriate image sizes, avoid loading huge images for thumbnails

---

## Related Components

- [AppAvatar](./AVATAR.md) - Circular user profile images with status indicators
- [AppCard](./CARD.md) - Container that often includes images
- [AppProgress](./PROGRESS.md) - Skeleton loading states

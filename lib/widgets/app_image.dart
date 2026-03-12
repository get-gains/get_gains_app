// lib/widgets/app_image.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Image shape variants
enum AppImageShape {
  /// No border radius
  rectangle,

  /// Medium border radius (12px)
  rounded,

  /// Large border radius (16px)
  roundedLg,

  /// Fully circular
  circle,
}

/// Predefined image sizes
enum AppImageSize {
  /// 48x48 - List icons, small previews
  thumbnail,

  /// 64x64 - Compact thumbnails
  small,

  /// 120x120 - Grid items, cards
  medium,

  /// 200x200 - Feature images
  large,

  /// Full width, 200 height - Banner images
  hero,

  /// User-defined dimensions
  custom,
}

/// A customizable image component with loading states and error handling.
///
/// Provides consistent image display with built-in placeholders, error states,
/// and loading animations.
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

  /// The image provider (network, asset, file, etc.)
  final ImageProvider imageProvider;

  /// Explicit width (overrides size preset)
  final double? width;

  /// Explicit height (overrides size preset)
  final double? height;

  /// Predefined size preset
  final AppImageSize size;

  /// Shape variant for border radius
  final AppImageShape shape;

  /// How to fit the image within bounds
  final BoxFit fit;

  /// Widget shown while loading
  final Widget? placeholder;

  /// Widget shown on error
  final Widget? errorWidget;

  /// Whether to show a border around the image
  final bool showBorder;

  /// Border color (defaults to theme border color)
  final Color? borderColor;

  /// Border width in pixels
  final double borderWidth;

  /// Duration of fade-in animation
  final Duration fadeInDuration;

  /// Background color shown behind transparent images
  final Color? backgroundColor;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Get dimensions based on size preset
  (double?, double?) _getDimensions() {
    switch (size) {
      case AppImageSize.thumbnail:
        return (width ?? 48, height ?? 48);
      case AppImageSize.small:
        return (width ?? 64, height ?? 64);
      case AppImageSize.medium:
        return (width ?? 120, height ?? 120);
      case AppImageSize.large:
        return (width ?? 200, height ?? 200);
      case AppImageSize.hero:
        return (width ?? double.infinity, height ?? 200);
      case AppImageSize.custom:
        return (width, height);
    }
  }

  /// Get border radius based on shape
  BorderRadius _getBorderRadius() {
    switch (shape) {
      case AppImageShape.rectangle:
        return BorderRadius.zero;
      case AppImageShape.rounded:
        return AppTheme.borderRadiusMd;
      case AppImageShape.roundedLg:
        return AppTheme.borderRadiusLg;
      case AppImageShape.circle:
        return AppTheme.borderRadiusFull;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (resolvedWidth, resolvedHeight) = _getDimensions();
    final borderRadius = _getBorderRadius();

    final effectiveBorderColor =
        borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight);
    final effectiveBackgroundColor =
        backgroundColor ??
        (isDark ? AppColors.surface2Dark : AppColors.surface2Light);

    Widget imageWidget = _ImageLoader(
      imageProvider: imageProvider,
      fit: fit,
      width: resolvedWidth,
      height: resolvedHeight,
      fadeInDuration: fadeInDuration,
      placeholder:
          placeholder ??
          AppImagePlaceholder(
            width: resolvedWidth,
            height: resolvedHeight,
            shape: shape,
          ),
      errorWidget:
          errorWidget ??
          _DefaultErrorWidget(
            width: resolvedWidth,
            height: resolvedHeight,
            isDark: isDark,
          ),
      semanticLabel: semanticLabel,
    );

    // Apply clipping and decorations
    return Container(
      width: resolvedWidth,
      height: resolvedHeight,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: shape == AppImageShape.circle ? null : borderRadius,
        shape: shape == AppImageShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        border: showBorder
            ? Border.all(color: effectiveBorderColor, width: borderWidth)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }
}

/// Internal widget that handles image loading states
class _ImageLoader extends StatefulWidget {
  const _ImageLoader({
    required this.imageProvider,
    required this.fit,
    required this.placeholder,
    required this.errorWidget,
    required this.fadeInDuration,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final ImageProvider imageProvider;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget placeholder;
  final Widget errorWidget;
  final Duration fadeInDuration;
  final String? semanticLabel;

  @override
  State<_ImageLoader> createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<_ImageLoader>
    with SingleTickerProviderStateMixin {
  late ImageStream _imageStream;
  late ImageStreamListener _listener;
  ImageInfo? _imageInfo;
  bool _hasError = false;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeInDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppTheme.curveDefault,
    );
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _ImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _imageStream.removeListener(_listener);
      _resolveImage();
    }
  }

  void _resolveImage() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _imageStream = widget.imageProvider.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (mounted) {
          setState(() {
            _imageInfo = info;
            _isLoading = false;
            _hasError = false;
          });
          if (!synchronousCall && widget.fadeInDuration > Duration.zero) {
            _fadeController.forward(from: 0);
          } else {
            _fadeController.value = 1.0;
          }
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      },
    );
    _imageStream.addListener(_listener);
  }

  @override
  void dispose() {
    _imageStream.removeListener(_listener);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget;
    }

    if (_isLoading || _imageInfo == null) {
      return widget.placeholder;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RawImage(
        image: _imageInfo!.image,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        debugImageLabel: widget.semanticLabel,
      ),
    );
  }
}

/// Default error widget shown when image fails to load
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({this.width, this.height, required this.isDark});

  final double? width;
  final double? height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: iconColor,
        size: _getIconSize(),
      ),
    );
  }

  double _getIconSize() {
    if (width == null && height == null) return 24;
    final minDim = (width ?? height)!;
    if (minDim < 48) return 16;
    if (minDim < 80) return 24;
    if (minDim < 150) return 32;
    return 48;
  }
}

/// Shimmer loading placeholder for images
///
/// Displays an animated shimmer effect while the image is loading.
///
/// Example usage:
/// ```dart
/// AppImagePlaceholder(
///   width: 120,
///   height: 120,
///   shape: AppImageShape.rounded,
/// )
/// ```
class AppImagePlaceholder extends StatefulWidget {
  const AppImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.shape = AppImageShape.rectangle,
    this.borderRadius,
  });

  /// Width of the placeholder
  final double? width;

  /// Height of the placeholder
  final double? height;

  /// Shape variant for border radius
  final AppImageShape shape;

  /// Custom border radius (overrides shape)
  final BorderRadius? borderRadius;

  @override
  State<AppImagePlaceholder> createState() => _AppImagePlaceholderState();
}

class _AppImagePlaceholderState extends State<AppImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BorderRadius _getBorderRadius() {
    if (widget.borderRadius != null) return widget.borderRadius!;
    switch (widget.shape) {
      case AppImageShape.rectangle:
        return BorderRadius.zero;
      case AppImageShape.rounded:
        return AppTheme.borderRadiusMd;
      case AppImageShape.roundedLg:
        return AppTheme.borderRadiusLg;
      case AppImageShape.circle:
        return AppTheme.borderRadiusFull;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.surface1Dark : AppColors.surface1Light;
    final highlightColor = isDark
        ? AppColors.surface3Dark
        : AppColors.surface3Light;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.shape == AppImageShape.circle
                ? null
                : _getBorderRadius(),
            shape: widget.shape == AppImageShape.circle
                ? BoxShape.circle
                : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, (_animation.value + 2) / 4, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A simple image placeholder with an icon
///
/// Use this for static placeholders without animation.
class AppImageIconPlaceholder extends StatelessWidget {
  const AppImageIconPlaceholder({
    super.key,
    this.width,
    this.height,
    this.icon = Icons.image_outlined,
    this.iconSize,
    this.backgroundColor,
    this.iconColor,
    this.shape = AppImageShape.rectangle,
  });

  final double? width;
  final double? height;
  final IconData icon;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final AppImageShape shape;

  BorderRadius _getBorderRadius() {
    switch (shape) {
      case AppImageShape.rectangle:
        return BorderRadius.zero;
      case AppImageShape.rounded:
        return AppTheme.borderRadiusMd;
      case AppImageShape.roundedLg:
        return AppTheme.borderRadiusLg;
      case AppImageShape.circle:
        return AppTheme.borderRadiusFull;
    }
  }

  double _getIconSize() {
    if (iconSize != null) return iconSize!;
    if (width == null && height == null) return 24;
    final minDim = (width ?? height)!;
    if (minDim < 48) return 16;
    if (minDim < 80) return 24;
    if (minDim < 150) return 32;
    return 48;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBackgroundColor =
        backgroundColor ??
        (isDark ? AppColors.surface2Dark : AppColors.surface2Light);
    final effectiveIconColor =
        iconColor ??
        (isDark
            ? AppColors.mutedForegroundDark
            : AppColors.mutedForegroundLight);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: shape == AppImageShape.circle ? null : _getBorderRadius(),
        shape: shape == AppImageShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: _getIconSize(), color: effectiveIconColor),
    );
  }
}

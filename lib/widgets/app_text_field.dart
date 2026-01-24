// lib/widgets/app_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Text field variant types
enum AppTextFieldVariant { outlined, filled, underlined }

/// Text field size options
enum AppTextFieldSize { sm, md, lg }

/// Text field state for custom validation display
enum AppTextFieldState { normal, error, success }

/// A customizable text field component following the design system.
///
/// Example usage:
/// ```dart
/// AppTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   keyboardType: TextInputType.emailAddress,
/// )
///
/// AppTextField.password(
///   label: 'Password',
///   controller: passwordController,
/// )
///
/// AppTextField.search(
///   hint: 'Search exercises...',
///   onChanged: (value) => searchExercises(value),
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.variant = AppTextFieldVariant.outlined,
    this.size = AppTextFieldSize.md,
    this.fieldState = AppTextFieldState.normal,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
  });

  /// Password field factory
  factory AppTextField.password({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    AppTextFieldVariant variant = AppTextFieldVariant.outlined,
    AppTextFieldSize size = AppTextFieldSize.md,
    AppTextFieldState fieldState = AppTextFieldState.normal,
    bool enabled = true,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return _PasswordTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      variant: variant,
      size: size,
      fieldState: fieldState,
      enabled: enabled,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      focusNode: focusNode,
    );
  }

  /// Search field factory
  factory AppTextField.search({
    Key? key,
    TextEditingController? controller,
    String? hint,
    AppTextFieldSize size = AppTextFieldSize.md,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    FocusNode? focusNode,
  }) {
    return _SearchTextField(
      key: key,
      controller: controller,
      hint: hint,
      size: size,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
      focusNode: focusNode,
    );
  }

  /// Multiline text area factory
  const AppTextField.textArea({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.variant = AppTextFieldVariant.outlined,
    this.size = AppTextFieldSize.md,
    this.fieldState = AppTextFieldState.normal,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 4,
    this.minLines = 3,
    this.maxLength,
    this.showCounter = true,
    this.onChanged,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
  }) : obscureText = false,
       keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       inputFormatters = null,
       prefixIcon = null,
       suffixIcon = null,
       prefix = null,
       suffix = null,
       onSubmitted = null;

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final AppTextFieldVariant variant;
  final AppTextFieldSize size;
  final AppTextFieldState fieldState;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autocorrect;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError =
        widget.fieldState == AppTextFieldState.error ||
        widget.errorText != null;
    final hasSuccess = widget.fieldState == AppTextFieldState.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: _getLabelColor(isDark, hasError, hasSuccess),
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
        ],
        AnimatedContainer(
          duration: AppTheme.durationFast,
          curve: AppTheme.curveDefault,
          decoration: _getDecoration(isDark, hasError, hasSuccess),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            autocorrect: widget.autocorrect,
            style: _getTextStyle(isDark),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: _getHintStyle(isDark),
              contentPadding: _getContentPadding(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: widget.showCounter ? null : '',
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: _getIconSize(),
                      color: _getIconColor(isDark, hasError, hasSuccess),
                    )
                  : widget.prefix,
              suffixIcon: widget.suffixIcon != null
                  ? Icon(
                      widget.suffixIcon,
                      size: _getIconSize(),
                      color: _getIconColor(isDark, hasError, hasSuccess),
                    )
                  : widget.suffix,
            ),
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            validator: widget.validator,
          ),
        ),
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: AppTheme.spacing1),
          Text(
            widget.errorText ?? widget.helperText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: hasError
                  ? AppColors.error
                  : (isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight),
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _getDecoration(bool isDark, bool hasError, bool hasSuccess) {
    switch (widget.variant) {
      case AppTextFieldVariant.outlined:
        return BoxDecoration(
          color: widget.enabled
              ? (isDark ? AppColors.inputDark : AppColors.surface1Light)
              : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: _getBorderColor(isDark, hasError, hasSuccess),
            width: _isFocused ? 2 : 1,
          ),
        );

      case AppTextFieldVariant.filled:
        return BoxDecoration(
          color: widget.enabled
              ? (isDark ? AppColors.surface2Dark : AppColors.surface2Light)
              : (isDark ? AppColors.mutedDark : AppColors.mutedLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: _isFocused
              ? Border.all(
                  color: _getBorderColor(isDark, hasError, hasSuccess),
                  width: 2,
                )
              : null,
        );

      case AppTextFieldVariant.underlined:
        return BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _getBorderColor(isDark, hasError, hasSuccess),
              width: _isFocused ? 2 : 1,
            ),
          ),
        );
    }
  }

  Color _getBorderColor(bool isDark, bool hasError, bool hasSuccess) {
    if (hasError) return AppColors.error;
    if (hasSuccess) return AppColors.success;
    if (_isFocused) return isDark ? AppColors.ringDark : AppColors.ringLight;
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Color _getLabelColor(bool isDark, bool hasError, bool hasSuccess) {
    if (hasError) return AppColors.error;
    if (hasSuccess) return AppColors.success;
    if (_isFocused) {
      return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
    return isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
  }

  Color _getIconColor(bool isDark, bool hasError, bool hasSuccess) {
    if (hasError) return AppColors.error;
    if (hasSuccess) return AppColors.success;
    if (_isFocused) {
      return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
    return isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
  }

  TextStyle _getTextStyle(bool isDark) {
    final baseStyle = switch (widget.size) {
      AppTextFieldSize.sm => AppTextStyles.bodyMedium,
      AppTextFieldSize.md => AppTextStyles.bodyLarge,
      AppTextFieldSize.lg => AppTextStyles.titleMedium,
    };
    return baseStyle.copyWith(
      color: widget.enabled
          ? (isDark ? AppColors.foregroundDark : AppColors.foregroundLight)
          : (isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight),
    );
  }

  TextStyle _getHintStyle(bool isDark) {
    final baseStyle = switch (widget.size) {
      AppTextFieldSize.sm => AppTextStyles.bodyMedium,
      AppTextFieldSize.md => AppTextStyles.bodyLarge,
      AppTextFieldSize.lg => AppTextStyles.titleMedium,
    };
    return baseStyle.copyWith(
      color: isDark
          ? AppColors.mutedForegroundDark
          : AppColors.mutedForegroundLight,
    );
  }

  EdgeInsets _getContentPadding() {
    return switch (widget.size) {
      AppTextFieldSize.sm => const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      AppTextFieldSize.md => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      AppTextFieldSize.lg => const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      AppTextFieldSize.sm => 18,
      AppTextFieldSize.md => 20,
      AppTextFieldSize.lg => 24,
    };
  }
}

/// Password text field with toggle visibility
class _PasswordTextField extends AppTextField {
  const _PasswordTextField({
    super.key,
    super.controller,
    super.label,
    super.hint,
    super.helperText,
    super.errorText,
    super.variant,
    super.size,
    super.fieldState,
    super.enabled,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
    super.validator,
    super.focusNode,
  }) : super(
         obscureText: true,
         keyboardType: TextInputType.visiblePassword,
         autocorrect: false,
       );

  @override
  State<AppTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends _AppTextFieldState {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError =
        widget.fieldState == AppTextFieldState.error ||
        widget.errorText != null;
    final hasSuccess = widget.fieldState == AppTextFieldState.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: _getLabelColor(isDark, hasError, hasSuccess),
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
        ],
        AnimatedContainer(
          duration: AppTheme.durationFast,
          curve: AppTheme.curveDefault,
          decoration: _getDecoration(isDark, hasError, hasSuccess),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            enabled: widget.enabled,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: widget.textInputAction,
            autocorrect: false,
            style: _getTextStyle(isDark),
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Enter password',
              hintStyle: _getHintStyle(isDark),
              contentPadding: _getContentPadding(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.lock_outline,
                size: _getIconSize(),
                color: _getIconColor(isDark, hasError, hasSuccess),
              ),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscureText = !_obscureText),
                child: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: _getIconSize(),
                  color: _getIconColor(isDark, hasError, hasSuccess),
                ),
              ),
            ),
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
          ),
        ),
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: AppTheme.spacing1),
          Text(
            widget.errorText ?? widget.helperText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: hasError
                  ? AppColors.error
                  : (isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight),
            ),
          ),
        ],
      ],
    );
  }
}

/// Search text field with clear button
class _SearchTextField extends AppTextField {
  const _SearchTextField({
    super.key,
    super.controller,
    super.hint,
    super.size,
    super.enabled,
    super.autofocus,
    super.onChanged,
    super.onSubmitted,
    this.onClear,
    super.focusNode,
  }) : super(
         variant: AppTextFieldVariant.filled,
         keyboardType: TextInputType.text,
         textInputAction: TextInputAction.search,
       );

  final VoidCallback? onClear;

  @override
  State<AppTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends _AppTextFieldState {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChange);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChange);
    }
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    (widget as _SearchTextField).onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppTheme.durationFast,
      curve: AppTheme.curveDefault,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: _isFocused
            ? Border.all(
                color: isDark ? AppColors.ringDark : AppColors.ringLight,
                width: 2,
              )
            : null,
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: _getTextStyle(isDark),
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Search...',
          hintStyle: _getHintStyle(isDark),
          contentPadding: _getContentPadding(),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            size: _getIconSize(),
            color: isDark
                ? AppColors.mutedForegroundDark
                : AppColors.mutedForegroundLight,
          ),
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: _clearText,
                  child: Icon(
                    Icons.close,
                    size: _getIconSize(),
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                )
              : null,
        ),
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
      ),
    );
  }
}

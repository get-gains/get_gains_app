import 'package:freezed_annotation/freezed_annotation.dart';

part 'help_content_model.freezed.dart';
part 'help_content_model.g.dart';

/// Help content shown in a bottom sheet when a user taps an info icon.
@freezed
abstract class HelpContentModel with _$HelpContentModel {
  const factory HelpContentModel({
    /// Screen or element this help content is for
    required String id,

    /// Bottom sheet title
    required String title,

    /// Ordered list of content sections
    required List<HelpSection> sections,
  }) = _HelpContentModel;

  factory HelpContentModel.fromJson(Map<String, dynamic> json) =>
      _$HelpContentModelFromJson(json);
}

/// A single section within help content.
@freezed
abstract class HelpSection with _$HelpSection {
  const factory HelpSection({
    /// Section heading (optional — omit for single-section help)
    String? heading,

    /// Section body text
    required String body,

    /// Optional icon to display next to heading (Material icon name)
    String? iconName,
  }) = _HelpSection;

  factory HelpSection.fromJson(Map<String, dynamic> json) =>
      _$HelpSectionFromJson(json);
}

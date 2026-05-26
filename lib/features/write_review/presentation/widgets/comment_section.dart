import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'section_label.dart';

/// Optional one-line review field with live character counter.
///
/// 150-char cap matches the design spec. Hard-clipping via a
/// [LengthLimitingTextInputFormatter] is friendlier than a maxLength badge
/// since users can't accidentally paste past the limit.
class CommentSection extends StatelessWidget {
  const CommentSection({
    super.key,
    required this.controller,
    required this.maxChars,
    required this.l,
  });

  final TextEditingController controller;
  final int maxChars;
  final CommentSectionLabels l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceMd,
        AppConstants.spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            icon: Icons.chat_bubble_outline_rounded,
            label: l.title,
            badgeText: l.optionalBadge,
          ),
          const SizedBox(height: AppConstants.spaceSm),
          _CommentField(
            controller: controller,
            maxChars: maxChars,
            placeholder: l.placeholder,
          ),
          const SizedBox(height: 4),
          _Counter(controller: controller, maxChars: maxChars),
        ],
      ),
    );
  }
}

class CommentSectionLabels {
  const CommentSectionLabels({
    required this.title,
    required this.optionalBadge,
    required this.placeholder,
  });

  final String title;
  final String optionalBadge;
  final String placeholder;
}

class _CommentField extends StatefulWidget {
  const _CommentField({
    required this.controller,
    required this.maxChars,
    required this.placeholder,
  });

  final TextEditingController controller;
  final int maxChars;
  final String placeholder;

  @override
  State<_CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final borderColor = _focus.hasFocus ? c.primary : c.borderPrimary;
    final borderWidth = _focus.hasFocus ? 1.5 : 0.5;
    return Container(
      constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        maxLines: null,
        expands: false,
        inputFormatters: [
          LengthLimitingTextInputFormatter(widget.maxChars),
        ],
        textInputAction: TextInputAction.done,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: c.textPrimary,
          height: 1.5,
        ),
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            color: c.textTertiary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.controller, required this.maxChars});

  final TextEditingController controller;
  final int maxChars;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, _) {
        final used = value.text.characters.length;
        final atLimit = used >= maxChars;
        final warning = used > maxChars - 20;
        Color color;
        if (atLimit) {
          color = c.errorText;
        } else if (warning) {
          color = c.primary;
        } else {
          color = c.textSecondary;
        }
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$used / $maxChars',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

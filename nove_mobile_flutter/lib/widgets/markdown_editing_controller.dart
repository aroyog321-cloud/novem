import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

class MarkdownEditingController extends TextEditingController {
  final BuildContext context;

  MarkdownEditingController({required this.context, super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle baseStyle = style ?? const TextStyle();
    final List<InlineSpan> children = [];
    final String text = this.text;

    // A unified regex to match markdown elements.
    final regex = RegExp(
      r'(!\[(.*?)\]\((.*?)\))|(\*\*([\s\S]*?)\*\*)|(_([\s\S]*?)_)|(^(#+) +(.*)$)|(^> +(.*)$)|(^(☑|☐) +(.*)$)|(^(•|-) +(.*)$)|(`([\s\S]*?)`)',
      multiLine: true,
    );

    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: baseStyle));
      }

      // We use fontSize: 1 and transparent color so the characters still "exist" for the caret
      // but are invisible to the user.
      final invisibleStyle = baseStyle.copyWith(color: Colors.transparent, fontSize: 1, letterSpacing: -1, height: 0.1);

      // Match 1: Image
      if (match.group(1) != null) {
        final fullMatch = match.group(0)!;
        final path = match.group(3)!;
        
        // Critical Fix: WidgetSpan takes 1 character of space. We replace the FIRST character of the 
        // markdown with the WidgetSpan, and make the rest invisible, keeping the text length exactly synchronized!
        children.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NoveRadii.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 100,
                    width: 200,
                    decoration: BoxDecoration(
                      color: NoveColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(NoveRadii.md),
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, color: NoveColors.error, size: 32),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
        
        if (fullMatch.length > 1) {
          children.add(TextSpan(text: fullMatch.substring(1), style: invisibleStyle));
        }
      }
      // Match 4: Bold
      else if (match.group(4) != null) {
        children.add(TextSpan(text: '**', style: invisibleStyle));
        children.add(TextSpan(text: match.group(5), style: baseStyle.copyWith(fontWeight: FontWeight.bold)));
        children.add(TextSpan(text: '**', style: invisibleStyle));
      }
      // Match 6: Italic
      else if (match.group(6) != null) {
        children.add(TextSpan(text: '_', style: invisibleStyle));
        children.add(TextSpan(text: match.group(7), style: baseStyle.copyWith(fontStyle: FontStyle.italic)));
        children.add(TextSpan(text: '_', style: invisibleStyle));
      }
      // Match 8: Header
      else if (match.group(8) != null) {
        final hashes = match.group(9)!;
        final content = match.group(10)!;
        double size = 24;
        if (hashes.length == 2) size = 20;
        if (hashes.length >= 3) size = 17;
        
        children.add(TextSpan(text: '$hashes ', style: invisibleStyle));
        children.add(TextSpan(
          text: content,
          style: GoogleFonts.lora(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: NoveColors.primaryText(context),
            height: 1.3,
          ),
        ));
      }
      // Match 11: Quote
      else if (match.group(11) != null) {
        children.add(TextSpan(text: '> ', style: invisibleStyle));
        children.add(TextSpan(
          text: match.group(12),
          style: GoogleFonts.lora(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: NoveColors.secondaryText(context),
          ),
        ));
      }
      // Match 13: Checkbox
      else if (match.group(13) != null) {
        final fullMatch = match.group(0)!;
        final isDone = match.group(14) == '☑';
        final content = match.group(15)!;
        
        // 1 char for the WidgetSpan
        children.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              final newText = text.replaceRange(match.start, match.end, '${isDone ? "☐" : "☑"} $content');
              final sel = this.selection;
              this.value = TextEditingValue(
                text: newText,
                selection: sel.isValid ? sel : TextSelection.collapsed(offset: newText.length),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: Icon(
                isDone ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: isDone ? NoveColors.accent(context) : NoveColors.warmGray400,
              ),
            ),
          ),
        ));
        
        // Hide the remaining space/characters before the text
        final spacePart = fullMatch.substring(1, fullMatch.length - content.length);
        if (spacePart.isNotEmpty) {
          children.add(TextSpan(text: spacePart, style: invisibleStyle));
        }
        
        children.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? NoveColors.mutedText(context) : null,
          ),
        ));
      }
      // Match 16: Bullet
      else if (match.group(16) != null) {
        final fullMatch = match.group(0)!; // '• text'
        final bulletStr = match.group(17)!; // '•' or '-'
        final content = match.group(18)!;
        
        // No need for WidgetSpan, just color the bullet
        children.add(TextSpan(
          text: '$bulletStr ',
          style: baseStyle.copyWith(color: NoveColors.accent(context), fontWeight: FontWeight.bold),
        ));
        children.add(TextSpan(
          text: content,
          style: baseStyle,
        ));
      }
      // Match 19: Inline code
      else if (match.group(19) != null) {
        children.add(TextSpan(text: '`', style: invisibleStyle));
        children.add(TextSpan(
          text: match.group(20),
          style: GoogleFonts.firaCode(
            backgroundColor: NoveColors.warmGray300.withValues(alpha: 0.3),
            fontSize: 14,
            color: NoveColors.terracotta,
          ),
        ));
        children.add(TextSpan(text: '`', style: invisibleStyle));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return TextSpan(style: baseStyle, children: children);
  }
}

import 'package:flutter/material.dart';
import 'package:jadwalin/ui/color.dart';

/// Parser Markdown ringan untuk bubble chat:
/// mendukung **bold**, *italic*, bullet (`- ` / `• `), dan baris baru.
class FormattedMessageText extends StatelessWidget {
  const FormattedMessageText({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  static final RegExp _boldPattern = RegExp(r'\*\*(.+?)\*\*');
  static final RegExp _italicPattern =
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)');

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: isUser ? Colors.white : darkEspresso,
      height: 1.4,
    );

    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }
      final isBullet =
          line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('• ');

      final content = isBullet ? line.trimLeft().substring(2) : line;

      final spans = _buildSpans(content, base);

      if (isBullet) {
        spans.insert(
          0,
          TextSpan(
            text: '• ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color:
                  isUser ? Colors.white.withValues(alpha: 0.8) : primaryColor,
            ),
          ),
        );
      }

      children.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i == lines.length - 1 ? 0 : 3,
            left: isBullet ? 4 : 0,
          ),
          child: Text.rich(
            TextSpan(style: base, children: spans),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  List<TextSpan> _buildSpans(String input, TextStyle base) {
    final spans = <TextSpan>[];
    var cursor = 0;

    // Kumpulkan semua match bold + italic, urut berdasarkan posisi teks.
    final matches = <_InlineMatch>[
      ..._boldPattern.allMatches(input).map(
            (m) => _InlineMatch(
              start: m.start,
              end: m.end,
              content: m.group(1)!,
              weight: FontWeight.w700,
            ),
          ),
      ..._italicPattern.allMatches(input).map(
            (m) => _InlineMatch(
              start: m.start,
              end: m.end,
              content: m.group(1)!,
              style: FontStyle.italic,
            ),
          ),
    ]..sort((a, b) => a.start.compareTo(b.start));

    for (final m in matches) {
      if (m.start < cursor) continue; // Lewati match yang tumpang tindih
      if (m.start > cursor) {
        spans.add(TextSpan(text: input.substring(cursor, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.content,
          style: TextStyle(fontWeight: m.weight, fontStyle: m.style),
        ),
      );
      cursor = m.end;
    }

    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor)));
    }

    return spans;
  }
}

class _InlineMatch {
  const _InlineMatch({
    required this.start,
    required this.end,
    required this.content,
    this.weight,
    this.style,
  });

  final int start;
  final int end;
  final String content;
  final FontWeight? weight;
  final FontStyle? style;
}

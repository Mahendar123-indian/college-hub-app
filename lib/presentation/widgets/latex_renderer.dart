import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// 🎯 ADVANCED LATEX MATH RENDERER
/// Supports inline ($...$) and block ($$...$$) math expressions
class LatexRenderer extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;
  final bool isDarkMode;

  const LatexRenderer({
    Key? key,
    required this.content,
    this.textStyle,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildMixedContent();
  }

  Widget _buildMixedContent() {
    final parts = _parseLatexContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part['type'] == 'latex_block') {
          return _buildBlockMath(part['content']!);
        } else if (part['type'] == 'text_with_inline') {
          // This contains mixed text and inline math
          return _buildTextWithInlineMath(part['content']!);
        } else if (part['type'] == 'text') {
          return _buildText(part['content']!);
        } else {
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  /// Parse content to extract LaTeX expressions
  List<Map<String, String>> _parseLatexContent(String text) {
    final parts = <Map<String, String>>[];
    final blockRegex = RegExp(r'\$\$(.*?)\$\$', dotAll: true);

    int lastEnd = 0;

    // First, find all block math ($$...$$)
    final blockMatches = blockRegex.allMatches(text).toList();

    for (final match in blockMatches) {
      // Add text before this match (may contain inline math)
      if (match.start > lastEnd) {
        final textBefore = text.substring(lastEnd, match.start);
        if (textBefore.trim().isNotEmpty) {
          parts.add({
            'type': 'text_with_inline',
            'content': textBefore,
          });
        }
      }

      // Add block math
      parts.add({
        'type': 'latex_block',
        'content': match.group(1)!.trim(),
      });

      lastEnd = match.end;
    }

    // Add remaining text (may contain inline math)
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.trim().isNotEmpty) {
        parts.add({
          'type': 'text_with_inline',
          'content': remaining,
        });
      }
    }

    return parts;
  }

  /// Build text that may contain inline math
  Widget _buildTextWithInlineMath(String text) {
    final inlineRegex = RegExp(r'\$(.*?)\$');
    final matches = inlineRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return _buildText(text);
    }

    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before this match
      if (match.start > lastEnd) {
        final textBefore = text.substring(lastEnd, match.start);
        if (textBefore.isNotEmpty) {
          spans.add(TextSpan(
            text: textBefore,
            style: textStyle ?? const TextStyle(fontSize: 15, height: 1.5),
          ));
        }
      }

      // Add inline math
      final latex = match.group(1)?.trim() ?? '';
      spans.add(WidgetSpan(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: _buildMathWidget(latex, isBlock: false),
        ),
        alignment: PlaceholderAlignment.middle,
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.isNotEmpty) {
        spans.add(TextSpan(
          text: remaining,
          style: textStyle ?? const TextStyle(fontSize: 15, height: 1.5),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: spans,
          style: textStyle ?? const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// Build block math (centered, larger)
  Widget _buildBlockMath(String latex) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: _buildMathWidget(latex, isBlock: true),
      ),
    );
  }

  /// Build actual Math widget
  Widget _buildMathWidget(String latex, {required bool isBlock}) {
    try {
      return Math.tex(
        latex,
        textStyle: TextStyle(
          fontSize: isBlock ? 20 : 16,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        mathStyle: isBlock ? MathStyle.display : MathStyle.text,
        onErrorFallback: (err) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'LaTeX Error: $latex',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Text(
        'Error rendering: $latex',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      );
    }
  }

  /// Build plain text
  Widget _buildText(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: textStyle ?? const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// 🎨 MATH EQUATION CARD - Beautiful Math Display
class MathEquationCard extends StatelessWidget {
  final String title;
  final String equation;
  final String? description;
  final Color color;

  const MathEquationCard({
    Key? key,
    required this.title,
    required this.equation,
    this.description,
    this.color = const Color(0xFF6366F1),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.functions_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Equation
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Math.tex(
                equation,
                textStyle: const TextStyle(fontSize: 22),
                mathStyle: MathStyle.display,
              ),
            ),
          ),

          // Description
          if (description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
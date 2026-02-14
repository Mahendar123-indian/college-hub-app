import 'package:flutter/material.dart';

/// 🎯 SIMPLE LATEX/MATH RENDERER (Without flutter_math_fork)
/// Displays math expressions with proper formatting
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
    return _buildContent();
  }

  Widget _buildContent() {
    // Check for block math ($$...$$)
    if (content.contains(r'$$')) {
      return _buildBlockMath(content);
    }

    // Check for inline math ($...$)
    if (content.contains(r'$')) {
      return _buildInlineMath(content);
    }

    // Plain text
    return _buildText(content);
  }

  Widget _buildBlockMath(String text) {
    final parts = <Widget>[];
    final blockRegex = RegExp(r'\$\$(.*?)\$\$', dotAll: true);
    int lastEnd = 0;

    for (final match in blockRegex.allMatches(text)) {
      // Add text before math
      if (match.start > lastEnd) {
        final textBefore = text.substring(lastEnd, match.start);
        if (textBefore.trim().isNotEmpty) {
          parts.add(_buildText(textBefore));
        }
      }

      // Add block math
      final mathContent = match.group(1)?.trim() ?? '';
      parts.add(_buildMathBlock(mathContent));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.trim().isNotEmpty) {
        parts.add(_buildText(remaining));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  Widget _buildInlineMath(String text) {
    final inlineRegex = RegExp(r'\$(.*?)\$');
    final matches = inlineRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return _buildText(text);
    }

    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before match
      if (match.start > lastEnd) {
        final textBefore = text.substring(lastEnd, match.start);
        if (textBefore.isNotEmpty) {
          spans.add(TextSpan(text: textBefore));
        }
      }

      // Add inline math
      final mathContent = match.group(1)?.trim() ?? '';
      spans.add(WidgetSpan(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            mathContent,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: isDarkMode ? Colors.white : const Color(0xFF6366F1),
            ),
          ),
        ),
        alignment: PlaceholderAlignment.middle,
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.isNotEmpty) {
        spans.add(TextSpan(text: remaining));
      }
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: textStyle ?? TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMathBlock(String mathContent) {
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
      child: SelectableText(
        mathContent,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          color: isDarkMode ? Colors.white : const Color(0xFF6366F1),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildText(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SelectableText(
        text.trim(),
        style: textStyle ?? TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isDarkMode ? Colors.white : Colors.black87,
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
              child: SelectableText(
                equation,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: color,
                ),
                textAlign: TextAlign.center,
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
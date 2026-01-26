import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_highlight/themes/github.dart';

/// 🎨 ADVANCED CODE SYNTAX HIGHLIGHTER
/// Supports 20+ languages with beautiful UI
class CodeHighlighter extends StatefulWidget {
  final String code;
  final String language;
  final bool showLineNumbers;
  final bool isDarkMode;

  const CodeHighlighter({
    Key? key,
    required this.code,
    required this.language,
    this.showLineNumbers = true,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<CodeHighlighter> createState() => _CodeHighlighterState();
}

class _CodeHighlighterState extends State<CodeHighlighter> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildCodeArea(),
        ],
      ),
    );
  }

  /// Build header with language and actions
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF252526)
            : const Color(0xFFF3F4F6),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode
                ? const Color(0xFF3E3E42)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          // Language Icon & Name
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getLanguageColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getLanguageIcon(),
              size: 18,
              color: _getLanguageColor(),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getLanguageName(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getLanguageColor(),
            ),
          ),
          const Spacer(),

          // Copy Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _copyCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _copied
                      ? Colors.green.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _copied
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 16,
                      color: _copied ? Colors.green : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _copied ? 'Copied!' : 'Copy',
                      style: TextStyle(
                        fontSize: 12,
                        color: _copied ? Colors.green : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build code area with syntax highlighting
  Widget _buildCodeArea() {
    final lines = widget.code.split('\n');

    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line Numbers
            if (widget.showLineNumbers) _buildLineNumbers(lines.length),

            // Code Content
            Container(
              padding: const EdgeInsets.all(16),
              child: HighlightView(
                widget.code,
                language: _normalizeLanguage(),
                theme: widget.isDarkMode ? vs2015Theme : githubTheme,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build line numbers column
  Widget _buildLineNumbers(int lineCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF252526)
            : const Color(0xFFF9FAFB),
        border: Border(
          right: BorderSide(
            color: widget.isDarkMode
                ? const Color(0xFF3E3E42)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(lineCount, (index) {
          return Container(
            height: 21, // Match line height
            alignment: Alignment.centerRight,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Copy code to clipboard
  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  /// Get language-specific color
  Color _getLanguageColor() {
    switch (widget.language.toLowerCase()) {
      case 'python':
        return const Color(0xFF3776AB);
      case 'javascript':
      case 'js':
        return const Color(0xFFF7DF1E);
      case 'java':
        return const Color(0xFFE76F00);
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'cpp':
      case 'c++':
        return const Color(0xFF00599C);
      case 'html':
        return const Color(0xFFE34F26);
      case 'css':
        return const Color(0xFF1572B6);
      case 'sql':
        return const Color(0xFF336791);
      case 'rust':
        return const Color(0xFFCE422B);
      case 'go':
        return const Color(0xFF00ADD8);
      default:
        return const Color(0xFF6366F1);
    }
  }

  /// Get language-specific icon
  IconData _getLanguageIcon() {
    switch (widget.language.toLowerCase()) {
      case 'python':
        return Icons.code_rounded;
      case 'javascript':
      case 'js':
        return Icons.javascript_rounded;
      case 'dart':
        return Icons.flutter_dash_rounded;
      case 'java':
        return Icons.coffee_rounded;
      case 'html':
        return Icons.web_rounded;
      case 'css':
        return Icons.style_rounded;
      case 'sql':
        return Icons.storage_rounded;
      default:
        return Icons.code_rounded;
    }
  }

  /// Get formatted language name
  String _getLanguageName() {
    switch (widget.language.toLowerCase()) {
      case 'python':
        return 'Python';
      case 'javascript':
      case 'js':
        return 'JavaScript';
      case 'dart':
        return 'Dart';
      case 'java':
        return 'Java';
      case 'cpp':
      case 'c++':
        return 'C++';
      case 'html':
        return 'HTML';
      case 'css':
        return 'CSS';
      case 'sql':
        return 'SQL';
      case 'rust':
        return 'Rust';
      case 'go':
        return 'Go';
      default:
        return widget.language.toUpperCase();
    }
  }

  /// Normalize language name for highlighter
  String _normalizeLanguage() {
    switch (widget.language.toLowerCase()) {
      case 'js':
        return 'javascript';
      case 'c++':
        return 'cpp';
      default:
        return widget.language.toLowerCase();
    }
  }
}

/// 🎯 CODE EXPLANATION CARD
class CodeExplanationCard extends StatelessWidget {
  final String title;
  final String explanation;
  final List<int> highlightLines;
  final Color color;

  const CodeExplanationCard({
    Key? key,
    required this.title,
    required this.explanation,
    this.highlightLines = const [],
    this.color = const Color(0xFF6366F1),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          if (highlightLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: highlightLines.map((line) {
                return Chip(
                  label: Text('Line $line'),
                  backgroundColor: color.withOpacity(0.1),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
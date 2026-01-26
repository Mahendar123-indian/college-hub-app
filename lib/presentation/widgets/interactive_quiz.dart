import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 📝 QUIZ QUESTION DATA MODEL
class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOption> options;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.explanation,
  });
}

class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
}

/// 🎮 INTERACTIVE QUIZ WIDGET
class InteractiveQuizWidget extends StatefulWidget {
  final QuizQuestion question;
  final VoidCallback? onCorrect;
  final VoidCallback? onIncorrect;

  const InteractiveQuizWidget({
    Key? key,
    required this.question,
    this.onCorrect,
    this.onIncorrect,
  }) : super(key: key);

  @override
  State<InteractiveQuizWidget> createState() => _InteractiveQuizWidgetState();
}

class _InteractiveQuizWidgetState extends State<InteractiveQuizWidget> {
  String? _selectedOptionId;
  bool _hasAnswered = false;
  bool? _isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildQuestion(),
          _buildOptions(),
          if (_hasAnswered) _buildResult(),
          if (!_hasAnswered) _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Quick Quiz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (_hasAnswered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isCorrect! ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCorrect!
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isCorrect! ? 'Correct!' : 'Try Again',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        widget.question.question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: widget.question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = _selectedOptionId == option.id;
          final showResult = _hasAnswered;

          Color? borderColor;
          Color? backgroundColor;

          if (showResult) {
            if (option.isCorrect) {
              borderColor = Colors.green;
              backgroundColor = Colors.green.withOpacity(0.1);
            } else if (isSelected && !option.isCorrect) {
              borderColor = Colors.red;
              backgroundColor = Colors.red.withOpacity(0.1);
            }
          } else if (isSelected) {
            borderColor = const Color(0xFF6366F1);
            backgroundColor = const Color(0xFF6366F1).withOpacity(0.1);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasAnswered
                    ? null
                    : () {
                  setState(() => _selectedOptionId = option.id);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor ?? Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: showResult && option.isCorrect
                              ? Colors.green
                              : (showResult && isSelected && !option.isCorrect
                              ? Colors.red
                              : (isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.grey[300])),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ||
                                  (showResult && option.isCorrect)
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (showResult && option.isCorrect)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 24,
                        )
                      else if (showResult && isSelected && !option.isCorrect)
                        const Icon(
                          Icons.cancel_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ).animate(target: showResult && option.isCorrect ? 1 : 0).shake(
                  duration: 500.ms),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isCorrect!
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCorrect!
                ? Colors.green.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCorrect!
                      ? Icons.lightbulb_rounded
                      : Icons.info_rounded,
                  color: _isCorrect! ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect! ? 'Explanation' : 'Keep Learning',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect! ? Colors.green[900] : Colors.orange[900],
                  ),
                ),
              ],
            ),
            if (widget.question.explanation != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.question.explanation!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedOptionId != null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSubmit ? _submitAnswer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: canSubmit ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[500],
          ),
          child: const Text(
            'Submit Answer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _submitAnswer() {
    final selectedOption = widget.question.options
        .firstWhere((opt) => opt.id == _selectedOptionId);

    setState(() {
      _hasAnswered = true;
      _isCorrect = selectedOption.isCorrect;
    });

    if (_isCorrect!) {
      widget.onCorrect?.call();
    } else {
      widget.onIncorrect?.call();
    }
  }
}

/// 📊 QUIZ PROGRESS INDICATOR
class QuizProgressIndicator extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final int correctAnswers;

  const QuizProgressIndicator({
    Key? key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.correctAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accuracy = currentQuestion > 0
        ? (correctAnswers / currentQuestion * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $currentQuestion of $totalQuestions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$accuracy% accuracy',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: currentQuestion / totalQuestions,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
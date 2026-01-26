import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// 🎯 PRACTICE PROBLEM DATA MODEL
class PracticeProblem {
  final String id;
  final String problem;
  final String difficulty;
  final List<String> hints;
  final String answer;
  final List<String> steps;
  final String? explanation;

  PracticeProblem({
    required this.id,
    required this.problem,
    required this.difficulty,
    required this.hints,
    required this.answer,
    required this.steps,
    this.explanation,
  });
}

/// 🎮 INTERACTIVE PRACTICE PROBLEM WIDGET
class PracticeProblemWidget extends StatefulWidget {
  final PracticeProblem problem;
  final VoidCallback? onComplete;

  const PracticeProblemWidget({
    Key? key,
    required this.problem,
    this.onComplete,
  }) : super(key: key);

  @override
  State<PracticeProblemWidget> createState() => _PracticeProblemWidgetState();
}

class _PracticeProblemWidgetState extends State<PracticeProblemWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  int _currentHintLevel = 0;
  int _attempts = 0;
  bool _showSolution = false;
  bool _isCorrect = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getDifficultyColor().withOpacity(0.1),
            _getDifficultyColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getDifficultyColor().withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getDifficultyColor().withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildProblemStatement(),
              if (_currentHintLevel > 0) _buildHints(),
              if (!_showSolution) _buildAnswerInput(),
              if (_feedback != null) _buildFeedback(),
              if (_showSolution) _buildSolution(),
              _buildActions(),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getDifficultyColor().withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getDifficultyColor(),
                  _getDifficultyColor().withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getDifficultyColor().withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getDifficultyIcon(),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice Problem',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.problem.difficulty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getDifficultyColor(),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_attempts > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.try_sms_star_rounded,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '$_attempts ${_attempts == 1 ? 'attempt' : 'attempts'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProblemStatement() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 Problem',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getDifficultyColor(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              widget.problem.problem,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHints() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Hints',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _currentHintLevel,
                (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.problem.hints[index],
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✍️ Your Answer',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getDifficultyColor(),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset = _shakeController.value *
                  10 *
                  ((_shakeController.value * 4).floor().isEven ? 1 : -1);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: TextField(
              controller: _answerController,
              enabled: !_isCorrect,
              decoration: InputDecoration(
                hintText: 'Enter your answer...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getDifficultyColor(),
                    width: 2,
                  ),
                ),
                suffixIcon: _isCorrect
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isCorrect
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCorrect
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isCorrect ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _isCorrect ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _feedback!,
                style: TextStyle(
                  fontSize: 14,
                  color: _isCorrect ? Colors.green[900] : Colors.red[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolution() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ Solution',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer: ${widget.problem.answer}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Steps:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.problem.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (widget.problem.explanation != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Explanation:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.problem.explanation!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (!_isCorrect && !_showSolution) ...[
            if (_currentHintLevel < widget.problem.hints.length)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _currentHintLevel++);
                  },
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  label: Text(
                      'Hint ${_currentHintLevel + 1}/${widget.problem.hints.length}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber[700],
                    side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _checkAnswer,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Check Answer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getDifficultyColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
              ),
            ),
          ],
          if (_attempts >= 3 && !_isCorrect && !_showSolution) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _showSolution = true);
                },
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Show Solution'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (_isCorrect)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onComplete,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Next Problem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _checkAnswer() {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = widget.problem.answer.trim().toLowerCase();

    setState(() {
      _attempts++;
      _isCorrect = userAnswer == correctAnswer;

      if (_isCorrect) {
        _feedback = '🎉 Perfect! Your answer is correct!';
        _confettiController.play();
        widget.onComplete?.call();
      } else {
        _feedback = '❌ Not quite right. Try again!';
        _shakeController.forward().then((_) => _shakeController.reset());
      }
    });
  }

  Color _getDifficultyColor() {
    switch (widget.problem.difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getDifficultyIcon() {
    switch (widget.problem.difficulty.toLowerCase()) {
      case 'beginner':
        return Icons.emoji_events_rounded;
      case 'intermediate':
        return Icons.trending_up_rounded;
      case 'advanced':
        return Icons.military_tech_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }
}
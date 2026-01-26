import 'package:flutter/material.dart';

enum StudyMode {
  beginner,
  exam,
  interview,
  quickRevision,
}

extension StudyModeExtension on StudyMode {
  String get name {
    switch (this) {
      case StudyMode.beginner:
        return 'Beginner Mode';
      case StudyMode.exam:
        return 'Exam Mode';
      case StudyMode.interview:
        return 'Interview Mode';
      case StudyMode.quickRevision:
        return 'Quick Revision';
    }
  }

  String get description {
    switch (this) {
      case StudyMode.beginner:
        return 'Simple explanations with real-world examples';
      case StudyMode.exam:
        return 'Concise, marks-oriented answers';
      case StudyMode.interview:
        return 'In-depth with practical applications';
      case StudyMode.quickRevision:
        return 'Bullet points for fast revision';
    }
  }

  IconData get icon {
    switch (this) {
      case StudyMode.beginner:
        return Icons.school_rounded;
      case StudyMode.exam:
        return Icons.quiz_rounded;
      case StudyMode.interview:
        return Icons.work_rounded;
      case StudyMode.quickRevision:
        return Icons.flash_on_rounded;
    }
  }

  Color get color {
    switch (this) {
      case StudyMode.beginner:
        return const Color(0xFF4CAF50); // Green
      case StudyMode.exam:
        return const Color(0xFFFF9800); // Orange
      case StudyMode.interview:
        return const Color(0xFF2196F3); // Blue
      case StudyMode.quickRevision:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  List<String> get features {
    switch (this) {
      case StudyMode.beginner:
        return [
          'Simple Language',
          'Step-by-step',
          'Real Examples',
          'Visual Aids',
        ];
      case StudyMode.exam:
        return [
          'Marks Oriented',
          'Key Points',
          'Formulas',
          'Past Patterns',
        ];
      case StudyMode.interview:
        return [
          'Practical Apps',
          'In-depth',
          'Industry Use',
          'Follow-ups',
        ];
      case StudyMode.quickRevision:
        return [
          'Bullet Points',
          'Quick Facts',
          'Must-Remember',
          'Time-Saving',
        ];
    }
  }

  String get prompt {
    switch (this) {
      case StudyMode.beginner:
        return '''You are explaining to a student who is learning this topic for the first time.
- Use simple, easy-to-understand language
- Explain concepts from basics
- Use real-world analogies and examples
- Break down complex topics into simple parts
- Avoid technical jargon unless necessary
- Be patient and encouraging''';

      case StudyMode.exam:
        return '''You are helping a student prepare for exams.
- Provide concise, marks-oriented answers
- Focus on exam-relevant information
- Highlight important definitions and formulas
- Structure answers for maximum marks
- Include previous year question patterns
- Use bullet points for clarity''';

      case StudyMode.interview:
        return '''You are preparing a student for job interviews.
- Focus on practical applications and real-world usage
- Explain "how" and "why" in detail
- Provide industry examples and use cases
- Discuss advantages and disadvantages
- Prepare for common follow-up questions
- Include best practices''';

      case StudyMode.quickRevision:
        return '''You are helping a student revise quickly before exams.
- Provide only the most important information
- Use bullet points and short explanations
- Focus on must-remember concepts
- Include key formulas and definitions
- Skip lengthy explanations
- Be extremely concise''';
    }
  }
}
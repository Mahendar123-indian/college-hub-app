import 'dart:io';

class AIChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<File> attachedFiles;
  final MessageType type;
  final String? analysisType;

  AIChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachedFiles = const [],
    this.type = MessageType.text,
    this.analysisType,
  });

  // Factory constructors
  factory AIChatMessage.user(
      String text, {
        List<File>? files,
      }) {
    return AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      attachedFiles: files ?? [],
      type: files != null && files.isNotEmpty
          ? MessageType.withAttachment
          : MessageType.text,
    );
  }

  factory AIChatMessage.ai(String text, {String? analysisType}) {
    return AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
      analysisType: analysisType,
    );
  }

  factory AIChatMessage.loading() {
    return AIChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Thinking...',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.loading,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'type': type.toString(),
    'analysisType': analysisType,
    // Note: Files are not serialized for persistence
  };

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
            (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      analysisType: json['analysisType'],
    );
  }

  // Copy with
  AIChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<File>? attachedFiles,
    MessageType? type,
    String? analysisType,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      type: type ?? this.type,
      analysisType: analysisType ?? this.analysisType,
    );
  }
}

enum MessageType {
  text,
  withAttachment,
  loading,
  error,
}

// Chat Session Model
class AIChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AIChatMessage> messages;
  final String? subject;
  final String? studyMode;

  AIChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.subject,
    this.studyMode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'subject': subject,
    'studyMode': studyMode,
  };

  factory AIChatSession.fromJson(Map<String, dynamic> json) {
    return AIChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List)
          .map((m) => AIChatMessage.fromJson(m))
          .toList(),
      subject: json['subject'],
      studyMode: json['studyMode'],
    );
  }

  AIChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AIChatMessage>? messages,
    String? subject,
    String? studyMode,
  }) {
    return AIChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      subject: subject ?? this.subject,
      studyMode: studyMode ?? this.studyMode,
    );
  }
}
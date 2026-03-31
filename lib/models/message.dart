import 'package:uuid/uuid.dart';

enum MessageType { user, agent, system, loading, error }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool? isToolCall;
  final String? toolName;

  Message({
    String? id,
    required this.content,
    required this.type,
    DateTime? timestamp,
    this.isToolCall,
    this.toolName,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}

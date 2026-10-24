import '../entities/ai_message.dart';

abstract interface class AiHelpRepository {
  bool get isConfigured;

  Future<String> ask({
    required String question,
    required List<AiMessage> history,
  });
}

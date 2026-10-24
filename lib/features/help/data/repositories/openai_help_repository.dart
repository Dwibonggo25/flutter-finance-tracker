import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/ai_message.dart';
import '../../domain/repositories/ai_help_repository.dart';

class OpenAiHelpRepository implements AiHelpRepository {
  static const _endpoint = String.fromEnvironment('AI_HELP_URL');

  final Dio _dio;
  final FirebaseAuth _auth;

  OpenAiHelpRepository({Dio? dio, FirebaseAuth? auth})
    : _dio = dio ?? Dio(),
      _auth = auth ?? FirebaseAuth.instance;

  @override
  bool get isConfigured =>
      _endpoint.isNotEmpty && !_endpoint.startsWith('YOUR_');

  @override
  Future<String> ask({
    required String question,
    required List<AiMessage> history,
  }) async {
    if (!isConfigured) throw StateError('AI_HELP_URL is not configured.');
    final user = _auth.currentUser;
    if (user == null) throw StateError('A signed-in user is required.');
    final token = await user.getIdToken();
    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      data: {
        'question': question.trim(),
        'history': history
            .take(10)
            .map(
              (message) => {
                'role': message.isUser ? 'user' : 'assistant',
                'content': message.text,
              },
            )
            .toList(growable: false),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final answer = response.data?['answer'] as String?;
    if (answer == null || answer.trim().isEmpty) {
      throw StateError('The AI response was empty.');
    }
    return answer.trim();
  }
}

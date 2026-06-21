import 'api_service.dart';

class AiChatService {
  Future<String> sendMessage(String message) async {
    final response = await ApiService.post(
      '/ai/chat',
      body: {'message': message},
    );
    return response['reply'] as String? ?? '';
  }
}

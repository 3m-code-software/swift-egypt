import 'api_service.dart';

class AiChatService {
  final ApiService _api = ApiService();

  Future<String> sendMessage(String message) async {
    final response =
        await _api.post('/ai/chat', body: {'message': message});
    return response['reply'] as String;
  }
}

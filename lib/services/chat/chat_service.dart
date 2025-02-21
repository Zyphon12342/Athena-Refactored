import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _serverUrl = 'https://just-mainly-monster.ngrok-free.app';
  http.Client? client;

  Future<dynamic> sendString(
      String message, List<Map<String, String>> history) async {
    final url = Uri.parse(_serverUrl);
    client = http.Client();
    try {
      final response = await client!
          .post(
            url,
            headers: {'Content-Type': 'text/plain'},
            body: history.toString(),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Request timed out'),
          );
      client?.close();
      client = null;
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  void cancelRequest() {
    client?.close();
    client = null;
  }
}

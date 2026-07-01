import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

const _baseUrl = 'https://integrate.api.nvidia.com/v1';

const kModels = {
  'super': 'nvidia/nemotron-3-super-120b-a12b',
  'ultra': 'nvidia/nemotron-3-ultra-550b-a55b',
  'nano':  'nvidia/nemotron-3-nano-30b-a3b',
};

class NimService {
  String apiKey;
  String model;
  bool   thinking;
  int    budget;

  NimService({
    required this.apiKey,
    this.model    = 'nvidia/nemotron-3-super-120b-a12b',
    this.thinking = true,
    this.budget   = 8192,
  });

  static const _systemPrompt = '''
You are Nemotron Code, an expert AI coding assistant running on Android.
Help the user write, debug, explain, and improve code across all languages.
Format code in markdown fences with the language specified.
Be concise, accurate, and practical.
''';

  /// Streams {type: 'think'|'answer', text: '...'} maps
  Stream<Map<String, String>> streamChat({
    required List<Message> history,
    required String        userMessage,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/completions'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type':  'application/json',
        'Accept':        'text/event-stream',
      });

      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': _systemPrompt},
        ...history.map((m) => m.toApiMap()),
        {'role': 'user', 'content': userMessage},
      ];

      final body = <String, dynamic>{
        'model':       model,
        'messages':    messages,
        'stream':      true,
        'max_tokens':  4096,
        'temperature': 0.3,
      };
      if (thinking) {
        body['chat_template_kwargs'] = {'enable_thinking': true};
        body['reasoning_budget']     = budget;
      }

      request.body = jsonEncode(body);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final err = await response.stream.bytesToString();
        yield {'type': 'error', 'text': 'API error ${response.statusCode}: $err'};
        return;
      }

      String buffer = '';
      await for (final chunk
          in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete line

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          try {
            final json   = jsonDecode(data) as Map<String, dynamic>;
            final delta  = (json['choices'] as List)[0]['delta']
                as Map<String, dynamic>;
            final reason = delta['reasoning_content'];
            final content= delta['content'];
            if (reason != null && reason is String && reason.isNotEmpty) {
              yield {'type': 'think', 'text': reason};
            }
            if (content != null && content is String && content.isNotEmpty) {
              yield {'type': 'answer', 'text': content};
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      yield {'type': 'error', 'text': e.toString()};
    } finally {
      client.close();
    }
  }

  Future<bool> testConnection() async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({
          'model':      model,
          'messages':   [{'role': 'user', 'content': 'hi'}],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

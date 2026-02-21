import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zone.dart';

class AiService {
  // Replace with your actual key — store in --dart-define for security
  static const _apiKey = String.fromEnvironment('CLAUDE_API_KEY', defaultValue: 'YOUR_KEY_HERE');
  static const _cacheKey = 'last_ai_response';

  // HACKATHON FALLBACK: if API fails or no internet, return this
  static const _hardcodedFallback = '''Рекомендую пастбище Ат-Башы. Состояние: хорошее (78/100), хватит на 18 дней для стада до 150 овец. Избегайте Жумгал и Ак-Талаа — они под официальным запретом.''';

  Future<String> getRecommendation(String userMessage, List<Zone> zones) async {
    final prompt = _buildPrompt(userMessage, zones);

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 300,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;

        // Cache for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, text);

        return text;
      } else {
        return _getCachedOrFallback();
      }
    } catch (_) {
      return _getCachedOrFallback();
    }
  }

  Future<String> _getCachedOrFallback() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey) ?? _hardcodedFallback;
  }

  String _buildPrompt(String userMessage, List<Zone> zones) {
    final zoneList = zones
        .map((z) =>
            '- ${z.name} (${z.nameEn}): здоровье ${z.healthScore}/100, '
            'макс стадо ${z.maxHerd} овец, статус: ${z.status}, '
            'безопасных дней: ${z.safeDays}')
        .join('\n');

    return '''
Ты — помощник пастухов в Кыргызстане (Нарынская область).
Отвечай ТОЛЬКО на русском языке.
Будь КРАТКИМ — максимум 3 предложения.
Не используй markdown, только обычный текст.

Сообщение пастуха: "$userMessage"

Доступные пастбища:
$zoneList

Дай конкретный совет: куда идти, на сколько дней хватит, одно предупреждение если нужно.
''';
  }
}

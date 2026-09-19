import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../logic/distractor_validator.dart';
import 'ai_settings.dart';

class DistractorApiException implements Exception {
  DistractorApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class DistractorApi {
  DistractorApi({AiSettings? settings, http.Client? client})
      : _settings = settings ?? AiSettings(),
        _client = client ?? http.Client();

  final AiSettings _settings;
  final http.Client _client;

  Future<List<String>> generate({
    required String question,
    required String correctAnswer,
    List<String> existingWrongAnswers = const [],
  }) async {
    final url = await _settings.backendUrl();
    final token = await _settings.backendToken();
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$url/v1/distractors'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'question': question,
              'correctAnswer': correctAnswer,
              if (existingWrongAnswers.isNotEmpty)
                'existingWrongAnswers': existingWrongAnswers,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } on SocketException {
      throw DistractorApiException(
        'Keine Verbindung zum KI-Backend. Lernkarten bleiben nutzbar.',
      );
    } on HttpException {
      throw DistractorApiException('Das KI-Backend ist nicht erreichbar.');
    } on FormatException {
      throw DistractorApiException('Ungültige Backend-URL.');
    }

    if (response.statusCode == 429) {
      throw DistractorApiException(
        'Das Anfragelimit ist erreicht. Bitte später erneut versuchen.',
        statusCode: 429,
      );
    }
    if (response.statusCode >= 400) {
      throw DistractorApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw DistractorApiException('Ungültige KI-Antwort.');
    }
    final raw = decoded['wrongAnswers'];
    if (raw is! List) {
      throw DistractorApiException('KI-Antwort ohne drei Falschantworten.');
    }
    final values = raw.map((e) => '$e').toList();
    final valid = DistractorValidator.normalizeThree(values, correctAnswer);
    if (valid == null) {
      throw DistractorApiException(
        DistractorValidator.issueFor(values, correctAnswer) ??
            'Die KI-Antwort ist ungültig und wurde nicht gespeichert.',
      );
    }
    return valid;
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] != null) {
        return '${decoded['detail']}';
      }
    } catch (_) {}
    if (response.statusCode >= 500) {
      return 'Das KI-Backend hat einen Fehler gemeldet.';
    }
    return 'KI-Anfrage fehlgeschlagen (${response.statusCode}).';
  }
}

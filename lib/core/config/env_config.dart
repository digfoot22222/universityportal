import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get geminiApiKey =>
      dotenv.maybeGet('GEMINI_API_KEY') ?? 'AQ.Ab8RN6KIQmRoFyDZYjS7tmEyr9zUzsNMuoR1dTxyjjhruOtbS';

  static String get geminiModelEndpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent';

  static String get remitaMerchantId =>
      dotenv.maybeGet('REMITA_MERCHANT_ID') ?? '2547916';

  static String get remitaApiKey =>
      dotenv.maybeGet('REMITA_API_KEY') ?? '1946';

  static bool get hasLiveGeminiKey =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'your_gemini_api_key_here';
}
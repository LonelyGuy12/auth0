import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get auth0Domain => dotenv.env['AUTH0_DOMAIN'] ?? '';
  static String get auth0ClientId => dotenv.env['AUTH0_CLIENT_ID'] ?? '';
  static String get auth0ClientSecret => dotenv.env['AUTH0_CLIENT_SECRET'] ?? '';
  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get defaultAiModel =>
      dotenv.env['AI_MODEL'] ?? 'openrouter/auto';
}

# AI Agent Desktop

A Windows desktop AI agent application built with Flutter for the **Authorized to Act** hackathon. Uses **Auth0 Token Vault** for secure OAuth token management and **OpenRouter** for AI chat capabilities.

![Screenshot Placeholder](https://via.placeholder.com/900x550?text=AI+Agent+Desktop+Screenshot)

## Features

- **Auth0 Token Vault Integration** — Secure OAuth token storage, refresh, and consent delegation
- **Multi-Service OAuth** — Connect Google Calendar, GitHub, and Spotify via Auth0
- **AI Chat Agent** — Powered by OpenRouter with tool/function calling
- **Model Switching** — Choose from free and paid AI models (Llama, Mistral, GPT-4o, Claude)
- **Calendar Management** — View and create Google Calendar events via AI
- **GitHub Integration** — Browse repos and view profile information
- **Modern Dark UI** — Sleek developer-tool aesthetic with animations

## Tech Stack

- Flutter (Windows desktop)
- Dart
- Auth0 Token Vault (OAuth token management)
- OpenRouter API (OpenAI-compatible chat completions)
- Provider (state management)
- flutter_secure_storage, flutter_markdown, google_fonts, animate_do

## Prerequisites

- Flutter SDK (3.11+)
- Windows development environment
- Auth0 account with Token Vault enabled
- OpenRouter API key

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/LonelyGuy12/auth0.git
cd auth0
```

### 2. Configure environment variables

Edit `assets/.env` with your credentials:

```
AUTH0_DOMAIN=your-tenant.auth0.com
AUTH0_CLIENT_ID=your_client_id
AUTH0_CLIENT_SECRET=your_client_secret
OPENROUTER_API_KEY=sk-or-v1-your_key
AI_MODEL=meta-llama/llama-3.1-8b-instruct:free
```

### 3. Auth0 Dashboard Setup

1. Create a new **Regular Web Application** in Auth0
2. Under **Connections**, enable Google OAuth2, GitHub, and Spotify social connections
3. Add `http://localhost:*/callback` to **Allowed Callback URLs**
4. Note your Domain, Client ID, and Client Secret

### 4. Install dependencies and run

```bash
flutter pub get
flutter run -d windows
```

### 5. Build Windows executable

```bash
flutter build windows
```

The built `.exe` will be in `build/windows/x64/runner/Release/`.

## Architecture

```
lib/
├── main.dart                    # App entry point, dotenv loading, providers
├── app.dart                     # MaterialApp with dark theme
├── config/constants.dart        # Environment variable access
├── models/
│   ├── message.dart             # Chat message model
│   └── service_connection.dart  # OAuth service connection model
├── services/
│   ├── token_vault_service.dart # Core Auth0 Token Vault integration
│   ├── auth_service.dart        # OAuth flow (browser + local callback server)
│   ├── openrouter_service.dart  # OpenRouter API with tool calling
│   ├── ai_agent_service.dart    # Orchestrates AI + external services
│   ├── google_calendar_service.dart
│   └── github_service.dart
├── providers/
│   ├── auth_provider.dart       # Service connection state
│   └── chat_provider.dart       # Chat messages & AI interaction state
├── screens/
│   └── home_screen.dart
└── widgets/
    ├── sidebar.dart
    ├── connection_tile.dart
    ├── chat_area.dart
    ├── message_bubble.dart
    ├── chat_input.dart
    ├── model_selector.dart
    └── typing_indicator.dart
```

## How Token Vault Is Used

The **Auth0 Token Vault** (`token_vault_service.dart`) is the core of this application:

1. **OAuth Initiation** — Builds Auth0 `/authorize` URLs with proper scopes and connection parameters
2. **Token Exchange** — Exchanges authorization codes for access/refresh tokens via Auth0's `/oauth/token` endpoint
3. **Secure Storage** — Stores tokens encrypted via `flutter_secure_storage`
4. **Automatic Refresh** — Detects expired tokens and transparently refreshes them using stored refresh tokens
5. **Consent Delegation** — The AI agent uses stored tokens to act on the user's behalf across connected services

The desktop OAuth flow uses a local HTTP callback server since Windows desktop apps cannot receive deep links. The flow: browser → Auth0 login → redirect to `http://localhost:{random_port}/callback` → local server catches it → token exchange.

## Credits

- [Auth0](https://auth0.com/) — Token Vault & OAuth infrastructure
- [OpenRouter](https://openrouter.ai/) — AI model access
- **Authorized to Act Hackathon**

## License

MIT

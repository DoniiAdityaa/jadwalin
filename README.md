# Jadwalin 📅✨

> Modern AI-powered student schedule manager built with Flutter and the **Warm Mocha** design system.

---

## Features

- **Modern Warm Mocha UI**: Roasted mocha palette, Plus Jakarta Sans typography, sleek card elevations.
- **Interactive Timeline**: 24-hour day grid with drag-to-reschedule, duration resizing, live "now" indicator, and quick event creation.
- **Collapsible Day Calendar**: Horizontal month and date strips with collapse-on-scroll header and day agenda dots.
- **AI Chat Assistant**: Integrated with Dattio (`deepseek-v4-flash`), dynamic typing animation, floating pill input bar.
- **ChatGPT-Style Sliding Drawer**: Push transition with swipe gestures, user profile, and swipe-to-delete chat history.
- **Local Persistence (SQLite)**: Offline-first with `sqflite` (schedules, chat sessions, chat messages) and automatic sample seeding on first run.

---

## Branching Strategy

We follow the standard **Git Flow** pattern:

```text
main (production-ready)
 │
 └── develop (active development)
      │
      ├── feature/<name>   (new feature, branched from develop)
      ├── fix/<name>       (bug fix, branched from develop)
      └── hotfix/<name>    (critical fix, branched from main)
```

- `main`: stable, deployable releases only.
- `develop`: daily integration branch. All PRs target here.
- `feature/*`: branch per feature, merge back to `develop` via PR.

See [CONTRIBUTING.md](CONTRIBUTING.md) for full commit message guidelines and branch naming conventions.

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.8.1` (Dart `^3.8.1`)
- Xcode (for iOS/macOS) or Android Studio (for Android)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DoniiAdityaa/jadwalin.git
   cd jadwalin
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file at the root of the project:
   ```env
   BASE_URL=
   DATTIO_API_KEY=your_dattio_api_key_here
   DATTIO_BASE_URL=https://bandelbanget.xyz/v1
   ```

4. **Generate environment bindings:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   > ⚠️ **Note**: `lib/config/env/env.g.dart` is ignored by Git to protect secrets. You must run this command after cloning or updating `.env`.

5. **Run the app:**
   ```bash
   flutter run
   ```

---

## Project Structure

```text
lib/
├── config/             # Service locator (GetIt), envied config, user prefs
├── data/
│   ├── local/          # DatabaseHelper, ScheduleDao, ChatDao, data models
│   └── service/        # AiChatService (Dattio / OpenAI completions)
├── feature/
│   ├── calendar/       # Day timeline, collapsible calendar detail screen
│   ├── chat/           # Chatbot screen with real-time AI & SQLite history
│   └── home/           # Main dashboard, highlight card, mini calendar
├── ui/
│   ├── shared_widget/  # Sidebar, timeline, bottom sheets, indicators
│   ├── color.dart      # Warm Mocha color tokens
│   ├── typography.dart # Plus Jakarta Sans font styles
│   └── theme.dart      # Global app theme
└── main_navigation.dart# Push-style sliding sidebar & bottom nav coordinator
```

---

## Conventional Commits

All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
<type>(<scope>): <short description>
```

Types: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`.
Local git hook enforces this automatically on every `git commit`.

---

## License

Private / Educational project.

# Briefed — Daily News Quiz App

> Stay Briefed. Stay Sharp.

A daily 5-question news quiz app powered by real headlines and AI-generated questions.

---

## ⚡ Quick Setup (5 steps)

### 1. Install Flutter
Make sure Flutter is installed: https://flutter.dev/docs/get-started/install

### 2. Unzip and open
```bash
cd briefed
```

### 3. Add your API keys
Pass API keys at run/build time with `--dart-define`:

```bash
flutter run \
  --dart-define=NEWSDATA_API_KEY=your_newsdata_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

Groq is tried first if you provide it:

```bash
flutter run \
  --dart-define=NEWSDATA_API_KEY=your_newsdata_key \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

Get your keys from:
- **Groq**: https://console.groq.com → API Keys
- **Gemini**: https://aistudio.google.com → API Keys → Create API Key
- **NewsData.io**: https://newsdata.io → Dashboard → API Key

### 4. Install dependencies
```bash
flutter pub get
```

### 5. Run
```bash
flutter run
```

---

## 📱 Features

| Feature | Description |
|---|---|
| Daily Quiz | 5 AI-generated questions from real news headlines |
| Google News Feed | Scrollable news briefing by category |
| Streaks | Daily streak tracking with calendar |
| Knowledge Score | Cumulative score with global percentile |
| Results | Confetti celebration with shareable result card |
| Hot Take | Daily yes/no poll with real-time results |
| Dark Mode | Full light/dark/system theme support |
| Offline Fallback | Mock questions if API is unavailable |

---

## 🗂 Project Structure

```
lib/
  main.dart                  ← App entry point + routes
  core/
    constants.dart           ← App config, dart-define keys, and mock data
    theme.dart               ← Full light/dark theme system
  models/
    models.dart              ← Question, QuizResult, NewsArticle, UserData
  services/
    storage_service.dart     ← SharedPreferences wrapper
    news_service.dart        ← NewsData.io API integration
    gemini_service.dart      ← Gemini question generation
  providers/
    providers.dart           ← All Riverpod state providers
  screens/
    screens.dart             ← All 10 screens
  widgets/
    widgets.dart             ← Shared reusable widgets
```

---

## 🎨 Design

- **Light theme default** — warm off-white (#F5F5F1) base
- **Dark mode** — deep black (#0D0D0D) base
- **Accent** — #FF4500 (energetic orange-red)
- **Font** — Poppins (900 weight headlines)
- **Category colours** — Blue (World), Teal (Tech), Orange (Business), Purple (Science), Pink (Sports), Gold (Entertainment)

---

## 🔑 API Details

### NewsData.io
- Endpoint: `https://newsdata.io/api/1/news`
- Default country: `au` (Australia)
- Categories pulled from user's onboarding selection
- Falls back to 6 mock articles if API fails

### Gemini 1.5 Flash
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`
- Questions cached per day — only 1 API call per day
- Falls back to 5 mock questions if API fails

---

## 🚀 Screens

1. **Splash** — animated logo
2. **Onboarding** — category selection → notification time → ready
3. **Home** — quiz hero card + streak + score + did you know
4. **Briefing** — Google News-style feed with sections by category
5. **Explore** — leaderboard + recent quizzes + stats
6. **Quiz** — 5 questions with countdown timer
7. **Results** — confetti + score + share card
8. **Hot Take** — daily yes/no poll
9. **Profile** — streak calendar + badges + history
10. **Settings** — theme toggle + categories + notifications

---

## 📦 Dependencies

```yaml
flutter_riverpod: ^2.5.1    # State management
go_router: ^13.2.0          # Navigation (via named routes)
http: ^1.2.1                # API calls
shared_preferences: ^2.2.3  # Local storage
google_fonts: ^6.2.1        # Poppins font
share_plus: ^9.0.0          # Share result cards
screenshot: ^2.3.0          # Capture share card as image
confetti: ^0.7.0            # Results celebration
shimmer: ^3.0.0             # Loading placeholders
intl: ^0.19.0               # Date formatting
url_launcher: ^6.3.0        # Open article links
path_provider: ^2.1.3       # File paths
```

---

## ⚠️ Important Notes

1. **Keep your API keys private** — never commit them to Git
2. Add `lib/core/constants.dart` to `.gitignore` or use environment variables before publishing
3. For Play Store release, enable ProGuard/R8 and add network security config
4. NewsData.io free tier: 200 requests/day — sufficient for development
5. Groq is attempted first for quiz generation when configured; Gemini is the fallback
6. Questions are cached daily so API usage is minimal

---

Built with Flutter · Powered by Gemini + NewsData.io

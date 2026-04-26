# Briefed Build Plan Summary

Original source: `Briefed_Complete_Build_Plan.docx`

## Product

Briefed is a daily 5-question news quiz app. It uses real news, personalized by region and interests, then turns it into a habit loop with streaks, scores, ranks, and share cards.

Tagline: **Stay Briefed. Stay Sharp.**

Primary launch target: Android first, Flutter Web alongside or shortly after, iOS later.

## Current Repo Status

Done:
- Flutter Android scaffold works.
- API keys are passed locally through `api_keys.json`.
- NewsData, Groq, and Gemini service wiring exists.
- Firebase Android config is installed for `briefed-app-76f01`.
- Android package is `com.binaygautam.briefed`.
- Firebase Auth is wired for email/password, Google, and guest mode.
- Signed-in quiz results sync to Firestore under user documents.

Not done yet:
- Full Firestore quiz collections and daily quiz publishing.
- Cloud Functions for scheduled AI quiz generation.
- Firebase Cloud Messaging reminders.
- Review answers screen.
- Real global ranking/percentile from Firestore scores.
- Pro features, streak freeze, archive, analytics, wrapped cards.
- Web setup and Firebase Hosting.

## Core Free Features

- One daily 5-question quiz.
- Regional news plus selected interest categories.
- 15-second timer per question.
- Instant correct/wrong feedback.
- Story summary after each answer.
- Daily streak tracking.
- Cumulative Knowledge Score.
- Global percentile rank.
- Shareable result card.
- Hot Take daily poll.
- Did You Know fact card.
- Daily reminder notification.
- Guest mode with local-only progress.

## Pro Features Later

- Unlimited quiz replay.
- Streak Freeze.
- Full AI explanations.
- Category analytics.
- Past quiz archive.
- Weekly personality card.
- Monthly wrapped.
- No ads.

## Firebase Data Model Target

Users:
- `users/{userId}`
- name, email, country, categories, notificationHour, fcmToken
- streak, longestStreak, knowledgeScore, lastPlayedDate
- badges, isPro, createdAt

Quizzes:
- `quizzes/{date}/metadata`
- `quizzes/{date}/questions/{q1..q5}`
- `quizzes/{date}/scores/{userId}`

Hot Takes:
- `hotTakes/{date}`
- question, yesVotes, noVotes
- `votes/{userId}`

## AI Pipeline Target

Daily automation:
- 6 AM: Cloud Function fetches headlines from NewsData.io.
- Send headlines to Gemini/Groq with strict JSON prompt.
- Validate exactly 5 questions.
- Deduplicate against last 30 days.
- Store quiz in Firestore.
- 7 AM: publish quiz and notify users.

Question mix:
- Q1-Q2: local or regional news.
- Q3: user's top interest category.
- Q4-Q5: harder global stories.

## Recommended Next Build Order

1. **Firestore Schema Pass**
   Move quiz completion, user stats, daily scores, and Hot Take votes into the target Firestore structure.

2. **Review Answers Screen**
   Add a post-results review route showing all 5 questions, chosen answers, correct answers, explanations, and story summaries.

3. **Real Ranking**
   Replace placeholder global rank with Firestore daily percentile based on `quizzes/{date}/scores`.

4. **Daily Quiz Source**
   Decide whether the app generates quiz questions client-side for now or reads a published quiz from Firestore. For launch-quality behavior, Firestore should be the source of truth.

5. **Cloud Functions**
   Add scheduled question generation using NewsData + Gemini/Groq, storing the result in Firestore.

6. **Notifications**
   Add Firebase Messaging, save FCM tokens, request permission during onboarding, and send daily quiz reminders.

7. **Prompt Upgrade**
   Replace the current shorter prompt with the full strict prompt from the plan and run multiple test batches.

8. **Web**
   Add Flutter Web config, responsive max-width shell, Firebase web app options, and Firebase Hosting.

## Immediate Practical Next Step

Build the Firestore-backed quiz result/ranking layer. This gives the app a real backend spine before we add scheduled generation and notifications.

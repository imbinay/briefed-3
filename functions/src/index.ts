import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import * as crypto from "crypto";

initializeApp();
const db = getFirestore();

// ── Secrets ───────────────────────────────────────────────────────────────
const CURRENTS_API_KEY = defineSecret("CURRENTS_API_KEY");
const GUARDIAN_API_KEY = defineSecret("GUARDIAN_API_KEY");
const NEWSDATA_API_KEY = defineSecret("NEWSDATA_API_KEY");
const GROQ_API_KEY = defineSecret("GROQ_API_KEY");
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");

// ── News types ────────────────────────────────────────────────────────────

type ApiSource = "currents" | "guardian" | "newsdata";

interface Article {
  id: string;
  title: string;
  summary: string;
  url: string;
  imageUrl: string | null;
  sourceName: string;
  sourceDomain: string;
  publishedAt: string;
  category: string;
  sourceQualityScore: number;
  quizabilityScore: number;
  quizabilityPassed: boolean;
  apiSource: ApiSource;
}

// ── Quiz types ────────────────────────────────────────────────────────────

// Exactly matches QuizQuestion.toJson() / fromJson() field names
interface QuizQuestion {
  id: string;
  articleId: string;
  articleTitle: string;
  articleSummary: string;
  articleSourceName: string;
  questionText: string;
  questionType: string; // Flutter QuestionType.name: who|what|when|where|which|howMany|howMuch
  options: string[];
  correctAnswerIndex: number;
  explanation: string;
  difficulty: string; // Flutter QuestionDifficulty.name: easy|medium|hard|veryHard|expert
  points: number;
  imageUrl: string | null;
  hasImage: boolean;
  category: string;
  generatedAt: string;
}

// ── Categories ────────────────────────────────────────────────────────────

const CATEGORIES = [
  "world",
  "politics",
  "sports",
  "technology",
  "business",
  "health",
  "entertainment",
] as const;

type Category = (typeof CATEGORIES)[number];

// ── Source config ─────────────────────────────────────────────────────────

const QUALITY_SCORES: Record<string, number> = {
  "reuters.com": 100, "apnews.com": 100, "bbc.co.uk": 95, "bbc.com": 95,
  "theguardian.com": 90, "bloomberg.com": 90, "ft.com": 90, "wsj.com": 90,
  "nytimes.com": 88, "washingtonpost.com": 88, "economist.com": 90,
  "politico.com": 80, "abc.net.au": 80, "cnbc.com": 78,
  "techcrunch.com": 75, "theverge.com": 75, "arstechnica.com": 75,
  "wired.com": 75, "technologyreview.com": 80, "newscientist.com": 80,
  "theatlantic.com": 78, "espn.com": 72, "skysports.com": 70,
  "foxsports.com.au": 65, "aljazeera.com": 78, "afr.com": 75,
  "deadline.com": 65, "variety.com": 65, "hollywoodreporter.com": 65,
};

const SOURCE_NAMES: Record<string, string> = {
  "reuters.com": "Reuters", "apnews.com": "AP News",
  "bbc.co.uk": "BBC News", "bbc.com": "BBC News",
  "theguardian.com": "The Guardian", "bloomberg.com": "Bloomberg",
  "ft.com": "Financial Times", "wsj.com": "Wall Street Journal",
  "nytimes.com": "New York Times", "washingtonpost.com": "Washington Post",
  "economist.com": "The Economist", "politico.com": "Politico",
  "abc.net.au": "ABC News", "cnbc.com": "CNBC",
  "techcrunch.com": "TechCrunch", "theverge.com": "The Verge",
  "arstechnica.com": "Ars Technica", "wired.com": "Wired",
  "technologyreview.com": "MIT Tech Review", "newscientist.com": "New Scientist",
  "theatlantic.com": "The Atlantic", "espn.com": "ESPN",
  "skysports.com": "Sky Sports", "foxsports.com.au": "Fox Sports AU",
  "aljazeera.com": "Al Jazeera", "afr.com": "AFR",
  "deadline.com": "Deadline", "variety.com": "Variety",
  "hollywoodreporter.com": "Hollywood Reporter",
};

function parseDomain(url: string): string {
  try { return new URL(url).hostname.replace(/^www\./, ""); } catch { return ""; }
}
function qualityScore(domain: string): number { return QUALITY_SCORES[domain] ?? 50; }
function displayName(domain: string): string { return SOURCE_NAMES[domain] ?? domain; }
function md5Id(url: string): string {
  return crypto.createHash("md5").update(url).digest("hex");
}

// ── QuizAbility scorer ────────────────────────────────────────────────────

const OUTCOME_VERBS = new Set([
  "wins", "beats", "elected", "appointed", "launches", "banned", "fined",
  "breaks", "sets", "signs", "signed", "passed", "approved", "announced",
  "revealed", "confirmed", "arrested", "released", "died", "opens", "closes",
  "cuts", "raises", "hits", "named", "found", "charged", "acquitted",
  "suspended", "sacked", "resigned", "struck", "defeated", "achieved",
  "reached", "secured", "halted", "resumes", "crackdown", "replaces",
  "settles", "unveils", "warns", "blocks",
]);
const SHOPPING_SIGNALS = new Set([
  "review", "deal", "sale", "discount", "cheaper", "best buy", "ranked",
  "guide", "how to", "tips", "watch", "listen", "podcast", "opinion",
  "analysis", "column", "explainer", "newsletter", "sponsored", "clone",
  "vs", "comparison", "roundup",
]);
const UNSTABLE_SIGNALS = new Set([
  "live", "breaking", "developing", "updating", "could", "might", "may",
  "perhaps", "possibly", "rumour", "rumoured", "alleged", "unconfirmed",
  "sources say", "report suggests", "exclusive", "watch", "opinion",
  "analysis", "comment",
]);
const NAMED_ENTITY_RE = /[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+/;
const NUMBER_STAT_RE = /\d+(?:\.\d+)?(?:%|bn|m|k|km|mph|years|days|hours)?/;

function scoreQuizAbility(article: Article): Article {
  let pts = 0;
  if (NAMED_ENTITY_RE.test(article.title)) pts += 25;
  if (NUMBER_STAT_RE.test(article.title) || NUMBER_STAT_RE.test(article.summary)) pts += 25;
  const titleLower = article.title.toLowerCase();
  for (const v of OUTCOME_VERBS) { if (titleLower.includes(v)) { pts += 25; break; } }
  let unstable = false;
  for (const s of UNSTABLE_SIGNALS) { if (titleLower.includes(s)) { unstable = true; break; } }
  if (!unstable) pts += 25;
  for (const s of SHOPPING_SIGNALS) { if (titleLower.includes(s)) { pts -= 25; break; } }
  return { ...article, quizabilityScore: pts, quizabilityPassed: pts >= 50 };
}

// ── Dedup ─────────────────────────────────────────────────────────────────

function deduplicate(articles: Article[]): Article[] {
  const seen = new Map<string, Article>();
  for (const a of articles) { if (!seen.has(a.id)) seen.set(a.id, a); }
  const result: Article[] = [];
  const titleKeys = new Set<string>();
  for (const a of seen.values()) {
    const key = a.title.toLowerCase().split(/\s+/).slice(0, 6).join(" ");
    if (!titleKeys.has(key)) { titleKeys.add(key); result.push(a); }
  }
  return result;
}

// ── Currents fetcher ──────────────────────────────────────────────────────

interface DomainConfig { domain: string; keywords?: string; category?: string; }

const CURRENTS_DOMAIN_CONFIGS: Record<Category, DomainConfig[]> = {
  world: [
    { domain: "reuters.com" }, { domain: "bbc.co.uk" }, { domain: "apnews.com" },
    { domain: "aljazeera.com" }, { domain: "theguardian.com" },
  ],
  politics: [
    { domain: "abc.net.au", keywords: "politics" }, { domain: "reuters.com", keywords: "politics" },
    { domain: "bbc.co.uk", keywords: "politics" }, { domain: "politico.com" },
    { domain: "theguardian.com", keywords: "politics" },
  ],
  sports: [
    { domain: "espn.com" }, { domain: "bbc.co.uk", category: "sport" },
    { domain: "theguardian.com", category: "sport" }, { domain: "foxsports.com.au" },
    { domain: "skysports.com" },
  ],
  technology: [
    { domain: "theverge.com" }, { domain: "techcrunch.com" }, { domain: "arstechnica.com" },
    { domain: "wired.com" }, { domain: "technologyreview.com" },
  ],
  business: [
    { domain: "bloomberg.com" }, { domain: "ft.com" }, { domain: "cnbc.com" },
    { domain: "reuters.com", keywords: "business" }, { domain: "afr.com" },
  ],
  health: [
    { domain: "theguardian.com", keywords: "health" }, { domain: "bbc.co.uk", keywords: "health" },
    { domain: "abc.net.au", keywords: "health" }, { domain: "newscientist.com" },
    { domain: "theatlantic.com", keywords: "health" },
  ],
  entertainment: [
    { domain: "theguardian.com", category: "culture" }, { domain: "bbc.co.uk", keywords: "entertainment" },
    { domain: "deadline.com" }, { domain: "variety.com" }, { domain: "hollywoodreporter.com" },
  ],
};

const CURRENTS_CATEGORY_MAP: Record<Category, string> = {
  world: "general", politics: "politics", sports: "sport", technology: "technology",
  business: "finance", health: "health", entertainment: "entertainment",
};

async function fetchCurrentsDomain(apiKey: string, cfg: DomainConfig, category: Category): Promise<Article[]> {
  const params = new URLSearchParams({ apiKey, domain: cfg.domain, language: "en", page_size: "20" });
  if (cfg.keywords) params.set("keywords", cfg.keywords);
  if (cfg.category) params.set("category", cfg.category);
  const res = await fetch(`https://api.currentsapi.services/v2/search?${params}`, { signal: AbortSignal.timeout(15000) });
  if (res.status === 429) throw new Error("RATE_LIMITED");
  if (res.status === 500) throw new Error("HTTP_500");
  if (!res.ok) throw new Error(`HTTP_${res.status}`);
  const data = await res.json() as { status: string; news?: unknown[] };
  if (data.status !== "ok") throw new Error(`API_STATUS_${data.status}`);
  const articles: Article[] = [];
  for (const item of data.news ?? []) {
    const map = item as Record<string, unknown>;
    const url = String(map["url"] ?? "").trim();
    const title = String(map["title"] ?? "").trim();
    if (!url || !title) continue;
    const domain = parseDomain(url) || cfg.domain;
    const imageRaw = map["image"] as string | null;
    articles.push({
      id: md5Id(url), title, summary: String(map["description"] ?? "").trim(), url,
      imageUrl: imageRaw?.startsWith("http") ? imageRaw : null,
      sourceName: displayName(domain), sourceDomain: domain,
      publishedAt: parseCurrentsDate(String(map["published"] ?? "")), category,
      sourceQualityScore: qualityScore(domain), quizabilityScore: 0, quizabilityPassed: false, apiSource: "currents",
    });
  }
  return articles;
}

async function fetchCurrentsCategoryFallback(apiKey: string, category: Category): Promise<Article[]> {
  const approvedDomains = new Set(CURRENTS_DOMAIN_CONFIGS[category].map((c) => c.domain));
  const params = new URLSearchParams({ language: "en", category: CURRENTS_CATEGORY_MAP[category], country: "gb,us,au", page_size: "20", apiKey });
  const res = await fetch(`https://api.currentsapi.services/v2/latest-news?${params}`, { signal: AbortSignal.timeout(15000) });
  if (!res.ok) return [];
  const data = await res.json() as { status: string; news?: unknown[] };
  if (data.status !== "ok") return [];
  const articles: Article[] = [];
  for (const item of data.news ?? []) {
    const map = item as Record<string, unknown>;
    const url = String(map["url"] ?? "").trim();
    const title = String(map["title"] ?? "").trim();
    if (!url || !title) continue;
    const domain = parseDomain(url);
    if (!approvedDomains.has(domain)) continue;
    const imageRaw = map["image"] as string | null;
    articles.push({
      id: md5Id(url), title, summary: String(map["description"] ?? "").trim(), url,
      imageUrl: imageRaw?.startsWith("http") ? imageRaw : null,
      sourceName: displayName(domain), sourceDomain: domain,
      publishedAt: parseCurrentsDate(String(map["published"] ?? "")), category,
      sourceQualityScore: qualityScore(domain), quizabilityScore: 0, quizabilityPassed: false, apiSource: "currents",
    });
  }
  return articles;
}

async function fetchCurrentsCategory(apiKey: string, category: Category): Promise<Article[]> {
  const configs = CURRENTS_DOMAIN_CONFIGS[category];
  const results: Article[] = [];
  let rateLimited = false;
  for (const cfg of configs) {
    if (rateLimited) break;
    await delay(200);
    try {
      results.push(...await fetchCurrentsDomain(apiKey, cfg, category));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg === "RATE_LIMITED") { rateLimited = true; console.log(`Currents RATE LIMITED for ${category}`); }
      else if (msg === "HTTP_500") { results.push(...await fetchCurrentsCategoryFallback(apiKey, category).catch(() => [])); }
      else console.log(`Currents ${cfg.domain} failed: ${msg}`);
    }
  }
  return results;
}

function parseCurrentsDate(s: string): string {
  try {
    const normalized = s.trim().replace(/^(\d{4}-\d{2}-\d{2}) /, "$1T").replace(" +", "+").replace(" -", "-");
    return new Date(normalized).toISOString();
  } catch { return new Date().toISOString(); }
}

// ── Guardian fetcher ──────────────────────────────────────────────────────

const GUARDIAN_SECTIONS: Record<Category, string> = {
  world: "world", politics: "politics", sports: "sport", technology: "technology",
  business: "business", health: "society", entertainment: "culture",
};

async function fetchGuardianCategory(apiKey: string, category: Category): Promise<Article[]> {
  const fromDate = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10);
  const params = new URLSearchParams({
    "api-key": apiKey, section: GUARDIAN_SECTIONS[category],
    "from-date": fromDate, "show-fields": "thumbnail,trailText", "page-size": "30", "order-by": "newest",
  });
  const res = await fetch(`https://content.guardianapis.com/search?${params}`, { signal: AbortSignal.timeout(15000) });
  if (!res.ok) return [];
  const data = await res.json() as { response?: { results?: unknown[] } };
  const articles: Article[] = [];
  for (const item of data.response?.results ?? []) {
    const map = item as Record<string, unknown>;
    const url = String(map["webUrl"] ?? "").trim();
    const title = String(map["webTitle"] ?? "").trim();
    if (!url || !title) continue;
    const fields = (map["fields"] ?? {}) as Record<string, unknown>;
    articles.push({
      id: md5Id(url), title,
      summary: fields["trailText"] ? String(fields["trailText"]).replace(/<[^>]*>/g, "").trim() : "",
      url, imageUrl: fields["thumbnail"] ? String(fields["thumbnail"]) : null,
      sourceName: "The Guardian", sourceDomain: "theguardian.com",
      publishedAt: map["webPublicationDate"] ? String(map["webPublicationDate"]) : new Date().toISOString(),
      category, sourceQualityScore: 90, quizabilityScore: 0, quizabilityPassed: false, apiSource: "guardian",
    });
  }
  return articles;
}

// ── NewsData fetcher ──────────────────────────────────────────────────────

const NEWSDATA_CATEGORY_MAP: Record<Category, string> = {
  world: "top", politics: "politics", sports: "sports", technology: "technology",
  business: "business", health: "health", entertainment: "entertainment",
};

const NEWSDATA_APPROVED: Record<Category, Set<string>> = {
  world: new Set(["reuters.com", "apnews.com", "bbc.co.uk", "bbc.com", "aljazeera.com", "theguardian.com"]),
  politics: new Set(["reuters.com", "bbc.co.uk", "theguardian.com", "politico.com", "abc.net.au"]),
  sports: new Set(["espn.com", "bbc.co.uk", "theguardian.com", "skysports.com"]),
  technology: new Set(["techcrunch.com", "theverge.com", "arstechnica.com", "wired.com", "technologyreview.com"]),
  business: new Set(["bloomberg.com", "cnbc.com", "reuters.com", "ft.com", "afr.com"]),
  health: new Set(["theguardian.com", "bbc.co.uk", "newscientist.com", "theatlantic.com"]),
  entertainment: new Set(["theguardian.com", "bbc.co.uk", "variety.com", "deadline.com"]),
};

async function fetchNewsdataCategory(apiKey: string, category: Category): Promise<Article[]> {
  const params = new URLSearchParams({ apikey: apiKey, language: "en", category: NEWSDATA_CATEGORY_MAP[category], size: "10" });
  const res = await fetch(`https://newsdata.io/api/1/latest?${params}`, { signal: AbortSignal.timeout(15000) });
  if (!res.ok) return [];
  const data = await res.json() as { status: string; results?: unknown[] };
  if (data.status !== "success") return [];
  const articles: Article[] = [];
  for (const item of data.results ?? []) {
    const map = item as Record<string, unknown>;
    const url = String(map["link"] ?? "").trim();
    const title = String(map["title"] ?? "").trim();
    if (!url || !title) continue;
    const domain = parseDomain(url);
    if (!NEWSDATA_APPROVED[category].has(domain)) continue;
    const imageRaw = map["image_url"] as string | null;
    const pubDate = map["pubDate"] as string | null;
    articles.push({
      id: md5Id(url), title, summary: String(map["description"] ?? map["content"] ?? "").trim(), url,
      imageUrl: imageRaw?.startsWith("http") ? imageRaw : null,
      sourceName: displayName(domain), sourceDomain: domain,
      publishedAt: pubDate ? new Date(pubDate).toISOString() : new Date().toISOString(),
      category, sourceQualityScore: qualityScore(domain), quizabilityScore: 0, quizabilityPassed: false, apiSource: "newsdata",
    });
  }
  return articles;
}

// ── News pipeline ─────────────────────────────────────────────────────────

async function runCategoryPipeline(
  category: Category, currentsKey: string, guardianKey: string, newsdataKey: string
): Promise<Article[]> {
  const [currents, guardian] = await Promise.all([
    fetchCurrentsCategory(currentsKey, category).catch(() => [] as Article[]),
    fetchGuardianCategory(guardianKey, category).catch(() => [] as Article[]),
  ]);
  let combined = deduplicate([...currents, ...guardian]).map(scoreQuizAbility);
  const cutoff = Date.now() - 48 * 60 * 60 * 1000;
  combined = combined.filter((a) => new Date(a.publishedAt).getTime() > cutoff);
  if (combined.filter((a) => a.quizabilityPassed).length < 5) {
    console.log(`${category}: < 5 quiz-able → NewsData fallback`);
    const fallback = await fetchNewsdataCategory(newsdataKey, category).catch(() => [] as Article[]);
    if (fallback.length > 0) {
      combined = deduplicate([...combined, ...fallback.map(scoreQuizAbility)])
        .filter((a) => Date.now() - new Date(a.publishedAt).getTime() < 48 * 60 * 60 * 1000);
    }
  }
  combined.sort((a, b) => (b.sourceQualityScore + b.quizabilityScore) - (a.sourceQualityScore + a.quizabilityScore));
  console.log(`${category}: ${combined.length} articles, ${combined.filter((a) => a.quizabilityPassed).length} quiz-able`);
  return combined;
}

// ── Quiz generation ───────────────────────────────────────────────────────

// Mirrors QuizGeneratorService._skipTitleKeywords
const SKIP_KEYWORDS = new Set([
  "celebrity", "gossip", "rumour", "rumored", "fashion", "style", "outfit",
  "dressed", "dating", "relationship", "breakup", "divorce", "reality tv",
  "bachelor", "bachelorette", "according to sources", "sources say", "opinion:",
  "analysis:", "comment:", "column:", "opinion", "opinions", "editorial",
  "commentary", "environmental promise", "watch:", "listen:", "podcast:", "video:",
  "horoscope", "astrology", "obituary", "crossword", "puzzle", "recipe",
  "weather", "letter to the editor", "advertorial", "sponsored", "quiz:",
  "your daily", "ronda rousey", "wwe", "ufc fighter", "boxing match",
  "kardashian", "taylor swift",
]);

const SKIP_DOMAINS = new Set([
  "tmz.com", "pagesix.com", "dailymail.co.uk", "eonline.com", "people.com",
  "usmagazine.com", "hollywoodlife.com", "reddit.com", "twitter.com", "x.com",
  "facebook.com", "instagram.com", "tiktok.com", "youtube.com",
]);

function shouldSkip(article: Article): boolean {
  if (article.summary.length < 100) return true;
  if (SKIP_DOMAINS.has(article.sourceDomain)) return true;
  if (article.url.includes("/commentisfree/") || article.url.includes("/opinion/")) return true;
  const lower = article.title.toLowerCase();
  for (const k of SKIP_KEYWORDS) { if (lower.includes(k)) return true; }
  return false;
}

const QUIZ_SYSTEM_PROMPT = `You are a quiz question writer for Briefed, a daily news quiz app.
Your questions must feel like a smart pub trivia night — specific, engaging, and satisfying to answer correctly.

CORE RULES:
1. Question must be a complete grammatical sentence (15–20 words)
2. Must start with: Who / What / When / Where / Which / How many / How much
3. Include enough context so the question makes sense on its own
4. NEVER reference "the article", "the report", journalist names, or the source
5. The correct answer must be a specific fact — a name, number, place, or outcome
6. All 4 options must be the same type (all countries, all numbers, all people, etc.)
7. Wrong options must be believable — real names/places/numbers that are plausible
8. NEVER write questions where the answer is obvious from the headline
9. NEVER write about: celebrity gossip, opinion pieces, product reviews, shopping deals
10. Explanation: exactly 2 sentences. Sentence 1: answer + context. Sentence 2: interesting related fact.
11. Return ONLY raw JSON. No markdown, no backticks, no preamble.

JSON format:
{
  "questionText": "complete grammatical sentence 15-20 words",
  "questionType": "who|what|when|where|which|how_many|how_much",
  "options": ["string","string","string","string"],
  "correctAnswerIndex": 0,
  "explanation": "2 sentences",
  "difficulty": "easy|medium|hard|veryHard|expert"
}`;

const DIFFICULTY_POINTS: Record<string, number> = {
  easy: 10, medium: 20, hard: 30, veryHard: 40, expert: 50,
};
const DIFFICULTY_ORDER: Record<string, number> = {
  easy: 0, medium: 1, hard: 2, veryHard: 3, expert: 4,
};
const DIFFICULTY_SLOTS = ["easy", "medium", "hard", "veryHard", "expert"];

// Converts AI response questionType to Flutter QuestionType enum name
function normalizeQuestionType(raw: string): string {
  const s = raw.toLowerCase().replace(/_/g, "");
  switch (s) {
    case "who": return "who";
    case "what": return "what";
    case "when": return "when";
    case "where": return "where";
    case "which": return "which";
    case "howmany": return "howMany";
    case "howmuch": return "howMuch";
    default: return "what";
  }
}

async function callGroq(userMsg: string, groqKey: string): Promise<Record<string, unknown>> {
  const body = JSON.stringify({
    model: "llama-3.3-70b-versatile",
    temperature: 0.5,
    max_tokens: 600,
    messages: [
      { role: "system", content: QUIZ_SYSTEM_PROMPT },
      { role: "user", content: userMsg },
    ],
    response_format: { type: "json_object" },
  });
  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": `Bearer ${groqKey}` },
    body,
    signal: AbortSignal.timeout(15000),
  });
  if (res.status === 429) throw new Error("GROQ_RATE_LIMITED");
  if (!res.ok) throw new Error(`Groq HTTP ${res.status}`);
  const data = await res.json() as { choices?: Array<{ message?: { content?: string } }> };
  const content = data.choices?.[0]?.message?.content ?? "";
  return JSON.parse(content) as Record<string, unknown>;
}

async function callGemini(userMsg: string, geminiKey: string): Promise<Record<string, unknown>> {
  const prompt = `${QUIZ_SYSTEM_PROMPT}\n\n${userMsg}\n\nReturn only valid JSON, no markdown.`;
  const body = JSON.stringify({
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.7, maxOutputTokens: 600 },
  });
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiKey}`,
    { method: "POST", headers: { "Content-Type": "application/json" }, body, signal: AbortSignal.timeout(20000) }
  );
  if (!res.ok) throw new Error(`Gemini HTTP ${res.status}`);
  const data = await res.json() as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  const cleaned = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
  return JSON.parse(cleaned) as Record<string, unknown>;
}

async function generateQuestion(
  article: Article, groqKey: string, geminiKey: string
): Promise<QuizQuestion | null> {
  const userMsg = `Article title: ${article.title}
Article URL: ${article.url}
Article summary: ${article.summary}
Source: ${article.sourceName}
Category: ${article.category}

Write one quiz question based only on specific facts stated in this summary.`;

  let parsed: Record<string, unknown> | null = null;
  try { parsed = await callGroq(userMsg, groqKey); }
  catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.log(`Groq failed for "${article.title.substring(0, 40)}": ${msg} → trying Gemini`);
    try { parsed = await callGemini(userMsg, geminiKey); }
    catch (e2) { console.log(`Gemini also failed: ${e2}`); return null; }
  }
  if (!parsed) return null;

  const questionText = String(parsed["questionText"] ?? "").trim();
  const options = (parsed["options"] as unknown[])?.map(String) ?? [];
  const correctAnswerIndex = Number(parsed["correctAnswerIndex"] ?? 0);
  const explanation = String(parsed["explanation"] ?? "").trim();
  const diffRaw = String(parsed["difficulty"] ?? "medium").trim();
  const difficulty = DIFFICULTY_POINTS[diffRaw] !== undefined ? diffRaw : "medium";

  if (!questionText || options.length < 4) {
    console.log(`Invalid AI response for "${article.title.substring(0, 40)}"`);
    return null;
  }

  return {
    id: `${article.id}_${Date.now()}`,
    articleId: article.id,
    articleTitle: article.title,
    articleSummary: article.summary,
    articleSourceName: article.sourceName,
    questionText,
    questionType: normalizeQuestionType(String(parsed["questionType"] ?? "what")),
    options: options.slice(0, 4),
    correctAnswerIndex: Math.max(0, Math.min(3, correctAnswerIndex)),
    explanation,
    difficulty,
    points: DIFFICULTY_POINTS[difficulty],
    imageUrl: article.imageUrl,
    hasImage: article.imageUrl !== null && article.imageUrl.length > 0,
    category: article.category,
    generatedAt: new Date().toISOString(),
  };
}

function enforceImageSlot(questions: QuizQuestion[]): QuizQuestion[] {
  // Keep at most 1 image question at index 1–3, strip hasImage from all others
  let chosen = -1;
  for (let i = 1; i <= 3 && i < questions.length; i++) {
    if (questions[i].hasImage && questions[i].imageUrl) { chosen = i; break; }
  }
  return questions.map((q, i) => {
    if (i === chosen) return q;
    return q.hasImage ? { ...q, hasImage: false } : q;
  });
}

function enforceUniqueness(questions: QuizQuestion[]): QuizQuestion[] {
  const seen = new Set<string>();
  return questions.filter((q) => {
    const words = q.questionText.toLowerCase().split(/\s+/).slice(0, 5).join(" ");
    if (seen.has(words)) return false;
    seen.add(words);
    const answer = q.options[q.correctAnswerIndex]?.toLowerCase() ?? "";
    if (seen.has(`ans_${answer}`)) return false;
    seen.add(`ans_${answer}`);
    return true;
  });
}

function applyDifficultyProgression(questions: QuizQuestion[]): QuizQuestion[] {
  if (questions.length !== 5) return questions;
  return questions.map((q, i) => {
    const slot = DIFFICULTY_SLOTS[i];
    return q.difficulty === slot ? q : { ...q, difficulty: slot, points: DIFFICULTY_POINTS[slot] };
  });
}

async function generateQuestionsForArticles(
  articles: Article[], category: string, groqKey: string, geminiKey: string
): Promise<QuizQuestion[]> {
  // Sequential with 4s gap — Gemini free tier is 15 RPM (60s/15 = 4s per call)
  const results: Array<PromiseSettledResult<QuizQuestion | null>> = [];
  for (const article of articles) {
    results.push(await Promise.allSettled([generateQuestion(article, groqKey, geminiKey)]).then((r) => r[0]));
    await delay(4000);
  }

  let questions = results
    .filter((r): r is PromiseFulfilledResult<QuizQuestion | null> => r.status === "fulfilled")
    .map((r) => r.value)
    .filter((q): q is QuizQuestion => q !== null);

  // Sort by difficulty, enforce progression, remove duplicates
  questions.sort((a, b) => (DIFFICULTY_ORDER[a.difficulty] ?? 2) - (DIFFICULTY_ORDER[b.difficulty] ?? 2));
  if (questions.length > 5) questions = questions.slice(0, 5);
  if (questions.length === 5) questions = applyDifficultyProgression(questions);
  questions = enforceUniqueness(questions);
  questions = enforceImageSlot(questions);

  console.log(`${category}: generated ${questions.length} questions`);
  return questions;
}

async function isQuizStale(key: string): Promise<boolean> {
  try {
    const doc = await db.collection("quiz_cache").doc(key).get();
    if (!doc.exists) return true;
    const updatedAt = (doc.data()?.["updatedAt"] as Timestamp | undefined)?.toDate();
    if (!updatedAt) return true;
    // Regenerate if > 6 hours old
    return Date.now() - updatedAt.getTime() > 6 * 60 * 60 * 1000;
  } catch { return true; }
}

async function runQuizGeneration(
  articlesByCategory: Map<Category, Article[]>,
  groqKey: string,
  geminiKey: string
): Promise<void> {
  const batch = db.batch();
  let batchCount = 0;

  // Category quizzes: top 5 quiz-able articles per category
  for (const [category, articles] of articlesByCategory) {
    if (!(await isQuizStale(category))) {
      console.log(`quiz_cache/${category}: fresh, skipping`);
      continue;
    }

    const pool = articles.filter((a) => a.quizabilityPassed && !shouldSkip(a)).slice(0, 5);
    if (pool.length === 0) { console.log(`${category}: no quiz-able articles`); continue; }

    const questions = await generateQuestionsForArticles(pool, category, groqKey, geminiKey);
    if (questions.length === 0) continue;

    batch.set(db.collection("quiz_cache").doc(category), {
      questions,
      updatedAt: FieldValue.serverTimestamp(),
    });
    batchCount++;
    await delay(300); // breathing room between categories
  }

  // Daily mix: 1 best article from each category → 5 questions
  if (await isQuizStale("daily_mix")) {
    const mixArticles: Article[] = [];
    for (const [, articles] of articlesByCategory) {
      const best = articles.find((a) => a.quizabilityPassed && !shouldSkip(a));
      if (best) mixArticles.push(best);
    }

    if (mixArticles.length >= 3) {
      const questions = await generateQuestionsForArticles(mixArticles, "daily_mix", groqKey, geminiKey);
      if (questions.length > 0) {
        batch.set(db.collection("quiz_cache").doc("daily_mix"), {
          questions,
          updatedAt: FieldValue.serverTimestamp(),
        });
        batchCount++;
      }
    }
  } else {
    console.log("quiz_cache/daily_mix: fresh, skipping");
  }

  if (batchCount > 0) {
    await batch.commit();
    console.log(`Quiz cache updated: ${batchCount} docs written`);
  } else {
    console.log("Quiz cache: no new docs to write (all fresh or all generation failed)");
  }
}

// ── Full pipeline ─────────────────────────────────────────────────────────

async function runFullPipeline(
  currentsKey: string, guardianKey: string, newsdataKey: string,
  groqKey: string, geminiKey: string
): Promise<void> {
  // 1 — Fetch news for all categories in parallel
  const newsResults = await Promise.allSettled(
    CATEGORIES.map((cat) => runCategoryPipeline(cat, currentsKey, guardianKey, newsdataKey))
  );

  // 2 — Write news to Firestore
  const newsBatch = db.batch();
  const articlesByCategory = new Map<Category, Article[]>();
  for (let i = 0; i < CATEGORIES.length; i++) {
    const category = CATEGORIES[i];
    const result = newsResults[i];
    if (result.status === "rejected") { console.error(`News pipeline failed for ${category}:`, result.reason); continue; }
    const articles = result.value;
    articlesByCategory.set(category, articles);
    newsBatch.set(db.collection("news_cache").doc(category), {
      articles: articles.slice(0, 50),
      updatedAt: FieldValue.serverTimestamp(),
      articleCount: articles.length,
    });
  }
  await newsBatch.commit();
  console.log("News cache updated");

  // 3 — Generate quiz questions (skips categories where cache is fresh)
  if (groqKey && geminiKey) {
    await runQuizGeneration(articlesByCategory, groqKey, geminiKey);
  } else {
    console.log("GROQ_API_KEY or GEMINI_API_KEY not set — skipping quiz generation");
  }
}

// ── Cloud Functions ───────────────────────────────────────────────────────

const ALL_SECRETS = [CURRENTS_API_KEY, GUARDIAN_API_KEY, NEWSDATA_API_KEY, GROQ_API_KEY, GEMINI_API_KEY];

export const refreshNewsCache = onSchedule(
  { schedule: "every 2 hours", timeoutSeconds: 540, memory: "512MiB", secrets: ALL_SECRETS },
  async () => {
    console.log("Starting scheduled pipeline refresh");
    await runFullPipeline(
      CURRENTS_API_KEY.value(), GUARDIAN_API_KEY.value(), NEWSDATA_API_KEY.value(),
      GROQ_API_KEY.value(), GEMINI_API_KEY.value()
    );
  }
);

export const triggerNewsRefresh = onRequest(
  { timeoutSeconds: 540, memory: "512MiB", secrets: [...ALL_SECRETS, REFRESH_TOKEN] },
  async (req, res) => {
    const token = req.headers["x-refresh-token"] ?? req.query["token"];
    if (token !== REFRESH_TOKEN.value()) { res.status(401).json({ error: "Unauthorized" }); return; }
    try {
      console.log("Starting on-demand pipeline refresh");
      await runFullPipeline(
        CURRENTS_API_KEY.value(), GUARDIAN_API_KEY.value(), NEWSDATA_API_KEY.value(),
        GROQ_API_KEY.value(), GEMINI_API_KEY.value()
      );
      res.json({ success: true, message: "News and quiz cache refreshed" });
    } catch (e) { console.error("Pipeline error:", e); res.status(500).json({ error: String(e) }); }
  }
);

// ── Helpers ───────────────────────────────────────────────────────────────

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

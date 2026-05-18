import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import * as crypto from "crypto";

initializeApp();
const db = getFirestore();

// ── Secrets (set via: firebase functions:secrets:set KEY_NAME) ─────────────
const CURRENTS_API_KEY = defineSecret("CURRENTS_API_KEY");
const GUARDIAN_API_KEY = defineSecret("GUARDIAN_API_KEY");
const NEWSDATA_API_KEY = defineSecret("NEWSDATA_API_KEY");
const REFRESH_TOKEN = defineSecret("REFRESH_TOKEN"); // for the HTTP endpoint

// ── Types ─────────────────────────────────────────────────────────────────

type ApiSource = "currents" | "guardian" | "newsdata";

interface Article {
  id: string;
  title: string;
  summary: string;
  url: string;
  imageUrl: string | null;
  sourceName: string;
  sourceDomain: string;
  publishedAt: string; // ISO string
  category: string;
  sourceQualityScore: number;
  quizabilityScore: number;
  quizabilityPassed: boolean;
  apiSource: ApiSource;
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
  "reuters.com": 100,
  "apnews.com": 100,
  "bbc.co.uk": 95,
  "bbc.com": 95,
  "theguardian.com": 90,
  "bloomberg.com": 90,
  "ft.com": 90,
  "wsj.com": 90,
  "nytimes.com": 88,
  "washingtonpost.com": 88,
  "economist.com": 90,
  "politico.com": 80,
  "abc.net.au": 80,
  "cnbc.com": 78,
  "techcrunch.com": 75,
  "theverge.com": 75,
  "arstechnica.com": 75,
  "wired.com": 75,
  "technologyreview.com": 80,
  "newscientist.com": 80,
  "theatlantic.com": 78,
  "espn.com": 72,
  "skysports.com": 70,
  "foxsports.com.au": 65,
  "aljazeera.com": 78,
  "afr.com": 75,
  "deadline.com": 65,
  "variety.com": 65,
  "hollywoodreporter.com": 65,
};

const SOURCE_NAMES: Record<string, string> = {
  "reuters.com": "Reuters",
  "apnews.com": "AP News",
  "bbc.co.uk": "BBC News",
  "bbc.com": "BBC News",
  "theguardian.com": "The Guardian",
  "bloomberg.com": "Bloomberg",
  "ft.com": "Financial Times",
  "wsj.com": "Wall Street Journal",
  "nytimes.com": "New York Times",
  "washingtonpost.com": "Washington Post",
  "economist.com": "The Economist",
  "politico.com": "Politico",
  "abc.net.au": "ABC News",
  "cnbc.com": "CNBC",
  "techcrunch.com": "TechCrunch",
  "theverge.com": "The Verge",
  "arstechnica.com": "Ars Technica",
  "wired.com": "Wired",
  "technologyreview.com": "MIT Tech Review",
  "newscientist.com": "New Scientist",
  "theatlantic.com": "The Atlantic",
  "espn.com": "ESPN",
  "skysports.com": "Sky Sports",
  "foxsports.com.au": "Fox Sports AU",
  "aljazeera.com": "Al Jazeera",
  "afr.com": "AFR",
  "deadline.com": "Deadline",
  "variety.com": "Variety",
  "hollywoodreporter.com": "Hollywood Reporter",
};

function parseDomain(url: string): string {
  try {
    const host = new URL(url).hostname.replace(/^www\./, "");
    return host;
  } catch {
    return "";
  }
}

function qualityScore(domain: string): number {
  return QUALITY_SCORES[domain] ?? 50;
}

function displayName(domain: string): string {
  return SOURCE_NAMES[domain] ?? domain;
}

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
  for (const v of OUTCOME_VERBS) {
    if (titleLower.includes(v)) { pts += 25; break; }
  }
  let unstable = false;
  for (const s of UNSTABLE_SIGNALS) {
    if (titleLower.includes(s)) { unstable = true; break; }
  }
  if (!unstable) pts += 25;

  for (const s of SHOPPING_SIGNALS) {
    if (titleLower.includes(s)) { pts -= 25; break; }
  }

  return { ...article, quizabilityScore: pts, quizabilityPassed: pts >= 50 };
}

// ── Dedup ─────────────────────────────────────────────────────────────────

function deduplicate(articles: Article[]): Article[] {
  const seen = new Map<string, Article>();
  for (const a of articles) {
    if (!seen.has(a.id)) seen.set(a.id, a);
  }
  // Simple title-overlap dedup (first 6 words)
  const result: Article[] = [];
  const titleKeys = new Set<string>();
  for (const a of seen.values()) {
    const key = a.title.toLowerCase().split(/\s+/).slice(0, 6).join(" ");
    if (!titleKeys.has(key)) {
      titleKeys.add(key);
      result.push(a);
    }
  }
  return result;
}

// ── Currents fetcher ──────────────────────────────────────────────────────

interface DomainConfig {
  domain: string;
  keywords?: string;
  category?: string;
}

const CURRENTS_DOMAIN_CONFIGS: Record<Category, DomainConfig[]> = {
  world: [
    { domain: "reuters.com" },
    { domain: "bbc.co.uk" },
    { domain: "apnews.com" },
    { domain: "aljazeera.com" },
    { domain: "theguardian.com" },
  ],
  politics: [
    { domain: "abc.net.au", keywords: "politics" },
    { domain: "reuters.com", keywords: "politics" },
    { domain: "bbc.co.uk", keywords: "politics" },
    { domain: "politico.com" },
    { domain: "theguardian.com", keywords: "politics" },
  ],
  sports: [
    { domain: "espn.com" },
    { domain: "bbc.co.uk", category: "sport" },
    { domain: "theguardian.com", category: "sport" },
    { domain: "foxsports.com.au" },
    { domain: "skysports.com" },
  ],
  technology: [
    { domain: "theverge.com" },
    { domain: "techcrunch.com" },
    { domain: "arstechnica.com" },
    { domain: "wired.com" },
    { domain: "technologyreview.com" },
  ],
  business: [
    { domain: "bloomberg.com" },
    { domain: "ft.com" },
    { domain: "cnbc.com" },
    { domain: "reuters.com", keywords: "business" },
    { domain: "afr.com" },
  ],
  health: [
    { domain: "theguardian.com", keywords: "health" },
    { domain: "bbc.co.uk", keywords: "health" },
    { domain: "abc.net.au", keywords: "health" },
    { domain: "newscientist.com" },
    { domain: "theatlantic.com", keywords: "health" },
  ],
  entertainment: [
    { domain: "theguardian.com", category: "culture" },
    { domain: "bbc.co.uk", keywords: "entertainment" },
    { domain: "deadline.com" },
    { domain: "variety.com" },
    { domain: "hollywoodreporter.com" },
  ],
};

const CURRENTS_CATEGORY_MAP: Record<Category, string> = {
  world: "general",
  politics: "politics",
  sports: "sport",
  technology: "technology",
  business: "finance",
  health: "health",
  entertainment: "entertainment",
};

async function fetchCurrentsDomain(
  apiKey: string,
  cfg: DomainConfig,
  category: Category
): Promise<Article[]> {
  const params = new URLSearchParams({
    apiKey,
    domain: cfg.domain,
    language: "en",
    page_size: "20",
  });
  if (cfg.keywords) params.set("keywords", cfg.keywords);
  if (cfg.category) params.set("category", cfg.category);

  const url = `https://api.currentsapi.services/v2/search?${params}`;
  const res = await fetch(url, { signal: AbortSignal.timeout(15000) });

  if (res.status === 429) throw new Error("RATE_LIMITED");
  if (res.status === 500) throw new Error("HTTP_500");
  if (!res.ok) throw new Error(`HTTP_${res.status}`);

  const data = await res.json() as { status: string; news?: unknown[] };
  if (data.status !== "ok") throw new Error(`API_STATUS_${data.status}`);

  const articles: Article[] = [];
  for (const item of data.news ?? []) {
    const map = item as Record<string, unknown>;
    const articleUrl = String(map["url"] ?? "").trim();
    const title = String(map["title"] ?? "").trim();
    if (!articleUrl || !title) continue;

    const domain = parseDomain(articleUrl) || cfg.domain;
    const imageRaw = map["image"] as string | null;
    articles.push({
      id: md5Id(articleUrl),
      title,
      summary: String(map["description"] ?? "").trim(),
      url: articleUrl,
      imageUrl: imageRaw?.startsWith("http") ? imageRaw : null,
      sourceName: displayName(domain),
      sourceDomain: domain,
      publishedAt: parseCurrentsDate(String(map["published"] ?? "")),
      category,
      sourceQualityScore: qualityScore(domain),
      quizabilityScore: 0,
      quizabilityPassed: false,
      apiSource: "currents",
    });
  }
  return articles;
}

async function fetchCurrentsCategoryFallback(
  apiKey: string,
  category: Category
): Promise<Article[]> {
  const approvedDomains = new Set(
    CURRENTS_DOMAIN_CONFIGS[category].map((c) => c.domain)
  );
  const params = new URLSearchParams({
    language: "en",
    category: CURRENTS_CATEGORY_MAP[category],
    country: "gb,us,au",
    page_size: "20",
    apiKey,
  });

  const res = await fetch(
    `https://api.currentsapi.services/v2/latest-news?${params}`,
    { signal: AbortSignal.timeout(15000) }
  );
  if (!res.ok) return [];

  const data = await res.json() as { status: string; news?: unknown[] };
  if (data.status !== "ok") return [];

  const articles: Article[] = [];
  for (const item of data.news ?? []) {
    const map = item as Record<string, unknown>;
    const articleUrl = String(map["url"] ?? "").trim();
    const title = String(map["title"] ?? "").trim();
    if (!articleUrl || !title) continue;

    const domain = parseDomain(articleUrl);
    if (!approvedDomains.has(domain)) continue;

    const imageRaw = map["image"] as string | null;
    articles.push({
      id: md5Id(articleUrl),
      title,
      summary: String(map["description"] ?? "").trim(),
      url: articleUrl,
      imageUrl: imageRaw?.startsWith("http") ? imageRaw : null,
      sourceName: displayName(domain),
      sourceDomain: domain,
      publishedAt: parseCurrentsDate(String(map["published"] ?? "")),
      category,
      sourceQualityScore: qualityScore(domain),
      quizabilityScore: 0,
      quizabilityPassed: false,
      apiSource: "currents",
    });
  }
  return articles;
}

async function fetchCurrentsCategory(
  apiKey: string,
  category: Category
): Promise<Article[]> {
  const configs = CURRENTS_DOMAIN_CONFIGS[category];
  const results: Article[] = [];
  let rateLimited = false;

  for (const cfg of configs) {
    if (rateLimited) break;
    await delay(200);
    try {
      const articles = await fetchCurrentsDomain(apiKey, cfg, category);
      results.push(...articles);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg === "RATE_LIMITED") {
        rateLimited = true;
        console.log(`Currents RATE LIMITED for ${category}`);
      } else if (msg === "HTTP_500") {
        const fallback = await fetchCurrentsCategoryFallback(apiKey, category).catch(() => []);
        results.push(...fallback);
      } else {
        console.log(`Currents ${cfg.domain} failed: ${msg}`);
      }
    }
  }

  return results;
}

function parseCurrentsDate(s: string): string {
  try {
    const normalized = s
      .trim()
      .replace(/^(\d{4}-\d{2}-\d{2}) /, "$1T")
      .replace(" +", "+")
      .replace(" -", "-");
    return new Date(normalized).toISOString();
  } catch {
    return new Date().toISOString();
  }
}

// ── Guardian fetcher ──────────────────────────────────────────────────────

const GUARDIAN_SECTIONS: Record<Category, string> = {
  world: "world",
  politics: "politics",
  sports: "sport",
  technology: "technology",
  business: "business",
  health: "society",
  entertainment: "culture",
};

async function fetchGuardianCategory(
  apiKey: string,
  category: Category
): Promise<Article[]> {
  const fromDate = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
    .toISOString()
    .substring(0, 10);

  const params = new URLSearchParams({
    "api-key": apiKey,
    section: GUARDIAN_SECTIONS[category],
    "from-date": fromDate,
    "show-fields": "thumbnail,trailText",
    "page-size": "30",
    "order-by": "newest",
  });

  const url = `https://content.guardianapis.com/search?${params}`;
  const res = await fetch(url, { signal: AbortSignal.timeout(15000) });
  if (!res.ok) return [];

  const data = await res.json() as {
    response?: { results?: unknown[] };
  };
  const results = data.response?.results ?? [];
  const articles: Article[] = [];

  for (const item of results) {
    const map = item as Record<string, unknown>;
    const articleUrl = String(map["webUrl"] ?? "").trim();
    const title = String(map["webTitle"] ?? "").trim();
    if (!articleUrl || !title) continue;

    const fields = (map["fields"] ?? {}) as Record<string, unknown>;
    const imageUrl = fields["thumbnail"] ? String(fields["thumbnail"]) : null;
    const summary = fields["trailText"] ? String(fields["trailText"]) : "";
    const publishedAt = map["webPublicationDate"]
      ? String(map["webPublicationDate"])
      : new Date().toISOString();

    articles.push({
      id: md5Id(articleUrl),
      title,
      summary: summary.replace(/<[^>]*>/g, "").trim(),
      url: articleUrl,
      imageUrl,
      sourceName: "The Guardian",
      sourceDomain: "theguardian.com",
      publishedAt,
      category,
      sourceQualityScore: 90,
      quizabilityScore: 0,
      quizabilityPassed: false,
      apiSource: "guardian",
    });
  }
  return articles;
}

// ── NewsData fetcher ──────────────────────────────────────────────────────

const NEWSDATA_CATEGORY_MAP: Record<Category, string> = {
  world: "top",
  politics: "politics",
  sports: "sports",
  technology: "technology",
  business: "business",
  health: "health",
  entertainment: "entertainment",
};

const NEWSDATA_APPROVED_DOMAINS: Record<Category, string[]> = {
  world: ["reuters.com", "apnews.com", "bbc.co.uk", "bbc.com", "aljazeera.com", "theguardian.com"],
  politics: ["reuters.com", "bbc.co.uk", "theguardian.com", "politico.com", "abc.net.au"],
  sports: ["espn.com", "bbc.co.uk", "theguardian.com", "skysports.com"],
  technology: ["techcrunch.com", "theverge.com", "arstechnica.com", "wired.com", "technologyreview.com"],
  business: ["bloomberg.com", "cnbc.com", "reuters.com", "ft.com", "afr.com"],
  health: ["theguardian.com", "bbc.co.uk", "newscientist.com", "theatlantic.com"],
  entertainment: ["theguardian.com", "bbc.co.uk", "variety.com", "deadline.com"],
};

async function fetchNewsdataCategory(
  apiKey: string,
  category: Category
): Promise<Article[]> {
  const approvedDomains = new Set(NEWSDATA_APPROVED_DOMAINS[category]);
  const params = new URLSearchParams({
    apikey: apiKey,
    language: "en",
    category: NEWSDATA_CATEGORY_MAP[category],
    size: "10",
  });

  const res = await fetch(
    `https://newsdata.io/api/1/latest?${params}`,
    { signal: AbortSignal.timeout(15000) }
  );
  if (!res.ok) return [];

  const data = await res.json() as { status: string; results?: unknown[] };
  if (data.status !== "success") return [];

  const articles: Article[] = [];
  for (const item of data.results ?? []) {
    const map = item as Record<string, unknown>;
    const articleUrl = String(map["link"] ?? "").trim();
    const title = String(map["title"] ?? "").trim();
    if (!articleUrl || !title) continue;

    const domain = parseDomain(articleUrl);
    if (!approvedDomains.has(domain)) continue;

    const imageRaw = map["image_url"] as string | null;
    const pubDateStr = map["pubDate"] as string | null;
    const publishedAt = pubDateStr ? new Date(pubDateStr).toISOString() : new Date().toISOString();

    articles.push({
      id: md5Id(articleUrl),
      title,
      summary: String(map["description"] ?? map["content"] ?? "").trim(),
      url: articleUrl,
      imageUrl: imageRaw?.startsWith("http") ? imageRaw : null,
      sourceName: displayName(domain),
      sourceDomain: domain,
      publishedAt,
      category,
      sourceQualityScore: qualityScore(domain),
      quizabilityScore: 0,
      quizabilityPassed: false,
      apiSource: "newsdata",
    });
  }
  return articles;
}

// ── Pipeline ──────────────────────────────────────────────────────────────

async function runCategoryPipeline(
  category: Category,
  currentsKey: string,
  guardianKey: string,
  newsdataKey: string
): Promise<Article[]> {
  const [currentsArticles, guardianArticles] = await Promise.all([
    fetchCurrentsCategory(currentsKey, category).catch(() => [] as Article[]),
    fetchGuardianCategory(guardianKey, category).catch(() => [] as Article[]),
  ]);

  let combined = deduplicate([...currentsArticles, ...guardianArticles]);

  // Score quiz-ability
  combined = combined.map(scoreQuizAbility);

  // Drop articles older than 48h
  const cutoff = Date.now() - 48 * 60 * 60 * 1000;
  combined = combined.filter((a) => new Date(a.publishedAt).getTime() > cutoff);

  // Fallback if fewer than 5 quiz-able
  const quizableCount = combined.filter((a) => a.quizabilityPassed).length;
  if (quizableCount < 5) {
    console.log(`${category}: only ${quizableCount} quiz-able → NewsData fallback`);
    const fallback = await fetchNewsdataCategory(newsdataKey, category).catch(() => [] as Article[]);
    if (fallback.length > 0) {
      const scoredFallback = fallback.map(scoreQuizAbility);
      combined = deduplicate([...combined, ...scoredFallback]).filter(
        (a) => Date.now() - new Date(a.publishedAt).getTime() < 48 * 60 * 60 * 1000
      );
    }
  }

  // Sort by finalScore (sourceQualityScore + quizabilityScore)
  combined.sort((a, b) => {
    const scoreA = a.sourceQualityScore + a.quizabilityScore;
    const scoreB = b.sourceQualityScore + b.quizabilityScore;
    return scoreB - scoreA;
  });

  console.log(
    `${category}: ${combined.length} articles, ` +
    `${combined.filter((a) => a.quizabilityPassed).length} quiz-able`
  );
  return combined;
}

async function runFullPipeline(
  currentsKey: string,
  guardianKey: string,
  newsdataKey: string
): Promise<void> {
  const results = await Promise.allSettled(
    CATEGORIES.map((cat) =>
      runCategoryPipeline(cat, currentsKey, guardianKey, newsdataKey)
    )
  );

  const batch = db.batch();
  for (let i = 0; i < CATEGORIES.length; i++) {
    const category = CATEGORIES[i];
    const result = results[i];
    if (result.status === "rejected") {
      console.error(`Pipeline failed for ${category}:`, result.reason);
      continue;
    }

    const articles = result.value;
    const ref = db.collection("news_cache").doc(category);
    batch.set(ref, {
      articles: articles.slice(0, 50), // cap at 50 per category
      updatedAt: FieldValue.serverTimestamp(),
      articleCount: articles.length,
    });
  }

  await batch.commit();
  console.log("News cache updated successfully");
}

// ── Cloud Functions ───────────────────────────────────────────────────────

// Scheduled: runs every 2 hours
export const refreshNewsCache = onSchedule(
  {
    schedule: "every 2 hours",
    timeoutSeconds: 300,
    memory: "512MiB",
    secrets: [CURRENTS_API_KEY, GUARDIAN_API_KEY, NEWSDATA_API_KEY],
  },
  async () => {
    console.log("Starting scheduled news cache refresh");
    await runFullPipeline(
      CURRENTS_API_KEY.value(),
      GUARDIAN_API_KEY.value(),
      NEWSDATA_API_KEY.value()
    );
  }
);

// HTTP endpoint: on-demand refresh (protected by token)
export const triggerNewsRefresh = onRequest(
  {
    timeoutSeconds: 300,
    memory: "512MiB",
    secrets: [CURRENTS_API_KEY, GUARDIAN_API_KEY, NEWSDATA_API_KEY, REFRESH_TOKEN],
  },
  async (req, res) => {
    const token = req.headers["x-refresh-token"] ?? req.query["token"];
    if (token !== REFRESH_TOKEN.value()) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    try {
      console.log("Starting on-demand news cache refresh");
      await runFullPipeline(
        CURRENTS_API_KEY.value(),
        GUARDIAN_API_KEY.value(),
        NEWSDATA_API_KEY.value()
      );
      res.json({ success: true, message: "News cache refreshed" });
    } catch (e) {
      console.error("Pipeline error:", e);
      res.status(500).json({ error: String(e) });
    }
  }
);

// ── Helpers ───────────────────────────────────────────────────────────────

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

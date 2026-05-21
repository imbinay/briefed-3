import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

import '../core/theme.dart';
import '../widgets/ad_widgets.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/pro_purchase_service.dart';
import '../widgets/widgets.dart';
import '../features/news/models/ranked_article.dart';
import '../features/news/models/news_category.dart';
import '../features/news/providers/news_pipeline_provider.dart';
import 'home_screen.dart';
import 'today_screen.dart';
import '../services/game_results_service.dart';
import '../features/xp/xp_service.dart';

// STATIC GAME DATA

class _RealOrFakeData {
  static const List<Map<String, dynamic>> headlines = [
    // ── REAL ──────────────────────────────────────────────────────────────
    {
      'headline':
          'Australia bans social media for children under 16, fines up to \$50M',
      'isReal': true,
      'explanation':
          'Australia passed this landmark law in late 2024, the first country globally to do so.'
    },
    {
      'headline': 'Twitter rebrands to X after Elon Musk acquisition',
      'isReal': true,
      'explanation':
          'Elon Musk completed his \$44B Twitter acquisition and rebranded it to X in 2023.'
    },
    {
      'headline': 'ChatGPT reaches 100 million users in just two months',
      'isReal': true,
      'explanation':
          'ChatGPT became the fastest-growing consumer app in history when it launched in late 2022.'
    },
    {
      'headline': 'India overtakes China as world\'s most populous country',
      'isReal': true,
      'explanation':
          'India surpassed China in 2023 according to UN population estimates.'
    },
    {
      'headline': 'Scientists release first ever image of a black hole',
      'isReal': true,
      'explanation':
          'The Event Horizon Telescope released the first black hole image in April 2019.'
    },
    {
      'headline':
          'NASA\'s Artemis I successfully completes uncrewed Moon mission',
      'isReal': true,
      'explanation':
          'Artemis I launched in November 2022 and completed a 25-day mission around the Moon.'
    },
    {
      'headline':
          'OpenAI\'s GPT-4 passes the bar exam scoring in top 10 percent',
      'isReal': true,
      'explanation':
          'GPT-4 scored in approximately the 90th percentile on the Uniform Bar Examination.'
    },
    {
      'headline': 'Japan\'s population declines for 13th consecutive year',
      'isReal': true,
      'explanation':
          'Japan has faced population decline since 2011 due to low birth rates and limited immigration.'
    },
    {
      'headline': 'Netflix loses subscribers for first time in over a decade',
      'isReal': true,
      'explanation':
          'Netflix reported losing 200,000 subscribers in Q1 2022, its first loss since 2011.'
    },
    {
      'headline': 'WHO declares COVID-19 a global pandemic',
      'isReal': true,
      'explanation':
          'The World Health Organisation officially declared COVID-19 a pandemic on March 11, 2020.'
    },
    {
      'headline':
          'Apple becomes first company to reach \$3 trillion market cap',
      'isReal': true,
      'explanation':
          'Apple briefly crossed \$3 trillion in January 2022, the first company to do so.'
    },
    {
      'headline': 'Spotify launches in 80 new markets in a single day',
      'isReal': true,
      'explanation':
          'Spotify expanded to 80 new markets in February 2021 including parts of Africa and Asia.'
    },
    {
      'headline':
          'Elon Musk surpasses Jeff Bezos to become world\'s richest person',
      'isReal': true,
      'explanation':
          'Musk overtook Bezos in January 2021 after Tesla\'s share price surged.'
    },
    {
      'headline': 'Facebook rebrands its parent company to Meta',
      'isReal': true,
      'explanation':
          'Mark Zuckerberg announced the rebrand to Meta in October 2021 to reflect the metaverse focus.'
    },
    {
      'headline': 'GameStop shares surge over 1,700% in a matter of weeks',
      'isReal': true,
      'explanation':
          'Reddit traders on WallStreetBets drove a massive short squeeze in January 2021.'
    },
    {
      'headline':
          'Container ship Ever Given runs aground, blocking the Suez Canal for six days',
      'isReal': true,
      'explanation':
          'The Ever Given grounded in March 2021, blocking one of the world\'s busiest trade routes.'
    },
    {
      'headline':
          'Squid Game becomes Netflix\'s most-watched series of all time',
      'isReal': true,
      'explanation':
          'The Korean thriller was watched in 111 million households within its first 28 days in 2021.'
    },
    {
      'headline': 'James Webb Space Telescope launches on Christmas Day',
      'isReal': true,
      'explanation':
          'Webb launched on December 25, 2021, from French Guiana and became the most powerful telescope ever built.'
    },
    {
      'headline':
          'Microsoft acquires Activision Blizzard for a record \$69 billion',
      'isReal': true,
      'explanation':
          'Microsoft completed the acquisition in October 2023 after a lengthy regulatory battle.'
    },
    {
      'headline': 'Russia launches a full-scale military invasion of Ukraine',
      'isReal': true,
      'explanation':
          'Russia began its invasion of Ukraine on February 24, 2022, triggering Europe\'s largest conflict since WWII.'
    },
    {
      'headline': 'Queen Elizabeth II dies after a 70-year reign, aged 96',
      'isReal': true,
      'explanation':
          'Queen Elizabeth II died at Balmoral Castle on September 8, 2022.'
    },
    {
      'headline':
          'FTX crypto exchange collapses; CEO Sam Bankman-Fried is arrested',
      'isReal': true,
      'explanation':
          'FTX filed for bankruptcy in November 2022 and Bankman-Fried was later convicted of fraud.'
    },
    {
      'headline':
          'Argentina wins the FIFA World Cup; Messi lifts the trophy for the first time',
      'isReal': true,
      'explanation':
          'Argentina beat France on penalties in the 2022 World Cup final in Qatar.'
    },
    {
      'headline':
          'NASA\'s DART mission successfully changes an asteroid\'s orbit',
      'isReal': true,
      'explanation':
          'DART deliberately crashed into the asteroid Dimorphos in September 2022, altering its path.'
    },
    {
      'headline':
          'Rishi Sunak becomes the UK\'s first British Asian prime minister',
      'isReal': true,
      'explanation':
          'Sunak took office in October 2022, becoming the UK\'s youngest PM in modern times.'
    },
    {
      'headline': 'iPhone 15 replaces the Lightning port with USB-C',
      'isReal': true,
      'explanation':
          'Apple switched to USB-C on all iPhone 15 models in 2023 following EU regulations.'
    },
    {
      'headline':
          'OpenAI CEO Sam Altman is fired, then reinstated within five days',
      'isReal': true,
      'explanation':
          'The OpenAI board ousted Altman in November 2023 before pressure from staff and investors forced his return.'
    },
    {
      'headline':
          'Meta launches Threads, gaining over 100 million users in under a week',
      'isReal': true,
      'explanation':
          'Threads launched in July 2023 and became the fastest app to reach 100 million sign-ups.'
    },
    {
      'headline':
          'India\'s Chandrayaan-3 becomes first spacecraft to land near the Moon\'s south pole',
      'isReal': true,
      'explanation':
          'Chandrayaan-3 successfully landed in August 2023, a world first for the lunar south pole.'
    },
    {
      'headline': 'King Charles III is crowned at Westminster Abbey',
      'isReal': true,
      'explanation':
          'Charles was coronated on May 6, 2023, the first British coronation in 70 years.'
    },
    {
      'headline': 'Lionel Messi wins a record-breaking eighth Ballon d\'Or',
      'isReal': true,
      'explanation':
          'Messi claimed his eighth Ballon d\'Or in October 2023, extending his own record.'
    },
    {
      'headline':
          'Apple unveils the Vision Pro mixed-reality headset at \$3,499',
      'isReal': true,
      'explanation':
          'Apple revealed the Vision Pro at WWDC in June 2023; it went on sale in February 2024.'
    },
    {
      'headline':
          'YouTube begins blocking ad-blocker extensions for users worldwide',
      'isReal': true,
      'explanation':
          'YouTube rolled out a global crackdown on ad blockers in late 2023.'
    },
    {
      'headline': 'Reddit goes public via IPO, valued at around \$6.4 billion',
      'isReal': true,
      'explanation':
          'Reddit listed on the New York Stock Exchange in March 2024.'
    },
    {
      'headline':
          'Nvidia briefly becomes the world\'s most valuable publicly traded company',
      'isReal': true,
      'explanation':
          'Nvidia overtook Microsoft in June 2024 driven by insatiable demand for AI chips.'
    },
    {
      'headline': 'TikTok faces a potential federal ban in the United States',
      'isReal': true,
      'explanation':
          'A US law requiring ByteDance to divest TikTok was signed in April 2024 over national security concerns.'
    },
    {
      'headline':
          'EU fines Apple nearly \$2 billion for anti-competitive App Store practices',
      'isReal': true,
      'explanation':
          'The European Commission fined Apple €1.84 billion in March 2024 over music streaming rules.'
    },
    {
      'headline':
          'SpaceX\'s Starship rocket completes its first fully successful test flight',
      'isReal': true,
      'explanation':
          'Starship\'s sixth test flight in October 2024 saw both the booster and ship successfully recovered.'
    },
    {
      'headline':
          'Boeing 737 Max grounded worldwide after two fatal crashes kill 346 people',
      'isReal': true,
      'explanation':
          'The Lion Air and Ethiopian Airlines crashes in 2018–19 led to a 20-month global grounding.'
    },
    {
      'headline':
          'Notre-Dame Cathedral in Paris catches fire, destroying its medieval spire',
      'isReal': true,
      'explanation':
          'The April 2019 fire caused catastrophic damage; restoration work continues.'
    },
    {
      'headline':
          'Greta Thunberg is named Time magazine\'s Person of the Year, aged 16',
      'isReal': true,
      'explanation':
          'Time chose the Swedish climate activist as Person of the Year in December 2019.'
    },
    {
      'headline': 'Facebook acquires WhatsApp for \$19 billion',
      'isReal': true,
      'explanation':
          'Facebook completed the WhatsApp acquisition in October 2014 for \$19 billion.'
    },
    {
      'headline':
          'Edward Snowden leaks classified NSA mass-surveillance documents',
      'isReal': true,
      'explanation':
          'Snowden revealed PRISM and other surveillance programmes to journalists in June 2013.'
    },
    {
      'headline':
          'NASA\'s Curiosity rover lands on Mars using a sky-crane system',
      'isReal': true,
      'explanation':
          'Curiosity touched down in Gale Crater in August 2012 using a novel sky-crane landing.'
    },
    {
      'headline': 'Osama bin Laden is killed by US Navy SEALs in Pakistan',
      'isReal': true,
      'explanation':
          'Operation Neptune Spear on May 2, 2011 ended the decade-long hunt for the al-Qaeda leader.'
    },
    {
      'headline': 'Steve Jobs dies aged 56 after battling pancreatic cancer',
      'isReal': true,
      'explanation':
          'Jobs passed away on October 5, 2011, six weeks after stepping down as Apple CEO.'
    },
    {
      'headline':
          'Google DeepMind\'s AlphaGo defeats world Go champion Lee Sedol 4-1',
      'isReal': true,
      'explanation':
          'AlphaGo\'s 2016 victory was seen as a landmark moment in artificial intelligence.'
    },
    {
      'headline':
          'Pokémon Go is downloaded 100 million times within its first month',
      'isReal': true,
      'explanation':
          'The augmented-reality game became a global phenomenon after launching in July 2016.'
    },
    {
      'headline':
          'UK votes to leave the European Union in the Brexit referendum',
      'isReal': true,
      'explanation':
          'The June 2016 vote resulted in 52% of Britons choosing to leave the EU.'
    },
    {
      'headline':
          'Scientists confirm the first direct detection of gravitational waves',
      'isReal': true,
      'explanation':
          'LIGO announced the detection in February 2016, confirming a prediction Einstein made 100 years earlier.'
    },
    {
      'headline': 'Paris Agreement on climate change is signed by 195 nations',
      'isReal': true,
      'explanation':
          'The landmark agreement was adopted at COP21 in December 2015.'
    },
    {
      'headline':
          'Lehman Brothers collapses, filing the largest bankruptcy in US history',
      'isReal': true,
      'explanation':
          'Lehman\'s September 2008 failure triggered a global financial crisis.'
    },
    {
      'headline':
          'Space Shuttle Challenger breaks apart 73 seconds after launch',
      'isReal': true,
      'explanation':
          'The January 28, 1986 disaster killed all seven crew members due to a failed O-ring seal.'
    },
    {
      'headline':
          'IBM\'s Deep Blue defeats world chess champion Garry Kasparov',
      'isReal': true,
      'explanation':
          'Deep Blue won a six-game match against Kasparov in May 1997, a milestone for AI.'
    },
    {
      'headline':
          'Dolly the sheep is revealed as the first mammal cloned from an adult cell',
      'isReal': true,
      'explanation':
          'Scientists at the Roslin Institute in Scotland cloned Dolly in 1996 and announced it in 1997.'
    },
    {
      'headline':
          'Y2K bug causes no major disasters despite widespread global panic',
      'isReal': true,
      'explanation':
          'Billions spent on fixes meant the millennium date change on January 1, 2000 passed without incident.'
    },
    {
      'headline':
          'Euro banknotes and coins enter circulation across 12 EU nations',
      'isReal': true,
      'explanation':
          'The euro became physical currency on January 1, 2002 in Austria, France, Germany and nine others.'
    },
    {
      'headline':
          'Skype launches, making free video calls over the internet widely accessible',
      'isReal': true,
      'explanation':
          'Skype launched in August 2003 and rapidly changed how people communicated long-distance.'
    },
    {
      'headline': 'WHO renames monkeypox to \'mpox\' amid stigma concerns',
      'isReal': true,
      'explanation':
          'The WHO officially adopted the new name mpox in November 2022.'
    },
    {
      'headline':
          'US Supreme Court overturns Roe v. Wade, ending federal abortion rights',
      'isReal': true,
      'explanation':
          'The Dobbs v. Jackson ruling in June 2022 left abortion law to individual states.'
    },
    {
      'headline':
          'Netflix confirms it will introduce ads for cheaper subscription tier',
      'isReal': true,
      'explanation':
          'Netflix launched its ad-supported plan in November 2022 to counter subscriber losses.'
    },
    {
      'headline':
          'Stephen Hawking dies peacefully at his home in Cambridge, aged 76',
      'isReal': true,
      'explanation':
          'The theoretical physicist and author of A Brief History of Time died on March 14, 2018.'
    },
    {
      'headline':
          'WhatsApp rolls out end-to-end encryption for all one billion users by default',
      'isReal': true,
      'explanation':
          'WhatsApp enabled full end-to-end encryption for every message in April 2016.'
    },
    {
      'headline':
          'Apple launches the iPad, creating the modern tablet computer market',
      'isReal': true,
      'explanation':
          'Steve Jobs unveiled the first iPad in January 2010; it sold 300,000 units on its first day.'
    },
    {
      'headline':
          'Google Maps launches with free street-level navigation for the public',
      'isReal': true,
      'explanation':
          'Google Maps launched in February 2005 and transformed how people navigate.'
    },

    // ── FAKE ──────────────────────────────────────────────────────────────
    {
      'headline':
          'France bans all smartphones in public parks to boost social interaction',
      'isReal': false,
      'explanation':
          'France banned phones in schools, but no such law exists for public parks.'
    },
    {
      'headline': 'Google announces plans to acquire Reddit for \$8 billion',
      'isReal': false,
      'explanation':
          'Reddit went public via IPO in 2024. Google has not acquired it.'
    },
    {
      'headline':
          'Amazon opens world\'s first fully underwater warehouse in Norway',
      'isReal': false,
      'explanation': 'Entirely fictional. Amazon has no underwater facilities.'
    },
    {
      'headline':
          'Tesla launches solar-powered commercial airline service by 2026',
      'isReal': false,
      'explanation':
          'Tesla operates in EVs and energy storage, not commercial aviation.'
    },
    {
      'headline':
          'Scientists confirm daily coffee consumption reverses memory loss',
      'isReal': false,
      'explanation':
          'No study confirms coffee reverses memory loss. Some suggest mild cognitive benefits only.'
    },
    {
      'headline':
          'UN passes resolution making internet access a basic human right with enforcement powers',
      'isReal': false,
      'explanation':
          'The UN has called internet access important but passed no binding enforcement resolution.'
    },
    {
      'headline':
          'Microsoft acquires Nintendo for \$75 billion to enter gaming hardware market',
      'isReal': false,
      'explanation':
          'Microsoft acquired Activision Blizzard but has not acquired Nintendo.'
    },
    {
      'headline':
          'New study confirms humans only use 10 percent of their brain capacity',
      'isReal': false,
      'explanation':
          'This is a long-debunked myth. Brain imaging shows all brain areas are regularly active.'
    },
    {
      'headline':
          'Sweden mandates four-day work week for all companies with over 50 employees',
      'isReal': false,
      'explanation':
          'Sweden trialled shorter hours in some sectors but has no national four-day work week law.'
    },
    {
      'headline':
          'Apple launches its own satellite internet service to rival Starlink',
      'isReal': false,
      'explanation': 'Apple has not launched a satellite internet service.'
    },
    {
      'headline': 'Google announces plans to acquire TikTok for \$30 billion',
      'isReal': false,
      'explanation':
          'Google has not acquired TikTok. ByteDance still owns it despite US legislative pressure.'
    },
    {
      'headline':
          'Tesla unveils a consumer flying car priced at \$25,000 for 2027 delivery',
      'isReal': false,
      'explanation':
          'Tesla has no flying car programme. It focuses on ground-based electric vehicles.'
    },
    {
      'headline':
          'Scientists develop a daily pill that fully replaces the need for physical exercise',
      'isReal': false,
      'explanation':
          'No approved pill replicates the full benefits of exercise. Research exists but no product.'
    },
    {
      'headline':
          'Spotify announces it will pay artists \$1 per stream starting 2025',
      'isReal': false,
      'explanation':
          'Spotify pays roughly \$0.003–\$0.005 per stream. A \$1 per stream rate is completely fictional.'
    },
    {
      'headline':
          'Apple purchases Formula 1 broadcasting rights for \$10 billion',
      'isReal': false,
      'explanation':
          'Apple has not purchased F1 broadcasting rights. It does have an F1 film in production.'
    },
    {
      'headline': 'Meta shuts down Instagram and migrates all users to Threads',
      'isReal': false,
      'explanation':
          'Instagram remains one of the world\'s most-used apps. Meta runs both Instagram and Threads.'
    },
    {
      'headline':
          'Scientists confirm signs of microbial life in the clouds of Venus',
      'isReal': false,
      'explanation':
          'Phosphine was detected in Venusian clouds (disputed), but life has not been confirmed.'
    },
    {
      'headline':
          'Microsoft acquires Adobe for \$75 billion to dominate creative software',
      'isReal': false,
      'explanation':
          'Adobe\'s proposed acquisition by Figma (\$20B) was scrapped. Microsoft has not acquired Adobe.'
    },
    {
      'headline':
          'EU mandates all social media posts must be fact-checked before publishing',
      'isReal': false,
      'explanation':
          'No such law exists. The EU\'s Digital Services Act requires platforms to address illegal content, not pre-screen posts.'
    },
    {
      'headline':
          'WHO classifies excessive social media use as a recognised mental disorder',
      'isReal': false,
      'explanation':
          'The WHO has not classified social media use as a mental disorder. Gaming disorder was added in 2018.'
    },
    {
      'headline':
          'China successfully lands astronauts on the Moon before NASA\'s Artemis crew',
      'isReal': false,
      'explanation':
          'As of 2024, no human has walked on the Moon since Apollo 17 in 1972. China targets the Moon by the 2030s.'
    },
    {
      'headline':
          'YouTube introduces mandatory 30-second unskippable ads before every video',
      'isReal': false,
      'explanation':
          'YouTube has non-skippable ads but they are typically 15–20 seconds and not on every video.'
    },
    {
      'headline':
          'Bitcoin becomes legal tender in the United States by executive order',
      'isReal': false,
      'explanation':
          'Bitcoin is legal in the US but is not legal tender. El Salvador adopted it as legal tender in 2021.'
    },
    {
      'headline':
          'Facebook sues Google for copying the concept of social \'likes\'',
      'isReal': false,
      'explanation':
          'No such lawsuit exists. The \'like\' button concept predates Facebook and has never been exclusively claimed.'
    },
    {
      'headline':
          'Apple acquires Netflix for \$200 billion in a landmark streaming deal',
      'isReal': false,
      'explanation':
          'Apple has not acquired Netflix. Both companies run separate, competing streaming services.'
    },
    {
      'headline':
          'Scientists successfully grow a fully functional human heart in a laboratory',
      'isReal': false,
      'explanation':
          'Researchers have grown organoids and partial heart tissue, but not a full functional human heart.'
    },
    {
      'headline': 'Elon Musk purchases Disney to merge it with X and Tesla',
      'isReal': false,
      'explanation':
          'Musk has not purchased Disney. He has expressed interest but made no formal bid.'
    },
    {
      'headline':
          'Netflix announces it will charge extra for watching more than 4 hours of content per day',
      'isReal': false,
      'explanation':
          'Netflix charges a flat subscription fee with no daily viewing limits.'
    },
    {
      'headline':
          'WHO declares climate anxiety a globally recognised mental health emergency',
      'isReal': false,
      'explanation':
          'Climate anxiety is acknowledged by mental health bodies, but the WHO has not declared it an emergency.'
    },
    {
      'headline':
          'Japan introduces a law requiring humanoid robots to hold legal rights by 2030',
      'isReal': false,
      'explanation':
          'No country has granted legal rights to robots. Japan leads in robotics but has passed no such law.'
    },
    {
      'headline': 'Scientists invent a pill that eliminates the need for sleep',
      'isReal': false,
      'explanation':
          'No approved drug replaces sleep. Some military research explores wakeful agents, none eliminate sleep need.'
    },
    {
      'headline':
          'Google launches a free smartphone to directly compete with the iPhone',
      'isReal': false,
      'explanation':
          'Google makes the Pixel phone but it is not free. A free Google-branded phone does not exist.'
    },
    {
      'headline':
          'NASA confirms it has received a signal from an alien civilisation',
      'isReal': false,
      'explanation':
          'NASA has found no confirmed signal from extraterrestrial intelligence. The search continues via SETI.'
    },
    {
      'headline':
          'Amazon announces free delivery will no longer be included with Prime',
      'isReal': false,
      'explanation':
          'Free delivery remains a core Prime benefit as of 2024. Amazon has raised prices but kept the feature.'
    },
    {
      'headline':
          'Facebook introduces a feature showing exactly who viewed your profile',
      'isReal': false,
      'explanation':
          'Facebook has never offered a profile-viewer feature and has repeatedly confirmed it cannot be built.'
    },
    {
      'headline': 'PayPal acquires Snapchat to expand into social commerce',
      'isReal': false,
      'explanation':
          'PayPal has not acquired Snapchat. Snap Inc. remains an independent company.'
    },
    {
      'headline':
          'EU bans all targeted advertising aimed at users under the age of 18',
      'isReal': false,
      'explanation':
          'The EU has restricted some targeting of minors under GDPR and DSA, but not banned all targeted ads.'
    },
    {
      'headline':
          'McDonald\'s announces plans to go fully vegetarian across all menus by 2030',
      'isReal': false,
      'explanation':
          'McDonald\'s has added plant-based options but has no plan to remove meat from its global menu.'
    },
    {
      'headline':
          'Amazon builds the world\'s first fully operational drone delivery motorway',
      'isReal': false,
      'explanation':
          'Amazon Prime Air drone deliveries exist in limited trials. A dedicated drone motorway does not exist.'
    },
    {
      'headline':
          'UN votes to ban all private jet travel by 2028 for climate reasons',
      'isReal': false,
      'explanation':
          'No UN resolution banning private jets has been passed. France banned short domestic flights in 2023.'
    },
    {
      'headline':
          'Scientists confirm that drinking a glass of red wine daily significantly extends lifespan',
      'isReal': false,
      'explanation':
          'Many studies suggest moderate alcohol offers little to no health benefit. No confirmed lifespan extension.'
    },
    {
      'headline':
          'Wikipedia permanently bans all AI-generated content from its articles',
      'isReal': false,
      'explanation':
          'Wikipedia has introduced guidance on AI content but has not issued a blanket permanent ban.'
    },
    {
      'headline':
          'OpenAI creates an AI that writes full novels completely indistinguishable from human authors',
      'isReal': false,
      'explanation':
          'AI can produce novel-length text, but studies show AI writing remains detectable by trained reviewers.'
    },
    {
      'headline':
          'South Korea passes a law making social media addiction a criminal offence',
      'isReal': false,
      'explanation':
          'South Korea treats gaming addiction as a health issue, not a crime. No such social media law exists.'
    },
    {
      'headline':
          'China bans all fossil fuel vehicles with immediate 90-day notice to drivers',
      'isReal': false,
      'explanation':
          'China aims to reduce fossil fuel vehicles by 2035 but has not issued an immediate ban.'
    },
    {
      'headline':
          'Apple announces the iPhone will switch to the Android operating system',
      'isReal': false,
      'explanation':
          'Apple develops its own iOS and has never indicated any plan to adopt Android.'
    },
  ];
}

class _OldestToLatestData {
  static const List<Map<String, dynamic>> events = [
    // ── Pre-20th century ──────────────────────────────────────────────────
    {
      'event': 'Battle of Hastings: William the Conqueror defeats King Harold',
      'year': 1066,
      'detail': 'October 14, 1066 — Norman conquest of England'
    },
    {
      'event': 'King John signs the Magna Carta',
      'year': 1215,
      'detail': 'June 15, 1215 — first limits on royal power'
    },
    {
      'event': 'Gutenberg completes his printing press with movable type',
      'year': 1440,
      'detail': 'c.1440 — transforms mass communication'
    },
    {
      'event': 'Columbus reaches the Americas on behalf of Spain',
      'year': 1492,
      'detail': 'October 12, 1492 — lands in the Bahamas'
    },
    {
      'event':
          'Copernicus publishes his heliocentric model of the solar system',
      'year': 1543,
      'detail': 'De revolutionibus, 1543'
    },
    {
      'event': 'Newton publishes his laws of gravity in Principia Mathematica',
      'year': 1687,
      'detail': 'July 5, 1687 — foundations of classical mechanics'
    },
    {
      'event': 'American Declaration of Independence signed in Philadelphia',
      'year': 1776,
      'detail': 'July 4, 1776'
    },
    {
      'event': 'French Revolution begins: the Bastille is stormed',
      'year': 1789,
      'detail': 'July 14, 1789 — Bastille Day'
    },
    {
      'event': 'Napoleon Bonaparte defeated at the Battle of Waterloo',
      'year': 1815,
      'detail': 'June 18, 1815 — end of the Napoleonic Wars'
    },
    {
      'event': 'Darwin publishes On the Origin of Species',
      'year': 1859,
      'detail': 'November 24, 1859 — theory of evolution by natural selection'
    },
    {
      'event': 'Alexander Graham Bell patents the telephone',
      'year': 1876,
      'detail': 'March 7, 1876 — first practical voice communication device'
    },
    {
      'event':
          'Edison demonstrates the first practical incandescent light bulb',
      'year': 1879,
      'detail': 'October 21, 1879 — changes life after dark forever'
    },
    {
      'event': 'Karl Benz patents the first true petrol-powered automobile',
      'year': 1886,
      'detail': 'January 29, 1886 — the Benz Patent-Motorwagen'
    },
    {
      'event': 'First modern Olympic Games held in Athens, Greece',
      'year': 1896,
      'detail': 'April 6–15, 1896 — 14 nations compete'
    },
    {
      'event': 'Wright Brothers achieve first powered flight at Kitty Hawk',
      'year': 1903,
      'detail': 'December 17, 1903 — 12 seconds, 120 feet'
    },
    {
      'event': 'Einstein publishes the Special Theory of Relativity',
      'year': 1905,
      'detail': 'June 30, 1905 — E=mc² introduced'
    },
    // ── 1910s–1940s ───────────────────────────────────────────────────────
    {
      'event': 'RMS Titanic sinks on her maiden voyage',
      'year': 1912,
      'detail': 'April 15, 1912 — 1,517 lives lost'
    },
    {
      'event':
          'World War I begins following assassination of Archduke Franz Ferdinand',
      'year': 1914,
      'detail': 'June 28, 1914 — four years of global conflict'
    },
    {
      'event': 'Russian Revolution begins: Tsar Nicholas II abdicates',
      'year': 1917,
      'detail': 'March 15, 1917 — end of the Romanov dynasty'
    },
    {
      'event': 'Treaty of Versailles officially ends World War I',
      'year': 1919,
      'detail': 'June 28, 1919 — signed in the Hall of Mirrors'
    },
    {
      'event': 'Fleming discovers penicillin in a contaminated petri dish',
      'year': 1928,
      'detail': 'September 28, 1928 — world\'s first antibiotic'
    },
    {
      'event': 'Wall Street Crash triggers the Great Depression',
      'year': 1929,
      'detail': 'October 29, 1929 — Black Tuesday'
    },
    {
      'event':
          'Amelia Earhart becomes first woman to fly solo across the Atlantic',
      'year': 1932,
      'detail': 'May 20–21, 1932 — Harbour Grace to Londonderry'
    },
    {
      'event': 'Germany invades Poland, starting World War II',
      'year': 1939,
      'detail':
          'September 1, 1939 — two days later Britain and France declare war'
    },
    {
      'event': 'D-Day: Allied forces storm the beaches of Normandy',
      'year': 1944,
      'detail': 'June 6, 1944 — largest seaborne invasion in history'
    },
    {
      'event': 'Atomic bomb dropped on Hiroshima, Japan',
      'year': 1945,
      'detail':
          'August 6, 1945 — \'Little Boy\' kills an estimated 80,000 immediately'
    },
    // ── 1947–1970 ─────────────────────────────────────────────────────────
    {
      'event': 'India gains independence from British rule',
      'year': 1947,
      'detail': 'August 15, 1947 — Nehru\'s \'Tryst with Destiny\' speech'
    },
    {
      'event': 'State of Israel officially declared',
      'year': 1948,
      'detail': 'May 14, 1948 — proclaimed by David Ben-Gurion'
    },
    {
      'event': 'Mao Zedong proclaims the People\'s Republic of China',
      'year': 1949,
      'detail': 'October 1, 1949 — Tiananmen Square ceremony'
    },
    {
      'event': 'Korean War begins as North Korea invades South Korea',
      'year': 1950,
      'detail': 'June 25, 1950 — the "Forgotten War"'
    },
    {
      'event': 'Watson and Crick publish the double helix structure of DNA',
      'year': 1953,
      'detail': 'April 25, 1953 — in Nature magazine'
    },
    {
      'event': 'Roger Bannister runs the first sub-four-minute mile',
      'year': 1954,
      'detail': 'May 6, 1954 — 3:59.4 at Oxford'
    },
    {
      'event': 'Rosa Parks refuses to give up her bus seat in Montgomery',
      'year': 1955,
      'detail': 'December 1, 1955 — sparks the Montgomery Bus Boycott'
    },
    {
      'event':
          'Sputnik launched as the first artificial satellite in Earth orbit',
      'year': 1957,
      'detail': 'October 4, 1957 — Soviet Union beats US into space'
    },
    {
      'event': 'NASA established as the US civilian space agency',
      'year': 1958,
      'detail': 'October 1, 1958 — born out of the space race'
    },
    {
      'event': 'Yuri Gagarin becomes the first human to travel in space',
      'year': 1961,
      'detail': 'April 12, 1961 — orbit completed in 108 minutes'
    },
    {
      'event':
          'Cuban Missile Crisis: the closest the world came to nuclear war',
      'year': 1962,
      'detail': 'October 16–28, 1962 — 13 days of standoff'
    },
    {
      'event': 'President John F. Kennedy assassinated in Dallas, Texas',
      'year': 1963,
      'detail': 'November 22, 1963 — Lee Harvey Oswald charged'
    },
    {
      'event': 'Civil Rights Act signed into law in the United States',
      'year': 1964,
      'detail': 'July 2, 1964 — signed by President Lyndon Johnson'
    },
    {
      'event': 'Neil Armstrong walks on the Moon',
      'year': 1969,
      'detail': 'Apollo 11 mission, July 20, 1969'
    },
    {
      'event':
          'Apollo 13 safely returns to Earth after an oxygen tank explosion',
      'year': 1970,
      'detail': 'April 17, 1970 — "Houston, we have a problem"'
    },
    // ── 1970s–1990 ────────────────────────────────────────────────────────
    {
      'event':
          'Intel releases the 4004, the world\'s first commercial microprocessor',
      'year': 1971,
      'detail': 'November 15, 1971 — 2,300 transistors, 740 kHz'
    },
    {
      'event': 'Roe v. Wade legalises abortion in the United States',
      'year': 1973,
      'detail': 'January 22, 1973 — overturned by Dobbs ruling in 2022'
    },
    {
      'event': 'President Nixon resigns over the Watergate scandal',
      'year': 1974,
      'detail': 'August 9, 1974 — only US president to resign'
    },
    {
      'event': 'Microsoft founded by Bill Gates and Paul Allen',
      'year': 1975,
      'detail': 'April 4, 1975 — originally based in Albuquerque'
    },
    {
      'event': 'Apple Computer Company founded by Steve Jobs and Steve Wozniak',
      'year': 1976,
      'detail': 'April 1, 1976 — incorporated in the Jobs family garage'
    },
    {
      'event': 'Star Wars premieres and becomes a global cultural phenomenon',
      'year': 1977,
      'detail': 'May 25, 1977 — goes on to earn billions worldwide'
    },
    {
      'event': 'First test-tube baby, Louise Brown, born in the UK',
      'year': 1978,
      'detail': 'July 25, 1978 — pioneer of in vitro fertilisation'
    },
    {
      'event': 'Sony launches the Walkman, transforming personal music',
      'year': 1979,
      'detail': 'July 1, 1979 — music becomes truly portable'
    },
    {
      'event': 'John Lennon shot outside his New York apartment',
      'year': 1980,
      'detail': 'December 8, 1980 — killed by Mark David Chapman'
    },
    {
      'event': 'IBM launches its first personal computer',
      'year': 1981,
      'detail': 'August 12, 1981 — the IBM PC sets the standard'
    },
    {
      'event': 'Compact disc commercially launched by Sony and Philips',
      'year': 1982,
      'detail': 'October 1, 1982 — replaces vinyl and cassette over time'
    },
    {
      'event': 'Microsoft Word is released for the first time',
      'year': 1983,
      'detail': 'October 25, 1983 — for MS-DOS'
    },
    {
      'event':
          'Apple Macintosh launched with the iconic Super Bowl advertisement',
      'year': 1984,
      'detail': 'January 22, 1984 — the "1984" ad directed by Ridley Scott'
    },
    {
      'event': 'Microsoft launches Windows 1.0',
      'year': 1985,
      'detail': 'November 20, 1985 — the beginning of Windows'
    },
    {
      'event': 'Space Shuttle Challenger breaks apart 73 seconds after launch',
      'year': 1986,
      'detail': 'January 28, 1986 — all seven crew members killed'
    },
    {
      'event': 'Black Monday: global stock markets lose 20% in a single day',
      'year': 1987,
      'detail': 'October 19, 1987 — worst single-day crash in history'
    },
    {
      'event': 'Ben Johnson stripped of 100m Olympic gold medal for doping',
      'year': 1988,
      'detail': 'September 24, 1988 — Seoul Olympics scandal'
    },
    {
      'event': 'The Berlin Wall falls',
      'year': 1989,
      'detail': 'November 9, 1989'
    },
    {
      'event': 'Tim Berners-Lee proposes the World Wide Web',
      'year': 1990,
      'detail':
          'March 12, 1990 — his CERN proposal called it "vague but exciting"'
    },
    // ── 1991–2010 ─────────────────────────────────────────────────────────
    {
      'event': 'The World Wide Web becomes publicly accessible',
      'year': 1991,
      'detail': 'August 6, 1991 — first website goes live'
    },
    {
      'event': 'First SMS text message sent, reading "Merry Christmas"',
      'year': 1992,
      'detail': 'December 3, 1992 — sent by Neil Papworth'
    },
    {
      'event': 'Mosaic launches as the first widely-used graphical web browser',
      'year': 1993,
      'detail': 'January 23, 1993 — makes the internet visual'
    },
    {
      'event': 'Amazon is founded by Jeff Bezos',
      'year': 1994,
      'detail': 'Started as an online bookstore'
    },
    {
      'event': 'Windows 95 launches with the iconic Start button',
      'year': 1995,
      'detail': 'August 24, 1995 — sold 7 million copies in five weeks'
    },
    {
      'event':
          'Dolly the sheep unveiled as the first mammal cloned from an adult cell',
      'year': 1996,
      'detail': 'February 22, 1997 — announced; cloned in July 1996'
    },
    {
      'event': 'IBM\'s Deep Blue defeats world chess champion Garry Kasparov',
      'year': 1997,
      'detail':
          'May 11, 1997 — first time a computer beat a world champion in a match'
    },
    {
      'event': 'Google is founded',
      'year': 1998,
      'detail': 'Incorporated September 4, 1998'
    },
    {
      'event': 'Napster launches and transforms music piracy online',
      'year': 1999,
      'detail': 'June 1, 1999 — shut down by court order in 2001'
    },
    {
      'event': 'Y2K bug causes no disasters despite worldwide panic',
      'year': 2000,
      'detail': 'January 1, 2000 — billions spent on fixes paid off'
    },
    {
      'event': 'Wikipedia launches publicly',
      'year': 2001,
      'detail': 'January 15, 2001'
    },
    {
      'event':
          'Euro banknotes and coins enter circulation across 12 EU nations',
      'year': 2002,
      'detail': 'January 1, 2002'
    },
    {
      'event': 'Skype launches, enabling free internet voice and video calls',
      'year': 2003,
      'detail': 'August 29, 2003 — acquired by Microsoft in 2011'
    },
    {
      'event': 'Facebook launches from a Harvard dorm room',
      'year': 2004,
      'detail': 'February 4, 2004'
    },
    {
      'event': 'YouTube is founded',
      'year': 2005,
      'detail': 'First video uploaded April 23, 2005'
    },
    {
      'event': 'Twitter is founded',
      'year': 2006,
      'detail': 'First tweet by Jack Dorsey, March 21, 2006'
    },
    {
      'event': 'First iPhone is unveiled by Steve Jobs',
      'year': 2007,
      'detail': 'Macworld, January 9, 2007'
    },
    {
      'event': 'Barack Obama elected as US President',
      'year': 2008,
      'detail': 'November 4, 2008'
    },
    {
      'event':
          'Lehman Brothers collapses, triggering the global financial crisis',
      'year': 2008,
      'detail': 'September 15, 2008 — largest bankruptcy in US history'
    },
    {
      'event': 'Bitcoin is created by Satoshi Nakamoto',
      'year': 2009,
      'detail': 'Genesis block mined January 3, 2009'
    },
    {
      'event': 'Instagram launches on the App Store',
      'year': 2010,
      'detail': 'October 6, 2010'
    },
    {
      'event': 'Apple launches the iPad, creating the tablet computer market',
      'year': 2010,
      'detail': 'January 27, 2010 — unveiled by Steve Jobs'
    },
    // ── 2011–2024 ─────────────────────────────────────────────────────────
    {
      'event': 'Osama bin Laden killed by US Navy SEALs in Pakistan',
      'year': 2011,
      'detail': 'May 2, 2011 — Operation Neptune Spear'
    },
    {
      'event': 'Steve Jobs dies aged 56 after battling pancreatic cancer',
      'year': 2011,
      'detail': 'October 5, 2011 — six weeks after stepping down as Apple CEO'
    },
    {
      'event': 'Snapchat launches',
      'year': 2011,
      'detail': 'Originally called "Picaboo"'
    },
    {
      'event': 'NASA\'s Curiosity rover lands on Mars using a sky-crane system',
      'year': 2012,
      'detail': 'August 6, 2012 — Gale Crater'
    },
    {
      'event': 'Edward Snowden leaks classified NSA surveillance documents',
      'year': 2013,
      'detail': 'June 5, 2013 — triggers global privacy debate'
    },
    {
      'event': 'Facebook acquires WhatsApp for \$19 billion',
      'year': 2014,
      'detail':
          'February 19, 2014 — largest venture-backed acquisition at the time'
    },
    {
      'event': 'SpaceX lands a rocket booster for the first time',
      'year': 2015,
      'detail': 'Cape Canaveral, December 21, 2015'
    },
    {
      'event': 'Paris Agreement on climate change signed by 195 nations',
      'year': 2015,
      'detail': 'December 12, 2015 — COP21'
    },
    {
      'event': 'UK votes to leave the European Union in the Brexit referendum',
      'year': 2016,
      'detail': 'June 23, 2016 — 52% vote Leave'
    },
    {
      'event': 'Pokémon Go downloaded 100 million times in its first month',
      'year': 2016,
      'detail': 'July 2016 — augmented reality craze'
    },
    {
      'event':
          '#MeToo movement goes viral, reshaping conversations on harassment',
      'year': 2017,
      'detail': 'October 2017 — hashtag used millions of times'
    },
    {
      'event': 'TikTok launches internationally after merging with Musical.ly',
      'year': 2018,
      'detail': 'August 2018'
    },
    {
      'event': 'First ever photograph of a black hole released by astronomers',
      'year': 2019,
      'detail': 'April 10, 2019 — Event Horizon Telescope team'
    },
    {
      'event':
          'Notre-Dame Cathedral fire devastates Paris, destroying the medieval spire',
      'year': 2019,
      'detail': 'April 15, 2019'
    },
    {
      'event': 'COVID-19 declared a global pandemic',
      'year': 2020,
      'detail': 'WHO declaration, March 11, 2020'
    },
    {
      'event':
          'George Floyd\'s death sparks global Black Lives Matter protests',
      'year': 2020,
      'detail': 'May 25, 2020 — worldwide demonstrations follow'
    },
    {
      'event': 'James Webb Space Telescope launches on Christmas Day',
      'year': 2021,
      'detail': 'December 25, 2021 — most powerful space telescope ever'
    },
    {
      'event': 'Container ship Ever Given blocks the Suez Canal for six days',
      'year': 2021,
      'detail': 'March 23–29, 2021 — \$9B of trade disrupted daily'
    },
    {
      'event': 'Russia launches a full-scale military invasion of Ukraine',
      'year': 2022,
      'detail': 'February 24, 2022'
    },
    {
      'event': 'Elon Musk acquires Twitter and renames it X',
      'year': 2022,
      'detail': 'October 27, 2022'
    },
    {
      'event': 'ChatGPT launches publicly',
      'year': 2022,
      'detail': 'OpenAI, November 30, 2022'
    },
    {
      'event': 'India overtakes China as world\'s most populous country',
      'year': 2023,
      'detail': 'UN confirmed mid-2023'
    },
    {
      'event':
          'India\'s Chandrayaan-3 lands near the Moon\'s south pole — a world first',
      'year': 2023,
      'detail': 'August 23, 2023'
    },
    {
      'event':
          'Nvidia briefly becomes the world\'s most valuable publicly traded company',
      'year': 2024,
      'detail': 'June 2024 — driven by AI chip demand'
    },
    {
      'event': 'Australia bans social media for under-16s',
      'year': 2024,
      'detail': 'World-first law, late 2024'
    },
  ];
}

IconData _iconForCat(String id) {
  switch (id) {
    case 'world':
      return Icons.language_rounded;
    case 'politics':
      return Icons.account_balance_rounded;
    case 'tech':
      return Icons.memory_rounded;
    case 'business':
      return Icons.trending_up_rounded;
    case 'sports':
      return Icons.sports_soccer_rounded;
    case 'health':
      return Icons.favorite_rounded;
    case 'entertainment':
      return Icons.star_rounded;
    default:
      return Icons.article_rounded;
  }
}

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.binaygautam.briefed';
const String _playBadgeUrl =
    'https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png';

String _formatReminderTime(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final displayMinute = minute.toString().padLeft(2, '0');
  return '$displayHour:$displayMinute $period';
}

// MAIN SHELL + NAV

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _pages = const [
    TodayScreen(),
    GamesScreen(),
    BriefingScreen(),
    ProfileScreen(),
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    unawaited(ref
        .read(userProvider.notifier)
        .syncAuthProfile(AuthService.currentUser));
    final user = ref.read(userProvider);
    ref.read(newsProvider.notifier).load(
      country: user.country,
      categories: const [
        'world',
        'tech',
        'business',
        'sports',
        'entertainment'
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!kIsWeb || constraints.maxWidth < 700) {
          return _buildMobileShell(tab);
        }
        return const ResponsiveShell();
      },
    );
  }

  Widget _buildMobileShell(int tab) {
    return Scaffold(
      body: IndexedStack(index: tab, children: _pages),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF171717).withValues(alpha: 0.76)
                    : Colors.white.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent
                        .withValues(alpha: context.isDark ? 0.12 : 0.18),
                    blurRadius: 34,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: SafeArea(
                  top: false,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _NavItem(
                                icon: Icons.home_rounded,
                                label: 'Today',
                                index: 0,
                                current: tab,
                                onTap: (i) => ref
                                    .read(selectedTabProvider.notifier)
                                    .state = i),
                            _NavItem(
                                icon: Icons.sports_esports_rounded,
                                label: 'Play',
                                index: 1,
                                current: tab,
                                onTap: (i) => ref
                                    .read(selectedTabProvider.notifier)
                                    .state = i),
                            _NavItem(
                                icon: Icons.explore_rounded,
                                label: 'Explore',
                                index: 2,
                                current: tab,
                                onTap: (i) => ref
                                    .read(selectedTabProvider.notifier)
                                    .state = i),
                            _NavItem(
                                icon: Icons.person_rounded,
                                label: 'Profile',
                                index: 3,
                                current: tab,
                                onTap: (i) => ref
                                    .read(selectedTabProvider.notifier)
                                    .state = i),
                          ]))),
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width > 1100;
        final horizontalPadding = isDesktop ? 32.0 : 20.0;
        return Scaffold(
          backgroundColor: context.bgColor,
          body: Column(children: [
            WebTopNav(
              currentIndex: tab,
              onSelect: (index) =>
                  ref.read(selectedTabProvider.notifier).state = index,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  36,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: _WebShellBody(tab: tab, isDesktop: isDesktop),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _WebShellBody extends ConsumerWidget {
  final int tab;
  final bool isDesktop;

  const _WebShellBody({required this.tab, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tab == 0) return DesktopHomePage(showRightSidebar: isDesktop);
    final content = switch (tab) {
      1 => const DesktopGamesPage(),
      2 => const DesktopBriefingPage(),
      3 => const _DesktopProfilePage(),
      _ => DesktopHomePage(showRightSidebar: isDesktop),
    };
    if (isDesktop) return content;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: content),
      const SizedBox(width: 18),
      const SizedBox(width: 280, child: RightSidebar()),
    ]);
  }
}

class WebTopNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const WebTopNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      ('Briefed', 0),
      ('Daily Quiz', -1),
      ('Briefing', 1),
      ('Games', 2),
      ('Profile', 3),
    ];
    return Container(
      decoration: BoxDecoration(
        color:
            context.cardColor.withValues(alpha: context.isDark ? 0.82 : 0.86),
        border: Border(
          bottom: BorderSide(
              color:
                  Colors.white.withValues(alpha: context.isDark ? 0.04 : 0.62)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => onSelect(0),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Briefed',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: context.textColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const TextSpan(
                    text: '.',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final item in items)
                    _TopNavButton(
                      label: item.$1,
                      selected: currentIndex == item.$2,
                      onTap: () {
                        if (item.$2 == -1) {
                          Navigator.of(context).pushNamed('/quiz');
                        } else {
                          onSelect(item.$2);
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _TopNavButton(
              label: 'Download App',
              selected: false,
              filled: true,
              onTap: () => _launchUrl(_playStoreUrl),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TopNavButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool filled;
  final VoidCallback onTap;

  const _TopNavButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.accent
        : selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.transparent;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: filled
            ? Colors.white
            : selected
                ? AppColors.accent
                : context.subColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 13,
            fontWeight: FontWeight.w800),
      ),
    );
  }
}

class DesktopHomePage extends ConsumerWidget {
  final bool showRightSidebar;

  const DesktopHomePage({super.key, this.showRightSidebar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    final articles = news.articles;
    final hero = articles.isNotEmpty ? articles.first : null;
    final latest = articles.skip(1).take(10).toList();
    final main =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _DesktopHeroSection(article: hero),
      const SizedBox(height: 18),
      const WebAdPlaceholder(label: 'Homepage leaderboard ad'),
      const SizedBox(height: 22),
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 820;
        if (!wide) {
          return const Column(children: [
            QuizPanel(),
            SizedBox(height: 18),
            GamesGrid(compact: true),
          ]);
        }
        return const Flex(
          direction: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: QuizPanel()),
            SizedBox(width: 18),
            Expanded(flex: 6, child: GamesGrid()),
          ],
        );
      }),
      const SizedBox(height: 26),
      _WebSectionTitle(
        title: 'Latest Briefing',
        action: 'View briefing',
        onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
      ),
      const SizedBox(height: 12),
      NewsCardGrid(articles: latest.isEmpty ? articles : latest),
    ]);

    if (!showRightSidebar) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: main),
        const SizedBox(width: 18),
        const SizedBox(width: 280, child: RightSidebar()),
      ]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: main),
      const SizedBox(width: 24),
      const SizedBox(width: 320, child: RightSidebar()),
    ]);
  }
}

class _DesktopHeroSection extends StatelessWidget {
  final NewsArticle? article;

  const _DesktopHeroSection({required this.article});

  @override
  Widget build(BuildContext context) {
    final catColor = article == null
        ? AppColors.accent
        : AppColors.categoryColor(article!.category);
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 760;
      final image = Container(
        height: stacked ? 240 : 360,
        color: catColor.withValues(alpha: 0.12),
        child: article?.imageUrl?.isNotEmpty == true
            ? Image.network(
                article!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _HeroPlaceholder(color: catColor),
              )
            : _HeroPlaceholder(color: catColor),
      );
      final copy = Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'TODAY ON BRIEFED',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.accent,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            article?.title ?? 'Your daily news briefing, sharpened.',
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            article?.description ??
                'Catch up on the headlines, test yourself with the daily quiz, and play fast news games from one clean desktop hub.',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 17,
              height: 1.45,
              color: context.subColor,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: [
            if (article != null) CategoryTag(category: article!.category),
            _MetaPill(
              icon: Icons.schedule_rounded,
              label: article?.timeAgo ?? 'Updated daily',
            ),
            _MetaPill(
              icon: Icons.public_rounded,
              label: article?.sourceName ?? 'Briefed',
            ),
          ]),
          const SizedBox(height: 24),
          AccentButton(
            text: article == null ? 'Open Briefing' : 'Read Story',
            icon: Icons.arrow_forward_rounded,
            onTap: () {
              if (article == null) return;
              _openArticle(context, article!);
            },
          ),
        ]),
      );
      return Container(
        constraints: const BoxConstraints(minHeight: 330),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: stacked
            ? Column(children: [image, copy])
            : Row(children: [
                Expanded(flex: 5, child: image),
                Expanded(flex: 4, child: copy),
              ]),
      );
    });
  }
}

class _HeroPlaceholder extends StatelessWidget {
  final Color color;

  const _HeroPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.newspaper_rounded,
            size: 96, color: Colors.white.withValues(alpha: 0.36)),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: context.inputBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: context.hintColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.subColor,
          ),
        ),
      ]),
    );
  }
}

class WebAdPlaceholder extends StatelessWidget {
  final String label;
  final double height;

  const WebAdPlaceholder({
    super.key,
    this.label = 'Advertisement',
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class PlayStoreDownloadCard extends StatelessWidget {
  const PlayStoreDownloadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BriefedCard(
      borderRadius: 8,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.phone_android_rounded,
                color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Get the full experience on Android',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.25,
                color: context.textColor,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _launchUrl(_playStoreUrl),
          child: Image.network(
            _playBadgeUrl,
            height: 54,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'GET IT ON Google Play',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: Colors.white,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class NewsCardGrid extends StatelessWidget {
  final List<NewsArticle> articles;
  final bool includeAds;

  const NewsCardGrid({
    super.key,
    required this.articles,
    this.includeAds = false,
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const WebAdPlaceholder(label: 'Latest stories loading');
    }
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 980
          ? 3
          : constraints.maxWidth > 620
              ? 2
              : 1;
      final children = <Widget>[];
      for (var i = 0; i < articles.length; i++) {
        if (includeAds && i > 0 && i % 5 == 0) {
          children.add(const WebAdPlaceholder(
              label: 'Briefing in-feed ad', height: 110));
        }
        children.add(_WebNewsCard(article: articles[i]));
      }
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 1.65 : 0.92,
        ),
        itemBuilder: (_, i) => children[i],
      );
    });
  }
}

class _WebNewsCard extends StatelessWidget {
  final NewsArticle article;

  const _WebNewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openArticle(context, article),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Builder(builder: (context) {
            final catColor = AppColors.categoryColor(article.category);
            final hasImage =
                article.imageUrl != null && article.imageUrl!.isNotEmpty;
            final placeholder = Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    catColor.withValues(alpha: 0.76),
                    AppColors.categoryBg(article.category),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.article_rounded,
                  size: 63, color: Colors.white.withValues(alpha: 0.38)),
            );
            return hasImage
                ? Image.network(article.imageUrl!,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => placeholder)
                : placeholder;
          }),
          Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CategoryTag(category: article.category, small: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    article.timeAgo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: context.hintColor),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.28,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Source: ${article.sourceName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.subColor,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class QuizPanel extends ConsumerWidget {
  const QuizPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return QuizHeroCard(
      user: user,
      latestResult:
          user.recentResults.isEmpty ? null : user.recentResults.first,
      onStartQuiz: () => Navigator.of(context).pushNamed('/quiz'),
      onPlayRealOrFake: () => ref.read(selectedTabProvider.notifier).state = 1,
    );
  }
}

class GamesGrid extends StatelessWidget {
  final bool compact;

  const GamesGrid({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GameCard(
        gradient: const LinearGradient(
          colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.fact_check_rounded,
        title: 'Real or Fake?',
        description:
            'Can you tell a real headline from a convincing fake? 10 rounds, tap as fast as you can.',
        tag: 'QUICK PLAY',
        tagColor: AppColors.blue,
        stats: const ['10 rounds', '~60 sec'],
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const RealOrFakeGame())),
      ),
      _GameCard(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.timeline_rounded,
        title: 'Oldest to Latest',
        description:
            'Sort 4 historical events from oldest to most recent. A fast little brain workout.',
        tag: 'BRAIN TEASER',
        tagColor: AppColors.purple,
        stats: const ['4 events', '~45 sec'],
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OldestToLatestGame())),
      ),
      _GameCard(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.compare_arrows_rounded,
        title: 'Headline Match',
        description:
            'Match the brief to the right headline. Five quick questions from a 100+ item bank.',
        tag: 'MATCH',
        tagColor: AppColors.teal,
        stats: const ['5 questions', '100+ bank'],
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const HeadlineMatchGame())),
      ),
      _GameCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.travel_explore_rounded,
        title: 'Source Sleuth',
        description:
            'Read the clue and identify the most likely news desk. Five rounds, rotating daily.',
        tag: 'SLEUTH',
        tagColor: AppColors.accent,
        stats: const ['5 questions', 'Daily mix'],
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SourceSleuthGame())),
      ),
    ];
    if (compact) {
      return Column(children: [
        for (final card in cards) ...[card, const SizedBox(height: 14)],
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _WebSectionTitle(title: 'News Games'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 14),
        Expanded(child: cards[1]),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: cards[2]),
        const SizedBox(width: 14),
        Expanded(child: cards[3]),
      ]),
    ]);
  }
}

class RightSidebar extends ConsumerWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final news = ref.watch(newsProvider).articles;
    final trending = news
        .map((a) => a.category)
        .where((c) => c.trim().isNotEmpty)
        .fold<Map<String, int>>({}, (acc, cat) {
          final key = cat[0].toUpperCase() + cat.substring(1).toLowerCase();
          acc[key] = (acc[key] ?? 0) + 1;
          return acc;
        })
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SidebarCard(
        title: 'Trending Topics',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final topic in trending.take(8))
              CategoryTag(category: topic.key, small: true, showIcon: false),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _SidebarCard(
        title: 'Your Streak',
        child: Row(children: [
          _SidebarMetric(
              value: '${user.streak}',
              label: 'days',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.accent),
          const SizedBox(width: 10),
          _SidebarMetric(
              value: _fmt(user.knowledgeScore),
              label: 'pts',
              icon: Icons.bolt_rounded,
              color: AppColors.gold),
        ]),
      ),
      const SizedBox(height: 14),
      const WebAdPlaceholder(label: 'Sidebar ad', height: 250),
      const SizedBox(height: 14),
      const PlayStoreDownloadCard(),
    ]);
  }
}

class _SidebarCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SidebarCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return BriefedCard(
      borderRadius: 8,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _SidebarMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SidebarMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.display,
              height: 1.02,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: context.textColor,
            ),
          ),
          Text(label,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: context.subColor)),
        ]),
      ),
    );
  }
}

class DesktopBriefingPage extends ConsumerWidget {
  const DesktopBriefingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _WebSectionTitle(
        title: 'Briefing',
        action: 'Refresh',
        onTap: () => ref.read(newsProvider.notifier).refresh(),
      ),
      const SizedBox(height: 6),
      Text(
        'Latest headlines grouped for desktop reading.',
        style: TextStyle(
            fontFamily: AppFonts.body, fontSize: 14, color: context.subColor),
      ),
      const SizedBox(height: 18),
      if (news.isLoading)
        const WebAdPlaceholder(label: 'Loading latest briefing')
      else
        NewsCardGrid(articles: news.articles, includeAds: true),
    ]);
  }
}

class DesktopGamesPage extends StatelessWidget {
  const DesktopGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _WebSectionTitle(title: 'Games'),
      const SizedBox(height: 6),
      Text(
        'Quick news games to sharpen your mind.',
        style: TextStyle(
            fontFamily: AppFonts.body, fontSize: 14, color: context.subColor),
      ),
      const SizedBox(height: 18),
      const GamesGrid(),
      const SizedBox(height: 18),
      const WebAdPlaceholder(label: 'Games page ad'),
      const SizedBox(height: 18),
      BriefedCard(
        borderRadius: 8,
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.inputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lock_rounded, color: context.hintColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'More games coming soon',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.textColor),
              ),
              Text(
                'Flash Headlines, News Connections and more',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: context.subColor),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class _DesktopProfilePage extends StatelessWidget {
  const _DesktopProfilePage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: max(700, MediaQuery.of(context).size.height - 120),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: const ProfileScreen(),
      ),
    );
  }
}

class _WebSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _WebSectionTitle({required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.display,
            height: 1.02,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: context.textColor,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Text(
            action!,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
        ),
    ]);
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.index,
      required this.current,
      required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.current == widget.index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = on
        ? AppColors.accent
        : isDark
            ? const Color(0xFF2A1A0E)
            : const Color(0xFFF0E0D0);

    final shadowColor = on
        ? const Color(0xFFB83400)
        : isDark
            ? const Color(0xFF120804)
            : const Color(0xFFCCA882);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap(widget.index);
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        padding: EdgeInsets.fromLTRB(on ? 16 : 12, 8, on ? 16 : 12, 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 0,
              offset: Offset(0, _pressed ? 0 : 4),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            widget.icon,
            size: 22,
            color: on ? Colors.white : const Color(0xFF9C7A60),
          ),
          if (on) ...[
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Duolingo-style tab chip used in the Explore tab bar ───────────────────────

class _TabChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _pressed = false;

  Color _shadow(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * 0.58).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final sel = widget.selected;
    final isDark = context.isDark;

    final unselBg =
        isDark ? const Color(0xFF252525) : const Color(0xFFF0EEEc);
    final unselShadow =
        isDark ? const Color(0xFF111111) : const Color(0xFFCECBCA);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? c : unselBg,
            borderRadius: BorderRadius.circular(14),
            border: sel
                ? null
                : Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE0DEDD),
                    width: 1.5,
                  ),
            boxShadow: [
              BoxShadow(
                color: sel ? _shadow(c) : unselShadow,
                blurRadius: 0,
                offset: Offset(0, _pressed ? 0 : 3),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: sel ? Colors.white : context.subColor,
            ),
          ),
        ),
      ),
    );
  }
}

// SPLASH

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final user = AuthService.currentUser;
      if (user != null && StorageService.isOnboardingDone()) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.accent,
        body: Center(
            child: FadeTransition(
                opacity: _fade,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ScaleTransition(
                      scale: _scale,
                      child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10))
                              ]),
                          child: const Center(
                              child: Icon(Icons.newspaper_rounded,
                                  color: AppColors.accent, size: 42)))),
                  const SizedBox(height: 20),
                  const Text('Briefed.',
                      style: TextStyle(
                          fontFamily: AppFonts.display,
                          height: 1.02,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5)),
                  const SizedBox(height: 6),
                  Text('STAY SHARP',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 3.5)),
                ]))));
  }
}

// SIGN-IN SCREEN

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _showEmailForm = false;
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    ref.read(userProvider.notifier).syncAuthProfile(AuthService.currentUser);
    Navigator.of(context).pushReplacementNamed(
      StorageService.isOnboardingDone() ? '/home' : '/onboarding',
    );
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.signInWithGoogle();
      _navigate();
    } catch (e) {
      setState(() {
        _error = _friendly(e.toString());
        _loading = false;
      });
    }
  }

  Future<void> _emailSubmit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(
            email: _emailCtrl.text, password: _passCtrl.text);
      } else {
        await AuthService.createAccount(
            email: _emailCtrl.text,
            password: _passCtrl.text,
            name: _nameCtrl.text);
      }
      _navigate();
    } catch (e) {
      setState(() {
        _error = _friendly(e.toString());
        _loading = false;
      });
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.continueAsGuest();
      await ref.read(userProvider.notifier).resetForGuest();
      _navigate();
    } catch (e) {
      setState(() {
        _error = _friendly(e.toString());
        _loading = false;
      });
    }
  }

  String _friendly(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (raw.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection.';
    }
    if (raw.contains('cancelled') || raw.contains('canceled')) {
      return 'Sign in cancelled.';
    }
    return 'Error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // ── Branding ──────────────────────────────────────────────────────────
                    Center(
                        child: Column(children: [
                      Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accentDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: const Icon(Icons.newspaper_rounded,
                              color: Colors.white, size: 38)),
                      const SizedBox(height: 18),
                      RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: 'Briefed',
                            style: TextStyle(
                                fontFamily: AppFonts.display,
                                height: 1.02,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: context.textColor,
                                letterSpacing: -1.2)),
                        const TextSpan(
                            text: '.',
                            style: TextStyle(
                                fontFamily: AppFonts.display,
                                height: 1.02,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                                letterSpacing: -1.2)),
                      ])),
                      const SizedBox(height: 6),
                      Text('Stay sharp. Stay informed.',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              color: context.hintColor)),
                    ])),
                    const SizedBox(height: 48),

                    // ── Google ────────────────────────────────────────────────────────────
                    GestureDetector(
                      onTap: _loading ? null : _googleSignIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.border2Color)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _GoogleLogo(size: 28),
                              const SizedBox(width: 12),
                              Text('Continue with Google',
                                  style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: context.textColor)),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Email button / form ───────────────────────────────────────────────
                    if (!_showEmailForm)
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => setState(() => _showEmailForm = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.email_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('Continue with Email',
                                    style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ]),
                        ),
                      )
                    else
                      BriefedCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            // Sign In / Create Account toggle
                            Container(
                                decoration: BoxDecoration(
                                    color: context.inputBg,
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(4),
                                child: Row(children: [
                                  Expanded(
                                      child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = true),
                                          child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                  color: _isLogin
                                                      ? AppColors.accent
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text('Sign In',
                                                  style: TextStyle(
                                                      fontFamily:
                                                          AppFonts.display,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _isLogin
                                                          ? Colors.white
                                                          : context.hintColor),
                                                  textAlign:
                                                      TextAlign.center)))),
                                  Expanded(
                                      child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = false),
                                          child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                  color: !_isLogin
                                                      ? AppColors.accent
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text('Create Account',
                                                  style: TextStyle(
                                                      fontFamily:
                                                          AppFonts.display,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: !_isLogin
                                                          ? Colors.white
                                                          : context.hintColor),
                                                  textAlign:
                                                      TextAlign.center)))),
                                ])),
                            const SizedBox(height: 16),
                            if (!_isLogin) ...[
                              _field(_nameCtrl, 'Your name',
                                  Icons.person_outline_rounded),
                              const SizedBox(height: 10),
                            ],
                            _field(_emailCtrl, 'Email', Icons.email_outlined,
                                type: TextInputType.emailAddress),
                            const SizedBox(height: 10),
                            _field(_passCtrl, 'Password',
                                Icons.lock_outline_rounded,
                                obscure: true),
                            const SizedBox(height: 16),
                            AccentButton(
                                text: _isLogin ? 'Sign In' : 'Create Account',
                                onTap: _loading ? () {} : _emailSubmit),
                            const SizedBox(height: 8),
                            GestureDetector(
                                onTap: () => setState(() {
                                      _showEmailForm = false;
                                      _error = null;
                                    }),
                                child: Center(
                                    child: Text('Back',
                                        style: TextStyle(
                                            fontFamily: AppFonts.body,
                                            fontSize: 12,
                                            color: context.hintColor)))),
                          ])),

                    // ── Error ─────────────────────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.red.withValues(alpha: 0.2))),
                          child: Text(_error!,
                              style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 12,
                                  color: AppColors.red))),
                    ],

                    // ── Loading ───────────────────────────────────────────────────────────
                    if (_loading) ...[
                      const SizedBox(height: 20),
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2.5)),
                    ],

                    const SizedBox(height: 40),

                    // ── Guest ─────────────────────────────────────────────────────────────
                    Center(
                        child: GestureDetector(
                      onTap: _loading ? null : _continueAsGuest,
                      child: Text('Continue as Guest',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 13,
                              color: context.hintColor,
                              decoration: TextDecoration.underline,
                              decorationColor: context.hintColor)),
                    )),
                    const SizedBox(height: 24),
                  ]))),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: TextStyle(
          fontFamily: AppFonts.body, fontSize: 14, color: context.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: AppFonts.body, color: context.hintColor, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: context.hintColor),
        filled: true,
        fillColor: context.inputBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
// HOME SCREEN — see lib/screens/home_screen.dart
// BRIEFING SCREEN (Explore tab)

class BriefingScreen extends ConsumerStatefulWidget {
  const BriefingScreen({super.key});
  @override
  ConsumerState<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends ConsumerState<BriefingScreen>
    with TickerProviderStateMixin {
  static const _tabs = [
    'For You',
    'Politics',
    'Sports',
    'Technology',
    'Business',
    'Health',
    'Entertainment',
  ];
  late TabController _tabController;
  late PageController _pageController;
  final ScrollController _tabScroll = ScrollController();
  int _selectedTab = 0;

  static const _catOrder = [
    NewsCategory.world,
    NewsCategory.politics,
    NewsCategory.sports,
    NewsCategory.technology,
    NewsCategory.business,
    NewsCategory.health,
    NewsCategory.entertainment,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _pageController = PageController();
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabScroll.hasClients) return;
      const itemW = 110.0;
      final screenW = MediaQuery.of(context).size.width;
      final target = (_selectedTab * itemW) - (screenW / 2 - itemW / 2);
      _tabScroll.animateTo(
        target.clamp(0.0, _tabScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.dispose();
    _tabScroll.dispose();
    super.dispose();
  }

  static Color _catColor(NewsCategory cat) {
    switch (cat) {
      case NewsCategory.world:
        return const Color(0xFF2196F3);
      case NewsCategory.politics:
        return const Color(0xFF9C27B0);
      case NewsCategory.sports:
        return const Color(0xFF4CAF50);
      case NewsCategory.technology:
        return const Color(0xFF00BCD4);
      case NewsCategory.business:
        return const Color(0xFFFF9800);
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return const Color(0xFFE91E63);
    }
  }

  static IconData _catIcon(NewsCategory cat) {
    switch (cat) {
      case NewsCategory.world:
        return Icons.language_rounded;
      case NewsCategory.politics:
        return Icons.account_balance_rounded;
      case NewsCategory.sports:
        return Icons.sports_rounded;
      case NewsCategory.technology:
        return Icons.memory_rounded;
      case NewsCategory.business:
        return Icons.trending_up_rounded;
      case NewsCategory.health:
        return Icons.health_and_safety_rounded;
      case NewsCategory.entertainment:
        return Icons.theaters_rounded;
    }
  }

  List<RankedArticle> _articlesForTab(PipelineState pipeline, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _buildForYouFeed(pipeline);
      case 1:
        return _filtered(pipeline, NewsCategory.politics);
      case 2:
        return _filtered(pipeline, NewsCategory.sports);
      case 3:
        return _filtered(pipeline, NewsCategory.technology);
      case 4:
        return _filtered(pipeline, NewsCategory.business);
      case 5:
        return _filtered(pipeline, NewsCategory.health);
      case 6:
        return _filtered(pipeline, NewsCategory.entertainment);
      default:
        return [];
    }
  }

  List<RankedArticle> _filtered(PipelineState pipeline, NewsCategory cat) =>
      (pipeline.byCategory[cat] ?? [])
          .where((a) => a.sourceQualityScore >= 60)
          .take(10)
          .toList();

  List<RankedArticle> _buildForYouFeed(PipelineState pipeline) {
    final perCat = <NewsCategory, List<RankedArticle>>{};
    for (final cat in _catOrder) {
      perCat[cat] = (pipeline.byCategory[cat] ?? [])
          .where((a) => a.sourceQualityScore >= 60)
          .take(4)
          .toList();
    }
    final result = <RankedArticle>[];
    final usedPerCat = <NewsCategory, int>{for (final c in _catOrder) c: 0};
    for (int round = 0; round < 2; round++) {
      for (final cat in _catOrder) {
        if (result.length >= 10) break;
        final pool = perCat[cat]!;
        int idx = usedPerCat[cat]!;
        final fallbackIdx = idx;
        while (idx < pool.length &&
            result.isNotEmpty &&
            pool[idx].sourceDomain == result.last.sourceDomain) {
          idx++;
        }
        // If all remaining pool items share the last domain, fall back to the
        // next unused item so single-source pipelines still show articles.
        if (idx >= pool.length && fallbackIdx < pool.length) {
          idx = fallbackIdx;
        }
        if (idx < pool.length) {
          result.add(pool[idx]);
          usedPerCat[cat] = idx + 1;
        }
      }
    }
    return result;
  }

  void _selectTab(int i) {
    setState(() => _selectedTab = i);
    _tabController.animateTo(i,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    _pageController.animateToPage(i,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  Color _getTabColor(int index) {
    if (index == 0) {
      return const Color(0xFFFF5722); // For You - orange
    }
    // Map tab index to category
    final categories = [
      NewsCategory.politics,
      NewsCategory.sports,
      NewsCategory.technology,
      NewsCategory.business,
      NewsCategory.health,
      NewsCategory.entertainment,
    ];
    if (index > 0 && index <= categories.length) {
      return _catColor(categories[index - 1]);
    }
    return const Color(0xFFFF5722);
  }

  void _showArticleDetailModal(
      BuildContext context, List<RankedArticle> articles, int initialIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArticleDetailModal(
        articles: articles,
        initialIndex: initialIndex,
        onLaunchUrl: _launchUrl,
        catColor: _catColor,
        catIcon: _catIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = ref.watch(newsPipelineProvider);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore',
                    style: TextStyle(
                        fontFamily: AppFonts.display,
                        height: 1.02,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: context.textColor)),
                const SizedBox(height: 2),
                Text('Stay informed beyond the quiz',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: context.hintColor)),
                const SizedBox(height: 4),
                _RefreshStatusChip(pipeline: pipeline),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Tab row — Duolingo-style chunky chips
          SizedBox(
            height: 54,
            child: ListView.builder(
              controller: _tabScroll,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              itemCount: _tabs.length,
              itemBuilder: (context, i) => _TabChip(
                label: _tabs[i],
                selected: _selectedTab == i,
                color: _getTabColor(i),
                onTap: () => _selectTab(i),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Body
          Expanded(
            child: pipeline.isLoading && pipeline.byCategory.isEmpty
                ? const _ExploreSkeleton()
                : pipeline.error != null && pipeline.byCategory.isEmpty
                    ? _buildError(context)
                    : PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _selectedTab = index);
                          _tabController.animateTo(index,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut);
                        },
                        children: List.generate(_tabs.length, (i) {
                          final articles = _articlesForTab(pipeline, i);
                          return RefreshIndicator(
                            color: const Color(0xFFFF5722),
                            onRefresh: i == 0
                                ? () => ref
                                    .read(newsPipelineProvider.notifier)
                                    .refresh()
                                : () async => _selectTab(0),
                            child: _buildFeed(context, articles),
                          );
                        }),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFeed(BuildContext context, List<RankedArticle> articles) {
    if (articles.isEmpty) {
      return ListView(children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.newspaper_rounded, size: 48, color: context.hintColor),
              const SizedBox(height: 12),
              Text('No stories yet',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.hintColor)),
              const SizedBox(height: 8),
              Text('Pull down to refresh',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      color: context.hintColor)),
            ]),
          ),
        ),
      ]);
    }

    final weeklyGame = _weeklyExploreGame(context);
    // Build items: hero, game, banner, articles..., bottom banner
    final itemCount = articles.length + 3; // hero + game + banner + articles + bottom banner
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Bottom banner — last item
        if (index == itemCount - 1) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: BriefedBannerAd()),
          );
        }
        // Post-game banner (index 2)
        if (index == 2) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: BriefedBannerAd()),
          );
        }
        // Weekly game card (index 1)
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ExploreWeeklyGameCard(game: weeklyGame),
          );
        }
        // Articles: index 0 = hero, index 3+ = remaining articles
        final articleIndex = index == 0 ? 0 : index - 2;
        if (articleIndex >= articles.length) return const SizedBox.shrink();
        final article = articles[articleIndex];
        final color = _catColor(article.category);
        final icon = _catIcon(article.category);
        if (articleIndex == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ExploreLeadCard(
              article: article,
              catColor: color,
              catIcon: icon,
              onTap: () =>
                  _showArticleDetailModal(context, articles, articleIndex),
            ),
          );
        }
        return _ExploreStandardCard(
          article: article,
          catColor: color,
          catIcon: icon,
          showDivider: articleIndex < articles.length - 1,
          onTap: () => _showArticleDetailModal(context, articles, articleIndex),
        );
      },
    );
  }

  _GameSpec _weeklyExploreGame(BuildContext context) {
    final games = [
      _GameSpec(
        icon: Icons.fact_check_rounded,
        title: 'Real or Fake?',
        description: 'Spot the fake headline',
        tag: 'QUICK PLAY',
        color: const Color(0xFF3B5BDB),
        best: '10 rounds',
        plays: '~60 sec',
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const RealOrFakeGame())),
      ),
      _GameSpec(
        icon: Icons.timeline_rounded,
        title: 'Oldest to Latest',
        description: 'Sort events in order',
        tag: 'BRAIN',
        color: const Color(0xFF7C3AED),
        best: '4 events',
        plays: '~45 sec',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OldestToLatestGame())),
      ),
      _GameSpec(
        icon: Icons.compare_arrows_rounded,
        title: 'Headline Match',
        description: 'Pair briefs with headlines',
        tag: 'MATCH',
        color: const Color(0xFF16A34A),
        best: '5 questions',
        plays: 'Daily mix',
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const HeadlineMatchGame())),
      ),
      _GameSpec(
        icon: Icons.travel_explore_rounded,
        title: 'Source Sleuth',
        description: 'Pick the right news desk',
        tag: 'SLEUTH',
        color: const Color(0xFF0EA5E9),
        best: '5 questions',
        plays: 'Daily mix',
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SourceSleuthGame())),
      ),
    ];
    return games[GamesScreen._weeklyIndex(games.length)];
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text("Couldn't load news",
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textColor)),
          const SizedBox(height: 4),
          Text('Pull down to refresh',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: context.hintColor)),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => ref.read(newsPipelineProvider.notifier).refresh(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF5722)),
              foregroundColor: const Color(0xFFFF5722),
            ),
            child: const Text('Retry',
                style: TextStyle(
                    fontFamily: AppFonts.body, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Explore: Refresh Status Chip ─────────────────────────────────────────────

class _RefreshStatusChip extends StatefulWidget {
  final PipelineState pipeline;
  const _RefreshStatusChip({required this.pipeline});

  @override
  State<_RefreshStatusChip> createState() => _RefreshStatusChipState();
}

class _RefreshStatusChipState extends State<_RefreshStatusChip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _label() {
    if (widget.pipeline.isLoading) return 'Refreshing…';
    final at = widget.pipeline.updatedAt;
    if (at == null) return '';
    final now = DateTime.now();
    final age = now.difference(at);
    final nextRefresh = at.add(const Duration(hours: 4));
    final until = nextRefresh.difference(now);

    String ago;
    if (age.inMinutes < 1) {
      ago = 'just now';
    } else if (age.inMinutes < 60) {
      ago = '${age.inMinutes}m ago';
    } else {
      ago = '${age.inHours}h ago';
    }

    String next;
    if (until.isNegative) {
      next = 'soon';
    } else if (until.inMinutes < 1) {
      next = '< 1 min';
    } else if (until.inMinutes < 60) {
      next = '~${until.inMinutes} min';
    } else {
      next = '~${until.inHours}h';
    }

    return 'Updated $ago · next in $next';
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();
    if (label.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: context.hintColor),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      color: context.hintColor)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Explore: Lead Card ────────────────────────────────────────────────────────

class _ExploreLeadCard extends StatelessWidget {
  final RankedArticle article;
  final Color catColor;
  final IconData catIcon;
  final VoidCallback onTap;

  const _ExploreLeadCard({
    required this.article,
    required this.catColor,
    required this.catIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              context.cardColor.withValues(alpha: context.isDark ? 0.84 : 0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color:
                  Colors.white.withValues(alpha: context.isDark ? 0.06 : 0.72)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 230,
              width: double.infinity,
              child: article.imageUrl != null && article.imageUrl!.isNotEmpty
                  ? Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.accentLight, AppColors.accent]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(article.category.label,
                        style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                        height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(article.sourceName,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.subColor)),
                    Text(' · ',
                        style:
                            TextStyle(color: context.hintColor, fontSize: 12)),
                    Text(article.timeAgo,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: context.hintColor)),
                  ]),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: context.subColor,
                          height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: catColor.withValues(alpha: 0.12),
        child: Center(
            child: Icon(catIcon,
                size: 48, color: catColor.withValues(alpha: 0.35))),
      );
}

// ── Explore: Standard Card ────────────────────────────────────────────────────

class _ExploreStandardCard extends StatelessWidget {
  final RankedArticle article;
  final Color catColor;
  final IconData catIcon;
  final bool showDivider;
  final VoidCallback onTap;

  const _ExploreStandardCard({
    required this.article,
    required this.catColor,
    required this.catIcon,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child:
                      article.imageUrl != null && article.imageUrl!.isNotEmpty
                          ? Image.network(
                              article.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumb(),
                            )
                          : _thumb(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(article.category.label,
                          style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                          height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Flexible(
                        child: Text(
                          article.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 11,
                              color: context.hintColor),
                        ),
                      ),
                      Text(' · ',
                          style: TextStyle(
                              color: context.hintColor, fontSize: 11)),
                      Text(article.timeAgo,
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 11,
                              color: context.hintColor)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (showDivider) Divider(height: 1, color: context.borderColor),
    ]);
  }

  Widget _thumb() => Container(
        color: catColor.withValues(alpha: 0.15),
        child: Center(
            child: Icon(catIcon,
                size: 32, color: catColor.withValues(alpha: 0.35))),
      );
}

class _ExploreWeeklyGameCard extends StatelessWidget {
  final _GameSpec game;

  const _ExploreWeeklyGameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final surface = context.isDark ? const Color(0xFF27170E) : Colors.white;
    return GestureDetector(
      onTap: game.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent
                  .withValues(alpha: context.isDark ? 0.10 : 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: game.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(game.icon, color: game.color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FEATURED GAME',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: game.color,
                      letterSpacing: 1.0)),
              const SizedBox(height: 3),
              Text(game.title,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: context.textColor,
                      letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text('${game.description} · ${game.plays}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.hintColor)),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: game.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: game.color.withValues(alpha: 0.30),
                  blurRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 20),
          ),
        ]),
      ),
    );
  }
}

// ── Article Detail Modal ──────────────────────────────────────────────────────

class _ArticleDetailModal extends StatefulWidget {
  final List<RankedArticle> articles;
  final int initialIndex;
  final Future<void> Function(String) onLaunchUrl;
  final Color Function(NewsCategory) catColor;
  final IconData Function(NewsCategory) catIcon;

  const _ArticleDetailModal({
    required this.articles,
    required this.initialIndex,
    required this.onLaunchUrl,
    required this.catColor,
    required this.catIcon,
  });

  @override
  State<_ArticleDetailModal> createState() => _ArticleDetailModalState();
}

class _ArticleDetailModalState extends State<_ArticleDetailModal> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final selectedArticle = widget.articles[_selectedIndex];
    final catColor = widget.catColor(selectedArticle.category);
    final catIcon = widget.catIcon(selectedArticle.category);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom +
        24;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border(bottom: BorderSide(color: catColor, width: 3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      selectedArticle.effectiveImageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: catColor.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(catIcon,
                              size: 48,
                              color: catColor.withValues(alpha: 0.35)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              selectedArticle.category.label.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: catColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedArticle.timeAgo,
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 11,
                                color: context.hintColor),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              selectedArticle.sourceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.subColor),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Text(
                          selectedArticle.title,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                            height: 1.35,
                          ),
                        ),
                        if (selectedArticle.summary.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            selectedArticle.summary,
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                color: context.subColor,
                                height: 1.65),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AccentButton(
              text: 'Read Full Article',
              icon: Icons.open_in_new_rounded,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: () => widget.onLaunchUrl(selectedArticle.url),
            ),
            if (widget.articles.length > 1) ...[
              const SizedBox(height: 16),
              Text(
                'More from ${selectedArticle.category.label}',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textColor),
              ),
              const SizedBox(height: 12),
              ...widget.articles.asMap().entries.where((entry) {
                return entry.key != _selectedIndex;
              }).map((entry) {
                final idx = entry.key;
                final article = entry.value;
                final color = widget.catColor(article.category);
                final icon = widget.catIcon(article.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = idx),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            article.effectiveImageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(icon,
                                    size: 24,
                                    color: color.withValues(alpha: 0.35)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.textColor,
                                    height: 1.35),
                              ),
                              const SizedBox(height: 6),
                              Row(children: [
                                Flexible(
                                  child: Text(
                                    article.sourceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: context.subColor),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '• ${article.timeAgo}',
                                  style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 10,
                                      color: context.hintColor),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Explore: Skeleton ─────────────────────────────────────────────────────────

class _ExploreSkeleton extends StatefulWidget {
  const _ExploreSkeleton();
  @override
  State<_ExploreSkeleton> createState() => _ExploreSkeletonState();
}

class _ExploreSkeletonState extends State<_ExploreSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        itemCount: 3,
        itemBuilder: (context, index) => Opacity(
          opacity: _opacity.value,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: index == 0 ? 320 : 88,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  const _NewsBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFD32F2F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

// ── NEW NEWS CARD (pipeline articles) ────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final RankedArticle article;
  final VoidCallback? onTap;
  const _NewsCard({required this.article, this.onTap});

  Color _catColor() {
    switch (article.category) {
      case NewsCategory.world:
        return AppColors.blue;
      case NewsCategory.politics:
        return AppColors.purple;
      case NewsCategory.sports:
        return AppColors.green;
      case NewsCategory.technology:
        return AppColors.teal;
      case NewsCategory.business:
        return AppColors.orange;
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return AppColors.pink;
    }
  }

  IconData _catIcon() {
    switch (article.category) {
      case NewsCategory.world:
        return Icons.language_rounded;
      case NewsCategory.politics:
        return Icons.account_balance_rounded;
      case NewsCategory.sports:
        return Icons.sports_rounded;
      case NewsCategory.technology:
        return Icons.memory_rounded;
      case NewsCategory.business:
        return Icons.trending_up_rounded;
      case NewsCategory.health:
        return Icons.health_and_safety_rounded;
      case NewsCategory.entertainment:
        return Icons.theaters_rounded;
    }
  }

  Color _sourceColor(BuildContext ctx) {
    if (article.sourceQualityScore >= 100) return ctx.textColor;
    if (article.sourceQualityScore >= 80) {
      return ctx.textColor.withValues(alpha: 0.82);
    }
    if (article.sourceQualityScore >= 60) return ctx.subColor;
    return ctx.hintColor;
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 16:9 image — effectiveImageUrl always provides a URL
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              article.effectiveImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => _placeholder(catColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(
                  article.sourceName,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _sourceColor(context),
                  ),
                ),
                const SizedBox(width: 5),
                Text('·',
                    style: TextStyle(color: context.hintColor, fontSize: 10)),
                const SizedBox(width: 5),
                Text(article.timeAgo,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        color: context.hintColor)),
              ]),
              const SizedBox(height: 8),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: catColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_catIcon(), size: 11, color: catColor),
                    const SizedBox(width: 4),
                    Text(
                      article.category.label,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: catColor,
                      ),
                    ),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      Share.share('${article.title}\n\n${article.url}'),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.inputBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.share_rounded,
                        color: context.hintColor, size: 16),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder(Color catColor) => Container(
        width: double.infinity,
        color: catColor.withValues(alpha: 0.15),
        child: Center(
          child: Icon(_catIcon(),
              size: 48, color: catColor.withValues(alpha: 0.35)),
        ),
      );
}

// ── RANKED ARTICLE BOTTOM SHEET ──────────────────────────────────────────────

void _openRankedArticle(BuildContext ctx, RankedArticle article) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RankedArticleSheet(article: article),
  );
}

class _RankedArticleSheet extends StatelessWidget {
  final RankedArticle article;
  const _RankedArticleSheet({required this.article});

  @override
  Widget build(BuildContext context) {
    final hasLink = article.url.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(children: [
            _CategoryChip(article.category),
            const SizedBox(width: 8),
            Text(article.timeAgo,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    color: context.hintColor)),
            const Spacer(),
            Flexible(
              child: Text(
                article.sourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.subColor,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(article.title,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textColor,
                height: 1.35,
              )),
          if (article.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(article.summary,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: context.subColor,
                    height: 1.65)),
          ],
          const SizedBox(height: 20),
          Row(children: [
            GestureDetector(
              onTap: () => Share.share('${article.title}\n\n${article.url}'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  color: context.inputBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.share_rounded, size: 16, color: context.subColor),
                  const SizedBox(width: 6),
                  Text('Share',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.subColor,
                      )),
                ]),
              ),
            ),
            if (hasLink) ...[
              const SizedBox(width: 10),
              Expanded(
                child: AccentButton(
                  text: 'Read Full Story',
                  icon: Icons.open_in_new_rounded,
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onTap: () => _launchUrl(article.url),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final NewsCategory cat;
  const _CategoryChip(this.cat);

  Color _color() {
    switch (cat) {
      case NewsCategory.world:
        return AppColors.blue;
      case NewsCategory.politics:
        return AppColors.purple;
      case NewsCategory.sports:
        return AppColors.green;
      case NewsCategory.technology:
        return AppColors.teal;
      case NewsCategory.business:
        return AppColors.orange;
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return AppColors.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        cat.label,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: c,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

void _openArticle(BuildContext ctx, NewsArticle article) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ArticleSheet(article: article),
  );
}

Future<void> _launchUrl(String link) async {
  final uri = Uri.tryParse(link);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ArticleSheet extends StatelessWidget {
  final NewsArticle article;
  const _ArticleSheet({required this.article});

  @override
  Widget build(BuildContext context) {
    final hasLink = article.link.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            CategoryTag(category: article.category, small: true),
            const SizedBox(width: 8),
            Text(article.timeAgo,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    color: context.hintColor)),
            const Spacer(),
            Flexible(
                child: Text('Source: ${article.sourceName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.subColor))),
          ]),
          const SizedBox(height: 12),
          Text(article.title,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                  height: 1.35)),
          if (article.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(article.description,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: context.subColor,
                    height: 1.65)),
          ],
          const SizedBox(height: 20),
          Row(children: [
            GestureDetector(
              onTap: () => Share.share('${article.title}\n\n${article.link}'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                    color: context.inputBg,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.share_rounded, size: 16, color: context.subColor),
                  const SizedBox(width: 6),
                  Text('Share',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.subColor)),
                ]),
              ),
            ),
            if (hasLink) ...[
              const SizedBox(width: 10),
              Expanded(
                  child: AccentButton(
                text: 'Read Full Story',
                icon: Icons.open_in_new_rounded,
                fontSize: 13,
                padding: const EdgeInsets.symmetric(vertical: 13),
                onTap: () => _launchUrl(article.link),
              )),
            ],
          ]),
        ],
      ),
    );
  }
}

class _QuizPromoStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final played = user.hasPlayedToday;

    void onTap() {
      if (!played) {
        Navigator.of(context).pushNamed('/quiz');
      } else {
        // Quiz already played — switch to Home tab where the full quiz card is shown
        ref.read(selectedTabProvider.notifier).state = 0;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Test your knowledge',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  Text(
                      played
                          ? 'Come back tomorrow for a fresh quiz'
                          : '5 questions from today\'s top stories',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          color: context.subColor)),
                ])),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ]),
                child: Text(played ? 'View' : 'Start Quiz',
                    style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white))),
          ])),
    );
  }
}

// GAMES SCREEN

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  List<_GameSpec> _games(BuildContext context) => [
        _GameSpec(
          icon: Icons.fact_check_rounded,
          title: 'Real or Fake?',
          description:
              'Spot a real headline from a convincing fake. 10 rapid rounds.',
          tag: 'QUICK PLAY',
          color: const Color(0xFF3B5BDB),
          best: '10 rounds',
          plays: '~60 sec',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const RealOrFakeGame())),
        ),
        _GameSpec(
          icon: Icons.timeline_rounded,
          title: 'Oldest to Latest',
          description: 'Sort historical events from oldest to newest.',
          tag: 'BRAIN',
          color: const Color(0xFF7C3AED),
          best: '4 events',
          plays: '~45 sec',
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OldestToLatestGame())),
        ),
        _GameSpec(
          icon: Icons.compare_arrows_rounded,
          title: 'Headline Match',
          description: 'Match each brief to the correct headline.',
          tag: 'MATCH',
          color: const Color(0xFF16A34A),
          best: '5/5',
          plays: 'Daily mix',
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HeadlineMatchGame())),
        ),
        _GameSpec(
          icon: Icons.travel_explore_rounded,
          title: 'Source Sleuth',
          description: 'Pick the most likely news desk from the clue.',
          tag: 'SLEUTH',
          color: const Color(0xFF0EA5E9),
          best: '5 questions',
          plays: 'Daily mix',
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SourceSleuthGame())),
        ),
      ];

  static int _weeklyIndex(int length) {
    if (length == 0) return 0;
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return now.difference(start).inDays ~/ 7 % length;
  }

  @override
  Widget build(BuildContext context) {
    final games = _games(context);
    final featured = games[_weeklyIndex(games.length)];
    final bg =
        context.isDark ? const Color(0xFF1A0F08) : const Color(0xFFFFF1E2);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Games',
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: context.textColor,
                      letterSpacing: -0.6)),
              const SizedBox(width: 8),
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.accent, size: 27),
            ]),
            const SizedBox(height: 4),
            Text('Quick news games to sharpen your mind',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.subColor)),
            const SizedBox(height: 16),
            _FeaturedGameHero(game: featured),
            const SizedBox(height: 16),
            const Center(child: BriefedBannerAd()),
            const SizedBox(height: 22),
            const _BriefedSectionHeader(title: 'All games'),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: games.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, i) => _GameTile(game: games[i]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _GameSpec {
  final IconData icon;
  final String title;
  final String description;
  final String tag;
  final Color color;
  final String best;
  final String plays;
  final VoidCallback onTap;

  const _GameSpec({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    required this.color,
    required this.best,
    required this.plays,
    required this.onTap,
  });
}

class _BriefedSectionHeader extends StatelessWidget {
  final String title;

  const _BriefedSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title,
          style: TextStyle(
              fontFamily: AppFonts.display,
              height: 1.02,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: context.textColor,
              letterSpacing: -0.4)),
    ]);
  }
}

class _FeaturedGameHero extends StatelessWidget {
  final _GameSpec game;

  const _FeaturedGameHero({required this.game});

  @override
  Widget build(BuildContext context) {
    final shadowColor =
        game.color.withValues(alpha: context.isDark ? 0.26 : 0.42);
    return GestureDetector(
      onTap: game.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [game.color, const Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: 0.95),
              blurRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: shadowColor,
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(children: [
          Positioned(
            right: -34,
            bottom: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('FEATURED THIS WEEK',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8)),
              ),
              const Spacer(),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(game.icon, color: Colors.white, size: 26),
              ),
            ]),
            const SizedBox(height: 14),
            Text(game.title,
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.7)),
            const SizedBox(height: 6),
            Text(game.description,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 0,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.play_arrow_rounded, color: game.color, size: 18),
                    const SizedBox(width: 6),
                    Text('Play now',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: game.color)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('BEST',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.70))),
                Text(game.best,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        height: 1.02,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ]),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final _GameSpec game;

  const _GameTile({required this.game});

  @override
  Widget build(BuildContext context) {
    final surface = context.isDark ? const Color(0xFF27170E) : Colors.white;
    final line =
        context.isDark ? const Color(0xFF3A2516) : const Color(0xFFF4E2CE);
    return GestureDetector(
      onTap: game.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.16 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: game.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(game.icon, color: game.color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(game.tag,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: game.color,
                  letterSpacing: 1.0)),
          const SizedBox(height: 3),
          Text(game.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: context.textColor,
                  height: 1.15,
                  letterSpacing: -0.2)),
          const Spacer(),
          Container(height: 1, color: line),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(
              child: Text(game.plays,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      color: context.hintColor)),
            ),
            Text(game.best,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: game.color)),
          ]),
        ]),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title, description, tag;
  final Color tagColor;
  final List<String> stats;
  final VoidCallback onTap;
  const _GameCard(
      {required this.gradient,
      required this.icon,
      required this.title,
      required this.description,
      required this.tag,
      required this.tagColor,
      required this.stats,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final cardGradient = LinearGradient(
      colors: dark
          ? const [
              Color(0xFF5A210E),
              Color(0xFF32140A),
              Color(0xFF1D0D08),
            ]
          : const [
              Color(0xFFFFB27C),
              Color(0xFFFF6B2C),
              Color(0xFFD84315),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(
                gradient: cardGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: (dark ? const Color(0xFFB84A1C) : AppColors.accent)
                          .withValues(alpha: dark ? 0.18 : 0.24),
                      blurRadius: dark ? 24 : 32,
                      offset: const Offset(0, 14))
                ]),
            padding: const EdgeInsets.all(22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18)),
                    child: Icon(icon, color: Colors.white, size: 26)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(tag,
                          style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5))),
                  const SizedBox(height: 4),
                  Text(title,
                      style: const TextStyle(
                          fontFamily: AppFonts.display,
                          height: 1.02,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                ]),
              ]),
              const SizedBox(height: 14),
              Text(description,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.55)),
              const SizedBox(height: 16),
              Row(children: [
                ...stats.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(s,
                            style: const TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))))),
                const Spacer(),
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: dark ? const Color(0xFFFFD8C2) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.accent, size: 20)),
              ]),
            ])));
  }
}

// REAL OR FAKE GAME

class RealOrFakeGame extends StatefulWidget {
  const RealOrFakeGame({super.key});
  @override
  State<RealOrFakeGame> createState() => _RealOrFakeGameState();
}

class _RealOrFakeGameState extends State<RealOrFakeGame>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _deck;
  int _index = 0, _score = 0;
  String? _tapped;
  bool _finished = false;
  bool _resultSaved = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  static const int _rounds = 10;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));
    _buildDeck();
  }

  void _buildDeck() {
    final all = List<Map<String, dynamic>>.from(_RealOrFakeData.headlines)
      ..shuffle();
    _deck = all.take(_rounds).toList();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _answer(bool guessedReal) {
    if (_tapped != null) return;
    final isReal = _deck[_index]['isReal'] as bool;
    final correct = guessedReal == isReal;
    setState(() {
      _tapped = guessedReal ? 'real' : 'fake';
      if (correct) _score++;
    });
    if (!correct) _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      if (_index + 1 >= _rounds) {
        _saveGameResult();
        await StorageService.incrementGamePlaysToday('real_or_fake');
        if (!mounted) return;
        if (StorageService.getGamePlaysToday('real_or_fake') >= 2) {
          AdService.showInterstitial(then: () {
            if (mounted) setState(() => _finished = true);
          });
        } else {
          setState(() => _finished = true);
        }
      } else {
        setState(() {
          _index++;
          _tapped = null;
        });
      }
    });
  }

  Future<void> _saveGameResult() async {
    if (_resultSaved) return;
    _resultSaved = true;
    final xp = _score * 10;
    await XpService.addXp(xp);
    await GameResultsService.saveResult(GameResult(
      gameId: 'real_or_fake',
      gameName: 'Real or Fake?',
      score: _score,
      total: _rounds,
      xpEarned: xp,
      playedAt: DateTime.now(),
    ));
  }

  void _restart() {
    _buildDeck();
    setState(() {
      _index = 0;
      _score = 0;
      _tapped = null;
      _finished = false;
      _resultSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
            title: const Text('Real or Fake?',
                style: TextStyle(
                    fontFamily: AppFonts.body, fontWeight: FontWeight.w800)),
            centerTitle: true,
            leading: BackButton(color: context.subColor),
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                      child: Text('${_index + 1}/$_rounds',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.subColor))))
            ]),
        body: _finished ? _buildResult() : _buildGame());
  }

  Widget _buildGame() {
    final item = _deck[_index];
    final isReal = item['isReal'] as bool;
    final headline = item['headline'] as String;
    final explanation = item['explanation'] as String;
    final answered = _tapped != null;
    final correct = _tapped == (isReal ? 'real' : 'fake');
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: _index / _rounds,
                  minHeight: 4,
                  backgroundColor: context.inputBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.blue))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Round ${_index + 1} of $_rounds',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    color: context.hintColor)),
            Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.green, size: 14),
              const SizedBox(width: 4),
              Text('$_score correct',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.subColor))
            ]),
          ]),
          const SizedBox(height: 10),
          const Center(child: BriefedBannerAd()),
          const Spacer(),
          AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final shake = sin(_shakeAnim.value * pi * 6) * 8;
                return Transform.translate(
                    offset: Offset(answered && !correct ? shake : 0, 0),
                    child: child);
              },
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: answered
                          ? (correct
                              ? AppColors.green.withValues(alpha: 0.1)
                              : AppColors.red.withValues(alpha: 0.1))
                          : AppColors.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: answered
                              ? (correct
                                  ? AppColors.green.withValues(alpha: 0.4)
                                  : AppColors.red.withValues(alpha: 0.4))
                              : AppColors.blue.withValues(alpha: 0.25),
                          width: answered ? 2 : 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withValues(alpha: context.isDark ? 0.2 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('HEADLINE',
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue,
                                letterSpacing: 2))),
                    const SizedBox(height: 16),
                    Text(headline,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                            height: 1.5,
                            letterSpacing: -0.3),
                        textAlign: TextAlign.center),
                    if (answered) ...[
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: (correct ? AppColors.green : AppColors.red)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                    correct
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: correct
                                        ? AppColors.green
                                        : AppColors.red,
                                    size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          correct
                                              ? 'Correct!'
                                              : 'This headline is ${isReal ? "REAL" : "FAKE"}',
                                          style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: correct
                                                  ? AppColors.green
                                                  : AppColors.red)),
                                      const SizedBox(height: 3),
                                      Text(explanation,
                                          style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 11,
                                              color: context.subColor,
                                              height: 1.5)),
                                    ])),
                              ])),
                    ],
                  ]))),
          const Spacer(),
          if (!answered)
            Text('Is this headline real or fake?',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: context.hintColor)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _VoteBtn(
                    label: 'REAL',
                    icon: Icons.check_rounded,
                    color: AppColors.green,
                    state: answered
                        ? (_tapped == 'real'
                            ? (isReal ? 'correct' : 'wrong')
                            : (isReal ? 'reveal' : 'dim'))
                        : 'idle',
                    onTap: () => _answer(true))),
            const SizedBox(width: 12),
            Expanded(
                child: _VoteBtn(
                    label: 'FAKE',
                    icon: Icons.close_rounded,
                    color: AppColors.red,
                    state: answered
                        ? (_tapped == 'fake'
                            ? (!isReal ? 'correct' : 'wrong')
                            : (!isReal ? 'reveal' : 'dim'))
                        : 'idle',
                    onTap: () => _answer(false))),
          ]),
          const SizedBox(height: 8),
        ]));
  }

  Widget _buildResult() {
    final pct = (_score / _rounds * 100).round();
    final emoji = _score >= 9
        ? '🏆'
        : _score >= 7
            ? '🔥'
            : _score >= 5
                ? '👏'
                : '💪';
    final label = _score >= 9
        ? 'Unbeatable!'
        : _score >= 7
            ? 'Sharp Eye!'
            : _score >= 5
                ? 'Not Bad!'
                : 'Keep Practising';
    final color = _score >= 7
        ? AppColors.green
        : _score >= 5
            ? AppColors.gold
            : AppColors.orange;
    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          Text(emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 10),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          RichText(
              text: TextSpan(children: [
            TextSpan(
                text: '$_score',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    foreground: Paint()
                      ..shader = LinearGradient(
                              colors: [color, color.withValues(alpha: 0.6)])
                          .createShader(const Rect.fromLTWH(0, 0, 100, 100)))),
            TextSpan(
                text: '/$_rounds',
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: 0.7))),
          ])),
          const SizedBox(height: 6),
          Text('$pct% correct',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: context.subColor)),
          const Spacer(),
          const Center(child: BriefedBannerAd()),
          const SizedBox(height: 12),
          AccentButton(
              text: 'Play Again', onTap: _restart, icon: Icons.refresh_rounded),
          const SizedBox(height: 10),
          OutlineButton(
              text: 'Share Score',
              onTap: () => Share.share(
                  'I scored $_score/$_rounds on Real or Fake? on Briefed! $emoji\n#Briefed #RealOrFake'),
              icon: Icons.share_rounded),
          const SizedBox(height: 10),
          OutlineButton(text: 'Back', onTap: () => Navigator.of(context).pop()),
        ]));
  }
}

class _VoteBtn extends StatelessWidget {
  final String label, state;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _VoteBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.state,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isCorrect = state == 'correct';
    final isWrong = state == 'wrong';
    final isReveal = state == 'reveal';
    final isDim = state == 'dim';
    final isIdle = state == 'idle';
    Color bg = context.cardColor;
    Color border = context.border2Color;
    Color tc = context.subColor;
    double op = 1.0;
    if (isCorrect) {
      bg = color.withValues(alpha: 0.12);
      border = color.withValues(alpha: 0.5);
      tc = color;
    } else if (isWrong) {
      bg = AppColors.red.withValues(alpha: 0.1);
      border = AppColors.red.withValues(alpha: 0.4);
      tc = AppColors.red;
    } else if (isReveal) {
      bg = color.withValues(alpha: 0.06);
      border = color.withValues(alpha: 0.25);
      tc = color;
    } else if (isDim) {
      op = 0.35;
    }
    return GestureDetector(
        onTap: isIdle ? onTap : null,
        child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: op,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: border, width: isCorrect || isWrong ? 2 : 1),
                    boxShadow: isIdle
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: context.isDark ? 0.15 : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : []),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : isWrong
                              ? Icons.cancel_rounded
                              : icon,
                      color: tc,
                      size: 28),
                  const SizedBox(height: 8),
                  Text(label,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: tc)),
                ]))));
  }
}

// OLDEST TO LATEST GAME

class OldestToLatestGame extends StatefulWidget {
  const OldestToLatestGame({super.key});
  @override
  State<OldestToLatestGame> createState() => _OldestToLatestGameState();
}

class _OldestToLatestGameState extends State<OldestToLatestGame> {
  late List<Map<String, dynamic>> _round, _order;
  bool _submitted = false, _finished = false;
  bool _resultSaved = false;
  int _score = 0, _roundNum = 1;
  static const int _totalRounds = 5;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final all = List<Map<String, dynamic>>.from(_OldestToLatestData.events)
      ..shuffle();
    _round = all.take(4).toList();
    _order = List.from(_round)..shuffle();
    _submitted = false;
  }

  List<Map<String, dynamic>> get _correctOrder => List.from(_round)
    ..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));
  bool get _isCorrect {
    final c = _correctOrder;
    for (int i = 0; i < _order.length; i++) {
      if (_order[i]['year'] != c[i]['year']) return false;
    }
    return true;
  }

  void _submit() {
    setState(() {
      _submitted = true;
      if (_isCorrect) _score++;
    });
  }

  Future<void> _saveGameResult() async {
    if (_resultSaved) return;
    _resultSaved = true;
    final xp = _score * 25;
    await XpService.addXp(xp);
    await GameResultsService.saveResult(GameResult(
      gameId: 'oldest_to_latest',
      gameName: 'Oldest to Latest',
      score: _score,
      total: _totalRounds,
      xpEarned: xp,
      playedAt: DateTime.now(),
    ));
  }

  Future<void> _next() async {
    if (_roundNum >= _totalRounds) {
      _saveGameResult();
      await StorageService.incrementGamePlaysToday('oldest_to_latest');
      if (!mounted) return;
      if (StorageService.getGamePlaysToday('oldest_to_latest') >= 2) {
        AdService.showInterstitial(then: () {
          if (mounted) setState(() => _finished = true);
        });
      } else {
        setState(() => _finished = true);
      }
    } else {
      setState(() {
        _roundNum++;
        _newRound();
      });
    }
  }

  void _restart() {
    setState(() {
      _score = 0;
      _roundNum = 1;
      _finished = false;
      _resultSaved = false;
      _newRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
            title: const Text('Oldest to Latest',
                style: TextStyle(
                    fontFamily: AppFonts.body, fontWeight: FontWeight.w800)),
            centerTitle: true,
            leading: BackButton(color: context.subColor),
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                      child: Text('$_roundNum/$_totalRounds',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.subColor))))
            ]),
        body: _finished ? _buildResult() : _buildGame());
  }

  Widget _buildGame() {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: (_roundNum - 1) / _totalRounds,
                  minHeight: 4,
                  backgroundColor: context.inputBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.purple))),
          const SizedBox(height: 16),
          Text('Round $_roundNum of $_totalRounds',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 10,
                  color: context.hintColor)),
          const SizedBox(height: 4),
          Text(
              _submitted
                  ? (_isCorrect
                      ? 'Correct order! 🎉'
                      : 'Not quite — here\'s the right order:')
                  : 'Sort oldest → most recent',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _submitted
                      ? (_isCorrect ? AppColors.green : AppColors.red)
                      : context.textColor)),
          if (!_submitted) ...[
            const SizedBox(height: 4),
            Text('Drag to reorder the events by when they happened',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: context.subColor))
          ],
          const SizedBox(height: 12),
          const Center(child: BriefedBannerAd()),
          const SizedBox(height: 12),
          Expanded(
              child: _submitted
                  ? _buildReveal()
                  : ReorderableListView.builder(
                      itemCount: _order.length,
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (newIdx > oldIdx) newIdx--;
                          final item = _order.removeAt(oldIdx);
                          _order.insert(newIdx, item);
                        });
                      },
                      itemBuilder: (context, i) => ReorderableDragStartListener(
                          key: ValueKey(_order[i]['event']),
                          index: i,
                          child: _EventCard(
                              key: ValueKey('card_${_order[i]['event']}'),
                              index: i,
                              event: _order[i]['event'] as String,
                              showYear: false,
                              color: AppColors.purple)),
                      proxyDecorator: (child, index, animation) =>
                          Material(color: Colors.transparent, child: child))),
          const SizedBox(height: 16),
          if (!_submitted)
            AccentButton(
                text: 'Submit Order', onTap: _submit, icon: Icons.check_rounded)
          else
            AccentButton(
                text: _roundNum >= _totalRounds ? 'See Results' : 'Next Round',
                onTap: _next,
                icon: Icons.arrow_forward_rounded),
        ]));
  }

  Widget _buildReveal() {
    final correct = _correctOrder;
    return ListView.builder(
        itemCount: 4,
        itemBuilder: (context, i) {
          final correctEvent = correct[i];
          final isRight = _order[i]['year'] == correctEvent['year'];
          return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventCard(
                  key: ValueKey('reveal_$i'),
                  index: i,
                  event: correctEvent['event'] as String,
                  year: correctEvent['year'] as int,
                  detail: correctEvent['detail'] as String,
                  showYear: true,
                  color: isRight ? AppColors.green : AppColors.red,
                  isCorrect: isRight));
        });
  }

  Widget _buildResult() {
    final pct = (_score / _totalRounds * 100).round();
    final emoji = _score >= 5
        ? '🏆'
        : _score >= 4
            ? '🔥'
            : _score >= 3
                ? '👏'
                : '💪';
    final label = _score >= 5
        ? 'History Expert!'
        : _score >= 3
            ? 'Sharp Mind!'
            : 'Keep Learning!';
    final color = _score >= 4
        ? AppColors.green
        : _score >= 3
            ? AppColors.gold
            : AppColors.orange;
    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          Text(emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 10),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          RichText(
              text: TextSpan(children: [
            TextSpan(
                text: '$_score',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    foreground: Paint()
                      ..shader = LinearGradient(
                              colors: [color, color.withValues(alpha: 0.6)])
                          .createShader(const Rect.fromLTWH(0, 0, 100, 100)))),
            TextSpan(
                text: '/$_totalRounds',
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: 0.7))),
          ])),
          const SizedBox(height: 6),
          Text('$pct% rounds correct',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: context.subColor)),
          const Spacer(),
          const Center(child: BriefedBannerAd()),
          const SizedBox(height: 12),
          AccentButton(
              text: 'Play Again', onTap: _restart, icon: Icons.refresh_rounded),
          const SizedBox(height: 10),
          OutlineButton(
              text: 'Share Score',
              onTap: () => Share.share(
                  'I scored $_score/$_totalRounds on Oldest to Latest on Briefed! $emoji\n#Briefed #NewsQuiz'),
              icon: Icons.share_rounded),
          const SizedBox(height: 10),
          OutlineButton(text: 'Back', onTap: () => Navigator.of(context).pop()),
        ]));
  }
}

class _EventCard extends StatelessWidget {
  final int index;
  final String event;
  final int? year;
  final String? detail;
  final bool showYear;
  final Color color;
  final bool? isCorrect;
  const _EventCard(
      {super.key,
      required this.index,
      required this.event,
      required this.showYear,
      required this.color,
      this.year,
      this.detail,
      this.isCorrect});
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: isCorrect == null
                ? (!showYear
                    ? color.withValues(alpha: 0.06)
                    : context.cardColor)
                : (isCorrect!
                    ? AppColors.green.withValues(alpha: 0.08)
                    : AppColors.red.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isCorrect == null
                    ? (!showYear
                        ? color.withValues(alpha: 0.25)
                        : context.border2Color)
                    : (isCorrect!
                        ? AppColors.green.withValues(alpha: 0.4)
                        : AppColors.red.withValues(alpha: 0.4))),
            boxShadow: [
              BoxShadow(
                  color: Colors.black
                      .withValues(alpha: context.isDark ? 0.15 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: isCorrect == null
                      ? color.withValues(alpha: 0.12)
                      : (isCorrect!
                          ? AppColors.green.withValues(alpha: 0.15)
                          : AppColors.red.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: isCorrect == null
                      ? Text('${index + 1}',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: color))
                      : Icon(
                          isCorrect!
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          color: isCorrect! ? AppColors.green : AppColors.red,
                          size: 18))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(event,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                        height: 1.4)),
                if (showYear && year != null) ...[
                  const SizedBox(height: 3),
                  Text(detail ?? '$year',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 10,
                          color: context.hintColor))
                ],
              ])),
          if (showYear && year != null && isCorrect != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: (isCorrect! ? AppColors.green : AppColors.red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999)),
                child: Text('$year',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isCorrect! ? AppColors.green : AppColors.red))),
        ]));
  }
}

// HEADLINE MATCH GAME

class HeadlineMatchGame extends StatefulWidget {
  const HeadlineMatchGame({super.key});

  @override
  State<HeadlineMatchGame> createState() => _HeadlineMatchGameState();
}

class _HeadlineMatchGameState extends State<HeadlineMatchGame> {
  static const int _rounds = 5;
  late List<_HeadlineMatchQuestion> _deck;
  int _index = 0, _score = 0;
  String? _selected;
  bool _finished = false, _resultSaved = false;

  @override
  void initState() {
    super.initState();
    _buildDeck();
  }

  void _buildDeck() {
    _deck = _dailyDeck(_HeadlineMatchData.questions, 'headline_match');
  }

  void _answer(String headline) {
    if (_selected != null) return;
    setState(() {
      _selected = headline;
      if (headline == _deck[_index].headline) _score++;
    });
  }

  Future<void> _saveGameResult() async {
    if (_resultSaved) return;
    _resultSaved = true;
    final xp = _score * 20;
    await XpService.addXp(xp);
    await GameResultsService.saveResult(GameResult(
      gameId: 'headline_match',
      gameName: 'Headline Match',
      score: _score,
      total: _rounds,
      xpEarned: xp,
      playedAt: DateTime.now(),
    ));
  }

  Future<void> _next() async {
    if (_index + 1 >= _rounds) {
      _saveGameResult();
      await StorageService.incrementGamePlaysToday('headline_match');
      if (!mounted) return;
      if (StorageService.getGamePlaysToday('headline_match') >= 2) {
        AdService.showInterstitial(then: () {
          if (mounted) setState(() => _finished = true);
        });
      } else {
        setState(() => _finished = true);
      }
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  void _restart() {
    _buildDeck();
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _finished = false;
      _resultSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Headline Match',
            style: TextStyle(
                fontFamily: AppFonts.body, fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: BackButton(color: context.subColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_index + 1}/$_rounds',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.subColor)),
            ),
          )
        ],
      ),
      body: _finished ? _buildResult() : _buildGame(),
    );
  }

  Widget _buildGame() {
    final q = _deck[_index];
    final answered = _selected != null;
    final options = q.optionsFor(_daySeed('headline_match') + _index);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _index / _rounds,
            minHeight: 4,
            backgroundColor: context.inputBg,
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
        ),
        const SizedBox(height: 14),
        Text('Round ${_index + 1} of $_rounds',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                color: context.hintColor)),
        const SizedBox(height: 4),
        Text('Which headline matches this brief?',
            style: TextStyle(
                fontFamily: AppFonts.display,
                height: 1.02,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.textColor)),
        const SizedBox(height: 12),
        const Center(child: BriefedBannerAd()),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.26)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.category.toUpperCase(),
                style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.teal,
                    letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text(q.brief,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 15,
                    color: context.textColor,
                    height: 1.55)),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, i) {
              final option = options[i];
              return _GameChoiceTile(
                text: option,
                color: AppColors.teal,
                selected: _selected == option,
                correct: option == q.headline,
                answered: answered,
                onTap: () => _answer(option),
              );
            },
          ),
        ),
        if (answered) ...[
          Text(
            _selected == q.headline ? 'Matched.' : 'Correct: ${q.headline}',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color:
                    _selected == q.headline ? AppColors.green : AppColors.red),
          ),
          const SizedBox(height: 10),
          AccentButton(
            text: _index + 1 >= _rounds ? 'See Results' : 'Next Brief',
            icon: Icons.arrow_forward_rounded,
            onTap: _next,
          ),
        ],
      ]),
    );
  }

  Widget _buildResult() => _GameResultView(
        gameName: 'Headline Match',
        score: _score,
        total: _rounds,
        color: AppColors.teal,
        onRestart: _restart,
        shareText:
            'I scored $_score/$_rounds on Headline Match in Briefed! #Briefed',
      );
}

// SOURCE SLEUTH GAME

class SourceSleuthGame extends StatefulWidget {
  const SourceSleuthGame({super.key});

  @override
  State<SourceSleuthGame> createState() => _SourceSleuthGameState();
}

class _SourceSleuthGameState extends State<SourceSleuthGame> {
  static const int _rounds = 5;
  late List<_SourceSleuthQuestion> _deck;
  int _index = 0, _score = 0;
  String? _selected;
  bool _finished = false, _resultSaved = false;

  @override
  void initState() {
    super.initState();
    _buildDeck();
  }

  void _buildDeck() {
    _deck = _dailyDeck(_SourceSleuthData.questions, 'source_sleuth');
  }

  void _answer(String desk) {
    if (_selected != null) return;
    setState(() {
      _selected = desk;
      if (desk == _deck[_index].desk) _score++;
    });
  }

  Future<void> _saveGameResult() async {
    if (_resultSaved) return;
    _resultSaved = true;
    final xp = _score * 20;
    await XpService.addXp(xp);
    await GameResultsService.saveResult(GameResult(
      gameId: 'source_sleuth',
      gameName: 'Source Sleuth',
      score: _score,
      total: _rounds,
      xpEarned: xp,
      playedAt: DateTime.now(),
    ));
  }

  Future<void> _next() async {
    if (_index + 1 >= _rounds) {
      _saveGameResult();
      await StorageService.incrementGamePlaysToday('source_sleuth');
      if (!mounted) return;
      if (StorageService.getGamePlaysToday('source_sleuth') >= 2) {
        AdService.showInterstitial(then: () {
          if (mounted) setState(() => _finished = true);
        });
      } else {
        setState(() => _finished = true);
      }
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  void _restart() {
    _buildDeck();
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _finished = false;
      _resultSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Source Sleuth',
            style: TextStyle(
                fontFamily: AppFonts.body, fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: BackButton(color: context.subColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_index + 1}/$_rounds',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.subColor)),
            ),
          )
        ],
      ),
      body: _finished ? _buildResult() : _buildGame(),
    );
  }

  Widget _buildGame() {
    final q = _deck[_index];
    final answered = _selected != null;
    final options = q.optionsFor(_daySeed('source_sleuth') + _index);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _index / _rounds,
            minHeight: 4,
            backgroundColor: context.inputBg,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 14),
        Text('Round ${_index + 1} of $_rounds',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                color: context.hintColor)),
        const SizedBox(height: 4),
        Text('Which news desk fits this clue?',
            style: TextStyle(
                fontFamily: AppFonts.display,
                height: 1.02,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.textColor)),
        const SizedBox(height: 12),
        const Center(child: BriefedBannerAd()),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.26)),
          ),
          child: Text(q.clue,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                  height: 1.5)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, i) {
              final option = options[i];
              return _GameChoiceTile(
                text: option,
                color: AppColors.accent,
                selected: _selected == option,
                correct: option == q.desk,
                answered: answered,
                onTap: () => _answer(option),
              );
            },
          ),
        ),
        if (answered) ...[
          Text(q.explanation,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: context.subColor)),
          const SizedBox(height: 10),
          AccentButton(
            text: _index + 1 >= _rounds ? 'See Results' : 'Next Clue',
            icon: Icons.arrow_forward_rounded,
            onTap: _next,
          ),
        ],
      ]),
    );
  }

  Widget _buildResult() => _GameResultView(
        gameName: 'Source Sleuth',
        score: _score,
        total: _rounds,
        color: AppColors.accent,
        onRestart: _restart,
        shareText:
            'I scored $_score/$_rounds on Source Sleuth in Briefed! #Briefed',
      );
}

class _GameChoiceTile extends StatelessWidget {
  final String text;
  final Color color;
  final bool selected;
  final bool correct;
  final bool answered;
  final VoidCallback onTap;

  const _GameChoiceTile({
    required this.text,
    required this.color,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showCorrect = answered && correct;
    final showWrong = answered && selected && !correct;
    final dim = answered && !selected && !correct;
    final tileColor = showCorrect
        ? AppColors.green.withValues(alpha: 0.1)
        : showWrong
            ? AppColors.red.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.06);
    final borderColor = showCorrect
        ? AppColors.green.withValues(alpha: 0.45)
        : showWrong
            ? AppColors.red.withValues(alpha: 0.45)
            : context.borderColor;
    final textColor = showCorrect
        ? AppColors.green
        : showWrong
            ? AppColors.red
            : context.textColor;

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: dim ? 0.45 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Icon(
              showCorrect
                  ? Icons.check_circle_rounded
                  : showWrong
                      ? Icons.cancel_rounded
                      : Icons.radio_button_unchecked_rounded,
              color: showCorrect
                  ? AppColors.green
                  : showWrong
                      ? AppColors.red
                      : color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.35)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _GameResultView extends StatelessWidget {
  final String gameName;
  final int score;
  final int total;
  final Color color;
  final VoidCallback onRestart;
  final String shareText;

  const _GameResultView({
    required this.gameName,
    required this.score,
    required this.total,
    required this.color,
    required this.onRestart,
    required this.shareText,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / total * 100).round();
    final emoji = score == total
        ? '🏆'
        : score >= 4
            ? '🔥'
            : score >= 3
                ? '👏'
                : '💪';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Spacer(),
        Text(emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 10),
        Text(gameName.toUpperCase(),
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 2)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: '$score',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 88,
                fontWeight: FontWeight.w900,
                letterSpacing: -4,
                color: color,
              ),
            ),
            TextSpan(
              text: '/$total',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.7)),
            ),
          ]),
        ),
        Text('$pct% correct',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: context.subColor)),
        const Spacer(),
        const Center(child: BriefedBannerAd()),
        const SizedBox(height: 12),
        AccentButton(
            text: 'Play Again', onTap: onRestart, icon: Icons.refresh_rounded),
        const SizedBox(height: 10),
        OutlineButton(
            text: 'Share Score',
            onTap: () => Share.share(shareText),
            icon: Icons.share_rounded),
        const SizedBox(height: 10),
        OutlineButton(text: 'Back', onTap: () => Navigator.of(context).pop()),
      ]),
    );
  }
}

class _HeadlineMatchQuestion {
  final String category;
  final String brief;
  final String headline;
  final List<String> distractors;

  const _HeadlineMatchQuestion({
    required this.category,
    required this.brief,
    required this.headline,
    required this.distractors,
  });

  List<String> optionsFor(int seed) {
    final options = [headline, ...distractors.take(3)]..shuffle(Random(seed));
    return options;
  }
}

class _SourceSleuthQuestion {
  final String clue;
  final String desk;
  final String explanation;

  const _SourceSleuthQuestion({
    required this.clue,
    required this.desk,
    required this.explanation,
  });

  List<String> optionsFor(int seed) {
    final options = ['World', 'Politics', 'Sports', 'Technology', 'Business'];
    options.shuffle(Random(seed));
    return options.take(4).contains(desk)
        ? options.take(4).toList()
        : ([desk, ...options.where((o) => o != desk).take(3)]
          ..shuffle(Random(seed + 7)));
  }
}

List<T> _dailyDeck<T>(List<T> bank, String salt) {
  final start = (_daySeed(salt) * 5) % bank.length;
  return List.generate(5, (i) => bank[(start + i) % bank.length]);
}

int _daySeed(String salt) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day)
      .difference(DateTime(2024, 1, 1))
      .inDays;
  return day + salt.codeUnits.fold<int>(0, (sum, code) => sum + code);
}

class _HeadlineMatchData {
  static final questions = List<_HeadlineMatchQuestion>.generate(120, (i) {
    final topic = _topics[i % _topics.length];
    final angle = _angles[(i ~/ _topics.length) % _angles.length];
    final headline = '${topic.$2} ${angle.$1}';
    final distractors = List.generate(3, (j) {
      final other = _topics[(i + j + 7) % _topics.length];
      final otherAngle = _angles[(i + j + 2) % _angles.length];
      return '${other.$2} ${otherAngle.$1}';
    });
    return _HeadlineMatchQuestion(
      category: topic.$1,
      headline: headline,
      brief: '${topic.$3} ${angle.$2}',
      distractors: distractors,
    );
  });

  static const _topics = [
    (
      'World',
      'Leaders gather for emergency climate talks',
      'A summit brings governments together after extreme weather strains regional planning.'
    ),
    (
      'Politics',
      'Parliament faces pressure over housing bill',
      'Lawmakers are negotiating a package aimed at affordability and rental supply.'
    ),
    (
      'Sports',
      'Underdog side stuns favourites in final',
      'A late surge changes the result after the match looked settled.'
    ),
    (
      'Technology',
      'Chip maker unveils faster low-power processor',
      'A hardware company says its latest design improves battery life and AI workloads.'
    ),
    (
      'Business',
      'Markets rise as inflation data cools',
      'Investors respond positively to signs that price growth may be easing.'
    ),
    (
      'World',
      'Ceasefire talks resume after border clashes',
      'Diplomats return to the table following several tense days near a disputed frontier.'
    ),
    (
      'Politics',
      'Election watchdog announces spending review',
      'Officials will examine campaign finance records before the next national vote.'
    ),
    (
      'Sports',
      'Teenage sprinter breaks long-standing record',
      'A young athlete delivers a standout performance at a major meet.'
    ),
    (
      'Technology',
      'New privacy rules target data brokers',
      'Regulators are preparing tighter limits on how personal information is packaged and sold.'
    ),
    (
      'Business',
      'Airline expands routes after profit rebound',
      'A carrier is adding capacity as travel demand improves.'
    ),
    (
      'World',
      'Aid convoys reach flood-hit communities',
      'Relief teams deliver supplies after severe rain cuts off towns.'
    ),
    (
      'Politics',
      'Cabinet reshuffle follows policy backlash',
      'A leader changes senior roles after criticism of a major reform plan.'
    ),
    (
      'Sports',
      'Coach defends selection after narrow loss',
      'A team boss backs their choices despite frustration from supporters.'
    ),
    (
      'Technology',
      'Cybersecurity warning issued after breach',
      'Authorities urge organisations to patch systems after a large intrusion.'
    ),
    (
      'Business',
      'Retail sales jump during holiday promotions',
      'Stores report stronger demand as discounts draw shoppers back.'
    ),
    (
      'World',
      'Health agency monitors new virus cluster',
      'Officials are tracking a local outbreak while advising calm and testing.'
    ),
    (
      'Politics',
      'Senate committee questions energy executives',
      'A hearing focuses on prices, supply and climate obligations.'
    ),
    (
      'Sports',
      'Star striker returns from injury layoff',
      'A key player is available again after weeks of rehabilitation.'
    ),
    (
      'Technology',
      'Satellite network expands rural coverage',
      'A communications firm adds capacity for remote communities.'
    ),
    (
      'Business',
      'Central bank holds rates steady',
      'Policymakers pause after months of debate about inflation and growth.'
    ),
  ];

  static const _angles = [
    (
      'after late-night negotiations',
      'The decision followed hours of talks and several unresolved sticking points.'
    ),
    (
      'as officials promise review',
      'Authorities say the outcome will be examined before longer-term changes are made.'
    ),
    (
      'amid public concern',
      'The issue has drawn attention from residents, advocates and industry groups.'
    ),
    (
      'with funding boost announced',
      'New money is being directed toward implementation and oversight.'
    ),
    (
      'following surprise data release',
      'Fresh figures shifted expectations and prompted a quick response.'
    ),
    (
      'as pressure builds on leaders',
      'Decision-makers are facing calls to explain what happens next.'
    ),
  ];
}

class _SourceSleuthData {
  static final questions = List<_SourceSleuthQuestion>.generate(120, (i) {
    final desk = _desks[i % _desks.length];
    final clue = _clues[(i ~/ _desks.length) % _clues.length];
    return _SourceSleuthQuestion(
      desk: desk.$1,
      clue: '$clue ${desk.$2}',
      explanation: 'This belongs on the ${desk.$1} desk because ${desk.$3}.',
    );
  });

  static const _desks = [
    (
      'World',
      'The story crosses borders and centres on diplomacy, conflict or international aid.',
      'the core actors are countries, international agencies or cross-border events'
    ),
    (
      'Politics',
      'The story focuses on lawmakers, elections, government policy or public officials.',
      'the main action is about power, legislation or public administration'
    ),
    (
      'Sports',
      'The story is driven by matches, athletes, teams, leagues or tournament results.',
      'the outcome depends on competition and sporting performance'
    ),
    (
      'Technology',
      'The story involves software, hardware, cybersecurity, platforms or scientific computing.',
      'the key development is a digital or technical change'
    ),
    (
      'Business',
      'The story follows companies, markets, jobs, prices, trade or central bank decisions.',
      'the central impact is economic or commercial'
    ),
  ];

  static const _clues = [
    'A breaking update mentions ministers, a vote and a contested reform.',
    'A report tracks earnings, demand forecasts and investor reaction.',
    'The lead names a club, a coach and a dramatic second-half comeback.',
    'The article explains a breach, a patch and warnings for users.',
    'The opening paragraph describes envoys meeting after regional tension.',
    'The key detail is a regulator examining a platform used by millions.',
    'The story turns on inflation, bond yields and household spending.',
    'A medal race changes after a favourite is ruled out injured.',
    'The report follows refugees, aid agencies and a humanitarian corridor.',
    'The lead names a mayor, a budget and opposition criticism.',
    'The main source is a central bank statement about rates.',
    'The piece compares smartphone chips, batteries and AI features.',
    'A national team announces its squad before a qualifying match.',
    'The story involves sanctions, negotiations and foreign ministers.',
    'A committee hearing asks executives about pricing and competition.',
    'The article centres on a start-up launch and cloud infrastructure.',
    'The lead describes polling, party strategy and campaign promises.',
    'The result changes league standings and playoff chances.',
    'A shipping disruption affects exporters and commodity prices.',
    'The report analyses a new app store rule and developer fees.',
    'The story follows peacekeepers, observers and border monitoring.',
    'The article explains a tax proposal before parliament.',
    'The lead highlights a record time, a podium and a championship.',
    'The core issue is a merger, revenue outlook and layoffs.',
  ];
}

// QUIZ SCREEN

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  Timer? _musicTimer;
  bool _isMusicPlaying = false;
  int _musicStep = 0;
  int? _lastTickSecond;
  int? _lastTickQuestionIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset stale finished state so the build's navigation guard doesn't
      // fire when this screen opens for a bonus round.
      if (ref.read(quizProvider).status == QuizStatus.finished) {
        ref.read(quizProvider.notifier).reset();
      }
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _start(
        forceRefresh: args?['forceRefresh'] == true,
        bonusRound: args?['bonusRound'] == true,
        replaySeed: args?['replaySeed'] as int?,
        categoryFilter: args?['categoryFilter'] as String?,
      );
    });
  }

  @override
  void dispose() {
    _musicTimer?.cancel();
    unawaited(_musicPlayer.stop());
    unawaited(_musicPlayer.dispose());
    unawaited(_tickPlayer.stop());
    unawaited(_tickPlayer.dispose());
    super.dispose();
  }

  Future<void> _start({
    bool forceRefresh = false,
    bool bonusRound = false,
    int? replaySeed,
    String? categoryFilter,
  }) async {
    // Wait up to 8 s for the pipeline to have real articles
    var pipeline = ref.read(newsPipelineProvider);
    for (int i = 0; i < 16 && pipeline.byCategory.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      pipeline = ref.read(newsPipelineProvider);
    }

    List<RankedArticle> ranked;
    if (categoryFilter != null) {
      final cat = NewsCategory.values.firstWhere(
        (c) => c.name == categoryFilter,
        orElse: () => NewsCategory.world,
      );
      ranked = pipeline.getTopStoriesForDisplay(cat);
    } else {
      ranked = pipeline.forYouStories;
    }

    final articles = ranked
        .map((ra) => NewsArticle(
              title: ra.title,
              description: ra.summary,
              sourceName: ra.sourceName,
              category: ra.category.name,
              pubDate: ra.publishedAt.toIso8601String(),
              link: ra.url,
              imageUrl: ra.imageUrl,
            ))
        .toList();

    await ref.read(quizProvider.notifier).startQuiz(
          articles.isNotEmpty ? articles : ref.read(newsProvider).articles,
          forceRefresh: forceRefresh,
          bonusRound: bonusRound,
          replaySeed: replaySeed,
          categoryFilter: categoryFilter,
        );
  }

  void _syncQuizAudio(QuizState quiz) {
    final hasQuestion =
        quiz.questions.isNotEmpty && quiz.currentQuestion != null;
    final isActive = quiz.status == QuizStatus.active && hasQuestion;
    final shouldTick = isActive && quiz.currentAnswer == null;

    if (isActive) {
      unawaited(_startQuizMusic());
    } else {
      unawaited(_stopQuizMusic());
      _lastTickSecond = null;
      _lastTickQuestionIndex = null;
    }

    if (!shouldTick) {
      _lastTickSecond = null;
      _lastTickQuestionIndex = quiz.currentIndex;
      return;
    }

    final isNewQuestion = _lastTickQuestionIndex != quiz.currentIndex;
    final isNewSecond = _lastTickSecond != quiz.timeLeft;
    if ((isNewQuestion || isNewSecond) && quiz.timeLeft > 0) {
      _lastTickQuestionIndex = quiz.currentIndex;
      _lastTickSecond = quiz.timeLeft;
      unawaited(_playQuizTick(isUrgent: quiz.timeLeft <= 5));
    }
  }

  Future<void> _startQuizMusic() async {
    if (_isMusicPlaying) return;
    _isMusicPlaying = true;
    _musicStep = 0;
    await _playMusicPulse();
    _musicTimer = Timer.periodic(const Duration(milliseconds: 680), (_) {
      unawaited(_playMusicPulse());
    });
  }

  Future<void> _stopQuizMusic() async {
    if (!_isMusicPlaying) return;
    _isMusicPlaying = false;
    _musicTimer?.cancel();
    _musicTimer = null;
    await _musicPlayer.stop();
  }

  Future<void> _playMusicPulse() async {
    if (!_isMusicPlaying) return;
    const notes = [196, 247, 330, 247, 175, 220, 294, 220];
    final frequency = notes[_musicStep % notes.length];
    _musicStep++;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setVolume(0.32);
      await _musicPlayer.play(BytesSource(_makeMusicPulse(frequency)));
    } catch (_) {
      // Keep quiz play independent from device audio availability.
    }
  }

  Future<void> _playQuizTick({required bool isUrgent}) async {
    try {
      await _tickPlayer.stop();
      await _tickPlayer.setVolume(isUrgent ? 0.22 : 0.14);
      await _tickPlayer.play(BytesSource(_makeTickSound(isUrgent: isUrgent)));
    } catch (_) {
      // Audio should never block quiz play.
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    _syncQuizAudio(quiz);
    if (quiz.status == QuizStatus.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Re-check: state may have been reset (e.g. bonus round starting)
        // since this build ran.
        if (ref.read(quizProvider).status != QuizStatus.finished) return;
        AdService.showInterstitial(then: () {
          if (mounted) Navigator.of(context).pushReplacementNamed('/result');
        });
      });
    }
    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(child: _buildBody(quiz)));
  }

  Widget _buildBody(QuizState quiz) {
    switch (quiz.status) {
      case QuizStatus.loading:
        return _buildLoading();
      case QuizStatus.error:
        return _buildError(quiz.errorMessage ?? 'Unknown error');
      default:
        if (quiz.questions.isEmpty) return _buildLoading();
        return _buildQuiz(quiz);
    }
  }

  Widget _buildLoading() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.newspaper_rounded,
                color: AppColors.accent, size: 30)),
        const SizedBox(height: 16),
        Text('Generating today\'s quiz...',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: context.subColor)),
        const SizedBox(height: 8),
        Text('Powered by AI',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: context.hintColor)),
        const SizedBox(height: 20),
        const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.accent))),
      ]));
  Widget _buildError(String msg) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            Text('Quiz failed to load',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.2))),
                child: Text(msg,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        color: context.subColor,
                        height: 1.6))),
            const SizedBox(height: 20),
            AccentButton(
                text: 'Retry (fresh)',
                onTap: () => _start(forceRefresh: true),
                icon: Icons.refresh_rounded),
            const SizedBox(height: 10),
            OutlineButton(
                text: 'Use offline questions',
                onTap: () {
                  final mockQs = GeminiService.mockQuestions();
                  ref.read(quizProvider.notifier).loadMock(mockQs);
                }),
          ])));
  Widget _buildQuiz(QuizState quiz) {
    final q = quiz.currentQuestion!;
    final sel = quiz.currentAnswer;
    final revealed = sel != null;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            GestureDetector(
                onTap: () {
                  ref.read(quizProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: context.borderColor)),
                    child: Icon(Icons.arrow_back_rounded,
                        color: context.subColor, size: 18))),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: (q.isEasy ? AppColors.green : AppColors.orange)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: (q.isEasy ? AppColors.green : AppColors.orange)
                            .withValues(alpha: 0.35))),
                child: Text(
                    q.difficulty[0].toUpperCase() + q.difficulty.substring(1),
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: q.isEasy ? AppColors.green : AppColors.orange))),
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: quiz.currentIndex / quiz.questions.length,
                  minHeight: 4,
                  backgroundColor: context.inputBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent)))),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _QuizTimerBar(
              timeLeft: quiz.timeLeft,
              totalTime: AppConstants.timerSeconds,
              answered: revealed)),
      Expanded(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(children: [
                      CategoryTag(category: q.category),
                      const SizedBox(width: 10),
                      Text(
                          '${quiz.currentIndex + 1} of ${quiz.questions.length}',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 11,
                              color: context.hintColor))
                    ]),
                    const SizedBox(height: 16),
                    Text(q.question,
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: context.textColor,
                            letterSpacing: -0.4,
                            height: 1.4)),
                    const SizedBox(height: 24),
                    ...q.options.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OptionButton(
                            text: e.value,
                            index: e.key,
                            isSelected: sel == e.key,
                            isCorrect: e.key == q.correctIndex,
                            isRevealed: revealed,
                            onTap: () => ref
                                .read(quizProvider.notifier)
                                .answerQuestion(e.key)))),
                    if (revealed) ...[
                      const SizedBox(height: 6),
                      Container(
                          decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.borderColor),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: context.isDark ? 0.2 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(18))),
                                    child: const Row(children: [
                                      Icon(Icons.newspaper_rounded,
                                          color: AppColors.accent, size: 15),
                                      SizedBox(width: 8),
                                      Text('STORY BEHIND THIS',
                                          style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accent,
                                              letterSpacing: 1.5))
                                    ])),
                                Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(q.storySummary,
                                              style: TextStyle(
                                                  fontFamily: AppFonts.body,
                                                  fontSize: 12,
                                                  color: context.subColor,
                                                  height: 1.7)),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            Text(q.source,
                                                style: TextStyle(
                                                    fontFamily:
                                                        AppFonts.display,
                                                    fontSize: 10,
                                                    color: context.hintColor)),
                                            Text(' · ',
                                                style: TextStyle(
                                                    color: context.hintColor,
                                                    fontSize: 10)),
                                            const Text('Read full story',
                                                style: TextStyle(
                                                    fontFamily:
                                                        AppFonts.display,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.accent))
                                          ]),
                                        ])),
                              ])),
                      const SizedBox(height: 8),
                    ],
                  ]))),
      if (revealed)
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AccentButton(
                text: quiz.currentIndex + 1 >= quiz.questions.length
                    ? 'See My Results'
                    : 'Next Question',
                onTap: () => ref.read(quizProvider.notifier).nextQuestion(),
                icon: quiz.currentIndex + 1 >= quiz.questions.length
                    ? Icons.emoji_events_rounded
                    : Icons.arrow_forward_rounded)),
    ]);
  }
}

class _QuizTimerBar extends StatelessWidget {
  final int timeLeft;
  final int totalTime;
  final bool answered;

  const _QuizTimerBar(
      {required this.timeLeft,
      required this.totalTime,
      required this.answered});

  Color _color(BuildContext context) {
    if (answered) return AppColors.green;
    if (timeLeft > totalTime * 0.5) return AppColors.green;
    if (timeLeft > totalTime * 0.25) return AppColors.gold;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final progress = answered ? 1.0 : (timeLeft / totalTime).clamp(0.0, 1.0);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                widthFactor: progress,
                heightFactor: 1,
                child: Container(color: color.withValues(alpha: 0.14)),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      answered
                          ? Icons.check_circle_rounded
                          : Icons.timer_rounded,
                      color: color,
                      size: 15),
                  const SizedBox(width: 7),
                  Text(
                    answered ? 'Answered' : '$timeLeft',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                  if (!answered) ...[
                    const SizedBox(width: 2),
                    Text('sec',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.8))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// RESULT SCREEN

final Map<int, Uint8List> _musicPulseCache = {};
Uint8List? _softTickCache;
Uint8List? _urgentTickCache;

Uint8List _makeWav({
  required int sampleRate,
  required int numSamples,
  required int Function(int sampleIndex) sampleAt,
}) {
  final dataSize = numSamples * 2;
  final bytes = ByteData(44 + dataSize);
  for (final e in {0: 0x52, 1: 0x49, 2: 0x46, 3: 0x46}.entries) {
    bytes.setUint8(e.key, e.value);
  }
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  for (final e in {
    8: 0x57,
    9: 0x41,
    10: 0x56,
    11: 0x45,
    12: 0x66,
    13: 0x6D,
    14: 0x74,
    15: 0x20
  }.entries) {
    bytes.setUint8(e.key, e.value);
  }
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  for (final e in {36: 0x64, 37: 0x61, 38: 0x74, 39: 0x61}.entries) {
    bytes.setUint8(e.key, e.value);
  }
  bytes.setUint32(40, dataSize, Endian.little);
  for (int i = 0; i < numSamples; i++) {
    bytes.setInt16(44 + i * 2, sampleAt(i).clamp(-32768, 32767), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

Uint8List _makeMusicPulse(int frequency) {
  final cached = _musicPulseCache[frequency];
  if (cached != null) return cached;
  const sampleRate = 22050;
  const durationSeconds = 0.46;
  final numSamples = (sampleRate * durationSeconds).round();

  final pulse = _makeWav(
    sampleRate: sampleRate,
    numSamples: numSamples,
    sampleAt: (i) {
      final t = i / sampleRate;
      final progress = i / numSamples;
      final attack = (progress / 0.12).clamp(0.0, 1.0);
      final release = pow(1 - progress, 1.8).toDouble();
      final envelope = attack * release;
      final base = frequency.toDouble();
      final value = (sin(2 * pi * base * t) * 0.38) +
          (sin(2 * pi * base * 1.5 * t) * 0.08) +
          (sin(2 * pi * base * 2.0 * t) * 0.06);

      return (value * 32767 * envelope).round();
    },
  );
  _musicPulseCache[frequency] = pulse;
  return pulse;
}

Uint8List _makeTickSound({required bool isUrgent}) {
  final cached = isUrgent ? _urgentTickCache : _softTickCache;
  if (cached != null) return cached;

  const sampleRate = 22050;
  final durationSeconds = isUrgent ? 0.085 : 0.055;
  final numSamples = (sampleRate * durationSeconds).round();
  final frequency = isUrgent ? 1200 : 880;
  final amplitude = isUrgent ? 0.35 : 0.22;

  final tick = _makeWav(
    sampleRate: sampleRate,
    numSamples: numSamples,
    sampleAt: (i) {
      final t = i / sampleRate;
      final envelope = pow(1 - (i / numSamples), 3).toDouble();
      final click = sin(2 * pi * frequency * t) +
          (0.35 * sin(2 * pi * frequency * 1.5 * t));
      return (click * 32767 * amplitude * envelope).round();
    },
  );

  if (isUrgent) {
    _urgentTickCache = tick;
  } else {
    _softTickCache = tick;
  }
  return tick;
}

// Generates a raw PCM WAV tone — no asset files required
Uint8List _makeBeep(int frequency, double durationSeconds,
    {double amplitude = 0.4}) {
  const sampleRate = 22050;
  final numSamples = (sampleRate * durationSeconds).round();
  return _makeWav(
      sampleRate: sampleRate,
      numSamples: numSamples,
      sampleAt: (i) {
        final fade = i > numSamples * 0.8
            ? 1.0 - (i - numSamples * 0.8) / (numSamples * 0.2)
            : 1.0;
        final sample = (sin(2 * pi * frequency * i / sampleRate) *
                32767 *
                amplitude *
                fade)
            .round()
            .clamp(-32768, 32767);
        return sample;
      });
}

Future<void> _playNote(int freq, double dur) async {
  final p = AudioPlayer();
  await p.play(BytesSource(_makeBeep(freq, dur)));
  await Future.delayed(Duration(milliseconds: (dur * 1000).round() + 40));
  await p.dispose();
}

Future<void> _playResultSound(int score, int total) async {
  if (score == total) {
    // Perfect: triumphant ascending chord
    await _playNote(523, 0.10);
    await _playNote(659, 0.10);
    await _playNote(784, 0.10);
    await _playNote(1047, 0.30);
  } else if (score >= (total * 0.8).ceil()) {
    // Great: two rising notes
    await _playNote(659, 0.10);
    await _playNote(880, 0.25);
  } else if (score >= 3) {
    // OK: single positive note
    await _playNote(523, 0.22);
  } else {
    // Poor: low descending notes
    await _playNote(330, 0.12);
    await _playNote(220, 0.30);
  }
}

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});
  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  final ScreenshotController _screenshotCtrl = ScreenshotController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _scaleCtrl.forward();
    _saveResult();
  }

  Future<void> _saveResult() async {
    if (_saved) return;
    _saved = true;
    final quiz = ref.read(quizProvider);
    final result = quiz.buildResult();
    await ref.read(userProvider.notifier).afterQuiz(result);
    ref.invalidate(dailyRankProvider);
    final score = quiz.score;
    final total = quiz.questions.length;
    unawaited(_playResultSound(score, total));
    if (score == total) {
      _confetti.play();
      HapticFeedback.heavyImpact();
      Future.delayed(
          const Duration(milliseconds: 200), HapticFeedback.heavyImpact);
      Future.delayed(
          const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
    } else if (score >= total * 0.8) {
      _confetti.play();
      HapticFeedback.heavyImpact();
      Future.delayed(
          const Duration(milliseconds: 250), HapticFeedback.lightImpact);
    } else if (score >= 3) {
      _confetti.play();
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _shakeCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Color _scoreColor(int score, int total) {
    if (score == total || score >= total * 0.8) return AppColors.green;
    if (score >= total * 0.6) return AppColors.gold;
    if (score >= total * 0.4) return AppColors.orange;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final user = ref.watch(userProvider);
    final score = quiz.score;
    final total = quiz.questions.length;
    final result = quiz.buildResult();
    final sc = _scoreColor(score, total);
    final dailyRank = ref.watch(dailyRankProvider);
    final bgColor = context.isDark
        ? context.bgColor
        : score >= total * 0.8
            ? const Color(0xFFE8FFF0)
            : score >= total * 0.6
                ? const Color(0xFFFFF8E8)
                : context.bgColor;
    return Scaffold(
        backgroundColor: bgColor,
        body: Stack(children: [
          Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: pi / 2,
                  emissionFrequency: score == total ? 0.08 : 0.05,
                  numberOfParticles: score == total
                      ? 30
                      : score >= total * 0.8
                          ? 20
                          : 12,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  gravity: 0.2,
                  colors: const [
                    AppColors.accent,
                    AppColors.green,
                    AppColors.gold,
                    AppColors.blue,
                    AppColors.purple
                  ])),
          SafeArea(
              child: Column(children: [
            Expanded(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                    child: Column(children: [
                      const SizedBox(height: 2),
                      AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (_, child) => Transform.translate(
                              offset: Offset(_shakeAnim.value, 0),
                              child: child),
                          child: ScaleTransition(
                              scale: _scaleAnim,
                              child: Column(children: [
                                Text(result.performanceEmoji,
                                    style: const TextStyle(fontSize: 46)),
                                const SizedBox(height: 2),
                                Text(result.performanceLabel.toUpperCase(),
                                    style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: sc,
                                        letterSpacing: 2.5)),
                                const SizedBox(height: 2),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: score),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOut,
                                  builder: (_, v, __) => RichText(
                                      text: TextSpan(children: [
                                    TextSpan(
                                        text: '$v',
                                        style: TextStyle(
                                            fontFamily: AppFonts.body,
                                            fontSize: 86,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -5,
                                            foreground: Paint()
                                              ..shader = LinearGradient(
                                                  colors: [
                                                    sc,
                                                    sc.withValues(alpha: 0.6)
                                                  ]).createShader(
                                                  const Rect.fromLTWH(
                                                      0, 0, 100, 100)))),
                                    TextSpan(
                                        text: '/$total',
                                        style: TextStyle(
                                            fontFamily: AppFonts.display,
                                            height: 1.02,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                            color: sc.withValues(alpha: 0.8))),
                                  ])),
                                ),
                                Container(
                                    width: 200,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                            value: score / total,
                                            backgroundColor: Colors.transparent,
                                            valueColor:
                                                AlwaysStoppedAnimation(sc)))),
                                const SizedBox(height: 6),
                                Text('${result.percentageString} correct',
                                    style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black.withValues(
                                            alpha:
                                                context.isDark ? 0.4 : 0.35))),
                              ]))),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: StatCard(
                                icon: Icons.local_fire_department_rounded,
                                value: '${user.streak}',
                                label: 'Streak',
                                color: AppColors.accent)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.bolt_rounded,
                                value: '+${result.pointsEarned}',
                                label: 'Points',
                                color: AppColors.gold)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.emoji_events_rounded,
                                value: dailyRank.when(
                                    data: (rank) => rank,
                                    loading: () => '...',
                                    error: (_, __) => user.globalRankLabel),
                                label: 'Today',
                                color: AppColors.purple)),
                      ]),
                      const SizedBox(height: 14),
                      if (kIsWeb &&
                          MediaQuery.of(context).size.width >= 700) ...[
                        const WebAdPlaceholder(label: 'Quiz results ad'),
                        const SizedBox(height: 14),
                      ],
                      Screenshot(
                          controller: _screenshotCtrl,
                          child: _ShareCard(
                              score: score, total: total, result: result)),
                      const SizedBox(height: 10),
                      _AnswerReviewCard(quiz: quiz),
                      const SizedBox(height: 10),
                      AccentButton(
                          text: 'Share Your Result',
                          onTap: _share,
                          icon: Icons.share_rounded),
                      const SizedBox(height: 10),
                      GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/hot-take'),
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color:
                                      AppColors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.purple
                                          .withValues(alpha: 0.25))),
                              child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        Icons.local_fire_department_rounded,
                                        color: AppColors.purple,
                                        size: 16),
                                    SizedBox(width: 8),
                                    Text("Today's Hot Take",
                                        style: TextStyle(
                                            fontFamily: AppFonts.body,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.purple)),
                                  ]))),
                      const SizedBox(height: 8),
                    ]))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: OutlineButton(
                  text: 'Want to Play More Games?',
                  icon: Icons.games_rounded,
                  onTap: () {
                    ref.read(quizProvider.notifier).reset();
                    final nav = Navigator.of(context);
                    final tab = ref.read(selectedTabProvider.notifier);
                    AdService.showInterstitial(then: () {
                      tab.state = 1;
                      nav.pushNamedAndRemoveUntil('/home', (_) => false);
                    });
                  }),
            ),
          ])),
        ]));
  }

  Future<void> _share() async {
    final quiz = ref.read(quizProvider);
    final result = quiz.buildResult();
    await Share.share(
        'I scored ${result.score}/${result.totalQuestions} on Briefed! ${result.performanceEmoji} ${result.performanceLabel}\n#Briefed #StaySharp');
  }
}

class _AnswerReviewCard extends StatelessWidget {
  final QuizState quiz;
  const _AnswerReviewCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return BriefedCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.fact_check_rounded,
                    color: AppColors.blue, size: 18)),
            const SizedBox(width: 10),
            Text('Review Answers',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.textColor)),
          ]),
          const SizedBox(height: 8),
          ...quiz.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final selected =
                index < quiz.answers.length ? quiz.answers[index] : null;
            final isCorrect = selected == question.correctIndex;
            final selectedLabel = selected != null &&
                    selected >= 0 &&
                    selected < question.options.length
                ? question.options[selected]
                : 'Timed out';
            final correctLabel = question.options[question.correctIndex];
            final color = isCorrect ? AppColors.green : AppColors.red;

            return Theme(
                data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent),
                child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9)),
                        child: Icon(
                            isCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            color: color,
                            size: 17)),
                    title: Text('Q${index + 1}. ${question.question}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.textColor)),
                    subtitle: Text(
                        isCorrect
                            ? 'Correct: $correctLabel'
                            : 'Your answer: $selectedLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color)),
                    children: [
                      _ReviewLine(
                          label: 'Your answer',
                          value: selectedLabel,
                          color: isCorrect ? AppColors.green : AppColors.red),
                      if (!isCorrect)
                        _ReviewLine(
                            label: 'Correct answer',
                            value: correctLabel,
                            color: AppColors.green),
                      if (question.explanation.isNotEmpty)
                        _ReviewParagraph(
                            icon: Icons.lightbulb_rounded,
                            title: 'Why',
                            text: question.explanation),
                      if (question.storySummary.isNotEmpty)
                        _ReviewParagraph(
                            icon: Icons.article_rounded,
                            title: 'Story',
                            text: question.storySummary),
                    ]));
          }),
        ]));
  }
}

class _ReviewLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ReviewLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 38, right: 4, bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 86,
              child: Text(label,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.hintColor))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color))),
        ]));
  }
}

class _ReviewParagraph extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _ReviewParagraph({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 38, right: 4, bottom: 8),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(12)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(title,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: context.textColor)),
              ]),
              const SizedBox(height: 4),
              Text(text,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: context.subColor,
                      height: 1.35)),
            ])));
  }
}

class _ShareCard extends StatelessWidget {
  final int score, total;
  final QuizResult result;
  const _ShareCard(
      {required this.score, required this.total, required this.result});
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('Briefed.',
                              style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const Spacer(),
                          Row(children: [
                            ...List.generate(
                                score,
                                (_) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 3),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle))),
                            ...List.generate(
                                total - score,
                                (_) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 3),
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        shape: BoxShape.circle))),
                          ]),
                        ]),
                        const SizedBox(height: 10),
                        Text('$score/$total — ${result.performanceLabel}',
                            style: const TextStyle(
                                fontFamily: AppFonts.display,
                                height: 1.02,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8)),
                        const SizedBox(height: 4),
                        Text(
                            '${result.pointsEarned} points · ${result.percentageString} correct',
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75))),
                      ])),
              Container(
                  color: context.cardColor,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(children: [
                    const Text('#Briefed',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                    const SizedBox(width: 8),
                    const Text('#StaySharp',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                    const Spacer(),
                    Text('briefedapp.com',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 10,
                            color: context.hintColor)),
                  ])),
            ])));
  }
}

// HOT TAKE SCREEN

class HotTakeScreen extends ConsumerWidget {
  const HotTakeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ht = ref.watch(hotTakeProvider);
    return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
            title: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text("Today's Hot Take")
            ]),
            centerTitle: true,
            leading: BackButton(color: context.subColor)),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const SizedBox(height: 20),
              Text(ht.question,
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.textColor,
                      letterSpacing: -0.5,
                      height: 1.4),
                  textAlign: TextAlign.center),
              const SizedBox(height: 36),
              Row(children: [
                Expanded(
                    child: _VoteButton(
                        label: 'YES',
                        icon: Icons.thumb_up_rounded,
                        color: AppColors.green,
                        isVoted: ht.userVote == 'yes',
                        disabled: ht.userVote != null || ht.isLoading,
                        onTap: () =>
                            ref.read(hotTakeProvider.notifier).vote('yes'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _VoteButton(
                        label: 'NO',
                        icon: Icons.thumb_down_rounded,
                        color: AppColors.red,
                        isVoted: ht.userVote == 'no',
                        disabled: ht.userVote != null || ht.isLoading,
                        onTap: () =>
                            ref.read(hotTakeProvider.notifier).vote('no'))),
              ]),
              if (ht.userVote != null) ...[
                const SizedBox(height: 28),
                BriefedCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        const Icon(Icons.bar_chart_rounded,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                            ht.total == 0
                                ? 'Be the first to vote!'
                                : '${_fmt(ht.total)} votes',
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: context.hintColor,
                                letterSpacing: 1.5))
                      ]),
                      const SizedBox(height: 16),
                      _ResultBar(
                          label: 'YES',
                          percent: ht.yesPercent,
                          color: AppColors.green),
                      const SizedBox(height: 12),
                      _ResultBar(
                          label: 'NO',
                          percent: ht.noPercent,
                          color: AppColors.red),
                      const SizedBox(height: 16),
                      AccentButton(
                          text: 'Share This Take',
                          onTap: () {
                            final pct = ht.userVote == 'yes'
                                ? ht.yesPercent
                                : ht.noPercent;
                            Share.share(
                                'I voted ${ht.userVote!.toUpperCase()} — and $pct% of Briefed users agree!\n\n"${ht.question}"\n\n#Briefed #HotTake');
                          },
                          icon: Icons.share_rounded),
                    ])),
              ],
              const Spacer(),
              OutlineButton(
                  text: 'Back to Home',
                  onTap: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (_) => false),
                  icon: Icons.home_rounded),
            ])));
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isVoted, disabled;
  final VoidCallback onTap;
  const _VoteButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.isVoted,
      required this.disabled,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
                color:
                    isVoted ? color.withValues(alpha: 0.1) : context.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: isVoted
                        ? color.withValues(alpha: 0.45)
                        : context.borderColor),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black
                          .withValues(alpha: context.isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]),
            child: Column(children: [
              Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: isVoted
                          ? color.withValues(alpha: 0.2)
                          : context.inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isVoted
                              ? color.withValues(alpha: 0.3)
                              : context.borderColor)),
                  child: Icon(icon,
                      color: isVoted ? color : context.hintColor, size: 26)),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isVoted ? color : context.subColor)),
            ])));
  }
}

class _ResultBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;
  const _ResultBar(
      {required this.label, required this.percent, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.subColor)),
        const Spacer(),
        Text('$percent%',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: context.inputBg,
                  valueColor: AlwaysStoppedAnimation(color)))),
    ]);
  }
}

Widget _buildAvatar(String? photoUrl, double size) {
  final fallback = Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.48),
  );
  if (photoUrl == null || photoUrl.isEmpty) return fallback;
  return ClipOval(
    child: Image.network(
      photoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (_, __, ___) => fallback,
    ),
  );
}

class _CategoryStat {
  final int correct;
  final int total;
  final double legacyAccuracyTotal;
  final int legacyQuizzes;

  const _CategoryStat({
    this.correct = 0,
    this.total = 0,
    this.legacyAccuracyTotal = 0,
    this.legacyQuizzes = 0,
  });

  _CategoryStat add({required bool correct}) => _CategoryStat(
        correct: this.correct + (correct ? 1 : 0),
        total: total + 1,
        legacyAccuracyTotal: legacyAccuracyTotal,
        legacyQuizzes: legacyQuizzes,
      );

  _CategoryStat addLegacy(double accuracy) => _CategoryStat(
        correct: correct,
        total: total,
        legacyAccuracyTotal: legacyAccuracyTotal + accuracy,
        legacyQuizzes: legacyQuizzes + 1,
      );

  double get accuracy {
    if (total > 0) return correct / total;
    if (legacyQuizzes > 0) return legacyAccuracyTotal / legacyQuizzes;
    return 0;
  }

  String get label {
    if (total > 0) return '$correct/$total questions';
    return '$legacyQuizzes quiz${legacyQuizzes == 1 ? '' : 'zes'}';
  }
}

// PRO PURCHASE SHEET — top-level so any screen can call it

void showBriefedProSheet(BuildContext context, WidgetRef ref) {
  final user = ref.read(userProvider);
  final canActivatePro =
      AuthService.currentUser != null && !AuthService.isGuest;
  final hasPro = user.isPro && canActivatePro;
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: ctx.borderColor,
                        borderRadius: BorderRadius.circular(2)))),
            Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.gold, Color(0xFFFF9100)]),
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 30)),
            const SizedBox(height: 14),
            Text('Briefed Pro',
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: ctx.textColor)),
            Text(hasPro ? 'Active' : ProPurchaseService.fallbackPriceLabel,
                style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ...[
              ('All 7 quiz categories unlocked', Icons.quiz_rounded),
              ('Unlimited quiz replays', Icons.replay_rounded),
              ('Ad-free experience across all games', Icons.block_rounded),
              ('Category accuracy breakdown', Icons.bar_chart_rounded),
              ('Early access to new games', Icons.games_rounded),
              ('Support Briefed\'s growth', Icons.favorite_rounded),
            ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9)),
                      child: Icon(f.$2, color: AppColors.gold, size: 16)),
                  const SizedBox(width: 12),
                  Text(f.$1,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ctx.textColor)),
                ]))),
            const SizedBox(height: 8),
            GestureDetector(
                onTap: hasPro
                    ? null
                    : () async {
                        if (!canActivatePro) {
                          Navigator.of(ctx).pop();
                          showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: context.cardColor,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24))),
                              builder: (_) => _AuthSheet(ref: ref));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final nav =
                            Navigator.of(context, rootNavigator: true);
                        showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (dCtx) => const Center(
                                child: CircularProgressIndicator()));
                        try {
                          final product =
                              await ProPurchaseService.loadProProduct();
                          if (nav.canPop()) nav.pop();
                          await ProPurchaseService.buyPro(product);
                          messenger.showSnackBar(const SnackBar(
                              content: Text(
                                  'Complete the purchase to activate Briefed Pro.')));
                        } catch (e) {
                          if (nav.canPop()) nav.pop();
                          messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())));
                        }
                      },
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.gold, Color(0xFFFF9100)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6))
                        ]),
                    child: Center(
                        child: Text(
                            hasPro
                                ? 'Pro Active'
                                : !canActivatePro
                                    ? 'Sign in to Activate'
                                    : 'Subscribe — A\$2.99/month',
                            style: const TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white))))),
            const SizedBox(height: 8),
            Text(
                hasPro
                    ? 'Unlimited replay is ready on the home quiz card'
                    : canActivatePro
                        ? 'Monthly subscription · cancel anytime'
                        : 'Pro is tied to a signed-in account',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    color: ctx.hintColor)),
            if (canActivatePro && !hasPro) ...[
              const SizedBox(height: 6),
              GestureDetector(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ProPurchaseService.restorePurchases();
                      messenger.showSnackBar(const SnackBar(
                          content:
                              Text('Checking for previous purchases...')));
                    } catch (e) {
                      messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Text('Restore subscription',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold))),
            ],
          ])));
}

// PROFILE SCREEN — with leaderboard

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFFFF5722);
  static const _gamePurple = Color(0xFFFF7A2F);
  static const _gameBlue = Color(0xFFE85D04);
  static const _darkProfileBg = Color(0xFF1A0F08);
  static const _darkProfileSurface = Color(0xFF27170E);
  late final AnimationController _heroCtrl;
  late final Future<Map<String, dynamic>> _gameSummaryFuture;
  late final Future<List<GameResult>> _recentGameResultsFuture;
  int _tabIndex = 0;
  int _categoryLeaderboardIndex = 0;
  int _gameLeaderboardIndex = 0;
  int _mainLbScope = 1; // 0=Friends, 1=Global, 2=Country

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _gameSummaryFuture = GameResultsService.getGameSummary();
    _recentGameResultsFuture = GameResultsService.getRecentResults(limit: 10);
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isGuest = authUser == null || authUser.isAnonymous;

    final catStats = _categoryStats(user);
    final strongest = _strongestCategory(catStats);
    final totalXp = XpService.getTotalXp();
    final level = XpService.getLevel();
    final levelTitle = XpService.getLevelTitle();
    final xpForNext = XpService.getXpForNextLevel();
    final progress = XpService.getLevelProgress();
    final profileBg = context.isDark ? _darkProfileBg : const Color(0xFFFFF1E2);

    return Scaffold(
      backgroundColor: profileBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _identityHero(
                context,
                user: user,
                photoUrl: authUser?.photoURL,
                level: level,
                levelTitle: levelTitle,
                totalXp: totalXp,
                xpForNext: xpForNext,
                progress: progress,
                strongest: strongest,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<GameResult>>(
                future: _recentGameResultsFuture,
                builder: (context, snap) => _thisWeekStrip(
                  context,
                  user.recentResults,
                  snap.data ?? const [],
                ),
              ),
              const SizedBox(height: 18),
              _tabs(context, isPro: user.isPro && !isGuest),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _tabIndex == 0
                    ? _quizStatsTab(context, user, isGuest)
                    : _tabIndex == 1
                        ? _gameStatsTab(context, user, isGuest)
                        : _categoriesTab(context, user, catStats, isGuest),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<GameResult>>(
                future: _recentGameResultsFuture,
                builder: (context, snap) => _recentActivity(
                  context,
                  user.recentResults,
                  snap.data ?? const [],
                  loading: snap.connectionState == ConnectionState.waiting,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>>(
                future: _gameSummaryFuture,
                builder: (context, snap) => _badges(
                  context,
                  user,
                  snap.data ?? const {},
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _profileSurface(BuildContext context) {
    return context.isDark ? _darkProfileSurface : Colors.white;
  }

  Color _profileBorder(BuildContext context, {double lightAlpha = 0.72}) {
    return context.isDark
        ? const Color(0xFF3A2516)
        : const Color(0xFFF4E2CE).withValues(alpha: lightAlpha);
  }

  List<BoxShadow> _profileShadow(BuildContext context, double lightAlpha) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }

  // ── Avatar colors by list rank ────────────────────────────────────────────
  static const _lbColors = [
    Color(0xFFDB2777), Color(0xFF7C3AED), Color(0xFF16A34A),
    Color(0xFF0EA5E9), Color(0xFF0891B2), Color(0xFF059669),
    Color(0xFFD97706), Color(0xFF9333EA),
  ];

  String _lbInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _lbInitialsCircle(LeaderboardEntry entry, double size, int rank,
      {Color? bg, Color? fg}) {
    final color = entry.isYou ? _accent : _lbColors[(rank - 1) % _lbColors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (bg ?? color).withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _lbInitials(entry.name),
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: size * (entry.name.contains(' ') ? 0.34 : 0.4),
            fontWeight: FontWeight.w800,
            color: fg ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _lbAvatarCircle(LeaderboardEntry entry, double size, int rank) {
    if (entry.photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          entry.photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _lbInitialsCircle(entry, size, rank),
        ),
      );
    }
    return _lbInitialsCircle(entry, size, rank);
  }

  Widget _lbMedal(int rank) {
    const medalColors = {
      1: Color(0xFFF5C400),
      2: Color(0xFFC0C0C0),
      3: Color(0xFFCD7F32),
    };
    final fill = medalColors[rank];
    if (fill == null) {
      return SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9C8377),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(fill, Colors.white, 0.3)!, fill],
        ),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _lbScopeTab(BuildContext context, String label, int index, bool isDark) {
    final active = _mainLbScope == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mainLbScope = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF3A2516) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active
                  ? (isDark ? Colors.white : const Color(0xFF1F1612))
                  : context.hintColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _lbYouHero(
    BuildContext context,
    LeaderboardEntry you,
    int rank,
    LeaderboardEntry? next,
  ) {
    final gap = next != null ? (next.score - you.score).clamp(0, 99999) : 0;
    final progress = (next != null && next.score > 0)
        ? (you.score / next.score).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6A1A), Color(0xFFD04E00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0xFF7A2A00), blurRadius: 0, offset: Offset(0, 5)),
          BoxShadow(color: Color(0x40FF6A1A), blurRadius: 24, offset: Offset(0, 16)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          right: -30,
          top: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                ),
                child: _lbInitialsCircle(you, 52, rank, bg: Colors.white, fg: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(
                    'YOU · GLOBAL',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rank #$rank',
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(
                      '${_fmt(you.score)} XP',
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Text(' · ', style: TextStyle(color: Colors.white54)),
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${you.streak} day',
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ]),
                ]),
              ),
            ]),
            if (next != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catching ${next.name}',
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$gap XP to go',
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _leaderboard(
    BuildContext context,
    bool isGuest,
    AsyncValue<List<LeaderboardEntry>> leaderboardAsync,
    String title, {
    String emptyText = 'No scores yet — play a quiz!',
    List<LeaderboardEntry> fallbackEntries = const [],
    bool showTabs = false,
  }) {
    final isDark = context.isDark;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: context.textColor,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Top 100',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 14, color: _accent),
          ]),
        ),
      ]),

      const SizedBox(height: 10),

      // Unified card: tabs + hero + list all inside one container
      Container(
        decoration: BoxDecoration(
          color: _profileSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _profileBorder(context)),
          boxShadow: _profileShadow(context, 0.08),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Scope tabs at top of the card
          if (showTabs) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27170E) : const Color(0xFFF4E2CE),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  _lbScopeTab(context, 'Friends', 0, isDark),
                  _lbScopeTab(context, 'Global', 1, isDark),
                  _lbScopeTab(context, 'Country', 2, isDark),
                ]),
              ),
            ),
          ],

          if (isGuest)
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.leaderboard_rounded, size: 28, color: _accent),
                ),
                const SizedBox(height: 12),
                Text(
                  'Compete globally',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to see where you rank among all Briefed players',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.subColor,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ]),
            )
          else
            leaderboardAsync.when(
              loading: () => const Column(children: [
                ShimmerBox(width: double.infinity, height: 108, borderRadius: 20),
                SizedBox(height: 10),
                ShimmerBox(width: double.infinity, height: 54, borderRadius: 14),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 54, borderRadius: 14),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 54, borderRadius: 14),
              ]),
              error: (_, __) =>
                  _leaderboardListOrEmpty(context, fallbackEntries, emptyText),
              data: (entries) {
                final users = entries.where((e) => !e.isSeparator).take(10).toList();
                return _leaderboardListOrEmpty(
                  context,
                  users.isEmpty ? fallbackEntries : users,
                  emptyText,
                );
              },
            ),
        ]),  // closes unified Container's Column
      ),     // closes unified Container
    ]);      // closes outer _leaderboard Column
  }

  Widget _leaderboardListOrEmpty(
    BuildContext context,
    List<LeaderboardEntry> entries,
    String emptyText,
  ) {
    final users = entries.where((e) => !e.isSeparator).take(10).toList();
    if (users.isEmpty) {
      // Empty state — no outer container needed (we're inside the unified card)
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: context.hintColor,
          ),
        ),
      );
    }

    // Find you and the person just above you
    final youIndex = users.indexWhere((e) => e.isYou);
    final youEntry = youIndex >= 0 ? users[youIndex] : null;
    final youRank = youIndex >= 0 ? youIndex + 1 : null;
    final nextEntry =
        (youRank != null && youRank > 1) ? users[youRank - 2] : null;

    // Render inside the unified card — no extra Container wrapper needed
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // YOU hero card — inset with padding so it sits inside the card
      if (youEntry != null) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: _lbYouHero(context, youEntry, youRank!, nextEntry),
        ),
        const SizedBox(height: 12),
      ],

      // Ranked list rows — rendered directly (unified card clips them)
      ...users.asMap().entries.map((e) => _leaderboardRow(
            context,
            e.value,
            e.key + 1,
            isLast: e.key == users.length - 1,
          )),
    ]);
  }

  Widget _leaderboardRow(
    BuildContext context,
    LeaderboardEntry entry,
    int rank, {
    required bool isLast,
  }) {
    final isDark = context.isDark;
    // Alternate subtle row tint: odd ranks (1,3,5…) get a faint accent wash
    final altTint = rank.isOdd && !entry.isYou
        ? _accent.withValues(alpha: isDark ? 0.04 : 0.03)
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isYou
            ? _accent.withValues(alpha: isDark ? 0.15 : 0.06)
            : altTint,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF3A2516)
                      : const Color(0xFFF4E2CE),
                  width: 1,
                ),
              ),
      ),
      child: Row(children: [
        // Medal or rank number
        SizedBox(width: 30, child: _lbMedal(rank)),
        const SizedBox(width: 8),
        // Colored avatar circle
        _lbAvatarCircle(entry, 32, rank),
        const SizedBox(width: 10),
        // Name + streak
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: entry.isYou ? _accent : context.textColor,
                    ),
                  ),
                ),
                if (entry.isYou) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.orange, size: 11),
                const SizedBox(width: 3),
                Text(
                  '${entry.streak} day streak',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.hintColor,
                  ),
                ),
              ]),
            ],
          ),
        ),
        // XP score
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmt(entry.score),
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: entry.isYou ? _accent : context.textColor,
              ),
            ),
            Text(
              'XP',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: context.hintColor,
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _identityHero(
    BuildContext context, {
    required UserData user,
    required String? photoUrl,
    required int level,
    required String levelTitle,
    required int totalXp,
    required int xpForNext,
    required double progress,
    required MapEntry<String, _CategoryStat>? strongest,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = user.name.trim().isEmpty ? 'Briefed User' : user.name.trim();
    final initial = name[0].toUpperCase();

    return ScaleTransition(
      scale: Tween<double>(begin: 0.97, end: 1).animate(
        CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: _heroCtrl,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_accent, Color(0xFFE85D04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              const BoxShadow(
                color: Color(0xFF7A2A00),
                blurRadius: 0,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: _accent.withValues(alpha: isDark ? 0.22 : 0.42),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -42,
                top: -42,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  photoUrl != null && photoUrl.isNotEmpty
                      ? _buildAvatar(photoUrl, 64)
                      : CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Text(initial,
                              style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  color: Color(0xFF7A2A00),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                        ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC15A),
                        shape: BoxShape.circle,
                        border: Border.all(color: _accent, width: 2),
                      ),
                      child: Text('$level',
                          style: const TextStyle(
                              fontFamily: AppFonts.body,
                              color: Color(0xFF5C2E04),
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: AppFonts.display,
                                height: 1.02,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('Lv. $level · $levelTitle',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white))),
                          const SizedBox(width: 7),
                          const Icon(Icons.local_fire_department_rounded,
                              color: Colors.white, size: 14),
                          Text('${user.streak} day',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.9))),
                        ]),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Stack(children: [
                            Container(
                                height: 10,
                                color: Colors.white.withValues(alpha: 0.24)),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text('${xpForNext - totalXp} XP to next level',
                              style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.88))),
                          const Spacer(),
                          Text('$totalXp / $xpForNext XP',
                              style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ]),
                        if (strongest != null) ...[
                          const SizedBox(height: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_categoryEmoji(strongest.key)} Strongest: ${_categoryLabel(strongest.key)}',
                              style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'Settings',
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  icon: Icon(Icons.settings_rounded,
                      color: Colors.white.withValues(alpha: 0.9), size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thisWeekStrip(
    BuildContext context,
    List<QuizResult> quizzes,
    List<GameResult> games,
  ) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _profileSurface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _profileShadow(context, 0.10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('This week',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: context.textColor)),
          const Spacer(),
          Text('${quizzes.length} quiz${quizzes.length == 1 ? '' : 'zes'}',
              style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _accent)),
        ]),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (i) {
            final day = monday.add(Duration(days: i));
            final ds = day.toIso8601String().substring(0, 10);
            final quiz = quizzes.where((r) => r.date == ds).toList();
            final dayGames =
                games.where((g) => _sameDay(g.playedAt, day)).toList();
            final hasQuiz = quiz.isNotEmpty;
            final hasGame = dayGames.isNotEmpty;
            final perfect = quiz.any((r) => r.score == r.totalQuestions);
            final today = _sameDay(day, now);
            final quizLabel = hasQuiz
                ? '${quiz.first.score}/${quiz.first.totalQuestions}'
                : null;

            return Expanded(
              child: Column(children: [
                Text('MTWTFSS'[i],
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: context.hintColor)),
                const SizedBox(height: 7),
                Container(
                  width: today ? 38 : 32,
                  height: today ? 38 : 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasQuiz && hasGame && !perfect
                        ? const LinearGradient(colors: [_accent, _gamePurple])
                        : null,
                    color: perfect
                        ? const Color(0xFFFFC15A)
                        : hasQuiz && !hasGame
                            ? _accent
                            : hasGame && !hasQuiz
                                ? _gamePurple
                                : hasQuiz && hasGame
                                    ? null
                                    : _profileBorder(context),
                    border: today
                        ? Border.all(color: context.textColor, width: 2)
                        : null,
                    boxShadow: perfect
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.38),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    hasQuiz
                        ? quizLabel!
                        : hasGame
                            ? '✓'
                            : '',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        color: Colors.white,
                        fontSize: hasQuiz ? 8 : 10,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ]),
            );
          }),
        ),
      ]),
    );
  }

  Widget _tabs(BuildContext context, {required bool isPro}) {
    const labels = ['Quiz Stats', 'Game Stats', 'Categories'];
    return Row(
      children: List.generate(labels.length, (i) {
        final selected = _tabIndex == i;
        final isCategoryTab = i == 2;
        final showLock = isCategoryTab && !isPro;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: Container(
              margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _accent : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected
                    ? [
                        const BoxShadow(
                          color: Color(0xFFE85D04),
                          blurRadius: 0,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (showLock) ...[
                  Icon(Icons.lock_rounded,
                      size: 11,
                      color: selected ? Colors.white : AppColors.gold),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : showLock
                                  ? AppColors.gold
                                  : context.hintColor)),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _quizStatsTab(BuildContext context, UserData user, bool isGuest) {
    final results = user.recentResults;
    final best = results.isEmpty
        ? 0
        : results.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final avg = results.isEmpty
        ? 0
        : ((results.map((r) => r.percentage).reduce((a, b) => a + b) /
                    results.length) *
                100)
            .round();
    final avgColor = avg >= 60
        ? AppColors.green
        : avg >= 40
            ? _accent
            : AppColors.red;

    return Column(
      key: const ValueKey('quiz'),
      children: [
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.75,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statTile(
                context, '${user.totalQuizzes}', 'quizzes completed', _accent),
            _statTile(context, '$best/5 ✓', 'best result', AppColors.green),
            _statTile(context, '${user.streak} 🔥', 'day streak', _accent),
            _statTile(context, '$avg%', 'average', avgColor),
          ],
        ),
        const SizedBox(height: 18),
        _leaderboard(
          context,
          isGuest,
          ref.watch(mainQuizLeaderboardProvider).when(
                data: (entries) => AsyncData(entries),
                loading: () {
                  final legacy = ref.watch(leaderboardProvider);
                  return legacy.hasValue
                      ? AsyncData(legacy.value ?? const [])
                      : const AsyncLoading();
                },
                error: (_, __) => ref.watch(leaderboardProvider),
              ),
          'Leaderboard',
          emptyText: 'No main quiz scores yet',
          showTabs: true,
        ),
      ],
    );
  }

  Widget _statTile(
      BuildContext context, String value, String label, Color color) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _profileSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _profileShadow(context, 0.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: context.hintColor)),
        ],
      ),
    );
  }

  Widget _gameStatsTab(BuildContext context, UserData user, bool isGuest) {
    return FutureBuilder<Map<String, dynamic>>(
      key: const ValueKey('games'),
      future: _gameSummaryFuture,
      builder: (context, snap) {
        final data = snap.data ?? const <String, dynamic>{};
        return _gameLeaderboardSection(context, user, isGuest, data);
      },
    );
  }

  Widget _gameLeaderboardSection(BuildContext context, UserData user,
      bool isGuest, Map<String, dynamic> data) {
    const games = [
      ('real_or_fake', 'Real or Fake?', _gamePurple),
      ('oldest_to_latest', 'Oldest to Latest', _gameBlue),
      ('headline_match', 'Headline Match', AppColors.teal),
      ('source_sleuth', 'Source Sleuth', _accent),
    ];
    final selected = games[_gameLeaderboardIndex];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: games.asMap().entries.map((entry) {
          final selectedChip = entry.key == _gameLeaderboardIndex;
          final game = entry.value;
          return GestureDetector(
            onTap: () => setState(() => _gameLeaderboardIndex = entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: selectedChip ? game.$3 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selectedChip ? game.$3 : context.borderColor,
                ),
              ),
              child: Text(
                game.$2,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selectedChip ? Colors.white : context.hintColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      _leaderboard(
        context,
        isGuest,
        ref.watch(gameLeaderboardProvider(selected.$1)),
        '${selected.$2} Leaderboard',
        emptyText: 'No game scores yet',
        fallbackEntries: _selfGameLeaderboardFallback(user, data, selected.$1),
      ),
    ]);
  }

  Widget _categoriesTab(BuildContext context, UserData user,
      List<MapEntry<String, _CategoryStat>> stats, bool isGuest) {
    final isPro = user.isPro && !isGuest;

    if (!isPro) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _profileSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          boxShadow: _profileShadow(context, 0.08),
        ),
        child: Column(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.gold, Color(0xFFFF9100)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Category Breakdown',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.textColor)),
          const SizedBox(height: 6),
          Text(
            'See your accuracy in each topic — \nhow well are you really briefed?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: context.hintColor,
                height: 1.5),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Pro feature',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => showBriefedProSheet(context, ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.gold, Color(0xFFFF9100)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Center(
                child: Text('Upgrade to Pro',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ),
        ]),
      );
    }

    final names = ['world', 'politics', 'sports', 'tech', 'business'];
    final byName = {for (final e in stats) e.key.toLowerCase(): e.value};

    return Column(
      key: const ValueKey('categories'),
      children: [
        ...names.map((name) {
          final stat = byName[name] ??
              byName[_categoryAlt(name)] ??
              const _CategoryStat();
          final color = AppColors.categoryColor(name);
          final pct = stat.total == 0 ? 0 : (stat.accuracy * 100).round();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _profileSurface(context),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _profileShadow(context, 0.06),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_categoryEmoji(name),
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_categoryLabel(name),
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: context.textColor)),
                    Text(
                        stat.total == 0
                            ? 'Not played yet'
                            : '${stat.correct}/${stat.total} questions',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            color: context.hintColor)),
                  ],
                ),
              ),
              Text(stat.total == 0 ? '—' : '$pct%',
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color)),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: _MiniArcPainter(
                    progress: stat.total == 0 ? 0 : stat.accuracy,
                    color: color,
                    trackColor: context.borderColor,
                  ),
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 8),
        _categoryLeaderboardSection(context, user, isGuest, names),
      ],
    );
  }

  Widget _categoryLeaderboardSection(
      BuildContext context, UserData user, bool isGuest, List<String> names) {
    final selectedName = names[_categoryLeaderboardIndex];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: names.length,
          itemBuilder: (context, i) {
            final selected = i == _categoryLeaderboardIndex;
            final name = names[i];
            final chipColor = AppColors.categoryColor(name);
            return GestureDetector(
              onTap: () => setState(() => _categoryLeaderboardIndex = i),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? chipColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: selected ? chipColor : context.borderColor),
                ),
                child: Text(_categoryLabel(name),
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : context.hintColor)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      _leaderboard(
        context,
        isGuest,
        ref.watch(categoryLeaderboardProvider(_categoryAlt(selectedName))),
        '${_categoryLabel(selectedName)} Quiz Leaderboard',
        emptyText:
            'No ${_categoryLabel(selectedName).toLowerCase()} quiz scores yet',
        fallbackEntries: _selfCategoryLeaderboardFallback(user, selectedName),
      ),
    ]);
  }

  Widget _recentActivity(
    BuildContext context,
    List<QuizResult> quizzes,
    List<GameResult> games, {
    required bool loading,
  }) {
    final items = <_ActivityItem>[
      ...quizzes.take(5).map(_ActivityItem.quiz),
      ...games.take(5).map(_ActivityItem.game),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final shown = items.take(8).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Recent Activity',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: context.textColor)),
        const Spacer(),
        Text('${items.length} total',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: context.hintColor)),
      ]),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: _profileSurface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _profileShadow(context, 0.08),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Column(children: [
                  ShimmerBox(
                      width: double.infinity, height: 44, borderRadius: 12),
                  SizedBox(height: 8),
                  ShimmerBox(
                      width: double.infinity, height: 44, borderRadius: 12),
                  SizedBox(height: 8),
                  ShimmerBox(
                      width: double.infinity, height: 44, borderRadius: 12),
                ]),
              )
            : shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(22),
                    child: Center(
                      child: Text(
                          'Complete quizzes and games to\nsee your activity here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              color: context.hintColor)),
                    ),
                  )
                : Column(
                    children: shown.asMap().entries.map((entry) {
                      final last = entry.key == shown.length - 1;
                      return _activityRow(context, entry.value, last: last);
                    }).toList(),
                  ),
      ),
    ]);
  }

  Widget _activityRow(BuildContext context, _ActivityItem item,
      {required bool last}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
          child: Text(item.icon, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: context.textColor)),
                ),
                if (item.category != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.categoryColor(item.category!)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(_categoryLabel(item.category!),
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 9,
                            color: AppColors.categoryColor(item.category!),
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              Text('${item.score}/${item.total} · ${_timeAgo(item.date)}',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      color: context.hintColor)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('+${item.xp} XP',
                style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _accent)),
            Text('${item.percentage}%',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    color: context.hintColor)),
          ],
        ),
      ]),
    );
  }

  Widget _badges(
      BuildContext context, UserData user, Map<String, dynamic> summary) {
    final gamesPlayed = summary['gamesPlayed'];
    final bestScores = summary['bestScores'];
    final badgeData = [
      _BadgeData('First Quiz', 'Complete your first daily quiz', '⭐',
          user.totalQuizzes >= 1),
      _BadgeData('7 Day Streak', 'Keep your quiz streak alive for a full week',
          '🔥', user.streak >= 7),
      _BadgeData('30 Day Streak', 'Build a month-long streak', '🏆',
          user.streak >= 30),
      _BadgeData('Perfect Score', 'Score every question correctly in one quiz',
          '⚡', user.recentResults.any((r) => r.score == r.totalQuestions)),
      _BadgeData('10 Quizzes', 'Finish ten quizzes to prove the habit', '📚',
          user.totalQuizzes >= 10),
      _BadgeData('Fake Buster', 'Complete 5 Real or Fake games', '🎭',
          _nestedInt(gamesPlayed, 'real_or_fake') >= 5),
      _BadgeData('Historian', 'Complete 5 Oldest to Latest games', '📅',
          _nestedInt(gamesPlayed, 'oldest_to_latest') >= 5),
      _BadgeData(
          'Perfect Detector',
          'Score 10/10 on Real or Fake',
          '🏆',
          (_nestedMap(bestScores, 'real_or_fake')['percentage'] as num? ?? 0) >=
              100),
    ];
    final earned = badgeData.where((b) => b.earned).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Badges',
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: context.textColor)),
      const SizedBox(height: 4),
      Text('$earned of ${badgeData.length} unlocked',
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: context.hintColor)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 0.86,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: badgeData.map((badge) => _badgeTile(context, badge)).toList(),
      ),
    ]);
  }

  Widget _badgeTile(BuildContext context, _BadgeData badge) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _profileSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _profileShadow(context, 0.06),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: badge.earned
                ? const LinearGradient(colors: [Color(0xFFFFC15A), _accent])
                : null,
            color: badge.earned ? null : _profileBorder(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(badge.earned ? badge.icon : '🔒',
              style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 8),
        Text(badge.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: badge.earned ? context.textColor : context.hintColor)),
      ]),
    );
  }

  List<MapEntry<String, _CategoryStat>> _categoryStats(UserData user) {
    final catMap = <String, _CategoryStat>{};
    for (final r in user.recentResults) {
      if (r.attempts.isNotEmpty) {
        for (final attempt in r.attempts) {
          final key = attempt.category.toLowerCase();
          final stat = catMap.putIfAbsent(key, () => const _CategoryStat());
          catMap[key] = stat.add(correct: attempt.correct);
        }
      } else {
        for (final cat in r.categories) {
          final key = cat.toLowerCase();
          final stat = catMap.putIfAbsent(key, () => const _CategoryStat());
          catMap[key] = stat.addLegacy(r.percentage);
        }
      }
    }
    final entries = catMap.entries.toList()
      ..sort((a, b) => b.value.accuracy.compareTo(a.value.accuracy));
    return entries;
  }

  MapEntry<String, _CategoryStat>? _strongestCategory(
    List<MapEntry<String, _CategoryStat>> stats,
  ) {
    for (final entry in stats) {
      if (entry.value.total >= 3) return entry;
    }
    return null;
  }

  List<LeaderboardEntry> _selfGameLeaderboardFallback(
    UserData user,
    Map<String, dynamic> data,
    String gameId,
  ) {
    final played = _nestedInt(data['gamesPlayed'], gameId);
    if (played <= 0) return const [];
    final gameXp = _nestedInt(data['gameXp'], gameId);
    return [
      LeaderboardEntry(
        uid: AuthService.currentUser?.uid ?? 'you',
        name: user.name.trim().isEmpty ? 'You' : user.name,
        photoUrl: AuthService.currentUser?.photoURL ?? user.photoUrl,
        score: gameXp,
        streak: user.streak,
        isYou: true,
      ),
    ];
  }

  List<LeaderboardEntry> _selfCategoryLeaderboardFallback(
    UserData user,
    String category,
  ) {
    final key = _categoryAlt(category).toLowerCase();
    final xp = user.recentResults.where((result) {
      if (result.categories.length != 1) return false;
      return _categoryAlt(result.categories.first).toLowerCase() == key;
    }).fold<int>(0, (sum, result) => sum + result.pointsEarned);
    if (xp <= 0) return const [];
    return [
      LeaderboardEntry(
        uid: AuthService.currentUser?.uid ?? 'you',
        name: user.name.trim().isEmpty ? 'You' : user.name,
        photoUrl: AuthService.currentUser?.photoURL ?? user.photoUrl,
        score: xp,
        streak: user.streak,
        isYou: true,
      ),
    ];
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _nestedInt(Object? source, String key) {
    if (source is Map) return (source[key] as num? ?? 0).toInt();
    return 0;
  }

  static Map<String, dynamic> _nestedMap(Object? source, String key) {
    if (source is Map && source[key] is Map) {
      return Map<String, dynamic>.from(source[key] as Map);
    }
    return const {};
  }

  static String _categoryAlt(String name) =>
      name == 'tech' ? 'technology' : name;

  static String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
      case 'technology':
        return 'Technology';
      case 'world':
        return 'World';
      case 'politics':
        return 'Politics';
      case 'sports':
        return 'Sports';
      case 'business':
        return 'Business';
      default:
        return category.isEmpty
            ? 'Quiz'
            : '${category[0].toUpperCase()}${category.substring(1)}';
    }
  }

  static String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'world':
        return '🌍';
      case 'politics':
        return '🏛️';
      case 'sports':
        return '🏅';
      case 'tech':
      case 'technology':
        return '💻';
      case 'business':
        return '💼';
      default:
        return '⚡';
    }
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ActivityItem {
  final String name;
  final String icon;
  final Color color;
  final int score;
  final int total;
  final int xp;
  final DateTime date;
  final String? category;

  const _ActivityItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.score,
    required this.total,
    required this.xp,
    required this.date,
    this.category,
  });

  factory _ActivityItem.quiz(QuizResult result) {
    final category =
        result.categories.isNotEmpty ? result.categories.first : null;
    return _ActivityItem(
      name: 'Daily Quiz',
      icon: '⚡',
      color: _ProfileScreenState._accent,
      score: result.score,
      total: result.totalQuestions,
      xp: result.pointsEarned,
      date: DateTime.tryParse(result.date) ?? DateTime.now(),
      category: category,
    );
  }

  factory _ActivityItem.game(GameResult result) {
    final icon = switch (result.gameId) {
      'real_or_fake' => '🎭',
      'oldest_to_latest' => '📅',
      'headline_match' => '🗞️',
      'source_sleuth' => '🕵️',
      _ => '🎮',
    };
    final color = switch (result.gameId) {
      'real_or_fake' => _ProfileScreenState._gamePurple,
      'oldest_to_latest' => _ProfileScreenState._gameBlue,
      'headline_match' => AppColors.teal,
      'source_sleuth' => _ProfileScreenState._accent,
      _ => AppColors.purple,
    };
    return _ActivityItem(
      name: result.gameName,
      icon: icon,
      color: color,
      score: result.score,
      total: result.total,
      xp: result.xpEarned,
      date: result.playedAt,
    );
  }

  int get percentage => total > 0 ? (score / total * 100).round() : 0;
}

class _BadgeData {
  final String name;
  final String description;
  final String icon;
  final bool earned;

  const _BadgeData(this.name, this.description, this.icon, this.earned);
}

class _MiniArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _MiniArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 6) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, pi * 2, false, track);
    canvas.drawArc(
        rect, -pi / 2, pi * 2 * progress.clamp(0.0, 1.0), false, fill);
  }

  @override
  bool shouldRepaint(covariant _MiniArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

class _StreakDay {
  final DateTime date;
  final QuizResult? result;
  final bool isToday;

  const _StreakDay(
      {required this.date, required this.result, required this.isToday});
}

class _StreakCalendarTile extends StatelessWidget {
  final _StreakDay day;
  final Duration delay;

  const _StreakCalendarTile({required this.day, required this.delay});

  @override
  Widget build(BuildContext context) {
    final result = day.result;
    final active = result != null;
    final pct = result?.percentage ?? 0.0;
    final color = !active
        ? context.inputBg
        : pct >= 0.8
            ? AppColors.green
            : pct >= 0.6
                ? AppColors.accent
                : pct >= 0.4
                    ? AppColors.orange
                    : AppColors.red;
    final label = day.date.day.toString();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay.inMilliseconds),
      curve: Curves.easeOutBack,
      builder: (context, v, child) =>
          Transform.scale(scale: 0.75 + (0.25 * v), child: child),
      child: Container(
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2 + (pct * 0.45))
              : context.inputBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: day.isToday
                  ? AppColors.accent
                  : active
                      ? color.withValues(alpha: 0.42)
                      : context.borderColor,
              width: day.isToday ? 1.6 : 1),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Stack(children: [
          Center(
              child: active
                  ? Icon(
                      result.score == result.totalQuestions
                          ? Icons.star_rounded
                          : Icons.check_rounded,
                      size: 13,
                      color: Colors.white)
                  : Text(label,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: context.hintColor.withValues(alpha: 0.72)))),
          if (day.isToday)
            Align(
                alignment: Alignment.topRight,
                child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle))),
        ]),
      ),
    );
  }
}

class _RecentQuizRow extends StatelessWidget {
  final QuizResult result;

  const _RecentQuizRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.score == result.totalQuestions
        ? AppColors.green
        : result.percentage >= 0.6
            ? AppColors.accent
            : result.percentage >= 0.4
                ? AppColors.orange
                : AppColors.red;
    final categories = result.categories.take(2).toList();
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.16))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Center(
                    child: Text('${result.score}/${result.totalQuestions}',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: color)))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(result.performanceLabel,
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: context.textColor))),
                    Text(result.percentageString,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: color)),
                  ]),
                  const SizedBox(height: 3),
                  Text(_formatResultDate(result.date),
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.hintColor)),
                  const SizedBox(height: 8),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                          value: result.percentage,
                          minHeight: 6,
                          backgroundColor:
                              context.borderColor.withValues(alpha: 0.45),
                          valueColor: AlwaysStoppedAnimation(color))),
                ])),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _recentMeta(context, Icons.bolt_rounded,
                '+${result.pointsEarned} pts', AppColors.gold),
            const SizedBox(width: 8),
            _recentMeta(context, Icons.timer_rounded,
                _formatDuration(result.timeTakenSeconds), AppColors.blue),
            const Spacer(),
            if (categories.isNotEmpty)
              Flexible(
                  child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 5,
                      runSpacing: 5,
                      children: categories
                          .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.categoryColor(c)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text(c[0].toUpperCase() + c.substring(1),
                                  style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.categoryColor(c)))))
                          .toList())),
          ]),
        ]));
  }

  Widget _recentMeta(
      BuildContext context, IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: context.hintColor)),
    ]);
  }
}

String _formatResultDate(String raw) {
  try {
    final date = DateTime.parse(raw);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  } catch (_) {
    return raw;
  }
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return 'no time';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes == 0) return '${rest}s';
  return '${minutes}m ${rest}s';
}

// Sparkline chart using CustomPainter
class _ScoreSparkline extends StatelessWidget {
  final List<double> values;
  final double width;
  final double height;
  const _ScoreSparkline(
      {required this.values, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(
          values: values, color: AppColors.accent, isDark: context.isDark),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool isDark;
  const _SparklinePainter(
      {required this.values, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).clamp(0.1, 1.0);

    double xOf(int i) => i / (values.length - 1) * size.width;
    double yOf(double v) =>
        size.height -
        ((v - minV) / range * size.height * 0.85 + size.height * 0.075);

    final path = Path();
    path.moveTo(xOf(0), yOf(values[0]));
    for (int i = 1; i < values.length; i++) {
      final cx = (xOf(i - 1) + xOf(i)) / 2;
      path.cubicTo(
          cx, yOf(values[i - 1]), cx, yOf(values[i]), xOf(i), yOf(values[i]));
    }

    // Fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(xOf(values.length - 1), size.height);
    fillPath.lineTo(xOf(0), size.height);
    fillPath.close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.0)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Line
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    // Dot at last value
    canvas.drawCircle(Offset(xOf(values.length - 1), yOf(values.last)), 3.5,
        Paint()..color = color);
    canvas.drawCircle(
        Offset(xOf(values.length - 1), yOf(values.last)),
        3.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

// SETTINGS SCREEN — fully interactive

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(userProvider);
    final authUser =
        ref.watch(authStateProvider).valueOrNull ?? AuthService.currentUser;
    final isSignedIn = authUser != null && !authUser.isAnonymous;
    final authEmail = authUser?.email ?? authUser?.displayName;
    final hasPro = user.isPro && isSignedIn;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
            child: Row(children: [
              IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: context.subColor),
                  onPressed: () => Navigator.of(context).pop()),
              Text('Settings',
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: context.textColor,
                      letterSpacing: -0.4,
                      height: 1.02)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── APPEARANCE ───────────────────────────────────────────────
              _sectionCard(isDark,
                  const [Color(0xFF7B2FBE), Color(0xFF5B1E93)],
                  const Color(0xFF3D0F70),
                  Icons.palette_rounded,
                  'Appearance',
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(
                                themeMode == ThemeMode.dark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: Colors.white,
                                size: 20)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Theme',
                                  style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              Text(
                                  themeMode == ThemeMode.dark
                                      ? 'Dark mode'
                                      : themeMode == ThemeMode.system
                                          ? 'System default'
                                          : 'Light mode',
                                  style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 10,
                                      color: Colors.white.withValues(
                                          alpha: 0.7))),
                            ])),
                        Container(
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              _ThemeChip(
                                  icon: Icons.light_mode_rounded,
                                  active: themeMode == ThemeMode.light,
                                  light: true,
                                  onTap: () => ref
                                      .read(themeProvider.notifier)
                                      .setLight()),
                              _ThemeChip(
                                  icon: Icons.dark_mode_rounded,
                                  active: themeMode == ThemeMode.dark,
                                  light: true,
                                  onTap: () => ref
                                      .read(themeProvider.notifier)
                                      .setDark()),
                              _ThemeChip(
                                  icon: Icons.phone_android_rounded,
                                  active: themeMode == ThemeMode.system,
                                  light: true,
                                  onTap: () => ref
                                      .read(themeProvider.notifier)
                                      .setSystem()),
                            ])),
                      ]))),
              const SizedBox(height: 16),
              // ── PREFERENCES ──────────────────────────────────────────────
              _sectionCard(isDark,
                  [AppColors.accent, const Color(0xFFE85D04)],
                  const Color(0xFF7A2A00),
                  Icons.tune_rounded,
                  'Preferences',
                  Column(children: [
                    _SettingsTile(
                        icon: Icons.language_rounded,
                        color: AppColors.blue,
                        title: 'News Categories',
                        sub: '${user.selectedCategories.length} selected',
                        onTap: () =>
                            _showCategoriesSheet(context, ref, user),
                        light: true),
                    Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.12)),
                    _SettingsTile(
                        icon: Icons.notifications_rounded,
                        color: AppColors.accent,
                        title: 'Daily Reminder',
                        sub: _formatReminderTime(
                            user.notificationHour, user.notificationMinute),
                        onTap: () => _showNotifSheet(context, ref, user),
                        light: true),
                  ])),
              const SizedBox(height: 16),
              // ── ACCOUNT ───────────────────────────────────────────────────
              _sectionCard(isDark,
                  const [Color(0xFF1A6B45), Color(0xFF0D4D32)],
                  const Color(0xFF063322),
                  Icons.manage_accounts_rounded,
                  'Account',
                  Column(children: [
                    _SettingsTile(
                        icon: Icons.person_rounded,
                        color: AppColors.purple,
                        title: 'Edit Profile',
                        sub: user.name,
                        onTap: () =>
                            _showEditNameDialog(context, ref, user),
                        light: true),
                    Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.12)),
                    _SettingsTile(
                        icon: Icons.lock_rounded,
                        color: AppColors.green,
                        title: 'Privacy',
                        sub: 'Local storage, cloud sync, and purchases',
                        onTap: () => _showPrivacySheet(context),
                        light: true),
                    Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.12)),
                    if (isSignedIn)
                      _SettingsTile(
                          icon: Icons.logout_rounded,
                          color: AppColors.red,
                          title: 'Sign Out',
                          sub: authEmail ?? 'Signed in',
                          onTap: () => _handleSignOut(context, ref),
                          light: true)
                    else
                      _SettingsTile(
                          icon: Icons.login_rounded,
                          color: AppColors.blue,
                          title: 'Sign In / Create Account',
                          sub: 'Sync your progress across devices',
                          onTap: () => _showAuthSheet(context, ref),
                          light: true),
                  ])),
              const SizedBox(height: 16),
              // ── PRO ───────────────────────────────────────────────────────
              _sectionCard(isDark,
                  const [Color(0xFFD97706), Color(0xFFB45309)],
                  const Color(0xFF7A3800),
                  Icons.star_rounded,
                  'Pro',
                  GestureDetector(
                      onTap: () => hasPro
                          ? _showProActiveDialog(context)
                          : _showProSheet(context, ref, user,
                              canActivatePro: isSignedIn),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(children: [
                            Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.star_rounded,
                                    color: Colors.white, size: 20)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      hasPro
                                          ? 'Briefed Pro'
                                          : 'Upgrade to Pro',
                                      style: const TextStyle(
                                          fontFamily: AppFonts.body,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                  Text(
                                      hasPro
                                          ? 'Active · Unlimited quiz replays'
                                          : '${ProPurchaseService.fallbackPriceLabel} · Cancel anytime',
                                      style: TextStyle(
                                          fontFamily: AppFonts.body,
                                          fontSize: 10,
                                          color: Colors.white
                                              .withValues(alpha: 0.7))),
                                ])),
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 18),
                          ])))),
            ])))])));
  }

  Widget _sectionCard(bool isDark, List<Color> gradient, Color shadow,
      IconData icon, String title, Widget content) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 0, offset: const Offset(0, 5)),
          BoxShadow(
              color: gradient[0].withValues(alpha: isDark ? 0.18 : 0.30),
              blurRadius: 28,
              offset: const Offset(0, 14)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(children: [
            Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 16)),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.02)),
          ]),
        ),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
        content,
      ]),
    );
  }

  void _showCategoriesSheet(
      BuildContext context, WidgetRef ref, UserData user) {
    final selected = List<String>.from(user.selectedCategories);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                    color: ctx.borderColor,
                                    borderRadius: BorderRadius.circular(2)))),
                        Text('News Categories',
                            style: TextStyle(
                                fontFamily: AppFonts.display,
                                height: 1.02,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ctx.textColor)),
                        const SizedBox(height: 4),
                        Text(
                            'Choose what topics appear in your quiz and briefing',
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 12,
                                color: ctx.subColor)),
                        const SizedBox(height: 20),
                        GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: AppConstants.allCategories.map((cat) {
                              final id = cat['id']!;
                              final on = selected.contains(id);
                              final color =
                                  AppColors.categoryColor(cat['label']!);
                              return GestureDetector(
                                  onTap: () => setS(() {
                                        if (on) {
                                          if (selected.length > 1) {
                                            selected.remove(id);
                                          }
                                        } else {
                                          selected.add(id);
                                        }
                                      }),
                                  child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                          color: on
                                              ? color.withValues(alpha: 0.1)
                                              : ctx.inputBg,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: on
                                                  ? color.withValues(alpha: 0.4)
                                                  : ctx.borderColor)),
                                      child: Row(children: [
                                        Icon(_iconForCat(id),
                                            size: 16,
                                            color: on ? color : ctx.hintColor),
                                        const SizedBox(width: 8),
                                        Text(cat['label']!,
                                            style: TextStyle(
                                                fontFamily: AppFonts.body,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: on
                                                    ? ctx.textColor
                                                    : ctx.subColor)),
                                        if (on) ...[
                                          const Spacer(),
                                          Icon(Icons.check_circle_rounded,
                                              size: 14, color: color)
                                        ],
                                      ])));
                            }).toList()),
                        const SizedBox(height: 20),
                        AccentButton(
                            text: 'Save',
                            onTap: () {
                              ref
                                  .read(userProvider.notifier)
                                  .updateCategories(selected);
                              Navigator.of(ctx).pop();
                            },
                            icon: Icons.check_rounded),
                      ]));
            }));
  }

  void _showNotifSheet(BuildContext context, WidgetRef ref, UserData user) {
    final options = [
      {
        'label': '7:00 AM',
        'sub': 'Early bird',
        'icon': Icons.wb_sunny_outlined,
        'hour': 7,
        'minute': 0
      },
      {
        'label': '8:30 AM',
        'sub': 'Morning',
        'icon': Icons.light_mode_outlined,
        'hour': 8,
        'minute': 30
      },
      {
        'label': '12:00 PM',
        'sub': 'Lunch break',
        'icon': Icons.lunch_dining_outlined,
        'hour': 12,
        'minute': 0
      },
      {
        'label': '6:00 PM',
        'sub': 'Evening',
        'icon': Icons.wb_twilight_outlined,
        'hour': 18,
        'minute': 0
      },
      {
        'label': '9:00 PM',
        'sub': 'Night owl',
        'icon': Icons.nightlight_outlined,
        'hour': 21,
        'minute': 0
      },
    ];
    int selectedHour = user.notificationHour;
    int selectedMinute = user.notificationMinute;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                    color: ctx.borderColor,
                                    borderRadius: BorderRadius.circular(2)))),
                        Text('Daily Reminder',
                            style: TextStyle(
                                fontFamily: AppFonts.display,
                                height: 1.02,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ctx.textColor)),
                        const SizedBox(height: 4),
                        Text("When should we remind you to take today's quiz?",
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 12,
                                color: ctx.subColor)),
                        const SizedBox(height: 20),
                        ...options.map((opt) {
                          final on = selectedHour == opt['hour'] &&
                              selectedMinute == opt['minute'];
                          return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                  onTap: () => setS(() {
                                        selectedHour = opt['hour'] as int;
                                        selectedMinute = opt['minute'] as int;
                                      }),
                                  child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: on
                                              ? AppColors.accent
                                                  .withValues(alpha: 0.08)
                                              : ctx.inputBg,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: on
                                                  ? AppColors.accent
                                                      .withValues(alpha: 0.4)
                                                  : ctx.borderColor)),
                                      child: Row(children: [
                                        Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                                color: on
                                                    ? AppColors.accent
                                                        .withValues(alpha: 0.15)
                                                    : ctx.cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Icon(opt['icon'] as IconData,
                                                color: on
                                                    ? AppColors.accent
                                                    : ctx.hintColor,
                                                size: 20)),
                                        const SizedBox(width: 14),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(opt['label'] as String,
                                                  style: TextStyle(
                                                      fontFamily:
                                                          AppFonts.display,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: on
                                                          ? ctx.textColor
                                                          : ctx.subColor)),
                                              Text(opt['sub'] as String,
                                                  style: TextStyle(
                                                      fontFamily:
                                                          AppFonts.display,
                                                      fontSize: 11,
                                                      color: ctx.hintColor)),
                                            ])),
                                        AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: on
                                                    ? AppColors.accent
                                                    : Colors.transparent,
                                                border: Border.all(
                                                    color: on
                                                        ? AppColors.accent
                                                        : ctx.hintColor,
                                                    width: 2)),
                                            child: on
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 13)
                                                : null),
                                      ]))));
                        }),
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                      context: ctx,
                                      initialTime: TimeOfDay(
                                          hour: selectedHour,
                                          minute: selectedMinute));
                                  if (picked != null) {
                                    setS(() {
                                      selectedHour = picked.hour;
                                      selectedMinute = picked.minute;
                                    });
                                  }
                                },
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: options.any((o) =>
                                                selectedHour == o['hour'] &&
                                                selectedMinute == o['minute'])
                                            ? ctx.inputBg
                                            : AppColors.accent
                                                .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: options.any((o) =>
                                                    selectedHour == o['hour'] &&
                                                    selectedMinute ==
                                                        o['minute'])
                                                ? ctx.borderColor
                                                : AppColors.accent
                                                    .withValues(alpha: 0.4))),
                                    child: Row(children: [
                                      Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                              color: ctx.cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Icon(
                                              Icons.edit_calendar_rounded,
                                              color: options.any((o) =>
                                                      selectedHour ==
                                                          o['hour'] &&
                                                      selectedMinute ==
                                                          o['minute'])
                                                  ? ctx.hintColor
                                                  : AppColors.accent,
                                              size: 20)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(
                                                _formatReminderTime(
                                                    selectedHour,
                                                    selectedMinute),
                                                style: TextStyle(
                                                    fontFamily:
                                                        AppFonts.display,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: ctx.textColor)),
                                            Text('Choose your own time',
                                                style: TextStyle(
                                                    fontFamily:
                                                        AppFonts.display,
                                                    fontSize: 11,
                                                    color: ctx.hintColor)),
                                          ])),
                                      const Icon(Icons.chevron_right_rounded,
                                          size: 18),
                                    ])))),
                        AccentButton(
                            text: 'Save',
                            onTap: () {
                              ref
                                  .read(userProvider.notifier)
                                  .updateNotificationTime(
                                      selectedHour, selectedMinute);
                              Navigator.of(ctx).pop();
                            },
                            icon: Icons.check_rounded),
                      ]));
            }));
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, UserData user) {
    final ctrl = TextEditingController(text: user.name);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: ctx.cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Edit Profile',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w800,
                        color: ctx.textColor)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: TextStyle(
                          fontFamily: AppFonts.body, color: ctx.textColor),
                      decoration: InputDecoration(
                          labelText: 'Your name',
                          labelStyle: TextStyle(
                              fontFamily: AppFonts.body, color: ctx.hintColor),
                          filled: true,
                          fillColor: ctx.inputBg,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.accent)))),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: ctx.hintColor))),
                  TextButton(
                      onPressed: () {
                        final name = ctrl.text.trim();
                        if (name.isNotEmpty) {
                          ref.read(userProvider.notifier).updateName(name);
                        }
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Save',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800))),
                ]));
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 32 + MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                  color: ctx.borderColor,
                                  borderRadius: BorderRadius.circular(2)))),
                      Text('Privacy',
                          style: TextStyle(
                              fontFamily: AppFonts.display,
                              height: 1.02,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ctx.textColor)),
                      const SizedBox(height: 6),
                      Text(
                          'Briefed stores some data on your device and uses trusted services to run accounts, sync, purchases, and reminders.',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              color: ctx.subColor,
                              height: 1.55)),
                      const SizedBox(height: 18),
                      ...[
                        (
                          'Local app data',
                          'Your name, categories, quiz history, streaks, scores, reminder time, theme, and cached quiz questions may be saved on this device.',
                          Icons.phone_android_rounded,
                          AppColors.green
                        ),
                        (
                          'Accounts and sync',
                          'If you sign in with email, Google, or continue as a guest, Firebase may store your user ID, email, display name, photo URL, progress, preferences, and leaderboard scores.',
                          Icons.cloud_sync_rounded,
                          AppColors.blue
                        ),
                        (
                          'Purchases',
                          'Briefed Pro is a one-time purchase processed by Google Play Billing. No subscription or recurring charges.',
                          Icons.payments_rounded,
                          AppColors.gold
                        ),
                        (
                          'Notifications',
                          'If you allow reminders, Briefed uses your selected reminder time and Android notification permission to schedule local daily quiz alerts.',
                          Icons.notifications_rounded,
                          AppColors.accent
                        ),
                        (
                          'Content services',
                          'Briefed uses news and AI/content services to fetch headlines and generate quiz content. We do not send your account details for quiz generation.',
                          Icons.api_rounded,
                          AppColors.purple
                        ),
                        (
                          'Advertising',
                          'Free users see banner ads powered by Google AdMob and occasional interstitial ads in games on your second play each day. Upgrade to Pro to remove all ads. You can manage ad personalisation in your device settings.',
                          Icons.ad_units_rounded,
                          AppColors.orange
                        ),
                        (
                          'Your choices',
                          'You can sign out, disable notifications in the app or device settings, manage ad personalization in Google/device settings, and request account or data deletion by email.',
                          Icons.privacy_tip_rounded,
                          AppColors.red
                        ),
                      ].map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                        color: item.$4.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Icon(item.$3,
                                        color: item.$4, size: 18)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(item.$1,
                                          style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: ctx.textColor)),
                                      const SizedBox(height: 3),
                                      Text(item.$2,
                                          style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 11,
                                              color: ctx.subColor,
                                              height: 1.55)),
                                    ])),
                              ]))),
                      const SizedBox(height: 4),
                      AccentButton(
                          text: 'Open Privacy Policy',
                          onTap: () => _launchUrl(
                              'https://sites.google.com/view/binay-briefed-contact/privacy-policy'),
                          icon: Icons.open_in_new_rounded),
                      const SizedBox(height: 10),
                      Center(
                          child: TextButton.icon(
                              onPressed: () => _launchUrl(
                                  'https://sites.google.com/view/binay-briefed-contact/data-deletion'),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                              label: const Text('Request Data Deletion',
                                  style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontWeight: FontWeight.w700)))),
                    ]))));
  }

  void _showProActiveDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: ctx.cardColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.gold, Color(0xFFFF9100)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
              ),
              child:
                  const Icon(Icons.star_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text('You\'re a Pro!',
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: ctx.textColor)),
            const SizedBox(height: 8),
            Text(
              'Thanks for supporting Briefed.\nEnjoy unlimited replays, no ads,\nand all pro perks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  height: 1.55,
                  color: ctx.hintColor),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Enjoy Briefed Pro',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showProSheet(
    BuildContext context,
    WidgetRef ref,
    UserData user, {
    required bool canActivatePro,
  }) {
    showBriefedProSheet(context, ref);
  }

  void _showAuthSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _AuthSheet(ref: ref));
  }

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    // Capture Navigator before any async gap — the auth stream will rebuild
    // SettingsScreen during signOut(), making the original context stale.
    final nav = Navigator.of(context);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: ctx.cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Sign Out',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w800,
                        color: ctx.textColor)),
                content: Text('Are you sure you want to sign out?',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: ctx.subColor)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: ctx.hintColor))),
                  TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await AuthService.signOut();
                        await StorageService.setIsPro(false);
                        ref.read(userProvider.notifier).reload();
                        nav.pushNamedAndRemoveUntil('/signin', (_) => false);
                      },
                      child: const Text('Sign Out',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.red,
                              fontWeight: FontWeight.w800))),
                ]));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: context.hintColor,
              letterSpacing: 2)));
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNTRY PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSelect;
  const _CountryPickerSheet({required this.current, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _search = TextEditingController();
  List<Map<String, String>> _filtered = [];

  static final _sorted = [
    AppConstants.allCountries.firstWhere((c) => c['code'] == 'world'),
    ...(AppConstants.allCountries.where((c) => c['code'] != 'world').toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!))),
  ];

  @override
  void initState() {
    super.initState();
    _filtered = _sorted;
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _search.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _sorted
          : _sorted
              .where((c) =>
                  c['name']!.toLowerCase().contains(q) ||
                  c['code']!.contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(children: [
        // drag handle
        Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('News Country',
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textColor)),
            const SizedBox(height: 2),
            Text('Your quiz and briefing will use news from this country',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: context.subColor)),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              autofocus: false,
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: context.textColor),
              decoration: InputDecoration(
                hintText: 'Search countries…',
                hintStyle: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    color: context.hintColor),
                prefixIcon:
                    Icon(Icons.search_rounded, color: context.hintColor),
                filled: true,
                fillColor: context.inputBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final c = _filtered[i];
              final isSelected = c['code'] == widget.current;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  widget.onSelect(c['code']!);
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.35)
                            : Colors.transparent),
                  ),
                  child: Row(children: [
                    Text(c['flag']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(c['name']!,
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? context.textColor
                                    : context.subColor))),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.accent),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  final bool light;
  const _SettingsTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.sub,
      required this.onTap,
      this.light = false});
  @override
  Widget build(BuildContext context) {
    final textCol = light ? Colors.white : context.textColor;
    final subCol =
        light ? Colors.white.withValues(alpha: 0.7) : context.hintColor;
    final iconBg =
        light ? Colors.white.withValues(alpha: 0.18) : color.withValues(alpha: 0.12);
    final iconCol = light ? Colors.white : color;
    final chevron =
        light ? Colors.white.withValues(alpha: 0.6) : context.hintColor;
    return GestureDetector(
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconCol, size: 18)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textCol)),
                    Text(sub,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 10,
                            color: subCol)),
                  ])),
              Icon(Icons.chevron_right_rounded, color: chevron, size: 18),
            ])));
  }
}

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool light;
  final VoidCallback onTap;
  const _ThemeChip(
      {required this.icon,
      required this.active,
      required this.onTap,
      this.light = false});
  @override
  Widget build(BuildContext context) {
    final bg = active
        ? (light ? Colors.white : context.cardColor)
        : Colors.transparent;
    final iconCol = active
        ? (light ? AppColors.accent : AppColors.accent)
        : (light ? Colors.white.withValues(alpha: 0.6) : context.hintColor);
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
                border: active && !light
                    ? Border.all(color: context.borderColor)
                    : null,
                boxShadow: active && !light
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : []),
            child: Icon(icon, size: 16, color: iconCol)));
  }
}

// ─── Auth Sheet ───────────────────────────────────────────────────────────────

class _AuthSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AuthSheet({required this.ref});
  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _error;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        final cred = await AuthService.createAccount(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            name: _nameCtrl.text.trim());
        await ref.read(userProvider.notifier).syncAuthProfile(cred.user);
      } else {
        final cred = await AuthService.signInWithEmail(
            email: _emailCtrl.text, password: _passwordCtrl.text);
        await ref.read(userProvider.notifier).syncAuthProfile(cred.user);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = _friendly(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cred = await AuthService.signInWithGoogle();
      await ref.read(userProvider.notifier).syncAuthProfile(cred.user);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = _friendly(e);
        _isLoading = false;
      });
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'Incorrect password.';
    }
    if (s.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (s.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (s.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (s.contains('network-request-failed')) return 'No internet connection.';
    if (s.contains('cancelled') || s.contains('canceled')) {
      return 'Sign in cancelled.';
    }
    return 'Error: $s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2)))),

          // Sign In / Create Account toggle
          Container(
            decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              _tab('Sign In', !_isSignUp),
              _tab('Create Account', _isSignUp)
            ]),
          ),
          const SizedBox(height: 20),

          if (_isSignUp) ...[
            _field(_nameCtrl, 'Your name', Icons.person_outline_rounded),
            const SizedBox(height: 12),
          ],
          _field(_emailCtrl, 'Email address', Icons.mail_outline_rounded,
              type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_passwordCtrl, 'Password', Icons.lock_outline_rounded,
              obscure: true),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.25))),
                child: Text(_error!,
                    style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: AppColors.red))),
            const SizedBox(height: 14),
          ],

          // Primary button
          GestureDetector(
              onTap: _isLoading ? null : _submit,
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDark]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5))
                      ]),
                  child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white))))),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(child: Divider(color: context.borderColor)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        color: context.hintColor))),
            Expanded(child: Divider(color: context.borderColor)),
          ]),
          const SizedBox(height: 14),

          // Google Sign In
          GestureDetector(
              onTap: _isLoading ? null : _googleSignIn,
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: context.inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _GoogleLogo(size: 26),
                        const SizedBox(width: 10),
                        Text('Continue with Google',
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.textColor)),
                      ]))),
        ]));
  }

  Widget _tab(String label, bool active) => Expanded(
      child: GestureDetector(
          onTap: () => setState(() {
                _isSignUp = label == 'Create Account';
                _error = null;
              }),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: active ? context.cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : []),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          active ? context.textColor : context.hintColor)))));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
          {bool obscure = false, TextInputType type = TextInputType.text}) =>
      TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: type,
          style: TextStyle(
              fontFamily: AppFonts.body,
              color: context.textColor,
              fontSize: 14),
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                  fontFamily: AppFonts.body,
                  color: context.hintColor,
                  fontSize: 13),
              prefixIcon: Icon(icon, color: context.hintColor, size: 18),
              filled: true,
              fillColor: context.inputBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accent))));
}

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE LOGO WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size s) {
    final side = min(s.width, s.height);
    const logoWidth = 533.5;
    const logoHeight = 544.3;
    final scale = min(side / logoWidth, side / logoHeight);
    final dx = (s.width - logoWidth * scale) / 2;
    final dy = (s.height - logoHeight * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = _blue;
    canvas.drawPath(_bluePath(), paint);

    paint.color = _green;
    canvas.drawPath(_greenPath(), paint);

    paint.color = _yellow;
    canvas.drawPath(_yellowPath(), paint);

    paint.color = _red;
    canvas.drawPath(_redPath(), paint);

    canvas.restore();
  }

  Path _bluePath() {
    return Path()
      ..moveTo(533.5, 278.4)
      ..relativeCubicTo(0, -18.5, -1.5, -37.1, -4.7, -55.3)
      ..lineTo(272.1, 223.1)
      ..relativeLineTo(0, 104.8)
      ..relativeLineTo(147, 0)
      ..relativeCubicTo(-6.1, 33.8, -25.7, 63.7, -54.4, 82.7)
      ..relativeLineTo(0, 68)
      ..relativeLineTo(87.7, 0)
      ..relativeCubicTo(51.5, -47.4, 81.1, -117.4, 81.1, -200.2)
      ..close();
  }

  Path _greenPath() {
    return Path()
      ..moveTo(272.1, 544.3)
      ..relativeCubicTo(73.4, 0, 135.3, -24.1, 180.4, -65.7)
      ..relativeLineTo(-87.7, -68)
      ..relativeCubicTo(-24.4, 16.6, -55.9, 26, -92.6, 26)
      ..relativeCubicTo(-71, 0, -131.2, -47.9, -152.8, -112.3)
      ..lineTo(28.9, 324.3)
      ..relativeLineTo(0, 70.1)
      ..relativeCubicTo(46.2, 91.9, 140.3, 149.9, 243.2, 149.9)
      ..close();
  }

  Path _yellowPath() {
    return Path()
      ..moveTo(119.3, 324.3)
      ..relativeCubicTo(-11.4, -33.8, -11.4, -70.4, 0, -104.2)
      ..lineTo(119.3, 150)
      ..lineTo(28.9, 150)
      ..relativeCubicTo(-38.6, 76.9, -38.6, 167.5, 0, 244.4)
      ..relativeLineTo(90.4, -70.1)
      ..close();
  }

  Path _redPath() {
    return Path()
      ..moveTo(272.1, 107.7)
      ..relativeCubicTo(38.8, -0.6, 76.3, 14, 104.4, 40.8)
      ..relativeLineTo(77.7, -77.7)
      ..cubicTo(405, 24.6, 339.7, -0.8, 272.1, 0)
      ..cubicTo(169.2, 0, 75.1, 58, 28.9, 150)
      ..relativeLineTo(90.4, 70.1)
      ..relativeCubicTo(21.5, -64.5, 81.8, -112.4, 152.8, -112.4)
      ..close();
  }

  @override
  bool shouldRepaint(_GoogleGPainter _) => false;
}

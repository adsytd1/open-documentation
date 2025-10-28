# 🔥 Firecrawl: Примеры использования для юридических источников

## 📚 Базовые примеры

### 1. Scrape одной страницы закона

```bash
curl -X POST https://api.firecrawl.dev/v2/scrape \
  -H 'Authorization: Bearer fc-YOUR-KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "url": "https://online.zakon.kz/Document/?doc_id=31577399",
    "formats": ["markdown"],
    "onlyMainContent": true,
    "parsers": ["pdf"],
    "maxAge": 2592000000
  }'
```

### 2. Crawl всего раздела законодательства

```bash
curl -X POST https://api.firecrawl.dev/v2/crawl \
  -H 'Authorization: Bearer fc-YOUR-KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "url": "https://online.zakon.kz/",
    "limit": 200,
    "includePaths": ["/Document/.*"],
    "excludePaths": ["/images/.*", "/scripts/.*"],
    "scrapeOptions": {
      "formats": ["markdown"],
      "onlyMainContent": true,
      "maxAge": 604800000,
      "parsers": [{"type": "pdf", "maxPages": 1000}]
    }
  }'
```

### 3. Extract структурированных данных из судебной практики

```bash
curl -X POST https://api.firecrawl.dev/v2/extract \
  -H 'Authorization: Bearer fc-YOUR-KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "urls": ["https://sud.gov.kz/rus/content/sudebnaya-praktika"],
    "prompt": "Извлеки из судебных решений: номер дела, дату, суть спора, решение суда",
    "schema": {
      "type": "object",
      "properties": {
        "cases": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "case_number": {"type": "string"},
              "date": {"type": "string"},
              "summary": {"type": "string"},
              "decision": {"type": "string"},
              "legal_basis": {"type": "string"}
            }
          }
        }
      }
    },
    "scrapeOptions": {
      "formats": ["markdown"],
      "parsers": ["pdf"]
    }
  }'
```

---

## 🎯 Специфичные для РК источники

### Гражданский кодекс РК

```javascript
// n8n HTTP Request node
{
  url: "https://api.firecrawl.dev/v2/crawl",
  method: "POST",
  headers: {
    "Authorization": "Bearer {{ $credentials.firecrawlApiKey }}"
  },
  body: {
    url: "https://online.zakon.kz/Document/?doc_id=31577399",
    limit: 300,
    prompt: "Crawl all sections about contracts and obligations (chapters 26-29)",
    scrapeOptions: {
      formats: ["markdown"],
      includeTags: ["div.document", "p", "article", "section"],
      excludeTags: ["nav", "footer", "aside"],
      onlyMainContent: true,
      parsers: [{ type: "pdf", maxPages: 2000 }],
      maxAge: 2592000000, // месяц
      blockAds: true
    }
  }
}
```

### Трудовой кодекс РК

```javascript
{
  url: "https://api.firecrawl.dev/v2/scrape",
  body: {
    url: "https://online.zakon.kz/Document/?doc_id=38910832",
    formats: [{
      type: "json",
      prompt: "Extract all articles about employment contracts, working hours, and termination procedures",
      schema: {
        type: "object",
        properties: {
          sections: {
            type: "array",
            items: {
              type: "object",
              properties: {
                section_number: { type: "string" },
                title: { type: "string" },
                articles: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      article_number: { type: "string" },
                      content: { type: "string" }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }],
    parsers: ["pdf"]
  }
}
```

### Судебная практика

```javascript
// Map сначала для получения всех URL дел
{
  url: "https://api.firecrawl.dev/v2/map",
  body: {
    url: "https://sud.gov.kz/",
    search: "договор аренда спор",
    limit: 100,
    sitemap: "include"
  }
}

// Потом batch scrape найденных URL
{
  url: "https://api.firecrawl.dev/v2/batch/scrape",
  body: {
    urls: [/* URLs from map */],
    formats: ["markdown"],
    maxConcurrency: 10,
    scrapeOptions: {
      parsers: ["pdf"],
      onlyMainContent: true
    }
  }
}
```

---

## 🔧 n8n Integration Patterns

### Pattern 1: Sequential Crawl с обработкой

```
┌─────────────┐
│ Firecrawl   │
│ Start Crawl │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Wait 30s  │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌─────────────┐
│ Check       │──NO──│  Wait more  │
│ Status      │      └──────┬──────┘
└──────┬──────┘             │
       │YES                 │
       ▼                    │
┌─────────────┐             │
│ Process     │◄────────────┘
│ Results     │
└─────────────┘
```

### Pattern 2: Batch Processing

```javascript
// Узел: Split URLs into Batches
const allUrls = $json.links; // из Map
const BATCH_SIZE = 50;
const batches = [];

for (let i = 0; i < allUrls.length; i += BATCH_SIZE) {
  batches.push(allUrls.slice(i, i + BATCH_SIZE));
}

return batches.map(batch => ({ json: { urls: batch } }));

// →  Loop Over Batches
//    → Firecrawl Batch Scrape
//       → Wait
//          → Check Status
//             → Store Results
```

### Pattern 3: Error Handling & Retry

```javascript
// Code node: Check Crawl with Retry
const maxRetries = 5;
const crawlId = $json.id;
let attempt = 0;

async function checkStatus() {
  const response = await $http.get(
    `https://api.firecrawl.dev/v2/crawl/${crawlId}`,
    {
      headers: {
        'Authorization': `Bearer ${$credentials.firecrawlApiKey}`
      }
    }
  );
  
  const status = response.status;
  
  if (status === 'completed') {
    return response.data;
  } else if (status === 'failed') {
    throw new Error('Crawl failed');
  } else if (attempt < maxRetries) {
    attempt++;
    await new Promise(resolve => setTimeout(resolve, 30000)); // wait 30s
    return checkStatus();
  } else {
    throw new Error('Max retries exceeded');
  }
}

const result = await checkStatus();
return [{ json: result }];
```

---

## 💾 Примеры хранения в Supabase

### Efficient Chunking Strategy

```javascript
// Code node: Smart Chunking
const markdown = $json.markdown;
const MIN_CHUNK = 500;
const MAX_CHUNK = 1500;
const OVERLAP = 150;

function smartChunk(text) {
  const chunks = [];
  const paragraphs = text.split('\\n\\n');
  
  let currentChunk = '';
  let chunkIndex = 0;
  
  for (const para of paragraphs) {
    // Если параграф сам по себе большой - разбиваем
    if (para.length > MAX_CHUNK) {
      if (currentChunk) {
        chunks.push({
          content: currentChunk,
          chunkIndex: chunkIndex++
        });
        currentChunk = '';
      }
      
      // Разбиваем большой параграф
      for (let i = 0; i < para.length; i += MAX_CHUNK - OVERLAP) {
        chunks.push({
          content: para.substring(i, i + MAX_CHUNK),
          chunkIndex: chunkIndex++
        });
      }
    }
    // Если добавление параграфа не превысит MAX_CHUNK
    else if ((currentChunk + para).length < MAX_CHUNK) {
      currentChunk += (currentChunk ? '\\n\\n' : '') + para;
    }
    // Иначе сохраняем текущий чанк и начинаем новый
    else {
      if (currentChunk.length >= MIN_CHUNK) {
        chunks.push({
          content: currentChunk,
          chunkIndex: chunkIndex++
        });
      }
      currentChunk = para;
    }
  }
  
  // Последний чанк
  if (currentChunk && currentChunk.length >= MIN_CHUNK) {
    chunks.push({
      content: currentChunk,
      chunkIndex: chunkIndex
    });
  }
  
  return chunks;
}

const chunks = smartChunk(markdown);
return chunks.map(chunk => ({ json: chunk }));
```

### Batch Insert для производительности

```javascript
// Вместо вставки по одному используйте batch:
// Code node: Prepare Batch Insert

const items = $input.all();
const values = items.map(item => {
  const embedding = JSON.stringify(item.json.embedding);
  return `(
    '${item.json.content.replace(/'/g, "''")}',
    '${item.json.category}',
    '${item.json.sourceUrl}',
    '${item.json.title}',
    ${item.json.chunkIndex},
    '${embedding}'::vector
  )`;
}).join(',\\n');

const query = `
INSERT INTO legal_knowledge 
  (content, category, source_url, title, chunk_index, embedding)
VALUES 
  ${values}
ON CONFLICT DO NOTHING;
`;

return [{ json: { query } }];

// → Postgres node: Execute Query
//   Query: {{ $json.query }}
```

---

## 🎨 Advanced Firecrawl Features

### 1. Actions для динамических сайтов

Если юридический источник требует взаимодействия:

```javascript
{
  url: "https://example-legal-site.kz",
  formats: ["markdown"],
  actions: [
    { type: "wait", milliseconds: 2000 },
    { type: "click", selector: "#accept-terms" },
    { type: "wait", milliseconds: 1000 },
    { type: "click", selector: ".show-full-text" },
    { type: "scroll", direction: "down" },
    { type: "wait", milliseconds: 1000 }
  ]
}
```

### 2. Location для региональных версий

```javascript
{
  url: "https://legal-site.com",
  formats: ["markdown"],
  location: {
    country: "KZ", // Казахстан
    languages: ["ru", "kk"] // русский, казахский
  }
}
```

### 3. Screenshot для визуальной проверки

```javascript
{
  url: "https://contract-template.kz",
  formats: [
    "markdown",
    {
      type: "screenshot",
      fullPage: true,
      quality: 90
    }
  ]
}

// Результат: $json.data.screenshot (base64 или URL)
```

---

## 📊 Мониторинг Firecrawl в n8n

### Узел для проверки остатка кредитов:

```javascript
// HTTP Request node
{
  url: "https://api.firecrawl.dev/v2/team/credit-usage",
  method: "GET",
  headers: {
    "Authorization": "Bearer {{ $credentials.firecrawlApiKey }}"
  }
}

// Response:
{
  "remainingCredits": 450000,
  "planCredits": 500000,
  "billingPeriodStart": "2025-01-01",
  "billingPeriodEnd": "2025-02-01"
}

// Code node: Check Low Credits
if ($json.remainingCredits < 50000) {
  // Отправить уведомление админу
  return [{
    json: {
      alert: true,
      message: `⚠️ Осталось ${$json.remainingCredits} Firecrawl кредитов!`
    }
  }];
}
```

---

## 🔍 Troubleshooting Firecrawl

### Проблема: Timeout при crawl

```javascript
// Используйте webhook вместо ожидания:
{
  url: "https://api.firecrawl.dev/v2/crawl",
  body: {
    url: "https://big-legal-site.kz",
    limit: 500,
    webhook: {
      url: "https://your-n8n.com/webhook/firecrawl-callback",
      events: ["completed", "failed"]
    }
  }
}

// Обрабатывайте callback в отдельном workflow
```

### Проблема: Некачественный markdown из PDF

```javascript
// Попробуйте с разными настройками:
{
  parsers: [{
    type: "pdf",
    maxPages: 100 // ограничьте если слишком большой
  }],
  onlyMainContent: true,
  includeTags: ["p", "div", "article"], // только текстовый контент
  excludeTags: ["script", "style", "nav", "footer"]
}
```

### Проблема: Rate limit exceeded

```javascript
// Добавьте задержки между запросами:
{
  delay: 1 // секунда между scrapes
}

// Или используйте batch с maxConcurrency:
{
  urls: [...],
  maxConcurrency: 5 // не более 5 одновременно
}
```

---

## 🏆 Best Practices

### 1. Кэширование для экономии кредитов

```javascript
// Законы меняются редко - кэшируйте агрессивно
const cacheSettings = {
  // Для кодексов и законов
  laws: {
    maxAge: 2592000000 // 30 дней
  },
  // Для судебной практики
  practice: {
    maxAge: 604800000 // 7 дней
  },
  // Для новостей и блогов
  news: {
    maxAge: 86400000 // 1 день
  }
};
```

### 2. Инкрементальное обновление

```javascript
// Сохраняйте последнюю дату обновления
// Парсите только новое

SELECT MAX(created_at) FROM legal_knowledge WHERE category = 'civil_code';
// → lastUpdate

// Crawl только с новыми публикациями
{
  url: "https://sud.gov.kz/",
  includePaths: [`/.*20(24|25).*/`], // только 2024-2025
  scrapeOptions: {
    maxAge: 0 // всегда свежее для нового контента
  }
}
```

### 3. Умное чанкирование по структуре

```javascript
// Для юридических текстов лучше чанкировать по статьям
function chunkByArticles(markdown) {
  // Разделяем по паттернам "Статья XXX" или "Article XXX"
  const articles = markdown.split(/(?=Статья \\d+|Article \\d+)/);
  
  return articles.map((article, index) => ({
    content: article.trim(),
    chunkIndex: index,
    isArticle: true,
    articleNumber: article.match(/(?:Статья|Article)\\s+(\\d+)/)?.[1]
  }));
}
```

---

## 💡 Продвинутые техники

### Multi-stage Extraction

Для сложных юридических сайтов используйте двухэтапный подход:

```javascript
// Stage 1: Map сайта для получения структуры
const mapResult = await fetch('https://api.firecrawl.dev/v2/map', {
  method: 'POST',
  headers: { 'Authorization': 'Bearer fc-KEY' },
  body: JSON.stringify({
    url: 'https://legal-database.kz',
    search: 'гражданский кодекс статья',
    limit: 500
  })
});

const relevantUrls = mapResult.links
  .filter(link => 
    link.title.includes('Статья') || 
    link.description.includes('договор')
  )
  .map(link => link.url);

// Stage 2: Batch scrape отфильтрованных URL
const scrapeResult = await fetch('https://api.firecrawl.dev/v2/batch/scrape', {
  body: JSON.stringify({
    urls: relevantUrls,
    formats: ["markdown"],
    ignoreInvalidURLs: true
  })
});
```

### Parallel Processing

```javascript
// Обрабатывайте разные категории параллельно
const categories = [
  'civil_code',
  'labor_code', 
  'judicial_practice'
];

// В n8n используйте Split In Batches
// Или Loop Over Items с параллельными ветками
```

---

## 📈 Оптимизация расходов

### Расчет стоимости парсинга

```
Firecrawl Pricing (Hobby план):
- Scrape: 1 кредит за страницу
- Crawl: 1 кредит за каждую найденную страницу
- PDF parsing: 1 кредит за страницу PDF

Пример для ГК РК:
- ~200 страниц PDF
- Парсинг: 200 кредитов
- С кэшем (maxAge): повторный доступ - 0 кредитов!

Итого: ~1000 кредитов на полную юридическую базу (при первом парсинге)
Еженедельное обновление: ~100-200 кредитов (только новое)
```

### Калькулятор окупаемости

```javascript
// Расходы на инфраструктуру (месяц):
const costs = {
  firecrawl: 20, // USD (Hobby)
  openai: 30, // ~300 анализов по $0.10
  supabase: 0, // Free tier достаточно
  n8n: 0, // Self-hosted
  total: 50 // USD
};

// Доход (при конверсии 5% из 100 пользователей):
const revenue = {
  pack_5: 5 * 3000, // 5 пользователей по 3000₸
  pack_10: 2 * 5000, // 2 пользователя по 5000₸
  pack_20: 1 * 8000, // 1 пользователь по 8000₸
  total_kzt: 33000, // ₸
  total_usd: 70 // ~USD
};

// Прибыль: $70 - $50 = $20 (при 100 пользователях)
// Масштабируется линейно!
```

---

## 🎓 Примеры промптов для Firecrawl Extract

### Извлечение статей с нумерацией

```json
{
  "url": "https://online.zakon.kz/Document/?doc_id=31577399",
  "prompt": "Извлеки из Гражданского кодекса РК все статьи о договорах (главы 26-29). Для каждой статьи укажи номер, название и полный текст.",
  "schema": {
    "type": "object",
    "properties": {
      "chapters": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "chapter_number": { "type": "integer" },
            "chapter_title": { "type": "string" },
            "articles": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "article_number": { "type": "integer" },
                  "article_title": { "type": "string" },
                  "article_text": { "type": "string" },
                  "notes": { "type": "string" }
                },
                "required": ["article_number", "article_text"]
              }
            }
          },
          "required": ["chapter_number", "articles"]
        }
      }
    },
    "required": ["chapters"]
  }
}
```

### Извлечение судебной практики

```json
{
  "urls": [
    "https://sud.gov.kz/rus/content/postanovleniya-vs-2024",
    "https://sud.gov.kz/rus/content/postanovleniya-vs-2023"
  ],
  "prompt": "Извлеки постановления Верховного Суда по договорным спорам",
  "schema": {
    "type": "object",
    "properties": {
      "rulings": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "case_number": { "type": "string" },
            "date": { "type": "string" },
            "court": { "type": "string" },
            "category": { "type": "string" },
            "summary": { "type": "string" },
            "legal_position": { "type": "string" },
            "cited_laws": {
              "type": "array",
              "items": { "type": "string" }
            }
          }
        }
      }
    }
  },
  "enableWebSearch": false,
  "showSources": true
}
```

---

## 🛡️ Security Best Practices

### 1. Защита API ключей

```javascript
// Никогда не храните ключи в коде!
// ✅ Используйте n8n credentials
const apiKey = $credentials.firecrawlApiKey;

// ❌ НЕ делайте так:
const apiKey = 'fc-hardcoded-key';
```

### 2. Rate Limiting

```javascript
// Code node: Rate Limiter
const REQUESTS_PER_MINUTE = 100; // Firecrawl Hobby limit
const lastRequest = $workflow.staticData.lastRequest || 0;
const now = Date.now();
const timeSinceLastRequest = now - lastRequest;

if (timeSinceLastRequest < 600) { // 600ms между запросами
  await new Promise(resolve => 
    setTimeout(resolve, 600 - timeSinceLastRequest)
  );
}

$workflow.staticData.lastRequest = Date.now();
```

### 3. Валидация URLs

```javascript
// Перед отправкой в Firecrawl
function isValidLegalUrl(url) {
  const allowedDomains = [
    'zakon.kz',
    'adilet.zan.kz',
    'sud.gov.kz',
    'government.kz'
  ];
  
  try {
    const urlObj = new URL(url);
    return allowedDomains.some(domain => 
      urlObj.hostname.includes(domain)
    );
  } catch {
    return false;
  }
}

const url = $json.url;
if (!isValidLegalUrl(url)) {
  throw new Error('Invalid legal source URL');
}
```

---

## 📞 Support & Resources

### Если что-то не работает:

1. **Firecrawl Issues:**
   - Check: https://www.firecrawl.dev/app/usage
   - Docs: https://docs.firecrawl.dev
   - Discord: https://discord.gg/gSmWdAkdwd

2. **Supabase Issues:**
   - Logs: Dashboard → Database → Logs
   - Docs: https://supabase.com/docs

3. **n8n Issues:**
   - Logs: Settings → Log Streaming
   - Forum: https://community.n8n.io

---

**Готово! Ваш AI-Юрист готов анализировать документы! ⚖️🚀**

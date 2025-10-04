# ❓ FAQ и Оптимизация AI-Юриста

## 🔥 Часто задаваемые вопросы

### Общие вопросы

#### Q: Сколько стоит запустить AI-Юриста?

**A:** Ежемесячные расходы:

```
Обязательные:
• Firecrawl Hobby: $20 (500K кредитов)
• OpenAI API: $20-50 (зависит от объема)
• Supabase: $0 (Free tier до 500MB БД)
• n8n: $0 (self-hosted)

ИТОГО: $40-70/месяц (~19,000-33,000₸)

Опциональные:
• Домен: $10/год
• SSL сертификат: $0 (Let's Encrypt)
• VPS для n8n: $5-10/месяц (если не локально)
```

#### Q: Сколько времени занимает настройка?

**A:** 

```
Первичная настройка: 2-3 часа
├─ Supabase setup: 30 минут
├─ Firecrawl + API keys: 15 минут
├─ Import workflows: 30 минут
├─ Первый парсинг базы: 30-60 минут
└─ Тестирование: 30 минут

Тонкая настройка: 1-2 дня
├─ Оптимизация промптов
├─ Настройка источников
└─ Кастомизация ответов
```

#### Q: Какие языки поддерживает бот?

**A:** По умолчанию русский. Для добавления казахского или английского:

```javascript
// В промпте добавьте:
const language = detectLanguage(documentText);

const systemPrompt = language === 'kk' 
  ? 'Сіз Қазақстан Республикасының заңгері боласыз...'
  : language === 'en'
  ? 'You are a legal expert in Kazakhstan...'
  : 'Ты юрист-эксперт РК...';
```

---

### Технические вопросы

#### Q: Почему Firecrawl, а не обычный scraper?

**A:** Преимущества Firecrawl:

```
✅ Обходит anti-bot защиту (важно для zakon.kz)
✅ Рендерит JavaScript (многие сайты динамические)
✅ Парсит PDF напрямую (законы часто в PDF)
✅ Готовый markdown (не нужна post-обработка)
✅ Rate limiting встроен
✅ Кэширование из коробки
✅ Инфраструктура масштабируется автоматически

❌ Обычный scraper:
- Блокируется сайтами
- Нужен Selenium/Playwright
- Сложный парсинг PDF
- Нужна своя инфраструктура
```

#### Q: Зачем векторная база? Можно просто в промпт?

**A:** Сравнение подходов:

```
БЕЗ векторной базы:
❌ Лимит контекста GPT-4 (128K токенов ≈ 200 страниц)
❌ Невозможно вместить весь ГК + ТК
❌ Дорого ($0.01 за 1K токенов input)
❌ Медленно (обработка 100K токенов)

С ВЕКТОРНОЙ БАЗОЙ:
✅ Ищем только релевантные 10 статей (vs 1000+)
✅ Контекст 10-15K токенов (vs 100K+)
✅ Дешево ($0.0001 за поиск в Supabase)
✅ Быстро (50ms поиск vs 30s обработка)
✅ Точность выше (релевантный контекст)

ЭКОНОМИЯ: ~90% стоимости анализа!
```

#### Q: Можно ли использовать другую LLM вместо GPT-4?

**A:** Да! Варианты:

```javascript
// 1. GPT-4o-mini (дешевле в 10 раз)
// Хорошо для FREE tier
{
  modelId: "gpt-4o-mini",
  maxTokens: 4000,
  cost: "$0.00015/1K tokens"
}

// 2. Claude 3.5 Sonnet (лучше для длинных текстов)
{
  model: "claude-3-5-sonnet-20241022",
  maxTokens: 8000,
  cost: "$0.003/1K tokens"
}

// 3. Open-source модели (для self-hosted)
{
  model: "ollama/llama3.3:70b",
  api_url: "http://localhost:11434",
  cost: "$0 (свой сервер)"
}

// Рекомендация:
// FREE tier: GPT-4o-mini
// PREMIUM: GPT-4o или Claude 3.5
```

---

### Вопросы по парсингу

#### Q: Как часто обновлять юридическую базу?

**A:** Рекомендуемая частота:

```
Гражданский/Трудовой кодекс:
• Раз в месяц (законы меняются редко)
• При мажорных изменениях (следите за новостями)

Судебная практика:
• Раз в неделю (новые решения ВС РК)

Нормативные постановления:
• Раз в 2 недели

Типовые формы:
• Раз в месяц
```

#### Q: Что делать если Firecrawl не может распарсить сайт?

**A:** Troubleshooting steps:

```javascript
// Шаг 1: Попробуйте разные настройки
{
  scrapeOptions: {
    waitFor: 5000,        // ждем загрузки JS
    proxy: "stealth",     // стелс-прокси (+5 кредитов)
    mobile: false,        // десктоп версия
    blockAds: true,
    skipTlsVerification: true
  }
}

// Шаг 2: Используйте actions
{
  actions: [
    { type: "wait", milliseconds: 3000 },
    { type: "click", selector: "#show-full-text" },
    { type: "scroll", direction: "down" }
  ]
}

// Шаг 3: Fallback на прямой download PDF
{
  url: "https://direct-link-to.pdf",
  parsers: [{ type: "pdf", maxPages: 500 }]
}

// Шаг 4: Последний resort - Google Apps Script
// (ваш существующий метод)
```

#### Q: Как обрабатывать PDF-сканы (не текстовые PDF)?

**A:** Два варианта:

```javascript
// Вариант 1: Google Apps Script OCR (ваш текущий)
// Плюсы: бесплатно, хорошо работает
// Минусы: медленно (15-30 сек)

// Вариант 2: Firecrawl с OCR через Vision
{
  url: "https://link-to-scan.pdf",
  formats: [
    {
      type: "json",
      prompt: "Распознай и извлеки весь текст из этого PDF-скана",
      schema: {
        type: "object",
        properties: {
          extracted_text: { type: "string" }
        }
      }
    }
  ],
  parsers: ["pdf"]
}

// Вариант 3: Предварительный OCR через Mathpix
// https://mathpix.com/ocr (платно, но очень точно)
```

---

## ⚡ Оптимизация производительности

### 1. Оптимизация векторного поиска

```sql
-- Создайте специализированный индекс для каждой категории
CREATE INDEX idx_legal_civil ON legal_knowledge 
USING ivfflat (embedding vector_cosine_ops)
WHERE category = 'civil_code'
WITH (lists = 50);

CREATE INDEX idx_legal_labor ON legal_knowledge
USING ivfflat (embedding vector_cosine_ops)
WHERE category = 'labor_code'
WITH (lists = 30);

-- Используйте в запросе:
SELECT * FROM legal_knowledge
WHERE category = 'civil_code' -- индекс сработает быстрее
  AND 1 - (embedding <=> $1::vector) > 0.7
ORDER BY embedding <=> $1::vector
LIMIT 5;
```

### 2. Кэширование embeddings

```sql
-- Создайте таблицу для кэша эмбеддингов документов
CREATE TABLE embedding_cache (
  id BIGSERIAL PRIMARY KEY,
  text_hash VARCHAR(64) UNIQUE,  -- MD5 или SHA256
  embedding vector(1536),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_embedding_cache_hash ON embedding_cache(text_hash);

-- Перед созданием эмбеддинга проверяйте кэш
```

```javascript
// Code node: Check Embedding Cache
const textHash = crypto
  .createHash('md5')
  .update($json.documentText.substring(0, 2000))
  .digest('hex');

const cached = await $postgres.query(
  'SELECT embedding FROM embedding_cache WHERE text_hash = $1',
  [textHash]
);

if (cached.length > 0) {
  // Используем кэшированный
  return [{ json: { embedding: cached[0].embedding, cached: true } }];
} else {
  // Создаем новый и сохраняем в кэш
  const newEmbedding = await createEmbedding($json.text);
  await saveToCache(textHash, newEmbedding);
  return [{ json: { embedding: newEmbedding, cached: false } }];
}
```

### 3. Параллельная обработка

```javascript
// Вместо последовательной обработки файлов
// используйте параллельные ветки

// Split файлов по типам:
const files = $json.files;

return [
  { json: { type: 'pdf', files: files.pdf } },
  { json: { type: 'docx', files: files.docx } },
  { json: { type: 'images', files: files.images } }
];

// Каждая ветка обрабатывается параллельно
// Затем Merge всех результатов
```

### 4. Batch API requests

```javascript
// Для множественных OpenAI вызовов используйте batch
const items = $input.all();

// Вместо Loop
const batchRequests = items.map(item => ({
  custom_id: item.json.id,
  method: "POST",
  url: "/v1/chat/completions",
  body: {
    model: "gpt-4o-mini",
    messages: [{
      role: "user",
      content: item.json.text
    }]
  }
}));

// Batch API (50% дешевле!)
// https://platform.openai.com/docs/guides/batch
```

---

## 💾 Оптимизация хранения

### Compression для больших текстов

```sql
-- Добавьте compressed колонки для экономии места
ALTER TABLE analyzed_documents
ADD COLUMN extracted_text_compressed BYTEA;

-- В n8n перед сохранением:
```

```javascript
// Code node: Compress Text
const zlib = require('zlib');
const text = $json.documentText;

const compressed = zlib.gzipSync(text).toString('base64');

return [{
  json: {
    text_compressed: compressed,
    original_size: text.length,
    compressed_size: compressed.length,
    compression_ratio: (1 - compressed.length / text.length) * 100
  }
}];

// Экономия: ~70% места для текстовых данных
```

### Партиционирование больших таблиц

```sql
-- Для analyzed_documents (если > 100K записей)
CREATE TABLE analyzed_documents_2025_01 
  PARTITION OF analyzed_documents
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE analyzed_documents_2025_02
  PARTITION OF analyzed_documents  
  FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- Автоматическое создание партиций
CREATE EXTENSION IF NOT EXISTS pg_partman;
```

---

## 🎯 Оптимизация промптов

### Техника 1: Few-shot примеры

```javascript
const systemPrompt = `
Ты юрист-эксперт РК.

ПРИМЕРЫ КАЧЕСТВЕННОГО АНАЛИЗА:

Пример 1:
INPUT: "Пункт 5.1: Штраф 2% от суммы договора за каждый день просрочки"
OUTPUT: {
  "clause_number": "5.1",
  "issue": "Штраф 2%/день = 730%/год - несоразмерно",
  "risk_level": 5,
  "legal_reference": "Ст. 297, 299 ГК РК о соразмерности неустойки"
}

Пример 2:
INPUT: "Пункт 8.3: Договор может быть расторгнут по соглашению сторон"
OUTPUT: {
  "clause_number": "8.3",
  "issue": "Стандартная формулировка, риска нет",
  "risk_level": 1,
  "positive": "Соответствует ст. 401 ГК РК"
}

Теперь проанализируй следующий документ...
`;

// Это повышает точность на 20-30%!
```

### Техника 2: Chain-of-Thought

```javascript
const analysisPrompt = `
Проанализируй договор следуя этому мыслительному процессу:

ШАГ 1: Определи тип договора
Размышление: "По наличию слов 'арендатор', 'арендодатель' и описанию 
недвижимости это договор аренды согласно ст. 557 ГК РК"
Вывод: rental_agreement

ШАГ 2: Проверь обязательные реквизиты
Размышление: "Согласно ст. 393 ГК РК должны быть: стороны, предмет, цена.
Проверяю наличие..."
Вывод: [список отсутствующих]

ШАГ 3: Анализ каждого пункта
Пункт 4.3: "Арендодатель вправе изменять цену..."
Размышление: "Это противоречит ст. 393 ГК РК об определенности условий.
В судебной практике (Постановление ВС №5) такие пункты признаются 
недействительными."
Вывод: { риск: 5, основание: "..." }

...

Итоговый JSON: {...}
`;

// Улучшает логику рассуждений AI
```

### Техника 3: Structured Outputs (OpenAI)

```javascript
// Используйте новую фичу Structured Outputs
{
  model: "gpt-4o-2024-08-06",
  messages: [...],
  response_format: {
    type: "json_schema",
    json_schema: {
      name: "legal_analysis",
      strict: true,
      schema: {
        type: "object",
        properties: {
          overall_risk_score: { 
            type: "integer",
            minimum: 1,
            maximum: 5
          },
          risk_points: {
            type: "array",
            items: {
              type: "object",
              properties: {
                clause_number: { type: "string" },
                risk_level: { type: "integer" }
              },
              required: ["clause_number", "risk_level"],
              additionalProperties: false
            }
          }
        },
        required: ["overall_risk_score", "risk_points"],
        additionalProperties: false
      }
    }
  }
}

// Гарантирует валидный JSON каждый раз!
```

---

## 🚀 Масштабирование

### Для 1000+ пользователей

#### 1. Upgrade Supabase

```bash
Free tier → Pro ($25/мес)

Преимущества:
• 8GB database (vs 500MB)
• Больше connections
• Автоматические бэкапы
• Point-in-time recovery
```

#### 2. Используйте Supabase Edge Functions

```javascript
// Вместо n8n для векторного поиска
// используйте Edge Function (быстрее + дешевле)

// supabase/functions/vector-search/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { embedding, limit } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL'),
    Deno.env.get('SUPABASE_SERVICE_KEY')
  )
  
  const { data } = await supabase.rpc('match_legal_documents', {
    query_embedding: embedding,
    match_threshold: 0.7,
    match_count: limit
  })
  
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' }
  })
})

// Вызов из n8n:
// POST https://xxx.supabase.co/functions/v1/vector-search
```

#### 3. Queue система для анализов

```javascript
// Для пиковых нагрузок используйте очередь

// Таблица очереди
CREATE TABLE analysis_queue (
  id BIGSERIAL PRIMARY KEY,
  chat_id VARCHAR(255),
  document_text TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  priority INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW()
);

// n8n workflow: Queue Processor (каждые 30 секунд)
// Забирает из очереди и обрабатывает
```

### Для 10000+ пользователей

#### 1. Горизонтальное масштабирование n8n

```yaml
# docker-compose.yml
services:
  n8n-worker-1:
    image: n8nio/n8n
    environment:
      - EXECUTIONS_MODE=queue
      
  n8n-worker-2:
    image: n8nio/n8n
    environment:
      - EXECUTIONS_MODE=queue
```

#### 2. Redis для кэширования

```javascript
// Кэшируйте частые векторные поиски
const Redis = require('redis');
const redis = Redis.createClient();

const cacheKey = `embed:${textHash}`;
const cached = await redis.get(cacheKey);

if (cached) {
  return JSON.parse(cached);
} else {
  const results = await vectorSearch();
  await redis.setex(cacheKey, 3600, JSON.stringify(results)); // 1 час
  return results;
}
```

#### 3. CDN для статических результатов

```javascript
// Экспортируйте популярные анализы в статику
// Храните на Cloudflare R2 / S3
const popularDocs = await getPopularAnalyses();

popularDocs.forEach(async doc => {
  const html = renderAnalysisAsHTML(doc);
  await uploadToR2(`analyses/${doc.id}.html`, html);
  
  // Шарьте ссылкой:
  // https://cdn.ai-lawyer.kz/analyses/123.html
});
```

---

## 💡 Продвинутые фичи

### Feature 1: Мультиязычность

```javascript
// Code node: Detect Language & Translate
const detectLang = require('langdetect');
const { translate } = require('@google-cloud/translate').v2;

const docLang = detectLang.detect($json.documentText)[0].lang;

if (docLang === 'kk') {
  // Казахский документ
  const translated = await translate($json.documentText, 'ru');
  
  // Анализируем на русском
  const analysis = await analyzeDocument(translated);
  
  // Переводим результат обратно
  const response = await translate(analysis, 'kk');
  
  return [{ json: { message: response, originalLang: 'kk' } }];
}
```

### Feature 2: Голосовой ввод для юристов

```javascript
// Пользователь отправляет голосовое:
// "Проверь этот договор на риски для арендатора"

// 1. Whisper transcription (уже есть в вашем flow)
const transcribed = $json.text;

// 2. Extract команда
const command = extractCommand(transcribed);
// → "проверь договор", "фокус: риски арендатора"

// 3. Модифицируем промпт
const enhancedPrompt = systemPrompt + 
  `\n\nОСОБОЕ ВНИМАНИЕ: ${command.focus}`;
```

### Feature 3: Экспорт в PDF

```javascript
// Code node: Generate PDF Report
const puppeteer = require('puppeteer');

const browser = await puppeteer.launch();
const page = await browser.newPage();

const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial; padding: 40px; }
    .risk { color: red; font-weight: bold; }
    .good { color: green; }
  </style>
</head>
<body>
  <h1>Анализ договора</h1>
  <p>Дата: ${new Date().toLocaleDateString('ru')}</p>
  
  <h2>Общий риск: ${analysisResult.overall_risk_score}/5</h2>
  
  <h3>Выявленные риски:</h3>
  ${analysisResult.risk_points.map(r => `
    <div class="risk">
      <strong>${r.clause_number}:</strong> ${r.issue}<br>
      <em>Рекомендация: ${r.recommendation}</em>
    </div>
  `).join('')}
  
  <footer>
    <p>Disclaimer: Не является юридической консультацией</p>
  </footer>
</body>
</html>
`;

await page.setContent(html);
const pdf = await page.pdf({ format: 'A4' });
await browser.close();

return [{ 
  binary: {
    data: pdf,
    fileName: `analysis_${Date.now()}.pdf`,
    mimeType: 'application/pdf'
  }
}];
```

### Feature 4: Интеграция с CRM

```javascript
// Webhook для интеграции с юридическими CRM
// Автоматически создавайте задачи в CRM при находке критических рисков

if (analysisResult.overall_risk_score >= 4) {
  await fetch('https://your-crm.com/api/tasks', {
    method: 'POST',
    headers: { 'Authorization': 'Bearer CRM_TOKEN' },
    body: JSON.stringify({
      title: `Критические риски в договоре клиента ${chatId}`,
      description: analysisResult.executive_summary,
      priority: 'high',
      assigned_to: 'senior_lawyer',
      attachments: [analysisResult]
    })
  });
}
```

---

## 📊 Аналитика и метрики

### Важные метрики для отслеживания

```sql
-- 1. DAU (Daily Active Users)
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT chat_id) as dau
FROM analyzed_documents
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- 2. Retention Rate
WITH cohorts AS (
  SELECT 
    chat_id,
    DATE_TRUNC('week', MIN(created_at)) as cohort_week
  FROM user_limits
  GROUP BY chat_id
)
SELECT 
  c.cohort_week,
  COUNT(DISTINCT c.chat_id) as cohort_size,
  COUNT(DISTINCT CASE 
    WHEN ad.created_at BETWEEN c.cohort_week + INTERVAL '7 days' 
                            AND c.cohort_week + INTERVAL '14 days'
    THEN ad.chat_id 
  END) as retained_week1
FROM cohorts c
LEFT JOIN analyzed_documents ad ON ad.chat_id = c.chat_id
GROUP BY c.cohort_week
ORDER BY c.cohort_week DESC;

-- 3. Средний чек и LTV
SELECT 
  AVG(amount) as avg_purchase,
  AVG(amount * analyses_count) as estimated_ltv
FROM (
  SELECT 
    p.chat_id,
    SUM(p.amount) as amount,
    COUNT(ad.id) as analyses_count
  FROM payments p
  LEFT JOIN analyzed_documents ad ON ad.chat_id = p.chat_id
  WHERE p.payment_status = 'completed'
  GROUP BY p.chat_id
) subquery;

-- 4. Популярные типы рисков
SELECT 
  jsonb_array_elements(risk_points)->>'risk_category' as risk_category,
  AVG((jsonb_array_elements(risk_points)->>'risk_level')::int) as avg_risk,
  COUNT(*) as occurrences
FROM analyzed_documents
WHERE risk_points IS NOT NULL
GROUP BY risk_category
ORDER BY occurrences DESC;
```

### Настройка аналитического дашборда

```javascript
// n8n workflow: Daily Analytics Report

const stats = {
  today: {
    newUsers: await countNewUsers(),
    analyses: await countAnalyses(),
    revenue: await sumRevenue(),
    avgRisk: await avgRiskScore()
  },
  trends: {
    userGrowth: calculateGrowth('users', 7), // 7-day trend
    revenueGrowth: calculateGrowth('revenue', 7)
  },
  topIssues: await getTopRisks(10)
};

const report = formatDashboard(stats);

// Отправляем админу в Telegram
await sendTelegram(ADMIN_CHAT_ID, report);
```

---

## 🛡️ Безопасность и Compliance

### GDPR / Защита персональных данных

```sql
-- Анонимизация данных пользователей
CREATE TABLE user_anonymization (
  original_chat_id VARCHAR(255) PRIMARY KEY,
  anonymized_id UUID DEFAULT gen_random_uuid(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Функция получения анонимного ID
CREATE OR REPLACE FUNCTION get_anonymous_id(p_chat_id VARCHAR)
RETURNS UUID AS $$
DECLARE
  v_anon_id UUID;
BEGIN
  INSERT INTO user_anonymization (original_chat_id)
  VALUES (p_chat_id)
  ON CONFLICT (original_chat_id) 
  DO UPDATE SET original_chat_id = EXCLUDED.original_chat_id
  RETURNING anonymized_id INTO v_anon_id;
  
  RETURN v_anon_id;
END;
$$ LANGUAGE plpgsql;

-- Используйте анонимные ID в аналитике
```

### Шифрование чувствительных данных

```javascript
// Code node: Encrypt Document
const crypto = require('crypto');

const algorithm = 'aes-256-gcm';
const key = Buffer.from(process.env.ENCRYPTION_KEY, 'hex');
const iv = crypto.randomBytes(16);

const cipher = crypto.createCipheriv(algorithm, key, iv);
let encrypted = cipher.update($json.documentText, 'utf8', 'hex');
encrypted += cipher.final('hex');

const authTag = cipher.getAuthTag();

return [{
  json: {
    encrypted_text: encrypted,
    iv: iv.toString('hex'),
    auth_tag: authTag.toString('hex')
  }
}];

// Сохраняем зашифрованным в БД
// Расшифровываем только при необходимости
```

### Автоудаление старых данных

```sql
-- Автоматическое удаление через 90 дней
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
  -- Удаляем старые анализы
  DELETE FROM analyzed_documents
  WHERE created_at < NOW() - INTERVAL '90 days';
  
  -- Удаляем неактивных пользователей
  DELETE FROM user_limits
  WHERE chat_id NOT IN (
    SELECT DISTINCT chat_id 
    FROM analyzed_documents 
    WHERE created_at > NOW() - INTERVAL '180 days'
  )
  AND created_at < NOW() - INTERVAL '180 days';
  
  -- Vacuum
  VACUUM ANALYZE;
END;
$$ LANGUAGE plpgsql;

-- Запускайте раз в неделю
```

---

## 🎓 Best Practices

### 1. Версионирование промптов

```sql
-- Отслеживайте эффективность разных версий
ALTER TABLE analysis_templates 
ADD COLUMN prompt_version INTEGER DEFAULT 1,
ADD COLUMN created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN effectiveness_score FLOAT; -- обновляется на основе feedback

-- При изменении промпта:
INSERT INTO analysis_templates (document_type, system_prompt, prompt_version)
VALUES ('rental_agreement', 'NEW_PROMPT...', 2);

-- Анализируйте что работает лучше:
SELECT 
  prompt_version,
  AVG(feedback_rating) as avg_feedback,
  COUNT(*) as uses
FROM analyzed_documents ad
JOIN user_feedback uf ON uf.analysis_id = ad.id
JOIN analysis_templates at ON at.document_type = ad.document_type
GROUP BY prompt_version;
```

### 2. Graceful degradation

```javascript
// Если векторный поиск не нашел контекста
// используйте базовый промпт без контекста

const legalContext = $('📑 Format Legal Context').item.json.legalContext;

const prompt = legalContext.includes('не найден')
  ? `Проанализируй договор на основе общих принципов права РК.
     ВАЖНО: Без доступа к специфичным статьям, будь осторожен со ссылками.
     Используй формулировки "обычно", "как правило", "согласно практике".`
  : `Проанализируй договор используя следующий контекст из законов РК:
     ${legalContext}`;
```

### 3. Мониторинг качества

```javascript
// После каждого анализа проверяйте качество
function validateAnalysis(result) {
  const checks = {
    hasRiskScore: result.overall_risk_score >= 1 && result.overall_risk_score <= 5,
    hasRisks: result.risk_points && result.risk_points.length > 0,
    risksHaveLegalRefs: result.risk_points.every(r => r.legal_reference),
    hasSummary: result.executive_summary && result.executive_summary.length > 50,
    hasActions: result.action_items && result.action_items.length > 0
  };
  
  const score = Object.values(checks).filter(Boolean).length / Object.keys(checks).length;
  
  if (score < 0.7) {
    // Логируем проблемные анализы
    console.error('Low quality analysis:', {
      checks,
      score,
      result
    });
  }
  
  return score;
}
```

---

## 🎬 Production Checklist

### Перед запуском

```bash
# Инфраструктура
□ Supabase база развернута и протестирована
□ Все SQL функции работают
□ Векторные индексы созданы
□ Backup настроен

# Firecrawl
□ API ключ активен и протестирован
□ База знаний наполнена (500+ chunks)
□ Кредиты достаточно (>100K)
□ Мониторинг настроен

# n8n
□ Все workflows импортированы
□ Credentials настроены
□ Тестовые прогоны успешны
□ Error handling на месте

# Бизнес-логика
□ Система лимитов работает
□ Платежи обрабатываются
□ Disclaimers добавлены
□ Тарифы определены

# Качество
□ 10+ тестовых документов проанализировано
□ Точность анализа проверена юристом
□ UI/UX сообщений оптимизирован
□ Время ответа <2 минут

# Безопасность
□ API ключи в секретах (не в коде!)
□ Rate limiting настроен
□ Шифрование чувствительных данных
□ GDPR compliance (если применимо)

# Мониторинг
□ Логи настроены
□ Alerting на критичные ошибки
□ Дашборд для метрик
□ Backup автоматизирован
```

---

## 🆘 Support Matrix

| Проблема | Где искать | Как решить |
|----------|------------|------------|
| Firecrawl ошибки | [Dashboard → Logs](https://firecrawl.dev/app) | Проверьте кредиты, измените конфиг |
| Векторный поиск медленный | Supabase → Database → Performance | Оптимизируйте индексы |
| AI дает плохие результаты | OpenAI → Usage | Улучшите промпт, добавьте примеры |
| n8n workflow падает | n8n → Executions | Проверьте error handling |
| Пользователи жалуются | Telegram/WhatsApp | Соберите feedback, улучшите UX |

---

## 🎯 KPI для отслеживания

```javascript
const KPIs = {
  product: {
    accuracy: '>85% корректных анализов',
    response_time: '<2 минут',
    user_satisfaction: '>4.0/5.0'
  },
  business: {
    conversion: '>5% в платящих',
    retention_7d: '>40%',
    churn: '<10%/месяц',
    ltv_cac: '>3.0'
  },
  technical: {
    uptime: '>99%',
    error_rate: '<1%',
    api_latency: '<500ms (p95)'
  },
  costs: {
    cost_per_analysis: '<50₸',
    margin: '>60%',
    firecrawl_utilization: '>80%'
  }
};

// Дашборд для отслеживания
setInterval(async () => {
  const current = await calculateKPIs();
  
  if (current.product.accuracy < 0.85) {
    alert('⚠️ Accuracy below threshold!');
  }
  
  if (current.costs.margin < 0.6) {
    alert('💰 Margins too low!');
  }
}, 3600000); // каждый час
```

---

## 🎉 Итого

Следуя этим рекомендациям вы:

- ✅ Сэкономите 50-70% расходов на API
- ✅ Ускорите анализ в 2-3 раза
- ✅ Повысите точность на 20-30%
- ✅ Обеспечите стабильную работу при росте
- ✅ Сможете масштабироваться до 10K+ пользователей

**Успехов! ⚖️🚀**

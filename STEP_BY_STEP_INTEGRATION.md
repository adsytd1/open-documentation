# 🚀 Пошаговая интеграция AI-Юриста

## ✅ Чеклист готовности

Перед началом убедитесь, что у вас есть:

- [ ] Аккаунт Supabase (бесплатный tier подойдет)
- [ ] Аккаунт Firecrawl (Hobby план, ~$20/мес)
- [ ] OpenAI API ключ (GPT-4o)
- [ ] Рабочий n8n instance
- [ ] PostgreSQL credentials от Supabase

---

## 📍 ШАГ 1: Настройка Supabase (15 минут)

### 1.1 Создание проекта

```bash
1. Войдите на supabase.com
2. New Project → выберите регион (Singapore для РК)
3. Задайте пароль БД (СОХРАНИТЕ ЕГО!)
4. Дождитесь создания (2-3 минуты)
```

### 1.2 Включение векторного расширения

```sql
-- SQL Editor → New query
CREATE EXTENSION IF NOT EXISTS vector;
```

### 1.3 Выполнение схемы

```bash
1. Откройте файл supabase_schema.sql
2. Скопируйте ВЕСЬ код
3. SQL Editor → New query → Вставьте → Run
4. Проверьте: должно быть 5 таблиц + 4 функции
```

### 1.4 Проверка

```sql
-- Выполните для проверки:
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- Должны увидеть:
-- legal_knowledge
-- analyzed_documents  
-- user_limits
-- analysis_templates
-- payments
```

### 1.5 Получение credentials

```bash
Settings → Database → Connection string

Формат:
postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres

Пример:
postgresql://postgres:your-password@db.xxxx.supabase.co:5432/postgres
```

---

## 🔥 ШАГ 2: Настройка Firecrawl (5 минут)

### 2.1 Регистрация

```bash
1. Перейдите на firecrawl.dev
2. Sign Up (можно через GitHub)
3. Choose Plan → Hobby ($20/мес, 500K кредитов)
```

### 2.2 Получение API ключа

```bash
1. Dashboard → API Keys
2. Create New Key
3. Скопируйте ключ (fc-XXXXXXXXXX)
4. СОХРАНИТЕ В БЕЗОПАСНОМ МЕСТЕ!
```

### 2.3 Тестовый запрос

```bash
# Проверьте что ключ работает:
curl -X POST https://api.firecrawl.dev/v2/scrape \
  -H 'Authorization: Bearer fc-YOUR-KEY' \
  -H 'Content-Type: application/json' \
  -d '{"url": "https://firecrawl.dev", "formats": ["markdown"]}'
```

---

## 🔧 ШАГ 3: Настройка credentials в n8n (10 минут)

### 3.1 PostgreSQL (Supabase)

```bash
Settings → Credentials → Add Credential → Postgres

Заполните:
Host: db.xxxx.supabase.co
Database: postgres
User: postgres
Password: [ваш пароль из шага 1.1]
Port: 5432
SSL: Enable
```

**Тест:** Execute query → `SELECT 1;` → должно вернуть 1

### 3.2 Firecrawl API

```bash
# В n8n пока нет готового Firecrawl credential, используем HTTP Header Auth

Settings → Credentials → Add → HTTP Header Auth

Name: Firecrawl API
Header Name: Authorization
Header Value: Bearer fc-YOUR-KEY
```

### 3.3 OpenAI API

```bash
Используйте существующий или создайте новый:

Settings → Credentials → OpenAI
API Key: sk-XXXXXXXX
```

---

## 📥 ШАГ 4: Импорт workflows (20 минут)

### 4.1 Workflow 0: Парсинг юридической базы

```bash
1. n8n → Workflows → Add workflow
2. три точки → Import from File
3. Выберите: workflow_1_legal_knowledge_parser.json
4. Откройте workflow
5. Настройте credentials во всех узлах
6. ВАЖНО: Откройте узел "Legal Sources Config"
7. Измените URLs на актуальные юридические источники РК
```

#### Рекомендуемые источники для РК:

```javascript
const legalSources = [
  {
    category: 'civil_code',
    url: 'https://online.zakon.kz/Document/?doc_id=31577399#pos=4;-45',
    description: 'ГК РК - Общая часть',
    crawlOptions: {
      limit: 150,
      includePaths: ['/Document/.*'],
      scrapeOptions: {
        formats: ['markdown'],
        onlyMainContent: true,
        parsers: [{ type: 'pdf', maxPages: 1000 }],
        maxAge: 604800000 // кэш на неделю
      }
    }
  },
  {
    category: 'civil_code',
    url: 'https://online.zakon.kz/Document/?doc_id=31577399#pos=4;-45',
    description: 'ГК РК - Договоры (главы 26-29)',
    crawlOptions: {
      limit: 200,
      includePaths: ['/Document/.*'],
      scrapeOptions: {
        formats: ['markdown'],
        includeTags: ['div.document', 'p', 'article'],
        onlyMainContent: true
      }
    }
  },
  {
    category: 'labor_code',
    url: 'https://online.zakon.kz/Document/?doc_id=38910832',
    description: 'Трудовой кодекс РК',
    crawlOptions: {
      limit: 100,
      scrapeOptions: {
        formats: ['markdown'],
        parsers: ['pdf']
      }
    }
  }
];
```

#### Первый запуск:

```bash
8. Execute workflow (кнопка Play внизу)
9. Мониторьте выполнение (может занять 10-30 минут!)
10. Проверьте Supabase:
    SELECT COUNT(*) FROM legal_knowledge;
    -- Должно быть минимум 100-200 записей
```

### 4.2 Интеграция в основной workflow

#### Вариант A: Ручная интеграция (рекомендуется)

Откройте ваш существующий workflow и добавьте узлы ПОСЛЕ "Wait2":

```bash
1. После узла "Wait2" добавьте Code node "🔍 Detect Legal Document"
   Скопируйте код из MODIFIED_MAIN_WORKFLOW.json

2. Добавьте IF node "⚖️ Is Legal Document?"
   TRUE branch → продолжить юридический анализ
   FALSE branch → вернуться к Loop Over Items

3. Добавьте цепочку узлов (из MODIFIED_MAIN_WORKFLOW.json):
   📄 Prepare Document
   ↓
   💳 Check Limits → 🏷️ Detect Type → 🔎 Prepare Search Query
   ↓                  ↓                ↓
   ✅ Has Limit?      📋 Get Template   🧮 Create Embedding
   ↓ (TRUE)           ↓                ↓
   🔀 Merge ←────────←──────────────── 📚 Search Legal DB
   ↓                                    ↓
   🤖 AI Legal Analysis                 📑 Format Legal Context
   ↓
   💬 Format User Response
   ↓
   💾 Save to DB
   ↓
   ➕ Increment Counter
   ↓
   → подключите к вашему существующему узлу "Merge"
```

#### Вариант B: Полная замена workflow

```bash
1. Сохраните текущий workflow как backup
2. Import from File → MODIFIED_MAIN_WORKFLOW.json
3. Восстановите недостающие узлы из вашего оригинала
4. Проверьте все connections
```

### 4.3 Обновление узла "Ответ"

Добавьте в начало кода узла "Ответ":

```javascript
const items = $input.all();

if (items.length === 0) {
  return [{ json: {} }];
}

const item = items[0].json;

// ═══════════════════════════════════════
// НОВОЕ: Обработка юридического анализа
// ═══════════════════════════════════════

if (item.sourceType === 'legal_analysis') {
  return [{
    json: {
      chatId: item.chatId,
      message: item.message,
      sourceType: 'legal_analysis',
      processed_message_ids: item.processed_message_ids || []
    }
  }];
}

// Обработка ошибок лимитов
if (item.sourceType === 'limit_exceeded') {
  return [{
    json: {
      chatId: item.chatId,
      message: item.message,
      sourceType: 'limit_exceeded',
      processed_message_ids: item.processed_message_ids || []
    }
  }];
}

// ═══════════════════════════════════════
// ВАША СУЩЕСТВУЮЩАЯ ЛОГИКА
// ═══════════════════════════════════════

if (item.combinedText) {
  // ... ваш существующий код ...
}
// и т.д.
```

---

## 🧪 ШАГ 5: Тестирование (30 минут)

### Тест 1: Проверка базы знаний

```sql
-- В Supabase SQL Editor
SELECT 
  category,
  COUNT(*) as chunks,
  AVG(LENGTH(content)) as avg_length
FROM legal_knowledge
GROUP BY category;

-- Ожидаемый результат:
-- civil_code: 100-200 chunks
-- labor_code: 50-100 chunks
-- каждый chunk: 500-1000 символов
```

### Тест 2: Векторный поиск

```sql
-- Проверьте что поиск работает:
SELECT 
  title,
  category,
  LENGTH(content) as content_length
FROM legal_knowledge
WHERE content ILIKE '%штраф%'
LIMIT 5;
```

### Тест 3: Создание тестового пользователя

```sql
-- Создайте тестового пользователя с лимитами
INSERT INTO user_limits (chat_id, subscription_tier, analyses_limit, max_pages_per_doc)
VALUES ('TEST_CHAT_123', 'premium', 20, 15);

-- Проверьте функцию
SELECT * FROM check_user_limit('TEST_CHAT_123');
```

### Тест 4: Анализ тестового документа

Создайте простой тестовый договор:

```
ДОГОВОР АРЕНДЫ КВАРТИРЫ

1. ПРЕДМЕТ ДОГОВОРА
1.1. Арендодатель передает, а Арендатор принимает в аренду квартиру
по адресу: г.Костанай, ул.Тестовая, д.1, кв.1

2. СРОК ДОГОВОРА
2.1. Срок аренды: 1 год с 01.01.2025

3. ОПЛАТА
3.1. Арендная плата: 100,000 тенге в месяц
3.2. Залог: 100,000 тенге
3.3. Коммунальные услуги оплачивает Арендатор

4. ШТРАФЫ
4.1. За просрочку платежа - 1% в день от суммы

5. РАСТОРЖЕНИЕ
5.1. Арендодатель может расторгнуть договор в любое время,
уведомив за 3 дня

Подписи сторон: ___________
```

Сохраните как PDF и отправьте боту.

#### Ожидаемый результат:

```
✅ Бот должен:
1. Распознать документ как юридический
2. Определить тип: rental_agreement
3. Найти минимум 2 критических риска:
   - Штраф 1%/день (365% годовых)
   - Расторжение за 3 дня
4. Дать конкретные рекомендации
5. Сослаться на ГК РК
6. Показать риск-скор 4-5/5
```

### Тест 5: Проверка лимитов

```bash
1. Создайте нового пользователя (другой chat_id)
2. Отправьте документ → должен проанализировать
3. Отправьте второй документ → должен сказать "лимит исчерпан"
4. Проверьте в БД:

SELECT * FROM user_limits WHERE chat_id = 'YOUR_CHAT_ID';
-- analyses_used_this_month должно быть = 1
```

---

## 🎨 ШАГ 6: Кастомизация (опционально)

### 6.1 Добавление своих источников

Отредактируйте узел "Legal Sources Config":

```javascript
// Добавьте источники специфичные для вашей ниши
{
  category: 'real_estate_law',
  url: 'https://adilet.zan.kz/rus/docs/Z970000094_', // Закон о гос.регистрации прав
  description: 'Закон о регистрации прав на недвижимость',
  crawlOptions: {
    limit: 50,
    scrapeOptions: {
      formats: ['markdown'],
      parsers: ['pdf']
    }
  }
},
{
  category: 'consumer_protection',
  url: 'https://adilet.zan.kz/rus/docs/Z100000274_',
  description: 'Закон о защите прав потребителей',
  crawlOptions: { limit: 60 }
}
```

### 6.2 Настройка промптов

```sql
-- Обновите промпты под вашу специфику:
UPDATE analysis_templates 
SET system_prompt = 'ВАШ УЛУЧШЕННЫЙ ПРОМПТ...'
WHERE document_type = 'rental_agreement';
```

Используйте промпты из файла `advanced_prompts.md`

### 6.3 Локализация для Казахстана

```javascript
// В узле форматирования ответа добавьте:
const currencySymbol = '₸'; // тенге
const courtReference = 'суд по месту нахождения объекта'; // для РК
const lawPrefix = 'ГК РК'; // вместо просто "ГК"
```

---

## 💰 ШАГ 7: Настройка монетизации (1 час)

### 7.1 Kaspi интеграция

#### Вариант A: Kaspi QR (простой)

```bash
1. Создайте Kaspi QR код в приложении
2. При оплате просите указывать в комментарии: AI-Lawyer [chat_id]
3. Проверяйте платежи вручную или через Kaspi API
```

#### Вариант B: Kaspi API (автоматический)

```bash
1. Зарегистрируйтесь как Kaspi merchant
2. Получите API credentials
3. Создайте webhook в n8n:
```

```json
{
  "parameters": {
    "path": "kaspi-payment-webhook",
    "responseMode": "lastNode"
  },
  "name": "Kaspi Payment Webhook",
  "type": "n8n-nodes-base.webhook"
}
```

#### Обработка платежа:

```javascript
// Code node: Process Payment
const payment = $json;
const chatId = payment.comment.match(/AI-Lawyer\s+(\S+)/)?.[1];
const amount = payment.amount;

// Определяем пакет по сумме
let packageType = '';
if (amount >= 7900 && amount <= 8100) packageType = 'pack_20';
else if (amount >= 4900 && amount <= 5100) packageType = 'pack_10';
else if (amount >= 2900 && amount <= 3100) packageType = 'pack_5';

if (chatId && packageType) {
  return [{
    json: {
      chatId: chatId,
      amount: amount,
      packageType: packageType,
      shouldActivate: true
    }
  }];
}
```

```sql
-- Postgres node: Activate Package
SELECT add_analyses_from_payment('{{ $json.chatId }}', '{{ $json.packageType }}');

-- + Insert в таблицу payments
```

### 7.2 Уведомление пользователю

```javascript
const analyses = $json.packageType === 'pack_20' ? 20 : 
                 $json.packageType === 'pack_10' ? 10 : 5;

const message = `✅ *Оплата получена!*\n\n` +
  `💎 Активирован пакет на ${analyses} анализов\n` +
  `📄 Лимит страниц увеличен\n\n` +
  `Отправьте документ для анализа!`;
```

---

## 🔄 ШАГ 8: Автоматизация обновления базы

### 8.1 Настройка расписания

```bash
В Workflow 0 (парсинг):
1. Откройте узел "Schedule Trigger"
2. Настройте: Каждое воскресенье в 03:00
   Rule: Weeks → Interval: 1
   Hour: 3
   Minute: 0
```

### 8.2 Инкрементальное обновление

Для экономии кредитов Firecrawl используйте параметр `maxAge`:

```javascript
scrapeOptions: {
  formats: ['markdown'],
  maxAge: 2592000000, // 30 дней - для законов
  parsers: ['pdf']
}
```

---

## 🎯 ШАГ 9: Продвинутые функции (Premium)

### 9.1 Сравнение версий договора

Добавьте новую ветку в основной workflow:

```javascript
// Узел: Detect Multiple Docs
const filesInBuffer = $('выбор лидера').item.json.filesCount;

if (filesInBuffer === 2) {
  // Пользователь отправил 2 файла - возможно сравнение версий
  return [{
    json: {
      shouldCompare: true,
      files: $('получаем данные о файлах').item.json.files
    }
  }];
}
```

```javascript
// Узел: Compare Versions (AI)
const version1 = $json.file1.text;
const version2 = $json.file2.text;

const prompt = `Сравни две версии договора:

ВЕРСИЯ 1 (была):
${version1}

ВЕРСИЯ 2 (стала):
${version2}

Выдели:
1. ЧТО ДОБАВЛЕНО (новые пункты)
2. ЧТО УДАЛЕНО (какие пункты убрали)
3. ЧТО ИЗМЕНИЛОСЬ (измененные формулировки)
4. ВЛИЯНИЕ НА РИСКИ (стало лучше/хуже)

Формат: детальный построчный разбор изменений.`;
```

### 9.2 Генерация протокола разногласий

```javascript
// После анализа добавьте кнопку:
if (riskScore >= 3) {
  keyboard: {
    inline_keyboard: [[
      { 
        text: '📝 Сгенерировать протокол разногласий', 
        callback_data: `generate_protocol_${messageId}` 
      }
    ]]
  }
}
```

```javascript
// Отдельный workflow для обработки callback:
const analysisId = $json.callback_data.split('_')[2];

// Получаем из БД результат анализа
const analysis = await getAnalysisById(analysisId);

const prompt = `На основе анализа создай ПРОТОКОЛ РАЗНОГЛАСИЙ:

РИСКИ:
${JSON.stringify(analysis.risk_points, null, 2)}

Используй формат:
ПРОТОКОЛ РАЗНОГЛАСИЙ
к Договору {тип} от {дата}

1. Пункт X.X изложить в редакции:
[новый текст]
Обоснование: [ссылка на закон]

...`;
```

---

## 📊 ШАГ 10: Мониторинг и оптимизация

### 10.1 Дашборд в Supabase

Создайте материализованное представление для аналитики:

```sql
CREATE MATERIALIZED VIEW analytics_dashboard AS
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_analyses,
  AVG(risk_score) as avg_risk,
  COUNT(DISTINCT chat_id) as unique_users,
  SUM(CASE WHEN risk_score >= 4 THEN 1 ELSE 0 END) as high_risk_docs
FROM analyzed_documents
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Обновляйте раз в день
REFRESH MATERIALIZED VIEW analytics_dashboard;
```

### 10.2 Мониторинг расходов Firecrawl

```bash
1. Dashboard Firecrawl → Usage
2. Отслеживайте:
   - Crawl credits (парсинг базы: ~100-200K/неделю)
   - Scrape credits (анализ документов: ~5-10/документ)
```

### 10.3 Оптимизация промптов

Тестируйте разные версии промптов:

```sql
-- Добавьте версионирование
ALTER TABLE analysis_templates ADD COLUMN version INTEGER DEFAULT 1;
ALTER TABLE analyzed_documents ADD COLUMN prompt_version INTEGER;

-- A/B тестинг
-- Проверяйте какая версия дает лучше результаты
SELECT 
  prompt_version,
  AVG(risk_score) as avg_risk,
  COUNT(*) as analyses_count
FROM analyzed_documents
GROUP BY prompt_version;
```

---

## ⚠️ Типичные проблемы и решения

### Проблема 1: Firecrawl не парсит сайт

**Симптомы:** Crawl возвращает пустой массив или ошибку

**Решение:**
```javascript
// Добавьте в crawlOptions:
scrapeOptions: {
  formats: ['markdown'],
  waitFor: 2000, // подождать загрузки JS
  proxy: 'auto', // использовать прокси
  skipTlsVerification: true // если сертификат проблемный
}
```

### Проблема 2: Векторный поиск не находит результаты

**Решение:**
```sql
-- Проверьте индекс
DROP INDEX IF EXISTS idx_legal_knowledge_embedding;

CREATE INDEX idx_legal_knowledge_embedding 
ON legal_knowledge 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

VACUUM ANALYZE legal_knowledge;
```

### Проблема 3: AI возвращает не JSON

**Решение:**
```javascript
// Улучшенный парсинг в узле форматирования:
try {
  // Сначала пробуем найти JSON в markdown
  let jsonText = aiResponse.match(/```json\\s*([\\s\\S]*?)\\s*```/)?.[1];
  
  // Если нет - ищем любой JSON
  if (!jsonText) {
    jsonText = aiResponse.match(/\\{[\\s\\S]*\\}/)?.[0];
  }
  
  // Очищаем от возможного мусора
  if (jsonText) {
    jsonText = jsonText
      .replace(/^[^{]*/, '') // убираем до первой {
      .replace(/[^}]*$/, ''); // убираем после последней }
  }
  
  analysisResult = JSON.parse(jsonText);
} catch (e) {
  // Запасной вариант - структурированный текст
  analysisResult = {
    document_type: 'unknown',
    overall_risk_score: 3,
    executive_summary: aiResponse,
    risk_points: []
  };
}
```

### Проблема 4: Google Script OCR не справляется

**Альтернатива - использовать Firecrawl для PDF:**

```javascript
// Замените узел "Отправить в Google Script" на:
{
  "name": "Firecrawl: Extract PDF",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://api.firecrawl.dev/v2/scrape",
    "method": "POST",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Authorization",
          "value": "=Bearer {{ $credentials.firecrawlApiKey }}"
        }
      ]
    },
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        {
          "name": "url",
          "value": "={{ $json.url }}" // URL файла
        },
        {
          "name": "formats",
          "value": ["markdown"]
        },
        {
          "name": "parsers",
          "value": [{ "type": "pdf", "maxPages": 15 }]
        }
      ]
    }
  }
}

// Результат будет в: $json.data.markdown
```

---

## 🎓 ШАГ 11: Обучение и улучшение

### 11.1 Сбор обратной связи

Добавьте после отправки анализа:

```javascript
message += `\\n\\n📊 Оцените анализ:\\n`;
keyboard: {
  inline_keyboard: [[
    { text: '👍 Полезно', callback_data: `feedback_good_${analysisId}` },
    { text: '👎 Не помогло', callback_data: `feedback_bad_${analysisId}` }
  ]]
}
```

### 11.2 Логирование для улучшения

```sql
-- Создайте таблицу feedback
CREATE TABLE user_feedback (
  id BIGSERIAL PRIMARY KEY,
  analysis_id BIGINT REFERENCES analyzed_documents(id),
  rating INTEGER, -- 1-5
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Анализируйте что работает плохо:
SELECT 
  ad.document_type,
  AVG(uf.rating) as avg_rating,
  COUNT(*) as feedback_count
FROM user_feedback uf
JOIN analyzed_documents ad ON ad.id = uf.analysis_id
GROUP BY ad.document_type;
```

### 11.3 Файн-тюнинг (продвинутый уровень)

Когда накопится 50+ проанализированных документов:

```bash
1. Экспортируйте лучшие анализы:
   SELECT extracted_text, analysis_result 
   FROM analyzed_documents 
   WHERE risk_score IS NOT NULL
   
2. Подготовьте JSONL для файн-тюнинга GPT-4o-mini
3. Обучите модель на ваших данных
4. Используйте для FREE tier (экономия на токенах)
```

---

## 🚀 ШАГ 12: Запуск в продакшн

### Чеклист перед запуском:

- [ ] Все SQL функции созданы и протестированы
- [ ] База знаний наполнена (минимум 200+ записей)
- [ ] Векторный поиск работает
- [ ] Тестовый документ анализируется корректно
- [ ] Лимиты работают
- [ ] Система оплаты подключена
- [ ] Добавлены disclaimers во все ответы
- [ ] Настроен мониторинг расходов
- [ ] Резервное копирование БД
- [ ] Rate limiting для защиты от спама

### Soft Launch:

```bash
1. Запустите для 10-20 тестовых пользователей
2. Соберите обратную связь
3. Исправьте найденные баги
4. Оптимизируйте промпты
5. Публичный запуск
```

---

## 📈 Метрики успеха

Отслеживайте:

```sql
-- Конверсия в платящих
SELECT 
  COUNT(DISTINCT CASE WHEN subscription_tier != 'free' THEN chat_id END) * 100.0 /
  COUNT(DISTINCT chat_id) as conversion_rate
FROM user_limits;

-- Средний чек
SELECT AVG(amount) FROM payments WHERE payment_status = 'completed';

-- Retention (возвращаются ли пользователи)
SELECT 
  chat_id,
  COUNT(*) as analyses_count,
  MAX(created_at) - MIN(created_at) as user_lifetime
FROM analyzed_documents
GROUP BY chat_id
HAVING COUNT(*) > 1;

-- Популярные типы документов
SELECT document_type, COUNT(*) 
FROM analyzed_documents 
GROUP BY document_type 
ORDER BY COUNT(*) DESC;
```

---

## 🎉 Готово!

Ваш AI-Юрист готов к работе!

### Следующие шаги:

1. ✅ Протестируйте на реальных документах
2. 📣 Запустите рекламу в соцсетях
3. 💬 Соберите первых пользователей
4. 📊 Анализируйте метрики
5. 🔄 Итерируйте на основе feedback

### Полезные ссылки:

- [Firecrawl Dashboard](https://www.firecrawl.dev/app)
- [Supabase Dashboard](https://supabase.com/dashboard)
- [OpenAI Usage](https://platform.openai.com/usage)

---

**Удачи в запуске! 🚀**

_Если возникнут вопросы - проверьте секцию Troubleshooting в SETUP_GUIDE.md_

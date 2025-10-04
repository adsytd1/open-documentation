# 🤖 AI-Юрист: Полное руководство по настройке

## 📋 Содержание
1. [Архитектура решения](#архитектура)
2. [Настройка Supabase](#supabase)
3. [Настройка Firecrawl](#firecrawl)
4. [Импорт Workflows в n8n](#workflows)
5. [Интеграция с существующим flow](#интеграция)
6. [Монетизация](#монетизация)
7. [Тестирование](#тестирование)

---

## 🏗️ Архитектура решения {#архитектура}

```
┌─────────────────────────────────────────────────────────────┐
│                    ПОЛЬЗОВАТЕЛЬ                              │
│              (отправляет документ в WhatsApp)               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              WORKFLOW 1: Обработка сообщений                │
│  • Получение файла                                          │
│  • OCR через Google Script                                  │
│  • Определение типа (юридический/нет)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│            WORKFLOW 2: Анализ документа                      │
│  • Проверка лимитов пользователя                            │
│  • Векторный поиск в базе законов                           │
│  • AI-анализ с контекстом                                   │
│  • Форматирование ответа                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  SUPABASE БАЗА ДАННЫХ                        │
│  ┌────────────────────────────────────────────────┐         │
│  │  legal_knowledge (векторная БД)                │         │
│  │  • Гражданский кодекс РК                       │         │
│  │  • Трудовой кодекс РК                          │         │
│  │  • Судебная практика                           │         │
│  │  • Шаблоны договоров                           │         │
│  └────────────────────────────────────────────────┘         │
│  ┌────────────────────────────────────────────────┐         │
│  │  user_limits (лимиты)                          │         │
│  │  analyzed_documents (история)                  │         │
│  │  payments (платежи)                            │         │
│  └────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
                       ▲
                       │
┌──────────────────────┴──────────────────────────────────────┐
│       WORKFLOW 0: Парсинг юридической базы (1 раз/неделю)   │
│  • Firecrawl: парсинг zakon.kz, sud.gov.kz                  │
│  • Чанкирование текста                                      │
│  • Векторизация через OpenAI Embeddings                     │
│  • Сохранение в Supabase                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Настройка Supabase {#supabase}

### Шаг 1: Создание базы данных

1. Войдите в [Supabase](https://supabase.com)
2. Создайте новый проект или используйте существующий
3. Перейдите в SQL Editor

### Шаг 2: Выполнение SQL скрипта

Выполните содержимое файла `supabase_schema.sql`:

```bash
# Скопируйте содержимое файла и выполните в SQL Editor Supabase
```

### Шаг 3: Включение векторного расширения

```sql
-- В SQL Editor выполните:
CREATE EXTENSION IF NOT EXISTS vector;
```

### Шаг 4: Получение credentials

1. Перейдите в Settings → Database
2. Скопируйте:
   - Host
   - Database name
   - Port
   - User
   - Password
3. Connection string будет вида:
   ```
   postgres://postgres:[PASSWORD]@[HOST]:5432/postgres
   ```

---

## 🔥 Настройка Firecrawl {#firecrawl}

### Шаг 1: Регистрация

1. Перейдите на [firecrawl.dev](https://firecrawl.dev)
2. Зарегистрируйтесь или войдите
3. Перейдите в [API Keys](https://www.firecrawl.dev/app/api-keys)

### Шаг 2: Получение API ключа

1. Создайте новый API ключ
2. Скопируйте его (формат: `fc-XXXXXXXXXX`)
3. **Сохраните в безопасном месте!**

### Шаг 3: Выбор плана

Для AI-Юриста рекомендуется:
- **Hobby план** (первый месяц) - 500K кредитов
- Парсинг юридических источников ~ 100-200K кредитов
- Анализ пользовательских документов ~ 1-5 кредитов/документ

---

## 🔄 Импорт Workflows в n8n {#workflows}

### WORKFLOW 0: Парсинг юридической базы

1. В n8n: **New Workflow**
2. Импортируйте `workflow_1_legal_knowledge_parser.json`
3. Настройте credentials:
   - **Firecrawl API**: добавьте ваш API ключ
   - **PostgreSQL (Supabase)**: добавьте connection string
4. **ВАЖНО**: Откорректируйте URL источников в узле "Legal Sources Config"

**Рекомендуемые источники для РК:**
```javascript
const legalSources = [
  {
    category: 'civil_code',
    url: 'https://online.zakon.kz/Document/?doc_id=31577399', 
    description: 'Гражданский кодекс РК',
    crawlOptions: {
      limit: 100,
      includePaths: ['/Document/.*'],
      formats: ['markdown'],
      onlyMainContent: true,
      parsers: ['pdf']
    }
  },
  {
    category: 'labor_code',
    url: 'https://online.zakon.kz/Document/?doc_id=38910832',
    description: 'Трудовой кодекс РК',
    crawlOptions: { limit: 80 }
  },
  {
    category: 'judicial_practice',
    url: 'https://sud.gov.kz/rus/content/sudebnaya-praktika',
    description: 'Судебная практика ВС РК',
    crawlOptions: { 
      limit: 150,
      includePaths: ['.*praktika.*', '.*postanovlen.*']
    }
  }
];
```

5. Запустите workflow вручную первый раз
6. Проверьте таблицу `legal_knowledge` в Supabase - должны появиться записи

### WORKFLOW 2: Анализ документов

Этот workflow встраивается в ваш существующий поток.

### WORKFLOW 3: Команды и подписки

1. Импортируйте `workflow_3_subscription_management.json`
2. Активируйте webhook
3. Настройте Kaspi оплату (см. раздел Монетизация)

---

## 🔗 Интеграция с существующим flow {#интеграция}

### Модификация вашего основного workflow

#### 1. После узла "Wait2" добавьте узлы детекции:

```javascript
// Узел: "Detect Legal Document" (Code node)
const fileName = ($('получаем данные о файлах').item.json.name || '').toLowerCase();
const fileType = $('получаем данные о файлах').item.json.type;
const scannedText = $('Отправить в Google Script').item.json || '';

// Ключевые слова
const legalKeywords = [
  'договор', 'contract', 'соглашение', 'agreement',
  'нда', 'nda', 'аренда', 'rental', 'lease',
  'услуг', 'service', 'трудов', 'employment',
  'купли', 'purchase', 'продаж', 'sale'
];

// Проверка по имени файла И по содержимому
const isLegalByName = legalKeywords.some(kw => fileName.includes(kw));
const isLegalByContent = legalKeywords.some(kw => 
  scannedText.toLowerCase().includes(kw)
);

const isPdfOrDocx = fileType === 'pdf' || fileType === 'document';

return [{
  json: {
    isLegalDocument: (isLegalByName || isLegalByContent) && isPdfOrDocx,
    fileName: fileName,
    fileType: fileType,
    shouldAnalyze: (isLegalByName || isLegalByContent) && isPdfOrDocx,
    scannedText: scannedText
  }
}];
```

#### 2. Добавьте условие (IF node):

```
IF: $json.shouldAnalyze === true
  TRUE → Execute Legal Analysis Workflow
  FALSE → Loop Over Items (продолжить обычную обработку)
```

#### 3. В узле "Ответ" добавьте обработку:

```javascript
// В начало вашего кода узла "Ответ"
const items = $input.all();

if (items.length === 0) {
  return [{ json: {} }];
}

// НОВОЕ: Проверка на юридический анализ
if (items[0].json.sourceType === 'legal_analysis') {
  return [{
    json: {
      chatId: items[0].json.chatId,
      message: items[0].json.message,
      sourceType: 'legal_analysis',
      processed_message_ids: items[0].json.processed_message_ids || []
    }
  }];
}

// ... остальной ваш код ...
```

---

## 💰 Монетизация {#монетизация}

### Структура пакетов

```javascript
const PACKAGES = {
  pack_5: {
    price: 2990, // KZT
    analyses: 5,
    maxPages: 10,
    features: ['basic_analysis'],
    validDays: 30
  },
  pack_10: {
    price: 4990,
    analyses: 10,
    maxPages: 10,
    features: ['basic_analysis'],
    validDays: 60
  },
  pack_20: {
    price: 7990,
    analyses: 20,
    maxPages: 15,
    features: [
      'advanced_analysis',
      'version_comparison',
      'disagreement_protocol',
      'priority_processing'
    ],
    validDays: 90
  }
};
```

### Интеграция Kaspi

1. Создайте Kaspi QR
2. При получении платежа проверяйте комментарий (должен содержать chatId)
3. Вызывайте функцию:

```sql
SELECT add_analyses_from_payment('CHAT_ID', 'pack_5');
```

### Автоматическая проверка оплаты

Создайте отдельный workflow с таймером каждые 5 минут:
- Проверяет Kaspi API на новые платежи
- Парсит комментарий для извлечения chatId
- Активирует пакет в БД
- Отправляет уведомление пользователю

---

## 🧪 Тестирование {#тестирование}

### Тест 1: Парсинг юридических источников

```bash
# Запустите WORKFLOW 1 вручную
# Проверьте в Supabase:

SELECT category, COUNT(*) as chunks_count 
FROM legal_knowledge 
GROUP BY category;

# Должно быть минимум:
# civil_code: 50-100 записей
# labor_code: 30-80 записей  
# judicial_practice: 100-150 записей
```

### Тест 2: Векторный поиск

```sql
-- Протестируйте поиск релевантного контекста
SELECT * FROM match_legal_documents(
  (SELECT embedding FROM legal_knowledge LIMIT 1),
  0.7,
  5,
  'civil_code'
);
```

### Тест 3: Анализ тестового договора

1. Создайте простой тестовый договор аренды (PDF)
2. Отправьте боту
3. Проверьте:
   - ✅ Бот распознал тип документа
   - ✅ Нашел рискованные пункты
   - ✅ Дал рекомендации со ссылками на законы
   - ✅ Вычел 1 анализ из лимита
   - ✅ Сохранил результат в БД

### Тест 4: Проверка лимитов

```bash
# Отправьте 2 документа подряд (FREE tier)
# Первый должен обработаться
# Второй должен получить сообщение о лимите
```

---

## ⚙️ Продвинутая настройка

### Улучшение точности анализа

#### 1. Настройка промптов под специфику РК

В таблице `analysis_templates` обновите системные промпты:

```sql
UPDATE analysis_templates 
SET system_prompt = 'Ты опытный юрист РК со специализацией на договорном праве. 
При анализе обязательно учитывай:
- Гражданский кодекс РК (особенно главы 26-29 об обязательствах)
- Закон РК "О защите прав потребителей"
- Судебную практику Верховного Суда РК

Анализируй договор с точки зрения законодательства РК...'
WHERE document_type = 'rental_agreement';
```

#### 2. Добавление категорий источников

```javascript
// В узле "Legal Sources Config" добавьте:
{
  category: 'consumer_protection',
  url: 'https://online.zakon.kz/Document/?doc_id=30002629',
  description: 'Закон о защите прав потребителей',
  crawlOptions: { limit: 50 }
},
{
  category: 'arbitration_practice',
  url: 'https://arbitr.gov.kz/',
  description: 'Решения арбитражных судов',
  crawlOptions: { 
    limit: 100,
    includePaths: ['.*resheni.*', '.*postanovlen.*']
  }
}
```

### Оптимизация производительности

#### 1. Кэширование Firecrawl

Используйте параметр `maxAge` для кэширования:

```javascript
// В Firecrawl запросах:
scrapeOptions: {
  formats: ['markdown'],
  onlyMainContent: true,
  parsers: ['pdf'],
  maxAge: 604800000 // 1 неделя - законы меняются редко
}
```

#### 2. Batch processing для векторизации

```javascript
// Обрабатывайте по 10 чанков за раз
const BATCH_SIZE = 10;
for (let i = 0; i < chunks.length; i += BATCH_SIZE) {
  const batch = chunks.slice(i, i + BATCH_SIZE);
  // векторизация batch
}
```

---

## 🚀 Дополнительные функции

### Premium Feature 1: Сравнение версий договора

Добавьте в WORKFLOW 2:

```javascript
// Узел: "Compare Contract Versions"
// Если пользователь отправил 2 файла подряд

const version1 = $('file1').json.text;
const version2 = $('file2').json.text;

const prompt = `Сравни две версии договора и выдели:
1. ЧТО ИЗМЕНИЛОСЬ (добавлено/удалено/изменено)
2. КАК ЭТО ВЛИЯЕТ НА РИСКИ
3. РЕКОМЕНДАЦИИ по изменениям

ВЕРСИЯ 1:
${version1}

ВЕРСИЯ 2:
${version2}`;
```

### Premium Feature 2: Генерация протокола разногласий

```javascript
// Узел: "Generate Disagreement Protocol"
const analysisResult = $json.analysisResult;

const prompt = `На основе анализа договора создай официальный 
ПРОТОКОЛ РАЗНОГЛАСИЙ в формате:

1. Пункт договора X.X
   Текст пункта: "..."
   Предлагаем изложить в редакции: "..."
   Обоснование: [ссылка на ГК РК]

2. ...

Риски: ${JSON.stringify(analysisResult.risk_points)}`;
```

---

## 🐛 Troubleshooting

### Проблема: Firecrawl не парсит PDF

**Решение:**
```javascript
// Добавьте в scrapeOptions:
parsers: [{ type: 'pdf', maxPages: 100 }]
```

### Проблема: Векторный поиск не находит контекст

**Решение:**
```sql
-- Проверьте индексы
CREATE INDEX IF NOT EXISTS idx_legal_knowledge_embedding 
ON legal_knowledge 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- Пересоздайте индекс если нужно
DROP INDEX idx_legal_knowledge_embedding;
-- создайте заново
```

### Проблема: Медленный анализ

**Решение:**
1. Уменьшите количество контекстных документов (5 вместо 10)
2. Сократите размер чанков (800 вместо 1000 символов)
3. Используйте `gpt-4o-mini` вместо `gpt-4o` для детекции типа

---

## 📊 Мониторинг и аналитика

### Запросы для отслеживания

```sql
-- Статистика использования
SELECT 
  subscription_tier,
  COUNT(*) as users,
  SUM(analyses_used_this_month) as total_analyses
FROM user_limits
GROUP BY subscription_tier;

-- Популярные типы документов
SELECT 
  document_type,
  COUNT(*) as count,
  AVG(risk_score) as avg_risk
FROM analyzed_documents
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY document_type
ORDER BY count DESC;

-- Конверсия в платящих пользователей
SELECT 
  (SELECT COUNT(DISTINCT chat_id) FROM payments WHERE payment_status = 'completed') * 100.0 /
  (SELECT COUNT(*) FROM user_limits) as conversion_rate;
```

---

## 💡 Продвинутые советы

### 1. Улучшение качества парсинга

**Используйте Firecrawl Extract для структурированного извлечения:**

```javascript
// Вместо обычного crawl используйте extract:
{
  "url": "https://online.zakon.kz/Document/?doc_id=31577399",
  "prompt": "Извлеки все статьи Гражданского кодекса РК, касающиеся договоров: номер статьи, название, полный текст",
  "schema": {
    "type": "object",
    "properties": {
      "articles": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "article_number": { "type": "string" },
            "title": { "type": "string" },
            "content": { "type": "string" }
          }
        }
      }
    }
  }
}
```

### 2. Кэширование частых запросов

```sql
-- Создайте материализованное представление для популярных статей
CREATE MATERIALIZED VIEW popular_legal_articles AS
SELECT DISTINCT ON (title) 
  content, category, source_url, title
FROM legal_knowledge
WHERE category IN ('civil_code', 'labor_code')
ORDER BY title, id DESC;

-- Обновляйте раз в день
REFRESH MATERIALIZED VIEW popular_legal_articles;
```

### 3. А/Б тестирование промптов

Создайте несколько версий системных промптов и тестируйте эффективность:

```sql
ALTER TABLE analysis_templates ADD COLUMN prompt_version INTEGER DEFAULT 1;
ALTER TABLE analyzed_documents ADD COLUMN prompt_version INTEGER;

-- Отслеживайте, какая версия дает лучшие результаты
```

---

## 🎯 Roadmap развития

### Фаза 1: MVP (1-2 недели)
- ✅ Базовый анализ 3 типов документов
- ✅ Векторная база с ГК и ТК РК
- ✅ Система лимитов
- ✅ Kaspi оплата

### Фаза 2: Рост (1 месяц)
- 🔄 Добавить 5+ типов документов
- 🔄 Сравнение версий
- 🔄 Генерация протоколов разногласий
- 🔄 Telegram Bot (дополнительно к WhatsApp)

### Фаза 3: Масштабирование (3 месяца)
- 🔄 Веб-интерфейс
- 🔄 API для партнеров
- 🔄 Интеграция с юридическими CRM
- 🔄 White-label решения

---

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте логи n8n: Settings → Log Streaming
2. Проверьте Supabase logs
3. Проверьте Firecrawl dashboard: [app/usage](https://www.firecrawl.dev/app)

---

## 📄 Лицензия и дисклеймеры

**ВАЖНО:** 

⚖️ Данный бот НЕ ЗАМЕНЯЕТ профессиональную юридическую консультацию.

Обязательно добавьте в каждый ответ бота:
```
⚠️ Данный анализ носит информационный характер и не является 
юридической консультацией. Для принятия важных решений 
обратитесь к квалифицированному юристу.
```

---

**Успехов в запуске! 🚀**

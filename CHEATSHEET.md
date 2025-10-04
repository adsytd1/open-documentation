# 📝 AI-Юрист: Шпаргалка

> Быстрый доступ к ключевым командам, кодам и настройкам

---

## ⚡ Быстрые команды

### Supabase (SQL)

```sql
-- Проверить что все таблицы созданы
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- Проверить количество данных
SELECT 
  'legal_knowledge' as table, COUNT(*) as rows FROM legal_knowledge
UNION ALL
SELECT 'user_limits', COUNT(*) FROM user_limits
UNION ALL  
SELECT 'analyzed_documents', COUNT(*) FROM analyzed_documents;

-- Проверить лимит пользователя
SELECT * FROM check_user_limit('CHAT_ID');

-- Добавить тестового пользователя
INSERT INTO user_limits (chat_id, subscription_tier, analyses_limit, max_pages_per_doc)
VALUES ('test_123', 'premium', 20, 15);

-- Активировать пакет после оплаты
SELECT add_analyses_from_payment('CHAT_ID', 'pack_10');

-- Поиск в векторной базе (нужен вектор)
SELECT * FROM match_legal_documents(
  '[0.1, 0.2, ...]'::vector,
  0.7,
  10,
  'civil_code'
);
```

### Firecrawl (cURL)

```bash
# Scrape одной страницы
curl -X POST https://api.firecrawl.dev/v2/scrape \
  -H "Authorization: Bearer fc-YOUR-KEY" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://zakon.kz/doc","formats":["markdown"],"parsers":["pdf"]}'

# Start crawl
curl -X POST https://api.firecrawl.dev/v2/crawl \
  -H "Authorization: Bearer fc-YOUR-KEY" \
  -d '{"url":"https://zakon.kz","limit":100,"scrapeOptions":{"formats":["markdown"],"parsers":["pdf"]}}'

# Check crawl status
curl -X GET https://api.firecrawl.dev/v2/crawl/CRAWL-ID \
  -H "Authorization: Bearer fc-YOUR-KEY"

# Check credits
curl -X GET https://api.firecrawl.dev/v2/team/credit-usage \
  -H "Authorization: Bearer fc-YOUR-KEY"
```

### n8n (JavaScript nodes)

```javascript
// Получить chatId
const chatId = $('set chatId').first().json.chatId;

// Получить данные из предыдущего узла
const data = $('NodeName').first().json;

// Получить все элементы
const allItems = $input.all();

// Postgres query
await $postgres.query('SELECT * FROM table WHERE id = $1', [value]);

// Условный возврат
return condition 
  ? [{ json: { success: true } }]
  : null; // останавливает выполнение
```

---

## 🎯 Готовые сниппеты кода

### Детекция юридического документа

```javascript
const legalKeywords = ['договор','contract','соглашение','аренда','услуг','нда'];
const text = $json.text.toLowerCase();
const isLegal = legalKeywords.some(kw => text.includes(kw)) && text.length > 200;
return [{ json: { isLegal } }];
```

### Форматирование ответа

```javascript
const risk = $json.risk_score;
const emoji = {1:'✅',2:'✅',3:'⚠️',4:'🚨',5:'🔴'}[risk];

const msg = `⚖️ *АНАЛИЗ*\\n\\n` +
  `Риск: ${emoji} ${risk}/5\\n\\n` +
  `Проблемы:\\n` +
  $json.risks.map((r,i) => `${i+1}. ${r}`).join('\\n') +
  `\\n\\n⚖️ _Не юр.консультация_`;
  
return [{ json: { message: msg } }];
```

### Проверка лимита

```javascript
const canAnalyze = await $postgres.query(
  'SELECT can_analyze($1)', 
  [$json.chatId]
);

if (!canAnalyze[0].can_analyze) {
  return [{ json: { error: true, message: 'Лимит исчерпан. /pay' } }];
}
```

---

## 🔧 Полезные SQL запросы

```sql
-- Статистика за сегодня
SELECT COUNT(*) FROM analyzed_documents 
WHERE DATE(created_at) = CURRENT_DATE;

-- Топ пользователей
SELECT chat_id, COUNT(*) as analyses 
FROM analyzed_documents 
GROUP BY chat_id 
ORDER BY analyses DESC 
LIMIT 10;

-- Средний риск-скор
SELECT AVG(risk_score) FROM analyzed_documents;

-- Конверсия
SELECT 
  COUNT(DISTINCT CASE WHEN subscription_tier != 'free' THEN chat_id END) * 100.0 /
  COUNT(*) as conversion_rate
FROM user_limits;

-- Очистка тестовых данных
DELETE FROM user_limits WHERE chat_id LIKE '%test%';
DELETE FROM analyzed_documents WHERE chat_id LIKE '%test%';
```

---

## 📊 Мониторинг одной командой

```sql
-- Дашборд (выполните в Supabase SQL Editor)
SELECT 
  'Пользователей всего' as metric, 
  COUNT(*)::text as value 
FROM user_limits
UNION ALL
SELECT 'Платящих пользователей', 
  COUNT(*)::text 
FROM user_limits 
WHERE subscription_tier != 'free'
UNION ALL
SELECT 'Анализов сегодня', 
  COUNT(*)::text 
FROM analyzed_documents 
WHERE DATE(created_at) = CURRENT_DATE
UNION ALL
SELECT 'Средний риск', 
  ROUND(AVG(risk_score), 2)::text 
FROM analyzed_documents
UNION ALL
SELECT 'Векторов в базе', 
  COUNT(*)::text 
FROM legal_knowledge;
```

---

## 🎨 Шаблоны сообщений

### Приветствие

```javascript
const welcome = `🤖 *AI-Юрист*

Анализирую договоры и выявляю риски.

📤 Отправьте PDF/DOCX
⏱️ Ответ через 1-2 минуты

🆓 FREE: 1 анализ/месяц
💎 От 2990₸: до 20 анализов

Команды: /help`;
```

### Лимит исчерпан

```javascript
const limit = `❌ Лимит исчерпан

💎 Пакеты:
• 5 анализов - 2990₸
• 10 анализов - 4990₸  
• 20 анализов - 7990₸

Купить: /pay`;
```

### После анализа

```javascript
const result = `⚖️ АНАЛИЗ ЗАВЕРШЕН

Риск: ${emoji} ${score}/5

🚨 Риски:
${risks.map((r,i) => `${i+1}. ${r.issue}`).join('\\n')}

💡 Рекомендации:
${actions.join('\\n')}

⚖️ _Не является юр.консультацией_`;
```

---

## 🔑 Важные переменные окружения

```bash
# .env для n8n

# Supabase
DATABASE_URL=postgres://postgres:PASSWORD@db.xxx.supabase.co:5432/postgres

# Firecrawl  
FIRECRAWL_API_KEY=fc-XXXXXXXXXX

# OpenAI
OPENAI_API_KEY=sk-XXXXXXXXXX

# Опционально
TELEGRAM_BOT_TOKEN=
KASPI_API_KEY=
ADMIN_CHAT_ID=
```

---

## 📱 Regex паттерны

```javascript
// Определение типа по контенту
const patterns = {
  rental: /аренд|найм|lease|rent/i,
  service: /услуг|подряд|service|work/i,
  nda: /неразглаш|конфиденц|nda|confidential/i,
  employment: /трудов|работ|employment|labor/i
};

// Извлечение номера пункта
const clauseNumber = text.match(/(?:пункт|п\.|clause)\s*(\d+\.?\d*)/i)?.[1];

// Извлечение суммы
const amount = text.match(/(\d+[\s,]?\d*)\s*(?:тенге|₸|тг|руб)/i)?.[1];

// Поиск штрафов
const penalty = text.match(/штраф|пен[яи]|неустой/i);
```

---

## 🎯 Shortcuts для debugging

### n8n

```
Проверить execution:
n8n → Executions → выбрать последний → смотреть каждый узел

Быстрый тест узла:
Выделить узел → Execute node (кнопка молнии)

Проверить данные между узлами:
Кликнуть на connection → View data

Экспорт workflow:
три точки → Download
```

### Supabase

```
Проверить данные:
Table Editor → выбрать таблицу → Browse rows

Быстрый SQL:
SQL Editor → New query → вставить → Run

Мониторинг:
Database → Logs → фильтр по таблице

API logs:
Logs → выбрать функцию
```

### Firecrawl

```
Проверить usage:
Dashboard → Usage → Credits used

Посмотреть crawl:
Dashboard → Jobs → выбрать job

Проверить credits:
Dashboard → Settings → Billing
```

---

## 💡 Quick Fixes

### Проблема → Решение (1 строка)

```
Firecrawl timeout → Увеличьте waitFor в scrapeOptions
Vector search медленный → VACUUM ANALYZE legal_knowledge;
AI не возвращает JSON → Добавьте response_format в params
Пользователь не получает ответ → Проверьте узел "Ответ"
Лимиты не работают → SELECT * FROM user_limits WHERE chat_id = 'XXX';
База не наполняется → Проверьте Firecrawl credits
OCR не работает → Проверьте Google Script URL
Дорого анализировать → Используйте gpt-4o-mini
Низкая точность → Улучшите промпты из advanced_prompts.md
```

---

## 🎨 Emoji Guide

Используйте для читабельности сообщений:

```
Риски:
✅ 1-2 (низкий)
⚠️ 3 (средний)
🚨 4 (высокий)
🔴 5 (критический)

Статус:
✅ Успех
❌ Ошибка
⏳ Обработка
💡 Совет
📌 Важно

Действия:
📄 Документ
💰 Оплата
📊 Статистика
🔍 Поиск
⚖️ Юридическое
```

---

## 🔢 Важные числа

```
Лимиты Firecrawl (Hobby):
├─ 500K кредитов/месяц
├─ 100 requests/min
└─ 5 concurrent crawls

Лимиты OpenAI:
├─ GPT-4o: 500 req/min (Tier 1)
├─ Embeddings: 3000 req/min
└─ ~$100/мес для 1000 анализов

Supabase FREE:
├─ 500 MB database
├─ 5 GB bandwidth/месяц
└─ Unlimited API requests

Рекомендуемые размеры:
├─ Chunk size: 1000-1500 символов
├─ Overlap: 150-200 символов
├─ Vectors per search: 5-10
├─ Max tokens для GPT-4: 4000
└─ Timeout для анализа: 120 секунд
```

---

## 🎯 Критические пороги

```
Когда бить тревогу:

Firecrawl credits < 50K
└─> Купить дополнительные или upgrade план

OpenAI costs > $50/день  
└─> Проверить на утечку токенов, оптимизировать промпты

Database size > 450 MB
└─> Очистить старые данные или upgrade Supabase

Error rate > 5%
└─> Срочно проверить логи, возможно баг

Response time > 3 минут
└─> Оптимизировать векторный поиск или промпты

User complaints > 10% от анализов
└─> Срочно улучшать качество
```

---

## 📋 Копируй-вставляй коды

### Минимальный анализ (без базы)

```javascript
// Один узел OpenAI:
const analysis = await openai.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [{
    role: 'user',
    content: `Юрист РК. Анализируй договор. Риски 1-5 + топ-3 проблемы JSON:\n\n${$json.text}`
  }],
  response_format: { type: "json_object" }
});

return [{ json: JSON.parse(analysis.choices[0].message.content) }];
```

### Быстрая проверка лимита

```javascript
// Code node
const limit = await $postgres.query('SELECT can_analyze($1)', [$json.chatId]);
if (!limit[0].can_analyze) return null; // stop
```

### Форматирование для WhatsApp

```javascript
const msg = `*Жирный*\n_Курсив_\n~Зачеркнутый~\n\`Моноширинный\`\n`;
```

---

## 🎓 Полезные формулы

### Расчет стоимости анализа

```javascript
const costPerAnalysis = {
  ocr: 0,              // Google Script бесплатно
  embedding: 0.00002,  // OpenAI embedding
  vectorSearch: 0,     // Supabase бесплатно  
  gptAnalysis: 0.08,   // GPT-4o (~2K in + 1K out)
  total: 0.08002       // ~$0.08 = 38₸
};

// Margin при цене 600₸/анализ:
const margin = (600 - 38) / 600 * 100; // = 93.6%
```

### Оптимальный размер чанка

```javascript
const chunkSize = Math.max(
  500,  // минимум
  Math.min(
    1500, // максимум
    textLength / expectedChunks // распределить равномерно
  )
);
```

---

## 🔍 Debug команды

### Логи n8n

```bash
# Docker
docker-compose logs -f n8n

# Self-hosted
pm2 logs n8n

# В интерфейсе
Settings → Log Streaming → Enable
```

### Логи Supabase

```
Dashboard → Logs → Filter by:
- postgres-logs (SQL ошибки)
- function-logs (функции)
```

### Test векторного поиска

```sql
-- Создайте тестовый вектор
WITH test AS (
  SELECT embedding FROM legal_knowledge LIMIT 1
)
SELECT 
  title,
  1 - (embedding <=> (SELECT embedding FROM test)) as similarity
FROM legal_knowledge
ORDER BY embedding <=> (SELECT embedding FROM test)
LIMIT 5;
```

---

## 🎨 Быстрые улучшения

### +10% точности

```javascript
// Добавьте few-shot примеры в промпт
const fewShot = `
ПРИМЕР ХОРОШЕГО АНАЛИЗА:
INPUT: "Штраф 1% в день"
OUTPUT: {"risk": 5, "issue": "365%/год несоразмерно", "law": "ст.297 ГК РК"}

Теперь твой анализ:
...
`;
```

### +50% скорости

```sql
-- Оптимизируйте индекс
DROP INDEX idx_legal_knowledge_embedding;
CREATE INDEX idx_legal_knowledge_embedding 
ON legal_knowledge USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
VACUUM ANALYZE legal_knowledge;
```

### -30% расходов

```javascript
// Используйте кэш
scrapeOptions: {
  maxAge: 2592000000 // 30 дней для законов
}

// Используйте mini модель для детекции
model: 'gpt-4o-mini' // вместо gpt-4o
```

---

## 🎯 Shortcuts для частых задач

### Добавить новый тип документа

```sql
-- 1. Добавить в analysis_templates
INSERT INTO analysis_templates (document_type, system_prompt, risk_categories)
VALUES ('NEW_TYPE', 'PROMPT...', '["cat1","cat2"]'::jsonb);

-- 2. Обновить детектор типа в workflow
-- 3. Добавить в switch node обработку
```

### Изменить тарифы

```javascript
// В workflow_3 обновить:
const PACKAGES = {
  pack_5: { price: 2990, analyses: 5 },
  pack_10: { price: 4990, analyses: 10 },
  pack_20: { price: 7990, analyses: 20 }
};
```

### Добавить источник для парсинга

```javascript
// В workflow_1 узел "Legal Sources Config":
{
  category: 'new_category',
  url: 'https://new-source.kz',
  description: 'Описание',
  crawlOptions: {
    limit: 100,
    scrapeOptions: { formats: ['markdown'], parsers: ['pdf'] }
  }
}
```

---

## 📞 Контакты поддержки (быстрый доступ)

```
Firecrawl support:
📧 help@firecrawl.dev
💬 Discord: discord.gg/gSmWdAkdwd

Supabase support:  
💬 Discord: discord.supabase.com
📖 Docs: supabase.com/docs

OpenAI support:
🎫 help.openai.com
📖 platform.openai.com/docs

n8n community:
💬 community.n8n.io
📖 docs.n8n.io
```

---

## 🎯 Памятка по файлам

```
Нужно быстро начать?
└─> QUICK_START.md

Нужна полная инструкция?
└─> SETUP_GUIDE.md

Что-то не работает?
└─> FAQ_AND_OPTIMIZATION.md

Хочу улучшить качество?
└─> advanced_prompts.md

Примеры Firecrawl?
└─> firecrawl_examples.md

Как все устроено?
└─> ARCHITECTURE_AND_CHECKLIST.md

Как интегрировать?
└─> STEP_BY_STEP_INTEGRATION.md

Что где находится?
└─> PROJECT_INDEX.md (этот файл)

Тестовые данные?
└─> test_data_and_scripts.md

Готовые workflow?
└─> workflow_*.json
```

---

## ⚡ Экстренная помощь

### Если ничего не работает

```
1. ☕ Сделайте паузу
2. 📋 Проверьте чеклист в ARCHITECTURE_AND_CHECKLIST.md
3. 🔍 Проверьте логи (n8n, Supabase, Firecrawl)
4. 🧪 Запустите тест из test_data_and_scripts.md
5. 📖 Перечитайте SETUP_GUIDE.md секцию Troubleshooting
6. 💬 Спросите в community
```

### Откат на безопасную версию

```bash
# Если что-то сломалось после изменений:

# 1. Откат workflow в n8n
три точки → Executions → найдите рабочую версию → Restore

# 2. Откат БД
psql $DATABASE_URL < backup_YYYYMMDD.sql

# 3. Проверка
Запустите тестовый анализ
```

---

## 🎉 Quick Wins

### Легкие улучшения с большим эффектом

```
1. Добавьте эмодзи в ответы
   Было: "Риск: 4"  
   Стало: "Риск: 🚨 4/5"
   Эффект: +30% удовлетворенность

2. Сократите время ответа
   Было: 2-3 минуты
   Стало: 45-60 секунд (кэш + оптимизация)
   Эффект: Меньше отказов

3. Добавьте конкретику в риски
   Было: "Высокие штрафы"
   Стало: "Штраф 365%/год (ст.297 ГК РК)"
   Эффект: +40% доверие

4. Красивое форматирование
   Используйте: *жирный*, _курсив_, разделители
   Эффект: +25% читабельность
```

---

<div align="center">

## 📚 КОНЕЦ ШПАРГАЛКИ

**Сохраните этот файл в закладки!**

Вернетесь к нему 100 раз 😉

---

[🏠 На главную](./README.md) | [⚡ Быстрый старт](./QUICK_START.md) | [📖 Полный гайд](./SETUP_GUIDE.md)

</div>

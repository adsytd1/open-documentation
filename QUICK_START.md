# ⚡ AI-Юрист: Быстрый старт за 30 минут

> Минимальная рабочая версия для тестирования концепции

---

## 🎯 Цель

Запустить базовую версию AI-Юриста за 30 минут для проверки идеи.

---

## ✅ Что понадобится (готовьте заранее)

1. **Supabase аккаунт** → [supabase.com](https://supabase.com) (бесплатный)
2. **Firecrawl API ключ** → [firecrawl.dev](https://firecrawl.dev) (пробный период)
3. **OpenAI API ключ** → [platform.openai.com](https://platform.openai.com)
4. **n8n** (ваш существующий instance)

---

## 🚀 30-минутный план

### ⏱️ Минуты 1-10: Supabase

```bash
1. Зайдите на supabase.com
2. New Project → "ai-lawyer-test"
3. Регион: Singapore
4. Пароль: [придумайте и СОХРАНИТЕ]
5. Create Project (ждем 2 минуты)

6. SQL Editor → New query
7. Скопируйте ЭТОТ минимальный SQL:
```

```sql
-- МИНИМАЛЬНАЯ СХЕМА для MVP
CREATE EXTENSION IF NOT EXISTS vector;

-- 1. Векторная база (упрощенная)
CREATE TABLE legal_knowledge (
  id BIGSERIAL PRIMARY KEY,
  content TEXT,
  category VARCHAR(50),
  embedding vector(1536)
);

CREATE INDEX ON legal_knowledge USING ivfflat (embedding vector_cosine_ops);

-- 2. Лимиты пользователей (упрощенные)
CREATE TABLE user_limits (
  chat_id VARCHAR(255) PRIMARY KEY,
  analyses_left INTEGER DEFAULT 1
);

-- 3. История анализов (минимум полей)
CREATE TABLE analyzed_documents (
  id BIGSERIAL PRIMARY KEY,
  chat_id VARCHAR(255),
  risk_score INTEGER,
  analysis_text TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 4. Простая функция проверки лимита
CREATE OR REPLACE FUNCTION can_analyze(p_chat_id VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
  v_left INTEGER;
BEGIN
  INSERT INTO user_limits (chat_id) VALUES (p_chat_id)
  ON CONFLICT (chat_id) DO NOTHING;
  
  SELECT analyses_left INTO v_left FROM user_limits WHERE chat_id = p_chat_id;
  RETURN v_left > 0;
END;
$$ LANGUAGE plpgsql;

-- 5. Уменьшить лимит
CREATE OR REPLACE FUNCTION use_analysis(p_chat_id VARCHAR)
RETURNS void AS $$
BEGIN
  UPDATE user_limits SET analyses_left = analyses_left - 1
  WHERE chat_id = p_chat_id;
END;
$$ LANGUAGE plpgsql;
```

```bash
8. Run → должно выполниться без ошибок
9. Settings → Database → копируем Connection String
```

### ⏱️ Минуты 11-15: Firecrawl

```bash
1. firecrawl.dev → Sign Up
2. Бесплатный пробный период (14 дней)
3. Dashboard → API Keys → Create
4. Копируем ключ: fc-XXXXXXXXXX
```

### ⏱️ Минуты 16-25: n8n - Минимальный workflow

**Создайте ОДИН простой workflow:**

```javascript
// Узел 1: Webhook (триггер)
// Path: legal-analysis

// Узел 2: Code - Check Limit
const chatId = $json.chatId;
const canAnalyze = await $postgres.query(
  'SELECT can_analyze($1)',
  [chatId]
);

if (!canAnalyze[0].can_analyze) {
  return [{ json: { 
    error: true, 
    message: 'Лимит исчерпан' 
  }}];
}

return [{ json: { chatId, documentText: $json.text } }];

// Узел 3: OpenAI - Простой анализ (БЕЗ векторного поиска для MVP)
// Model: gpt-4o-mini (дешево)
// Prompt:
`Проанализируй договор и найди риски.
Оцени общий риск 1-5.
Верни JSON:
{
  "risk_score": 1-5,
  "risks": ["риск1", "риск2"],
  "verdict": "краткий вердикт"
}

ДОГОВОР:
${$json.documentText}`

// Узел 4: Code - Format Response
const result = JSON.parse($json.message);

const msg = `⚖️ АНАЛИЗ\n\n` +
  `Риск: ${result.risk_score}/5\n\n` +
  `Проблемы:\n` +
  result.risks.map((r, i) => `${i+1}. ${r}`).join('\n') +
  `\n\n${result.verdict}`;

return [{ json: { chatId: $json.chatId, message: msg } }];

// Узел 5: Postgres - Save & Decrement
// Query 1: INSERT INTO analyzed_documents...
// Query 2: SELECT use_analysis($1)

// Узел 6: Respond to User
// Отправить сообщение в WhatsApp/Telegram
```

### ⏱️ Минуты 26-30: Тестирование

```bash
1. Создайте простой тестовый договор (Word/PDF):
   "Договор аренды. Штраф 5% в день за просрочку."

2. Отправьте POST запрос на webhook:
   curl -X POST https://your-n8n.com/webhook/legal-analysis \
     -H 'Content-Type: application/json' \
     -d '{
       "chatId": "test_user",
       "text": "Договор аренды. Пункт 5: Штраф 5% в день..."
     }'

3. Должны получить анализ с риск-скором

4. Отправьте еще раз → "Лимит исчерпан"

5. ✅ MVP РАБОТАЕТ!
```

---

## 🎓 Что дальше?

### После успешного теста за 30 минут:

**День 1-2: Улучшения**
- Добавьте векторную базу (SETUP_GUIDE.md)
- Настройте Firecrawl парсинг законов
- Улучшите промпты (advanced_prompts.md)

**День 3-5: Монетизация**
- Интеграция Kaspi оплаты
- Система тарифов
- Команды бота (/start, /help, /pay)

**День 6-7: Полировка**
- Premium функции
- Красивое форматирование
- Тестирование на реальных пользователях

---

## 💰 Упрощенная монетизация для MVP

**Вариант "ручная обработка":**

```
1. Пользователь пишет: "Хочу купить 5 анализов"
2. Вы отправляете: "Переведите 2990₸ на Kaspi: +7XXX, укажите ваш ID: {chatId}"
3. После получения оплаты вручную выполняете:
   UPDATE user_limits SET analyses_left = 5 WHERE chat_id = '{chatId}';
4. Уведомляете пользователя: "✅ Активировано 5 анализов!"
```

Это позволит протестировать спрос БЕЗ полной автоматизации платежей.

---

## 🎯 MVP функционал (только самое важное)

### Что ОБЯЗАТЕЛЬНО должно быть:

- ✅ Прием PDF/DOCX файлов
- ✅ Извлечение текста (OCR)
- ✅ AI анализ договора
- ✅ Оценка рисков 1-5
- ✅ 2-3 конкретных риска
- ✅ Disclaimer
- ✅ Лимит 1 анализ для новых

### Что можно ОТЛОЖИТЬ:

- ⏸️ Векторная база законов (используйте базовые знания GPT)
- ⏸️ Firecrawl парсинг (добавите потом)
- ⏸️ Автоматические платежи (начните с ручных)
- ⏸️ Красивое форматирование (сначала текст)
- ⏸️ Команды бота (только основной анализ)
- ⏸️ Premium функции (сравнение версий, протоколы)

---

## 🧪 Быстрый тест без Firecrawl

**Если хотите протестировать СОВСЕМ БЫСТРО:**

```javascript
// Замените векторный поиск на:

// Code node: Mock Legal Context
const mockContext = `
Статья 297 ГК РК: Неустойка должна быть соразмерной.

Статья 299 ГК РК: Суд вправе уменьшить неустойку если она явно несоразмерна.

Статья 393 ГК РК: Договор должен содержать существенные условия: стороны, предмет, цена.

Статья 609 ГК РК: Односторонний отказ от договора аренды возможен только по основаниям закона.
`;

return [{ json: { legalContext: mockContext } }];

// Этого достаточно для базового анализа!
```

---

## 📊 Минимальные метрики для MVP

Отслеживайте только ключевое:

```sql
-- 1. Сколько пользователей
SELECT COUNT(DISTINCT chat_id) FROM user_limits;

-- 2. Сколько анализов сделано
SELECT COUNT(*) FROM analyzed_documents;

-- 3. Средний риск
SELECT AVG(risk_score) FROM analyzed_documents;

-- Этого достаточно для старта!
```

---

## ⚠️ Важные предупреждения для MVP

### 1. Юридический disclaimer

**ОБЯЗАТЕЛЬНО добавьте в КАЖДЫЙ ответ:**

```
⚖️ Это не юридическая консультация!
Для важных решений обратитесь к юристу.
```

### 2. Качество анализа

MVP будет давать **базовый** анализ без глубокого контекста законов.

**Не обещайте** пользователям:
- ❌ "100% точность"
- ❌ "Заменяет юриста"
- ❌ "Гарантия выигрыша в суде"

**Позиционируйте как:**
- ✅ "Первичный анализ рисков"
- ✅ "Помощник для непрофессионалов"
- ✅ "Быстрая проверка перед юристом"

### 3. Ограничения FREE версии

```
FREE tier MVP:
• 1 анализ
• До 3 страниц
• Базовый уровень детализации
• Время ответа: 2-5 минут
```

---

## 🎬 Сценарий первого пользователя

```
Шаг 1: Пользователь находит бота
  • Через рекламу / рекомендацию
  • Отправляет /start

Шаг 2: Получает приветствие
  📱 "Привет! Я анализирую договоры.
     Отправь PDF договора для проверки.
     FREE: 1 анализ"

Шаг 3: Отправляет договор
  • Загружает PDF
  • Ждет 1-2 минуты

Шаг 4: Получает результат
  ⚖️ "АНАЛИЗ:
     Риск: 4/5
     
     Проблемы:
     1. Штраф 365%/год (ст.297 ГК РК)
     2. Нет срока возврата залога
     
     Рекомендация: Не подписывать"

Шаг 5: Впечатлен, хочет еще
  📱 "Как купить еще анализов?"
  
  💬 "Пакет 5 анализов - 2990₸
     Напишите @your_telegram"
```

---

## 💡 Советы для успешного MVP

### 1. Начните с узкой ниши

```
❌ НЕ делайте:
"Анализируем любые документы"

✅ ДЕЛАЙТЕ:
"Специализируемся на договорах аренды жилья"

Почему:
• Фокус → качество выше
• Легче набрать базу знаний
• Целевая аудитория понятна
• Проще маркетинг
```

### 2. Собирайте feedback с первого дня

```javascript
// После каждого анализа спрашивайте:
const feedback = {
  message: "Был ли анализ полезен?",
  keyboard: {
    inline_keyboard: [[
      { text: "👍 Да", callback_data: "fb_yes" },
      { text: "👎 Нет", callback_data: "fb_no" }
    ]]
  }
};

// Если "Нет" - спрашивайте почему
// Улучшайте на основе ответов!
```

### 3. Начните с друзей и знакомых

```
День 1-3: Бета-тест на 10 знакомых
  → Собираете feedback
  → Исправляете баги
  → Улучшаете промпты

День 4-7: Soft launch в соцсетях
  → 50-100 пользователей
  → Анализ метрик
  → Оптимизация

День 8+: Публичный запуск
  → Реклама
  → Масштабирование
```

---

## 📈 Минимальная воронка продаж

```
100 посетителей
    ↓ (50% пробуют)
50 отправили документ
    ↓ (80% получили результат)
40 получили анализ
    ↓ (10% купили)
4 платящих клиента

Доход: 4 × 3000₸ = 12,000₸
Расходы: ~10,000₸
Прибыль: 2,000₸

При 1000 посетителей:
40 покупок × 3000₸ = 120,000₸/месяц
```

---

## 🎯 Альтернативный ULTRA-быстрый старт (10 минут)

**Если нужно протестировать ПРЯМО СЕЙЧАС без всякой базы:**

### Single-node решение:

```javascript
// Один Code node в n8n:

const { Configuration, OpenAIApi } = require('openai');

const configuration = new Configuration({
  apiKey: 'sk-YOUR-OPENAI-KEY'
});
const openai = new OpenAIApi(configuration);

// Получаем текст документа
const documentText = $json.documentText;

// Минималистичный промпт
const prompt = `Ты юрист. Проанализируй договор.
Найди 3 главных риска. Оцени общий риск 1-5.

ДОГОВОР:
${documentText}

JSON ответ:
{"risk": 1-5, "issues": ["...", "...", "..."]}`;

const completion = await openai.createChatCompletion({
  model: "gpt-4o-mini",
  messages: [{ role: "user", content: prompt }],
  temperature: 0.3
});

const result = JSON.parse(completion.data.choices[0].message.content);

const response = `⚖️ Риск: ${result.risk}/5\n\n` +
  `Проблемы:\n` +
  result.issues.map((issue, i) => `${i+1}. ${issue}`).join('\n');

return [{ json: { message: response } }];

// Готово! Работает за 10 секунд без всяких баз!
```

---

## 🎨 Минималистичный UI для старта

```
Пользователь отправляет: 📄 contract.pdf

Бот отвечает:
┌─────────────────────────┐
│ ⏳ Анализирую...        │
│ Это займет ~1 минуту    │
└─────────────────────────┘

        ↓ (через 60 сек)

┌─────────────────────────┐
│ ⚖️ РЕЗУЛЬТАТ            │
│                         │
│ Риск: 🚨 4/5           │
│                         │
│ Топ-3 проблемы:        │
│ 1. Штрафы слишком       │
│    высокие (365%/год)   │
│                         │
│ 2. Короткий срок для    │
│    выселения (7 дней)   │
│                         │
│ 3. Нет процедуры        │
│    возврата залога      │
│                         │
│ Вердикт: Требуются      │
│ обязательные правки     │
│                         │
│ ⚠️ Не юр.консультация   │
└─────────────────────────┘
```

**Просто. Понятно. Работает.**

---

## 🔧 Минимальная интеграция с вашим flow

**В ваш существующий workflow добавьте ТОЛЬКО:**

### После узла "Отправить в Google Script":

```javascript
// Code node: Quick Legal Check
const text = $json; // результат OCR
const hasLegalKeywords = /договор|contract|аренда|услуг|нда/i.test(text);

if (hasLegalKeywords && text.length > 200) {
  // Отправляем в OpenAI для быстрого анализа
  return [{ 
    json: { 
      shouldAnalyze: true, 
      text: text,
      chatId: $('set chatId').item.json.chatId
    } 
  }];
} else {
  // Обычная обработка
  return [{ json: { shouldAnalyze: false } }];
}
```

### IF условие + OpenAI анализ:

```
IF shouldAnalyze === true
  → OpenAI (простой промпт)
    → Format response
      → Send to user
      
IF shouldAnalyze === false  
  → Continue with your existing flow
```

**3 новых узла. 5 минут работы. Готово!**

---

## ✅ MVP Success Criteria

```
Считайте MVP успешным если:

✅ 10 человек попробовали
✅ 5+ отправили документы
✅ 3+ получили корректные анализы
✅ 1+ купил платный пакет
✅ 0 критических багов

→ Можно масштабировать!
```

---

## 🎉 Запуск за 5 минут (экстремальный вариант)

**Совсем нет времени? Сделайте ТАК:**

1. **Один узел в n8n:**

```javascript
// Webhook → Code node:

const openai = require('openai');
const api = new openai({ apiKey: 'sk-YOUR-KEY' });

const analysis = await api.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [{
    role: 'user',
    content: `Юрист, анализируй договор. Риски 1-5:\n${$json.text}`
  }]
});

return [{ 
  json: { 
    response: analysis.choices[0].message.content 
  } 
}];

// → Отправка ответа пользователю
```

2. **Запустите**

3. **Profit!** (самая базовая версия работает)

---

## 🚦 Decision Tree: Какой путь выбрать?

```
Сколько у вас времени?

├─ 5 минут
│  └─> Ultra-Quick (один узел OpenAI)
│
├─ 30 минут  
│  └─> Quick Start (этот гайд)
│      ├─ Базовый анализ
│      ├─ Простые лимиты
│      └─ Без векторной базы
│
├─ 3 часа
│  └─> Full Setup (SETUP_GUIDE.md)
│      ├─ Векторная база
│      ├─ Firecrawl парсинг
│      ├─ Продвинутые промпты
│      └─ Система оплаты
│
└─ 1 неделя
   └─> Production Ready
       ├─ Все функции
       ├─ Тестирование
       ├─ Оптимизация
       └─ Маркетинг
```

---

## 💪 Мотивация

```
"Лучше запустить простую версию СЕГОДНЯ,
чем идеальную НИКОГДА"

Начните с MVP за 30 минут.
Получите первых пользователей.
Улучшайте на основе feedback.

Iterate. Iterate. Iterate.

🚀 Удачи!
```

---

## 📞 Нужна помощь?

**Застряли на каком-то шаге?**

1. Проверьте логи n8n
2. Посмотрите примеры в других файлах
3. Погуглите ошибку
4. Спросите в community

**Все получится! 💪**

---

<div align="center">

### 🎯 Готовы? Погнали!

[📖 Полная документация](./SETUP_GUIDE.md) • [🐛 Troubleshooting](./FAQ_AND_OPTIMIZATION.md)

</div>

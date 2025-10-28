# 🧪 Тестовые данные и скрипты для AI-Юриста

## 📄 Тестовые документы

### 1. Договор аренды с рисками (для тестирования)

```
ДОГОВОР АРЕНДЫ ЖИЛОГО ПОМЕЩЕНИЯ
№ А-2025-001 от 15 января 2025 г.

г. Костанай

1. СТОРОНЫ ДОГОВОРА

1.1. Арендодатель: ИП "Иванов Иван Иванович", ИИН 123456789012,
адрес: г.Костанай, ул.Ленина, 1

1.2. Арендатор: Петров Петр Петрович, ИИН 210987654321,
адрес: г.Костанай, ул.Мира, 10

2. ПРЕДМЕТ ДОГОВОРА

2.1. Арендодатель обязуется предоставить Арендатору за плату во временное
владение и пользование жилое помещение - квартиру, расположенную по адресу:
г. Костанай, ул. Тестовая, дом 5, квартира 25, общей площадью 45 кв.м.

3. СРОК АРЕНДЫ

3.1. Квартира передается в аренду на срок 12 (двенадцать) месяцев
с 01 февраля 2025 г. по 31 января 2026 г.

3.2. При отсутствии заявления одной из сторон о прекращении или изменении
договора в течение одного месяца по окончании срока его действия, договор
считается продленным на тех же условиях на неопределенный срок.

4. РАЗМЕР И ПОРЯДОК ВНЕСЕНИЯ АРЕНДНОЙ ПЛАТЫ

4.1. Размер арендной платы составляет 150 000 (сто пятьдесят тысяч) тенге
в месяц.

4.2. Арендная плата вносится ежемесячно не позднее 5 числа текущего месяца
путем перечисления на карту Арендодателя или наличными.

4.3. Арендодатель вправе в одностороннем порядке изменять размер арендной
платы, уведомив Арендатора за 10 дней до начала месяца.

4.4. Коммунальные платежи, включая электроэнергию, воду, отопление, газ,
интернет, вывоз мусора и прочие расходы по содержанию помещения оплачиваются
Арендатором дополнительно.

5. ОБЕСПЕЧИТЕЛЬНЫЙ ПЛАТЕЖ

5.1. При заключении настоящего договора Арендатор вносит обеспечительный
платеж (залог) в размере 200 000 (двести тысяч) тенге.

5.2. Залог возвращается Арендатору в течение 30 дней после освобождения
квартиры за вычетом расходов на устранение повреждений и задолженности
по оплате.

5.3. Оценка повреждений производится Арендодателем самостоятельно.

6. ОБЯЗАННОСТИ АРЕНДАТОРА

6.1. Использовать квартиру только для проживания.
6.2. Поддерживать квартиру в надлежащем состоянии.
6.3. Производить текущий и капитальный ремонт за свой счет.
6.4. Не сдавать квартиру в субаренду.
6.5. Не вносить изменений в квартиру без письменного согласия Арендодателя.
6.6. При обнаружении неисправностей немедленно уведомлять Арендодателя.

7. ОБЯЗАННОСТИ АРЕНДОДАТЕЛЯ

7.1. Предоставить квартиру в срок.
7.2. Обеспечить условия для проживания.

8. ОТВЕТСТВЕННОСТЬ СТОРОН

8.1. За просрочку внесения арендной платы Арендатор уплачивает пеню
в размере 1% от суммы платежа за каждый день просрочки.

8.2. За иные нарушения условий договора Арендатор уплачивает штраф
в размере 50 000 тенге за каждое нарушение.

8.3. Арендодатель не несет ответственности за скрытые недостатки квартиры.

9. РАСТОРЖЕНИЕ ДОГОВОРА

9.1. Арендодатель вправе расторгнуть настоящий договор в любое время,
уведомив Арендатора за 7 (семь) календарных дней.

9.2. Арендатор может расторгнуть договор только при наличии согласия
Арендодателя.

9.3. При досрочном расторжении по инициативе Арендатора, последний
выплачивает Арендодателю компенсацию в размере трех месячных арендных плат.

10. ПРОЧИЕ УСЛОВИЯ

10.1. Все споры разрешаются в суде по месту нахождения Арендодателя.

10.2. Договор составлен в двух экземплярах, имеющих одинаковую юридическую силу.

Арендодатель: _______________
Арендатор: _______________

М.П. (при наличии)
```

#### Ожидаемый анализ этого договора:

```json
{
  "overall_risk_score": 5,
  "risk_points": [
    {
      "clause_number": "4.3",
      "issue": "Односторонее изменение цены",
      "risk_level": 5,
      "legal_reference": "Ст. 393 ГК РК - условия должны быть согласованы"
    },
    {
      "clause_number": "8.1",
      "issue": "Пеня 1% в день = 365% годовых",
      "risk_level": 5,
      "legal_reference": "Ст. 297, 299 ГК РК - несоразмерная неустойка"
    },
    {
      "clause_number": "9.1",
      "issue": "Расторжение за 7 дней без оснований",
      "risk_level": 5
    },
    {
      "clause_number": "6.3",
      "issue": "Капремонт за счет арендатора",
      "risk_level": 4,
      "legal_reference": "Ст. 575 ГК РК - капремонт обязанность арендодателя"
    }
  ]
}
```

---

## 🔬 SQL тестовые запросы

### Проверка функций

```sql
-- 1. Тест функции проверки лимитов
SELECT * FROM check_user_limit('test_user_123');

-- Ожидаемый результат:
-- can_analyze: true
-- remaining_analyses: 1 (для нового FREE пользователя)
-- tier: 'free'
-- max_pages: 3

-- 2. Тест инкремента
SELECT increment_analysis_usage('test_user_123');
SELECT * FROM check_user_limit('test_user_123');
-- remaining_analyses должно стать 0

-- 3. Тест добавления пакета
SELECT add_analyses_from_payment('test_user_123', 'pack_10');
SELECT * FROM check_user_limit('test_user_123');
-- analyses_limit должно быть 10
-- tier: 'basic'

-- 4. Тест векторного поиска
-- Сначала добавим тестовую запись
INSERT INTO legal_knowledge (content, category, source_url, title, embedding)
VALUES (
  'Статья 297 ГК РК. Неустойка должна быть соразмерной последствиям нарушения обязательства.',
  'civil_code',
  'https://test.kz',
  'Статья 297 ГК РК',
  '[0.1, 0.2, ..., 0.1]'::vector -- замените на реальный вектор
);

-- Поиск (нужен реальный вектор):
SELECT * FROM match_legal_documents(
  (SELECT embedding FROM legal_knowledge LIMIT 1), -- тестовый вектор
  0.5, -- низкий порог для теста
  5,
  NULL
);

-- 5. Тест сброса месячных лимитов
UPDATE user_limits SET last_reset_date = '2024-12-01' WHERE chat_id = 'test_user_123';
SELECT reset_monthly_limits();
SELECT * FROM user_limits WHERE chat_id = 'test_user_123';
-- analyses_used_this_month должно обнулиться
```

---

## 🎬 Скрипты для быстрого старта

### Скрипт 1: Наполнение тестовыми данными

```sql
-- Создаем 3 тестовых пользователя с разными тарифами
INSERT INTO user_limits (chat_id, subscription_tier, analyses_limit, max_pages_per_doc, analyses_used_this_month)
VALUES 
  ('free_user_test', 'free', 1, 3, 0),
  ('basic_user_test', 'basic', 10, 10, 5),
  ('premium_user_test', 'premium', 20, 15, 10);

-- Добавляем тестовые анализы
INSERT INTO analyzed_documents (
  chat_id, 
  message_id, 
  document_type, 
  file_name,
  extracted_text,
  analysis_result,
  risk_score,
  risk_points
)
VALUES 
  (
    'basic_user_test',
    'msg_001',
    'rental_agreement',
    'test_rental.pdf',
    'Договор аренды...',
    '{"overall_risk_score": 4}'::jsonb,
    4,
    '[{"issue": "High penalties", "risk_level": 5}]'::jsonb
  ),
  (
    'basic_user_test',
    'msg_002', 
    'service_agreement',
    'test_service.pdf',
    'Договор услуг...',
    '{"overall_risk_score": 2}'::jsonb,
    2,
    '[]'::jsonb
  );

-- Проверка
SELECT 
  u.chat_id,
  u.subscription_tier,
  u.analyses_used_this_month,
  COUNT(ad.id) as actual_analyses
FROM user_limits u
LEFT JOIN analyzed_documents ad ON ad.chat_id = u.chat_id
GROUP BY u.chat_id, u.subscription_tier, u.analyses_used_this_month;
```

### Скрипт 2: Очистка тестовых данных

```sql
-- Удаление тестовых пользователей и их данных
DELETE FROM analyzed_documents WHERE chat_id LIKE '%test%';
DELETE FROM user_limits WHERE chat_id LIKE '%test%';
DELETE FROM payments WHERE chat_id LIKE '%test%';

-- Сброс счетчиков
UPDATE user_limits SET analyses_used_this_month = 0;

-- Очистка старых анализов (старше 90 дней)
DELETE FROM analyzed_documents 
WHERE created_at < NOW() - INTERVAL '90 days';

-- Вакуум для оптимизации
VACUUM ANALYZE analyzed_documents;
VACUUM ANALYZE user_limits;
VACUUM ANALYZE legal_knowledge;
```

### Скрипт 3: Бэкап важных данных

```bash
#!/bin/bash
# backup_legal_db.sh

# Настройки
SUPABASE_PROJECT="your-project-ref"
SUPABASE_DB_PASSWORD="your-password"
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Создаем директорию для бэкапов
mkdir -p $BACKUP_DIR

# Бэкап юридической базы знаний
pg_dump \
  -h db.$SUPABASE_PROJECT.supabase.co \
  -U postgres \
  -d postgres \
  -t legal_knowledge \
  -t analysis_templates \
  --clean \
  --if-exists \
  -f "$BACKUP_DIR/legal_knowledge_$DATE.sql"

echo "✅ Backup saved to: $BACKUP_DIR/legal_knowledge_$DATE.sql"

# Бэкап пользовательских данных
pg_dump \
  -h db.$SUPABASE_PROJECT.supabase.co \
  -U postgres \
  -d postgres \
  -t user_limits \
  -t payments \
  -t analyzed_documents \
  --clean \
  -f "$BACKUP_DIR/user_data_$DATE.sql"

echo "✅ User data backup saved"

# Удаляем бэкапы старше 30 дней
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete

echo "🎉 Backup completed!"
```

---

## 🎯 Тестовые кейсы

### Тест-кейс 1: Новый пользователь FREE tier

```
Шаги:
1. Отправить /start
   Ожидание: Приветственное сообщение с описанием

2. Отправить /balance
   Ожидание: "Осталось анализов: 1"

3. Отправить тестовый договор (PDF)
   Ожидание: 
   - Анализ выполнен
   - Риск-скор отображается
   - Минимум 3 риска найдено
   
4. Отправить второй документ
   Ожидание: "Лимит исчерпан, /pay"
   
5. Проверить БД:
   SELECT * FROM user_limits WHERE chat_id = '{chat_id}';
   -- analyses_used_this_month должно быть 1
```

### Тест-кейс 2: Оплата пакета

```
Шаги:
1. Пользователь отправляет /pay
   Ожидание: Сообщение с ценами

2. Симулируем оплату:
   INSERT INTO payments (chat_id, amount, package_type, payment_status)
   VALUES ('test_user', 4990, 'pack_10', 'completed');
   
3. Активируем пакет:
   SELECT add_analyses_from_payment('test_user', 'pack_10');
   
4. Проверяем:
   SELECT * FROM check_user_limit('test_user');
   -- analyses_limit должно быть 10
   -- tier должен быть 'basic'
```

### Тест-кейс 3: Большой документ

```
Шаги:
1. FREE пользователь отправляет PDF на 5 страниц
   Ожидание: "Документ слишком большой, лимит 3 страницы"

2. PREMIUM пользователь отправляет тот же файл
   Ожидание: Успешный анализ
```

---

## 🔧 Утилиты для n8n

### Утилита 1: Массовое тестирование векторного поиска

```javascript
// Code node: Bulk Vector Search Test
const testQueries = [
  "штраф за просрочку платежа",
  "расторжение договора аренды",
  "обязанности арендодателя",
  "неустойка размер",
  "срок действия NDA"
];

const results = [];

for (const query of testQueries) {
  // Создаем эмбеддинг (вызов OpenAI)
  const embedding = await createEmbedding(query);
  
  // Ищем в БД
  const matches = await searchLegalDB(embedding);
  
  results.push({
    query: query,
    matchesFound: matches.length,
    topMatch: matches[0]?.title,
    topSimilarity: matches[0]?.similarity
  });
}

return results.map(r => ({ json: r }));
```

### Утилита 2: Валидатор качества чанков

```javascript
// Code node: Validate Chunks Quality
const chunks = $input.all();

const quality = chunks.map(chunk => {
  const content = chunk.json.content;
  const length = content.length;
  
  // Проверяем качество
  const hasArticleNumber = /Статья \\d+/.test(content);
  const hasStructure = content.split('\\n').length > 2;
  const notTooShort = length >= 200;
  const notTooLong = length <= 2000;
  
  const score = [
    hasArticleNumber,
    hasStructure,
    notTooShort,
    notTooLong
  ].filter(Boolean).length;
  
  return {
    chunkIndex: chunk.json.chunkIndex,
    length: length,
    hasArticleNumber,
    qualityScore: score,
    preview: content.substring(0, 100)
  };
});

// Фильтруем плохие чанки (score < 2)
const badChunks = quality.filter(q => q.qualityScore < 2);

return [{
  json: {
    totalChunks: chunks.length,
    badChunks: badChunks.length,
    avgQuality: quality.reduce((sum, q) => sum + q.qualityScore, 0) / quality.length,
    issues: badChunks
  }
}];
```

### Утилита 3: Симулятор пользовательского потока

```javascript
// Code node: Simulate User Journey
async function simulateUser(userId) {
  const steps = [];
  
  // Шаг 1: Регистрация
  steps.push({
    action: 'send_command',
    command: '/start',
    expected: 'welcome_message'
  });
  
  // Шаг 2: Проверка баланса
  steps.push({
    action: 'send_command',
    command: '/balance',
    expected: 'remaining: 1'
  });
  
  // Шаг 3: Отправка документа
  steps.push({
    action: 'send_document',
    file: 'test_rental_agreement.pdf',
    expected: 'risk_score: 4-5'
  });
  
  // Шаг 4: Исчерпание лимита
  steps.push({
    action: 'send_document',
    file: 'test_nda.pdf',
    expected: 'limit_exceeded'
  });
  
  // Шаг 5: Покупка
  steps.push({
    action: 'send_command',
    command: '/pay',
    expected: 'payment_options'
  });
  
  return steps;
}

const testUser = 'simulation_user_' + Date.now();
const journey = await simulateUser(testUser);

return journey.map(step => ({ json: step }));
```

---

## 📊 Готовые SQL запросы для аналитики

### Общая статистика

```sql
-- Дашборд владельца бота
SELECT 
  (SELECT COUNT(*) FROM user_limits) as total_users,
  (SELECT COUNT(*) FROM user_limits WHERE subscription_tier != 'free') as paying_users,
  (SELECT COUNT(*) FROM analyzed_documents) as total_analyses,
  (SELECT COUNT(*) FROM analyzed_documents WHERE created_at > NOW() - INTERVAL '24 hours') as analyses_today,
  (SELECT SUM(amount) FROM payments WHERE payment_status = 'completed') as total_revenue_kzt,
  (SELECT AVG(risk_score) FROM analyzed_documents) as avg_risk_score
;
```

### Популярность типов документов

```sql
SELECT 
  document_type,
  COUNT(*) as count,
  AVG(risk_score) as avg_risk,
  COUNT(CASE WHEN risk_score >= 4 THEN 1 END) as high_risk_count
FROM analyzed_documents
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY document_type
ORDER BY count DESC;
```

### Анализ конверсии

```sql
WITH funnel AS (
  SELECT 
    chat_id,
    MIN(created_at) as first_seen,
    COUNT(*) as analyses_count,
    MAX(CASE WHEN subscription_tier != 'free' THEN 1 ELSE 0 END) as converted
  FROM user_limits ul
  LEFT JOIN analyzed_documents ad USING (chat_id)
  GROUP BY chat_id
)
SELECT 
  COUNT(*) as total_users,
  SUM(CASE WHEN analyses_count >= 1 THEN 1 ELSE 0 END) as activated_users,
  SUM(converted) as paying_users,
  ROUND(SUM(converted)::numeric / COUNT(*) * 100, 2) as conversion_rate,
  ROUND(AVG(analyses_count), 2) as avg_analyses_per_user
FROM funnel;
```

### Когортный анализ

```sql
SELECT 
  DATE_TRUNC('week', ul.created_at) as cohort_week,
  COUNT(DISTINCT ul.chat_id) as cohort_size,
  COUNT(DISTINCT ad.chat_id) as active_users,
  ROUND(COUNT(DISTINCT ad.chat_id)::numeric / COUNT(DISTINCT ul.chat_id) * 100, 2) as activation_rate
FROM user_limits ul
LEFT JOIN analyzed_documents ad ON 
  ad.chat_id = ul.chat_id AND
  ad.created_at BETWEEN ul.created_at AND ul.created_at + INTERVAL '7 days'
GROUP BY cohort_week
ORDER BY cohort_week DESC
LIMIT 8;
```

---

## 🎨 Примеры красивого форматирования ответов

### Стиль 1: Минималистичный (для FREE)

```javascript
const msg = `⚖️ *Анализ завершен*\n\n` +
  `Риск: ${emoji} ${score}/5\n\n` +
  `🚨 Найдено ${criticalCount} критических рисков\n\n` +
  `Топ-3 проблемы:\n` +
  risks.slice(0, 3).map((r, i) => 
    `${i+1}. ${r.issue} (п.${r.clause})`
  ).join('\n') +
  `\n\n💎 Полный отчет в Premium`;
```

### Стиль 2: Подробный (для Premium)

```javascript
const msg = `╔═══════════════════════════════╗\n` +
  `║  ЮРИДИЧЕСКАЯ ЭКСПЕРТИЗА      ║\n` +
  `╚═══════════════════════════════╝\n\n` +
  
  `📋 ${docType.toUpperCase()}\n` +
  `📅 ${currentDate}\n` +
  `📊 РИСК: ${riskEmoji} ${score}/5\n\n` +
  
  `┏━━━ 🎯 EXECUTIVE SUMMARY ━━━┓\n` +
  `┃ ${summary}\n` +
  `┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n\n` +
  
  `┌─ 🚨 КРИТИЧЕСКИЕ РИСКИ ─┐\n` +
  risks.map(r => 
    `│ • ${r.issue}\n` +
    `│   └ ${r.recommendation}\n`
  ).join('') +
  `└─────────────────────────┘\n\n`;
```

### Стиль 3: Интерактивный

```javascript
{
  message: mainMessage,
  keyboard: {
    inline_keyboard: [
      [
        { text: '📊 Детали рисков', callback_data: 'details_' + analysisId },
        { text: '📝 Протокол', callback_data: 'protocol_' + analysisId }
      ],
      [
        { text: '📤 Экспорт PDF', callback_data: 'export_' + analysisId },
        { text: '🔄 Переанализировать', callback_data: 'reanalyze_' + analysisId }
      ],
      [
        { text: '💬 Задать вопрос юристу', url: 'https://t.me/your_lawyer' }
      ]
    ]
  }
}
```

---

## 🔄 Скрипты обслуживания

### Ежедневная задача (cron в n8n)

```javascript
// Schedule Trigger: Every day at 02:00

// 1. Сброс месячных лимитов
SELECT reset_monthly_limits();

// 2. Очистка старых данных
DELETE FROM analyzed_documents 
WHERE created_at < NOW() - INTERVAL '90 days';

// 3. Обновление статистики
REFRESH MATERIALIZED VIEW analytics_dashboard;

// 4. Проверка здоровья системы
const health = {
  legalKnowledgeCount: await countLegalDocs(),
  usersCount: await countUsers(),
  todayAnalyses: await countTodayAnalyses(),
  firecrawlCredits: await checkFirecrawlCredits(),
  openaiCost: await checkOpenAICost()
};

// 5. Отправка отчета админу
if (health.firecrawlCredits < 50000) {
  sendAlert('⚠️ Firecrawl credits low!');
}
```

### Еженедельная задача

```javascript
// Schedule Trigger: Every Sunday at 03:00

// 1. Обновление юридической базы
executeWorkflow('Legal Knowledge Parser');

// 2. Генерация недельного отчета
const weeklyReport = `
📊 ОТЧЕТ ЗА НЕДЕЛЮ

Пользователи:
• Всего: ${stats.totalUsers}
• Новых: ${stats.newUsers}
• Активных: ${stats.activeUsers}

Анализы:
• Выполнено: ${stats.analyses}
• Ср. риск: ${stats.avgRisk}/5
• Популярный тип: ${stats.topDocType}

Финансы:
• Доход: ${stats.revenue}₸
• Конверсия: ${stats.conversion}%

Топ-3 риска:
${stats.topRisks.join('\n')}
`;

sendToTelegram(adminChatId, weeklyReport);
```

---

## 🎓 Обучающие датасеты

### Подготовка данных для файн-тюнинга

```javascript
// Code node: Export Training Data
const analyses = await getCompletedAnalyses();

const trainingData = analyses.map(a => ({
  messages: [
    {
      role: "system",
      content: "Ты юрист-эксперт по договорному праву РК"
    },
    {
      role: "user",
      content: `Проанализируй договор:\n${a.extracted_text}`
    },
    {
      role: "assistant",
      content: JSON.stringify(a.analysis_result)
    }
  ]
}));

// Сохраняем в JSONL формат для OpenAI fine-tuning
const jsonl = trainingData
  .map(d => JSON.stringify(d))
  .join('\n');

return [{ json: { jsonl, count: trainingData.length } }];
```

---

## 🚀 Production Readiness Checklist

### Pre-launch Verification

```bash
#!/bin/bash
# pre_launch_check.sh

echo "🔍 Проверка готовности к продакшну..."

# 1. База данных
echo "Checking database..."
psql $DATABASE_URL -c "SELECT COUNT(*) FROM legal_knowledge;" || exit 1

# 2. Workflows активны
echo "Checking n8n workflows..."
curl -f http://localhost:5678/healthz || exit 1

# 3. Credentials настроены
echo "Checking credentials..."
# n8n cli command для проверки

# 4. Тестовый анализ
echo "Running test analysis..."
# Отправка тестового файла

# 5. Firecrawl credits
echo "Checking Firecrawl credits..."
curl -H "Authorization: Bearer $FIRECRAWL_KEY" \
  https://api.firecrawl.dev/v2/team/credit-usage

echo "✅ All checks passed! Ready to launch!"
```

---

## 📱 Примеры уведомлений пользователю

### После успешного анализа

```javascript
const notification = {
  chatId: chatId,
  message: `✅ Анализ завершен!\n\n` +
    `📄 ${fileName}\n` +
    `⚖️ Риск: ${riskScore}/5\n\n` +
    `🔍 Детали в сообщении выше\n` +
    `💾 Сохранено в историю\n\n` +
    `📊 Осталось анализов: ${remaining}`,
  replyToMessageId: originalMessageId
};
```

### При приближении к лимиту

```javascript
if (remaining <= 2 && remaining > 0) {
  const warningMsg = `⚠️ У вас осталось ${remaining} анализа!\n\n` +
    `Купить дополнительные: /pay`;
  
  sendMessage(chatId, warningMsg);
}
```

### После покупки пакета

```javascript
const successMsg = `🎉 Спасибо за покупку!\n\n` +
  `✅ Активирован пакет: ${packageName}\n` +
  `📊 Доступно анализов: ${analysesCount}\n` +
  `📄 Макс. страниц: ${maxPages}\n` +
  `⏰ Действует до: ${expiryDate}\n\n` +
  `Отправьте документ для анализа!`;
```

---

**Используйте эти примеры как отправную точку и адаптируйте под свои нужды! 🎯**

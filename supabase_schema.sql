-- ====================================
-- ТАБЛИЦЫ ДЛЯ AI-ЮРИСТА
-- ====================================

-- 1. Векторная база юридических знаний
CREATE TABLE IF NOT EXISTS public.legal_knowledge (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- civil_code, labor_code, contract_templates, judicial_practice
    source_url TEXT,
    title TEXT,
    chunk_index INTEGER DEFAULT 0,
    embedding vector(1536), -- для text-embedding-3-small
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_legal_knowledge_category ON public.legal_knowledge(category);
CREATE INDEX IF NOT EXISTS idx_legal_knowledge_embedding ON public.legal_knowledge USING ivfflat (embedding vector_cosine_ops);

-- Функция для поиска по векторному сходству
CREATE OR REPLACE FUNCTION match_legal_documents(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.7,
  match_count int DEFAULT 5,
  filter_category text DEFAULT NULL
)
RETURNS TABLE (
  id bigint,
  content text,
  category varchar,
  source_url text,
  title text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    legal_knowledge.id,
    legal_knowledge.content,
    legal_knowledge.category,
    legal_knowledge.source_url,
    legal_knowledge.title,
    1 - (legal_knowledge.embedding <=> query_embedding) as similarity
  FROM legal_knowledge
  WHERE 
    (filter_category IS NULL OR legal_knowledge.category = filter_category)
    AND 1 - (legal_knowledge.embedding <=> query_embedding) > match_threshold
  ORDER BY legal_knowledge.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- 2. Таблица для хранения проанализированных документов пользователей
CREATE TABLE IF NOT EXISTS public.analyzed_documents (
    id BIGSERIAL PRIMARY KEY,
    chat_id VARCHAR(255) NOT NULL,
    message_id VARCHAR(255) NOT NULL,
    document_type VARCHAR(50), -- rental, service, nda, employment, etc.
    file_name TEXT,
    file_url TEXT,
    extracted_text TEXT,
    analysis_result JSONB, -- JSON с результатами анализа
    risk_score INTEGER, -- 1-5
    risk_points JSONB, -- массив рискованных пунктов
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analyzed_docs_chat ON public.analyzed_documents(chat_id);
CREATE INDEX IF NOT EXISTS idx_analyzed_docs_date ON public.analyzed_documents(created_at DESC);

-- 3. Таблица лимитов пользователей
CREATE TABLE IF NOT EXISTS public.user_limits (
    id BIGSERIAL PRIMARY KEY,
    chat_id VARCHAR(255) UNIQUE NOT NULL,
    subscription_tier VARCHAR(50) DEFAULT 'free', -- free, basic, premium
    analyses_used_this_month INTEGER DEFAULT 0,
    analyses_limit INTEGER DEFAULT 1, -- для free tier
    max_pages_per_doc INTEGER DEFAULT 3, -- для free tier
    last_reset_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Функция автоматического сброса лимитов каждый месяц
CREATE OR REPLACE FUNCTION reset_monthly_limits()
RETURNS void AS $$
BEGIN
  UPDATE public.user_limits
  SET 
    analyses_used_this_month = 0,
    last_reset_date = CURRENT_DATE,
    updated_at = NOW()
  WHERE 
    EXTRACT(DAY FROM last_reset_date) = 1
    AND last_reset_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- 4. Таблица шаблонов анализа (для разных типов документов)
CREATE TABLE IF NOT EXISTS public.analysis_templates (
    id BIGSERIAL PRIMARY KEY,
    document_type VARCHAR(50) UNIQUE NOT NULL,
    system_prompt TEXT NOT NULL,
    risk_categories JSONB, -- категории рисков для этого типа документа
    example_output JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Вставка базовых шаблонов
INSERT INTO public.analysis_templates (document_type, system_prompt, risk_categories) VALUES
(
  'rental_agreement',
  'Ты опытный юрист, специализирующийся на договорах аренды. Проанализируй договор и найди:
  1. ШТРАФЫ и санкции (размеры, условия применения)
  2. ОДНОСТОРОННЕЕ РАСТОРЖЕНИЕ (кто имеет право, условия)
  3. РАЗМЫТЫЕ ФОРМУЛИРОВКИ (неконкретные сроки, суммы, обязательства)
  4. ОБЯЗАННОСТИ АРЕНДАТОРА (особенно нестандартные)
  5. ЗАЛОГИ И ОБЕСПЕЧЕНИЯ (размеры, условия возврата)
  
  Оцени риски для Арендатора по шкале 1-5, где:
  1 = минимальный риск
  5 = критический риск
  
  Используй контекст из Гражданского кодекса РК для оценки законности пунктов.',
  '["penalties", "termination", "vague_terms", "tenant_obligations", "deposits"]'::jsonb
),
(
  'service_agreement',
  'Ты опытный юрист, специализирующийся на договорах оказания услуг. Проанализируй договор:
  1. ОТВЕТСТВЕННОСТЬ СТОРОН (штрафы, пени, санкции)
  2. СРОКИ И ПОРЯДОК ОПЛАТЫ
  3. УСЛОВИЯ РАСТОРЖЕНИЯ
  4. ИНТЕЛЛЕКТУАЛЬНАЯ СОБСТВЕННОСТЬ (кому принадлежит результат)
  5. КОНФИДЕНЦИАЛЬНОСТЬ
  
  Оцени риски для Заказчика по шкале 1-5.',
  '["liability", "payment_terms", "termination", "ip_rights", "confidentiality"]'::jsonb
),
(
  'nda',
  'Ты опытный юрист, специализирующийся на соглашениях о неразглашении. Проанализируй NDA:
  1. ОПРЕДЕЛЕНИЕ КОНФИДЕНЦИАЛЬНОЙ ИНФОРМАЦИИ (насколько широкое)
  2. СРОК ДЕЙСТВИЯ ОБЯЗАТЕЛЬСТВ
  3. ИСКЛЮЧЕНИЯ (что можно раскрывать)
  4. ШТРАФЫ ЗА НАРУШЕНИЕ
  5. ВОЗВРАТ/УНИЧТОЖЕНИЕ ИНФОРМАЦИИ
  
  Оцени риски подписания по шкале 1-5.',
  '["scope_definition", "duration", "exceptions", "penalties", "return_obligations"]'::jsonb
)
ON CONFLICT (document_type) DO NOTHING;

-- 5. Таблица истории платежей (для монетизации)
CREATE TABLE IF NOT EXISTS public.payments (
    id BIGSERIAL PRIMARY KEY,
    chat_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'KZT',
    package_type VARCHAR(50), -- pack_5, pack_10, pack_20, premium_month
    analyses_added INTEGER,
    payment_status VARCHAR(20) DEFAULT 'pending', -- pending, completed, failed
    payment_provider VARCHAR(50),
    transaction_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_chat ON public.payments(chat_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(payment_status);

-- ====================================
-- ФУНКЦИИ-ПОМОЩНИКИ
-- ====================================

-- Проверка лимитов пользователя
CREATE OR REPLACE FUNCTION check_user_limit(p_chat_id VARCHAR)
RETURNS TABLE (
    can_analyze BOOLEAN,
    remaining_analyses INTEGER,
    tier VARCHAR,
    max_pages INTEGER
) AS $$
DECLARE
    v_user RECORD;
BEGIN
    -- Получаем или создаем запись пользователя
    INSERT INTO public.user_limits (chat_id)
    VALUES (p_chat_id)
    ON CONFLICT (chat_id) DO NOTHING;
    
    SELECT * INTO v_user
    FROM public.user_limits
    WHERE chat_id = p_chat_id;
    
    -- Проверяем, нужен ли сброс месячных лимитов
    IF EXTRACT(MONTH FROM v_user.last_reset_date) < EXTRACT(MONTH FROM CURRENT_DATE) THEN
        UPDATE public.user_limits
        SET 
            analyses_used_this_month = 0,
            last_reset_date = CURRENT_DATE
        WHERE chat_id = p_chat_id;
        
        v_user.analyses_used_this_month := 0;
    END IF;
    
    RETURN QUERY SELECT
        (v_user.analyses_used_this_month < v_user.analyses_limit) AS can_analyze,
        (v_user.analyses_limit - v_user.analyses_used_this_month) AS remaining_analyses,
        v_user.subscription_tier AS tier,
        v_user.max_pages_per_doc AS max_pages;
END;
$$ LANGUAGE plpgsql;

-- Увеличить счетчик использованных анализов
CREATE OR REPLACE FUNCTION increment_analysis_usage(p_chat_id VARCHAR)
RETURNS void AS $$
BEGIN
    UPDATE public.user_limits
    SET 
        analyses_used_this_month = analyses_used_this_month + 1,
        updated_at = NOW()
    WHERE chat_id = p_chat_id;
END;
$$ LANGUAGE plpgsql;

-- Добавить анализы после оплаты
CREATE OR REPLACE FUNCTION add_analyses_from_payment(
    p_chat_id VARCHAR,
    p_package_type VARCHAR
)
RETURNS void AS $$
DECLARE
    v_analyses_to_add INTEGER;
    v_new_tier VARCHAR;
    v_new_max_pages INTEGER;
BEGIN
    -- Определяем количество анализов в зависимости от пакета
    CASE p_package_type
        WHEN 'pack_5' THEN 
            v_analyses_to_add := 5;
            v_new_tier := 'basic';
            v_new_max_pages := 10;
        WHEN 'pack_10' THEN 
            v_analyses_to_add := 10;
            v_new_tier := 'basic';
            v_new_max_pages := 10;
        WHEN 'pack_20' THEN 
            v_analyses_to_add := 20;
            v_new_tier := 'premium';
            v_new_max_pages := 15;
        WHEN 'premium_month' THEN 
            v_analyses_to_add := 100;
            v_new_tier := 'premium';
            v_new_max_pages := 15;
        ELSE 
            v_analyses_to_add := 0;
    END CASE;
    
    UPDATE public.user_limits
    SET 
        analyses_limit = analyses_limit + v_analyses_to_add,
        subscription_tier = v_new_tier,
        max_pages_per_doc = v_new_max_pages,
        updated_at = NOW()
    WHERE chat_id = p_chat_id;
END;
$$ LANGUAGE plpgsql;

-- ====================================
-- КОММЕНТАРИИ И ДОКУМЕНТАЦИЯ
-- ====================================

COMMENT ON TABLE public.legal_knowledge IS 'Векторная база знаний: законы, кейсы, шаблоны договоров';
COMMENT ON TABLE public.analyzed_documents IS 'История проанализированных документов пользователей';
COMMENT ON TABLE public.user_limits IS 'Лимиты и подписки пользователей';
COMMENT ON TABLE public.analysis_templates IS 'Шаблоны системных промптов для разных типов документов';
COMMENT ON TABLE public.payments IS 'История платежей и транзакций';

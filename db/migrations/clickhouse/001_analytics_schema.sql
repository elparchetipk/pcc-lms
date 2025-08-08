-- ClickHouse Schema for Analytics and BI
-- Version: 2025-08-08
-- Description: Analytics database for real-time metrics and BI

-- =============================================================================
-- USER EVENTS TRACKING
-- =============================================================================

CREATE TABLE user_events (
    event_id UUID DEFAULT generateUUIDv4(),
    user_id UUID,
    session_id UUID,
    event_type LowCardinality(String), -- 'page_view', 'video_play', 'quiz_start', etc.
    event_category LowCardinality(String), -- 'learning', 'payment', 'navigation'
    entity_type LowCardinality(String), -- 'course', 'lesson', 'assignment'
    entity_id UUID,
    event_data String, -- JSON string
    ip_address IPv4,
    user_agent String,
    referrer String,
    utm_source LowCardinality(String),
    utm_medium LowCardinality(String),
    utm_campaign LowCardinality(String),
    device_type LowCardinality(String), -- 'desktop', 'mobile', 'tablet'
    browser LowCardinality(String),
    os LowCardinality(String),
    country LowCardinality(String),
    city String,
    timestamp DateTime64(3) DEFAULT now64()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id, event_type)
TTL timestamp + INTERVAL 2 YEAR;

-- =============================================================================
-- LEARNING ANALYTICS
-- =============================================================================

CREATE TABLE learning_events (
    event_id UUID DEFAULT generateUUIDv4(),
    user_id UUID,
    course_id UUID,
    lesson_id UUID,
    assignment_id UUID,
    event_type LowCardinality(String), -- 'lesson_start', 'lesson_complete', 'quiz_attempt'
    progress_percent UInt8,
    time_spent_seconds UInt32,
    score Float32,
    max_score Float32,
    attempt_number UInt8,
    completion_status LowCardinality(String), -- 'completed', 'in_progress', 'failed'
    engagement_metrics String, -- JSON: clicks, pauses, speed changes, etc.
    timestamp DateTime64(3) DEFAULT now64()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id, course_id)
TTL timestamp + INTERVAL 3 YEAR;

-- =============================================================================
-- REVENUE AND PAYMENT ANALYTICS
-- =============================================================================

CREATE TABLE payment_events (
    event_id UUID DEFAULT generateUUIDv4(),
    user_id UUID,
    order_id UUID,
    course_id UUID,
    event_type LowCardinality(String), -- 'order_created', 'payment_completed', 'refunded'
    amount_cents UInt32,
    currency LowCardinality(String),
    payment_method LowCardinality(String),
    payment_provider LowCardinality(String),
    coupon_code String,
    discount_amount_cents UInt32,
    user_country LowCardinality(String),
    acquisition_source LowCardinality(String),
    timestamp DateTime64(3) DEFAULT now64()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id, currency)
TTL timestamp + INTERVAL 7 YEAR; -- Keep financial data longer

-- =============================================================================
-- REAL-TIME METRICS AGGREGATIONS
-- =============================================================================

-- Hourly user activity aggregation
CREATE MATERIALIZED VIEW hourly_user_activity
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, event_type)
AS SELECT
    toStartOfHour(timestamp) as hour,
    event_type,
    count() as event_count,
    uniq(user_id) as unique_users,
    uniq(session_id) as unique_sessions
FROM user_events
GROUP BY hour, event_type;

-- Daily course metrics
CREATE MATERIALIZED VIEW daily_course_metrics
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, course_id)
AS SELECT
    toDate(timestamp) as date,
    entity_id as course_id,
    count() as total_events,
    uniq(user_id) as unique_users,
    countIf(event_type = 'course_enroll') as enrollments,
    countIf(event_type = 'lesson_complete') as lessons_completed,
    countIf(event_type = 'course_complete') as course_completions
FROM user_events
WHERE entity_type = 'course'
GROUP BY date, course_id;

-- Real-time revenue tracking
CREATE MATERIALIZED VIEW daily_revenue
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, currency)
AS SELECT
    toDate(timestamp) as date,
    currency,
    sumIf(amount_cents, event_type = 'payment_completed') as total_revenue_cents,
    sumIf(amount_cents, event_type = 'refunded') as refunded_amount_cents,
    countIf(event_type = 'payment_completed') as successful_payments,
    countIf(event_type = 'refunded') as refunds_count,
    uniq(user_id) as paying_users
FROM payment_events
GROUP BY date, currency;

-- =============================================================================
-- AI ANALYTICS
-- =============================================================================

CREATE TABLE ai_interaction_events (
    event_id UUID DEFAULT generateUUIDv4(),
    user_id UUID,
    conversation_id UUID,
    event_type LowCardinality(String), -- 'chat_message', 'recommendation_shown', 'recommendation_clicked'
    message_type LowCardinality(String), -- 'question', 'answer', 'system'
    content_length UInt16,
    response_time_ms UInt16,
    tokens_used UInt16,
    model_used LowCardinality(String),
    confidence_score Float32,
    user_satisfaction UInt8, -- 1-5 rating if provided
    timestamp DateTime64(3) DEFAULT now64()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id)
TTL timestamp + INTERVAL 1 YEAR;

-- =============================================================================
-- SEARCH ANALYTICS
-- =============================================================================

CREATE TABLE search_events (
    event_id UUID DEFAULT generateUUIDv4(),
    user_id UUID,
    session_id UUID,
    query_text String,
    search_type LowCardinality(String), -- 'course', 'general', 'ai_assisted'
    results_count UInt16,
    clicked_position UInt8,
    clicked_result_id UUID,
    no_results_found UInt8, -- Boolean: 1 if no results
    response_time_ms UInt16,
    timestamp DateTime64(3) DEFAULT now64()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id)
TTL timestamp + INTERVAL 1 YEAR;

-- =============================================================================
-- PERFORMANCE MONITORING
-- =============================================================================

CREATE TABLE api_performance (
    request_id String,
    service_name LowCardinality(String), -- 'auth-service', 'courses-service', etc.
    endpoint String,
    method LowCardinality(String), -- 'GET', 'POST', etc.
    status_code UInt16,
    response_time_ms UInt16,
    request_size_bytes UInt32,
    response_size_bytes UInt32,
    user_id UUID,
    ip_address IPv4,
    user_agent String,
    timestamp DateTime64(3) DEFAULT now64()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, service_name, endpoint)
TTL timestamp + INTERVAL 3 MONTH;

-- Performance aggregation view
CREATE MATERIALIZED VIEW api_performance_hourly
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, service_name, endpoint)
AS SELECT
    toStartOfHour(timestamp) as hour,
    service_name,
    endpoint,
    count() as request_count,
    avg(response_time_ms) as avg_response_time,
    quantile(0.95)(response_time_ms) as p95_response_time,
    quantile(0.99)(response_time_ms) as p99_response_time,
    countIf(status_code >= 500) as error_5xx_count,
    countIf(status_code >= 400 AND status_code < 500) as error_4xx_count
FROM api_performance
GROUP BY hour, service_name, endpoint;

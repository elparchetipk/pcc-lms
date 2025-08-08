# PCC LMS — Arquitectura de Base de Datos Compartida

**Versión:** 2025-08-08  
**Estado:** Definitivo para implementación  
**Estrategia:** Database-per-Domain con datos compartidos

---

## Filosofía de Datos

**Principio base:** Base de datos compartida con acceso controlado por dominio

- **PostgreSQL Principal:** Datos transaccionales y relacionales
- **MongoDB:** Contenido no estructurado y logs de eventos
- **Redis:** Cache, sesiones y rate limiting
- **ClickHouse:** Analytics y Business Intelligence
- **pgvector:** Embeddings para IA (extensión PostgreSQL)

**Ventajas de DB compartida:**

- Consistencia transaccional cross-domain
- Simplifica joins complejos (enrollments + courses + users)
- Reduce latencia entre servicios
- Facilita analytics y reporting
- Backup/restore unificado

---

## PostgreSQL - Esquema Principal

### Core Tables (Transaccional)

```sql
-- ========================================
-- AUTHENTICATION & USERS DOMAIN
-- ========================================

-- Tabla central de usuarios (auth-service, users-service)
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    hashed_password TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'instructor', 'admin')),
    avatar_url TEXT,
    bio TEXT,
    timezone TEXT DEFAULT 'UTC',
    language_preference TEXT DEFAULT 'en',
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    email_verification_token TEXT,
    password_reset_token TEXT,
    password_reset_expires TIMESTAMP,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP -- soft delete
);

-- Índices para performance
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at);

-- Refresh tokens para JWT (auth-service)
CREATE TABLE refresh_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL,
    device_fingerprint TEXT,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- User preferences (users-service)
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    marketing_emails BOOLEAN NOT NULL DEFAULT TRUE,
    push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    course_reminders BOOLEAN NOT NULL DEFAULT TRUE,
    weekly_progress_email BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ========================================
-- COURSES DOMAIN
-- ========================================

-- Categories for courses (courses-service)
CREATE TABLE course_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    parent_category_id UUID REFERENCES course_categories(category_id),
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Main courses table (courses-service)
CREATE TABLE courses (
    course_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES users(user_id),
    category_id UUID REFERENCES course_categories(category_id),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    short_description TEXT NOT NULL,
    full_description TEXT,
    thumbnail_url TEXT,
    trailer_video_url TEXT,
    price_cents INTEGER NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'USD',
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    estimated_duration_hours INTEGER NOT NULL DEFAULT 1,
    language TEXT NOT NULL DEFAULT 'en',
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMP,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_ratings INTEGER DEFAULT 0,
    total_enrollments INTEGER DEFAULT 0,
    requirements JSONB DEFAULT '[]'::jsonb, -- prerrequisitos
    learning_objectives JSONB DEFAULT '[]'::jsonb, -- qué aprenderá
    target_audience JSONB DEFAULT '[]'::jsonb, -- para quién
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP
);

-- Índices para performance y búsqueda
CREATE INDEX idx_courses_instructor_id ON courses(instructor_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_category_id ON courses(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_published ON courses(is_published, published_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_price ON courses(price_cents) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_rating ON courses(average_rating) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_text_search ON courses USING gin((title || ' ' || short_description));

-- Course sections/modules (courses-service)
CREATE TABLE course_sections (
    section_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Individual lessons (courses-service)
CREATE TABLE lessons (
    lesson_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID NOT NULL REFERENCES course_sections(section_id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('video', 'article', 'quiz', 'assignment', 'live_session')),
    content_ref TEXT, -- S3 key, video ID, article slug, etc.
    duration_seconds INTEGER DEFAULT 0,
    is_preview BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lessons_section_id ON lessons(section_id);
CREATE INDEX idx_lessons_course_id ON lessons(course_id);

-- ========================================
-- ENROLLMENTS DOMAIN
-- ========================================

-- Student enrollments (enrollments-service)
CREATE TABLE enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    course_id UUID NOT NULL REFERENCES courses(course_id),
    status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'paused', 'refunded', 'expired')),
    progress_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    last_accessed_at TIMESTAMP,
    certificate_issued_at TIMESTAMP,
    enrollment_source TEXT DEFAULT 'purchase', -- purchase, gift, admin
    expires_at TIMESTAMP, -- for time-limited access
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

CREATE INDEX idx_enrollments_user_id ON enrollments(user_id);
CREATE INDEX idx_enrollments_course_id ON enrollments(course_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);

-- Lesson progress tracking (enrollments-service)
CREATE TABLE lesson_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    status TEXT NOT NULL CHECK (status IN ('not_started', 'in_progress', 'completed')),
    completion_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    last_position_seconds INTEGER DEFAULT 0, -- for video resume
    completed_at TIMESTAMP,
    first_accessed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_accessed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(enrollment_id, lesson_id)
);

CREATE INDEX idx_lesson_progress_enrollment_id ON lesson_progress(enrollment_id);
CREATE INDEX idx_lesson_progress_user_id ON lesson_progress(user_id);

-- ========================================
-- ASSIGNMENTS & GRADES DOMAIN
-- ========================================

-- Quizzes and assessments (assignments-service)
CREATE TABLE quizzes (
    quiz_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    total_points INTEGER NOT NULL DEFAULT 100,
    passing_score_percentage DECIMAL(5,2) NOT NULL DEFAULT 70.00,
    time_limit_minutes INTEGER, -- NULL = no time limit
    max_attempts INTEGER DEFAULT 1, -- unlimited = -1
    shuffle_questions BOOLEAN NOT NULL DEFAULT FALSE,
    show_correct_answers BOOLEAN NOT NULL DEFAULT TRUE,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Quiz questions (assignments-service)
CREATE TABLE quiz_questions (
    question_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID NOT NULL REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('single_choice', 'multiple_choice', 'true_false', 'short_answer', 'essay', 'code')),
    points INTEGER NOT NULL DEFAULT 5,
    sort_order INTEGER NOT NULL,
    explanation TEXT, -- shown after submission
    options JSONB DEFAULT '[]'::jsonb, -- for choice questions
    correct_answers JSONB DEFAULT '[]'::jsonb,
    code_language TEXT, -- for code questions
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Student quiz submissions (grades-service)
CREATE TABLE quiz_submissions (
    submission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID NOT NULL REFERENCES quizzes(quiz_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    enrollment_id UUID NOT NULL REFERENCES enrollments(enrollment_id),
    attempt_number INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL CHECK (status IN ('in_progress', 'submitted', 'graded')),
    score DECIMAL(5,2) DEFAULT 0.00,
    max_score DECIMAL(5,2) NOT NULL,
    passed BOOLEAN,
    time_spent_seconds INTEGER DEFAULT 0,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    submitted_at TIMESTAMP,
    graded_at TIMESTAMP,
    instructor_feedback TEXT
);

-- Individual question responses (grades-service)
CREATE TABLE quiz_responses (
    response_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES quiz_submissions(submission_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES quiz_questions(question_id),
    answer_data JSONB NOT NULL, -- student's answer(s)
    is_correct BOOLEAN,
    points_earned DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    instructor_feedback TEXT,
    auto_graded BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ========================================
-- PAYMENTS DOMAIN
-- ========================================

-- Purchase orders (payments-service)
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    course_id UUID NOT NULL REFERENCES courses(course_id),
    order_number TEXT UNIQUE NOT NULL, -- human-readable: ORD-2025-001234
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'paid', 'failed', 'cancelled', 'refunded')),
    subtotal_cents INTEGER NOT NULL,
    tax_cents INTEGER NOT NULL DEFAULT 0,
    discount_cents INTEGER NOT NULL DEFAULT 0,
    total_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    payment_provider TEXT, -- stripe, mercadopago, paypal
    payment_intent_id TEXT, -- provider transaction ID
    discount_code TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Payment transactions (payments-service)
CREATE TABLE payment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(order_id),
    provider TEXT NOT NULL,
    provider_transaction_id TEXT NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('payment', 'refund', 'chargeback')),
    amount_cents INTEGER NOT NULL,
    currency TEXT NOT NULL,
    status TEXT NOT NULL,
    provider_fee_cents INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'::jsonb,
    processed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Discount codes (payments-service)
CREATE TABLE discount_codes (
    code_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount')),
    discount_value DECIMAL(10,2) NOT NULL,
    minimum_order_cents INTEGER DEFAULT 0,
    max_uses INTEGER, -- NULL = unlimited
    current_uses INTEGER NOT NULL DEFAULT 0,
    valid_from TIMESTAMP NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ========================================
-- COURSE RATINGS & REVIEWS
-- ========================================

-- Student course reviews (courses-service)
CREATE TABLE course_reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(course_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    enrollment_id UUID NOT NULL REFERENCES enrollments(enrollment_id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_title TEXT,
    review_text TEXT,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified_purchase BOOLEAN NOT NULL DEFAULT TRUE,
    helpful_votes INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(course_id, user_id)
);

CREATE INDEX idx_course_reviews_course_id ON course_reviews(course_id);
CREATE INDEX idx_course_reviews_rating ON course_reviews(rating);

-- ========================================
-- AI & VECTORS (pgvector extension)
-- ========================================

-- Embeddings for semantic search (ai-service)
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE content_embeddings (
    embedding_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type TEXT NOT NULL CHECK (content_type IN ('course', 'lesson', 'quiz', 'user_query')),
    content_id UUID NOT NULL, -- references course_id, lesson_id, etc.
    text_content TEXT NOT NULL,
    embedding vector(1536), -- OpenAI ada-002 dimension
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_content_embeddings_type ON content_embeddings(content_type);
CREATE INDEX idx_content_embeddings_vector ON content_embeddings USING ivfflat (embedding vector_cosine_ops);

-- AI chat conversations (ai-service)
CREATE TABLE ai_conversations (
    conversation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    course_id UUID REFERENCES courses(course_id),
    title TEXT,
    status TEXT NOT NULL CHECK (status IN ('active', 'archived')) DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Individual chat messages (ai-service)
CREATE TABLE ai_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(conversation_id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb, -- citations, sources, etc.
    tokens_used INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ========================================
-- NOTIFICATIONS SYSTEM
-- ========================================

-- Notification templates (notifications-service)
CREATE TABLE notification_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('email', 'push', 'in_app')),
    subject_template TEXT,
    body_template TEXT NOT NULL,
    variables JSONB DEFAULT '[]'::jsonb, -- required template variables
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- User notification queue (notifications-service)
CREATE TABLE user_notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    template_id UUID NOT NULL REFERENCES notification_templates(template_id),
    type TEXT NOT NULL,
    subject TEXT,
    content TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'sent', 'failed', 'read')) DEFAULT 'pending',
    priority INTEGER NOT NULL DEFAULT 1, -- 1=low, 5=urgent
    scheduled_for TIMESTAMP NOT NULL DEFAULT NOW(),
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX idx_user_notifications_status ON user_notifications(status);
CREATE INDEX idx_user_notifications_scheduled ON user_notifications(scheduled_for);
```

---

## MongoDB - Documentos No Estructurados

### Colecciones Principales

```javascript
// content_assets - Metadatos de archivos multimedia (content-service)
{
  _id: ObjectId,
  assetId: "asset-uuid",
  type: "video|audio|image|document|scorm",
  filename: "lecture-01-intro.mp4",
  originalName: "Introduction to React.mp4",
  mimeType: "video/mp4",
  size: 157892345,
  duration: 3600, // seconds for video/audio
  resolution: "1920x1080",
  s3Key: "courses/course-123/videos/lecture-01-intro.mp4",
  thumbnailUrl: "https://cdn.example.com/thumbs/...",
  transcriptionUrl: "https://cdn.example.com/transcripts/...",
  metadata: {
    bitrate: 2000,
    codec: "h264",
    language: "en"
  },
  courseId: "course-uuid",
  lessonId: "lesson-uuid",
  uploadedBy: "user-uuid",
  processingStatus: "completed|processing|failed",
  createdAt: ISODate,
  updatedAt: ISODate
}

// event_logs - Auditoría y analytics en tiempo real (analytics-service)
{
  _id: ObjectId,
  eventType: "user_login|course_view|lesson_complete|purchase|quiz_submit",
  userId: "user-uuid",
  sessionId: "session-uuid",
  entityType: "course|lesson|quiz|user",
  entityId: "entity-uuid",
  properties: {
    courseId: "course-uuid",
    progress: 0.75,
    score: 85,
    timeSpent: 1200,
    userAgent: "...",
    ipAddress: "192.168.1.1",
    referrer: "https://google.com"
  },
  timestamp: ISODate,
  correlationId: "req-uuid"
}

// search_index - Índice de búsqueda full-text (search-service)
{
  _id: ObjectId,
  documentId: "course-uuid|lesson-uuid",
  documentType: "course|lesson|instructor",
  title: "Complete React Course",
  content: "Learn React from scratch with hooks, context, and modern patterns...",
  tags: ["react", "javascript", "frontend", "web-development"],
  category: "Programming",
  language: "en",
  searchVector: [...], // pre-computed search weights
  popularity: 0.85,
  createdAt: ISODate,
  updatedAt: ISODate
}
```

---

## Redis - Cache y Sesiones

### Estructura de Keys

```redis
# User sessions y rate limiting
session:user:<user-id>                 # TTL: 7 days
rate_limit:api:<user-id>                # TTL: 1 hour
rate_limit:login:<ip>                   # TTL: 15 minutes

# Cache de contenido frecuente
cache:course:<course-id>                # TTL: 1 hour
cache:user:<user-id>                    # TTL: 30 minutes
cache:catalog:page:<page-number>        # TTL: 10 minutes
cache:enrollments:<user-id>             # TTL: 5 minutes

# Leaderboards y analytics en tiempo real
leaderboard:course:<course-id>          # ZSET with scores
stats:daily:enrollments:<date>          # Hash with counters
stats:live:concurrent_users             # Simple counter

# AI y recomendaciones
recommendations:<user-id>               # TTL: 1 day
chat:conversation:<conversation-id>     # TTL: 30 days
search:recent:<user-id>                 # LIST with recent searches
```

---

## ClickHouse - Analytics y BI

### Tablas de Analytics

```sql
-- Events aggregados para reportes rápidos (business-intelligence-service)
CREATE TABLE events_summary (
    event_date Date,
    event_type LowCardinality(String),
    user_id String,
    course_id String,
    count UInt32,
    revenue_cents UInt64,
    processing_time_ms UInt32
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, event_type, user_id, course_id);

-- Cohort analysis para BI
CREATE TABLE user_cohorts (
    cohort_month Date,
    user_id String,
    registration_date Date,
    first_purchase_date Nullable(Date),
    total_courses_purchased UInt16,
    total_revenue_cents UInt64,
    is_active UInt8
) ENGINE = ReplacingMergeTree()
ORDER BY (cohort_month, user_id);

-- Course performance metrics
CREATE TABLE course_metrics (
    date Date,
    course_id String,
    instructor_id String,
    total_enrollments UInt32,
    completion_rate Float32,
    average_rating Float32,
    total_revenue_cents UInt64,
    refund_rate Float32
) ENGINE = ReplacingMergeTree()
ORDER BY (date, course_id);
```

---

## Estrategia de Acceso por Microservicio

### Permisos y Ownership

| Servicio                          | PostgreSQL Tables                                                                                  | MongoDB Collections  | Redis Patterns                  | ClickHouse Tables    |
| --------------------------------- | -------------------------------------------------------------------------------------------------- | -------------------- | ------------------------------- | -------------------- |
| **auth-service**                  | users (R/W), refresh_tokens (R/W)                                                                  | -                    | session:_, rate_limit:login:_   | -                    |
| **users-service**                 | users (R/W), user_preferences (R/W)                                                                | -                    | cache:user:\*                   | -                    |
| **courses-service**               | courses (R/W), course_sections (R/W), lessons (R/W), course_categories (R/W), course_reviews (R/W) | search_index (R/W)   | cache:course:_, cache:catalog:_ | course_metrics (R)   |
| **enrollments-service**           | enrollments (R/W), lesson_progress (R/W)                                                           | -                    | cache:enrollments:\*            | -                    |
| **assignments-service**           | quizzes (R/W), quiz_questions (R/W)                                                                | -                    | -                               | -                    |
| **grades-service**                | quiz_submissions (R/W), quiz_responses (R/W)                                                       | -                    | -                               | -                    |
| **payments-service**              | orders (R/W), payment_transactions (R/W), discount_codes (R/W)                                     | -                    | -                               | -                    |
| **notifications-service**         | notification_templates (R/W), user_notifications (R/W)                                             | -                    | -                               | -                    |
| **content-service**               | -                                                                                                  | content_assets (R/W) | -                               | -                    |
| **search-service**                | courses (R), lessons (R)                                                                           | search_index (R/W)   | search:recent:\*                | -                    |
| **analytics-service**             | ALL (R)                                                                                            | event_logs (R/W)     | stats:\*                        | events_summary (R/W) |
| **ai-service**                    | content_embeddings (R/W), ai_conversations (R/W), ai_messages (R/W)                                | -                    | recommendations:_, chat:_       | -                    |
| **business-intelligence-service** | ALL (R)                                                                                            | ALL (R)              | -                               | ALL (R/W)            |

### Connection Pool por Stack

```yaml
# Configuración de conexiones por tecnología
database:
  postgresql:
    host: 'postgres-primary'
    port: 5432
    database: 'pcc_lms'
    pool_size: 20
    max_overflow: 10

  mongodb:
    host: 'mongodb-replica'
    port: 27017
    database: 'pcc_lms_docs'

  redis:
    host: 'redis-cluster'
    port: 6379
    db: 0

  clickhouse:
    host: 'clickhouse-cluster'
    port: 9000
    database: 'pcc_lms_analytics'
```

---

## Migrations y Versionado

### Estructura de Migraciones

```
_docs/migrations/
├── postgresql/
│   ├── 001_initial_schema.sql
│   ├── 002_add_user_preferences.sql
│   ├── 003_add_ai_tables.sql
│   └── ...
├── mongodb/
│   ├── 001_create_collections.js
│   ├── 002_add_indexes.js
│   └── ...
└── clickhouse/
    ├── 001_create_analytics_tables.sql
    └── ...
```

### Scripts de Migration

```bash
# Aplicar todas las migraciones
./scripts/migrate-all.sh

# Por base de datos específica
./scripts/migrate-postgres.sh
./scripts/migrate-mongo.sh
./scripts/migrate-clickhouse.sh
```

---

## Próximos Pasos

1. **Crear migraciones iniciales** para PostgreSQL, MongoDB y ClickHouse
2. **Configurar connection pools** en cada stack tecnológico
3. **Implementar Data Access Layer** (repositories) por dominio
4. **Setup de scripts de backup/restore** automatizados
5. **Crear seed data** para desarrollo y testing

Esta arquitectura soporta todos los requisitos funcionales y permite escalabilidad independiente por stack manteniendo coherencia de datos.

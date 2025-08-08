-- PCC LMS - Complete Database Schema
-- Version: 2025-08-08
-- Description: Unified database schema for multi-stack LMS with AI and BI capabilities
-- Supports all user stories and functional requirements

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector"; -- For AI embeddings
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- =============================================================================
-- CORE AUTHENTICATION & USERS DOMAIN
-- =============================================================================

-- Users table (core authentication and profile)
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'instructor', 'admin')),
    phone VARCHAR(20),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(5) DEFAULT 'en',
    profile_image_url TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    email_verification_token VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP -- Soft delete
);

-- User sessions (JWT/Auth tracking)
CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    revoked_at TIMESTAMP
);

-- User preferences and settings
CREATE TABLE user_preferences (
    preference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    notification_email BOOLEAN DEFAULT true,
    notification_push BOOLEAN DEFAULT true,
    notification_sms BOOLEAN DEFAULT false,
    theme VARCHAR(20) DEFAULT 'light',
    dashboard_layout JSONB DEFAULT '{}',
    learning_reminders BOOLEAN DEFAULT true,
    marketing_emails BOOLEAN DEFAULT false,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id)
);

-- =============================================================================
-- COURSES DOMAIN
-- =============================================================================

-- Course categories for organization
CREATE TABLE course_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    color VARCHAR(7), -- Hex color
    parent_category_id UUID REFERENCES course_categories(category_id),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Main courses table
CREATE TABLE courses (
    course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instructor_id UUID NOT NULL REFERENCES users(user_id),
    category_id UUID REFERENCES course_categories(category_id),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    price_cents INTEGER NOT NULL DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    difficulty_level VARCHAR(20) CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    estimated_duration_hours INTEGER,
    thumbnail_url TEXT,
    trailer_video_url TEXT,
    is_published BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    is_draft BOOLEAN DEFAULT true,
    tags VARCHAR(255)[] DEFAULT '{}',
    prerequisites TEXT[] DEFAULT '{}',
    learning_objectives TEXT[] DEFAULT '{}',
    target_audience TEXT,
    language VARCHAR(5) DEFAULT 'en',
    certificate_template TEXT,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP
);

-- Course modules (sections/chapters)
CREATE TABLE course_modules (
    module_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    sort_order INTEGER NOT NULL,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Individual lessons within modules
CREATE TABLE lessons (
    lesson_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES course_modules(module_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('video', 'article', 'quiz', 'assignment', 'live_session', 'download')),
    content_data JSONB NOT NULL DEFAULT '{}', -- Flexible content storage
    duration_minutes INTEGER,
    sort_order INTEGER NOT NULL,
    is_published BOOLEAN DEFAULT false,
    is_preview BOOLEAN DEFAULT false, -- Free preview lesson
    access_requirements JSONB DEFAULT '{}', -- Prerequisites, completion requirements
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- CONTENT MANAGEMENT DOMAIN
-- =============================================================================

-- Content assets (files, videos, documents)
CREATE TABLE content_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(lesson_id) ON DELETE SET NULL,
    course_id UUID REFERENCES courses(course_id) ON DELETE SET NULL,
    file_name VARCHAR(255) NOT NULL,
    original_file_name VARCHAR(255),
    file_path VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    duration_seconds INTEGER, -- For video/audio files
    resolution VARCHAR(20), -- For video files (e.g., "1920x1080")
    storage_provider VARCHAR(50) DEFAULT 'minio', -- 'local', 's3', 'minio'
    storage_metadata JSONB DEFAULT '{}',
    upload_status VARCHAR(20) DEFAULT 'pending' CHECK (upload_status IN ('pending', 'processing', 'completed', 'failed')),
    processing_metadata JSONB DEFAULT '{}',
    access_url TEXT, -- CDN or direct access URL
    thumbnail_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- ENROLLMENTS DOMAIN
-- =============================================================================

-- Course enrollments (student-course relationship)
CREATE TABLE enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    course_id UUID NOT NULL REFERENCES courses(course_id),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'refunded', 'expired', 'suspended', 'cancelled')),
    progress_percent INTEGER DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
    completion_date TIMESTAMP,
    certificate_issued_at TIMESTAMP,
    certificate_url TEXT,
    enrolled_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    last_accessed_at TIMESTAMP,
    total_time_spent_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

-- Detailed lesson progress tracking
CREATE TABLE lesson_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'skipped')),
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    time_spent_seconds INTEGER DEFAULT 0,
    last_position_seconds INTEGER DEFAULT 0, -- For video lessons
    attempts_count INTEGER DEFAULT 0,
    first_accessed_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(enrollment_id, lesson_id)
);

-- =============================================================================
-- ASSIGNMENTS AND ASSESSMENTS DOMAIN
-- =============================================================================

-- Quiz/Assignment definitions
CREATE TABLE assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructions TEXT,
    assignment_type VARCHAR(20) NOT NULL CHECK (assignment_type IN ('quiz', 'essay', 'project', 'peer_review', 'code_exercise')),
    max_attempts INTEGER DEFAULT 1,
    time_limit_minutes INTEGER,
    passing_score_percentage INTEGER DEFAULT 70,
    randomize_questions BOOLEAN DEFAULT false,
    show_correct_answers BOOLEAN DEFAULT true,
    is_graded BOOLEAN DEFAULT true,
    weight DECIMAL(5,2) DEFAULT 1.0, -- Weight in final grade calculation
    due_date TIMESTAMP,
    available_from TIMESTAMP,
    available_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Quiz questions
CREATE TABLE quiz_questions (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id UUID NOT NULL REFERENCES assignments(assignment_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL CHECK (question_type IN ('multiple_choice', 'multiple_select', 'true_false', 'short_answer', 'essay', 'fill_blank', 'matching')),
    options JSONB DEFAULT '[]', -- For multiple choice questions
    correct_answers JSONB DEFAULT '[]',
    points INTEGER DEFAULT 1,
    explanation TEXT,
    hint TEXT,
    sort_order INTEGER NOT NULL,
    difficulty_level VARCHAR(10) CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    tags VARCHAR(255)[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Student assignment submissions
CREATE TABLE assignment_submissions (
    submission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id UUID NOT NULL REFERENCES assignments(assignment_id),
    enrollment_id UUID NOT NULL REFERENCES enrollments(enrollment_id),
    attempt_number INTEGER NOT NULL DEFAULT 1,
    answers JSONB NOT NULL DEFAULT '{}',
    submitted_at TIMESTAMP DEFAULT NOW(),
    time_spent_seconds INTEGER DEFAULT 0,
    auto_graded_score DECIMAL(5,2),
    manual_graded_score DECIMAL(5,2),
    final_score DECIMAL(5,2),
    feedback TEXT,
    instructor_notes TEXT,
    graded_by UUID REFERENCES users(user_id),
    graded_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'submitted' CHECK (status IN ('draft', 'submitted', 'graded', 'returned', 'plagiarism_check')),
    plagiarism_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- GRADES DOMAIN
-- =============================================================================

-- Final grades for courses and assignments
CREATE TABLE grades (
    grade_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES enrollments(enrollment_id),
    assignment_id UUID REFERENCES assignments(assignment_id),
    grade_type VARCHAR(20) NOT NULL CHECK (grade_type IN ('assignment', 'quiz', 'project', 'final')),
    score DECIMAL(5,2) NOT NULL,
    max_score DECIMAL(5,2) NOT NULL,
    percentage DECIMAL(5,2) GENERATED ALWAYS AS (CASE WHEN max_score > 0 THEN (score / max_score) * 100 ELSE 0 END) STORED,
    grade_letter VARCHAR(5),
    feedback TEXT,
    rubric_scores JSONB DEFAULT '{}',
    graded_by UUID NOT NULL REFERENCES users(user_id),
    graded_at TIMESTAMP DEFAULT NOW(),
    is_released BOOLEAN DEFAULT false,
    released_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Grade scale definitions
CREATE TABLE grade_scales (
    scale_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES courses(course_id),
    name VARCHAR(50) NOT NULL,
    scale_definition JSONB NOT NULL, -- {"A": {"min": 90, "max": 100}, "B": {"min": 80, "max": 89}}
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- PAYMENTS DOMAIN
-- =============================================================================

-- Payment orders
CREATE TABLE payment_orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    course_id UUID NOT NULL REFERENCES courses(course_id),
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    discount_amount_cents INTEGER DEFAULT 0,
    tax_amount_cents INTEGER DEFAULT 0,
    total_amount_cents INTEGER NOT NULL,
    payment_method VARCHAR(50), -- 'stripe', 'paypal', 'mercadopago'
    payment_provider_id VARCHAR(255), -- External payment ID
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled', 'expired')),
    coupon_code VARCHAR(50),
    customer_info JSONB DEFAULT '{}',
    billing_address JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    expires_at TIMESTAMP,
    completed_at TIMESTAMP,
    refunded_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Payment transactions
CREATE TABLE payment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES payment_orders(order_id),
    provider_transaction_id VARCHAR(255),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('charge', 'refund', 'chargeback', 'transfer')),
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(20) NOT NULL,
    provider_response JSONB DEFAULT '{}',
    fees_cents INTEGER DEFAULT 0,
    net_amount_cents INTEGER,
    processed_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Discount coupons
CREATE TABLE coupons (
    coupon_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount')),
    discount_value DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    max_uses INTEGER,
    uses_count INTEGER DEFAULT 0,
    min_order_amount_cents INTEGER DEFAULT 0,
    valid_from TIMESTAMP DEFAULT NOW(),
    valid_until TIMESTAMP,
    applicable_courses UUID[] DEFAULT '{}', -- Empty means all courses
    is_active BOOLEAN DEFAULT true,
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- NOTIFICATIONS DOMAIN
-- =============================================================================

-- Notification templates
CREATE TABLE notification_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    subject_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    template_type VARCHAR(20) NOT NULL CHECK (template_type IN ('email', 'push', 'sms', 'in_app')),
    language VARCHAR(5) DEFAULT 'en',
    variables JSONB DEFAULT '[]', -- Available template variables
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User notifications
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    template_id UUID REFERENCES notification_templates(template_id),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('email', 'push', 'sms', 'in_app')),
    priority VARCHAR(10) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed', 'cancelled')),
    recipient_info JSONB DEFAULT '{}', -- Email, phone, etc.
    delivery_attempts INTEGER DEFAULT 0,
    last_attempt_at TIMESTAMP,
    error_message TEXT,
    read_at TIMESTAMP,
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- AI DOMAIN (Promoted to first level)
-- =============================================================================

-- AI embeddings for semantic search and RAG
CREATE TABLE ai_embeddings (
    embedding_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_type VARCHAR(50) NOT NULL, -- 'course', 'lesson', 'question', 'user_query'
    content_id UUID NOT NULL,
    content_text TEXT NOT NULL,
    content_metadata JSONB DEFAULT '{}',
    embedding vector(1536), -- OpenAI/Ollama embedding dimension
    model_name VARCHAR(100) DEFAULT 'text-embedding-ada-002',
    model_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- AI chat conversations
CREATE TABLE ai_conversations (
    conversation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    course_id UUID REFERENCES courses(course_id),
    title VARCHAR(255),
    conversation_type VARCHAR(30) DEFAULT 'general' CHECK (conversation_type IN ('general', 'course_support', 'technical_help', 'career_guidance')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- AI chat messages
CREATE TABLE ai_messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(conversation_id) ON DELETE CASCADE,
    sender_type VARCHAR(10) NOT NULL CHECK (sender_type IN ('user', 'ai', 'system')),
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'code', 'image', 'file', 'system')),
    metadata JSONB DEFAULT '{}', -- For storing context, sources, model info
    tokens_used INTEGER,
    response_time_ms INTEGER,
    confidence_score DECIMAL(3,2),
    sources_used JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT NOW()
);

-- AI-powered course recommendations
CREATE TABLE ai_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    recommended_course_id UUID NOT NULL REFERENCES courses(course_id),
    recommendation_type VARCHAR(50) NOT NULL, -- 'based_on_progress', 'collaborative_filtering', 'content_based', 'ai_generated'
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    reasons JSONB DEFAULT '[]',
    algorithm_version VARCHAR(20),
    shown_at TIMESTAMP,
    clicked_at TIMESTAMP,
    enrolled_at TIMESTAMP,
    dismissed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- AI learning path suggestions
CREATE TABLE ai_learning_paths (
    path_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    recommended_courses UUID[] NOT NULL,
    estimated_duration_hours INTEGER,
    difficulty_progression JSONB DEFAULT '[]',
    personalization_factors JSONB DEFAULT '{}',
    created_by_ai BOOLEAN DEFAULT true,
    status VARCHAR(20) DEFAULT 'suggested' CHECK (status IN ('suggested', 'accepted', 'in_progress', 'completed', 'abandoned')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- BUSINESS INTELLIGENCE DOMAIN (Promoted to first level)
-- =============================================================================

-- Daily metrics aggregations
CREATE TABLE bi_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_type VARCHAR(50) NOT NULL, -- 'daily_enrollments', 'daily_revenue', 'completion_rate', 'engagement_score'
    date_recorded DATE NOT NULL,
    course_id UUID REFERENCES courses(course_id),
    instructor_id UUID REFERENCES users(user_id),
    category_id UUID REFERENCES course_categories(category_id),
    metric_value DECIMAL(15,2) NOT NULL,
    metric_count INTEGER DEFAULT 1,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(metric_type, date_recorded, course_id, instructor_id, category_id)
);

-- Student cohort analysis
CREATE TABLE student_cohorts (
    cohort_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_name VARCHAR(100) NOT NULL,
    cohort_type VARCHAR(30) NOT NULL CHECK (cohort_type IN ('enrollment_month', 'course_launch', 'user_segment', 'custom')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    filters JSONB DEFAULT '{}', -- Cohort definition criteria
    total_students INTEGER NOT NULL DEFAULT 0,
    active_students INTEGER NOT NULL DEFAULT 0,
    completed_students INTEGER DEFAULT 0,
    retention_rate_30d DECIMAL(5,2) DEFAULT 0,
    retention_rate_90d DECIMAL(5,2) DEFAULT 0,
    avg_completion_time_days DECIMAL(8,2),
    avg_engagement_score DECIMAL(5,2) DEFAULT 0,
    revenue_generated_cents BIGINT DEFAULT 0,
    ltv_estimate_cents BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Cohort membership tracking
CREATE TABLE cohort_memberships (
    membership_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_id UUID NOT NULL REFERENCES student_cohorts(cohort_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    enrollment_source VARCHAR(50),
    acquisition_cost_cents INTEGER,
    joined_at TIMESTAMP DEFAULT NOW(),
    last_active_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'churned', 'completed')),
    UNIQUE(cohort_id, user_id)
);

-- Revenue forecasting data
CREATE TABLE revenue_forecasts (
    forecast_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    forecast_date DATE NOT NULL,
    forecast_period VARCHAR(20) NOT NULL CHECK (forecast_period IN ('daily', 'weekly', 'monthly', 'quarterly')),
    course_id UUID REFERENCES courses(course_id),
    predicted_revenue_cents BIGINT NOT NULL,
    confidence_interval_lower BIGINT,
    confidence_interval_upper BIGINT,
    model_used VARCHAR(50) NOT NULL,
    model_accuracy DECIMAL(5,2),
    factors_considered JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- ANALYTICS AND TRACKING
-- =============================================================================

-- Detailed user activity tracking
CREATE TABLE user_activities (
    activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    session_id UUID REFERENCES user_sessions(session_id),
    activity_type VARCHAR(50) NOT NULL, -- 'login', 'course_view', 'lesson_start', 'lesson_complete', 'purchase'
    entity_type VARCHAR(50), -- 'course', 'lesson', 'assignment', 'user'
    entity_id UUID,
    activity_data JSONB DEFAULT '{}',
    duration_seconds INTEGER,
    ip_address INET,
    user_agent TEXT,
    referrer_url TEXT,
    utm_source VARCHAR(100),
    utm_medium VARCHAR(100),
    utm_campaign VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Learning analytics (daily aggregations)
CREATE TABLE learning_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    course_id UUID NOT NULL REFERENCES courses(course_id),
    lesson_id UUID REFERENCES lessons(lesson_id),
    date_recorded DATE NOT NULL,
    time_spent_seconds INTEGER DEFAULT 0,
    interactions_count INTEGER DEFAULT 0,
    videos_watched INTEGER DEFAULT 0,
    quizzes_attempted INTEGER DEFAULT 0,
    assignments_submitted INTEGER DEFAULT 0,
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    engagement_score DECIMAL(5,2) DEFAULT 0, -- Calculated engagement metric
    focus_score DECIMAL(5,2) DEFAULT 0, -- Time spent vs content duration
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, course_id, lesson_id, date_recorded)
);

-- =============================================================================
-- SEARCH DOMAIN
-- =============================================================================

-- Search queries and results tracking
CREATE TABLE search_queries (
    query_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    session_id UUID REFERENCES user_sessions(session_id),
    query_text TEXT NOT NULL,
    search_type VARCHAR(20) DEFAULT 'general' CHECK (search_type IN ('general', 'course', 'instructor', 'ai_assisted', 'semantic')),
    filters_applied JSONB DEFAULT '{}',
    results_count INTEGER DEFAULT 0,
    clicked_result_ids UUID[] DEFAULT '{}',
    clicked_result_positions INTEGER[] DEFAULT '{}',
    response_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Search result click tracking
CREATE TABLE search_clicks (
    click_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_id UUID NOT NULL REFERENCES search_queries(query_id),
    result_type VARCHAR(30) NOT NULL, -- 'course', 'lesson', 'instructor'
    result_id UUID NOT NULL,
    result_position INTEGER NOT NULL,
    clicked_at TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- PERFORMANCE INDEXES
-- =============================================================================

-- User indexes
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_active ON users(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created ON users(created_at);

-- Course indexes
CREATE INDEX idx_courses_instructor ON courses(instructor_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_published ON courses(is_published) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_category ON courses(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_slug ON courses(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_price ON courses(price_cents) WHERE deleted_at IS NULL;

-- Enrollment indexes
CREATE INDEX idx_enrollments_user ON enrollments(user_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);
CREATE INDEX idx_enrollments_created ON enrollments(created_at);

-- Progress tracking indexes
CREATE INDEX idx_lesson_progress_enrollment ON lesson_progress(enrollment_id);
CREATE INDEX idx_lesson_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX idx_lesson_progress_status ON lesson_progress(status);

-- Assignment indexes
CREATE INDEX idx_assignments_lesson ON assignments(lesson_id);
CREATE INDEX idx_assignment_submissions_assignment ON assignment_submissions(assignment_id);
CREATE INDEX idx_assignment_submissions_enrollment ON assignment_submissions(enrollment_id);

-- AI indexes
CREATE INDEX idx_ai_embeddings_content ON ai_embeddings(content_type, content_id);
CREATE INDEX idx_ai_embeddings_vector ON ai_embeddings USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX idx_ai_conversations_user ON ai_conversations(user_id);
CREATE INDEX idx_ai_messages_conversation ON ai_messages(conversation_id);

-- Analytics indexes
CREATE INDEX idx_user_activities_user ON user_activities(user_id);
CREATE INDEX idx_user_activities_type ON user_activities(activity_type);
CREATE INDEX idx_user_activities_created ON user_activities(created_at);
CREATE INDEX idx_user_activities_entity ON user_activities(entity_type, entity_id);

-- BI indexes
CREATE INDEX idx_bi_metrics_type_date ON bi_metrics(metric_type, date_recorded);
CREATE INDEX idx_bi_metrics_course ON bi_metrics(course_id);
CREATE INDEX idx_learning_analytics_user_course ON learning_analytics(user_id, course_id);
CREATE INDEX idx_learning_analytics_date ON learning_analytics(date_recorded);

-- Payment indexes
CREATE INDEX idx_payment_orders_user ON payment_orders(user_id);
CREATE INDEX idx_payment_orders_status ON payment_orders(status);
CREATE INDEX idx_payment_orders_created ON payment_orders(created_at);

-- Notification indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_type ON notifications(notification_type);

-- =============================================================================
-- TRIGGERS AND FUNCTIONS
-- =============================================================================

-- Function to update timestamps automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply timestamp triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_enrollments_updated_at BEFORE UPDATE ON enrollments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lesson_progress_updated_at BEFORE UPDATE ON lesson_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_assignments_updated_at BEFORE UPDATE ON assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_assignment_submissions_updated_at BEFORE UPDATE ON assignment_submissions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON grades FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payment_orders_updated_at BEFORE UPDATE ON payment_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_ai_embeddings_updated_at BEFORE UPDATE ON ai_embeddings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_ai_conversations_updated_at BEFORE UPDATE ON ai_conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_student_cohorts_updated_at BEFORE UPDATE ON student_cohorts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_learning_analytics_updated_at BEFORE UPDATE ON learning_analytics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to auto-update enrollment progress when lesson progress changes
CREATE OR REPLACE FUNCTION update_enrollment_progress()
RETURNS TRIGGER AS $$
DECLARE
    total_lessons INTEGER;
    completed_lessons INTEGER;
    new_progress INTEGER;
    course_completed BOOLEAN := FALSE;
BEGIN
    -- Count total lessons in the course
    SELECT COUNT(l.lesson_id) INTO total_lessons
    FROM lessons l
    JOIN course_modules cm ON l.module_id = cm.module_id
    JOIN courses c ON cm.course_id = c.course_id
    JOIN enrollments e ON e.course_id = c.course_id
    WHERE e.enrollment_id = NEW.enrollment_id
    AND l.is_published = true;
    
    -- Count completed lessons
    SELECT COUNT(*) INTO completed_lessons
    FROM lesson_progress lp
    WHERE lp.enrollment_id = NEW.enrollment_id 
    AND lp.status = 'completed';
    
    -- Calculate new progress percentage
    IF total_lessons > 0 THEN
        new_progress := (completed_lessons * 100) / total_lessons;
        course_completed := (new_progress >= 100);
    ELSE
        new_progress := 0;
    END IF;
    
    -- Update enrollment progress
    UPDATE enrollments 
    SET 
        progress_percent = new_progress,
        completion_date = CASE 
            WHEN course_completed AND completion_date IS NULL THEN NOW() 
            WHEN NOT course_completed THEN NULL
            ELSE completion_date 
        END,
        status = CASE 
            WHEN course_completed AND status = 'active' THEN 'completed'
            ELSE status 
        END,
        last_accessed_at = NOW()
    WHERE enrollment_id = NEW.enrollment_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_enrollment_progress 
    AFTER INSERT OR UPDATE ON lesson_progress 
    FOR EACH ROW EXECUTE FUNCTION update_enrollment_progress();

-- Function to create user preferences when user is created
CREATE OR REPLACE FUNCTION create_user_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_preferences (user_id) VALUES (NEW.user_id);
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_create_user_preferences 
    AFTER INSERT ON users 
    FOR EACH ROW EXECUTE FUNCTION create_user_preferences();

-- Function to update cohort statistics
CREATE OR REPLACE FUNCTION update_cohort_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called by a scheduled job to update cohort statistics
    -- Implementation depends on business logic
    RETURN NULL;
END;
$$ language 'plpgsql';

COMMIT;
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- User preferences
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

-- Course categories
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

-- Main courses table
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
    requirements JSONB DEFAULT '[]'::jsonb,
    learning_objectives JSONB DEFAULT '[]'::jsonb,
    target_audience JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP
);

-- Course performance indexes
CREATE INDEX idx_courses_instructor_id ON courses(instructor_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_category_id ON courses(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_published ON courses(is_published, published_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_price ON courses(price_cents) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_rating ON courses(average_rating) WHERE deleted_at IS NULL;
CREATE INDEX idx_courses_text_search ON courses USING gin((title || ' ' || short_description));

-- Course sections
CREATE TABLE course_sections (
    section_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Lessons
CREATE TABLE lessons (
    lesson_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID NOT NULL REFERENCES course_sections(section_id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('video', 'article', 'quiz', 'assignment', 'live_session')),
    content_ref TEXT,
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

-- Student enrollments
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
    enrollment_source TEXT DEFAULT 'purchase',
    expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

CREATE INDEX idx_enrollments_user_id ON enrollments(user_id);
CREATE INDEX idx_enrollments_course_id ON enrollments(course_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);

-- Lesson progress tracking
CREATE TABLE lesson_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    status TEXT NOT NULL CHECK (status IN ('not_started', 'in_progress', 'completed')),
    completion_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    last_position_seconds INTEGER DEFAULT 0,
    completed_at TIMESTAMP,
    first_accessed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_accessed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(enrollment_id, lesson_id)
);

CREATE INDEX idx_lesson_progress_enrollment_id ON lesson_progress(enrollment_id);
CREATE INDEX idx_lesson_progress_user_id ON lesson_progress(user_id);

-- Insert default data
INSERT INTO course_categories (name, slug, description, sort_order) VALUES
    ('Programming', 'programming', 'Software development and coding courses', 1),
    ('Data Science', 'data-science', 'Data analysis and machine learning', 2),
    ('Business', 'business', 'Business and entrepreneurship', 3),
    ('Design', 'design', 'UI/UX and graphic design', 4);

-- Create default admin user (password: admin123)
INSERT INTO users (email, hashed_password, first_name, last_name, role, email_verified) VALUES
    ('admin@pcc-lms.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewcehzXQ5KbR.zPy', 'System', 'Admin', 'admin', true);

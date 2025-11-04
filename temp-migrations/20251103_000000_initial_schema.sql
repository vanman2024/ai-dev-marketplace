-- ============================================================================
-- RedAI Database Schema - Initial Migration
-- ============================================================================
-- Database: Supabase PostgreSQL with pgvector
-- Purpose: Multi-agent AI platform for Red Seal certification preparation
-- Features: Chat, RAG, Multi-tenant, Exam simulation, Mentorship, Employer
-- Created: 2025-11-03
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgvector for semantic search (RAG system)
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable full-text search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Enable pgcrypto for encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to check user role
CREATE OR REPLACE FUNCTION has_role(required_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
        AND role = required_role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- CORE USER MANAGEMENT
-- ============================================================================

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin', 'employer', 'mentor')),
    profile JSONB DEFAULT '{}'::jsonb,
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Profile structure:
-- {
--   "first_name": "John",
--   "last_name": "Doe",
--   "phone": "+1-555-0123",
--   "location": {"city": "Toronto", "province": "ON", "country": "CA"},
--   "trade_specialization": "heavy_equipment_technician",
--   "years_experience": 5,
--   "certification_level": "apprentice_level_3",
--   "employer_visibility": false,
--   "avatar_url": "https://...",
--   "language": "en",
--   "timezone": "America/Toronto"
-- }

-- Settings structure:
-- {
--   "notifications_enabled": true,
--   "email_frequency": "weekly",
--   "voice_enabled": true,
--   "preferred_model": "claude-3.5-sonnet",
--   "study_reminders": true,
--   "study_times": ["09:00-11:00", "19:00-21:00"]
-- }

-- Indexes for users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_profile ON users USING gin(profile);

-- Trigger for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRADE SPECIALIZATIONS
-- ============================================================================

-- Trade specializations (Red Seal trades)
CREATE TABLE trade_specializations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name_en TEXT NOT NULL,
    name_fr TEXT NOT NULL,
    description_en TEXT,
    description_fr TEXT,
    noa_code TEXT, -- National Occupational Analysis code
    exam_duration_minutes INT DEFAULT 240, -- 4 hours standard
    passing_score_percentage INT DEFAULT 70,
    question_count INT DEFAULT 120,
    metadata JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Metadata structure:
-- {
--   "industry": "automotive",
--   "difficulty_level": "intermediate",
--   "prerequisite_trades": [],
--   "related_trades": ["truck_transport_mechanic"],
--   "certification_body": "red_seal",
--   "revision_date": "2023-01-01"
-- }

CREATE INDEX idx_trade_specializations_code ON trade_specializations(code);
CREATE INDEX idx_trade_specializations_active ON trade_specializations(is_active);

CREATE TRIGGER update_trade_specializations_updated_at
    BEFORE UPDATE ON trade_specializations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SUBSCRIPTION & BILLING
-- ============================================================================

-- User subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    plan_type TEXT NOT NULL DEFAULT 'free' CHECK (plan_type IN ('free', 'basic', 'pro', 'lifetime')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'past_due', 'expired', 'trialing')),
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    period_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    period_end TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days',
    trial_end TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Metadata structure:
-- {
--   "monthly_message_limit": 1000,
--   "monthly_document_limit": 50,
--   "monthly_exam_limit": 10,
--   "messages_used": 150,
--   "documents_used": 10,
--   "exams_taken": 3,
--   "features": ["chat", "documents", "multi_model", "voice", "mentorship"],
--   "discount_code": "LAUNCH2025",
--   "billing_amount_cents": 2999
-- }

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_period_end ON subscriptions(period_end);
CREATE INDEX idx_subscriptions_stripe_customer ON subscriptions(stripe_customer_id);

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- CHAT & CONVERSATION SYSTEM
-- ============================================================================

-- Conversation sessions
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    conversation_type TEXT DEFAULT 'general' CHECK (conversation_type IN ('general', 'exam_prep', 'mentorship', 'troubleshooting')),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Metadata structure:
-- {
--   "model_id": "claude-3.5-sonnet",
--   "message_count": 10,
--   "total_tokens": 5000,
--   "tags": ["technical", "troubleshooting", "hydraulics"],
--   "trade_context": "heavy_equipment_technician",
--   "learning_goals": ["master_hydraulic_systems"],
--   "is_voice_enabled": true
-- }

CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX idx_conversations_type ON conversations(conversation_type);

CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Messages in conversations
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Metadata structure:
-- {
--   "model": "claude-3.5-sonnet",
--   "tokens": 150,
--   "tool_use": ["search_documents", "heavy_equipment_expert"],
--   "response_time_ms": 1250,
--   "voice_interaction": true,
--   "audio_duration_seconds": 45,
--   "specialist_agents_invoked": ["heavy_equipment_expert", "curriculum_validator"],
--   "confidence_score": 0.95
-- }

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_messages_role ON messages(role);
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at DESC);

-- ============================================================================
-- MEM0 PERSISTENT MEMORY
-- ============================================================================

-- User memories (Mem0 integration)
CREATE TABLE user_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    learning_profile JSONB DEFAULT '{}'::jsonb,
    conversation_context JSONB DEFAULT '{}'::jsonb,
    preferences JSONB DEFAULT '{}'::jsonb,
    career_journey JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- learning_profile structure:
-- {
--   "learning_style": "visual",
--   "optimal_study_times": ["09:00-11:00", "19:00-21:00"],
--   "preferred_explanation_style": "technical_with_diagrams",
--   "attention_span_minutes": 30,
--   "learning_dna": {
--     "strength_areas": ["hydraulic_systems", "electrical_diagnostics"],
--     "weak_areas": ["pneumatic_systems", "transmission_theory"],
--     "learning_pace": "moderate",
--     "retention_rate": 0.85
--   }
-- }

-- conversation_context structure:
-- {
--   "recent_topics": ["electrical_codes", "safety_procedures", "hydraulic_troubleshooting"],
--   "current_goals": ["Pass Red Seal exam", "Master hydraulic systems"],
--   "upcoming_milestones": ["exam_date_2025_06_15"],
--   "conversation_history_summary": "User is preparing for Red Seal Heavy Equipment exam..."
-- }

-- career_journey structure:
-- {
--   "certification_timeline": [
--     {"date": "2023-01-15", "event": "Started apprenticeship", "level": 1},
--     {"date": "2024-06-20", "event": "Completed Level 2", "level": 2}
--   ],
--   "employment_history": [
--     {"employer": "ABC Construction", "start": "2023-01", "end": null, "role": "Apprentice"}
--   ],
--   "exam_attempts": [
--     {"date": "2025-03-15", "score": 68, "passed": false}
--   ],
--   "mentorship_connections": ["mentor_uuid_1", "mentor_uuid_2"]
-- }

CREATE INDEX idx_user_memories_user_id ON user_memories(user_id);
CREATE INDEX idx_user_memories_learning_profile ON user_memories USING gin(learning_profile);

CREATE TRIGGER update_user_memories_updated_at
    BEFORE UPDATE ON user_memories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MCP SERVER COORDINATION
-- ============================================================================

-- MCP server registry
CREATE TABLE mcp_servers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    server_type TEXT NOT NULL CHECK (server_type IN ('specialist_agent', 'tool_provider', 'data_source')),
    endpoint_url TEXT,
    capabilities JSONB DEFAULT '[]'::jsonb,
    configuration JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Capabilities structure: ["question_generation", "performance_analysis"]
-- Configuration structure:
-- {
--   "max_concurrent_requests": 10,
--   "timeout_seconds": 30,
--   "retry_attempts": 3,
--   "priority": "high"
-- }

CREATE INDEX idx_mcp_servers_name ON mcp_servers(name);
CREATE INDEX idx_mcp_servers_type ON mcp_servers(server_type);
CREATE INDEX idx_mcp_servers_active ON mcp_servers(is_active);

CREATE TRIGGER update_mcp_servers_updated_at
    BEFORE UPDATE ON mcp_servers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Agent coordination sessions
CREATE TABLE agent_coordination_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    primary_agent TEXT NOT NULL DEFAULT 'red_personal_agent',
    specialist_agents_invoked JSONB DEFAULT '[]'::jsonb,
    coordination_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- specialist_agents_invoked: ["heavy_equipment_expert", "question_generation", "performance_analysis"]
-- coordination_metadata:
-- {
--   "routing_decisions": [
--     {"agent": "heavy_equipment_expert", "reason": "technical_question_about_hydraulics", "timestamp": "2025-11-03T10:15:00Z"}
--   ],
--   "response_fusion": "combined_responses_from_multiple_agents",
--   "total_coordination_time_ms": 850
-- }

CREATE INDEX idx_agent_coordination_user_id ON agent_coordination_sessions(user_id);
CREATE INDEX idx_agent_coordination_conversation_id ON agent_coordination_sessions(conversation_id);
CREATE INDEX idx_agent_coordination_created_at ON agent_coordination_sessions(created_at DESC);

-- ============================================================================
-- RAG SYSTEM (DOCUMENT STORAGE & EMBEDDINGS)
-- ============================================================================

-- Documents (Red Seal NOA, equipment manuals, trade materials)
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL for system documents
    document_type TEXT NOT NULL CHECK (document_type IN ('noa_documentation', 'equipment_manual', 'user_upload', 'study_material')),
    trade_specialization_id UUID REFERENCES trade_specializations(id),
    filename TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'ready', 'failed')),
    extracted_text TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Metadata structure:
-- {
--   "page_count": 10,
--   "processing_time_ms": 5000,
--   "embedding_count": 150,
--   "language": "en",
--   "source": "red_seal_official",
--   "version": "2023",
--   "topics": ["hydraulic_systems", "safety_procedures"]
-- }

CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_trade ON documents(trade_specialization_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_created_at ON documents(created_at DESC);
CREATE INDEX idx_documents_text_search ON documents USING gin(to_tsvector('english', extracted_text));

CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Document embeddings (pgvector for semantic search)
CREATE TABLE document_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    embedding vector(1536), -- OpenAI ada-002 dimension
    chunk_text TEXT NOT NULL,
    chunk_index INT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Metadata structure:
-- {
--   "page_number": 3,
--   "section_title": "Hydraulic System Diagnostics",
--   "word_count": 250,
--   "topics": ["hydraulics", "troubleshooting"],
--   "difficulty_level": "intermediate"
-- }

CREATE INDEX idx_document_embeddings_document_id ON document_embeddings(document_id);
CREATE INDEX idx_document_embeddings_chunk_index ON document_embeddings(document_id, chunk_index);

-- HNSW index for fast approximate vector similarity search
CREATE INDEX idx_document_embeddings_vector ON document_embeddings
    USING hnsw (embedding vector_cosine_ops);

-- ============================================================================
-- EXAM & LEARNING SYSTEM
-- ============================================================================

-- Question bank
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trade_specialization_id UUID NOT NULL REFERENCES trade_specializations(id),
    question_type TEXT NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'diagram', 'scenario')),
    question_text TEXT NOT NULL,
    question_image_url TEXT,
    correct_answer TEXT NOT NULL,
    answer_options JSONB NOT NULL, -- Array of options for multiple choice
    explanation TEXT NOT NULL,
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    noa_topic TEXT NOT NULL, -- National Occupational Analysis topic
    subtopic TEXT,
    source TEXT NOT NULL CHECK (source IN ('red_seal_official', 'ai_generated', 'instructor_created')),
    review_status TEXT NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending', 'approved', 'rejected', 'revision_needed')),
    ai_generation_metadata JSONB DEFAULT '{}'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- answer_options structure:
-- ["Option A text", "Option B text", "Option C text", "Option D text"]

-- ai_generation_metadata:
-- {
--   "generated_by": "question_generation_agent",
--   "generation_date": "2025-11-03",
--   "source_document_id": "uuid",
--   "confidence_score": 0.92,
--   "variations_count": 3
-- }

-- tags: ["hydraulics", "troubleshooting", "safety"]

CREATE INDEX idx_questions_trade ON questions(trade_specialization_id);
CREATE INDEX idx_questions_type ON questions(question_type);
CREATE INDEX idx_questions_difficulty ON questions(difficulty_level);
CREATE INDEX idx_questions_topic ON questions(noa_topic);
CREATE INDEX idx_questions_source ON questions(source);
CREATE INDEX idx_questions_review_status ON questions(review_status);
CREATE INDEX idx_questions_tags ON questions USING gin(tags);

CREATE TRIGGER update_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Exam sessions
CREATE TABLE exam_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trade_specialization_id UUID NOT NULL REFERENCES trade_specializations(id),
    session_type TEXT NOT NULL CHECK (session_type IN ('practice', 'mock_exam', 'adaptive', 'weak_area_focus')),
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('not_started', 'in_progress', 'paused', 'completed', 'abandoned')),
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    time_limit_minutes INT NOT NULL,
    score_percentage DECIMAL(5,2),
    passed BOOLEAN,
    questions_data JSONB NOT NULL, -- Array of question IDs and user answers
    performance_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- questions_data structure:
-- [
--   {
--     "question_id": "uuid",
--     "user_answer": "A",
--     "correct_answer": "B",
--     "is_correct": false,
--     "time_spent_seconds": 45,
--     "bookmarked": false
--   }
-- ]

-- performance_metadata:
-- {
--   "questions_correct": 85,
--   "questions_total": 120,
--   "time_remaining_seconds": 300,
--   "topic_breakdown": {
--     "hydraulic_systems": {"correct": 15, "total": 20},
--     "electrical_systems": {"correct": 18, "total": 25}
--   },
--   "difficulty_breakdown": {
--     "easy": {"correct": 30, "total": 40},
--     "medium": {"correct": 35, "total": 50},
--     "hard": {"correct": 20, "total": 30}
--   }
-- }

CREATE INDEX idx_exam_sessions_user_id ON exam_sessions(user_id);
CREATE INDEX idx_exam_sessions_trade ON exam_sessions(trade_specialization_id);
CREATE INDEX idx_exam_sessions_status ON exam_sessions(status);
CREATE INDEX idx_exam_sessions_created_at ON exam_sessions(created_at DESC);
CREATE INDEX idx_exam_sessions_user_created ON exam_sessions(user_id, created_at DESC);

CREATE TRIGGER update_exam_sessions_updated_at
    BEFORE UPDATE ON exam_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Learning profiles (performance tracking)
CREATE TABLE learning_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    trade_specialization_id UUID NOT NULL REFERENCES trade_specializations(id),
    weak_areas JSONB DEFAULT '[]'::jsonb,
    strong_areas JSONB DEFAULT '[]'::jsonb,
    learning_metrics JSONB DEFAULT '{}'::jsonb,
    recommendations JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- weak_areas:
-- [
--   {"topic": "pneumatic_systems", "accuracy": 0.45, "priority": "high"},
--   {"topic": "transmission_theory", "accuracy": 0.58, "priority": "medium"}
-- ]

-- strong_areas:
-- [
--   {"topic": "hydraulic_systems", "accuracy": 0.92, "mastery_level": "expert"},
--   {"topic": "electrical_diagnostics", "accuracy": 0.88, "mastery_level": "advanced"}
-- ]

-- learning_metrics:
-- {
--   "total_exams_taken": 15,
--   "average_score": 78.5,
--   "improvement_rate": 0.12,
--   "study_hours": 45,
--   "questions_answered": 1850,
--   "current_readiness_score": 82
-- }

-- recommendations:
-- [
--   {"type": "study_focus", "topic": "pneumatic_systems", "priority": "high"},
--   {"type": "practice_exam", "difficulty": "hard", "suggested_date": "2025-11-10"}
-- ]

CREATE INDEX idx_learning_profiles_user_id ON learning_profiles(user_id);
CREATE INDEX idx_learning_profiles_trade ON learning_profiles(trade_specialization_id);

CREATE TRIGGER update_learning_profiles_updated_at
    BEFORE UPDATE ON learning_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MENTORSHIP MARKETPLACE
-- ============================================================================

-- Mentor profiles
CREATE TABLE mentor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    trade_specialization_ids JSONB NOT NULL, -- Array of trade UUIDs
    years_experience INT NOT NULL,
    certification_level TEXT NOT NULL,
    bio TEXT NOT NULL,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    verification_documents JSONB DEFAULT '[]'::jsonb,
    mentorship_type TEXT[] DEFAULT ARRAY['paid'], -- Can be 'paid', 'volunteer', 'corporate'
    hourly_rate_cents INT, -- NULL for volunteer
    availability JSONB DEFAULT '{}'::jsonb,
    rating_average DECIMAL(3,2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    total_sessions INT DEFAULT 0,
    specialties JSONB DEFAULT '[]'::jsonb,
    languages JSONB DEFAULT '["en"]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- availability structure:
-- {
--   "timezone": "America/Toronto",
--   "weekly_schedule": {
--     "monday": [{"start": "09:00", "end": "17:00"}],
--     "tuesday": [{"start": "09:00", "end": "17:00"}],
--     "wednesday": [],
--     "thursday": [{"start": "09:00", "end": "17:00"}],
--     "friday": [{"start": "09:00", "end": "15:00"}],
--     "saturday": [],
--     "sunday": []
--   },
--   "max_sessions_per_week": 10
-- }

-- specialties: ["hydraulic_troubleshooting", "electrical_diagnostics", "heavy_equipment_repair"]
-- languages: ["en", "fr"]

CREATE INDEX idx_mentor_profiles_user_id ON mentor_profiles(user_id);
CREATE INDEX idx_mentor_profiles_verification ON mentor_profiles(verification_status);
CREATE INDEX idx_mentor_profiles_rating ON mentor_profiles(rating_average DESC);
CREATE INDEX idx_mentor_profiles_specialties ON mentor_profiles USING gin(specialties);

CREATE TRIGGER update_mentor_profiles_updated_at
    BEFORE UPDATE ON mentor_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Mentorship sessions
CREATE TABLE mentorship_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mentee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_type TEXT NOT NULL CHECK (session_type IN ('one_on_one', 'group', 'workshop')),
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show')),
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ NOT NULL,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    video_conference_url TEXT,
    session_notes TEXT,
    mentee_goals JSONB DEFAULT '[]'::jsonb,
    outcomes JSONB DEFAULT '[]'::jsonb,
    payment_status TEXT CHECK (payment_status IN ('pending', 'paid', 'refunded', 'volunteer')),
    payment_amount_cents INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- mentee_goals: ["Understand hydraulic pressure calculations", "Learn troubleshooting workflow"]
-- outcomes: ["Mastered pressure calculations", "Practiced diagnostic workflow"]

CREATE INDEX idx_mentorship_sessions_mentor_id ON mentorship_sessions(mentor_id);
CREATE INDEX idx_mentorship_sessions_mentee_id ON mentorship_sessions(mentee_id);
CREATE INDEX idx_mentorship_sessions_status ON mentorship_sessions(status);
CREATE INDEX idx_mentorship_sessions_scheduled_start ON mentorship_sessions(scheduled_start);
CREATE INDEX idx_mentorship_sessions_mentor_scheduled ON mentorship_sessions(mentor_id, scheduled_start);

CREATE TRIGGER update_mentorship_sessions_updated_at
    BEFORE UPDATE ON mentorship_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Mentorship reviews
CREATE TABLE mentorship_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES mentorship_sessions(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    helpful_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(session_id, reviewer_id)
);

CREATE INDEX idx_mentorship_reviews_session_id ON mentorship_reviews(session_id);
CREATE INDEX idx_mentorship_reviews_reviewee_id ON mentorship_reviews(reviewee_id);
CREATE INDEX idx_mentorship_reviews_rating ON mentorship_reviews(rating);

CREATE TRIGGER update_mentorship_reviews_updated_at
    BEFORE UPDATE ON mentorship_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Corporate mentorship programs
CREATE TABLE corporate_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_name TEXT NOT NULL,
    description TEXT,
    participating_mentors JSONB DEFAULT '[]'::jsonb, -- Array of user IDs
    participating_mentees JSONB DEFAULT '[]'::jsonb, -- Array of user IDs
    program_type TEXT NOT NULL CHECK (program_type IN ('apprenticeship', 'upskilling', 'certification_prep')),
    budget_cents INT,
    sessions_allocated INT,
    sessions_used INT DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_corporate_programs_employer_id ON corporate_programs(employer_id);
CREATE INDEX idx_corporate_programs_active ON corporate_programs(is_active);

CREATE TRIGGER update_corporate_programs_updated_at
    BEFORE UPDATE ON corporate_programs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- EMPLOYER & RECRUITING
-- ============================================================================

-- Employer profiles
CREATE TABLE employer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    company_size TEXT CHECK (company_size IN ('1-10', '11-50', '51-200', '201-500', '500+')),
    industry TEXT NOT NULL,
    website_url TEXT,
    description TEXT,
    logo_url TEXT,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    trade_specializations_hiring JSONB DEFAULT '[]'::jsonb, -- Array of trade codes
    location JSONB NOT NULL,
    contact_info JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- location structure:
-- {
--   "city": "Toronto",
--   "province": "ON",
--   "country": "CA",
--   "postal_code": "M5V 3A8",
--   "coordinates": {"lat": 43.6532, "lng": -79.3832}
-- }

-- contact_info:
-- {
--   "primary_contact_name": "Jane Doe",
--   "primary_contact_email": "jane@company.com",
--   "phone": "+1-555-0199"
-- }

CREATE INDEX idx_employer_profiles_user_id ON employer_profiles(user_id);
CREATE INDEX idx_employer_profiles_verification ON employer_profiles(verification_status);
CREATE INDEX idx_employer_profiles_company_name ON employer_profiles(company_name);

CREATE TRIGGER update_employer_profiles_updated_at
    BEFORE UPDATE ON employer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Candidate pipeline (employer view of students)
CREATE TABLE candidate_pipeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'discovered' CHECK (status IN ('discovered', 'contacted', 'interviewing', 'offered', 'hired', 'rejected', 'withdrawn')),
    match_score DECIMAL(5,2), -- AI-calculated match score
    match_reasons JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    contacted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(employer_id, candidate_id)
);

-- match_reasons:
-- [
--   {"reason": "High exam scores in target trade", "weight": 0.4},
--   {"reason": "Geographic proximity", "weight": 0.3},
--   {"reason": "Certification level match", "weight": 0.3}
-- ]

CREATE INDEX idx_candidate_pipeline_employer_id ON candidate_pipeline(employer_id);
CREATE INDEX idx_candidate_pipeline_candidate_id ON candidate_pipeline(candidate_id);
CREATE INDEX idx_candidate_pipeline_status ON candidate_pipeline(status);
CREATE INDEX idx_candidate_pipeline_match_score ON candidate_pipeline(match_score DESC);

CREATE TRIGGER update_candidate_pipeline_updated_at
    BEFORE UPDATE ON candidate_pipeline
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- JOB HUB
-- ============================================================================

-- Job postings
CREATE TABLE job_postings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trade_specialization_id UUID NOT NULL REFERENCES trade_specializations(id),
    job_title TEXT NOT NULL,
    job_type TEXT NOT NULL CHECK (job_type IN ('full_time', 'part_time', 'contract', 'apprenticeship')),
    description TEXT NOT NULL,
    requirements JSONB DEFAULT '[]'::jsonb,
    salary_range_min_cents INT,
    salary_range_max_cents INT,
    location JSONB NOT NULL,
    benefits JSONB DEFAULT '[]'::jsonb,
    start_date DATE,
    application_deadline DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'paused', 'filled', 'closed')),
    application_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- requirements: ["Red Seal certification", "3+ years experience", "Valid driver's license"]
-- benefits: ["Health insurance", "Pension plan", "Tool allowance", "Continuing education"]

CREATE INDEX idx_job_postings_employer_id ON job_postings(employer_id);
CREATE INDEX idx_job_postings_trade ON job_postings(trade_specialization_id);
CREATE INDEX idx_job_postings_type ON job_postings(job_type);
CREATE INDEX idx_job_postings_status ON job_postings(status);
CREATE INDEX idx_job_postings_created_at ON job_postings(created_at DESC);
CREATE INDEX idx_job_postings_application_deadline ON job_postings(application_deadline);

CREATE TRIGGER update_job_postings_updated_at
    BEFORE UPDATE ON job_postings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Job applications
CREATE TABLE job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_posting_id UUID NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
    applicant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'under_review', 'shortlisted', 'interviewing', 'offered', 'accepted', 'rejected', 'withdrawn')),
    cover_letter TEXT,
    resume_url TEXT,
    match_score DECIMAL(5,2),
    match_metadata JSONB DEFAULT '{}'::jsonb,
    employer_notes TEXT,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(job_posting_id, applicant_id)
);

-- match_metadata:
-- {
--   "exam_readiness_score": 85,
--   "relevant_experience_years": 4,
--   "certification_level_match": true,
--   "geographic_distance_km": 15
-- }

CREATE INDEX idx_job_applications_job_posting_id ON job_applications(job_posting_id);
CREATE INDEX idx_job_applications_applicant_id ON job_applications(applicant_id);
CREATE INDEX idx_job_applications_status ON job_applications(status);
CREATE INDEX idx_job_applications_match_score ON job_applications(match_score DESC);
CREATE INDEX idx_job_applications_applied_at ON job_applications(applied_at DESC);

CREATE TRIGGER update_job_applications_updated_at
    BEFORE UPDATE ON job_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMUNITY FORUM
-- ============================================================================

-- Forum topics
CREATE TABLE forum_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trade_specialization_id UUID REFERENCES trade_specializations(id),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    topic_type TEXT NOT NULL CHECK (topic_type IN ('question', 'discussion', 'tip', 'showcase')),
    tags JSONB DEFAULT '[]'::jsonb,
    view_count INT DEFAULT 0,
    upvote_count INT DEFAULT 0,
    reply_count INT DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    is_solved BOOLEAN DEFAULT FALSE,
    accepted_answer_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- tags: ["hydraulics", "troubleshooting", "beginner"]

CREATE INDEX idx_forum_topics_author_id ON forum_topics(author_id);
CREATE INDEX idx_forum_topics_trade ON forum_topics(trade_specialization_id);
CREATE INDEX idx_forum_topics_type ON forum_topics(topic_type);
CREATE INDEX idx_forum_topics_created_at ON forum_topics(created_at DESC);
CREATE INDEX idx_forum_topics_upvote_count ON forum_topics(upvote_count DESC);
CREATE INDEX idx_forum_topics_tags ON forum_topics USING gin(tags);

CREATE TRIGGER update_forum_topics_updated_at
    BEFORE UPDATE ON forum_topics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Forum replies
CREATE TABLE forum_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_reply_id UUID REFERENCES forum_replies(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    upvote_count INT DEFAULT 0,
    is_accepted_answer BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_forum_replies_topic_id ON forum_replies(topic_id);
CREATE INDEX idx_forum_replies_author_id ON forum_replies(author_id);
CREATE INDEX idx_forum_replies_parent_reply_id ON forum_replies(parent_reply_id);
CREATE INDEX idx_forum_replies_created_at ON forum_replies(created_at);

CREATE TRIGGER update_forum_replies_updated_at
    BEFORE UPDATE ON forum_replies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Forum votes (upvotes/downvotes)
CREATE TABLE forum_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    votable_type TEXT NOT NULL CHECK (votable_type IN ('topic', 'reply')),
    votable_id UUID NOT NULL,
    vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, votable_type, votable_id)
);

CREATE INDEX idx_forum_votes_user_id ON forum_votes(user_id);
CREATE INDEX idx_forum_votes_votable ON forum_votes(votable_type, votable_id);

-- ============================================================================
-- AI USAGE TRACKING & ANALYTICS
-- ============================================================================

-- AI request tracking
CREATE TABLE ai_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    model_id TEXT NOT NULL,
    request_type TEXT NOT NULL CHECK (request_type IN ('chat', 'question_generation', 'performance_analysis', 'document_processing', 'voice')),
    tokens_input INT NOT NULL,
    tokens_output INT NOT NULL,
    tokens_total INT NOT NULL,
    cost_usd DECIMAL(10,6),
    response_time_ms INT,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- metadata:
-- {
--   "specialist_agent": "heavy_equipment_expert",
--   "prompt_tokens": 1200,
--   "completion_tokens": 350,
--   "cache_hit": false
-- }

CREATE INDEX idx_ai_requests_user_id ON ai_requests(user_id);
CREATE INDEX idx_ai_requests_conversation_id ON ai_requests(conversation_id);
CREATE INDEX idx_ai_requests_model_id ON ai_requests(model_id);
CREATE INDEX idx_ai_requests_created_at ON ai_requests(created_at DESC);
CREATE INDEX idx_ai_requests_user_created ON ai_requests(user_id, created_at DESC);

-- User analytics aggregation
CREATE TABLE user_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    total_sessions INT DEFAULT 0,
    total_messages INT DEFAULT 0,
    total_exams_taken INT DEFAULT 0,
    total_study_hours DECIMAL(10,2) DEFAULT 0.00,
    total_ai_tokens_used BIGINT DEFAULT 0,
    total_mentorship_sessions INT DEFAULT 0,
    total_forum_posts INT DEFAULT 0,
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_analytics_user_id ON user_analytics(user_id);
CREATE INDEX idx_user_analytics_last_active ON user_analytics(last_active_at DESC);

CREATE TRIGGER update_user_analytics_updated_at
    BEFORE UPDATE ON user_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- AUDIT LOGGING
-- ============================================================================

-- Audit logs for security and compliance
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id UUID,
    metadata JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- metadata:
-- {
--   "old_value": {...},
--   "new_value": {...},
--   "changed_fields": ["email", "role"],
--   "reason": "user_request"
-- }

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentorship_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentorship_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE employer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidate_pipeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_postings ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Users: can read own data, admins can read all
CREATE POLICY "Users can read own data"
    ON users FOR SELECT
    USING (auth.uid() = id OR has_role('admin'));

CREATE POLICY "Users can update own data"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Subscriptions: users can read own, admins can modify
CREATE POLICY "Users can read own subscription"
    ON subscriptions FOR SELECT
    USING (user_id = auth.uid() OR has_role('admin'));

CREATE POLICY "Admins can modify subscriptions"
    ON subscriptions FOR ALL
    USING (has_role('admin'));

-- Conversations and messages: users can only access their own
CREATE POLICY "Users can access own conversations"
    ON conversations FOR ALL
    USING (user_id = auth.uid());

CREATE POLICY "Users can access own messages"
    ON messages FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- User memories: users can only access their own
CREATE POLICY "Users can access own memory"
    ON user_memories FOR ALL
    USING (user_id = auth.uid());

-- Documents: users can access their own + public system documents
CREATE POLICY "Users can access own documents and system documents"
    ON documents FOR SELECT
    USING (user_id = auth.uid() OR user_id IS NULL OR has_role('admin'));

CREATE POLICY "Users can modify own documents"
    ON documents FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own documents"
    ON documents FOR UPDATE
    USING (user_id = auth.uid() OR has_role('admin'));

CREATE POLICY "Users can delete own documents"
    ON documents FOR DELETE
    USING (user_id = auth.uid() OR has_role('admin'));

-- Document embeddings: read-only for users, full access for system
CREATE POLICY "Users can read embeddings for accessible documents"
    ON document_embeddings FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM documents
            WHERE documents.id = document_embeddings.document_id
            AND (documents.user_id = auth.uid() OR documents.user_id IS NULL)
        )
    );

-- Exam sessions: users can only access their own
CREATE POLICY "Users can access own exam sessions"
    ON exam_sessions FOR ALL
    USING (user_id = auth.uid() OR has_role('admin'));

-- Learning profiles: users can access their own
CREATE POLICY "Users can access own learning profile"
    ON learning_profiles FOR ALL
    USING (user_id = auth.uid() OR has_role('admin'));

-- Mentor profiles: public read, mentors can modify their own
CREATE POLICY "Anyone can read verified mentor profiles"
    ON mentor_profiles FOR SELECT
    USING (verification_status = 'verified' OR user_id = auth.uid() OR has_role('admin'));

CREATE POLICY "Mentors can modify own profile"
    ON mentor_profiles FOR ALL
    USING (user_id = auth.uid() OR has_role('admin'));

-- Mentorship sessions: participants and admins can access
CREATE POLICY "Participants can access mentorship sessions"
    ON mentorship_sessions FOR ALL
    USING (mentor_id = auth.uid() OR mentee_id = auth.uid() OR has_role('admin'));

-- Mentorship reviews: public read, participants can create
CREATE POLICY "Anyone can read reviews"
    ON mentorship_reviews FOR SELECT
    USING (TRUE);

CREATE POLICY "Participants can create reviews"
    ON mentorship_reviews FOR INSERT
    WITH CHECK (reviewer_id = auth.uid());

-- Employer profiles: public read verified, owners can modify
CREATE POLICY "Anyone can read verified employer profiles"
    ON employer_profiles FOR SELECT
    USING (verification_status = 'verified' OR user_id = auth.uid() OR has_role('admin'));

CREATE POLICY "Employers can modify own profile"
    ON employer_profiles FOR ALL
    USING (user_id = auth.uid() OR has_role('admin'));

-- Candidate pipeline: employers can access their own, candidates can see if they're in it
CREATE POLICY "Employers can access own pipeline"
    ON candidate_pipeline FOR ALL
    USING (employer_id = auth.uid() OR candidate_id = auth.uid() OR has_role('admin'));

-- Job postings: public read active jobs, employers can modify their own
CREATE POLICY "Anyone can read active job postings"
    ON job_postings FOR SELECT
    USING (status = 'active' OR employer_id = auth.uid() OR has_role('admin'));

CREATE POLICY "Employers can modify own job postings"
    ON job_postings FOR ALL
    USING (employer_id = auth.uid() OR has_role('admin'));

-- Job applications: applicants and job owners can access
CREATE POLICY "Applicants and employers can access applications"
    ON job_applications FOR ALL
    USING (
        applicant_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM job_postings
            WHERE job_postings.id = job_applications.job_posting_id
            AND job_postings.employer_id = auth.uid()
        ) OR
        has_role('admin')
    );

-- Forum: public read, authenticated users can post
CREATE POLICY "Anyone can read forum topics"
    ON forum_topics FOR SELECT
    USING (TRUE);

CREATE POLICY "Authenticated users can create topics"
    ON forum_topics FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authors can modify own topics"
    ON forum_topics FOR UPDATE
    USING (author_id = auth.uid() OR has_role('admin'));

CREATE POLICY "Anyone can read forum replies"
    ON forum_replies FOR SELECT
    USING (TRUE);

CREATE POLICY "Authenticated users can create replies"
    ON forum_replies FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authors can modify own replies"
    ON forum_replies FOR UPDATE
    USING (author_id = auth.uid() OR has_role('admin'));

-- AI requests: users can access their own, admins can access all
CREATE POLICY "Users can access own AI requests"
    ON ai_requests FOR SELECT
    USING (user_id = auth.uid() OR has_role('admin'));

-- User analytics: users can access their own
CREATE POLICY "Users can access own analytics"
    ON user_analytics FOR SELECT
    USING (user_id = auth.uid() OR has_role('admin'));

-- Audit logs: admins only
CREATE POLICY "Admins can access audit logs"
    ON audit_logs FOR ALL
    USING (has_role('admin'));

-- ============================================================================
-- INITIAL DATA SEEDING
-- ============================================================================

-- Insert Heavy Equipment Technician trade specialization
INSERT INTO trade_specializations (
    code,
    name_en,
    name_fr,
    description_en,
    description_fr,
    noa_code,
    exam_duration_minutes,
    passing_score_percentage,
    question_count,
    metadata
) VALUES (
    'heavy_equipment_technician',
    'Heavy Equipment Technician',
    'Technicien d''équipement lourd',
    'Maintains, diagnoses, and repairs heavy construction and mining equipment',
    'Entretient, diagnostique et répare l''équipement lourd de construction et d''exploitation minière',
    '421A',
    240,
    70,
    120,
    '{
        "industry": "construction_mining",
        "difficulty_level": "advanced",
        "prerequisite_trades": [],
        "related_trades": ["truck_transport_mechanic", "automotive_service_technician"],
        "certification_body": "red_seal",
        "revision_date": "2023-01-01"
    }'::jsonb
);

-- Insert MCP servers for specialist agents
INSERT INTO mcp_servers (name, description, server_type, capabilities, configuration) VALUES
(
    'heavy_equipment_expert',
    'Specialist agent for heavy equipment technical knowledge',
    'specialist_agent',
    '["technical_troubleshooting", "equipment_diagnostics", "repair_procedures", "safety_protocols"]'::jsonb,
    '{"max_concurrent_requests": 10, "timeout_seconds": 30, "retry_attempts": 3, "priority": "high"}'::jsonb
),
(
    'question_generation',
    'AI agent for generating exam questions from content',
    'specialist_agent',
    '["question_generation", "question_variation", "difficulty_calibration"]'::jsonb,
    '{"max_concurrent_requests": 5, "timeout_seconds": 60, "retry_attempts": 2, "priority": "medium"}'::jsonb
),
(
    'performance_analysis',
    'Analyzes user performance and provides recommendations',
    'specialist_agent',
    '["performance_tracking", "weak_area_identification", "study_recommendations", "readiness_scoring"]'::jsonb,
    '{"max_concurrent_requests": 10, "timeout_seconds": 20, "retry_attempts": 3, "priority": "high"}'::jsonb
),
(
    'curriculum_validator',
    'Validates content against Red Seal NOA standards',
    'specialist_agent',
    '["content_validation", "noa_alignment", "quality_assurance"]'::jsonb,
    '{"max_concurrent_requests": 5, "timeout_seconds": 30, "retry_attempts": 2, "priority": "medium"}'::jsonb
);

-- ============================================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- ============================================================================

-- Materialized view for user conversation statistics
CREATE MATERIALIZED VIEW user_conversation_stats AS
SELECT
    c.user_id,
    COUNT(c.id) as total_conversations,
    COUNT(m.id) as total_messages,
    MAX(c.updated_at) as last_activity,
    AVG(jsonb_array_length(COALESCE(c.metadata->'tags', '[]'::jsonb))) as avg_tags_per_conversation
FROM conversations c
LEFT JOIN messages m ON c.id = m.conversation_id
GROUP BY c.user_id;

CREATE INDEX idx_user_conversation_stats_user_id ON user_conversation_stats(user_id);

-- Materialized view for mentor performance metrics
CREATE MATERIALIZED VIEW mentor_performance_stats AS
SELECT
    mp.user_id as mentor_id,
    mp.rating_average,
    mp.review_count,
    mp.total_sessions,
    COUNT(DISTINCT ms.mentee_id) as unique_mentees,
    AVG(EXTRACT(EPOCH FROM (ms.actual_end - ms.actual_start))/60) as avg_session_duration_minutes,
    COUNT(CASE WHEN ms.status = 'completed' THEN 1 END) as completed_sessions,
    COUNT(CASE WHEN ms.status = 'cancelled' THEN 1 END) as cancelled_sessions,
    COUNT(CASE WHEN ms.status = 'no_show' THEN 1 END) as no_show_sessions
FROM mentor_profiles mp
LEFT JOIN mentorship_sessions ms ON mp.user_id = ms.mentor_id
GROUP BY mp.user_id, mp.rating_average, mp.review_count, mp.total_sessions;

CREATE INDEX idx_mentor_performance_stats_mentor_id ON mentor_performance_stats(mentor_id);

-- Materialized view for employer recruiting metrics
CREATE MATERIALIZED VIEW employer_recruiting_stats AS
SELECT
    ep.user_id as employer_id,
    COUNT(DISTINCT jp.id) as total_job_postings,
    COUNT(DISTINCT CASE WHEN jp.status = 'active' THEN jp.id END) as active_job_postings,
    COUNT(DISTINCT ja.id) as total_applications_received,
    COUNT(DISTINCT cp.id) as total_candidates_in_pipeline,
    COUNT(DISTINCT CASE WHEN cp.status = 'hired' THEN cp.id END) as total_hires,
    AVG(jp.application_count) as avg_applications_per_job
FROM employer_profiles ep
LEFT JOIN job_postings jp ON ep.user_id = jp.employer_id
LEFT JOIN job_applications ja ON jp.id = ja.job_posting_id
LEFT JOIN candidate_pipeline cp ON ep.user_id = cp.employer_id
GROUP BY ep.user_id;

CREATE INDEX idx_employer_recruiting_stats_employer_id ON employer_recruiting_stats(employer_id);

-- ============================================================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- ============================================================================

-- Function to update mentor rating after new review
CREATE OR REPLACE FUNCTION update_mentor_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    review_cnt INT;
BEGIN
    SELECT AVG(rating), COUNT(*)
    INTO avg_rating, review_cnt
    FROM mentorship_reviews
    WHERE reviewee_id = NEW.reviewee_id;

    UPDATE mentor_profiles
    SET rating_average = avg_rating,
        review_count = review_cnt
    WHERE user_id = NEW.reviewee_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_mentor_rating
    AFTER INSERT ON mentorship_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_mentor_rating();

-- Function to increment application count on job posting
CREATE OR REPLACE FUNCTION increment_job_application_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE job_postings
    SET application_count = application_count + 1
    WHERE id = NEW.job_posting_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increment_job_application_count
    AFTER INSERT ON job_applications
    FOR EACH ROW
    EXECUTE FUNCTION increment_job_application_count();

-- Function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
    p_user_id UUID,
    p_action TEXT,
    p_resource_type TEXT,
    p_resource_id UUID,
    p_metadata JSONB DEFAULT '{}'::jsonb,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO audit_logs (user_id, action, resource_type, resource_id, metadata, ip_address, user_agent)
    VALUES (p_user_id, p_action, p_resource_type, p_resource_id, p_metadata, p_ip_address, p_user_agent)
    RETURNING id INTO log_id;

    RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE users IS 'Core user accounts extending Supabase auth.users';
COMMENT ON TABLE trade_specializations IS 'Red Seal trade certifications catalog';
COMMENT ON TABLE subscriptions IS 'User subscription plans and billing';
COMMENT ON TABLE conversations IS 'Chat conversation sessions with Red AI';
COMMENT ON TABLE messages IS 'Individual messages within conversations';
COMMENT ON TABLE user_memories IS 'Mem0 persistent memory for AI context and learning profiles';
COMMENT ON TABLE mcp_servers IS 'Registry of MCP specialist agents';
COMMENT ON TABLE agent_coordination_sessions IS 'Tracks multi-agent coordination events';
COMMENT ON TABLE documents IS 'RAG document storage (NOA docs, manuals, uploads)';
COMMENT ON TABLE document_embeddings IS 'pgvector embeddings for semantic search';
COMMENT ON TABLE questions IS 'Exam question bank with AI generation tracking';
COMMENT ON TABLE exam_sessions IS 'Practice exam sessions with timing and scoring';
COMMENT ON TABLE learning_profiles IS 'User performance tracking and weak area analysis';
COMMENT ON TABLE mentor_profiles IS 'Verified mentor profiles for mentorship marketplace';
COMMENT ON TABLE mentorship_sessions IS 'Scheduled mentorship sessions';
COMMENT ON TABLE mentorship_reviews IS 'Mentor/mentee rating and review system';
COMMENT ON TABLE corporate_programs IS 'Corporate mentorship programs';
COMMENT ON TABLE employer_profiles IS 'Employer company profiles';
COMMENT ON TABLE candidate_pipeline IS 'Employer candidate tracking and recruiting';
COMMENT ON TABLE job_postings IS 'Job board postings';
COMMENT ON TABLE job_applications IS 'Job applications with AI matching';
COMMENT ON TABLE forum_topics IS 'Community forum discussion topics';
COMMENT ON TABLE forum_replies IS 'Replies to forum topics';
COMMENT ON TABLE ai_requests IS 'AI API usage tracking for billing and analytics';
COMMENT ON TABLE user_analytics IS 'Aggregated user activity metrics';
COMMENT ON TABLE audit_logs IS 'Security and compliance audit trail';

-- ============================================================================
-- SCHEMA MIGRATION COMPLETE
-- ============================================================================

-- Refresh materialized views (run after initial data seeding)
REFRESH MATERIALIZED VIEW user_conversation_stats;
REFRESH MATERIALIZED VIEW mentor_performance_stats;
REFRESH MATERIALIZED VIEW employer_recruiting_stats;

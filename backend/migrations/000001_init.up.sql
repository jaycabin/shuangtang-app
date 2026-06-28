-- 双糖 (DoubleSugar) 数据库初始化迁移
-- 使用 UUID 主键，合理索引

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "postgis"; -- 需要时取消注释，普通开发不需要

-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(100) NOT NULL DEFAULT '',
    avatar_url TEXT NOT NULL DEFAULT '',
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'zh',
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- 情侣关系表
CREATE TABLE couples (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES users(id) ON DELETE SET NULL,
    invitation_code VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'ended')),
    started_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_couples_user1_id ON couples(user1_id);
CREATE INDEX idx_couples_user2_id ON couples(user2_id);
CREATE INDEX idx_couples_invitation_code ON couples(invitation_code);
CREATE INDEX idx_couples_status ON couples(status);

-- 动态/瞬间表（撒糖）
CREATE TABLE moments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL DEFAULT 'moment' CHECK (type IN ('moment', 'anniversary', 'checkin', 'location')),
    content TEXT NOT NULL DEFAULT '',
    image_urls JSONB NOT NULL DEFAULT '[]',
    location JSONB,
    mood_tag VARCHAR(50) DEFAULT '',
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_moments_couple_id ON moments(couple_id);
CREATE INDEX idx_moments_couple_created ON moments(couple_id, created_at DESC);
CREATE INDEX idx_moments_author_id ON moments(author_id);

-- 纪念日表
CREATE TABLE anniversaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    title JSONB NOT NULL DEFAULT '{}',
    date DATE NOT NULL,
    is_recurring BOOLEAN NOT NULL DEFAULT TRUE,
    remind_before INTEGER NOT NULL DEFAULT 1,
    icon VARCHAR(50) NOT NULL DEFAULT '❤️',
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_anniversaries_couple ON anniversaries(couple_id);
CREATE INDEX idx_anniversaries_date ON anniversaries(date);

-- 打卡任务表
CREATE TABLE check_in_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    title JSONB NOT NULL DEFAULT '{}',
    icon VARCHAR(50) NOT NULL DEFAULT '✅',
    schedule_type VARCHAR(20) NOT NULL DEFAULT 'daily' CHECK (schedule_type IN ('daily', 'weekly', 'custom')),
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_checkin_tasks_couple ON check_in_tasks(couple_id);

-- 打卡记录表
CREATE TABLE check_in_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES check_in_tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    check_date DATE NOT NULL,
    done_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    note TEXT DEFAULT ''
);

CREATE INDEX idx_checkin_records_task ON check_in_records(task_id);
CREATE INDEX idx_checkin_records_user ON check_in_records(user_id);
CREATE INDEX idx_checkin_records_date ON check_in_records(check_date);
CREATE UNIQUE INDEX idx_checkin_records_unique ON check_in_records(task_id, user_id, check_date);

-- 愿望清单表
CREATE TABLE wishlist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title JSONB NOT NULL DEFAULT '{}',
    description TEXT NOT NULL DEFAULT '',
    image_url TEXT DEFAULT '',
    price DECIMAL(12,2),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'claimed', 'completed')),
    claimed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wishlist_couple ON wishlist_items(couple_id);
CREATE INDEX idx_wishlist_status ON wishlist_items(status);

-- 相册表
CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    uploader_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT DEFAULT '',
    taken_at TIMESTAMP WITH TIME ZONE,
    location JSONB,
    tags TEXT[] DEFAULT '{}',
    width INTEGER DEFAULT 0,
    height INTEGER DEFAULT 0,
    file_size INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_albums_couple ON albums(couple_id);
CREATE INDEX idx_albums_couple_created ON albums(couple_id, created_at DESC);

-- 悄悄话表
CREATE TABLE secret_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    encrypted_content TEXT NOT NULL DEFAULT '',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_secret_messages_couple ON secret_messages(couple_id);
CREATE INDEX idx_secret_messages_couple_created ON secret_messages(couple_id, created_at DESC);

-- 双糖闹钟表
CREATE TABLE alarms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    setter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    closer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    alarm_time TIMESTAMP WITH TIME ZONE NOT NULL,
    task_type VARCHAR(20) NOT NULL DEFAULT 'record' CHECK (task_type IN ('record', 'quiz', 'shake')),
    task_description TEXT DEFAULT '',
    audio_url TEXT DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'ringing', 'completed', 'missed')),
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alarms_couple ON alarms(couple_id);
CREATE INDEX idx_alarms_time ON alarms(alarm_time);

-- 系统配置表
CREATE TABLE system_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(255) NOT NULL UNIQUE,
    value TEXT NOT NULL DEFAULT '',
    description TEXT DEFAULT '',
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 翻译表（可选，用于管理后台动态管理多语言）
CREATE TABLE translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lang VARCHAR(10) NOT NULL,
    key VARCHAR(255) NOT NULL,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(lang, key)
);

CREATE INDEX idx_translations_lang ON translations(lang);

-- 通知表
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- 位置共享记录表
CREATE TABLE location_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    battery_level INTEGER DEFAULT 100,
    is_moving BOOLEAN NOT NULL DEFAULT FALSE,
    shared_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_location_shares_couple ON location_shares(couple_id, shared_at DESC);

-- 插入默认系统配置
INSERT INTO system_configs (key, value, description) VALUES
('app_name', '双糖', '应用名称'),
('app_logo_url', '', 'Logo URL'),
('file_storage', 'local', '文件存储策略：local 或 minio'),
('minio_endpoint', 'localhost:9000', 'MinIO 端点'),
('minio_access_key', '', 'MinIO 访问密钥'),
('minio_secret_key', '', 'MinIO 密钥'),
('minio_bucket', 'shuangtang', 'MinIO 存储桶'),
('smtp_host', '', 'SMTP 服务器'),
('smtp_port', '587', 'SMTP 端口'),
('smtp_user', '', 'SMTP 用户名'),
('smtp_pass', '', 'SMTP 密码'),
('smtp_from', 'noreply@shuangtang.app', '发件人邮箱'),
('admin_email', 'admin@shuangtang.app', '管理员邮箱');

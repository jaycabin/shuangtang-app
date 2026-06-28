-- 双糖 (DoubleSugar) Supabase Schema + Row Level Security
-- 核心原则：所有数据通过 couple_id + user_id 做 RLS 隔离

-- ========== EXTENSIONS ==========
create extension if not exists "uuid-ossp";

-- ========== AUTH (Supabase 内置) ==========
-- 使用 supabase.auth.users 作为用户基础
-- profiles 表扩展 auth.users 的信息

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text,
    nickname text not null default '',
    avatar_url text not null default '',
    preferred_language text not null default 'zh',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 注册时自动创建 profile
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email, nickname)
    values (new.id, new.email, split_part(new.email, '@', 1));
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- ========== COUPLES ==========
create table public.couples (
    id uuid primary key default uuid_generate_v4(),
    user1_id uuid not null references public.profiles(id) on delete cascade,
    user2_id uuid references public.profiles(id) on delete set null,
    invitation_code text not null unique,
    status text not null default 'pending' check (status in ('pending', 'active', 'ended')),
    started_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- ========== MOMENTS (时光轴) ==========
create table public.moments (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    author_id uuid not null references public.profiles(id) on delete cascade,
    type text not null default 'moment' check (type in ('moment', 'anniversary', 'checkin', 'location')),
    content text not null default '',
    image_urls jsonb not null default '[]',
    location jsonb,
    mood_tag text default '',
    is_pinned boolean not null default false,
    created_at timestamptz not null default now()
);

-- ========== ANNIVERSARIES (纪念日) ==========
create table public.anniversaries (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    title jsonb not null default '{}',
    date date not null,
    is_recurring boolean not null default true,
    remind_before int not null default 1,
    icon text not null default '❤️',
    created_by uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default now()
);

-- ========== CHECK-IN TASKS (打卡任务) ==========
create table public.check_in_tasks (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    title jsonb not null default '{}',
    icon text not null default '✅',
    schedule_type text not null default 'daily' check (schedule_type in ('daily', 'weekly', 'custom')),
    sort_order int not null default 0,
    is_active boolean not null default true,
    created_by uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default now()
);

create table public.check_in_records (
    id uuid primary key default uuid_generate_v4(),
    task_id uuid not null references public.check_in_tasks(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    check_date date not null,
    done_at timestamptz not null default now(),
    note text default '',
    unique(task_id, user_id, check_date)
);

-- ========== WISHLIST (愿望清单) ==========
create table public.wishlist_items (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    creator_id uuid not null references public.profiles(id) on delete cascade,
    title jsonb not null default '{}',
    description text not null default '',
    image_url text default '',
    price decimal(12,2),
    status text not null default 'pending' check (status in ('pending', 'claimed', 'completed')),
    claimed_by uuid references public.profiles(id) on delete set null,
    completed_at timestamptz,
    created_at timestamptz not null default now()
);

-- ========== ALBUMS (相册) ==========
create table public.albums (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    uploader_id uuid not null references public.profiles(id) on delete cascade,
    image_url text not null,
    thumbnail_url text default '',
    width int default 0,
    height int default 0,
    file_size int default 0,
    created_at timestamptz not null default now()
);

-- ========== SECRET MESSAGES (悄悄话) ==========
create table public.secret_messages (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    sender_id uuid not null references public.profiles(id) on delete cascade,
    content text not null,
    is_read boolean not null default false,
    read_at timestamptz,
    created_at timestamptz not null default now()
);

-- ========== ALARMS (闹钟) ==========
create table public.alarms (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    setter_id uuid not null references public.profiles(id) on delete cascade,
    closer_id uuid references public.profiles(id) on delete set null,
    alarm_time timestamptz not null,
    task_type text not null default 'record' check (task_type in ('record', 'quiz', 'shake')),
    task_description text default '',
    audio_url text default '',
    status text not null default 'pending' check (status in ('pending', 'ringing', 'completed', 'missed')),
    closed_at timestamptz,
    created_at timestamptz not null default now()
);

-- ========== LOCATIONS (位置共享) ==========
create table public.location_shares (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    latitude double precision not null,
    longitude double precision not null,
    battery_level int default 100,
    is_moving boolean not null default false,
    shared_at timestamptz not null default now()
);

-- ========== NOTIFICATIONS (通知) ==========
create table public.notifications (
    id uuid primary key default uuid_generate_v4(),
    couple_id uuid not null references public.couples(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    type text not null,
    title text not null,
    body text not null,
    metadata jsonb default '{}',
    is_read boolean not null default false,
    created_at timestamptz not null default now()
);

-- ========== INDEXES ==========
create index idx_couples_invitation_code on public.couples(invitation_code);
create index idx_couples_user1 on public.couples(user1_id);
create index idx_couples_user2 on public.couples(user2_id);
create index idx_moments_couple_created on public.moments(couple_id, created_at desc);
create index idx_anniversaries_couple on public.anniversaries(couple_id);
create index idx_anniversaries_date on public.anniversaries(date);
create index idx_checkin_records_task_date on public.check_in_records(task_id, check_date);
create index idx_wishlist_couple on public.wishlist_items(couple_id);
create index idx_albums_couple on public.albums(couple_id, created_at desc);
create index idx_secret_messages_couple on public.secret_messages(couple_id, created_at desc);
create index idx_alarms_couple on public.alarms(couple_id);
create index idx_notifications_user_unread on public.notifications(user_id, is_read) where is_read = false;
create index idx_location_shares_couple on public.location_shares(couple_id, shared_at desc);

-- ========== ROW LEVEL SECURITY ==========

-- 1. PROFILES — 每个人只能看/改自己的
alter table public.profiles enable row level security;

create policy "Users can view own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- 2. COUPLES — 创建者可读，只有 user1/user2 可见
alter table public.couples enable row level security;

create policy "Couple members can view their couple"
    on public.couples for select
    using (auth.uid() = user1_id or auth.uid() = user2_id);

create policy "User can create couple"
    on public.couples for insert
    with check (auth.uid() = user1_id);

create policy "User can join couple"
    on public.couples for update
    using (auth.uid() = user2_id and status = 'pending');

-- 3. MOMENTS — 情侣成员可见，作者可写
alter table public.moments enable row level security;

create policy "Couple members can view moments"
    on public.moments for select
    using (
        exists (
            select 1 from public.couples c
            where c.id = couple_id
            and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
        )
    );

create policy "Couple members can insert moments"
    on public.moments for insert
    with check (auth.uid() = author_id);

-- 4. ANNIVERSARIES
alter table public.anniversaries enable row level security;

create policy "Couple members can view anniversaries"
    on public.anniversaries for select
    using (
        exists (
            select 1 from public.couples c
            where c.id = couple_id
            and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
        )
    );

create policy "Couple members can create anniversaries"
    on public.anniversaries for insert
    with check (auth.uid() = created_by);

-- 5. CHECK-IN TASKS + RECORDS
alter table public.check_in_tasks enable row level security;
alter table public.check_in_records enable row level security;

create policy "Couple members can view tasks"
    on public.check_in_tasks for select
    using (
        exists (select 1 from public.couples c where c.id = couple_id and (c.user1_id = auth.uid() or c.user2_id = auth.uid()))
    );

create policy "Couple members can view records"
    on public.check_in_records for select
    using (
        exists (select 1 from public.check_in_tasks t
            join public.couples c on c.id = t.couple_id
            where t.id = task_id and (c.user1_id = auth.uid() or c.user2_id = auth.uid()))
    );

create policy "Users can insert own records"
    on public.check_in_records for insert
    with check (auth.uid() = user_id);

-- 6. WISHLIST
alter table public.wishlist_items enable row level security;

create policy "Couple members can view wishes"
    on public.wishlist_items for select
    using (
        exists (select 1 from public.couples c where c.id = couple_id and (c.user1_id = auth.uid() or c.user2_id = auth.uid()))
    );

create policy "Users can create wishes"
    on public.wishlist_items for insert
    with check (auth.uid() = creator_id);

-- 7. ALBUMS
alter table public.albums enable row level security;

create policy "Couple members can view albums"
    on public.albums for select
    using (
        exists (select 1 from public.couples c where c.id = couple_id and (c.user1_id = auth.uid() or c.user2_id = auth.uid()))
    );

create policy "Couple members can upload"
    on public.albums for insert
    with check (auth.uid() = uploader_id);

-- 8. SECRET MESSAGES
alter table public.secret_messages enable row level security;

create policy "Couple members can view messages"
    on public.secret_messages for select
    using (
        exists (select 1 from public.couples c where c.id = couple_id and (c.user1_id = auth.uid() or c.user2_id = auth.uid()))
    );

create policy "Users can send messages"
    on public.secret_messages for insert
    with check (auth.uid() = sender_id);

-- 9. ALARMS
alter table public.alarms enable row level security;

create policy "Couple members can view alarms"
    on public.alarms for select
    using (
        exists (select 1 from public.couples c where c.id = couple_id and (c.user1_id = auth.uid() or c.user2_id = auth.uid()))
    );

-- 10. LOCATIONS
alter table public.location_shares enable row level security;

create policy "Couple members can view locations"
    on public.location_shares for select
    using (
        exists (select 1 from public.couples c where c.id = couple_id and (c.user1_id = auth.uid() or c.user2_id = auth.uid()))
    );

create policy "Users can share own location"
    on public.location_shares for insert
    with check (auth.uid() = user_id);

-- 11. NOTIFICATIONS
alter table public.notifications enable row level security;

create policy "Users can view own notifications"
    on public.notifications for select
    using (auth.uid() = user_id);

create policy "Users can update own notifications"
    on public.notifications for update
    using (auth.uid() = user_id);

-- ========== FUNCTIONS ==========

-- 生成邀请码
create or replace function public.generate_invitation_code()
returns text as $$
declare
    chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result text := '';
    i int := 0;
begin
    for i in 1..8 loop
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    end loop;
    return result;
end;
$$ language plpgsql;

-- 创建情侣空间
create or replace function public.create_couple()
returns uuid as $$
declare
    couple_id uuid;
    code text;
begin
    code := public.generate_invitation_code();
    insert into public.couples (id, user1_id, invitation_code)
    values (uuid_generate_v4(), auth.uid(), code)
    returning id into couple_id;
    return couple_id;
end;
$$ language plpgsql security definer;

-- 加入情侣空间
create or replace function public.join_couple(code text)
returns boolean as $$
begin
    update public.couples
    set user2_id = auth.uid(), status = 'active', started_at = now(), updated_at = now()
    where invitation_code = code and status = 'pending';
    return found;
end;
$$ language plpgsql security definer;

-- 获取伴侣信息
create or replace function public.get_partner()
returns table (id uuid, nickname text, avatar_url text) as $$
begin
    return query
    select p.id, p.nickname, p.avatar_url
    from public.couples c
    join public.profiles p on p.id = case when c.user1_id = auth.uid() then c.user2_id else c.user1_id end
    where (c.user1_id = auth.uid() or c.user2_id = auth.uid()) and c.status = 'active';
end;
$$ language plpgsql security definer;

-- ========== DEFAULT DATA (预设打卡任务) ==========
insert into public.check_in_tasks (couple_id, title, icon, schedule_type, sort_order, created_by) values
    ('00000000-0000-0000-0000-000000000001', '{"zh": "说早安", "en": "Say Good Morning"}', '🌅', 'daily', 1, '00000000-0000-0000-0000-000000000001'),
    ('00000000-0000-0000-0000-000000000001', '{"zh": "一次拥抱", "en": "A Hug"}', '🤗', 'daily', 2, '00000000-0000-0000-0000-000000000001'),
    ('00000000-0000-0000-0000-000000000001', '{"zh": "一起看日落", "en": "Watch Sunset"}', '🌇', 'daily', 3, '00000000-0000-0000-0000-000000000001');
-- 注：默认任务的 couple_id 和 created_by 用占位，实际会在 seed 时替换

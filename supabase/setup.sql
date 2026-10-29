-- Arab Chat - Supabase Setup (مرة واحدة فقط)

-- 1. تفعيل الإضافات
create extension if not exists "uuid-ossp";

-- 2. جدول البروفايلات
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  avatar_url text,
  bio text,
  gender text,
  country text,
  is_verified boolean default false,
  is_online boolean default false,
  last_seen timestamp with time zone default now(),
  coins int default 0,
  created_at timestamp with time zone default now()
);

-- 3. جدول الرسائل الخاصة
create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  sender_id uuid references public.profiles(id) on delete cascade,
  receiver_id uuid references public.profiles(id) on delete cascade,
  content text,
  image_url text,
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

-- 4. جدول الغرف الصوتية
create table if not exists public.voice_rooms (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  owner_id uuid references public.profiles(id),
  country text,
  max_users int default 12,
  is_private boolean default false,
  created_at timestamp with time zone default now()
);

-- 5. جدول أعضاء الغرفة
create table if not exists public.room_members (
  room_id uuid references public.voice_rooms(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text default 'member',
  joined_at timestamp with time zone default now(),
  primary key (room_id, user_id)
);

-- 6. جدول البث المباشر
create table if not exists public.live_streams (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id) on delete cascade,
  title text,
  is_live boolean default true,
  viewers int default 0,
  likes int default 0,
  started_at timestamp with time zone default now(),
  ended_at timestamp with time zone
);

-- 7. جدول المتابعات
create table if not exists public.follows (
  follower_id uuid references public.profiles(id) on delete cascade,
  following_id uuid references public.profiles(id) on delete cascade,
  created_at timestamp with time zone default now(),
  primary key (follower_id, following_id)
);

-- 8. جدول KV للتطبيق الحالي
create table if not exists public.kv (
  key text primary key,
  value jsonb,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 9. تفعيل RLS
alter table public.profiles enable row level security;
alter table public.messages enable row level security;
alter table public.voice_rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.live_streams enable row level security;
alter table public.follows enable row level security;
alter table public.kv enable row level security;

-- 10. سياسات مفتوحة للتجربة
drop policy if exists "Allow all for profiles" on public.profiles;
create policy "Allow all for profiles" on public.profiles for all using (true) with check (true);
drop policy if exists "Allow all for messages" on public.messages;
create policy "Allow all for messages" on public.messages for all using (true) with check (true);
drop policy if exists "Allow all for voice_rooms" on public.voice_rooms;
create policy "Allow all for voice_rooms" on public.voice_rooms for all using (true) with check (true);
drop policy if exists "Allow all for room_members" on public.room_members;
create policy "Allow all for room_members" on public.room_members for all using (true) with check (true);
drop policy if exists "Allow all for live_streams" on public.live_streams;
create policy "Allow all for live_streams" on public.live_streams for all using (true) with check (true);
drop policy if exists "Allow all for follows" on public.follows;
create policy "Allow all for follows" on public.follows for all using (true) with check (true);
drop policy if exists "Allow all for kv" on public.kv;
create policy "Allow all for kv" on public.kv for all using (true) with check (true);

-- 11. إنشاء بروفايل تلقائي عند التسجيل
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

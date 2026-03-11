-- Run this in Supabase SQL Editor for project: zmtytwilsdpcpzbhjeac

create extension if not exists "pgcrypto" with schema extensions;

insert into storage.buckets (id, name, public)
values ('notenest-uploads', 'notenest-uploads', false)
on conflict (id) do nothing;

create table if not exists public.student_users (
  id uuid primary key default gen_random_uuid(),
  username text not null,
  phone text not null,
  college text not null,
  password_hash text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists student_users_username_unique_idx
  on public.student_users (lower(username));

create unique index if not exists student_users_phone_unique_idx
  on public.student_users (phone);

alter table public.student_users enable row level security;

drop policy if exists "student_users_no_direct_access" on public.student_users;

-- Block direct table access; app uses security-definer RPCs below.
create policy "student_users_no_direct_access"
  on public.student_users
  for all
  to public
  using (false)
  with check (false);

create or replace function public.register_student_user(
  p_username text,
  p_phone text,
  p_college text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  clean_username text := btrim(p_username);
  clean_phone text := btrim(p_phone);
  clean_college text := btrim(p_college);
  created_row public.student_users%rowtype;
begin
  if clean_username = '' or clean_phone = '' or clean_college = '' or btrim(p_password) = '' then
    raise exception 'Please fill all fields.';
  end if;

  if clean_phone !~ '^\d{10}$' then
    raise exception 'Phone must be 10 digits.';
  end if;

  if length(p_password) < 6 then
    raise exception 'Password must be at least 6 characters.';
  end if;

  if exists (
    select 1
    from public.student_users su
    where lower(su.username) = lower(clean_username)
       or su.phone = clean_phone
  ) then
    raise exception 'User with same name or phone already exists.';
  end if;

  insert into public.student_users (username, phone, college, password_hash)
  values (
    clean_username,
    clean_phone,
    clean_college,
    extensions.crypt(p_password, extensions.gen_salt('bf'))
  )
  returning * into created_row;

  return jsonb_build_object(
    'id', created_row.id,
    'username', created_row.username,
    'phone', created_row.phone,
    'college', created_row.college
  );
end;
$$;

create or replace function public.login_student_user(
  p_identifier text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  clean_id text := btrim(p_identifier);
  found_user public.student_users%rowtype;
begin
  if clean_id = '' or btrim(p_password) = '' then
    raise exception 'Enter name/phone and password.';
  end if;

  select *
  into found_user
  from public.student_users su
  where su.phone = clean_id or lower(su.username) = lower(clean_id)
  limit 1;

  if found_user.id is null then
    raise exception 'User not found. Please sign up first.';
  end if;

  if found_user.password_hash <> extensions.crypt(p_password, found_user.password_hash) then
    raise exception 'Incorrect password.';
  end if;

  return jsonb_build_object(
    'id', found_user.id,
    'username', found_user.username,
    'phone', found_user.phone,
    'college', found_user.college
  );
end;
$$;

create or replace function public.change_student_password(
  p_user_id uuid,
  p_current_password text,
  p_new_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  found_user public.student_users%rowtype;
begin
  if p_user_id is null then
    raise exception 'User not found.';
  end if;

  if btrim(coalesce(p_current_password, '')) = '' or btrim(coalesce(p_new_password, '')) = '' then
    raise exception 'Enter current and new password.';
  end if;

  if length(p_new_password) < 6 then
    raise exception 'New password must be at least 6 characters.';
  end if;

  select *
  into found_user
  from public.student_users su
  where su.id = p_user_id
  limit 1;

  if found_user.id is null then
    raise exception 'User not found.';
  end if;

  if found_user.password_hash <> extensions.crypt(p_current_password, found_user.password_hash) then
    raise exception 'Current password is incorrect.';
  end if;

  update public.student_users
  set password_hash = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
  where id = p_user_id;
end;
$$;

create or replace function public.update_student_account(
  p_user_id uuid,
  p_username text,
  p_phone text,
  p_college text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_username text := btrim(coalesce(p_username, ''));
  clean_phone text := btrim(coalesce(p_phone, ''));
  clean_college text := btrim(coalesce(p_college, ''));
begin
  if p_user_id is null then
    raise exception 'User not found.';
  end if;

  if clean_username = '' or clean_phone = '' or clean_college = '' then
    raise exception 'Please fill all fields.';
  end if;

  if clean_phone !~ '^\d{10}$' then
    raise exception 'Phone must be 10 digits.';
  end if;

  if exists (
    select 1
    from public.student_users su
    where su.id <> p_user_id
      and (lower(su.username) = lower(clean_username) or su.phone = clean_phone)
  ) then
    raise exception 'User with same name or phone already exists.';
  end if;

  update public.student_users
  set username = clean_username,
      phone = clean_phone,
      college = clean_college
  where id = p_user_id;
end;
$$;

revoke all on table public.student_users from anon, authenticated;
revoke all on function public.register_student_user(text, text, text, text) from public;
revoke all on function public.login_student_user(text, text) from public;
revoke all on function public.change_student_password(uuid, text, text) from public;
revoke all on function public.update_student_account(uuid, text, text, text) from public;

grant execute on function public.register_student_user(text, text, text, text) to anon, authenticated;
grant execute on function public.login_student_user(text, text) to anon, authenticated;
grant execute on function public.change_student_password(uuid, text, text) to anon, authenticated;
grant execute on function public.update_student_account(uuid, text, text, text) to anon, authenticated;

create table if not exists public.user_profiles (
  user_id uuid primary key references public.student_users(id) on delete cascade,
  bio text not null default 'Focused on smart revision',
  emoji text not null default '🤓',
  unique_id text not null unique,
  avatar_path text,
  additional_note text not null default '',
  extra_fields jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table if exists public.user_profiles
  add column if not exists avatar_path text;

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.student_users(id) on delete cascade,
  name text not null,
  subject text not null,
  year text not null,
  type text not null,
  keywords text not null default '',
  file_path text not null,
  file_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.url_folders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.student_users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.url_subfolders (
  id uuid primary key default gen_random_uuid(),
  folder_id uuid not null references public.url_folders(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.saved_urls (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.student_users(id) on delete cascade,
  folder_id uuid not null references public.url_folders(id) on delete cascade,
  subfolder_id uuid references public.url_subfolders(id) on delete set null,
  url text not null,
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.study_groups (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.student_users(id) on delete cascade,
  name text not null,
  photo_path text,
  created_at timestamptz not null default now()
);

alter table if exists public.study_groups
  add column if not exists photo_path text;

create table if not exists public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.study_groups(id) on delete cascade,
  name text not null,
  unique_id text not null,
  added_at timestamptz not null default now()
);

create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.study_groups(id) on delete cascade,
  sender_unique_id text not null,
  content text not null,
  is_mine boolean not null default false,
  attachment_name text,
  attachment_ref text,
  attachment_type text,
  sent_at timestamptz not null default now()
);

create table if not exists public.group_attachments (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.study_groups(id) on delete cascade,
  file_name text not null,
  file_ref text not null,
  file_type text not null,
  sent_by text not null,
  sent_at timestamptz not null default now()
);

create table if not exists public.direct_chats (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.student_users(id) on delete cascade,
  target_unique_id text not null,
  target_name text,
  created_at timestamptz not null default now()
);

create unique index if not exists direct_chats_owner_target_unique_idx
  on public.direct_chats (owner_user_id, target_unique_id);

create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.direct_chats(id) on delete cascade,
  sender_unique_id text not null,
  content text not null,
  is_mine boolean not null default false,
  attachment_name text,
  attachment_ref text,
  attachment_type text,
  sent_at timestamptz not null default now()
);

alter table public.user_profiles enable row level security;
alter table public.notes enable row level security;
alter table public.url_folders enable row level security;
alter table public.url_subfolders enable row level security;
alter table public.saved_urls enable row level security;
alter table public.study_groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_messages enable row level security;
alter table public.group_attachments enable row level security;
alter table public.direct_chats enable row level security;
alter table public.direct_messages enable row level security;

drop policy if exists "user_profiles_owner_all" on public.user_profiles;
create policy "user_profiles_owner_all"
  on public.user_profiles
  for all
  to anon, authenticated
  using (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id))
  with check (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id));

drop policy if exists "notes_owner_all" on public.notes;
create policy "notes_owner_all"
  on public.notes
  for all
  to anon, authenticated
  using (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id))
  with check (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id));

drop policy if exists "url_folders_owner_all" on public.url_folders;
create policy "url_folders_owner_all"
  on public.url_folders
  for all
  to anon, authenticated
  using (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id))
  with check (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id));

drop policy if exists "url_subfolders_owner_all" on public.url_subfolders;
create policy "url_subfolders_owner_all"
  on public.url_subfolders
  for all
  to anon, authenticated
  using (
    exists (
      select 1 from public.url_folders f
      where f.id = folder_id
    )
  )
  with check (
    exists (
      select 1 from public.url_folders f
      where f.id = folder_id
    )
  );

drop policy if exists "saved_urls_owner_all" on public.saved_urls;
create policy "saved_urls_owner_all"
  on public.saved_urls
  for all
  to anon, authenticated
  using (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id))
  with check (user_id = coalesce((auth.jwt() ->> 'sub')::uuid, user_id));

drop policy if exists "study_groups_owner_all" on public.study_groups;
create policy "study_groups_owner_all"
  on public.study_groups
  for all
  to anon, authenticated
  using (owner_user_id = coalesce((auth.jwt() ->> 'sub')::uuid, owner_user_id))
  with check (owner_user_id = coalesce((auth.jwt() ->> 'sub')::uuid, owner_user_id));

drop policy if exists "group_members_owner_all" on public.group_members;
create policy "group_members_owner_all"
  on public.group_members
  for all
  to anon, authenticated
  using (
    exists (
      select 1 from public.study_groups g
      where g.id = group_id
    )
  )
  with check (
    exists (
      select 1 from public.study_groups g
      where g.id = group_id
    )
  );

drop policy if exists "group_messages_owner_all" on public.group_messages;
create policy "group_messages_owner_all"
  on public.group_messages
  for all
  to anon, authenticated
  using (
    exists (
      select 1 from public.study_groups g
      where g.id = group_id
    )
  )
  with check (
    exists (
      select 1 from public.study_groups g
      where g.id = group_id
    )
  );

drop policy if exists "group_attachments_owner_all" on public.group_attachments;
create policy "group_attachments_owner_all"
  on public.group_attachments
  for all
  to anon, authenticated
  using (
    exists (
      select 1 from public.study_groups g
      where g.id = group_id
    )
  )
  with check (
    exists (
      select 1 from public.study_groups g
      where g.id = group_id
    )
  );

drop policy if exists "direct_chats_owner_all" on public.direct_chats;
create policy "direct_chats_owner_all"
  on public.direct_chats
  for all
  to anon, authenticated
  using (owner_user_id = coalesce((auth.jwt() ->> 'sub')::uuid, owner_user_id))
  with check (owner_user_id = coalesce((auth.jwt() ->> 'sub')::uuid, owner_user_id));

drop policy if exists "direct_messages_owner_all" on public.direct_messages;
create policy "direct_messages_owner_all"
  on public.direct_messages
  for all
  to anon, authenticated
  using (
    exists (
      select 1 from public.direct_chats c
      where c.id = chat_id
    )
  )
  with check (
    exists (
      select 1 from public.direct_chats c
      where c.id = chat_id
    )
  );

drop policy if exists "storage_note_files_access" on storage.objects;
drop policy if exists "storage_upload_insert" on storage.objects;
drop policy if exists "storage_upload_select" on storage.objects;
drop policy if exists "storage_upload_update" on storage.objects;
drop policy if exists "storage_upload_delete" on storage.objects;
create policy "storage_note_files_access"
  on storage.objects
  for all
  to anon, authenticated
  using (bucket_id = 'notenest-uploads')
  with check (bucket_id = 'notenest-uploads');

create policy "storage_upload_insert"
  on storage.objects
  for insert
  to anon, authenticated
  with check (bucket_id = 'notenest-uploads');

create policy "storage_upload_select"
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'notenest-uploads');

create policy "storage_upload_update"
  on storage.objects
  for update
  to anon, authenticated
  using (bucket_id = 'notenest-uploads')
  with check (bucket_id = 'notenest-uploads');

create policy "storage_upload_delete"
  on storage.objects
  for delete
  to anon, authenticated
  using (bucket_id = 'notenest-uploads');

create or replace function public.ensure_default_user_profile(
  p_user_id uuid,
  p_user_name text,
  p_seed text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  generated_unique_id text;
begin
  generated_unique_id := 'NN-' || upper(substr(md5(coalesce(p_seed, gen_random_uuid()::text)), 1, 6));

  insert into public.user_profiles (
    user_id,
    bio,
    emoji,
    unique_id,
    additional_note,
    extra_fields
  )
  values (
    p_user_id,
    'Focused on smart revision',
    '🤓',
    generated_unique_id,
    'Semester 6',
    jsonb_build_array(jsonb_build_object('label', 'College', 'value', p_user_name))
  )
  on conflict (user_id) do nothing;
end;
$$;

revoke all on function public.ensure_default_user_profile(uuid, text, text) from public;
grant execute on function public.ensure_default_user_profile(uuid, text, text) to anon, authenticated;

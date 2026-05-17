-- Kontent Zavod — Supabase schema
-- Postgres 15+. Run as a single migration.
-- All identifiers are snake_case. All times are timestamptz.

create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- ---------- service enums ----------
create type service_code as enum (
  'MOW','OVR','CLR','STM','TRE','POO','MNT','RNT','PLW','CLN','OTHER'
);

create type cam_code as enum ('A','B','C','D');         -- phone-wide, phone-hand, drone, action
create type clip_status as enum (
  'ingested','classified','candidates_ready','rendered','rejected','duplicate'
);
create type post_status as enum (
  'pending','approved','auto_ok','rejected','published','failed','archived'
);
create type platform as enum ('TT','IG','YT','FB');
create type viral_label as enum ('dud','ok','hit','viral','mega','unknown');

-- ---------- jobs ----------
create table jobs (
  job_id           text primary key,            -- 20260517-MOW-03
  service          service_code not null,
  address          text,
  city             text,
  region           text,
  geo_lat          numeric,
  geo_lng          numeric,
  scheduled_for    date,
  started_at       timestamptz,
  finished_at      timestamptz,
  hours_total      numeric,
  workers_count    int,
  customer_name    text,
  customer_phone   text,
  customer_consent boolean default false,
  notes            text,
  created_at       timestamptz default now()
);

create index jobs_service_idx on jobs(service);
create index jobs_city_idx on jobs(city);

-- ---------- clips ----------
create table clips (
  clip_id           text primary key,           -- 20260517-MOW-03-A-001
  job_id            text references jobs(job_id) on delete cascade,
  cam               cam_code not null,
  shot_seq          int not null,
  storage_key       text not null,              -- R2 key
  duration_s        numeric not null,
  width             int,
  height            int,
  fps               numeric,
  codec             text,
  sha256_head       text,
  status            clip_status default 'ingested',
  classification    jsonb,                      -- Gemini Vision output
  transcript        text,
  srt               text,
  slate_address     text,
  slate_service     service_code,
  slate_phase       text,
  ingested_at       timestamptz default now(),
  classified_at     timestamptz,
  unique (job_id, cam, shot_seq)
);

create index clips_job_idx on clips(job_id);
create index clips_status_idx on clips(status);
create index clips_classification_gin on clips using gin (classification);

-- ---------- candidates ----------
create table candidates (
  candidate_id     uuid primary key default uuid_generate_v4(),
  clip_id          text references clips(clip_id) on delete cascade,
  start_s          numeric not null,
  end_s            numeric not null,
  kind             text not null,               -- transformation_reveal, asmr_loop, ...
  template         text not null,               -- T01..T08
  viral_score      int not null,                -- 0..100
  score_breakdown  jsonb,
  weaknesses       text[],
  hooks            jsonb not null,              -- [{hook_id, hook_text, predicted_ret}]
  captions         jsonb not null,              -- per platform pack
  created_at       timestamptz default now()
);

create index candidates_clip_idx on candidates(clip_id);
create index candidates_score_idx on candidates(viral_score desc);

-- ---------- hooks bank ----------
create table hooks (
  hook_id          text primary key,            -- H001 ... H100 (and Hxxx for drafts)
  category         text not null,
  service_tags     service_code[] not null,
  triggers         text[] not null,             -- contrast, curiosity, ...
  text_en          text not null,
  text_ru          text,
  slots            text[],                       -- e.g. ARRAY['N','HOURS','CITY']
  status           text default 'active',       -- active | retired | promoted | draft
  uses_count       int default 0,
  avg_ret_3s       numeric,
  avg_completion   numeric,
  avg_velocity_pct numeric,
  last_used_at     timestamptz,
  cooling_until    timestamptz,
  created_at       timestamptz default now()
);

create index hooks_status_idx on hooks(status);
create index hooks_service_tags_gin on hooks using gin (service_tags);

-- ---------- templates performance ----------
create table template_stats (
  template         text not null,
  service          service_code not null,
  platform         platform not null,
  n_posts          int default 0,
  avg_velocity_pct numeric,
  avg_completion   numeric,
  avg_ret_3s       numeric,
  updated_at       timestamptz default now(),
  primary key (template, service, platform)
);

-- ---------- posts ----------
create table posts (
  post_id          text primary key,            -- 20260517-MOW-03-A-001-TT-v2
  candidate_id     uuid references candidates(candidate_id) on delete set null,
  clip_id          text references clips(clip_id) on delete cascade,
  job_id           text references jobs(job_id) on delete cascade,
  service          service_code,
  template         text,
  hook_id          text references hooks(hook_id),
  hook_text        text,
  platform         platform not null,
  variant          text not null,               -- v1, v2, ...
  asset_url        text not null,
  cover_url        text,
  caption          text,
  hashtags         text[],
  cta_strategy     text,
  scheduled_at     timestamptz,
  published_at     timestamptz,
  external_id      text,                        -- platform's post id
  status           post_status default 'pending',
  viral_score_pre  int,
  viral_label      viral_label default 'unknown',
  viral_velocity   numeric,
  recycle          text,                        -- null | archived | cloning | cloned
  manual           boolean default false,
  notes            text,
  created_at       timestamptz default now(),
  unique (clip_id, platform, variant)
);

create index posts_status_idx on posts(status);
create index posts_platform_idx on posts(platform);
create index posts_scheduled_idx on posts(scheduled_at);
create index posts_label_idx on posts(viral_label);

-- ---------- metrics ----------
create table metrics (
  metric_id        uuid primary key default uuid_generate_v4(),
  post_id          text references posts(post_id) on delete cascade,
  scheduled_for    timestamptz not null,        -- when this poll was supposed to happen
  captured_at      timestamptz,                 -- actually captured
  hours_since      numeric,
  views            bigint,
  likes            bigint,
  comments         bigint,
  shares           bigint,
  saves            bigint,
  avg_watch_time   numeric,
  completion_rate  numeric,
  ret_3s           numeric,
  ret_10s          numeric,
  ret_25s          numeric,
  profile_visits   bigint,
  link_clicks      bigint
);

create index metrics_post_idx on metrics(post_id);
create index metrics_due_idx on metrics(captured_at, scheduled_for);

-- ---------- funnel events ----------
create table funnel_events (
  event_id         uuid primary key default uuid_generate_v4(),
  ts               timestamptz default now(),
  platform         platform,
  post_id          text,
  event_type       text not null,               -- bio_click | bot_start | sub | quote_start | quote_done | lead | booked
  user_hash        text,
  username         text,
  utm_source       text,
  utm_medium       text,
  utm_campaign     text,
  metadata         jsonb
);

create index funnel_ts_idx on funnel_events(ts);
create index funnel_event_type_idx on funnel_events(event_type);

-- ---------- leads ----------
create table leads (
  lead_id          uuid primary key default uuid_generate_v4(),
  user_id          text,                        -- telegram user id (hashed)
  username         text,
  source_platform  platform,
  source_post_id   text references posts(post_id),
  service          service_code,
  address          text,
  timeframe        text,
  notes            text,
  lead_score       int,
  status           text default 'new',          -- new | contacted | quoted | booked | completed | no_show | cancelled | reviewed
  quoted_price     numeric,
  booked_for       date,
  completed_at     timestamptz,
  created_at       timestamptz default now()
);

create index leads_status_idx on leads(status);
create index leads_created_idx on leads(created_at);

-- ---------- workflow runs ----------
create table workflow_runs (
  run_id           uuid primary key default uuid_generate_v4(),
  workflow         text not null,
  entity_id        text,
  started_at       timestamptz default now(),
  finished_at      timestamptz,
  status           text default 'running',      -- running | done | error
  cost_usd         numeric,
  error_text       text
);

create index runs_wf_idx on workflow_runs(workflow, status);

-- ---------- llm calls ----------
create table llm_calls (
  call_id          uuid primary key default uuid_generate_v4(),
  run_id           uuid references workflow_runs(run_id),
  provider         text not null,               -- openai | anthropic | google
  model            text not null,
  prompt_tokens    int,
  completion_tokens int,
  latency_ms       int,
  cost_usd         numeric,
  workflow         text,
  entity_id        text,
  ok               boolean default true,
  error_text       text,
  ts               timestamptz default now()
);

create index llm_ts_idx on llm_calls(ts);
create index llm_provider_idx on llm_calls(provider, model);

-- ---------- category targets / actuals ----------
create table category_targets (
  category         text primary key,            -- C1..C12
  target_pct       numeric not null
);

create table category_actuals (
  category         text not null,
  platform         platform not null,
  rolling_window   text not null,               -- '14d'
  actual_pct       numeric not null,
  updated_at       timestamptz default now(),
  primary key (category, platform, rolling_window)
);

-- ---------- system state ----------
create table system_state (
  key              text primary key,
  value            jsonb,
  updated_at       timestamptz default now()
);

insert into system_state (key, value) values
  ('paused', 'false'::jsonb),
  ('mode',   '"standard"'::jsonb),
  ('version','"1.0.0"'::jsonb)
on conflict (key) do nothing;

-- ---------- baseline / thresholds ----------
create table viral_thresholds (
  platform         platform primary key,
  dud_ceiling      bigint,
  ok_ceiling       bigint,
  hit_ceiling      bigint,
  viral_ceiling    bigint,
  mega_floor       bigint,
  updated_at       timestamptz default now()
);

insert into viral_thresholds (platform, dud_ceiling, ok_ceiling, hit_ceiling, viral_ceiling, mega_floor)
values
  ('TT',  500,  5000,  50000,  500000, 500000),
  ('IG',  300,  3000,  30000,  300000, 300000),
  ('YT',  400,  4000,  40000,  400000, 400000),
  ('FB',  300,  3000,  30000,  300000, 300000)
on conflict (platform) do nothing;

-- ---------- consents ----------
create table consents (
  consent_id       uuid primary key default uuid_generate_v4(),
  job_id           text references jobs(job_id) on delete cascade,
  person_name      text,
  granted_at       timestamptz default now(),
  signed_image_url text,
  audio_clip_url   text,
  notes            text
);

-- ---------- trending sounds / hashtags ----------
create table trending_sounds (
  id               uuid primary key default uuid_generate_v4(),
  platform         platform not null,
  external_ref     text not null,
  title            text,
  weekly_score     int,
  added_at         timestamptz default now()
);

create table trending_hashtags (
  id               uuid primary key default uuid_generate_v4(),
  platform         platform not null,
  tag              text not null,
  weekly_score     int,
  region           text,
  added_at         timestamptz default now()
);

-- ---------- seasonal triggers ----------
create table seasonal_triggers (
  id               uuid primary key default uuid_generate_v4(),
  trigger_name     text not null,
  active_from      date,
  active_to        date,
  service_codes    service_code[],
  recommended_hooks text[],
  notes            text
);

-- ---------- views ----------

-- Latest metric snapshot per post
create or replace view v_latest_metrics as
select distinct on (post_id)
  post_id, captured_at, hours_since,
  views, likes, comments, shares, saves,
  completion_rate, ret_3s, ret_10s
from metrics
where captured_at is not null
order by post_id, captured_at desc;

-- 24h post performance summary
create or replace view v_post_24h as
select p.*,
       lm.views as views_latest,
       lm.completion_rate as completion_latest,
       lm.ret_3s as ret_3s_latest,
       lm.captured_at as last_capture
from posts p
left join v_latest_metrics lm on lm.post_id = p.post_id;

-- ---------- row level security stubs ----------
-- Enable in production. Out-of-the-box, Supabase service role bypasses RLS.

alter table jobs enable row level security;
alter table clips enable row level security;
alter table candidates enable row level security;
alter table posts enable row level security;
alter table metrics enable row level security;
alter table leads enable row level security;
alter table funnel_events enable row level security;

-- ---------- seed: hooks bank (sample) ----------
-- Populate the rest via a CSV import from docs/06-hooks.md
insert into hooks (hook_id, category, service_tags, triggers, text_en, text_ru, slots, status)
values
  ('H001','abandoned',ARRAY['OVR','CLR','MNT']::service_code[],ARRAY['curiosity','scale'],
   'Nobody had touched this yard in {N} years.','На этом участке никто не был {N} лет.',ARRAY['N'],'active'),
  ('H011','grass',ARRAY['MOW','OVR']::service_code[],ARRAY['contrast','scale','mastery'],
   '{HEIGHT}-meter grass in {HOURS} hours. Watch.','{HEIGHT}-метровая трава за {HOURS} часов. Смотри.',
   ARRAY['HEIGHT','HOURS'],'active'),
  ('H062','pool',ARRAY['POO']::service_code[],ARRAY['curiosity','shock'],
   'The water was BLACK.','Вода была ЧЁРНАЯ.',ARRAY[]::text[],'active')
on conflict (hook_id) do nothing;

-- ---------- seed: category targets ----------
insert into category_targets (category, target_pct) values
  ('C1',0.25),('C2',0.15),('C3',0.10),('C4',0.10),
  ('C5',0.08),('C6',0.08),('C7',0.07),('C8',0.07),
  ('C9',0.05),('C10',0.03),('C11',0.01),('C12',0.01)
on conflict (category) do nothing;

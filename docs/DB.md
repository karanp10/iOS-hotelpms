rooms

create table public.rooms (
  id uuid not null default gen_random_uuid (),
  hotel_id uuid not null,
  room_number integer not null,
  floor_number integer not null,
  occupancy_status text not null default 'vacant'::text,
  cleaning_status text not null default 'dirty'::text,
  flags text[] not null default '{}'::text[],
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  updated_by uuid null,
  constraint rooms_pkey primary key (id),
  constraint unique_room_per_hotel unique (hotel_id, room_number),
  constraint rooms_hotel_id_fkey foreign KEY (hotel_id) references hotels (id) on delete CASCADE,
  constraint rooms_updated_by_fkey foreign KEY (updated_by) references profiles (id),
  constraint rooms_cleaning_status_check check (
    (
      cleaning_status = any (
        array[
          'dirty'::text,
          'cleaning_in_progress'::text,
          'ready'::text
        ]
      )
    )
  ),
  constraint rooms_occupancy_status_check check (
    (
      occupancy_status = any (
        array[
          'vacant'::text,
          'assigned'::text,
          'occupied'::text,
          'stayover'::text,
          'checked_out'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_rooms_hotel_id on public.rooms using btree (hotel_id) TABLESPACE pg_default;

create index IF not exists idx_rooms_hotel_room on public.rooms using btree (hotel_id, room_number) TABLESPACE pg_default;

create index IF not exists idx_rooms_hotel_floor on public.rooms using btree (hotel_id, floor_number) TABLESPACE pg_default;

create index IF not exists idx_rooms_updated_by on public.rooms using btree (updated_by) TABLESPACE pg_default;


room_notes

create table public.room_notes (
  id uuid not null default gen_random_uuid (),
  room_id uuid not null,
  author_id uuid null,
  note text not null,
  created_at timestamp with time zone null default now(),
  deleted_at timestamp with time zone null,
  constraint room_notes_pkey primary key (id),
  constraint room_notes_author_id_fkey foreign KEY (author_id) references profiles (id),
  constraint room_notes_room_id_fkey foreign KEY (room_id) references rooms (id) on delete CASCADE
) TABLESPACE pg_default;


room_history

create table public.room_history (
  id uuid not null default gen_random_uuid (),
  room_id uuid not null,
  changed_by uuid null,
  change_type text not null,
  old_value text null,
  new_value text null,
  note text null,
  created_at timestamp with time zone null default now(),
  constraint room_history_pkey primary key (id),
  constraint fk_room_history_room_id foreign KEY (room_id) references rooms (id) on delete CASCADE,
  constraint room_history_changed_by_fkey foreign KEY (changed_by) references profiles (id),
  constraint chk_room_history_change_type check (
    (
      change_type = any (
        array[
          'occupancy_status'::text,
          'cleaning_status'::text,
          'flags'::text,
          'notes'::text,
          'created'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_room_history_room_id on public.room_history using btree (room_id) TABLESPACE pg_default;

profiles

create table public.profiles (
  id uuid not null default auth.uid (),
  first_name text not null,
  last_name text not null,
  created_at timestamp with time zone null default now(),
  email text not null,
  constraint profiles_pkey primary key (id),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create unique INDEX IF not exists profiles_email_key on public.profiles using btree (email) TABLESPACE pg_default;

join_requests

create table public.join_requests (
  id uuid not null default gen_random_uuid (),
  profile_id uuid not null,
  hotel_id uuid not null,
  status text not null default 'pending'::text,
  created_at timestamp with time zone null default now(),
  constraint join_requests_pkey primary key (id),
  constraint join_requests_hotel_id_fkey foreign KEY (hotel_id) references hotels (id),
  constraint join_requests_profile_id_fkey foreign KEY (profile_id) references profiles (id) on delete CASCADE,
  constraint join_requests_status_check check (
    (
      status = any (
        array[
          'pending'::text,
          'accepted'::text,
          'rejected'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

hotels

create table public.hotels (
  id uuid not null default gen_random_uuid (),
  name text not null,
  created_by uuid not null,
  created_at timestamp with time zone null default now(),
  phone text null,
  address text null,
  city text null,
  state text null,
  zip_code text null,
  constraint hotels_pkey primary key (id),
  constraint hotels_created_by_fkey foreign KEY (created_by) references profiles (id) on delete RESTRICT
) TABLESPACE pg_default;



hotel_memberships

create table public.hotel_memberships (
  id uuid not null default gen_random_uuid (),
  profile_id uuid not null,
  hotel_id uuid not null,
  role text not null,
  status text not null default 'pending'::text,
  created_at timestamp with time zone null default now(),
  constraint hotel_memberships_pkey primary key (id),
  constraint unique_profile_hotel unique (profile_id, hotel_id),
  constraint hotel_memberships_hotel_id_fkey foreign KEY (hotel_id) references hotels (id) on delete CASCADE,
  constraint hotel_memberships_profile_id_fkey foreign KEY (profile_id) references profiles (id) on delete CASCADE,
  constraint hotel_memberships_role_check check (
    (
      role = any (
        array[
          'admin'::text,
          'manager'::text,
          'front_desk'::text,
          'housekeeping'::text,
          'maintenance'::text
        ]
      )
    )
  ),
  constraint hotel_memberships_status_check check (
    (
      status = any (
        array[
          'pending'::text,
          'approved'::text,
          'rejected'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_hotel_memberships_hotel on public.hotel_memberships using btree (hotel_id) TABLESPACE pg_default;

create index IF not exists idx_hotel_memberships_profile on public.hotel_memberships using btree (profile_id) TABLESPACE pg_default;



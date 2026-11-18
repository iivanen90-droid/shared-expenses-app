begin;

create table public.expense_groups (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(btrim(name)) > 0),
  emoji text not null check (length(btrim(emoji)) > 0),
  currency_code text not null check (currency_code ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now()
);

create index expense_groups_owner_id_idx on public.expense_groups(owner_id);

-- Participants are names, not accounts. Position is stable within an immutable
-- creation payload, so replaying it cannot duplicate participants.
create table public.group_participants (
  group_id uuid not null references public.expense_groups(id) on delete cascade,
  position integer not null check (position >= 0),
  name text not null check (length(btrim(name)) > 0),
  primary key (group_id, position)
);

alter table public.expense_groups enable row level security;
alter table public.group_participants enable row level security;

revoke all on public.expense_groups, public.group_participants from public, anon, authenticated;
grant select, insert, delete on public.expense_groups to authenticated;
grant update (name, emoji, currency_code) on public.expense_groups to authenticated;
grant select, insert, delete on public.group_participants to authenticated;
grant update (name) on public.group_participants to authenticated;

create policy groups_select on public.expense_groups for select to authenticated
  using (owner_id = (select auth.uid()));
create policy groups_insert on public.expense_groups for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy groups_update on public.expense_groups for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy groups_delete on public.expense_groups for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy participants_select on public.group_participants for select to authenticated
  using (exists (select 1 from public.expense_groups g where g.id = group_id and g.owner_id = (select auth.uid())));
create policy participants_insert on public.group_participants for insert to authenticated
  with check (exists (select 1 from public.expense_groups g where g.id = group_id and g.owner_id = (select auth.uid())));
create policy participants_update on public.group_participants for update to authenticated
  using (exists (select 1 from public.expense_groups g where g.id = group_id and g.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.expense_groups g where g.id = group_id and g.owner_id = (select auth.uid())));
create policy participants_delete on public.group_participants for delete to authenticated
  using (exists (select 1 from public.expense_groups g where g.id = group_id and g.owner_id = (select auth.uid())));

-- A single invoker transaction creates the group and all participant rows.
-- No elevated privileges: table grants and RLS apply inside this function.
create function public.create_expense_group(
  p_id uuid, p_owner_id uuid, p_name text, p_emoji text,
  p_currency_code text, p_participants text[]
) returns uuid
language plpgsql security invoker set search_path = ''
as $$
declare
  inserted_id uuid;
  existing_group public.expense_groups%rowtype;
  existing_names text[];
begin
  if auth.uid() is null or p_owner_id is distinct from auth.uid() then
    raise exception 'Access denied' using errcode = '42501';
  end if;
  if p_participants is null or exists (
    select 1 from unnest(p_participants) n where n is null or length(btrim(n)) = 0
  ) then
    raise exception 'Invalid participants' using errcode = '22023';
  end if;

  insert into public.expense_groups(id, owner_id, name, emoji, currency_code)
  values (p_id, p_owner_id, p_name, p_emoji, p_currency_code)
  on conflict (id) do nothing returning id into inserted_id;

  if inserted_id is not null then
    insert into public.group_participants(group_id, position, name)
    select p_id, (ordinality - 1)::integer, name
      from unnest(p_participants) with ordinality as participant(name, ordinality);
  else
    select * into existing_group from public.expense_groups where id = p_id for update;
    if not found then
      raise exception 'Access denied' using errcode = '42501';
    end if;
    select coalesce(array_agg(name order by position), '{}'::text[]) into existing_names
      from public.group_participants where group_id = p_id;
    if existing_group.owner_id is distinct from p_owner_id
      or existing_group.name is distinct from p_name
      or existing_group.emoji is distinct from p_emoji
      or existing_group.currency_code is distinct from p_currency_code
      or existing_names is distinct from p_participants then
      raise exception 'Conflicting creation payload' using errcode = '23505';
    end if;
  end if;
  return p_id;
end;
$$;

revoke all on function public.create_expense_group(uuid, uuid, text, text, text, text[]) from public, anon;
grant execute on function public.create_expense_group(uuid, uuid, text, text, text, text[]) to authenticated;

commit;

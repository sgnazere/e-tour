-- =====================================================================
--  e-Tour Côte d'Ivoire — Base de données SÉCURISÉE (version 2)
--  À exécuter en une fois dans Supabase > SQL Editor > Run
--
--  ⚠️ Ce script SUPPRIME l'ancienne version (tables + données de test).
--
--  Principe :
--   - le public (clé anon) ne peut NI lire NI écrire directement dans les tables ;
--   - toutes les écritures passent par 4 fonctions qui contrôlent tout ;
--   - la lecture publique se limite à 2 fonctions qui renvoient des totaux.
-- =====================================================================

-- 0) Nettoyage de l'ancienne version ----------------------------------
drop view  if exists tendance_villes;
drop view  if exists interet_dates;
drop table if exists reservations;
drop table if exists duels;
drop table if exists participants;
drop table if exists villes;

-- 1) Tables -----------------------------------------------------------
create table villes (
  nom text primary key
);
insert into villes (nom) values
 ('Assinie'),('Grand-Bassam'),('Jacqueville'),('Grand-Béréby'),('San-Pédro'),
 ('Sassandra'),('Fresco'),('Yamoussoukro'),('Bouaké'),('Daloa'),('Soubré'),
 ('Man'),('Abengourou'),('Korhogo'),('Ferkessédougou'),('Odienné');
-- ⚠️ Les noms doivent être EXACTEMENT ceux de config.js (accents compris).

create table participants (
  id             uuid primary key default gen_random_uuid(),
  pseudo         text not null check (char_length(pseudo) between 2 and 30),
  whatsapp       text not null unique check (whatsapp ~ '^(01|05|07)[0-9]{8}$'),
  ville_choisie  text references villes(nom),
  a_vote         boolean not null default false,
  created_at     timestamptz not null default now()
);
create unique index participants_pseudo_unique on participants (lower(pseudo));

create table duels (
  id              bigint generated always as identity primary key,
  participant_id  uuid not null references participants(id) on delete cascade,
  tour            smallint not null check (tour between 1 and 4),
  ville_gagnante  text not null references villes(nom),
  ville_perdante  text not null references villes(nom),
  created_at      timestamptz not null default now()
);

create table reservations (
  id              bigint generated always as identity primary key,
  participant_id  uuid not null unique references participants(id) on delete cascade,
  ville           text not null references villes(nom),
  date_vendredi   date not null,
  created_at      timestamptz not null default now()
);

-- 2) Verrouillage : aucun accès direct pour le public -----------------
alter table villes        enable row level security;
alter table participants  enable row level security;
alter table duels         enable row level security;
alter table reservations  enable row level security;
-- (aucune policy = aucun accès direct via l'API)
revoke all on villes, participants, duels, reservations from anon, authenticated;

-- 3) Fonction : inscription ------------------------------------------
create or replace function inscrire(p_pseudo text, p_whatsapp text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_pseudo text := btrim(p_pseudo);
  v_tel    text := regexp_replace(coalesce(p_whatsapp,''), '\D', '', 'g');
  v_id     uuid;
begin
  -- numéro saisi avec l'indicatif +225 : on le retire
  if char_length(v_tel) = 13 and left(v_tel,3) = '225' then v_tel := substr(v_tel,4); end if;

  if v_pseudo is null or v_pseudo !~ '^[[:alnum:] _.''-]{2,30}$' then
    raise exception 'PSEUDO_INVALIDE';
  end if;
  if v_tel !~ '^(01|05|07)[0-9]{8}$' then
    raise exception 'NUMERO_INVALIDE';
  end if;

  -- anti-robots : 30 inscriptions max toutes les 10 minutes pour tout le site
  if (select count(*) from participants where created_at > now() - interval '10 minutes') >= 30 then
    raise exception 'TROP_DE_DEMANDES';
  end if;

  begin
    insert into participants (pseudo, whatsapp) values (v_pseudo, v_tel) returning id into v_id;
  exception when unique_violation then
    if exists (select 1 from participants where whatsapp = v_tel) then
      raise exception 'NUMERO_DEJA_INSCRIT';
    else
      raise exception 'PSEUDO_PRIS';
    end if;
  end;
  return v_id;
end $$;

-- 4) Fonction : enregistrement du tournoi (15 duels) ------------------
--  p_duels = [{"g":"Man","p":"Korhogo"}, ...] dans l'ordre :
--  8 duels (huitièmes), 4 (quarts), 2 (demies), 1 (finale)
create or replace function enregistrer_duels(p_id uuid, p_duels jsonb)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_part     participants%rowtype;
  r_debut    int[] := array[0,8,12,14];
  r_nb       int[] := array[8,4,2,1];
  v_pool     text[];
  v_gagnants text[];
  v_vus      text[];
  v_g text; v_p text;
  k int; i int;
begin
  select * into v_part from participants where id = p_id for update;
  if not found then raise exception 'PARTICIPANT_INCONNU'; end if;
  if v_part.a_vote then raise exception 'DEJA_VOTE'; end if;
  if v_part.created_at < now() - interval '2 hours' then raise exception 'SESSION_EXPIREE'; end if;
  if jsonb_typeof(p_duels) <> 'array' or jsonb_array_length(p_duels) <> 15 then
    raise exception 'TOURNOI_INVALIDE';
  end if;

  select array_agg(nom) into v_pool from villes;
  if cardinality(v_pool) <> 16 then raise exception 'LISTE_VILLES_INCORRECTE'; end if;

  -- vérifie que c'est un vrai tournoi : chaque tour oppose exactement
  -- les gagnants du tour précédent, chaque ville une seule fois par tour
  for k in 1..4 loop
    v_gagnants := '{}'; v_vus := '{}';
    for i in r_debut[k] .. r_debut[k] + r_nb[k] - 1 loop
      v_g := p_duels->i->>'g';
      v_p := p_duels->i->>'p';
      if v_g is null or v_p is null or v_g = v_p
         or not (v_g = any(v_pool)) or not (v_p = any(v_pool))
         or v_g = any(v_vus) or v_p = any(v_vus) then
        raise exception 'TOURNOI_INVALIDE';
      end if;
      v_vus := v_vus || v_g || v_p;
      v_gagnants := v_gagnants || v_g;
      insert into duels (participant_id, tour, ville_gagnante, ville_perdante)
      values (p_id, k, v_g, v_p);
    end loop;
    if cardinality(v_vus) <> cardinality(v_pool) then raise exception 'TOURNOI_INVALIDE'; end if;
    v_pool := v_gagnants;
  end loop;

  update participants set a_vote = true, ville_choisie = v_pool[1] where id = p_id;
  return v_pool[1];  -- la ville championne
end $$;

-- 5) Fonction : réservation du week-end -------------------------------
create or replace function reserver(p_id uuid, p_date date)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_part participants%rowtype;
  v_dim  date := p_date + 2;
begin
  select * into v_part from participants where id = p_id;
  if not found then raise exception 'PARTICIPANT_INCONNU'; end if;
  if not v_part.a_vote or v_part.ville_choisie is null then raise exception 'VOTE_MANQUANT'; end if;
  if v_part.created_at < now() - interval '2 hours' then raise exception 'SESSION_EXPIREE'; end if;

  -- vendredi, pas dans le passé, au plus 4 mois à l'avance
  if extract(isodow from p_date) <> 5 or p_date < current_date or p_date > current_date + 120 then
    raise exception 'DATE_INVALIDE';
  end if;
  -- vendredi ET dimanche entre le 25 du mois et le 10 du mois suivant
  if not ((extract(day from p_date) >= 25 or extract(day from p_date) <= 10)
      and (extract(day from v_dim)  >= 25 or extract(day from v_dim)  <= 10)) then
    raise exception 'DATE_INVALIDE';
  end if;

  begin
    -- la ville vient de la base (le champion), jamais du navigateur
    insert into reservations (participant_id, ville, date_vendredi)
    values (p_id, v_part.ville_choisie, p_date);
  exception when unique_violation then
    raise exception 'DEJA_RESERVE';
  end;
end $$;

-- 5 bis) Fonction : renoncer (efface le participant, ses duels et sa réservation)
--  Seul le navigateur qui a fait l'inscription connaît l'identifiant (uuid secret).
--  Possible pendant 24 h après l'inscription ; après, il faut passer par l'organisateur.
create or replace function renoncer(p_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  delete from participants
  where id = p_id and created_at > now() - interval '24 hours';
  -- pas d'erreur si l'identifiant est inconnu : on ne révèle rien
end $$;

-- 6) Lectures publiques : uniquement des totaux -----------------------
create or replace function tendance()
returns table (ville text, victoires bigint)
language sql stable security definer set search_path = public
as $$
  select v.nom, count(d.id)
  from villes v left join duels d on d.ville_gagnante = v.nom
  group by v.nom;
$$;

create or replace function interet_dates(p_ville text)
returns table (date_vendredi date, inscrits bigint)
language sql stable security definer set search_path = public
as $$
  select r.date_vendredi, count(*)
  from reservations r
  where r.ville = p_ville and r.date_vendredi >= current_date
  group by r.date_vendredi;
$$;

-- 7) Droits d'exécution : seulement ces 6 fonctions ------------------
revoke execute on function inscrire(text,text), enregistrer_duels(uuid,jsonb),
  reserver(uuid,date), renoncer(uuid), tendance(), interet_dates(text) from public;
grant execute on function inscrire(text,text), enregistrer_duels(uuid,jsonb),
  reserver(uuid,date), renoncer(uuid), tendance(), interet_dates(text) to anon, authenticated;


-- =====================================================================
--  REQUÊTES POUR TOI (à lancer dans le SQL Editor, jamais exposées)
-- =====================================================================

-- Liste des inscrits par week-end, avec lien WhatsApp cliquable :
-- select r.date_vendredi, r.ville, p.pseudo,
--        'https://wa.me/225' || p.whatsapp as lien_whatsapp
-- from reservations r join participants p on p.id = r.participant_id
-- order by r.date_vendredi, r.ville, p.pseudo;

-- Nettoyage après la saison (supprime aussi duels et réservations liés) :
-- delete from participants where created_at < now() - interval '6 months';

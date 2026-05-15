-- TP3 - Exercice 1 : Schéma Cassandra
-- Use Case : SmartGrid DZ - IoT Électrique

-- ─── 1.1 : Créer le Keyspace ───────────────────────────────────────────────────
-- Pour le TP local (docker) on utilise SimpleStrategy avec replication_factor 1.
-- En production on utiliserait NetworkTopologyStrategy avec replication_factor 3.
CREATE KEYSPACE IF NOT EXISTS smartgrid
WITH replication = {
  'class'              : 'SimpleStrategy',
  'replication_factor' : 1
}
AND durable_writes = true;

USE smartgrid;

-- ─── 1.2 : Table mesures_par_capteur ──────────────────────────────────────────
-- Requête cible : "Mesures du capteur X entre T1 et T2"
--
-- Choix de la Partition Key : (capteur_id, date_jour)
--   → capteur_id  : chaque capteur a sa propre partition (pas de hot partition)
--   → date_jour   : bucket par jour → limite la taille de chaque partition
--                   (10 000 capteurs × 1 440 min/jour = 1 440 lignes max par partition)
-- Clustering Key : timestamp DESC
--   → les mesures les plus récentes arrivent en premier, idéal pour LIMIT 1

CREATE TABLE IF NOT EXISTS mesures_par_capteur (
  capteur_id   UUID,
  date_jour    DATE,
  timestamp    TIMESTAMP,
  wilaya       TEXT,
  commune      TEXT,
  tension_v    FLOAT,
  courant_a    FLOAT,
  puissance_kw FLOAT,
  frequence_hz FLOAT,
  temperature  FLOAT,
  alerte       BOOLEAN,
  code_alerte  TEXT,
  PRIMARY KEY ((capteur_id, date_jour), timestamp)
) WITH CLUSTERING ORDER BY (timestamp DESC)
  AND default_time_to_live = 7776000   -- 90 jours = 90 × 86 400 s
  AND comment = 'Mesures brutes IoT par capteur et par jour';


-- ─── 1.3 : Table alertes_par_wilaya ───────────────────────────────────────────
-- Requête cible : "Alertes de la wilaya X le jour Y"
--
-- Partition Key : (wilaya, date_jour)
--   → on interroge toujours par wilaya + jour → pas de scan complet
-- Clustering Key : timestamp DESC, capteur_id ASC
--   → tri chronologique inverse + unicité garantie par capteur_id

CREATE TABLE IF NOT EXISTS alertes_par_wilaya (
  wilaya       TEXT,
  date_jour    DATE,
  timestamp    TIMESTAMP,
  capteur_id   UUID,
  code_alerte  TEXT,
  description  TEXT,
  gravite      INT,        -- 1=info  2=warning  3=critique
  resolue      BOOLEAN,
  PRIMARY KEY ((wilaya, date_jour), timestamp, capteur_id)
) WITH CLUSTERING ORDER BY (timestamp DESC, capteur_id ASC)
  AND default_time_to_live = 31536000   -- 1 an = 365 × 86 400 s
  AND comment = 'Alertes regroupées par wilaya et par jour';


-- ─── 1.4 : Table agregats_horaires ────────────────────────────────────────────
-- Requête cible : "Consommation moyenne par heure pour le dashboard d'une wilaya"
--
-- Partition Key : wilaya
--   → dashboard par wilaya, volumétrie maîtrisée (5 wilayas × 24h × 365j)
-- Clustering Key : date_heure DESC
--   → heures les plus récentes en premier (pratique pour les dashboards)

CREATE TABLE IF NOT EXISTS agregats_horaires (
  wilaya           TEXT,
  date_heure       TIMESTAMP,
  nb_capteurs      INT,
  puissance_moy_kw FLOAT,
  puissance_max_kw FLOAT,
  puissance_min_kw FLOAT,
  nb_alertes       INT,
  PRIMARY KEY (wilaya, date_heure)
) WITH CLUSTERING ORDER BY (date_heure DESC)
  AND default_time_to_live = 157680000   -- 5 ans
  AND comment = 'Agrégats horaires pré-calculés par wilaya';


-- ─── 1.5 : Index secondaire pour recherche par gravité (optionnel) ─────────────
-- Utilisé uniquement en interne par wilaya — index local acceptable
CREATE INDEX IF NOT EXISTS idx_alertes_gravite
ON alertes_par_wilaya (gravite);


-- ─── Vérification ─────────────────────────────────────────────────────────────
DESCRIBE TABLES;

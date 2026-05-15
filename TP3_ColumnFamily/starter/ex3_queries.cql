-- TP3 - Exercice 3 : Requêtes CQL
-- Use Case : SmartGrid DZ

USE smartgrid;

-- ─── 3.1 : Mesures d'un capteur spécifique sur les dernières 6 heures ─────────
-- On connaît capteur_id → on peut filtrer sur la partition (capteur_id, date_jour)
-- puis sur la clustering key timestamp avec ALLOW FILTERING évité car on filtre
-- sur la clé de partition complète + clustering key.

SELECT capteur_id, timestamp, tension_v, courant_a, puissance_kw, alerte
FROM mesures_par_capteur
WHERE capteur_id = 550e8400-e29b-41d4-a716-446655440000  -- remplacer par un UUID réel
  AND date_jour  = '2025-01-15'
  AND timestamp >= '2025-01-15 10:00:00+0000'
  AND timestamp <= '2025-01-15 16:00:00+0000'
ORDER BY timestamp DESC;


-- ─── 3.2 : Dernière mesure de chaque capteur d'une wilaya ─────────────────────
-- Astuce : CLUSTERING ORDER BY timestamp DESC + LIMIT 1 par capteur.
-- On ne peut pas faire un GROUP BY en CQL → on interroge capteur par capteur
-- (dans le code applicatif) ou on utilise une table dédiée.
-- Ici : dernière mesure d'UN capteur connu :

SELECT capteur_id, timestamp, tension_v, puissance_kw
FROM mesures_par_capteur
WHERE capteur_id = 550e8400-e29b-41d4-a716-446655440000
  AND date_jour  = '2025-01-15'
LIMIT 1;   -- CLUSTERING ORDER DESC → retourne la mesure la plus récente

-- Pour plusieurs capteurs, le code Python itère la liste et exécute cette
-- requête en parallèle (async) pour chacun.


-- ─── 3.3 : Capteurs en alerte dans la wilaya "Alger" aujourd'hui ──────────────
-- On utilise alertes_par_wilaya — la table est conçue exactement pour ça.

SELECT capteur_id, timestamp, code_alerte, gravite, description
FROM alertes_par_wilaya
WHERE wilaya    = 'Alger'
  AND date_jour = '2025-01-15'
ORDER BY timestamp DESC;

-- Compter les alertes du jour
SELECT COUNT(*) AS nb_alertes_alger_aujourd_hui
FROM alertes_par_wilaya
WHERE wilaya    = 'Alger'
  AND date_jour = '2025-01-15';

-- Alertes critiques uniquement (gravite = 3)
SELECT capteur_id, timestamp, code_alerte
FROM alertes_par_wilaya
WHERE wilaya    = 'Alger'
  AND date_jour = '2025-01-15'
  AND gravite   = 3;   -- possible grâce à l'index secondaire créé en Ex1


-- ─── 3.4 : Consommation totale par heure sur une journée (dashboard) ──────────
-- On utilise agregats_horaires — pré-calculé lors de l'ingestion.

SELECT date_heure, nb_capteurs, puissance_moy_kw, puissance_max_kw,
       puissance_min_kw, nb_alertes
FROM agregats_horaires
WHERE wilaya = 'Alger'
  AND date_heure >= '2025-01-15 00:00:00+0000'
  AND date_heure <= '2025-01-15 23:59:59+0000'
ORDER BY date_heure DESC;


-- ─── 3.5 : Capteurs avec tension anormale (< 200 V ou > 240 V) ────────────────
-- 30 dernières minutes : on filtre sur date_jour + plage de timestamp.
-- La colonne alerte + code_alerte est déjà remplie à l'ingestion.
-- On passe par alertes_par_wilaya (conçue pour ça) :

SELECT capteur_id, timestamp, code_alerte, description
FROM alertes_par_wilaya
WHERE wilaya    = 'Alger'
  AND date_jour = '2025-01-15'
  AND timestamp >= '2025-01-15 15:30:00+0000'   -- now - 30 min
  AND timestamp <= '2025-01-15 16:00:00+0000'   -- now
  AND code_alerte IN ('SURTENSION', 'SOUS_TENSION');
-- Note : filtrer sur code_alerte nécessite un index ou ALLOW FILTERING (petite partition ok)


-- ─── 3.6 : Top 10 capteurs les plus actifs cette semaine ──────────────────────
-- En CQL pur on ne peut pas faire un COUNT(*) GROUP BY capteur_id sur toute
-- la table — ce serait un full scan.
-- Bonne pratique : tenir un compteur dans une table dédiée mise à jour
-- à l'ingestion, ou utiliser une materialized view / Spark.
-- Requête CQL possible sur une seule partition connue :

SELECT capteur_id, COUNT(*) AS nb_mesures
FROM mesures_par_capteur
WHERE capteur_id = 550e8400-e29b-41d4-a716-446655440000
  AND date_jour IN ('2025-01-09','2025-01-10','2025-01-11',
                    '2025-01-12','2025-01-13','2025-01-14','2025-01-15');
-- Pour le top 10 global → calculer côté application (Python) sur la liste des capteurs.


-- ─── 3.7 : ALLOW FILTERING — pourquoi l'éviter, et comment faire autrement ────

-- ❌ Requête DANGEREUSE (full table scan) :
-- SELECT * FROM mesures_par_capteur WHERE tension_v < 200 ALLOW FILTERING;
--
-- Problème : Cassandra doit lire TOUTES les partitions de tous les nœuds pour
-- filtrer sur tension_v, qui n'est ni clé de partition ni clé de clustering.
-- → latence imprévisible, surcharge des nœuds, timeout en production.

-- ✅ Solution correcte : utiliser la table déjà filtrée alertes_par_wilaya
--    qui stocke UNIQUEMENT les mesures anomales à l'ingestion.

SELECT capteur_id, timestamp, code_alerte
FROM alertes_par_wilaya
WHERE wilaya    = 'Alger'
  AND date_jour = '2025-01-15';
-- → requête sur une seule partition, O(1) sur le nœud responsable.

-- Règle d'or : si tu utilises ALLOW FILTERING en production, c'est que
-- le schéma ne modélise pas correctement la requête.

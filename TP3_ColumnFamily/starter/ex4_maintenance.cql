-- TP3 - Exercice 4 : Compaction et Maintenance
-- Use Case : SmartGrid DZ

USE smartgrid;

-- ─── 4.1 : Stratégie de compaction — choix et justification ───────────────────
--
-- Il existe 3 stratégies principales :
--
-- │ Stratégie │ Quand utiliser                          │ Notre cas          │
-- │-----------│-----------------------------------------│--------------------|
-- │ STCS      │ Usage général, charges mixtes           │ ❌ pas optimal IoT  │
-- │ LCS       │ Lectures intensives, peu d'écritures    │ ❌ trop coûteux     │
-- │ TWCS      │ Séries temporelles + TTL                │ ✅ parfait ici      │
--
-- TimeWindowCompactionStrategy (TWCS) :
--   • Regroupe les SSTables par fenêtre de temps (ex: 1 jour)
--   • Quand les données expirent (TTL), toute la fenêtre est supprimée en bloc
--   • Évite la fragmentation : chaque fenêtre est compactée séparément
--   • Idéal pour des données qui arrivent dans l'ordre chronologique (IoT)
--
-- On choisit une fenêtre de 1 DAYS pour mesures_par_capteur :
--   → chaque journée forme une SSTable distincte
--   → après 90 jours (TTL), la fenêtre entière est purgée proprement


-- ─── 4.2 : Configurer TWCS pour mesures_par_capteur ──────────────────────────

ALTER TABLE mesures_par_capteur
WITH compaction = {
  'class'                   : 'TimeWindowCompactionStrategy',
  'compaction_window_unit'  : 'DAYS',      -- fenêtre = 1 jour
  'compaction_window_size'  : 1,
  'expired_sstable_check_frequency_seconds': 86400  -- vérifier 1×/jour
};

-- Pour alertes_par_wilaya (TTL 1 an → fenêtre 7 jours)
ALTER TABLE alertes_par_wilaya
WITH compaction = {
  'class'                  : 'TimeWindowCompactionStrategy',
  'compaction_window_unit' : 'DAYS',
  'compaction_window_size' : 7
};

-- Pour agregats_horaires (TTL 5 ans, faible volumétrie → LCS acceptable)
ALTER TABLE agregats_horaires
WITH compaction = {
  'class'                    : 'LeveledCompactionStrategy',
  'sstable_size_in_mb'       : 160
};


-- ─── 4.3 : Vérifier l'utilisation des TTL ─────────────────────────────────────
-- Voir le TTL restant d'une ligne spécifique :

SELECT capteur_id, timestamp, TTL(tension_v) AS ttl_restant_secondes
FROM mesures_par_capteur
WHERE capteur_id = 550e8400-e29b-41d4-a716-446655440000
  AND date_jour  = '2025-01-15'
LIMIT 5;

-- Estimer combien de lignes expirent dans les 7 prochains jours :
-- (CQL ne supporte pas les filtres sur TTL → à faire en Python)
-- Exemple Python :
--
--   rows = session.execute(
--       "SELECT capteur_id, timestamp, TTL(tension_v) AS ttl "
--       "FROM mesures_par_capteur "
--       "WHERE capteur_id = %s AND date_jour = %s",
--       (capteur_id, date.today())
--   )
--   bientot = [r for r in rows if r.ttl is not None and r.ttl < 7 * 86400]
--   print(f"{len(bientot)} lignes expirent dans les 7 prochains jours")


-- ─── 4.4 : Partitions "hot" — détection et correction ─────────────────────────
--
-- Une partition hot = une partition qui reçoit beaucoup plus de requêtes
-- que les autres → surcharge d'un nœud → goulot d'étranglement.
--
-- Comment détecter :
--   1. Outil nodetool :
--      $ nodetool tablestats smartgrid.mesures_par_capteur
--      → regarder "Maximum partition size" et "Average partition size"
--      → si max >> average → partition hot
--
--   2. Métriques Cassandra (JMX / Prometheus) :
--      → coordinated_write_latency par partition
--
-- Cause fréquente ici :
--   Si on avait utilisé (wilaya) seul comme Partition Key, "Alger" (plus grande
--   wilaya) aurait reçu ~40% des requêtes → hot partition.
--
-- Notre solution (ex1) :
--   Partition Key = (capteur_id, date_jour)
--   → 10 000 capteurs × N jours → distribution uniforme sur tous les nœuds
--   → aucune wilaya ne concentre les écritures
--
-- Si malgré tout une partition est trop grande (> 100 MB recommandé) :
--   → Affiner le bucket : remplacer date_jour par heure_bucket (TIMESTAMP tronqué à l'heure)
--   → Résultat : partition max = 10 000 mesures/heure au lieu de 240 000/jour

-- Vérifier la taille des SSTables depuis le shell Docker :
-- $ docker exec -it nosql_cassandra nodetool tablestats smartgrid.mesures_par_capteur

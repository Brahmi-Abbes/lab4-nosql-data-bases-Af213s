# Rapport TP3 - Cassandra (Column Family)
**Nom: BENRAHMOUNE ANES**

## Ingestion IoT
- **Modélisation :** Création d'un keyspace `powergrid` optimisé pour les séries temporelles.
- **Ingestion :** Script Python utilisant des `BatchStatement` pour insérer des milliers de mesures par seconde.
- **Requêtes :** Utilisation efficace des clés de partition (`sid`, `day`) et de clustering (`ts`).
- **Maintenance :** Configuration de la stratégie de compaction `TWCS` (Time Window Compaction Strategy).

## Point technique
Le choix des clés de partition est crucial dans Cassandra pour éviter les partitions géantes ("hot partitions") et assurer une distribution uniforme des données.

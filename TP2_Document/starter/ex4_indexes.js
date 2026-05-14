/**
 * TP2 - Exercice 4 : Index et Optimisation
 * Use Case : HealthCare DZ - Optimisation des requêtes
 */

use("medical_db");

// ─── 4.1 : Créer les index appropriés ────────────────────────────────────────

// Index 1 : Recherche fréquente par wilaya + antécédents
// Justification : la requête 2.1 filtre d'abord par wilaya puis par antécédents.
// L'index composé dans cet ordre permet un IXSCAN efficace au lieu d'un COLLSCAN.
db.patients.createIndex(
  { "adresse.wilaya": 1, antecedents: 1 },
  { name: "idx_wilaya_antecedents" }
);

// Index 2 : Recherche par date de naissance (calcul d'âge, filtre sur les seniors)
// Justification : les requêtes 2.1 et 3.4 filtrent par dateNaissance.
// Sans index, MongoDB scanne toute la collection.
db.patients.createIndex(
  { dateNaissance: 1 },
  { name: "idx_date_naissance" }
);

// Index 3 : Texte sur les diagnostics pour recherche full-text (requête 2.5)
// Justification : l'opérateur $text requiert un index text. Sans lui, la requête échoue.
// On cible les diagnostics et les notes des consultations.
db.patients.createIndex(
  {
    "consultations.diagnostic": "text",
    "consultations.notes": "text"
  },
  { name: "idx_text_diagnostic", default_language: "french" }
);

// Index 4 : Collection analyses - lookup par patient_id (requête 5.1 avec $lookup)
// Justification : $lookup sans index sur patient_id fait un COLLSCAN sur analyses
// pour chaque document patient. L'index réduit la complexité de O(N*M) à O(N*log M).
db.analyses.createIndex(
  { patient_id: 1 },
  { name: "idx_analyses_patient_id" }
);

// Index 5 : Index composé pour la requête la plus complexe (3.4 - patients à risque)
// Justification : filtre sur antecedents (array) + dateNaissance.
// L'ordre est important : antecedents en premier car c'est $all (très sélectif),
// puis dateNaissance pour filtrer les >60 ans.
db.patients.createIndex(
  { antecedents: 1, dateNaissance: 1 },
  { name: "idx_antecedents_age" }
);

print("✅ Tous les index créés.");
db.patients.getIndexes().forEach(idx => print(" -", idx.name));


// ─── 4.2 : Comparer avec explain() ────────────────────────────────────────────
const requeteTest = {
  "adresse.wilaya": "Alger",
  antecedents: "Diabète type 2"
};

print("\n=== AVANT index (simulation - supprimer idx_wilaya_antecedents) ===");
// Pour voir l'effet sans l'index, on peut utiliser hint({$natural:1}) pour forcer COLLSCAN
const avantIndex = db.patients.find(requeteTest).hint({ $natural: 1 }).explain("executionStats");
print("Stage:              ", avantIndex.executionStats.executionStages.stage);
print("Docs examinés:      ", avantIndex.executionStats.totalDocsExamined);
print("Docs retournés:     ", avantIndex.executionStats.nReturned);
print("Temps (ms):         ", avantIndex.executionStats.executionTimeMillis);

print("\n=== APRÈS index (avec idx_wilaya_antecedents) ===");
const apresIndex = db.patients.find(requeteTest).hint("idx_wilaya_antecedents").explain("executionStats");
print("Stage:              ", apresIndex.executionStats.executionStages.stage);
print("Docs examinés:      ", apresIndex.executionStats.totalDocsExamined);
print("Docs retournés:     ", apresIndex.executionStats.nReturned);
print("Temps (ms):         ", apresIndex.executionStats.executionTimeMillis);

/*
  Résultats attendus (exemple avec 20 patients) :
  AVANT index :
    Stage: COLLSCAN — examine TOUS les documents (20)
    Docs examinés: 20 | Docs retournés: 3 | Temps: ~1ms

  APRÈS index :
    Stage: IXSCAN — utilise l'index, examine seulement les documents pertinents
    Docs examinés: 3 | Docs retournés: 3 | Temps: ~0ms

  Avec 100 000 patients, l'impact serait dramatique :
  AVANT : 100 000 docs examinés vs APRÈS : ~quelques dizaines
*/


// ─── 4.4 : Index TTL pour archivage des analyses de plus de 5 ans ─────────────
// TTL = 5 ans = 5 × 365.25 × 24 × 3600 = 157 788 000 secondes
// MongoDB supprime automatiquement les documents dont date + TTL < now
db.analyses.createIndex(
  { date: 1 },
  {
    expireAfterSeconds: 157788000,  // 5 ans en secondes
    name: "idx_ttl_analyses_5ans"
  }
);
print("\n✅ Index TTL créé : analyses expireront 5 ans après leur date.");
print("   Note : le background thread TTL s'exécute toutes les 60 secondes.");

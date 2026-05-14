/**
 * TP2 - Exercice 2 : Requêtes MongoDB de Base
 * Use Case : HealthCare DZ - Requêtes sur les dossiers médicaux
 */

use("medical_db");

// ─── 2.1 : Patients diabétiques de plus de 50 ans à Alger ────────────────────
print("=== 2.1 : Diabétiques > 50 ans à Alger ===");
const cinquanteAnsAvant = new Date();
cinquanteAnsAvant.setFullYear(cinquanteAnsAvant.getFullYear() - 50);

const diabetiquesAlger = db.patients.find({
  "adresse.wilaya": "Alger",
  antecedents: "Diabète type 2",
  dateNaissance: { $lte: cinquanteAnsAvant }
}).toArray();
printjson(diabetiquesAlger.map(p => `${p.prenom} ${p.nom} - ${p.adresse.wilaya}`));


// ─── 2.2 : Patients allergiques à la Pénicilline avec ≥ 3 consultations ───────
print("\n=== 2.2 : Allergiques Pénicilline avec ≥ 3 consultations ===");
const allergiquesPeni = db.patients.find({
  allergies: "Pénicilline",
  $expr: { $gte: [{ $size: "$consultations" }, 3] }
}).toArray();
printjson(allergiquesPeni.map(p => `${p.prenom} ${p.nom} - ${p.consultations.length} consultations`));


// ─── 2.3 : Projection : Nom, prénom et dernière consultation uniquement ────────
print("\n=== 2.3 : Projection nom + dernière consultation ===");
const projectionResultats = db.patients.find(
  {},
  {
    nom: 1,
    prenom: 1,
    // Retourner seulement le dernier élément du tableau consultations
    consultations: { $slice: -1 }
  }
).limit(5).toArray();
printjson(projectionResultats);


// ─── 2.4 : Patients sans antécédents avec tension systolique > 140 ────────────
print("\n=== 2.4 : Sans antécédents & tension systolique > 140 ===");
const sansAntecedentsHTA = db.patients.find({
  antecedents: { $size: 0 },
  "consultations": {
    $elemMatch: {
      "tension.systolique": { $gt: 140 }
    }
  }
}).toArray();
printjson(sansAntecedentsHTA.map(p => `${p.prenom} ${p.nom}`));


// ─── 2.5 : Créer un index texte sur les diagnostics, puis recherche textuelle ──
print("\n=== 2.5 : Recherche textuelle ===");

// Créer l'index texte si pas encore fait
db.patients.createIndex({ "consultations.diagnostic": "text" });

const rechercheTexte = db.patients.find({
  $text: { $search: "Hypertension artérielle" }
},
{
  score: { $meta: "textScore" },
  nom: 1, prenom: 1
}).sort({ score: { $meta: "textScore" } }).toArray();

printjson(rechercheTexte);

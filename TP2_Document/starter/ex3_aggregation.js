/**
 * TP2 - Exercice 3 : Pipelines d'Agrégation
 * Use Case : Statistiques médicales HealthCare DZ
 */

use("medical_db");

// ─── 3.1 : Distribution des diagnostics par wilaya ────────────────────────────
print("=== 3.1 : Top diagnostics par wilaya ===");

const diagParWilaya = db.patients.aggregate([
  // Étape 1 : Dérouler le tableau des consultations
  { $unwind: "$consultations" },
  // Étape 2 : Grouper par wilaya + diagnostic et compter
  {
    $group: {
      _id: { wilaya: "$adresse.wilaya", diagnostic: "$consultations.diagnostic" },
      count: { $sum: 1 }
    }
  },
  // Étape 3 : Trier par nombre décroissant
  { $sort: { count: -1 } },
  // Étape 4 : Projeter pour un résultat lisible
  {
    $project: {
      _id: 0,
      wilaya: "$_id.wilaya",
      diagnostic: "$_id.diagnostic",
      count: 1
    }
  },
  { $limit: 20 }
]).toArray();

printjson(diagParWilaya);


// ─── 3.2 : Médicament le plus prescrit par spécialité ─────────────────────────
print("\n=== 3.2 : Top médicaments par spécialité ===");

const medsParSpecialite = db.patients.aggregate([
  // Dérouler les consultations
  { $unwind: "$consultations" },
  // Dérouler les médicaments de chaque consultation
  { $unwind: "$consultations.medicaments" },
  // Grouper par spécialité + médicament
  {
    $group: {
      _id: {
        specialite: "$consultations.medecin.specialite",
        medicament: "$consultations.medicaments.nom"
      },
      nb_prescriptions: { $sum: 1 }
    }
  },
  // Trier par spécialité et nombre de prescriptions
  { $sort: { "_id.specialite": 1, nb_prescriptions: -1 } },
  // Regrouper pour garder seulement le top 1 par spécialité
  {
    $group: {
      _id: "$_id.specialite",
      top_medicament: { $first: "$_id.medicament" },
      nb_prescriptions: { $first: "$nb_prescriptions" }
    }
  },
  { $sort: { nb_prescriptions: -1 } }
]).toArray();

printjson(medsParSpecialite);


// ─── 3.3 : Évolution mensuelle des consultations ──────────────────────────────
print("\n=== 3.3 : Consultations par mois (12 derniers mois) ===");

const evolutionMensuelle = db.patients.aggregate([
  { $unwind: "$consultations" },
  // Filtrer les 12 derniers mois
  {
    $match: {
      "consultations.date": {
        $gte: new Date(new Date().setFullYear(new Date().getFullYear() - 1))
      }
    }
  },
  // Grouper par année + mois
  {
    $group: {
      _id: {
        annee: { $year: "$consultations.date" },
        mois: { $month: "$consultations.date" }
      },
      nb_consultations: { $sum: 1 }
    }
  },
  // Trier chronologiquement
  { $sort: { "_id.annee": 1, "_id.mois": 1 } },
  // Formatter la date en "YYYY-MM"
  {
    $project: {
      _id: 0,
      periode: {
        $concat: [
          { $toString: "$_id.annee" },
          "-",
          {
            $cond: {
              if: { $lt: ["$_id.mois", 10] },
              then: { $concat: ["0", { $toString: "$_id.mois" }] },
              else: { $toString: "$_id.mois" }
            }
          }
        ]
      },
      nb_consultations: 1
    }
  }
]).toArray();

printjson(evolutionMensuelle);


// ─── 3.4 : Patients à risque multiple ────────────────────────────────────────
print("\n=== 3.4 : Profil patients à risque élevé ===");

const soixanteAnsAvant = new Date();
soixanteAnsAvant.setFullYear(soixanteAnsAvant.getFullYear() - 60);

const patientsRisque = db.patients.aggregate([
  // Filtrer : Diabète type 2 + HTA + âge > 60
  {
    $match: {
      antecedents: { $all: ["Diabète type 2", "HTA"] },
      dateNaissance: { $lte: soixanteAnsAvant }
    }
  },
  // Calculer l'âge et le nombre de consultations
  {
    $addFields: {
      age: {
        $floor: {
          $divide: [
            { $subtract: [new Date(), "$dateNaissance"] },
            1000 * 60 * 60 * 24 * 365.25
          ]
        }
      },
      nb_consultations: { $size: "$consultations" }
    }
  },
  // Statistiques globales
  {
    $group: {
      _id: null,
      nb_patients_risque: { $sum: 1 },
      age_moyen: { $avg: "$age" },
      consultations_moyennes: { $avg: "$nb_consultations" },
      patients: { $push: { nom: "$nom", prenom: "$prenom", age: "$age" } }
    }
  },
  {
    $project: {
      _id: 0,
      nb_patients_risque: 1,
      age_moyen: { $round: ["$age_moyen", 1] },
      consultations_moyennes: { $round: ["$consultations_moyennes", 1] },
      patients: 1
    }
  }
]).toArray();

printjson(patientsRisque);


// ─── 3.5 : Rapport médecins ───────────────────────────────────────────────────
print("\n=== 3.5 : Top 5 médecins & taux de ré-consultation ===");

const rapportMedecins = db.patients.aggregate([
  { $unwind: "$consultations" },
  // Grouper par médecin : compter patients uniques et consultations totales
  {
    $group: {
      _id: "$consultations.medecin.nom",
      specialite: { $first: "$consultations.medecin.specialite" },
      patients_uniques: { $addToSet: "$_id" },
      total_consultations: { $sum: 1 }
    }
  },
  // Calculer le taux de ré-consultation
  {
    $addFields: {
      nb_patients_uniques: { $size: "$patients_uniques" },
      taux_reconsultation: {
        $multiply: [
          {
            $divide: [
              { $subtract: ["$total_consultations", { $size: "$patients_uniques" }] },
              { $size: "$patients_uniques" }
            ]
          },
          100
        ]
      }
    }
  },
  // Trier par total des consultations et garder le top 5
  { $sort: { total_consultations: -1 } },
  { $limit: 5 },
  {
    $project: {
      _id: 0,
      medecin: "$_id",
      specialite: 1,
      nb_patients_uniques: 1,
      total_consultations: 1,
      taux_reconsultation: { $round: ["$taux_reconsultation", 1] }
    }
  }
]).toArray();

printjson(rapportMedecins);

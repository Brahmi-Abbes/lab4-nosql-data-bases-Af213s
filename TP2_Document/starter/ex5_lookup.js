/**
 * TP2 - Exercice 5 : $lookup et Données Référencées
 * Use Case : HealthCare DZ - Jointures entre patients et analyses
 */

use("medical_db");

// ─── 5.1 : Dossier complet d'un patient (patients + analyses) ─────────────────
print("=== 5.1 : Dossier complet du patient Ahmed Bensalem ===");

const dossierComplet = db.patients.aggregate([
  // Cibler un patient spécifique
  { $match: { cin: "198001012300" } },
  // Jointure avec la collection analyses
  {
    $lookup: {
      from: "analyses",
      localField: "_id",
      foreignField: "patient_id",
      as: "analyses_resultats"
    }
  },
  // Projection pour un affichage propre
  {
    $project: {
      nom: 1,
      prenom: 1,
      cin: 1,
      dateNaissance: 1,
      antecedents: 1,
      allergies: 1,
      nb_consultations: { $size: "$consultations" },
      nb_analyses: { $size: "$analyses_resultats" },
      analyses_resultats: 1
    }
  }
]).toArray();

printjson(dossierComplet);


// ─── 5.2 : Patients avec glycémie > 1.26 g/L (dans la collection analyses) ────
print("\n=== 5.2 : Patients avec hyperglycémie (glycémie > 1.26 g/L) ===");

const hyperglycemiques = db.analyses.aggregate([
  // Filtrer les analyses de glycémie avec glucose > 1.26
  {
    $match: {
      type: "Glycémie",
      "resultats.glucose_gl": { $gt: 1.26 }
    }
  },
  // Jointure avec les patients
  {
    $lookup: {
      from: "patients",
      localField: "patient_id",
      foreignField: "_id",
      as: "patient"
    }
  },
  // Dérouler le tableau patient (il y en a un seul)
  { $unwind: "$patient" },
  // Projeter le résultat
  {
    $project: {
      _id: 0,
      "patient.prenom": 1,
      "patient.nom": 1,
      "patient.adresse.wilaya": 1,
      "patient.antecedents": 1,
      glycemie_gl: "$resultats.glucose_gl",
      date_analyse: "$date",
      laboratoire: 1
    }
  },
  { $sort: { glycemie_gl: -1 } }
]).toArray();

printjson(hyperglycemiques);


// ─── 5.3 : Taux d'analyses anormales par wilaya ───────────────────────────────
print("\n=== 5.3 : Statistiques croisées - analyses anormales par wilaya ===");

// On définit "anormale" comme : glycémie > 1.26 OU créatinine > 1.2 OU LDL > 1.6
const statsParWilaya = db.analyses.aggregate([
  // Jointure avec les patients pour avoir la wilaya
  {
    $lookup: {
      from: "patients",
      localField: "patient_id",
      foreignField: "_id",
      as: "patient"
    }
  },
  { $unwind: "$patient" },
  // Calculer si l'analyse est anormale selon le type
  {
    $addFields: {
      est_anormale: {
        $switch: {
          branches: [
            {
              case: {
                $and: [
                  { $eq: ["$type", "Glycémie"] },
                  { $gt: ["$resultats.glucose_gl", 1.26] }
                ]
              },
              then: true
            },
            {
              case: {
                $and: [
                  { $eq: ["$type", "Créatinine"] },
                  { $gt: ["$resultats.creatinine_mgdl", 1.2] }
                ]
              },
              then: true
            },
            {
              case: {
                $and: [
                  { $eq: ["$type", "Lipidogramme"] },
                  { $gt: ["$resultats.ldl", 1.6] }
                ]
              },
              then: true
            }
          ],
          default: false
        }
      }
    }
  },
  // Grouper par wilaya
  {
    $group: {
      _id: "$patient.adresse.wilaya",
      total_analyses: { $sum: 1 },
      analyses_anormales: { $sum: { $cond: ["$est_anormale", 1, 0] } }
    }
  },
  // Calculer le taux
  {
    $addFields: {
      taux_anormalite_pct: {
        $round: [
          { $multiply: [{ $divide: ["$analyses_anormales", "$total_analyses"] }, 100] },
          1
        ]
      }
    }
  },
  { $sort: { taux_anormalite_pct: -1 } },
  {
    $project: {
      _id: 0,
      wilaya: "$_id",
      total_analyses: 1,
      analyses_anormales: 1,
      taux_anormalite_pct: 1
    }
  }
]).toArray();

printjson(statsParWilaya);

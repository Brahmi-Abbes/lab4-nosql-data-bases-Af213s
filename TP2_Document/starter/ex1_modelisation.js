/**
 * TP2 - Exercice 1 : Modélisation MongoDB
 * Use Case : HealthCare DZ - Dossiers Médicaux
 */

use("medical_db");

// ─── 1.1 : Créer la collection avec validation ────────────────────────────────
db.createCollection("patients", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["cin", "nom", "prenom", "dateNaissance", "sexe"],
      properties: {
        cin: {
          bsonType: "string",
          minLength: 12,
          maxLength: 18,
          description: "Numéro CIN obligatoire"
        },
        nom: {
          bsonType: "string",
          description: "Nom de famille obligatoire"
        },
        prenom: {
          bsonType: "string",
          description: "Prénom obligatoire"
        },
        dateNaissance: {
          bsonType: "date",
          description: "Date de naissance obligatoire"
        },
        sexe: {
          bsonType: "string",
          enum: ["M", "F"],
          description: "Sexe : M ou F"
        },
        adresse: {
          bsonType: "object",
          properties: {
            wilaya: { bsonType: "string" },
            commune: { bsonType: "string" }
          }
        },
        groupeSanguin: {
          bsonType: "string",
          enum: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
        },
        antecedents: {
          bsonType: "array",
          items: { bsonType: "string" }
        },
        allergies: {
          bsonType: "array",
          items: { bsonType: "string" }
        },
        consultations: {
          bsonType: "array"
        }
      }
    }
  }
});

// ─── 1.2 : Insérer 20 patients avec données algériennes réalistes ─────────────
const patients = [
  {
    cin: "198001012300",
    nom: "Bensalem",
    prenom: "Ahmed",
    dateNaissance: new Date("1980-01-01"),
    sexe: "M",
    adresse: { wilaya: "Alger", commune: "Bab Ezzouar" },
    groupeSanguin: "O+",
    antecedents: ["Diabète type 2", "HTA"],
    allergies: ["Pénicilline"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-15"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Hypertension artérielle",
        tension: { systolique: 145, diastolique: 92 },
        medicaments: [
          { nom: "Amlodipine", dosage: "5mg", duree: "30 jours" },
          { nom: "Metformine", dosage: "500mg", duree: "90 jours" }
        ],
        notes: "Surveillance tensionnelle recommandée"
      },
      {
        id: UUID(),
        date: new Date("2024-04-10"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Contrôle HTA - stabilisé",
        tension: { systolique: 132, diastolique: 84 },
        medicaments: [
          { nom: "Amlodipine", dosage: "5mg", duree: "30 jours" }
        ],
        notes: "Bonne observance du traitement"
      }
    ]
  },
  {
    cin: "199205153400",
    nom: "Ouali",
    prenom: "Fatima",
    dateNaissance: new Date("1992-05-15"),
    sexe: "F",
    adresse: { wilaya: "Oran", commune: "Bir El Djir" },
    groupeSanguin: "A+",
    antecedents: ["Asthme"],
    allergies: ["Aspirine"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-02-20"),
        medecin: { nom: "Dr. Khelifi", specialite: "Pneumologie" },
        diagnostic: "Crise d'asthme légère",
        tension: { systolique: 118, diastolique: 75 },
        medicaments: [
          { nom: "Salbutamol", dosage: "100mcg", duree: "7 jours" },
          { nom: "Budésonide", dosage: "200mcg", duree: "30 jours" }
        ],
        notes: "Éviter les allergènes"
      },
      {
        id: UUID(),
        date: new Date("2024-06-05"),
        medecin: { nom: "Dr. Khelifi", specialite: "Pneumologie" },
        diagnostic: "Contrôle asthme - stable",
        tension: { systolique: 115, diastolique: 72 },
        medicaments: [{ nom: "Budésonide", dosage: "200mcg", duree: "30 jours" }],
        notes: "Spirométrie normale"
      }
    ]
  },
  {
    cin: "197512248900",
    nom: "Meziane",
    prenom: "Karim",
    dateNaissance: new Date("1975-12-24"),
    sexe: "M",
    adresse: { wilaya: "Constantine", commune: "El Khroub" },
    groupeSanguin: "B+",
    antecedents: ["Diabète type 2", "HTA", "Insuffisance rénale légère"],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-08"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Diabète mal équilibré",
        tension: { systolique: 152, diastolique: 98 },
        medicaments: [
          { nom: "Insuline Glargine", dosage: "20UI", duree: "30 jours" },
          { nom: "Ramipril", dosage: "5mg", duree: "30 jours" }
        ],
        notes: "HbA1c : 9.2% - régime strict requis"
      },
      {
        id: UUID(),
        date: new Date("2024-03-15"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Suivi diabète",
        tension: { systolique: 138, diastolique: 88 },
        medicaments: [
          { nom: "Insuline Glargine", dosage: "22UI", duree: "30 jours" }
        ],
        notes: "HbA1c : 8.1% - amélioration"
      },
      {
        id: UUID(),
        date: new Date("2024-07-22"),
        medecin: { nom: "Dr. Aoudia", specialite: "Néphrologie" },
        diagnostic: "Contrôle rénal",
        tension: { systolique: 140, diastolique: 90 },
        medicaments: [{ nom: "Ramipril", dosage: "10mg", duree: "30 jours" }],
        notes: "Créatinine stable à 1.4 mg/dL"
      }
    ]
  },
  {
    cin: "198806197800",
    nom: "Hamdi",
    prenom: "Yasmina",
    dateNaissance: new Date("1988-06-19"),
    sexe: "F",
    adresse: { wilaya: "Annaba", commune: "El Bouni" },
    groupeSanguin: "O-",
    antecedents: [],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-03-01"),
        medecin: { nom: "Dr. Saidi", specialite: "Médecine Générale" },
        diagnostic: "Grippe saisonnière",
        tension: { systolique: 110, diastolique: 70 },
        medicaments: [
          { nom: "Paracétamol", dosage: "1000mg", duree: "5 jours" },
          { nom: "Ibuprofène", dosage: "400mg", duree: "3 jours" }
        ],
        notes: "Repos recommandé"
      }
    ]
  },
  {
    cin: "196308045600",
    nom: "Belkacem",
    prenom: "Abdelkader",
    dateNaissance: new Date("1963-08-04"),
    sexe: "M",
    adresse: { wilaya: "Blida", commune: "Boufarik" },
    groupeSanguin: "AB+",
    antecedents: ["HTA", "Cardiopathie ischémique"],
    allergies: ["Codéine"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-20"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Angor stable",
        tension: { systolique: 148, diastolique: 95 },
        medicaments: [
          { nom: "Bisoprolol", dosage: "5mg", duree: "30 jours" },
          { nom: "Aspirine", dosage: "100mg", duree: "permanent" }
        ],
        notes: "ECG : ACFA légère"
      },
      {
        id: UUID(),
        date: new Date("2024-05-10"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Contrôle cardiaque",
        tension: { systolique: 135, diastolique: 85 },
        medicaments: [
          { nom: "Bisoprolol", dosage: "5mg", duree: "30 jours" }
        ],
        notes: "Écho cardiaque : FE 55%"
      }
    ]
  },
  {
    cin: "199110231200",
    nom: "Cherif",
    prenom: "Rania",
    dateNaissance: new Date("1991-10-23"),
    sexe: "F",
    adresse: { wilaya: "Alger", commune: "Hydra" },
    groupeSanguin: "B-",
    antecedents: ["Hypothyroïdie"],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-02-14"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Hypothyroïdie - TSH élevée",
        tension: { systolique: 105, diastolique: 65 },
        medicaments: [{ nom: "Lévothyroxine", dosage: "50mcg", duree: "90 jours" }],
        notes: "TSH : 8.2 mUI/L"
      },
      {
        id: UUID(),
        date: new Date("2024-05-20"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Suivi thyroïde",
        tension: { systolique: 110, diastolique: 70 },
        medicaments: [{ nom: "Lévothyroxine", dosage: "75mcg", duree: "90 jours" }],
        notes: "TSH : 3.1 mUI/L - dosage ajusté"
      }
    ]
  },
  {
    cin: "198304166700",
    nom: "Haddar",
    prenom: "Mourad",
    dateNaissance: new Date("1983-04-16"),
    sexe: "M",
    adresse: { wilaya: "Oran", commune: "Es Senia" },
    groupeSanguin: "A-",
    antecedents: ["Diabète type 2"],
    allergies: ["Sulfamides"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-30"),
        medecin: { nom: "Dr. Khelifi", specialite: "Endocrinologie" },
        diagnostic: "Diabète type 2 équilibré",
        tension: { systolique: 125, diastolique: 80 },
        medicaments: [{ nom: "Metformine", dosage: "1000mg", duree: "90 jours" }],
        notes: "HbA1c : 7.0% - bon équilibre"
      }
    ]
  },
  {
    cin: "197007092300",
    nom: "Amrani",
    prenom: "Fateh",
    dateNaissance: new Date("1970-07-09"),
    sexe: "M",
    adresse: { wilaya: "Constantine", commune: "Ain Smara" },
    groupeSanguin: "O+",
    antecedents: ["HTA", "Diabète type 2", "Obésité"],
    allergies: ["Pénicilline", "AINS"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-02-05"),
        medecin: { nom: "Dr. Aoudia", specialite: "Médecine Interne" },
        diagnostic: "Syndrome métabolique",
        tension: { systolique: 155, diastolique: 100 },
        medicaments: [
          { nom: "Amlodipine", dosage: "10mg", duree: "30 jours" },
          { nom: "Metformine", dosage: "500mg", duree: "30 jours" }
        ],
        notes: "IMC : 35 - régime hypocalorique strict"
      },
      {
        id: UUID(),
        date: new Date("2024-04-20"),
        medecin: { nom: "Dr. Aoudia", specialite: "Médecine Interne" },
        diagnostic: "Suivi syndrome métabolique",
        tension: { systolique: 142, diastolique: 90 },
        medicaments: [
          { nom: "Amlodipine", dosage: "10mg", duree: "30 jours" }
        ],
        notes: "Perte de 3kg - encourageant"
      },
      {
        id: UUID(),
        date: new Date("2024-08-15"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Contrôle diabète",
        tension: { systolique: 138, diastolique: 87 },
        medicaments: [{ nom: "Metformine", dosage: "1000mg", duree: "90 jours" }],
        notes: "HbA1c : 7.8%"
      }
    ]
  },
  {
    cin: "199509281500",
    nom: "Boudia",
    prenom: "Selma",
    dateNaissance: new Date("1995-09-28"),
    sexe: "F",
    adresse: { wilaya: "Blida", commune: "Bougara" },
    groupeSanguin: "AB-",
    antecedents: [],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-03-12"),
        medecin: { nom: "Dr. Saidi", specialite: "Gynécologie" },
        diagnostic: "Consultation de routine",
        tension: { systolique: 108, diastolique: 68 },
        medicaments: [{ nom: "Acide folique", dosage: "0.4mg", duree: "90 jours" }],
        notes: "Bonne santé générale"
      }
    ]
  },
  {
    cin: "196012317800",
    nom: "Derbal",
    prenom: "Hocine",
    dateNaissance: new Date("1960-12-31"),
    sexe: "M",
    adresse: { wilaya: "Annaba", commune: "Seraidi" },
    groupeSanguin: "B+",
    antecedents: ["Diabète type 2", "HTA", "Arthrose"],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-10"),
        medecin: { nom: "Dr. Mansouri", specialite: "Rhumatologie" },
        diagnostic: "Arthrose sévère genoux",
        tension: { systolique: 143, diastolique: 91 },
        medicaments: [
          { nom: "Paracétamol", dosage: "1000mg", duree: "30 jours" },
          { nom: "Glucosamine", dosage: "1500mg", duree: "90 jours" }
        ],
        notes: "Kiné recommandée"
      },
      {
        id: UUID(),
        date: new Date("2024-06-18"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Diabète type 2 - contrôle",
        tension: { systolique: 140, diastolique: 88 },
        medicaments: [
          { nom: "Metformine", dosage: "850mg", duree: "90 jours" },
          { nom: "Gliclazide", dosage: "60mg", duree: "30 jours" }
        ],
        notes: "HbA1c : 8.5%"
      }
    ]
  },
  {
    cin: "198803225600",
    nom: "Meguenni",
    prenom: "Nassim",
    dateNaissance: new Date("1988-03-22"),
    sexe: "M",
    adresse: { wilaya: "Alger", commune: "Dar El Beida" },
    groupeSanguin: "O+",
    antecedents: [],
    allergies: ["Pénicilline"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-04-01"),
        medecin: { nom: "Dr. Khelifi", specialite: "Médecine Générale" },
        diagnostic: "Sinusite aiguë",
        tension: { systolique: 120, diastolique: 78 },
        medicaments: [
          { nom: "Azithromycine", dosage: "500mg", duree: "5 jours" }
        ],
        notes: "Allergie pénicilline notée"
      }
    ]
  },
  {
    cin: "197411301100",
    nom: "Brahimi",
    prenom: "Nadia",
    dateNaissance: new Date("1974-11-30"),
    sexe: "F",
    adresse: { wilaya: "Oran", commune: "Arzew" },
    groupeSanguin: "A+",
    antecedents: ["HTA"],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-02-28"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "HTA contrôlée",
        tension: { systolique: 130, diastolique: 82 },
        medicaments: [{ nom: "Losartan", dosage: "50mg", duree: "30 jours" }],
        notes: "Bonne observance"
      },
      {
        id: UUID(),
        date: new Date("2024-07-05"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "HTA - suivi",
        tension: { systolique: 128, diastolique: 80 },
        medicaments: [{ nom: "Losartan", dosage: "50mg", duree: "30 jours" }],
        notes: "Stable"
      }
    ]
  },
  {
    cin: "200101084500",
    nom: "Tlemcani",
    prenom: "Zakia",
    dateNaissance: new Date("2001-01-08"),
    sexe: "F",
    adresse: { wilaya: "Alger", commune: "El Harrach" },
    groupeSanguin: "A-",
    antecedents: [],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-05-15"),
        medecin: { nom: "Dr. Saidi", specialite: "Médecine Générale" },
        diagnostic: "Angine streptococcique",
        tension: { systolique: 112, diastolique: 72 },
        medicaments: [{ nom: "Amoxicilline", dosage: "1000mg", duree: "8 jours" }],
        notes: "TDR positif"
      }
    ]
  },
  {
    cin: "198609147800",
    nom: "Bouzid",
    prenom: "Rachid",
    dateNaissance: new Date("1986-09-14"),
    sexe: "M",
    adresse: { wilaya: "Constantine", commune: "Hamma Bouziane" },
    groupeSanguin: "B-",
    antecedents: ["Asthme", "Rhinite allergique"],
    allergies: ["Aspirine", "AINS"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-03-25"),
        medecin: { nom: "Dr. Khelifi", specialite: "Pneumologie" },
        diagnostic: "Asthme allergique persistant",
        tension: { systolique: 117, diastolique: 74 },
        medicaments: [
          { nom: "Fluticasone", dosage: "250mcg", duree: "30 jours" },
          { nom: "Salbutamol", dosage: "100mcg", duree: "si besoin" }
        ],
        notes: "Éviter les AINS - risque anaphylaxie"
      }
    ]
  },
  {
    cin: "196702196700",
    nom: "Larbi",
    prenom: "Djamila",
    dateNaissance: new Date("1967-02-19"),
    sexe: "F",
    adresse: { wilaya: "Annaba", commune: "El Hadjar" },
    groupeSanguin: "O-",
    antecedents: ["Diabète type 2", "HTA", "Dyslipidémie"],
    allergies: ["Pénicilline"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-25"),
        medecin: { nom: "Dr. Aoudia", specialite: "Médecine Interne" },
        diagnostic: "Bilan de santé annuel",
        tension: { systolique: 150, diastolique: 96 },
        medicaments: [
          { nom: "Metformine", dosage: "1000mg", duree: "90 jours" },
          { nom: "Atorvastatine", dosage: "20mg", duree: "90 jours" }
        ],
        notes: "LDL : 1.65 g/L - cible < 1.0 g/L"
      },
      {
        id: UUID(),
        date: new Date("2024-07-30"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Contrôle cardiovasculaire",
        tension: { systolique: 138, diastolique: 88 },
        medicaments: [
          { nom: "Amlodipine", dosage: "5mg", duree: "30 jours" }
        ],
        notes: "Risque cardiovasculaire élevé"
      }
    ]
  },
  {
    cin: "199207312400",
    nom: "Ferhat",
    prenom: "Anis",
    dateNaissance: new Date("1992-07-31"),
    sexe: "M",
    adresse: { wilaya: "Blida", commune: "Larbaa" },
    groupeSanguin: "AB+",
    antecedents: [],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-06-10"),
        medecin: { nom: "Dr. Saidi", specialite: "Médecine Générale" },
        diagnostic: "Lombalgie aiguë",
        tension: { systolique: 122, diastolique: 79 },
        medicaments: [
          { nom: "Ibuprofène", dosage: "400mg", duree: "7 jours" },
          { nom: "Myolastan", dosage: "50mg", duree: "5 jours" }
        ],
        notes: "Repos et kiné"
      }
    ]
  },
  {
    cin: "197808092100",
    nom: "Benabbas",
    prenom: "Khaled",
    dateNaissance: new Date("1978-08-09"),
    sexe: "M",
    adresse: { wilaya: "Alger", commune: "Bab Ezzouar" },
    groupeSanguin: "A+",
    antecedents: ["HTA"],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-02-10"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "HTA grade 2",
        tension: { systolique: 160, diastolique: 100 },
        medicaments: [
          { nom: "Lisinopril", dosage: "10mg", duree: "30 jours" },
          { nom: "Hydrochlorothiazide", dosage: "12.5mg", duree: "30 jours" }
        ],
        notes: "Bilan lipidique à faire"
      },
      {
        id: UUID(),
        date: new Date("2024-05-25"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "HTA - amélioration",
        tension: { systolique: 135, diastolique: 85 },
        medicaments: [{ nom: "Lisinopril", dosage: "10mg", duree: "30 jours" }],
        notes: "Continuer le traitement"
      }
    ]
  },
  {
    cin: "198505042300",
    nom: "Rahmani",
    prenom: "Sihem",
    dateNaissance: new Date("1985-05-04"),
    sexe: "F",
    adresse: { wilaya: "Oran", commune: "Bir El Djir" },
    groupeSanguin: "O+",
    antecedents: ["Thyroïdite d'Hashimoto"],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-04-15"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Hypothyroïdie sur Hashimoto",
        tension: { systolique: 108, diastolique: 68 },
        medicaments: [{ nom: "Lévothyroxine", dosage: "100mcg", duree: "90 jours" }],
        notes: "TSH : 5.6 - anticorps anti-TPO positifs"
      }
    ]
  },
  {
    cin: "196809145600",
    nom: "Sadaoui",
    prenom: "Omar",
    dateNaissance: new Date("1968-09-14"),
    sexe: "M",
    adresse: { wilaya: "Constantine", commune: "El Khroub" },
    groupeSanguin: "B+",
    antecedents: ["Diabète type 2", "HTA", "BPCO"],
    allergies: ["Pénicilline"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-05"),
        medecin: { nom: "Dr. Khelifi", specialite: "Pneumologie" },
        diagnostic: "Exacerbation BPCO",
        tension: { systolique: 148, diastolique: 94 },
        medicaments: [
          { nom: "Tiotropium", dosage: "18mcg", duree: "30 jours" },
          { nom: "Azithromycine", dosage: "500mg", duree: "5 jours" }
        ],
        notes: "SpO2 : 93% - oxygénothérapie envisagée"
      },
      {
        id: UUID(),
        date: new Date("2024-04-18"),
        medecin: { nom: "Dr. Benali", specialite: "Endocrinologie" },
        diagnostic: "Diabète - suivi",
        tension: { systolique: 145, diastolique: 92 },
        medicaments: [
          { nom: "Insuline NPH", dosage: "30UI", duree: "30 jours" }
        ],
        notes: "HbA1c : 9.8% - insulinothérapie instaurée"
      }
    ]
  }
];

db.patients.insertMany(patients);

// ─── 1.3 : Collection analyses (référencée) ───────────────────────────────────
// Récupérer les IDs des patients insérés
const p = db.patients.find({}, { _id: 1, cin: 1 }).toArray();
const getPatientId = (cin) => p.find(x => x.cin === cin)?._id;

const analyses = [
  {
    patient_id: getPatientId("198001012300"),
    date: new Date("2024-01-12"),
    type: "Glycémie",
    resultats: { glucose_gl: 1.85, interpretation: "Diabète déséquilibré" },
    laboratoire: "Labo Central Alger",
    valide: true
  },
  {
    patient_id: getPatientId("198001012300"),
    date: new Date("2024-01-12"),
    type: "Lipidogramme",
    resultats: { cholesterol_total: 2.1, ldl: 1.3, hdl: 0.45, triglycerides: 1.8 },
    laboratoire: "Labo Central Alger",
    valide: true
  },
  {
    patient_id: getPatientId("197512248900"),
    date: new Date("2024-01-05"),
    type: "Glycémie",
    resultats: { glucose_gl: 2.45, hba1c: 9.2, interpretation: "Diabète très déséquilibré" },
    laboratoire: "Labo Constantine",
    valide: true
  },
  {
    patient_id: getPatientId("197512248900"),
    date: new Date("2024-01-05"),
    type: "Créatinine",
    resultats: { creatinine_mgdl: 1.4, dfg: 55, interpretation: "IRC stade 2" },
    laboratoire: "Labo Constantine",
    valide: true
  },
  {
    patient_id: getPatientId("196308045600"),
    date: new Date("2024-01-18"),
    type: "ECG",
    resultats: { rythme: "ACFA", fc: 88, anomalies: "Fibrillation auriculaire légère" },
    laboratoire: "Clinique Cardiologique Blida",
    valide: true
  },
  {
    patient_id: getPatientId("196712196700"),
    date: new Date("2024-01-22"),
    type: "NFS",
    resultats: { hemoglobine: 11.2, globulesRouges: 3.8, globulesBlancs: 8500, plaquettes: 280000 },
    laboratoire: "Labo Annaba",
    valide: true
  },
  {
    patient_id: getPatientId("196712196700"),
    date: new Date("2024-01-22"),
    type: "Glycémie",
    resultats: { glucose_gl: 1.95, hba1c: 8.1, interpretation: "Diabète déséquilibré" },
    laboratoire: "Labo Annaba",
    valide: true
  },
  {
    patient_id: getPatientId("196712196700"),
    date: new Date("2024-01-22"),
    type: "Lipidogramme",
    resultats: { cholesterol_total: 2.8, ldl: 1.65, hdl: 0.38, triglycerides: 2.1 },
    laboratoire: "Labo Annaba",
    valide: true
  },
  {
    patient_id: getPatientId("197808092100"),
    date: new Date("2024-02-08"),
    type: "Lipidogramme",
    resultats: { cholesterol_total: 2.3, ldl: 1.5, hdl: 0.42, triglycerides: 1.9 },
    laboratoire: "Labo Central Alger",
    valide: true
  },
  {
    patient_id: getPatientId("196809145600"),
    date: new Date("2024-01-03"),
    type: "NFS",
    resultats: { hemoglobine: 12.8, globulesRouges: 4.2, globulesBlancs: 12000, plaquettes: 310000 },
    laboratoire: "Labo Constantine",
    valide: true
  }
];

db.analyses.insertMany(analyses);

print("✅ Modélisation terminée. Patients insérés:", db.patients.countDocuments());
print("✅ Analyses insérées:", db.analyses.countDocuments());

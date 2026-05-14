// TP4 - Exercice 1 : Création du graphe UniConnect DZ
// Effacer la base pour partir propre
MATCH (n) DETACH DELETE n;

// ─── 1.1 : Contraintes d'unicité ─────────────────────────────────────────────
CREATE CONSTRAINT etudiant_id IF NOT EXISTS FOR (e:Etudiant) REQUIRE e.id IS UNIQUE;
CREATE CONSTRAINT cours_code IF NOT EXISTS FOR (c:Cours) REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT competence_nom IF NOT EXISTS FOR (c:Competence) REQUIRE c.nom IS UNIQUE;

// ─── 1.2 : Créer les compétences ──────────────────────────────────────────────
UNWIND [
  {nom: "Python",          categorie: "Programmation"},
  {nom: "Java",            categorie: "Programmation"},
  {nom: "SQL",             categorie: "Bases de Données"},
  {nom: "NoSQL",           categorie: "Bases de Données"},
  {nom: "Machine Learning",categorie: "IA"},
  {nom: "Deep Learning",   categorie: "IA"},
  {nom: "React",           categorie: "Web"},
  {nom: "Docker",          categorie: "DevOps"},
  {nom: "Linux",           categorie: "Systèmes"},
  {nom: "Réseaux",         categorie: "Infrastructure"}
] AS comp
MERGE (:Competence {nom: comp.nom, categorie: comp.categorie});

// ─── 1.3 : Créer les cours ────────────────────────────────────────────────────
UNWIND [
  {code: "INFO401", intitule: "Bases de Données Avancées", credits: 6, dept: "Informatique"},
  {code: "INFO402", intitule: "Intelligence Artificielle",  credits: 6, dept: "Informatique"},
  {code: "INFO403", intitule: "Développement Web",          credits: 4, dept: "Informatique"},
  {code: "INFO404", intitule: "Systèmes Distribués",        credits: 5, dept: "Informatique"},
  {code: "INFO405", intitule: "Cloud Computing",            credits: 4, dept: "Informatique"}
] AS cours
MERGE (:Cours {code: cours.code, intitule: cours.intitule,
               credits: cours.credits, departement: cours.dept});

// ─── Relations cours → compétences requises ────────────────────────────────────
MATCH (bdd:Cours {code: "INFO401"}),  (sql:Competence {nom: "SQL"}),
      (nosql:Competence {nom: "NoSQL"})
MERGE (bdd)-[:REQUIERT]->(sql)
MERGE (bdd)-[:REQUIERT]->(nosql);

MATCH (ia:Cours {code: "INFO402"}),   (ml:Competence {nom: "Machine Learning"}),
      (py:Competence {nom: "Python"})
MERGE (ia)-[:REQUIERT]->(ml)
MERGE (ia)-[:REQUIERT]->(py);

MATCH (web:Cours {code: "INFO403"}),  (react:Competence {nom: "React"})
MERGE (web)-[:REQUIERT]->(react);

MATCH (dist:Cours {code: "INFO404"}), (docker:Competence {nom: "Docker"}),
      (linux:Competence {nom: "Linux"})
MERGE (dist)-[:REQUIERT]->(docker)
MERGE (dist)-[:REQUIERT]->(linux);

MATCH (cloud:Cours {code: "INFO405"}),(docker2:Competence {nom: "Docker"}),
      (reseau:Competence {nom: "Réseaux"})
MERGE (cloud)-[:REQUIERT]->(docker2)
MERGE (cloud)-[:REQUIERT]->(reseau);

// ─── 1.4 : Créer les clubs ────────────────────────────────────────────────────
UNWIND [
  {nom: "Club IA USTHB",     universite: "USTHB", domaine: "Intelligence Artificielle"},
  {nom: "Club Dev UMBB",     universite: "UMBB",  domaine: "Développement Logiciel"},
  {nom: "Club Réseau USTO",  universite: "USTO",  domaine: "Réseaux & Sécurité"},
  {nom: "Club Maths UMC",    universite: "UMC",   domaine: "Mathématiques"},
  {nom: "Club Cyber UBMA",   universite: "UBMA",  domaine: "Cybersécurité"}
] AS club
MERGE (:Club {nom: club.nom, universite: club.universite, domaine: club.domaine});

// ─── 1.5 : Créer les entreprises ─────────────────────────────────────────────
UNWIND [
  {nom: "Sonatrach",    secteur: "Énergie",      ville: "Alger"},
  {nom: "Djezzy",       secteur: "Telecoms",     ville: "Alger"},
  {nom: "Ooredoo",      secteur: "Telecoms",     ville: "Alger"},
  {nom: "Cevital",      secteur: "Industrie",    ville: "Bejaia"},
  {nom: "NCA Rouïba",   secteur: "Industrie",    ville: "Alger"}
] AS ent
MERGE (:Entreprise {nom: ent.nom, secteur: ent.secteur, ville: ent.ville});

// ─── 1.6 : Créer les 50 étudiants ────────────────────────────────────────────
UNWIND [
  {id:"E001",prenom:"Ahmed",   nom:"Bensalem",  universite:"USTHB", filiere:"Informatique",  annee:3, ville:"Alger"},
  {id:"E002",prenom:"Fatima",  nom:"Ouali",     universite:"USTHB", filiere:"Informatique",  annee:3, ville:"Alger"},
  {id:"E003",prenom:"Karim",   nom:"Meziane",   universite:"UMBB",  filiere:"Informatique",  annee:2, ville:"Boumerdes"},
  {id:"E004",prenom:"Yasmina", nom:"Hamdi",     universite:"USTO",  filiere:"Informatique",  annee:4, ville:"Oran"},
  {id:"E005",prenom:"Rania",   nom:"Belkacem",  universite:"UMC",   filiere:"GL",            annee:3, ville:"Constantine"},
  {id:"E006",prenom:"Mehdi",   nom:"Derbal",    universite:"USTHB", filiere:"Electronique",  annee:2, ville:"Alger"},
  {id:"E007",prenom:"Sara",    nom:"Amrani",    universite:"UBMA",  filiere:"Telecoms",      annee:3, ville:"Annaba"},
  {id:"E008",prenom:"Youcef",  nom:"Cherif",    universite:"UMBB",  filiere:"Mathematiques", annee:4, ville:"Boumerdes"},
  {id:"E009",prenom:"Lina",    nom:"Boudia",    universite:"USTHB", filiere:"Informatique",  annee:1, ville:"Alger"},
  {id:"E010",prenom:"Anis",    nom:"Haddar",    universite:"USTO",  filiere:"GL",            annee:3, ville:"Oran"},
  {id:"E011",prenom:"Zineb",   nom:"Khaldi",    universite:"USTHB", filiere:"Informatique",  annee:4, ville:"Alger"},
  {id:"E012",prenom:"Sofiane", nom:"Boudali",   universite:"UMBB",  filiere:"GL",            annee:2, ville:"Boumerdes"},
  {id:"E013",prenom:"Nadia",   nom:"Ferhat",    universite:"USTO",  filiere:"Informatique",  annee:3, ville:"Oran"},
  {id:"E014",prenom:"Billal",  nom:"Rezgui",    universite:"UMC",   filiere:"Electronique",  annee:2, ville:"Constantine"},
  {id:"E015",prenom:"Amira",   nom:"Saadi",     universite:"UBMA",  filiere:"Informatique",  annee:4, ville:"Annaba"},
  {id:"E016",prenom:"Sami",    nom:"Haddad",    universite:"USTHB", filiere:"Mathematiques", annee:3, ville:"Alger"},
  {id:"E017",prenom:"Hanane",  nom:"Bouzid",    universite:"UMBB",  filiere:"Telecoms",      annee:3, ville:"Boumerdes"},
  {id:"E018",prenom:"Walid",   nom:"Meddah",    universite:"USTO",  filiere:"GL",            annee:1, ville:"Oran"},
  {id:"E019",prenom:"Imane",   nom:"Ramdane",   universite:"UMC",   filiere:"Informatique",  annee:4, ville:"Constantine"},
  {id:"E020",prenom:"Reda",    nom:"Bouazza",   universite:"UBMA",  filiere:"Informatique",  annee:2, ville:"Annaba"},
  {id:"E021",prenom:"Siham",   nom:"Zerrouk",   universite:"USTHB", filiere:"GL",            annee:3, ville:"Alger"},
  {id:"E022",prenom:"Fares",   nom:"Hamdani",   universite:"UMBB",  filiere:"Informatique",  annee:4, ville:"Boumerdes"},
  {id:"E023",prenom:"Asma",    nom:"Nait",      universite:"USTO",  filiere:"Mathematiques", annee:2, ville:"Oran"},
  {id:"E024",prenom:"Djamel",  nom:"Benmansour",universite:"UMC",   filiere:"Informatique",  annee:3, ville:"Constantine"},
  {id:"E025",prenom:"Houda",   nom:"Messai",    universite:"UBMA",  filiere:"GL",            annee:1, ville:"Annaba"},
  {id:"E026",prenom:"Nassim",  nom:"Taleb",     universite:"USTHB", filiere:"Informatique",  annee:2, ville:"Alger"},
  {id:"E027",prenom:"Meriem",  nom:"Benali",    universite:"UMBB",  filiere:"Electronique",  annee:3, ville:"Boumerdes"},
  {id:"E028",prenom:"Ayoub",   nom:"Djebbari",  universite:"USTO",  filiere:"Informatique",  annee:4, ville:"Oran"},
  {id:"E029",prenom:"Dalila",  nom:"Khelil",    universite:"UMC",   filiere:"Telecoms",      annee:2, ville:"Constantine"},
  {id:"E030",prenom:"Idir",    nom:"Ait",       universite:"UBMA",  filiere:"Informatique",  annee:3, ville:"Annaba"},
  {id:"E031",prenom:"Sabrina", nom:"Lahreche",  universite:"USTHB", filiere:"GL",            annee:4, ville:"Alger"},
  {id:"E032",prenom:"Hamza",   nom:"Guerroudj", universite:"UMBB",  filiere:"Informatique",  annee:1, ville:"Boumerdes"},
  {id:"E033",prenom:"Wafa",    nom:"Benguerba", universite:"USTO",  filiere:"Informatique",  annee:3, ville:"Oran"},
  {id:"E034",prenom:"Tarek",   nom:"Ouadah",    universite:"UMC",   filiere:"Mathematiques", annee:4, ville:"Constantine"},
  {id:"E035",prenom:"Chaima",  nom:"Ghomari",   universite:"UBMA",  filiere:"Informatique",  annee:2, ville:"Annaba"},
  {id:"E036",prenom:"Mourad",  nom:"Belfodil",  universite:"USTHB", filiere:"Electronique",  annee:3, ville:"Alger"},
  {id:"E037",prenom:"Nawel",   nom:"Kaci",      universite:"UMBB",  filiere:"GL",            annee:4, ville:"Boumerdes"},
  {id:"E038",prenom:"Amine",   nom:"Soufi",     universite:"USTO",  filiere:"Informatique",  annee:2, ville:"Oran"},
  {id:"E039",prenom:"Ryma",    nom:"Bettache",  universite:"UMC",   filiere:"Informatique",  annee:3, ville:"Constantine"},
  {id:"E040",prenom:"Lotfi",   nom:"Mabrouk",   universite:"UBMA",  filiere:"GL",            annee:1, ville:"Annaba"},
  {id:"E041",prenom:"Hadjer",  nom:"Benkaci",   universite:"USTHB", filiere:"Telecoms",      annee:4, ville:"Alger"},
  {id:"E042",prenom:"Oussama", nom:"Bousseraf", universite:"UMBB",  filiere:"Informatique",  annee:3, ville:"Boumerdes"},
  {id:"E043",prenom:"Feriel",  nom:"Abdi",      universite:"USTO",  filiere:"Informatique",  annee:2, ville:"Oran"},
  {id:"E044",prenom:"Khaled",  nom:"Mansouri",  universite:"UMC",   filiere:"GL",            annee:4, ville:"Constantine"},
  {id:"E045",prenom:"Melissa", nom:"Aissaoui",  universite:"UBMA",  filiere:"Informatique",  annee:3, ville:"Annaba"},
  {id:"E046",prenom:"Yacine",  nom:"Berkane",   universite:"USTHB", filiere:"Informatique",  annee:2, ville:"Alger"},
  {id:"E047",prenom:"Soraya",  nom:"Benbrahim", universite:"UMBB",  filiere:"Mathematiques", annee:3, ville:"Boumerdes"},
  {id:"E048",prenom:"Adel",    nom:"Hadjsaid",  universite:"USTO",  filiere:"Informatique",  annee:4, ville:"Oran"},
  {id:"E049",prenom:"Karima",  nom:"Ziani",     universite:"UMC",   filiere:"Informatique",  annee:1, ville:"Constantine"},
  {id:"E050",prenom:"Ilyes",   nom:"Benmoussa", universite:"UBMA",  filiere:"GL",            annee:3, ville:"Annaba"}
] AS data
MERGE (e:Etudiant {id: data.id})
SET e += data;

// ─── 1.7 : Relations CONNAIT ──────────────────────────────────────────────────
// Réseau dense garantissant la connexité du graphe
UNWIND [
  // USTHB cluster
  ["E001","E002",2023,"cours"],  ["E001","E006",2022,"club"],   ["E001","E009",2024,"cours"],
  ["E001","E011",2022,"cours"],  ["E001","E021",2023,"projet"], ["E001","E026",2023,"cours"],
  ["E002","E006",2023,"club"],   ["E002","E009",2024,"cours"],  ["E002","E016",2022,"cours"],
  ["E006","E011",2023,"cours"],  ["E009","E016",2024,"projet"], ["E011","E031",2022,"projet"],
  ["E016","E036",2023,"cours"],  ["E021","E031",2023,"cours"],  ["E026","E036",2022,"club"],
  ["E031","E041",2022,"cours"],  ["E036","E041",2023,"cours"],  ["E041","E046",2024,"club"],
  // UMBB cluster
  ["E003","E008",2023,"cours"],  ["E003","E012",2022,"club"],   ["E008","E017",2023,"cours"],
  ["E012","E017",2022,"projet"], ["E017","E022",2023,"cours"],  ["E022","E027",2022,"cours"],
  ["E027","E032",2023,"club"],   ["E032","E037",2024,"cours"],  ["E037","E042",2022,"cours"],
  ["E042","E047",2023,"cours"],  ["E047","E003",2022,"projet"],
  // USTO cluster
  ["E004","E010",2023,"cours"],  ["E010","E013",2022,"club"],   ["E013","E018",2023,"cours"],
  ["E018","E023",2024,"cours"],  ["E023","E028",2022,"cours"],  ["E028","E033",2023,"club"],
  ["E033","E038",2022,"cours"],  ["E038","E043",2023,"cours"],  ["E043","E048",2024,"projet"],
  ["E048","E004",2022,"cours"],
  // UMC cluster
  ["E005","E014",2023,"cours"],  ["E014","E019",2022,"club"],   ["E019","E024",2023,"cours"],
  ["E024","E029",2022,"cours"],  ["E029","E034",2023,"cours"],  ["E034","E039",2024,"club"],
  ["E039","E044",2022,"cours"],  ["E044","E049",2023,"cours"],  ["E049","E005",2024,"projet"],
  // UBMA cluster
  ["E007","E015",2023,"cours"],  ["E015","E020",2022,"club"],   ["E020","E025",2023,"cours"],
  ["E025","E030",2022,"cours"],  ["E030","E035",2023,"cours"],  ["E035","E040",2024,"club"],
  ["E040","E045",2022,"cours"],  ["E045","E050",2023,"cours"],  ["E050","E007",2024,"projet"],
  // Ponts inter-universités (garantit la connexité globale)
  ["E001","E003",2023,"conférence"], ["E001","E004",2022,"conférence"],
  ["E002","E005",2023,"conférence"], ["E004","E022",2022,"hackathon"],
  ["E011","E019",2023,"hackathon"],  ["E031","E039",2022,"stage"],
  ["E007","E017",2023,"conférence"], ["E005","E015",2022,"conférence"],
  ["E008","E034",2023,"hackathon"],  ["E046","E042",2022,"conférence"]
] AS rel
MATCH (a:Etudiant {id: rel[0]}), (b:Etudiant {id: rel[1]})
MERGE (a)-[:CONNAIT {depuis: rel[2], contexte: rel[3]}]->(b)
MERGE (b)-[:CONNAIT {depuis: rel[2], contexte: rel[3]}]->(a);

// ─── 1.8 : Relations SUIT (étudiant → cours) avec notes ──────────────────────
UNWIND [
  ["E001","INFO401",18.5,"S5"], ["E001","INFO402",16.0,"S5"],
  ["E002","INFO401",17.0,"S5"], ["E002","INFO403",15.5,"S5"],
  ["E003","INFO402",14.0,"S4"], ["E003","INFO403",16.5,"S4"],
  ["E004","INFO401",19.0,"S7"], ["E004","INFO404",17.5,"S7"],
  ["E005","INFO403",15.0,"S5"], ["E005","INFO405",14.5,"S5"],
  ["E006","INFO404",13.0,"S3"], ["E007","INFO405",16.0,"S5"],
  ["E008","INFO402",18.0,"S7"], ["E009","INFO401",12.5,"S1"],
  ["E010","INFO403",14.0,"S5"], ["E011","INFO401",17.5,"S7"],
  ["E011","INFO402",16.0,"S7"], ["E012","INFO403",13.5,"S3"],
  ["E013","INFO401",15.0,"S5"], ["E014","INFO404",14.0,"S3"],
  ["E015","INFO401",19.5,"S7"], ["E016","INFO402",15.0,"S5"],
  ["E017","INFO405",14.5,"S5"], ["E018","INFO403",13.0,"S1"],
  ["E019","INFO401",18.0,"S7"], ["E020","INFO402",15.5,"S3"],
  ["E021","INFO401",16.0,"S5"], ["E022","INFO402",17.0,"S7"],
  ["E023","INFO403",14.0,"S3"], ["E024","INFO401",15.5,"S5"],
  ["E025","INFO405",13.5,"S1"], ["E026","INFO402",16.5,"S3"],
  ["E027","INFO404",14.0,"S5"], ["E028","INFO401",18.5,"S7"],
  ["E029","INFO403",15.0,"S3"], ["E030","INFO402",16.0,"S5"],
  ["E031","INFO401",17.0,"S7"], ["E032","INFO403",12.5,"S1"],
  ["E033","INFO402",15.0,"S5"], ["E034","INFO401",18.0,"S7"],
  ["E035","INFO404",14.5,"S3"], ["E036","INFO402",13.0,"S5"],
  ["E037","INFO401",16.5,"S7"], ["E038","INFO403",15.0,"S3"],
  ["E039","INFO402",17.0,"S5"], ["E040","INFO405",13.5,"S1"],
  ["E041","INFO401",18.0,"S7"], ["E042","INFO403",14.5,"S5"],
  ["E043","INFO402",15.5,"S3"], ["E044","INFO401",17.5,"S7"]
] AS suit
MATCH (e:Etudiant {id: suit[0]}), (c:Cours {code: suit[1]})
MERGE (e)-[:SUIT {note: suit[2], semestre: suit[3]}]->(c);

// ─── 1.9 : Relations MAITRISE (étudiant → compétence) ─────────────────────────
UNWIND [
  ["E001","Python","expert"],     ["E001","SQL","intermédiaire"],
  ["E002","Java","expert"],       ["E002","React","intermédiaire"],
  ["E003","Python","intermédiaire"],["E003","Docker","débutant"],
  ["E004","SQL","expert"],        ["E004","NoSQL","expert"],
  ["E005","React","intermédiaire"],["E005","Python","débutant"],
  ["E006","Linux","intermédiaire"],["E006","Réseaux","intermédiaire"],
  ["E007","Réseaux","expert"],    ["E008","Machine Learning","expert"],
  ["E009","Python","débutant"],   ["E010","React","intermédiaire"],
  ["E011","Python","expert"],     ["E011","Machine Learning","intermédiaire"],
  ["E012","Java","intermédiaire"],["E013","SQL","intermédiaire"],
  ["E014","Linux","débutant"],    ["E015","NoSQL","expert"],
  ["E016","Machine Learning","intermédiaire"],["E017","Réseaux","intermédiaire"],
  ["E018","React","débutant"],    ["E019","Python","expert"],
  ["E019","SQL","expert"],        ["E020","Docker","intermédiaire"],
  ["E021","Python","intermédiaire"],["E022","Machine Learning","expert"],
  ["E023","Java","intermédiaire"], ["E024","SQL","expert"],
  ["E025","React","débutant"],    ["E026","Python","intermédiaire"],
  ["E027","Linux","intermédiaire"],["E028","NoSQL","expert"],
  ["E028","Python","expert"],     ["E029","Réseaux","intermédiaire"],
  ["E030","Machine Learning","intermédiaire"],["E031","Python","expert"],
  ["E031","Docker","expert"],     ["E032","Java","débutant"],
  ["E033","SQL","intermédiaire"], ["E034","Machine Learning","expert"],
  ["E034","Deep Learning","intermédiaire"],   ["E035","React","intermédiaire"],
  ["E036","Réseaux","intermédiaire"],["E037","Python","expert"],
  ["E038","SQL","intermédiaire"], ["E039","Machine Learning","intermédiaire"],
  ["E040","Docker","débutant"],   ["E041","Python","expert"],
  ["E041","NoSQL","expert"],      ["E042","Java","intermédiaire"],
  ["E043","SQL","intermédiaire"], ["E044","Python","expert"],
  ["E045","Machine Learning","intermédiaire"],["E046","Python","intermédiaire"],
  ["E047","Machine Learning","expert"],["E048","NoSQL","expert"],
  ["E049","React","débutant"],    ["E050","Python","intermédiaire"]
] AS mait
MATCH (e:Etudiant {id: mait[0]}), (c:Competence {nom: mait[1]})
MERGE (e)-[:MAITRISE {niveau: mait[2]}]->(c);

// ─── 1.10 : Relations MEMBRE_DE ───────────────────────────────────────────────
UNWIND [
  ["E001","Club IA USTHB","président"],   ["E002","Club IA USTHB","membre"],
  ["E003","Club Dev UMBB","membre"],      ["E004","Club Réseau USTO","vice-président"],
  ["E005","Club Maths UMC","membre"],     ["E006","Club IA USTHB","membre"],
  ["E007","Club Cyber UBMA","président"], ["E008","Club Dev UMBB","membre"],
  ["E009","Club IA USTHB","membre"],      ["E011","Club IA USTHB","trésorier"],
  ["E012","Club Dev UMBB","membre"],      ["E013","Club Réseau USTO","membre"],
  ["E015","Club Cyber UBMA","membre"],    ["E019","Club Maths UMC","président"],
  ["E022","Club Dev UMBB","vice-président"],["E028","Club Réseau USTO","membre"],
  ["E031","Club IA USTHB","membre"],      ["E034","Club Maths UMC","membre"],
  ["E037","Club Dev UMBB","membre"],      ["E041","Club IA USTHB","membre"],
  ["E044","Club Maths UMC","membre"],     ["E047","Club Dev UMBB","membre"],
  ["E048","Club Réseau USTO","membre"]
] AS memb
MATCH (e:Etudiant {id: memb[0]}), (c:Club {nom: memb[1]})
MERGE (e)-[:MEMBRE_DE {role: memb[2]}]->(c);

// ─── 1.11 : Relations A_STAGE_CHEZ ────────────────────────────────────────────
UNWIND [
  ["E004","Sonatrach",   2023, 6],
  ["E008","Djezzy",      2022, 3],
  ["E011","Cevital",     2023, 6],
  ["E015","Ooredoo",     2022, 6],
  ["E019","Sonatrach",   2023, 3],
  ["E022","NCA Rouïba",  2022, 3],
  ["E028","Djezzy",      2023, 6],
  ["E031","Sonatrach",   2022, 6],
  ["E034","Cevital",     2023, 3],
  ["E037","Ooredoo",     2023, 6],
  ["E041","Sonatrach",   2022, 6],
  ["E044","NCA Rouïba",  2023, 3],
  ["E048","Djezzy",      2022, 6]
] AS stage
MATCH (e:Etudiant {id: stage[0]}), (ent:Entreprise {nom: stage[1]})
MERGE (e)-[:A_STAGE_CHEZ {annee: stage[2], duree_mois: stage[3]}]->(ent);

// ─── 1.12 : Import CSV (données supplémentaires depuis le fichier fourni) ──────
// Exécuter si Neo4j a accès au fichier import/students.csv
// LOAD CSV WITH HEADERS FROM 'file:///students.csv' AS row
// MERGE (e:Etudiant { id: row.id })
// SET e.prenom     = row.prenom,
//     e.nom        = row.nom,
//     e.universite = row.universite,
//     e.filiere    = row.filiere,
//     e.annee      = toInteger(row.annee),
//     e.ville      = row.ville;

// ─── Vérification finale ──────────────────────────────────────────────────────
MATCH (n) RETURN labels(n)[0] AS type, count(n) AS total ORDER BY total DESC;
MATCH ()-[r]->() RETURN type(r) AS relation, count(r) AS total ORDER BY total DESC;

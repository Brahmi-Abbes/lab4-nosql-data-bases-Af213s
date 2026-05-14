// TP4 - Exercice 4 : Requêtes Avancées

// ─── 4.1 : Trouver un tuteur ──────────────────────────────────────────────────
// "Étudiant en Master (annee 4) qui maîtrise Python ET a eu >14/20 en BDD"
MATCH (tuteur:Etudiant)-[m:MAITRISE]->(comp:Competence {nom: "Python"})
MATCH (tuteur)-[s:SUIT]->(bdd:Cours {code: "INFO401"})
WHERE tuteur.annee = 4
  AND m.niveau IN ["intermédiaire", "expert"]
  AND s.note > 14
RETURN tuteur.prenom        AS tuteur,
       tuteur.universite    AS universite,
       tuteur.filiere       AS filiere,
       m.niveau             AS niveau_python,
       s.note               AS note_bdd
ORDER BY s.note DESC;

// ─── 4.2 : Réseau alumni dans une entreprise (jusqu'à 3 sauts) ───────────────
// "Qui de mon réseau (jusqu'à 3 sauts) travaille chez Sonatrach ?"
MATCH (moi:Etudiant {prenom: "Ahmed"})
MATCH path = (moi)-[:CONNAIT*1..3]-(contact:Etudiant)-[:A_STAGE_CHEZ]->(ent:Entreprise {nom: "Sonatrach"})
WITH contact, ent, min(length(path) - 1) AS distance
RETURN contact.prenom      AS contact,
       contact.universite  AS universite,
       ent.nom             AS entreprise,
       distance            AS degres_de_separation
ORDER BY distance, contact.prenom;

// ─── 4.3 : Détection de ponts ────────────────────────────────────────────────
// Étudiants dont les amis appartiennent à plusieurs universités différentes
// (connectent des communautés potentiellement isolées)
MATCH (pont:Etudiant)-[:CONNAIT]-(voisin:Etudiant)
WITH pont, collect(DISTINCT voisin.universite) AS universites_voisines
WHERE size(universites_voisines) >= 3
RETURN pont.prenom        AS etudiant_pont,
       pont.universite    AS universite,
       universites_voisines,
       size(universites_voisines) AS nb_universites_reliees
ORDER BY nb_universites_reliees DESC;

// ─── 4.4 : Analyse temporelle — Nouvelles connexions par année ────────────────
MATCH ()-[r:CONNAIT]->()
WITH r.depuis AS annee, count(r) / 2 AS nouvelles_connexions
RETURN annee,
       nouvelles_connexions
ORDER BY annee;

// ─── 4.5 : Score de similarité de Jaccard ────────────────────────────────────
// "Étudiants les plus similaires à Ahmed"
// Jaccard = |intersection| / |union|  sur (cours ∪ compétences ∪ clubs)
MATCH (ahmed:Etudiant {prenom: "Ahmed"})

// Ensemble A : cours + compétences d'Ahmed
MATCH (ahmed)-[:SUIT|MAITRISE]->(itemA)
WITH ahmed, collect(DISTINCT id(itemA)) AS setA

MATCH (autre:Etudiant)
WHERE autre <> ahmed

// Ensemble B : cours + compétences de l'autre étudiant
MATCH (autre)-[:SUIT|MAITRISE]->(itemB)
WITH ahmed, autre, setA, collect(DISTINCT id(itemB)) AS setB

// Calcul Jaccard
WITH autre,
     [x IN setA WHERE x IN setB]   AS inter,
     [x IN setA + setB WHERE true]  AS union_list,
     setA, setB
WITH autre,
     size(inter)                                    AS intersection,
     size(setA) + size(setB) - size(inter)          AS union_size
WHERE union_size > 0
RETURN autre.prenom      AS etudiant,
       autre.universite  AS universite,
       round(100.0 * intersection / union_size, 2)  AS jaccard_pct
ORDER BY jaccard_pct DESC
LIMIT 10;

// TP4 - Exercice 2 : Requêtes de Base

// ─── 2.1 : Tous les amis d'Ahmed (1 saut) ────────────────────────────────────
MATCH (ahmed:Etudiant {prenom: "Ahmed"})-[:CONNAIT]-(ami:Etudiant)
RETURN ami.prenom AS ami, ami.universite AS universite, ami.filiere AS filiere
ORDER BY ami.prenom;

// ─── 2.2 : Amis d'amis d'Ahmed qui ne sont pas déjà ses amis ─────────────────
MATCH (ahmed:Etudiant {prenom: "Ahmed"})-[:CONNAIT]-(ami:Etudiant)-[:CONNAIT]-(suggestion:Etudiant)
WHERE NOT (ahmed)-[:CONNAIT]-(suggestion)
  AND suggestion <> ahmed
RETURN DISTINCT suggestion.prenom      AS suggestion,
                suggestion.universite  AS universite,
                suggestion.filiere     AS filiere
ORDER BY suggestion.prenom;

// ─── 2.3 : Étudiants qui suivent le même cours que Fatima mais ne la connaissent pas ──
MATCH (fatima:Etudiant {prenom: "Fatima"})-[:SUIT]->(cours:Cours)
      <-[:SUIT]-(autre:Etudiant)
WHERE NOT (fatima)-[:CONNAIT]-(autre)
  AND autre <> fatima
RETURN DISTINCT autre.prenom AS etudiant,
                autre.universite AS universite,
                cours.intitule AS cours_commun
ORDER BY cours_commun, etudiant;

// ─── 2.4 : Clubs les plus populaires (par nombre de membres) ─────────────────
MATCH (e:Etudiant)-[:MEMBRE_DE]->(c:Club)
RETURN c.nom          AS club,
       c.universite   AS universite,
       c.domaine      AS domaine,
       count(e)       AS nb_membres
ORDER BY nb_membres DESC;

// ─── 2.5 : Profil complet d'un étudiant (amis, cours, compétences, clubs) ─────
MATCH (e:Etudiant {prenom: "Ahmed"})
OPTIONAL MATCH (e)-[:CONNAIT]-(ami:Etudiant)
OPTIONAL MATCH (e)-[s:SUIT]->(cours:Cours)
OPTIONAL MATCH (e)-[m:MAITRISE]->(comp:Competence)
OPTIONAL MATCH (e)-[mb:MEMBRE_DE]->(club:Club)
RETURN e.prenom        AS prenom,
       e.universite    AS universite,
       e.filiere       AS filiere,
       e.annee         AS annee,
       collect(DISTINCT ami.prenom)  AS amis,
       collect(DISTINCT {cours: cours.intitule, note: s.note}) AS cours_suivis,
       collect(DISTINCT {competence: comp.nom, niveau: m.niveau}) AS competences,
       collect(DISTINCT {club: club.nom, role: mb.role}) AS clubs;

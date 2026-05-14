// TP4 - Exercice 3 : Algorithmes de Graphe avec GDS
// Prérequis : Plugin Graph Data Science installé (inclus dans docker-compose)

// ─── 3.1 : Plus court chemin entre Ahmed et Yasmina ──────────────────────────
MATCH p = shortestPath(
  (a:Etudiant {prenom: "Ahmed"})-[:CONNAIT*..10]-(b:Etudiant {prenom: "Yasmina"})
)
RETURN [n IN nodes(p) | n.prenom + " (" + n.universite + ")"] AS chemin,
       length(p) AS nb_intermediaires;

// ─── 3.2 : Centralité de degré — Top 10 étudiants les plus connectés ─────────
// Projeter le graphe en mémoire
CALL gds.graph.project(
  'reseau_social',
  'Etudiant',
  {
    CONNAIT: { orientation: 'UNDIRECTED' }
  }
);

// Calculer la centralité de degré
CALL gds.degree.stream('reseau_social')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).prenom      AS etudiant,
       gds.util.asNode(nodeId).universite  AS universite,
       score                               AS nb_connexions
ORDER BY score DESC
LIMIT 10;

// ─── 3.3 : Détection de communautés (algorithme de Louvain) ──────────────────
CALL gds.louvain.stream('reseau_social')
YIELD nodeId, communityId
WITH communityId,
     collect(gds.util.asNode(nodeId).prenom + " (" +
             gds.util.asNode(nodeId).universite + ")") AS membres
RETURN communityId,
       size(membres)    AS taille,
       membres[0..5]    AS exemple_membres
ORDER BY taille DESC;

// ─── 3.4 : Recommandation de contacts pour Ahmed ─────────────────────────────
// Score = amis_communs * 3 + cours_communs * 2 + (même_filière ? 1 : 0)
MATCH (moi:Etudiant {prenom: "Ahmed"})

// Candidats : ni moi-même, ni déjà connecté
MATCH (suggestion:Etudiant)
WHERE suggestion <> moi
  AND NOT (moi)-[:CONNAIT]-(suggestion)

// Amis en commun
OPTIONAL MATCH (moi)-[:CONNAIT]-(ami:Etudiant)-[:CONNAIT]-(suggestion)
WITH moi, suggestion, count(DISTINCT ami) AS amis_communs

// Cours en commun
OPTIONAL MATCH (moi)-[:SUIT]->(cours:Cours)<-[:SUIT]-(suggestion)
WITH moi, suggestion, amis_communs, count(DISTINCT cours) AS cours_communs

// Score composite
WITH suggestion,
     amis_communs,
     cours_communs,
     (amis_communs * 3 + cours_communs * 2 +
      CASE WHEN suggestion.filiere = moi.filiere THEN 1 ELSE 0 END
     ) AS score,
     moi
WHERE score > 0
RETURN suggestion.prenom      AS suggestion,
       suggestion.universite  AS universite,
       suggestion.filiere     AS filiere,
       amis_communs,
       cours_communs,
       score
ORDER BY score DESC
LIMIT 5;

// ─── 3.5 : Chemin de compétences ─────────────────────────────────────────────
// "Quels cours mènent à la compétence Machine Learning ?"
MATCH path = (debut:Cours)-[:REQUIERT*1..3]->(but:Competence {nom: "Machine Learning"})
RETURN [n IN nodes(path) |
  CASE WHEN n:Cours THEN n.intitule ELSE n.nom END
] AS parcours_apprentissage
ORDER BY length(path);

// ─── Nettoyage de la projection GDS ──────────────────────────────────────────
CALL gds.graph.drop('reseau_social');

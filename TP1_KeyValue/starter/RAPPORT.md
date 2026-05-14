# RAPPORT TP1 — Redis : Système de Cache E-commerce ShopFast

## 1. Comparaison de Performance : Cache HIT vs MISS

| Métrique | Cache MISS | Cache HIT |
|----------|-----------|-----------|
| Temps moyen | ~2001 ms | ~0.2 ms |
| Facteur d'accélération | 1x (référence) | **~10 000x plus rapide** |
| Source des données | PostgreSQL (simulé) | Redis (mémoire) |

**Résultat du benchmark (10 itérations) :**
- 1ère requête : CACHE MISS (~2000ms) — aller en base
- Requêtes 2-10 : CACHE HIT (~0.2ms) — servies depuis Redis
- Hit rate : 90% (après le premier MISS)

---

## 2. Justification des Choix de Modélisation

### Structure Hash pour les produits (`product:{id}`)
- **Pourquoi Hash ?** Un produit est un objet structuré avec plusieurs champs (name, price, category, stock). Le Hash permet de lire ou modifier un seul champ sans re-sérialiser tout l'objet (contrairement à JSON dans une String).
- **Alternative écartée :** String + JSON — oblige à désérialiser tout l'objet pour modifier une seule valeur.

### Structure Hash pour les paniers (`cart:{user_id}`)
- **Pourquoi Hash ?** Le panier est une map `product_id → quantité`. `HINCRBY` permet d'incrémenter atomiquement la quantité sans lire avant d'écrire.
- **Clé de champ :** product_id (converti en string).

### Structure List pour l'historique (`history:{user_id}`)
- **Pourquoi List ?** L'historique est une liste ordonnée par temps d'accès. `LPUSH` ajoute en tête (LIFO), `LTRIM` maintient la taille maximale en O(1).
- **Alternative écartée :** Set — ne préserve pas l'ordre temporel.

### Structure Set pour les catégories (`category:{name}`)
- **Pourquoi Set ?** Les catégories sont des ensembles sans doublons. `SINTER` permet d'effectuer des intersections de catégories en une seule commande (ex: produits qui sont à la fois "electronics" ET "promo").

### Structure Sorted Set pour le classement (`leaderboard:sales`)
- **Pourquoi Sorted Set ?** Le score correspond au nombre de ventes. Redis maintient l'ordre automatiquement. `ZINCRBY` incrémente atomiquement, `ZREVRANGE` retourne le top-N en O(log N + N).

---

## 3. Réponses aux Questions de Réflexion

### Q1 : Que se passe-t-il si Redis redémarre ?
Par défaut, Redis est **en mémoire uniquement**. Un redémarrage entraîne la **perte de toutes les données** du cache. C'est acceptable pour un cache (les données sont reconstruites depuis la DB au prochain accès — MISS), mais critique pour les sessions et le classement.

**Solutions :**
- **RDB (Snapshotting)** : sauvegarde périodique sur disque (toutes les N secondes/opérations). Risque de perte des données récentes.
- **AOF (Append-Only File)** : journalisation de chaque opération d'écriture. Reconstruction complète au redémarrage.
- **Combinaison RDB + AOF** : recommandé en production.
- Pour les sessions : utiliser `SAVE` ou configurer la persistance AOF avec `appendfsync always`.

### Q2 : Comment gérer la cohérence cache/DB en cas d'accès concurrent ?
Problème : deux requêtes simultanées peuvent toutes deux obtenir un MISS et écrire des valeurs différentes en cache.

**Stratégies :**
1. **TTL court** : accepter une légère incohérence temporaire (cohérence éventuelle).
2. **Invalidation sur écriture** : à chaque `UPDATE` en DB, appeler `invalidate_product_cache()`. Pattern **Cache-Aside with Write-Through**.
3. **Verrou distribué (Redlock)** : lors d'un MISS, acquérir un verrou Redis avant d'aller en DB. Évite les "stampedes" (multiples requêtes simultanées pour le même MISS).
4. **WATCH/MULTI/EXEC** : transactions optimistes pour les écritures critiques (ex: stock).

### Q3 : Quand un TTL trop court est-il problématique ?
- **Cache thrashing** : si le TTL est inférieur au temps moyen entre deux requêtes pour le même objet, le cache est inutile — on va constamment en DB (taux de hit proche de 0%).
- **Thundering herd** : si beaucoup d'objets expirent simultanément, cela génère un pic de requêtes vers la DB (jitter aléatoire recommandé : `TTL = base ± random(10%)`).
- **Cas problématiques** : pages produits très consultées, tableaux de bord en temps réel, données de configuration rarement modifiées.
- **Règle pratique** : TTL ≥ 2× le temps moyen entre deux accès au même objet.

---

## 4. Bonus : Rate-Limiting par Utilisateur

Implémenté dans `ex5_pipeline.py` (méthode `place_order_atomic`).

**Principe :** utiliser un compteur Redis avec TTL fixe par fenêtre temporelle.
```python
key = f"ratelimit:{user_id}:{int(time.time() // 60)}"  # fenêtre d'1 minute
count = r.incr(key)
r.expire(key, 60)
if count > MAX_REQUESTS_PER_MINUTE:
    raise RateLimitExceeded()
```

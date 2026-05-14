"""
TP1 - Exercice 5 : Pipeline & Transactions Redis
Use Case : Bulk insert et commande atomique ShopFast
"""
import redis
import time
import json
import uuid

r = redis.Redis(host='localhost', port=6379, decode_responses=True)


def bulk_insert_products(r, products: list) -> float:
    """
    Insérer plusieurs produits en utilisant un pipeline Redis.
    Retourne le temps d'exécution en secondes.
    """
    start = time.time()
    pipe = r.pipeline()

    for product in products:
        pid = product["id"]
        pipe.hset(f"product:{pid}", mapping={
            "name": product["name"],
            "price": str(product["price"]),
            "category": product["category"],
            "stock": str(product["stock"])
        })

    pipe.execute()
    elapsed = time.time() - start
    print(f"✅ {len(products)} produits insérés en {elapsed*1000:.1f}ms (pipeline)")
    return elapsed


def place_order_atomic(r, user_id: str, product_id: str, quantity: int) -> bool:
    """
    Passer une commande de manière atomique avec MULTI/EXEC.
    Opérations :
    1. Décrémenter le stock du produit
    2. Enregistrer la commande
    3. Vider le panier de l'utilisateur

    Utilise WATCH pour détecter les modifications concurrentes.
    Retourne True si succès, False si le stock est insuffisant ou conflit.
    """
    stock_key = f"product:{product_id}"
    order_id = str(uuid.uuid4())[:8]

    with r.pipeline() as pipe:
        while True:
            try:
                # WATCH : surveiller le stock pour détecter les conflits
                pipe.watch(stock_key)

                # Vérifier le stock disponible
                product = pipe.hgetall(stock_key)
                if not product:
                    print(f"❌ Produit {product_id} introuvable")
                    pipe.reset()
                    return False

                current_stock = int(product.get("stock", 0))
                if current_stock < quantity:
                    print(f"❌ Stock insuffisant : {current_stock} disponible, {quantity} demandé")
                    pipe.reset()
                    return False

                # MULTI : démarrer la transaction
                pipe.multi()
                pipe.hincrby(stock_key, "stock", -quantity)
                pipe.hset(f"order:{order_id}", mapping={
                    "user_id": user_id,
                    "product_id": product_id,
                    "quantity": str(quantity),
                    "status": "confirmed"
                })
                pipe.delete(f"cart:{user_id}")

                # EXEC : exécuter atomiquement
                pipe.execute()
                print(f"✅ Commande {order_id} confirmée pour {user_id}")
                return True

            except redis.WatchError:
                # Un autre client a modifié le stock, réessayer
                print("⚠️  Conflit détecté, nouvelle tentative...")
                continue


def compare_pipeline_vs_sequential(r, n: int = 1000):
    """Comparer l'insertion séquentielle vs pipeline."""
    r.flushdb()

    # Séquentiel
    start = time.time()
    for i in range(n):
        r.set(f"key:{i}", f"value:{i}")
    seq_time = time.time() - start
    r.flushdb()

    # Pipeline
    start = time.time()
    pipe = r.pipeline()
    for i in range(n):
        pipe.set(f"key:{i}", f"value:{i}")
    pipe.execute()
    pipe_time = time.time() - start
    r.flushdb()

    print(f"\n=== Pipeline vs Séquentiel ({n} opérations) ===")
    print(f"  Séquentiel : {seq_time*1000:.0f}ms")
    print(f"  Pipeline   : {pipe_time*1000:.0f}ms")
    print(f"  Gain       : {seq_time/pipe_time:.1f}x plus rapide")


if __name__ == "__main__":
    r.flushdb()

    # Test bulk insert
    products = [
        {"id": i, "name": f"Produit {i}", "price": i * 1000, "category": "electronics", "stock": 20}
        for i in range(1, 51)
    ]
    bulk_insert_products(r, products)

    # Test commande atomique
    print("\n=== Test Transaction Atomique ===")
    place_order_atomic(r, "user:42", "1", 2)
    place_order_atomic(r, "user:42", "1", 100)  # Stock insuffisant

    # Comparaison pipeline
    compare_pipeline_vs_sequential(r, 500)

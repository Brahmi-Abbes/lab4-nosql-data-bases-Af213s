"""
TP5 - Benchmark Comparatif NoSQL
Mesurer les performances de Redis, MongoDB, Cassandra, Neo4j
"""
import time
import statistics
import random
import string
import threading
from typing import Callable, List

import redis
from pymongo import MongoClient, InsertOne
from cassandra.cluster import Cluster
from cassandra.policies import RoundRobinPolicy
from neo4j import GraphDatabase

# ─── Utilitaires de mesure ────────────────────────────────────────────────────

def measure_latency(fn: Callable, iterations: int = 1000) -> dict:
    """Exécuter fn iterations fois et retourner les statistiques de latence."""
    latencies = []
    for _ in range(iterations):
        start = time.perf_counter()
        fn()
        latencies.append((time.perf_counter() - start) * 1000)  # en ms

    latencies.sort()
    return {
        "mean_ms":         round(statistics.mean(latencies), 3),
        "p50_ms":          round(latencies[int(0.50 * len(latencies))], 3),
        "p95_ms":          round(latencies[int(0.95 * len(latencies))], 3),
        "p99_ms":          round(latencies[int(0.99 * len(latencies))], 3),
        "max_ms":          round(max(latencies), 3),
        "throughput_rps":  round(1000 / statistics.mean(latencies), 1),
    }


def print_results(name: str, results: dict):
    print(f"\n{'='*52}")
    print(f"  {name}")
    print(f"{'='*52}")
    for k, v in results.items():
        print(f"  {k:22s}: {v}")


def random_string(n: int = 8) -> str:
    return "".join(random.choices(string.ascii_lowercase, k=n))


# ─── Ex1 : Benchmark Écriture ─────────────────────────────────────────────────

def benchmark_write_redis(n: int = 100_000):
    """Insérer n enregistrements dans Redis avec pipeline."""
    r = redis.Redis(host="localhost", port=6379, decode_responses=True)
    r.flushdb()

    start = time.perf_counter()
    batch_size = 500
    for i in range(0, n, batch_size):
        pipe = r.pipeline()
        for j in range(i, min(i + batch_size, n)):
            key = f"user:{j}"
            pipe.hset(key, mapping={
                "name":  f"user_{j}",
                "email": f"user_{j}@example.com",
                "score": random.randint(0, 1000),
            })
        pipe.execute()

    elapsed = time.perf_counter() - start
    throughput = n / elapsed
    print_results(f"Redis WRITE ({n:,} enregistrements)", {
        "total_seconds":    round(elapsed, 2),
        "throughput_rps":   round(throughput, 1),
        "ms_per_record":    round(elapsed * 1000 / n, 4),
    })
    return throughput


def benchmark_write_mongodb(n: int = 100_000):
    """Insérer n documents dans MongoDB avec bulk_write."""
    client = MongoClient("mongodb://admin:admin123@localhost:27017/")
    db = client["benchmark"]
    db.users.drop()

    start = time.perf_counter()
    batch_size = 1000
    for i in range(0, n, batch_size):
        ops = [
            InsertOne({
                "_id":   i + j,
                "name":  f"user_{i+j}",
                "email": f"user_{i+j}@example.com",
                "score": random.randint(0, 1000),
                "tags":  [random_string() for _ in range(3)],
            })
            for j in range(min(batch_size, n - i))
        ]
        db.users.bulk_write(ops, ordered=False)

    elapsed = time.perf_counter() - start
    throughput = n / elapsed
    print_results(f"MongoDB WRITE ({n:,} documents)", {
        "total_seconds":  round(elapsed, 2),
        "throughput_rps": round(throughput, 1),
        "ms_per_record":  round(elapsed * 1000 / n, 4),
    })
    client.close()
    return throughput


def benchmark_write_cassandra(n: int = 100_000):
    """Insérer n rows dans Cassandra avec UNLOGGED BATCH."""
    cluster = Cluster(["localhost"], load_balancing_policy=RoundRobinPolicy(),
                      protocol_version=4)
    session = cluster.connect()

    session.execute("""
        CREATE KEYSPACE IF NOT EXISTS benchmark
        WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}
    """)
    session.set_keyspace("benchmark")
    session.execute("DROP TABLE IF EXISTS users")
    session.execute("""
        CREATE TABLE users (
            id      int PRIMARY KEY,
            name    text,
            email   text,
            score   int
        )
    """)

    insert_stmt = session.prepare(
        "INSERT INTO users (id, name, email, score) VALUES (?, ?, ?, ?)"
    )

    start = time.perf_counter()
    batch_size = 50   # Cassandra recommends small batches
    from cassandra.query import BatchStatement, BatchType
    for i in range(0, n, batch_size):
        batch = BatchStatement(batch_type=BatchType.UNLOGGED)
        for j in range(min(batch_size, n - i)):
            idx = i + j
            batch.add(insert_stmt, (idx, f"user_{idx}", f"user_{idx}@example.com",
                                    random.randint(0, 1000)))
        session.execute(batch)

    elapsed = time.perf_counter() - start
    throughput = n / elapsed
    print_results(f"Cassandra WRITE ({n:,} rows)", {
        "total_seconds":  round(elapsed, 2),
        "throughput_rps": round(throughput, 1),
        "ms_per_record":  round(elapsed * 1000 / n, 4),
    })
    cluster.shutdown()
    return throughput


# ─── Ex2 : Benchmark Lecture ─────────────────────────────────────────────────

def benchmark_read_redis(n_queries: int = 10_000):
    """Point lookup, ZRANGE, pipeline multi-get."""
    r = redis.Redis(host="localhost", port=6379, decode_responses=True)

    # Point lookup
    def point_lookup():
        key = f"user:{random.randint(0, 9999)}"
        r.hgetall(key)

    pl_results = measure_latency(point_lookup, n_queries)
    print_results("Redis READ — point lookup", pl_results)

    # Range via sorted set (build index once)
    for i in range(1000):
        r.zadd("score_index", {f"user:{i}": random.randint(0, 1000)})

    def range_query():
        r.zrangebyscore("score_index", 200, 800, withscores=True, start=0, num=50)

    rq_results = measure_latency(range_query, n_queries)
    print_results("Redis READ — range query (ZRANGEBYSCORE)", rq_results)

    # Pipeline multi-get
    def multi_get():
        pipe = r.pipeline()
        for k in range(10):
            pipe.hgetall(f"user:{random.randint(0, 9999)}")
        pipe.execute()

    mg_results = measure_latency(multi_get, n_queries // 10)
    print_results("Redis READ — pipeline multi-get (10 keys)", mg_results)


def benchmark_read_mongodb(n_queries: int = 10_000):
    """find_one, range query, aggregate pipeline."""
    client = MongoClient("mongodb://admin:admin123@localhost:27017/")
    db = client["benchmark"]
    db.users.create_index("score")

    # Point lookup
    def find_one():
        db.users.find_one({"_id": random.randint(0, 99999)})

    fo_results = measure_latency(find_one, n_queries)
    print_results("MongoDB READ — find_one by _id", fo_results)

    # Range query with index
    def range_query():
        list(db.users.find({"score": {"$gte": 200, "$lte": 800}}).limit(50))

    rq_results = measure_latency(range_query, n_queries // 10)
    print_results("MongoDB READ — range query on score (indexed)", rq_results)

    # Aggregation pipeline
    def aggregate():
        list(db.users.aggregate([
            {"$group": {"_id": None,
                        "avg_score": {"$avg": "$score"},
                        "max_score": {"$max": "$score"},
                        "count":     {"$sum": 1}}},
        ]))

    ag_results = measure_latency(aggregate, 500)
    print_results("MongoDB READ — aggregate (avg/max score)", ag_results)

    client.close()


# ─── Ex3 : Charge concurrente ─────────────────────────────────────────────────

def benchmark_concurrent(db_fn: Callable, label: str,
                          n_clients: int = 50,
                          requests_per_client: int = 200):
    """
    Lancer n_clients threads simultanés.
    Chaque thread effectue requests_per_client requêtes.
    Mesure la latence globale et la dégradation vs client unique.
    """
    all_latencies = []
    lock = threading.Lock()

    def worker():
        latencies = []
        for _ in range(requests_per_client):
            start = time.perf_counter()
            db_fn()
            latencies.append((time.perf_counter() - start) * 1000)
        with lock:
            all_latencies.extend(latencies)

    threads = [threading.Thread(target=worker) for _ in range(n_clients)]
    start_total = time.perf_counter()
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    elapsed = time.perf_counter() - start_total

    total_requests = n_clients * requests_per_client
    all_latencies.sort()
    print_results(f"Concurrent {label} ({n_clients} clients × {requests_per_client} req)", {
        "total_requests":  total_requests,
        "total_seconds":   round(elapsed, 2),
        "throughput_rps":  round(total_requests / elapsed, 1),
        "mean_ms":         round(statistics.mean(all_latencies), 3),
        "p50_ms":          round(all_latencies[int(0.50 * len(all_latencies))], 3),
        "p95_ms":          round(all_latencies[int(0.95 * len(all_latencies))], 3),
        "p99_ms":          round(all_latencies[int(0.99 * len(all_latencies))], 3),
    })


# ─── Ex4 : Rapport de décision ────────────────────────────────────────────────

RAPPORT_TABLE = """
╔══════════════════════╦══════════════╦══════════════╦══════════════╦══════════════╗
║ Critère              ║    Redis     ║   MongoDB    ║  Cassandra   ║    Neo4j     ║
╠══════════════════════╬══════════════╬══════════════╬══════════════╬══════════════╣
║ Débit écriture       ║  ★★★★★       ║  ★★★★☆       ║  ★★★★☆       ║  ★★☆☆☆       ║
║ Débit lecture        ║  ★★★★★       ║  ★★★★☆       ║  ★★★★★       ║  ★★★☆☆       ║
║ Requêtes complexes   ║  ★★☆☆☆       ║  ★★★★☆       ║  ★★☆☆☆       ║  ★★★★★       ║
║ Scalabilité          ║  ★★★☆☆       ║  ★★★★☆       ║  ★★★★★       ║  ★★★☆☆       ║
║ Modélisation         ║  Clé-Valeur  ║  Documents   ║  Colonnes    ║  Graphe      ║
║ Use case idéal       ║  Cache/Session║ Catalogues  ║  IoT / Logs  ║  Réseaux     ║
╚══════════════════════╩══════════════╩══════════════╩══════════════╩══════════════╝

Recommandation :
  • Redis     → Sessions, cache applicatif, file de messages temps-réel
  • MongoDB   → API REST, catalogues produits, données semi-structurées
  • Cassandra → Séries temporelles, logs IoT à haute volumétrie
  • Neo4j     → Réseaux sociaux, recommandations, détection de fraude
"""


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("🚀 Benchmark NoSQL — Comparatif des 4 technologies")
    print("=" * 60)

    N = 10_000   # Réduire pour les tests; 100_000 pour la production

    print(f"\n📝 Ex1 — Benchmark Écriture ({N:,} enregistrements)")
    benchmark_write_redis(N)
    benchmark_write_mongodb(N)
    benchmark_write_cassandra(N)

    print(f"\n📖 Ex2 — Benchmark Lecture (10 000 requêtes)")
    benchmark_read_redis()
    benchmark_read_mongodb()

    print(f"\n⚡ Ex3 — Test Charge Concurrente (50 clients)")
    # Redis concurrent read
    _r = redis.Redis(host="localhost", port=6379, decode_responses=True)
    benchmark_concurrent(
        lambda: _r.hgetall(f"user:{random.randint(0, N-1)}"),
        label="Redis READ",
        n_clients=50,
        requests_per_client=200,
    )

    # MongoDB concurrent read
    _mc = MongoClient("mongodb://admin:admin123@localhost:27017/")
    _db = _mc["benchmark"]
    benchmark_concurrent(
        lambda: _db.users.find_one({"_id": random.randint(0, N-1)}),
        label="MongoDB READ",
        n_clients=50,
        requests_per_client=200,
    )

    print("\n📊 Ex4 — Tableau de Décision")
    print(RAPPORT_TABLE)

    print("\n✅ Benchmark terminé ! Consultez RAPPORT.md pour l'analyse complète.")

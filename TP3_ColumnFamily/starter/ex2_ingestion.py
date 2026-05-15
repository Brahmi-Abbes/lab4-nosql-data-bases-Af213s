"""
TP3 - Exercice 2 : Ingestion de données IoT
Use Case : SmartGrid DZ - 10 000 capteurs, 5 minutes de mesures
"""
from cassandra.cluster import Cluster
from cassandra.query import BatchStatement, BatchType
import uuid
import random
from datetime import datetime, timedelta
import time

# ─── Configuration ─────────────────────────────────────────────────────────────
CASSANDRA_HOST      = "localhost"
KEYSPACE            = "smartgrid"
NB_CAPTEURS         = 10_000
MINUTES_HISTORIQUE  = 5
BATCH_SIZE          = 50      # Bonne pratique Cassandra : batches ≤ 50 lignes
TTL_MESURE          = 7_776_000    # 90 jours en secondes
TTL_ALERTE          = 31_536_000   # 1 an en secondes

WILAYAS = ["Alger", "Oran", "Constantine", "Annaba", "Blida"]
COMMUNES = {
    "Alger":       ["Bab Ezzouar", "Hydra", "El Harrach", "Dar El Beida"],
    "Oran":        ["Bir El Djir", "Es Senia", "Arzew"],
    "Constantine": ["El Khroub", "Ain Smara", "Hamma Bouziane"],
    "Annaba":      ["El Bouni", "El Hadjar", "Seraidi"],
    "Blida":       ["Bougara", "Boufarik", "Larbaa"],
}

# ─── Connexion ─────────────────────────────────────────────────────────────────

def connect():
    """Connexion au cluster Cassandra."""
    cluster = Cluster([CASSANDRA_HOST])
    session = cluster.connect(KEYSPACE)
    session.default_timeout = 30
    return session, cluster


# ─── Générateur de données ─────────────────────────────────────────────────────

def generate_capteurs(n: int) -> list:
    """
    Générer n capteurs avec un ID fixe, une wilaya et une commune assignées.
    On garde les IDs stables pour simuler des appareils réels.
    """
    capteurs = []
    for _ in range(n):
        wilaya  = random.choice(WILAYAS)
        commune = random.choice(COMMUNES[wilaya])
        capteurs.append({
            "capteur_id": uuid.uuid4(),
            "wilaya":     wilaya,
            "commune":    commune,
        })
    return capteurs


def generate_mesure(capteur: dict, timestamp: datetime) -> dict:
    """Générer une mesure réaliste pour un capteur IoT électrique."""
    tension   = round(220 + random.gauss(0, 5), 2)    # 220 V ± bruit
    courant   = round(random.uniform(0.5, 15.0), 2)
    puissance = round(tension * courant / 1000, 3)     # kW
    alerte    = tension < 200 or tension > 240 or random.random() < 0.05
    code      = ("SURTENSION" if tension > 240
                 else "SOUS_TENSION" if tension < 200
                 else "ANOMALIE" if alerte else None)
    return {
        "capteur_id":   capteur["capteur_id"],
        "date_jour":    timestamp.date(),
        "timestamp":    timestamp,
        "wilaya":       capteur["wilaya"],
        "commune":      capteur["commune"],
        "tension_v":    tension,
        "courant_a":    courant,
        "puissance_kw": puissance,
        "frequence_hz": round(50 + random.gauss(0, 0.1), 2),
        "temperature":  round(random.uniform(20, 65), 1),
        "alerte":       alerte,
        "code_alerte":  code,
    }


# ─── 2.1 / 2.2 / 2.3 : Insertion avec prepared statements ────────────────────

def prepare_statements(session):
    """Préparer les statements UNE SEULE FOIS pour maximiser les performances."""
    insert_mesure = session.prepare("""
        INSERT INTO mesures_par_capteur
            (capteur_id, date_jour, timestamp, wilaya, commune,
             tension_v, courant_a, puissance_kw, frequence_hz, temperature,
             alerte, code_alerte)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        USING TTL ?
    """)

    insert_alerte = session.prepare("""
        INSERT INTO alertes_par_wilaya
            (wilaya, date_jour, timestamp, capteur_id,
             code_alerte, description, gravite, resolue)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        USING TTL ?
    """)

    insert_agregat = session.prepare("""
        INSERT INTO agregats_horaires
            (wilaya, date_heure, nb_capteurs,
             puissance_moy_kw, puissance_max_kw, puissance_min_kw, nb_alertes)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """)

    return insert_mesure, insert_alerte, insert_agregat


def insert_single(session, stmt_mesure, mesure: dict):
    """Insérer une seule mesure — utile pour les tests unitaires."""
    m = mesure
    session.execute(stmt_mesure, (
        m["capteur_id"], m["date_jour"], m["timestamp"],
        m["wilaya"], m["commune"],
        m["tension_v"], m["courant_a"], m["puissance_kw"],
        m["frequence_hz"], m["temperature"],
        m["alerte"], m["code_alerte"],
        TTL_MESURE,
    ))


def insert_batch(session, stmt_mesure, stmt_alerte, mesures: list):
    """
    2.1 + 2.2 : Insérer un batch de mesures avec TTL.
    On utilise UNLOGGED BATCH : recommandé pour les séries temporelles
    car les lignes vont dans la même partition (même capteur_id + date_jour).
    Taille max : BATCH_SIZE (50) pour ne pas saturer les coordinateurs.
    """
    alertes_batch = []

    for i in range(0, len(mesures), BATCH_SIZE):
        chunk = mesures[i : i + BATCH_SIZE]
        batch = BatchStatement(batch_type=BatchType.UNLOGGED)
        for m in chunk:
            batch.add(stmt_mesure, (
                m["capteur_id"], m["date_jour"], m["timestamp"],
                m["wilaya"], m["commune"],
                m["tension_v"], m["courant_a"], m["puissance_kw"],
                m["frequence_hz"], m["temperature"],
                m["alerte"], m["code_alerte"],
                TTL_MESURE,
            ))
            # 2.4 : Collecter les alertes séparément
            if m["alerte"] and m["code_alerte"]:
                alertes_batch.append(m)

        session.execute(batch)

    # Insérer les alertes (batch séparé — partition différente)
    for i in range(0, len(alertes_batch), BATCH_SIZE):
        chunk = alertes_batch[i : i + BATCH_SIZE]
        batch = BatchStatement(batch_type=BatchType.UNLOGGED)
        for m in chunk:
            gravite = (3 if m["code_alerte"] in ("SURTENSION", "SOUS_TENSION")
                       else 2)
            batch.add(stmt_alerte, (
                m["wilaya"], m["date_jour"], m["timestamp"],
                m["capteur_id"], m["code_alerte"],
                f"Capteur {m['capteur_id']} — {m['code_alerte']}",
                gravite, False,
                TTL_ALERTE,
            ))
        session.execute(batch)


# ─── 2.3 : Agrégats horaires pré-calculés ────────────────────────────────────

def insert_agregats(session, stmt_agregat, mesures_par_heure: dict):
    """
    Calculer et insérer les agrégats horaires pour chaque wilaya.
    mesures_par_heure : { (wilaya, heure_tronquée) : [mesures] }
    """
    for (wilaya, heure), liste in mesures_par_heure.items():
        puissances = [m["puissance_kw"] for m in liste]
        nb_alertes = sum(1 for m in liste if m["alerte"])
        session.execute(stmt_agregat, (
            wilaya, heure,
            len(liste),
            round(sum(puissances) / len(puissances), 3),
            round(max(puissances), 3),
            round(min(puissances), 3),
            nb_alertes,
        ))


# ─── run_ingestion ─────────────────────────────────────────────────────────────

def run_ingestion(session):
    """
    2.3 : Générer et insérer NB_CAPTEURS × MINUTES_HISTORIQUE mesures.
    Affiche le débit d'ingestion en mesures/seconde.
    """
    print(f"Génération des capteurs…")
    capteurs = generate_capteurs(NB_CAPTEURS)

    stmt_mesure, stmt_alerte, stmt_agregat = prepare_statements(session)

    now        = datetime.utcnow().replace(second=0, microsecond=0)
    timestamps = [now - timedelta(minutes=i) for i in range(MINUTES_HISTORIQUE)]
    total      = NB_CAPTEURS * MINUTES_HISTORIQUE

    print(f"Démarrage ingestion : {NB_CAPTEURS:,} capteurs × {MINUTES_HISTORIQUE} min "
          f"= {total:,} mesures")

    agregats: dict = {}   # (wilaya, heure_tronquée) → liste de mesures
    start = time.time()

    for ts in timestamps:
        heure = ts.replace(minute=0, second=0, microsecond=0)
        mesures_minute = [generate_mesure(c, ts) for c in capteurs]

        # Grouper pour les agrégats
        for m in mesures_minute:
            key = (m["wilaya"], heure)
            agregats.setdefault(key, []).append(m)

        insert_batch(session, stmt_mesure, stmt_alerte, mesures_minute)

        elapsed_now = time.time() - start
        inserted    = (timestamps.index(ts) + 1) * NB_CAPTEURS
        print(f"  [{inserted:>8,}/{total:,}]  {elapsed_now:5.1f}s  "
              f"  débit courant : {inserted/elapsed_now:,.0f} mes/s", end="\r")

    # Insérer les agrégats
    insert_agregats(session, stmt_agregat, agregats)

    elapsed = time.time() - start
    print(f"\n✅ {total:,} mesures insérées en {elapsed:.1f}s")
    print(f"   Débit moyen : {total / elapsed:,.0f} mesures/seconde")
    alertes_count = sum(
        1 for ts_list in [generate_mesure(c, now)
                          for c in capteurs[:100]]
        if ts_list["alerte"]
    )
    print(f"   (environ {total * 0.05:,.0f} alertes insérées — ~5% des mesures)")


# ─── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("🔌 SmartGrid DZ — Ingestion IoT Cassandra")
    print("=" * 50)
    session, cluster = connect()
    try:
        run_ingestion(session)
    finally:
        cluster.shutdown()

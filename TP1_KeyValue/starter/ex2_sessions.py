"""
TP1 - Exercice 2 : Gestion des sessions utilisateur
Use Case : ShopFast - Sessions avec TTL glissant
"""
import redis
import uuid
import json
import time

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

SESSION_TTL = 1800  # 30 minutes en secondes


def create_session(r, user_id: str, user_data: dict) -> str:
    """
    Créer une nouvelle session pour un utilisateur.
    Retourne le session_token (UUID).
    TTL : 30 minutes (sliding expiration).
    """
    session_token = str(uuid.uuid4())
    session_key = f"session:{session_token}"
    session_data = {
        "user_id": user_id,
        "created_at": str(time.time()),
        **user_data
    }
    r.hset(session_key, mapping=session_data)
    r.expire(session_key, SESSION_TTL)
    return session_token


def get_session(r, session_token: str) -> dict | None:
    """
    Récupérer les données d'une session et renouveler son TTL (sliding expiration).
    Retourne None si la session n'existe pas ou a expiré.
    """
    session_key = f"session:{session_token}"
    data = r.hgetall(session_key)
    if not data:
        return None
    # Sliding expiration : renouveler le TTL à chaque accès
    r.expire(session_key, SESSION_TTL)
    return data


def delete_session(r, session_token: str) -> bool:
    """Supprimer une session (logout). Retourne True si supprimée."""
    result = r.delete(f"session:{session_token}")
    return result > 0


def get_session_ttl(r, session_token: str) -> int:
    """Retourner le TTL restant en secondes (-2 si inexistante)."""
    return r.ttl(f"session:{session_token}")


if __name__ == "__main__":
    r.flushdb()

    # Créer une session
    token = create_session(r, "user:42", {"nom": "Ahmed", "role": "client"})
    print("Token:", token)

    # Récupérer la session
    session = get_session(r, token)
    print("Session:", session)
    print("TTL restant:", get_session_ttl(r, token), "secondes")

    # Supprimer la session
    delete_session(r, token)
    print("Après logout:", get_session(r, token))

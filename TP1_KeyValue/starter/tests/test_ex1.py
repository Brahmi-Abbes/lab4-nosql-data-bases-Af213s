"""Tests pour l'exercice 1 - Structures de données Redis"""
import pytest
import redis
import sys
sys.path.insert(0, '..')
from ex1_structures import *

@pytest.fixture(autouse=True)
def clean_redis():
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    r.flushdb()
    yield r
    r.flushdb()

def test_store_and_get_product(clean_redis):
    r = clean_redis
    data = {"name": "Samsung A54", "price": "65000", "category": "phones", "stock": "15"}
    store_product(r, 1, data)
    product = get_product(r, 1)
    assert product is not None
    assert product["name"] == "Samsung A54"
    assert product["price"] == "65000"

def test_get_nonexistent_product(clean_redis):
    r = clean_redis
    assert get_product(r, 999) is None

def test_add_to_cart(clean_redis):
    r = clean_redis
    add_to_cart(r, "user:1", 1, 2)
    add_to_cart(r, "user:1", 2, 1)
    add_to_cart(r, "user:1", 1, 3)  # Ajouter encore produit 1
    cart = get_cart(r, "user:1")
    assert cart["1"] == "5"  # 2+3
    assert cart["2"] == "1"

def test_record_view_history_limit(clean_redis):
    r = clean_redis
    for i in range(15):
        record_view(r, "user:1", i, max_history=10)
    history = get_history(r, "user:1")
    assert len(history) == 10
    assert history[0] == "14"  # Dernier vu en premier

def test_category_intersection(clean_redis):
    r = clean_redis
    add_product_to_category(r, "electronics", 1)
    add_product_to_category(r, "electronics", 2)
    add_product_to_category(r, "promo", 1)
    add_product_to_category(r, "promo", 3)
    
    result = get_products_in_categories(r, "electronics", "promo")
    assert "1" in result
    assert "2" not in result
    assert "3" not in result

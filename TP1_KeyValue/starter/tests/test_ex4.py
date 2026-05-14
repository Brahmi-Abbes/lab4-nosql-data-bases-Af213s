"""Tests pour l'exercice 4 - Leaderboard"""
import pytest
import redis
import sys
sys.path.insert(0, '..')
from ex4_leaderboard import *

@pytest.fixture(autouse=True)
def clean_redis():
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    r.flushdb()
    yield r
    r.flushdb()

def test_record_sale_and_rank(clean_redis):
    r = clean_redis
    record_sale(r, 1, 100)
    record_sale(r, 2, 50)
    record_sale(r, 3, 200)
    
    top = get_top_products(r, 3)
    assert top[0]["product_id"] == "3"
    assert int(top[0]["sales"]) == 200

def test_product_rank(clean_redis):
    r = clean_redis
    record_sale(r, 1, 100)
    record_sale(r, 2, 200)
    record_sale(r, 3, 50)
    
    assert get_product_rank(r, 2) == 1
    assert get_product_rank(r, 1) == 2
    assert get_product_rank(r, 3) == 3
    assert get_product_rank(r, 99) is None

def test_top_n(clean_redis):
    r = clean_redis
    for i in range(20):
        record_sale(r, i+1, (i+1)*10)
    
    top5 = get_top_products(r, 5)
    assert len(top5) == 5
    assert top5[0]["product_id"] == "20"

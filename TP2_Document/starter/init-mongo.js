// MongoDB initialization script
db = db.getSiblingDB('medical_db');

// Create admin user for medical_db
db.createUser({
  user: 'medical_user',
  pwd: 'medical123',
  roles: [{ role: 'readWrite', db: 'medical_db' }]
});

// Create collections with initial setup
db.createCollection('patients');
db.createCollection('analyses');

print('medical_db initialized successfully');

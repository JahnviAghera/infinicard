-- Example init script for Infinicard DB
-- This runs against the database specified by POSTGRES_DB (set in docker-compose.yml)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Add schema, seed data or other migrations here as needed.

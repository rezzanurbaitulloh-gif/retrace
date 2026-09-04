-- Seed for local development
INSERT INTO location_sources (name, description) VALUES ('GPS','seed') ON CONFLICT DO NOTHING;

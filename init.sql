-- Smart Ranch Management System - Database Schema

-- 1. PENS (Batches)
CREATE TABLE IF NOT EXISTS pens (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    livestock_type VARCHAR(50) NOT NULL, -- e.g., 'Cattle', 'Goat', 'Sheep'
    capacity INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. ANIMALS (Individual Tracking)
CREATE TABLE IF NOT EXISTS animals (
    id SERIAL PRIMARY KEY,
    tag_number VARCHAR(50) UNIQUE NOT NULL,
    pen_id INTEGER REFERENCES pens(id) ON DELETE SET NULL,
    breed VARCHAR(100),
    sex VARCHAR(10) CHECK (sex IN ('Male', 'Female')),
    dob DATE,
    acquisition_date DATE,
    acquisition_cost DECIMAL(10, 2),
    status VARCHAR(20) DEFAULT 'Active', -- Active, Sold, Deceased
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. HEALTH EVENTS (Individual History)
CREATE TABLE IF NOT EXISTS health_events (
    id SERIAL PRIMARY KEY,
    animal_id INTEGER REFERENCES animals(id) ON DELETE CASCADE,
    event_date DATE NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- Vaccination, Treatment, Checkup
    symptoms TEXT,
    diagnosis TEXT,
    treatment TEXT,
    cost DECIMAL(10, 2) DEFAULT 0.00,
    performed_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. FEED LOGS (Batch Level)
CREATE TABLE IF NOT EXISTS feed_logs (
    id SERIAL PRIMARY KEY,
    pen_id INTEGER REFERENCES pens(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    feed_type VARCHAR(100) NOT NULL,
    quantity_kg DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. EXPENSES (Financials)
CREATE TABLE IF NOT EXISTS expenses (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL, -- Feed, Medical, Labor, Maintenance, Other
    amount DECIMAL(10, 2) NOT NULL,
    expense_date DATE NOT NULL,
    description TEXT,
    pen_id INTEGER REFERENCES pens(id) ON DELETE SET NULL, -- Optional link to batch
    animal_id INTEGER REFERENCES animals(id) ON DELETE SET NULL, -- Optional link to animal
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES for Performance
CREATE INDEX idx_animals_pen_id ON animals(pen_id);
CREATE INDEX idx_health_animal_id ON health_events(animal_id);
CREATE INDEX idx_feed_pen_id ON feed_logs(pen_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);

-- MATERIALIZED VIEW for Batch Performance (Example of HTAP)
-- Calculates total feed cost and quantity per pen
CREATE MATERIALIZED VIEW IF NOT EXISTS batch_performance_summary AS
SELECT 
    p.id AS pen_id,
    p.name AS pen_name,
    COUNT(a.id) AS animal_count,
    COALESCE(SUM(fl.quantity_kg), 0) AS total_feed_kg,
    COALESCE(SUM(fl.cost), 0) AS total_feed_cost
FROM pens p
LEFT JOIN animals a ON p.id = a.pen_id AND a.status = 'Active'
LEFT JOIN feed_logs fl ON p.id = fl.pen_id
GROUP BY p.id, p.name;

-- Function to refresh the view (to be called periodically or via trigger)
CREATE OR REPLACE FUNCTION refresh_batch_performance()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW batch_performance_summary;
END;
$$ LANGUAGE plpgsql;

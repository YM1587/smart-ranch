-- SMART RANCH MANAGEMENT SYSTEM - REFINED SCHEMA
-- Enhanced for Individual Animal Performance & P&L Tracking

------------------------------
-- 1. FARMER PROFILE
------------------------------

CREATE TABLE IF NOT EXISTS farmer (
    farmer_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15),
    farm_name VARCHAR(100),
    location VARCHAR(255),
    farm_type VARCHAR(20) NOT NULL CHECK (farm_type IN ('Dairy', 'Beef', 'Mixed')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMPTZ
);

------------------------------
-- 2. ANIMAL GROUPING SYSTEM
------------------------------

CREATE TABLE IF NOT EXISTS animal_pen (
    pen_id SERIAL PRIMARY KEY,
    pen_name VARCHAR(50) NOT NULL,
    pen_type VARCHAR(20) NOT NULL CHECK (pen_type IN (
        'Calves', 'Heifers', 'Milking Cows', 'Dry Cows', 'Bulls', 'Beef Fattening'
    )),
    capacity INT,
    description TEXT,
    farmer_id INT NOT NULL REFERENCES farmer(farmer_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

------------------------------
-- 3. ANIMAL MANAGEMENT
------------------------------

CREATE TABLE IF NOT EXISTS animal (
    animal_id SERIAL PRIMARY KEY,
    farmer_id INT NOT NULL REFERENCES farmer(farmer_id) ON DELETE CASCADE,
    pen_id INT NOT NULL REFERENCES animal_pen(pen_id) ON DELETE CASCADE,
    tag_number VARCHAR(50) NOT NULL,
    animal_type VARCHAR(10) NOT NULL CHECK (animal_type IN ('Dairy', 'Beef')),
    breed VARCHAR(50) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female')),
    birth_date DATE,
    acquisition_type VARCHAR(20) NOT NULL CHECK (acquisition_type IN ('Purchased', 'Born-on-farm')),
    acquisition_cost DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Sold', 'Dead', 'Culled')),
    disposal_reason VARCHAR(100),
    disposal_date DATE,
    disposal_value DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(farmer_id, tag_number)
);

------------------------------
-- 4. PRODUCTION TRACKING
------------------------------

CREATE TABLE IF NOT EXISTS milk_production (
    production_id SERIAL PRIMARY KEY,
    animal_id INT NOT NULL REFERENCES animal(animal_id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    morning_yield DECIMAL(5,2) CHECK (morning_yield >= 0),
    evening_yield DECIMAL(5,2) CHECK (evening_yield >= 0),
    total_yield DECIMAL(5,2) GENERATED ALWAYS AS (COALESCE(morning_yield,0) + COALESCE(evening_yield,0)) STORED,
    fat_content DECIMAL(4,2) CHECK (fat_content BETWEEN 0 AND 10),
    protein_content DECIMAL(4,2) CHECK (protein_content BETWEEN 0 AND 10),
    somatic_cell_count INT CHECK (somatic_cell_count >= 0),
    quality_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS weight_record (
    weight_id SERIAL PRIMARY KEY,
    animal_id INT NOT NULL REFERENCES animal(animal_id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    weight_kg DECIMAL(6,2) NOT NULL CHECK (weight_kg > 0),
    body_condition_score INT CHECK (body_condition_score BETWEEN 1 AND 5),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS breeding_record (
    breeding_id SERIAL PRIMARY KEY,
    female_id INT NOT NULL REFERENCES animal(animal_id) ON DELETE CASCADE,
    male_id INT REFERENCES animal(animal_id) ON DELETE SET NULL,
    breeding_date DATE NOT NULL,
    breeding_method VARCHAR(20) CHECK (breeding_method IN ('Natural', 'AI')),
    pregnancy_status VARCHAR(20) DEFAULT 'Unknown' CHECK (pregnancy_status IN ('Unknown', 'Confirmed', 'Failed')),
    expected_calving_date DATE,
    actual_calving_date DATE,
    outcome VARCHAR(20) CHECK (outcome IN ('Live Calf', 'Stillborn', 'Abortion')),
    offspring_id INT REFERENCES animal(animal_id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

------------------------------
-- 5. FEED & NUTRITION MANAGEMENT
------------------------------

CREATE TABLE IF NOT EXISTS feed_log (
    log_id SERIAL PRIMARY KEY,
    pen_id INT NOT NULL REFERENCES animal_pen(pen_id) ON DELETE CASCADE,
    feed_type VARCHAR(50) NOT NULL CHECK (feed_type IN (
        'Napier Grass', 'Dairy Meal', 'Maize Bran', 'Hay', 'Silage', 
        'Concentrates', 'Mineral Supplement', 'Other'
    )),
    quantity_kg DECIMAL(8,2) NOT NULL CHECK (quantity_kg > 0),
    cost_per_kg DECIMAL(8,2) NOT NULL CHECK (cost_per_kg >= 0),
    total_cost DECIMAL(10,2) GENERATED ALWAYS AS (quantity_kg * cost_per_kg) STORED,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- INDIVIDUAL ANIMAL FEED TRACKING (NEW)
CREATE TABLE IF NOT EXISTS individual_feed_log (
    individual_feed_id SERIAL PRIMARY KEY,
    animal_id INT NOT NULL REFERENCES animal(animal_id) ON DELETE CASCADE,
    feed_type VARCHAR(50) NOT NULL,
    quantity_kg DECIMAL(6,2) NOT NULL CHECK (quantity_kg > 0),
    cost_per_kg DECIMAL(6,2) NOT NULL CHECK (cost_per_kg >= 0),
    total_cost DECIMAL(8,2) GENERATED ALWAYS AS (quantity_kg * cost_per_kg) STORED,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

------------------------------
-- 6. HEALTH MANAGEMENT
------------------------------

CREATE TABLE IF NOT EXISTS health_record (
    record_id SERIAL PRIMARY KEY,
    animal_id INT NOT NULL REFERENCES animal(animal_id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    condition VARCHAR(100) NOT NULL,
    symptoms TEXT NOT NULL,
    treatment TEXT NOT NULL,
    cost DECIMAL(10,2) DEFAULT 0 CHECK (cost >= 0),
    vet_name VARCHAR(100),
    next_checkup_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

------------------------------
-- 7. LABOR & OPERATIONS TRACKING
------------------------------

CREATE TABLE IF NOT EXISTS labor_activity (
    activity_id SERIAL PRIMARY KEY,
    farmer_id INT NOT NULL REFERENCES farmer(farmer_id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN (
        'Milking', 'Feeding', 'Cleaning', 'Health Check', 'Treatment',
        'Breeding', 'Moving Animals', 'Maintenance', 'Other'
    )),
    description TEXT,
    hours_spent DECIMAL(4,2) NOT NULL CHECK (hours_spent > 0),
    labor_cost DECIMAL(8,2) NOT NULL CHECK (labor_cost >= 0),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    related_animal_id INT REFERENCES animal(animal_id) ON DELETE SET NULL,
    related_pen_id INT REFERENCES animal_pen(pen_id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

------------------------------
-- 8. FINANCIAL MANAGEMENT
------------------------------

CREATE TABLE IF NOT EXISTS financial_transaction (
    transaction_id SERIAL PRIMARY KEY,
    farmer_id INT NOT NULL REFERENCES farmer(farmer_id) ON DELETE CASCADE,
    type VARCHAR(10) NOT NULL CHECK (type IN ('Income', 'Expense')),
    category VARCHAR(30) NOT NULL CHECK (category IN (
        -- Income categories
        'Milk Sales', 'Animal Sales', 'Manure Sales', 'Breeding Services',
        -- Expense categories
        'Feed', 'Veterinary', 'Labor', 'Medication', 'Transport', 
        'Breeding Costs', 'Equipment', 'Utilities', 'Other'
    )),
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    related_animal_id INT REFERENCES animal(animal_id) ON DELETE SET NULL,
    related_pen_id INT REFERENCES animal_pen(pen_id) ON DELETE SET NULL,
    buyer_supplier VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

------------------------------
-- 9. PERFORMANCE ANALYTICS CACHE
------------------------------

CREATE TABLE IF NOT EXISTS performance_cache (
    cache_id SERIAL PRIMARY KEY,
    farmer_id INT NOT NULL REFERENCES farmer(farmer_id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(12,4) NOT NULL,
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('Daily', 'Weekly', 'Monthly', 'Yearly')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    related_animal_id INT REFERENCES animal(animal_id) ON DELETE SET NULL,
    related_pen_id INT REFERENCES animal_pen(pen_id) ON DELETE SET NULL,
    calculated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(farmer_id, metric_name, period_type, period_start, related_animal_id, related_pen_id)
);

------------------------------
-- 10. INDEXES FOR PERFORMANCE
------------------------------

-- Farmer indexes
CREATE INDEX IF NOT EXISTS idx_farmer_username ON farmer(username);

-- Animal pen indexes
CREATE INDEX IF NOT EXISTS idx_animal_pen_farmer_id ON animal_pen(farmer_id);
CREATE INDEX IF NOT EXISTS idx_animal_pen_type ON animal_pen(pen_type);

-- Animal indexes
CREATE INDEX IF NOT EXISTS idx_animal_farmer_id ON animal(farmer_id);
CREATE INDEX IF NOT EXISTS idx_animal_pen_id ON animal(pen_id);
CREATE INDEX IF NOT EXISTS idx_animal_status ON animal(status);
CREATE INDEX IF NOT EXISTS idx_animal_tag_number ON animal(tag_number);
CREATE INDEX IF NOT EXISTS idx_animal_type ON animal(animal_type);
CREATE INDEX IF NOT EXISTS idx_animal_disposal_date ON animal(disposal_date);

-- Production indexes
CREATE INDEX IF NOT EXISTS idx_milk_production_animal_id ON milk_production(animal_id);
CREATE INDEX IF NOT EXISTS idx_milk_production_date ON milk_production(date);
CREATE INDEX IF NOT EXISTS idx_weight_record_animal_id ON weight_record(animal_id);
CREATE INDEX IF NOT EXISTS idx_weight_record_date ON weight_record(date);
CREATE INDEX IF NOT EXISTS idx_breeding_female_id ON breeding_record(female_id);
CREATE INDEX IF NOT EXISTS idx_breeding_date ON breeding_record(breeding_date);

-- Feed indexes
CREATE INDEX IF NOT EXISTS idx_feed_log_pen_id ON feed_log(pen_id);
CREATE INDEX IF NOT EXISTS idx_feed_log_date ON feed_log(date);
CREATE INDEX IF NOT EXISTS idx_individual_feed_animal_id ON individual_feed_log(animal_id);
CREATE INDEX IF NOT EXISTS idx_individual_feed_date ON individual_feed_log(date);

-- Health indexes
CREATE INDEX IF NOT EXISTS idx_health_record_animal_id ON health_record(animal_id);
CREATE INDEX IF NOT EXISTS idx_health_record_date ON health_record(date);

-- Labor indexes
CREATE INDEX IF NOT EXISTS idx_labor_activity_farmer_id ON labor_activity(farmer_id);
CREATE INDEX IF NOT EXISTS idx_labor_activity_date ON labor_activity(date);
CREATE INDEX IF NOT EXISTS idx_labor_activity_type ON labor_activity(activity_type);

-- Financial indexes
CREATE INDEX IF NOT EXISTS idx_transaction_farmer_id ON financial_transaction(farmer_id);
CREATE INDEX IF NOT EXISTS idx_transaction_date ON financial_transaction(date);
CREATE INDEX IF NOT EXISTS idx_transaction_type ON financial_transaction(type);
CREATE INDEX IF NOT EXISTS idx_transaction_category ON financial_transaction(category);
CREATE INDEX IF NOT EXISTS idx_transaction_related_animal ON financial_transaction(related_animal_id);

-- Performance cache indexes
CREATE INDEX IF NOT EXISTS idx_performance_cache_farmer_id ON performance_cache(farmer_id);
CREATE INDEX IF NOT EXISTS idx_performance_cache_metric ON performance_cache(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_cache_period ON performance_cache(period_start, period_end);

------------------------------
-- 11. FUNCTIONS & TRIGGERS
------------------------------

-- Update animal updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_animal_updated_at ON animal;
CREATE TRIGGER update_animal_updated_at 
    BEFORE UPDATE ON animal 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create default pens when farmer registers
CREATE OR REPLACE FUNCTION create_default_pens()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO animal_pen (pen_name, pen_type, description, farmer_id) VALUES
    ('Calf Pen', 'Calves', 'Young animals under 1 year', NEW.farmer_id),
    ('Heifer Yard', 'Heifers', 'Young females before first calving', NEW.farmer_id),
    ('Milking Parlor', 'Milking Cows', 'Lactating dairy animals', NEW.farmer_id),
    ('Dry Cow Area', 'Dry Cows', 'Non-lactating dairy animals', NEW.farmer_id),
    ('Bull Pen', 'Bulls', 'Breeding males', NEW.farmer_id),
    ('Beef Feedlot', 'Beef Fattening', 'Animals being fattened for beef', NEW.farmer_id);
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS create_default_pens ON farmer;
CREATE TRIGGER create_default_pens 
    AFTER INSERT ON farmer 
    FOR EACH ROW 
    EXECUTE FUNCTION create_default_pens();

-- Auto-update animal status when disposal info is added
CREATE OR REPLACE FUNCTION update_animal_status_on_disposal()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.disposal_date IS NOT NULL AND NEW.status = 'Active' THEN
        IF NEW.disposal_reason IN ('Sold', 'Culled') THEN
            NEW.status = 'Sold';
        ELSIF NEW.disposal_reason = 'Died' THEN
            NEW.status = 'Dead';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_animal_status_on_disposal ON animal;
CREATE TRIGGER update_animal_status_on_disposal
    BEFORE UPDATE ON animal
    FOR EACH ROW
    EXECUTE FUNCTION update_animal_status_on_disposal();

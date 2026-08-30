create schema Pharma_Commercial_Analytics_Territory_Performance;
create database analysis;
use analysis;
CREATE TABLE Sales_Territories (
    territory_id INT PRIMARY KEY,
    territory_name VARCHAR(100),
    region VARCHAR(50),
    district VARCHAR(50),
    target_quota_q1 INT,
    target_quota_q2 INT
);

# Sales Representatives
CREATE TABLE Sales_Reps (
    rep_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    territory_id INT,
    hire_date DATE,
    FOREIGN KEY (territory_id) REFERENCES Sales_Territories(territory_id)
);

-- 3. Physicians Table (Adding Payer Preference)
CREATE TABLE Physicians (
    physician_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    specialty VARCHAR(100),
    npi_number VARCHAR(10) UNIQUE, 
    territory_id INT,
    preferred_payer_segment VARCHAR(50), 
    FOREIGN KEY (territory_id) REFERENCES Sales_Territories(territory_id)
);

-- 4. Products Table
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    brand_name VARCHAR(100),
    therapeutic_class VARCHAR(100),
    is_proprietary_brand BOOLEAN,
    competitor_group VARCHAR(50)
);

-- 5. Deep Prescription Claims (Granular tracking)
CREATE TABLE Prescription_Data (
    rx_id INT PRIMARY KEY,
    physician_id INT,
    product_id INT,
    dispense_date DATE,
    trx INT, -- Total Prescriptions
    nrb INT, -- New-to-Brand Prescriptions
    refills_remaining INT,
    payer_type VARCHAR(50), -- e.g., Managed Care, Cash
    FOREIGN KEY (physician_id) REFERENCES Physicians(physician_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

INSERT INTO Sales_Territories (territory_id, territory_name, region, district, target_quota_q1, target_quota_q2) VALUES
(101, 'Northeast Oncology A', 'North', 'District 1', 500, 550),
(102, 'Mid-Atlantic Care', 'North', 'District 2', 400, 420),
(103, 'Southeast Block', 'South', 'District 1', 600, 650),
(104, 'West Coast Specialty', 'West', 'District 3', 700, 750),
(105, 'Midwest Hub', 'East', 'District 2', 350, 380);

-- 2. Populate Sales Representatives
INSERT INTO Sales_Reps (rep_id, first_name, last_name, territory_id, hire_date) VALUES
(1, 'Rahul', 'Sharma', 101, '2023-04-15'),
(2, 'Priya', 'Patel', 102, '2024-01-10'),
(3, 'Amit', 'Verma', 103, '2022-11-01'),
(4, 'Sneha', 'Reddy', 104, '2025-06-01'), -- Newer rep, might underperform
(5, 'Vikram', 'Singh', 105, '2021-08-24');

-- 3. Populate Physicians (With NPIs and Payer Segments)
INSERT INTO Physicians (physician_id, first_name, last_name, specialty, npi_number, territory_id, preferred_payer_segment) VALUES
(501, 'Dr. Arvinder', 'Anand', 'Oncology', '1234567890', 101, 'Commercial'),
(502, 'Dr. Beatrice', 'Correa', 'Oncology', '2345678901', 101, 'Medicare'),
(503, 'Dr. Chandresh', 'Joshi', 'Cardiology', '3456789012', 102, 'Commercial'),
(504, 'Dr. Divya', 'Mehta', 'Oncology', '4567890123', 103, 'Medicaid'),
(505, 'Dr. Evan', 'Wright', 'Oncology', '5678901234', 104, 'Medicare'),
(506, 'Dr. Farah', 'Khan', 'Oncology', '6789012345', 105, 'Commercial');

-- 4. Populate Products (Your Brand vs Competitors)
INSERT INTO Products (product_id, brand_name, therapeutic_class, is_proprietary_brand, competitor_group) VALUES
(9001, 'Zeloxen (Our Brand)', 'Oncology - TKI', TRUE, NULL),
(9002, 'CompeteRx Alpha', 'Oncology - TKI', FALSE, 'Group A'),
(9003, 'CompeteRx Beta', 'Oncology - TKI', FALSE, 'Group A'),
(9004, 'CardioMax', 'Cardiology - Beta Blocker', FALSE, 'Group B');

-- 5. Populate Detailed Prescription Claims (Q1 2026 Data)
INSERT INTO Prescription_Data (rx_id, physician_id, product_id, dispense_date, trx, nrb, refills_remaining, payer_type) VALUES
-- Dr. Anand (High-volume writer, highly loyal to Our Brand)
(1001, 501, 9001, '2026-01-15', 120, 30, 3, 'Commercial'),
(1002, 501, 9001, '2026-02-20', 140, 40, 2, 'Commercial'),
(1003, 501, 9002, '2026-01-18', 40, 10, 1, 'Commercial'),

-- Dr. Correa (Prefers Competitor Alpha for Medicare patients due to bad pricing/formulary)
(1004, 502, 9001, '2026-01-10', 30, 5, 2, 'Medicare'),
(1005, 502, 9002, '2026-02-12', 180, 50, 4, 'Medicare'),
(1006, 502, 9003, '2026-03-05', 90, 20, 3, 'Medicare'),

-- Dr. Joshi (Cardiologist - writes very low volumes for oncology drugs)
(1007, 503, 9004, '2026-01-22', 300, 80, 5, 'Commercial'),
(1008, 503, 9001, '2026-02-15', 5, 1, 0, 'Commercial'), 

-- Dr. Mehta (Massive volume writer in the South)
(1009, 504, 9001, '2026-01-05', 250, 70, 4, 'Medicaid'),
(1010, 504, 9001, '2026-02-10', 280, 90, 3, 'Medicaid'),
(1011, 504, 9003, '2026-03-01', 100, 15, 2, 'Medicaid'),

-- Dr. Wright (West Coast - Underperforming due to Rep Sneha being new)
(1012, 505, 9001, '2026-01-20', 40, 10, 2, 'Medicare'),
(1013, 505, 9002, '2026-02-25', 150, 40, 4, 'Medicare'),

-- Dr. Farah Khan (East Coast - Stable volume)
(1014, 506, 9001, '2026-01-15', 190, 45, 3, 'Commercial'),
(1015, 506, 9002, '2026-03-10', 110, 25, 2, 'Commercial');

WITH Patient_Chronology AS (
    SELECT 
        pd.patient_id,  -- Sourced from the primary context of longitudinal patient datasets
        pd.dispense_date,
        prod.brand_name,
        prod.is_proprietary_brand,
        pd.refills_remaining,
        LAG(prod.brand_name) OVER (PARTITION BY pd.patient_id ORDER BY pd.dispense_date) as previous_brand,
        LAG(pd.dispense_date) OVER (PARTITION BY pd.patient_id ORDER BY pd.dispense_date) as previous_dispense_date
    FROM Prescription_Data pd
    JOIN Products prod ON pd.product_id = prod.product_id
)
SELECT 
    patient_id,
    previous_brand as switched_from_brand,
    brand_name as switched_to_brand,
    previous_dispense_date,
    dispense_date as switch_date,
    -- Calculate the exact gap in days between treatments
    (dispense_date - previous_dispense_date) as days_between_therapy_switch,
    CASE 
        WHEN (dispense_date - previous_dispense_date) > 30 THEN 'High Risk: Non-Compliant Switch Gap'
        ELSE 'Compliant Switch'
    END as clinical_compliance_status
FROM Patient_Chronology
WHERE previous_brand IS NOT NULL 
  AND previous_brand != brand_name
  AND is_proprietary_brand = TRUE;
  
  ALTER TABLE Prescription_Data ADD COLUMN patient_id INT;
  
  #Show Sales Reps and Their Assigned Territories
  select
  sales_reps.rep_id,
  sales_reps.first_name,
  sales_reps.last_name,
  sales_territories.territory_id,
  sales_territories.territory_name,
  sales_territories.district
  from sales_reps
  join sales_territories on sales_territories.territory_id;
  
  #List Physicians and Their Territory Details
  select
  physicians.physician_id,
  physicians.first_name,
  physicians.last_name,
  physicians.specialty,
  physicians.territory_id
  from physicians
  join sales_territories on sales_territories.territory_id;
  
  #See Which Products Each Physician Prescribed
 select physicians.physician_id,
 physicians.first_name,
 physicians.last_name,
  prescription_data.rx_id,
  prescription_data.product_id,
  prescription_data.trx,
  products.product_id,
  products.brand_name
  from physicians
  join prescription_data on prescription_data.rx_id
  join products on products.product_id;
  
# Track Sales Reps and the Products Prescribed in Their Territory
select
sales_reps.rep_id,
sales_reps.first_name,
sales_reps.last_name,
products.product_id,
products.brand_name,
sales_territories.territory_id,
prescription_data.rx_id
from sales_reps
join products on products.product_id
join sales_territories on sales_territories.territory_id
join prescription_data on prescription_data.rx_id;

#Total Prescriptions Prescribed by Each Physician
select
prescription_data.physician_id as doctor_id,
 sum(trx) as total_prescription
 from prescription_data
 group by physician_id;
 
#Count of Physicians in Each Specialty
SELECT 
    specialty AS medicine_specialty, 
    COUNT(physician_id) AS total_physician 
FROM physicians 
GROUP BY specialty;

#Total Brand Sales & New Patient Volume per Territory
SELECT 
    st.territory_name AS territory,
    st.region AS sales_region,
    SUM(pd.trx) AS total_prescriptions,
    SUM(pd.nrb) AS total_new_brand_patients
FROM Prescription_Data pd
JOIN Physicians phy ON pd.physician_id = phy.physician_id
JOIN Sales_Territories st ON phy.territory_id = st.territory_id
GROUP BY st.territory_name, st.region;

#Calculates average prescriptions per payer segment and filters out lower-volume segments using HAVING alongside column aliases.
select
prescription_data.payer_type as insurance_claimed,
count(rx_id) as insurance_claimed,
count(trx) as avg_insurance_claimed
from prescription_data
group by payer_type having sum(trx)<300;

SELECT COUNT(*) total_records
FROM Prescription_Data;
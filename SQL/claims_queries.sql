-- ================================================
-- Insurance Analytics Project - SQL Queries
-- Author: Supriya Rajendran
-- Purpose: Data validation, KPI calculations, aggregation, ranking, and anomaly detection
-- Dataset: claims_data
-- ================================================

-- 1. Data Validation & Cleaning
SELECT 
    COUNT(*) AS total_rows,
    COUNT(claim_amount) AS claim_amount_count,
    COUNT(premium) AS premium_count
FROM claims_data;

SELECT 
    claim_id,
    COALESCE(claim_amount,0) AS claim_amount,
    COALESCE(premium,0) AS premium
FROM claims_data;

-- 2. Core Metrics Calculation: Loss Ratio and SLA Breach
SELECT 
    claim_id,
    claim_amount,
    premium,
    processing_days,
    ROUND(claim_amount / NULLIF(premium,0),2) AS loss_ratio,
    CASE 
        WHEN processing_days > 10 THEN 'Yes'
        ELSE 'No' 
    END AS sla_breach
FROM claims_data;

-- 3. High-Risk Claims Flag
SELECT 
    claim_id,
    claim_amount,
    premium,
    ROUND(claim_amount / NULLIF(premium,0),2) AS loss_ratio,
    processing_days,
    CASE
        WHEN ROUND(claim_amount / NULLIF(premium,0),2) > 1 THEN 'X'
        ELSE ''
    END AS high_risk_claim_flag,
    CASE
        WHEN processing_days > 10 THEN 'X'
        ELSE ''
    END AS sla_breach_flag
FROM claims_data;

-- 4. Regional Summary
SELECT 
    region,
    COUNT(claim_id) AS total_claims,
    SUM(claim_amount) AS total_claim_amount,
    SUM(premium) AS total_premium,
    AVG(processing_days) AS avg_processing_days,
    SUM(claim_amount) / NULLIF(SUM(premium),0) AS total_loss_ratio
FROM claims_data
GROUP BY region
ORDER BY total_claim_amount DESC;

-- 5. Ranking High-Risk Claims Within Region
SELECT 
    claim_id,
    region,
    claim_amount,
    premium,
    ROUND(claim_amount / NULLIF(premium,0),2) AS loss_ratio,
    RANK() OVER(PARTITION BY region ORDER BY (claim_amount / NULLIF(premium,0)) DESC) AS claim_rank
FROM claims_data;

-- 6. Running Total of Claim Amounts by Region
SELECT 
    claim_id,
    region,
    claim_date,
    claim_amount,
    SUM(claim_amount) OVER(PARTITION BY region ORDER BY claim_date) AS running_region_claim_total
FROM claims_data;

-- 7. Combined Insights: High-Risk or SLA-Breaching Claims
SELECT *,
    ROUND(claim_amount / NULLIF(premium,0),2) AS loss_ratio,
    CASE 
        WHEN ROUND(claim_amount / NULLIF(premium,0),2) > 1 THEN 'YES'
        ELSE 'NO'
    END AS high_risk_claim,
    CASE 
        WHEN processing_days > 10 THEN 'YES'
        ELSE 'NO'
    END AS sla_breach
FROM claims_data
WHERE ROUND(claim_amount / NULLIF(premium,0),2) > 1 
   OR processing_days > 10;

-- 8. Rank High Value Claims Within Each Region
SELECT 
    region,
    claim_id,
    claim_amount,
    RANK() OVER(PARTITION BY region ORDER BY claim_amount DESC) AS regional_claim_rank
FROM claims_data;

-- 9. Identify Claims Far Above Average (50% higher than regional avg)
SELECT * 
FROM (
    SELECT
        claim_id,
        region,
        claim_amount,
        AVG(claim_amount) OVER(PARTITION BY region) AS avg_region_claim,
        claim_amount - AVG(claim_amount) OVER(PARTITION BY region) AS deviation
    FROM claims_data
) t
WHERE claim_amount > avg_region_claim * 1.5;

-- 10. Flag Claims More Than 2 Standard Deviations Above Average (Using CTE)
WITH regional_data AS (
    SELECT
        region,
        AVG(claim_amount) AS avg_amt,
        STDDEV(claim_amount) AS stddev_amt
    FROM claims_data
    GROUP BY region
)
SELECT 
    c.claim_id,
    c.region,
    c.claim_amount,
    rd.avg_amt,
    rd.stddev_amt
FROM claims_data c
JOIN regional_data rd ON c.region = rd.region
WHERE c.claim_amount > rd.avg_amt + (2 * rd.stddev_amt);

-- 11. SLA Performance by Region
SELECT 
    region,
    COUNT(claim_id) AS total_claims,
    SUM(CASE WHEN processing_days > 10 THEN 1 ELSE 0 END) AS sla_breaches,
    ROUND(SUM(CASE WHEN processing_days > 10 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS sla_breach_percentage
FROM claims_data
GROUP BY region;

-- 12. Claims Contribution to Total Exposure (% Impact)
SELECT 
    claim_id,
    region,
    claim_amount,
    ROUND(claim_amount * 100.0 / SUM(claim_amount) OVER(),2) AS percentage_of_total_claims
FROM claims_data
ORDER BY percentage_of_total_claims DESC;

-- 13. Top 3 Claims Per Region
SELECT * 
FROM (
    SELECT
        claim_id,
        region,
        claim_amount,
        DENSE_RANK() OVER(PARTITION BY region ORDER BY claim_amount DESC) AS claim_amount_rank
    FROM claims_data
) t
WHERE claim_amount_rank <= 3;

-- 14. Claims Maturity Analysis
SELECT 
    claim_id,
    processing_days,
    CASE 
        WHEN processing_days <= 5 THEN 'Fast'
        WHEN processing_days BETWEEN 6 AND 10 THEN 'Normal'
        ELSE 'Delayed'
    END AS processing_category
FROM claims_data;

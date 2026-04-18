Create database Sales_Analytics_Insights;
Use Sales_Analytics_Insights;

/* 1. Predicting High-Value Deals Using Revenue Percentile Analysis */

WITH DealSegments AS (
    SELECT 
        opportunity_id,
        sales_agent,
        close_value,
        NTILE(3) OVER (ORDER BY close_value DESC) AS deal_segment
    FROM sales_pipeline
    WHERE deal_stage = 'Won' AND close_value IS NOT NULL
)
SELECT 
    sales_agent,
    deal_segment,
    COUNT(opportunity_id) AS total_deals,
    SUM(close_value) AS total_revenue
FROM DealSegments
WHERE deal_segment = 1  -- High-value deals
GROUP BY sales_agent, deal_segment
ORDER BY total_revenue DESC;


/* 2. Sales Pipeline Velocity Analysis */

WITH StageDurations AS (
    SELECT 
        opportunity_id,
        account,
        DATEDIFF(DAY, engage_date, close_date) AS total_days,
        deal_stage
    FROM sales_pipeline
    WHERE engage_date IS NOT NULL AND close_date IS NOT NULL
)
SELECT 
    account,
    AVG(total_days) AS avg_days_to_close,
    COUNT(opportunity_id) AS total_deals
FROM StageDurations
GROUP BY account
ORDER BY avg_days_to_close DESC;  -- Slowest accounts first

/* 3. Average Deal Closing Time by Industry */

SELECT 
    a.sector AS industry,
    AVG(DATEDIFF(DAY, sp.engage_date, sp.close_date)) AS avg_closing_days,
    COUNT(sp.opportunity_id) AS total_deals
FROM sales_pipeline sp
JOIN accounts a ON sp.account = a.account
WHERE sp.close_date IS NOT NULL
GROUP BY a.sector
ORDER BY avg_closing_days ASC;

/* 4. Churn Risk Analysis Based on Deal Loss Patterns */ 

WITH AccountDealStats AS (
    SELECT 
        account,
        COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) * 100.0 / COUNT(*) AS lost_deal_percentage,
        MAX(CASE WHEN deal_stage = 'Won' THEN close_date END) AS last_won_date
    FROM sales_pipeline
    GROUP BY account
)
SELECT 
    account,
    lost_deal_percentage,
    DATEDIFF(DAY, last_won_date, GETDATE()) AS days_since_last_win
FROM AccountDealStats
WHERE lost_deal_percentage > 40  -- High churn risk threshold
ORDER BY days_since_last_win DESC; 

/* 5. Sales Seasonality & Revenue Impact Analysis */

SELECT 
    YEAR(close_date) AS year,
    MONTH(close_date) AS month,
    SUM(close_value) AS total_revenue,
    COUNT(opportunity_id) AS total_deals
FROM sales_pipeline
WHERE deal_stage = 'Won' AND close_date IS NOT NULL
GROUP BY YEAR(close_date), MONTH(close_date)
ORDER BY year, month;





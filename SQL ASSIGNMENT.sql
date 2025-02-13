-- Customer Risk Analysis: Identify customers with low credit scores and high-risk loans to predict potential defaults and prioritize risk mitigation strategies.

SELECT 
  customer_table.customer_id,
  customer_table.name,
  customer_table.credit_score,
  loan_table.loan_id,
  loan_table.loan_amount,
  loan_table.default_risk
FROM 
  sql_assignment.customer_table 
  JOIN sql_assignment.loan_table ON customer_table.customer_id = loan_table.customer_id
WHERE 
  customer_table.credit_score < 600  -- Low credit score threshold
  AND loan_table.default_risk = 'High'  -- High default risk threshold
ORDER BY 
  customer_table.credit_score ASC, 
  loan_table.default_risk DESC;
  
 -- Loan Purpose Insights: Determine the most popular loan purposes and their associated revenues to align financial products with customer demands
 SELECT loan_purpose, COUNT(*) as most_popular_loan, SUM(loan_amount) as total_revenue FROM loan_table group by loan_purpose order by count(*) desc;
-- High-Value Transactions: Detect transactions that exceed 30% of their respective loan amounts to flag potential fraudulent activities
 select transaction_table.transaction_id, transaction_table.transaction_amount, loan_table.loan_id, loan_table.loan_amount,(transaction_table.transaction_amount/loan_table.loan_amount)*100 as transaction_percentage from sql_assignment.transaction_table join sql_assignment.loan_table on transaction_table.loan_id=loan_table.loan_id where (transaction_table.transaction_amount/loan_table.loan_amount)*100 > 30;
 -- 
 -- Missed EMI Count: Analyze the number of missed EMIs per loan to identify loans at risk of default and suggest intervention strategies

SELECT
l.loan_id,
c.name,
COUNT(CASE WHEN t.status = 'Missed' THEN t.transaction_id END) AS missed_emi_count
FROM
sql_assignment.loan_table l
JOIN sql_assignment.transaction_table t ON l.loan_id = t.loan_id
JOIN sql_assignment.customer_table c ON l.customer_id = c.customer_id
GROUP BY
l.loan_id, c.name
HAVING
COUNT(CASE WHEN t.status = 'Missed' THEN t.transaction_id END) > 2

SELECT 
    l.loan_id, 
    l.customer_id, 
    COUNT(t.transaction_id) AS Paid_EMIs,
    (12 - COUNT(t.transaction_id)) AS Missed_EMIs,  -- Assuming 12 EMIs per year
    ROUND(((12 - COUNT(t.transaction_id)) / 12) * 100, 2) AS Missed_Percentage,
    CASE 
        WHEN ((12 - COUNT(t.transaction_id)) / 12) * 100 <= 10 THEN 'Low Risk - Gentle Reminder'
        WHEN ((12 - COUNT(t.transaction_id)) / 12) * 100 BETWEEN 10 AND 30 THEN 'Moderate Risk - Personalized Call'
        ELSE 'High Risk - Legal Notice/Recovery Measures'
    END AS Risk_Level
FROM loan_table l
LEFT JOIN transaction_table t 
    ON l.loan_id = t.loan_id 
    AND t.transaction_type = 'EMI Payment' 
    AND t.status = 'Successful'
GROUP BY l.loan_id, l.customer_id
ORDER BY Missed_Percentage DESC;

-- Regional Loan Distribution: Examine the geographical distribution of loan disbursements to assess regional trends and business opportunities.
SELECT 
    c.region, 
    COUNT(l.loan_id) AS Total_Loans, 
    SUM(l.loan_amount) AS Total_Loan_Disbursement, 
    AVG(l.loan_amount) AS Avg_Loan_Amount
FROM customer_table c
JOIN loan_table l ON c.customer_id = l.customer_id
GROUP BY c.region
ORDER BY Total_Loan_Disbursement DESC;

select transaction_type, count(*) from transaction_table group by transaction_type order by count(*);
-- Loyal Customers: List customers who have been associated with Cross River Bank for over five years and evaluate their loan activity to design loyalty programs.
select customer_table.customer_id, customer_table.name,customer_table.customer_since, loan_table.loan_amount,loan_table.loan_status from  sql_assignment.customer_table join sql_assignment.loan_table on customer_table.customer_id=loan_table.customer_id where customer_since < date_sub(curdate(),interval 5 year);
-- High-Performing Loans: Identify loans with excellent repayment histories to refine lending policies and highlight successful products.
SELECT customer_table.name, count(*) as name_total, sum(loan_table.loan_amount) as total_loan_amount, sum( loan_table.repayment_history) as total_repayment_history from sql_assignment.loan_table join sql_assignment.customer_table on loan_table.customer_id=customer_table.customer_id group by customer_table.name;
-- Age-Based Loan Analysis: Analyze loan amounts disbursed to customers of different age groups to design targeted financial products.

SELECT 
  CASE 
    WHEN c.age BETWEEN 18 AND 24 THEN '18-24'
    WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
    WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
    WHEN c.age BETWEEN 45 AND 54 THEN '45-54'
    WHEN c.age >= 55 THEN '55+'
    ELSE 'Unknown'
  END AS age_group,
  COUNT(l.loan_id) AS loan_count,
  SUM(l.loan_amount) AS total_loan_amount,
  AVG(l.loan_amount) AS average_loan_amount
FROM 
  sql_assignment.customer_table c
JOIN 
  sql_assignment.loan_table l 
  ON c.customer_id = l.customer_id
GROUP BY 
  age_group
ORDER BY 
  age_group;
  
  -- Seasonal Transaction Trends: Examine transaction patterns over years and months to identify seasonal trends in loan repayments.
SELECT 
    YEAR(t.transaction_date) AS transaction_year, 
    MONTH(t.transaction_date) AS transaction_month,
    COUNT(t.transaction_id) AS total_transactions, 
    SUM(t.transaction_amount) AS total_repayments  
FROM 
    transaction_table t
JOIN 
    loan_table l ON t.loan_id = l.loan_id  
GROUP BY 
    transaction_year, 
    transaction_month                      
ORDER BY 
    transaction_year, 
    transaction_month;  
-- Fraud Detection: Highlight potential fraud by identifying mismatches between customer address locations and transaction IP locations.

SELECT 
  c.customer_id,
  COUNT(l.loan_id) AS loan_count,
  SUM(l.loan_amount) AS total_loan_amount,
  AVG(l.loan_amount) AS average_loan_amount
FROM 
  sql_assignment.customer_table c
JOIN 
  sql_assignment.loan_table l 
  ON c.customer_id = l.customer_id
GROUP BY 
  c.customer_id
HAVING 
  loan_count > 5 OR total_loan_amount > 100000;
  
  -- Repayment History Analysis: Rank loans by repayment performance using window functions.
SELECT 
    loan_id, 
    customer_id, 
    loan_amount, 
    loan_date, 
    loan_status, 
    repayment_history, 
    interest_rate, 
    loan_purpose, 
    collateral, 
    default_risk,
    RANK() OVER (ORDER BY repayment_history DESC) AS repayment_rank  
FROM 
    loan_table
    -- Credit Score vs. Loan Amount: Compare average loan amounts for different credit score ranges.
    SELECT 
  CASE 
    WHEN c.credit_score BETWEEN 300 AND 579 THEN 'Poor (300-579)'
    WHEN c.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
    WHEN c.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
    WHEN c.credit_score BETWEEN 740 AND 850 THEN 'Excellent (740-850)'
    ELSE 'Unknown'
  END AS credit_score_range,
  AVG(l.loan_amount) AS average_loan_amount
FROM 
  sql_assignment.customer_table c
JOIN 
  sql_assignment.loan_table l 
  ON c.customer_id = l.customer_id
GROUP BY 
  credit_score_range
ORDER BY 
  credit_score_range;
  -- Top Borrowing Regions: Identify regions with the highest total loan disbursements.
SELECT 
  c.address,
  SUM(l.loan_amount) AS total_loan_disbursement
FROM 
  sql_assignment.customer_table c
JOIN 
  sql_assignment.loan_table l 
  ON c.customer_id = l.customer_id
GROUP BY 
  c.address
ORDER BY 
  total_loan_disbursement DESC
LIMIT 0, 1000;
-- Early Repayment Patterns: Detect loans with frequent early repayments and their impact on revenue.
SELECT 
    t.transaction_id, 
    t.loan_id, 
    t.customer_id, 
    t.transaction_date, 
    t.transaction_amount, 
    l.loan_amount,  -- Assuming loan_amount is a column in the loan_table
    CASE 
        WHEN t.transaction_amount > 0.3 * l.loan_amount THEN 'High-Value Transaction' 
        ELSE 'Normal Transaction' 
    END AS transaction_flag
FROM 
    transaction_table t
JOIN 
    loan_table l ON t.loan_id = l.loan_id  
WHERE 
    t.transaction_amount > 0.3 * l.loan_amount;
-- Feedback Correlation: Correlate customer feedback sentiment scores with loan statuses.
SELECT 
    t.transaction_id, 
    t.loan_id, 
    t.customer_id, 
    t.transaction_date, 
    t.transaction_amount, 
    l.loan_amount,  
    CASE 
        WHEN t.transaction_amount > 0.3 * l.loan_amount THEN 'High-Value Transaction' 
        ELSE 'Normal Transaction' 
    END AS transaction_flag
FROM 
    transaction_table t
JOIN 
    loan_table l ON t.loan_id = l.loan_id  
WHERE 
    t.transaction_amount > 0.3 * l.loan_amount;


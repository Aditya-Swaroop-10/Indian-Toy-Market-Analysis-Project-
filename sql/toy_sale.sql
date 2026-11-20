CREATE DATABASE toy_sales;
USE toy_sales;

SELECT * FROM sales_toy;

-- A. Sales performance analysis
-- Q1. Calculate net revenue, total units sold, and total transactions.

SELECT SUM(net_revenue_inr) As total_revenue, SUM(quantity) AS total_quantity, COUNT(DISTINCT transaction_id) As total_transactions
FROM sales_toy; 

-- Q2. Find the top 10 brands based on net revenue. Display their total revenue, gross revenue, and total quantity sold.

SELECT brand, SUM(net_revenue_inr) AS total_revenue, SUM(quantity) As total_quantity_sold
FROM sales_toy
GROUP BY brand
ORDER BY total_revenue DESC
LIMIT 10;

-- Q3. Calculate the contribution percentage of each product category to the company's overall net revenue.

WITH category_rev AS (
    SELECT 
        product_category,
        SUM(net_revenue_inr) AS category_revenue
    FROM sales_toy
    GROUP BY product_category
)
SELECT 
    product_category,
    category_revenue,
    ROUND(
        (category_revenue / SUM(category_revenue) OVER ()) * 100, 
        2
    ) AS revenue_contribution_pct
FROM category_rev
ORDER BY revenue_contribution_pct DESC;

-- Q4. Find the top 5 product subcategories by net revenue within each product category.

WITH subcat_rev AS (
    SELECT 
        product_category,
        product_subcategory,
        SUM(net_revenue_inr) AS subcategory_revenue
    FROM sales_toy
    GROUP BY product_category,product_subcategory
    ),
ranked_subcats AS (
    SELECT 
        product_category,
        product_subcategory,
        subcategory_revenue,
        DENSE_RANK() OVER (
            PARTITION BY product_category 
            ORDER BY subcategory_revenue DESC
        ) AS rev_rank
    FROM subcat_rev
)
SELECT 
	product_category,
	product_subcategory,
    subcategory_revenue,
    rev_rank
FROM ranked_subcats
WHERE rev_rank <= 5
ORDER BY product_category, rev_rank;

-- Q5. Calculate the average transaction value (ATV) for each brand type.

SELECT 
    brand_type,
    ROUND(AVG(net_revenue_inr), 2) AS avg_transaction_value
FROM sales_toy
GROUP BY brand_type
ORDER BY avg_transaction_value DESC;

-- Q6. Identify the top 10 products based on total net revenue. Display product ID, brand, category, total quantity, and revenue.

SELECT 
    product_id,
    brand,
    product_category,
    SUM(quantity) AS total_quantity,
    SUM(net_revenue_inr) AS total_revenue
FROM sales_toy
GROUP BY product_id, brand, product_category
ORDER BY total_revenue DESC
LIMIT 10;

-- B. Time-based analysis
-- Q7. Calculate monthly net revenue and month-over-month revenue growth percentage.

WITH monthly_info AS (
    SELECT 
        YEAR(transaction_date) AS year_,
        DATE_FORMAT(transaction_date, '%Y-%m') AS year_month_,
        SUM(net_revenue_inr) AS monthly_revenue
    FROM sales_toy
    GROUP BY 
        YEAR(transaction_date),
        DATE_FORMAT(transaction_date, '%Y-%m')
),

mom_calc AS (
    SELECT 
        year_,
        year_month_,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY year_month_
        ) AS prev_month_revenue
    FROM monthly_info
)

SELECT 
    year_,
    year_month_,
    monthly_revenue,
    prev_month_revenue,
    ROUND(
        (
            (monthly_revenue - prev_month_revenue)
            / NULLIF(prev_month_revenue, 0)
        ) * 100,
        2
    ) AS mom_growth_percentage
FROM mom_calc
ORDER BY year_month_;

-- Q8. Compare quarterly revenue across different years and identify the best-performing quarter for each year.

WITH quarter_year AS (SELECT year, quarter, SUM(net_revenue_inr) AS revenue
FROM sales_toy
GROUP BY year, quarter),
quarter_rank AS (
SELECT year, quarter, SUM(revenue) OVER (PARTITION BY year ,quarter) AS revenue,
DENSE_RANK() OVER (PARTITION BY year
ORDER BY revenue DESC) AS best_quarter
FROM quarter_year
GROUP BY year, quarter)
SELECT year, quarter, revenue, best_quarter
FROM quarter_rank
GROUP BY year, quarter
HAVING best_quarter = 1;

-- Q9. Calculate the cumulative monthly net revenue for each year.

WITH monthly_revenue AS (SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS month_year, ROUND(SUM(net_revenue_inr),2) AS revenue
FROM sales_toy
GROUP BY month_year)
SELECT month_year, revenue, 
ROUND(SUM(revenue) OVER (ORDER BY month_year),2) AS cummulative_revenue
FROM monthly_revenue
GROUP BY month_year;

-- Q10. Identify the day of the week that generates the highest average daily revenue.

SELECT day_of_week, ROUND(AVG(net_revenue_inr),2) As avg_revenue
FROM sales_toy
GROUP BY day_of_week
ORDER BY avg_revenue DESC
LIMIT 1;

-- Q11. Calculate the percentage contribution of each month to its respective year's total revenue.

WITH monthly_sales AS (
    SELECT 
        year, 
        month, 
        month_name, 
        SUM(net_revenue_inr) AS total_revenue
    FROM sales_toy
    GROUP BY year, month, month_name
)
SELECT 
    year, 
    month, 
    month_name,
    total_revenue,
    ROUND(
        total_revenue * 100.0 / SUM(total_revenue) OVER (PARTITION BY year),2)  AS pct_contribution

FROM monthly_sales
ORDER BY year, month;

-- C. Customer and geographical analysis
-- Q12. Calculate net revenue generated by each customer age group and identify the highest-contributing age group

SELECT target_age_group, ROUND(SUM(net_revenue_inr),2)  AS net_revenue
FROM sales_toy
GROUP BY target_age_group
ORDER BY net_revenue DESC;

SELECT * FROM sales_toy;

-- Q13. Compare the average transaction value of new and returning customers.

SELECT customer_type, ROUND(SUM(net_revenue_inr)/COUNT(DISTINCT transaction_id),2) AS avg_transaction_value
FROM sales_toy
GROUP BY customer_type;

-- Q14. Find the top 5 cities by net revenue within each region.

WITH revenue_city AS (SELECT region, city, ROUND(SUM(net_revenue_inr),2) AS net_revenue,
DENSE_RANK () OVER (PARTITION BY region ORDER BY SUM(net_revenue_inr) DESC) AS rank_
FROM sales_toy
GROUP BY region, city)
SELECT region, city, net_revenue, rank_
FROM revenue_city
GROUP BY region, city
HAVING rank_ <= 5;

-- Q15. Calculate the return rate for each city tier and identify which tier has the highest return rate.

SELECT city_tier, (COUNT(CASE WHEN returned = 'yes' THEN transaction_id END) * 100/ COUNT(transaction_id)) AS return_rate
FROM sales_toy
GROUP BY city_tier
ORDER BY return_rate DESC;

-- Q16. Rank regions based on their net revenue using a window function.

WITH rank_region AS (SELECT region, ROUND(SUM(net_revenue_inr),2) AS net_revenue 
FROM sales_toy
GROUP BY region)
SELECT region, net_revenue,
DENSE_RANK() OVER (ORDER BY net_revenue DESC) AS rank_
FROM rank_region;

-- D. Discount, returns and customer satisfaction
-- Q17. Divide transactions into discount groups:
-- - No discount
-- - Low discount (0–10%)
-- - Medium discount (10–25%)
-- - High discount (above 25%)
-- Calculate total transactions, quantity sold, and net revenue for each group.

WITH row_with_groups AS (
    SELECT 
        transaction_id,
        quantity,
        net_revenue_inr,
        CASE 
            WHEN discount_percentage BETWEEN 0 AND 10 THEN 'Low discount (0–10%)'
            WHEN discount_percentage > 10 AND discount_percentage <= 25 THEN 'Medium discount (10–25%)'
            WHEN discount_percentage > 25 THEN 'High discount (above 25%)'
        END AS discount_group
    FROM sales_toy
)
SELECT 
    discount_group,
    COUNT(DISTINCT transaction_id) AS total_transaction,
    SUM(quantity) AS total_quantity,
    SUM(net_revenue_inr) AS net_revenue
FROM row_with_groups
WHERE discount_group IS NOT NULL -- handles any edge cases like negative or null discounts
GROUP BY discount_group
ORDER BY net_revenue DESC;

-- Q18. Calculate the return rate for each brand and rank brands from highest to lowest return rate.

SELECT brand, (COUNT(CASE WHEN returned = 'yes' THEN transaction_id END) * 100.0 / COUNT(transaction_id)) AS return_rate,
DENSE_RANK() OVER (ORDER BY (COUNT(CASE WHEN returned = 'yes' THEN transaction_id END) * 100.0 / COUNT(transaction_id)) DESC) AS rank_
FROM sales_toy
GROUP BY brand;

-- Q19. Find brands with an average customer rating below the overall average rating. Also display their total revenue and return rate.

SELECT brand, 
ROUND(AVG(customer_rating),2) AS avg_customer_rating, 
ROUND(SUM(net_revenue_inr),2) AS total_revenue, 
(COUNT(CASE WHEN returned = 'yes' THEN transaction_id END) * 100.0 / (COUNT(transaction_id) )) AS return_rate
FROM sales_toy
GROUP BY brand
HAVING avg_customer_rating < (SELECT AVG(customer_rating) FROM sales_toy);

-- Q20. Identify products that have both:
-- - Above-average discount percentage.
-- - Below-average customer rating.

SELECT product_id, brand,product_category,discount_percentage, customer_rating 
FROM sales_toy
HAVING discount_percentage > (SELECT AVG(discount_percentage) FROM sales_toy) 
AND customer_rating < (SELECT AVG(customer_rating) FROM sales_toy);


-- Q21. Monthly revenue performance

-- Using a CTE:
-- - Calculate monthly net revenue for each year.

SELECT year, DATE_FORMAT(transaction_date, '%Y-%m') AS month_year, ROUND(SUM(net_revenue_inr),2) AS monthly_revenue
FROM sales_toy
GROUP BY year, month_year
ORDER BY month_year;

-- - Calculate the previous month's revenue.

WITH month_revenue AS (SELECT year, DATE_FORMAT(transaction_date, '%Y-%m') AS month_year, ROUND(SUM(net_revenue_inr),2) AS monthly_revenue
FROM sales_toy
GROUP BY year, month_year
ORDER BY month_year)
SELECT year, month_year,monthly_revenue,
LAG(monthly_revenue) OVER (PARTITION BY year 
ORDER BY month_year)  AS prev_month_revenue
FROM month_revenue;

-- - Calculate month-over-month growth percentage.

WITH month_revenue AS (SELECT year, DATE_FORMAT(transaction_date, '%Y-%m') AS month_year, ROUND(SUM(net_revenue_inr),2) AS monthly_revenue
FROM sales_toy
GROUP BY year, month_year
ORDER BY month_year), 
prev_month_rev AS (SELECT year, month_year,monthly_revenue,
LAG(monthly_revenue) OVER (PARTITION BY year 
ORDER BY month_year)  AS prev_month_revenue
FROM month_revenue)
SELECT year, month_year,monthly_revenue, prev_month_revenue,
ROUND(((monthly_revenue - prev_month_revenue) * 100/ (prev_month_revenue)),2) AS mom_growth_pct
FROM prev_month_rev
GROUP BY year, month_year
ORDER BY month_year;

-- - Identify months where revenue declined compared to the previous month.

WITH month_revenue AS (SELECT year, DATE_FORMAT(transaction_date, '%Y-%m') AS month_year,month_name, ROUND(SUM(net_revenue_inr),2) AS monthly_revenue
FROM sales_toy
GROUP BY year, month_year,month_name
ORDER BY month_year), 
prev_month_rev AS (SELECT year, month_year,month_name,monthly_revenue,
LAG(monthly_revenue) OVER (PARTITION BY year 
ORDER BY month_year)  AS prev_month_revenue
FROM month_revenue)
SELECT year, month_year,month_name AS month_name,monthly_revenue, prev_month_revenue,
ROUND(((monthly_revenue - prev_month_revenue) * 100/ (prev_month_revenue)),2) AS mom_growth_pct
FROM prev_month_rev
GROUP BY year, month_year,month_name
HAVING mom_growth_pct < 0
ORDER BY month_year
;

-- Q22. High-performing brands

-- Create a CTE that calculates total net revenue for every brand.

WITH brand_revenue AS (SELECT brand, net_revenue_inr
FROM sales_toy)
SELECT brand, ROUND(SUM(net_revenue_inr),2) AS net_revenue
FROM brand_revenue
GROUP BY brand;

-- Using the result, identify brands whose revenue is greater than the average revenue across all brands.


WITH brand_revenue AS (SELECT brand, net_revenue_inr
FROM sales_toy)
SELECT brand, ROUND(SUM(net_revenue_inr),2) AS net_revenue
FROM brand_revenue
GROUP BY brand
HAVING net_revenue > (SELECT AVG(net_revenue_inr) FROM brand_revenue);

-- Display brand, total revenue, and percentage contribution to overall revenue.

WITH brand_revenue AS (SELECT brand, net_revenue_inr
FROM sales_toy)
SELECT brand, ROUND(SUM(net_revenue_inr),2) AS net_revenue, 
ROUND((SUM(net_revenue_inr) * 100)/(SELECT SUM(net_revenue_inr) FROM brand_revenue),2) AS pct_contribution
FROM brand_revenue
GROUP BY brand;

-- Q23. Customer segmentation

-- Using a CTE, calculate the following for each customer type:
-- - Total transactions.
-- - Total net revenue.
-- - Average transaction value.
-- - Average customer rating.
-- - Return rate.
-- Identify the customer type generating the highest average transaction value.

WITH customer_info AS (SELECT customer_type, transaction_id, 
net_revenue_inr, returned, customer_rating
FROM sales_toy)
SELECT customer_type, COUNT(DISTINCT transaction_id) AS total_transaction, 
SUM(net_revenue_inr) AS total_net_revenue, (SUM(net_revenue_inr)/COUNT(DISTINCT transaction_id)) AS avg_transaction_value,AVG(customer_rating) AS avg_customer_rating, 
(COUNT(CASE WHEN returned = 'yes' THEN transaction_id END) * 100.0/( COUNT(DISTINCT transaction_id))) AS return_rate
FROM customer_info
GROUP BY customer_type
ORDER BY avg_transaction_value DESC; 

-- Q24. Discount effectiveness

-- Create a CTE to divide transactions into four discount categories:

-- - Low discount (0–10%).
-- - Medium discount (10–25%).
-- - High discount (above 25%).
-- Calculate the revenue contribution, average transaction value, and return rate for each category.

WITH revenue_contribution AS (SELECT net_revenue_inr, discount_percentage, transaction_id, returned, 
CASE 
	WHEN discount_percentage >= 0 AND discount_percentage <= 10 THEN 'Low discount (0–10%)'
	WHEN discount_percentage > 10 AND discount_percentage <= 25 THEN 'Medium discount (10–25%)'
	WHEN discount_percentage > 25 THEN 'High discount (above 25%)'
END AS discount_group    
FROM sales_toy)
SELECT discount_group, ROUND((SUM(net_revenue_inr) * 100)/ (SELECT SUM(net_revenue_inr) FROM revenue_contribution),2) AS revenue_contribution,
(SUM(net_revenue_inr)/ COUNT(DISTINCT transaction_id)) AS avg_transaction_value , 
ROUND((COUNT(CASE WHEN returned = 'yes' THEN transaction_id END) * 100 / COUNT(DISTINCT transaction_id)),2) AS return_rate
FROM revenue_contribution
GROUP BY discount_group;


-- Q25. Underperforming products

-- Using multiple CTEs:
-- 1. Calculate total net revenue for each product.
-- 2. Calculate average product revenue across all products.
-- 3. Identify products generating less than 50% of the average product revenue.
-- Display product ID, brand, category, revenue, and difference from average revenue.

-- B. LAG() and LEAD() analysis (Q26–Q30)
-- Q26. Month-over-month revenue comparison

-- Calculate monthly revenue and use LAG() to retrieve the previous month's revenue.

-- Calculate the absolute and percentage change in revenue.

WITH month_rev AS (SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS year_month_, ROUND(SUM(net_revenue_inr),2) AS monthly_revenue
FROM sales_toy
GROUP BY year_month_), 
prev_month_rev AS (
SELECT year_month_, monthly_revenue,
LAG(monthly_revenue) OVER (ORDER BY year_month_) AS prev_month_revenue
FROM month_rev
GROUP BY  year_month_)
SELECT year_month_, monthly_revenue, prev_month_revenue, ROUND((monthly_revenue - prev_month_revenue),2) AS absolute_revenue_change, 
ROUND(((monthly_revenue - prev_month_revenue) * 100)/(prev_month_revenue),2) AS prev_rev_change
FROM prev_month_rev
GROUP BY  year_month_;

-- Q27. Quarterly revenue growth

-- Calculate quarterly revenue for each year.

-- Use LAG() to compare each quarter with the previous quarter and calculate quarterly growth percentage.

-- Make sure the comparison is chronological across year boundaries.

WITH quarter_rev AS (
SELECT year, quarter, ROUND(SUM(net_revenue_inr),2) AS quarterly_revenue
FROM sales_toy
GROUP BY year, quarter),
prev_quarter_rev AS (
SELECT year, quarter, quarterly_revenue,
LAG(quarterly_revenue) OVER (PARTITION BY year 
ORDER BY quarter) AS prev_quarter_revenue
FROM quarter_rev)
SELECT year, quarter, quarterly_revenue,
prev_quarter_revenue, ROUND(((quarterly_revenue - prev_quarter_revenue) * 100) / (prev_quarter_revenue),2) AS rev_quarter_growth_pct
FROM prev_quarter_rev
GROUP BY year, quarter
ORDER BY year, quarter;

-- Q28. Brand revenue movement

-- Calculate monthly revenue for each brand.

-- Use LAG() to identify:
-- - Previous month's brand revenue.
-- - Current month's brand revenue.
-- - Absolute revenue change.
-- - Percentage revenue change.
-- Identify brands experiencing the largest revenue decline.

WITH monthly_rev AS 
(SELECT brand, DATE_FORMAT(transaction_date, '%Y-%m') AS date_info, 
ROUND(SUM(net_revenue_inr),2) AS monthly_revenue
FROM sales_toy
GROUP BY brand, date_info),
prev_month_rev AS (
SELECT brand, date_info, monthly_revenue,
LAG(monthly_revenue) OVER (PARTITION BY brand ORDER BY date_info) AS prev_month_revenue
FROM monthly_rev)
SELECT brand, date_info, monthly_revenue, prev_month_revenue, ROUND((monthly_revenue -  prev_month_revenue),2) AS absolute_rev_change,
ROUND((monthly_revenue -  prev_month_revenue) * 100 / (prev_month_revenue),2) AS pct_change
FROM prev_month_rev
GROUP BY  brand, date_info
ORDER BY date_info;

-- Q29. Customer rating changes

-- Calculate average monthly customer ratings for each product category.

-- Use LAG() to compare the current month's rating with the previous month's rating.

-- Identify categories experiencing the greatest decline in customer satisfaction.

WITH monthly_rating AS (SELECT product_category, DATE_FORMAT(transaction_date, '%Y-%m') AS year_month_,ROUND(AVG(customer_rating),2) AS avg_monthly_rating
FROM sales_toy
GROUP BY product_category, year_month_),
prev_month_rating AS (
SELECT product_category, year_month_, avg_monthly_rating,
LAG(avg_monthly_rating) OVER (PARTITION BY product_category
ORDER BY year_month_) AS prev_month_avg_rating
FROM monthly_rating
GROUP BY product_category, year_month_), 
rating_decrease AS 
(SELECT product_category, year_month_, avg_monthly_rating, prev_month_avg_rating,
ROUND((avg_monthly_rating - prev_month_avg_rating) * 100/(prev_month_avg_rating)) AS satisfaction_change
FROM prev_month_rating
GROUP BY product_category, year_month_
HAVING satisfaction_change < 0
ORDER BY year_month_, satisfaction_change ASC)
SELECT product_category, year_month_, avg_monthly_rating, prev_month_avg_rating, satisfaction_change
FROM rating_decrease
GROUP BY product_category, year_month_
HAVING satisfaction_change < 0
ORDER BY year_month_, satisfaction_change ASC;

-- Note: If a product has multiple transactions on the same date, use transaction_id as a secondary ordering column.

-- C. RANK(), DENSE_RANK() and ROW_NUMBER() (Q31–Q35)
-- Q31. Brand ranking within each category

-- Calculate total net revenue for every brand within each product category.

-- Use DENSE_RANK() to rank brands within their respective categories.

-- Display the top 3 brands in each category.

WITH brand_revenue AS (SELECT product_category,brand,ROUND(SUM(net_revenue_inr),2) AS total_revenue
FROM sales_toy
GROUP BY product_category,brand),
brand_ranking AS (
SELECT product_category,brand, total_revenue,
DENSE_RANK() OVER (PARTITION BY product_category
ORDER BY total_revenue DESC) AS rank_
FROM brand_revenue)
SELECT product_category,brand, total_revenue,
rank_
FROM brand_ranking
GROUP BY product_category,brand
HAVING rank_ <= 3;

-- Q32. City performance ranking

-- Calculate total revenue generated by each city.

-- Use RANK() to rank cities within each region based on revenue.

-- Identify the top 3 cities in each region.

WITH region_city AS (SELECT region, city, ROUND(SUM(net_revenue_inr),2) AS revenue_generated
FROM sales_toy
GROUP BY region, city) ,
region_city_rank AS
(SELECT region, city, revenue_generated, DENSE_RANK() OVER (PARTITION BY region
ORDER BY revenue_generated DESC) AS revenue_rank
FROM region_city
GROUP BY region, city)
SELECT region, city, revenue_generated, revenue_rank
FROM region_city_rank
GROUP BY region, city
HAVING revenue_rank <= 3;

-- Q33. Product ranking across different years

-- Calculate annual net revenue for each product.

-- Use ROW_NUMBER() to identify the highest-revenue product in each year.

-- Also use RANK() to identify all products sharing the first position.

WITH annual_product_revenue AS (
    SELECT 
        EXTRACT(YEAR FROM transaction_date) AS sale_year,
        product_id,
        SUM(net_revenue_inr) AS net_revenue
    FROM sales_toy
    GROUP BY 
        EXTRACT(YEAR FROM transaction_date), 
        product_id
),
ranked_products AS (
    SELECT 
        sale_year,
        product_id,
        net_revenue,
        RANK() OVER (
            PARTITION BY sale_year 
            ORDER BY net_revenue DESC
        ) AS product_rank
    FROM annual_product_revenue
)
SELECT 
    sale_year,
    product_id,
    net_revenue,
    product_rank
FROM ranked_products
WHERE product_rank = 1
ORDER BY sale_year ASC;


-- Q34. Sales channel ranking

-- Calculate the revenue generated by each sales channel within every region.

-- Use DENSE_RANK() to rank sales channels in each region.

-- Identify the best-performing channel for each region.

WITH region_revenue AS (SELECT region, sales_channel, 
ROUND(SUM(net_revenue_inr),2) AS net_revenue
FROM sales_toy
GROUP BY region, sales_channel), 
region_revenue_rank AS
(SELECT region, sales_channel, net_revenue, DENSE_RANK() OVER (PARTITION BY region
ORDER BY net_revenue DESC) As rank_
FROM region_revenue)
SELECT region, sales_channel, net_revenue, rank_
FROM region_revenue_rank
GROUP BY region, sales_channel
HAVING rank_ = 1;

-- Q35. Customer age group ranking

-- Calculate total revenue and average transaction value for every age group.

-- Rank age groups separately based on:
-- - Total net revenue.
-- - Average transaction value.
-- - Total quantity sold.
-- Identify whether the highest-revenue age group is also the highest in average transaction value.

WITH  info AS (SELECT target_age_group, net_revenue_inr, transaction_id, quantity
FROM sales_toy)
SELECT target_age_group, ROUND((SUM(net_revenue_inr)),2) AS total_revenue, ROUND((SUM(net_revenue_inr)/COUNT(transaction_id)),2) AS avg_transaction_value, 
SUM(quantity) AS total_quantity
FROM info
GROUP BY  target_age_group
ORDER BY total_revenue DESC, avg_transaction_value DESC;

-- D. Cumulative and rolling analysis (Q36–Q40)
-- Q36. Cumulative monthly revenue

-- Calculate monthly revenue and use:

-- SUM() OVER()

-- Calculate cumulative revenue for each year, resetting the cumulative total when a new year starts.

WITH month_rev AS (SELECT DATE_FORMAT(transaction_date, '%Y-%m') As year_month_,year, ROUND(SUM(net_revenue_inr),2) As total_monthly_revenue
FROM sales_toy
GROUP BY year,year_month_
ORDER BY year_month_)
SELECT  year, year_month_, total_monthly_revenue,
SUM(total_monthly_revenue) OVER (PARTITION BY year ORDER BY year_month_) AS cummulative_monthly_revenue
FROM month_rev
GROUP BY year, year_month_ ,total_monthly_revenue;


### MARKETPLACE PERFORMANCE ###

# Creating the orders table to import the data into it
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NULL
);

# Checking all the data was imported well
SELECT COUNT(*)
FROM olist_orders_dataset;

SELECT *
FROM olist_orders_dataset
LIMIT 10;

# Creating the order_items table to import the data into it
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

SELECT COUNT(*)
FROM olist_order_items_dataset;

SELECT *
FROM olist_order_items_dataset
LIMIT 10;

# How has marketplace activity changed over time?
SELECT
    DATE_FORMAT(ood.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT ood.order_id) AS completed_orders,
    COUNT(ooid.order_item_id) AS items_sold,
    SUM(ooid.price) AS gmv,
    SUM(ooid.price) / COUNT(DISTINCT ood.order_id) AS aov,
    COUNT(ooid.order_item_id) / COUNT(DISTINCT ood.order_id) AS items_per_order 
FROM olist_orders_dataset ood 
JOIN olist_order_items_dataset ooid 
    ON ood.order_id = ooid.order_id 
WHERE ood.order_status = 'delivered'
GROUP BY month
ORDER BY month;

# Creating the products table to import the data into it
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

SELECT COUNT(*)
FROM olist_products_dataset;

SELECT *
FROM olist_products_dataset
LIMIT 10;

# Creating the translation table to import the data into it
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

SELECT COUNT(*)
FROM product_category_name_translation;

SELECT *
FROM product_category_name_translation
LIMIT 10;

# Which product categories drive the most marketplace activity?
SELECT 
	SUM(ooid.price) AS gmv,
	COUNT(ooid.order_item_id) AS items_sold,
	pcnt.product_category_name_english AS category_name,
	AVG(ooid.price) AS avg_item_price
FROM olist_order_items_dataset ooid 
LEFT JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id 
LEFT JOIN product_category_name_translation pcnt ON opd.product_category_name  = pcnt.product_category_name 
LEFT JOIN olist_orders_dataset ood ON ood.order_id  = ooid.order_id 
WHERE ood.order_status = 'delivered'
GROUP BY pcnt.product_category_name_english
ORDER BY items_sold DESC 
LIMIT 5;

# Creating the customers table to import the data into it
CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

SELECT COUNT(*)
FROM olist_customers_dataset;

SELECT *
FROM olist_customers_dataset
LIMIT 10;

# Which geographic markets generate the most marketplace activity?
SELECT 
	ocd.customer_state AS state,
	SUM(ooid.price) AS gmv,
	COUNT(ooid.order_item_id) AS items_sold,
	COUNT(DISTINCT ood.order_id) AS completed_orders,
	SUM(ooid.price) / COUNT(DISTINCT ood.order_id) AS aov
	FROM olist_orders_dataset ood 
	LEFT JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id 
	LEFT JOIN olist_order_items_dataset ooid ON ood.order_id = ooid.order_id 
	WHERE ood.order_status = 'delivered'
	GROUP BY ocd.customer_state
	ORDER BY gmv DESC 
	LIMIT 10;

# Which sellers contribute the most to marketplace activity?
SELECT
	ooid.seller_id,
	SUM(ooid.price) AS gmv,
	COUNT(ooid.order_item_id) AS items_sold,
	AVG(ooid.price) AS avg_item_price
FROM olist_orders_dataset ood
LEFT JOIN olist_order_items_dataset ooid ON ood.order_id = ooid.order_id 
WHERE ood.order_status = 'delivered'
GROUP BY ooid.seller_id 
ORDER BY items_sold DESC
LIMIT 10;

# Are high-GMV sellers associated with higher-priced product categories?
SELECT
	ooid.seller_id,
	pcnt.product_category_name_english AS category_name,
	SUM(ooid.price) AS gmv,
	COUNT(ooid.order_item_id) AS items_sold,
	AVG(ooid.price) AS avg_item_price
FROM olist_orders_dataset ood
LEFT JOIN olist_order_items_dataset ooid ON ood.order_id  = ooid.order_id 
LEFT JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id 
LEFT JOIN product_category_name_translation pcnt ON pcnt.product_category_name = opd.product_category_name 
WHERE ood.order_status = 'delivered'
GROUP BY ooid.seller_id, pcnt.product_category_name_english
ORDER BY items_sold DESC;

# Among customers who made a repeat purchase, how long did it take them to make their second purchase?
# Customers with more than one order
SELECT 
	ocd.customer_unique_id,
	ood.order_id,
	ROW_NUMBER() OVER (
    	PARTITION BY ocd.customer_unique_id
    	ORDER BY ood.order_purchase_timestamp
	) AS purchase_number
FROM olist_orders_dataset ood 
LEFT JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id
WHERE ood.order_status NOT IN ('canceled', 'unavailable')
ORDER BY purchase_number DESC;

# Max number of orders is 16
# Creating a view of purchase history for further investigation
CREATE VIEW purchase_history AS
SELECT 
    ocd.customer_unique_id,
    ROW_NUMBER() OVER (
        PARTITION BY ocd.customer_unique_id
        ORDER BY ood.order_purchase_timestamp
    ) AS purchase_number,
    ood.order_purchase_timestamp AS purchase_date,
    LAG(ood.order_purchase_timestamp) OVER (
        PARTITION BY ocd.customer_unique_id
        ORDER BY ood.order_purchase_timestamp
    ) AS previous_purchase_date
FROM olist_orders_dataset ood
LEFT JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id
WHERE ood.order_status NOT IN ('canceled', 'unavailable');

# Looking at the day difference in days between the first and second order of a customer
SELECT
    customer_unique_id,
    purchase_number,
    purchase_date,
    previous_purchase_date,
    DATEDIFF(purchase_date, previous_purchase_date) AS days_since_previous_purchase
FROM purchase_history
WHERE purchase_number = 2;

# Statistics summary
SELECT 
	COUNT(customer_unique_id),
	MIN(DATEDIFF(purchase_date, previous_purchase_date)),
	MAX(DATEDIFF(purchase_date, previous_purchase_date)),
	AVG(DATEDIFF(purchase_date, previous_purchase_date))
FROM purchase_history
WHERE purchase_number = 2;

# Out of all recurring customers how many placed their second order in the same day
SELECT 
	COUNT(customer_unique_id)
FROM purchase_history
WHERE purchase_number = 2 AND DATEDIFF(purchase_date, previous_purchase_date) = 0;

# How many minutes between orders of the same day?
SELECT
    customer_unique_id,
    previous_purchase_date,
    purchase_date,
    TIMESTAMPDIFF(
        MINUTE,
        previous_purchase_date,
        purchase_date
    ) AS minutes_between_purchases
FROM purchase_history
WHERE purchase_number = 2
  AND DATEDIFF(purchase_date, previous_purchase_date) = 0
ORDER BY minutes_between_purchases DESC;

# Dividing the second orders into 6 categories
SELECT
	SUM(
    	CASE
       		WHEN TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) = 0
        	THEN 1 ELSE 0
    	END
	) AS under_1_minute,
	
    SUM(
        CASE
            WHEN TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) BETWEEN 1 AND 10
            THEN 1 ELSE 0
        END
    ) AS within_10_minutes,

    SUM(
        CASE
            WHEN TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) > 10
             AND TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) <= 30
            THEN 1 ELSE 0
        END
    ) AS between_10_and_30_minutes,

    SUM(
        CASE
            WHEN TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) > 30
             AND TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) <= 60
            THEN 1 ELSE 0
        END
    ) AS between_30_and_60_minutes,

    SUM(
        CASE
            WHEN TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) > 60
             AND TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) <= 360
            THEN 1 ELSE 0
        END
    ) AS between_1_and_6_hours,

    SUM(
        CASE
            WHEN TIMESTAMPDIFF(MINUTE, previous_purchase_date, purchase_date) > 360
            THEN 1 ELSE 0
        END
    ) AS over_6_hours

FROM purchase_history

WHERE purchase_number = 2
  AND DATEDIFF(purchase_date, previous_purchase_date) = 0;

# Conclusion: Out of all the customers that placed more than one order a day, 778 did so within 10 minutes from the first order.

# Looking into the median and some of the percentiles of the repeating customers
CREATE VIEW second_purchases AS
SELECT
    customer_unique_id,
    previous_purchase_date,
    purchase_date,
    DATEDIFF(purchase_date, previous_purchase_date) AS days_to_second_purchase,
    TIMESTAMPDIFF(
        MINUTE,
        previous_purchase_date,
        purchase_date
    ) AS minutes_to_second_purchase
FROM purchase_history
WHERE purchase_number = 2;

# Creating a CTE of the ranking
WITH ranked AS (
    SELECT
        days_to_second_purchase,
        ROW_NUMBER() OVER (
            ORDER BY days_to_second_purchase
        ) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM second_purchases
)

SELECT
    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.25)
        THEN days_to_second_purchase
    END) AS p25,

    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.50)
        THEN days_to_second_purchase
    END) AS median,

    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.75)
        THEN days_to_second_purchase
    END) AS p75,

    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.90)
        THEN days_to_second_purchase
    END) AS p90
FROM ranked;

# Without the customers that made the second order within 10 minutes
WITH ranked AS (
    SELECT
        days_to_second_purchase,
        ROW_NUMBER() OVER (
            ORDER BY days_to_second_purchase
        ) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM second_purchases
WHERE minutes_to_second_purchase > 10
)

SELECT
    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.25)
        THEN days_to_second_purchase
    END) AS p25,

    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.50)
        THEN days_to_second_purchase
    END) AS median,

    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.75)
        THEN days_to_second_purchase
    END) AS p75,

    MIN(CASE
        WHEN row_num >= CEIL(total_rows * 0.90)
        THEN days_to_second_purchase
    END) AS p90,
    COUNT(*) AS customers,
	AVG(days_to_second_purchase) AS avg_days
FROM ranked;

# Our cutoff for the customers who made more than one purchase will be of the customers that made their first purchase at
# least 180 days before the last purchase date in the data

# Finding out the last purchase date
SELECT MAX(ood.order_purchase_timestamp) AS last_purchase_date
FROM olist_orders_dataset ood;

# Calculating 180 days before the last purchase
SELECT
    MAX(order_purchase_timestamp) AS last_purchase_date,
    DATE_SUB(MAX(order_purchase_timestamp), INTERVAL 180 DAY) AS cutoff_date
FROM olist_orders_dataset;

# Making sure if the last couple of months have enough orders for the actual cutoff
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(*) AS orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp >= '2018-08-01'
GROUP BY month
ORDER BY month;

# In the months of September and October there were only 20 orders in total.
# We will set the last purchase date to be August 31st and our cutoff will be 180 days before
SELECT DATE_SUB('2018-08-31', INTERVAL 180 DAY) AS cutoff_date;

# Looking at all the eligible customers, that is, the customers that made their first purchase before the cutoff
SELECT
    COUNT(*) AS eligible_customers
FROM purchase_history
WHERE purchase_number = 1
    AND purchase_date <= '2018-03-04 23:59:59';

# Creating a CTE of the first purchases that were made before the cutoff date
WITH first_purchases AS (
    SELECT
        customer_unique_id,
        purchase_date AS first_purchase_date
    FROM purchase_history
    WHERE purchase_number = 1
      AND purchase_date <= '2018-03-04 23:59:59'
)

# Counting the number of customers that made a second order within more than 10 minutes of the first order
# and the first order before the cutoff date
SELECT
    COUNT(DISTINCT fp.customer_unique_id) AS repeat_customers
FROM first_purchases fp
JOIN purchase_history ph
    ON fp.customer_unique_id = ph.customer_unique_id
WHERE ph.purchase_date > DATE_ADD(fp.first_purchase_date, INTERVAL 10 MINUTE)
  AND ph.purchase_date <= DATE_ADD(fp.first_purchase_date, INTERVAL 180 DAY);

# How do customers pay for their purchases, and how commonly are installment payments used?
# Creating the payments table to import the data into it
CREATE TABLE olist_order_payments_dataset (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

SELECT COUNT(*)
FROM olist_order_payments_dataset;

SELECT *
FROM olist_order_payments_dataset
LIMIT 10;

# How do customers pay for their orders?
SELECT 
	oopd.payment_type,
	COUNT(DISTINCT oopd.order_id) AS number_of_orders,
    COUNT(DISTINCT oopd.order_id) / (
        SELECT COUNT(DISTINCT order_id)
        FROM olist_order_payments_dataset oopd 
    ) * 100 AS percentage
FROM olist_order_payments_dataset oopd 
GROUP BY oopd.payment_type
ORDER BY number_of_orders DESC;

# How many installments?
SELECT 
	oopd.payment_installments,
	COUNT(DISTINCT oopd.order_id) AS number_of_orders,
	COUNT(DISTINCT oopd.order_id) / (
		SELECT COUNT(DISTINCT order_id)
		FROM olist_order_payments_dataset
	) * 100 AS percentage
FROM olist_order_payments_dataset oopd 
GROUP BY oopd.payment_installments 
ORDER BY number_of_orders DESC;

# Which orders have more than one value of payment installments?
SELECT
    order_id,
    COUNT(DISTINCT payment_installments)
FROM olist_order_payments_dataset
GROUP BY order_id
HAVING COUNT(DISTINCT payment_installments) > 1;

# What percentage of orders used installment payments?
SELECT 
	COUNT(DISTINCT oopd.order_id) AS number_of_orders,
	COUNT(DISTINCT oopd.order_id) / (
		SELECT COUNT(DISTINCT order_id)
		FROM olist_order_payments_dataset
	) * 100 AS percentage
FROM olist_order_payments_dataset oopd 
WHERE oopd.payment_installments > 1;

# -----------------------------------------------------------------------------------------

### DELIVERY & LOGISTICS ###

# How well are deliveries performing?
CREATE VIEW delivery_performance AS
SELECT 
	order_id,
	order_delivered_customer_date AS customer_delivery,
	order_estimated_delivery_date AS estimated_delivery,
	order_purchase_timestamp AS order_date,
	DATEDIFF(
    order_estimated_delivery_date,
    order_delivered_customer_date
	) AS date_differences,
	CASE 
		WHEN (DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) > 0)
		THEN 'Early'
		WHEN (DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) = 0)
		THEN 'On_time'
		ELSE 'Late'
	END AS delivery_time,
CASE 
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 1 AND 7
    THEN '1-7 days early'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 8 AND 14
    THEN '8-14 days early'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 15 AND 30
    THEN '15-30 days early'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) >= 31
    THEN '30+ days early'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN -7 AND -1
    THEN '1-7 days late'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN -14 AND -8
    THEN '8-14 days late'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) BETWEEN -30 AND -15
    THEN '15-30 days late'
    WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) <= -31
    THEN '30+ days late'
    ELSE 'On_time'
END AS delivery_difference_group
FROM olist_orders_dataset ood 
WHERE ood.order_status = 'delivered' AND ood.order_delivered_customer_date IS NOT NULL
ORDER BY date_differences;

# How many deliveries are in each category?
SELECT
    delivery_time,
    COUNT(*) AS orders,
    COUNT(*) / (
        SELECT COUNT(*)
        FROM delivery_performance
    ) * 100 AS percentage
FROM delivery_performance
GROUP BY delivery_time;

# Among early deliveries, how many days early do orders typically arrive, 
# and among late deliveries, how many days late do they typically arrive?
SELECT 
	dp.delivery_time,
	AVG(dp.date_differences) AS average_difference
FROM delivery_performance dp 
WHERE dp.delivery_time IN ('Early', 'Late')
GROUP BY dp.delivery_time;

# Counting the number of orders in each delivery group
SELECT 
	delivery_difference_group,
	COUNT(*) AS orders,
	COUNT(*) / (
    SELECT COUNT(*)
    FROM delivery_performance
) * 100 AS percentage
FROM delivery_performance dp 
GROUP BY dp.delivery_difference_group 
ORDER BY COUNT(*);

# Where are delivery problems concentrated geographically?
SELECT 
    ocd.customer_state,
    COUNT(*) AS total_deliveries,
    SUM(CASE 
            WHEN dp.delivery_time = 'Late' THEN 1
            ELSE 0
        END) AS late_deliveries,
    SUM(CASE 
        	WHEN dp.delivery_time = 'Late' THEN 1
        	ELSE 0
    	END) / COUNT(*) * 100 AS late_percentage,
    AVG(CASE
        WHEN dp.delivery_time = 'Late'
        THEN ABS(date_differences)
        ELSE NULL
    END) AS average_days_late
FROM delivery_performance dp
JOIN olist_orders_dataset ood ON dp.order_id = ood.order_id
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id
GROUP BY ocd.customer_state
ORDER BY late_percentage DESC;

# Does delivery performance vary across product categories?
# Checking how many multi-categories orders we have
CREATE VIEW order_categories AS (
SELECT 
	ooid.order_id,
	COUNT(DISTINCT opd.product_category_name) AS number_of_categories
FROM olist_order_items_dataset ooid 
LEFT JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id  
GROUP BY ooid.order_id 
);

SELECT 
	COUNT(*)
FROM order_categories oc;
# 98666 orders in total

SELECT 
	COUNT(*) 
FROM order_categories
WHERE number_of_categories > 1;
# 727 orders with more than 1 category (less than 1% of the total orders)
# Calculations regarding the delivery performance by product category will be performed only on orders that have products of 1 category.

# For single-category orders, how does delivery performance vary by product category?
SELECT 
	pcnt.product_category_name_english,
	COUNT(DISTINCT ooid.order_id) AS total_deliveries,
	COUNT(DISTINCT CASE 
            WHEN dp.delivery_time = 'Late' THEN ooid.order_id 
            ELSE NULL
        END) AS late_deliveries,
    COUNT(DISTINCT CASE
        	WHEN dp.delivery_time = 'Late' THEN ooid.order_id
        	ELSE NULL
    	END) / COUNT(DISTINCT ooid.order_id) * 100 AS late_percentage,
    AVG(CASE
        	WHEN dp.delivery_time = 'Late'
        	THEN ABS(date_differences)
        	ELSE NULL
    	END) AS average_days_late
FROM olist_products_dataset opd 
JOIN product_category_name_translation pcnt ON opd.product_category_name = pcnt.product_category_name 
LEFT JOIN olist_order_items_dataset ooid ON opd.product_id = ooid.product_id 
LEFT JOIN delivery_performance dp ON ooid.order_id = dp.order_id 
LEFT JOIN order_categories oc ON oc.order_id = ooid.order_id
WHERE number_of_categories = 1
GROUP BY pcnt.product_category_name_english 
ORDER BY late_percentage DESC;

# Creating the sellers table to import the data into it
CREATE TABLE olist_sellers_dataset (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10),
    PRIMARY KEY (seller_id)
);

SELECT COUNT(*)
FROM olist_sellers_dataset;

SELECT *
FROM olist_sellers_dataset
LIMIT 10;

# What factors are associated with freight/shipping cost?
CREATE VIEW freight_cost AS (
SELECT 
	opd.product_id,
	ooid.seller_id,
	pcnt.product_category_name_english,
	ooid.price,
	ooid.freight_value,
	opd.product_weight_g,
	(opd.product_length_cm * opd.product_height_cm * opd.product_width_cm) AS product_volume_cm3
FROM olist_products_dataset opd 
JOIN olist_order_items_dataset ooid ON opd.product_id = ooid.product_id
JOIN product_category_name_translation pcnt ON opd.product_category_name = pcnt.product_category_name
);

# Among orders with a positive shipping charge, is product weight associated with higher freight cost?
SELECT
    product_weight_g,
    freight_value
FROM freight_cost
WHERE product_weight_g IS NOT NULL
ORDER BY product_weight_g DESC;

# Calculating correlation
# Creating ranked weight and freight values for Spearman correlation
# Records with missing or zero weight/freight values are excluded
CREATE VIEW ranked_rows_weight AS 
SELECT
    product_weight_g,
    freight_value,
    weight_row,
    freight_row,
    AVG(weight_row) OVER (PARTITION BY product_weight_g) AS weight_rank,
	AVG(freight_row) OVER (PARTITION BY freight_value) AS freight_rank
FROM (
    SELECT
        product_weight_g,
        freight_value,
        ROW_NUMBER() OVER (ORDER BY product_weight_g) AS weight_row,
        ROW_NUMBER() OVER (ORDER BY freight_value) AS freight_row
    FROM freight_cost
    WHERE product_weight_g IS NOT NULL 
      AND product_weight_g > 0
      AND freight_value > 0
) AS row_numbers;

# Checking how many free shipping items there are
SELECT
    COUNT(*) AS free_shipping_items
FROM freight_cost
WHERE freight_value = 0;
# 381 free shipping items

SELECT
    COUNT(CASE WHEN freight_value = 0 THEN 1 END) * 100.0 / COUNT(*) 
        AS free_shipping_percentage
FROM freight_cost;
# 0.34317% of all the products are free shipping

SELECT
    COUNT(*) AS very_low_freight
FROM freight_cost
WHERE freight_value > 0
  AND freight_value <= 1;
# 140 have a freight value of 0.01-1 and will not be counted as free

# Spearman
SELECT
    (COUNT(*) * SUM(weight_rank * freight_rank) - SUM(weight_rank) * SUM(freight_rank)) /
    SQRT((COUNT(*) * SUM(weight_rank * weight_rank) - POWER(SUM(weight_rank), 2)) *
    (COUNT(*) * SUM(freight_rank * freight_rank) - POWER(SUM(freight_rank), 2))
    ) AS spearman_correlation
FROM ranked_rows_weight;
# 0.4512160581846764

# Pearson
SELECT
    (COUNT(*) * SUM(product_weight_g * freight_value) - SUM(product_weight_g) * SUM(freight_value)) /
    SQRT((COUNT(*) * SUM(product_weight_g * product_weight_g) - POWER(SUM(product_weight_g), 2)) *(
	COUNT(*) * SUM(freight_value * freight_value) - POWER(SUM(freight_value), 2))
    ) AS pearson_correlation
FROM ranked_rows_weight;
# 0.6127414696566842

# Among orders with a positive shipping charge, is product volume associated with higher freight cost?
SELECT
    product_volume_cm3,
    freight_value
FROM freight_cost
WHERE product_volume_cm3  IS NOT NULL
ORDER BY product_volume_cm3 DESC;

# Calculating correlation
# Creating a ranking view for the volume and freight values
CREATE VIEW ranked_rows_volume AS 
SELECT
    product_volume_cm3,
    freight_value,
    volume_row,
    freight_row,
    AVG(volume_row) OVER (PARTITION BY product_volume_cm3) AS volume_rank,
	AVG(freight_row) OVER (PARTITION BY freight_value) AS freight_rank
FROM (
    SELECT
        product_volume_cm3,
        freight_value,
        ROW_NUMBER() OVER (ORDER BY product_volume_cm3) AS volume_row,
        ROW_NUMBER() OVER (ORDER BY freight_value) AS freight_row
    FROM freight_cost
    WHERE product_volume_cm3 IS NOT NULL
      AND freight_value > 0
) AS row_numbers;

# Spearman
SELECT
    (COUNT(*) * SUM(volume_rank * freight_rank) - SUM(volume_rank) * SUM(freight_rank)) /
    SQRT((COUNT(*) * SUM(volume_rank * volume_rank) - POWER(SUM(volume_rank), 2)) *
    (COUNT(*) * SUM(freight_rank * freight_rank) - POWER(SUM(freight_rank), 2))
    ) AS spearman_correlation
FROM ranked_rows_volume;
# 0.3683504936994988

# Pearson
SELECT
    (COUNT(*) * SUM(product_volume_cm3 * freight_value) - SUM(product_volume_cm3) * SUM(freight_value)) /
    SQRT((COUNT(*) * SUM(product_volume_cm3 * product_volume_cm3) - POWER(SUM(product_volume_cm3), 2)) *(
	COUNT(*) * SUM(freight_value * freight_value) - POWER(SUM(freight_value), 2))
    ) AS pearson_correlation
FROM ranked_rows_volume;
# 0.5883659795650596

# Is shipping distance associated with freight cost?
# Creating the geolocation table to import the data into it
CREATE TABLE olist_geolocation_dataset (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(10,7),
    geolocation_lng DECIMAL(10,7),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);

SELECT COUNT(*)
FROM olist_geolocation_dataset;

SELECT *
FROM olist_geolocation_dataset
LIMIT 10;

# Checking how many unique zip codes there are in the geolocation table
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_codes
FROM olist_geolocation_dataset;

# Creating a view with one geographic coordinate to each zip code prefix
CREATE VIEW geolocation_by_zip AS
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude
FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;

# Creating a view with calculation of the approximate distances between customers and sellers
CREATE VIEW freight_distance AS
SELECT 
	ooid.order_id,
	ooid.order_item_id,
	ooid.seller_id,
	osd.seller_zip_code_prefix AS seller_zip,
	seller_geo.latitude AS seller_lat,
	seller_geo.longitude AS seller_lng,
	ocd.customer_zip_code_prefix AS customer_zip,
	customer_geo.latitude AS customer_lat,
	customer_geo.longitude AS customer_lng,
	6371 * 2 * ASIN(
    SQRT(
    	POWER(SIN(RADIANS(customer_geo.latitude - seller_geo.latitude) / 2), 2) +
        	  COS(RADIANS(seller_geo.latitude)) * COS(RADIANS(customer_geo.latitude)) *
        	  POWER(SIN(RADIANS(customer_geo.longitude - seller_geo.longitude) / 2), 2))) AS distance_km,
	ooid.freight_value
FROM olist_order_items_dataset ooid 
JOIN olist_sellers_dataset osd ON ooid.seller_id = osd.seller_id 
JOIN geolocation_by_zip seller_geo ON osd.seller_zip_code_prefix = seller_geo.geolocation_zip_code_prefix 
JOIN olist_orders_dataset ood ON ooid.order_id = ood.order_id
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id
JOIN geolocation_by_zip customer_geo ON ocd.customer_zip_code_prefix = customer_geo.geolocation_zip_code_prefix;

# Calculating correlation
# Creating a ranking view for the distance and freight values
CREATE VIEW ranked_rows_distance AS 
SELECT
    distance_km,
    freight_value,
    distance_row,
    freight_row,
    AVG(distance_row) OVER (PARTITION BY distance_km) AS distance_rank,
	AVG(freight_row) OVER (PARTITION BY freight_value) AS freight_rank
FROM (
    SELECT
        distance_km,
        freight_value,
        ROW_NUMBER() OVER (ORDER BY distance_km) AS distance_row,
        ROW_NUMBER() OVER (ORDER BY freight_value) AS freight_row
    FROM freight_distance fd 
    WHERE freight_value > 0
) AS row_numbers;

# Spearman
SELECT
    (COUNT(*) * SUM(distance_rank * freight_rank) - SUM(distance_rank) * SUM(freight_rank)) /
    SQRT((COUNT(*) * SUM(distance_rank * distance_rank) - POWER(SUM(distance_rank), 2)) *
    (COUNT(*) * SUM(freight_rank * freight_rank) - POWER(SUM(freight_rank), 2))
    ) AS spearman_correlation
FROM ranked_rows_distance;
# 0.6377185093500204

# Pearson
SELECT
    (COUNT(*) * SUM(distance_km * freight_value) - SUM(distance_km) * SUM(freight_value)) /
    SQRT((COUNT(*) * SUM(distance_km * distance_km) - POWER(SUM(distance_km), 2)) *(
	COUNT(*) * SUM(freight_value * freight_value) - POWER(SUM(freight_value), 2))
    ) AS pearson_correlation
FROM ranked_rows_distance;
# 0.3915718659733333

# -----------------------------------------------------------------------------------------

### CUSTOMER SATISFACTION ### 

# Creating the reviews table to import the data into it
CREATE TABLE olist_order_reviews_dataset (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

# Checking all the data was imported well
SELECT COUNT(*)
FROM olist_order_reviews_dataset;

SELECT *
FROM olist_order_reviews_dataset
LIMIT 10;

# Checking the number of duplicated order ids
SELECT 
	COUNT(order_id) AS total_order_id,
	COUNT(DISTINCT order_id) AS distinct_order_id,
	COUNT(order_id) - COUNT(DISTINCT order_id) AS number_of_duplicates
FROM olist_order_reviews_dataset oord;

SELECT 
	order_id,
    COUNT(*) AS number_of_reviews
FROM olist_order_reviews_dataset
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY number_of_reviews DESC;

SELECT 
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM olist_order_reviews_dataset 
WHERE order_id IN (
    SELECT order_id
    FROM olist_order_reviews_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id;

SELECT
    review_id,
    COUNT(*) AS number_of_rows
FROM olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY number_of_rows DESC;

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM olist_order_reviews_dataset
WHERE review_id IN (
    SELECT review_id
    FROM olist_order_reviews_dataset
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id;

# review_id is not unique in the source data; in some cases identical review records are associated with different orders.
# Therefore, review_id was not used as the unit of analysis.

# For orders associated with multiple reviews, the mean review score was used to obtain a single satisfaction measure per order.

# Creating a reviews view with the order_id and the average review score
CREATE VIEW reviews AS
SELECT 
	order_id,
	AVG(review_score) AS avg_review_score
FROM olist_order_reviews_dataset oord 
GROUP BY order_id;

SELECT 
	r.order_id,
	r.avg_review_score,
	dp.delivery_time,
	dp.date_differences 
FROM reviews r 
JOIN delivery_performance dp ON r.order_id = dp.order_id;

# Is there a connection between the delivery performance and the review score?
SELECT 
	dp.delivery_time,
	COUNT(*) AS number_of_orders,
	AVG(r.avg_review_score) AS avg_review_score
FROM reviews r 
JOIN delivery_performance dp ON r.order_id = dp.order_id 
GROUP BY dp.delivery_time;

SELECT 
	dp.delivery_difference_group,
	COUNT(*) AS number_of_orders,
	AVG(r.avg_review_score) AS avg_review_score
FROM reviews r 
JOIN delivery_performance dp ON r.order_id = dp.order_id 
WHERE dp.delivery_difference_group LIKE '%late%'
GROUP BY dp.delivery_difference_group; 


# Do repeat customers report different satisfaction levels between their initial and repeat orders?
CREATE VIEW first_orders AS 
    SELECT
        ocd.customer_unique_id,
        MIN(ood.order_purchase_timestamp) AS first_order_time
    FROM olist_customers_dataset ocd 
    JOIN olist_orders_dataset ood ON ocd.customer_id = ood.customer_id 
    WHERE ood.order_status NOT IN ('canceled', 'unavailable') 
    GROUP BY ocd.customer_unique_id;

SELECT
    ocd.customer_unique_id,
    ood.order_id,
    ood.order_purchase_timestamp AS order_date,
    r.avg_review_score
FROM olist_orders_dataset ood
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id 
JOIN reviews r ON ood.order_id = r.order_id 
JOIN first_orders fo ON fo.customer_unique_id = ocd.customer_unique_id 
WHERE ood.order_status NOT IN ('canceled', 'unavailable')
    AND EXISTS (
        SELECT 1
        FROM olist_orders_dataset ood2
        JOIN olist_customers_dataset ocd2
            ON ood2.customer_id = ocd2.customer_id
        WHERE ocd2.customer_unique_id = ocd.customer_unique_id
          AND ood2.order_status NOT IN ('canceled', 'unavailable')
          AND ood2.order_purchase_timestamp >
              DATE_ADD(fo.first_order_time, INTERVAL 10 MINUTE)
    )
ORDER BY ocd.customer_unique_id, ood.order_purchase_timestamp;

CREATE VIEW repeat_customer_orders AS
SELECT
    ocd.customer_unique_id,
    ood.order_id,
    ood.order_purchase_timestamp AS order_date,
    r.avg_review_score, 
    ROW_NUMBER() OVER (
        PARTITION BY ocd.customer_unique_id
        ORDER BY ood.order_purchase_timestamp
    ) AS order_number
FROM olist_customers_dataset ocd 
JOIN olist_orders_dataset ood ON ocd.customer_id = ood.customer_id 
JOIN reviews r ON r.order_id = ood.order_id 
JOIN first_orders fo ON fo.customer_unique_id = ocd.customer_unique_id
WHERE ood.order_status NOT IN ('canceled', 'unavailable')
    AND EXISTS (
        SELECT 1
        FROM olist_orders_dataset ood2
        JOIN olist_customers_dataset ocd2
            ON ood2.customer_id = ocd2.customer_id
        WHERE ocd2.customer_unique_id = ocd.customer_unique_id
          AND ood2.order_status NOT IN ('canceled', 'unavailable')
          AND ood2.order_purchase_timestamp >
              DATE_ADD(fo.first_order_time, INTERVAL 10 MINUTE)
    );

SELECT
    CASE
        WHEN order_number = 1 THEN 'Initial order'
        ELSE 'Repeat order'
    END AS order_type,
    COUNT(*) AS number_of_orders,
    AVG(avg_review_score) AS avg_review_score
FROM repeat_customer_orders
GROUP BY order_type;

# What are the main strengths and weaknesses mentioned in customer reviews?
SELECT 
	COUNT(oord.review_comment_message) AS review_comment_message,
	oord.review_score 
FROM olist_order_reviews_dataset oord 
WHERE oord.review_comment_message IS NOT NULL
GROUP BY oord.review_score 
ORDER BY COUNT(oord.review_comment_message) DESC;

# ------------------------------------------------------------------------------------------
# Creating a helper table with shipping distance for dashboard preparation
CREATE TABLE freight_distance_dashboard AS
SELECT
    order_id,
    order_item_id,
    distance_km
FROM freight_distance;

# Preparing the two datasets used in the Power BI dashboard
# Orders-level dataset
SELECT
	ood.order_id,
	ood.customer_id,
	ood.order_status,
	ood.order_purchase_timestamp,
	ocd.customer_unique_id,
	ocd.customer_city,
	ocd.customer_state,
	dp.delivery_time,
	dp.date_differences,
	dp.delivery_difference_group,
	CASE
    	WHEN dp.date_differences < 0 THEN dp.date_differences * -1
    	ELSE NULL
	END AS days_late,
	r.avg_review_score
FROM olist_orders_dataset ood 
JOIN olist_customers_dataset ocd ON ood.customer_id = ocd.customer_id 
LEFT JOIN delivery_performance dp ON ood.order_id = dp.order_id
LEFT JOIN reviews r ON ood.order_id = r.order_id;

# Order-item-level sales dataset
SELECT
	ooid.order_id,
	ooid.order_item_id,
	ooid.product_id,
	ooid.seller_id,
	ooid.price,
	ooid.freight_value,
	pcnt.product_category_name_english,
	opd.product_weight_g,
	(opd.product_height_cm * opd.product_length_cm * opd.product_width_cm) AS product_volume_cm3,
	fd.distance_km 
FROM olist_order_items_dataset ooid 
JOIN olist_products_dataset opd ON ooid.product_id = opd.product_id 
LEFT JOIN product_category_name_translation pcnt ON opd.product_category_name = pcnt.product_category_name 
LEFT JOIN freight_distance_dashboard fd ON fd.order_id = ooid.order_id AND fd.order_item_id = ooid.order_item_id;


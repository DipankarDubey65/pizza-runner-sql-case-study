-- A. Pizza Metrics

-- Q1.  How many pizzas were ordered?
SELECT 
    COUNT(*) total_orders
FROM
    customer_orders; 

-- Q2 How many unique customer orders were made?
SELECT 
    COUNT(DISTINCT order_id) unique_orders
FROM
    customer_orders;
    
-- Q3 How many successful orders were delivered by each runner?
SELECT 
    runner_id, COUNT(order_id) order_deliverd
FROM
    runner_orders
WHERE
    cancellation IS NULL
GROUP BY runner_id;

-- Q4 How many of each type of pizza was delivered?
SELECT 
    pz.pizza_name, COUNT(ro.order_id) total_deliverd
FROM
    customer_orders oc
        JOIN
    runner_orders ro ON oc.order_id = ro.order_id
        JOIN
    pizza_names pz ON oc.pizza_id = pz.pizza_id
WHERE
    ro.cancellation IS NULL
GROUP BY pz.pizza_name; 

-- Q5 How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    oc.customer_id,
    pz.pizza_name,
    COUNT(oc.order_id) total_order
FROM
    customer_orders oc
        JOIN
    pizza_names pz ON oc.pizza_id = pz.pizza_id
GROUP BY oc.customer_id , pz.pizza_name;

-- Q6 What was the maximum number of pizzas delivered in a single order?
select max(order_delivered) single_order 
from 
(SELECT 
    oc.order_id, COUNT(*) order_delivered
FROM
    customer_orders oc
        JOIN
    runner_orders ro ON oc.order_id = ro.order_id
WHERE
    ro.cancellation IS NULL
GROUP BY oc.order_id) sub;

-- Q7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    oc.customer_id,
    COUNT(CASE
        WHEN
            (oc.exclusions IS NOT NULL
                OR oc.extras IS NOT NULL)
        THEN
            1
    END) total_changes,
    COUNT(CASE
        WHEN
            (oc.exclusions IS NULL
                AND oc.extras IS NULL)
        THEN
            1
    END) total_no_changes
FROM
    customer_orders oc
        JOIN
    runner_orders ro ON oc.order_id = ro.order_id
WHERE
    cancellation IS NULL
GROUP BY oc.customer_id;


-- Q8 How many pizzas were delivered that had both exclusions and extras?
SELECT 
    COUNT(CASE
        WHEN
            co.exclusions IS NOT NULL
                AND co.extras IS NOT NULL
        THEN
            1
    END) total
FROM
    customer_orders co
        JOIN
    runner_orders ro ON co.order_id = ro.order_id
WHERE
    ro.cancellation IS NULL;
    
-- Q9 What was the total volume of pizzas ordered for each hour of the day?
SELECT 
    HOUR(order_time) AS times, COUNT(*) total_order
FROM
    customer_orders
GROUP BY times;

-- Q10 What was the volume of orders for each day of the week?
SELECT 
    DAYNAME(order_time) days, COUNT(*) orders
FROM
    customer_orders
GROUP BY days;


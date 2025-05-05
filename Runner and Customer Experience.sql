
-- Q1    How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) + 1 week_number,
    MIN(registration_date) start_week,
    MAX(registration_date) end_week,
    COUNT(*) runner_count
FROM
    runners
GROUP BY week_number
ORDER BY week_number; 

-- Q2    What was the average time in minutes it took for each runner to arrive 
-- at the Pizza Runner HQ to pickup the order?
with t as(SELECT 
    runner_id, substring_index(duration,' ',1) duration_time
FROM
    runner_orders)
 
 SELECT 
    runner_id,
    ROUND(AVG(CAST(SUBSTRING_INDEX(duration_time, 'm', 1) AS UNSIGNED)),
            2) average_time
FROM
    t
GROUP BY runner_id; 
 
-- Q3   Is there any relationship between the number of pizzas and how long the order takes to prepare?
with ord as(select co.order_id, count(co.order_id) orders from customer_orders co group by co.order_id),
cln as(select order_id,runner_id,pickup_time,distance,substring_index(duration,' ',1) as duration,cancellation from runner_orders),
dsn as(select order_id,runner_id,pickup_time,distance, cast(substring_index(duration,'m',1) as unsigned) as duration,cancellation from cln)

select ord.orders,round(avg(dsn.duration),2) as duration from dsn join ord on dsn.order_id = ord.order_id group by ord.orders;

-- Q4   What was the average distance travelled for each customer?
with distance_t as(select order_id, cast(substring_index(distance,'k',1) as float)  distance from runner_orders)

select customer_id,round(avg(dt.distance),2) as distance from customer_orders co 
join distance_t  dt on co.order_id = dt.order_id group by customer_id; 


-- Q5   What was the difference between the longest and shortest delivery times for all orders?
with cln as(select order_id,runner_id,pickup_time,distance,substring_index(duration,' ',1) as duration,cancellation from runner_orders),
dsn as(select order_id,runner_id,pickup_time,distance, cast(substring_index(duration,'m',1) as unsigned) as duration,cancellation from cln)

select (longest_time-shortest_time) as time from(
select max(duration) longest_time,min(duration) shortest_time from dsn) a;

-- Q6  What was the average speed for each runner for each delivery and do you notice any trend for these values?
with cln as(select order_id,runner_id,pickup_time,distance,substring_index(duration,' ',1) as duration,cancellation from runner_orders),
dsn as(select order_id,runner_id,pickup_time,distance, cast(substring_index(duration,'m',1) as unsigned) as duration,cancellation from cln),
distance_t as(select order_id, cast(substring_index(distance,'k',1) as float)  distance from runner_orders)

SELECT 
    du.order_id,du.runner_id,
    ROUND(AVG(dt.distance / du.duration)*60, 2) avg_speed
FROM
    dsn du
        JOIN
    distance_t dt ON du.order_id = dt.order_id
GROUP BY du.runner_id,du.order_id;

-- Q7   What is the successful delivery percentage for each runner?
SELECT 
    runner_id,
    ROUND((COUNT(CASE
                WHEN cancellation IS NULL THEN 1
            END) * 100) / COUNT(*)) successfull_delivery_percentage
FROM
    runner_orders
GROUP BY runner_id;


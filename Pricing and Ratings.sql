
   /* Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
         how much money has Pizza Runner made so far if there are no delivery fees? */
with filter_data as(SELECT 
	co.pizza_id ,count(*) total_delivered
FROM
    customer_orders co
        JOIN
    runner_orders ro ON co.order_id = ro.order_id
WHERE
    ro.cancellation IS NULL
    group by co.pizza_id),

price_data as(select pn.pizza_name,(case when pizza_name = 'Meatlovers' then fd.total_delivered * 12  else fd.total_delivered *10 end) total_earn 
from filter_data as fd join pizza_names pn on fd.pizza_id = pn.pizza_id)

select sum(total_earn) as total_revenue from price_data;


/* Q2. What if there was an additional $1 charge for any pizza extras?
        Add cheese is $1 extra  */
with filter_data as(select co.pizza_id,co.extras from customer_orders co 
join runner_orders ro on co.order_id = ro.order_id where ro.cancellation is null), 

extra_t as(select fd.pizza_id,t.extra_id from filter_data fd,json_table(concat('["',replace(fd.extras,',','","'),'"]'),
"$[*]"columns(extra_id int path "$")) as t),

total_extr_price as(select et.pizza_id, sum(case when extra_id is not null then 1 end) total_extra from extra_t et group by et.pizza_id),

pizza_delivered as(select pn.pizza_id, pn.pizza_name,count(*) pizza_count from filter_data fd 
join pizza_names pn on fd.pizza_id = pn.pizza_id group by pn.pizza_name,pn.pizza_id),

revenue as(select pd.pizza_name, tp.total_extra,(case when pd.pizza_name = 'Meatlovers' 
then pd.pizza_count * 12 else pd.pizza_count * 10 end) as total_earn from pizza_delivered pd 
left join total_extr_price tp on pd.pizza_id = tp.pizza_id)

select sum(revenue.total_earn+coalesce(total_extra,0))  as total_revenue from revenue;

        
/* Q3.    The Pizza Runner team now wants to add an additional ratings system that 
allows customers to rate their runner, how would you design an additional table for this new dataset - 
generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5. */
create table runner_ratings(order_id int primary key,runner_id int, rating int check(rating between 1 and 5), rating_date date);
insert into runner_ratings(order_id,runner_id,rating,rating_date) 
values 
(1, 1, 5, '2021-01-01'),
(2, 1, 4, '2021-01-01'),
(3, 1, 3, '2021-01-02'),
(4, 2, 5, '2021-01-02'),
(5, 3, 4, '2021-01-11');
select * from runner_ratings;


/* Q4.    Using your newly generated table - can you join all of the information together to 
form a table which has the following information for successful deliveries?
customer_id, order_id, runner_id, rating, order_time, pickup_time, Time between order 
and pickup, Delivery duration, Average speed, Total number of pizzas */

with pizzas_count as(select order_id,count(*) total_pizzas from customer_orders group by order_id),

dur as (select order_id, substring_index(duration,' ',1)  duration  from runner_orders ro),
duration as(select order_id,cast(substring_index(duration,'m',1)as unsigned) durations from dur),

distance_t as(select order_id,cast(substring_index(ro.distance,'k',1)as unsigned) as distance from runner_orders ro)

select co.order_id,co.customer_id,co.order_time,
ro.runner_id,ro.pickup_time,ro.distance,ro.duration,rt.rating,rt.rating_date,pc.total_pizzas, du.durations,
round(dt.distance / (du.durations/60),2) as average_speed_kmph,
timestampdiff(minute,co.order_time,ro.pickup_time)  time_between_order_and_pickup 
from customer_orders co join runner_orders ro on co.order_id = ro.order_id 
join runner_ratings rt on co.order_id = rt.order_id join pizzas_count pc on co.order_id = pc.order_id 
join duration du on co.order_id = du.order_id join distance_t dt on co.order_id = dt.order_id
where ro.cancellation is null;
  
 /* Q5.   If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and 
    each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries? */
with  filter_data as(select co.pizza_id,count(*) pizza_deliver from customer_orders co join runner_orders ro 
on co.order_id = ro.order_id  where ro.cancellation is null group by co.pizza_id),

company_earn  as(select pn.pizza_name,( case when pn.pizza_name = 'Meatlovers' then fd.pizza_deliver * 12 
else fd.pizza_deliver *10 end) as earn 
from filter_data fd join pizza_names pn on fd.pizza_id = pn.pizza_id),

runner_earn as(select runner_id,(sum(cast(substring_index(ro.distance,'k',1) as decimal))*0.30) as runner_payment 
from runner_orders ro group by runner_id)

select
((select sum(earn) revenue from company_earn) -(select sum(runner_payment) total_runner_payment from runner_earn)) total_profit



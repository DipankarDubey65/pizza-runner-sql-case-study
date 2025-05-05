-- C. Ingredient Optimisation --

 -- aaray ke value ko column me insert krna 
 select* from json_table('["1","2","3","4"]',"$[*]" columns(val int path "$")) as t;
 
-- Q1    What are the standard ingredients for each pizza?
with topping as(select prz.pizza_id,t.topping_id from pizza_recipes prz, 
json_table(
concat('["',replace(toppings,',','","'),'"]'), -- convert array form
 "$[*]"columns(topping_id int path "$"))as t )  -- insert column in
 
 SELECT 
    pzn.pizza_id, pzn.pizza_name, pt.topping_name
FROM
    pizza_names pzn
        JOIN
    topping pzr ON pzn.pizza_id = pzr.pizza_id
        JOIN
    pizza_toppings pt ON pzr.topping_id = pt.topping_id
ORDER BY pzn.pizza_id ASC; 

-- Q2    What was the most commonly added extra?
with filter_data as(select pizza_id,order_id,extras_id from customer_orders,
json_table(concat('["',replace(extras,',','","'),'"]'),"$[*]"columns(extras_id int path "$"))as t)

select topping_name,max(most_commonly) as most_extras from
(select pt.topping_name,count(fd.extras_id) as most_commonly from pizza_toppings pt 
join filter_data fd on pt.topping_id = fd.extras_id group by pt.topping_name) s ;

-- Q3    What was the most common exclusion?
with filter_data AS(select order_id,pizza_id,exclusion_id 
from customer_orders,json_table(concat('["',replace(exclusions,',','","'),'"]'),"$[*]" columns(exclusion_id int path "$")) as t)
select topping_name,max(exclusion_qunt) as most_exclusion from(
select pt.topping_name,count(fd.exclusion_id) exclusion_qunt from filter_data fd join pizza_toppings pt 
on fd.exclusion_id = pt.topping_id group by pt.topping_name) as s;

/* Q4    Generate an order item for each record in the customers_orders table in the format of one of the following:
        Meat Lovers
        Meat Lovers - Exclude Beef
        Meat Lovers - Extra Bacon
        Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */
        
      -- step 1 
    with   exc as (select * from customer_orders,json_table(concat('["',replace(exclusions,',','","'),'"]'),
    "$[*]"columns(exc_id int path "$")) as s),
       
       extr as (select * from customer_orders,json_table(concat('["',replace(extras,',','","'),'"]'),"$[*]"
       columns(extr_id int path "$")) as s),
       
       -- step 2
       exclusion_final as (select exc.order_id,group_concat(pt.topping_name order by  pt.topping_name)as exclusions from pizza_toppings pt join
        exc on pt.topping_id = exc.exc_id group by exc.order_id),
        
     extras_final as  ( select extr.order_id,group_concat(pt.topping_name order by pt.topping_name) extras
     from pizza_toppings pt join extr on pt.topping_id = extr.extr_id group by extr.order_id),
     
     -- step 3
      pizza_data as(select co.order_id, pizza_name from pizza_names pn join customer_orders co on pn.pizza_id = co.pizza_id) 
     
     -- step 4 final query
     select pd.order_id,concat(pd.pizza_name,ifnull(concat('- Exclude ',ef.exclusions),''),
     ifnull(concat('- Extra ',extf.extras),'') ) as order_items
     from pizza_data pd  left join exclusion_final ef  on pd.order_id = ef.order_id 
     left join  extras_final extf  on pd.order_id = extf.order_id ; 
	
  

/* Q5    Generate an alphabetically ordered comma separated ingredient list for each 
pizza order from the customer_orders table and add a 2x in 
front of any relevant ingredients For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" */
with base_toppings as(select pizza_id,topping_id from pizza_recipes,json_table(concat('["',replace(toppings,',','","'),'"]'),
"$[*]"columns(topping_id int path "$"))as t),

 extras_t as(select * from customer_orders co,json_table(concat('["',replace(extras,',','","'), '"]'), 
"$[*]"columns(extras_id int path "$")) as t),

exclusion_t as(select * from customer_orders co,json_table(concat('["',replace(exclusions,',','","'), '"]'), 
"$[*]"columns(exc_id int path "$")) as s),

all_ingredients AS (
  SELECT co.order_id, co.pizza_id, pt.topping_name
  FROM customer_orders co
  JOIN base_toppings bt ON co.pizza_id = bt.pizza_id
  JOIN pizza_toppings pt ON bt.topping_id = pt.topping_id
  LEFT JOIN exclusion_t et ON co.order_id = et.order_id AND bt.topping_id = et.exc_id
  WHERE et.exc_id IS NULL -- Remove exclusions
  UNION ALL
  SELECT et.order_id, co.pizza_id, CONCAT('2x', pt.topping_name) AS topping_name
  FROM extras_t et
  JOIN pizza_toppings pt ON et.extras_id = pt.topping_id
  JOIN customer_orders co ON co.order_id = et.order_id
),


order_pizza AS (
  SELECT co.order_id, pn.pizza_name
  FROM customer_orders co
  JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
),

-- Final output
final_output AS (
  SELECT ai.order_id, op.pizza_name,
         GROUP_CONCAT(ai.topping_name ORDER BY ai.topping_name SEPARATOR ', ') AS ingredients
  FROM all_ingredients ai
  JOIN order_pizza op ON ai.order_id = op.order_id
  GROUP BY ai.order_id, op.pizza_name
)

-- Final Select
SELECT CONCAT(pizza_name, ': ', ingredients) AS final_order
FROM final_output
ORDER BY order_id;





-- Q6    What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

with deliverd_t as(select co.order_id,co.pizza_id,co.exclusions,co.extras from runner_orders ro 
join customer_orders co on ro.order_id = co.order_id  where ro.cancellation is null),

base_toppings as(select pr.pizza_id,t.topping_id from pizza_recipes pr, 
json_table(concat('["',replace(toppings,',','","'),'"]'),"$[*]"columns(topping_id int path "$"))as t),

extr_t as(select dt.order_id,t.extr_id from deliverd_t as dt,
json_table(concat('["',replace(extras,',','","'), '"]'),"$[*]"columns(extr_id int path "$")) as t),

exc_t as(select dt.order_id,t.exc_id from deliverd_t as dt,
json_table(concat('["',replace(exclusions,',','","'), '"]'),"$[*]"columns(exc_id int path "$")) as t),

base_clean as(select dt.order_id,bt.topping_id from deliverd_t dt join base_toppings bt on dt.pizza_id = bt.pizza_id
left join exc_t et on dt.order_id = et.order_id and bt.topping_id = et.exc_id  where et.exc_id is null),

final_topping as(select topping_id,1 as quantity from base_clean
union all
select extr_id as tooping_id, 2 as quantity from extr_t)

select pt.topping_name,sum(ft.quantity) as total_quantity from final_topping ft join pizza_toppings pt on ft.topping_id = pt.topping_id
group by pt.topping_name
order by total_quantity desc;
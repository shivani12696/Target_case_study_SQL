# Problem: What does 'good' look like? 
# Import the dataset and do usual exploratory analysis steps like checking the structure & 
# characteristics of the dataset: 
# Data type of all columns in the "customers" table. 

 Select * from ‘sqlproject.customers’ limit 10 

# Problem: Get the time range between which the orders were placed.  

Select extract (year from order_purchase_timestamp) as Year,  
Min(order_purchase_timestamp) as Min_order_purchased,  
Max(order_purchase_timestamp) as Max_order_purchased, 
timestamp_diff(max(order_purchase_timestamp), min(order_purchase_timestamp), 
day) as days_diff 
from `sqlproject.orders` 
group by Year 
order by Year  

# Problem: Count the Cities & States of customers who ordered during the given period.  

select count(distinct x.customer_city) as cities, count(distinct x.customer_state) as 
states from  
(select *  
from `sqlproject.customers` 
inner join `sqlproject.orders`  
using(customer_id)) x  

# Problem: Is there a growing trend in the no. of orders placed over the past years? 

select extract(year from order_purchase_timestamp) as Year, count(*) as no_of_orders 
from `sqlproject.orders` 
group by extract(year from order_purchase_timestamp) 
order by Year  

# Problem: Can we see some kind of monthly seasonality in terms of the no. of orders being placed? 

select extract(month from order_purchase_timestamp) as Months,  
format_datetime("%B", order_purchase_timestamp) as month_name, 
count(*) as no_of_orders 
from `sqlproject.orders`  
group by extract(month from order_purchase_timestamp), format_datetime("%B", 
order_purchase_timestamp) 
order by no_of_orders desc   

# Problem:  During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night) 

# 0-6 hrs : Dawn 
# 7-12 hrs : Mornings 
# 13-18 hrs : Afternoon 
# 19-23 hrs : Night

select y.time_, count(*) as no_of_order_placed from  
  (select hours_, 
  case  
      when hours_ <= 6 then "Dawn" 
      when hours_ between 7 and 12 then "Mornings"  
      when hours_ between 13 and 18 then "Afternoon"  
      else "Night"  
  end as time_ from  
    ( 
      select extract(hour from order_purchase_timestamp) as hours_ 
      from `sqlproject.orders` 
      order by hours_ 
    )x  
  ) y 
group by y.time_ 
order by no_of_order_placed desc 

# Problem: Evolution of E-commerce orders in the Brazil region: Get the month on month no. of orders placed in each state.  

select c.customer_state, extract(month from o.order_purchase_timestamp) as Month, 
format_datetime("%B", o.order_purchase_timestamp) as month_name, 
count(o.order_id) as no_of_orders 
from `sqlproject.orders` o 
inner join `sqlproject.customers` c 
using(customer_id)  
group by c.customer_state, Month, month_name  
order by c.customer_state, Month  

# Problem: How are the customers distributed across all the states?

select customer_state, count(customer_id) as no_of_customers from 
`sqlproject.customers` 
group by customer_state  
order by no_of_customers desc

# Problem: Impact on Economy: Analyse the money movement by e-commerce by looking at order prices, freight and others.  

# Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). You can use the "payment_value" column in the payments table to get the cost of # orders.

WITH order_costs AS ( 
    SELECT  
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year, 
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS order_month, 
        SUM(p.payment_value) AS total_payment_value 
    FROM `sqlproject.orders` o 
    JOIN `sqlproject.payments` p ON o.order_id = p.order_id 
    WHERE EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 
AND 8 
    GROUP BY order_year, order_month 
) 
 
SELECT  
    (SUM(CASE WHEN order_year = 2018 THEN total_payment_value ELSE 0 END) -  
     SUM(CASE WHEN order_year = 2017 THEN total_payment_value ELSE 0 END)) 
/  
SUM(CASE WHEN order_year = 2017 THEN total_payment_value ELSE 0 END) 
* 100 AS percentage_increase 
FROM order_costs; 












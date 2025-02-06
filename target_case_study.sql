# WHAT DOES GOOD LOOK LIKE:  
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

# EVOLUTION OF E-COMMERCE IN THE BRAZIL REGION: 
# Get the month on month no. of orders placed in each state.  

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

# IMPACT ON ECONOMY: ANALYSE THE MONEY MOVEMENT BY E-COMMERCE BY LOOKING AT ORDER PRICES, FREIGHT AND OTHERS.   

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

# Calculate the Total & Average value of order price for each state.  

select c.customer_state, round(sum(p.payment_value), 2) as total_price, 
round(avg(p.payment_value), 2) as average_value 
from `sqlproject.customers` c  
inner join `sqlproject.orders` o  
using(customer_id)  
inner join `sqlproject.payments` p 
using(order_id)  
group by c.customer_state 
order by total_price desc  

#  Calculate the Total & Average value of order freight for each state. 

select c.customer_state, round(sum(ot.freight_value), 2) as total_freight_value, 
round(avg(ot.freight_value), 2) as average_freight_value 
from `sqlproject.customers` c 
inner join `sqlproject.orders` o  
using(customer_id) 
inner join `sqlproject.order_items` ot  
using(order_id) 
group by c.customer_state  
order by total_freight_value desc   

# ANALYSIS BASED ON SALES, FREIGHT, AND DELIVERY TIME. 

# Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. Also, calculate the difference (in days) between the estimated & actual delivery date of # an order. 
# Do this in a single query. You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula: 
# 	a. time_to_deliver = order_delivered_customer_date - order_purchase_timestamp 
# 	b. diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date

select  order_id,   
date_diff(order_delivered_customer_date, order_purchase_timestamp, day) as 
time_to_deliver,  
date_diff(order_delivered_customer_date, order_estimated_delivery_date, day) as 
diff_estimated_delivery 
from `sqlproject.orders` 

# Find out the top 5 states with the highest & lowest average freight value.  

(SELECT c.customer_state, round(AVG(oi.freight_value), 2) AS avg_freight 
FROM `sqlproject.customers` c 
JOIN 
`sqlproject.orders` o 
using(customer_id)  
JOIN 
`sqlproject.order_items` oi 
using(order_id) 
group by c.customer_state  
order by avg_freight desc limit 5)   
union all   
(SELECT c.customer_state, round(AVG(oi.freight_value), 3) AS lowest_avg_freight 
FROM `sqlproject.customers` c 
JOIN 
`sqlproject.orders` o 
using(customer_id)  
JOIN 
`sqlproject.order_items` oi 
using(order_id) 
group by c.customer_state  
order by lowest_avg_freight asc limit 5)  

# Find out the top 5 states with the highest & lowest average delivery time. 
# Highest delivery_time (in Days):   

select c.customer_state, 
round(avg(date_diff(order_delivered_customer_date, 
order_purchase_timestamp, day)), 2) as highest_delivery_time 
from `sqlproject.customers` c 
join `sqlproject.orders` o 
using(customer_id)  
group by c.customer_state  
order by highest_delivery_time desc 
limit 5  

# Lowest delivery time (in Days):   

select c.customer_state, 
round(avg(date_diff(order_delivered_customer_date, 
order_purchase_timestamp, day)), 2) as lowest_delivery_time 
from `sqlproject.customers` c 
join `sqlproject.orders` o 
using(customer_id)  
group by c.customer_state  
order by lowest_delivery_time asc 
limit 5 

# Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery. You can use the difference between the averages of actual & estimated
# delivery date to figure out how fast the delivery was for each state. 

select customer_state, round(estimated_days-delivered_days, 2) as 
fastest_days_taken from  
(select c.customer_state,  
round(avg(date_diff(o.order_delivered_customer_date, 
o.order_purchase_timestamp, day)), 2) as delivered_days, 
round(avg(date_diff(o.order_estimated_delivery_date, 
o.order_purchase_timestamp, day)), 2) as estimated_days 
from `sqlproject.customers` c 
inner join `sqlproject.orders` o 
using(customer_id) 
where o.order_purchase_timestamp is Not NULL  
and o.order_delivered_customer_date is Not NULL  
and o.order_estimated_delivery_date is Not NULL  
group by c.customer_state ) x 
order by estimated_days-delivered_days desc limit 5 

# ANALYSIS BASED ON THE PAYMENTS.  

# Find the month on month no. of orders placed using different payment types. 

select extract(month from o.order_purchase_timestamp) as month, 
format_datetime("%B", o.order_purchase_timestamp) as month_name, 
p.payment_type, count(o.order_id) as orders_placed 
from `sqlproject.orders` o 
inner join `sqlproject.payments` p 
using(order_id) 
group by month, month_name, p.payment_type 
order by month  

# Find the no. of orders placed on the basis of the payment instalments that have been paid.  

select payment_installments, count(order_id) as no_of_orders 
from `sqlproject.payments` 
group by payment_installments 
















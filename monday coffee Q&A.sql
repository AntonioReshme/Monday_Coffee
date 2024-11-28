--Monday Coffee--Data Analysis

select *from city
select*from products
select*from customers
select*from sales

--Reports and Data Analysis
--(1)Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?

select
city_name,
round((population*0.25)/1000000,2)as coffee_consumers_in_millions,
city_rank
from city
order by 2 desc

--(2)Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select
c.city_name,
sum(s.total)as total_revenue
from sales as s
join customers as cu
on cu.customer_id=s.customer_id
join city as c
on c.city_id=cu.city_id
where 
	extract(year from sale_date)='2023'
and
	extract(quarter from sale_date)='4'
group by 1
order by 2 desc

--(3)Sales Count for Each Product
--How many units of each coffee product have been sold?

select
p.product_name,
count(sale_id)as total_orders
from products as p
join sales as s
on s.product_id=p.product_id
group by 1
order by 2 desc

--(4)Average Sales Amount per City
--What is the average sales amount per customer in each city?

select
c.city_name,
sum(s.total)as total_revenue,
count(distinct s.customer_id)as total_customers,
round(sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2)as average_sale_per_customer
from sales as s
join customers as cu
on cu.customer_id=s.customer_id
join city as c
on c.city_id=cu.city_id
group by 1
order by 4 desc

--(5)City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers?

select
c.city_name,
round((c.population*0.25)/1000000,2)as coffee_consumers,
count(distinct cu.customer_id)as unique_customer
from city as c
join customers as cu
on cu.city_id=c.city_id
group by 1,2
order by 1

--(6)Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?

with t1 as
(
select 
c.city_name,
p.product_name,
count(s.sale_id)as Total_orders,
dense_rank()over(partition by c.city_name order by count(s.sale_id)desc)as rank
from sales as s
join products as p
on p.product_id=s.product_id
join customers as cu
on cu.customer_id=s.customer_id
join city as c
on c.city_id=cu.city_id
group by 1,2
)
select*from t1
where rank<=3

--(7)Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

select
c.city_name,
p.product_name,
count(distinct cu.customer_id)as unique_customer
from sales as s
join customers as cu
on cu.customer_id=s.customer_id
join city as c
on c.city_id=cu.city_id
join products as p
on p.product_id=s.product_id
group by 1,2

--(8)Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer?
with city_table as
(
select
c.city_name,
sum(s.total)as total_revenue,
count(distinct s.customer_id)as total_customers,
round(sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2) as average_sales_per_customer
from sales as s
join customers as cu
on cu.customer_id=s.customer_id
join city as c
on c.city_id=cu.city_id
group by 1
order by 4 desc
),
city_rent as
(
select
city_name,
sum(estimated_rent)as total_rent
from city
group by 1
)
select
city_rent.city_name,
city_rent.total_rent,
city_table.total_customers,
city_table.average_sales_per_customer,
round((city_rent.total_rent::numeric/city_table.total_customers::numeric),2)as average_rent_per_customer
from city_rent
join city_table
on city_table.city_name=city_rent.city_name
order by 5 desc

--(9)Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)?
with monthly_sales as
(
select
c.city_name,
extract(year from s.sale_date)as year,
extract(month from s.sale_date)as month,
sum(s.total)as total_sale
from sales as s
join customers as cu
on cu.customer_id=s.customer_id
join city as c
on c.city_id=cu.city_id
group by 1,2,3
order by 1,2,3
),
growth_ratio as
(
select
city_name,
year,
month,
total_sale as current_month_sale,
lag(total_sale)over(partition by city_name order by year,month)as previous_month_sale
from monthly_sales
)
select
city_name,
year,
month,
current_month_sale,
previous_month_sale,
round((current_month_sale-previous_month_sale)::numeric/previous_month_sale::numeric*100,2)as growth_ratio
from growth_ratio
where previous_month_sale is not null

--(10)Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer?

with city_table as
(
select
c.city_name,
sum(s.total)as total_revenue,
count(distinct s.customer_id)as total_customers,
round(sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2) as average_sales_per_customer
from sales as s
join customers as cu
on cu.customer_id=s.customer_id
join city as c
on c.city_id=cu.city_id
group by 1
order by 2 desc
),
city_rent as
(
select
city_name,
estimated_rent,
round((population*0.25)/1000000,3) as estimated_coffee_consumers_in_millions
from city
)
select
city_rent.city_name,
city_table.total_revenue,
city_rent.estimated_rent as total_rent,
city_table.total_customers,
city_rent.estimated_coffee_consumers_in_millions,
city_table.average_sales_per_customer,
round((city_rent.estimated_rent::numeric/city_table.total_customers::numeric),2)as average_rent_per_customer
from city_rent
join city_table
on city_table.city_name=city_rent.city_name
order by 4 desc

/*
--Recommendation
City 1 : Pune
		1. average_rent_per_customer is very less
		2. highest_total_revenue 
		3. average_sale_per_customer is also high
		
City 2 : Delhi
		1. highest_estimated_coffee_comsumer which is 7.7M
		2. highest total_customer which is 68
		3. average_rent_per_customer is 330(still under 500)

City 3 : Jaipur
		1. highest customer no is 69
		2. average_rent_per_customer is very less 156
		3. average_sale_per_customer is better which is at 11.6k


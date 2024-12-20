# Monday Coffee Expansion SQL Project

![image](https://github.com/user-attachments/assets/bbca5af2-96b7-4ead-ad0a-c6ee9e85ab5a)
  
## Objective

The goal of this project is to analyze the sales data of Monday Coffee, a company that has been selling its products online since January 2023, and to recommend the top three major cities in India for opening new coffee shop locations based on consumer demand and sales performance.

## Project Structure

## 1. Database Setup

**- Database Creation**: The project starts by creating a database named monday_coffee_db.

**- Table Creation**: A table named city, customers, products and sales is created to store the coffee sales data.

CREATE TABLE city(

city_id	INT PRIMARY KEY,

city_name VARCHAR(15),	

population	BIGINT,

estimated_rent	FLOAT,

city_rank INT);


CREATE TABLE customers(

customer_id INT PRIMARY KEY,

customer_name VARCHAR(25),

city_id INT,

CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id));


CREATE TABLE products(

product_id	INT PRIMARY KEY,

product_name VARCHAR(35),	

Price float);


CREATE TABLE sales(

sale_id	INT PRIMARY KEY,

sale_date	date,

product_id	INT,

customer_id	INT,

total FLOAT,

rating INT,

CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),

CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) );

## 2. Data Analysis and Findings

**1. How many people in each city are estimated to consume coffee, given that 25% of the population does?**

select city_name, round((population*0.25)/1000000,2)as coffee_consumers_in_millions, city_rank

from city

order by 2 desc

**2. What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?**

select c.city_name, sum(s.total)as total_revenue

from sales as s

join customers as cu

on cu.customer_id=s.customer_id

join city as c

on c.city_id=cu.city_id

where extract(year from sale_date)='2023'

and

extract(quarter from sale_date)='4'

group by 1

order by 2 desc

**3. How many units of each coffee product have been sold?**

select p.product_name, count(sale_id)as total_orders

from products as p

join sales as s

on s.product_id=p.product_id

group by 1

order by 2 desc

**4. What is the average sales amount per customer in each city?**

select c.city_name, sum(s.total)as total_revenue, count(distinct s.customer_id)as total_customers, round(sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2)as average_sale_per_customer

from sales as s

join customers as cu

on cu.customer_id=s.customer_id

join city as c

on c.city_id=cu.city_id

group by 1

order by 4 desc

**5. Provide a list of cities along with their populations and estimated coffee consumers?**

select c.city_name, round((c.population*0.25)/1000000,2)as coffee_consumers, count(distinct cu.customer_id)as unique_customer

from city as c

join customers as cu

on cu.city_id=c.city_id

group by 1,2

order by 1

**6. What are the top 3 selling products in each city based on sales volume?**

with t1 as (

select  c.city_name, p.product_name, count(s.sale_id)as Total_orders, dense_rank()over(partition by c.city_name order by count(s.sale_id)desc)as rank

from sales as s

join products as p

on p.product_id=s.product_id

join customers as cu

on cu.customer_id=s.customer_id

join city as c

on c.city_id=cu.city_id

group by 1,2)

select*from t1

where rank<=3

**7. How many unique customers are there in each city who have purchased coffee products?**

select c.city_name, p.product_name, count(distinct cu.customer_id)as unique_customer

from sales as s

join customers as cu

on cu.customer_id=s.customer_id

join city as c

on c.city_id=cu.city_id

join products as p

on p.product_id=s.product_id

group by 1,2

**8. Find each city and their average sale per customer and avg rent per customer**

with city_table as(

select c.city_name, sum(s.total)as total_revenue, count(distinct s.customer_id)as total_customers, round(sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2) as average_sales_per_customer

from sales as s

join customers as cu

on cu.customer_id=s.customer_id

join city as c

on c.city_id=cu.city_id

group by 1

order by 4 desc),

city_rent as(

select city_name, sum(estimated_rent)as total_rent

from city

group by 1)

select city_rent.city_name, city_rent.total_rent, city_table.total_customers, city_table.average_sales_per_customer, round((city_rent.total_rent::numeric/city_table.total_customers::numeric),2)as 

average_rent_per_customer

from city_rent

join city_table

on city_table.city_name=city_rent.city_name

order by 5 desc

**9. Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)?**

with monthly_sales as(

select c.city_name, extract(year from s.sale_date)as year, extract(month from s.sale_date)as month, sum(s.total)as total_sale

from sales as s

join customers as cu

on cu.customer_id=s.customer_id

join city as c

on c.city_id=cu.city_id

group by 1,2,3

order by 1,2,3),

growth_ratio as(

select city_name, year, month, total_sale as current_month_sale, lag(total_sale)over(partition by city_name order by year,month)as previous_month_sale

from monthly_sales)

select city_name, year, month, current_month_sale, previous_month_sale, round((current_month_sale-previous_month_sale)::numeric/previous_month_sale::numeric*100,2)as growth_ratio

from growth_ratio

where previous_month_sale is not null

**10. Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer?**

with city_table as (

select c.city_name, sum(s.total)as total_revenue, count(distinct s.customer_id)as total_customers, round(sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2) as average_sales_per_customer

from sales as s

join customers as cu

on cu.customer_id=s.customer_id

join city as c

on c.city_id=cu.city_id

group by 1

order by 2 desc), 

city_rent as(

select city_name, estimated_rent, round((population*0.25)/1000000,3) as estimated_coffee_consumers_in_millions

from city)

select city_rent.city_name, city_table.total_revenue, city_rent.estimated_rent as total_rent, city_table.total_customers, city_rent.estimated_coffee_consumers_in_millions, city_table.average_sales_per_customer, 

round((city_rent.estimated_rent::numeric/city_table.total_customers::numeric),2)as average_rent_per_customer

from city_rent

join city_table

on city_table.city_name=city_rent.city_name

order by 4 desc

## Recommendations

After analyzing the data, the recommended top three cities for new store openings are:

#### City 1: Pune

- Average rent per customer is very low.
- Highest total revenue.
- Average sales per customer is also high.

#### City 2: Delhi

- Highest estimated coffee consumers at 7.7 million.
- Highest total number of customers, which is 68.
- Average rent per customer is 330 (still under 500).

#### City 3: Jaipur

- Highest number of customers, which is 69.
- Average rent per customer is very low at 156.
- Average sales per customer is better at 11.6k.

## Conclusion

This project serves as a comprehensive introduction to SQL for data analysts, covering database setup, data cleaning, exploratory data analysis, and business-driven SQL queries. The findings from this project can help drive business decisions by understanding sales patterns, customer behavior, and product performance.

## Author - Antonio Reshme

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!


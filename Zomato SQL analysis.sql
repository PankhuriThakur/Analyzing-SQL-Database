drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--Question 1:  What is the total amount each customer spent on zomato?

select a.userid, sum(b.price) as total_amount_spent
from sales
a inner join product b
on a.product_id = b.product_id
group by a.userid;


-- Question 2: How many days has each customer visited zomato?

select userid, count(distinct created_date) distinct_days 
from sales
group by userid;

-- Question 3: What is the most purchased item on the menu and how many times was it purchased by all customer?
select * from
(select *, rank() over (partition by userid order by created_date)
rank from sales) 
a where rank =1; -- This is the very first product bought by the customer who are joining Zomato. This is a simple indication that all the customer are attracted 
                 -- to this particular product and the business should invest and make it more good because in the future lot of customer would be attracted to this product.


-- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

select userid, count(product_id) cnt from sales where product_id = 
(select top 1  product_id
from sales
group by product_id
order by count(product_id) desc) 
group by userid;

-- Question 5: What item was the most popular  for each customer?

select * from
(select *, rank() over (partition by userid order by cnt desc) rank from 
(select userid, product_id, count(product_id) cnt
from sales 
group by userid, product_id)a)b
where rank = 1;    -- this gives which product is liked by each of the customer


-- Question 6: Which item was purchased first by the customer after they became a member?

select * from 
(select c.*, rank() over(partition by userid order by created_date) rank from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date 
from sales
a inner join goldusers_signup b 
on a.userid = b.userid
and created_date >= gold_signup_date) c) d where rank =1;  -- From this information we get to know that userid 1 has purchased product 3 after signup for gold membership similary for user id 2.

-- Question 7: Which item was purchased by customer just before becoming a member?

select * from 
(select c.*, rank() over(partition by userid order by created_date desc) rank from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date 
from sales
a inner join goldusers_signup b 
on a.userid = b.userid
and created_date <= gold_signup_date) c) d where rank =1; -- Product 2 

-- Question 8: What is the total orders and amount spent for each member before they became a member?

select userid, count(created_date) as order_purchased, sum(price) total_amount_spent from
(select c.*, d.price from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date 
from sales 
a inner join goldusers_signup b
on a.userid = b.userid
and created_date <= gold_signup_date)
c inner join product d 
on c.product_id = d.product_id) e
group by userid;

-- Question 9: If buying each product generates points for eg 5$ = 2 zomoato points and each product has different purchasing points
-- for eg for p1 5$ = 1 zomato point, for p2 10$ = 5 zomato points and p3 5$ = 1 zomato point
-- calculate points collected by each customer and for which product most points have been given till now.

select userid, sum(total_points) * 2.5 total_money_earned from
(select e.*, amount/points total_points from
(select d.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amount from
(select a.*, b.price 
from sales
a inner join product b
on a.product_id  = b.product_id) c
group by userid, product_id)d)e)f      -- so here when userid 1 has spent 1960$ he earned 392 points. 1960/5
group by userid;



(select product_id, sum(total_points) total_point_earned from
(select e.*, amount/points total_points from
(select d.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amount from
(select a.*, b.price 
from sales
a inner join product b
on a.product_id  = b.product_id) c
group by userid, product_id)d)e)f      -- so here when userid 1 has spent 1960$ he earned 392 points. 1960/5
group by product_id);


select * from 
(select *, rank() over (order by total_point_earned desc) rank from
(select product_id, sum(total_points) total_point_earned from
(select e.*, amount/points total_points from
(select d.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select c.userid, c.product_id, sum(price) amount from
(select a.*, b.price 
from sales
a inner join product b
on a.product_id  = b.product_id) c
group by userid, product_id)d)e)f  -- so here when userid 1 has spent 1960$ he earned 392 points. 1960/5
group by product_id)f)g
where rank =1;


-- Question 10:In the first one year after a customers joins the gold program(including their join date) irrespective of what the customer has purchased they earn 5 Zomato ponits
-- for every 10$ spent who earned more 1 or 3 and what was their points earning in thier first year?

select c. *, d.price* 0.5 total_points_earned from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date 
from sales
a inner join goldusers_signup b
on a.userid = b.userid
and created_date <=DATEADD(year, 1, gold_signup_date))c
inner join product d on c.product_id = d.product_id;

-- Question 11: Rank all the transaction of the customers

select *, rank() over (partition by userid order by created_date) rank from sales

-- Question 12: Rank all the transcation for each member whenever they are a zomato gold member for every non gold member trancation mark as na

select e.*, case when rank = 0 then 'na' else rank end as rankk from 
(select c.*, cast ((case when gold_signup_date is null then 0 else rank() over (partition by userid order by created_date desc)end) as varchar) as rank from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date 
from sales 
a left join goldusers_signup b
on a.userid = b.userid
and created_date >= gold_signup_date)c)e;                      -- when I wanted to have na value in the rank column it was not coming because the rank column data type was integer, data type was not matching & giving error so i changed rank data type to varchar so that i can insert na and  it will accomated.


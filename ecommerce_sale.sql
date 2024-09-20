create database Ecommercesales;
use Ecommercesales;
CREATE TABLE goldusers_signup(
userid integer,
gold_signup_date date
); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,"2017-09-22"),(3,"2017-04-21");
 
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,"2014-02-09"),(2,"2015-01-15"),(3,"2014-11-04"); # date column "" should be need
 
 CREATE TABLE sales(userid integer,created_date date,product_id integer); 
 
 INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),

(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


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

# 1.what is the total amount spent each customer on ecommerce sale?
select userid,sum(price) as total_amt from sales s
inner join product p on s.product_id=p.product_id
group by userid;


# 2. how many days has each customer visited ecommercesales?
select u.userid,count(s.userid) as total_visit_days from users u  #(created date alsofind days)
join sales s on s.userid=u.userid
group by u.userid;

# 3.what was the first product purchased by each customer?
select * from 
(select *, rank() over(partition by userid order by created_date) as first_rank from sales) a where first_rank=1 ;

# 4.what is the most purchased item on menu and how many times purchased by all customers?

select product_id,count(product_id) as cnt from sales
group by  product_id
order by cnt desc limit 1;

select userid,count(product_id) as cnt from sales where product_id=
(select product_id from sales group by  product_id
order by count(product_id) desc limit 1)
group by userid order by userid;

# 5.which item was the most popular for each of the customers?

select * from(select*, rank() over(partition by userid order by cnt desc) as rnk from
(select userid,product_id,count(product_id) as cnt from sales group by userid,product_id ) a)b
where rnk=1;

# 6.which item was first purchased by the customer after they became a member?

SELECT * 
FROM (
    SELECT 
        s.userid, 
        s.product_id, 
        p.product_name,
        RANK() OVER (PARTITION BY s.userid ORDER BY s.created_date) AS rnk 
    FROM product p 
    JOIN sales s ON s.product_id = p.product_id
    JOIN goldusers_signup g ON g.userid = s.userid 
    WHERE s.created_date >= g.gold_signup_date
) a 
WHERE rnk = 1;

# 7. which item was purchased by before become a membership?

SELECT * 
FROM (
    SELECT 
        s.userid, 
        s.product_id, 
        p.product_name,
        RANK() OVER (PARTITION BY s.userid ORDER BY s.created_date desc) AS rnk 
    FROM product p 
    JOIN sales s ON s.product_id = p.product_id
    JOIN goldusers_signup g ON g.userid = s.userid 
    WHERE s.created_date < g.gold_signup_date
) a 
WHERE rnk = 1;

# 8. what is the total orders and amount spent each customer before they become a member ship?

SELECT 
        s.userid, 
        count(s.created_date) as total_orders,
        sum(p.price) as total_amt
        from product p
        inner join sales s on p.product_id=s.product_id 
        JOIN goldusers_signup g ON g.userid = s.userid 
		WHERE s.created_date < g.gold_signup_date
		group by  s.userid  order by userid asc;
        
        
# 9. if products buying generates points for eg: 2 coin points and each product has different purchasing points 
# for eg p1 5rs for 1 coin points ,for p2 10rs 2 coins points and p3 5rs 1 coin points. 
# p1- 1coin/5rs,p2-1/2rs,p3-1/5rs. 

# calculate points collected by the each customers and for which product most points have been given till now. 


select c.product_id,sum(c.total_points) as earned_points from   
(
select a.userid,a.product_id,
case 
when product_id=1 then amount/5
when product_id=2 then amount/2
when product_id=3 then amount/5
else "None" end as total_points from
(select s.userid,s.product_id,sum(p.price) as amount from sales s 
inner join product p on p.product_id=s.product_id
group by s.userid,s.product_id
order by s.userid)a
group by a.userid,a.product_id
order by a.userid,a.product_id)c
group by  c.product_id
order by earned_points desc;

-- based on user_id

select d.* from
(select f.*,rank() over(order by earned_points desc) as rnk from
(select c.userid,sum(c.total_points) as earned_points from    # if you want find product wise just add column p.product_id
(
select a.userid,a.product_id,
case 
when product_id=1 then amount/5
when product_id=2 then amount/2
when product_id=3 then amount/5
else "None" end as total_points from
(select s.userid,s.product_id,sum(p.price) as amount from sales s 
inner join product p on p.product_id=s.product_id
group by s.userid,s.product_id
order by s.userid)a
group by a.userid,a.product_id
order by a.userid,a.product_id)c
group by  c.userid)f)d where rnk=1; 

# 10.In the first one year customer after a customer joins the gold program (including joinng date) 
# irrespective of what the customer has purchased they earn 5 gold coin points for every 10rs spent who earned more 1 (or) 3
# and what was thier points earning in thier first year?

-- 10rs-5 coins, 1rs-0.5 coins

select s.userid,s.created_date ,p.product_id,g.gold_signup_date,sum(p.price)*0.5 as total_points from product p 
inner join sales s on s.product_id=p.product_id
inner join goldusers_signup g on  s.userid=g.userid 
where created_date>=gold_signup_date and created_date<=date_add(gold_signup_date,interval '1' year)
group by s.userid,s.created_date,p.product_id,g.gold_signup_date; 


# 11.rank all the transctions of the customers?

select *,rank() over(partition by userid order by created_date desc) as ranks from sales;

# 12. Rank all the transctions for each member whenever they are a gold member for every non gold member transctions mark as na. 

select a.*, 
case when a.gold_signup_date is null then "na"
else rank() over(partition by s.userid order by created_date desc) 
end as ranks  from
(select s.userid,s.created_date,g.gold_signup_date from sales s
left join goldusers_signup g on g.userid=s.userid and created_date>=gold_signup_date) a;


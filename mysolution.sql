select * from credit_card_transactions;

-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends--
with cte as (
select SUM(amount) as 'total_spends'
from credit_card_transactions),

cte1 as (
select top 5 city, SUM(amount) as 'spends'
from credit_card_transactions
group by city
order by spends desc)

select *, concat(round(cast((spends/total_spends*100) as float),2), '%') as 'precentage_contribution'
from cte1 cross join cte;

--2- write a query to print highest spend month and amount spent in that month for each card type--
with cte as (
select card_type, DATEname(month, transaction_date) as 'monthNo', 
DATEPART(year, transaction_date) as 'yearNo', SUM(amount) as 'spends'
from credit_card_transactions
group by card_type, DATEname(month, transaction_date), DATEPART(year, transaction_date)
)

select * from (
select *,
RANK() over(partition by card_type order by spends desc) as 'rnk'
from cte) as A
where A.rnk = 1;

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)--
with cte as (
select *,
sum(amount) over(partition by card_type order by transaction_date, transaction_id) as 'cumulativeSUm'
from credit_card_transactions)

select * from (
select *,
RANK() over(partition by card_type order by cumulativeSUm) as 'rnk'
from cte where cumulativeSUm >= 1000000) as A
where A.rnk = 1;

-- 4- write a query to find city which had lowest percentage spend for gold card type--
with cte as (
select city, SUM(amount) as 'total_spends'
from credit_card_transactions
group by city),

cte1 as (
select city, card_type, SUM(amount) as 'gold_spends'
from credit_card_transactions
group by city, card_type
),

cte2 as (
select cte.city,cte.total_spends, cte1.card_type, cte1.gold_spends
from cte join cte1 on cte.city = cte1.city
where cte1.card_type = 'Gold')

select *, (gold_spends * 100/total_spends) as 'percentage_spends'
from cte2
order by percentage_spends asc;

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)--
with cte as (
select city,exp_type, SUM(amount) as 'total_spends'
from credit_card_transactions
group by city, exp_type)

,cte1 as (
select *,
RANK() over(partition by city order by total_spends desc) as 'highest_rank',
rank() over(partition by city order by total_spends) as 'lowest_rank'
from cte
)

select cte1.city,
max(case when highest_rank = 1 then cte1.exp_type end) as 'highest_expense_type',
max(case when lowest_rank = 1 then cte1.exp_type end) as 'lowest_expense_type'
from cte1
group by cte1.city;

--6- write a query to find percentage contribution of spends by females for each expense type--
with cte as (
select exp_type, SUM(amount) as 'total_spends',
SUM(case when gender = 'F' then amount else 0 end) as 'female_spends'
from credit_card_transactions
group by exp_type)

select *, (female_spends/total_spends*100) as 'female_contribution'
from cte
order by female_contribution;

-- altenative --
with cte as (
select exp_type, SUM(amount) as 'total_spends'
from credit_card_transactions
group by exp_type),

cte1 as (
select exp_type, gender, SUM(amount) as 'gender_expenses'
from credit_card_transactions
group by exp_type, gender),

cte2 as (
select cte.exp_type, cte.total_spends, cte1.gender, cte1.gender_expenses
from cte join cte1 on cte.exp_type = cte1.exp_type
where cte1.gender = 'F')

select *, (gender_expenses * 100/total_spends) as 'percentage_contribution'
from cte2 order by percentage_contribution;

--7- which card and expense type combination saw highest month over month growth in Jan-2014--
with cte as (
select card_type, exp_type, DATEpart(month, transaction_date) as 'monthname', 
DATEPART(year, transaction_date) as 'year', SUM(amount) as 'total_spends'
from credit_card_transactions
group by card_type, exp_type, DATEpart(month, transaction_date), DATEPART(year, transaction_date)),

cte1 as (
select *,
LAG(total_spends,1) over(partition by card_type, exp_type order by year, monthname) as 'prev_month_spends'
from cte) 

select top 1 *, (total_spends-prev_month_spends) as 'mom_growth' from 
cte1 where prev_month_spends is not null and year = 2014 and monthname = 1 
order by mom_growth desc;

--8- during weekends which city has highest total spend to total no of transcations ratio--
select city, SUM(amount) as 'total_spends', SUM(amount)/COUNT(*) as 'transaction_ratio'
from credit_card_transactions
where DATEPART(weekday, transaction_date) = 1 OR DATEPART(weekday, transaction_date) = 7
group by city
order by transaction_ratio desc;

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city--
with cte as (
select *,
ROW_NUMBER() over(partition by city order by transaction_date, transaction_id) as 'rn'
from credit_card_transactions)

select city, MIN(transaction_date) as 'first_transaction', MAX(transaction_date) as 'last_transaction',
DATEDIFF(day, MIN(transaction_date), MAX(transaction_date)) as 'date_diff'
from cte
where rn in (1,500)
group by city
having count(*) = 2
order by date_diff asc;

-------------------------------------------------------------------------------------------------------------------------
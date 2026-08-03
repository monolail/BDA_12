with monthlysales as (
	## 매출 집계 테이블
    select 
		date_format(paymentDate, '%Y-%m') as year_months,
        date_format(paymentDate, '%m') as month_only,
        year(paymentDate) as year_only,
        sum(amount) as revenue
	from 
		payments
	group by year_months, month_only, year_only
) ## 셀프 조인을 통한 YoY 계산
select 
	curr.year_months as '현재월',
	curr.revenue as '현재_매출' ,
    prevs.year_months as '전년_동월',
    prevs.revenue as '전년_매출',
    round((curr.revenue - prevs.revenue) / prevs.revenue * 100,2) as '성장률'
from
	monthlysales as curr
left join monthlysales as prevs
	on curr.month_only = prevs.month_only
    and curr.year_only = prevs.year_only + 1
order by '현재월' ASC;


# ------------
## concat
select concat(firstName, '/', lastName) as full_name
from employees;

## ifnull
select 
customerName,
concat(addressLine1, ',', ifnull(addressLine2, '없음')) as full_address
from customers;

## concat_ws null을 자동으로 생략하고 진행
select 
customerName,
concat_ws( ',',addressLine1 ,addressLine2) as full_address
from customers;

## substring(문자열 자르기)

select substring(productCode, 5,4) from products;

## substring * postion

select
substring(email,1,position('@' in email)-1)as user_id
from employees;

## coalesce
## 널이 아닌 첫 번째 값을 찾아내는 함수
## n개의 컬럼을 넣어서 순차적으로 감시할 수 있다.

select 
coalesce(addressLine2, addressLine1, city)
from customers;
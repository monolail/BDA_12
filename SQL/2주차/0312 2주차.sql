Select *
From orders;

select
	orderNumber,
    orderDate,
    Year(orderDate) as order_year,
    Month(orderDate) as order_month,
    DAYNAME(orderDate) as day_name
from
	orders
where Month(orderDate) = '12';

## 날짜 더하기
## 주문일로부터 +2일 뒤로 배송예정일
select
	orderNumber,
    orderDate,
    date_add(orderDate, interval 2 Day) as estimated_delivery
from
	orders;
    
## 리드 타임 배송 일정 구하기
with ship_cnt as (
select orderNumber,
	datediff(shippedDate, orderDate) as days_to_ships
from 
	orders
	)
select 
	days_to_ships,
    count(distinct orderNumber)
from ship_cnt
group by days_to_ships;

## 배송이 지연된 경우만 추출
select 
	orderNumber, orderDate, requiredDate, shippedDate
from orders
Where datediff(shippedDate,requiredDate) >0;
# ------------------------------------------

## 날짜 추출해서 비교
select
	orderNumber, orderDate, requiredDate, shippedDate
from
	orders
where datediff(shippedDate,requiredDate) > 0 ;

## 요일별 주말에 대한 데이터를 뽑아서 -> 평균 금액 구하는 것
## YoY 전월 동일대비 매출 성장률 분석
## 매달 발생하는 매출 -> 전년도와 비교
## 날짜 함수를 가지고, 전월 대비 YOY가 필요하다.
-- 날짜 포멧팅 // 그룹별 // 
## 성장률 계산 --> (현재 - 과거)

select 
	date_format(p.paymentDate,'%Y-%m') as current_month
    , sum(p.amount)
	-- ,date_format(date_sub(p.paymentDate, Interval 1 year), '%Y-%m') as prev_year_month
    -- p.amount
from payments as p
group by current_month;


## CTE를 사용해서 분해를 해야한다.
## cross join을 이용한다.
with monthlysales as (
	## 매출 집계 테이블
    select 
		date_format(paymentDate, '%Y-%m') as years_month,
        date_format(paymentDate, '%m') as month_only,
        year(paymentDate) as year_only,
        sum(amount) as revenue
	from 
		payments
	group by years_month, month_only, year_only
)
## 셀프 조인을 통한 YoY 계산
select 
*
 from monthlysales as curr;


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
    prevs.revenue as '전년_매출'
from
	monthlysales as curr
left join monthlysales as prevs
	on curr.month_only = prevs.month_only
    and curr.year_only = prevs.year_only + 1;
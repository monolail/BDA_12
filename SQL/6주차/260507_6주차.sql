## 집계
## count 
## count(*) - 마스킹된 모든 행 카운트 -> Null 포함한 모든 로우 존재 확인
## count(column)- 해당 컬럼의 값이 null 이 아닌 카운트 행만 본다.
## count(distinct columns) - 중복을 제거한 유일한 값들만 카운팅 한다.

select 
	count(*),
    count(comments),
    count(distinct customerNumber) 
-- count(*) 
from orders;

## sum/ avg

select 
	sum(quantityInStock),
    avg(buyPrice)
from products;

## 배송율 계산
## 분자 배송된 수 /분모(전체)
select 
	count(shippedDate) / count(*) * 100
from orders; 

select * from orderdetails;

## group by 

select 
	customerNumber,
    sum(amount),
    count(*)
from payments
group by customerNumber;

## Conditional Aggregation


select 
	customerNumber,
    count(case when
		status = 'Shipped' then 1 end) as shipped_count, 
	count(case when 
		status = 'Cancelled' then 1 end) as cancelled_count,
	count(case when 
		status = 'On Hold' then 1 end) as hold_count
from orders
group by customerNumber;


select count(*) from orders;

select 	
	customerNumber
from orders 
group by customerNumber;

## customers 테이블
## 각 고객의 총 주문 금액와 총 결제금액
select * from customers ;
select * from orders;
select * from orderdetails;
select * from payments;


## 필수과제 진행 
## CTE1 - sum(quantityOrdered * priceEach 전체 주문 금액)
## CTE2 - sum(amount)
## FInal - CTE1, CTE2를 join 하여 1:1 관계로 만든다.
## customerNumber, total_sales, total_amount, diff - 아웃풋 컬럼 결과 

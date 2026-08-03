## 집계
## count
## count (*) 마스킹된 모든 행 카운트 -> Null 포함한 모든 로우 존재 확인
## count (column) - 해당 커럼의 값이 null 이 아닌 카운트 행만 본다.
## count(distinct columns) - 중복 제외한 유일 값들만 헤아린다.

select count(*), count(comments), count(distinct customerNumber) from orders;

## sum / avg

select
	sum(quantityInStock),
    avg(BuyPrice)
from products;

## 배송율 계싼
## 분자 : 배송수 / 분ㅁ모 : 전체

select
	count(ShippedDate) / count(*) * 100
from orders;

select * from orderdetails;

## groupby

select 
	customerNumber,
    sum(amount),
    count(*)
from payments
group by customerNumber;

## Conditional Aggregation

select * from orders;

select 
	customerNumber,
    count(case when
		status = 'Shipped' then 1 end) as shipped_count,
	count(case when
		status = 'Cancelled' then 1 end) as cancel_count,
	count(case when
		status = 'On Hold' then 1 end) as hold_count
from orders
group by customerNumber;

## customer 테이블
## 각 고객의 총 주문 금액과 결제금액

select * from customers;

select * from payments;

## 필수과제 진행
## CTE1 - sum(quantityOrdered * priceEach) 전체 주문 금액
## CTE2 - sum(amount)
## Final - CTE1 , CTE2를 join하여 1:1관계로 만든다.

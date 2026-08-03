Select * from customers;

## 정규표현식
## Like -> 숫자가 포함한 모든 행을 찾아준다.alter
## REGPXP을 사용하여 복잡한 패터 찾기 -> REGPXP, Regular Expression

## 정규표현식, 임의의 문자하나,
## abc -> abc로 시작하는 문자열
## $문자열의 끝 -> abc$로 끝나는 문자열
## * 앞의 문자가 0번이상 반복
## + 앞의 문자가 1번이상 반복
## gpt로 검색하여 필요한 것을 사용하면된다.

select * from customers;

## 유효하지 않은 전화패턴 탐지
## 특수문자나, 잘못된 전화번는 다 정리해서 국가코드 없이 예를 들어 숫자 2~3자리 - 3~4자리 - 숫자 4자리 형식이 아닌 것은 다 잘못된 정보다라는 것을 체크

select 
	customerName,
    phone
from customers
where phone not regexp '^[0-9]{2,3}-[0-9]{3,4}-[0-9]{4}';


## 회사 메일 중 잘못된 메일 주소로 가입한 사람
select 
	employeeNumber,
    email
from employees
where email not regexp '@classicmodels\.com$';

## 배송이 단순히 늦은것이 아니라 -> 배송이 늦어 환불하는 것이 아닌가?

## 고객에 따라 세그먼트를 구분할 수 있다. VIP Regular / 하루라도 늦으면 문제가 있다. // 일반과 달리 vip는 하루만에 배송
## 패널티를 계산하여 -> 실제 주문한 금액에서 손실액을 10%가 나올 수 있다.
## 이슈가 있는 데이터를 찾아보는 것

select * from customers;

with OrderTotals as (
select orderNumber, sum(quantityOrdered * priceEach) as totalamount
from orderdetails
Group by orderNumber)
select o.orderNumber,
	c.customerName,
    -- 고객사 등급 나누기
    if(c.customerName regexp 'Gift|Doecast','Vip','Regular') as customer_tier,
    -- 배송 소요시간
    coalesce(cast(datediff(o.shippedDate,o.orderDate) as char), 'In transit' ) as shipping_days,
    case
		## 아직 배송전인데 약속 날짜가 지남
		when o.shippedDate is null and o.requiredDate < current_Date() Then 'Expedited'
        ## 아직 배송전인데 여유가 있음
        when o.shippedDate is null Then 'On schedule'
        ## VIP 하루라도 늦은 경우
        When c.customerName regexp 'Gift|Doecast' and datediff(o.shippedDate,o.requiredDate) > 0 Then 'Critical delay'
        when  datediff(o.shippedDate,o.requiredDate) > 3 Then 'Major delay'
        else 'On Time'
	end as sla_status
from orders as o
join customers as  c
on o.customerNumber = c.customerNumber
join orderTotals as ot 
on o.orderNumber = ot.orderNumber;


### KPI 테이블 만들기!
### 문자열 데이터를 사용하기 위해서 + 우리 배운 것들 + KPI 실무까지 잡아가기 위한 방법!!
### 실무에서 이렇게 쓸 수 있다 이해하고 접근하시면 좋다!

### products - buyPrice : 공급업체에서 사들인 원가 
### MSRP - 소비자 판매가 , 권장 소비자가격
### orderdetails priceEach, quantityOrdered 실제 판매 가격 수량
### 실무 KPI 쿼리 
### 제품별 마진율 계산
### 권장가 대비 실제 판매가 할인율 계산 

### 포드 차량에 대한 KPI 테이블 설계를 위한 정리 
### 제품에 대한 월간 마진율 -> 월마다 마진이 나올 것
### MSRP -> 실제 판매가 대비 할인율
### 손실 여부 ( 마진이 마이너스인가 플러스인가 ) -> 그대로 가야하나 가격 정책에 대한 인사이트를 줄 수 있다.
### 임직원 별로의 가격에 대한 손실 여부 볼 수 있다. -> 체계적인 관리까지 가능 

select * from products;
select * from orderdetails;

### KPI 테이블 만들기!
### 문자열 데이터를 사용하기 위해서 + 우리 배운 것들 + KPI 실무까지 잡아가기 위한 방법!!
### 실무에서 이렇게 쓸 수 있다 이해하고 접근하시면 좋다!

### products - buyPrice : 공급업체에서 사들인 원가 
### MSRP - 소비자 판매가 , 권장 소비자가격
### orderdetails priceEach, quantityOrdered 실제 판매 가격 수량
### 실무 KPI 쿼리 
### 제품별 마진율 계산
### 권장가 대비 실제 판매가 할인율 계산 

### 포드 차량에 대한 KPI 테이블 설계를 위한 정리 
### 제품에 대한 월간 마진율 -> 월마다 마진이 나올 것
### MSRP -> 실제 판매가 대비 할인율
### 손실 여부 ( 마진이 마이너스인가 플러스인가 ) -> 그대로 가야하나 가격 정책에 대한 인사이트를 줄 수 있다.
### 임직원 별로의 가격에 대한 손실 여부 볼 수 있다. -> 체계적인 관리까지 가능 

select * from products;
select * from orderdetails;

### products - buyPrice : 공급업체에서 사들인 원가 
### MSRP - 소비자 판매가 , 권장 소비자가격
### orderdetails priceEach, quantityOrdered 실제 판매 가격 수량

### 마진율 계산 -> 수식 -> sum(판매한 제품가 - 공급업체가 사들인 원가)/sum(판매한 제품가)
### sum((priceEach - buyPrice)) / sum(priceEach)
### MSRP 대비 할인율 -> sum((MSRP - priceEach)) / sum(MSRP)
### 손익 플래그 sum((priceEach - buyPrice) )  < 0 , -1 else 0

select * from products;

### Ford 차량에 대한 테이블 CTE
	select 
		p.productCode,
		p.productName,
		p.buyPrice,
		p.MSRP
	from products as p 
	where p.productName  LIKE '%Ford%';


with ford_products as (
	select 
		p.productCode,
		p.productName,
		p.buyPrice,
		p.MSRP
	from products as p 
	where p.productName  LIKE '%Ford%'
    ),
sales as (
	select 
		o.orderNumber,
		o.orderDate,
		Date_format(o.orderDate, '%Y-%m') as ym,
		od.productCode,
		od.quantityOrdered,
		od.priceEach
	from orders as o 
	join orderdetails as od using(orderNumber)
    join ford_products fp using(productCode)
    where o.status not in ('Cancelled')
    ),
calc as (
	select
    s.ym,
    s.productCode,
    f.productName,
    sum(s.quantityOrdered) as qty_sold,
    sum(s.quantityOrdered * s.priceEach) as gross_sales,
    sum(s.quantityOrdered * f.buyPrice) as buy_cost,
    sum(s.quantityOrdered * (s.priceEach - f.buyPrice)) as gross_profit,
    
    ## 마진율 : 이익/매출
    case
		when sum(s.quantityOrdered * s.priceEach) = 0 then NULL #예외조건 
        else sum(s.quantityOrdered * (s.priceEach - f.buyPrice)) / sum(s.quantityOrdered * s.priceEach) 
	end as margin_rate,
    
    ## 권장가 대비 할인율 (MSRP - 실제가) / MSRP
	case
		when sum(s.quantityOrdered * f.MSRP) = 0 then null #예외조건
        else sum(s.quantityOrdered * (f.MSRP - s.priceEach)) / sum(s.quantityOrdered * f.MSRP) 
	end as discount_vs_msrp,
    
	## 손실에 대한 확인
    case 
		when sum(s.quantityOrdered * (s.priceEach - f.buyPrice)) < 0 then 1 else 0
	end as is_negative
    from sales as s 
    join ford_products as f using (productCode)
    group by s.ym, s.productCode, f.productName
	) 
SELECT
  ym,
  productCode,
  productName,
  qty_sold,
  gross_sales,
  buy_cost,
  gross_profit,
  ROUND(margin_rate * 100, 2)           AS margin_pct,             -- %
  ROUND(discount_vs_msrp * 100, 2) AS discount_vs_msrp_pct,   -- %
  is_negative
FROM calc
ORDER BY ym, productName;

### 영엉사원들의 성과 지표 (사원별 성과지표)
### 연말에 대한 영업 상원 담당자 매출 실적 집계 -> 총매출, 목표매출 달성여부

select * from employees;
select * from customers;
select * from orders;
select * from orderdetails;

### 임직원아이디, 정보,-- ,달성률, 달성률에 따라 인센티브 티어도 계산할 수 있다. 1등급, 2등급, 3등급 
### CTE 임직원, 매출, 고객
with sales_rep_performance as (
select 
	e.employeeNumber,
    concat(e.firstName, ' ', e.LastName) as employeeName,
    sum(od.quantityOrdered * od.priceEach) as total_sales_amount,
    count(distinct o.orderNumber) as total_orders
from employees as e
join customers as c on e.employeeNumber = c.salesRepEmployeeNumber
join orders as o on o.customerNumber = c.customerNumber
join orderdetails as od on od.orderNumber =o.orderNumber
group by e.employeeNumber, e.firstName, e.lastName),
calc  as (
select  
	*,
    500000 as sales_target,
    (total_sales_amount / 500000) * 100 as achivement_rate
from sales_rep_performance)
select 
	employeeName,
    format(total_sales_amount, 0) as sales_value,
    round(achivement_rate,2) ach_pct,
    case
		when achivement_rate >= 100 then '1 Tier'
        when achivement_rate >= 80 then '2 Tier'
        else '3 Tier'
	end as incentive_grade
from calc
where achivement_rate >= 100;
## 목표대비 달성률  500000

select * from offices;
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

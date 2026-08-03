-- [문제]
-- 테이블 shop_events에는 고객들의 행동 로그(view, cart, purchase)가 기록되어 있습니다.
-- 각 이벤트 종류에 따라 event_properties에 담긴 상품 배열 구조가 다릅니다.

-- 다음 요구사항을 만족하는 **상품 요약 리포트(product_summary)**를 생성하는 SQL 쿼리를 작성하세요.

-- [요구사항]
-- 각 상품(sku)별로 다음 지표를 집계하세요.
-- view_cnt: 해당 상품을 조회(view)한 총 횟수
-- cart_cnt: 해당 상품을 장바구니(cart)에 담은 총 횟수
-- buy_cnt: 해당 상품을 실제 구매(purchase)한 총 수량 (주의: 이벤트 발생 횟수가 아니라 구매 수량(qty)의 합계여야 함)
-- total_revenue: 해당 상품을 통해 벌어들인 총 구매 금액을 계산하세요. ({수량(qty)} x(price)}

## 여기서

select * from shop_events;

with flattened_json_events as (
select 
	e.event_name,
     jt.sku,
     coalesce(jt.qty, 1) as qty,
     coalesce(jt.price,0.0) as price
from shop_events as e
join json_table(e.event_properties, '$.items[*]'
	COLUMNS(
 		sku varchar(40) path '$.sku',
         qty int path '$.qty',
         price decimal(10,2) path '$.price'
         )
 	) as jt
)

select 
	sku,
    count(case when event_name = 'view' then 1 end) as view_cnt,
    count(case when event_name = 'add_to_cart' then 1 end) as cart_cnt,
    sum(case when event_name = 'purchase' then qty else 0 end) as buy_cnt,
    sum(case when event_name = 'purchase' then qty*price else 0 end) as total_revenue
from flattened_json_events
group by sku;

## 필수과제
## view_cnt, cart_cnt가 모두 0이 나오는데, 이것도 0이 안나오게 하기 위해선 커리를 어떻게 짜야할까?

with flattened_json_events as (
    select 
        e.event_name,
        coalesce(jt.sku, e.event_properties->>'$.item.sku', e.event_properties->>'$.sku') as sku,
        coalesce(jt.qty, e.event_properties->>'$.item.qty', e.event_properties->>'$.qty', 1) as qty,
        coalesce(jt.price, e.event_properties->>'$.item.price', e.event_properties->>'$.price', 0.0) as price
    from shop_events as e
    left join json_table(e.event_properties, '$.items[*]'
        columns(
            sku varchar(40) path '$.sku',
            qty int path '$.qty',
            price decimal(10,2) path '$.price'
        )
    ) as jt on 1=1
)
select 
    sku,
    count(case when event_name = 'view_item' then 1 end) as view_cnt,
    count(case when event_name = 'add_to_cart' then 1 end) as cart_cnt,
    sum(case when event_name = 'purchase' then qty else 0 end) as buy_cnt,
    sum(case when event_name = 'purchase' then qty * price else 0 end) as total_revenue
from flattened_json_events
where sku is not null
group by sku;
## 필수과제 끝




select * from payments;

## Row-number
select 
	row_number() over(order by amount desc) as num,
    customerNumber,
    amount
from (
	select customerNumber, sum(amount) as amount
    from payments
    group by customerNumber
    ) as x;
    
## 동점자 기준
select 
	row_number() over(order by amount desc, customerNumber desc) as num,
    customerNumber,
    amount
from (
	select customerNumber, sum(amount) as amount
    from payments
    group by customerNumber
    ) as x;
    
## rank / desc_rank
select 
	dense_rank() over(order by amount desc, customerNumber desc) as num,
    customerNumber,
    amount
from (
	select customerNumber, sum(amount) as amount
    from payments
    group by customerNumber
    ) as x;
    
## ntile

select 
	row_number() over(order by amount desc) as num,
    orderNumber,
    amount
from (
	select orderNumber, sum(quantityOrdered) as amount
    from orderdetails
    group by orderNumber
    ) as x;
    

## rank 문제 풀기
## 오더 테이블에서 customerNumber별로 최근 사건들만 추출하기

select * from orders

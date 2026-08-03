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

## customerNumber partition by, orderdaate 내림차순, 오른차순 정렬해서 내리면 된다. (순위 컬럼 부여)

with lastestOrder as (
select orderNumber,
		orderdate,
        status,
        customerNumber,
        row_number() over(partition by customerNumber order by orderdate desc) as lastest_rank
from orders)
select 
	customerNumber,
    orderNumber,
    orderDate,
    status
from lastestOrder
where
	lastest_rank = 1;


## 연속 굼매한 유저 찾기
## order 테이블의 고객의 구매 일자가 있는데, 하루에 여러 번 구매했을 수도 있고, 3일 이상 연속으로 (consecutive)구매한 이력이 있는 유저는?
select * from orders;

## 연속성 문제
## --> 3일 이상 날짜가 +1이 되면 순위가 +1이 된다.
## 연속된 데이터라고 하면, diff 상태가 되어야한다.
##1일 1순위 - 0
##2일 2순위 - 0
##3일 3순위 - 0
##5일 4순위 - 1

## 하루에 여러 번 구매을 했을 수 있의니, --> 유니크하게 날짜 기준 하나의 date 집계
with uniqueDates as (
select 
	distinct customerNumber,
    cast(orderDate as Date) as order_date
from
	orders),
RankDates as (
	select
		customerNumber,
        order_date,
        dense_rank() over(partition by customerNumber order by order_date desc) as rnk
	from UniqueDates
),
GroupedStreaks as (
	select
		customerNumber,
        order_date,
        date_sub(order_date, interval rnk day) as streak_group
	from RankDates
)
select 
	customerNumber,
    min(order_date) as streak_start,
    max(order_date) as  streak_end,
    count(*) as consecutive_days
from GroupedStreaks
group by 
	customerNumber, streak_group
having count(*) >=3;

## user 클릭, 스크롤 -> event time매칭
## 유저가 행동을 멈추고 --> 30분 이상 다시 재접속을 하면 , seesion_id가 새롭게 만들어진다.
## 각 유저별로 세션 번호를 매기고 각 세션의 시작과 체류시간을 알고싶다.
## lag, lead

## lag 과거 시간을 갖고ㅗㅇㄴ다.
## 30q분 이상 지난다면 gap 새로운 세션이란 것을 알린다.
## 체류시간을 하기 위해서는 누적합 -> sum(event_time) partition by user_id order by event_time (체류시간)
## 마지막 집계 -> 세션 그룹 바이 -> min, max, order by

select * from customers;


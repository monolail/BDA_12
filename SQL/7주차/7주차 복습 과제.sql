select * from shop_events;

## event name 별 유저들의 수 / event_name 별 이벤트 수를 보여라

select event_name,count(distinct user_id)
from shop_events
group by event_name;

select event_name,count(event_id)
from shop_events
group by event_name;

## 퍼널 데이터 분석
## case when을 통해 사용 퍼널 세션 수를 계산해보자.

select * from shop_events;

select
	count(distinct case when event_name = 'app_open' then session_id end) as step1_app_open,
    count(distinct case when event_name = 'view_item' then session_id end )as step2_view_open,
    count(distinct case when event_name = 'add_cart' then session_id end )as step3_add_to_cart,
    count(distinct case when event_name = 'purchase' then session_id end )as step4_purchase,
    # 구매 전환 세션율
    round(count(distinct case when event_name = 'purchase' then session_id end )/
	count(distinct case when event_name = 'add_cart' then session_id end )*100,2) as purchase_ratio
from shop_events;

## evnet_name 별로 sku 정보들을 분석한다.
## product_summary
## 상품별 집계 -> view_cnt, cart_cnt, buy_cnt
## sum(구매한 금액이 얼마인지?)

select *
from shop_events;

-- event_name 별 유저 수
select
    event_name,
    count(distinct user_id) as user_cnt
from shop_events
group by event_name
order by user_cnt desc;

-- event_name 별 이벤트 발생 수
select
    event_name,
    count(*) as event_cnt
from shop_events
group by event_name
order by event_cnt desc;

-- 퍼널 데이터 분석
select
    count(distinct case
        when event_name = 'app_open'
        then session_id
    end) as app_open,

    count(distinct case
        when event_name = 'view_item'
        then session_id
    end) as view_item,

    count(distinct case
        when event_name = 'add_to_cart'
        then session_id
    end) as add_to_cart,

    count(distinct case
        when event_name = 'purchase'
        then session_id
    end) as 'purchase',

    -- 앱 오픈 -> 상품 조회 전환율
    round(
        count(distinct case
            when event_name = 'view_item'
            then session_id
        end) /
        count(distinct case
            when event_name = 'app_open'
            then session_id
        end)
        * 100, 2) as open_to_view_ratio,

    -- 상품 조회 -> 장바구니 전환율
    round(
        count(distinct case
            when event_name = 'add_to_cart'
            then session_id
        end)/
        count(distinct case
            when event_name = 'view_item'
            then session_id
        end)
        * 100, 2) as view_to_cart_ratio,

    -- 장바구니 -> 구매 전환율
    round(
        count(distinct case
            when event_name = 'purchase'
            then session_id
        end) /
        count(distinct case
            when event_name = 'add_to_cart'
            then session_id
        end)
        * 100,2) as purchase_ratio,

    -- 전체 구매 전환율
    round(
        count(distinct case
            when event_name = 'purchase'
            then session_id
        end) /
        count(distinct case
            when event_name = 'app_open'
            then session_id
        end)* 100, 2) as total_purchase_ratio
from shop_events;
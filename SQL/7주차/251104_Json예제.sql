-- (필요 시) 작업할 DB 명시
-- USE classicmodels;

-- 0) 기존 테이블 제거
DROP TABLE IF EXISTS shop_events;

-- 1) 테이블 생성
CREATE TABLE shop_events (
  event_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  session_id   VARCHAR(16) NOT NULL,
  event_name   VARCHAR(32) NOT NULL,
  event_time   DATETIME(3) NOT NULL,
  event_properties JSON NOT NULL,

  INDEX ix_event_time (event_time),
  INDEX ix_event_name (event_name),

  -- 자주 쓰는 경로는 생성 칼럼 + 인덱스
  device  VARCHAR(16)
    GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(event_properties, '$.device'))) STORED,
  country VARCHAR(2)
    GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(event_properties, '$.geo.country'))) STORED,

  INDEX ix_device (device),
  INDEX ix_country (country),

  CHECK (JSON_VALID(event_properties))
) ENGINE=InnoDB;

-- 2) 샘플 데이터 삽입 (CTE를 INSERT ... SELECT에 직접 붙임)
INSERT INTO shop_events (user_id, session_id, event_name, event_time, event_properties)
WITH RECURSIVE
-- 2.1 세션 번호 1..380 생성
seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 380
),
-- 2.2 세션별 기본 특성 생성
base AS (
  SELECT
      n                                AS session_no,
      (100 + (n % 50))                 AS user_id,                 -- 50명 유저
      LPAD(CONV(n, 10, 16), 8, '0')    AS session_id,              -- 8자리 hex
      ((n*37) % 100) < 90              AS has_view,                -- 90%
      ((n*73) % 100) < 60              AS has_cart,                -- 60%
      ((n*97) % 100) < 40              AS has_purchase,            -- 40%

      /* 기초 시간: 기준 + 분/초 산포 (안전하게 CAST + INTERVAL) */
      CAST('2025-10-01 09:00:00' AS DATETIME)
        + INTERVAL FLOOR(((n*17) % (5*24*60))) MINUTE
        + INTERVAL ((n*29) % 45) SECOND AS base_time,

      CASE n % 3
        WHEN 0 THEN 'ios'
        WHEN 1 THEN 'android'
        ELSE 'web'
      END AS device,

      CONCAT('1.', (n % 4), '.', (n % 10)) AS app_ver,

      CASE n % 4
        WHEN 0 THEN 'KR' WHEN 1 THEN 'KR' WHEN 2 THEN 'US' ELSE 'JP'
      END AS country,

      CASE n % 4
        WHEN 0 THEN 'Seoul' WHEN 1 THEN 'Busan' WHEN 2 THEN 'LA' ELSE 'Tokyo'
      END AS city
  FROM seq
),
-- 2.3 상품 카탈로그(간단)
products AS (
  SELECT 'A100' AS sku,  9.90 AS price UNION ALL
  SELECT 'A200',        14.50 UNION ALL
  SELECT 'B100',         5.25 UNION ALL
  SELECT 'C300',        29.00 UNION ALL
  SELECT 'D400',        49.00
),
-- 2.4 세션별 대표 상품(뷰/카트용 1개)
pick_item AS (
  SELECT
    b.session_no,
    CASE (b.session_no % 5)
      WHEN 0 THEN 'A100' WHEN 1 THEN 'A200' WHEN 2 THEN 'B100' WHEN 3 THEN 'C300' ELSE 'D400'
    END AS sku1
  FROM base b
),
-- 2.5 구매 이벤트용 추가 상품 후보
pick_more AS (
  SELECT
    b.session_no,
    (((b.session_no*11) % 100) < 50) AS has_item2,
    (((b.session_no*19) % 100) < 25) AS has_item3,
    CASE ((b.session_no+1) % 5)
      WHEN 0 THEN 'A100' WHEN 1 THEN 'A200' WHEN 2 THEN 'B100' WHEN 3 THEN 'C300' ELSE 'D400'
    END AS sku2,
    CASE ((b.session_no+2) % 5)
      WHEN 0 THEN 'A100' WHEN 1 THEN 'A200' WHEN 2 THEN 'B100' WHEN 3 THEN 'C300' ELSE 'D400'
    END AS sku3
  FROM base b
),
-- 2.6 이벤트들 생성
events AS (
  /* (1) app_open : 항상 존재 */
  SELECT
    b.user_id,
    b.session_id,
    'app_open' AS event_name,
    b.base_time AS event_time,
    JSON_OBJECT(
      'device', b.device,
      'app_ver', b.app_ver,
      'geo', JSON_OBJECT('country', b.country, 'city', b.city)
    ) AS event_properties
  FROM base b

  UNION ALL

  /* (2) view_item : 90% */
  SELECT
    b.user_id,
    b.session_id,
    'view_item' AS event_name,
    b.base_time + INTERVAL 5 SECOND AS event_time,
    JSON_OBJECT(
      'device', b.device,
      'app_ver', b.app_ver,
      'geo', JSON_OBJECT('country', b.country, 'city', b.city),
      'item', JSON_OBJECT(
        'sku',   pi.sku1,
        'qty',   1,
        'price', (SELECT p.price FROM products p WHERE p.sku = pi.sku1)
      )
    ) AS event_properties
  FROM base b
  JOIN pick_item pi ON pi.session_no = b.session_no
  WHERE b.has_view

  UNION ALL

  /* (3) add_to_cart : 60% (view_item 있었던 세션만) */
  SELECT
    b.user_id,
    b.session_id,
    'add_to_cart' AS event_name,
    b.base_time + INTERVAL 15 SECOND AS event_time,
    JSON_OBJECT(
      'device', b.device,
      'app_ver', b.app_ver,
      'geo', JSON_OBJECT('country', b.country, 'city', b.city),
      'item', JSON_OBJECT(
        'sku',   pi.sku1,
        'qty',   1 + (b.session_no % 3),  -- 1~3개
        'price', (SELECT p.price FROM products p WHERE p.sku = pi.sku1)
      )
    ) AS event_properties
  FROM base b
  JOIN pick_item pi ON pi.session_no = b.session_no
  WHERE b.has_view AND b.has_cart

  UNION ALL

  /* (4) purchase : 40% (add_to_cart 있었던 세션만)
       items 는 JSON 배열(1~3개), NULL 없이 붙이기 위해 JSON_MERGE_PRESERVE 사용 */
  SELECT
    b.user_id,
    b.session_id,
    'purchase' AS event_name,
    b.base_time + INTERVAL 45 SECOND AS event_time,
    JSON_OBJECT(
      'device', b.device,
      'app_ver', b.app_ver,
      'geo', JSON_OBJECT('country', b.country, 'city', b.city),
      'items',
        JSON_MERGE_PRESERVE(
          JSON_ARRAY(
            JSON_OBJECT(
              'sku',   pi.sku1,
              'qty',   1 + ((b.session_no*3) % 2),  -- 1~2
              'price', (SELECT p.price FROM products p WHERE p.sku = pi.sku1)
            )
          ),
          IF(pm.has_item2,
             JSON_ARRAY(
               JSON_OBJECT(
                 'sku',   pm.sku2,
                 'qty',   1 + ((b.session_no*5) % 2),  -- 1~2
                 'price', (SELECT p.price FROM products p WHERE p.sku = pm.sku2)
               )
             ),
             JSON_ARRAY()
          ),
          IF(pm.has_item3,
             JSON_ARRAY(
               JSON_OBJECT(
                 'sku',   pm.sku3,
                 'qty',   1 + ((b.session_no*7) % 2),  -- 1~2
                 'price', (SELECT p.price FROM products p WHERE p.sku = pm.sku3)
               )
             ),
             JSON_ARRAY()
          )
        )
    ) AS event_properties
  FROM base b
  JOIN pick_item pi ON pi.session_no = b.session_no
  JOIN pick_more pm ON pm.session_no = b.session_no
  WHERE b.has_view AND b.has_cart AND b.has_purchase
)
SELECT user_id, session_id, event_name, event_time, event_properties
FROM events
ORDER BY event_time, session_id, event_name
LIMIT 1000;

-- 3) 확인
SELECT COUNT(*) AS inserted_rows FROM shop_events;

SELECT event_name, COUNT(*) AS cnt
FROM shop_events
GROUP BY event_name
ORDER BY cnt DESC;

SELECT event_id, user_id, session_id, event_name, event_time, device, country
FROM shop_events
ORDER BY event_time
LIMIT 5;

select *from customers;

## classicmodels -> 앱을 만들었다!
## 우리 앱의 유저들의 로그 데이터를 살펴보자
## ga4 를 사용해서 데이터를 적재한다.

## event_name 
## app_open -> view_item -> add_to_cart -> purchase
## event_time event_name에 대한 시
select * from shop_events;


## 데이터에 대한 추출
select 
	event_id,
    user_id,
    session_id,
    event_properties
from
	shop_events;
    
## json 파일 추출
## json_extract 

select * from shop_events;

select
	user_id,
	event_id,
    event_name,
    JSON_EXTRACT(event_properties, '$.device') as device_raw, 
    JSON_EXTRACT(event_properties, '$.geo.country') as country_raw
from
	shop_events;
    
select 
	user_id,
	event_properties -> '$.device' as device_raw
from
	shop_events;
    
    
## select 데이터를 추출하여 속성 형태로 추출하는 것을 연습함

## JSON 값 기준으로 필터링을 해보자!
## Where 조건으로 진행

## iOS 유저들만 추출하여 이벤트가 몇 개 일어났는지 분석
## json_unquote(json_extract(~~))
select * from shop_events;


## 다시 문법 확인했습니다.
# 두 개 모두 같이 써야해요!
SELECT
  user_id,
  JSON_UNQUOTE(JSON_EXTRACT(event_properties, '$.device')) AS device
FROM shop_events
WHERE JSON_UNQUOTE(JSON_EXTRACT(event_properties, '$.device')) = 'ios';
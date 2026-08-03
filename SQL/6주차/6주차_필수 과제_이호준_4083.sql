## 필수과제 진행
## CTE1 - sum(quantityOrdered * priceEach) 전체 주문 금액
## CTE2 - sum(amount)
## Final - CTE1 , CTE2를 join하여 1:1관계로 만든다.

WITH CTE1 AS (
    # 전체 주문 금액 계산
    select 
        o.customerNumber,
        sum(od.quantityOrdered * od.priceEach) as total_sales
    from orders o
    join orderdetails od
        on o.orderNumber = od.orderNumber
    group by o.customerNumber
),

CTE2 AS (
    # 전체 결제 금액 계산
    select
        customerNumber,
        sum(amount) as total_amount
    from payments
    group BY customerNumber
)

select
    c1.customerNumber,
    c1.total_sales,
    c2.total_amount,
    ## 전체 판매액에서 양을 뺀값 컬럼 - diff
    (c1.total_sales - c2.total_amount) as diff
from CTE1 c1
join CTE2 c2
    on c1.customerNumber = c2.customerNumber;
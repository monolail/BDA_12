select count(customerNumber), count(distinct customerNumber) from customers;
select * from customers;

## 전체 상품 중에 평균 구매가보다 비싼 제품들의 이름과 가격을 추출해 주세요!

SELECT productName, buyPrice, quantityInStock
FROM products
WHERE quantityInStock < 1000
ORDER BY quantityInStock DESC;


SELECT 
    productName, 
    buyPrice
FROM 
    products
WHERE 
    buyPrice > (SELECT AVG(buyPrice) FROM products)
ORDER BY 
    buyPrice DESC;
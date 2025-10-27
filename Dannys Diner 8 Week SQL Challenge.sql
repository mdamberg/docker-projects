/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

Use [Danny's Diner]
GO

----------------------------------------------------------------------------------------------------------
-- 1). What is the total amount each customer spent at the restaurant?
----------------------------------------------------------------------------------------------------------

Select
	s.customer_id,
	SUM(m.price) as Amt_per_Customer
FROM [dbo].[sales] s JOIN [dbo].[menu] m ON
	s.product_id = m.product_id
GROUP BY s.customer_id

--A: 76
--B: 74
--C: 36

----------------------------------------------------------------------------------------------------------
-- 2. How many days has each customer visited the restaurant?
----------------------------------------------------------------------------------------------------------

Select
	Customer_id,
	Count(Distinct Order_date) as day_count
FROM [dbo].[sales]
GROUP BY Customer_id

--A: 4
--B: 6
--C: 2


----------------------------------------------------------------------------------------------------------
-- 3. What was the first item from the menu purchased by each customer?
----------------------------------------------------------------------------------------------------------
WITH ranking AS
(
    SELECT
        s.customer_id,
        m.product_name,
        s.Order_date,
        DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY s.Order_date ASC) AS date_rank
    FROM [dbo].[sales] s
    JOIN [dbo].[menu] m ON s.product_id = m.product_id
)

SELECT
    customer_id,
    product_name,
    Order_date
FROM ranking 
WHERE date_rank = 1
GROUP BY customer_id, product_name, Order_date;

----------------------------------------------------------------------------------------------------------
-- 4.  What is the most purchased item on the menu and how many times was it purchased by all customers?
----------------------------------------------------------------------------------------------------------


SELECT
	TOP 1 M.PRODUCT_NAME,
	COUNT(S.PRODUCT_ID) AS TOTAL_COUNT
FROM SALES S JOIN  MENU M ON
	S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY M.PRODUCT_NAME
ORDER BY TOTAL_COUNT DESC

----------------------------------------------------------------------------------------------------------
-- 5. Which item was the most popular for each customer?
----------------------------------------------------------------------------------------------------------

WITH RANKING AS
(
SELECT
	CUSTOMER_ID,
	PRODUCT_NAME,
	COUNT(S.PRODUCT_ID) AS TOTAL_COUNT,
	DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(S.PRODUCT_ID) DESC) AS COUNT_RANK
FROM SALES S JOIN  MENU M ON
	S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY CUSTOMER_ID, PRODUCT_NAME
)

SELECT
	CUSTOMER_ID,
	PRODUCT_NAME,
	TOTAL_COUNT
FROM RANKING
WHERE COUNT_RANK = 1

----------------------------------------------------------------------------------------------------------
-- 6. Which item was purchased first by the customer after they became a member?
----------------------------------------------------------------------------------------------------------

WITH RANKING AS 
(
SELECT
	S.CUSTOMER_ID, 
	M.PRODUCT_NAME,
	ME.JOIN_DATE,
	S.ORDER_DATE,
	ROW_NUMBER() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE) AS DATE_RANK
FROM SALES S JOIN MENU M ON
	S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS ME ON
	S.CUSTOMER_ID = ME.CUSTOMER_ID
WHERE S.ORDER_DATE > ME.JOIN_DATE
GROUP BY S.CUSTOMER_ID, M.PRODUCT_NAME, S.ORDER_DATE, ME.JOIN_DATE
)

SELECT
	CUSTOMER_ID,
	ORDER_DATE,
	PRODUCT_NAME
FROM RANKING
WHERE DATE_RANK = 1


----------------------------------------------------------------------------------------------------------
-- 7. Which item was purchased just before the customer became a member?
----------------------------------------------------------------------------------------------------------

WITH RANKING AS 
(
SELECT
	S.CUSTOMER_ID, 
	ME.JOIN_DATE,
	S.ORDER_DATE,
	M.PRODUCT_NAME,
	DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE DESC) AS DATE_RANK
FROM SALES S JOIN MEMBERS ME ON
	S.CUSTOMER_ID = ME.CUSTOMER_ID
JOIN MENU M ON
	S.PRODUCT_ID = M.PRODUCT_ID
WHERE S.ORDER_DATE < ME.JOIN_DATE
)

SELECT
	CUSTOMER_ID,
	ORDER_DATE,
	PRODUCT_NAME
FROM RANKING 
WHERE DATE_RANK = 1



----------------------------------------------------------------------------------------------------------
-- 8. What is the total items and amount spent for each member before they became a member?
----------------------------------------------------------------------------------------------------------

SELECT
	S.CUSTOMER_ID,
	COUNT(DISTINCT S.PRODUCT_ID) AS TOTAL_PRODUCTS,
	SUM(M.PRICE) AS TOTAL_PRICE
FROM SALES S JOIN MENU M ON
	S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS ME ON 
	S.CUSTOMER_ID = ME.CUSTOMER_ID
WHERE ORDER_DATE < JOIN_DATE 
GROUP BY S.CUSTOMER_ID


----------------------------------------------------------------------------------------------------------------------------------------
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
----------------------------------------------------------------------------------------------------------------------------------------
WITH CTE AS
(
Select
	S.CUSTOMER_ID,
	M.PRODUCT_NAME,
	M.PRICE,
	CASE WHEN product_name = 'sushi' then PRICE * 10 * 2
		 ELSE PRICE * 10
			END AS value
FROM SALES S JOIN MENU M ON
	S.PRODUCT_ID = M.PRODUCT_ID
)

SELECT
	CUSTOMER_ID,
	SUM(VALUE) AS TOTAL_POINTS
FROM CTE
GROUP BY CUSTOMER_ID



--------------------------------------------------------------------------------------------------------------------------------------------
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
--------------------------------------------------------------------------------------------------------------------------------------------

WITH DATES AS 
(
SELECT
	*,
	DATEADD(DAY, 6, JOIN_DATE) AS VALID_DATE,
	EOMONTH('2021-01-31') AS ENDOFMONTH
FROM MEMBERS
)

SELECT
	S.CUSTOMER_ID,
	SUM(CASE
		WHEN M.PRODUCT_ID = 1 THEN M.PRICE * 20
		WHEN S.ORDER_DATE BETWEEN D.JOIN_DATE AND D.VALID_DATE THEN M.PRICE * 20
		ELSE M.PRICE * 10
		END) AS TOTAL_POINTS
FROM DATES D 
JOIN SALES S ON
	D.CUSTOMER_ID = S.CUSTOMER_ID
JOIN MENU M ON
	S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS ME ON 
	S.CUSTOMER_ID = ME.CUSTOMER_ID
WHERE S.ORDER_DATE <= ENDOFMONTH
GROUP BY S.CUSTOMER_ID
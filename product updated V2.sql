SELECT *
FROM product.product;

-- Taking on this dataset to analyze whether or not selling a banner placements to a partner will be worthwhile
-- Wanting to analyze the effectiveness of the banners in generating sales

-- Finding the conversion rate between people who were shown a banner and those who clicked on it

WITH cte AS (SELECT
	SUM(CASE WHEN title = 'banner_click' THEN 1 END) total_banner_click,
    SUM(CASE WHEN title = 'banner_show' THEN 1 END) total_banner_show
FROM product.product)
SELECT (total_banner_click /total_banner_show) * 100
FROM cte;

-- Using a very similar query to find the conversion rate between those who were shown the banner and then ordered

WITH cte AS (SELECT
	SUM(CASE WHEN title = 'order' THEN 1 END) total_order,
    SUM(CASE WHEN title = 'banner_show' THEN 1 END) total_banner_show
FROM product.product)
SELECT (total_order /total_banner_show) * 100
FROM cte;

-- Lastly we will find the conversion rate between people who clicked, and people who ordered

WITH cte AS (SELECT
	SUM(CASE WHEN title = 'order' THEN 1 END) total_order,
    SUM(CASE WHEN title = 'banner_click' THEN 1 END) total_banner_click
FROM product.product)
SELECT (total_order /total_banner_click) * 100
FROM cte;

SELECT *
FROM product.product
ORDER BY user_id, time;

-- Creating a query that finds users who clicked on a banner for a specific product and then later went back and bought that product
-- This is an imperfect means to guage click-to-order conversion due to the lack of knowing whether or not they used the original link...
-- ... when making the purchase but this acts as a means to perform that operation 

WITH B AS (SELECT 
	*
FROM product.product
WHERE title = 'banner_click'
ORDER BY user_id, time),
O AS (SELECT 
	*
FROM product.product
WHERE title = 'order'
ORDER BY user_id, time)

SELECT 
	B.user_id,
    B.product,
    O.product,
    B.time AS ClickDay,
    O.time AS OrderDay,
    B.title,
    O.title
FROM B
JOIN O ON B.user_id = O.user_id AND B.product = O.product
WHERE B.time < O.time
ORDER BY B.order_id, B.time, O.time;

-- Finding the total number of customers who purchased something versus didn't purchase something yet saw a banner

SELECT
    target,
    COUNT(DISTINCT user_id) AS DidNotBuy
FROM product.product
WHERE target = 0
UNION
SELECT
    target,
    COUNT(DISTINCT user_id) AS DidBuy
FROM product.product
WHERE target = 1;

-- finding the average number of banners that are shown to customers before they make a purchase
-- combach to this one
SELECT
	user_id,
    time,
    title,
    DENSE_RANK() OVER(PARTITION BY user_id, title ORDER BY user_id)
FROM product.product
WHERE title IN ('banner_show', 'order') 
ORDER BY user_id, time;

-- Which site version led to the most clicks/sales

SELECT
	COUNT(CASE WHEN site_version = 'desktop' AND title = 'banner_click' THEN 1 END) AS DesktopClicks,
    COUNT(CASE WHEN site_version = 'desktop' AND title = 'order' THEN 1 END) AS DesktopSales,
    COUNT(CASE WHEN site_version = 'mobile' AND title = 'banner_click' THEN 1 END) AS MobileClicks,
    COUNT(CASE WHEN site_version = 'mobile' AND title = 'order' THEN 1 END) MobileSales
FROM product.product;

-- Finding which products led to the most clicks and sales regardless of site version

SELECT 
	COUNT(CASE WHEN product = 'sneakers' AND title = 'banner_click' THEN 1 END) AS SneakerClicks,
    COUNT(CASE WHEN product = 'sneakers' AND title = 'order' THEN 1 END) AS SneakerSales,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'banner_click' THEN 1 END) AS SportsNutritionClicks,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'order' THEN 1 END) SportsNutritionSales,
    COUNT(CASE WHEN product = 'company' AND title = 'banner_click' THEN 1 END) CompanyClicks,
    COUNT(CASE WHEN product = 'company' AND title = 'order' THEN 1 END) CompanySales,
    COUNT(CASE WHEN product = 'accessories' AND title = 'banner_click' THEN 1 END) AS AccessoriesClicks,
    COUNT(CASE WHEN product = 'accessories' AND title = 'order' THEN 1 END) AccessoriesSales,
    COUNT(CASE WHEN product = 'clothes' AND title = 'banner_click' THEN 1 END) AS ClothesClicks,
    COUNT(CASE WHEN product = 'clothes' AND title = 'order' THEN 1 END) ClothesSales
FROM product.product;

-- Finding out who clicked on a banner and within a month purchased the same product shown on the banner
	
SELECT	
	p.user_id,
    p.title titleclick,
    x.title titleorder,
    p.product,
    p.time timeclick,
    x.time timeorder
FROM product.product p
INNER JOIN (SELECT
	user_id,
    title,
    product,
    time
FROM product.product
WHERE title = 'order') x ON p.user_id = x.user_id AND p.product = x.product AND DATEDIFF (p.time, x.time) <1
WHERE p.title = 'banner_click' AND x.title = 'order';

-- Finding the above queries number of clicks/orders

WITH cte AS (SELECT	
	p.user_id,
    p.title titleclick,
    x.title titleorder,
    p.product,
    p.time timeclick,
    x.time timeorder
FROM product.product p
INNER JOIN (SELECT
	user_id,
    title,
    product,
    time
FROM product.product
WHERE title = 'order') x ON p.user_id = x.user_id AND p.product = x.product AND DATEDIFF (p.time, x.time) <1
WHERE p.title = 'banner_click' AND x.title = 'order')

SELECT 
	COUNT(user_id)
FROM cte;

-- Finding the total number of orders to compare between orders purchased from clicks and ones which aren't correlated with a banner click

SELECT
	COUNT(CASE WHEN title = 'order' THEN 1 END) Total_Orders
FROM product.product;

-- Finding the best times for banners to be shown based on clicks for both mobile and desktop users

WITH cte AS (SELECT
	user_id,
	title,
    site_version,
    time,
    CASE
		WHEN HOUR(time) BETWEEN 4 AND 11 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'MidDay'
        WHEN HOUR(time) BETWEEN 18 AND 23 OR HOUR(time) BETWEEN 0 AND 3 THEN 'NightTime'
        END AS 'DesktopClickTime'
FROM product.product
WHERE site_version = 'desktop' AND title = 'banner_click'
ORDER BY time)
SELECT
	COUNT(CASE WHEN DesktopClickTime = 'Morning' THEN 1 END) MorningClicks,
    COUNT(CASE WHEN DesktopClickTime = 'MidDay' THEN 1 END) MidDayClicks,
    COUNT(CASE WHEN DesktopClickTime = 'NightTime' THEN 1 END) NightTimeClicks
FROM cte;


WITH cte AS (SELECT
	user_id,
	title,
    site_version,
    time,
    CASE
		WHEN HOUR(time) BETWEEN 4 AND 11 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'MidDay'
        WHEN HOUR(time) BETWEEN 18 AND 23 OR HOUR(time) BETWEEN 0 AND 3 THEN 'NightTime'
        END AS 'MobileClickTime'
FROM product.product
WHERE site_version = 'mobile' AND title = 'banner_click'
ORDER BY time)
SELECT
	COUNT(CASE WHEN MobileClickTime = 'Morning' THEN 1 END) MorningClicks,
    COUNT(CASE WHEN MobileClickTime = 'MidDay' THEN 1 END) MidDayClicks,
    COUNT(CASE WHEN MobileClickTime = 'NightTime' THEN 1 END) NightTimeClicks
FROM cte;

WITH cte AS (SELECT
	user_id,
	title,
    site_version,
    time,
    CASE
		WHEN HOUR(time) BETWEEN 4 AND 11 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'MidDay'
        WHEN HOUR(time) BETWEEN 18 AND 23 OR HOUR(time) BETWEEN 0 AND 3 THEN 'NightTime'
        END AS 'DesktopOrderTime'
FROM product.product
WHERE site_version = 'desktop' AND title = 'order'
ORDER BY time)
SELECT
	COUNT(CASE WHEN DesktopOrderTime = 'Morning' THEN 1 END) MorningOrders,
    COUNT(CASE WHEN DesktopOrderTime = 'MidDay' THEN 1 END) MidDayOrders,
    COUNT(CASE WHEN DesktopOrderTime = 'NightTime' THEN 1 END) NightTimeOrders
FROM cte;

WITH cte AS (SELECT
	user_id,
	title,
    site_version,
    time,
    CASE
		WHEN HOUR(time) BETWEEN 4 AND 11 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'MidDay'
        WHEN HOUR(time) BETWEEN 18 AND 23 OR HOUR(time) BETWEEN 0 AND 3 THEN 'NightTime'
        END AS 'MobileOrderTime'
FROM product.product
WHERE site_version = 'mobile' AND title = 'order'
ORDER BY time)
SELECT
	COUNT(CASE WHEN MobileOrderTime = 'Morning' THEN 1 END) MorningOrders,
    COUNT(CASE WHEN MobileOrderTime = 'MidDay' THEN 1 END) MidDayOrders,
    COUNT(CASE WHEN MobileOrderTime = 'NightTime' THEN 1 END) NightTimeOrders
FROM cte;


-- Finding how many people were shown, clicked on, and ordered the banner for each different product

SELECT
	COUNT(CASE WHEN product = 'company' AND title = 'banner_show' THEN 1 END) CompanyBannerShown,
    COUNT(CASE WHEN product = 'company' AND title = 'banner_click' THEN 1 END) CompanyBannerClicks,
    COUNT(CASE WHEN product = 'accessories' AND title = 'banner_show' THEN 1 END) AccessoryBannerShown,
    COUNT(CASE WHEN product = 'accessories' AND title = 'banner_click' THEN 1 END) AccessoryClicks,
    COUNT(CASE WHEN product = 'accessories' AND title = 'order' THEN 1 END) AccessoryOrder,
    COUNT(CASE WHEN product = 'clothes' AND title = 'banner_show' THEN 1 END) ClothesBannerShown,
    COUNT(CASE WHEN product = 'clothes' AND title = 'banner_click' THEN 1 END) ClothesClicks,
    COUNT(CASE WHEN product = 'clothes' AND title = 'order' THEN 1 END) ClothesOrder,
    COUNT(CASE WHEN product = 'sneakers' AND title = 'banner_show' THEN 1 END) SneakersBannerShown,
    COUNT(CASE WHEN product = 'sneakers' AND title = 'banner_click' THEN 1 END) SneakersClicks,
    COUNT(CASE WHEN product = 'sneakers' AND title = 'order' THEN 1 END) SneakersOrder,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'banner_show' THEN 1 END) Sports_NutritionBannerShown,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'banner_click' THEN 1 END) Sports_NutritionClicks,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'order' THEN 1 END) ASports_nutritionOrder
FROM product.product
WHERE site_version = 'desktop';

SELECT
	COUNT(CASE WHEN product = 'company' AND title = 'banner_show' THEN 1 END) CompanyBannerShown,
    COUNT(CASE WHEN product = 'company' AND title = 'banner_click' THEN 1 END) CompanyBannerClicks,
    COUNT(CASE WHEN product = 'accessories' AND title = 'banner_show' THEN 1 END) AccessoryBannerShown,
    COUNT(CASE WHEN product = 'accessories' AND title = 'banner_click' THEN 1 END) AccessoryClicks,
    COUNT(CASE WHEN product = 'accessories' AND title = 'order' THEN 1 END) AccessoryOrder,
    COUNT(CASE WHEN product = 'clothes' AND title = 'banner_show' THEN 1 END) ClothesBannerShown,
    COUNT(CASE WHEN product = 'clothes' AND title = 'banner_click' THEN 1 END) ClothesClicks,
    COUNT(CASE WHEN product = 'clothes' AND title = 'order' THEN 1 END) ClothesOrder,
    COUNT(CASE WHEN product = 'sneakers' AND title = 'banner_show' THEN 1 END) SneakersBannerShown,
    COUNT(CASE WHEN product = 'sneakers' AND title = 'banner_click' THEN 1 END) SneakersClicks,
    COUNT(CASE WHEN product = 'sneakers' AND title = 'order' THEN 1 END) SneakersOrder,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'banner_show' THEN 1 END) Sports_NutritionBannerShown,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'banner_click' THEN 1 END) Sports_NutritionClicks,
    COUNT(CASE WHEN product = 'sports_nutrition' AND title = 'order' THEN 1 END) ASports_nutritionOrder
FROM product.product
WHERE site_version = 'mobile'
   




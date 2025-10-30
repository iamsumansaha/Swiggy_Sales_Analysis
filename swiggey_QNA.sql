CREATE DATABASE SWIGGEY_DB;


USE SWIGGEY_DB;

DROP TABLE IF EXISTS swiggey;
CREATE TABLE swiggey (
    id INT AUTO_INCREMENT PRIMARY KEY,   
    State VARCHAR(100),
    City VARCHAR(100),
    Restaurant_Name VARCHAR(255),
    Location VARCHAR(255),
    Category VARCHAR(100),
    Dish_Name VARCHAR(255),
    Price_INR DECIMAL(10,2),           
    Rating DECIMAL(3,2),                 
    Rating_Count INT
);


SELECT *
FROM swiggey;



-- adding ID column 
ALTER TABLE swiggey 
ADD COLUMN ID INT AUTO_INCREMENT PRIMARY KEY FIRST;




-- Q1. Find the top 10 most expensive dishes in the dataset.
SELECT
    id,
    restaurant_name,
    dish_name,
    price_inr
FROM swiggey
ORDER BY price_inr DESC
LIMIT 10;



-- Q2. List the top 5 highest-rated restaurants in each city.
WITH max_rating AS (
        SELECT
            s1.state AS state,
            s1.city AS city,
            s1.restaurant_name AS restaurant,
            s1.rating AS rating,
            s2.max_rate AS max_rating,
            ROW_NUMBER() OVER(PARTITION BY s1.city) AS rnks
        FROM swiggey s1
        JOIN (
            SELECT
                city,
                MAX(rating) as max_rate
            FROM swiggey
            GROUP BY city
        ) s2
        ON s1.city = s2.city
        WHERE s1.rating = s2.max_rate
        GROUP BY s1.state, s1.city, s1.restaurant_name
)
SELECT
    city,
    restaurant,
    rating,
    rnks
FROM max_rating
WHERE rnks <= 5;



-- Q3. Find the average price of dishes by category across all states.
 SELECT
    state,
    city,
    category,
    ROUND(AVG(price_inr),2) AS avg_price
 FROM swiggey
 GROUP BY state, city,category
 ORDER BY state, city, category;




-- Q4. Identify the city with the maximum number of restaurants listed.
SELECT
    city,
    COUNT(*) AS no_of_restaurants
FROM swiggey
GROUP BY city
ORDER BY no_of_restaurants DESC
LIMIT 1;



-- Q5. Show the top 10 most popular dishes (based on Rating Count).
SELECT 
    restaurant_name,
    dish_name,
    SUM(rating_count) AS rating_count
FROM swiggey
GROUP BY restaurant_name, dish_name
ORDER BY rating_count DESC
LIMIT 10;


-- Q6. Find the average dish price per city and rank the cities from cheapest to most expensive.
WITH city_rank AS (
SELECT
    city,
    ROUND(AVG(price_inr),2) AS avg_price
FROM swiggey
GROUP BY city
)
SELECT
    city,
    avg_price,
    RANK() OVER(ORDER BY avg_price) AS rnk
FROM city_rank;



-- Q7. Get the top 5 restaurants in each state with the highest number of dishes listed.
WITH high_rest AS (
        SELECT
            state,
            Restaurant_Name,
            COUNT(DISTINCT Dish_Name) AS no_of_dish,
            RANK() OVER(PARTITION BY state ORDER BY COUNT(DISTINCT Dish_Name) DESC) AS ranks
        FROM swiggey
        GROUP BY state, restaurant_name
)
SELECT
    state,
    restaurant_name,
    no_of_dish,
    ranks
FROM high_rest
WHERE ranks <= 5;



-- Q8. Find restaurants with rating higher than their city's average rating.
WITH rest_rate AS (
                SELECT
                    city,
                    restaurant_name,
                    ROUND(AVG(rating),2) AS rest_avg_rating
                FROM swiggey
                GROUP BY city, restaurant_name
),
city_avg_rate AS (
                    SELECT
                        city,
                        ROUND(AVG(rating),2) AS city_avg_rating
                    FROM swiggey
                    GROUP BY city
)
SELECT 
    rr.city,
    rr.restaurant_name,
    rr.rest_avg_rating,
    car.city_avg_rating
FROM rest_rate rr
JOIN city_avg_rate car
ON rr.city = car.city
WHERE rr.rest_avg_rating > car.city_avg_rating;




-- Q9. List dishes that have a price higher than the city’s average price.
SELECT
    s1.city,
    s1.restaurant_name,
    s1.dish_name,
    s1.price_inr AS price,
    s2.city_avg
FROM swiggey s1
JOIN (
    SELECT
        city,
        ROUND(AVG(price_inr),2) AS city_avg
    FROM swiggey
GROUP BY city
) as s2
ON s1.city = s2.city
WHERE s1.price_inr > city_avg
ORDER BY city;




-- Q10. Find the most common dish categories across India.
SELECT
    dish_name,
    sum(rating_count) AS no_of_person_rate
FROM swiggey
GROUP BY dish_name
ORDER BY no_of_person_rate DESC;



-- Q11. Find the top 3 most expensive dishes in each city along with their restaurant and price.
WITH exp_food AS (  
SELECT
    city,
    restaurant_name,
    dish_name,
    price_inr,
    RANK() OVER(PARTITION BY city ORDER BY price_inr DESC) AS expense_dish
FROM swiggey
)
SELECT
    city,
    restaurant_name,
    dish_name,
    price_inr AS price,
    expense_dish
FROM exp_food
WHERE expense_dish <= 3;



-- Q12. Show the average, minimum, and maximum rating of restaurants in each state.
SELECT
    state,
    restaurant_name,
    ROUND(AVG(rating),2) AS avg_rating,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating  
FROM swiggey
GROUP BY state, restaurant_name
ORDER BY state;




-- Q13. Find restaurants that offer more than 50 unique dishes in their menu per city. 
SELECT
    restaurant_name,
    COUNT(DISTINCT dish_name) AS no_of_dish
FROM swiggey
GROUP BY restaurant_name
HAVING no_of_dish > 50
ORDER BY no_of_dish DESC;




-- Q14. Identify the restaurant(s) with the highest average rating in each state. 
WITH high_avg_rt AS (
SELECT
    state,
    restaurant_name,
    ROUND(AVG(rating),2) AS state_avg,
    RANK() OVER(PARTITION BY state ORDER BY AVG(rating) DESC) AS rnks
FROM swiggey
GROUP BY state ,restaurant_name
ORDER BY state
)
SELECT 
    state,
    restaurant_name,
    state_avg
FROM high_avg_rt
WHERE rnks = 1
ORDER BY state_avg DESC;




-- Q15. Find the percentage contribution of each category to the total menu items in a city. 
WITH cte_category AS (
            SELECT
                city,
                category,
                SUM(rating_count) AS nop_category
            FROM swiggey
            GROUP BY city, category
            ORDER BY city
),
cte_city AS (
            SELECT
                city,
                SUM(Rating_count) AS nop_city
            FROM swiggey
            GROUP BY city
)
SELECT
    ct.city,
    ct.category,
    CONCAT(
        100 * ct.nop_category / cc.nop_city,
        '%') AS '%contribution'
FROM cte_category ct
JOIN cte_city cc 
ON ct.city = cc.city;




-- Q16. Find the percentage contribution of each Restaurant in a city.
WITH cte_res AS (
            SELECT
                city,
                Restaurant_Name,
                SUM(rating_count) AS res_count
            FROM swiggey
            GROUP BY city, restaurant_name
            ORDER BY city
),
cte_city AS (
            SELECT
                city,
                SUM(rating_count) AS city_count
            FROM swiggey
            GROUP BY city
            ORDER BY city
)
SELECT
    cr.city,
    cr.restaurant_name,
    CONCAT(
        100 * cr.res_count / cc.city_count
        , '%') AS '%contribute'
FROM cte_res cr 
JOIN cte_city cc 
ON cr.city = cc.city
ORDER BY cr.city, (100 * cr.res_count / cc.city_count) DESC;
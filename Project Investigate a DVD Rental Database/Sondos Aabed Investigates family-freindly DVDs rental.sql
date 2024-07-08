/**
	Done by: Sondos Aabed 
	The observation and insights of these queries are presented on the slides
**/
/** 
	Query #1: investigate the rental of family-friendly movies 
	the question is What movies are the Families watching and which are the most rented?
	use withm aggregation function COUNT, JOINS, ordered
**/

WITH categories_counts AS (
  	SELECT 
  		f.title as Film_title, 
		c.name as Category_name,
		COUNT(*)
  	FROM 
  		category c
  		JOIN film_category f_c
  			ON c.category_id = f_c.category_id
  		JOIN film f
  			ON f.film_id = f_c.film_id
  		JOIN inventory i
			ON f.film_id = i.film_id
  		JOIN rental r
  			ON i.inventory_id = r.inventory_id
  	GROUP BY 1,2
  	ORDER BY 2, 1
)

SELECT * 
FROM 
	categories_counts
WHERE 
	Category_name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') 
ORDER BY count DESC;

/** 
	Query #2: investigate the rental duration of family-friendly movies using quartiles
	How the length of rental duration of the later family-friendly movies are compared to all movie duration based on category?
	used subqueries, aggregation AVG, window NTILE, ordered, JOINS
	
**/

SELECT
        sub.Film_title,
        sub.rental_duration,
        sub.Category_name,
        sub.avg_rent_dur_of_category,
        NTILE(4) OVER (PARTITION BY sub.Category_name ORDER BY sub.avg_rent_dur_of_category) AS rental_duration_quartile
FROM
	(
         SELECT
                f.title AS Film_title,
                f.rental_duration,
                c.name AS Category_name,
                AVG(f.rental_duration) OVER (PARTITION BY c.name) AS avg_rent_dur_of_category
          FROM
                category c
                JOIN film_category f_c 
			ON c.category_id = f_c.category_id
                JOIN film f 
			ON f.film_id = f_c.film_id
           WHERE
                c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
        ) sub
  ORDER BY rental_duration_quartile;

/** 
	Query #3: show a table of each quartile and each category with their counts 
	used multiple WITH, aggregation avg, COUNT, NTILE, JOINS, ordered 
**/

WITH family_freindly AS (
            SELECT
                f.title AS Film_title,
                f.rental_duration,
                c.name AS Category_name,
                AVG(f.rental_duration) OVER (PARTITION BY c.name) AS avg_rent_dur_of_category
            FROM
                category c
                JOIN film_category f_c 
			ON c.category_id = f_c.category_id
                JOIN film f 
			ON f.film_id = f_c.film_id
            WHERE
                c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')       
), quartiles AS (
  	SELECT
        	family_freindly.Category_name,
       	 	NTILE(4) OVER (PARTITION BY family_freindly.Category_name ORDER BY family_freindly.avg_rent_dur_of_category) AS rental_duration_quartile
    	FROM 
		family_freindly
)

SELECT 
	quartiles.Category_name,
	quartiles.rental_duration_quartile,
	COUNT(*)
FROM 
	quartiles
GROUP BY 
	quartiles.Category_name,
	quartiles.rental_duration_quartile
ORDER BY 1, 3 DESC;


/** 
	Query #4: shows the top 10 customers who paid for the Family Friendly movies 
	Used aggregation SUM, JOINS, ordered, used CONCAT and DATE_TRUNC, LIMIT
**/

SELECT DISTINCT 
	CONCAT(cus.first_name ,
                          CONCAT(' ',cus.last_name)) as customer_name, 
	cus.email, SUM(pay.amount) as sum_payment
FROM 
     category c
     JOIN film_category f_c
     	ON c.category_id = f_c.category_id
     JOIN film f
     	ON f.film_id = f_c.film_id
     JOIN inventory i
     	ON f.film_id = i.film_id
     JOIN rental r
     	ON i.inventory_id = r.inventory_id
     JOIN customer cus
         ON cus.customer_id = r.customer_id   
     JOIN payment pay
         ON pay.customer_id = cus.customer_id                    
WHERE 
	c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music') 
AND 
	DATE_TRUNC('year',r.rental_date) = TO_DATE('2006', 'year') 
GROUP BY 
	pay.amount, cus.first_name, cus.last_name, cus.email
ORDER BY 
	SUM(pay.amount) DESC
LIMIT 10;

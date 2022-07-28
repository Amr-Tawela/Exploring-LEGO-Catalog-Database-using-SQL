--1--
--What is the total number of parts per theme ?--

SELECT t.name , SUM(num_parts) total_parts_per_theme 
  FROM sets s
  JOIN themes t
    ON s.theme_id = t.id 
 GROUP BY t.name  
 ORDER BY 2 DESC


--2--
--What is the total number of parts per year ?--  Production of parts per year 

SELECT year , SUM(num_parts) total_parts_per_year
  FROM sets s 
  JOIN themes t 
    ON s.theme_id = t.id 
 GROUP BY year 
 ORDER BY 2 


--3--
--How many Sets Where Created in each Century in the dataset ?--

SELECT CASE WHEN year BETWEEN 1901 AND 2000 THEN '20th_century'
			WHEN year BETWEEN 2001 AND 2100 THEN '21st_century'
			END AS century
			,COUNT(set_num) number_sets_per_century
  FROM sets s 
  JOIN themes t 
    ON s.theme_id = t.id 
 GROUP BY (CASE WHEN year BETWEEN 1901 AND 2000 THEN '20th_century'
			WHEN year BETWEEN 2001 AND 2100 THEN '21st_century'
			END
		   )


--4--
--What percentage of sets ever released in the 21st century were trains themed ?-- 

WITH cte_1 AS 
(
SELECT set_num , s.name set_name , year , theme_id , num_parts , id , t.name theme_name , parent_id ,
	   CASE WHEN year BETWEEN 1901 AND 2000 THEN '20th_century'
			WHEN year BETWEEN 2001 AND 2100 THEN '21st_century'
			END AS century , COUNT(set_num) OVER () total_number_of_sets
  FROM sets s 
  JOIN themes t 
    ON s.theme_id = t.id 
)
,cte_2 AS
(
SELECT set_num , COUNT(set_num) OVER (PARTITION BY century ,theme_name) part_number_of_sets
  FROM cte_1
 WHERE century = '21st_century' AND theme_name LIKE '%train%'
)
,cte_3 AS
(
SELECT Distinct(theme_name), century , part_number_of_sets , total_number_of_sets 
  FROM cte_1 a
  JOIN cte_2 b 
    ON a.set_num = b.set_num 
)
,cte_4 AS
(
SELECT REPLACE(theme_name,'Trains','Train') theme_name, century ,part_number_of_sets, total_number_of_sets,
	   CAST(1.00*part_number_of_sets / total_number_of_sets AS DECIMAL(10,10))*100 percentage
  FROM cte_3 
)

SELECT theme_name , century , total_number_of_sets ,SUM(part_number_of_sets) number_of_sets,SUM(percentage) percentage
  FROM cte_4
 GROUP BY theme_name , century ,total_number_of_sets 
 

--5--
--What was the popular theme by year in terms of sets released in the 21st Century?--
WITH cte_1 AS
(
SELECT set_num , s.name set_name , year , theme_id ,  num_parts , t.name theme_name , parent_id ,
	   CASE WHEN year BETWEEN 1901 AND 2000 THEN '20th_century' 
			WHEN year BETWEEN 2001 AND 2100 THEN '21st_century'
		END AS century 
  FROM sets s 
  JOIN themes t 
    ON s.theme_id = t.id 
)
SELECT * 
  FROM 
(
SELECT theme_name , year , COUNT(set_name) count_sets , 
       DENSE_RANK () OVER (PARTITION BY year ORDER BY COUNT(set_name) DESC) rank
  FROM cte_1 
 WHERE century = '21st_century' AND parent_id IS NOT NULL 
 GROUP BY theme_name , year 
) sub_1 
  WHERE rank = 1 
  ORDER BY year DESC
 

--6--
--What is the most produced color of lego ever in terms of quantity of parts?--

WITH cte AS
(
SELECT ip.part_num , quantity , c.name color_name 
  FROM inventory_parts ip
  JOIN parts p
    ON ip.part_num = p.part_num 
  JOIN colors c 
    ON ip.color_id = c.id
)

SELECT color_name  , SUM(CAST(quantity AS INT)) quantity_of_parts 
  FROM cte 
 GROUP BY color_name 
 ORDER BY 2 DESC
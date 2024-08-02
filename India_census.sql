-- https://censusindia.gov.in/census.website/data/data-visualizations#

Create database indian_census;
use indian_census;
/*select the tabless*/
select * from dataset1;
select * from dataset2;
select * from dataset3;

-- counting the rows

select count(*) from dataset1;
select count(*) from dataset2;

-- data for jharkhand and bihar state
SELECT *
FROM dataset1
WHERE state IN ('Jharkhand', 'Bihar')
ORDER BY state;
-- total population in india in 2011

SELECT SUM(population) AS total_population
FROM dataset2;

-- avg growth in total population

SELECT CONCAT(ROUND(100 * AVG(Growth), 2), '%') AS "Avg Growth in Population"
FROM dataset1;

-- avg growth in total population for each state
SELECT state, CONCAT(ROUND(100 * AVG(Growth), 2), '%') AS "Avg Growth in Population"
FROM dataset1
GROUP BY state;

-- avg sex ratio
SELECT state, ROUND(AVG(sex_ratio)) AS "Avg Sex Ratio of States"
FROM dataset1
GROUP BY state
ORDER BY 2 DESC;

-- avg literacy rate
SELECT state, ROUND(AVG(Literacy), 1) AS "Avg Literacy Rate"
FROM dataset1
GROUP BY state;

-- avg literacy rate greater than 90
SELECT state, ROUND(AVG(Literacy), 1) AS "Avg Literacy Rate"
FROM dataset1
GROUP BY state
HAVING AVG(Literacy) > 90;

-- Top 3 states showing highest growth rate
SELECT state, Avg_Growth_in_Population
from(
SELECT state, ROUND(100 * AVG(Growth), 2) AS Avg_Growth_in_Population, DENSE_RANK() OVER(ORDER BY AVG(growth) DESC) AS r
FROM dataset1
GROUP BY state
ORDER BY 2 DESC) a
WHERE r < 4;


-- bottom 3 states showing sex ratio
SELECT state, Avg_Sex_Ratio_of_States
from(
SELECT state, ROUND(AVG(sex_ratio)) AS Avg_Sex_Ratio_of_States, DENSE_RANK() OVER(ORDER BY AVG(sex_ratio) ASC) AS r
FROM dataset1
GROUP BY state
ORDER BY 2) a
where r <6;

-- top and bottom 3 states of literacy rate we used union here with cte
WITH literacy_highest AS (
    SELECT state, ROUND(AVG(Literacy),1) AS "Avg Literacy rate"
    FROM dataset1
    GROUP BY state
    ORDER BY 2 DESC
    LIMIT 3
),
literacy_lowest AS (
    SELECT state, ROUND(AVG(Literacy),1) AS "Avg Literacy rate"
    FROM dataset1
    GROUP BY state
    ORDER BY 2 ASC
    LIMIT 3
)
SELECT *
FROM literacy_highest
UNION
SELECT *
FROM literacy_lowest
ORDER BY 2 DESC;

-- joining 2 tables. sex ratio is the no of females for 1000 males 
SELECT d1.district, d1.state, d1.sex_ratio/1000, d2.population
FROM dataset1 d1
JOIN dataset2 d2
USING (district);


-- find the male and female population for each district and order by state
/* f/m = sex_ratio
	f = m*sex_ratio ,,,,1
	m+f = population (considering only 2)
	f = poulation - m,...2
     m*sex_ratio = (population - m)
     m(sex_ratio+1) = population
     m = population/(sex_ratio+1)             */

SELECT district, state, population,
       ROUND(population/(sex_ratio+1)) AS male_population,
       ROUND(population - (population/(sex_ratio+1))) AS female_population
FROM (
    SELECT d1.district, d1.state, d1.sex_ratio/1000 AS sex_ratio, d2.population
    FROM dataset1 d1
    JOIN dataset2 d2
    USING (district)
) s
ORDER BY state;


 -- find the male and female population for each state
SELECT state, 
       SUM(males) AS total_males, 
       SUM(females) AS total_females
FROM (
    SELECT district, state, population,
           ROUND(population/(sex_ratio+1)) AS males,
           ROUND(population - (population/(sex_ratio+1))) AS females
    FROM (
        SELECT d1.district, d1.state, d1.sex_ratio/1000 AS sex_ratio, d2.population #converting sex ratio into a decimal since it given as whole number.
        FROM dataset1 d1
        JOIN dataset2 d2
        USING (district)
    ) a
    ORDER BY state
) b
GROUP BY state
ORDER BY population DESC;


-- finding the literate and illerte people per district
/*		literacy ratio = literate/population
		literacy ratio*population = literate	
        population  - literacy ratio*population = illiterate */
SELECT district, state,
       ROUND(literacy_ratio* population) AS total_literate_people,
       ROUND(population - (literacy_ratio* population)) AS total_illiterate_people
FROM (
    SELECT d1.district, d1.state, d1.literacy/100 AS literacy_ratio, d2.population
    FROM dataset1 d1
    JOIN dataset2 d2
    USING (district)
) x;

-- finding the previous census population for each states

/* previous_census(growth +1) = current_census
	prevuous_census = current_census/(1+growth)*/

SELECT state, SUM(previous_population_census) AS total_previous_population_census, SUM(population_census) AS total_population_census
FROM (
    SELECT district, state, population AS population_census,
           ROUND(population/(1+growth)) AS previous_population_census
    FROM (
        SELECT d1.district, d1.state, d1.growth, d2.population
        FROM dataset1 d1
        JOIN dataset2 d2
        USING (district)
    ) s
) x
GROUP BY state;

        
-- top 3 district with the highest literacy rate within each state

WITH top_literacy_cte AS(
SELECT district, state, literacy,
DENSE_RANK() OVER(PARTITION BY state ORDER BY literacy DESC) AS rnk
FROM dataset1)

SELECT state, district, literacy
FROM top_literacy_cte
WHERE rnk IN (1,2,3);

-- EDA ON THIS DATASET 

-- How many districts are included in the data?
SELECT COUNT(DISTINCT district) AS total_districts
FROM dataset1;

-- What is the average literacy rate across all districts?
SELECT ROUND(AVG(literacy),2) AS "average literacy rate across all districts"
FROM dataset1;
        
-- Which state has the highest population?
SELECT state, sum(population) as total_population
from dataset2
group by state
order by 2 desc
limit 1;

-- What is the sex ratio in the district with the highest literacy rate?
SELECT district, sex_ratio, literacy
FROM dataset1
WHERE literacy = (SELECT MAX(literacy) FROM dataset1);

-- How many districts have a literacy rate above 80%?
SELECT COUNT(district) AS total_districts
FROM dataset1
WHERE literacy > 80;

-- 6. What is the overall population density for each state?
SELECT state, CONCAT(ROUND(population/Area_km2), " persons per sq.km") AS population_density
FROM dataset2;

-- 7. Which district has the highest population density?
SELECT district, ROUND(population/Area_km2) AS population_density
FROM dataset2
WHERE state != '#N/A'
ORDER BY 2 DESC;

-- 8. How has the literacy rate changed over the last decade for each district?

/* The correlation coefficient is a measure of the linear relationship between two variables, and it can be calculated using the following formula:
r = (nΣxy - ΣxΣy) / (sqrt(nΣx² - (Σx)²) * sqrt(nΣy² - (Σy)²))
A correlation coefficient of -0.1697 suggests a weak negative correlation between population growth and literacy rate in your dataset. 
This means that there is a tendency for higher population growth to be associated with lower literacy rates,
*/
        
SELECT 
  ROUND((COUNT(*) * SUM(growth * literacy) - SUM(growth) * SUM(literacy)) / 
  SQRT((COUNT(*) * SUM(growth * growth) - SUM(growth) * SUM(growth)) *
  (COUNT(*) * SUM(literacy * literacy) - SUM(literacy) * SUM(literacy))),4) AS correlation
FROM (
SELECT growth, literacy/100 AS literacy
FROM dataset1) s;

-- Which state has the highest number of districts with a female-majority population?\
-- Tamil Nadu has 15 districts with a female-majority population	
WITH population_cte AS (
SELECT district, state, population,
ROUND(population/(sex_ratio+1)) AS males,
ROUND(population - (population/(sex_ratio+1))) AS females
FROM (
	SELECT d1.district, d1.state, sex_ratio/1000 AS sex_ratio, population
	FROM dataset1 d1
	JOIN dataset2 d2
	USING (district)
     ) s
ORDER BY state
)
SELECT state, COUNT(district) AS total_districts
FROM population_cte
WHERE females > males
GROUP BY state
ORDER BY 2 DESC
LIMIT 1;

-- What is the difference in population growth between rural and urban districts
-- from the o/p the rural population is 0.14% greater than the urban population growth
WITH type_cte AS (
SELECT
d1.district,
population,
growth,
ROUND(population / Area_km2) AS population_density,
CASE WHEN population > 5000 AND ROUND(population / Area_km2) > 400 THEN 'urban' ELSE 'rural' END AS type
FROM dataset2 d2
JOIN dataset1 d1
USING (district)
)

SELECT
round(100*AVG(growth),2) AS urban_population_growth,
(SELECT round(100*AVG(growth),2) FROM type_cte WHERE type = 'rural') AS rural_population_growth,
round(100*(AVG(growth) - (SELECT AVG(growth) FROM type_cte WHERE type = 'rural')),2) AS difference
FROM type_cte
WHERE type = 'urban';

-- How many districts have a population density above the national average?
WITH national_avg_cte AS (
SELECT *, population / area_km2 AS population_density
FROM dataset2
WHERE state != '#N/A'
)

SELECT COUNT(*) AS total_districts
FROM national_avg_cte
WHERE population_density > (SELECT AVG(population_density) FROM national_avg_cte);	

-- How many districts have a population density below the national average?
WITH population_density_cte AS (
SELECT district, population / area_km2 AS population_density
FROM dataset2
WHERE state != '#N/A'
)

SELECT COUNT(district) AS total_districts
FROM population_density_cte
WHERE population_density < (SELECT AVG(population_density) FROM population_density_cte);

-- What is the difference in literacy rate between male and female population in each state?
SELECT 
    state,
    ROUND((Male_literacy - Female_literacy), 2) AS difference
FROM dataset3;

-- Which district has the highest literacy rate per capita?
SELECT 
    district, 
    literacy 
FROM dataset1 
WHERE literacy = (SELECT MAX(literacy) FROM dataset1);

-- How does the population distribution differ between states with a high and low literacy rate?
SELECT 
  CASE WHEN Literacy > (SELECT AVG(Literacy) FROM dataset1) THEN 'High Literacy' ELSE 'Low Literacy' END Literacy_Group,
  SUM(Population) AS Total_Population,
  round(AVG(Population),2) AS Avg_Population
FROM dataset2
JOIN dataset1
USING (state)
GROUP BY Literacy_Group;

--  What is the average growth rate for districts with a literacy rate above 80%

SELECT 
    state, 
    ROUND(AVG(growth), 2)
FROM dataset1
GROUP BY state
HAVING AVG(literacy) > 80
ORDER BY 2 DESC;

--  Which district has the highest change in literacy rate over the past decade?
SELECT state, literacy_growth
FROM dataset3
WHERE literacy_growth = (SELECT MAX(literacy_growth) FROM dataset3);

-- What is the correlation between literacy rate and male literacy rate?
/* correlation coefficient of 0.9656 indicates a strong positive correlation between male literacy rate and overall literacy rate between states in India. 
While this suggests that there may be a relationship between the two variables, it does not necessarily imply causation.

As you noted, there could be other factors at play that contribute to the overall literacy rate in a state. 
For example, socioeconomic factors such as access to education, income levels, and cultural attitudes towards education may also have an impact on literacy rates. 
Additionally, the relationship between male literacy rate and overall literacy rate may not be causal, but rather a reflection of broader trends in education 
and development in a given state.*/
SELECT 
  ROUND((COUNT(*) * SUM(Literacy * male_Literacy) - SUM(Literacy) * SUM(male_Literacy)) / 
  SQRT((COUNT(*) * SUM(Literacy * Literacy) - SUM(Literacy) * SUM(Literacy)) *
  (COUNT(*) * SUM(male_Literacy * male_Literacy) - SUM(male_Literacy) * SUM(male_Literacy))),4) AS correlation
FROM (
SELECT male_literacy/100 AS male_literacy, literacy/100 AS literacy
FROM dataset3) s;

-- How does the sex ratio differ between states with a high and low female literacy rate?
WITH literacy_cte AS(
SELECT state, ROUND(AVG(literacy),2) AS literacy_per_state, sex_ratio
FROM dataset1
GROUP BY state)

SELECT 
	CASE WHEN female_literacy > (SELECT AVG(female_literacy) FROM dataset3) THEN 'High literacy' ELSE 'Low literacy' END Female_literacy_group,
    round(AVG(sex_ratio))
FROM dataset3
JOIN literacy_cte
USING(state)
GROUP BY Female_literacy_group;

























































-- Netflix  Project
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(6),
    type         VARCHAR(10),
    title        VARCHAR(150),
    director     VARCHAR(208),
    casts        VARCHAR(1000),
    country      VARCHAR(150),
    date_added   VARCHAR(50),
    release_year INT,
    rating       VARCHAR(10),
    duration     VARCHAR(15),
    listed_in    VARCHAR(100),
    description  VARCHAR(250)
);

SELECT  * FROM netflix;


SELECT 
COUNT(*) as total_content
FROM netflix;

	
SELECT  
    DISTINCT type
FROM netflix;

SELECT  * FROM netflix;

-- 15 Buisness Problems

1. Count the number of Movies vs TV Shows

SELECT 
  	type,
	  COUNT(*) as total_content
FROM netflix
GROUP BY type




2. Find the most common rating for movies and TV shows

WITH RatingCounts AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY type, rating
),
RankedRatings AS (
    SELECT 
        type,
        rating,
        rating_count,
        RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS rank
    FROM RatingCounts
)
SELECT 
    type,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rank = 1;

3. Find the top 5 countries with the most content on Netflix

SELECT
    UNNEST(STRING_TO_ARRAY(country, ',')) AS new_country,
    COUNT(show_id) AS total_content
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

4. Identify the longest movie

SELECT * FROM netflix
WHERE
	type = 'Movie'
	AND
	duration = (SELECT MAX(duration) FROM netflix)

5. List all TV shows with more than 5 seasons

SELECT *
FROM netflix
WHERE 
	TYPE = 'TV Show'
	AND
	SPLIT_PART(duration, ' ', 1)::INT > 5

6. Count the number of content items in each genre

SELECT 
	UNNEST(STRING_TO_ARRAY(listed_in, ',')) as genre,
	COUNT(*) as total_content
FROM netflix
GROUP BY 1 
ORDER BY 2 DESC

7.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

SELECT 
	country,
	release_year,
	COUNT(show_id) as total_release,
	ROUND(
		COUNT(show_id)::numeric/
								(SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100 
		,2
		)
		as avg_release
FROM netflix
WHERE country = 'India' 
GROUP BY country, 2
ORDER BY avg_release DESC 
LIMIT 5





8. List all movies that are documentaries

SELECT * FROM netflix
WHERE listed_in LIKE '%Documentaries'
ORDER BY show_id DESC

9. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT 
	UNNEST(STRING_TO_ARRAY(casts, ',')) as actor,
	COUNT(*)
FROM netflix
WHERE country = 'India'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10


10.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.

SELECT 
    category,
	TYPE,
    COUNT(*) AS content_count
FROM (
    SELECT 
		*,
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY 1,2
ORDER BY 2


11. Director with Highest Average Movie Duration

SELECT
    director,
    ROUND(AVG(CAST(REPLACE(duration,' min','') AS INTEGER)),2) AS avg_duration
FROM netflix
WHERE type = 'Movie'
    AND director IS NOT NULL
GROUP BY director
ORDER BY avg_duration DESC
LIMIT 10;

12. Country with Most Genre Diversity

WITH genre_country AS
(
    SELECT
        UNNEST(STRING_TO_ARRAY(country, ',')) AS country,
        UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre
    FROM netflix
    WHERE country IS NOT NULL
)

SELECT
    TRIM(country) AS country,
    COUNT(DISTINCT TRIM(genre)) AS genre_count
FROM genre_country
GROUP BY country
ORDER BY genre_count DESC
LIMIT 10;

13. Year-over-Year Netflix Content Growth %

WITH yearly_content AS
(
    SELECT
        release_year,
        COUNT(*) AS total_content
    FROM netflix
    GROUP BY release_year
)

SELECT
    release_year,
    total_content,
    LAG(total_content) OVER(ORDER BY release_year) AS previous_year,
    
    ROUND(
        (
            (total_content -
             LAG(total_content) OVER(ORDER BY release_year)
            )::NUMERIC
            /
            LAG(total_content) OVER(ORDER BY release_year)
        ) * 100,
        2
    ) AS growth_percentage

FROM yearly_content;

14. Directors Who Created Both Movies and TV Shows

SELECT
    director,
    COUNT(DISTINCT type) AS content_types
FROM netflix
WHERE director IS NOT NULL
GROUP BY director
HAVING COUNT(DISTINCT type) = 2
ORDER BY director;

15. Most Dominant Rating in Each Country

WITH country_rating AS
(
    SELECT
        TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS country,
        rating,
        COUNT(*) AS total_titles
    FROM netflix
    WHERE country IS NOT NULL
    GROUP BY 1,2
),

ranked_rating AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY country
            ORDER BY total_titles DESC
        ) AS rn
    FROM country_rating
)

SELECT
    country,
    rating,
    total_titles
FROM ranked_rating
WHERE rn = 1
ORDER BY total_titles DESC;

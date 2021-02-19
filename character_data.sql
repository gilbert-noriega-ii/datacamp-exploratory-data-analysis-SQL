/* fortune500 table fields are 

rank 
title 
name 
ticker
url
hq 
sector
industry
employees
revenue
revenues_change
profit
profits_change
assets
equity

*/

/* company table fields are 

id
exchange
ticker 
name
parent_id

*/

/* stackoverflow table fields are 

id
tag
date
question_count
question_pct
unanswered_count
unanswered_pct

*/

/* tag_type table fields are 

id
tag
type

*/

/* tag_company table fields are 

tag
company_id

*/

/* evanston311 table fields are 

id
priority
source
category
date_created
date_completed
street
house_num
zip
description

*/


/*How many rows does each priority level have?*/

SELECT priority, count(*)
FROM evanston311
GROUP BY priority;

/*How many distinct values of zip appear in at least 100 rows?*/

SELECT zip, count(*)
FROM evanston311
GROUP BY zip
HAVING count(*) >= 100; 

/*How many distinct values of source appear in at least 100 rows?*/

SELECT source, count(*)
FROM evanston311
GROUP BY source
HAVING count(*) >= 100;

/*Select the five most common values of street and the count of each.*/

SELECT street, count(*)
FROM evanston311
GROUP BY street
ORDER BY count(*) DESC
LIMIT 5;

/*Remove the house numbers, extra punctuation, and any spaces from the beginning and end of the street values as a first attempt at cleaning up the values.
Trim digits 0-9, #, /, ., and spaces from the beginning and end of street.
Select distinct original street value and the corrected street value.
Order the results by the original street value.*/

SELECT distinct street,
       trim(street, '0123456789 #/.') AS cleaned_street
FROM evanston311
ORDER BY street;

/*Use ILIKE to count rows in evanston311 where the description contains 'trash' or 'garbage' regardless of case.*/

SELECT COUNT(*)
FROM evanston311
WHERE description ILIKE '%trash%' 
OR description ILIKE '%garbage%';

/*category values are in title case. Use LIKE to find category values with 'Trash' or 'Garbage' in them.*/

SELECT category
FROM evanston311
WHERE category LIKE '%Trash%'
OR category LIKE '%Garbage%';

/*Count rows where the description includes 'trash' or 'garbage' but the category does not.*/

SELECT count(*)
FROM evanston311 
WHERE (description ILIKE '%trash%'
    OR description ILIKE '%garbage%') 
AND category NOT LIKE '%Trash%'
AND category NOT LIKE '%Garbage%';

/*Find the most common categories for rows with a description about trash that don't have a trash-related category.*/

SELECT category, count(*)
FROM evanston311 
WHERE (description ILIKE '%trash%'
OR description ILIKE '%garbage%') 
AND category NOT LIKE '%Trash%'
AND category NOT LIKE '%Garbage%'
GROUP BY category
ORDER BY count(*) DESC
LIMIT 10;

/*Concatenate house_num, a space ' ', and street into a single value using the concat().
Use a trim function to remove any spaces from the start of the concatenated value.*/

SELECT TRIM(CONCAT(house_num, ' ', street), ' ') AS address
FROM evanston311;

/*Use split_part() to select the first word in street; alias the result as street_name.
Also select the count of each value of street_name.*/

SELECT split_part(street, ' ', 1) AS street_name, 
       count(*)
FROM evanston311
GROUP BY street_name
ORDER BY count DESC
LIMIT 20;

/*Select the first 50 characters of description with '...' concatenated on the end where the length() of the description is greater than 50 characters. Otherwise just select the description as is.
Select only descriptions that begin with the word 'I' and not the letter 'I'.*/

SELECT CASE WHEN length(description) > 50
            THEN left(description, 50) || '...'
       ELSE description
       END
FROM evanston311
WHERE description LIKE 'I %'
ORDER BY description;

/*Create recode with a standardized column; use split_part() and then rtrim() to remove any remaining whitespace on the result of split_part().*/

DROP TABLE IF EXISTS recode;

CREATE TEMP TABLE recode AS

SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
FROM evanston311;
    
SELECT DISTINCT standardized 
FROM recode
WHERE standardized LIKE 'Trash%Cart'
    OR standardized LIKE 'Snow%Removal%';

/*UPDATE standardized values LIKE 'Trash%Cart' to 'Trash Cart'.
UPDATE standardized values of 'Snow Removal/Concerns' and 'Snow/Ice/Hazard Removal' to 'Snow Removal'.*/

DROP TABLE IF EXISTS recode;

CREATE TEMP TABLE recode AS
SELECT DISTINCT category, 
              rtrim(split_part(category, '-', 1)) AS standardized
FROM evanston311;

UPDATE recode 
SET standardized='Trash Cart' 
WHERE standardized LIKE 'Trash%Cart';

UPDATE recode
SET standardized='Snow Removal' 
WHERE standardized LIKE 'Snow%Removal%';
    
SELECT DISTINCT standardized 
FROM recode
WHERE standardized LIKE 'Trash%Cart'
    OR standardized LIKE 'Snow%Removal%';

/*UPDATE recode by setting standardized values of 'THIS REQUEST IS INACTIVE...Trash Cart', '(DO NOT USE) Water Bill', 'DO NOT USE Trash', and 'NO LONGER IN USE' to 'UNUSED'.*/

DROP TABLE IF EXISTS recode;

CREATE TEMP TABLE recode AS
  SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
  FROM evanston311;
  
UPDATE recode SET standardized='Trash Cart' 
WHERE standardized LIKE 'Trash%Cart';

UPDATE recode SET standardized='Snow Removal' 
WHERE standardized LIKE 'Snow%Removal%';

UPDATE recode
SET standardized='UNUSED' 
WHERE standardized IN (
              'THIS REQUEST IS INACTIVE...Trash Cart',
              '(DO NOT USE) Water Bill',
              'DO NOT USE Trash', 
              'NO LONGER IN USE');

SELECT DISTINCT standardized 
FROM recode
ORDER BY standardized;

/*Now, join the evanston311 and recode tables to count the number of requests with each of the standardized values
List the most common standardized values first.*/

DROP TABLE IF EXISTS recode;
CREATE TEMP TABLE recode AS
  SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
  FROM evanston311;
UPDATE recode SET standardized='Trash Cart' 
WHERE standardized LIKE 'Trash%Cart';
UPDATE recode SET standardized='Snow Removal' 
WHERE standardized LIKE 'Snow%Removal%';
UPDATE recode SET standardized='UNUSED' 
WHERE standardized IN (
              'THIS REQUEST IS INACTIVE...Trash Cart', 
              '(DO NOT USE) Water Bill',
              'DO NOT USE Trash', 
              'NO LONGER IN USE');

SELECT standardized, count(*)
FROM evanston311
LEFT JOIN recode
ON evanston311.category = recode.category
GROUP BY standardized
ORDER BY count(*) DESC;

/*Create a temp table indicators from evanston311 with three columns: id, email, and phone.
Use LIKE comparisons to detect the email and phone patterns that are in the description, and cast the result as an integer with CAST().
Your phone indicator should use a combination of underscores _ and dashes - to represent a standard 10-digit phone number format.
Remember to start and end your patterns with % so that you can locate the pattern within other text!*/

DROP TABLE IF EXISTS indicators;

CREATE TEMP TABLE indicators AS
  SELECT id, 
        CAST (description LIKE '%@%' AS integer) AS email,
        CAST (description LIKE '%___-___-____%' AS integer) AS phone 
  FROM evanston311;

SELECT *
FROM indicators;

/*Join the indicators table to evanston311, selecting the proportion of reports including an email or phone grouped by priority.
Include adjustments to account for issues arising from integer division.*/

DROP TABLE IF EXISTS indicators;

CREATE TEMP TABLE indicators AS
  SELECT id, 
         CAST (description LIKE '%@%' AS integer) AS email,
         CAST (description LIKE '%___-___-____%' AS integer) AS phone 
  FROM evanston311;
  
SELECT priority,
       SUM(email)/COUNT(*)::numeric AS email_prop, 
       SUM(phone)/COUNT(*)::numeric AS phone_prop
FROM evanston311
LEFT JOIN indicators
ON evanston311.id=indicators.id
GROUP BY priority;
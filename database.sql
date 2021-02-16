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


/*Which column of fortune500 has the most missing values?
First, figure out how many rows are in fortune500 by counting them.*/

SELECT COUNT(*)
FROM fortune500;

/*Subtract the count of the non-NULL ticker values from the total number of rows; alias the difference as missing.*/

SELECT count(*) - count(ticker) AS missing
FROM fortune500;

/*Repeat for the profits_change column.*/

SELECT count(*) - count(profits_change) AS missing
FROM fortune500;

/*Repeat for the industry column.*/

SELECT count(*) - count(industry) AS missing
FROM fortune500;

/*Look at the contents of the company and fortune500 tables. Find a column that they have in common where the values for each company are the same in both tables.
Join the company and fortune500 tables with an INNER JOIN.
Select only company.name for companies that appear in both tables.*/

SELECT company.name
FROM fortune500
INNER JOIN company
ON company.ticker = fortune500.ticker;

/*What is the most common stackoverflow tag_type? What companies have a tag of that type?
First, using the tag_type table, count the number of tags with each type.
Order the results to find the most common tag type.*/

SELECT type, COUNT(tag) AS count
FROM tag_type
GROUP BY type
ORDER BY type DESC;

/*Join the tag_company, company, and tag_type tables, keeping only mutually occurring records.
Select company.name, tag_type.tag, and tag_type.type for tags with the most common type from the previous step.*/

SELECT company.name, tag_type.tag, tag_type.type
FROM company
INNER JOIN tag_company
  ON company.id = tag_company.company_id
INNER JOIN tag_type
  ON tag_company.tag = tag_type.tag
WHERE type='cloud';

/*Use coalesce() to select the first non-NULL value from industry, sector, or 'Unknown' as a fallback value.
Alias the result of the call to coalesce() as industry2.
Count the number of rows with each industry2 value.
Find the most common value of industry2.*/

SELECT coalesce(industry, sector, 'Unknown') AS industry2,
COUNT(*)
FROM fortune500 
GROUP BY industry2
ORDER BY COUNT(*) DESC
LIMIT 1;

/*Join company to itself to add information about a company's parent to the original company's information.
Use coalesce to get the parent company ticker if available and the original company ticker otherwise.
INNER JOIN to fortune500 using the ticker.
Select original company name, fortune500 title and rank.*/

SELECT company_original.name, title, rank
FROM company AS company_original
LEFT JOIN company AS company_parent
    ON company_original.parent_id = company_parent.id
INNER JOIN fortune500 
    ON coalesce(company_original.ticker, 
                company_parent.ticker) = 
                fortune500.ticker
ORDER BY rank; 

/*Select profits_change and profits_change cast as integer from fortune500.
Look at how the values were converted.*/

SELECT profits_change, 
	  CAST(profits_change AS integer) AS profits_change_int
FROM fortune500;

/*Compare the results of casting of dividing the integer value 10 by 3 to the result of dividing the numeric value 10 by 3.*/

SELECT 10/3, 
       10::numeric/3;

/*Now cast numbers that appear as text as numeric.
Note: 1e3 is scientific notation.*/

SELECT '3.2'::numeric,
       '-123'::numeric,
       '1e3'::numeric,
       '1e-3'::numeric,
       '02314'::numeric,
       '0002'::numeric;

/*Was 2017 a good or bad year for revenue of Fortune 500 companies? 
Use GROUP BY and count() to examine the values of revenues_change.
Order the results by revenues_change to see the distribution.*/

SELECT revenues_change, count(*)
FROM fortune500
GROUP BY revenues_change
ORDER BY revenues_change;

/*Repeat step 1, but this time, cast revenues_change as an integer to reduce the number of different values.*/

SELECT revenues_change::integer, count(*)
FROM fortune500
GROUP BY revenues_change::integer
ORDER BY revenues_change;

/*How many of the Fortune 500 companies had revenues increase in 2017 compared to 2016? To find out, count the rows of fortune500 where revenues_change indicates an increase.*/

SELECT count(*)
FROM fortune500
WHERE revenues_change > 0;
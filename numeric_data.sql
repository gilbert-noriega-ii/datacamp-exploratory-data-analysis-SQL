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



/*Compute the average revenue per employee for Fortune 500 companies by sector.
Compute revenue per employee by dividing revenues by employees; use casting to produce a numeric result.
Take the average of revenue per employee with avg(); alias this as avg_rev_employee.
Group by sector.
Order by the average revenue per employee.*/

SELECT sector, 
       AVG(revenues/employees::numeric) AS avg_rev_employee
FROM fortune500
GROUP BY sector
ORDER BY avg_rev_employee;

/*Divide unanswered_count (unanswered ?s with tag) by question_count (all ?s with tag) to see if the value matches that of unanswered_pct to determine the answer.
Exclude rows where question_count is 0 to avoid a divide by zero error.
Limit the result to 10 rows.*/

SELECT unanswered_count/question_count::numeric AS computed_pct, 
      unanswered_pct
FROM stackoverflow
WHERE question_count > 0 
LIMIT 10;

/*Compute the min(), avg(), max(), and stddev() of profits.*/

SELECT min(profits),
       avg(profits),
       max(profits),
       stddev(profits)
FROM fortune500;

/*Now repeat step 1, but summarize profits by sector.
Order the results by the average profits for each sector.*/

SELECT sector,
       min(profits),
       avg(profits),
       max(profits),
       stddev(profits)
FROM fortune500
GROUP BY sector
ORDER BY avg;

/*For this exercise, what is the standard deviation across tags in the maximum number of Stack Overflow questions per day? What about the mean, min, and max of the maximums as well?
Start by writing a subquery to compute the max() of question_count per tag; alias the subquery result as maxval.
Then compute the standard deviation of maxval with stddev().
Compute the min(), max(), and avg() of maxval too.*/

SELECT stddev(maxval),
       min(maxval),
       max(maxval),
       avg(maxval)
FROM (SELECT max(question_count) AS maxval
       FROM stackoverflow
       GROUP BY tag) AS max_results;

/*Use trunc() to truncate employees to the 100,000s (5 zeros).
Count the number of observations with each truncated value.*/

SELECT trunc(employees, -5) AS employee_bin,
       count(*)
FROM fortune500
GROUP BY employee_bin
ORDER BY employee_bin;

/*Repeat step 1 for companies with < 100,000 employees (most common).
This time, truncate employees to the 10,000s place.*/

SELECT trunc(employees, -4) AS employee_bin,
       count(*)
FROM fortune500
WHERE employees < 100000
GROUP BY employee_bin
ORDER BY employee_bin;

/*Summarize the distribution of the number of questions with the tag "dropbox" on Stack Overflow per day by binning the data.
Start by selecting the minimum and maximum of the question_count column for the tag 'dropbox' so you know the range of values to cover with the bins.*/

SELECT min(question_count), 
       max(question_count)
FROM stackoverflow
WHERE tag = 'dropbox';

/*Next, use generate_series() to create bins of size 50 from 2200 to 3100.
To do this, you need an upper and lower bound to define a bin.
This will require you to modify the stopping value of the lower bound and the starting value of the upper bound by the bin width.*/

SELECT generate_series(2200, 3050, 50) AS lower,
       generate_series(2250, 3100, 50) AS upper;

/*Select lower and upper from bins, along with the count of values within each bin bounds.
To do this, you'll need to join 'dropbox', which contains the question_count for tag "dropbox", to the bins created by generate_series().
The join should occur where the count is greater than or equal to the lower bound, and strictly less than the upper bound.*/


WITH bins AS (
      SELECT generate_series(2200, 3050, 50) AS lower,
             generate_series(2250, 3100, 50) AS upper),
dropbox AS (
      SELECT question_count 
        FROM stackoverflow
       WHERE tag='dropbox') 


SELECT lower, upper, count(question_count) 
FROM bins
LEFT JOIN dropbox
ON question_count >= lower 
AND question_count < upper
GROUP BY lower, upper
ORDER BY lower;

/*What's the relationship between a company's revenue and its other financial attributes? 
Compute the correlation between revenues and profits.
Compute the correlation between revenues and assets.
Compute the correlation between revenues and equity.*/

SELECT corr(revenues, profits) AS rev_profits,
	  corr(revenues, assets) AS rev_assets,
       corr(revenues, equity) AS rev_equity 
FROM fortune500;

/*Compute the mean (avg()) and median assets of Fortune 500 companies by sector.*/

SELECT sector,
       avg(assets) AS mean,
       percentile_disc(0.5) WITHIN GROUP (ORDER BY assets) AS median
       FROM fortune500
GROUP BY sector
ORDER BY mean;

/*Find the Fortune 500 companies that have profits in the top 20% for their sector (compared to other Fortune 500 companies).
Create a temporary table called profit80 containing the sector and 80th percentile of profits for each sector.
Alias the percentile column as pct80.*/

DROP TABLE IF EXISTS profit80;

CREATE TEMP TABLE profit80 AS 
SELECT sector, 
         percentile_disc(.8) WITHIN GROUP (ORDER BY profits) AS pct80
FROM fortune500
GROUP BY sector;
   
SELECT * 
FROM profit80;

/*Using the profit80 table you created in step 1, select companies that have profits greater than pct80.
Select the title, sector, profits from fortune500, as well as the ratio of the company's profits to the 80th percentile profit.*/

DROP TABLE IF EXISTS profit80;

CREATE TEMP TABLE profit80 AS
  SELECT sector, 
         percentile_disc(0.8) WITHIN GROUP (ORDER BY profits) AS pct80
    FROM fortune500 
   GROUP BY sector;

SELECT title, fortune500.sector, 
       profits, profits/pct80 AS ratio
FROM fortune500 
LEFT JOIN profit80
ON fortune500.sector = profit80.sector
WHERE profits > pct80;

/*Find out how many questions had each tag on the first date for which data for the tag is available, as well as how many questions had the tag on the last day. Also, compute the difference between these two values.Find out how many questions had each tag on the first date for which data for the tag is available, as well as how many questions had the tag on the last day. Also, compute the difference between these two values.
First, create a temporary table called startdates with each tag and the min() date for the tag in stackoverflow.*/

DROP TABLE IF EXISTS startdates;

CREATE TEMP TABLE startdates AS
SELECT tag,
       min(date) AS mindate
FROM stackoverflow
GROUP BY tag;

SELECT * 
FROM startdates;

/*Join startdates to stackoverflow twice using different table aliases.
For each tag, select mindate, question_count on the mindate, and question_count on 2018-09-25 (the max date).
Compute the change in question_count over time.*/

DROP TABLE IF EXISTS startdates;

CREATE TEMP TABLE startdates AS
SELECT tag, min(date) AS mindate
FROM stackoverflow
GROUP BY tag;
 
SELECT mindate, 
       startdates.tag, 
       so_min.question_count AS min_date_question_count,
       so_max.question_count AS max_date_question_count,
       so_max.question_count - so_min.question_count AS change
FROM startdates
INNER JOIN stackoverflow AS so_min
        ON startdates.tag = so_min.tag
        AND startdates.mindate = so_min.date
INNER JOIN stackoverflow AS so_max
       	ON startdates.tag = so_max.tag
        AND so_max.date = '2018-09-25';

/*Create a temp table correlations.
Compute the correlation between profits and each of the three variables (i.e. correlate profits with profits, profits with profits_change, etc).
Alias columns by the name of the variable for which the correlation with profits is being computed.*/

DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
FROM fortune500;

/*Insert rows into the correlations table for profits_change and revenues_change.*/

DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
FROM fortune500;

INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
FROM fortune500;

INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
FROM fortune500;

/*Select all rows and columns from the correlations table to view the correlation matrix.
First, you will need to round each correlation to 2 decimal places.
The output of corr() is of type double precision, so you will need to also cast columns to numeric.*/

DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
  FROM fortune500;

SELECT measure, 
       round(profits::numeric, 2) AS profits,
       round(profits_change::numeric, 2) AS profits_change,
       round(revenues_change::numeric, 2) AS revenues_change
FROM correlations;
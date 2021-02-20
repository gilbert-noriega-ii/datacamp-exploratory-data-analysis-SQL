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


/*Count the number of Evanston 311 requests created on January 31, 2017 by casting date_created to a date.*/

SELECT count(*) 
FROM evanston311
WHERE date_created::date = '2017-01-31';

/*Count the number of Evanston 311 requests created on February 29, 2016 by using >= and < operators.*/

SELECT count(*)
FROM evanston311 
WHERE date_created >= '2016-2-29' 
AND date_created < '2016-3-1';

/*Count the number of requests created on March 13, 2017.
Specify the upper bound by adding 1 to the lower bound.*/

SELECT count(*)
FROM evanston311
WHERE date_created >= '2017-03-13'
AND date_created < '2017-03-13'::date + 1;

/*Subtract the minimum date_created from the maximum date_created.*/

SELECT max(date_created) - min(date_created)
FROM evanston311;

/*Using now(), find out how old the most recent evanston311 request was created.*/

SELECT now() - max(date_created)
FROM evanston311;

/*Add 100 days to the current timestamp.*/

SELECT now() + '100 days'::interval;

/*Select the current timestamp and the current timestamp plus 5 minutes.*/

SELECT now(), now() + '5 minutes'::interval;

/*Which category of Evanston 311 requests takes the longest to complete?
Compute the average difference between the completion timestamp and the creation timestamp by category.
Order the results with the largest average time to complete the request first.*/

SELECT category, 
       avg(date_completed - date_created) AS completion_time
FROM evanston311
GROUP BY category
ORDER BY completion_time DESC;

/*In this exercise, you'll use date_part() to gain insights about when Evanston 311 requests are submitted and completed.
How many requests are created in each of the 12 months during 2016-2017?*/

SELECT date_part('month', date_created) AS month, 
       count(*)
FROM evanston311
WHERE date_created >= '2016-01-01'
AND date_created < '2018-01-01'
GROUP BY month;

/*What is the most common hour of the day for requests to be created?*/

SELECT date_part('hour', date_created) AS hour,
       count(*)
FROM evanston311
GROUP BY hour
ORDER BY count(*) DESC
LIMIT 1;

/*During what hours are requests usually completed? Count requests completed by hour.
Order the results by hour.*/

SELECT date_part('hour', date_completed) AS hour,
       count(*)
FROM evanston311
GROUP BY hour
ORDER BY hour;

/*Does the time required to complete a request vary by the day of the week on which the request was created?
Select the name of the day of the week the request was created (date_created) as day.
Select the mean time between the request completion (date_completed) and request creation as duration.
Group by day (the name of the day of the week) and the integer value for the day of the week (use a function).
Order by the integer value of the day of the week using the same function used in GROUP BY.*/

SELECT to_char(date_created, 'day') AS day, 
       avg(date_completed - date_created) AS duration
FROM evanston311 
GROUP BY day, EXTRACT(DOW FROM date_created)
ORDER BY EXTRACT(DOW FROM date_created);

/*Using date_trunc(), find the average number of Evanston 311 requests created per day for each month of the data. Ignore days with no requests when taking the average.
Write a subquery to count the number of requests created per day.
Select the month and average count per month from the daily_count subquery.*/

SELECT date_trunc('month', day) AS month,
       avg(count)
FROM (SELECT date_trunc('day', date_created) AS day,
               count(*) AS count
      FROM evanston311
      GROUP BY day) AS daily_count
GROUP BY month
ORDER BY month;

/*Are there any days in the Evanston 311 data where no requests were created?
Write a subquery using generate_series() to get all dates between the min() and max() date_created in evanston311.
Write another subquery to select all values of date_created as dates from evanston311.
Both subqueries should produce values of type date (look for the ::).
Select dates (day) from the first subquery that are NOT IN the results of the second subquery. This gives you days that are not in date_created.*/

SELECT day
FROM (SELECT generate_series(min(date_created),
                             max(date_created),
                             '1 day')::date AS day
        FROM evanston311) AS all_dates
WHERE day NOT IN
       (SELECT date_created::date
        FROM evanston311);

/*Find the median number of Evanston 311 requests per day in each six month period from 2016-01-01 to 2018-06-30. Build the query following the three steps below.
Use generate_series() to create bins of 6 month intervals. Recall that the upper bin values are exclusive, so the values need to be one day greater than the last day to be included in the bin.
Notice how in the sample code, the first bin value of the upper bound is July 1st, and not June 30th.
Use the same approach when creating the last bin values of the lower and upper bounds (i.e. for 2018).*/

SELECT generate_series('2016-01-01',
                       '2018-06-30',  
                       '6 months'::interval) AS lower,
       generate_series('2016-07-01',
                       '2018-12-31',
                       '6 months'::interval) AS upper;

/*Count the number of requests created per day. Remember to not count *, or you will risk counting NULL values.
Include days with no requests by joining evanston311 to a daily series from 2016-01-01 to 2018-06-30.
- Note that because we are not generating bins, you can use June 30th as your series end date.*/

SELECT day, count(date_created) AS count
FROM (SELECT generate_series('2016-01-01', 
                               '2018-06-30', 
                               '1 day'::interval)::date AS day) AS daily_series
LEFT JOIN evanston311
ON day = date_created::date
GROUP BY day;

/*Assign each daily count to a single 6 month bin by joining bins to daily_counts.
Compute the median value per bin using percentile_disc().*/

WITH bins AS (
	  SELECT generate_series('2016-01-01',
                            '2018-01-01',
                            '6 months'::interval) AS lower,
            generate_series('2016-07-01',
                            '2018-07-01',
                            '6 months'::interval) AS upper),

daily_counts AS (
    SELECT day, count(date_created) AS count
    FROM (SELECT generate_series('2016-01-01',
                                    '2018-06-30',
                                    '1 day'::interval)::date AS day) AS daily_series
    LEFT JOIN evanston311
    ON day = date_created::date
    GROUP BY day)

SELECT lower, 
       upper, 
       percentile_disc(0.5) WITHIN GROUP (ORDER BY count) AS median
FROM bins
LEFT JOIN daily_counts
ON day >= lower
AND day < upper
GROUP BY lower, upper
ORDER BY lower;

/*Find the average number of Evanston 311 requests created per day for each month of the data.
Generate a series of dates from 2016-01-01 to 2018-06-30.
Join the series to a subquery to count the number of requests created per day.
Use date_trunc() to get months from date, which has all dates, NOT day.
Use coalesce() to replace NULL count values with 0. Compute the average of this value.*/

WITH all_days AS 
     (SELECT generate_series('2016-01-01',
                             '2018-06-30',
                             '1 day'::interval) AS date),
daily_count AS 
     (SELECT date_trunc('day', date_created) AS day,
             count(*) AS count
      FROM evanston311
      GROUP BY day)
SELECT date_trunc('month', date) AS month,
       avg(coalesce(count, 0)) AS average
FROM all_days
LEFT JOIN daily_count
ON all_days.date = daily_count.day
GROUP BY month
ORDER BY month; 

/*What is the longest time between Evanston 311 requests being submitted?
Select date_created and the date_created of the previous request using lead() or lag() as appropriate.
Compute the gap between each request and the previous request.
Select the row with the maximum gap.*/

WITH request_gaps AS (
        SELECT date_created,
               lag(date_created) OVER (ORDER BY date_created) AS previous,
              date_created - lag(date_created) OVER (ORDER BY date_created) AS gap
          FROM evanston311)

SELECT *
FROM request_gaps
WHERE gap = (SELECT max(gap)
             FROM request_gaps);

/*Requests in category "Rodents- Rats" average over 64 days to resolve. Why?
Use date_trunc() to examine the distribution of rat request completion times by number of days.*/

SELECT date_trunc('day', date_completed - date_created) AS completion_time,
       count(*)
FROM evanston311
WHERE category = 'Rodents- Rats'
GROUP BY completion_time
ORDER BY count;

/*Compute average completion time per category excluding the longest 5% of requests (outliers).*/

SELECT category, 
       avg(date_completed - date_created) AS avg_completion_time
FROM evanston311
WHERE date_completed - date_created < 
      (SELECT percentile_disc(0.95) WITHIN GROUP (ORDER BY date_completed - date_created)
       FROM evanston311)
GROUP BY category
ORDER BY avg_completion_time DESC;

/*Get corr() between avg. completion time and monthly requests. EXTRACT(epoch FROM interval) returns seconds in interval.*/

SELECT corr(avg_completion, count)
FROM (SELECT date_trunc('month', date_created) AS month, 
             avg(EXTRACT(epoch FROM date_completed - date_created)) AS avg_completion, 
             count(*) AS count
      FROM evanston311
      WHERE category='Rodents- Rats' 
      GROUP BY month) AS monthly_avgs;

/*Select the number of requests created and number of requests completed per month.*/

WITH created AS (
       SELECT date_trunc('month', date_created) AS month,
              count(*) AS created_count
         FROM evanston311
        WHERE category='Rodents- Rats'
        GROUP BY month),

completed AS (
       SELECT date_trunc('month', date_completed) AS month,
              count(*) AS completed_count
         FROM evanston311
        WHERE category='Rodents- Rats'
        GROUP BY month)

SELECT created.month, 
       created_count, 
       completed_count
FROM created
INNER JOIN completed
ON created.month = completed.month
ORDER BY created.month;
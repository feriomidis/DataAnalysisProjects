--- Database link: postgres://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/TravelTide


/*
Question #1:
Calculate the number of flights with a departure time during the work week (Monday through Friday) and the number of flights departing during the weekend (Saturday or Sunday).

Expected column names: working_cnt, weekend_cnt
*/

-- q1 solution:

SELECT 
    COUNT(CASE WHEN DATE_PART('dow', departure_time) IN (1,2,3,4,5) THEN trip_id END) AS working_cnt,
    COUNT(CASE WHEN DATE_PART('dow', departure_time) IN (0,6) THEN trip_id END) AS weekend_cnt
FROM 
    flights;



/*

Question #2: 
For users that have booked at least 2  trips with a hotel discount, it is possible to calculate their average hotel discount, and maximum hotel discount. write a solution to find users whose maximum hotel discount is strictly greater than the max average discount across all users.

Expected column names: user_id

*/

-- q2 solution:

with t1 as(
select 
       user_id,count(trip_id) as hotel_discount_cnt,
       max(hotel_discount_amount) as user_max_dis,
       avg(coalesce(hotel_discount_amount,0)) as user_avg_dis 
from sessions
where hotel_discount   and not cancellation and hotel_booked
group by 1
having sum(case when hotel_discount and hotel_booked and not cancellation then 1 else 0 end) >1)


select user_id from t1
where 
user_max_dis>(select max(user_avg_dis) from t1)

/*
Question #3: 
when a customer passes through an airport we count this as one “service”.

for example:

suppose a group of 3 people book a flight from LAX to SFO with return flights. In this case the number of services for each airport is as follows:

3 services when the travelers depart from LAX

3 services when they arrive at SFO

3 services when they depart from SFO

3 services when they arrive home at LAX

for a total of 6 services each for LAX and SFO.

find the airport with the most services.

Expected column names: airport

*/

-- q3 solution:

WITH airport_services AS (
    SELECT
        destination_airport AS airport,
        COUNT(*) AS departures
    FROM
        flights
    WHERE 
        return_flight_booked
    GROUP BY
        destination_airport
    UNION ALL
    SELECT
        origin_airport AS airport,
        COUNT(*) AS arrivals
    FROM
        flights
    GROUP BY
        origin_airport
)

select airport from
(SELECT
    airport,
    RANK() OVER (ORDER BY SUM(departures) DESC) AS departure_rank
FROM
    airport_services
GROUP BY
    airport
ORDER BY
    SUM(departures) DESC)sub
where departure_rank<2    


/*
Question #4: 
using the definition of “services” provided in the previous question, we will now rank airports by total number of services. 

write a solution to report the rank of each airport as a percentage, where the rank as a percentage is computed using the following formula: 

`percent_rank = (airport_rank - 1) * 100 / (the_number_of_airports - 1)`

The percent rank should be rounded to 1 decimal place. airport rank is ascending, such that the airport with the least services is rank 1. If two airports have the same number of services, they also get the same rank.

Return by ascending order of rank

E**xpected column names: airport, percent_rank**

Expected column names: airport, percent_rank
*/

-- q4 solution:

WITH airport_services AS (
    SELECT
        destination_airport AS airport,
        sum(seats) AS departures
    FROM
        flights
    WHERE 
        return_flight_booked
    GROUP BY
        destination_airport
    UNION ALL
    SELECT
        origin_airport AS airport,
        sum(seats) AS arrivals
    FROM
        flights
    GROUP BY
        origin_airport
),
ranked_airports AS (
    SELECT
        airport,
        SUM(departures) AS total_services,
        RANK() OVER (ORDER BY SUM(departures)) AS airport_rank
    FROM
        airport_services
    GROUP BY
        airport
)
SELECT
    airport,
    ROUND((PERCENT_RANK() OVER (ORDER BY airport_rank) * 100)::numeric, 1) AS percent_rank
    
FROM
    ranked_airports
ORDER BY
    airport_rank;




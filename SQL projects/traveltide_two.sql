
--- Database link: postgres://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/TravelTide

/*
Question #1:
return users who have booked and completed at least 10 flights, ordered by user_id.

Expected column names: `user_id`
*/

-- q1 solution:

SELECT 
    user_id,
    COUNT(DISTINCT trip_id) AS num_completed_flights
FROM 
    sessions
WHERE 
    flight_booked 
    AND NOT cancellation 
GROUP BY 
    user_id
HAVING 
    COUNT(DISTINCT trip_id) >= 10
    ORDER BY 1;


/*

Question #2: 
Write a solution to report the trip_id of sessions where:

1. session resulted in a booked flight
2. booking occurred in May, 2022
3. booking has the maximum flight discount on that respective day.

If in one day there are multiple such transactions, return all of them.

Expected column names: `trip_id`

*/

-- q2 solution:

WITH RankedSessions AS (
SELECT
trip_id,flight_discount,session_id,
date_trunc('day',session_end)AS booking_date,flight_booked,
flight_discount_amount,
RANK() OVER (PARTITION BY date_trunc('day',session_end) ORDER BY flight_discount_amount DESC) AS rank
FROM
sessions
WHERE

(session_end >= '2022-05-01')
AND (session_end < '2022-06-01')
AND flight_booked  
And flight_discount
and flight_discount_amount is not null
and trip_id is not null

)
SELECT
distinct trip_id
FROM
RankedSessions
WHERE
rank = 1
/*
Question #3: 
Write a solution that will, for each user_id of users with greater than 10 flights, 
find out the largest window of days between 
the departure time of a flight and the departure time 
of the next departing flight taken by the user.

Expected column names: `user_id`, `biggest_window`

*/

-- q3 solution:

WITH FlightGaps AS (
    SELECT
        user_id,
        departure_time,
        LEAD(departure_time) OVER (PARTITION BY user_id ORDER BY departure_time) AS next_departure_time,
        DATE_PART('day', LEAD(departure_time) OVER (PARTITION BY user_id ORDER BY departure_time) - departure_time) AS gap_days
    FROM
        flights
    JOIN
        sessions USING (trip_id)
    WHERE
        trip_id IS NOT NULL
)
SELECT
    user_id,
    MAX(gap_days) AS largest_window_days
FROM
    FlightGaps
GROUP BY
    user_id
HAVING
    COUNT(*) > 10;





/*
Question #4: 
Find the user_id’s of people whose origin airport is Boston (BOS) 
and whose first and last flight were to the same destination. 
Only include people who have flown out of Boston at least twice.

Expected column names: user_id
*/

-- q4 solution:

WITH BostonFlights AS (
    SELECT
       distinct  user_id,
       origin_airport,
        destination,
        trip_id,
  flight_booked,
        
        FIRST_VALUE(destination_airport) OVER (PARTITION BY user_id ORDER BY departure_time) AS first_destination,
        LAST_VALUE(destination_airport) OVER (PARTITION BY user_id ORDER BY departure_time ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_destination
    FROM
        flights
  join sessions
  using(trip_id)
    WHERE
        origin_airport = 'BOS' and trip_id is not null and flight_booked and cancellation=false
 
)

    SELECT
          user_id
    FROM
        BostonFlights
  where first_destination=last_destination 
  group by 1
having count(*)>=2
order by 1;

    

















-- to check for duplicate values in our primary key tripid
select tripid,count(tripid) cnt from trips_details group by tripid
having count(tripid)>1;

select tripid,count(tripid) cnt from trips group by tripid
having count(tripid)>1;

-- Q1.total trips(we can take into account as total number of trips where endride =1 or maybe total searches)

select count(distinct tripid) from trips_details;


-- Q2.total drivers

select count(distinct driverid) from trips;

-- Q3.total earnings

select sum(fare) from trips;

-- Q4.total Completed trips

select * from trips_details;
select sum(end_ride) from trips_details;

select count(distinct tripid) from trips;

-- Q5.total searches

select sum(searches) searches from trips_details;


-- Q6.Total searches which got estimate
select sum(searches_got_estimate) searches_estimated from trips_details;

-- Q7.total searches for quotes

select sum(searches_for_quotes) searches_quoted from trips_details;

-- Q8.total searches which got quotes
select sum(searches_got_quotes) searches_quoted from trips_details;

select * from trips;


select * from trips_details;


-- Q10.total cutomer cancelled ride
select count(*) - sum(customer_not_cancelled) driver_cancelled from trips_details;

-- Q11.total driver cancelled ride
select count(*) - sum(driver_not_cancelled) driver_cancelled from trips_details;

-- Q12.total otp entered
select sum(otp_entered) total_otp_entered from trips_details;

-- Q13.total end ride

select sum(end_ride) total_otp_entered from trips_details;

-- Q14.average distance per trip
select avg(distance) avg_distance from trips;

-- Q15.average fare per trip

select sum(fare)/count(*) avg_fare from trips;

-- Q16.total distance travelled
select sum(distance) total_distance from trips;

-- Q17.which is the most used payment method 
SELECT faremethod, COUNT(DISTINCT tripid) AS cnt
FROM trips
GROUP BY faremethod
ORDER BY cnt DESC;

-- Fetching the fare method with the highest count of distinct trips
SELECT faremethod, COUNT(DISTINCT tripid) AS cnt
FROM trips
GROUP BY faremethod
ORDER BY cnt DESC
LIMIT 1;

-- Joining with the payment table to fetch the payment method corresponding to the most common fare method
SELECT a.method
FROM payment a
JOIN (
    SELECT faremethod, COUNT(DISTINCT tripid) AS cnt
    FROM trips
    GROUP BY faremethod
    ORDER BY cnt DESC
    LIMIT 1
) b ON a.id = b.faremethod;

-- Q18.the highest payment was made through which instrument

/* the highest payment in the particular day can be the highest payment amount for particular trip and we can get the payment instrument for 
that particular trip */

-- Fetching the payment method for the trip with the highest fare
SELECT a.method
FROM payment a
INNER JOIN (
    SELECT *
    FROM trips
    ORDER BY fare DESC
    LIMIT 1
) b ON a.id = b.faremethod;


-- or 
/*we could just get a sum of the payment method and group by all payment to know which method had the highest payment amount done 
through entire day*/

-- Summing fares by payment method and finding the method with the highest total
SELECT a.method
FROM payment a
INNER JOIN (
    SELECT faremethod, SUM(fare) AS total_fare
    FROM trips
    GROUP BY faremethod
    ORDER BY total_fare DESC
    LIMIT 1
) b ON a.id = b.faremethod;

-- or

-- Determining which payment method had the highest total payment amount for the entire day
SELECT p.method, SUM(t.fare) AS total_fare
FROM trips t
JOIN payment p ON t.faremethod = p.id
GROUP BY p.id
ORDER BY total_fare DESC
LIMIT 1;

-- Q19.which two locations had the most trips

-- to get the locations between which customers are travelling the most (we can apply offer)


SELECT *
FROM (
    SELECT loc_from, loc_to, COUNT(DISTINCT tripid) AS trip_count,
           DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT tripid) DESC) AS rnk
    FROM trips
    GROUP BY loc_from, loc_to
) AS ranked_trips
WHERE rnk = 1;

SELECT loc_from, loc_to, COUNT(DISTINCT tripid) AS trip_count
FROM trips
GROUP BY loc_from, loc_to
HAVING trip_count = (
    SELECT MAX(trip_count) FROM (
        SELECT COUNT(DISTINCT tripid) AS trip_count
        FROM trips
        GROUP BY loc_from, loc_to
    ) AS subquery
);

-- to get the name as well
SELECT from_loc.assembly1 AS from_location_name, to_loc.assembly1 AS to_location_name, ranked_trips.trip_count
FROM (
    SELECT loc_from, loc_to, COUNT(DISTINCT tripid) AS trip_count,
           DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT tripid) DESC) AS rnk
    FROM trips
    GROUP BY loc_from, loc_to
) AS ranked_trips
JOIN loc as from_loc ON ranked_trips.loc_from = from_loc.id
JOIN loc as to_loc ON ranked_trips.loc_to = to_loc.id
WHERE ranked_trips.rnk = 1;


SELECT from_loc.assembly1 AS from_location_name, to_loc.assembly1 AS to_location_name, t.trip_count
FROM (
    SELECT loc_from, loc_to, COUNT(DISTINCT tripid) AS trip_count
    FROM trips
    GROUP BY loc_from, loc_to
    HAVING trip_count = (
        SELECT MAX(trip_count) FROM (
            SELECT COUNT(DISTINCT tripid) AS trip_count
            FROM trips
            GROUP BY loc_from, loc_to
        ) AS subquery
    )
) AS t
JOIN loc AS from_loc ON t.loc_from = from_loc.id
JOIN loc AS to_loc ON t.loc_to = to_loc.id;


-- Q20.top 5 earning drivers
SELECT driverid, SUM(fare) AS total_fare
FROM trips
GROUP BY driverid
ORDER BY total_fare DESC
LIMIT 5;
-- without using dense function
SELECT *
FROM (
  SELECT driverid, SUM(fare) AS total_fare,
         DENSE_RANK() OVER (ORDER BY SUM(fare) DESC) AS rnk
  FROM trips
  GROUP BY driverid
) AS ranked_drivers
WHERE rnk <= 5;


-- Q21.which duration had more trips
SELECT duration, trip_count
FROM (
    SELECT duration, COUNT(DISTINCT tripid) AS trip_count,
           RANK() OVER (ORDER BY COUNT(DISTINCT tripid) DESC) AS rnk
    FROM trips
    GROUP BY duration
) AS duration_rank
WHERE rnk = 1;

SELECT dur.duration, duration_rank.trip_count
FROM (
    SELECT t.duration, COUNT(DISTINCT t.tripid) AS trip_count,
           RANK() OVER (ORDER BY COUNT(DISTINCT t.tripid) DESC) AS rnk
    FROM trips t
    GROUP BY t.duration
) AS duration_rank
JOIN duration dur ON duration_rank.duration = dur.id
WHERE duration_rank.rnk = 1;


-- Q22.which driver , customer pair had more orders
SELECT driverid, custid, trip_count
FROM (
    SELECT driverid, custid, COUNT(tripid) AS trip_count,
           RANK() OVER (ORDER BY COUNT(tripid) DESC) AS rnk
    FROM trips
    GROUP BY driverid, custid
) AS trip_rank
WHERE rnk = 1;


-- Q23.search to estimate rate
SELECT (SUM(searches_got_estimate) * 100.0) / SUM(searches) AS estimate_rate
FROM trips_details;


-- Q24.estimate to search for quote rates
SELECT (SUM(searches_for_quotes) * 100.0) / SUM(searches_got_estimate) AS estimate_to_search_for_quote_rate
FROM trips_details;


-- Q25.quote acceptance rate
SELECT (SUM(searches_got_quotes) * 100.0) / SUM(searches_for_quotes) AS quote_acceptance_rate
FROM trips_details;


-- Q26.quote to booking rate
SELECT (SUM(otp_entered) * 100.0) / SUM(searches_got_quotes) AS quote_to_booking_rate
FROM trips_details;


-- Q27.booking cancellation rate
SELECT ((SUM(searches) - SUM(customer_not_cancelled)) * 100.0) / SUM(searches) AS booking_cancellation_rate
FROM trips_details;


-- Q28.conversion rate
-- Conversion_rate = calculate(sum(Merge2[end_ride])/sum(Merge2[searches]))
SELECT (SUM(end_ride) * 100.0) / SUM(searches) AS conversion_rate
FROM trips_details;

-- Q29.which area got highest trips in which duration
SELECT loc.assembly1 AS location, trip_counts.duration, trip_counts.trip_count
FROM (
    SELECT duration, loc_from, COUNT(DISTINCT tripid) AS trip_count,
           RANK() OVER (PARTITION BY duration ORDER BY COUNT(DISTINCT tripid) DESC) AS rnk
    FROM trips
    GROUP BY duration, loc_from
) AS trip_counts
JOIN loc ON loc.id = trip_counts.loc_from
WHERE trip_counts.rnk = 1;

-- Q30.which area got the highest fares, cancellations,trips,
-- for the area with the highest total fares:
SELECT loc_from, SUM(fare) AS total_fare
FROM trips
GROUP BY loc_from
ORDER BY total_fare DESC
LIMIT 1;
--  for the area with the highest number of cancellations:
SELECT loc_from, SUM(customer_not_cancelled = 0) AS total_cancellations
FROM trips_details
GROUP BY loc_from
ORDER BY total_cancellations DESC
LIMIT 1;
-- for the area with the most trips:
SELECT loc_from, COUNT(*) AS number_of_trips
FROM trips
GROUP BY loc_from
ORDER BY number_of_trips DESC
LIMIT 1;
-- join these results
-- assuming the loc_from field is a foreign key to the loc table's id field

SELECT L.assembly1 AS location, SUM(T.fare) AS total_fare
FROM trips T
JOIN loc L ON T.loc_from = L.id
GROUP BY L.id
ORDER BY total_fare DESC
LIMIT 1;

SELECT L.assembly1 AS location, SUM(TD.customer_not_cancelled = 0) AS total_cancellations
FROM trips_details TD
JOIN loc L ON TD.loc_from = L.id
GROUP BY L.id
ORDER BY total_cancellations DESC
LIMIT 1;

SELECT L.assembly1 AS location, COUNT(*) AS number_of_trips
FROM trips T
JOIN loc L ON T.loc_from = L.id
GROUP BY L.id
ORDER BY number_of_trips DESC
LIMIT 1;



-- Q31.which duration got the highest trips and fares
SELECT 
    duration, 
    trip_count, 
    total_fare
FROM (
    SELECT 
        duration, 
        COUNT(DISTINCT tripid) AS trip_count, 
        SUM(fare) AS total_fare,
        RANK() OVER (ORDER BY SUM(fare) DESC, COUNT(DISTINCT tripid) DESC) AS rnk
    FROM 
        trips
    GROUP BY 
        duration
) AS ranked_durations
WHERE 
    rnk = 1;





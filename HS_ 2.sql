CREATE DATABASE hospitality_analytics1;
USE hospitality_analytics1;

CREATE TABLE dim_date (
    date DATE PRIMARY KEY,
    mmm_yy VARCHAR(10),
    week_no INT,
    day_type VARCHAR(10)
);

CREATE TABLE dim_hotels (
    property_id INT PRIMARY KEY,
    property_name VARCHAR(100),
    category VARCHAR(50),
    city VARCHAR(50)
);

select * from dim_hotels;

CREATE TABLE dim_rooms (
    room_id VARCHAR(10) PRIMARY KEY,
    room_class VARCHAR(50)
);
select * from dim_rooms;

CREATE TABLE fact_aggregated_bookings (
    property_id INT,
    check_in_date DATE,
    room_category VARCHAR(10),
    successful_bookings INT,
    capacity INT
);

select * from fact_aggregated_bookings;

CREATE TABLE fact_bookings (
    booking_id VARCHAR(50) PRIMARY KEY,
    property_id INT,
    booking_date DATE,
    check_in_date DATE,
    check_out_date DATE,
    no_guests INT,
    room_category VARCHAR(10),
    booking_platform VARCHAR(50),
    ratings_given DECIMAL(3,1),
    booking_status VARCHAR(20),
    revenue_generated DECIMAL(10,2),
    revenue_realized DECIMAL(10,2)
);

select * from fact_bookings;

desc dim_date;
desc dim_hotels;
desc dim_rooms;
desc fact_aggregated_bookings;
desc fact_bookings;

SHOW COLUMNS FROM dim_date;

SHOW VARIABLES LIKE 'secure_file_priv';

-- Step 1: Truncate existing incomplete data
TRUNCATE TABLE fact_bookings;
TRUNCATE TABLE fact_aggregated_bookings;

-- Step 2: Load full CSV directly (fast & reliable)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_bookings.csv'
INTO TABLE fact_bookings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;




-- Load fact_aggregated_bookings
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_aggregated_bookings.csv'
INTO TABLE fact_aggregated_bookings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM fact_bookings;
SELECT COUNT(*) FROM fact_aggregated_bookings;
-----------------------------------------------------------------------------------------------------------------------------------------
## 1️ Total Revenue
SELECT 
SUM(revenue_realized) AS total_revenue
FROM fact_bookings;

## 02 Occupancy
##(Actual rooms booked vs total room capacity)
SELECT
  ROUND(
    SUM(successful_bookings) * 100.0 / SUM(capacity), 2
  ) AS occupancy_pct
FROM fact_aggregated_bookings;

## 03 Cancellation Rate
SELECT 
ROUND(
    (SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0) 
    / COUNT(booking_id), 2
) AS cancellation_rate
FROM fact_bookings;

## Total Bookings
SELECT COUNT(*) AS total_bookings
FROM fact_bookings;


## 05 Utilize Capacity

SELECT
  SUM(successful_bookings) AS total_successful_bookings,
  SUM(capacity) AS total_capacity,
  ROUND(
    SUM(successful_bookings) * 100.0
    / NULLIF(SUM(capacity), 0), 2
  )  AS utilization_pct
FROM fact_aggregated_bookings;

## 06 Trend Analysis
## (Daily revenue trend)

SELECT 
    fb.check_in_date,
    SUM(fb.revenue_realized) AS daily_revenue
FROM fact_bookings fb
GROUP BY fb.check_in_date
ORDER BY fb.check_in_date;

## 07 Weekday vs Weekend Revenue and Booking Count

SELECT 
    d.day_type,
    SUM(fb.revenue_realized) AS revenue,
    COUNT(fb.booking_id) AS total_bookings
FROM fact_bookings fb
JOIN dim_date d ON fb.check_in_date = d.date
GROUP BY d.day_type;

## 08 Revenue by State (City) & Hotel

SELECT 
    h.city,
    h.property_name,
    SUM(fb.revenue_realized) AS revenue
FROM fact_bookings fb
JOIN dim_hotels h ON fb.property_id = h.property_id
GROUP BY h.city, h.property_name
ORDER BY revenue DESC;


## 09 Class - Wise Revenue (Luxury vs Business hotels)
SELECT 
    h.category AS hotel_class,
    SUM(fb.revenue_realized) AS revenue
FROM fact_bookings fb
JOIN dim_hotels h ON fb.property_id = h.property_id
GROUP BY h.category;


## 10 Checked‑Out vs Cancel vs No- Show Counts
SELECT 
    booking_status,
    COUNT(*) AS total
FROM fact_bookings
GROUP BY booking_status;


## 11   Weekly Key Trend — Revenue, Total Bookings & Occupancy

SELECT
  d.`week no`  AS week_number,
  MIN(d.date)   AS week_start_date,

  -- Revenue
  SUM(fb.revenue_realized)  AS total_revenue,

  -- Total Bookings
  COUNT(fb.booking_id) AS total_bookings,

  -- Occupancy %
  ROUND(
    SUM(fa.successful_bookings) * 100.0
    / NULLIF(SUM(fa.capacity), 0), 2
  )    AS occupancy_pct

FROM dim_date d
LEFT JOIN fact_bookings fb
       ON STR_TO_DATE(d.date, '%d-%b-%y')
        = STR_TO_DATE(fb.check_in_date, '%Y-%m-%d')
LEFT JOIN fact_aggregated_bookings fa
       ON STR_TO_DATE(d.date, '%d-%b-%y')
        = STR_TO_DATE(fa.check_in_date, '%Y-%m-%d')
GROUP BY d.`week no`
ORDER BY d.`week no`;
----------------------------------------------------------------


SELECT
  d.`week no`  AS week_number,
  MIN(d.date)  AS week_start_date,

  -- Revenue
  SUM(fb.revenue_realized)   AS total_revenue,

  -- Total Bookings
  COUNT(fb.booking_id) AS total_bookings,

  -- Occupancy %
  ROUND(
    SUM(fa.successful_bookings) * 100.0
    / NULLIF(SUM(fa.capacity), 0), 2
  )   AS occupancy_pct

FROM dim_date d
LEFT JOIN fact_bookings fb
       ON STR_TO_DATE(fb.check_in_date, '%Y-%m-%d')
        = STR_TO_DATE(d.date, '%d-%b-%y')
LEFT JOIN fact_aggregated_bookings fa
       ON STR_TO_DATE(fa.check_in_date, '%Y-%m-%d')
        = STR_TO_DATE(d.date, '%d-%b-%y')
GROUP BY d.`week no`
ORDER BY d.`week no`;


-----------------------------------------------------------------------------------------------------------------------------
SELECT date FROM dim_date LIMIT 3;
SELECT check_in_date FROM fact_bookings LIMIT 3;


SELECT 
  MIN(check_in_date) AS min_date,
  MAX(check_in_date) AS max_date,
  COUNT(DISTINCT check_in_date) AS unique_dates
FROM fact_bookings;

SELECT 
  MIN(check_in_date) AS min_date,
  MAX(check_in_date) AS max_date,
  COUNT(DISTINCT check_in_date) AS unique_dates
FROM fact_aggregated_bookings;


SELECT 
  `week no`, 
  MIN(date) AS week_start, 
  MAX(date) AS week_end
FROM dim_date
GROUP BY `week no`
ORDER BY `week no`;


SELECT check_in_date 
FROM fact_aggregated_bookings 
LIMIT 3;



SELECT
  d.`week no`                                      AS week_number,
  MIN(d.date)                                     AS week_start_date,

  -- Revenue
  SUM(fb.revenue_realized)                        AS total_revenue,

  -- Total Bookings
  COUNT(fb.booking_id)                            AS total_bookings,

  -- Occupancy %
  ROUND(
    SUM(fa.successful_bookings) * 100.0
    / NULLIF(SUM(fa.capacity), 0), 2
  )                                                AS occupancy_pct

FROM dim_date d
LEFT JOIN fact_bookings fb
       ON STR_TO_DATE(fb.check_in_date, '%Y-%m-%d')
        = STR_TO_DATE(d.date, '%d-%b-%y')
LEFT JOIN fact_aggregated_bookings fa
       ON fa.check_in_date = d.date
GROUP BY d.`week no`
ORDER BY d.`week no`;

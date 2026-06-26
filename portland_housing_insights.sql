USE portland_house;

-- Average price over time
SELECT d.soldYear, AVG(f.price) AS avg_price
FROM housing f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.soldYear
ORDER BY d.soldYear;

-- Monthly price trend
SELECT d.soldMonth, AVG(h.price) as avg_price
FROM housing h JOIN dim_date d ON
h.date_id = d.date_id GROUP BY d.soldMonth
ORDER BY d.soldMonth;

-- Quarterly market trend
SELECT d.soldQuarter, AVG(f.price)
FROM housing f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.soldQuarter;

-- Year-over-year price growth
SELECT d.soldYear,
AVG(f.price) AS avg_price,
LAG(AVG(f.price)) OVER (ORDER BY d.soldYear) AS prev_year_price
FROM housing f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.soldYear;

-- other 
WITH yearly_avg AS (
    SELECT 
        d.soldYear,
        AVG(f.price) AS avg_price
    FROM housing f
    JOIN dim_date d 
        ON f.date_id = d.date_id
    GROUP BY d.soldYear
)

SELECT 
    soldYear,
    avg_price,
    LAG(avg_price) OVER (ORDER BY soldYear) AS prev_year_price,
    CONCAT(
        ROUND(
            (avg_price - LAG(avg_price) OVER (ORDER BY soldYear)) * 100.0 
            / LAG(avg_price) OVER (ORDER BY soldYear),
        0),
        '%'
    ) AS YoY
FROM yearly_avg;


-- Average price by home type
SELECT p.homeType, AVG(h.price) as avg_price
FROM housing h JOIN dim_property p ON h.property_id = p.property_id
GROUP BY p.homeType;

-- Price per sqft by home type
SELECT p.homeType, AVG(h.PricePerSqft) from housing h JOIN dim_property p
ON p.property_id = h.property_id 
GROUP BY p.homeType;

-- Most expensive cities
SELECT c.address_city, AVG(h.price) 
FROM housing h JOIN dim_city c 
ON h.city_id = c.city_id 
GROUP BY c.address_city ORDER BY AVG(h.price) DESC LIMIT 10;

-- Cheapest cities
SELECT c.address_city, AVG(h.price) 
FROM housing h JOIN dim_city c 
ON h.city_id = c.city_id 
GROUP BY c.address_city ORDER BY AVG(h.price) ASC LIMIT 10;

-- Price distribution by bedrooms
SELECT bedrooms, AVG(price)
FROM housing
GROUP BY bedrooms
ORDER BY bedrooms;

-- Top cities by number of listings
SELECT c.address_city, COUNT(*) as listings FROM
housing h JOIN dim_city c ON h.city_id = c.city_id 
GROUP BY c.address_city ORDER BY listings DESC LIMIT 10;

-- Average price by zipcode
SELECT c.address_zipcode, AVG(h.price) 
FROM housing h JOIN dim_city c 
ON h.city_id = c.city_id 
GROUP BY c.address_zipcode ORDER BY AVG(h.price);

-- Price heat by location
SELECT c.latitude, c.longitude, AVG(f.price)
FROM housing f
JOIN dim_city c ON f.city_id = c.city_id
GROUP BY c.latitude, c.longitude;

-- High-value locations (luxury homes)
SELECT c.address_city, COUNT(*) AS luxury_count
FROM housing f
JOIN dim_city c ON f.city_id = c.city_id
JOIN dim_property p ON f.property_id = p.property_id
WHERE p.IsLuxury = 1
GROUP BY c.address_city
ORDER BY luxury_count DESC;

-- Best school zones
SELECT s.AvgSchoolRating, AVG(f.PricePerSqft)
FROM housing f
JOIN dim_school s ON f.school_id = s.school_id
GROUP BY s.AvgSchoolRating
ORDER BY s.AvgSchoolRating DESC;

-- High tax vs low tax comparison
SELECT
CASE
    WHEN TaxToPriceRatio > 0.8 THEN 'High Tax'
    ELSE 'Low Tax'
END AS tax_bucket,
AVG(price)
FROM housing
GROUP BY tax_bucket;

-- Listings by year built
SELECT p.yearBuilt, AVG(f.price)
FROM housing f
JOIN dim_property p ON f.property_id = p.property_id
GROUP BY p.yearBuilt
ORDER BY p.yearBuilt DESC LIMIT 10;

-- summary
SELECT
COUNT(*) AS total_properties,
AVG(price) AS avg_price,
AVG(livingArea) AS avg_size,
ROUND(AVG(bedrooms)) AS avg_bedrooms
FROM housing;

-- Fastest appreciating cities (investment hotspots)
SELECT 
c.city_name,
AVG(f.price) AS current_price,
MIN(f.price) AS min_price,
(AVG(f.price) - MIN(f.price)) / MIN(f.price) AS appreciation_rate
FROM housing f
JOIN dim_city c ON f.city_id = c.city_id
GROUP BY c.city_name
ORDER BY appreciation_rate DESC;

-- Most “undervalued” homes (low price but large size)
SELECT 
c.city_name,
f.price,
f.livingArea,
(f.price / f.livingArea) AS price_per_sqft
FROM housing f
JOIN dim_city c ON f.city_id = c.city_id
ORDER BY price_per_sqft ASC
LIMIT 20;

-- What drives price more: size or bedrooms?
SELECT 
AVG(f.price / f.livingArea) AS price_per_sqft_by_size,
AVG(f.price / f.bedrooms) AS price_per_bedroom
FROM housing f;

-- Seasonal pricing effect
SELECT 
d.soldMonth,
AVG(f.price) AS avg_price
FROM housing f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.soldMonth
ORDER BY d.soldMonth;

-- Luxury vs non-luxury comparison (proper segmentation)
SELECT 
    p.IsLuxury,
    COUNT(*) AS total,
    ROUND(AVG(h.price)) AS avg_price,
    ROUND(AVG(h.livingArea)) AS avg_sqft,
    ROUND(AVG(h.PricePerSqft)) AS avg_price_sqft,
    ROUND(AVG(s.AvgSchoolRating), 1) AS avg_school_rating
FROM housing h
JOIN dim_property p ON h.property_id = p.property_id
JOIN dim_school s ON h.school_id = s.school_id
GROUP BY p.IsLuxury;

-- Moving average (smooths out monthly noise)
SELECT 
    d.soldYear,
    d.soldMonth,
    AVG(h.price) AS monthly_avg,
    ROUND(AVG(AVG(h.price)) OVER (
        ORDER BY d.soldYear, d.soldMonth
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )) AS rolling_3month_avg
FROM housing h
JOIN dim_date d ON h.date_id = d.date_id
GROUP BY d.soldYear, d.soldMonth;

-- School rating impact on price (binned)
SELECT 
    CASE 
        WHEN s.AvgSchoolRating >= 8 THEN 'Top rated (8+)'
        WHEN s.AvgSchoolRating >= 6 THEN 'Good (6-8)'
        WHEN s.AvgSchoolRating >= 4 THEN 'Average (4-6)'
        ELSE 'Below average (<4)'
    END AS school_tier,
    COUNT(*) AS listings,
    ROUND(AVG(h.price)) AS avg_price,
    ROUND(AVG(h.PricePerSqft)) AS avg_price_per_sqft
FROM housing h
JOIN dim_school s ON h.school_id = s.school_id
GROUP BY school_tier
ORDER BY avg_price DESC;

-- Price percentile ranking per city
SELECT 
    c.address_city,
    h.price,
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY c.address_city 
        ORDER BY h.price
    ) * 100, 1) AS price_percentile
FROM housing h
JOIN dim_city c ON h.city_id = c.city_id;

-- Running total (cumulative sales volume)
SELECT 
    d.soldYear,
    d.soldMonth,
    COUNT(*) AS monthly_listings,
    SUM(COUNT(*)) OVER (ORDER BY d.soldYear, d.soldMonth) AS cumulative_listings
FROM housing h
JOIN dim_date d ON h.date_id = d.date_id
GROUP BY d.soldYear, d.soldMonth;
--- Link to the database: postgresql://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/revroll?sslmode=require

/*
Question #1:

Identify installers who have participated in at least one installer competition by name.

Expected column names: name
*/

-- q1 solution:

SELECT name
FROM (
SELECT installer_one_id AS installer_id FROM install_derby
UNION
SELECT installer_two_id AS installer_id FROM install_derby
order by 1
) AS combined_installers
JOIN installers ON combined_installers.installer_id = installers.installer_id;

/*
Question #2: 
Write a solution to find the third transaction of every customer, where the spending on the preceding two transactions is lower than the spending on the third transaction. 
Only consider transactions that include an installation, and return the result table by customer_id in ascending order.

Expected column names: customer_id, third_transaction_spend, third_transaction_date
*/

-- q2 solution:

-- to rank transactions per customer
with ranked_transaction_per_customer AS (
    SELECT
        o.customer_id,
        order_id,
        price as spending,
        i.install_date as transaction_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY i.install_date) AS transaction_rank
    FROM
        installs i
    JOIN
        orders o
    USING
        (order_id)
    JOIN
        parts
    USING
        (part_id)
),

--  to compare spending on the third transaction with the max of preceding two transactions
compare_three_transactions AS (
    SELECT
        customer_id,
        SUM(CASE WHEN transaction_rank = 3 THEN spending ELSE 0 END) as third_transaction_spend
    FROM
        ranked_transaction_per_customer
    GROUP BY
        customer_id
    HAVING
        MAX(CASE WHEN transaction_rank <= 2 THEN spending ELSE 0 END) <
        SUM(CASE WHEN transaction_rank = 3 THEN spending ELSE 0 END)
    ORDER BY
        customer_id
)

-- Selecting the third transaction details if previous conditions satisfied
SELECT
    customer_id,
    third_transaction_spend,
    transaction_date as third_transaction_date
FROM
    compare_three_transactions
JOIN
    ranked_transaction_per_customer
USING
    (customer_id)
WHERE
    third_transaction_spend = spending
AND
    transaction_rank = 3;

/*
Question #3: 
Write a solution to report the most expensive part in each order. 
Only include installed orders. In case of a tie, report all parts with the maximum price. 
Order by order_id and limit the output to 5 rows.

Expected column names: order_id, part_id
*/

-- q3 solution:

-- to select installed orders
WITH installed AS (
    SELECT order_id,part_id
    FROM orders
    JOIN installs
    USING(order_id)
),

-- to find the maximum price-part per order
max_price_installed AS (
    SELECT 
        order_id,
        part_id,
        price,
        MAX(p.price) OVER (PARTITION BY i.order_id) AS max_price_per_order
    FROM 
        installed i
    JOIN 
        parts p
    USING(part_id)
)

-- Selecting part(s) per order with max price
SELECT 
    order_id,
    part_id
FROM 
    max_price_installed
WHERE 
    price = max_price_per_order
ORDER BY 
    order_id
LIMIT 5;

/*
Question #4: 
Write a query to find the installers who have completed installations for at least four consecutive days. 
Include the `installer_id`, start date of the consecutive installations period and the end date of the consecutive installations period. 

Return the result table ordered by `installer_id` in ascending order.

Expected column names: `installer_id`, `consecutive_start`, `consecutive_end`**
*/

-- q4 solution:

-- select distinct installer IDs and installation dates
with installations as (
    select distinct installer_id, install_date as installation_date 
    from installs
    order by install_date
),

-- to identify consecutive installations per installer
consecutive_installations AS (
    SELECT
        installer_id,
        installation_date,
        installation_date - ROW_NUMBER() OVER (PARTITION BY installer_id ORDER BY installation_date) * INTERVAL '1 DAY' AS grp
    FROM
        installations
)

-- Selecting installers with installations for at least four consecutive days
SELECT
    installer_id,
    MIN(installation_date) AS consecutive_start,
    MAX(installation_date) AS consecutive_end
FROM
    consecutive_installations
GROUP BY
    installer_id,
    grp
HAVING
    COUNT(*) >= 4
ORDER BY
    installer_id;
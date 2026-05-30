TRUNCATE TABLE
    public.brands,
    public.categories,
    public.customers,
    public.stores,
    public.staffs,
    public.products,
    public.orders,
    public.order_items,
    public.stocks,
	public.master_data
CASCADE;

-- 1. STORES-- Holds information about 3 store locations.
CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    phone VARCHAR(25),
    email VARCHAR(255),
    street VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(10),
    zip_code VARCHAR(10)
);

-- 2. BRANDS -- Holds brand information (Trek, Haro, etc.)
CREATE TABLE brands (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(255) NOT NULL
);

-- 3. CATEGORIES-- Holds product categories (Children Bicycles, Road Bikes, etc.)
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL
);

-- 4. PRODUCTS-- Holds all unique products. This table will link to brands and categories.
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year INT,
    list_price NUMERIC(10, 2) NOT NULL
);

-- 5. STAFFS-- All employees. This table links to the store they work at.
CREATE TABLE staffs (
    staff_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(25),
    active INT NOT NULL,
    store_id INT NOT NULL,
    manager_id INT
);

-- 6. CUSTOMERS-- All customers who have made purchases.
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(25),
    email VARCHAR(255) NOT NULL,
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(10),
    zip_code VARCHAR(10)
);

-- 7. ORDERS-- The main transaction header. Links to customer, store, and staff.
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_status INT NOT NULL,
    order_date DATE NOT NULL,
    required_date DATE NOT NULL,
    shipped_date DATE,
    store_id INT NOT NULL,
    staff_id INT NOT NULL
);

-- 8. ORDER_ITEMS --The line items for each order. This is a crucial "junction" table. Links to both orders and products.
CREATE TABLE order_items (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    list_price NUMERIC(10, 2) NOT NULL,
    discount NUMERIC(4, 2) NOT NULL DEFAULT 0,
    PRIMARY KEY (order_id, item_id)
);

-- 9. STOCKS -- Tracks the inventory (stock level) of each product at each store.
CREATE TABLE stocks (
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT,
    PRIMARY KEY (store_id, product_id)
);

--10. MASTER DATA
CREATE TABLE master_data (
    order_id INT,
    item_id INT,
    product_id INT,
    quantity INT,
    list_price NUMERIC(10, 2),
    discount NUMERIC(4, 2),
    customer_id INT,
    order_status INT,
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    store_id INT,
    staff_id INT,
    cust_first_name VARCHAR(255),
    cust_last_name VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(10),
    zip_code VARCHAR(10),
    product_name VARCHAR(255),
    brand_id INT,
    model_year INT,
    staffs_first_name VARCHAR(255),
    staffs_last_name VARCHAR(255),
    staffs_phone VARCHAR(50),
    staffs_active INT,
    manager_id INT,
    brand_name VARCHAR(255),
    revenue NUMERIC(10, 2),
    PRIMARY KEY (order_id, item_id)
);

select * from master_data;
select * from stores;
select * from brands;
select * from categories;
select * from products;
select * from staffs;
select * from customers;
select * from orders;
select * from order_items;
select * from stocks;


--Store-wise Sales Analysis
-- Calculates total sales revenue for each store.
SELECT
    s.store_name,
    m.store_id AS master_data_store_id,
    SUM(m.revenue) AS total_sales_revenue
FROM master_data m
LEFT JOIN stores s ON m.store_id = s.store_id
GROUP BY s.store_name, m.store_id
ORDER BY total_sales_revenue DESC;

-- Region-wise (State & City) Sales Analysis
-- Calculates total sales revenue grouped by store's state and city.
SELECT
    s.state,
    s.city,
    SUM(m.revenue) AS total_sales_revenue
FROM master_data m
JOIN stores s ON m.store_id = s.store_id
GROUP BY s.state, s.city
ORDER BY s.state, total_sales_revenue DESC;

-- Product-wise Sales
-- Ranks products by total units sold and total revenue generated.
SELECT
    m.product_name,
    m.brand_name,
    c.category_name,
    SUM(m.quantity) AS total_units_sold,
    SUM(m.revenue) AS total_revenue
FROM master_data m
JOIN products p ON m.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY m.product_id, m.product_name, m.brand_name, c.category_name
ORDER BY total_revenue DESC;

--Sales vs. Current Inventory
SELECT p.product_name, b.brand_name, c.category_name,
    COALESCE(sales.total_units_sold, 0) AS total_units_sold,
    COALESCE(stock.current_inventory, 0) AS current_total_inventory
FROM products p
JOIN brands b ON p.brand_id = b.brand_id
JOIN categories c ON p.category_id = c.category_id
-- Subquery to get total sales per product from master_data
LEFT JOIN (SELECT product_id, SUM(quantity) AS total_units_sold
    FROM master_data
    GROUP BY product_id
) AS sales ON p.product_id = sales.product_id
-- Subquery to get total current stock per product
LEFT JOIN (SELECT product_id,SUM(quantity) AS current_inventory
    FROM stocks
    GROUP BY product_id
) AS stock ON p.product_id = stock.product_id
ORDER BY total_units_sold DESC;

--Staff Sales Performance
SELECT
    m.staffs_first_name,
    m.staffs_last_name,
    s.store_name,
    COUNT(DISTINCT m.order_id) AS total_orders_handled,
    SUM(m.revenue) AS total_sales_generated
FROM master_data m
JOIN stores s ON m.store_id = s.store_id
WHERE m.staffs_active = 1 -- Let 1 means active
GROUP BY m.staff_id, m.staffs_first_name, m.staffs_last_name, s.store_name
ORDER BY total_sales_generated DESC;

--Top Customers by Lifetime Value
SELECT
    m.cust_first_name,
    m.cust_last_name,
    c.email, -- Email is not in master_data, so I join 'customers'
    m.city AS customer_city,
    m.state AS customer_state,
    COUNT(DISTINCT m.order_id) AS total_orders,
    SUM(m.revenue) AS total_lifetime_value
FROM master_data m
JOIN customers c ON m.customer_id = c.customer_id
GROUP BY m.customer_id, m.cust_first_name, m.cust_last_name, c.email, m.city, m.state
ORDER BY total_lifetime_value DESC
LIMIT 50;

--Customer Order Frequency
SELECT
    m.cust_first_name,
    m.cust_last_name,
    c.email, -- Email is not in master_data, so I join 'customers'
    COUNT(DISTINCT m.order_id) AS order_count
FROM master_data m
JOIN customers c ON m.customer_id = c.customer_id
GROUP BY m.customer_id, m.cust_first_name, m.cust_last_name, c.email
ORDER BY order_count DESC;


--Overall Revenue and Discoun

SELECT
    SUM(m.quantity * m.list_price) AS total_gross_revenue,
    SUM(m.quantity * m.list_price * m.discount) AS total_discount_amount,
    SUM(m.revenue) AS total_net_revenue,
    (SUM(m.quantity * m.list_price * m.discount) / SUM(m.quantity * m.list_price)) * 100 AS overall_discount_percentage
FROM master_data m;

--Discount Analysis by Brand
SELECT
    m.brand_name,
    SUM(m.quantity * m.list_price) AS total_gross_revenue,
    SUM(m.quantity * m.list_price * m.discount) AS total_discount_amount,
    SUM(m.revenue) AS total_net_revenue,
    AVG(m.discount) * 100 AS average_discount_percentage
FROM master_data m
GROUP BY m.brand_name
ORDER BY total_discount_amount DESC;


--Discount Analysis by Category
SELECT
    c.category_name,
    SUM(m.quantity * m.list_price) AS total_gross_revenue,
    SUM(m.quantity * m.list_price * m.discount) AS total_discount_amount,
    SUM(m.revenue) AS total_net_revenue,
    AVG(m.discount) * 100 AS average_discount_percentage
FROM master_data m
JOIN products p ON m.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_discount_amount DESC;

--SQL Views for Reusable Insights.
CREATE VIEW SalesDetails AS
SELECT
    m.order_id,
    m.order_date,
    m.order_status,
    m.item_id,
    m.quantity,
    m.list_price,
    m.discount,
    m.revenue AS net_revenue_item,
    m.product_id,
    m.product_name,
    m.brand_name,
    c.category_name,
    s.store_id,
    s.store_name,    
    s.city AS store_city,
    s.state AS store_state,
    m.staff_id,
    m.staffs_first_name,
    m.staffs_last_name,
    m.customer_id,
    m.cust_first_name,
    m.cust_last_name,
    cust.email AS customer_email,
    m.city AS cust_city,
    m.state AS cust_state
FROM master_data m
JOIN stores s ON m.store_id = s.store_id
JOIN products p ON m.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN customers cust ON m.customer_id = cust.customer_id;

SELECT * FROM SalesDetails;

---- Get total sales per brand for 2016
SELECT brand_name, SUM(net_revenue_item) AS total_sales_2016
FROM SalesDetails
WHERE EXTRACT(YEAR FROM order_date) = 2016
GROUP BY brand_name
ORDER BY total_sales_2016 DESC;

---- Get total sales per brand for 2017
SELECT brand_name, SUM(net_revenue_item) AS total_sales_2017
FROM SalesDetails
WHERE EXTRACT(YEAR FROM order_date) = 2017
GROUP BY brand_name
ORDER BY total_sales_2017 DESC;

-- Get total sales per brand for 2018
SELECT brand_name, SUM(net_revenue_item) AS total_sales_2018
FROM SalesDetails
WHERE EXTRACT(YEAR FROM order_date) = 2018
GROUP BY brand_name
ORDER BY total_sales_2018 DESC;

--view for the Sales vs. Inventory analysis
CREATE VIEW ProductInventory AS
SELECT
    p.product_id,
    p.product_name,
    b.brand_name,
    c.category_name,
    p.list_price,
    COALESCE(sales.total_units_sold, 0) AS total_units_sold,
    COALESCE(stock.current_inventory, 0) AS current_total_inventory,
    (COALESCE(stock.current_inventory, 0) * p.list_price) AS inventory_value
FROM products p
LEFT JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN categories c ON p.category_id = c.category_id
LEFT JOIN (
    SELECT
        product_id,
        SUM(quantity) AS total_units_sold
    FROM master_data
    GROUP BY product_id
) AS sales ON p.product_id = sales.product_id
LEFT JOIN (
    SELECT
        product_id,
        SUM(quantity) AS current_inventory
    FROM stocks
    GROUP BY product_id
) AS stock ON p.product_id = stock.product_id;

SELECT * FROM ProductInventory;

--items that are overstocked
SELECT product_name, brand_name, total_units_sold, current_total_inventory
FROM ProductInventory
WHERE current_total_inventory > 10 AND total_units_sold < 5
ORDER BY current_total_inventory DESC;









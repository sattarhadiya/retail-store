

DROP DATABASE IF EXISTS retail;
CREATE DATABASE retail;
USE retail;

SET FOREIGN_KEY_CHECKS = 0;



CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    join_date DATE NOT NULL,
    gender VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    brand VARCHAR(100),
    unit_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2),
    active BOOLEAN DEFAULT TRUE
);

CREATE TABLE stores (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE promotions (
    promo_id INT AUTO_INCREMENT PRIMARY KEY,
    promo_name VARCHAR(255),
    promo_type VARCHAR(50),
    value DECIMAL(10,2),
    start_date DATE,
    end_date DATE
);

CREATE TABLE dim_date (
    d DATE PRIMARY KEY,
    day_num INT,
    month_num INT,
    month_name VARCHAR(20),
    year_num INT,
    quarter_num INT,
    day_of_week INT
);

CREATE TABLE sales (
    sale_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sale_date DATE NOT NULL,
    customer_id INT,
    store_id INT,
    product_id INT,
    promo_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (promo_id) REFERENCES promotions(promo_id)
);


INSERT INTO customers (first_name,last_name,email,phone,join_date,gender,city,state,country) VALUES
('Asha','Kumar','asha.kumar@example.com','+919900112233','2023-02-10','F','Mumbai','Maharashtra','India'),
('Ravi','Patel','ravi.patel@example.com','+919988776655','2022-11-05','M','Ahmedabad','Gujarat','India'),
('Sara','Verma','sara.verma@example.com','+919911223344','2024-01-15','F','Bengaluru','Karnataka','India'),
('John','Doe','john.doe@example.com','+919900445566','2021-06-20','M','Delhi','Delhi','India');

INSERT INTO products (sku,name,category,brand,unit_price,cost_price) VALUES
('P1001','Wireless Mouse','Accessories','LogiTech',599.00,250.00),
('P1002','Mechanical Keyboard','Accessories','KeyPro',2499.00,1200.00),
('P2001','27\" Monitor','Displays','ViewMax',15999.00,9500.00),
('P3001','USB-C Cable 1m','Accessories','CableMate',199.00,40.00),
('P4001','Laptop 14\" i5','Computers','CompEdge',54999.00,42000.00);

INSERT INTO stores (name,city,state,country) VALUES
('Central Mall Branch','Mumbai','Maharashtra','India'),
('Tech Plaza','Bengaluru','Karnataka','India'),
('City Center Store','Delhi','Delhi','India');

INSERT INTO promotions (promo_name,promo_type,value,start_date,end_date) VALUES
('Diwali Sale 20%','Percent',20,'2024-10-20','2024-11-05'),
('Clearance - Flat 500','Flat',500,'2024-12-01','2024-12-31'),
('New Year 10%','Percent',10,'2025-01-01','2025-01-10');

INSERT INTO dim_date
SELECT 
    d,
    DAY(d),
    MONTH(d),
    MONTHNAME(d),
    YEAR(d),
    QUARTER(d),
    WEEKDAY(d)
FROM (
    SELECT DATE_ADD('2023-01-01', INTERVAL seq DAY) AS d
    FROM (
        SELECT @row:=@row+1 AS seq 
        FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
             (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
             (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
             (SELECT @row:= -1) r
    ) AS days
    WHERE DATE_ADD('2023-01-01', INTERVAL seq DAY) <= '2025-12-31'
) dt;


INSERT INTO sales
(sale_date, customer_id, store_id, product_id, promo_id, quantity, unit_price, discount_amount, total_amount, payment_method)
VALUES
('2024-11-01',1,1,1,1,2,599, ROUND(2*599*0.20,2), ROUND(2*599 - (2*599*0.20),2), 'Card'),
('2024-11-02',2,2,2,1,1,2499, ROUND(2499*0.20,2), ROUND(2499-(2499*0.20),2), 'UPI'),
('2024-12-05',3,2,5,2,1,54999,500,54499, 'Card'),
('2025-01-02',4,3,3,3,1,15999, ROUND(15999*0.10,2), ROUND(15999-(15999*0.10),2), 'Cash'),
('2024-12-15',1,1,4,NULL,3,199,0,597, 'Card'),
('2024-10-25',2,3,2,1,2,2499, ROUND(2*2499*0.20,2), ROUND(2*2499-(2*2499*0.20),2), 'UPI'),
('2024-11-03',3,1,1,1,1,599, ROUND(599*0.20,2), ROUND(599-(599*0.20),2), 'Card');




CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_store ON sales(store_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);




CREATE OR REPLACE VIEW vw_daily_sales_summary AS
SELECT 
    s.sale_date,
    dd.year_num AS year,
    dd.month_num AS month,
    SUM(s.quantity) AS total_quantity,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.discount_amount) AS total_discount,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM sales s
JOIN dim_date dd ON dd.d = s.sale_date
GROUP BY s.sale_date, dd.year_num, dd.month_num;

CREATE OR REPLACE VIEW vw_monthly_top_products AS
SELECT
    dd.year_num,
    dd.month_num,
    p.product_id,
    p.name AS product_name,
    SUM(s.quantity) AS qty_sold,
    SUM(s.total_amount) AS revenue
FROM sales s
JOIN products p ON p.product_id = s.product_id
JOIN dim_date dd ON dd.d = s.sale_date
GROUP BY dd.year_num, dd.month_num, p.product_id, p.name
ORDER BY dd.year_num, dd.month_num, revenue DESC;

CREATE OR REPLACE VIEW vw_customer_ltv AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.join_date,
    COUNT(s.sale_id) AS transactions,
    COALESCE(SUM(s.total_amount),0) AS total_spent,
    CASE WHEN COUNT(s.sale_id)=0 THEN 0
         ELSE ROUND(SUM(s.total_amount)/COUNT(s.sale_id),2)
    END AS avg_order_value
FROM customers c
LEFT JOIN sales s ON s.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_spent DESC;



DELIMITER $$

CREATE PROCEDURE monthly_sales_report(IN p_year INT, IN p_month INT)
BEGIN
    SELECT 
        dd.year_num AS year,
        dd.month_num AS month,
        SUM(s.total_amount) AS total_revenue,
        SUM(s.quantity) AS total_quantity,
        ROUND(SUM(s.total_amount)/COUNT(s.sale_id),2) AS avg_order_value,
        COUNT(DISTINCT s.customer_id) AS unique_customers
    FROM sales s
    JOIN dim_date dd ON dd.d = s.sale_date
    WHERE dd.year_num = p_year AND dd.month_num = p_month
    GROUP BY dd.year_num, dd.month_num;
END $$

CREATE PROCEDURE top_n_products(IN p_year INT, IN p_month INT, IN p_n INT)
BEGIN
    SELECT 
        p.product_id,
        p.name AS product_name,
        SUM(s.quantity) AS qty_sold,
        SUM(s.total_amount) AS revenue
    FROM sales s
    JOIN products p ON p.product_id = s.product_id
    JOIN dim_date dd ON dd.d = s.sale_date
    WHERE dd.year_num = p_year AND dd.month_num = p_month
    GROUP BY p.product_id, p.name
    ORDER BY revenue DESC
    LIMIT p_n;
END $$

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;


select * from customers;


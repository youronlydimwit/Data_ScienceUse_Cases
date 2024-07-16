create database BikeStore

-- Adding Foreign Keys
---- Products
ALTER TABLE products
ADD CONSTRAINT Brand_to_Prod
FOREIGN KEY (brand_id) REFERENCES brands(brand_id);

ALTER TABLE products
ADD CONSTRAINT Cat_to_Prod
FOREIGN KEY (category_id) REFERENCES categories(category_id);

---- Staffs
ALTER TABLE staffs
ALTER COLUMN store_id TINYINT

ALTER TABLE staffs
ADD CONSTRAINT Store_to_Staff
FOREIGN KEY (store_id) REFERENCES stores(store_id);

---- Stocks
ALTER TABLE stocks
ADD CONSTRAINT Store_to_Stock
FOREIGN KEY (store_id) REFERENCES stores(store_id);

ALTER TABLE stocks
ADD CONSTRAINT Prod_to_Stock
FOREIGN KEY (product_id) REFERENCES products(product_id);

---- Orders
ALTER TABLE orders
ADD CONSTRAINT PK_Orders
PRIMARY KEY (order_id);

ALTER TABLE orders
ADD CONSTRAINT Cust_to_Orders
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE orders
ADD CONSTRAINT Store_to_Orders
FOREIGN KEY (store_id) REFERENCES stores(store_id);

ALTER TABLE orders
ADD CONSTRAINT Staff_to_Orders
FOREIGN KEY (staff_id) REFERENCES staffs(staff_id);

--- Order_Items
ALTER TABLE order_items
ADD CONSTRAINT orderItems_to_orders
FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- BEGINNER LEVELS
--- Retrieve a list of full names and ID's of customers in the database.
SELECT DISTINCT
[Customer ID] = customer_id,
[Full Name] = CONCAT(first_name, ' ',last_name)
FROM
BikeStore.dbo.customers 

--- Find the total number of orders placed by each customer, sort it from largest to smallest.
SELECT
[Customer ID] = C.customer_id,
[Full Name] = CONCAT(C.first_name, ' ',C.last_name),
[Order Count] = COUNT(O.order_id)
FROM
BikeStore.dbo.customers C join BikeStore.dbo.orders O on C.customer_id = O.customer_id
GROUP BY
C.customer_id, C.first_name, C.last_name
ORDER BY
[Order Count] desc

--- List all the products in a specific category.
SELECT
[Category] = category_name,
[Product Name] = product_name
FROM products P join categories C on P.category_id = C.category_id

--- Calculate the total sales (without discount) for a specific store.
SELECT
[Store Name] = store_name,
[Total Sales] = CAST(SUM(O.list_price*quantity) as INT)
FROM
stores S join orders D on S.store_id = D.store_id join order_items O on D.order_id = O.order_id
GROUP BY
store_name
ORDER BY
[Store Name] desc

--- Get the names of staff members working at Baldwin Bikes.
SELECT
[Full Name] = CONCAT(S.first_name, ' ',S.last_name)
FROM
staffs S join stores T on S.store_id = T.store_id
WHERE T.store_name like 'Baldwin Bikes'

--- Find the brands of products that are out of stock.
SELECT DISTINCT
[Brand] = B.brand_name,
[Stock] = S.quantity
FROM brands B join products P on B.brand_id = P.brand_id join stocks S on S.product_id = P.product_id
WHERE S.quantity = 0

--- Identify the store names, couunt of them buying from that store, placed by Onita Johns.
SELECT
[Full Name] = CONCAT(C.first_name, ' ',C.last_name),
[Store Name] = S.store_name,
[Count of Orders] = COUNT(order_id)
FROM customers C join orders O on C.customer_id = O.customer_id join stores S on O.store_id = S.store_id
WHERE C.first_name like 'Onita' AND C.last_name like 'Johns'
GROUP BY
C.first_name, C.last_name, S.store_name

--- List all products that are only ordered <=5 times.
SELECT
[Product Name] = P.product_name,
[Order Count] = COUNT(O.order_id)
FROM order_items O join products P on P.product_id = O.product_id
GROUP BY P.product_name
HAVING COUNT(O.order_id) < 5 or COUNT(O.order_id) = 5

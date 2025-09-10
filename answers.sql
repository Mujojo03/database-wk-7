USE first_normalization;

-- 1.1: draft the original denormalized table and insert sample rows
DROP TABLE IF EXISTS ProductDetail;
CREATE TABLE ProductDetail (
  OrderID INT,
  CustomerName VARCHAR(100),
  Products VARCHAR(255)
);

INSERT INTO ProductDetail (OrderID, CustomerName, Products) VALUES
(101, 'John Doe', 'Laptop, Mouse'),
(102, 'Jane Smith', 'Tablet, Keyboard, Mouse'),
(103, 'Emily Clark', 'Phone');

-- 1.2: Create the normalized 1NF table (one product per row)
DROP TABLE IF EXISTS ProductDetail_1NF;
CREATE TABLE ProductDetail_1NF (
  OrderID INT,
  CustomerName VARCHAR(100),
  Product VARCHAR(100)
);

-- 1.3: Populate ProductDetail_1NF
INSERT INTO ProductDetail_1NF (OrderID, CustomerName, Product)
SELECT
  pd.OrderID,
  pd.CustomerName,
  TRIM(jt.product) AS Product
FROM ProductDetail pd
CROSS JOIN JSON_TABLE(
  CONCAT('["', REPLACE(pd.Products, ', ', '","'), '"]'),
  '$[*]' COLUMNS (product VARCHAR(100) PATH '$')
) AS jt;

-- Verify transformation to 1NF
SELECT * FROM ProductDetail_1NF ORDER BY OrderID;

-- 2.1: Create the sample OrderDetails (already in 1NF)
DROP TABLE IF EXISTS OrderDetails;
CREATE TABLE OrderDetails (
  OrderID INT,
  CustomerName VARCHAR(100),
  Product VARCHAR(100),
  Quantity INT
);

INSERT INTO OrderDetails (OrderID, CustomerName, Product, Quantity) VALUES
(101, 'John Doe',    'Laptop',   2),
(101, 'John Doe',    'Mouse',    1),
(102, 'Jane Smith',  'Tablet',   3),
(102, 'Jane Smith',  'Keyboard', 1),
(102, 'Jane Smith',  'Mouse',    2),
(103, 'Emily Clark', 'Phone',    1);

-- 2.2: Create Orders table (Order-level info) to remove partial dependency
DROP TABLE IF EXISTS Orders;
CREATE TABLE Orders (
  OrderID INT PRIMARY KEY,
  CustomerName VARCHAR(100)
);

-- Populate Orders with distinct order-level data
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName FROM OrderDetails;

-- 2.3: Create OrderItems table (order-line items) - now non-key columns fully depend on PK (OrderID,Product)
DROP TABLE IF EXISTS OrderItems;
CREATE TABLE OrderItems (
  OrderID INT,
  Product VARCHAR(100),
  Quantity INT,
  PRIMARY KEY (OrderID, Product),
  CONSTRAINT fk_orderitems_orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Populate OrderItems from the original OrderDetails
INSERT INTO OrderItems (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity FROM OrderDetails;

-- Verify the results (now in 2NF)
SELECT * FROM Orders ORDER BY OrderID;
SELECT * FROM OrderItems ORDER BY OrderID, Product;

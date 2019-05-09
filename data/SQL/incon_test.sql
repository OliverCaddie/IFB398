CREATE VIEW PObad AS
SELECT t1.*
FROM POdata AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM POdata
GROUP BY Purch_Doc_, Item
HAVING COUNT(Item) > 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

SELECT COUNT(1)
FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM PObad) AS t;

CREATE VIEW incon_1 AS 
SELECT t2.*
FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING COUNT(Quantity) > 1 AND SUM(CAST(Quantity AS FLOAT)) = CAST(Qty_Delivered AS FLOAT)) AS t1
JOIN PObad AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

SELECT COUNT(1)
FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM incon_1) AS t;

CREATE VIEW incon_2 AS 
SELECT t2.*
FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item, Quantity
HAVING COUNT(Quantity) > 1 AND SUM(CAST(Qty_Delivered AS FLOAT)) = CAST(Quantity AS FLOAT)) AS t1
JOIN PObad AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

SELECT COUNT(1)
FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM incon_2) AS t;




SELECT 1
FROM incon_1 AS t1 JOIN incon_2 AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_;



SELECT TOP (100) * FROM incon_2;















SELECT Purch_Doc_, Item
INTO i1
FROM PObad
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING COUNT(Quantity) > 1 
AND SUM(CAST(Quantity AS FLOAT)) = CAST(Qty_Delivered AS FLOAT);

SELECT DISTINCT Purch_Doc_, Item
INTO i2
FROM PObad
GROUP BY Purch_Doc_, Item, Quantity
HAVING COUNT(Quantity) > 1 
AND CAST(Quantity AS FLOAT) <> 0 
AND SUM(CAST(Qty_Delivered AS FLOAT)) = CAST(Quantity AS FLOAT);


CREATE VIEW PObad2 AS
SELECT t1.*
FROM PObad AS t1 LEFT JOIN (
SELECT * FROM i1 
UNION 
SELECT * FROM i2) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
WHERE t2.Purch_Doc_ IS NULL AND t2.Item IS NULL;

SELECT COUNT(1) FROM (SELECT DISTINCT Purch_Doc_, Item FROM PObad3) AS t;

SELECT 
FROM (SELECT DISTINCT * FROM PObad2) AS t1


SELECT TOP (100) * FROM PObad2 ORDER BY Purch_Doc_, LEN(Item), Item;

DROP VIEW PObad3

CREATE VIEW PObad3 AS
SELECT t1.*
FROM PObad2 AS t1 LEFT JOIN (
SELECT Purch_Doc_, Item
FROM (SELECT DISTINCT * FROM PObad2) AS t
GROUP BY Purch_Doc_, Item
HAVING COUNT(Item) > 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
WHERE t2.Purch_Doc_ IS NOT NULL AND t2.Item IS NOT NULL;



SELECT TOP (100) * FROM PObad3 ORDER BY Purch_Doc_, LEN(Item), Item;
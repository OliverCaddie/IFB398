DROP TABLE IF EXISTS purchase_delivery, purchase_item, purchase_order;

CREATE TABLE purchase_order (
purchase_id BIGINT PRIMARY KEY,
brand CHAR(3),
ord_date DATE,
vendor VARCHAR(10),
del_site char(4),
deleted BIT,
);

CREATE TABLE purchase_item (
purchase_id BIGINT,
item INT,
category CHAR(6),
article VARCHAR(10),
vendor_article VARCHAR(50),
quantity FLOAT,
net_price MONEY,
--mov_avg_price MONEY,
delivered BIT,
PO_date date,
calc_date date,
PRIMARY KEY (purchase_id, item),
FOREIGN KEY (purchase_id) REFERENCES purchase_order (purchase_id)
);

CREATE TABLE purchase_delivery (
purchase_id BIGINT,
item INT,
post_date date,
entry_date date,
sch_qty FLOAT,
del_qty FLOAT,
qty FLOAT,
PRIMARY KEY (purchase_id, item, post_date, entry_date),
FOREIGN KEY (purchase_id, item) REFERENCES purchase_item (purchase_id, item)
);

SELECT * 
INTO POinsert
FROM (
SELECT *
FROM POgood
UNION
SELECT *
FROM type1
UNION
SELECT *
FROM type2
UNION
SELECT *
FROM type3
UNION
SELECT *
FROM type4) AS t;

INSERT INTO purchase_order
SELECT DISTINCT [Purch_Doc_], [POrg], [Doc__Date], [Vendor], [Site], CASE WHEN [D] IS NULL THEN 0 ELSE 1 END 
FROM POinsert;

INSERT INTO purchase_item
SELECT DISTINCT [Purch_Doc_]
		, [Item]
		, CASE WHEN LEN(Mdse_Cat_) < 6 THEN REPLICATE('0', 6 - LEN(Mdse_Cat_)) + Mdse_Cat_ ELSE Mdse_Cat_ END
		, [Article]
		, [Vendor_Article_Number]
		, [PO_Quantity]
		, [Net_Price]
		--, [MovAvgPrice]
		, CASE WHEN [DCI] IS NULL THEN 0 ELSE 1 END
		, [Deliv__Date]
		, [StatDelD]  
FROM POinsert;

INSERT INTO purchase_delivery
SELECT DISTINCT [Purch_Doc_], [Item], [Pstng_Date], [Entry_Dte], [Scheduled_Qty], [Qty_Delivered], [Quantity]
FROM POinsert;
/******************************************************************************/

SELECT * FROM purchase_order t1 JOIN purchase_item t2
ON t1.purchase_id = t2.purchase_id;

/*

INSERT INTO purchase_order  
SELECT DISTINCT [Purch_Doc_],[POrg],[Doc__Date],[Vendor],[Site]
FROM POgood;

INSERT INTO purchase_item
SELECT DISTINCT t.Purch_Doc_, t.Item, s.Category, s.sub, s.merch, t.Article, t.Vendor_Article_Number, t.PO_Quantity, t.Net_Price, t.MovAvgPrice
FROM POgood t LEFT JOIN hierarchy_import s ON s.Merchandise_Category =  t.Mdse_Cat_;




USE srg;
ALTER TABLE POgood ADD dBit BIT;
ALTER TABLE POgood ADD dciBit BIT;

UPDATE POgood 
SET dBit = 1
WHERE D IS NOT NULL;

UPDATE POgood 
SET dciBit = 1
WHERE DCI IS NOT NULL;

UPDATE POgood 
SET dBit = 0
WHERE D IS NULL;

UPDATE POgood 
SET dciBit = 0
WHERE DCI IS NULL;


INSERT INTO purchase_delivery
SELECT DISTINCT Purch_Doc_, Item, dBit, dciBit, Deliv__Date, StatDelD, Pstng_Date, Entry_Dte, Scheduled_Qty, Qty_Delivered, Quantity
FROM POgood;

SELECT TOP (1000) * FROM purchase_delivery;


SELECT TOP (100) * FROM purchase_delivery ORDER BY purchase_id, item;

SELECT COUNT(1)
FROM (SELECT DISTINCT Object_value FROM chgtest) AS a;

SELECT * FROM chgtest WHERE Doc__no_ IS NULL OR Object_value IS NULL;

SELECT *
FROM chgtest
WHERE Object_value IN (
SELECT Object_value 
FROM chgtest
GROUP BY Object_value
HAVING COUNT(DISTINCT Doc__no_) > 1)
ORDER BY Object_value;

SELECT * 
FROM POdata 
WHERE Purch_Doc_ = '4510608722' AND PO_Quantity IN (13, 6, 47, 11)
ORDER BY PO_Quantity, Item;

SELECT * FROM chgtest WHERE Object_value = 4510608722

SELECT TOP (10) * FROM POdata

4.204510680729E+21*/
CREATE TABLE purchase_order (
order_id BIGINT PRIMARY KEY,
brand CHAR(3),
ord_date DATE,
vendor VARCHAR(10),
del_site char(4)
)

CREATE TABLE purchase_item (
purchase_id BIGINT,
item INT,
cat_id CHAR(2),
sub_id CHAR(2),
merch_id CHAR(2),
article VARCHAR(10),
vendor_article VARCHAR(50),
quantity INT,
net_price MONEY,
mov_avg_price MONEY,

PRIMARY KEY (purchase_id, item),
FOREIGN KEY (purchase_id) REFERENCES purchase_order (order_id),
FOREIGN KEY (cat_id, sub_id, merch_id) REFERENCES merch_category (cat_id, sub_id, merch_id),
);

CREATE TABLE purchase_delivery (
purchase_id BIGINT,
item INT,
deleted BIT,
delivered BIT,
PO_date date,
calc_date date,
post_date date,
entry_date date,
)

SELECT  * FROM POgood WHERE Quantity <> Qty_Delivered

SELECT * FROM POdata WHERE Purch_Doc_ = 4510587975

/* CREATE TABLE OF WELL BEHAVED DATA */
SELECT *
INTO POgood
FROM POdata
WHERE Purch_Doc_ NOT IN (
SELECT Purch_Doc_
FROM POdata
GROUP BY Purch_Doc_, Item
HAVING COUNT(Item) > 1
);

/* BAD, DATA, BAD */
SELECT *
INTO PObad
FROM POdata
WHERE Purch_Doc_ IN (
SELECT Purch_Doc_
FROM POdata
GROUP BY Purch_Doc_, Item
HAVING COUNT(Item) > 1
);





INSERT INTO purchase_order  
SELECT DISTINCT [Purch_Doc_],[POrg],[Doc__Date],[Vendor],[Site]
FROM POdata;

SELECT TOP (1000) * FROM purchase_order;
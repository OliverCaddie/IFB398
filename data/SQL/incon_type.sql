/* STEP 1 */
/* SELECT ALL THE DATA THAT DOESN'T CONTAIN DUPLICATE ITEM NUMBERS */
SELECT t1.*
INTO POgood
FROM POdata AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM POdata
GROUP BY Purch_Doc_, Item
HAVING COUNT(*) = 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

/* STEP 2 */
/* SELECT ALL THE DATA THAT DOES CONTAIN DUPLICATE ITEM NUMBERS */
SELECT t1.*
INTO PObad
FROM POdata AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM POdata
GROUP BY Purch_Doc_, Item
HAVING COUNT(Item) > 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 3 */
/* SELECT PO and Item no. FROM PObad WHERE Qty_Delivered = SUM(Quantity) */
SELECT Purch_Doc_, Item
INTO i1
FROM PObad
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING COUNT(Quantity) > 1 
AND SUM(CAST(Quantity AS FLOAT)) = CAST(Qty_Delivered AS FLOAT);


/* CREATING THE INCONSISTENCY TYPE 1 TABLE:
	CONTAINS ALL OF THE DATA GROUPED BY PO, Item, Date THAT HAS Qty_Delivered = SUM(Quantity) */
SELECT DISTINCT t3.[Purch_Doc_]
      ,[POrg]
      ,[Doc__Date]
      ,[Vendor]
      ,[Site]
      ,t3.[Item]
      ,[Article]
      ,[Mdse_Cat_]
      ,[Vendor_Article_Number]
      ,[PO_Quantity]
      ,[Net_Price]
      ,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,t3.[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,[Qty_Delivered]
      , t4.Quantity
INTO type1
FROM PObad as t3
JOIN ( 
SELECT DISTINCT t1.Purch_Doc_, t1.Item, Pstng_Date, SUM(CAST(Quantity AS FLOAT)) AS Quantity
FROM PObad t1 JOIN
i1 t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
GROUP BY t1.Purch_Doc_, t1.Item, t1.Pstng_Date ) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item AND t3.Pstng_Date = t4.Pstng_Date;


/* DELETE TROUBLE SOME DATA (SHOULD BE ONLY A FEW) */
DELETE t1 
FROM type1 AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM type1
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING SUM(CAST(Quantity AS FLOAT)) <> CAST(Qty_Delivered AS FLOAT)) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

/* REMOVE CATEGORISED DATA FROM PObad */
DELETE PObad
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type1) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 4 */
/* SELECT PO and Item FROM PObad WHERE Quantity = SUM(Qty_Delivered) */
SELECT Purch_Doc_, Item
INTO i2
FROM PObad
GROUP BY Purch_Doc_, Item, Quantity
HAVING COUNT(Qty_Delivered) > 1 
AND SUM(CAST(Qty_Delivered AS FLOAT)) = CAST(Quantity AS FLOAT);

/* CREATING THE INCONSISTENCY TYPE 1 TABLE for i2:
	CONTAINS ALL OF THE DATA GROUPED BY PO, Item, Date THAT HAS Qty_Delivered = SUM(Quantity) */
SELECT DISTINCT t3.[Purch_Doc_]
      ,[POrg]
      ,[Doc__Date]
      ,[Vendor]
      ,[Site]
      ,t3.[Item]
      ,[Article]
      ,[Mdse_Cat_]
      ,[Vendor_Article_Number]
      ,[PO_Quantity]
      ,[Net_Price]
      ,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,t3.[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,t4.[Qty_Delivered]
      , Quantity
INTO type2
FROM PObad as t3
JOIN ( 
SELECT DISTINCT t1.Purch_Doc_, t1.Item, Pstng_Date, SUM(CAST(Qty_Delivered AS FLOAT)) AS Qty_Delivered
FROM PObad as t1 JOIN
i2 t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
GROUP BY t1.Purch_Doc_, t1.Item, t1.Pstng_Date ) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item AND t3.Pstng_Date = t4.Pstng_Date;


DROP TABLE type2

SELECT Purch_Doc_, Item
FROM type2
GROUP BY Purch_Doc_, Item, Quantity
HAVING SUM(CAST(Qty_Delivered AS FLOAT)) <> CAST(Quantity AS FLOAT)
AND SUM(CAST(Scheduled_Qty AS FLOAT)) <> CAST(Quantity AS FLOAT);

SELECT * FROM PObad WHERE Purch_Doc_ = '4510674400' AND Item = '1';

DELETE PObad
FROM PObad AS t1 JOIN i2
ON t1.Purch_Doc_ = i2.Purch_Doc_ AND t1.Item = i2.Item AND t1.Pstng_Date = i2.Pstng_Date;




SELECT DISTINCT Purch_Doc_, Item, Pstng_Date
INTO i3
FROM PObad
WHERE PO_Quantity = Scheduled_Qty 
AND Scheduled_Qty = Qty_Delivered
AND Qty_Delivered = Quantity;


SELECT DISTINCT t1.*
INTO type3
FROM PObad as t1
JOIN i3
ON t1.Purch_Doc_ = i3.Purch_Doc_ AND t1.Item = i3.Item AND t1.Pstng_Date = i3.Pstng_Date;


DELETE PObad
FROM PObad AS t1 JOIN i3
ON t1.Purch_Doc_ = i3.Purch_Doc_ AND t1.Item = i3.Item AND t1.Pstng_Date = i3.Pstng_Date;


SELECT COUNT(1) FROM (SELECT DISTINCT Purch_Doc_, Item, Pstng_Date FROM PObad) AS t;

SELECT TOP(100) * FROM PObad;

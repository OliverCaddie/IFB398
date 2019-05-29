/* PRELIM */
DROP TABLE POdata;
DROP TABLE POgood;
DROP TABLE PObad;
DROP TABLE i1; 
DROP TABLE i2; 
DROP TABLE i3; 
DROP TABLE type1; 
DROP TABLE type2; 
DROP TABLE type3;
DROP TABLE type4;
DROP TABLE temp1;
DROP TABLE mov_avg_issue;


SELECT * INTO POdata FROM (
SELECT * FROM POdata_T1
UNION ALL
SELECT t1.[Purch_Doc_]
      ,[POrg]
      ,[Doc__Date]
      ,[Vendor]
      ,[Site]
      ,t1.[Item]
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
      ,[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,[Qty_Delivered]
      , -CAST(Quantity AS FLOAT) 
FROM POdata_T2 AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM POdata_T1) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item) AS t;

ALTER TABLE POdata DROP COLUMN [MovAvgPrice];

/* STEP 1 ################################################################################################*/
/* SELECT ALL THE DATA THAT DOES NOT CONTAIN DUPLICATE ITEM NUMBERS */
SELECT t1.*
INTO POgood
FROM POdata AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM POdata
GROUP BY Purch_Doc_, Item
HAVING COUNT(*) = 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

/* STEP 2 ################################################################################################*/
/* SELECT ALL THE DATA THAT DOES CONTAIN DUPLICATE ITEM NUMBERS */
SELECT t1.*
INTO PObad
FROM POdata AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM POdata
GROUP BY Purch_Doc_, Item
HAVING COUNT(Item) > 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 3 ################################################################################################*/
/* SELECT PO and Item no. FROM PObad WHERE PO_Quantity = SUM(Quantity) */
SELECT DISTINCT Purch_Doc_, Item
INTO i1
FROM PObad
GROUP BY Purch_Doc_, Item, PO_Quantity
HAVING SUM(Quantity) = PO_Quantity;


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
      --,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,t3.[Pstng_Date]
      ,[Entry_Dte]
      ,[PO_Quantity] AS Scheduled_Qty
      ,[PO_Quantity] AS Qty_Delivered
      , t4.Quantity
INTO type1
FROM PObad AS t3
JOIN 
( 
	SELECT t1.Purch_Doc_, t1.Item, Pstng_Date, SUM(Quantity) AS Quantity
	FROM PObad AS t1 JOIN i1 AS t2
	ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
	GROUP BY t1.Purch_Doc_, t1.Item, t1.Pstng_Date
) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item AND t3.Pstng_Date = t4.Pstng_Date;


SELECT * 
INTO mov_avg_issue
FROM PObad AS t1
WHERE EXISTS (
SELECT * FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM type1
GROUP BY Purch_Doc_, Item, PO_Quantity
HAVING SUM(Quantity) <> PO_Quantity) AS t2
WHERE t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item)
ORDER BY Purch_Doc_, Item;


/* REMOVE CATEGORISED DATA FROM PObad */
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type1) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

DELETE t1
FROM type1 AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM mov_avg_issue) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 4 ################################################################################################*/
/* GET PO AND ITEM FROM DUPLICATE ENTRIES */
SELECT Purch_Doc_, Item
INTO i2
FROM (
SELECT DISTINCT *, CASE WHEN PO_Quantity = Scheduled_Qty 
AND Scheduled_Qty = Qty_Delivered
AND Qty_Delivered = Quantity THEN 1 ELSE 0 END AS col
FROM PObad) AS t
GROUP BY Purch_Doc_, Item
HAVING COUNT(*) = 1 AND SUM(col) = 1;



/* CREATE TABLE FOR TYPE3 */
SELECT DISTINCT t1.[Purch_Doc_]
      ,[POrg]
      ,[Doc__Date]
      ,[Vendor]
      ,[Site]
      ,t1.[Item]
      ,[Article]
      ,[Mdse_Cat_]
      ,[Vendor_Article_Number]
      ,[PO_Quantity]
      ,[Net_Price]
      --,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,[Qty_Delivered]
      ,[Quantity]
INTO type2
FROM PObad AS t1
JOIN i2 AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* REMOVE CATEGORISED DATA FROM PObad */
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type2) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 5 ################################################################################################*/
/* SELECT PO and Item no. FROM PObad WHERE Qty_Delivered = SUM(Quantity) AND PO_Quantity = Scheduled */
SELECT DISTINCT Purch_Doc_, Item
INTO i3
FROM PObad
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING COUNT(Quantity) > 1 
AND SUM(Quantity) = Qty_Delivered;


/* CREATING THE INCONSISTENCY TYPE 1 TABLE:*/
/*	CONTAINS ALL OF THE DATA GROUPED BY PO, Item, Date THAT HAS Qty_Delivered = SUM(Quantity) */
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
      --,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,t3.[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,[Qty_Delivered]
      , t4.Quantity
INTO type3
FROM PObad as t3
JOIN ( 
SELECT DISTINCT t1.Purch_Doc_, t1.Item, Pstng_Date, SUM(Quantity) AS Quantity
FROM PObad t1 JOIN
i3 t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
GROUP BY t1.Purch_Doc_, t1.Item, t1.Pstng_Date) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item AND t3.Pstng_Date = t4.Pstng_Date;


INSERT INTO mov_avg_issue
SELECT * 
FROM PObad AS t1
WHERE EXISTS (
SELECT * FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM type3
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING SUM(Quantity) <> Qty_Delivered) AS t2
WHERE t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item);

/* REMOVE CATEGORISED DATA FROM PObad */
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type3) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

/* DELETE TROUBLESOME DATA (SHOULD BE ONLY A FEW) */
DELETE t1 
FROM type3 AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM type3
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING SUM(Quantity) <> Qty_Delivered) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;




/* STEP 6 */
/* WHERE SUMS ARE ALL EQUAL */
SELECT t1.*
INTO temp1
FROM PObad AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item
HAVING SUM(Scheduled_Qty) = SUM(Qty_Delivered)
AND SUM(Qty_Delivered) = SUM(Quantity)) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
WHERE t1.Scheduled_Qty = t1.Qty_Delivered AND t1.Qty_Delivered = t1.Quantity;


SELECT DISTINCT t1.[Purch_Doc_]
      ,[POrg]
      ,[Doc__Date]
      ,[Vendor]
      ,[Site]
      ,t1.[Item]
      ,[Article]
      ,[Mdse_Cat_]
      ,[Vendor_Article_Number]
      ,[PO_Quantity]
      ,[Net_Price]
      --,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,t1.[Pstng_Date]
      ,[Entry_Dte]
      ,[PO_Quantity] AS Scheduled_Qty
      ,[PO_Quantity] AS Qty_Delivered
      ,[PO_Quantity] AS Quantity 
INTO type4
FROM temp1 t1 JOIN (
SELECT Purch_Doc_, Item, Pstng_Date, SUM(PO_Quantity)/SUM(Quantity) AS fac
FROM temp1
GROUP BY Purch_Doc_, Item, Pstng_Date
HAVING COUNT(DISTINCT Scheduled_Qty) = 1
AND COUNT(DISTINCT Qty_Delivered) = 1
AND COUNT(DISTINCT Quantity) = 1) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item AND t1.Pstng_Date = t2.Pstng_Date
WHERE fac = 2;


/* REMOVE CATEGORISED DATA FROM PObad */
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type4) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

DELETE t1
FROM temp1 AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type4) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/*******************************************************/


SELECT  
CASE WHEN LEN(Mdse_Cat_) < 6 THEN REPLICATE('0', 6 - LEN(Mdse_Cat_)) + Mdse_Cat_ ELSE Mdse_Cat_ END 
FROM POdata 
WHERE LEN(Mdse_Cat_) = 5

SELECT COUNT(*) FROM i1;
SELECT COUNT(*) FROM type2;
SELECT COUNT(*) FROM type3;
SELECT COUNT(*) FROM type4;


/********************************************************/
/*** PROPORTIONS ***/
SELECT COUNT(*) AS bad_PO_Item_tot FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM PObad) AS t;
SELECT COUNT(*) AS data_PO_Item_tot FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM POdata) AS t;

SELECT COUNT(DISTINCT Purch_Doc_) AS bad_PO_tot FROM PObad;
SELECT COUNT(DISTINCT Purch_Doc_) AS data_PO_tot FROM POdata;

SELECT COUNT(*) AS bad_tot FROM PObad;
SELECT COUNT(*) AS data_tot FROM POdata;
/********************************************************/
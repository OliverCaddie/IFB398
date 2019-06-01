-- PRELIM 
DROP TABLE IF EXISTS POdata
	, POgood
	, PObad
	, type1
	, type2
	, type3
	, type4
	, interm1;

/* We used the below statement to generate the complete set of POdata 
as some of the entries in the correction table POdata_T2 (type 102, I believe?) 
contains some data that is not relevant to the original data set 
(Likely because it was collected at different dates).

This will be unnecessary when the suppled PO data comes in a single table */
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

ALTER TABLE POdata DROP COLUMN [MovAvgPrice]; -- As it was causing some issues

/* PRELIM 1 ################################################################################################
SELECT ALL THE DATA THAT DOES NOT CONTAIN DUPLICATE ITEM NUMBERS */
SELECT t1.*
INTO POgood
FROM POdata AS t1 JOIN (
	SELECT Purch_Doc_, Item
	FROM POdata
	GROUP BY Purch_Doc_, Item
	HAVING COUNT(*) = 1 
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

/* PRELIM 2 ################################################################################################
SELECT ALL THE DATA THAT DOES CONTAIN DUPLICATE ITEM NUMBERS */
SELECT t1.*
INTO PObad
FROM POdata AS t1 JOIN (
	SELECT Purch_Doc_, Item
	FROM POdata
	GROUP BY Purch_Doc_, Item
	HAVING COUNT(Item) > 1 
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* TYPE 1 ################################################################################################
SELECT * FROM PObad WHERE PO_Quantity = SUM(Quantity) (We could be painting these incons with too broad a brush) */
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
INTO type1 -- Ideally we would make these temporary tables in a final release
FROM PObad AS t3
JOIN ( 
	SELECT t1.Purch_Doc_, t1.Item, Pstng_Date, SUM(Quantity) AS Quantity
	FROM PObad AS t1 JOIN (
		SELECT DISTINCT Purch_Doc_, Item
		FROM PObad
		GROUP BY Purch_Doc_, Item, PO_Quantity
		HAVING SUM(Quantity) = PO_Quantity
	) AS t2
	ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
	GROUP BY t1.Purch_Doc_, t1.Item, t1.Pstng_Date
) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item AND t3.Pstng_Date = t4.Pstng_Date;


-- REMOVE DATA THAT WAS MISTAKENLY CAUGHT IN THE NET
DELETE t1
FROM type1 AS t1 JOIN (
	SELECT DISTINCT Purch_Doc_, Item
	FROM type1
	GROUP BY Purch_Doc_, Item, PO_Quantity
	HAVING SUM(Quantity) <> PO_Quantity
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

-- REMOVE PROPERLY CATEGORISED DATA FROM PObad
DELETE t1
FROM PObad AS t1 JOIN (
	SELECT DISTINCT Purch_Doc_, Item
	FROM type1
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* TYPE 2 ################################################################################################
SELECT * IN FULL DUPLICATE ENTRIES (It is hard to interpret duplicates not in full) */
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
JOIN (
	SELECT Purch_Doc_, Item
	FROM (
		SELECT DISTINCT *, CASE WHEN PO_Quantity = Scheduled_Qty 
		AND Scheduled_Qty = Qty_Delivered
		AND Qty_Delivered = Quantity THEN 1 ELSE 0 END AS chk
		FROM PObad
	) AS t
	GROUP BY Purch_Doc_, Item
	HAVING COUNT(*) = 1 AND SUM(chk) = 1 -- could be a better way to do this
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


-- REMOVE CATEGORISED DATA FROM PObad
DELETE t1
FROM PObad AS t1 JOIN (
	SELECT DISTINCT Purch_Doc_, Item
	FROM type2
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* TYPE 3 ################################################################################################
SELECT * FROM PObad WHERE Qty_Delivered = SUM(Quantity) */
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
	SELECT t1.Purch_Doc_, t1.Item, Pstng_Date, SUM(Quantity) AS Quantity
	FROM PObad t1 JOIN (
		SELECT DISTINCT Purch_Doc_, Item
		FROM PObad
		GROUP BY Purch_Doc_, Item, Qty_Delivered
		HAVING COUNT(*) > 1 
		AND SUM(Quantity) = Qty_Delivered
	) AS t2
	ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
	GROUP BY t1.Purch_Doc_, t1.Item, t1.Pstng_Date
) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item AND t3.Pstng_Date = t4.Pstng_Date;

-- DELETE TROUBLESOME DATA FROM type3
DELETE t1 
FROM type3 AS t1 JOIN (
	SELECT Purch_Doc_, Item
	FROM type3
	GROUP BY Purch_Doc_, Item, Qty_Delivered
	HAVING SUM(Quantity) <> Qty_Delivered
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


-- REMOVE CATEGORISED DATA FROM PObad
DELETE t1
FROM PObad AS t1 JOIN (
	SELECT DISTINCT Purch_Doc_, Item
	FROM type3
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;



/* TYPE 4 ################################################################################################
WHERE QUANTITY SUMS ARE ALL EQUAL */
SELECT t1.*
INTO interm1 -- An inconsistency table that has been in part categorised, but not resolved
FROM PObad AS t1 JOIN (
	SELECT Purch_Doc_, Item
	FROM PObad
	GROUP BY Purch_Doc_, Item
	HAVING SUM(Scheduled_Qty) = SUM(Qty_Delivered)
	AND SUM(Qty_Delivered) = SUM(Quantity)
) AS t2
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
FROM interm1 t1 JOIN (
	SELECT Purch_Doc_, Item, Pstng_Date, SUM(PO_Quantity)/SUM(Quantity) AS fac
	FROM interm1
	GROUP BY Purch_Doc_, Item, Pstng_Date
	HAVING COUNT(DISTINCT Scheduled_Qty) = 1
	AND COUNT(DISTINCT Qty_Delivered) = 1
	AND COUNT(DISTINCT Quantity) = 1
) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item AND t1.Pstng_Date = t2.Pstng_Date
WHERE fac = 2; -- Meaning it has been duplicated


-- REMOVE CATEGORISED DATA FROM PObad
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type4) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

-- REMOVE CATEGORISED DATA FROM INTERMEDIARY TABLE
DELETE t1
FROM interm1 AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type4) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/*******************************************************/



/********************************************************/
/*** PROPORTIONS (To see how much has been categorised) ***/
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
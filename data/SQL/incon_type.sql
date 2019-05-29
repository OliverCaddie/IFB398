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


/* STEP 1 ################################################################################################*/
/* SELECT ALL THE DATA THAT DOESN'T CONTAIN DUPLICATE ITEM NUMBERS */
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
/* SELECT PO and Item no. FROM PObad WHERE Qty_Delivered = SUM(Quantity) */
SELECT DISTINCT Purch_Doc_, Item
INTO i1
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
SELECT DISTINCT t1.Purch_Doc_, t1.Item, Pstng_Date, SUM(Quantity) AS Quantity
FROM PObad t1 JOIN
i1 t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
GROUP BY t1.Purch_Doc_, t1.Item, t1.Pstng_Date ) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item AND t3.Pstng_Date = t4.Pstng_Date;


/* DELETE TROUBLESOME DATA (SHOULD BE ONLY A FEW) */
DELETE t1 
FROM type1 AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM type1
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING SUM(Quantity) <> Qty_Delivered) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* REMOVE CATEGORISED DATA FROM PObad */
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type1) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 4 ################################################################################################*/
/* SELECT PO and Item FROM PObad WHERE Quantity = SUM(Qty_Delivered) AND SUM(Scheduled_Qty) = Quantity*/
SELECT Purch_Doc_, Item
INTO i2
FROM PObad
GROUP BY Purch_Doc_, Item, Quantity
HAVING COUNT(*) > 1 
AND SUM(Qty_Delivered) = Quantity
AND SUM(Scheduled_Qty) = Quantity;


/* CREATING THE INCONSISTENCY TYPE 2 TABLE for i2:*/
/*	CONTAINS ALL OF THE DATA GROUPED BY PO, Item, Date THAT HAS Qty_Delivered = SUM(Quantity) AND SUM(Scheduled_Qty) = Quantity */
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
      ,[Pstng_Date]
      ,[Entry_Dte]
      ,t4.[Scheduled_Qty]
      ,t4.[Qty_Delivered]
      , Quantity
INTO type2
FROM PObad as t3
JOIN ( 
SELECT t1.Purch_Doc_, t1.Item, 
SUM(Scheduled_Qty) AS Scheduled_Qty, 
SUM(Qty_Delivered) AS Qty_Delivered
FROM PObad as t1 JOIN
i2 as t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
GROUP BY t1.Purch_Doc_, t1.Item) AS t4
ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item;



/* DELETE TROUBLESOME DATA (SHOULD BE ONLY A FEW) */
DELETE t1 
FROM type2 AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM type2
GROUP BY Purch_Doc_, Item, Pstng_Date, Quantity
HAVING SUM(Qty_Delivered) <> Quantity) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* REMOVE CATEGORISED DATA FROM PObad */
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type2) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 5 ################################################################################################*/
/* GET PO AND ITEM FROM DUPLICATE ENTRIES */
SELECT Purch_Doc_, Item
INTO i3
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
      ,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,[Qty_Delivered]
      ,[Quantity]
INTO type3
FROM PObad AS t1
JOIN i3 AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* REMOVE CATEGORISED DATA FROM PObad */
DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type3) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 6 ################################################################################################*/
/* CORRECTION RESULTS IN 0 */
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
      ,[MovAvgPrice]
      ,[D]
      ,[DCI]
      ,[Deliv__Date]
      ,[StatDelD]
      ,[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,0 AS Qty_Delivered
      ,[Quantity]
INTO type4 
FROM PObad AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item
HAVING SUM(Quantity) = 0 AND COUNT(DISTINCT Pstng_Date) = COUNT(Pstng_Date)) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

DELETE t1
FROM PObad AS t1 JOIN (
SELECT DISTINCT Purch_Doc_, Item
FROM type4) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


/* STEP 7 */

SELECT t1.* FROM Pobad AS t1 JOIN (
SELECT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item, Quantity
HAVING COUNT(*) > 1 
AND SUM(Qty_Delivered) = Quantity) As t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

SELECT DISTINCT t5.[Purch_Doc_]
      ,[POrg]
      ,[Doc__Date]
      ,[Vendor]
      ,[Site]
      ,t5.[Item]
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
      ,t5.[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,qd
      ,sq

SELECT *
--INTO test1
FROM PObad AS t5 JOIN (
	SELECT t3.Purch_Doc_, t3.Item, Pstng_Date, qd, SUM(Quantity) AS sq
	FROM PObad AS t3 JOIN (
		SELECT t1.Purch_Doc_, t1.Item, SUM(Quantity) AS qd
		FROM PObad AS t1 JOIN (
			SELECT DISTINCT Purch_Doc_, Item
			FROM PObad
			WHERE Qty_Delivered = 0 AND Quantity < 0) AS t2
		ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
		GROUP BY t1.Purch_Doc_, t1.Item
		HAVING SUM(Qty_Delivered) > 0 
		AND COUNT(DISTINCT Scheduled_Qty) = 1
		AND SUM(Quantity) = SUM(Scheduled_Qty)/COUNT(*)) As t4
	ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item
	GROUP BY t3.Purch_Doc_, t3.Item, qd, Pstng_Date) AS t6
ON t5.Purch_Doc_ = t6.Purch_Doc_ AND t5.Item = t6.Item AND t5.Pstng_Date = t6.Pstng_Date
ORDER BY t5.Purch_Doc_, t5.Item, t5.Pstng_Date;





SELECT * FROM POdata_T2



SELECT * FROM POdata WHERE Purch_Doc_ = 4510789518



SELECT * FROM type2 t1 JOIN POdata t2 ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

SELECT COUNT(*) FROM PObad;

SELECT * FROM PObad WHERE Purch_Doc_ = 4510863447 AND Item = 2;

SELECT COUNT(*) FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM PObad) AS t;


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


SELECT t1.*
INTO temp2
FROM PObad t1 JOIN (
SELECT Purch_Doc_, Item, SUM(Quantity)*COUNT(*)/SUM(PO_Quantity) AS fac
FROM PObad
GROUP BY Purch_Doc_, Item
HAVING SUM(Quantity)*COUNT(*)/SUM(PO_Quantity) = 2) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


SELECT COUNT(DISTINCT Purch_Doc_) FROM temp2

SELECT * FROM temp2 ORDER BY Purch_Doc_, Item;


DROP TABLE temp1


SELECT t1.*, fac
INTO temp1
FROM PObad t1 JOIN (
SELECT Purch_Doc_, Item, SUM(Quantity)*COUNT(*)/SUM(PO_Quantity) AS fac
FROM PObad
GROUP BY Purch_Doc_, Item
HAVING SUM(Quantity)*COUNT(*)/SUM(PO_Quantity) = FLOOR(SUM(Quantity)*COUNT(*)/SUM(PO_Quantity))) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;

SELECT t1.*
--INTO temp1
FROM PObad t1 JOIN (
SELECT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item
HAVING SUM(Scheduled_Qty) = SUM(Qty_Delivered)
AND SUM(Qty_Delivered) = SUM(PO_Quantity)) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item;


SELECT * FROM  temp1;





SELECT COUNT(*) FROM (
SELECT DISTINCT Purch_Doc_, Item 
FROM POdata_T2 
WHERE Qty_Delivered = 0) AS t;

SELECT * FROM (
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
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item) AS a
WHERE EXISTS

SELECT * FROM (
	SELECT DISTINCT t3.Purch_Doc_, t3.Item
	FROM POdata AS t3 JOIN (
		SELECT t1.Purch_Doc_, t1.Item
		FROM POdata_T2 AS t1 JOIN (
			SELECT DISTINCT Purch_Doc_, Item
			FROM POdata_T1) AS t2
		ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item) AS t4
	ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item
	GROUP BY t3.Purch_Doc_, t3.Item
	HAVING COUNT(DISTINCT Pstng_Date) > 1
	--WHERE Qty_Delivered = 0
) As t5 JOIN (
    SELECT DISTINCT t3.Purch_Doc_, t3.Item
	FROM POdata AS t3 JOIN (
		SELECT t1.Purch_Doc_, t1.Item
		FROM POdata_T2 AS t1 JOIN (
			SELECT DISTINCT Purch_Doc_, Item
			FROM POdata_T1) AS t2
		ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item) AS t4
	ON t3.Purch_Doc_ = t4.Purch_Doc_ AND t3.Item = t4.Item
	WHERE Qty_Delivered = 0
)AS t6
ON t5.Purch_Doc_ = t6.Purch_Doc_ AND t5.Item = t6.Item
ORDER BY t5.Purch_Doc_, t5.Item;


--222 with no group
--138 with more than two dates
--135 w/ 0

SELECT COUNT(*) FROM POdata;


SELECT COUNT(*) FROM i1;

SELECT COUNT(*) FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM POdata) AS t;


SELECT COUNT(*) FROM (
SELECT COUNT(*) FROM (
SELECT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item, PO_Quantity
HAVING SUM(Quantity) = PO_Quantity) AS t;


SELECT COUNT(*) FROM (
SELECT DISTINCT Purch_Doc_, Item
FROM PObad
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING COUNT(*) > 1 AND SUM(Quantity) = Qty_Delivered) AS t;








SELECT * 
FROM 
(
	SELECT DISTINCT Purch_Doc_, Item
	FROM PObad
	GROUP BY Purch_Doc_, Item, Qty_Delivered
	HAVING COUNT(*) > 1 AND SUM(Quantity) = Qty_Delivered
) AS t3
WHERE NOT EXISTS  
	(
	SELECT t.*
	FROM
	(
		SELECT t1.* 
		FROM 
		(
			SELECT DISTINCT Purch_Doc_, Item
			FROM PObad
			GROUP BY Purch_Doc_, Item, PO_Quantity
			HAVING SUM(Quantity) = PO_Quantity
		) AS t1 
		JOIN 
		(
			SELECT DISTINCT Purch_Doc_, Item
			FROM PObad
			GROUP BY Purch_Doc_, Item, Qty_Delivered
			HAVING COUNT(*) > 1 AND SUM(Quantity) = Qty_Delivered
		) AS t2
		ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item
	) AS t
	WHERE t.Purch_Doc_ = t3.Purch_Doc_ AND t.Item = t3.Item
	);



SELECT * FROM POdata WHERE Purch_Doc_ = 4510651715 AND Item = 9;
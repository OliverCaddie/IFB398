/* STEP 1 */

SELECT t1.*
INTO POgood
FROM POdata AS t1 JOIN (
SELECT Purch_Doc_, Item, Pstng_Date
FROM POdata
GROUP BY Purch_Doc_, Item, Pstng_Date
HAVING COUNT(Item) = 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item AND t1.Pstng_Date = t2.Pstng_Date;

/* STEP 2 */

SELECT t1.*
INTO PObad
FROM POdata AS t1 JOIN (
SELECT Purch_Doc_, Item, Pstng_Date
FROM POdata
GROUP BY Purch_Doc_, Item, Pstng_Date
HAVING COUNT(Item) > 1 ) AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_ AND t1.Item = t2.Item AND t1.Pstng_Date = t2.Pstng_Date;


/* STEP 3 */
SELECT Purch_Doc_, Item, Pstng_Date, SUM(CAST(Quantity AS FLOAT)) AS Quantity
INTO i1
FROM PObad
GROUP BY Purch_Doc_, Item, Pstng_Date, Qty_Delivered
HAVING COUNT(Quantity) > 1 
AND SUM(CAST(Quantity AS FLOAT)) = CAST(Qty_Delivered AS FLOAT);



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
      ,t1.[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,[Qty_Delivered]
      , i1.Quantity
INTO type1
FROM PObad as t1
JOIN i1
ON t1.Purch_Doc_ = i1.Purch_Doc_ AND t1.Item = i1.Item AND t1.Pstng_Date = i1.Pstng_Date;

SELECT COUNT(1) FROM PObad;
SELECT COUNT(1) FROM type1;



DELETE PObad
FROM PObad AS t1 JOIN i1 
ON t1.Purch_Doc_ = i1.Purch_Doc_ AND t1.Item = i1.Item AND t1.Pstng_Date = i1.Pstng_Date;

SELECT DISTINCT Purch_Doc_, Item, Pstng_Date, SUM(CAST(Qty_Delivered AS FLOAT)) AS Qty_Delivered
INTO i2
FROM PObad
GROUP BY Purch_Doc_, Item, Pstng_Date, Quantity
HAVING COUNT(Qty_Delivered) > 1 
AND CAST(Quantity AS FLOAT) <> 0 
AND SUM(CAST(Qty_Delivered AS FLOAT)) = CAST(Quantity AS FLOAT);

DROP TABLE type2

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
      ,t1.[Pstng_Date]
      ,[Entry_Dte]
      ,[Scheduled_Qty]
      ,i2.[Qty_Delivered]
      ,Quantity
INTO type2
FROM PObad as t1
JOIN i2
ON t1.Purch_Doc_ = i2.Purch_Doc_ AND t1.Item = i2.Item AND t1.Pstng_Date = i2.Pstng_Date;

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

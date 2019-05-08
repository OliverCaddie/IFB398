/* Proportion of POs with multiple items of same number */
SELECT COUNT (DISTINCT Purch_Doc_) FROM POdata;
SELECT COUNT (DISTINCT Purch_Doc_) FROM PObad;

/* Proportion of Sites in bad data*/
SELECT COUNT (DISTINCT Site) FROM POdata;
SELECT COUNT (DISTINCT Site) FROM PObad;

SELECT DISTINCT d.Site
FROM (SELECT DISTINCT Site FROM POdata) d 
LEFT JOIN (SELECT DISTINCT Site FROM PObad) b
ON b.Site = d.Site
WHERE b.Site IS NULL;

SELECT DISTINCT POrg FROM PObad;
SELECT DISTINCT POrg FROM POdata;

SELECT POrg , COUNT (POrg)
FROM (SELECT DISTINCT Purch_Doc_, POrg
FROM PObad) AS t
GROUP BY POrg;

SELECT POrg , COUNT (POrg)
FROM (SELECT DISTINCT Purch_Doc_, POrg
FROM POdata) AS t
GROUP BY POrg;


/* INCONSISTENCY TYPE 1 */
CREATE VIEW incon_1 AS 
SELECT t2.*
FROM (
SELECT DISTINCT Purch_Doc_
FROM PObad
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING COUNT(Quantity) > 1 AND SUM(CAST(Quantity AS FLOAT)) = CAST(Qty_Delivered AS FLOAT)) AS t1
RIGHT JOIN PObad AS t2
ON t1.Purch_Doc_ = t2.Purch_Doc_
WHERE t1.Purch_Doc_ IS NOT NULL;

SELECT * FROM incon_1 ORDER BY Purch_Doc_, LEN(Item), Item;

SELECT * 
FROM POdata
WHERE Purch_Doc_ = '4510965339' ORDER BY LEN(Item), Item;


SELECT TOP (10) Site, COUNT(Site) AS cnt
FROM incon_1
GROUP BY Site
ORDER BY cnt DESC;

SELECT TOP (10) Site, COUNT(Site) AS cnt
FROM POdata
GROUP BY Site
ORDER BY cnt DESC;

SELECT COUNT(1)
FROM ( SELECT DISTINCT Purch_Doc_, Item, PO_Quantity FROM PObad) AS t;

SELECT COUNT(1) FROM (
SELECT DISTINCT Purch_Doc_ FROM PObad WHERE PO_Quantity <> Scheduled_Qty) AS t;




SELECT * FROM incon_1 ORDER BY Purch_Doc_, LEN(Item), Item;



SELECT Purch_Doc_, Item, Qty_Delivered, SUM(CAST(Quantity AS FLOAT))
FROM PObad 
GROUP BY Purch_Doc_, Item, Qty_Delivered
HAVING Purch_Doc_ = '4510596116' /*AND COUNT(Quantity) > 1 AND SUM(CAST(Quantity AS FLOAT)) = CAST(Qty_Delivered AS FLOAT)*



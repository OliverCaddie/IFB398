UPDATE POdata
SET Mdse_Cat_ = REPLICATE('0', 6 - LEN(CAST(Mdse_Cat_ AS VARCHAR))) + CAST(Mdse_Cat_ AS VARCHAR);

ALTER TABLE POdata ALTER COLUMN Doc__Date DATE;

USE srg;
UPDATE dbo.hierarchy_import
SET Category = REPLICATE('0', 2 - LEN(CAST(Category AS VARCHAR))) + 
CAST(Category AS VARCHAR);

UPDATE dbo.hierarchy_import
SET Sub_Category = REPLICATE('0', 4 - LEN(CAST(Sub_Category AS VARCHAR))) + 
CAST(Sub_Category AS VARCHAR);

UPDATE dbo.hierarchy_import
SET Merchandise_Category = REPLICATE('0', 6 - LEN(CAST(Merchandise_Category AS VARCHAR))) + 
CAST(Merchandise_Category AS VARCHAR);


ALTER TABLE hierarchy_import ADD sub VARCHAR(2), merch VARCHAR(2);

UPDATE hierarchy_import
SET sub = SUBSTRING(Sub_Category, 3, 2);

UPDATE hierarchy_import
SET merch = SUBSTRING(Merchandise_Category, 5, 2);

DELETE FROM hierarchy_import WHERE Merchandise_Category = '930703' AND Merchandise_Category_Description <> 'LIFTING ACCESSORIES'

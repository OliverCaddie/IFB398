USE srg;

CREATE TABLE category (
cat_id CHAR(2) PRIMARY KEY,
group_brand VARCHAR(10),
cat_desc VARCHAR(50)
);

CREATE TABLE sub_category (
cat_id CHAR(2),
sub_id CHAR(2),
sub_desc VARCHAR(50),
PRIMARY KEY (cat_id, sub_id),
FOREIGN KEY (cat_id) REFERENCES category (cat_id)
);

CREATE TABLE merch_category (
cat_id CHAR(2),
sub_id CHAR(2),
merch_id CHAR(2),
merch_desc VARCHAR(50),
PRIMARY KEY (cat_id, sub_id, merch_id),
FOREIGN KEY (cat_id, sub_id) REFERENCES sub_category (cat_id, sub_id)
);

INSERT INTO category
SELECT DISTINCT Category, Group_Brand, Category_Description
FROM hierarchy_import;



INSERT INTO sub_category
SELECT DISTINCT Category, sub, Sub_Category_Description
FROM hierarchy_import;

INSERT INTO merch_category
SELECT DISTINCT Category, sub, merch, Merchandise_Category_Description
FROM hierarchy_import;

/*
SELECT DISTINCT LEN(Merchandise_Category_Description) FROM hierarchy_import;

SELECT * FROM category;
SELECT * FROM sub_category;
SELECT * FROM merch_category;
SELECT * FROM category c 
JOIN sub_category s 
ON c.cat_id = s.cat_id
JOIN merch_category m
ON s.cat_id = m.cat_id
AND s.sub_id = m.sub_id;*/
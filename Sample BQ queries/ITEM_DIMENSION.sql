--DDLS
bq mk -t ulta_work.ITEM_DIMENSION ITEM_KEY:INTEGER,ITEM_ID:STRING,ITEM_DESCRIPTION:STRING,ITEM_TYPE_NAME:STRING,SIZE_CODE:STRING,COLOR_NAME:STRING,COLOR_DESCRIPTION:STRING,SUBCLASS_KEY:INTEGER,SUBCLASS_ID:STRING,SUBCLASS_NAME:STRING,CATEGORY_ID:STRING,CATEGORY_NAME:STRING,DEPARTMENT_ID:STRING,DEPARTMENT_NAME:STRING,DIVISION_ID:STRING,DIVISION_NAME:STRING,ROOT_ID:STRING,ROOT_NAME:STRING,DOTCOM:STRING,KEY_BENEFIT:STRING,LAST_MODIFIED:TIMESTAMP,SAPUOM:STRING,MATERIAL_TYPE:STRING,PRICE_BAND_CATEGORY:STRING,PRODUCT_TARGET:STRING,SALON_DESIGNATION:STRING,SKINTYPE:STRING,SUBBRANDS:STRING,TARGET_CUSTOMER:STRING,CATEGORY:STRING,SERVICE_CATEGORY_KEY:INTEGER,BRAND_ID:STRING,BRAND_NAME:STRING,BRAND_KEY:INTEGER

bq mk -t ulta_work.ITEM_DIMENSION_UNCHANGED ITEM_KEY:INTEGER,ITEM_ID:STRING,ITEM_DESCRIPTION:STRING,ITEM_TYPE_NAME:STRING,SIZE_CODE:STRING,COLOR_NAME:STRING,COLOR_DESCRIPTION:STRING,SUBCLASS_KEY:INTEGER,SUBCLASS_ID:STRING,SUBCLASS_NAME:STRING,CATEGORY_ID:STRING,CATEGORY_NAME:STRING,DEPARTMENT_ID:STRING,DEPARTMENT_NAME:STRING,DIVISION_ID:STRING,DIVISION_NAME:STRING,ROOT_ID:STRING,ROOT_NAME:STRING,DOTCOM:STRING,KEY_BENEFIT:STRING,LAST_MODIFIED:TIMESTAMP,SAPUOM:STRING,MATERIAL_TYPE:STRING,PRICE_BAND_CATEGORY:STRING,PRODUCT_TARGET:STRING,SALON_DESIGNATION:STRING,SKINTYPE:STRING,SUBBRANDS:STRING,TARGET_CUSTOMER:STRING,CATEGORY:STRING,SERVICE_CATEGORY_KEY:INTEGER,BRAND_ID:STRING,BRAND_NAME:STRING,BRAND_KEY:INTEGER

bq mk -t ulta_mart.ITEM_DIMENSION ITEM_KEY:INTEGER,ITEM_ID:STRING,ITEM_DESCRIPTION:STRING,ITEM_TYPE_NAME:STRING,SIZE_CODE:STRING,COLOR_NAME:STRING,COLOR_DESCRIPTION:STRING,SUBCLASS_KEY:INTEGER,SUBCLASS_ID:STRING,SUBCLASS_NAME:STRING,CATEGORY_ID:STRING,CATEGORY_NAME:STRING,DEPARTMENT_ID:STRING,DEPARTMENT_NAME:STRING,DIVISION_ID:STRING,DIVISION_NAME:STRING,ROOT_ID:STRING,ROOT_NAME:STRING,DOTCOM:STRING,KEY_BENEFIT:STRING,LAST_MODIFIED:TIMESTAMP,SAPUOM:STRING,MATERIAL_TYPE:STRING,PRICE_BAND_CATEGORY:STRING,PRODUCT_TARGET:STRING,SALON_DESIGNATION:STRING,SKINTYPE:STRING,SUBBRANDS:STRING,TARGET_CUSTOMER:STRING,CATEGORY:STRING,SERVICE_CATEGORY_KEY:INTEGER,BRAND_ID:STRING,BRAND_NAME:STRING,BRAND_KEY:INTEGER

bq mk -t ulta_work.ITEM_DIMENSION_UPDATED ITEM_KEY:INTEGER,ITEM_ID:STRING,ITEM_DESCRIPTION:STRING,ITEM_TYPE_NAME:STRING,SIZE_CODE:STRING,COLOR_NAME:STRING,COLOR_DESCRIPTION:STRING,SUBCLASS_KEY:INTEGER,SUBCLASS_ID:STRING,SUBCLASS_NAME:STRING,CATEGORY_ID:STRING,CATEGORY_NAME:STRING,DEPARTMENT_ID:STRING,DEPARTMENT_NAME:STRING,DIVISION_ID:STRING,DIVISION_NAME:STRING,ROOT_ID:STRING,ROOT_NAME:STRING,DOTCOM:STRING,KEY_BENEFIT:STRING,LAST_MODIFIED:TIMESTAMP,SAPUOM:STRING,MATERIAL_TYPE:STRING,PRICE_BAND_CATEGORY:STRING,PRODUCT_TARGET:STRING,SALON_DESIGNATION:STRING,SKINTYPE:STRING,SUBBRANDS:STRING,TARGET_CUSTOMER:STRING,CATEGORY:STRING,SERVICE_CATEGORY_KEY:INTEGER,BRAND_ID:STRING,BRAND_NAME:STRING,BRAND_KEY:INTEGER

bq mk -t ulta_work.ITEM_ID_TABLE_SOURCE ITEM_ID:STRING,LOAD_DATE:TIMESTAMP

bq mk -t ulta_work.DRIVER_TABLE_ITEM_DIM ITEM_ID:STRING,SUBCLASS:STRING,ITEM_DESCRIPTIION:STRING

--1. DELETE base tables
DELETE ulta_work.ITEM_DIMENSION WHERE TRUE;
--DELETE ulta_work.ITEM_ID_TABLE_SOURCE WHERE TRUE; -- Need to decide whether to truncate or append
DELETE ulta_work.DRIVER_TABLE_ITEM_DIM WHERE TRUE;


--2. LOAD DRIVER TABLE
INSERT INTO ulta_work.DRIVER_TABLE_ITEM_DIM(ITEM_ID,SUBCLASS,ITEM_DESCRIPTIION)
SELECT SKU.ITEM_NUMBER AS ITEM_ID
,COALESCE(SKU.SUB_CLASS_OF_MERCH_HIERARCHY,SALEDETAIL.ULTA_SUBCLASS_OF_ARTICLE,POINTSDETAIL.MERCH_HIERCHARCHY_SUB_CLASS) AS SUBCLASS
,COALESCE(SKU.ARTICLE_DESCRIPTION,SALONSALEDETAIL.SERVICE_NAME) AS ITEM_DESCRIPTIION
FROM ulta_incoming.SKU SKU
LEFT OUTER JOIN ulta_incoming.SALEDETAIL SALEDETAIL
ON SKU.ITEM_NUMBER = SALEDETAIL.ITEM_NUMBER_SKU
LEFT OUTER JOIN ulta_incoming.POINTSDETAIL POINTSDETAIL
ON SKU.ITEM_NUMBER = POINTSDETAIL.ITEM_NUMBER_SKU
LEFT OUTER JOIN ulta_incoming.SALONSALEDETAIL SALONSALEDETAIL
ON SKU.ITEM_NUMBER = cast(SALONSALEDETAIL.SERVICE_ID as string)
GROUP BY ITEM_ID,SUBCLASS,ITEM_DESCRIPTIION;


INSERT INTO ulta_work.ITEM_DIMENSION (ITEM_KEY,ITEM_ID,ITEM_DESCRIPTION,ITEM_TYPE_NAME,SIZE_CODE,COLOR_NAME,COLOR_DESCRIPTION,SUBCLASS_KEY,SUBCLASS_ID,SUBCLASS_NAME,CATEGORY_ID,CATEGORY_NAME,DEPARTMENT_ID,DEPARTMENT_NAME,DIVISION_ID,DIVISION_NAME,ROOT_ID,ROOT_NAME,DOTCOM,KEY_BENEFIT,LAST_MODIFIED,SAPUOM,MATERIAL_TYPE,PRICE_BAND_CATEGORY,PRODUCT_TARGET,SALON_DESIGNATION,SKINTYPE,SUBBRANDS,TARGET_CUSTOMER,CATEGORY,SERVICE_CATEGORY_KEY,BRAND_ID,BRAND_NAME,BRAND_KEY)
SELECT 
NULL AS ITEM_KEY, -- will be populated from new keys
DRIVER.ITEM_ID AS ITEM_ID,
DRIVER.ITEM_DESCRIPTIION AS ITEM_DESCRIPTION,
CASE WHEN cast(DRIVER.SUBCLASS as INT64) = 4010 THEN 'Salon Service' ELSE 'Offering Item' END AS ITEM_TYPE_NAME,
SKU.SIZE AS SIZE_CODE,
CASE WHEN PRODUCTMETA.SNAME='color' THEN PRODUCTMETA.SVALUE ELSE NULL END AS COLOR_NAME,
'' AS COLOR_DESCRIPTION,
NULL AS SUBCLASS_KEY, -- It will be NULL
DRIVER.SUBCLASS AS SUBCLASS_ID,
COALESCE(MERCH.SUBCLASS_NAME,ITEM_DIM.SUBCLASS_NAME) AS SUBCLASS_NAME,
COALESCE(MERCH.CATEGORY_ID,ITEM_DIM.CATEGORY_ID) AS CATEGORY_ID,
COALESCE(MERCH.CATEGORY_NAME,ITEM_DIM.CATEGORY_NAME) AS CATEGORY_NAME,
COALESCE(MERCH.DEPARTMENT_ID,ITEM_DIM.DEPARTMENT_ID) AS DEPARTMENT_ID,
COALESCE(MERCH.DEPARTMENT_NAME,ITEM_DIM.DEPARTMENT_NAME) AS DEPARTMENT_NAME,
COALESCE(MERCH.DIVISION_ID,ITEM_DIM.DIVISION_ID) AS DIVISION_ID,
COALESCE(MERCH.DIVISION_NAME,ITEM_DIM.DIVISION_NAME) AS DIVISION_NAME,
COALESCE(MERCH.ROOT_ID,ITEM_DIM.ROOT_ID) AS ROOT_ID,
COALESCE(MERCH.ROOT_NAME,ITEM_DIM.ROOT_NAME) AS ROOT_NAME,
SKU.DOTCOM AS DOTCOM,
SKU.KEY_BENEFIT AS KEY_BENEFIT,
CAST (SUBSTR(CASE WHEN SKU.LAST_MODIFIED = '' THEN NULL ELSE SKU.LAST_MODIFIED END,1,19) AS TIMESTAMP) AS LAST_MODIFIED,
SKU.LOWER_LEVEL_OF_PACKING_HIERARCHY AS SAPUOM,  
SKU.MATERIAL_TYPE AS MATERIAL_TYPE,
SKU.PRICE_BAND_CATEGORY AS PRICE_BAND_CATEGORY,
SKU.PRODUCT_TARGET AS PRODUCT_TARGET,
SKU.SALON_DESIGNATION AS SALON_DESIGNATION,
SKU.SKINTYPE AS SKINTYPE,
SKU.SUBBRANDS AS SUBBRANDS,
SKU.TARGET_CUSTOMER AS TARGET_CUSTOMER,
first_Value(SALONSERVICE.CATEGORY) over (partition by SALONSERVICE.SERVICE_ID order by case when SALONSERVICE.CATEGORY = '' then null else SALONSERVICE.SALON_SERVICE_ID end desc) AS CATEGORY,
coalesce(SALON_SERVICE_CATEGORY_DIMENSION.SERVICE_CATEGORY_KEY,0) AS SERVICE_CATEGORY_KEY, -- will be populated from new keys
SKU.BRAND AS BRAND_ID,
BRANDMAPPING.BRAND_NAME AS BRAND_NAME, 
NULL AS BRAND_KEY -- will be populated from new keys
FROM ulta_work.DRIVER_TABLE_ITEM_DIM DRIVER
LEFT OUTER JOIN ulta_incoming.SKU SKU
ON DRIVER.ITEM_ID = SKU.ITEM_NUMBER
LEFT OUTER JOIN
(
Select root.CLASS_NUMBER as ROOT_ID, root.CLASS_DESCRIPTION AS ROOT_NAME, division.CLASS_NUMBER as DIVISION_ID, division.CLASS_DESCRIPTION as DIVISION_NAME,
dept.CLASS_NUMBER as DEPARTMENT_ID, dept.CLASS_DESCRIPTION AS DEPARTMENT_NAME, category.CLASS_NUMBER as CATEGORY_ID, category.CLASS_DESCRIPTION as CATEGORY_NAME,
subclass.CLASS_NUMBER as SUBCLASS_ID, subclass.CLASS_DESCRIPTION as SUBCLASS_NAME
from 
(select CLASS_NUMBER,CLASS_DESCRIPTION,CLASS_NUMBER_OF_PARENT from ulta_incoming.MERCHHIERARCHY where LEVEL_OF_A_HIERARCHY_NODE = 1) root
LEFT OUTER JOIN 
(select CLASS_NUMBER,CLASS_DESCRIPTION, CLASS_NUMBER_OF_PARENT from ulta_incoming.MERCHHIERARCHY where LEVEL_OF_A_HIERARCHY_NODE = 2) division
ON root.CLASS_NUMBER = division.CLASS_NUMBER_OF_PARENT
LEFT OUTER JOIN 
(select CLASS_NUMBER,CLASS_DESCRIPTION, CLASS_NUMBER_OF_PARENT from ulta_incoming.MERCHHIERARCHY where LEVEL_OF_A_HIERARCHY_NODE = 3) dept
ON division.CLASS_NUMBER = dept.CLASS_NUMBER_OF_PARENT
LEFT OUTER JOIN 
(select CLASS_NUMBER,CLASS_DESCRIPTION, CLASS_NUMBER_OF_PARENT from ulta_incoming.MERCHHIERARCHY where LEVEL_OF_A_HIERARCHY_NODE = 4) category
ON dept.CLASS_NUMBER = category.CLASS_NUMBER_OF_PARENT
LEFT OUTER JOIN 
(select CLASS_NUMBER,CLASS_DESCRIPTION, CLASS_NUMBER_OF_PARENT from ulta_incoming.MERCHHIERARCHY where LEVEL_OF_A_HIERARCHY_NODE = 5) subclass
ON category.CLASS_NUMBER = subclass.CLASS_NUMBER_OF_PARENT
) MERCH
ON DRIVER.SUBCLASS = MERCH.SUBCLASS_ID
LEFT OUTER JOIN (select SUBCLASS_ID, SUBCLASS_NAME, CATEGORY_ID, CATEGORY_NAME, DEPARTMENT_ID, DEPARTMENT_NAME, DIVISION_ID, DIVISION_NAME, ROOT_ID, ROOT_NAME from ulta_vinod.ITEM_DIMENSION_08212018 group by SUBCLASS_ID, SUBCLASS_NAME, CATEGORY_ID, CATEGORY_NAME, DEPARTMENT_ID, DEPARTMENT_NAME, DIVISION_ID, DIVISION_NAME, ROOT_ID, ROOT_NAME) ITEM_DIM -- Change the ulta_vinod.ITEM_DIMENSION_08212018 to ulta_mart.ITEM_DIMENSION
ON DRIVER.SUBCLASS = ITEM_DIM.SUBCLASS_ID
LEFT OUTER JOIN ulta_incoming.BRANDMAPPING BRANDMAPPING
ON SKU.BRAND = BRANDMAPPING.BRAND_ID
LEFT OUTER JOIN ulta_incoming.SALONSERVICE SALONSERVICE
ON cast(SALONSERVICE.SERVICE_ID AS STRING) = SKU.ITEM_NUMBER
LEFT OUTER JOIN ulta_incoming.PRODUCTMETA PRODUCTMETA
ON DRIVER.ITEM_ID = PRODUCTMETA.SSKU
LEFT JOIN ulta_mart.SALON_SERVICE_CATEGORY_DIMENSION
ON SALONSERVICE.SERVICE_ID=SALON_SERVICE_CATEGORY_DIMENSION.SERVICE_ID;


--2. populate unchanged stage table
DELETE ulta_work.ITEM_DIMENSION_UNCHANGED WHERE TRUE;

INSERT INTO ulta_work.ITEM_DIMENSION_UNCHANGED (ITEM_KEY,ITEM_ID,ITEM_DESCRIPTION,ITEM_TYPE_NAME,SIZE_CODE,COLOR_NAME,COLOR_DESCRIPTION,SUBCLASS_KEY,SUBCLASS_ID,SUBCLASS_NAME,CATEGORY_ID,CATEGORY_NAME,DEPARTMENT_ID,DEPARTMENT_NAME,DIVISION_ID,DIVISION_NAME,ROOT_ID,ROOT_NAME,DOTCOM,KEY_BENEFIT,LAST_MODIFIED,SAPUOM,MATERIAL_TYPE,PRICE_BAND_CATEGORY,PRODUCT_TARGET,SALON_DESIGNATION,SKINTYPE,SUBBRANDS,TARGET_CUSTOMER,CATEGORY,SERVICE_CATEGORY_KEY,BRAND_ID,BRAND_NAME,BRAND_KEY)
SELECT mart.ITEM_KEY,mart.ITEM_ID,mart.ITEM_DESCRIPTION,mart.ITEM_TYPE_NAME,mart.SIZE_CODE,mart.COLOR_NAME,mart.COLOR_DESCRIPTION,mart.SUBCLASS_KEY,mart.SUBCLASS_ID,mart.SUBCLASS_NAME,mart.CATEGORY_ID,mart.CATEGORY_NAME,mart.DEPARTMENT_ID,mart.DEPARTMENT_NAME,mart.DIVISION_ID,mart.DIVISION_NAME,mart.ROOT_ID,mart.ROOT_NAME,mart.DOTCOM,mart.KEY_BENEFIT,mart.LAST_MODIFIED,mart.SAPUOM,mart.MATERIAL_TYPE,mart.PRICE_BAND_CATEGORY,mart.PRODUCT_TARGET,mart.SALON_DESIGNATION,mart.SKINTYPE,mart.SUBBRANDS,mart.TARGET_CUSTOMER,mart.CATEGORY,mart.SERVICE_CATEGORY_KEY,mart.BRAND_ID,mart.BRAND_NAME,mart.BRAND_KEY
FROM ulta_mart.ITEM_DIMENSION mart LEFT OUTER JOIN ulta_work.ITEM_DIMENSION stage 
ON mart.ITEM_ID = stage.ITEM_ID
where stage.ITEM_ID is null;

--2. populate updated stage table
DELETE ulta_work.ITEM_DIMENSION_UPDATED WHERE TRUE;

INSERT INTO ulta_work.ITEM_DIMENSION_UPDATED (ITEM_KEY,ITEM_ID,ITEM_DESCRIPTION,ITEM_TYPE_NAME,SIZE_CODE,COLOR_NAME,COLOR_DESCRIPTION,SUBCLASS_KEY,SUBCLASS_ID,SUBCLASS_NAME,CATEGORY_ID,CATEGORY_NAME,DEPARTMENT_ID,DEPARTMENT_NAME,DIVISION_ID,DIVISION_NAME,ROOT_ID,ROOT_NAME,DOTCOM,KEY_BENEFIT,LAST_MODIFIED,SAPUOM,MATERIAL_TYPE,PRICE_BAND_CATEGORY,PRODUCT_TARGET,SALON_DESIGNATION,SKINTYPE,SUBBRANDS,TARGET_CUSTOMER,CATEGORY,SERVICE_CATEGORY_KEY,BRAND_ID,BRAND_NAME,BRAND_KEY)
SELECT mart.ITEM_KEY,stage.ITEM_ID,stage.ITEM_DESCRIPTION,stage.ITEM_TYPE_NAME,stage.SIZE_CODE,stage.COLOR_NAME,stage.COLOR_DESCRIPTION,stage.SUBCLASS_KEY,stage.SUBCLASS_ID,stage.SUBCLASS_NAME,stage.CATEGORY_ID,stage.CATEGORY_NAME,stage.DEPARTMENT_ID,stage.DEPARTMENT_NAME,stage.DIVISION_ID,stage.DIVISION_NAME,stage.ROOT_ID,stage.ROOT_NAME,stage.DOTCOM,stage.KEY_BENEFIT,stage.LAST_MODIFIED,stage.SAPUOM,stage.MATERIAL_TYPE,stage.PRICE_BAND_CATEGORY,stage.PRODUCT_TARGET,stage.SALON_DESIGNATION,stage.SKINTYPE,stage.SUBBRANDS,stage.TARGET_CUSTOMER,stage.CATEGORY,stage.SERVICE_CATEGORY_KEY,stage.BRAND_ID,stage.BRAND_NAME,stage.BRAND_KEY
FROM ulta_mart.ITEM_DIMENSION mart INNER JOIN ulta_work.ITEM_DIMENSION stage 
ON mart.ITEM_ID = stage.ITEM_ID;

--3. delete data from mart 
bq cp ulta_mart.ITEM_DIMENSION ulta_mart.ITEM_DIMENSION_20180726

DELETE ulta_mart.ITEM_DIMENSION WHERE TRUE;


--4. Populate mart table 

INSERT INTO ulta_mart.ITEM_DIMENSION (ITEM_KEY,ITEM_ID,ITEM_DESCRIPTION,ITEM_TYPE_NAME,SIZE_CODE,COLOR_NAME,COLOR_DESCRIPTION,SUBCLASS_KEY,SUBCLASS_ID,SUBCLASS_NAME,CATEGORY_ID,CATEGORY_NAME,DEPARTMENT_ID,DEPARTMENT_NAME,DIVISION_ID,DIVISION_NAME,ROOT_ID,ROOT_NAME,DOTCOM,KEY_BENEFIT,LAST_MODIFIED,SAPUOM,MATERIAL_TYPE,PRICE_BAND_CATEGORY,PRODUCT_TARGET,SALON_DESIGNATION,SKINTYPE,SUBBRANDS,TARGET_CUSTOMER,CATEGORY,SERVICE_CATEGORY_KEY,BRAND_ID,BRAND_NAME,BRAND_KEY)
select stage.ITEM_KEY,stage.ITEM_ID,stage.ITEM_DESCRIPTION,stage.ITEM_TYPE_NAME,stage.SIZE_CODE,stage.COLOR_NAME,stage.COLOR_DESCRIPTION,stage.SUBCLASS_KEY,stage.SUBCLASS_ID,stage.SUBCLASS_NAME,stage.CATEGORY_ID,stage.CATEGORY_NAME,stage.DEPARTMENT_ID,stage.DEPARTMENT_NAME,stage.DIVISION_ID,stage.DIVISION_NAME,stage.ROOT_ID,stage.ROOT_NAME,stage.DOTCOM,stage.KEY_BENEFIT,stage.LAST_MODIFIED,stage.SAPUOM,stage.MATERIAL_TYPE,stage.PRICE_BAND_CATEGORY,stage.PRODUCT_TARGET,stage.SALON_DESIGNATION,stage.SKINTYPE,stage.SUBBRANDS,stage.TARGET_CUSTOMER,stage.CATEGORY,stage.SERVICE_CATEGORY_KEY,stage.BRAND_ID,stage.BRAND_NAME,stage.BRAND_KEY
from ulta_work.ITEM_DIMENSION stage
left join
ulta_work.ITEM_DIMENSION_UPDATED updated
on stage.ITEM_ID = updated.ITEM_ID 
where updated.ITEM_ID is null
UNION ALL
select ITEM_KEY,ITEM_ID,ITEM_DESCRIPTION,ITEM_TYPE_NAME,SIZE_CODE,COLOR_NAME,COLOR_DESCRIPTION,SUBCLASS_KEY,SUBCLASS_ID,SUBCLASS_NAME,CATEGORY_ID,CATEGORY_NAME,DEPARTMENT_ID,DEPARTMENT_NAME,DIVISION_ID,DIVISION_NAME,ROOT_ID,ROOT_NAME,DOTCOM,KEY_BENEFIT,LAST_MODIFIED,SAPUOM,MATERIAL_TYPE,PRICE_BAND_CATEGORY,PRODUCT_TARGET,SALON_DESIGNATION,SKINTYPE,SUBBRANDS,TARGET_CUSTOMER,CATEGORY,SERVICE_CATEGORY_KEY,BRAND_ID,BRAND_NAME,BRAND_KEY
from ulta_work.ITEM_DIMENSION_UPDATED
UNION ALL
select ITEM_KEY,ITEM_ID,ITEM_DESCRIPTION,ITEM_TYPE_NAME,SIZE_CODE,COLOR_NAME,COLOR_DESCRIPTION,SUBCLASS_KEY,SUBCLASS_ID,SUBCLASS_NAME,CATEGORY_ID,CATEGORY_NAME,DEPARTMENT_ID,DEPARTMENT_NAME,DIVISION_ID,DIVISION_NAME,ROOT_ID,ROOT_NAME,DOTCOM,KEY_BENEFIT,LAST_MODIFIED,SAPUOM,MATERIAL_TYPE,PRICE_BAND_CATEGORY,PRODUCT_TARGET,SALON_DESIGNATION,SKINTYPE,SUBBRANDS,TARGET_CUSTOMER,CATEGORY,SERVICE_CATEGORY_KEY,BRAND_ID,BRAND_NAME,BRAND_KEY
from ulta_work.ITEM_DIMENSION_UNCHANGED;

--5. Populate ITEM IDs which are not in ITEM_DIMENSION
INSERT INTO ulta_work.ITEM_ID_TABLE_SOURCE(ITEM_ID,LOAD_DATE)
select UNIONED.ITEM_ID AS ITEM_ID,CURRENT_TIMESTAMP AS LOAD_DATE from 
(SELECT cast(SERVICE_ID as string) AS ITEM_ID FROM ulta_incoming.SALONSALEDETAIL
UNION DISTINCT
SELECT cast(SERVICE_ID as string) AS ITEM_ID FROM ulta_incoming.SALONSERVICE
UNION DISTINCT
SELECT SSKU AS ITEM_ID FROM ulta_incoming.CREDITCARDPOINTSDETAIL 
UNION DISTINCT
SELECT ITEM_NUMBER_SKU AS ITEM_ID FROM ulta_incoming.POINTSDETAIL
UNION DISTINCT
SELECT ITEM_NUMBER_SKU AS ITEM_ID FROM ulta_incoming.PROMOLINEITEM
UNION DISTINCT
SELECT ITEM_NUMBER_SKU AS ITEM_ID FROM ulta_incoming.SALEDETAIL
UNION DISTINCT
SELECT SSKU AS ITEM_ID FROM ulta_incoming.PRODUCTMETA) UNIONED
LEFT OUTER JOIN ulta_mart.ITEM_DIMENSION ITEM
ON UNIONED.ITEM_ID = ITEM.ITEM_ID
where ITEM.ITEM_ID is NULL;


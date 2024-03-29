--DDL
bq mk -t ulta_work.POINTS_DETAIL_FACT POINTS_HEADER_KEY:INTEGER,POINTS_DETAIL_KEY:INTEGER,POINTS_TRANSACTION_ID:INTEGER,LINE_NUMBER:INTEGER,RETURN_FLAG:STRING,OFFERING_ITEM_KEY:INTEGER,BASE_POINT_AMOUNT:FLOAT,BONUS_POINT_AMOUNT:FLOAT,SUBCLASS_KEY:INTEGER,LAST_MODIFIED_DATE:TIMESTAMP,TRANSACTION_DATETIME:TIMESTAMP,SALES_HEADER_KEY:INTEGER

bq mk -t ulta_work.POINTS_DETAIL_FACT_UNCHANGED POINTS_HEADER_KEY:INTEGER,POINTS_DETAIL_KEY:INTEGER,POINTS_TRANSACTION_ID:INTEGER,LINE_NUMBER:INTEGER,RETURN_FLAG:STRING,OFFERING_ITEM_KEY:INTEGER,BASE_POINT_AMOUNT:FLOAT,BONUS_POINT_AMOUNT:FLOAT,SUBCLASS_KEY:INTEGER,LAST_MODIFIED_DATE:TIMESTAMP,TRANSACTION_DATETIME:TIMESTAMP,SALES_HEADER_KEY:INTEGER

bq mk -t ulta_mart.POINTS_DETAIL_FACT POINTS_HEADER_KEY:INTEGER,POINTS_DETAIL_KEY:INTEGER,POINTS_TRANSACTION_ID:INTEGER,LINE_NUMBER:INTEGER,RETURN_FLAG:STRING,OFFERING_ITEM_KEY:INTEGER,BASE_POINT_AMOUNT:FLOAT,BONUS_POINT_AMOUNT:FLOAT,SUBCLASS_KEY:INTEGER,LAST_MODIFIED_DATE:TIMESTAMP,TRANSACTION_DATETIME:TIMESTAMP,SALES_HEADER_KEY:INTEGER

bq mk -t ulta_work.POINTS_DETAIL_FACT_UPDATED POINTS_HEADER_KEY:INTEGER,POINTS_DETAIL_KEY:INTEGER,POINTS_TRANSACTION_ID:INTEGER,LINE_NUMBER:INTEGER,RETURN_FLAG:STRING,OFFERING_ITEM_KEY:INTEGER,BASE_POINT_AMOUNT:FLOAT,BONUS_POINT_AMOUNT:FLOAT,SUBCLASS_KEY:INTEGER,LAST_MODIFIED_DATE:TIMESTAMP,TRANSACTION_DATETIME:TIMESTAMP,SALES_HEADER_KEY:INTEGER

--1. Step to insert in to stage table
DELETE ulta_work.POINTS_DETAIL_FACT WHERE TRUE;

INSERT INTO ulta_work.POINTS_DETAIL_FACT (POINTS_HEADER_KEY,POINTS_DETAIL_KEY,POINTS_TRANSACTION_ID,LINE_NUMBER,RETURN_FLAG,OFFERING_ITEM_KEY,BASE_POINT_AMOUNT,BONUS_POINT_AMOUNT,SUBCLASS_KEY,LAST_MODIFIED_DATE,TRANSACTION_DATETIME,SALES_HEADER_KEY)
SELECT
	NULL AS POINTS_HEADER_KEY,
	NULL AS POINTS_DETAIL_KEY,
	COALESCE(ps.TRANSACTION_ID) AS POINTS_TRANSACTION_ID, --POINTSDETAIL.TRANSACTION_ID-RULEEXECUTION.TRANSACTION_ID
	COALESCE(ps.LINE_NUMBER) AS LINE_NUMBER, --RULEEXECUTION.LINE_NUMBER-POINTSDETAIL.LINE_NUMBER
	ps.RETURN_FLAG AS RETURN_FLAG,
	NULL AS OFFERING_ITEM_KEY, --FK
	CAST(ps.BASE_POINT_AMOUNT AS NUMERIC) AS BASE_POINT_AMOUNT, --SUM(BASE_POINT_AMOUNT) 
	CAST(ps.BONUS_POINT_AMOUNT AS NUMERIC) AS BONUS_POINT_AMOUNT, --SUM(BONUS_POINT_AMOUNT)
	NULL AS SUBCLASS_KEY, --FK
	CAST(SUBSTR((CASE WHEN ps.LAST_MODIFIED = '' THEN NULL ELSE ps.LAST_MODIFIED END),1,19) AS TIMESTAMP) AS LAST_MODIFIED_DATE,
	NULL AS TRANSACTION_DATETIME, --It will come from POINTS_HEADER_FACT
	ph.FK_SALEID AS SALES_HEADER_KEY -- It will come from ph 
FROM
	ulta_incoming.POINTSDETAIL ps
LEFT OUTER JOIN
	(select * from (select *, row_number() over ( partition by transaction_id order by last_modified desc) as row_num from ulta_incoming.POINTSHEADER) where row_num = 1) ph
ON ps.TRANSACTION_ID = ph.TRANSACTION_ID 
/*LEFT OUTER JOIN
	--ulta_incoming.RULEEXECUTION re
(SELECT TRANSACTION_ID, LINE_NUMBER FROM ulta_incoming.RULEEXECUTION WHERE IFNULL(CAST(TRANSACTION_ID AS STRING),'') not in ('', '0') AND IFNULL(CAST(LINE_NUMBER AS STRING),'') not in ('', '0') GROUP BY TRANSACTION_ID, LINE_NUMBER) re
ON ps.TRANSACTION_ID = re.TRANSACTION_ID*/;

--2. populate unchanged stage table
DELETE ulta_work.POINTS_DETAIL_FACT_UNCHANGED WHERE TRUE;
	
	
INSERT INTO ulta_work.POINTS_DETAIL_FACT_UNCHANGED (POINTS_HEADER_KEY,POINTS_DETAIL_KEY,POINTS_TRANSACTION_ID,LINE_NUMBER,RETURN_FLAG,OFFERING_ITEM_KEY,BASE_POINT_AMOUNT,BONUS_POINT_AMOUNT,SUBCLASS_KEY,LAST_MODIFIED_DATE,TRANSACTION_DATETIME,SALES_HEADER_KEY)
SELECT mart.POINTS_HEADER_KEY,mart.POINTS_DETAIL_KEY,mart.POINTS_TRANSACTION_ID,mart.LINE_NUMBER,mart.RETURN_FLAG,mart.OFFERING_ITEM_KEY,mart.BASE_POINT_AMOUNT,mart.BONUS_POINT_AMOUNT,mart.SUBCLASS_KEY,mart.LAST_MODIFIED_DATE,mart.TRANSACTION_DATETIME,mart.SALES_HEADER_KEY
FROM 
ulta_mart.POINTS_DETAIL_FACT mart LEFT OUTER JOIN ulta_work.POINTS_DETAIL_FACT stage ON mart.POINTS_TRANSACTION_ID = stage.POINTS_TRANSACTION_ID
AND mart.LINE_NUMBER = stage.LINE_NUMBER
WHERE stage.POINTS_TRANSACTION_ID IS NULL;

--2. populate updated stage table
DELETE ulta_work.POINTS_DETAIL_FACT_UPDATED WHERE TRUE;
	
	
INSERT INTO ulta_work.POINTS_DETAIL_FACT_UPDATED (POINTS_HEADER_KEY,POINTS_DETAIL_KEY,POINTS_TRANSACTION_ID,LINE_NUMBER,RETURN_FLAG,OFFERING_ITEM_KEY,BASE_POINT_AMOUNT,BONUS_POINT_AMOUNT,SUBCLASS_KEY,LAST_MODIFIED_DATE,TRANSACTION_DATETIME,SALES_HEADER_KEY)
SELECT stage.POINTS_HEADER_KEY,mart.POINTS_DETAIL_KEY,stage.POINTS_TRANSACTION_ID,stage.LINE_NUMBER,stage.RETURN_FLAG,stage.OFFERING_ITEM_KEY,stage.BASE_POINT_AMOUNT,stage.BONUS_POINT_AMOUNT,stage.SUBCLASS_KEY,stage.LAST_MODIFIED_DATE,stage.TRANSACTION_DATETIME,stage.SALES_HEADER_KEY
FROM 
ulta_mart.POINTS_DETAIL_FACT mart INNER JOIN ulta_work.POINTS_DETAIL_FACT stage ON mart.POINTS_TRANSACTION_ID = stage.POINTS_TRANSACTION_ID
AND mart.LINE_NUMBER = stage.LINE_NUMBER;

--3. delete data from mart 
bq cp ulta_mart.POINTS_DETAIL_FACT ulta_mart.POINTS_DETAIL_FACT_20180727
DELETE ulta_mart.POINTS_DETAIL_FACT WHERE TRUE; 


--4. Populate mart table

INSERT INTO ulta_mart.POINTS_DETAIL_FACT(POINTS_HEADER_KEY,POINTS_DETAIL_KEY,POINTS_TRANSACTION_ID,LINE_NUMBER,RETURN_FLAG,OFFERING_ITEM_KEY,BASE_POINT_AMOUNT,BONUS_POINT_AMOUNT,SUBCLASS_KEY,LAST_MODIFIED_DATE,TRANSACTION_DATETIME,SALES_HEADER_KEY)
SELECT stage.POINTS_HEADER_KEY,stage.POINTS_DETAIL_KEY,stage.POINTS_TRANSACTION_ID,stage.LINE_NUMBER,stage.RETURN_FLAG,stage.OFFERING_ITEM_KEY,stage.BASE_POINT_AMOUNT,stage.BONUS_POINT_AMOUNT,stage.SUBCLASS_KEY,stage.LAST_MODIFIED_DATE,stage.TRANSACTION_DATETIME,stage.SALES_HEADER_KEY
FROM ulta_work.POINTS_DETAIL_FACT stage
LEFT OUTER JOIN  ulta_work.POINTS_DETAIL_FACT_UPDATED updated
ON stage.POINTS_TRANSACTION_ID = updated.POINTS_TRANSACTION_ID AND stage.LINE_NUMBER = updated.LINE_NUMBER
WHERE updated.POINTS_TRANSACTION_ID is null
UNION ALL
SELECT
POINTS_HEADER_KEY,POINTS_DETAIL_KEY,POINTS_TRANSACTION_ID,LINE_NUMBER,RETURN_FLAG,OFFERING_ITEM_KEY,BASE_POINT_AMOUNT,BONUS_POINT_AMOUNT,SUBCLASS_KEY,LAST_MODIFIED_DATE,TRANSACTION_DATETIME,SALES_HEADER_KEY
from ulta_work.POINTS_DETAIL_FACT_UPDATED
UNION ALL
SELECT POINTS_HEADER_KEY,POINTS_DETAIL_KEY,POINTS_TRANSACTION_ID,LINE_NUMBER,RETURN_FLAG,OFFERING_ITEM_KEY,BASE_POINT_AMOUNT,BONUS_POINT_AMOUNT,SUBCLASS_KEY,LAST_MODIFIED_DATE,TRANSACTION_DATETIME,SALES_HEADER_KEY
FROM ulta_work.POINTS_DETAIL_FACT_UNCHANGED;

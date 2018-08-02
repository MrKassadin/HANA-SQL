DROP PROCEDURE XN_FM."FR_ActualCostPPOIGNDT";
CREATE PROCEDURE XN_FM."FR_ActualCostPPOIGNDT"
(
IN DocNum INT,
IN FcCode NVARCHAR(10),
IN ItemCode NVARCHAR(10)
)
LANGUAGE SQLSCRIPT
AS
BEGIN

	DECLARE Pierod_MHAmt DECIMAL;
	DECLARE Pierod_LableAmt DECIMAL;
	DECLARE Pierod_DisPower DECIMAL;
	DECLARE Last_MHAmt DECIMAL;
	DECLARE Last_LableAmt DECIMAL;
	DECLARE Last_DisPower DECIMAL;
	
	SELECT SUM("DisAmount") INTO Pierod_MHAmt FROM "U_CMOH1" WHERE "ItemCode"=:ItemCode AND "FcCode"=:FcCode AND "AcctCode"<>'50010202';
	SELECT SUM("DisAmount") INTO Pierod_LableAmt FROM "U_CMOH1" WHERE "ItemCode"=:ItemCode AND "FcCode"=:FcCode AND "AcctCode"='50010202';
	SELECT SUM("DisPower") INTO Pierod_DisPower FROM "U_CMOH1" WHERE "ItemCode"=:ItemCode AND "FcCode"=:FcCode AND "AcctCode"='50010202';--本期分摊数量*权重
	SELECT SUM("DisAmount") INTO Last_MHAmt FROM "U_CMOH1" WHERE "ItemCode"=:ItemCode AND "FcCode"=LEFT(:FcCode,6)||(TO_INT(RIGHT(:FcCode,1))-1) AND "AcctCode"<>'50010202';
	SELECT SUM("DisAmount") INTO Last_LableAmt FROM "U_CMOH1" WHERE "ItemCode"=:ItemCode AND "FcCode"=LEFT(:FcCode,6)||(TO_INT(RIGHT(:FcCode,1))-1) AND "AcctCode"='50010202';
	SELECT SUM("DisPower") INTO Last_DisPower FROM "U_CMOH1" WHERE "ItemCode"=:ItemCode AND "FcCode"=LEFT(:FcCode,6)||(TO_INT(RIGHT(:FcCode,1))-1) AND "AcctCode"='50010202';--上期分摊数量*权重
	
	
	--生产收货金额sql_2_工单号钻取
	SELECT T0."PlantCode",
		   CASE WHEN T0."PlantCode" = 'W0000001' THEN N'膨化厂（上海）' 
			   	WHEN T0."PlantCode" = 'W0000002' THEN N'青浦厂（上海）'
			   	WHEN T0."PlantCode" = 'W0000003' THEN N'松江厂（上海）'
			   	WHEN T0."PlantCode" = 'W0000004' THEN N'香川厂（上海）' ELSE T8."Descr" END "Descr",
		   CASE WHEN T0."ItemCode" IS NULL THEN 'MH_Lable' ELSE T0."ItemCode" END "ItemCode",
		   CASE WHEN T0."ItemCode" IS NULL THEN '工费分摊' ELSE T1."ItemName" END "ItemName",
		   TO_DATE(T2."PostDate") "DocDate",T2."DocNum", 
		   CASE WHEN T2."U_ProType" = 'S' THEN N'标准'
		   	    WHEN T2."U_ProType" = 'P' THEN N'换包'
		   	    WHEN T2."U_ProType" = 'T' THEN N'回机' END "ProType",
		   CASE WHEN T0."DocType" = 'OWOR' THEN N'生产工单'
		   	    WHEN T0."DocType" = 'PlantTRS' THEN N'工厂间调入调出'
		   	    WHEN T0."DocType" = 'PRDItemTRS' THEN N'物料代码转换' END "Type",
		   T0."IssueType",
		   CASE WHEN T0."DocType" = 'OWOR' THEN T0."Quantity" ELSE 0 END AS "WOR1Qty",
		   CASE WHEN T0."DocType" = 'OWOR' THEN T0."StdAmount" ELSE 0 END AS "WOR1StdAmt",
		   CASE WHEN T0."DocType" = 'OWOR' THEN T0."FactAmount" ELSE 0 END AS "WOR1FactAmt",
		   ROUND(CASE WHEN T0."DocType" = 'OWOR' THEN T0."FactPrice" ELSE 0 END,4) AS "Pierod_Price",
	   	   ROUND(IFNULL(T6."Price",0),4) "Last_Price",
	   	   ROUND(CASE WHEN T0."DocType" = 'OWOR' THEN T0."FactPrice" ELSE 0 END,4) - ROUND(IFNULL(T6."Price",0),4) "AdjPrice",
	   	   CASE WHEN ROUND(CASE WHEN T0."DocType" = 'OWOR' THEN T0."FactPrice" ELSE 0 END,4) - ROUND(IFNULL(T6."Price",0),4) > 0 THEN N'升'
	   		    WHEN ROUND(CASE WHEN T0."DocType" = 'OWOR' THEN T0."FactPrice" ELSE 0 END,4) - ROUND(IFNULL(T6."Price",0),4) = 0 THEN N'平'
	   		    WHEN ROUND(CASE WHEN T0."DocType" = 'OWOR' THEN T0."FactPrice" ELSE 0 END,4) - ROUND(IFNULL(T6."Price",0),4) < 0 THEN N'降' END "成本趋势"
		   --CASE WHEN T0."DocType" = 'PlantTRS' THEN T0."Quantity" ELSE 0 END AS "PlantTRSOutQty",
		   --CASE WHEN T0."DocType" = 'PlantTRS' THEN ROUND(T0."FactAmount",2) ELSE 0 END AS "PlantTRSOutAmt",
		   --CASE WHEN T0."DocType" = 'PRDItemTRS' THEN T0."Quantity" ELSE 0 END AS "PRDItemTRSOutQty",
		   --CASE WHEN T0."DocType" = 'PRDItemTRS' THEN ROUND(T0."FactAmount",2) ELSE 0 END AS "PRDItemTRSOutAmt",
	FROM U_CWOR1 T0
	LEFT JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
	LEFT JOIN OWOR T2 ON T0."DocEntry" = T2."DocEntry"
	LEFT JOIN U_COPCT T6 ON T0."PlantCode" = T6."PlantCode" AND T0."ItemCode" = T6."ItemCode" AND T0."BPLId" = T6."BPLId" 
					    AND T6."FcCode" = (SELECT MAX("Code") FROM OFPR WHERE "Code" < :FcCode)
	LEFT JOIN (SELECT "FldValue","Descr" FROM UFD1 WHERE "TableID" = 'OWHS' AND "FieldID" = 7) T8 ON T0."PlantCode" = T8."FldValue"
	WHERE T0."DocType" = 'OWOR' AND T0."IssueType" <> '费用分摊'
	  AND T2."DocNum" = :DocNum  --工单号
	--ORDER BY T0."ItemCode" ASC
	
	UNION ALL
	SELECT "PlantCode","Descr","ItemCode","ItemName","DocDate","DocNum","ProType","Type","IssueType",
		   "WOR1Qty","WOR1StdAmt",SUM("WOR1FactAmt") "WOR1FactAmt"
		   ,CASE WHEN "ItemCode"='MH' THEN :Pierod_MHAmt/:Pierod_DisPower
		    WHEN "ItemCode"='Lable' THEN :Pierod_LableAmt/:Pierod_DisPower
		    END "Pierod_Price"
		   ,CASE WHEN "ItemCode"='MH' THEN :Last_MHAmt/:Last_DisPower
		    WHEN "ItemCode"='Lable' THEN :Last_LableAmt/:Last_DisPower
		    END "Last_Price"
		   ,"AdjPrice","成本趋势"
	FROM(
		SELECT T1."PlantCode",
			   CASE WHEN T1."PlantCode" = 'W0000001' THEN N'膨化厂（上海）' 
				   	WHEN T1."PlantCode" = 'W0000002' THEN N'青浦厂（上海）'
				   	WHEN T1."PlantCode" = 'W0000003' THEN N'松江厂（上海）'
				   	WHEN T1."PlantCode" = 'W0000004' THEN N'香川厂（上海）' ELSE T8."Descr" END "Descr",
			   CASE WHEN T0."AcctCode" = '50010202' THEN 'Lable' ELSE 'MH' END "ItemCode",
			   CASE WHEN T0."AcctCode" = '50010202' THEN '直接人工' ELSE '制造费用' END "ItemName",
			   TO_DATE(T2."PostDate") "DocDate",T2."DocNum", 
			   CASE WHEN T2."U_ProType" = 'S' THEN N'标准'
			   	    WHEN T2."U_ProType" = 'P' THEN N'换包'
			   	    WHEN T2."U_ProType" = 'T' THEN N'回机' END "ProType",
			  N'生产工单'"Type",
			  N'费用分摊'"IssueType",
			  NULL "WOR1Qty",
			  NULL "WOR1StdAmt",
			  T0."DisAmount" "WOR1FactAmt",
			  NULL "Pierod_Price",
			  NULL "Last_Price",
			  NULL "AdjPrice",
			  NULL "成本趋势"
		FROM U_CMOH1 T0
		JOIN (SELECT DISTINCT "PlantCode","DocEntry","DocType" FROM U_CWOR1) T1 ON T0."DocEntry"=T1."DocEntry" AND T1."DocType"='OWOR'
		LEFT JOIN OWOR T2 ON T0."DocEntry" = T2."DocEntry"
		LEFT JOIN (SELECT "FldValue","Descr" FROM UFD1 WHERE "TableID" = 'OWHS' AND "FieldID" = 7) T8 ON T1."PlantCode" = T8."FldValue"
		WHERE T2."DocNum" = :DocNum
		) U0
	WHERE 1=1
	GROUP BY "PlantCode","Descr","ItemCode","ItemName","DocDate","DocNum","ProType","Type","IssueType",
			 "WOR1Qty","WOR1StdAmt","Pierod_Price","Last_Price","AdjPrice","成本趋势";
	 
END;
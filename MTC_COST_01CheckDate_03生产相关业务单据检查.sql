ALTER PROCEDURE "MTC_COST_01CheckDate_03" 
(
IN BPLId NVARCHAR(20),
IN FcCode NVARCHAR(20)
)
LANGUAGE SQLSCRIPT
AS
BEGIN 
  DECLARE BDATE DATE;
  DECLARE EDATE DATE;
  
  --起止日期
  SELECT "F_RefDate","T_RefDate" INTO BDATE ,EDATE FROM OFPR WHERE "Code" = :FcCode;
  
  --提取Advance GL AcctCode中物料料组配置的科目设置
  StockDifActTmp = SELECT DISTINCT T0."ItmsGrpCod",T0."StockAct" AS "BalInvntAc",T0."VariancAct" AS "VarianceAc",T1."U_ItemGrpType",T1."ItmsGrpNam" 
   			       FROM OGAR T0 JOIN OITB T1 ON T0."ItmsGrpCod" = T1."ItmsGrpCod"; 
   			       
  /*此存储过程用来检查成本相关的配置是否正确*/
  --01，提取配置 相关的数据
  Temp01=
     SELECT T1."U_ChkId" AS "ItemCode",
            T1."U_Comment" AS "ItemName",
            T0."Code"
        FROM "@MTC_CCHKDB" T0
        JOIN "@MTC_CCHKDB1" T1 ON T0."Code" =T1."Code"
        WHERE T0."Code" ='30';
   
  --02.直接生产耗用相关
  Temp03=
	 SELECT T0."DocNum",T0."BPLId",
	 		CASE WHEN T1."BaseType" = '202' AND T1."BaseLine" IS NULL THEN N'生产收货'
	 			 WHEN T1."BaseType" = '202' AND T1."BaseLine" IS NOT NULL THEN N'退货组件'
	 			 WHEN T1."BaseType" = '-1' THEN N'库存-收货'END "ObjType",
	 		T0."U_TrsName",T0."U_SrcNum",T0."DocDate",T3."CloseDate",
	 		T1."ItemCode",T2."ItemName",T20."U_ItemGrpType",T1."BaseType",T1."BaseLine",T1."LineNum",T1."AcctCode",
	 		T1."WhsCode",IFNULL(T7."U_AcToPlant",'') "AcToPlant",IFNULL(T7."U_Workshop",'-') "Workshop",T10."InQty"-T10."OutQty" "Quantity",
	 		T3."ItemCode" "OWORItemCode",T5."ItemName" "OWORItemName",T50."U_ItemGrpType" "OWORU_ItemGrpType",
	 		T3."OcrCode" "OWOROcrCode",T3."OcrCode2" "OWOROcrCode2",T6."U_Workshop" "OWORU_Workshop",
	 		T3."DocNum" "OWORDocNum",T3."PostDate" "OWORDocDate",
	 		T3."Status" "OWORStatus",IFNULL(T3."U_ProType",'') "OWORU_ProType",
	 		T17."BPLid" "OWORBPLId"
	 FROM OIGN T0
	  INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
	  INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	  INNER JOIN OITB T20 ON T2."ItmsGrpCod" = T20."ItmsGrpCod"
	  INNER JOIN OFPR T4 ON T0."DocDate" BETWEEN T4."F_RefDate" AND T4."T_RefDate" 
	  LEFT JOIN OWOR T3 ON CASE WHEN T1."BaseType" = '-1' THEN T0."U_SrcNum" ELSE T1."BaseRef" END = T3."DocNum"
	  LEFT JOIN OITM T5 ON T3."ItemCode" = T5."ItemCode"
	  LEFT JOIN OITB T50 ON T5."ItmsGrpCod" = T50."ItmsGrpCod"
	  LEFT JOIN "@U_PIT1" T6 ON T3."ItemCode" = T6."U_ItemCode" AND T6."Code" = :BPLId
	  LEFT JOIN OWHS T7 ON T1."WhsCode" = T7."WhsCode"
	  LEFT JOIN OWHS T17 ON T3."Warehouse" = T17."WhsCode"
	  LEFT JOIN OIVL T10 ON T1."LineNum" = T10."DocLineNum" AND T1."DocEntry" = T10."CreatedBy" AND T10."TransType" = '59'
	 WHERE T4."Code" = :FcCode AND T0."BPLId" = :BPLId
	   AND ( T1."BaseType" = '202' OR (T1."BaseType" = '-1' AND T0."U_TrsName" IN('301','302','303','304')) )
	 
	 UNION ALL
	 SELECT T0."DocNum",T0."BPLId",
	 		CASE WHEN T1."BaseType" = '202' AND T1."BaseLine" IS NOT NULL THEN N'生产发料'
	 			 WHEN T1."BaseType" = '-1' THEN N'库存-发货'END "ObjType",
	 		T0."U_TrsName",T0."U_SrcNum",T0."DocDate",T3."CloseDate",
	 		T1."ItemCode",T2."ItemName",T20."U_ItemGrpType",T1."BaseType",T1."BaseLine",T1."LineNum",T1."AcctCode",
	 		T1."WhsCode",IFNULL(T7."U_AcToPlant",'') "AcToPlant",IFNULL(T7."U_Workshop",'-') "Workshop",T10."InQty"-T10."OutQty" "Quantity",
	 		T3."ItemCode" "OWORItemCode",T5."ItemName" "OWORItemName",T50."U_ItemGrpType" "OWORU_ItemGrpType",
	 		T3."OcrCode" "OWOROcrCode",T3."OcrCode2" "OWOROcrCode2",T6."U_Workshop" "OWORU_Workshop",
	 		T3."DocNum" "OWORDocNum",T3."PostDate" "OWORDocDate",
	 		T3."Status" "OWORStatus",IFNULL(T3."U_ProType",'') "OWORU_ProType",
	 		T17."BPLid"
	 FROM OIGE T0
	  INNER JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry"
	  INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	  INNER JOIN OITB T20 ON T2."ItmsGrpCod" = T20."ItmsGrpCod"
	  INNER JOIN OFPR T4 ON T0."DocDate" BETWEEN T4."F_RefDate" AND T4."T_RefDate" 
	  LEFT JOIN OWOR T3 ON CASE WHEN T1."BaseType" = '-1' THEN T0."U_SrcNum" ELSE T1."BaseRef" END = T3."DocNum"
	  LEFT JOIN OITM T5 ON T3."ItemCode" = T5."ItemCode"
	  LEFT JOIN OITB T50 ON T5."ItmsGrpCod" = T50."ItmsGrpCod"
	  LEFT JOIN "@U_PIT1" T6 ON T3."ItemCode" = T6."U_ItemCode" AND T6."Code" = :BPLId
	  LEFT JOIN OWHS T7 ON T1."WhsCode" = T7."WhsCode"
	  LEFT JOIN OWHS T17 ON T3."Warehouse" = T17."WhsCode"
	  LEFT JOIN OIVL T10 ON T1."LineNum" = T10."DocLineNum" AND T1."DocEntry" = T10."CreatedBy" AND T10."TransType" = '60'
	 WHERE T4."Code" = :FcCode AND T0."BPLId" = :BPLId
	   AND ( T1."BaseType" = '202' OR (T1."BaseType" = '-1' AND T0."U_TrsName" IN('301','302','303','304')) )
	 ;  
  
  
  --其他出入库数据		   
  Temp04=
     SELECT T0."DocNum",T0."BPLId",
	 		CASE WHEN T1."BaseType" = '202' AND T1."BaseLine" IS NULL THEN N'生产收货'
	 			 WHEN T1."BaseType" = '202' AND T1."BaseLine" IS NOT NULL THEN N'退货组件'
	 			 WHEN T1."BaseType" = '-1' THEN N'库存-收货'END "ObjType",
	 		T0."U_TrsName",T0."U_SrcNum",T0."DocDate", 
	 		T1."ItemCode",T2."ItemName",T20."U_ItemGrpType",T1."BaseType",T1."BaseLine",T1."LineNum",
	 		T1."WhsCode",IFNULL(T7."U_Workshop",'-') "Workshop",T10."InQty"-T10."OutQty" "Quantity",
	 		T1."AcctCode"
     FROM OIGN T0
	  INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"
	  INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	  INNER JOIN OITB T20 ON T2."ItmsGrpCod" = T20."ItmsGrpCod"
	  INNER JOIN OFPR T4 ON T0."DocDate" BETWEEN T4."F_RefDate" AND T4."T_RefDate" 
	  LEFT JOIN "@U_PIT1" T6 ON T1."ItemCode" = T6."U_ItemCode" AND T6."Code" = :BPLId
	  LEFT JOIN OWHS T7 ON T1."WhsCode" = T7."WhsCode"
	  LEFT JOIN OIVL T10 ON T1."LineNum" = T10."DocLineNum" AND T1."DocEntry" = T10."CreatedBy" AND T10."TransType" = '59'
	 WHERE T4."Code" = :FcCode AND T0."BPLId" = :BPLId
	   AND T1."BaseType" = '-1' AND T0."U_TrsName" NOT IN('301','302','303','304')
	 
  	 UNION ALL
  	 SELECT T0."DocNum",T0."BPLId",
	 		CASE WHEN T1."BaseType" = '202' AND T1."BaseLine" IS NOT NULL THEN N'生产发料'
	 			 WHEN T1."BaseType" = '-1' THEN N'库存-发货'END "ObjType",
	 		T0."U_TrsName",T0."U_SrcNum",T0."DocDate", 
	 		T1."ItemCode",T2."ItemName",T20."U_ItemGrpType",T1."BaseType",T1."BaseLine",T1."LineNum",
	 		T1."WhsCode",IFNULL(T7."U_Workshop",'-') "Workshop",T10."InQty"-T10."OutQty" "Quantity",
	 		T1."AcctCode"
     FROM OIGE T0
	  INNER JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry"
	  INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	  INNER JOIN OITB T20 ON T2."ItmsGrpCod" = T20."ItmsGrpCod"
	  INNER JOIN OFPR T4 ON T0."DocDate" BETWEEN T4."F_RefDate" AND T4."T_RefDate" 
	  LEFT JOIN "@U_PIT1" T6 ON T1."ItemCode" = T6."U_ItemCode" AND T6."Code" = :BPLId
	  LEFT JOIN OWHS T7 ON T1."WhsCode" = T7."WhsCode"
	  LEFT JOIN OIVL T10 ON T1."LineNum" = T10."DocLineNum" AND T1."DocEntry" = T10."CreatedBy" AND T10."TransType" = '60'
	 WHERE T4."Code" = :FcCode AND T0."BPLId" = :BPLId
	   AND T1."BaseType" = '-1' AND T0."U_TrsName" NOT IN('301','302','303','304') ;
	   	   
  
  
  Temp02=
     --3001 入库产品与订单产品一致检查
     SELECT  DISTINCT
     		'3001'AS "Code",
             "ObjType" AS "ObjType",
             T0."DocNum" AS "DocEntry",
             T0."ItemCode" AS "ItemCode",
             T0."ItemName" AS "ItemName",
	         N'数据错误：该单据不为生产订单-'||T0."OWORDocNum"||'的产出物料；方法：反向调整或修改源单编号' AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE IFNULL(T0."U_TrsName" ,'') = '302' AND T0."ItemCode" <> T0."OWORItemCode"
	 
	 --3002 单据与订单日期同月检查
	 UNION ALL
	 SELECT  DISTINCT
	 		'3002'AS "Code",
             "ObjType" AS "ObjType",
             T0."DocNum" AS "DocEntry",
             N'单据日期：'||TO_NVARCHAR(TO_DATE(T0."DocDate")) AS "ItemCode",
             N'订单日期：'||TO_NVARCHAR(TO_DATE(T0."OWORDocDate")) AS "ItemName",
	         N'数据错误：单据过账日期与生产订单-'||T0."OWORDocNum"||'的日期不为同一期间；方法：先反向调整,再当期耗用' AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE LEFT(TO_NVARCHAR(TO_DATE(T0."DocDate")),7) <> LEFT(TO_NVARCHAR(TO_DATE(T0."OWORDocDate")),7)
	 
	 --3003 订单结算日期检查
	 UNION ALL
	 SELECT  DISTINCT
	 		'3003'AS "Code",
            '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             N'订单日期：'||TO_NVARCHAR(TO_DATE(T0."DocDate")) AS "ItemCode",
             N'结算日期：'||TO_NVARCHAR(TO_DATE(T0."OWORDocDate")) AS "ItemName",
	         N'数据错误：该生产订单日期 与 结算日期 不为同一期间；方法：成本结转后再总账调整差异' AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE LEFT(TO_NVARCHAR(TO_DATE(T0."CloseDate")),7) <> LEFT(TO_NVARCHAR(TO_DATE(T0."OWORDocDate")),7)
	 
	 --3004 产品BOM检查
	 UNION ALL
	 SELECT  DISTINCT
	 		'3004'AS "Code",
            '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：该生产订单的产品未设置系统物料清单-BOM；请先维护 物料清单-BOM ' AS "ErrorMSG"
     FROM :Temp03 T0
      LEFT JOIN "@U_COITT" T1 ON T0."OWORItemCode" = T1."U_Code" AND T0."BPLId" = T1."U_BPLID"
	 WHERE T1."DocEntry" IS NULL AND T0."OWORStatus" <> 'C'
	 
	 --3005 产出负数量检查
	 UNION ALL
	 SELECT  '3005'AS "Code",
             '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             TO_NVARCHAR(SUM(T0."Quantity")) AS "ItemName",
	         N'数据错误：该生产订单的产出为负数量:'||TO_NVARCHAR(SUM(T0."Quantity"))  AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE ( (T0."BaseType" = '202' AND T0."BaseLine" IS NULL) OR (T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName" ,'') = '302') )
	 GROUP BY T0."OWORDocNum",T0."OWORItemCode"
	 HAVING SUM(T0."Quantity") < 0
	 
	 --3006 工单有产出无投入 检查
	 UNION ALL
	 SELECT  '3006'AS "Code",
             '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：该生产订单存在 有产出无投入 的情况；方法:请调整工单的投入或产出，保证工单有产出有投入'  AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE T0."OWORStatus" <> 'C'
	 GROUP BY T0."OWORDocNum",T0."OWORItemCode",T0."OWORItemName" 
	 HAVING IFNULL(SUM(CASE WHEN ( (T0."BaseType" = '202' AND T0."BaseLine" IS NULL) OR (T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName" ,'') = '302') )THEN IFNULL(T0."Quantity",0) ELSE 0 END ),0) <> 0
		AND IFNULL(SUM(CASE WHEN ( (T0."BaseType" = '202' AND T0."BaseLine" IS NOT NULL) OR (T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName" ,'') <> '302') )THEN IFNULL(T0."Quantity",0) ELSE 0 END ),0) = 0
	 
	 --3007 工单有投入无产出 检查
	 UNION ALL
	 SELECT  '3007'AS "Code",
             '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：该生产订单存在 有投入无产出  的情况；方法:请调整工单的投入或产出，保证工单有产出有投入'  AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE T0."OWORStatus" <> 'C'
	 GROUP BY T0."OWORDocNum",T0."OWORItemCode",T0."OWORItemName" 
	 HAVING IFNULL(SUM(CASE WHEN ( (T0."BaseType" = '202' AND T0."BaseLine" IS NULL) OR (T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName" ,'') = '302') )THEN IFNULL(T0."Quantity",0) ELSE 0 END ),0) = 0
		AND IFNULL(SUM(CASE WHEN ( (T0."BaseType" = '202' AND T0."BaseLine" IS NOT NULL) OR (T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName" ,'') <> '302') )THEN IFNULL(T0."Quantity",0) ELSE 0 END ),0) <> 0
	 
	 --3008 工单状态检查
	 UNION ALL
	 SELECT  '3008'AS "Code",
             '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：为 取消 状态的生产订单不允许存在产出；方法:请调整工单的产出为0'  AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE T0."OWORStatus" = 'C'
	 GROUP BY T0."OWORDocNum",T0."OWORItemCode",T0."OWORItemName" 
	 HAVING SUM(CASE WHEN ( (T0."BaseType" = '202' AND T0."BaseLine" IS NULL) OR (T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName" ,'') = '302') )THEN IFNULL(T0."Quantity",0) ELSE 0 END ) <> 0
	 
	 --3009 工单状态检查
	 UNION ALL
	 SELECT  '3009'AS "Code",
             '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：为 取消 状态的生产订单不允许存在投入；方法:请调整工单的投入为0'  AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE T0."OWORStatus" = 'C'
	 GROUP BY T0."OWORDocNum",T0."OWORItemCode",T0."OWORItemName" 
	 HAVING SUM(CASE WHEN ( (T0."BaseType" = '202' AND T0."BaseLine" IS NOT NULL) OR (T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName" ,'') <> '302') )THEN IFNULL(T0."Quantity",0) ELSE 0 END ) <> 0
	 
	 --3010生产类型检查
	 UNION ALL
	 SELECT  DISTINCT 
	 		 '3010'AS "Code",
             '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：订单的生产类型错误，方法：请修改生产类型为T-回机生产 或 P-换包生产'  AS "ErrorMSG"
     FROM :Temp03 T0
     LEFT JOIN "@U_COITT" T1 ON T0."OWORItemCode" = T1."U_Code" AND T0."OWORBPLId" = T1."U_BPLID"
     LEFT JOIN "@U_CITT1" T2 ON T1."DocEntry" = T2."DocEntry" AND T0."ItemCode" = T2."U_Code"
	 WHERE T0."OWORStatus" <> 'C' 
	   AND ( (T0."BaseType" = '202' AND T0."BaseLine" IS NOT NULL) OR (T0."U_TrsName" IN ('301','303','304')) )	  --查看工单投料 		
	   AND T0."U_ItemGrpType" =  T0."OWORU_ItemGrpType" 	--投入物料与订单产品同一级别 ，
	   AND T0."OWORU_ProType" = 'S' 						--且生产类型= 'S' 时，需要修改生产类型
	   AND T2."DocEntry" IS NULL							--且 不属于BOM组件 ，
	 
	 --3011跨工厂耗用
	 UNION ALL
	 SELECT '3011'AS "Code",
             T0."ObjType",
             T0."DocNum" AS "DocEntry",
             T0."ItemCode" AS "ItemCode",
             T0."ItemName" AS "ItemName",
	         N'数据错误：单据行-'||T0."ItemCode"||'的仓库错误，不允许出现跨工厂进行生产耗用；'||'方法：请反向调整单据'  AS "ErrorMSG"
     FROM :Temp03 T0
	 WHERE T0."OWORDocNum" IS NOT NULL
	   AND T0."AcToPlant" <> T0."OWOROcrCode"
	   AND T0."U_ItemGrpType" NOT IN ('A','B')
	   AND ( IFNULL(T0."U_TrsName",'') IN ('301','303','304') OR "ObjType" IN('生产发料','退货组件') )

	 --3012 原料类订单检查
	 UNION ALL
	 SELECT '3012'AS "Code",
             T0."ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：不允许添加原料级别的生产订单；方法：修改产品的物料组属性半成品或成品'  AS "ErrorMSG"
     FROM :Temp03 T0 
	 WHERE T0."OWORStatus" <> 'C' AND IFNULL(T0."OWORU_ItemGrpType",'') NOT IN('A','B')
	 
	 --3013 产品对应表检查
	 UNION ALL
	 SELECT '3013'AS "Code",
             '生产订单' AS "ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	         N'数据错误：该产品未维护在工厂产品对应表中；方法：请先维护'  AS "ErrorMSG"
     FROM :Temp03 T0 
     LEFT JOIN "@U_PIT1" T1 ON T0."OWORItemCode" = T1."U_ItemCode" AND T1."Code" = :BPLId
	 WHERE T0."OWORStatus" <> 'C' 
       AND ( IFNULL(T0."U_TrsName",'') IN ('302') OR "ObjType" IN('生产收货') )
       AND T1."Code" IS NULL
	 GROUP BY T0."OWORDocNum",T0."OWORItemCode",T0."OWORItemName"
	 HAVING SUM("Quantity") > 0
	 
	 --3014生产成本科目检查
	 UNION ALL
	 SELECT '3014'AS "Code",
             T0."ObjType",
             T0."DocNum" AS "DocEntry",
             T0."ItemCode" AS "ItemCode",
             T0."ItemName" AS "ItemName",
	         N'数据错误：物料行的科目错误；方法：成本结转后再总账调整差异'  AS "ErrorMSG"
	 FROM :Temp03 T0 
	 WHERE T0."AcctCode" NOT IN ('500101','500103')
	 
	 --3015分支检查
	 UNION ALL
	 SELECT '3015'AS "Code",
             T0."ObjType",
             T0."DocNum" AS "DocEntry",
             T0."ItemCode" AS "ItemCode",
             T0."ItemName" AS "ItemName",
	        N'数据错误：单据所属分支与生产订单分支不一致错误；方法：反向调回，再重新调整'  AS "ErrorMSG"
	 FROM :Temp03 T0 
	 WHERE T0."BaseType" = '-1' AND T0."BPLId" <> T0."OWORBPLId" 
	 
	 --3016车间为空检查
	 UNION ALL
	 SELECT '3016'AS "Code",
            N'生产订单'"ObjType",
             T0."OWORDocNum" AS "DocEntry",
             T2."OcrCode2" AS "ItemCode",
            N'' AS "ItemName",
	        N'数据错误：单据的 车间 选择错误；方法：请选择归属本分支的 车间 代码'  AS "ErrorMSG"
	 FROM :Temp03 T0 
	 INNER JOIN OWOR T2 ON T0."OWORDocNum" = T2."DocNum"
	 INNER JOIN OWHS T3 ON T2."Warehouse" = T3."WhsCode"
	 LEFT JOIN OPRC T1 ON T2."OcrCode2" = T1."PrcCode" AND T3."BPLid" = T1."U_BPLId"
	 WHERE T0."OWORStatus" <> 'C' AND T3."BPLid" <> '1' AND T1."PrcCode" IS NULL
	 
	 
	 UNION ALL
	 SELECT distinct 
		   '3021'AS "Code"
		   ,N'库存重估'
		   ,T0."DocNum"
		   ,T1."ItemCode"
		   ,T2."ItemName"
		   ,N'错误提示：借贷/重估的单据行 总账增加科目与总账减少科目 不允许为库存科目；方法：成本核算后手工结转库存差异' "ModifyMtd"
	 FROM OMRV T0 
	    JOIN MRV1 T1 ON T0."DocEntry"=T1."DocEntry"
	    JOIN OITM T2 ON T1."ItemCode"=T2."ItemCode"
	    JOIN OWHS T4 ON T1."WhsCode" = T4."WhsCode" AND T4."BPLid" = :BPLID
	    JOIN :StockDifActTmp T3 ON T2."ItmsGrpCod"=T3."ItmsGrpCod"
     WHERE (T1."RIncmAcct"=T3."BalInvntAc" OR T1."RDcrmAcct"=T3."BalInvntAc") AND T0."RevalType"='M'	
    
     --D-01、库存重估中的价格重估，出现科目代码不一致
	 UNION ALL
	 SELECT distinct 
		   '3022'AS "Code"
		   ,N'库存重估'
		   ,T0."DocNum"
		   ,T1."ItemCode"
		   ,T2."ItemName"
		   ,N'错误提示：价格重估的单据行 总账增加科目与总账减少科目 必须为库存科目;方法：成本核算后手工结转库存差异' "ModifyMtd"
	 FROM OMRV T0 
	    JOIN MRV1 T1 ON T0."DocEntry"=T1."DocEntry"
	    JOIN OITM T2 ON T1."ItemCode"=T2."ItemCode"
	    JOIN OWHS T4 ON T1."WhsCode" = T4."WhsCode" AND T4."BPLid" = :BPLID
	    JOIN :StockDifActTmp T3 ON T2."ItmsGrpCod"=T3."ItmsGrpCod"
     WHERE (T1."RIncmAcct"<>T3."BalInvntAc" OR T1."RDcrmAcct"<>T3."BalInvntAc") AND T0."RevalType"='P'
	 
	 	 
	 --其他出入库数据
	 UNION ALL
	 SELECT distinct 
		   '3030'AS "Code"
		   ,T0."ObjType"
		   ,T0."DocNum"
		   ,T0."ItemCode"
		   ,T0."ItemName"
		   ,N'错误提示：401-出入库单据只允许1对1进行代码转换' "ModifyMtd"
	 FROM :Temp04 T0
     WHERE IFNULL(T0."U_TrsName",'') = '401'
     GROUP BY T0."ObjType",T0."DocNum",T0."ItemCode",T0."ItemName"
     HAVING COUNT(T0."LineNum") > 1
	 
	 UNION ALL
	 SELECT distinct 
		   '3031'AS "Code"
		   ,T0."ObjType"
		   ,T0."DocNum"
		   ,T0."ItemCode"
		   ,T0."ItemName"
		   ,N'错误提示：单据没有维护源-发货单' "ModifyMtd"
	 FROM :Temp04 T0
     WHERE T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName",'') IN ('601','602') 
       AND T0."ObjType" <> N'库存-发货' AND IFNULL(T0."U_SrcNum",0) = 0
     
     UNION ALL
	 SELECT distinct 
		   '3032'AS "Code"
		   ,T0."ObjType"
		   ,T0."DocNum"
		   ,T0."ItemCode"
		   ,T0."ItemName"
		   ,N'错误提示：单据物料未维护在 <其他出库列表>的主物料中' "ModifyMtd"
	 FROM :Temp04 T0
	 LEFT JOIN "@U_OTFI" T1 ON T0."ItemCode" = T1."Code"
     WHERE T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName",'') IN ('601') 
       AND T1."Code" IS NULL
     
     UNION ALL
	 SELECT distinct 
		   '3033'AS "Code"
		   ,T0."ObjType"
		   ,T0."DocNum"
		   ,T0."ItemCode"
		   ,T0."ItemName"
		   ,N'错误提示：单据物料未维护在 <其他出库列表>的辅物料中' "ModifyMtd"
	 FROM :Temp04 T0
	 LEFT JOIN "@U_OTFI" T1 ON T0."ItemCode" = T1."U_TFItemCd"
     WHERE T0."BaseType" = '-1' AND IFNULL(T0."U_TrsName",'') IN ('602') 
       AND T1."U_TFItemCd" IS NULL
     
     --3034 科目检查
     UNION ALL
     SELECT  DISTINCT
     		 '3034'AS "Code",
             T0."ObjType",
             T0."DocNum" AS "DocEntry",
             T0."ItemCode" AS "ItemCode",
             T0."ItemName" AS "ItemName",
	         N'数据错误：物料行的科目错误；方法：成本结转后再总账调整差异'  AS "ErrorMSG"
     FROM :Temp04 T0
     WHERE T0."BaseType" = '-1'
       AND ( ( T0."AcctCode" IN ('500101','500103') AND IFNULL(T0."U_TrsName",'') NOT IN ('305','306','307','401','601','602' ) ) OR
     	     ( T0."AcctCode" NOT IN ('500101','500103') AND IFNULL(T0."U_TrsName",'') IN ('305','306','307','401','601','602' ) ) )
     
     UNION ALL
     SELECT DISTINCT
     		N'3035',
	        N'产品费用分摊系数',
	        0,
	         T0."OWORItemCode" AS "ItemCode",
             T0."OWORItemName" AS "ItemName",
	        N'数据错误：请打开菜单 管理>>设置>>财务>>制费分摊>>产品费用分摊系数 表中先维护该物料，否则无法分摊到当期人工制费！'
     FROM :Temp03 T0
     LEFT JOIN "@U_CCOSDS" T1 ON T0."BPLId" = T1."U_BPLId"
     LEFT JOIN "@U_CCSDS1" T2 ON T1."DocEntry" = T2."DocEntry" AND T0."OWORItemCode" = T2."U_ItemCode"
     WHERE T2."U_ItemCode" IS NULL 
     
     UNION ALL
     SELECT DISTINCT
     		N'3036',
	        N'产品费用分摊系数',
	        0,
	         T0."U_DsListNum" AS "ItemCode",
             T2."Name" AS "ItemName",
	        N'数据错误：请打开菜单  管理>>设置>>财务>>制费分摊>>产品费用分摊系数  表中该分摊系数出现重复维护！'
     FROM "@U_CCOSDS" T0
     LEFT JOIN "@U_CCOSDS" T1 ON T0."U_BPLId" = T1."U_BPLId" AND T0."DocEntry" <> T1."DocEntry"
     LEFT JOIN "@U_CCDSLT" T2 ON T1."U_DsListNum" = T2."Code"
     WHERE T0."U_BPLId" =:BPLId
       AND T2."Code" IS NOT NULL 
       AND T0."U_DsListNum" = T1."U_DsListNum"
     
     --其他出入库表检查
 	 UNION ALL
 	 SELECT DISTINCT
 	 		N'3037',
	        N'其他出入库表',
	        0,
	         T0."Code" AS "ItemCode",
             T0."Name" AS "ItemName",
	        N'数据错误：《其他出入库表》 中同一物料代码不允许同时维护在 主物料 与  辅物料 '
 	 FROM "@U_OTFI" T0
 	 LEFT JOIN "@U_OTFI" T1 ON T0."Code" = T1."U_TFItemCd"
 	 WHERE :BPLId = 1 AND T1."U_TFItemCd" IS NOT NULL
 
 
 
     
     --销售数据检查
	 UNION ALL
     SELECT  DISTINCT
     		  '4010'AS "Code",
             N'销售出库',
             T0."DocNum" AS "DocEntry",
             T0."CardCode" AS "ItemCode",
             T3."CardName" AS "ItemName",
	         N'数据错误：销售出库单未开票；方法：请检查并将销售出库单生成应收发票以完成收入确认'  AS "ErrorMSG" 
     FROM ODLN T0
     JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
     JOIN OFPR T2 ON T0."DocDate" BETWEEN T2."F_RefDate" AND T2."T_RefDate"
     JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
     WHERE T0."BPLId" = :BPLId AND T2."Code" = :FcCode AND T1."LineStatus" = 'O'
       AND T1."BaseType" <> 15 AND T0."CANCELED" <> 'Y'
     
     UNION ALL
     SELECT  DISTINCT
     		  '4011'AS "Code",
             N'销售退货',
             T0."DocNum" AS "DocEntry",
             T0."CardCode" AS "ItemCode",
             T3."CardName" AS "ItemName",
	         N'数据错误：销售退货单未开票；方法：请检查并将销售出库单生成应收贷项凭证以完成收入确认扣减'  AS "ErrorMSG" 
     FROM ORDN T0
     JOIN RDN1 T1 ON T0."DocEntry" = T1."DocEntry"
     JOIN OFPR T2 ON T0."DocDate" BETWEEN T2."F_RefDate" AND T2."T_RefDate"
     JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
     WHERE T0."BPLId" = :BPLId AND T2."Code" = :FcCode AND T1."LineStatus" = 'O'
       AND T1."BaseType" <> 16 AND T0."CANCELED" <> 'Y'
    
     
     
     
     
     
     --采购检查
	 UNION ALL
	 SELECT  DISTINCT
	 		  '5010'AS "Code",
             N'日记账分录',
             T0."TransId" AS "DocEntry",
             T1."Account" AS "ItemCode",
             T4."AcctName" AS "ItemName",
	         N'数据错误：暂估行未指定业务伙伴；方法：请将分录源单据的供应商代码更新至暂估科目行的业务伙伴字段'  AS "ErrorMSG"
	 FROM OJDT T0
	 JOIN JDT1 T1 ON T0."TransId" = T1."TransId"
	 JOIN OCRD T2 ON CASE WHEN T1."Account" = '220201' THEN T1."ShortName" 
	 					  WHEN T1."Account" IN('220202','220203') THEN T1."U_CardCode" END = T2."CardCode"
     JOIN OFPR T3 ON T0."RefDate" BETWEEN T3."F_RefDate" AND T3."T_RefDate"
     JOIN OACT T4 ON T1."Account" = T4."AcctCode"
     WHERE T1."BPLId" = :BPLId AND T3."Code" = :FcCode
       AND T1."Account" LIKE '2202%'
       AND T2."CardCode" IS NULL
     
     
     
     
     --库存数据检查
	 UNION ALL
	 SELECT  DISTINCT
	 		  '6010'AS "Code",
             N'库存转出请求',
             T0."DocNum" AS "DocEntry",
             T1."ItemCode" AS "ItemCode",
             T4."ItemName" AS "ItemName",
	         N'数据错误：请结算关闭 当期及之前会计期间事务名称为105/106/107的未清库存转储请求单'  AS "ErrorMSG"
	 FROM OWTQ T0 
	 INNER JOIN WTQ1 T1 ON T0."DocEntry" = T1."DocEntry" 
	 INNER JOIN OWHS T2 ON T1."FromWhsCod" = T2."WhsCode" 
	 INNER JOIN OWHS T3 ON T1."WhsCode" = T3."WhsCode" 
	 INNER JOIN OITM T4 ON T1."ItemCode" = T4."ItemCode" 
	 INNER JOIN OITB T5 ON T4."ItmsGrpCod" = T5."ItmsGrpCod" 
	 LEFT JOIN (SELECT U0."U_ItemCode",U0."U_Workshop",U0."Code" FROM "@U_PIT1" U0 WHERE 1 =1 ) T11 ON T1."ItemCode" = T11."U_ItemCode" AND T11."Code" = T0."BPLId" 
	 WHERE T0."U_TrsName" IN ('105','106','107') AND T1."LineStatus" = 'O' AND T0."DocDate" <= :EDATE AND T0."BPLId" = :BPLId
     ; 
     --SELECT * FROM :TEMP02 ;
   
   
   
     --03 插入到相应的表中
     ---0301 插入到主表
     DELETE FROM "U_CCHKDB" T0 WHERE T0."BPLId" =:BPLId AND T0."FcCode"=:FcCode AND
        EXISTS(SELECT 1 FROM :Temp01 U0 WHERE U0."Code"=T0."Code");
     DELETE FROM "U_CCHKDB1" T0 WHERE T0."BPLId" =:BPLId AND T0."FcCode"=:FcCode AND 
        EXISTS(SELECT 1 FROM :Temp01 U0 WHERE U0."Code"=T0."FatherCode");
   
     INSERT INTO "U_CCHKDB"("BPLId","FcCode","Code","ItemCode","ItemName","Confirm","CreatedDate","CreatedTime")
     SELECT :BPLId,:FcCode,T0."Code",T0."ItemCode",T0."ItemName", 
             CASE WHEN T1."Code" IS NULL THEN 'Y' ELSE 'N' END,CURRENT_DATE,CURRENT_TIME       
     FROM :Temp01 T0
     LEFT JOIN 
      (SELECT DISTINCT U0."Code" 
         FROM :Temp02 U0 ) T1 ON T0."ItemCode"=T1."Code"
     WHERE  1=1 ;
  
     --03.02 插入到子表
     INSERT INTO "U_CCHKDB1"("BPLId","FcCode","FatherCode","Code","ObjType","DocEntry",
  						     "ItemCode","ItemName","ErrorMSG","CreatedDate","CreatedTime")
     SELECT :BPLId,:FcCode,T1."Code",T0."Code",T0."ObjType",T0."DocEntry",
  		     T0."ItemCode",T0."ItemName",T0."ErrorMSG",CURRENT_DATE,CURRENT_TIME
     FROM :Temp02 T0
     LEFT JOIN :Temp01 T1 ON T0."Code" = T1."ItemCode"
     WHERE 1=1;
  
     SELECT T0."ItemCode",T0."ItemName",T0."Confirm"
     FROM "U_CCHKDB" T0
     WHERE T0."BPLId" =:BPLId aND T0."FcCode"=:FcCode AND EXISTS(SELECT 1 FROM :Temp01 U0 WHERE T0."Code"=U0."Code"); 
     
     
END;
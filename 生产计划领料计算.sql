CREATE PROCEDURE U_PD_GetWorkMtrlData	
(DocEntry INt)
LANGUAGE SQLSCRIPT
AS
BEGIN
  
  WKPL_TEMP =
  	--当前生产计划
	SELECT T0."U_Department" ,T0."U_WorkShop" ,T0."U_ClassGroup" ,T11."ItemCode" 
	       ,T12."ItemName" ,T12."ItmsGrpCod" ,T12."U_Class2"	
		   ,CASE WHEN ( T12."U_IsPackage" = 'Y' AND T12."ItmsGrpCod" IN(100,101) ) 			--原料，添加剂为标包的物料,剔出车间仓余量后按整包计算需求量							
		   		    THEN CEILING( (SUM(T11."PlannedQty")-T13."OnHand") / T12."PurFactor1" ) * T12."PurFactor1"  
		   		 WHEN ( T12."U_IsPackage" = 'Y' AND T12."ItmsGrpCod" IN(103,104,105,106) ) 	--成品中为标包的物料,剔出车间仓余量后按整包计算需求量					
		   		    THEN CEILING( (SUM(T11."PlannedQty")-T13."OnHand") / T12."SalFactor1" ) * T12."SalFactor1"  
		   		 WHEN ( T12."ItmsGrpCod" = 102 )
		   		    THEN CEILING(  SUM(T11."PlannedQty")  ) - FLOOR(T13."OnHand")
		   		 ELSE ( SUM( T11."PlannedQty" ) - T13."OnHand" ) END "PlannedQty"	 -- 标准用量取整
	FROM "@U_WKPL1" T0
	  INNER JOIN OWOR T1 ON T0."U_WorkNum" = T1."DocNum"
	  INNER JOIN OITM T10 ON T1."ItemCode" = T10."ItemCode"
	  INNER JOIN WOR1 T11 ON T1."DocEntry" = T11."DocEntry"
	  INNER JOIN OITM T12 ON T11."ItemCode" = T12."ItemCode"
	  INNER JOIN OITW T13 ON T12."ItemCode" = T13."ItemCode" 
	  INNER JOIN OWHS T14 ON T11."wareHouse" = T14."WhsCode"
	  LEFT JOIN "@U_COWSTY" T15 ON T14."U_WhsType" = T15."Code"
	  LEFT JOIN OPRC T2 ON T0."U_WorkShop" = t2."PrcCode"
	  LEFT JOIN OPRC T3 ON T0."U_Department" = t3."PrcCode"
	WHERE T0."DocEntry" = :DocEntry 
	  AND IFNULL(T11."U_TrsferType",'') = '2'  --只针对物料自动转储物料进行领料汇总
	  AND IFNULL(T15."Code",'') = '41' 		   --只针对从车间仓耗用出库的物料进行领料汇总
	  AND T13."WhsCode" = (SELECT "U_RltWhsCd" --获取生产车间对应的车间仓库，其设置在成本中心上
		  					   FROM OPRC 
		  					   WHERE "PrcCode" = (SELECT TOP 1 "U_WorkShop" 
		  					   					  FROM "@U_WKPL1" 
		  					   					  WHERE "DocEntry" = :DocEntry  )  )
	GROUP BY T0."U_Department",T0."U_WorkShop" ,T0."U_ClassGroup" ,T11."ItemCode",T12."ItemName",T12."ItmsGrpCod"
			,T12."U_Class2" ,T12."U_IsPackage" ,T12."PurFactor1" ,T13."OnHand" ,T12."SalFactor1" ;
  
  OWOR_TEMP = 	
	SELECT T0."U_Department",T0."U_WorkShop" ,T0."U_ClassGroup"
	      ,T0."ItemCode" ,T0."ItemName",T0."ItmsGrpCod" ,T0."U_Class2"
	      ,SUM(t0."PlannedQty") "PlannedQty"
	FROM(
		SELECT * FROM :WKPL_TEMP
		
	    --未结算订单剩余量
		UNION ALL 
		SELECT T1."OcrCode",T1."OcrCode2",T1."U_ProClass" ,T11."ItemCode" 
		   	   ,T12."ItemName" ,T12."ItmsGrpCod" ,T12."U_Class2"	
			   ,CASE WHEN ( T12."U_IsPackage" = 'Y' AND T12."ItmsGrpCod" IN(100,101) ) 			--原料，添加剂为标包的物料,剔出车间仓余量后按整包计算需求量							
			   		    THEN CEILING( (SUM(T11."PlannedQty"-T11."IssuedQty")) / T12."PurFactor1" ) * T12."PurFactor1"  
			   		 WHEN ( T12."U_IsPackage" = 'Y' AND T12."ItmsGrpCod" IN(103,104,105,106) ) 	--成品中为标包的物料,剔出车间仓余量后按整包计算需求量					
			   		    THEN CEILING( (SUM(T11."PlannedQty"-T11."IssuedQty")) / T12."SalFactor1" ) * T12."SalFactor1"  
			   		 WHEN ( T12."ItmsGrpCod" = 102 )
			   		    THEN CEILING(  SUM(T11."PlannedQty"-T11."IssuedQty")  )
			   		 ELSE ( SUM( T11."PlannedQty"-T11."IssuedQty" ) ) END "PlannedQty"	 -- 标准用量取整
		FROM OWOR T1 
		  INNER JOIN OITM T10 ON T1."ItemCode" = T10."ItemCode"
		  INNER JOIN WOR1 T11 ON T1."DocEntry" = T11."DocEntry"
		  INNER JOIN OITM T12 ON T11."ItemCode" = T12."ItemCode"
		  INNER JOIN OWHS T14 ON T11."wareHouse" = T14."WhsCode"
		  LEFT JOIN "@U_COWSTY" T15 ON T14."U_WhsType" = T15."Code" 
		  LEFT JOIN OPRC T2 ON T1."OcrCode" = t2."PrcCode"
		  LEFT JOIN OPRC T3 ON T1."OcrCode2" = t3."PrcCode"
		WHERE T1."Status" = 'R'  				   --已审批生产订单的未清计划量
          AND T1."ItemCode" NOT IN('10080001','10080002')  --预入库产品剔除
		  AND T1."U_TskDoc" <> :DocEntry		   --剔除当前生产计划单
		  AND IFNULL(T11."U_TrsferType",'') = '2'  --只针对物料自动转储物料进行领料汇总
		  AND IFNULL(T15."Code",'') = '41' 		   --只针对从车间仓耗用出库的物料进行领料汇总
		  AND IFNULL(T1."OcrCode2",'') in (SELECT DISTINCT "U_WorkShop" FROM "@U_WKPL1" WHERE "DocEntry" = :DocEntry)  --当前车间
		  AND T1."PostDate" <= (SELECT DISTINCT "U_WCreDate" FROM "@U_WKPL1" WHERE "DocEntry" = :DocEntry)			   --小于当前时期
		  AND T1."PostDate" >= (SELECT DISTINCT LEFT(TO_NVARCHAR(TO_DATE("U_WCreDate")),7)||N'-01' FROM "@U_WKPL1" WHERE "DocEntry" = :DocEntry)	
		GROUP BY T1."OcrCode",T1."OcrCode2",T1."U_ProClass" ,T11."ItemCode",T12."ItemName",T12."ItmsGrpCod"
				,T12."U_Class2" ,T12."U_IsPackage" ,T12."PurFactor1" ,T12."SalFactor1"    
		) T0
	WHERE 1 = 1
	GROUP BY T0."U_Department",T0."U_WorkShop" ,T0."U_ClassGroup"
	        ,T0."ItemCode" ,T0."ItemName",T0."ItmsGrpCod" ,T0."U_Class2"
	;
  --select * from wor1
  --SELECT * FROM "@U_WKPL3"
  --返回结果集
  SELECT T0."U_Department" ,T0."U_WorkShop" ,T0."U_ClassGroup" ,T0."ItemCode" 
        ,T1."ItemName" ,T0."ItmsGrpCod" ,T0."U_Class2"	
        ,T0."PlannedQty" + IFNULL(T2."U_LossQty",0.00) "PlannedQty" --加上固定量（独立出来，易于调整）
  		,CASE WHEN T3."ItemCode" IS NOT NULL AND IFNULL(T0."PlannedQty",0.00) > 0 
  											 AND IFNULL(T3."PlannedQty",0.00) > 0 
  											 AND IFNULL(T0."PlannedQty",0.00) > IFNULL(T3."PlannedQty",0.00)  
  				   THEN  N'含未结算生产订单的未发货量：'||TO_NVARCHAR(IFNULL(T0."PlannedQty",0.00) - IFNULL(T3."PlannedQty",0.00)) 
  			  ELSE NULL END "Comments"
  FROM :OWOR_TEMP T0
   JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
   LEFT JOIN :WKPL_TEMP T3 ON T0."ItemCode" = T3."ItemCode"
   LEFT JOIN 
    ( SELECT T11."ItemCode",MAX(IFNULL(U3."U_LossQty",0.00)) "U_LossQty"  --存在同一原料在不同产品的配方U_LossQty不一致的可能，此时MAX取最大值
   	  FROM "@U_WKPL1" U0
   		JOIN "@U_OWKPL" U1 ON U0."DocEntry" = U1."DocEntry"
   		JOIN OWOR T1 ON U0."U_WorkNum" = T1."DocNum"
	 	JOIN WOR1 T11 ON T1."DocEntry" = T11."DocEntry"					   --以生产订单组件为准
   		JOIN "@U_COITT" U2 ON U0."U_ItemCode" = U2."U_Code" AND U0."U_Version1" = U2."U_Version" AND U1."U_BPLID" = U2."U_BPLID"
   		LEFT JOIN "@U_CITT1" U3 ON U2."DocEntry" = U3."DocEntry" AND T11."ItemCode" = U3."U_Code"
   	   WHERE IFNULL(U3."U_LossQty",0.00) <> 0 AND U0."DocEntry" = :DocEntry
   	   GROUP BY T11."ItemCode"
     ) T2 ON T0."ItemCode" = T2."ItemCode" 
  WHERE T0."PlannedQty" + IFNULL(T2."U_LossQty",0.00) > 0.00
  ORDER BY T0."U_Department",T0."U_WorkShop",T0."U_ClassGroup",T0."ItmsGrpCod";
  

END
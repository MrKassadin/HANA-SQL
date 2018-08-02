set schema XN_FM_1016TEST;
drop procedure U_PC_IndentCheck;
create procedure U_PC_IndentCheck(
               in BPLname varchar (60),   
               in F_RefDate date,
               in T_RefDate date,
               in CodeId  varchar (60),
               in Numbering varchar(10))
as 
begin
DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
DECLARE BPLID nvarchar(10);
select "BPLId" into BPLID from OBPL where "BPLName" = :BPLname;
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0  ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"=:BPLname;

CREATE GLOBAL TEMPORARY TABLE U_table(
    "编号" int,
    "订单号" int
  );

IF :CNT = 0 THEN
  SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;	
ELSE
  --产品入库数量
  TMP_PoInQty = 
  	SELECT U0."DocEntry",U0."ItemCode",
	       SUM(U0."StdInQty") AS "StdInQty",
	       SUM(U0."AdjQty") AS "AdjQty",
	       SUM(U0."Quantity") AS "Quantity",
	       SUM(U0."BoxQty") AS "BoxQty"
	
	FROM
	   ( SELECT T3."DocEntry",T3."ItemCode", --生产工单号
				CASE WHEN T1."BaseType" = '202' THEN T9."InQty" - T9."OutQty" ELSE 0 END as "StdInQty",
				CASE WHEN T1."BaseType" = '-1' THEN T9."InQty" - T9."OutQty" ELSE 0 END as "AdjQty" ,
				T9."InQty" - T9."OutQty" as "Quantity",  
			    IFNULL(T9."InQty",0)*1.00/NULLIF(T2."SalFactor1",0) AS "BoxQty"     
		 FROM OIGN T0 
			  JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry"   --工单，产品收货
			  JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode" 
			  JOIN OITB T4 ON T4."ItmsGrpCod" = T2."ItmsGrpCod" AND T4."U_ItemGrpType" IN ('A','B')
			  JOIN OWOR T3 ON (CASE WHEN T1."BaseType" = '202' THEN T1."BaseRef" ELSE T0."U_SrcNum" END) = T3."DocNum"
			  JOIN OFPR T7 ON T0."DocDate" BETWEEN T7."F_RefDate" AND T7."T_RefDate"
     		  JOIN OIVL T9 ON T9."TransType" = '59' AND T9."CreatedBy" = T1."DocEntry" AND T9."DocLineNum" = T1."LineNum" AND T1."ItemCode" = T9."ItemCode"
		 WHERE T0."DocDate" BETWEEN :F_RefDate AND :T_RefDate AND T0."BPLId" = BPLID
		 	AND T3."Warehouse" in (SELECT DISTINCT "WhsCode" FROM OWHS WHERE "BPLid" = BPLID)
		 	AND( 	(T1."BaseType" = '202' AND T1."BaseLine" IS NULL ) 
		 		OR  (T1."BaseType" = '-1' AND T0."U_TrsName" in ('302')) 
		 	   )  

		 UNION ALL
         SELECT T3."DocEntry",T3."ItemCode", --生产工单号
				CASE WHEN T1."BaseType" = '202' THEN T9."InQty" - T9."OutQty" ELSE 0 END as "StdInQty",
				CASE WHEN T1."BaseType" = '-1' THEN T9."InQty" - T9."OutQty" ELSE 0 END as "AdjQty" ,
				T9."InQty" - T9."OutQty" as "Quantity",  
			    IFNULL(T9."InQty",0)*1.00/NULLIF(T2."SalFactor1",0) AS "BoxQty"
		 FROM OIGE T0 
			  JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry"   --工单，产品收货
			  JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode" 
			  JOIN OITB T4 ON T4."ItmsGrpCod" = T2."ItmsGrpCod" AND T4."U_ItemGrpType" IN ('A','B')
			  JOIN OWOR T3 ON (CASE WHEN T1."BaseType" = '202' THEN T1."BaseRef" ELSE T0."U_SrcNum" END) = T3."DocNum"
			  JOIN OFPR T7 ON T0."DocDate" BETWEEN T7."F_RefDate" AND T7."T_RefDate"
     		  JOIN OIVL T9 ON T9."TransType" = '60' AND T9."CreatedBy" = T1."DocEntry" AND T9."DocLineNum" = T1."LineNum" AND T1."ItemCode" = T9."ItemCode"
		 WHERE T0."DocDate" BETWEEN :F_RefDate AND :T_RefDate AND T0."BPLId" = BPLID
		 	AND T3."Warehouse" in (SELECT DISTINCT "WhsCode" FROM OWHS WHERE "BPLid" = BPLID)
		 	AND( 	(T1."BaseType" = '202' AND T1."BaseLine" IS NULL ) 
		 		OR  (T1."BaseType" = '-1' AND T0."U_TrsName" in ('302')) 
		 	   )  
	) U0 
    GROUP BY U0."DocEntry",U0."ItemCode"
	;
	
  --投入
  TMP_PoOtQty = 
    SELECT T0."DocEntry",
    	   ROW_NUMBER() OVER(PARTITION BY T0."DocEntry" ORDER BY T0."ItemCode") as "LineID",
		   T1."ItmsGrpCod",
		   T0."ItemCode",
		   T1."ItemName",
		   T0."WhsName",
		   SUM("StdOutQty") AS "StdOutQty",
		   SUM("AdjQty") as "AdjQty",
		   SUM("Quantity") "Quantity"

	 FROM
		(	
		SELECT T2."DocEntry",  --生产工单号
			   T1."ItemCode",
			   T8."WhsName",
			   CASE WHEN T1."BaseType" = '202' THEN T6."OutQty" - T6."InQty" ELSE 0 END "StdOutQty",
			   CASE WHEN T1."BaseType" = '-1' THEN T6."OutQty" - T6."InQty" ELSE 0 END "AdjQty",
			   (T6."OutQty" - T6."InQty") "Quantity"
		FROM OIGE T0  
		   JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry" 
		   JOIN OITM T10 ON T1."ItemCode" = T10."ItemCode" 
		   LEFT JOIN OWOR T2 ON (CASE WHEN T1."BaseType" = '202' THEN T1."BaseRef" ELSE T0."U_SrcNum" END) = T2."DocNum" 
		   LEFT JOIN OITM T3 ON T2."ItemCode" = T3."ItemCode" 
		   LEFT JOIN OITB T11 ON T3."ItmsGrpCod" = T11."ItmsGrpCod" AND T11."U_ItemGrpType" IN('A','B') AND T11."ItmsGrpCod" IS NOT NULL --生产工单的产品级别
		   JOIN OIVL T6 ON T6."TransType"='60' AND T6."CreatedBy"=T1."DocEntry" AND T6."DocLineNum"=T1."LineNum"
		   JOIN OWHS T8 ON T6."LocCode" = T8."WhsCode"
		WHERE T0."DocDate" BETWEEN :F_RefDate AND :T_RefDate AND 
			   (
				 (T1."BaseType"='202' AND T1."BaseLine" IS NOT NULL)  
				 OR 
				 (T1."BaseType"='-1' AND T0."U_TrsName" IN ('301','303','304','305') )
			   )
		  AND T0."BPLId" =BPLID
		  
		UNION ALL	
		--退库作为领料的负数
	    SELECT T2."DocEntry",  --生产工单号
			   T1."ItemCode",
			   T8."WhsName",
			   CASE WHEN T1."BaseType" = '202' THEN T6."OutQty" - T6."InQty" ELSE 0 END "StdOutQty",
			   CASE WHEN T1."BaseType" = '-1' THEN T6."OutQty" - T6."InQty" ELSE 0 END "AdjQty",
			   (T6."OutQty" - T6."InQty") "Quantity"
		FROM OIGN T0  
		   JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry" 
		   JOIN OITM T10 ON T1."ItemCode" = T10."ItemCode" 
		   LEFT JOIN OWOR T2 ON (CASE WHEN T1."BaseType" = '202' THEN T1."BaseRef" ELSE T0."U_SrcNum" END) = T2."DocNum" 
		   LEFT JOIN OITM T3 ON T2."ItemCode" = T3."ItemCode" 
		   LEFT JOIN OITB T11 ON T3."ItmsGrpCod" = T11."ItmsGrpCod" AND T11."U_ItemGrpType" IN('A','B') AND T11."ItmsGrpCod" IS NOT NULL --生产工单的产品级别
		   JOIN OIVL T6 ON T6."TransType"='59' AND T6."CreatedBy"=T1."DocEntry" AND T6."DocLineNum"=T1."LineNum" 
		   JOIN OWHS T8 ON T6."LocCode" = T8."WhsCode"
		WHERE T0."DocDate" BETWEEN :F_RefDate AND :T_RefDate AND 
			   (
				 (T1."BaseType"='202' AND T1."BaseLine" IS NOT NULL)  
				 OR 
				 (T1."BaseType"='-1' AND T0."U_TrsName" IN ('301','303','304','305') )
			   )
		  AND T0."BPLId" =BPLID
			 	
	    --倒冲
	    UNION ALL 
	    SELECT T3."DocEntry",  --生产工单号
			   T1."ItemCode",
			   T8."WhsName",
			   T0."OutQty" AS "StdOutQty",
			   0 "AdjQty" ,
			   T0."OutQty"
		FROM OIVL T0
		   INNER JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode" 
		   INNER JOIN OILM T2 ON T0."MessageID" = T2."MessageID" 
		   LEFT JOIN OWOR T3 ON T2."AppObjAbs" = T3."DocEntry" AND T2."ApplObj" = '202' 
		   LEFT JOIN OITM T4 ON T3."ItemCode" = T4."ItemCode" 
		   LEFT JOIN OITB T11 ON T4."ItmsGrpCod" = T11."ItmsGrpCod" AND  T11."U_ItemGrpType" IN('A','B') AND T11."ItmsGrpCod" IS NOT NULL --生产工单的产品级别
		   JOIN OWHS T8 ON T0."LocCode" = T8."WhsCode" AND T8."BPLid" = BPLID
		WHERE T0."DocDate" BETWEEN :F_RefDate AND :T_RefDate 
		  AND T0."TransType" ='59' AND T2."ApplObj" = '202' AND T0."OutQty"<>0 
		  
		--系统分摊
		UNION ALL
		SELECT T0."DocEntry",T1."ItemCode",N'月末分摊',0.00,0.00,
  		   SUM(CASE WHEN T1."IssueType" IN ('按发货分摊','全部分摊') THEN IFNULL(T1."Quantity",0.00) ELSE 0.00 END) "CheckQty"
	  	FROM OWOR T0
	  	 LEFT JOIN U_CWOR1 T1 ON T0."DocEntry" = T1."DocEntry" 
	  	WHERE T0."PostDate" BETWEEN :F_RefDate AND :T_RefDate 
	 	  AND T0."Warehouse" IN(SELECT "WhsCode" FROM OWHS WHERE "BPLid" = BPLID)
	  	  AND T1."IssueType" IN ('按发货分摊','全部分摊') AND T1."DocType" NOT IN ('PlantTRS','PRDItemTRS')
	  	GROUP BY T0."DocEntry",T0."DocNum",T1."ItemCode"  	
    ) T0
	JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
	WHERE 1=1 
	GROUP BY  T0."DocEntry",T0."ItemCode",T0."WhsName",T1."ItmsGrpCod",T1."ItemName";
  --SELECT * FROM :TMP_PoOtQty ;
  
  --配方标准用量
  TMP_PoBmQty =
  	SELECT T1."DocEntry",T1."DocNum",T2."U_Version",T3."U_Code" "Child",T3."U_Quantity" "BOMStdQty",T4."Descr"
  	FROM OWOR T1 
  	 INNER JOIN "@U_COITT" T2 ON T1."ItemCode" = T2."U_Code" AND T1."U_Version" = T2."U_Version" AND T2."U_BPLID" = BPLID
  	 INNER JOIN "@U_CITT1" T3 ON T2."DocEntry" = T3."DocEntry"
  	 LEFT JOIN (select t0."FldValue",t0."Descr" 
  	 			from UFD1 t0 where t0."TableID" = '@U_CITT1' and t0."FieldID" = '10' ) T4 on T4."FldValue" = T3."U_InputType"
    WHERE 1 =1  ;
  --SELECT * FROM :TMP_PoBmQty ;
  
  --订单计划用量
  TMP_WOR1Qty = 
  	SELECT "DocEntry","ItemCode",SUM("PlannedQty") "PlannedQty"
  	FROM WOR1 
    GROUP BY "DocEntry","ItemCode" ;
    
  --Union工单组件
  TMP_Child = 	
  	SELECT "DocEntry","Child" FROM :TMP_PoBmQty
  	UNION 
  	SELECT "DocEntry","ItemCode" FROM :TMP_PoOtQty
  	UNION
  	SELECT "DocEntry","ItemCode" FROM :TMP_WOR1Qty   ;
  
  TMP_Report = 
    SELECT T0."PostDate",T0."DocNum",T5."Descr",
    	   CASE WHEN T0."Status" = 'P' then N'已下达' WHEN T0."Status" = 'C' THEN N'已取消'
   		 	    WHEN T0."Status" = 'L' then N'已结算' WHEN T0."Status" = 'R' THEN N'已审批' END "Status",
    	   T3."PrcName" "OcrCode",
    	   T4."PrcName" "OcrCode2",
    	   T2."WhsName" "ProWhsNm",
    	   IFNULL(T0."U_Version",'') "U_Version",
    	   T0."ItemCode" "ProItmCd",
    	   T1."ItemName" "ProItmNm",
    	   T0."PlannedQty" "ProPlanedQty",
    	   IFNULL(T10."Quantity",0.00) "PoInQty",
    	   IFNULL(R0."Child",'') "MtlItmCd",
    	   IFNULL(R1."ItemName",'') "MtlItmNm",
    	   IFNULL(T11."WhsName",'') "MtWhsNm",
    	   IFNULL(T11."Quantity",0.00) "FactOutQty",
    	   IFNULL(T12."PlannedQty",0.00) "PlanedOutQty",
    	   IFNULL(T13."BOMStdQty",0.00) "BOMStdQty"
    FROM OWOR T0
     INNER JOIN (SELECT "DocEntry","Child" FROM :TMP_Child) R0 ON R0."DocEntry" = T0."DocEntry" 
     INNER JOIN OITM R1 ON R1."ItemCode" = R0."Child"
     INNER JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
     INNER JOIN OWHS T2 ON T0."Warehouse" = T2."WhsCode"     
     LEFT JOIN :TMP_PoInQty T10 ON T10."DocEntry" = T0."DocEntry"  									  --产出量
     LEFT JOIN :TMP_PoOtQty T11 ON T11."DocEntry" = R0."DocEntry" AND T11."ItemCode" = R0."Child"	  --实际投料 
	 LEFT JOIN OITM T110 ON T110."ItemCode" = T11."ItemCode" 
	 LEFT JOIN :TMP_WOR1Qty T12 ON T12."DocEntry" = R0."DocEntry" AND T12."ItemCode" = R0."Child" 			  --计划用量
	 LEFT JOIN OITM T120 ON T120."ItemCode" = T12."ItemCode"
	 LEFT JOIN :TMP_PoBmQty T13 ON T13."DocEntry" = R0."DocEntry" AND T13."Child" = R0."Child"  	  --配方标量
	 LEFT JOIN OITM T130 ON T130."ItemCode" = T13."Child"    
	 LEFT JOIN (select t0."FldValue",t0."Descr" 
  	 			from UFD1 t0 where t0."TableID" = 'OWOR' and t0."FieldID" = '1' ) T5 on T5."FldValue" = T0."U_ProType"
     LEFT JOIN OPRC T3 ON T3."PrcCode" = T0."OcrCode"
     LEFT JOIN OPRC T4 ON T4."PrcCode" = T0."OcrCode2"
    WHERE T0."PostDate" BETWEEN :F_RefDate AND :T_RefDate 
	  AND T0."Warehouse" IN(SELECT "WhsCode" FROM OWHS WHERE "BPLid" = BPLID);
	 
  
  Finally_Rpt =
    SELECT 0 Id,
           "PostDate","DocNum","Descr","Status",
    	   "OcrCode","OcrCode2","ProWhsNm","U_Version",
    	   "ProItmCd","ProItmNm","ProPlanedQty","PoInQty", 
    	   N'SUMMARY' "MtlItmCd",N'汇总行' "MtlItmNm",NULL "MtWhsNm",
    	   SUM( CASE WHEN T1."ItmsGrpCod" IN('102','107') THEN 0 ELSE "FactOutQty" END )"FactOutQty",
    	   SUM( CASE WHEN T1."ItmsGrpCod" IN('102','107') THEN 0 ELSE "PlanedOutQty" END ) "PlanedOutQty",
    	   SUM( CASE WHEN T1."ItmsGrpCod" IN('102','107') THEN 0 ELSE "BOMStdQty" END ) "BOMStdQty"
    FROM :TMP_Report T0
     LEFT JOIN OITM T1 ON T0."MtlItmCd" = T1."ItemCode"
    WHERE 1 = 1
    GROUP BY "PostDate","DocNum","Descr","Status","OcrCode","OcrCode2","ProWhsNm","U_Version",
    	     "ProItmCd","ProItmNm","ProPlanedQty","PoInQty"
    
    UNION ALL
    SELECT ROW_NUMBER() OVER(PARTITION BY "DocNum" ORDER BY "DocNum") , *
    FROM :TMP_Report;

if :CodeId = '' THEN 
table_temporary =
  SELECT '' as "选择",
         rank() over(order by T0."PostDate",T0."DocNum",T0.Id) as "编号" ,  
         CASE WHEN T0.Id = 0 THEN CASE WHEN IFNULL(T3."U_Approved",'') = '1' THEN '已审核' ELSE NULL END ELSE NULL END "审核状态",
  		 CASE WHEN T0.Id = 0 THEN T0."ProWhsNm" ELSE NULL END "入库仓库",
  		 CASE WHEN T0.Id = 0 THEN T0."Status" ELSE NULL END "状态",
  		 CASE WHEN T0.Id = 0 THEN T0."PostDate" ELSE NULL END "订单日期",
  		 CASE WHEN T0.Id = 0 THEN T0."DocNum" ELSE NULL END "订单号",
  		 CASE WHEN T0.Id = 0 THEN T0."U_Version" ELSE NULL END  "配方版本号",
    	 CASE WHEN T0.Id = 0 THEN T0."ProItmCd" ELSE NULL END "产品编码",
    	 CASE WHEN T0.Id = 0 THEN T0."ProItmNm" ELSE NULL END "产品名称",
    	 CASE WHEN T0.Id = 0 THEN T0."ProPlanedQty" ELSE NULL END "生产数量",
    	 CASE WHEN T0.Id = 0 THEN T0."PoInQty" ELSE NULL END "完成数量", 
    	 T0.Id "序号",  
    	 T0."MtlItmCd" "原料编码",T0."MtlItmNm" "原料名称",
    	 T0."BOMStdQty" "配方标量",T0."PlanedOutQty" "计划用量",T0."FactOutQty" "实际耗用",
    	 T0."FactOutQty" - T0."PlanedOutQty" "差异",
    	 CASE WHEN T0.Id = 0 THEN N'投入-产出率 ：'||TO_NVARCHAR(IFNULL(ROUND(IFNULL(T0."FactOutQty",0)/NULLIF(T0."PoInQty",0.00)*100,2),0.00))||'%' 
    	 	  ELSE N'计划-耗用比： '||TO_NVARCHAR(IFNULL(ROUND(IFNULL(T0."PlanedOutQty",0)/NULLIF(T0."FactOutQty",0.00)*100,2),0.00))||'%'  END "比率",
    	 --CASE WHEN T0.Id = 0 THEN TO_NVARCHAR(IFNULL(ROUND(IFNULL(T0."FactOutQty",0)/NULLIF(T0."PoInQty",0.00)*100,2),0.00))||'%' ELSE NULL END "投入产出比",
    	 T0."MtWhsNm" "耗用仓库",     	 
    	 --T0."Name"  "产品大类",
    	 --T0."U_AliasName"  "内部名称", 
		 '' "备注",	
    	 T0."OcrCode" "工厂",
    	 T0."Descr"  "订单类型"
  FROM :Finally_Rpt T0
    LEFT JOIN OITM T1 ON T0."ProItmCd" = T1."ItemCode"
    LEFT JOIN OITM T2 ON T0."MtlItmCd" = T2."ItemCode"
    LEFT JOIN OWOR T3 ON T0."DocNum" = T3."DocNum"
    LEFT JOIN OPRC T4 ON T3."OcrCode" = T4."PrcCode"
  WHERE IFNULL(T3."Status",'') <> 'C'
  ORDER BY T0."PostDate",T0."DocNum",T0.Id ;

  
  ELSE 
  
  table_temporary = 
         SELECT '' as "选择",
         rank() over(order by T0."PostDate",T0."DocNum",T0.Id) as  "编号" ,  
         CASE WHEN T0.Id = 0 THEN CASE WHEN IFNULL(T3."U_Approved",'') = '1' THEN '已审核' ELSE NULL END ELSE NULL END "审核状态",
  		 CASE WHEN T0.Id = 0 THEN T0."ProWhsNm" ELSE NULL END "入库仓库",
  		 CASE WHEN T0.Id = 0 THEN T0."Status" ELSE NULL END "状态",
  		 CASE WHEN T0.Id = 0 THEN T0."PostDate" ELSE NULL END "订单日期",
  		 CASE WHEN T0.Id = 0 THEN T0."DocNum" ELSE NULL END "订单号",
  		 CASE WHEN T0.Id = 0 THEN T0."U_Version" ELSE NULL END  "配方版本号",
    	 CASE WHEN T0.Id = 0 THEN T0."ProItmCd" ELSE NULL END "产品编码",
    	 CASE WHEN T0.Id = 0 THEN T0."ProItmNm" ELSE NULL END "产品名称",
    	 CASE WHEN T0.Id = 0 THEN T0."ProPlanedQty" ELSE NULL END "生产数量",
    	 CASE WHEN T0.Id = 0 THEN T0."PoInQty" ELSE NULL END "完成数量", 
    	 T0.Id "序号",  
    	 T0."MtlItmCd" "原料编码",T0."MtlItmNm" "原料名称",
    	 T0."BOMStdQty" "配方标量",T0."PlanedOutQty" "计划用量",T0."FactOutQty" "实际耗用",
    	 T0."FactOutQty" - T0."PlanedOutQty" "差异",
    	 CASE WHEN T0.Id = 0 THEN N'投入-产出率 ：'||TO_NVARCHAR(IFNULL(ROUND(IFNULL(T0."FactOutQty",0)/NULLIF(T0."PoInQty",0.00)*100,2),0.00))||'%' 
    	 	  ELSE N'计划-耗用比： '||TO_NVARCHAR(IFNULL(ROUND(IFNULL(T0."PlanedOutQty",0)/NULLIF(T0."FactOutQty",0.00)*100,2),0.00))||'%'  END "比率",
    	 --CASE WHEN T0.Id = 0 THEN TO_NVARCHAR(IFNULL(ROUND(IFNULL(T0."FactOutQty",0)/NULLIF(T0."PoInQty",0.00)*100,2),0.00))||'%' ELSE NULL END "投入产出比",
    	 T0."MtWhsNm" "耗用仓库",     	 
    	 --T0."Name"  "产品大类",
    	 --T0."U_AliasName"  "内部名称", 
		 '' "备注",	
    	 T0."OcrCode" "工厂",
    	 T0."Descr"  "订单类型"
   FROM :Finally_Rpt T0
    LEFT JOIN OITM T1 ON T0."ProItmCd" = T1."ItemCode"
    LEFT JOIN OITM T2 ON T0."MtlItmCd" = T2."ItemCode"
    LEFT JOIN OWOR T3 ON T0."DocNum" = T3."DocNum"
    LEFT JOIN OPRC T4 ON T3."OcrCode" = T4."PrcCode"
   WHERE IFNULL(T3."Status",'') <> 'C' and T3."U_Approved"=:CodeId
   ORDER BY T0."PostDate",T0."DocNum",T0.Id ;
   END IF;
  end if;
  
  
  if :Numbering = 'Y' then 
       insert into U_table select "编号","订单号" from  :table_temporary order by "编号" ASC;
      select * from U_table;
     else
       select * from  :table_temporary ;
  end if;
  drop table U_table;
end ;

drop procedure U_PC_IndentCheck;

call U_PC_IndentCheck('上海新农饲料股份有限公司','2017-10-01','2017-10-31','-','Y');

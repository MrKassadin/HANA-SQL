/*SELECT FROM OBPL T0 WHERE T0."BPLName"=[%0];*/
/*SELECT FROM "@U_COUQR" T2 WHERE T2."U_EDate" =[%2];*/
/*SELECT FROM "OITM" T4 WHERE T4."ItemName" LIKE '%[%4]%';*/
/*SELECT FROM "@U_COUQR" T6 WHERE T6."U_Plant" LIKE '%[%6]%';*/
/*SELECT FROM OCRD T5 WHERE t5."U_CustClass6" LIKE '%[%5]%';*/ 
/*SELECT FROM "OCRD" T3 WHERE T3."CardName" LIKE '%[%3]%';*/

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
DECLARE BPLId int;

select "BPLId" into BPLId from OBPL where "BPLName" = '[%0]';
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 
WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId"
WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';

IF :CNT = 0 THEN
	SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;	
ELSE
  Detail_TMP = 	
	SELECT --T5."PrcName" "工厂",
		   CASE WHEN T7."U_ItemGrpType" = 'A' THEN T5."U_Workshop" ELSE T11."U_Workshop" END "工厂",
		   t0."DocDate" "订单日期",T0."DocDueDate" "预发货日",T0."DocNum" "订单号", 
		   CASE WHEN T1."LineStatus" = 'C' THEN N'已关闭' WHEN T1."LineStatus" = 'O' THEN N'未清' ELSE T1."LineStatus" END "行状态",
		   CASE WHEN T0."U_DLNType" = '1' THEN N'送货' WHEN T0."U_DLNType" = '2' THEN N'自提' END "发货方式", 
		   CASE WHEN T0."U_FrMtType" = '1' THEN N'公司统管' WHEN T0."U_FrMtType" = '2' THEN N'业务员管理' ELSE NULL END "物流管理由",
		   T0."CardCode" "客户代码", T3."CardName" "客户名称",
		   T1."ItemCode" "物料编码", IFNULL(T2."ItemName",'') "物料名称", T2."SalFactor1"  "规格",T2."U_PrdtPara" "折教系数",
		   --T1."LineNum"+1 "行号",
		   CASE WHEN T1."U_Type" = '1' THEN N'销售' WHEN T1."U_Type" = '2' THEN N'赠料'ELSE NULL END "销售方式", 
		   --T1."Quantity" "订货量（KG）",
		   
		   --Modify:2018/01/02
		   --如果销售订单行关闭的数量 不等于 销售发货的数量，则取销售发货量，否则取 销售订单量  作为订货量 
		   CASE WHEN T1."LineStatus" = 'C' AND T1."Quantity" <> SUM(IFNULL(T13."Quantity",0.00)) THEN SUM(IFNULL(T13."Quantity",0.00)) ELSE T1."Quantity" END  "订货量（KG）",
		   --如果销售订单行数量 小于 销售出库量 ，则取 实际销售出库量，否则取 销售订单量  作为已发货量
		   --CASE WHEN SUM(IFNULL(T13."SUM_DLNQty",0.00)) <> 0 THEN SUM(IFNULL(T13."SUM_DLNQty",0.00)) ELSE SUM(IFNULL(T13."Quantity",0.00)) END "已发货量（KG）",
		   CASE WHEN SUM(IFNULL(T13."Open_ORDR_Qty",0.00)) < 0 THEN SUM(IFNULL(T13."SUM_DLNQty",0.00)) ELSE SUM(IFNULL(T13."Quantity",0.00)) END "已发货量（KG）",
		   --T1."OpenQty"  "未清剩余量（KG）",
           --订货量 减去 已发货量
		   CASE WHEN T1."LineStatus" = 'C' AND T1."Quantity" <> SUM(IFNULL(T13."Quantity",0.00)) THEN SUM(IFNULL(T13."Quantity",0.00)) ELSE T1."Quantity" END 
		 --- CASE WHEN SUM(IFNULL(T13."SUM_DLNQty",0.00)) <> 0 THEN SUM(IFNULL(T13."SUM_DLNQty",0.00)) ELSE SUM(IFNULL(T13."Quantity",0.00)) END "未清剩余量（KG）",
		 - CASE WHEN SUM(IFNULL(T13."Open_ORDR_Qty",0.00)) < 0 THEN SUM(IFNULL(T13."SUM_DLNQty",0.00)) ELSE SUM(IFNULL(T13."Quantity",0.00)) END "未清剩余量（KG）",  
		   
		   
		   T1."WhsCode" "仓库",IFNULL(t2."U_AliasName",'') "内部名称",IFNULL(t6."Name",'') "物料大类",
		   IFNULL(T1."U_SlpName",T99."SlpName") "行销员",
		   IFNULL(T1."U_BusiUnit",T3."U_RegSupName") "区域经理",
		   IFNULL(T1."U_SaleUnit",T3."U_SupMangName") "经理主管",
		   IFNULL(T81."Name",T8."Name") "大区",
		   IFNULL(T82."Name",T9."Name") "销售单元",
		   IFNULL(T83."Name",T10."Name") "财务单元",
		   TO_CHAR(T0."U_TComments") "自定义备注"
	FROM OQUT T0
	JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
	JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
	JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
	JOIN OWHS T11 ON T1."WhsCode" = T11."WhsCode"
	LEFT JOIN OUSR T12 ON T0."UserSign" = T12."USERID"
	LEFT JOIN 
	  (SELECT T1."BaseType" ,T1."BaseEntry",T1."BaseLine",T1."Quantity",
			  T1."DocEntry" ,T1."LineNum",SUM(IFNULL(T2."SUM_DLNQty",0)) "SUM_DLNQty",
			  T1."Quantity" - SUM(IFNULL(T2."SUM_DLNQty",0)) "Open_ORDR_Qty"
	   FROM RDR1 T1
	    INNER JOIN ORDR T0 ON T1."DocEntry" = T0."DocEntry"
	    LEFT JOIN 
		  (SELECT T1."BaseType" ,T1."BaseEntry",T1."BaseLine",SUM(T1."Quantity") "SUM_DLNQty"
		   FROM DLN1 T1
		    JOIN ODLN T0 ON T1."DocEntry" = T0."DocEntry"
		   WHERE T0."CANCELED" <> 'Y'
		   GROUP BY T1."BaseType" ,T1."BaseEntry",T1."BaseLine"
		   ) T2 ON T2."BaseEntry" = t1."DocEntry" AND T2."BaseLine" = T1."LineNum" AND T2."BaseType" = T1."ObjType"
	   WHERE T0."CANCELED" <> 'Y' AND T1."BaseType" = 23
	   GROUP BY T1."BaseType" ,T1."BaseEntry",T1."BaseLine",T1."Quantity",T1."DocEntry" ,T1."LineNum"
	   ) T13 ON T13."BaseEntry" = t1."DocEntry" AND T13."BaseLine" = T1."LineNum" AND T13."BaseType" = T1."ObjType"
	LEFT JOIN OCRD T30 ON T0."U_SubCardCd" = T30."CardCode"
	--LEFT JOIN OPRC T5 ON T1."OcrCode" = T5."PrcCode"
	LEFT JOIN (SELECT "U_ItemCode","U_Workshop","Code" FROM "@U_PIT1" ) T5 ON T1."ItemCode" = T5."U_ItemCode" AND T0."BPLId" = T5."Code"
	LEFT JOIN "@U_CITTY2" T6 ON T2."U_Class2" = T6."Code"
	LEFT JOIN OITB T7 ON T2."ItmsGrpCod" = T7."ItmsGrpCod"
	LEFT JOIN "@U_CBPTY4" T8 ON T3."U_CustClass4" = T8."Code"
	LEFT JOIN "@U_CBPTY5" T9 ON T3."U_CustClass5" = T9."Code"
	LEFT JOIN "@U_CBPTY6" T10 ON T3."U_CustClass6" = T10."Code"
	LEFT JOIN "@U_CBPTY4" T81 ON T0."U_CustClass4" = T81."Code"
	LEFT JOIN "@U_CBPTY5" T82 ON T0."U_CustClass5" = T82."Code"
	LEFT JOIN "@U_CBPTY6" T83 ON T0."U_CustClass6" = T83."Code"
	LEFT JOIN OSLP T99 ON T3."SlpCode" = T99."SlpCode"
	WHERE T4."BPLId" = :BPLId
	  --AND (T5."PrcName" LIKE '%[%6]%' OR '[%6]'='' OR '[%6]' IS NULL )
	  AND (T2."ItemName" LIKE '%[%4]%' OR '[%4]'='' OR '[%4]' IS NULL )
	  AND (T3."CardName" LIKE '%[%3]%' OR '[%3]'='' OR '[%3]' IS NULL )
	  AND (T10."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL )
	  AND T0."DocDate" <= '[%2]' 
	  AND T0."CANCELED" <> 'Y'
	  AND T0."DocStatus" = 'O'
	GROUP BY T12."USER_CODE",T12."U_NAME",--T5."PrcName",
		     CASE WHEN T7."U_ItemGrpType" = 'A' THEN T5."U_Workshop" ELSE T11."U_Workshop" END,
		     t0."DocDate",T0."DocNum",
		     T0."U_DLNType",T0."U_FrMtType",T0."CardCode", T3."CardName",T1."ItemCode",IFNULL(T2."ItemName",''),T2."SalFactor1" , 
		     --T1."LineNum",
		     T1."U_Type",T1."LineStatus",T1."Quantity",
		     T1."WhsCode",IFNULL(t2."U_AliasName",''),IFNULL(t6."Name",''),
		     IFNULL(T1."U_SlpName",T99."SlpName") ,
		     IFNULL(T1."U_BusiUnit",T3."U_RegSupName") ,
		     IFNULL(T1."U_SaleUnit",T3."U_SupMangName") ,
		     IFNULL(T81."Name",T8."Name") ,
		     IFNULL(T82."Name",T9."Name") ,
		     IFNULL(T83."Name",T10."Name") ,
		     T0."DocDueDate",TO_CHAR(T0."U_TComments"),T2."U_PrdtPara"
	ORDER BY t0."DocDueDate",T0."DocNum"--,T5."PrcName"
	;	
 
 Summary_TMP =
 	SELECT N'1-SUM' "查看方式",                           
 	       T0."物料大类",T0."内部名称",T0."物料编码",T0."物料名称", --汇总时 按仓库按物料代码汇总
 		   
 		   SUM(T1."OnHand") AS "即时库存（KG）",
 		   SUM(IFNULL(T3."TeRtClQty",0)) AS  "理论库存（KG）",     --从视图"U_VC_AvailableQty"计算, 它等于即时库存量  减去  销售发货单_ORDR上已打印未生成出库单的量
 		   T0."折教系数" ,
 		   SUM(T0."未清剩余量（KG）") AS "未清剩余量（KG）",
 		   SUM(IFNULL(T3."TeRtClQty",0) - T0."未清剩余量（KG）" ) AS "缺量（KG）",
 		   
 		   '0' "序号" ,
 		   "工厂"||N' - '||CASE WHEN "工厂" = 'W0000001' THEN N'膨化厂（上海）'
	  						    WHEN "工厂" = 'W0000002' THEN N'青浦厂（上海）'
	  						    WHEN "工厂" = 'W0000003' THEN N'松江厂（上海）'
	  						    WHEN "工厂" = 'W0000004' THEN N'香川厂（上海）'
	  						    WHEN "工厂" = 'WH300999' THEN N'武汉新农翔'
	  						    WHEN "工厂" = 'WZ400999' THEN N'新农（郑州）'
	  						    WHEN "工厂" = 'WF500999' THEN N'上海丰卉'
	  						    WHEN "工厂" = 'WC600999' THEN N'上海和畅'  END "工厂",
 		   T0."仓库"||N' - '||T2."WhsName" AS  "仓库",
 		   NULL "订货量（KG）",NULL "已发货量（KG）",   
		   NULL "客户代码",NULL "客户名称",
		   NULL "订单日期",NULL "预发货日",NULL "自定义备注",NULL "订单号",--NULL "行号",
		   NULL "销售方式",NULL "行状态", NULL "发货方式",NULL "物流管理由", 
		   NULL "大区", NULL "销售单元", NULL "财务单元" ,NULL "行销员", NULL "区域经理", NULL "经理主管"    
 	FROM 
 	 (SELECT "物料大类","内部名称","物料编码","物料名称","折教系数","工厂","仓库",SUM("未清剩余量（KG）") "未清剩余量（KG）"
 	  FROM :Detail_TMP 
 	  GROUP BY "物料大类","内部名称","物料编码","物料名称","折教系数","工厂","仓库"
 	  )T0
 	 JOIN OITW T1 ON T0."物料编码" = T1."ItemCode" AND T0."仓库" = T1."WhsCode"
 	 JOIN OWHS T2 ON T1."WhsCode" = T2."WhsCode"
 	 LEFT JOIN 
 	  (SELECT "ItemCode","WhsCode","BPLid",SUM("TeRtClQty") "TeRtClQty"
 	   FROM "U_VC_AvailableQty" 
 	   GROUP BY "ItemCode","WhsCode","BPLid"
 	   )T3 ON T0."物料编码" = T3."ItemCode" AND T0."仓库" = T3."WhsCode" AND T3."BPLid" = :BPLId 
 	LEFT JOIN "@U_COWSTY" T4 ON T2."U_WhsType" = T4."Code"
 	WHERE T4."Code" <> '33'
 	GROUP BY T0."物料大类",T0."内部名称",T0."物料编码",T0."物料名称",T0."工厂",T0."仓库",T2."WhsName",T0."折教系数"
	
	UNION ALL
	SELECT N'2-detail' ,
		   "物料大类","内部名称", "物料编码","物料名称",
 		   
 		   NULL, 
 		   NULL,
 		   T0."折教系数",
 		   "未清剩余量（KG）", 
 		   NULL,
 		   
 		   ROW_NUMBER() OVER(PARTITION BY "物料编码","工厂",t0."仓库" ORDER BY "物料编码") Id,
 		   "工厂"||N' - '||CASE WHEN "工厂" = 'W0000001' THEN N'膨化厂（上海）'
	  						    WHEN "工厂" = 'W0000002' THEN N'青浦厂（上海）'
	  						    WHEN "工厂" = 'W0000003' THEN N'松江厂（上海）'
	  						    WHEN "工厂" = 'W0000004' THEN N'香川厂（上海）'
	  						    WHEN "工厂" = 'WH300999' THEN N'武汉新农翔'
	  						    WHEN "工厂" = 'WZ400999' THEN N'新农（郑州）'
	  						    WHEN "工厂" = 'WF500999' THEN N'上海丰卉'
	  						    WHEN "工厂" = 'WC600999' THEN N'上海和畅'  END "工厂",
 		   t0."仓库"||N' - '||T1."WhsName", 
 		   "订货量（KG）", "已发货量（KG）",
		   "客户代码", "客户名称", 
		   "订单日期", "预发货日","自定义备注", "订单号", --"行号", 
		   "销售方式", "行状态",  "发货方式","物流管理由", 
		   "大区", "销售单元", "财务单元","行销员", "区域经理", "经理主管" 
 	FROM :Detail_TMP T0
 	 JOIN OWHS T1 ON T0."仓库" = t1."WhsCode"
 	 LEFT JOIN "@U_COWSTY" T2 ON T1."U_WhsType" = T2."Code"
 	WHERE 1 = 1 
 	  AND T2."Code" <> '33';
  
  
  SELECT *
  FROM(
	  SELECT * 
	  FROM :Summary_TMP 
	  WHERE 1 = 1 
	  
	  UNION ALL
	  SELECT N'1-SUM' "查看方式",                           
	 	       T3."Name",T0."U_AliasName",T0."ItemCode",T0."ItemName", --汇总时 不区分仓库按物料代码汇总
	 		   
	 		   T2."OnHand" AS "即时库存（KG）",
	 		   T7."TeRtClQty" AS "理论库存（KG）",   
	 		   T0."U_PrdtPara" "折教系数",
	 		   0.00 AS "未清剩余量（KG）",
	 		   T7."TeRtClQty" AS "缺量（KG）",
	 		   
	 		   '0' "序号" ,
	 		   T5."U_Workshop"||N' - '||CASE WHEN T5."U_Workshop" = 'W0000001' THEN N'膨化厂（上海）'
		    	  						     WHEN T5."U_Workshop" = 'W0000002' THEN N'青浦厂（上海）'
		    	  						     WHEN T5."U_Workshop" = 'W0000003' THEN N'松江厂（上海）'
		    	  						     WHEN T5."U_Workshop" = 'W0000004' THEN N'香川厂（上海）'
		    	  						     WHEN T5."U_Workshop" = 'WH300999' THEN N'武汉新农翔'
		    	  						     WHEN T5."U_Workshop" = 'WZ400999' THEN N'新农（郑州）'
		    	  						     WHEN T5."U_Workshop" = 'WF500999' THEN N'上海丰卉'
		    	  						     WHEN T5."U_Workshop" = 'WC600999' THEN N'上海和畅'  END "工厂",
	 		   T2."WhsCode"||N' - '||T4."WhsName" "仓库",
	 		   NULL "订货量（KG）",NULL "已发货量（KG）",   
			   NULL "客户代码",NULL "客户名称",
			   NULL "订单日期",NULL "预发货日",NULL "备注",NULL "订单号",--NULL "行号",
			   NULL "销售方式",NULL "行状态", NULL "发货方式",NULL "物流管理由", 
			   NULL "大区", NULL "销售单元", NULL "财务单元" ,NULL "行销员", NULL "区域经理", NULL "经理主管" 
	  FROM OITM T0
	  JOIN OITB T1 ON T0."ItmsGrpCod" = T1."ItmsGrpCod" AND T1."U_ItemGrpType" IN('A')
	  JOIN OITW T2 ON T0."ItemCode" = T2."ItemCode" AND T2."OnHand" <> 0.000
	  JOIN OWHS T4 ON T2."WhsCode" = T4."WhsCode"
	  LEFT JOIN "@U_CITTY2" T3 ON T0."U_Class2" = T3."Code"
	  LEFT JOIN "@U_COWSTY" T6 ON T4."U_WhsType" = T6."Code"
	  LEFT JOIN
	   (SELECT "ItemCode","WhsCode","BPLid",SUM("TeRtClQty") "TeRtClQty"
 	    FROM "U_VC_AvailableQty" 
 	    GROUP BY "ItemCode","WhsCode","BPLid"
 	    )T7 ON T0."ItemCode" = T7."ItemCode" AND T2."WhsCode" = T7."WhsCode" AND T7."BPLid" = :BPLId  
	  LEFT JOIN (SELECT "U_ItemCode","U_Workshop","Code" FROM "@U_PIT1" ) T5 ON T0."ItemCode" = T5."U_ItemCode" AND T4."BPLid" = T5."Code"
	  LEFT JOIN (SELECT DISTINCT U0."物料编码",U0."仓库",U0."工厂" FROM :Detail_TMP U0) T8 ON T8."物料编码" = T0."ItemCode" AND T8."仓库" = T2."WhsCode" AND T8."工厂" = T5."U_Workshop"
	  WHERE 1 = 1 --NOT EXISTS(SELECT 1 FROM :Summary_TMP U0 WHERE U0."物料编码" = T0."ItemCode" )
	    AND T4."BPLid" = :BPLId
	    AND T8."物料编码" IS NULL
	    AND T6."Code" <> '33'
      ) R0
  WHERE 1 = 1
    AND (R0."工厂" LIKE '%[%6]%' OR '[%6]'='' OR '[%6]' IS NULL )
  ORDER BY "工厂","物料编码","查看方式","序号","仓库","预发货日";
  
END IF;
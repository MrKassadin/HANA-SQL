ALTER PROCEDURE "U_PC_SaleORDR"
(
IN BPLId NVARCHAR(100),
IN BDATE DATE,
IN EDATE DATE
)
LANGUAGE SQLSCRIPT
AS
BEGIN
/*SELECT FROM OBPL T0 WHERE T0."BPLName"=[%0];*/
/*SELECT FROM "OFPR" T1 WHERE T1."F_RefDate" >=[%1];*/
/*SELECT FROM "OFPR" T2 WHERE T2."T_RefDate" <=[%2];*/
/*SELECT FROM "@U_COUQR" T4 WHERE T4."U_Plant" LIKE '%[%4]%';*/
/*SELECT FROM OCRD T5 WHERE t5."U_CustClass6" LIKE '%[%5]%';*/ 
/*SELECT FROM "OCRD" T3 WHERE T3."CardName" LIKE '%[%3]%';*/

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
--declare BPLId int;
--select "BPLId" into BPLId from OBPL where "BPLName" = '[%0]';
--SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
--SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';

--IF :CNT = 0 THEN
--    SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;	
--ELSE

	CALL "U_PC_SaleOrders_Cur" (:BPLId,:BDATE,:EDATE,TB) ;
	ORDR_TB = SELECT * FROM :TB ;

    SELECT CASE WHEN T1."BaseType" = 23 THEN N'基于订单生成' ELSE N'手工添加' END "生成方式",
    	   CASE WHEN T1."BaseType" = 23 THEN T1."BaseRef" ELSE NULL END "订单号",
    	   T6."PrcName" "工厂",T11."Name" "业务类型",T12."WhsName" "仓库",
    	   T0."CardCode" "客户编码",T3."CardName" "客户名称",
    	   CASE WHEN T5."CardCode" IS NOT NULL THEN T5."CardCode" ELSE T0."CardCode" END "下级客户",
		   CASE WHEN T5."CardCode" IS NOT NULL THEN T5."CardName" ELSE T3."CardName" END "下级客户名称",
		   T0."DocNum" "发货单号",to_date(T0."DocDate") "发货日期",
		   T2."U_PrdtPara" "折教系数",
           --case when t0."U_Approve" = '2' then N'通过' else N'未通过' end "授信审批" ,
		   
		   CASE WHEN T0."DocStatus" = 'O' AND T0."CANCELED" = 'N' AND T0."Printed" = 'Y' AND T8."BaseEntry" IS NULL THEN N'已开单未出库'
		   	    WHEN T0."DocStatus" = 'O' AND T0."CANCELED" = 'N' AND T0."Printed" <> 'Y' THEN N'未开单' 	   	    
		   	    WHEN T0."DocStatus" = 'O' AND T0."CANCELED" = 'N' AND T0."InvntSttus" = 'O' AND T8."BaseEntry" IS NOT NULL AND T9."BaseEntry" IS NULL THEN N'部分出库' 
		   	    
		   	    WHEN T0."DocStatus" = 'C' AND T0."CANCELED" = 'N' AND T0."InvntSttus" = 'O' AND T8."BaseEntry" IS NULL THEN N'手工关闭' 
		   	    WHEN T0."DocStatus" = 'C' AND T0."CANCELED" = 'N' AND T0."InvntSttus" = 'O' AND T8."BaseEntry" IS NOT NULL AND T9."BaseEntry" IS NULL THEN N'退货关闭'
		   	    WHEN T0."DocStatus" = 'C' AND T0."CANCELED" = 'N' AND T0."InvntSttus" = 'C' AND T8."BaseEntry" IS NOT NULL AND T9."BaseEntry" IS NULL THEN N'完全出库'
		   	    WHEN T0."DocStatus" = 'C' AND T0."CANCELED" = 'N' AND T0."InvntSttus" = 'C' AND T9."BaseEntry" IS NOT NULL AND IFNULL(T8."ODLN_Qty",0) <> IFNULL(T9."OINV_Qty",0) THEN N'部分开票'
		   	    WHEN T0."DocStatus" = 'C' AND T0."CANCELED" = 'N' AND T0."InvntSttus" IN ('C','O') AND T9."BaseEntry" IS NOT NULL AND IFNULL(T8."ODLN_Qty",0) = IFNULL(T9."OINV_Qty",0) THEN N'完全开票'
		   	    WHEN T0."DocStatus" = 'C' AND T0."CANCELED" = 'Y' THEN N'手工取消'  ELSE '未知状态（请联系系统管理员）' END  "状态",		   
		   
		   CASE WHEN T0."U_DLNType"='1' THEN  N'送货' 
		   	 	WHEN  T0."U_DLNType"='2' THEN  N'自提' ELSE '未知' END "发货方式",	   
		   T1."ItemCode" "物料代码",T2."ItemName" "物料名称",T2."SalFactor1" "规格",
		   T1."Quantity"/T2."SalFactor1" "发货单-件数",T1."Quantity" "发货单-重量(KG)",T2."InvntryUom" "单位",
		   T1."Price" "不含税单价",T1."LineTotal"  "不含税金额",T1."PriceAfVAT" "含税单价",T1."LineTotal"+T1."VatSum" "含税金额",
		   T1."U_Realdisc" "赠料",
		   T0."Comments" "发货备注",
		   T0."U_TComments" "备注信息",
		   T0."U_Driver" "司机姓名",
		   T0."U_CarCd" "车牌号",
		   T0."U_TelPhNum" "司机电话",
		   IFNULL(T0."U_ShipPrice",0.00) "运费单价",IFNULL(T0."U_ShipExpns",0.00) "其他杂费",IFNULL(T0."U_TtlShpAmt",0.00) "运费总额" ,
           /*	
		   T8."DocNum" "出库单号",to_date(T8."DocDate") "出库日期",T8."WhsName" "出库仓库",
           */           
		   IFNULL(T40."ODLNDocNum",'') "出库单号",
		   IFNULL(T8."ODLN_Qty",0)/T2."SalFactor1" "出库单-件数",
		   IFNULL(T8."ODLN_Qty",0) "出库单-重量(KG)",
		   T1."Quantity" - IFNULL(T8."ODLN_Qty",0) "未出库数量" ,
           IFNULL(T40."OINVDocNum",'') "发票单号",
           /*
	       T8."RspStatus" "回单状态",T8."Comments" "出库备注",
		   T9."DocNum" "发票单号",to_date(T9."DocDate") "发票日期",
		   T9."Quantity"/T2."SalFactor1" "发票单-包数",T9."Quantity" "发票单-重量(KG)",
		   T9."Price" "不含税单价",T9."LineTotal"  "不含税金额",T9."PriceAfVAT" "含税单价",T9."LineTotal"+T9."VatSum" "含税金额",
		   CASE WHEN T9.id = 1 THEN T9."DiscSum" ELSE 0.00 END "折扣金额", T9."Comments" "发票备注",
		   */
		   t10."lastName"||t10."firstName" "制单人",T2."U_OldItemCode" "旧代码",
		   T02."ItmsGrpNam" "物料组",T20."Name" "物料大类",T2."U_Class3" "物料中类",
		   T2."U_ItemNameType" ||'-'||T13."Name" "物料小类",
		   
		   T2."U_ItemName" "别名",T2."U_AliasName" "内部名称",
		   IFNULL(T1."U_SlpName",T99."SlpName") "行销员",
		   IFNULL(T1."U_BusiUnit",T3."U_RegSupName") "区域经理",
		   IFNULL(T1."U_SaleUnit",T3."U_SupMangName") "经理主管",
		   IFNULL(T81."Name",T31."Name") "管理大区",
		   IFNULL(T82."Name",T32."Name") "销售单元",
		   IFNULL(T83."Name",T33."Name") "财务维度"
	FROM ORDR T0
	JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
	JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	LEFT JOIN "@U_ITEMNAMETYPE" T13 on t2."U_ItemNameType"= T13."Code"
	JOIN OITB T02 ON T2."ItmsGrpCod" = T02."ItmsGrpCod"
	JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
	JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"	
	LEFT JOIN OCRD T5 ON T0."U_SubCardCd" = T5."CardCode"
	LEFT JOIN OPRC T6 ON T1."OcrCode" = T6."PrcCode"
	LEFT JOIN OHEM T10 ON T0."OwnerCode" = T10."empID"
	LEFT JOIN "@U_CMSBST" T11 ON T0."U_BusiType" = T11."Code"
	LEFT JOIN OWHS T12 ON T1."WhsCode" = T12."WhsCode"
	LEFT JOIN 
	  ( SELECT T1."BaseEntry",T1."BaseLine",T1."BaseType",SUM(T1."Quantity") "ODLN_Qty"
	    FROM DLN1 T1 
	    JOIN ODLN T0 ON T1."DocEntry" = T0."DocEntry"
	    WHERE T0."CANCELED" <> 'Y' AND T1."BaseType" = 17
	    GROUP BY T1."BaseEntry",T1."BaseLine",T1."BaseType"
	   ) T8 ON t1."DocEntry" = t8."BaseEntry" and t1."LineNum" = t8."BaseLine" and t1."ObjType" = t8."BaseType"
	LEFT JOIN 
	  ( SELECT T3."BaseEntry",T3."BaseLine",T3."BaseType",SUM(T1."Quantity") "OINV_Qty"
	    FROM INV1 T1 
	    INNER JOIN OINV T0 ON T1."DocEntry" = T0."DocEntry"
	    INNER JOIN DLN1 T3 ON T1."BaseEntry" = T3."DocEntry" AND T1."BaseLine" = T3."LineNum" AND T1."BaseType" = T3."ObjType"
	    INNER JOIN ODLN T4 ON T3."DocEntry" = T4."DocEntry" AND T3."BaseType" = 17 AND T4."CANCELED" <> 'Y'
	    WHERE T0."CANCELED" <> 'Y' AND T1."BaseType" = 15 
	    GROUP BY T3."BaseEntry",T3."BaseLine",T3."BaseType"
	   ) T9 ON T1."DocEntry" = T9."BaseEntry" and T1."LineNum" = T9."BaseLine" and T1."ObjType" = T9."BaseType"
	LEFT JOIN "@U_CITTY2" T20 ON T2."U_Class2" = T20."Code"--物料种类
	LEFT JOIN "@U_CBPTY4" T31 ON T3."U_CustClass4" = T31."Code"
	LEFT JOIN "@U_CBPTY5" T32 ON T3."U_CustClass5" = T32."Code"
	LEFT JOIN "@U_CBPTY6" T33 ON T3."U_CustClass6" = T33."Code"
	LEFT JOIN "@U_CBPTY4" T81 ON T0."U_CustClass4" = T81."Code"
	LEFT JOIN "@U_CBPTY5" T82 ON T0."U_CustClass5" = T82."Code"
	LEFT JOIN "@U_CBPTY6" T83 ON T0."U_CustClass6" = T83."Code"
	LEFT JOIN OSLP T99 ON T3."SlpCode" = T99."SlpCode"
	LEFT JOIN :ORDR_TB T40 ON T0."DocNum" = T40."ORDRDocNum"
	WHERE T4."BPLId" = :BPLId
	  --AND IFNULL(T0."U_BusiType",'') <> 'S03'                    --不考虑库存调拨的订单
      --AND (T6."PrcName" LIKE '%[%4]%' OR '[%4]'='' OR '[%4]' IS NULL )
	  AND (T0."DocDate" >=:BDATE OR :BDATE=' ' OR :BDATE IS NULL) 
	  AND (T0."DocDate" <=:EDATE OR :EDATE=' ' OR :EDATE IS NULL)
	  --AND (T3."CardName" LIKE '%[%3]%' OR '[%3]'=' ' OR '[%3]' IS NULL )
	  --AND (T33."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL )
	  AND T0."CANCELED" <> 'Y'
	ORDER BY to_date(T0."DocDate"),T0."DocNum" ;		
   
--END IF;
END;
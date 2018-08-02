/*SELECT FROM OBPL T0 WHERE T0."BPLName"=[%0];*/
/*SELECT FROM "OFPR" T1 WHERE T1."F_RefDate" >=[%1];*/
/*SELECT FROM "OFPR" T2 WHERE T2."T_RefDate" <=[%2];*/
/*SELECT FROM OCRD T5 WHERE t5."U_CustClass6" LIKE '%[%5]%';*/
/*SELECT FROM "OCRD" T3 WHERE T3."CardName" LIKE '%[%3]%';*/

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
declare BPLId INT;
select "BPLId" into BPLId from OBPL where "BPLName" = '[%0]';
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';

IF :CNT = 0 THEN
	SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;	
ELSE
	SELECT t10."lastName"||t10."firstName" as "制单人",
		 N'应收发票' "单据类型",
		   T6."PrcName" "工厂",
		   --T0."DocEntry" "链接号",
		   T0."DocNum" "单据号",T0."DocDate" "日期",
		   T0."U_GTSRegNum" "发票编号",T0."U_GTSRegIdx" "发票代号",
		   T0."CardCode" "客户",T3."CardName" "客户名称",
		   CASE WHEN T03."CardCode" IS NOT NULL THEN T03."CardCode" ELSE T0."CardCode" END "下级客户",
		   CASE WHEN T03."CardCode" IS NOT NULL THEN T03."CardName" ELSE T3."CardName" END "下级客户名称",
		   T1."ItemCode" "物料代码",T2."ItemName" "物料名称",--T2."SalFactor1" "规格",
		   --T1."Quantity" / T2."SalFactor1" "包数",
		   T1."Quantity" "重量(KG)",
		   T2."InvntryUom" "单位",
		   T1."PriceBefDi" "不含税单价",--T1."LineTotal" "不含税金额",
		   CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END "不含税金额",
		   CASE WHEN T1."U_Realdisc" = '是' THEN T1."PriceBefDi" ELSE T1."PriceAfVAT" END "含税单价",
		   --(t1."LineTotal"+t1."VatSum") "含税金额",
		   (CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum") "含税金额",
		   T1."U_Realdisc" "是否赠料",
		   CASE WHEN T11."Code" IS NOT NULL THEN T11."Name" ELSE T1."U_MutDiscType" END "折扣名称" ,
		   -IFNULL(T1."U_SDiscAmt",0.00) "折扣额",
		   (CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum")-IFNULL(T1."U_SDiscAmt",0.00) "折扣后金额",
		   T0."Comments" "备注", 
           T02."ItmsGrpNam" "物料组",T20."Name" "物料大类",T2."U_Class3" "物料中类",T2."U_ItemName" "别名",T2."U_AliasName" "内部名称",
		   T1."U_SlpName" "行销员",T1."U_BusiUnit" "区域经理",T1."U_SaleUnit" "经理主管",
		   T31."Name" "管理大区",T32."Name" "销售单元",T33."Name" "财务维度"
	FROM OINV T0
	JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
	JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	JOIN OITB T02 ON T2."ItmsGrpCod" = T02."ItmsGrpCod"
	JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
	LEFT JOIN OCRD T03 ON T0."U_SubCardCd" = T03."CardCode"
	LEFT JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
	LEFT JOIN OPRC T6 ON T1."OcrCode" = T6."PrcCode"
    left join ohem  t10 on t0."UserSign"=t10."userId"
    LEFT JOIN "@U_SODIU" T11 ON T1."U_SUdDicTyp" = T11."Code"
	left join "@U_CITTY2" t20 ON  T2."U_Class2" = t20."Code"
	LEFT JOIN "@U_CBPTY4" T31 ON T3."U_CustClass4" = T31."Code"
	LEFT JOIN "@U_CBPTY5" T32 ON T3."U_CustClass5" = T32."Code"
	LEFT JOIN "@U_CBPTY6" T33 ON T3."U_CustClass6" = T33."Code"
	WHERE T4."BPLId" = :BPLId
	  AND (T0."DocDate" >='[%1]' OR '[%1]'=' ' OR '[%1]' IS NULL) 
	  AND (T0."DocDate" <='[%2]' OR '[%2]'=' ' OR '[%2]' IS NULL)
	  AND (T3."CardName" = '%[%3]%' OR '[%3]' = '' OR '[%3]' IS NULL)
	  AND (T33."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL )
	  AND T0."CANCELED" <> 'Y'
	  AND T1."BaseType" <> 13 	 --不考虑取消单与抵消单	
	
	UNION ALL
	SELECT t10."lastName"||t10."firstName" as "制单人",
	      N'应收贷项凭证' "单据类型",
		   T6."PrcName" "工厂",
		   --T0."DocEntry" "链接号",
		   T0."DocNum" ,T0."DocDate" "日期",
		   T0."U_GTSRegNum" "发票编号",T0."U_GTSRegIdx" "发票代号",
		   T0."CardCode" "客户",T3."CardName" "客户名称",
		   CASE WHEN T03."CardCode" IS NOT NULL THEN T03."CardCode" ELSE T0."CardCode" END "下级客户",
		   CASE WHEN T03."CardCode" IS NOT NULL THEN T03."CardName" ELSE T3."CardName" END "下级客户名称",
		   T1."ItemCode" "物料代码",T2."ItemName" "物料名称",--T2."SalFactor1" "规格",
		   -- - CASE WHEN (T1."BaseType" = 16 OR T1."NoInvtryMv" = 'Y') THEN 0.00 ELSE T1."Quantity" END / T2."SalFactor1" "包数",
		   - CASE WHEN (T1."BaseType" = 16 OR T1."NoInvtryMv" = 'Y') THEN 0.00 ELSE T1."Quantity" END "重量(KG)",
		   T2."InvntryUom" "单位",
		   T1."PriceBefDi" "不含税单价",--T1."LineTotal" "不含税金额",
		   -CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END "不含税金额",
		   CASE WHEN T1."U_Realdisc" = '是' THEN T1."PriceBefDi" ELSE T1."PriceAfVAT" END "含税单价",
		   --(t1."LineTotal"+t1."VatSum") "含税金额",
		   -(CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum") "含税金额",
		   T1."U_Realdisc" "是否赠料",
		   CASE WHEN T11."Code" IS NOT NULL THEN T11."Name" ELSE T1."U_MutDiscType" END "折扣名称" ,
		   IFNULL(T1."U_SDiscAmt",0.00) "折扣额",
		   -(CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum")+IFNULL(T1."U_SDiscAmt",0.00) "折扣后金额",
		   T0."Comments" "备注",
           T02."ItmsGrpNam" "物料组",T20."Name" "物料大类",T2."U_Class3" "物料中类",T2."U_ItemName" "别名",T2."U_AliasName" "内部名称",
		   T1."U_SlpName" "行销员",T1."U_BusiUnit" "区域经理",T1."U_SaleUnit" "经理主管",
		   T31."Name" "管理大区",T32."Name" "销售单元",T33."Name" "财务维度"
	FROM ORIN T0
	JOIN RIN1 T1 ON T0."DocEntry" = T1."DocEntry"
	JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
	JOIN OITB T02 ON T2."ItmsGrpCod" = T02."ItmsGrpCod"
	JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
	LEFT JOIN OCRD T03 ON T0."U_SubCardCd" = T03."CardCode"
	LEFT JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
	LEFT JOIN OPRC T6 ON T1."OcrCode" = T6."PrcCode"
    left join ohem  t10 on t0."UserSign"=t10."userId"
    LEFT JOIN "@U_SODIU" T11 ON T1."U_SUdDicTyp" = T11."Code"
	left join "@U_CITTY2" t20 ON  T2."U_Class2" = t20."Code"
	LEFT JOIN "@U_CBPTY4" T31 ON T3."U_CustClass4" = T31."Code"
	LEFT JOIN "@U_CBPTY5" T32 ON T3."U_CustClass5" = T32."Code"
	LEFT JOIN "@U_CBPTY6" T33 ON T3."U_CustClass6" = T33."Code"
	WHERE T4."BPLId" = :BPLId
	  AND (T0."DocDate" >='[%1]' OR '[%1]'=' ' OR '[%1]' IS NULL) 
	  AND (T0."DocDate" <='[%2]' OR '[%2]'=' ' OR '[%2]' IS NULL)
	  AND (T3."CardName" = '%[%3]%' OR '[%3]' = '' OR '[%3]' IS NULL)
	  AND (T33."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL )
	  AND T0."CANCELED" <> 'Y'
	  AND T1."BaseType" <> 14 ;	 --不考虑取消单与抵消单	
	--select * from ORDR ORDER BY "DocNum"
END IF;
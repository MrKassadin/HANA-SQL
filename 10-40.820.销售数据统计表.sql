/*SELECT FROM OBPL T0 WHERE T0.BPLname = [%0];*/
/*SELECT FROM OFPR T1 WHERE T1."Code" = [%1];*/
/*SELECT FROM OFPR T3 WHERE T3."Code" = [%3];*/

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
DECLARE BPLId INT;
DECLARE CODE NVARCHAR(20);
DECLARE Crt_FcCode NVARCHAR(10);
DECLARE Old_FcCode NVARCHAR(10);
DECLARE Crt_BDATE DATE;
DECLARE Crt_EDATE DATE;
DECLARE Old_BDATE DATE;
DECLARE Old_EDATE DATE;

Old_FcCode := '[%1]';
Crt_FcCode := '[%3]';
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';
SELECT "BPLId" INTO bplid FROM OBPL WHERE "BPLName"='[%0]';
SELECT T0."F_RefDate" , T0."T_RefDate" INTO Old_BDATE,Old_EDATE FROM OFPR T0 WHERE T0."Code"= :Old_FcCode; 
SELECT T0."F_RefDate" , T0."T_RefDate" INTO Crt_BDATE,Crt_EDATE FROM OFPR T0 WHERE T0."Code"= :Crt_FcCode; 

IF :CNT = 0 THEN	
	SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;	
ELSE	
	TEMP = 
		SELECT T10."lastName"||T10."firstName" as "Creator",
			 N'应收发票' "DocType",
			   CASE WHEN T20."U_ItemGrpType" IN ('A','B') THEN IFNULL(T40."U_Workshop",'') ELSE T41."U_Workshop" END "Plant",
			   T5."Code" "FcCode",
			   T0."DocNum" ,
			   T1."LineNum",
			   T0."DocDate" "DocDate",
			   T0."U_GTSRegDat" "GTSRegDate" ,
			   T0."U_GTSRegNum" "GTSRegNum",
			   T0."U_GTSRegIdx" "GTSRegIdx",
			   T0."CardCode" ,T3."CardName",
			   CASE WHEN T30."CardCode" IS NOT NULL THEN T30."CardCode" ELSE T0."CardCode" END "SubCardCd",
			   CASE WHEN T30."CardCode" IS NOT NULL THEN T30."CardName" ELSE T3."CardName" END "SubCardNm",
			   T1."ItemCode" ,T2."ItemName" ,
			   --T2."SalFactor1" "Size",
			   --T1."Quantity" / T2."SalFactor1" "Packages",
			   T1."Quantity",
			   T2."InvntryUom" ,
			   --CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END "LineTotal",
			   --(CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum") "GTotal",
			   CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."U_LineTotal"+IFNULL(T1."U_LocaAmt",0.00)+IFNULL(T1."U_ExpsAmt",0.00) END "LineTotal",
			   (CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."U_LineTotal"+IFNULL(T1."U_LocaAmt",0.00)+IFNULL(T1."U_ExpsAmt",0.00) END + t1."VatSum") "GTotal",
			   T1."U_Realdisc" "Realdisc",
			   CASE WHEN T11."Code" IS NOT NULL THEN T11."Name" ELSE T1."U_MutDiscType" END "MutDiscType" ,
			   -IFNULL(T1."U_SDiscAmt",0.00) "SDiscAmt",
			   -IFNULL(T1."U_LocaAmt",0.00) "LocaAmt",
			   -IFNULL(T1."U_ExpsAmt",0.00) "ExpsAmt",
			   --(CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum") - IFNULL(T1."U_SDiscAmt",0.00) "Revenues",
			   (CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."U_LineTotal" END + t1."VatSum") - IFNULL(T1."U_SDiscAmt",0.00) "Revenues",
			   T0."Comments" , 
	           T20."ItmsGrpNam" ,T21."Name" "ItemClass1",T2."U_Class3" "ItemClass2",T2."U_ItemName" "ItemClass3",T2."U_AliasName" "ItemClass4",
			   T1."U_SlpName" "SlpName",T1."U_BusiUnit" "BusiUnit",T1."U_SaleUnit" "SaleUnit",
			   T31."Name" "SArea",T32."Name" "SDept",T33."Name" "SDimCd",T3."AddID"||N'-'||T3."U_CustClass3" "SScale"--上级客户规模拼接客户分类三,徐浩3月20日更新
		FROM OINV T0
		INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
		INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
		INNER JOIN OITB T20 ON T2."ItmsGrpCod" = T20."ItmsGrpCod"
		INNER JOIN OFPR T5 ON T0."DocDate" BETWEEN T5."F_RefDate" AND T5."T_RefDate" 
		INNER JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
		LEFT JOIN OCRD T30 ON T0."U_SubCardCd" = T30."CardCode"
		LEFT JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
	    LEFT JOIN OHEM T10 on t0."UserSign"=t10."userId"
	    LEFT JOIN "@U_SODIU" T11 ON T1."U_SUdDicTyp" = T11."Code"
		LEFT JOIN "@U_CITTY2" T21 ON  T2."U_Class2" = T21."Code"
		LEFT JOIN "@U_CBPTY4" T31 ON T3."U_CustClass4" = T31."Code"
		LEFT JOIN "@U_CBPTY5" T32 ON T3."U_CustClass5" = T32."Code"
		LEFT JOIN "@U_CBPTY6" T33 ON T3."U_CustClass6" = T33."Code"
		LEFT JOIN ( SELECT "U_ItemCode","U_ItemName","U_ActoPlant","U_Workshop" 
         			FROM "@U_PIT1" WHERE "Code" = :BPLId  ) T40 ON T1."ItemCode" = T40."U_ItemCode"
		LEFT JOIN OWHS T41 ON T1."WhsCode" = T41."WhsCode"
		WHERE T4."BPLId" = :BPLId
		  AND T5."Code" >= :Old_FcCode AND T5."Code" <= :Crt_FcCode
		  AND T0."CANCELED" <> 'Y'
		  AND T1."BaseType" <> 13 	 --不考虑取消单与抵消单	
		
		UNION ALL
		SELECT t10."lastName"||t10."firstName" as "Creator",
		      N'应收贷项凭证' "DocType",
			   CASE WHEN T20."U_ItemGrpType" IN ('A','B') THEN IFNULL(T40."U_Workshop",'') ELSE T41."U_Workshop" END "Plant",
			   T5."Code" "FcCode",
			   T0."DocNum" ,
			   T1."LineNum",
			   T0."DocDate",
			   T0."U_GTSRegDat" "GTSRegDate" ,
			   T0."U_GTSRegNum" ,
			   T0."U_GTSRegIdx" ,
			   T0."CardCode" ,
			   T3."CardName" ,
			   CASE WHEN T30."CardCode" IS NOT NULL THEN T30."CardCode" ELSE T0."CardCode" END "SubCardCd",
			   CASE WHEN T30."CardCode" IS NOT NULL THEN T30."CardName" ELSE T3."CardName" END "SubCardNm",
			   T1."ItemCode" ,T2."ItemName" ,
			   --T2."SalFactor1" "Size",
			   -- - CASE WHEN (T1."NoInvtryMv" = 'Y') THEN 0.00 ELSE T1."Quantity" END / T2."SalFactor1" "Packages",
			   - T1."Quantity"  "Quantity",--CASE WHEN (T1."NoInvtryMv" = 'Y') THEN 0.00 ELSE T1."Quantity" END "Quantity",--应财务要求,将不含数量过账的应付贷项的数量也在报表中显示
			   T2."InvntryUom" ,
			   -CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END "LineTotal",
			   -(CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum") "GTotal",
			   T1."U_Realdisc" "Realdisc",
			   CASE WHEN T11."Code" IS NOT NULL THEN T11."Name" ELSE T1."U_MutDiscType" END "MutDiscType" ,
			   IFNULL(T1."U_SDiscAmt",0.00) "SDiscAmt",
			   IFNULL(T1."U_LocaAmt",0.00) "LocaAmt",
			   IFNULL(T1."U_ExpsAmt",0.00) "ExpsAmt",
			   -(CASE WHEN T1."U_Realdisc" = '是' THEN IFNULL(T1."U_SDiscAmt",0.00) ELSE T1."LineTotal" END + t1."VatSum")+IFNULL(T1."U_SDiscAmt",0.00) "Revenues",
			   T0."Comments" ,
	           T20."ItmsGrpNam" ,T21."Name" "ItemClass1",T2."U_Class3" "ItemClass2",T2."U_ItemName" "ItemClass3",T2."U_AliasName" "ItemClass4",
			   T1."U_SlpName" "SlpName",T1."U_BusiUnit" "BusiUnit",T1."U_SaleUnit" "SaleUnit",
			   T31."Name" "SArea",T32."Name" "SDept",T33."Name" "SDimCd",T3."AddID" "SScale"--上级客户规模,徐浩3月12日更新
		FROM ORIN T0
		INNER JOIN RIN1 T1 ON T0."DocEntry" = T1."DocEntry"
		INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
		INNER JOIN OITB T20 ON T2."ItmsGrpCod" = T20."ItmsGrpCod"
		INNER JOIN OFPR T5 ON T0."DocDate" BETWEEN T5."F_RefDate" AND T5."T_RefDate" 
		INNER JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
		LEFT JOIN OCRD T30 ON T0."U_SubCardCd" = T30."CardCode"
		LEFT JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
	    LEFT JOIN OHEM T10 on t0."UserSign"=t10."userId"
	    LEFT JOIN "@U_SODIU" T11 ON T1."U_SUdDicTyp" = T11."Code"
		LEFT JOIN "@U_CITTY2" T21 ON  T2."U_Class2" = T21."Code"
		LEFT JOIN "@U_CBPTY4" T31 ON T3."U_CustClass4" = T31."Code"
		LEFT JOIN "@U_CBPTY5" T32 ON T3."U_CustClass5" = T32."Code"
		LEFT JOIN "@U_CBPTY6" T33 ON T3."U_CustClass6" = T33."Code"
		LEFT JOIN ( SELECT "U_ItemCode","U_ItemName","U_ActoPlant","U_Workshop" 
         			FROM "@U_PIT1" WHERE "Code" = :BPLId  ) T40 ON T1."ItemCode" = T40."U_ItemCode"
		LEFT JOIN OWHS T41 ON T1."WhsCode" = T41."WhsCode"
		WHERE T4."BPLId" = :BPLId
		  AND T5."Code" >= :Old_FcCode AND T5."Code" <= :Crt_FcCode
		  AND T0."CANCELED" <> 'Y'
		  AND T1."BaseType" <> 14 ;	 --不考虑取消单与抵消单	

 
 
 	--处理尾差
	CREATE LOCAL TEMPORARY TABLE #T1
 	("Id"		   INT,
     "Plant"       NVARCHAR(30),
     "DocType"     NVARCHAR(30),
     "FcCode"	   NVARCHAR(10),
     "DocNum"	   INT,
     "DocDate"     DATE,
     "GTSRegDate"  DATE,
     "GTSRegNum"   NVARCHAR(200),
     "GTSRegIdx"   NVARCHAR(200),
     "CardCode"    NVARCHAR(30),
     "CardName"    NVARCHAR(100),
     "SubCardCd"   NVARCHAR(30),
     "SubCardNm"   NVARCHAR(100),
     "ItmsGrpNam"  NVARCHAR(30), 
     "ItemCode"    NVARCHAR(30),
     "ItemName"    NVARCHAR(50),
     "InvntryUom"  NVARCHAR(30),
     "Quantity"    DECIMAL(19,6),
     "LineTotal"   DECIMAL(19,6),
     "GTotal"      DECIMAL(19,6),
     "Realdisc"    NVARCHAR(30),
     "MutDiscType" NVARCHAR(100),
     "SDiscAmt"    DECIMAL(19,6),
     "LocaAmt"     DECIMAL(19,6),
     "ExpsAmt"     DECIMAL(19,6),
     "Revenues"    DECIMAL(19,6),
     "SaleCost"    DECIMAL(19,6),
     "PLAmount"	   DECIMAL(19,6),
     "ItemClass1"  NVARCHAR(30),
     "ItemClass2"  NVARCHAR(30),
     "SlpName"     NVARCHAR(30),
     "BusiUnit"    NVARCHAR(30),
     "SaleUnit"    NVARCHAR(30),
     "SArea"       NVARCHAR(30),
     "SDept"	   NVARCHAR(30),
     "SDimCd"      NVARCHAR(30),
     "SScale"      NVARCHAR(30)
	);
	INSERT INTO #T1
 	SELECT ROW_NUMBER() OVER(PARTITION BY T0."Plant",T0."ItemCode",T0."FcCode" ORDER BY T0."Plant",T0."ItemCode",T0."FcCode",T0."Revenues" DESC) "序号",
 		   T0."Plant" "工厂代码",
 		   /*
 		   CASE WHEN T0."Plant" = 'W0000001' THEN N'膨化厂（上海）'
  				WHEN T0."Plant" = 'W0000002' THEN N'青浦厂（上海）'
  				WHEN T0."Plant" = 'W0000003' THEN N'松江厂（上海）'
  				WHEN T0."Plant" = 'W0000004' THEN N'香川厂'
  				WHEN T0."Plant" = 'WH300999' THEN N'武汉新农翔'
  				WHEN T0."Plant" = 'WZ400999' THEN N'新农（郑州）'
  				WHEN T0."Plant" = 'WF500999' THEN N'上海丰卉'
  				WHEN T0."Plant" = 'WC600999' THEN N'上海和畅'  END "工厂名称",*/
 		   T0."DocType" "单据类型",
 		   T0."FcCode" "期间",
 		   T0."DocNum" "单据号",
 		   T0."DocDate" "过账日期",
 		   T0."GTSRegDate" "开票日期",
 		   T0."GTSRegNum" "发票编号",
 		   T0."GTSRegIdx" "发票代号",
 		   T0."CardCode" "客户代码",
 		   T0."CardName" "客户名称",
 		   T0."SubCardCd" "下级客户",
 		   T0."SubCardNm" "下级客户名称",
 		   T0."ItmsGrpNam" "物料组",
 		   T0."ItemCode" "物料编码",
 		   T0."ItemName" "物料名称",
 		   T0."InvntryUom" "单位",
 		   T0."Quantity" "销量(KG)",
 		   T0."LineTotal" "不含税金额",
 		   T0."GTotal" "含税金额",
 		   T0."Realdisc" "是否赠料",
 		   T0."MutDiscType" "折扣名称",
 		   T0."SDiscAmt" "折扣额",
 		   T0."LocaAmt" "现金折扣额",
 		   T0."ExpsAmt" "现场运补额",
 		   T0."Revenues" "销售收入",
 		   --ROUND(T0."Quantity" * IFNULL(T1."Price",0) ,2) + IFNULL(T2."DisCostAmt",0) "销售成本",
 		   ROUND(T0."Quantity" * IFNULL(T1."Price",0) ,2)  "销售成本",
 		   T0."Revenues" - ROUND(T0."Quantity" * IFNULL(T1."Price",0) ,2) "毛利金额",
 		   T0."ItemClass1" "物料大类",
 		   T0."ItemClass2" "物料中类",
 		   T0."SlpName" "业务员",
 		   T0."BusiUnit" "区域经理",
 		   T0."SaleUnit" "经理主管",
 		   T0."SArea" "管理大区",
 		   T0."SDept" "销售单元",
 		   T0."SDimCd" "财务维度",
 		   T0."SScale" "客户养殖规模"
 	FROM :TEMP T0
 	LEFT JOIN U_COPCT T1 ON T1."ItemCode" = T0."ItemCode"
						AND T1."FcCode" = T0."FcCode"
						AND T1."BPLId" =:BPLId
						AND T1."PlantCode" = T0."Plant"
 	--LEFT JOIN :Allocate_Cost T2 ON T0."DocType" = T2."DocType" AND T0."DocNum" = T2."DocNum" AND T0."LineNum" = T2."LineNum"
 	WHERE 1 = 1
 	;
 	
 	--SELECT "PlantCode","ItemCode",SUM("FactAmount") FROM U_COIVL U0 
 	--WHERE U0."FcCode" = '2018-01' AND U0."BPLId" = 1 AND "BuzType" = 'SALEOUT' 
 	--GROUP BY "PlantCode","ItemCode";
 	
 	UPDATE T0
 		SET T0."SaleCost" = (SELECT SUM(U0."FactAmount") FROM U_COIVL U0 WHERE U0."FcCode"=T0."FcCode" AND U0."BPLId"=:BPLId AND U0."PlantCode"=T0."Plant" AND U0."ItemCode"=T0."ItemCode" AND U0."BuzType"='SALEOUT')
 						- IFNULL((SELECT SUM(U1."SaleCost") FROM #T1 U1 WHERE U1."Plant" = T0."Plant" AND U1."ItemCode" = T0."ItemCode" AND U1."FcCode"=T0."FcCode" AND U1."Id" <> 1),0)
 	FROM #T1 T0
 	WHERE T0."Id" = 1 ;	
 	
 	SELECT N'从'||:Old_FcCode||N' 至 '||:Crt_FcCode "查看期间",
 		   T0."Plant" "工厂代码",		   
 		   CASE WHEN T0."Plant" = 'W0000001' THEN N'膨化厂（上海）'
  				WHEN T0."Plant" = 'W0000002' THEN N'青浦厂（上海）'
  				WHEN T0."Plant" = 'W0000003' THEN N'松江厂（上海）'
  				WHEN T0."Plant" = 'W0000004' THEN N'香川厂'
  				WHEN T0."Plant" = 'WH300999' THEN N'武汉新农翔'
  				WHEN T0."Plant" = 'WZ400999' THEN N'新农（郑州）'
  				WHEN T0."Plant" = 'WF500999' THEN N'上海丰卉'
  				WHEN T0."Plant" = 'WC600999' THEN N'上海和畅'  END "工厂名称",
 		   T0."FcCode" "会计期间",
 		   T0."DocType" "单据类型",
 		   T0."DocNum" "单据号",
 		   T0."DocDate" "过账日期",
 		   T0."GTSRegDate" "开票日期",
 		   T0."GTSRegNum" "发票编号",
 		   T0."GTSRegIdx" "发票代号",
 		   T0."CardCode" "客户代码",
 		   T0."CardName" "客户名称",
 		   T0."SubCardCd" "下级客户",
 		   T0."SubCardNm" "下级客户名称",
 		   T0."ItmsGrpNam" "物料组",
 		   T0."ItemCode" "物料编码",
 		   T0."ItemName" "物料名称",
 		   T0."InvntryUom" "单位",
 		   T0."Quantity" "销量(KG)",
 		   T0."LineTotal" "不含税金额",
 		   T0."GTotal" "含税金额",
 		   T0."Realdisc" "是否赠料",
 		   T0."MutDiscType" "折扣名称",
 		   T0."SDiscAmt" "使用折扣额",
 		   T0."LocaAmt" "现金折扣额",
 		   T0."ExpsAmt" "现场运补额",
 		   T0."Revenues" "销售收入",
 		   T0."SaleCost" "销售成本",
 		   T0."PLAmount" "毛利金额",
 		   T0."ItemClass1" "物料大类",
 		   T0."ItemClass2" "物料中类",
 		   T0."SlpName" "业务员",
 		   T0."BusiUnit" "区域经理",
 		   T0."SaleUnit" "经理主管",
 		   T0."SArea" "管理大区",
 		   T0."SDept" "销售单元",
 		   T0."SDimCd" "财务维度",
 		   T0."SScale" "客户养殖规模",
 		   CASE WHEN T1."U_CustClass2" = '10' THEN N'经销商'
 		   		WHEN T1."U_CustClass2" = '11' THEN N'直销商'
 		   		WHEN T1."U_CustClass2" = '12' THEN N'猪场关联方'
 		   		WHEN T1."U_CustClass2" = '13' THEN N'武汉分公司'
 		   		WHEN T1."U_CustClass2" = '14' THEN N'郑州分公司' ELSE NULL END "客户分类二"
 	FROM #T1 T0
 	LEFT JOIN OCRD T1 ON T0."CardCode"=T1."CardCode"
 	WHERE 1=1
 	;
 	
 	DROP TABLE #T1;
	
END IF;
alter PROCEDURE "MTC_COST_95Report_ItemsCostDetail_06"
(
IN BPLId NVARCHAR(20),
IN FcCode NVARCHAR(20),
IN GroupCode NVARCHAR(20) DEFAULT ''
)
LANGUAGE SQLSCRIPT
AS
BEGIN 
	
	DECLARE USERCODE NVARCHAR(30); 
	DECLARE CNT INT; 
	DECLARE CNT1 INT; 
	DECLARE BOMVer NVARCHAR(1);
	DECLARE BDATE DATE;
	DECLARE EDATE DATE;
	DECLARE resultsql NVARCHAR(4000);
	
	
	SELECT "F_RefDate","T_RefDate" INTO BDATE,EDATE FROM OFPR WHERE "Code" = :FcCode ;
	
	COWOR_TEMP = 
		SELECT --T1."U_Approver" "审批人"*,T1."U_ApprvDate", "审核日期",
		   	   --CASE WHEN T1."U_Approved" = '1' THEN '已审核' ELSE NULL END "审核状态",
		       N'此表不包含PV1120的生产入库数据' "备注"
		      ,ROW_NUMBER()OVER(PARTITION BY "订单号" ORDER BY "数量" DESC) "Id"
		      ,(SELECT "Quantity" FROM U_COWOR U0 WHERE U0."DocType" = 'OWOR' AND U0."DocEntry" = T0."DocEntry" ) "SumPower"
		      ,(SELECT "FactAmount" FROM U_COWOR U0 WHERE U0."DocType" = 'OWOR' AND U0."DocEntry" = T0."DocEntry" ) "FactAmoiunt"
		   	  ,ROUND(IFNULL(T0."数量" / NULLIF((SELECT "Quantity" FROM U_COWOR U0 WHERE U0."DocType" = 'OWOR' AND U0."DocEntry" = T0."DocEntry"),0)
		   	  		    	    	  * IFNULL((SELECT "FactAmount" FROM U_COWOR U0 WHERE U0."DocType" = 'OWOR' AND U0."DocEntry" = T0."DocEntry"),0),0),2) "DisAmount"
		   	  ,T0.*
		FROM 
		   (
			--获取生产收货数据
			SELECT 
				   CASE WHEN T5."U_Approved" = '1' THEN '已审核' ELSE NULL END "审核状态",
				   T2."WhsName" "入库仓库",
				   T11."USER_CODE"||N' - '||CASE WHEN IFNULL(t10."lastName"||t10."firstName",T11."U_NAME") = 'manager' 
				   								   THEN '中控入库' 
				   								 ELSE IFNULL(t10."lastName"||t10."firstName",T11."U_NAME") END as "制单人"
				  ,t5."PostDate" as "订单日期",T5."DocNum" as "订单号",T5."DocEntry"
				  ,'生产收货' as "单据类型",T0."DocDate" "入库日期" ,T0."DocNum" "入库单号"
				  ,T1."ItemCode" "产品编码"
				  ,T3."U_OldItemCode" "旧系统物料编码"
				  ,T3."ItemName" "产品名称" 
				  ,t3."SalFactor1" as "规格",T3."InvntryUom" "主计量单位"
				  ,CASE WHEN t3."SalFactor1" = 1 THEN 0.00 ELSE t1."Quantity"/nullif(t3."SalFactor1",0) END as "件数"
				  ,T1."Quantity" "数量"
				  ,t6."Name" "大类",t3."U_Class3" as "中类",t3."U_AliasName" as "内部名称"  
				  ,T20."PrcName" "生产车间"			  
				  ,CASE WHEN T5."Status" = 'C' THEN N'已取消'
				  	    WHEN T5."Status" = 'P' THEN N'已计划' 
				  	    WHEN T5."Status" = 'R' THEN N'已下达' 
				  	    WHEN T5."Status" = 'L' THEN N'已结算' ELSE '其他' END "订单状态"
				  ,case t5."U_ProType" when 'S' then '标准生产'
			                     	   when 'T' then '回机生产'
			                     	   when 'P' then '换包生产' else '-' end as "工单类型"
				FROM OIGN T0
					JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry"
					JOIN OWHS T2 ON T2."WhsCode"=T1."WhsCode"
					JOIN OITM T3 ON T3."ItemCode"=T1."ItemCode"
					LEFT JOIN "@U_CIOTRN" T4 ON T4."Code"=T0."U_TrsName"
					left join ohem  t10 on t0."UserSign"=t10."userId"
					LEFT JOIN OUSR T11 ON t0."UserSign" = T11."USERID"
					left join OWOR t5 on t5."DocEntry" = T1."BaseEntry"
					left join "@U_CITTY2" t6 on t6."Code"=t3."U_Class2" 
					left join OPRC T20 ON T5."OcrCode2" = t20."PrcCode"
					LEFT JOIN OPRC T21 ON T5."OcrCode" = T21."PrcCode"
				WHERE (T1."BaseType"=202 AND "BaseLine" IS NULL)
				  AND T0."DocDate" BETWEEN BDATE AND EDATE
				  AND T0."BPLId"= :BPLId
			
				Union all
				select  
						CASE WHEN T2."U_Approved" = '1' THEN '已审核' ELSE NULL END "审核状态",
						T3."WhsName" "入库仓库",
					    T11."USER_CODE"||N' - '||CASE WHEN IFNULL(t10."lastName"||t10."firstName",T11."U_NAME") = 'manager' 
						   								THEN '中控入库' 
						   							  ELSE IFNULL(t10."lastName"||t10."firstName",T11."U_NAME") END as "制单人"
					   ,t2."PostDate" as "订单日期",T2."DocNum" as "生产订单",T2."DocEntry"
					   ,'库存-发货（调减入库数）' as "单据类型",T1."DocDate" "单据日期" ,T1."DocNum" "单据号"
					   ,t0."ItemCode" as "产品编码"
					   ,T4."U_OldItemCode" "旧系统物料编码"
					   ,t4."ItemName" as "产品名称" 
					   ,t4."SalFactor1" as "规格",T4."InvntryUom" "主计量单位"
					   ,- CASE WHEN t4."SalFactor1" = 1 THEN 0.00 ELSE t0."Quantity"/nullif(t4."SalFactor1",0) END as "件数"
					   ,- t0."Quantity" as "数量"
					   ,t5."Name" "大类",t4."U_Class3" as "中类",t4."U_AliasName" as "内部名称"			   
					   ,T20."PrcName" "车间"
					   ,CASE WHEN T2."Status" = 'C' THEN N'已取消'
					  	     WHEN T2."Status" = 'P' THEN N'已计划' 
					  	     WHEN T2."Status" = 'R' THEN N'已下达' 
					  	     WHEN T2."Status" = 'L' THEN N'已结算' ELSE '其他' END "订单状态",
					    case t2."U_ProType" when 'S' then '标准生产'
				                     	    when 'T' then '回机生产'
				                     	    when 'P' then '换包生产' else '-' end as "工单类型"		   
				from IGE1 t0 
					inner join OIGE t1 on t0."DocEntry" = t1."DocEntry"
					left join OWOR t2 on t2."DocNum" = t1."U_SrcNum"
					left join OWHS t3 on t3."WhsCode" = t0."WhsCode"
					left join OITM t4 on t4."ItemCode" = t0."ItemCode"
					left join ohem  t10 on t1."UserSign"=t10."userId"
					LEFT JOIN OUSR T11 ON t1."UserSign" = T11."USERID"
					left join "@U_CITTY2" t5 on t5."Code"=t4."U_Class2"
					left join OPRC T20 ON T2."OcrCode2" = t20."PrcCode"
					LEFT JOIN OPRC T21 ON T2."OcrCode" = T21."PrcCode"
				where t0."BaseType" = '-1' and t1."U_TrsName" = '302' 
				  AND T1."DocDate" BETWEEN BDATE AND EDATE
				  AND T1."BPLId"= :BPLId
			
				Union all
				select  
						CASE WHEN T2."U_Approved" = '1' THEN '已审核' ELSE NULL END "审核状态",
						T3."WhsName" "入库仓库",
					    T11."USER_CODE"||N' - '||CASE WHEN IFNULL(t10."lastName"||t10."firstName",T11."U_NAME") = 'manager' 
						   								THEN '中控入库' 
						   							  ELSE IFNULL(t10."lastName"||t10."firstName",T11."U_NAME") END as "制单人"
					   ,t2."PostDate" as "订单日期",T2."DocNum" as "生产订单",T2."DocEntry"
					   ,'库存-收货（调增入库数）' as "单据类型",T1."DocDate" "单据日期" ,T1."DocNum" "单据号"
					   ,t0."ItemCode" as "产品编码"
					   ,T4."U_OldItemCode" "旧系统物料编码"
					   ,t4."ItemName" as "产品名称" 
					   ,t4."SalFactor1" as "规格",T4."InvntryUom" "主计量单位"
					   ,CASE WHEN t4."SalFactor1" = 1 THEN 0.00 ELSE t0."Quantity"/nullif(t4."SalFactor1",0) END as "件数" 
					   ,t0."Quantity" as "数量"
					   ,t5."Name" "大类",t4."U_Class3" as "中类",t4."U_AliasName" as "内部名称"			   
					   ,T20."PrcName" "车间"
					   ,CASE WHEN T2."Status" = 'C' THEN N'已取消'
					  	     WHEN T2."Status" = 'P' THEN N'已计划' 
					  	     WHEN T2."Status" = 'R' THEN N'已下达' 
					  	     WHEN T2."Status" = 'L' THEN N'已结算' ELSE '其他' END "订单状态"
					   ,case t2."U_ProType" when 'S' then '标准生产'
				                     	    when 'T' then '回机生产'
				                     	    when 'P' then '换包生产' else '-' end as "工单类型"
				from IGN1 t0 inner join OIGN t1 on t0."DocEntry" = t1."DocEntry"
					left join OWOR t2 on t2."DocNum" = t1."U_SrcNum"
					left join OWHS t3 on t3."WhsCode" = t0."WhsCode"
					left join OITM t4 on t4."ItemCode" = t0."ItemCode"
					left join ohem  t10 on t1."UserSign"=t10."userId"
					LEFT JOIN OUSR T11 ON t1."UserSign" = T11."USERID"
					left join "@U_CITTY2" t5 on t5."Code"=t4."U_Class2"
					left join OPRC T20 ON T2."OcrCode2" = t20."PrcCode"
					LEFT JOIN OPRC T21 ON T2."OcrCode" = T21."PrcCode"
				where t0."BaseType" = '-1' and t1."U_TrsName" = '302' 
				  AND T1."DocDate" BETWEEN BDATE AND EDATE
				  AND T1."BPLId"= :BPLId
				) T0
		WHERE  1 = 1
		  AND T0."产品编码" <> '15010023'
		--ORDER BY T0."订单号"
		;
		
CREATE LOCAL TEMPORARY TABLE #T1
	(
     "U_Approved"     NVARCHAR(30),--审核状态
	 "WhsName"	 NVARCHAR(100),----入库仓库
     "USER_CODE"    NVARCHAR(100),---制单人
     "DocDate"     DATE,---订单日期
     "DocNum"	   INT,----订单号
	 "DocEntry"     INT,---DocEntry
     "DocType"    NVARCHAR(30),---单据类型
     "INDocDate"     DATE,---入库日期
	 "INDocNum"	   INT,----入库单号
 	 "ItemCode"    NVARCHAR(30),---产品编码
	 "U_OldItemCode" NVARCHAR(30), ---旧系统物料编码
	 "ItemName"    NVARCHAR(50),---产品名称
	 "SalFactor1"  NVARCHAR(30),---规格
	 "InvntryUom"    NVARCHAR(30),---主计量单位
	 "SalFactor2"  NVARCHAR(30),---件数
     "Quantity"    DECIMAL(19,6),---收货数量
	 "DisAmount"		DECIMAL(19,6),---金额
     "Name"  NVARCHAR(300), ---物料大类
	 "U_Class3"   NVARCHAR(200),--物料中类
     "U_AliasName"   NVARCHAR(300),---内部名称
     "PrcName"   NVARCHAR(100),--生产车间
	 "Status"       NVARCHAR(30),--订单状态
     "U_ProType"   NVARCHAR(200)--工单类型
	);
	
	
	INSERT INTO #T1
SELECT
		TT1."审核状态" "审核状态"
		,TT1."入库仓库" "入库仓库"
		,TT1."制单人" "制单人"
		,TT1."订单日期" "订单日期"
		,TT1."订单号" "订单号"
		,TT1."DocEntry" "DocEntry"
		,TT1."单据类型" "单据类型"
		,TT1."入库日期" "入库日期"
		,TT1."入库单号" "入库单号"
		,TT1."产品编码" "产品编码"
		,TT1."旧系统物料编码" "旧系统物料编码"
		,TT1."产品名称" "产品名称"
		,TT1."规格" "规格"
		,TT1."主计量单位" "主计量单位"
		,TT1."件数" "件数"
		,TT1."SumPower" "收货数量"
		,TT1."DisAmount" "金额"
		,TT1."大类" "物料大类"
		,TT1."中类" "物料中类"
		,TT1."内部名称" "内部名称"
		,TT1."生产车间" "生产车间"
		,TT1."订单状态" "订单状态"
		,TT1."工单类型" "工单类型"
FROM :COWOR_TEMP TT1;


 if :GroupCode='' then 
	SELECT T0."U_Approved" "审核状态"
			   ,T0."WhsName" "入库仓库"
			   ,T0."USER_CODE" "制单人"
			   ,T0."DocDate" "订单日期"
			   ,T0."DocNum" "订单号"
			   ,T0."DocType" "单据类型",T0."INDocDate" "入库日期",T0."INDocNum" "入库单号"
			   ,T0."ItemCode" "产品编码"
			   ,T0."U_OldItemCode" "旧系统物料编码"
			   ,T0."ItemName" "产品名称"
			   ,T0."SalFactor1" "规格",T0."InvntryUom" "主计量单位"
			   ,T0."SalFactor2" "件数"
			   ,T0."Quantity" "数量"
			   ,T0."DisAmount" "金额"
			  --- ,CASE WHEN T0."Id" = 1 THEN T1."FactAmount"-IFNULL((SELECT SUM(U0."DisAmount") FROM :COWOR_TEMP U0 WHERE U0."DocEntry"=T0."DocEntry" AND U0."Id"<>1),0) ELSE T0."DisAmount" END "金额"
			   ,T0."Name" "物料大类",T0."U_Class3" "物料种类",T0."U_AliasName" "内部名称"  
			   ,T0."PrcName" "生产车间"	  
		 	   ,T0."Status" "订单状态"
			   ,T0."U_ProType" "工单类型"
	FROM #T1 T0
	INNER JOIN U_COWOR T1 ON T0."DocEntry" = T1."DocEntry" AND T1."DocType" = 'OWOR'
	WHERE 1=1;
else 
	resultsql:=
	'select
	"审核状态",
	"入库仓库",
	"制单人",
	"订单日期",
	"订单号",
	"单据类型",
	"入库日期",
	"入库单号",
	"产品编码",
	"旧系统物料编码",
	"产品名称",
	"规格",
	"主计量单位",
	"件数",
	sum("数量") "数量",
	sum("金额") "金额",
	"内部名称",
	"生产车间",
	"订单状态",
	"工单类型"
	from
		(SELECT T0."U_Approved" "审核状态"
			   ,T0."WhsName" "入库仓库"
			   ,T0."USER_CODE" "制单人"
			   ,T0."DocDate" "订单日期"
			   ,T0."DocNum" "订单号"
			   ,T0."DocType" "单据类型",T0."INDocDate" "入库日期",T0."INDocNum" "入库单号"
			   ,T0."ItemCode" "产品编码"
			   ,T0."U_OldItemCode" "旧系统物料编码"
			   ,T0."ItemName" "产品名称"
			   ,T0."SalFactor1" "规格",T0."InvntryUom" "主计量单位"
			   ,T0."SalFactor2" "件数"
			   ,T0."Quantity" "数量"
			   ,T0."DisAmount" "金额"
			  --- ,CASE WHEN T0."Id" = 1 THEN T1."FactAmount"-IFNULL((SELECT SUM(U0."DisAmount") FROM :COWOR_TEMP U0 WHERE U0."DocEntry"=T0."DocEntry" AND U0."Id"<>1),0) ELSE T0."DisAmount" END "金额"
			   ,T0."Name" "物料大类",T0."U_Class3" "物料种类",T0."U_AliasName" "内部名称"  
			   ,T0."PrcName" "生产车间"	  
		 	   ,T0."Status" "订单状态"
			   ,T0."U_ProType" "工单类型"
		FROM #T1 T0
		INNER JOIN U_COWOR T1 ON T0."DocEntry" = T1."DocEntry" AND T1."DocType" = ''OWOR''
		WHERE 1=1
		)
GROUP BY GROUPING SETS(
	(
	"审核状态",
	"入库仓库",
	"制单人",
	"订单日期",
	"订单号",
	"单据类型",
	"入库日期",
	"入库单号",
	"产品编码",
	"旧系统物料编码",
	"产品名称",
	"规格",
	"主计量单位",
	"件数",
	"内部名称",
	"生产车间",
	"订单状态",
	"工单类型"
	),"'||:GroupCode||'",NULL)
ORDER BY "'||:GroupCode||'" ASC NULLS LAST,"订单号" ASC NULLS LAST ';
 	EXECUTE IMMEDIATE :resultsql;
 	END IF;
	DROP TABLE #T1;
END;
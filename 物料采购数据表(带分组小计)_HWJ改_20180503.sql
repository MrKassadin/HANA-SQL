alter PROCEDURE "MTC_COST_95Report_ItemPurChsInDetail_01"
(
IN BPLId NVARCHAR(20),
IN FcCode NVARCHAR(20),
IN GroupCode NVARCHAR(20) DEFAULT ''
)
LANGUAGE SQLSCRIPT
AS
BEGIN
    DECLARE CNT INTEGER;
    DECLARE BPLName NVARCHAR(100);
    DECLARE BeginDate DATE;
    DECLARE ENDDate DATE;
    DECLARE resultsql NVARCHAR(5000);
    
   
    SELECT T0."F_RefDate" , T0."T_RefDate" INTO BeginDate,ENDDate FROM OFPR T0 WHERE T0."Code"= :FcCode; 
	if :GroupCode='' then
	SELECT	
	T0."PlantCode" "工厂代码",
		   CASE WHEN T0."PlantCode" = 'W0000001' THEN N'膨化厂（上海）'
  				WHEN T0."PlantCode" = 'W0000002' THEN N'青浦厂（上海）'
  				WHEN T0."PlantCode" = 'W0000003' THEN N'松江厂（上海）'
  				WHEN T0."PlantCode" = 'W0000004' THEN N'香川厂'
  				WHEN T0."PlantCode" = 'WH300999' THEN N'武汉新农翔'
  				WHEN T0."PlantCode" = 'WZ400999' THEN N'新农（郑州）'
  				WHEN T0."PlantCode" = 'WF500999' THEN N'上海丰卉'
  				WHEN T0."PlantCode" = 'WC600999' THEN N'上海和畅' ELSE ''  END "工厂名称",
		  T1."Name" "类型",
		  T0."DocDate" "日期",
		  T0."BASE_REF" "单据号",
		  T0."ItemCode" "物料编码",
		  T0."ItemName" "物料名称",
		  T0."InQty"-T0."OutQty" "入库数量",
		  T0."SumStock"+T0."VarVal"+T0."PriceDiff" "成本金额",
		  T0."LocCode" "仓库代码",
		  T2."WhsName" "仓库名称"
	FROM U_COIVL T0
	INNER JOIN OWHS T2 ON T0."LocCode" = T2."WhsCode"
	LEFT JOIN "@U_AOBJL" T1 ON T0."TransType" = T1."Code"
	WHERE T0."FcCode" =:FcCode  AND T0."BPLId" = :BPLId
	  AND T0."TransType" IN(18,19,20,21,69,162)
	  AND (T0."InQty"-T0."OutQty") + (T0."SumStock"+T0."VarVal"+T0."PriceDiff") <> 0
	ORDER BY T0."PlantCode",T0."DocDate",T0."ItemCode";

else	
	resultsql:=
	'SELECT 
	"工厂代码",
	"工厂名称",
	"类型",
	"日期",
	"单据号",
	"物料编码",
	"物料名称",
	SUM("入库数量") "入库数量",
	SUM("成本金额") "成本金额",
	"仓库代码",
	"仓库名称"
	FROM
 	(SELECT	
	T0."PlantCode" "工厂代码",
		   CASE WHEN T0."PlantCode" = ''W0000001'' THEN N''膨化厂（上海）''
  				WHEN T0."PlantCode" = ''W0000002'' THEN N''青浦厂（上海）''
  				WHEN T0."PlantCode" = ''W0000003'' THEN N''松江厂（上海）''
  				WHEN T0."PlantCode" = ''W0000004'' THEN N''香川厂''
  				WHEN T0."PlantCode" = ''WH300999'' THEN N''武汉新农翔''
  				WHEN T0."PlantCode" = ''WZ400999'' THEN N''新农（郑州）''
  				WHEN T0."PlantCode" = ''WF500999'' THEN N''上海丰卉''
  				WHEN T0."PlantCode" = ''WC600999'' THEN N''上海和畅'' ELSE ''''  END "工厂名称",
		  T1."Name" "类型",
		  T0."DocDate" "日期",
		  T0."BASE_REF" "单据号",
		  T0."ItemCode" "物料编码",
		  T0."ItemName" "物料名称",
		  T0."InQty"-T0."OutQty" "入库数量",
		  T0."SumStock"+T0."VarVal"+T0."PriceDiff" "成本金额",
		  T0."LocCode" "仓库代码",
		  T2."WhsName" "仓库名称"
	FROM U_COIVL T0
	INNER JOIN OWHS T2 ON T0."LocCode" = T2."WhsCode"
	LEFT JOIN "@U_AOBJL" T1 ON T0."TransType" = T1."Code"
	WHERE T0."FcCode" ='''||:FcCode||'''  AND T0."BPLId" = '||:BPLId||'
	  AND T0."TransType" IN(18,19,20,21,69,162)
	  AND (T0."InQty"-T0."OutQty") + (T0."SumStock"+T0."VarVal"+T0."PriceDiff") <> 0
	ORDER BY T0."PlantCode",T0."DocDate",T0."ItemCode")
	GROUP BY GROUPING SETS((
	"工厂代码",
	"工厂名称",
	"类型",
	"日期",
	"单据号",
	"物料编码",
	"物料名称",
	"入库数量",
	"成本金额",
	"仓库代码",
	"仓库名称"
	),"'||:GroupCode||'", null
	) ORDER BY  "'||:GroupCode||'" ASC nulls last,"仓库名称" desc, "日期" ASC ' ;
	EXECUTE IMMEDIATE :resultsql;
	end if;
	end
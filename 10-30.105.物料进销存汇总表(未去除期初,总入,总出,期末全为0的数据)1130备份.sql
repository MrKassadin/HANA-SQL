/*SELECT FROM OBPL T2 WHERE T2."BPLName"=[%2];*/ 
/*SELECT FROM "OFPR" T0 WHERE T0."F_RefDate" >=[%0];*/ 
/*SELECT FROM "OFPR" T1 WHERE T1."T_RefDate" <=[%1];*/ 
/*SELECT FROM OWHS T4 WHERE T4."WhsName" LIKE '%[%4]%';*/
/*SELECT FROM "OITM" T5 WHERE T5."ItemName" LIKE '%[%5]%';*/
/*SELECT FROM "@U_COUQR" T6 WHERE T6."U_MrgType" = '[%6]';*/

DECLARE USERCODE NVARCHAR(30); 
DECLARE CNT INT; 
DECLARE CNT1 INT; 
DECLARE SDATE DATE;
DECLARE EDATE DATE;
DECLARE BPLID INT;
DECLARE MrgType nvarchar(1);
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%2]';
SELECT "BPLId" INTO BPLID FROM OBPL WHERE "BPLName"='[%2]';
SDATE:=[%0];
EDATE:=[%1];
MrgType:='[%6]';

IF :CNT = 0 THEN
  SELECT '没有当前所选分支的权限！' "提示" FROM DUMMY;	 --判断用户是否有权限查看
ELSE 
  
  CNT := 0 ;
  SELECT COUNT(1) INTO CNT 
  FROM "@U_PIT1" T0
  LEFT JOIN "@U_PIT1" T1 ON T0."Code" = T1."Code" AND T1."LineId" <> T0."LineId"
  WHERE T0."Code" = :BPLId AND T0."U_ItemCode" = T1."U_ItemCode" ;
  IF :CNT > 0 THEN
  	SELECT N'物料：'||T0."U_ItemCode"||N' - '||T0."U_ItemName"||N'在《工厂产品对应表》中出现维护重复，请在此表保持唯一存在' "错误提示"  
  	FROM "@U_PIT1" T0
  	LEFT JOIN "@U_PIT1" T1 ON T0."Code" = T1."Code" AND T1."LineId" <> T0."LineId"
  	WHERE T0."Code" = :BPLId AND T0."U_ItemCode" = T1."U_ItemCode" ;
  	RETURN;
  END IF;
  
  TEMP = 	
	SELECT
	     T50."BPLName",T0."DocDate",RIGHT(N'0000'||to_nvarchar(T0."CreateTime"),4) "CreateTime",
		 T0."TransType" "ObjType"
		,CASE WHEN T4."U_ItemGrpType" IN ('A') THEN IFNULL(T142."U_Workshop",'') ELSE T140."U_Workshop" END "Plant"
		,T0."LocCode" "WhsCode",T5."WhsName"
		,T0."BASE_REF",T0."DocLineNum"+1 "DocLineNum"
		,IFNULL(T17."U_TrsName",T18."U_TrsName") "TrsName" 
		,IFNULL(T7."BaseType",T8."BaseType") "BaseType" 
		,IFNULL(T7."BaseLine",T8."BaseLine") "BaseLine" 
		,T1."ItemCode"
		,CASE WHEN T121."CANCELED" = 'Y' OR T120."BaseType" = '0' OR	--剔除转储取消单与抵消单
				   T31."CANCELED" = 'Y' OR T30."BaseType" = '20' OR		--剔除采购入库取消单与抵消单
				   T41."CANCELED" = 'Y' OR T40."BaseType" = '21' OR		--剔除采购退货取消单与抵消单
				   T61."CANCELED" = 'Y' OR T60."BaseType" = '15' OR		--剔除销售出库取消单与抵消单
				   T71."CANCELED" = 'Y' OR T70."BaseType" = '16' OR		--剔除销售退货取消单与抵消单
				   T81."CANCELED" = 'Y' OR T80."BaseType" = '14' OR		--剔除应收贷项取消单与抵消单
				   T91."CANCELED" = 'Y' OR T90."BaseType" = '13' OR		--剔除应收发票取消单与抵消单
				   T101."CANCELED" = 'Y' OR T100."BaseType" = '19' OR	--剔除应付贷项取消单与抵消单
				   T111."CANCELED" = 'Y' OR T110."BaseType" = '18' 		--剔除应付发票取消单与抵消单
			  THEN 0 ELSE T0."InQty" END "InQty"
		,CASE WHEN T121."CANCELED" = 'Y' OR T120."BaseType" = '0' OR	--剔除转储取消单与抵消单
				   T31."CANCELED" = 'Y' OR T30."BaseType" = '20' OR		--剔除采购入库取消单与抵消单
				   T41."CANCELED" = 'Y' OR T40."BaseType" = '21' OR		--剔除采购退货取消单与抵消单
				   T61."CANCELED" = 'Y' OR T60."BaseType" = '15' OR		--剔除销售出库取消单与抵消单
				   T71."CANCELED" = 'Y' OR T70."BaseType" = '16' OR		--剔除销售退货取消单与抵消单
				   T81."CANCELED" = 'Y' OR T80."BaseType" = '14' OR		--剔除应收贷项取消单与抵消单
				   T91."CANCELED" = 'Y' OR T90."BaseType" = '13' OR		--剔除应收发票取消单与抵消单
				   T101."CANCELED" = 'Y' OR T100."BaseType" = '19' OR	--剔除应付贷项取消单与抵消单
				   T111."CANCELED" = 'Y' OR T110."BaseType" = '18' 		--剔除应付发票取消单与抵消单
			  THEN 0 ELSE T0."OutQty" END "OutQty"
		,CASE WHEN T121."CANCELED" = 'Y' OR T120."BaseType" = '0' OR	--剔除转储取消单与抵消单
				   T31."CANCELED" = 'Y' OR T30."BaseType" = '20' OR		--剔除采购入库取消单与抵消单
				   T41."CANCELED" = 'Y' OR T40."BaseType" = '21' OR		--剔除采购退货取消单与抵消单
				   T61."CANCELED" = 'Y' OR T60."BaseType" = '15' OR		--剔除销售出库取消单与抵消单
				   T71."CANCELED" = 'Y' OR T70."BaseType" = '16' OR		--剔除销售退货取消单与抵消单
				   T81."CANCELED" = 'Y' OR T80."BaseType" = '14' OR		--剔除应收贷项取消单与抵消单
				   T91."CANCELED" = 'Y' OR T90."BaseType" = '13' OR		--剔除应收发票取消单与抵消单
				   T101."CANCELED" = 'Y' OR T100."BaseType" = '19' OR	--剔除应付贷项取消单与抵消单
				   T111."CANCELED" = 'Y' OR T110."BaseType" = '18' 		--剔除应付发票取消单与抵消单
			  THEN 0 ELSE T0."InQty" END
	-	 CASE WHEN T121."CANCELED" = 'Y' OR T120."BaseType" = '0' OR	--剔除转储取消单与抵消单
				   T31."CANCELED" = 'Y' OR T30."BaseType" = '20' OR		--剔除采购入库取消单与抵消单
				   T41."CANCELED" = 'Y' OR T40."BaseType" = '21' OR		--剔除采购退货取消单与抵消单
				   T61."CANCELED" = 'Y' OR T60."BaseType" = '15' OR		--剔除销售出库取消单与抵消单
				   T71."CANCELED" = 'Y' OR T70."BaseType" = '16' OR		--剔除销售退货取消单与抵消单
				   T81."CANCELED" = 'Y' OR T80."BaseType" = '14' OR		--剔除应收贷项取消单与抵消单
				   T91."CANCELED" = 'Y' OR T90."BaseType" = '13' OR		--剔除应收发票取消单与抵消单
				   T101."CANCELED" = 'Y' OR T100."BaseType" = '19' OR	--剔除应付贷项取消单与抵消单
				   T111."CANCELED" = 'Y' OR T110."BaseType" = '18' 		--剔除应付发票取消单与抵消单
			  THEN 0 ELSE T0."OutQty" END  "EndQty"
		,T2."Name" "Class2"
		,T1."U_Class3" "Class3"
		,T4."ItmsGrpNam" "Class4"
		,TO_NVARCHAR(t12."USER_CODE")||N' - '||T12."U_NAME" "UserCode"
	FROM OIVL T0
	INNER JOIN OITM T1 ON T0."ItemCode"=T1."ItemCode"
	LEFT JOIN "@U_CITTY2" T2 ON T2."Code"=T1."U_Class2"
	LEFT JOIN OITB T4 ON T4."ItmsGrpCod"=T1."ItmsGrpCod"
	INNER JOIN OWHS T5 ON T5."WhsCode"=T0."LocCode"
	INNER JOIN OBPL T50 ON T5."BPLid" = t50."BPLId"
	LEFT JOIN "@U_AOBJL" T6 ON T6."Code"=T0."TransType"
	LEFT JOIN IGN1 T7 ON T7."ObjType"=T0."TransType" AND T7."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T7."LineNum"
	LEFT JOIN OIGN T17 ON T17."DocEntry"=T7."DocEntry"
	LEFT JOIN IGE1 T8 ON T8."ObjType"=T0."TransType" AND T8."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T8."LineNum"
	LEFT JOIN OIGE T18 ON T18."DocEntry"=T8."DocEntry"
	LEFT JOIN "@U_CIOTRN" T9 ON T9."Code"=IFNULL(T17."U_TrsName",T18."U_TrsName")
	LEFT JOIN PDN1 T30 ON T30."ObjType"=T0."TransType" AND T30."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T30."LineNum"
	LEFT JOIN OPDN T31 ON T30."DocEntry"=T31."DocEntry"
	LEFT JOIN RPD1 T40 ON T40."ObjType"=T0."TransType" AND T40."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T40."LineNum"
	LEFT JOIN ORPD T41 ON T40."DocEntry"=T41."DocEntry"
	LEFT JOIN DLN1 T60 ON T60."ObjType"=T0."TransType" AND T60."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T60."LineNum"
	LEFT JOIN ODLN T61 ON T60."DocEntry"=T61."DocEntry"
	LEFT JOIN RDN1 T70 ON T70."ObjType"=T0."TransType" AND T70."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T70."LineNum"
	LEFT JOIN ORDN T71 ON T70."DocEntry"=T71."DocEntry"
	LEFT JOIN RIN1 T80 ON T80."ObjType"=T0."TransType" AND T80."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T80."LineNum"
	LEFT JOIN ORIN T81 ON T80."DocEntry"=T81."DocEntry"
	LEFT JOIN INV1 T90 ON T90."ObjType"=T0."TransType" AND T90."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T90."LineNum"
	LEFT JOIN OINV T91 ON T90."DocEntry"=T91."DocEntry"
	LEFT JOIN RPC1 T100 ON T100."ObjType"=T0."TransType" AND T100."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T100."LineNum"
	LEFT JOIN ORPC T101 ON T100."DocEntry"=T101."DocEntry"
	LEFT JOIN PCH1 T110 ON T110."ObjType"=T0."TransType" AND T110."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T110."LineNum"
	LEFT JOIN OPCH T111 ON T110."DocEntry"=T111."DocEntry"
	LEFT JOIN WTR1 T120 ON T120."ObjType"=T0."TransType" AND T120."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T120."LineNum"
	LEFT JOIN OWTR T121 ON T120."DocEntry"=T121."DocEntry"
	LEFT JOIN "@U_CIOTRN" T19 ON T19."Code" = T121."U_TrsName"
	LEFT JOIN OILM T130 ON T0."MessageID" = T130."MessageID"  --倒冲
	LEFT JOIN OWOR T131 ON T130."AppObjAbs" = T131."DocEntry" AND T130."ApplObj" = '202' 
	LEFT JOIN OWHS T140 ON T0."LocCode" = T140."WhsCode" 
	LEFT JOIN ( SELECT DISTINCT "Code","U_ItemCode","U_ActoPlant" ,"U_Workshop"
				FROM "@U_PIT1" ) T142 ON T0."ItemCode" = T142."U_ItemCode" AND T142."Code" = :BPLId
	LEFT JOIN OFPR T10 ON T0."DocDate" BETWEEN T10."F_RefDate" AND T10."T_RefDate"
	LEFT JOIN OUSR T12 ON T0."UserSign" = t12."USERID"
	WHERE T5."BPLid"= :BPLId
	  AND ( T0."InQty" - T0."OutQty" ) <> 0
	  AND T0."DocDate" <= :EDATE
	  AND ( T5."WhsName" LIKE '%[%4]%' OR '[%4]' = '' OR '[%4]' IS NULL ) 
	  AND ( T1."ItemName" LIKE '%[%5]%' OR '[%5]' = '' OR '[%5]' IS NULL )
	ORDER BY T0."DocDate",t6."Name",T0."BASE_REF";
  
    --查看 :TEMP 与  OIVL表返回行数
    --SELECT * FROM OIVL T0 JOIN OWHS T1 ON T0."LocCode" = T1."WhsCode" where T1."BPLid" = 1 and (T0."InQty"<>0 OR T0."OutQty"<>0) ;
  
    --判断物料是否对应工厂
    SELECT COUNT(1) INTO CNT1 
    FROM :TEMP T0 
    WHERE IFNULL(T0."Plant",'') = '';
    IF :CNT1 > 0 THEN
  	  SELECT DISTINCT 
  	  		N'请检查 <'
  	   		  ||T0."ItemCode"
  	   		  ||'> 若为原料 或 包材，则该行的'||T0."WhsCode"
  	          ||N'是否已指定归属车间；若为成品 或 半成品，则请先在《工厂产品对应表》中进行维护！' "错误提示"
  	  FROM :TEMP T0 WHERE IFNULL(T0."Plant",'') = '';
  	  RETURN;
    END IF ;
  
  IF ( :MrgType = 'N' OR :MrgType = '' ) THEN
    SELECT T0."Plant"||N' - '||CASE WHEN T0."Plant" = 'W0000001' THEN N'膨化厂（上海）'
    	  						    WHEN T0."Plant" = 'W0000002' THEN N'青浦厂（上海）'
    	  						    WHEN T0."Plant" = 'W0000003' THEN N'松江厂（上海）'
    	  						    WHEN T0."Plant" = 'W0000004' THEN N'香川厂'
    	  						    WHEN T0."Plant" = 'WH300999' THEN N'武汉新农翔'
    	  						    WHEN T0."Plant" = 'WZ400999' THEN N'新农（郑州）'
    	  						    WHEN T0."Plant" = 'WF500999' THEN N'上海丰卉'
    	  						    WHEN T0."Plant" = 'WC600999' THEN N'上海和畅'  END "工厂"
    	  ,T4."Code"||N' - '||T4."Name" "大类"
    	  ,T1."U_Class3" "中类"
    	  ,T1."U_AliasName"  "内部名称"
    	  ,T0."WhsCode"||N' - '||T2."WhsName" "仓库"
    	  ,T0."ItemCode" "物料"
    	  ,T1."ItemName" "名称"
    	   ,SUM(CASE WHEN T0."DocDate" < :SDATE THEN T0."EndQty" ELSE 0 END ) "期初数量"
    	  
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(18,19,20,21,162,69) THEN T0."EndQty" ELSE 0 END )
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('302'))) THEN T0."EndQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('602') THEN T0."EndQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."InQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."InQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."InQty" ELSE 0 END ) "总入库_数量"
    	  
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NOT NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('301','303','304','305','306','307'))) THEN T0."EndQty" ELSE 0 END ) 
    	  - SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('601') THEN T0."EndQty" ELSE 0 END )
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."OutQty" ELSE 0 END )
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."OutQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."OutQty" ELSE 0 END ) 
    	  - SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(13,14,15,16) THEN T0."EndQty" ELSE 0 END ) "总出库_数量"
    	  
    	  ,SUM(CASE WHEN T0."DocDate" <= :EDATE THEN T0."EndQty" ELSE 0 END ) "期末数量"
    	  
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(18,19,20,21,162,69) THEN T0."EndQty" ELSE 0 END ) "采购入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('302'))) THEN T0."EndQty" ELSE 0 END ) "生产入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('602') THEN T0."EndQty" ELSE 0 END ) "工厂调入数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."InQty" ELSE 0 END ) "代码转换入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."InQty" ELSE 0 END ) "库存转储入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."InQty" ELSE 0 END ) "库存收货数量"
    	  
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NOT NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('301','303','304','305','306','307'))) THEN T0."EndQty" ELSE 0 END ) "生产发料数量"
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('601') THEN T0."EndQty" ELSE 0 END ) "工厂调出数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."OutQty" ELSE 0 END ) "代码转换出库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."OutQty" ELSE 0 END ) "库存转储出库数量"	  
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."OutQty" ELSE 0 END ) "库存发货数量"
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(13,14,15,16) THEN T0."EndQty" ELSE 0 END ) "销售出库数量"

    FROM :TEMP T0
     INNER JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
     INNER JOIN OWHS T2 ON T0."WhsCode" = T2."WhsCode"
     LEFT JOIN "@U_CITTY2" T4 ON T1."U_Class2" = T4."Code"
    WHERE T0."DocDate" <= :EDATE
    GROUP BY T4."Code",T4."Name",T1."U_Class3",T1."U_AliasName",T0."Plant",T0."WhsCode",T2."WhsName",T0."ItemCode",T1."ItemName"
    ORDER BY T4."Code" DESC,T0."Plant",T0."WhsCode",T0."ItemCode" ;
  
  ELSE
    SELECT N'合并：按工厂查看' "合并仓库"
    	  ,T0."Plant"||N' - '||CASE WHEN T0."Plant" = 'W0000001' THEN N'膨化厂（上海）'
    	  						    WHEN T0."Plant" = 'W0000002' THEN N'青浦厂（上海）'
    	  						    WHEN T0."Plant" = 'W0000003' THEN N'松江厂（上海）'
    	  						    WHEN T0."Plant" = 'W0000004' THEN N'香川厂'
    	  						    WHEN T0."Plant" = 'WH300999' THEN N'武汉新农翔'
    	  						    WHEN T0."Plant" = 'WZ400999' THEN N'新农（郑州）'
    	  						    WHEN T0."Plant" = 'WF500999' THEN N'上海丰卉'
    	  						    WHEN T0."Plant" = 'WC600999' THEN N'上海和畅'  END "工厂"
    	  ,T4."Code"||N' - '||T4."Name" "大类"
    	  ,T1."U_Class3" "中类"
    	  ,T1."U_AliasName"  "内部名称"
    	  ,T0."ItemCode" "物料"
    	  ,T1."ItemName" "名称"
    	  ,SUM(CASE WHEN T0."DocDate" < :SDATE THEN T0."EndQty" ELSE 0 END ) "期初数量"
    	  
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(18,19,20,21,162,69) THEN T0."EndQty" ELSE 0 END )
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('302'))) THEN T0."EndQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('602') THEN T0."EndQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."InQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."InQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."InQty" ELSE 0 END ) "总入库_数量"
    	  
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NOT NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('301','303','304','305','306','307'))) THEN T0."EndQty" ELSE 0 END ) 
    	  - SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('601') THEN T0."EndQty" ELSE 0 END )
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."OutQty" ELSE 0 END )
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."OutQty" ELSE 0 END ) 
    	  +SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."OutQty" ELSE 0 END ) 
    	  - SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(13,14,15,16) THEN T0."EndQty" ELSE 0 END ) "总出库_数量"
    	  
    	  ,SUM(CASE WHEN T0."DocDate" <= :EDATE THEN T0."EndQty" ELSE 0 END ) "期末数量"
    	  
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(18,19,20,21,162,69) THEN T0."EndQty" ELSE 0 END ) "采购入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('302'))) THEN T0."EndQty" ELSE 0 END ) "生产入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('602') THEN T0."EndQty" ELSE 0 END ) "工厂调入数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."InQty" ELSE 0 END ) "代码转换入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."InQty" ELSE 0 END ) "库存转储入库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."InQty" ELSE 0 END ) "库存收货数量"
    	  
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND ((T0."BaseType"='202' AND T0."BaseLine" IS NOT NULL) OR (T0."BaseType"='-1' AND T0."TrsName" IN ('301','303','304','305','306','307'))) THEN T0."EndQty" ELSE 0 END ) "生产发料数量"
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."BaseType"='-1' AND T0."TrsName" IN('601') THEN T0."EndQty" ELSE 0 END ) "工厂调出数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND T0."TrsName" IN('401') THEN T0."OutQty" ELSE 0 END ) "代码转换出库数量"
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."OutQty" ELSE 0 END ) "库存转储出库数量"	  
    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(60) AND T0."BaseType"='-1' AND LEFT(T0."TrsName",1) NOT IN('3','4','6') THEN T0."OutQty" ELSE 0 END ) "库存发货数量"
    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(13,14,15,16) THEN T0."EndQty" ELSE 0 END ) "销售出库数量"
    FROM :TEMP T0
     INNER JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
     INNER JOIN OWHS T2 ON T0."WhsCode" = T2."WhsCode"
     LEFT JOIN "@U_CITTY2" T4 ON T1."U_Class2" = T4."Code"
    WHERE T0."DocDate" <= :EDATE
      --AND ( T6."Name" LIKE '%[%4]%' OR '[%4]' = '' OR '[%4]' IS NULL )
    GROUP BY T4."Code",T4."Name",T1."U_Class3",T1."U_AliasName",T0."Plant",T0."ItemCode",T1."ItemName"
    ORDER BY T4."Code" DESC,T0."Plant",T0."ItemCode" ;
  
  END IF ; 
END IF ;
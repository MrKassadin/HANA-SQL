/*SELECT FROM OBPL T2 WHERE T2."BPLName"=[%2];*/ 
/*SELECT FROM "OFPR" T0 WHERE T0."F_RefDate" >=[%0];*/ 
/*SELECT FROM "OFPR" T1 WHERE T1."T_RefDate" <=[%1];*/ 
/*SELECT FROM "OITM" T5 WHERE T5."ItemName" LIKE '%[%5]%';*/
/*SELECT FROM "@U_COUQR" T3 WHERE T3."U_IsIncProdt" = [%6];*/

DECLARE USERCODE NVARCHAR(30); 
DECLARE CNT INT; 
DECLARE CNT1 INT; 
DECLARE SDATE DATE;
DECLARE EDATE DATE;
DECLARE BPLID INT;
DECLARE IsIncProdt nvarchar(1);
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%2]';
SELECT "BPLId" INTO BPLID FROM OBPL WHERE "BPLName"='[%2]';
SDATE:=[%0];
EDATE:=[%1];
IsIncProdt := '[%6]';

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
		,CASE WHEN T0."TransType" IN (59,60) AND IFNULL(T7."BaseType",T8."BaseType")=-1 THEN '库存交易-'||IFNULL(T9."Name",'')
		      WHEN T0."TransType" IN (59) AND IFNULL(T7."BaseType",T8."BaseType")=202 AND  IFNULL(T7."BaseLine",T8."BaseLine") IS NULL THEN '生产入库'
			  WHEN T0."TransType" IN (59) AND IFNULL(T7."BaseType",T8."BaseType")=202 AND  IFNULL(T7."BaseLine",T8."BaseLine") IS NOT NULL THEN '生产退货'
			  WHEN T0."TransType" = 59 AND T130."ApplObj" = '202' AND T0."OutQty"<>0 THEN '生产发货（倒冲）'
			  WHEN T0."TransType" IN (60) AND IFNULL(T7."BaseType",T8."BaseType")=202  THEN '生产发货'
			  WHEN T0."TransType" = 67 THEN '库存调拨-'||IFNULL(T19."Name",'')
			 ELSE t6."Name" END "TransType"
		,CASE WHEN T0."TransType" IN (59,60) AND IFNULL(T7."BaseType",T8."BaseType") = -1 THEN IFNULL(T17."U_TrsName",T18."U_TrsName")
			  WHEN T0."TransType" IN (59,60) AND IFNULL(T7."BaseType",T8."BaseType") = 202 AND IFNULL(T7."BaseLine",T8."BaseLine") IS NOT NULL THEN '301'
			  WHEN T0."TransType" IN (59,60) AND IFNULL(T7."BaseType",T8."BaseType") = 202 AND IFNULL(T7."BaseLine",T8."BaseLine") IS NULL THEN '302'
			  WHEN T0."TransType" = 59 AND T130."ApplObj" = '202' AND T0."OutQty"<>0 THEN '301'  --倒冲 
			  WHEN T0."TransType" = 67 THEN IFNULL(T121."U_TrsName",'') ELSE NULL END "TrsName"
		--,CASE WHEN T141."Code" IS NULL THEN IFNULL(T142."U_ActoPlant",'') ELSE T141."Code" END "Plant"
		,CASE WHEN T4."U_ItemGrpType" IN ('A') THEN IFNULL(T142."U_Workshop",'') ELSE T140."U_Workshop" END "Plant"
		,T0."LocCode" "WhsCode",T5."WhsName"
		,T0."BASE_REF",T0."DocLineNum"+1 "DocLineNum"
		,CASE WHEN t0."TransType" = 20 THEN T31."CardCode"||N' - '||T31."CardName" 
		      WHEN t0."TransType" = 21 THEN T41."CardCode"||N' - '||T41."CardName" 
		      WHEN t0."TransType" = 18 THEN T111."CardCode"||N' - '||T111."CardName" 
		      WHEN t0."TransType" = 19 THEN T101."CardCode"||N' - '||T101."CardName"
		      WHEN t0."TransType" = 15 THEN T61."CardCode"||N' - '||T61."CardName" 
		      WHEN t0."TransType" = 16 THEN T71."CardCode"||N' - '||T71."CardName" 
		      WHEN t0."TransType" = 13 THEN T91."CardCode"||N' - '||T81."CardName" 
		      WHEN t0."TransType" = 14 THEN T81."CardCode"||N' - '||T81."CardName" 
		      ELSE NULL END"CardName"
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
		,CASE WHEN T121."CANCELED" = 'Y' OR T120."BaseType" = '0' OR	--剔除转储取消单与抵消单
				   T31."CANCELED" = 'Y' OR T30."BaseType" = '20' OR		--剔除采购入库取消单与抵消单
				   T41."CANCELED" = 'Y' OR T40."BaseType" = '21' OR		--剔除采购退货取消单与抵消单
				   T61."CANCELED" = 'Y' OR T60."BaseType" = '15' OR		--剔除销售出库取消单与抵消单
				   T71."CANCELED" = 'Y' OR T70."BaseType" = '16' OR		--剔除销售退货取消单与抵消单
				   T81."CANCELED" = 'Y' OR T80."BaseType" = '14' OR		--剔除应收贷项取消单与抵消单
				   T91."CANCELED" = 'Y' OR T90."BaseType" = '13' OR		--剔除应收发票取消单与抵消单
				   T101."CANCELED" = 'Y' OR T100."BaseType" = '19' OR	--剔除应付贷项取消单与抵消单
				   T111."CANCELED" = 'Y' OR T110."BaseType" = '18' 		--剔除应付发票取消单与抵消单
			  THEN 0 ELSE (T0."SumStock"+T0."VarVal"+T0."PriceDiff") END "StdAmt"
		/*
		,T0."InQty"
		,T0."OutQty"
		,IFNULL(T0."InQty",0) - IFNULL(T0."OutQty",0) "EndQty"
		,(T0."SumStock"+T0."VarVal"+T0."PriceDiff") "StdAmt"
		*/
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
	left join PDN1 T30 ON T30."ObjType"=T0."TransType" AND T30."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T30."LineNum"
	LEFT JOIN OPDN T31 ON T30."DocEntry"=T31."DocEntry"
	left join RPD1 T40 ON T40."ObjType"=T0."TransType" AND T40."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T40."LineNum"
	LEFT JOIN ORPD T41 ON T40."DocEntry"=T41."DocEntry"
	left join DLN1 T60 ON T60."ObjType"=T0."TransType" AND T60."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T60."LineNum"
	LEFT JOIN ODLN T61 ON T60."DocEntry"=T61."DocEntry"
	left join RDN1 T70 ON T70."ObjType"=T0."TransType" AND T70."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T70."LineNum"
	LEFT JOIN ORDN T71 ON T70."DocEntry"=T71."DocEntry"
	left join RIN1 T80 ON T80."ObjType"=T0."TransType" AND T80."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T80."LineNum"
	LEFT JOIN ORIN T81 ON T80."DocEntry"=T81."DocEntry"
	left join INV1 T90 ON T90."ObjType"=T0."TransType" AND T90."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T90."LineNum"
	LEFT JOIN OINV T91 ON T90."DocEntry"=T91."DocEntry"
	left join RPC1 T100 ON T100."ObjType"=T0."TransType" AND T100."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T100."LineNum"
	LEFT JOIN ORPC T101 ON T100."DocEntry"=T101."DocEntry"
	left join PCH1 T110 ON T110."ObjType"=T0."TransType" AND T110."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T110."LineNum"
	LEFT JOIN OPCH T111 ON T110."DocEntry"=T111."DocEntry"
	left join WTR1 T120 ON T120."ObjType"=T0."TransType" AND T120."DocEntry"=T0."CreatedBy" AND T0."DocLineNum"=T120."LineNum"
	LEFT JOIN OWTR T121 ON T120."DocEntry"=T121."DocEntry"
	LEFT JOIN "@U_CIOTRN" T19 ON T19."Code" = T121."U_TrsName"
	LEFT JOIN OILM T130 ON T0."MessageID" = T130."MessageID"  --倒冲
	LEFT JOIN OWOR T131 ON T130."AppObjAbs" = T131."DocEntry" AND T130."ApplObj" = '202' 
	LEFT JOIN OWHS T140 ON T0."LocCode" = T140."WhsCode" 
	LEFT JOIN ( SELECT DISTINCT "Code","U_ItemCode","U_ActoPlant" ,"U_Workshop"
				FROM "@U_PIT1" ) T142 ON T0."ItemCode" = T142."U_ItemCode" AND T142."Code" = :BPLId
	JOIN OFPR T10 ON T0."DocDate" BETWEEN T10."F_RefDate" AND T10."T_RefDate"
	left join OUSR T12 ON T0."UserSign" = t12."USERID"
	WHERE T5."BPLid"= :BPLId
	  AND ( T0."InQty" - T0."OutQty" ) <> 0
	  AND T0."DocDate" <= :EDATE
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
  	  		N'请检查 ->'
  	   		  ||T0."TransType"||N'：单据号-'||To_nvarchar(T0."BASE_REF")
  	   		  ||N' 行中物料<'|| T0."ItemCode"
  	   		  ||'> 若为原料 或 包材，则该行的'||T0."WhsCode"
  	          ||N'是否已指定归属车间；若为成品 或 半成品，则请先在《工厂产品对应表》中进行维护！' "错误提示"
  	  FROM :TEMP T0 WHERE IFNULL(T0."Plant",'') = '';
  	  RETURN;
    END IF ;
  
 	Sum_Temp =  
	    SELECT N'合并：按工厂查看' "查看方式"
	    	  ,T0."Plant"||N' - '||CASE WHEN T0."Plant" = 'W0000001' THEN N'膨化厂（上海）'
	    	  						    WHEN T0."Plant" = 'W0000002' THEN N'青浦厂（上海）'
	    	  						    WHEN T0."Plant" = 'W0000003' THEN N'松江厂（上海）'
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
	    	  ,0 "期初金额"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE THEN T0."InQty" ELSE 0 END ) "总入库_数量"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE THEN T0."OutQty" ELSE 0 END ) "总出库_数量"
	    	  ,SUM(CASE WHEN T0."DocDate" <= :EDATE THEN T0."EndQty" ELSE 0 END ) "期末数量"
	    	  ,0 "期末金额"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(18,19,20,21,162,69) THEN T0."EndQty" ELSE 0 END ) "采购入库数量"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(18,19,20,21,162,69) THEN T0."StdAmt" ELSE 0 END ) "采购入库金额"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."TrsName" = '302' THEN T0."EndQty" ELSE 0 END ) "生产入库数量"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND LEFT(T0."TrsName",1) <> '3' THEN T0."InQty" ELSE 0 END ) "其他入库数量"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."InQty" ELSE 0 END ) "调拨入库数量"
	    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(13,14,15,16) THEN T0."EndQty" ELSE 0 END ) "销售出库数量"
	    	  ,- SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND T0."TrsName" <> '302' AND LEFT(T0."TrsName",1) = '3' THEN T0."EndQty" ELSE 0 END ) "生产出库数量"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(59,60) AND LEFT(T0."TrsName",1) <> '3' THEN T0."OutQty" ELSE 0 END ) "其他出库数量"
	    	  ,SUM(CASE WHEN T0."DocDate" BETWEEN :SDATE AND :EDATE AND T0."ObjType" IN(67) THEN T0."OutQty" ELSE 0 END ) "调拨出库数量"	  
	    FROM :TEMP T0
	     INNER JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
	     INNER JOIN OWHS T2 ON T0."WhsCode" = T2."WhsCode"
	     LEFT JOIN "@U_CITTY2" T4 ON T1."U_Class2" = T4."Code"
	    WHERE T0."DocDate" <= :EDATE
	    GROUP BY T4."Code",T4."Name",T1."U_Class3",T1."U_AliasName",T0."Plant",T0."ItemCode",T1."ItemName"
	    
	    UNION ALL
	    SELECT N'合并：按工厂查看' "合并仓库"
	    	  ,T0."PlantCode"||N' - '||CASE WHEN T0."PlantCode" = 'W0000001' THEN N'膨化厂（上海）'
		    	  						    WHEN T0."PlantCode" = 'W0000002' THEN N'青浦厂（上海）'
		    	  						    WHEN T0."PlantCode" = 'W0000003' THEN N'松江厂（上海）'
		    	  						    WHEN T0."PlantCode" = 'WH300999' THEN N'武汉新农翔'
		    	  						    WHEN T0."PlantCode" = 'WZ400999' THEN N'新农（郑州）'
		    	  						    WHEN T0."PlantCode" = 'WF500999' THEN N'上海丰卉'
		    	  						    WHEN T0."PlantCode" = 'WC600999' THEN N'上海和畅'  END "工厂"
	   		  ,T4."Code"||N' - '||T4."Name" "大类"
	    	  ,T1."U_Class3" "中类"
	    	  ,T1."U_AliasName"  "内部名称"
	    	  ,T0."ItemCode" "物料"
	    	  ,T1."ItemName" "名称"
	    	  ,0 "期初数量"
	    	  ,SUM( CASE WHEN T0."FcCode" = LEFT(TO_NVARCHAR(TO_DATE(:SDATE)),7) THEN T0."UPAmt" ELSE 0 END ) "期初金额"
	    	  ,0 "总入库_数量"
	    	  ,0 "总出库_数量"
	    	  ,0 "期末数量"
	    	  ,SUM( CASE WHEN T0."FcCode" = LEFT(TO_NVARCHAR(TO_DATE(:EDATE)),7) THEN T0."Amount" ELSE 0 END ) "期末金额"
	    	  ,0 "采购入库数量"
	    	  ,0 "采购入库金额"
	    	  ,0 "生产入库数量"
	    	  ,0 "其他入库数量"
	    	  ,0 "调拨入库数量"
	    	  ,0 "销售出库数量"
	    	  ,0 "生产出库数量"
	    	  ,0 "其他出库数量"
	    	  ,0 "调拨出库数量"	  
	    FROM U_COPCT T0
	    JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
	    LEFT JOIN "@U_CITTY2" T4 ON T1."U_Class2" = T4."Code"
	    WHERE T0."BPLId" = :BPLId
	    GROUP BY T4."Code",T4."Name",T1."U_Class3",T1."U_AliasName",T0."PlantCode",T0."ItemCode",T1."ItemName" 
	    ;
	--SELECT * FROM :Sum_Temp ;

	--返回结果
	IF :IsIncProdt = 'Y' THEN   
	 	SELECT    T0."查看方式"
		    	  ,T0."工厂"
		   		  ,T0."大类"
		    	  ,T0."中类"
		    	  ,T0."内部名称"
		    	  ,T0."物料"
		    	  ,T0."名称"
		    	  ,SUM(T0."期初数量") "期初数量"
		    	  ,IFNULL(SUM(T0."期初金额")/ NULLIF(SUM(T0."期初数量"),0) ,0) "期初单价"
		    	  ,SUM(T0."期初金额") "期初金额"
		    	  ,SUM(T0."总入库_数量") "总入库_数量"
		    	  ,SUM(T0."总出库_数量") "总出库_数量"
		    	  ,SUM(T0."期末数量") "期末数量"
		    	  ,IFNULL(SUM(T0."期末金额")/ NULLIF(SUM(T0."期末数量"),0) ,0) "期末单价"
		    	  ,SUM(T0."期末金额") "期末金额"
		    	  ,SUM(T0."采购入库数量") "采购入库数量"
		    	  ,IFNULL(SUM(T0."采购入库金额")/ NULLIF(SUM(T0."采购入库数量"),0) ,0) "本期入库均价"
		    	  ,SUM(T0."采购入库金额") "采购入库金额"
		    	  ,SUM(T0."生产入库数量") "生产入库数量"
		    	  ,SUM(T0."其他入库数量") "其他入库数量"
		    	  ,SUM(T0."调拨入库数量") "调拨入库数量"
		    	  ,SUM(T0."销售出库数量") "销售出库数量"
		    	  ,SUM(T0."生产出库数量") "生产出库数量"
		    	  ,SUM(T0."其他出库数量") "其他出库数量"
		    	  ,SUM(T0."调拨出库数量") "调拨出库数量"  
	 	FROM :Sum_Temp T0
	 	JOIN OITM T1 ON T0."物料" = T1."ItemCode"
	 	JOIN OITB T2 ON T1."ItmsGrpCod" = T2."ItmsGrpCod"
	 	WHERE 1 = 1
	 	GROUP BY T0."查看方式" ,T0."工厂" ,T0."大类" ,T0."中类" ,T0."内部名称" ,T0."物料" ,T0."名称",T2."U_ItemGrpType"
	 	ORDER BY T2."U_ItemGrpType",T0."物料"; 	
 	ELSE 
 		SELECT    T0."查看方式"
		    	  ,T0."工厂"
		   		  ,T0."大类"
		    	  ,T0."中类"
		    	  ,T0."内部名称"
		    	  ,T0."物料"
		    	  ,T0."名称"
		    	  ,SUM(T0."期初数量") "期初数量"
		    	  ,IFNULL(SUM(T0."期初金额")/ NULLIF(SUM(T0."期初数量"),0) ,0) "期初单价"
		    	  ,SUM(T0."期初金额") "期初金额"
		    	  ,SUM(T0."总入库_数量") "总入库_数量"
		    	  ,SUM(T0."总出库_数量") "总出库_数量"
		    	  ,SUM(T0."期末数量") "期末数量"
		    	  ,IFNULL(SUM(T0."期末金额")/ NULLIF(SUM(T0."期末数量"),0) ,0) "期末单价"
		    	  ,SUM(T0."期末金额") "期末金额"
		    	  ,SUM(T0."采购入库数量") "采购入库数量"
		    	  ,IFNULL(SUM(T0."采购入库金额")/ NULLIF(SUM(T0."采购入库数量"),0) ,0) "本期入库均价"
		    	  ,SUM(T0."采购入库金额") "采购入库金额"
		    	  ,SUM(T0."生产入库数量") "生产入库数量"
		    	  ,SUM(T0."其他入库数量") "其他入库数量"
		    	  ,SUM(T0."调拨入库数量") "调拨入库数量"
		    	  ,SUM(T0."销售出库数量") "销售出库数量"
		    	  ,SUM(T0."生产出库数量") "生产出库数量"
		    	  ,SUM(T0."其他出库数量") "其他出库数量"
		    	  ,SUM(T0."调拨出库数量") "调拨出库数量"  
	 	FROM :Sum_Temp T0
	 	JOIN OITM T1 ON T0."物料" = T1."ItemCode"
	 	JOIN OITB T2 ON T1."ItmsGrpCod" = T2."ItmsGrpCod"
	 	WHERE T2."U_ItemGrpType" NOT IN('A','B')
	 	GROUP BY T0."查看方式" ,T0."工厂" ,T0."大类" ,T0."中类" ,T0."内部名称" ,T0."物料" ,T0."名称" ,T2."U_ItemGrpType"
	 	ORDER BY T2."U_ItemGrpType",T0."物料"; 
 	END IF ;

END IF ;
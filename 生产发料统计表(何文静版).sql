/*SELECT FROM OBPL T0 WHERE T0.BPLname=[%0];*/
/*SELECT FROM OFPR T1 WHERE T1.F_REFDATE >=[%1];*/
/*SELECT FROM OFPR T2 WHERE T2.T_REFDATE <=[%2];*/
/*SELECT FROM "@U_COUQR" T3 WHERE T3."U_Plant" LIKE '%[%3]%'*/
/*SELECT FROM OITM T4 WHERE T4."ItemName" '%[%4]%'*/

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT; 
DECLARE BPLID INT;

SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';
SELECT "BPLId" INTO BPLID FROM OBPL WHERE "BPLName"='[%0]';

IF :CNT>0 THEN
  select 
	   R.*
  from(
	SELECT 
		 CASE WHEN T5."U_Approved" = '1' THEN '已审核' ELSE NULL END "审核状态",
	     T0."DocNum" "出库单号",T0."DocDate" "出库日期"
	    ,T2."WhsName" "仓库"
	    ,T5."PostDate" "订单日期"
	    ,case when t1."BaseType" = '-1' then t0."U_SrcNum" when t1."BaseType" = 202 then t1."BaseRef" end as "订单号"
		,T60."ItmsGrpNam" "产品大类",t5."ItemCode" as "产品编码",t6."ItemName" as "产品名称"
		,T1."ItemCode" "原料编码",T3."ItemName" "原料名称",T12."ItmsGrpNam" "物料组"
		,t13."OutQty" - t13."InQty" "数量",T3."InvntryUom" "主计量单位"
		,T14."USER_CODE"||N' - '||CASE WHEN IFNULL(t10."lastName"||t10."firstName",T14."U_NAME") = 'manager' 
		   								 THEN '中控入库' 
		   							   ELSE IFNULL(t10."lastName"||t10."firstName",T14."U_NAME") END as "制单人"
		,CASE WHEN T1."BaseType"=202 THEN '生产发料' ELSE t4."Code"||'：'||T4."Name"||'  -发料(库存-发货)' END "事务"
		
		,case when t0."U_SrcNum" is null and t1."BaseType"=-1 then T16."PrcName" else T11."PrcName" end "车间名称"
		
		,CASE WHEN T5."U_ProType" = 'S' THEN N'标准' WHEN T5."U_ProType" = 'T' THEN N'回机' WHEN T5."U_ProType" = 'P' THEN N'换包' ELSE NULL END "生产类型"
        ,T0."Comments"
	FROM OIGE T0
	inner join IGE1 T1 ON T0."DocEntry"=T1."DocEntry"
	inner join OWHS T2 ON T1."WhsCode"=T2."WhsCode"
	inner join OITM T3 ON T3."ItemCode"=T1."ItemCode"
	inner join OITB t12 on t3."ItmsGrpCod" = t12."ItmsGrpCod"
	left join "@U_CIOTRN" T4 ON T4."Code"=T0."U_TrsName"
    left join OWOR t5 on case when t1."BaseType" = '-1' then t0."U_SrcNum" when t1."BaseType" = 202 then t1."BaseRef" end = t5."DocNum" 
    left join OITM t6 on t6."ItemCode" = t5."ItemCode"
    LEFT JOIN OITB T60 ON T60."ItmsGrpCod" = T6."ItmsGrpCod"
    left join ohem t10 on t0."UserSign"=t10."userId"
    LEFT JOIN OUSR T14 ON t0."UserSign" = T14."USERID"
    left join OPRC T11 ON T5."OcrCode2" = t11."PrcCode"
    left join OPRC T15 ON T5."OcrCode" = t15."PrcCode"
    
    left join OPRC T16 ON T1."OcrCode2" = t16."PrcCode"
    
    join oivl t13 on t13."TransType" = t1."ObjType" and t1."DocEntry" = t13."CreatedBy" and t1."LineNum" = t13."DocLineNum"
	WHERE (
			   (T1."BaseType"=202 AND "BaseLine" IS NOT NULL)
		   OR  (T1."BaseType"=-1 AND "U_TrsName" IN ('301','303','304','305','306','307'))
	      )
	  AND T0."DocDate" BETWEEN [%1] AND [%2]
	  AND T0."BPLId"=:BPLID
	  
	  
	  
	  AND case when t0."U_SrcNum" is null and t1."BaseType"=-1 then T16."PrcName" else T11."PrcName" end  like '%[%3]%'
	  
	  
	  
	  AND T3."ItemName" LIKE '%[%4]%'
		
	UNION ALL
	SELECT CASE WHEN T5."U_Approved" = '1' THEN '已审核' ELSE NULL END "审核状态",
		 T0."DocNum" "出库单号",T0."DocDate" "出库日期"
		,T2."WhsName" "仓库"
		,T5."PostDate" "订单日期"
		,case when t1."BaseType" = '-1' then t0."U_SrcNum" when t1."BaseType" = 202 then t1."BaseRef" end as "订单号"
		,T60."ItmsGrpNam" "产品大类",t5."ItemCode" as "产品编码",t6."ItemName" as "产品名称"
		,T1."ItemCode" "原料编码",T3."ItemName" "原料名称",T12."ItmsGrpNam" "物料组"
		,t13."OutQty" - t13."InQty"  "数量",T3."InvntryUom" "主计量单位"
		,T14."USER_CODE"||N' - '||CASE WHEN IFNULL(t10."lastName"||t10."firstName",T14."U_NAME") = 'manager' 
		   								 THEN '中控入库' 
		   							   ELSE IFNULL(t10."lastName"||t10."firstName",T14."U_NAME") END as "制单人"
		,CASE WHEN T1."BaseType"=202 THEN '退货组件' ELSE t4."Code"||'：'||T4."Name"||'  -退料(库存-收货)' END "事务"	
		,case when t0."U_SrcNum" is null and t1."BaseType"=-1 then T16."PrcName" else T11."PrcName" end  "车间名称"
        ,CASE WHEN T5."U_ProType" = 'S' THEN N'标准' WHEN T5."U_ProType" = 'T' THEN N'回机' WHEN T5."U_ProType" = 'P' THEN N'换包' ELSE NULL END "生产类型"
        ,T0 ."Comments"
	FROM OIGN T0
	inner join IGN1 T1 ON T0."DocEntry"=T1."DocEntry"
	inner join OWHS T2 ON T1."WhsCode"=T2."WhsCode"
	inner join OITM T3 ON T3."ItemCode"=T1."ItemCode"
	inner join OITB T12 on t3."ItmsGrpCod" = t12."ItmsGrpCod"
	left join "@U_CIOTRN" T4 ON T4."Code"=T0."U_TrsName"
	left join OWOR t5 on case when t1."BaseType" = '-1' then t0."U_SrcNum" when t1."BaseType" = 202 then t1."BaseRef" end = t5."DocNum" 
    left join OITM t6 on t6."ItemCode" = t5."ItemCode"
    LEFT JOIN OITB T60 ON T60."ItmsGrpCod" = T6."ItmsGrpCod"
    left join OHEM  t10 on t0."UserSign"=t10."userId"
    LEFT JOIN OUSR T14 ON t0."UserSign" = T14."USERID"
    left join OPRC T11 ON T5."OcrCode2" = t11."PrcCode"
    left join OPRC T15 ON T5."OcrCode" = t15."PrcCode"
    left join OPRC T16 ON T1."OcrCode2" = t16."PrcCode"
    
    join oivl t13 on t13."TransType" = t1."ObjType" and t1."DocEntry" = t13."CreatedBy" and t1."LineNum" = t13."DocLineNum"
	WHERE (
			 (T1."BaseType"=202 AND "BaseLine" IS NOT NULL)
		  OR (T1."BaseType"=-1 AND "U_TrsName" IN ('301','303','304','305','306','307'))
		  )
	  AND T0."DocDate" BETWEEN [%1] AND [%2]
	  AND T0."BPLId"=:BPLID		
	  
	  AND case when t0."U_SrcNum" is null and t1."BaseType"=-1 then T16."PrcName" else T11."PrcName" end LIKE '%[%3]%'
	  
	  
	  AND T3."ItemName" LIKE '%[%4]%'
	  	
	  )	R
  WHERE 1 = 1
  ORDER BY R."订单日期",R."订单号"
  ;
	
ELSE 
	SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;
END IF;

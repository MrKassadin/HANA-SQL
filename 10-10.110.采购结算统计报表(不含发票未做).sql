/*SELECT FROM OBPL T0 WHERE T0."BPLName"=[%0];*/
/*SELECT FROM "@U_COUQR" T1 WHERE T1."U_BDate" =[%1];*/
/*SELECT FROM "@U_COUQR" T2 WHERE T2."U_EDate" =[%2];*/
/*SELECT FROM "OCRD" T3 WHERE T3."CardName" =[%3];*/

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
DECLARE BPLId NVARCHAR(10);
DECLARE BDate DATE;
DECLARE EDate DATE;

BDate:='[%1]';
EDate:='[%2]';
SELECT "BPLId" INTO BPLId FROM OBPL WHERE "BPLName"='[%0]';
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';

IF :CNT > 0 THEN

				SELECT DISTINCT T7."Name" "业务类型"
				,T8."U_DocDate" "进厂日期"
				,T0."DocDate" AS "入库日期", 
				T0."CardName" AS "供应商名称",
				T1."Dscription"AS "物料名称",
				T3."DocNum" AS "订单号",
				T5."DocNum" AS "结算单号",
				T8."DocEntry" AS "进场通知单号", 
				T1."U_CarNumber" AS "车号",
				T1."U_SupplyQty" AS "供方数量",
				T1."Quantity" AS "实际入库数量",
				T4."Quantity" AS "结算数量",
				T8."U_Amount" "包数",
				T2."Price" AS "合同单价",
				T4."Price" AS "结算单价",
				(T4."LineTotal"+IFNULL(T11."运费金额",0))/T1."Quantity" AS "实际单价",
				T4."LineTotal" AS "结算金额",
				IFNULL(T11."运费金额",0) AS "运费金额",
				T10."U_OVPMNum" "付款单号",
				T0."DocNum" AS "入库单号"
				,T9."U_CheckQty" "扣量",
				T9."U_CheckPri" "扣价",
				T0."BPLName" AS "单位名称",
				T0."Comments" AS "备注"
		
		FROM OPDN T0 
		INNER JOIN PDN1 T1 ON T0."DocEntry" = T1."DocEntry"
		LEFT JOIN POR1 T2 ON IFNULL(T1."BaseLine",0)=T2."LineNum"  AND T1."BaseType"=T2."ObjType" AND T1."BaseEntry" =T2."DocEntry"
		LEFT JOIN OPOR T3 ON T2."DocEntry"=T3."DocEntry"
		LEFT JOIN 
		          (
		            SELECT CASE T1."U_PayQty" WHEN '0' THEN T1."Quantity" ELSE T1."U_PayQty" END "Quantity",
			               CASE T1."U_PayPrice" WHEN '0' THEN T1."Price" ELSE T1."U_PayPrice" END "Price",
			              T1."LineTotal",T1."BaseEntry",T1."BaseLine",T1."BaseType",T0."DocEntry",T1."LineNum"
		            FROM OPCH T0
		            JOIN PCH1 T1 on T0."DocEntry"=T1."DocEntry" 
		          )T4 ON  T4."BaseEntry" = T1."DocEntry" AND T4."BaseLine" = T1."LineNum" AND T4."BaseType" = T1."ObjType"
		LEFT JOIN OPCH T5 ON T4."DocEntry" = T5."DocEntry"
		LEFT JOIN ODPO T6 ON T5."DocNum"=T6."DocNum"
		LEFT JOIN "@U_CMSBST" T7 ON T0."U_BusiType"=T7."Code"
		LEFT JOIN 
					(
						SELECT T0."DocEntry",T0."U_DocDate",T1."LineId",T2."U_Amount" ,T1."U_CarNumber"
						FROM "@U_AOGI" T0
						JOIN "@U_OGI1" T1 ON T0."DocEntry"=T1."DocEntry"
						JOIN "@U_OGI3" T2 ON T0."DocEntry"=T2."DocEntry" AND T1."U_CarNumber"=T2."U_CarNumber" AND T1."LineId"=T2."U_LineId"
					) T8 ON T1."U_NoticeNumber"=T8."DocEntry" AND T1."U_NoticeLineNum" =T8."LineId" AND T1."U_CarNumber"=T8."U_CarNumber"
		LEFT JOIN "@U_QASR" T9 ON T0."DocNum"=T9."U_RPONumber" AND T1."U_CarNumber"=T9."U_CarNumber" AND T1."U_NoticeNumber"=T9."U_NoticeNumber" AND T1."U_NoticeLineNum"=T9."U_NoticeLineNum"
		LEFT JOIN 
					(
						SELECT T0."DocNum", T0."U_OVPMNum",  T1."U_BaseEntry", T1."U_BaseLine", T1."U_PayAmt" 
						FROM "@U_QKD"  T0  JOIN "@U_QKD1"  T1 ON T0."DocEntry"=T1."DocEntry" 
					) T10 ON T4."DocEntry"=T10."U_BaseEntry" AND T4."LineNum"=T10."U_BaseLine"
		LEFT JOIN
	   (
	   SELECT T0."DocNum" "采购收货单号"--,T0."AgentCode" "承运商"
	   --,T2."TtlCostLC" "运费金额"
	   ,SUM(T2."TtlCostLC") "运费金额"
	   ,T2."OrigLine" "采购收货单行号"
	   --,T2."OriBAbsEnt"
	   --,T3."DocNum"
	   FROM "OPDN" T0
	   INNER JOIN "PDN1" T1 ON T0."DocEntry"=T1."DocEntry"
	   LEFT JOIN "IPF1" T2 ON (T1."DocEntry"=T2."OriBAbsEnt" AND T2."OriBDocTyp"=20)
	   --LEFT JOIN "OIPF" T3 ON T2."DocEntry"=T3."DocEntry"
	   --LEFT JOIN "IPF2" T4 ON T3."DocEntry"=T4."DocEntry"
	   WHERE
	   T1."BaseType" <> 20
	   AND T0."CANCELED"='N'
	   AND "TargetDoc" IS NULL
	   AND T2."TtlCostLC"<>0
	   GROUP BY T0."DocNum",T2."OrigLine"
	   ) T11 ON T0."DocNum"=T11."采购收货单号" AND T1."LineNum"=T11."采购收货单行号"
		WHERE T0."BPLName"='[%0]'
	  			AND T0."DocDate" BETWEEN :BDate AND :EDate
	  			AND (T0."CardName" LIKE '%[%3]%' OR T0."CardName" IS NULL) 
				AND T5."DocNum" IS NOT NULL;--剔除发票未做

ELSE
    SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;
END IF;

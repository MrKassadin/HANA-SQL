SELECT
T0."BPLId" AS "分公司编号"
,T4."Code" AS "会计期间"
,T0."DocDate" AS "过账日期"
,CASE T2."U_DocType"
WHEN N'1' THEN N'现'
WHEN N'2' THEN N'银'
WHEN N'3' THEN N'转'
ELSE T2."U_DocType"
END AS "凭证类型"
,T2."U_TransID" AS "凭证号"
,T0."TransId" AS "日记账分录号"
,T0."CardCode" AS "客户编码"
,T3."CardName" AS "客户名称"
,T9."DocNum" AS "订单"
,T8."DocNum" AS "发货单号"
,T6."DocNum" AS "出库单号"
,T0."DocNum" AS "应收发票号"
,T0."DocTotal" AS "发票金额"
FROM OINV T0
JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
JOIN OJDT T2 ON T0."DocEntry" = T2."CreatedBy" AND T2."TransType" = 13
JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
JOIN OFPR T4 ON T0."DocDate" BETWEEN T4."F_RefDate" AND T4."T_RefDate"
JOIN DLN1 T5 ON (T1."BaseEntry"=T5."DocEntry" AND T1."BaseType"=15) OR (T1."DocEntry"=T5."TrgetEntry" AND T5."TargetType"=13)
JOIN ODLN T6 ON T5."DocEntry"=T6."DocEntry"
JOIN RDR1 T7 ON (T5."BaseEntry"=T7."DocEntry" AND T5."BaseType"=17) OR (T5."DocEntry"=T7."TrgetEntry" AND T7."TargetType"=15) 
JOIN ORDR T8 ON T7."DocEntry"=T8."DocEntry"
JOIN OQUT T9 ON T7."BaseEntry"=T9."DocEntry"
WHERE T0."CANCELED" <> 'Y' AND T1."BaseType" <> '13'
  AND T6."CANCELED"<>'Y' AND T5."BaseType"<>15
  AND T8."CANCELED"<>'Y' AND T7."BaseType"<>17
  AND T0."DocDate" >= '2018-01-01'
  AND T0."DocDate"<='2018-03-31'
  AND T0."BPLId" = 1
GROUP BY
T0."DocNum",T0."BPLId",T0."DocDate"
,T0."CardCode",T3."CardName",T0."TransId"
,T4."Code",T2."U_DocType",T2."U_TransID",T6."DocNum"
,T8."DocNum",T9."DocNum",T0."DocTotal"
ORDER BY T4."Code",T2."U_DocType",T2."U_TransID",T0."DocNum";

SELECT DISTINCT(T0."DocNum")
FROM "OINV" T0
INNER JOIN "INV1" T1 ON T0."DocEntry"=T1."DocEntry"
WHERE T0."CANCELED" <> 'Y' AND T1."BaseType" <> '13'
  AND T0."DocDate" >= '2018-01-01'
  AND T0."DocDate"<='2018-03-31'
  AND T0."BPLId" = 1;
  
SELECT T0."DocNum" FROM ORDR T0
JOIN RDR1 T1 ON T0."DocEntry"=T1."DocEntry"
WHERE (T1."BaseEntry" IS NULL
OR T1."BaseEntry"=0)
AND T0."DocDate">='2018-01-01'
AND T0."BPLId"=1
AND T0."CANCELED" <> 'Y' AND T1."BaseType" <> '17';

SELECT CASE WHEN IFNULL(NULL,1)=IFNULL(1,0) THEN 'True' END FROM DUMMY;

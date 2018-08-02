--耗用级别
SELECT TOP 100 *
FROM "U_COWOR" U0
INNER JOIN "U_CWOR1" U1 ON U0."DocEntry"=U1."DocEntry" AND U1."DocType"='OWOR' AND U1."FcCode"='2018-01'
INNER JOIN "U_COILV" U2 ON U1."ItemCode"=U2."ItemCode" AND U2."BPLId"='1' AND U2."FcCode"='2018-01';

SELECT
T1."成品编码",T1."成品名称",T1."单据号"
,T0."iLevel" AS "成品级别"
,T1."耗用编码",T1."耗用名称",T1."耗用级别"
FROM "U_COILV" T0
INNER JOIN
(
	SELECT U0."ItemCode" AS "成品编码",U0."ItemName" AS "成品名称"
	,U1."ItemCode" AS "耗用编码",U1."ItemName" AS "耗用名称"
	,U0."DocNum" AS "单据号"
	,U2."iLevel" AS "耗用级别"
	FROM "U_COWOR" U0
	INNER JOIN "U_CWOR1" U1 ON U0."DocEntry"=U1."DocEntry" AND U1."DocType"='OWOR' AND U1."FcCode"='2018-03'
	INNER JOIN "U_COILV" U2 ON U1."ItemCode"=U2."ItemCode" AND U2."BPLId"='1' AND U2."FcCode"='2018-03'
	WHERE U0."FcCode"='2018-03'
	AND U0."BPLId"='1'
	AND U0."DocType"='OWOR'
) T1 ON T0."ItemCode"=T1."成品编码"
WHERE T0."BPLId"='1'
AND T0."FcCode"='2018-03'
AND T0."iLevel"<=T1."耗用级别"
ORDER BY T0."ItemCode";

--最新版本启用配方中将膨化大豆粉替换成膨化大豆(注意ItemCode及ItemName都需要更新)
SELECT
T0."U_Code" "成品编码",T0."U_ItemName" "成品"
,T1."U_Code" "原料编码",T1."U_ItemName" "原料"
FROM
"@U_COITT" T0
INNER JOIN "@U_CITT1" T1 ON T0."DocEntry"=T1."DocEntry"
WHERE T0."DocEntry" =(SELECT MAX("DocEntry") FROM "@U_COITT" U0 WHERE U0."U_Code"=T0."U_Code" AND U0."U_BPLID"=T0."U_BPLID")
AND T1."U_Code"='10080003'
AND T0."U_BPLID"=1
AND T0."U_IsActive"='是';
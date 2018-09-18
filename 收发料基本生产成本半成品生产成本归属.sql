SELECT DISTINCT * FROM
(
	SELECT DISTINCT T3."ItemCode" "物料编码",T0."ItemName" "物料名称",T1."ItmsGrpNam" "物料组"
	,CASE WHEN T1."ItmsGrpNam"='半成品' THEN N'半成品生产成本' ELSE N'基本生产成本' END "成本类型"
	FROM "IGN1" T3
	INNER JOIN "OITM" T0 ON T3."ItemCode"=T0."ItemCode"
	INNER JOIN "OITB" T1 ON T0."ItmsGrpCod"=T1."ItmsGrpCod"
	INNER JOIN "OIGN" T4 ON T3."DocEntry"=T4."DocEntry" 
	WHERE T4."DocDate" BETWEEN '2018-08-01' AND '2018-08-31'
	AND T4."BPLId"=1
	UNION ALL
	SELECT DISTINCT T3."ItemCode" "物料编码",T0."ItemName" "物料名称",T1."ItmsGrpNam" "物料组"
	,CASE WHEN T1."ItmsGrpNam"='半成品' THEN N'半成品生产成本' ELSE N'基本生产成本' END "成本类型"
	FROM "IGE1" T3
	INNER JOIN "OITM" T0 ON T3."ItemCode"=T0."ItemCode"
	INNER JOIN "OITB" T1 ON T0."ItmsGrpCod"=T1."ItmsGrpCod"
	INNER JOIN "OIGE" T4 ON T3."DocEntry"=T4."DocEntry" 
	WHERE T4."DocDate" BETWEEN '2018-08-01' AND '2018-08-31'
	AND T4."BPLId"=1
)
ORDER BY "物料编码";
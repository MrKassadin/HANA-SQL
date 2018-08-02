SELECT T0."DocNum" "采购收货单号"--,T0."AgentCode" "承运商"
--,T2."TtlCostLC" "运费金额"
,SUM(T2."TtlCostLC") "运费金额"
,T2."OriBLinNum" "采购收货单行号"
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
GROUP BY T0."DocNum",T2."OriBLinNum"
ORDER BY T0."DocNum"
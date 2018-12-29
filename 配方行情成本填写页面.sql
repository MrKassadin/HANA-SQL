SET SCHEMA XN_FM;
SELECT "ItemCode" "Code","ItemName" "Name",IFNULL("U_ItemPrice",N'无') "Price"
FROM "OITM" T0
INNER JOIN "OITB" T1 ON T0."ItmsGrpCod"=T1."ItmsGrpCod"
LEFT JOIN "@U_ITMPRICE" T2 ON T0."ItemCode"=T2."Code"
WHERE T1."ItmsGrpNam" IN ('大宗原料','添加剂','半成品','包装物')
AND "ItemName" NOT LIKE '%WH%' AND "ItemName" NOT LIKE '%ZZ%'
AND "ItemName" LIKE '模糊搜索值'
ORDER BY T0."ItemCode";

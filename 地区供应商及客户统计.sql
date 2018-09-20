SET SCHEMA XN_FM;
SELECT T0."Code",T0."Name",T1."CardCode"--,COUNT(T1."U_SupClass3")
FROM "@U_SBPTY3" T0
LEFT JOIN "OCRD" T1 ON T0."Code"=T1."U_SupClass3"
WHERE T1."CardType"='S'
--GROUP BY T0."Code",T0."Name"
ORDER BY T0."Code";

SELECT * FROM "OCRD" WHERE "U_SupClass3"='138';

SELECT COUNT(T0."CardCode"),T1."Code",T1."Name"
FROM OCRD T0
LEFT JOIN "@U_SBPTY3" T1 ON T0."U_SupClass3"=T1."Code"
WHERE T0."CardType"='S'
GROUP BY T1."Code",T1."Name";

SELECT * FROM "@U_SBPTY3";
SELECT * FROM "@U_CBPTY4";
UPDATE "OCRD" SET "U_SupClass3" = '110' WHERE "U_SupClass3"='130';

--供应商地区数量统计
SELECT
DISTINCT T0."Code",T0."Name",
IFNULL(T1."TotalNum",0) AS "TotalNum"
FROM "@U_SBPTY3" T0
LEFT JOIN(
			SELECT
			U0."Code",
			U0."Name",
			COUNT(U1."CardCode") AS "TotalNum"
			FROM "@U_SBPTY3" U0
			LEFT JOIN "OCRD" U1 ON U0."Code"=U1."U_SupClass3"
			WHERE U1."CardType"='S'--此处S表述供应商
			GROUP BY U0."Code",U0."Name"
		) T1 ON T0."Code"=T1."Code"
WHERE T0."Code" NOT LIKE '9%'
ORDER BY T0."Code";
--客户地区数量统计
SELECT
DISTINCT T0."Code",T0."Name",
IFNULL(T1."TotalNum",0) AS "TotalNum"
FROM "@U_SBPTY3" T0
LEFT JOIN(
			SELECT
			U0."Code",
			U0."Name",
			COUNT(U1."CardCode") AS "TotalNum"
			FROM "@U_SBPTY3" U0
			LEFT JOIN "OCRD" U1 ON U0."Code"=U1."U_SupClass3"
			WHERE U1."CardType"='C'--此处S表述供应商
			GROUP BY U0."Code",U0."Name"
		) T1 ON T0."Code"=T1."Code"
WHERE T0."Code" NOT LIKE '9%'
ORDER BY T0."Code";

			

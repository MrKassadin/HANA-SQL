/*SELECT FROM OBPL T2 WHERE T2.BPLName=[%2]*/
/*SELECT FROM OFPR T0 WHERE T0.F_REFDATE=[%0]*/
/*SELECT FROM OFPR T1 WHERE T1.T_REFDATE=[%1]*/
/*SELECT FROM "@U_COUQR" T3 WHERE T3.U_ISVOURCHER='[%3]'*/
/*SELECT FROM OACT T7 WHERE T7.AcctCode='[%4]'*/

DECLARE BPLId INT;
DECLARE StartDate DATE;
DECLARE EndDate DATE;
DECLARE AcctCode NVARCHAR(20);

StartDate:='[%0]';
EndDate:='[%1]';
SELECT "BPLId" INTO BPLId FROM OBPL WHERE "BPLName"='[%2]';
 		
SELECT "TransId",
	   "AcctCode" "科目",
   	   "RefDate",
   	   "JETrsId" "自制凭证号",
   	   "ObjType" "对象类型",
   	   "CreateTime",
   	   "Line_ID" "行号",
       "LineMemo" "行摘要",
   	   "ContraAct" "总账科目/业务伙伴",
       "Debit" "借方",
   	   "Credit" "贷方",
   	   "OcrCode1" "部门",
	   "OcrCode2" "车间",
	   "OcrCode3" "维度3",
	   "OcrCode4" "辅助核算",
	   "OcrCode5" "维度5",
	   "CardCode" "业务伙伴"
FROM( 
	   SELECT T1."Account"||N' - '||T2."AcctName" "AcctCode",
	   		  T0."RefDate",
		      --ROW_NUMBER() OVER(ORDER BY IFNULL(T0."U_TransID",'')) AS "ID",
	      T0."U_DocType" AS "DocType",
	      CASE WHEN T0."U_DocType" = '1' THEN N'现' 
	      	   WHEN T0."U_DocType" = '2' THEN N'银' 
	      	   WHEN T0."U_DocType" = '3' THEN N'转' ELSE '' END||N' - '||RIGHT('0000'||IFNULL(T0."U_TransID",''),4) AS "JETrsId" ,
	      T0."TransType" AS "ObjType",
	      T0."TransId",
	      T0."CreateTime",
	      T1."Line_ID"+1 "Line_ID",
	      IFNULL(T1."U_LineMemo",T1."LineMemo") "LineMemo",
	      T1."ContraAct",
	      IFNULL(T1."Debit",0) "Debit",
	      IFNULL(T1."Credit",0) "Credit",
	      IFNULL(T1."Debit",0)-IFNULL(T1."Credit",0) "Balance",
	      T1."ProfitCode"||N' - '||T3."PrcName" "OcrCode1",
	      T1."OcrCode2"||N' - '||T4."PrcName" "OcrCode2",
	      T1."OcrCode3"||N' - '||T5."PrcName" "OcrCode3",
	      T1."OcrCode4"||N' - '||T6."PrcName" "OcrCode4",
	      T1."OcrCode5"||N' - '||T7."PrcName" "OcrCode5",
	      T1."ShortName"||N' - '||T8."CardName" "CardCode"
   FROM OJDT T0
	JOIN JDT1 T1 ON T1."TransId" = T0."TransId" 
	JOIN OACT T2 ON T1."Account" = T2."AcctCode"
	LEFT JOIN OPRC T3 ON T1."ProfitCode" = T3."PrcCode"
	LEFT JOIN OPRC T4 ON T1."OcrCode2" = T4."PrcCode"
	LEFT JOIN OPRC T5 ON T1."OcrCode3" = T5."PrcCode"
	LEFT JOIN OPRC T6 ON T1."OcrCode4" = T6."PrcCode"
	LEFT JOIN OPRC T7 ON T1."OcrCode5" = T7."PrcCode"
	LEFT JOIN OCRD T8 ON CASE WHEN T2."LocManTran" = 'Y' THEN T1."ShortName" ELSE T1."U_CardCode" END = T8."CardCode"
   WHERE T1."Account" LIKE IFNULL(:AcctCode,'%')||'%'  
	 AND T0."RefDate" BETWEEN :StartDate AND :EndDate AND T1."BPLId"=:BPLId
     AND T2."FrozenFor" <> 'Y' 
     --AND (T2."U_IsHidAct" = 'N' AND (IFNULL(T2."BPLId",'') = '' OR T2."BPLId" = 1))
   UNION ALL 
   SELECT T1."U_ControlAcct"||N' - '||T2."AcctName" "AcctCode",
   		  T0."U_RefDate",
	      --ROW_NUMBER() OVER(ORDER BY IFNULL(T0."U_DocJEId",'')) AS "ID", --若启用，这个ID要重新
	      T0."U_DocType" AS "DocType",
	      CASE WHEN T0."U_DocType" = '1' THEN N'现' 
	      	   WHEN T0."U_DocType" = '2' THEN N'银' 
	      	   WHEN T0."U_DocType" = '3' THEN N'转' ELSE '' END||N' - '||RIGHT('0000'||IFNULL(T0."U_DocJEId",''),4) AS "JETrsId" ,
	      'UJOUR' AS "ObjType",
	      T0."DocEntry",
	      T0."CreateTime",
	      T1."LineId"+1 "Line_ID",
	      N'#未过账草稿# '||IFNULL(T1."U_LineMemo",''),
	      T1."U_ControlAcct",
	      IFNULL(T1."U_Debit",0),
	      IFNULL(T1."U_Credit",0),
	      IFNULL(T1."U_Debit",0)-IFNULL(T1."U_Credit",0),
	      T1."U_ProfitCode"||N' - '||T3."PrcName" "OcrCode1",
	      T1."U_OcrCode2"||N' - '||T4."PrcName" "OcrCode2",
	      T1."U_OcrCode3"||N' - '||T5."PrcName" "OcrCode3",
	      T1."U_OcrCode4"||N' - '||T6."PrcName" "OcrCode4",
	      T1."U_OcrCode5"||N' - '||T7."PrcName" "OcrCode5",
	      T1."U_AcctCode"||N' - '||T8."CardName" "CardCode"
   FROM "@U_JOURNALENTRY" T0
	JOIN "@U_JOURNALENTRY1" T1 ON T1."DocEntry" = T0."DocEntry" AND T0."U_Status" = 'O' 
	JOIN OACT T2 ON T1."U_ControlAcct" = T2."AcctCode"
	LEFT JOIN OPRC T3 ON T1."U_ProfitCode" = T3."PrcCode"
	LEFT JOIN OPRC T4 ON T1."U_OcrCode2" = T4."PrcCode"
	LEFT JOIN OPRC T5 ON T1."U_OcrCode3" = T5."PrcCode"
	LEFT JOIN OPRC T6 ON T1."U_OcrCode4" = T6."PrcCode"
	LEFT JOIN OPRC T7 ON T1."U_OcrCode5" = T7."PrcCode"
	LEFT JOIN OCRD T8 ON T1."U_AcctCode" = T8."CardCode"
   WHERE T1."U_ControlAcct" LIKE IFNULL(:AcctCode,'%')||'%' AND IFNULL('[%3]','N') = 'Y' 
	 AND T0."U_RefDate" BETWEEN :StartDate AND :EndDate AND T0."U_BPLId"=:BPLId 
	 AND T2."FrozenFor" <> 'Y'
	 --AND (T2."U_IsHidAct" = 'N' AND (IFNULL(T2."BPLId",'') = '' OR T2."BPLId" = 1))
)
WHERE 1=1
ORDER BY "RefDate","TransId","CreateTime","Line_ID";
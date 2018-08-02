CREATE PROCEDURE "U_PC_JournalEntryNumberU_JEPRNT"
(
IN JETrsIdFrom NVARCHAR(10),    --指定的凭证号
IN JETrsIdTo NVARCHAR(10),    --指定的凭证号
IN DocType NVARCHAR(1),		--指定的凭证类型
IN BPLId INT,				--数据界面分支
IN FcCode NVARCHAR(7)
)
LANGUAGE SQLSCRIPT
AS
BEGIN
	PRINT_TEMP = 
		--按需填制 / 按月合并 的查询 U_FOJDT
		SELECT T0."TransID",
			   '第'||T0."TransID"||'号' "ChrId",
			   T0."DocType",
			   T0."DocTName",
			   T0."FcCode",
			   T0."BPLId",
			   T2."BPLName",
			   T0."RefDate",
			   T0."Creator",
			   T0."Approver",
			   T3."MainCurncy",
			   T1."LineMemo",
			   T5."AcctName" "AcctName5",
			   T1."AcctName" "AcctName1",
			   T1."CardName",
			   case when T1."AcctName" like '%-%' then RIGHT(T1."AcctName",length(T1."AcctName") - instr(T1."AcctName",'-',-1,1)) ||'-'||T1."AcctCode" else T1."AcctName"||'-'||T1."AcctCode" END as "Name" ,
			   case when T5."AcctName" like '%-%' then LEFT(T5."AcctName", instr(T5."AcctName",'-',0,1)-1)||'-'||substr(T1."AcctCode",0,4) else T5."AcctName" ||'-'||T1."AcctCode" end  as "Code" ,
	          -- row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID") as rownum,
	          -- T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId")||ceil((row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID"))/5) as pagenum,  
			   REPLACE(TO_DATE(T0."RefDate"), '-','   ') "StrDate",
			   CASE WHEN T3."MainCurncy" ='RMB' THEN '人民币'  END "Currency",
			   CASE WHEN T1."Debit" = 0.00 THEN NULL ELSE T1."Debit" END "Debit",
			   CASE WHEN T1."Credit" = 0.00 THEN NULL ELSE T1."Credit" END "Credit",
			   T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId") "GroupIId"
			   
		FROM XN_FM.U_FOJDT T0
		INNER JOIN XN_FM.U_FJDT1 T1 ON T0."TransID" = T1."TransID" AND T0."BPLId" = T1."BPLId" AND T0."FcCode" = T1."FcCode" AND T0."DocType" =T1."DocType"  
		INNER JOIN XN_FM.OBPL T2 ON T0."BPLId" = T2."BPLId"
		LEFT JOIN XN_FM."OADM" T3 ON 1=1
		LEFT JOIN XN_FM."OACT" T5 ON T1."AcctCode"= T5."AcctCode" 		
		WHERE T0."BPLId" = :BPLId
		  AND T1."PrtType" IN('D','M')
		  AND T0."DocType" = :DocType
		  AND T0."FcCode" = :FcCode 
		  AND (T0."TransID" >= :JETrsIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  AND (T0."TransID" <= :JETrsIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )
		--ORDER BY T0."TransID",(row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId" order by T1."TransID"))
		        
		
		--未过账日记账草稿
		UNION ALL
		SELECT RIGHT('0000'||T0."U_DocJEId",4) "TransID",
			   '第'||RIGHT('0000'||T0."U_DocJEId",4)||'号'  "ChrId",
			   T0."U_DocType" "DocType",
			   CASE WHEN T0."U_DocType" = '1' THEN N'现金凭证' 
			      	WHEN T0."U_DocType" = '2' THEN N'银行凭证' 
			      	WHEN T0."U_DocType" = '3' THEN N'转账凭证' END "DocTName",
			   LEFT(TO_NVARCHAR(TO_DATE(T0."U_RefDate")),7) "FcCode",
			   T0."U_BPLId" "BPLId",
			   T2."BPLName",
			   TO_DATE(T0."U_RefDate") "RefDate",
			   T0."U_Creator" "Creator",
			   T0."U_Approver" "Approver",
			   T3."MainCurncy",
			   T1."U_LineMemo" "LineMemo",
			   T5."AcctName" 
			   || CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName5",
			   T1."U_AcctName"
			   || CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName1",
			   T31."CardName",
			   case when T1."U_AcctName" like '%-%' then RIGHT(T1."U_AcctName",length(T1."U_AcctName") - instr(T1."U_AcctName",'-',-1,1)) ||'-'||T1."U_ControlAcct" else T1."U_AcctName"||'-'||T1."U_ControlAcct" END as "Name" ,
			   case when T5."AcctName" like '%-%' then LEFT(T5."AcctName", instr(T5."AcctName",'-',0,1)-1)||'-'||substr(T1."U_ControlAcct",0,4) else T5."AcctName" ||'-'||T1."U_ControlAcct" end  as "Code" ,
	          -- row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID") as rownum,
	          -- T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId")||ceil((row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID"))/5) as pagenum,   
			   REPLACE(TO_DATE(T0."U_RefDate"), '-','   ') "StrDate",
			   CASE WHEN T3."MainCurncy" ='RMB' THEN '人民币'  END "Currency",
			   CASE WHEN T1."U_Debit" = 0.00 THEN NULL ELSE T1."U_Debit" END "Debit",
			   CASE WHEN T1."U_Credit" = 0.00 THEN NULL ELSE T1."U_Credit" END "Credit",
			   T0."U_DocJEId"||T0."U_DocType"||LEFT(TO_NVARCHAR(TO_DATE(T0."U_RefDate")),7)||TO_NVARCHAR(T0."U_BPLId") "GroupIId"
			   
		FROM XN_FM."@U_JOURNALENTRY" T0
		INNER JOIN XN_FM."@U_JOURNALENTRY1" T1 ON T0."DocEntry" = T1."DocEntry"
		INNER JOIN XN_FM.OBPL T2 ON T0."U_BPLId" = T2."BPLId"
		LEFT JOIN XN_FM."OADM" T3 ON 1=1
		LEFT JOIN XN_FM."OACT" T5 ON T1."U_ControlAcct" = T5."AcctCode" 	
		LEFT JOIN XN_FM.OPRC T21 ON T1."U_ProfitCode" = T21."PrcCode"
		LEFT JOIN XN_FM.OPRC T22 ON T1."U_OcrCode2" = T22."PrcCode"
		LEFT JOIN XN_FM.OPRC T23 ON T1."U_OcrCode3" = T23."PrcCode"
		LEFT JOIN XN_FM.OPRC T24 ON T1."U_OcrCode4" = T24."PrcCode"
		LEFT JOIN XN_FM.OPRC T25 ON T1."U_OcrCode5" = T25."PrcCode"
		LEFT JOIN XN_FM.OCRD T31 ON T1."U_AcctCode" = T31."CardCode"	
		WHERE T0."U_BPLId" = :BPLId
		  AND T0."U_Status" = 'O'
		  AND T0."U_DocType" = :DocType
		  AND LEFT(TO_NVARCHAR(TO_DATE(T0."U_RefDate")),7) = :FcCode 
		  AND (RIGHT('0000'||T0."U_DocJEId",4) >= :JETrsIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  AND (RIGHT('0000'||T0."U_DocJEId",4) <= :JETrsIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )
		--ORDER BY RIGHT('0000'||T0."U_DocJEId",4),( row_number() over(partition by RIGHT('0000'||T0."U_DocJEId",4),T0."U_DocType",LEFT(TO_NVARCHAR(TO_DATE(T0."U_RefDate")),7),T0."U_BPLId" order by RIGHT('0000'||T0."U_DocJEId",4)))
		 
		
		--从不合并查询日记帐分录 30,24,46
		UNION ALL
		SELECT T0."U_TransID",
			   '第'||T0."U_TransID"||'号' "ChrId",
			   T0."U_DocType" "DocType",
			   CASE WHEN T0."U_DocType" = '1' THEN N'现金凭证' 
			      	WHEN T0."U_DocType" = '2' THEN N'银行凭证' 
			      	WHEN T0."U_DocType" = '3' THEN N'转账凭证' END "DocTName",
			   T4."Code" "FcCode",
			   T1."BPLId",
			   T2."BPLName",
			   TO_DATE(T0."RefDate") "RefDate",
			   CASE WHEN T0."TransType" = '30' AND T7."U_TransId" IS NOT NULL THEN T7."U_Creator"
				  	WHEN T0."TransType" <> '30' AND T99."U_PrtType" = 'N' THEN T8."U_NAME" ELSE N'自动过账' END "Creator",
			   CASE WHEN T0."TransType" = '30' AND T7."U_TransId" IS NOT NULL THEN T7."U_Approver" 
				  																		   ELSE N'自动过账' END "Approver",
			   T3."MainCurncy",
			   CASE WHEN ( (T0."TransType" = '30') OR (T0."TransType" <> '30' AND IFNULL(T1."U_LineMemo",'')<>'') ) THEN T1."U_LineMemo" ELSE T1."LineMemo" END "LineMemo" ,
			   T5."AcctName"
			   || CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName5",
			   T5."AcctName"
			   || CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName1",
			   T31."CardName" ,
			   case when T5."AcctName" like '%-%' then RIGHT(T5."AcctName",length(T5."AcctName") - instr(T5."AcctName",'-',-1,1)) ||'-'||T1."Account" else T5."AcctName"||'-'||T1."Account" END as "Name" ,
			   case when T5."AcctName" like '%-%' then LEFT(T5."AcctName", instr(T5."AcctName",'-',0,1)-1)||'-'||substr(T1."Account",0,4) else T5."AcctName" ||'-'||T1."Account" end  as "Code" ,
	          -- row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID") as rownum,
	          -- T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId")||ceil((row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID"))/5) as pagenum,  
			   REPLACE(TO_DATE(T0."RefDate"), '-','   ') "StrDate",
			   CASE WHEN T3."MainCurncy" ='RMB' THEN '人民币'  END "Currency",
			   CASE WHEN T1."Debit" = 0.00 THEN NULL ELSE T1."Debit" END "Debit",
			   CASE WHEN T1."Credit" = 0.00 THEN NULL ELSE T1."Credit" END "Credit",
			   T0."U_TransID"||T0."U_DocType"||T4."Code"||TO_NVARCHAR(T1."BPLId") "GroupIId"
			   
		FROM XN_FM.OJDT T0
		INNER JOIN XN_FM.JDT1 T1 ON T0."TransId" = T1."TransId"
		INNER JOIN XN_FM.OBPL T2 ON T1."BPLId" = T2."BPLId"
		INNER JOIN XN_FM.OFPR T4 ON T0."RefDate" BETWEEN T4."F_RefDate" AND T4."T_RefDate"
		LEFT JOIN XN_FM."OADM" T3 ON 1=1
		LEFT JOIN XN_FM."OACT" T5 ON T1."Account"= T5."AcctCode" 		
		LEFT JOIN XN_FM.OJDT T10 ON T0."TransId" = T10."StornoToTr" 
		LEFT JOIN XN_FM."@U_FPRT1" T99 ON T0."TransType"  = T99."U_ObjType" AND TO_NVARCHAR(T1."BPLId") = T99."Code"    --获取参与存档凭证号计算的单据类型
		LEFT JOIN (SELECT DISTINCT "U_TransId","U_Creator","U_Approver" FROM XN_FM."@U_JOURNALENTRY" ) T7 ON T0."TransId" = T7."U_TransId"
		LEFT JOIN XN_FM.OUSR T8 ON T0."UserSign" = T8."USERID" 
		LEFT JOIN XN_FM.OPRC T21 ON T1."ProfitCode" = T21."PrcCode"
		LEFT JOIN XN_FM.OPRC T22 ON T1."OcrCode2" = T22."PrcCode"
		LEFT JOIN XN_FM.OPRC T23 ON T1."OcrCode3" = T23."PrcCode"
		LEFT JOIN XN_FM.OPRC T24 ON T1."OcrCode4" = T24."PrcCode"
		LEFT JOIN XN_FM.OPRC T25 ON T1."OcrCode5" = T25."PrcCode"
		LEFT JOIN XN_FM.OCRD T31 ON T1."ShortName" = T31."CardCode"
		WHERE T1."BPLId" = :BPLId
		  AND T99."U_PrtType" = 'N'
		  AND T0."StornoToTr" IS NULL			--过滤掉生成的冲销分录
		  AND T10."StornoToTr" IS NULL     	    --只返回未被冲销的分录
		  AND T0."U_DocType" = :DocType
		  AND T4."Code" = :FcCode 
		  AND (T0."U_TransID" >= :JETrsIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  AND (T0."U_TransID" <= :JETrsIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )
		--ORDER BY T0."U_TransID",(row_number() over(partition by T0."U_TransID",T0."U_DocType",T4."Code",T1."BPLId" order by T0."U_TransID"))
		        
		;

	SELECT *
	FROM :PRINT_TEMP T0
	WHERE 1 = 1
	ORDER BY --T0."TransID",
	--T0."Debit",
   	T0."Credit";
	
	  
END ;
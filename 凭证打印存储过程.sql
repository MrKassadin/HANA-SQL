ALTER PROCEDURE "U_PC_JournalEntryNumberU_JEPRNT"
(
IN JETrsIdFrom NVARCHAR(1000),    --指定的凭证号
IN JETrsIdTo NVARCHAR(1000),      --指定的凭证号
IN DocType NVARCHAR(1),		--指定的凭证类型
IN BPLId INT,				--数据界面分支
IN FcCode NVARCHAR(7),
IN Creator NVARCHAR(20),
IN Approver NVARCHAR(20)
)
LANGUAGE SQLSCRIPT
AS
BEGIN
    
    DECLARE TransIdFrom NVARCHAR(4);
    DECLARE TransIdTo NVARCHAR(4);
    --由于参数不能更改,赋值给临时变量
	DECLARE InputStr3 NVARCHAR(2000) := ','||JETrsIdFrom||',';  
	DECLARE InputStr4 NVARCHAR(2000) := ','||JETrsIdTo||',';
	DECLARE Split1 char(1) ; 
	Split1 := ',';  --以逗号分开 

	--JETrsIdFrom:循环截取分割符字符串
	CREATE LOCAL TEMPORARY TABLE #IdTemp_3 ("Code" NVARCHAR(10));
	WHILE LOCATE(:InputStr3,:Split1) <> 0 DO
		IF SUBSTRING(:InputStr3,1,LOCATE(:InputStr3,:Split1)-1) <> '' THEN
			INSERT INTO #IdTemp_3
			VALUES(SUBSTRING(:InputStr3,0,LOCATE(:InputStr3,:Split1)-1));
		END IF;
		InputStr3 := SUBSTRING(:InputStr3,LOCATE(:InputStr3,:Split1)+1,LENGTH(:InputStr3)-LOCATE(:InputStr3,:Split1));
	END WHILE;
	
	--JETrsIdTo:循环截取分割符字符串
	CREATE LOCAL TEMPORARY TABLE #IdTemp_4 ("Code" NVARCHAR(10));
	WHILE LOCATE(:InputStr4,:Split1) <> 0 DO
		IF SUBSTRING(:InputStr4,1,LOCATE(:InputStr4,:Split1)-1) <> '' THEN
			INSERT INTO #IdTemp_4
			VALUES(SUBSTRING(:InputStr4,0,LOCATE(:InputStr4,:Split1)-1));
		END IF;
		InputStr4 := SUBSTRING(:InputStr4,LOCATE(:InputStr4,:Split1)+1,LENGTH(:InputStr4)-LOCATE(:InputStr4,:Split1));
	END WHILE;
	
    --赋值起始值与结束值
    SELECT IFNULL(MAX(RIGHT(N'0000'||"Code",4)),'') INTO TransIdFrom FROM #IdTemp_3 ;
	SELECT IFNULL(MIN(RIGHT(N'0000'||"Code",4)),'') INTO TransIdTo FROM #IdTemp_4 ;
    
    --SELECT * FROM #IdTemp_3;
    --SELECT * FROM #IdTemp_4;
    --SELECT :TransIdFrom FROM DUMMY;
    --SELECT :TransIdTo FROM DUMMY;
    
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
			   NULL "AcctName5",
			   T1."AcctName" "AcctName1",
			   CASE WHEN T1."CardName" ='' THEN '' ELSE N'/'||T1."CardName" END "CardName",
  
			   CASE WHEN T1."AcctName" LIKE '%-%' THEN RIGHT(T1."AcctName",LENGTH(T1."AcctName") - INSTR(T1."AcctName",'-',-1,1)) 
			   ||'-'
			   ||T1."AcctCode" ELSE T1."AcctName"
			   ||'-'
			   ||T1."AcctCode" END as "Name" ,
			    
			   CASE WHEN T5."AcctName" LIKE '%-%' THEN LEFT(T5."AcctName", instr(T5."AcctName",'-',0,1)-1)||'-'||SUBSTR(T1."AcctCode",0,4) ELSE T5."AcctName" ||'-'||T1."AcctCode" END  as "Code" ,
	          -- row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID") as rownum,
	          -- T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId")||ceil((row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID"))/5) as pagenum,  
			   REPLACE(TO_DATE(T0."RefDate"), '-','   ') "StrDate",
			   CASE WHEN T3."MainCurncy" ='RMB' THEN '人民币'  END "Currency",
			   CASE WHEN T1."Debit" = 0.00 THEN NULL ELSE T1."Debit" END "Debit",
			   CASE WHEN T1."Credit" = 0.00 THEN NULL ELSE T1."Credit" END "Credit",
			   T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId") "GroupIId",
			   N'合并' "来源",
			   T1."LineID" "LineID",
			   NULL "TransType"	   
			   		   
		FROM "XN_FM".U_FOJDT T0
		INNER JOIN "XN_FM".U_FJDT1 T1 ON T0."TransID" = T1."TransID" AND T0."BPLId" = T1."BPLId" AND T0."FcCode" = T1."FcCode" AND T0."DocType" =T1."DocType"  
		INNER JOIN "XN_FM".OBPL T2 ON T0."BPLId" = T2."BPLId"
		LEFT JOIN "XN_FM"."OADM" T3 ON 1=1
		LEFT JOIN "XN_FM"."OACT" T5 ON T1."AcctCode"= T5."AcctCode" 		
		WHERE T0."BPLId" = :BPLId
		  AND T1."PrtType" IN('D','M')
		  AND T0."DocType" = :DocType
		  AND T0."FcCode" = :FcCode 
		  --AND (T0."TransID" >= :JETrsIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  --AND (T0."TransID" <= :JETrsIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )		  
		  AND ( T0."TransID" IN (SELECT IFNULL(RIGHT(N'0000'||"Code",4),'') FROM #IdTemp_3) OR T0."TransID" >= :TransIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  AND ( T0."TransID" IN (SELECT IFNULL(RIGHT(N'0000'||"Code",4),'') FROM #IdTemp_4) OR T0."TransID" <= :TransIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )		  
		  AND (T0."Creator" LIKE '%'||:Creator||'%' OR :Creator = '' OR :Creator IS NULL)
		  AND (T0."Approver" LIKE '%'||:Approver||'%' OR :Approver = '' OR :Approver IS NULL)
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
			   CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END		--部门
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END	--车间	
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END	--维度3
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END	--辅助核算
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName5",
			   CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName1",
			   case when T31."CardName" = '' then '' else N'/'||T31."CardName" end "CardName",																	--业务伙伴
			   case when T1."U_AcctName" like '%-%' then RIGHT(T1."U_AcctName",length(T1."U_AcctName") - instr(T1."U_AcctName",'-',-1,1)) ||'-'||T1."U_ControlAcct" else T1."U_AcctName"||'-'||T1."U_ControlAcct" END as "Name" ,
			   case when T5."AcctName" like '%-%' then LEFT(T5."AcctName", instr(T5."AcctName",'-',0,1)-1)||'-'||substr(T1."U_ControlAcct",0,4) else T5."AcctName" ||'-'||T1."U_ControlAcct" end  as "Code" ,
	          -- row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID") as rownum,
	          -- T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId")||ceil((row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID"))/5) as pagenum,   
			   REPLACE(TO_DATE(T0."U_RefDate"), '-','   ') "StrDate",
			   CASE WHEN T3."MainCurncy" ='RMB' THEN '人民币'  END "Currency",
			   CASE WHEN T1."U_Debit" = 0.00 THEN NULL ELSE T1."U_Debit" END "Debit",
			   CASE WHEN T1."U_Credit" = 0.00 THEN NULL ELSE T1."U_Credit" END "Credit",
			   T0."U_DocJEId"||T0."U_DocType"||LEFT(TO_NVARCHAR(TO_DATE(T0."U_RefDate")),7)||TO_NVARCHAR(T0."U_BPLId") "GroupIId",
			   N'未过账' "来源",
			   T1."LineId" "LineID",
			   NULL "TransType"
			   
		FROM "XN_FM"."@U_JOURNALENTRY" T0
		INNER JOIN "XN_FM"."@U_JOURNALENTRY1" T1 ON T0."DocEntry" = T1."DocEntry"
		INNER JOIN "XN_FM".OBPL T2 ON T0."U_BPLId" = T2."BPLId"
		LEFT JOIN "XN_FM"."OADM" T3 ON 1=1
		LEFT JOIN "XN_FM"."OACT" T5 ON T1."U_ControlAcct" = T5."AcctCode" 	
		LEFT JOIN "XN_FM".OPRC T21 ON T1."U_ProfitCode" = T21."PrcCode"
		LEFT JOIN "XN_FM".OPRC T22 ON T1."U_OcrCode2" = T22."PrcCode"
		LEFT JOIN "XN_FM".OPRC T23 ON T1."U_OcrCode3" = T23."PrcCode"
		LEFT JOIN "XN_FM".OPRC T24 ON T1."U_OcrCode4" = T24."PrcCode"
		LEFT JOIN "XN_FM".OPRC T25 ON T1."U_OcrCode5" = T25."PrcCode"
		LEFT JOIN "XN_FM".OCRD T31 ON T1."U_AcctCode" = T31."CardCode"	
		WHERE T0."U_BPLId" = :BPLId
		  AND T0."U_Status" = 'O'
		  AND T0."U_DocType" = :DocType
		  AND LEFT(TO_NVARCHAR(TO_DATE(T0."U_RefDate")),7) = :FcCode 
		  --AND (RIGHT('0000'||T0."U_DocJEId",4) >= :JETrsIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  --AND (RIGHT('0000'||T0."U_DocJEId",4) <= :JETrsIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )
		  AND ( RIGHT('0000'||T0."U_DocJEId",4) IN (SELECT IFNULL(RIGHT(N'0000'||"Code",4),'') FROM #IdTemp_3) OR RIGHT('0000'||T0."U_DocJEId",4) >= :TransIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  AND ( RIGHT('0000'||T0."U_DocJEId",4) IN (SELECT IFNULL(RIGHT(N'0000'||"Code",4),'') FROM #IdTemp_4) OR RIGHT('0000'||T0."U_DocJEId",4) <= :TransIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )		  
		  AND (T0."U_Creator" LIKE '%'||:Creator||'%' OR :Creator = '' OR :Creator IS NULL)
		  AND (T0."U_Approver" LIKE '%'||:Approver||'%' OR :Approver = '' OR :Approver IS NULL)
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
			   CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName5",
			   CASE WHEN T21."PrcCode" IS NOT NULL THEN N' /'||T21."PrcName" ELSE N'' END
			   || CASE WHEN T22."PrcCode" IS NOT NULL THEN N' /'||T22."PrcName" ELSE N'' END
			   || CASE WHEN T23."PrcCode" IS NOT NULL THEN N' /'||T23."PrcName" ELSE N'' END
			   || CASE WHEN T24."PrcCode" IS NOT NULL THEN N' /'||T24."PrcName" ELSE N'' END
			   || CASE WHEN T25."PrcCode" IS NOT NULL THEN N' /'||T25."PrcName" ELSE N'' END "AcctName1",
			   case when T31."CardName" = '' then '' else N'/'||T31."CardName" end "CardName",
			   case when T5."AcctName" like '%-%' then RIGHT(T5."AcctName",length(T5."AcctName") - instr(T5."AcctName",'-',-1,1)) ||'-'||T1."Account" else T5."AcctName"||'-'||T1."Account" END as "Name" ,
			   case when T5."AcctName" like '%-%' then LEFT(T5."AcctName", instr(T5."AcctName",'-',0,1)-1)||'-'||substr(T1."Account",0,4) else T5."AcctName" ||'-'||T1."Account" end  as "Code" ,
	          -- row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID") as rownum,
	          -- T0."TransID"||T0."DocType"||T0."FcCode"||TO_NVARCHAR(T0."BPLId")||ceil((row_number() over(partition by T0."TransID",T0."DocType",T0."FcCode",T0."BPLId"  order by T1."TransID"))/5) as pagenum,  
			   REPLACE(TO_DATE(T0."RefDate"), '-','   ') "StrDate",
			   CASE WHEN T3."MainCurncy" ='RMB' THEN '人民币'  END "Currency",
			   CASE WHEN T1."Debit" = 0.00 THEN NULL ELSE T1."Debit" END "Debit",
			   CASE WHEN T1."Credit" = 0.00 THEN NULL ELSE T1."Credit" END "Credit",
			   T0."U_TransID"||T0."U_DocType"||T4."Code"||TO_NVARCHAR(T1."BPLId") "GroupIId",
			   N'不合并' "来源",
			   T1."Line_ID" "LineID",
			   T0."TransType" "TransType" 
			   
		FROM "XN_FM".OJDT T0
		INNER JOIN "XN_FM".JDT1 T1 ON T0."TransId" = T1."TransId"
		INNER JOIN "XN_FM".OBPL T2 ON T1."BPLId" = T2."BPLId"
		INNER JOIN "XN_FM".OFPR T4 ON T0."RefDate" BETWEEN T4."F_RefDate" AND T4."T_RefDate"
		LEFT JOIN "XN_FM"."OADM" T3 ON 1=1
		LEFT JOIN "XN_FM"."OACT" T5 ON T1."Account"= T5."AcctCode" 		
		LEFT JOIN "XN_FM".OJDT T10 ON T0."TransId" = T10."StornoToTr" 
		LEFT JOIN "XN_FM"."@U_FPRT1" T99 ON T0."TransType"  = T99."U_ObjType" AND TO_NVARCHAR(T1."BPLId") = T99."Code"    --获取参与存档凭证号计算的单据类型
		LEFT JOIN (SELECT DISTINCT "U_TransId","U_Creator","U_Approver" FROM "XN_FM"."@U_JOURNALENTRY" ) T7 ON T0."TransId" = T7."U_TransId"
		LEFT JOIN "XN_FM".OUSR T8 ON T0."UserSign" = T8."USERID" 
		LEFT JOIN "XN_FM".OPRC T21 ON T1."ProfitCode" = T21."PrcCode"
		LEFT JOIN "XN_FM".OPRC T22 ON T1."OcrCode2" = T22."PrcCode"
		LEFT JOIN "XN_FM".OPRC T23 ON T1."OcrCode3" = T23."PrcCode"
		LEFT JOIN "XN_FM".OPRC T24 ON T1."OcrCode4" = T24."PrcCode"
		LEFT JOIN "XN_FM".OPRC T25 ON T1."OcrCode5" = T25."PrcCode"
		LEFT JOIN "XN_FM".OCRD T31 ON T1."ShortName" = T31."CardCode"
		WHERE T1."BPLId" = :BPLId
		  AND T99."U_PrtType" = 'N'
		  AND T0."StornoToTr" IS NULL			--过滤掉生成的冲销分录
		  AND T10."StornoToTr" IS NULL     	    --只返回未被冲销的分录
		  AND T0."U_DocType" = :DocType
		  AND T4."Code" = :FcCode 
		  --AND (T0."U_TransID" >= :JETrsIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  --AND (T0."U_TransID" <= :JETrsIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )
		  AND ( T0."U_TransID" IN (SELECT IFNULL(RIGHT(N'0000'||"Code",4),'') FROM #IdTemp_3) OR T0."U_TransID" >= :TransIdFrom OR :JETrsIdFrom = '' OR :JETrsIdFrom IS NULL )
		  AND ( T0."U_TransID" IN (SELECT IFNULL(RIGHT(N'0000'||"Code",4),'') FROM #IdTemp_4) OR T0."U_TransID" <= :TransIdTo OR :JETrsIdTo = '' OR :JETrsIdTo IS NULL )		  
		  AND (CASE WHEN T0."TransType" = '30' AND T7."U_TransId" IS NOT NULL THEN T7."U_Creator"
				  	WHEN T0."TransType" <> '30' AND T99."U_PrtType" = 'N' THEN T8."U_NAME" ELSE N'自动过账' END LIKE '%'||:Creator||'%' OR :Creator = '' OR :Creator IS NULL)
		  AND (CASE WHEN T0."TransType" = '30' AND T7."U_TransId" IS NOT NULL THEN T7."U_Approver" 
				  																		   ELSE N'自动过账' END LIKE '%'||:Approver||'%' OR :Approver = '' OR :Approver IS NULL)
		--ORDER BY T0."U_TransID",(row_number() over(partition by T0."U_TransID",T0."U_DocType",T4."Code",T1."BPLId" order by T0."U_TransID"))		        
		;

	SELECT  SUBSTR("AcctName5",0, 23) AS "JQName",*	
	FROM :PRINT_TEMP T0
	WHERE 1 = 1
	ORDER BY T0."TransID" ASC,
			 CASE WHEN T0."来源"=N'合并' OR T0."TransType"=46 THEN ABS(T0."Debit") END DESC, --徐浩修改，合并凭证或付款凭证按照借方降序排列
			 CASE WHEN T0."来源"=N'合并' OR T0."TransType"=46 THEN ABS(T0."Credit") END DESC,--徐浩修改，合并凭证或付款凭证次要排序条件增加贷方降序排列
			 CASE T0."来源" WHEN N'不合并' THEN T0."LineID" END ASC,--徐浩修改，从不合并凭证按照JDT1表中Line_ID升序排列，确保打印单据与前台一致
			 CASE T0."来源" WHEN N'未过账' THEN T0."LineID" END ASC --徐浩修改，未过账凭证按照U_JOURNALENTRY1表中LineId升序排列，确保打印单据与前台一致,为条理清晰分行
			 --T0."Debit",
   	;
	
	DROP TABLE #IdTemp_3;
	DROP TABLE #IdTemp_4;
	
END ;
CREATE PROCEDURE "MTC_FI_AgAnalysisByBPBalance"
(
  IN BPLId 			INT,			--分支
  IN CardType 		NVARCHAR(1), 			--业务伙伴类型
  IN IntervalType	NVARCHAR(10),			--帐龄依据：P-过账日期，D-到期日，T-单据日期
  IN ToAgingDate 	DATE,					--账龄日期
  IN Code			NVARCHAR(20),			--区间值：将每个区间值  number1,number2,number3 拼接传入
  IN CardCodeFrom 	NVARCHAR(50),			--业务伙伴代码
  IN CardCodeTo 	NVARCHAR(50),			--业务伙伴代码
  IN ControlAct 	NVARCHAR(50),			--控制科目代码
  IN IsZeroBal		NVARCHAR(1),			--是否显示余额为0的纪录
  IN IsIncJV 		NVARCHAR(1),     		--是否包含凭单 
  IN DocDateFrom    DATE DEFAULT '',		--过账日期
  IN DocDateTo      DATE DEFAULT '',		--过账日期
  IN DueDateFrom    DATE DEFAULT '',		--到期日期
  IN DueDateTo      DATE DEFAULT '',		--到期日期
  IN TaxDateFrom    DATE DEFAULT '',		--单据日期
  IN TaxDateTo      DATE DEFAULT ''			--单据日期
 )
AS
BEGIN
	
	--查询管理器，调用此存储过程
	--CALL "MTC_FI_AgingAnalysisReportQry_01"( 
	--/*SELECT FROM OBPL T0 WHERE T0."BPLId" = [%0]*/'[%0]',
	--/*SELECT FROM "@U_COUQR" T1 WHERE T1."U_CardType" = [%1]*/'[%1]',
	--/*SELECT FROM "@U_COUQR" T6 WHERE T6."U_IntervalType" = [%2]*/'[%2]',
	--/*SELECT FROM "@U_COUQR" T5 WHERE T5."U_AgingDate" <= [%3]*/'[%3]',
	--/*SELECT FROM "@U_AGIN" T7 WHERE T7."Code" = [%4]*/'[%4]',
	--/*SELECT FROM OCRD T2 WHERE T2."CardCode" >= [%5]*/'[%5]',
	--/*SELECT FROM OCRD T3 WHERE T3."CardCode" <= [%6]*/'[%6]',
	--/*SELECT FROM OACT T4 WHERE T4."AcctCode" = [%7]*/'[%7]',
	--/*SELECT FROM "@U_COUQR" T8 WHERE T8."U_IsZeroBal" = [%8]*/'[%8]',
	--/*SELECT FROM "@U_COUQR" T9 WHERE T9."U_ISVOURCHER" = [%9]*/'[%9]',
	--/*SELECT FROM OJDT T10 WHERE T10."RefDate" >= [%10]*/'[%10]',
	--/*SELECT FROM OJDT T11 WHERE T11."RefDate" <= [%11]*/'[%11]',
	--/*SELECT FROM OJDT T12 WHERE T12."DueDate" >= [%12]*/'[%12]',
	--/*SELECT FROM OJDT T13 WHERE T13."DueDate" <= [%13]*/'[%13]',
	--/*SELECT FROM OJDT T14 WHERE T14."TaxDate" >= [%14]*/'[%14]',
	--/*SELECT FROM OJDT T15 WHERE T15."TaxDate" <= [%15]*/'[%15]' );
	
	DECLARE CNT     INT;
	DECLARE Bdays   INT;
	DECLARE Edays   INT;
	DECLARE Maxdays INT;
	DECLARE IntervalValu NVARCHAR(200);
	DECLARE AgDate  NVARCHAR(20) := TO_NVARCHAR(TO_DATE(:ToAgingDate,'YYYY-MM-DD')) ;
	DECLARE SqlStr  NVARCHAR(5000);
	--由于参数不能更改,赋值给临时变量
	DECLARE InputStr3 NVARCHAR(2000);
	DECLARE Split1 char(1) ; 
	Split1 := ',';  --以逗号分开 
	
	IF ( IFNULL(:CardType,'')='' OR  
		 IFNULL(:ToAgingDate,'1900-01-01')='1900-01-01' OR 
		 IFNULL(:IntervalType,'')='' OR 
		 IFNULL(:Code,'')='' ) 
	  THEN
	 	SELECT '请指定 业务伙伴类型，帐龄日期，帐龄依据，帐龄区间!' "提示信息" FROM DUMMY;	
		RETURN;
	END IF;		

	
	--帐龄区间Code
	AG_RANG = 
		SELECT IFNULL(CASE "U_R1Type" WHEN 'D' THEN "U_RANG1" WHEN 'M' THEN "U_RANG1"*30 WHEN 'Y' THEN "U_RANG1"*365 END,0) "RANG1",
			   IFNULL(CASE "U_R2Type" WHEN 'D' THEN "U_RANG2" WHEN 'M' THEN "U_RANG2"*30 WHEN 'Y' THEN "U_RANG2"*365 END,0) "RANG2", 
			   IFNULL(CASE "U_R3Type" WHEN 'D' THEN "U_RANG3" WHEN 'M' THEN "U_RANG3"*30 WHEN 'Y' THEN "U_RANG3"*365 END,0) "RANG3", 
			   IFNULL(CASE "U_R4Type" WHEN 'D' THEN "U_RANG4" WHEN 'M' THEN "U_RANG4"*30 WHEN 'Y' THEN "U_RANG4"*365 END,0) "RANG4", 
			   IFNULL(CASE "U_R5Type" WHEN 'D' THEN "U_RANG5" WHEN 'M' THEN "U_RANG5"*30 WHEN 'Y' THEN "U_RANG5"*365 END,0) "RANG5", 
			   IFNULL(CASE "U_R6Type" WHEN 'D' THEN "U_RANG6" WHEN 'M' THEN "U_RANG6"*30 WHEN 'Y' THEN "U_RANG6"*365 END,0) "RANG6", 
			   IFNULL(CASE "U_R7Type" WHEN 'D' THEN "U_RANG7" WHEN 'M' THEN "U_RANG7"*30 WHEN 'Y' THEN "U_RANG7"*365 END,0) "RANG7", 
			   IFNULL(CASE "U_R8Type" WHEN 'D' THEN "U_RANG8" WHEN 'M' THEN "U_RANG8"*30 WHEN 'Y' THEN "U_RANG8"*365 END,0) "RANG8", 
			   IFNULL(CASE "U_R9Type" WHEN 'D' THEN "U_RANG9" WHEN 'M' THEN "U_RANG9"*30 WHEN 'Y' THEN "U_RANG9"*365 END,0) "RANG9", 
			   IFNULL(CASE "U_R10Type" WHEN 'D' THEN "U_RANG10" WHEN 'M' THEN "U_RANG10"*30 WHEN 'Y' THEN "U_RANG10"*365 END,0) "RANG10"
		FROM "@U_AGIN" 
		WHERE "Code" = :Code;
	--SELECT * FROM :AG_RANG;
	
	--区间值
	SELECT "RANG1"||','||
		   "RANG2"||','||
		   "RANG3"||','||
		   "RANG4"||','||
		   "RANG5"||','||
		   "RANG6"||','||
		   "RANG7"||','||
		   "RANG8"||','||
		   "RANG9"||','||
		   "RANG10" 
	INTO IntervalValu FROM :AG_RANG;	
	--SELECT :IntervalValu FROM DUMMY;
	--SELECT REPLACE(:IntervalValu,',0','') FROM DUMMY;


	InputStr3 := ','|| REPLACE(:IntervalValu,',0','')||',';
	--IntervalValu:循环截取分割符字符串
	CREATE LOCAL TEMPORARY TABLE #T1 ("Id" INT,"Bdays" INT,"Edays" INT);
	WHILE LOCATE(:InputStr3,:Split1) <> 0 DO
		IF SUBSTRING(:InputStr3,1,LOCATE(:InputStr3,:Split1)-1) <> '' THEN
			INSERT INTO #T1
			VALUES(0,0,SUBSTRING(:InputStr3,0,LOCATE(:InputStr3,:Split1)-1));
		END IF;
		InputStr3 := SUBSTRING(:InputStr3,LOCATE(:InputStr3,:Split1)+1,LENGTH(:InputStr3)-LOCATE(:InputStr3,:Split1));
	END WHILE;
			
	--判断是否输入区间值
 	CNT := 0 ;
	SELECT IFNULL((SELECT COUNT(1) FROM #T1),0) INTO CNT FROM DUMMY ;
	IF :CNT = 0 THEN 
		SELECT N'请输入区间值!' "提示信息" FROM DUMMY;
		DROP TABLE #T1 ;
		RETURN;
	END IF; 
	
	--按照天数升序排序指定序号
	UPDATE T0
		SET T0."Id" = T1."Id"
	FROM #T1 T0
	INNER JOIN 
	 ( SELECT "Edays",ROW_NUMBER()OVER(ORDER BY "Edays") "Id"
	   FROM #T1
	   WHERE 1=1
	 ) T1 ON T0."Edays" = T1."Edays"
	WHERE 1=1;
	
	--更新起始天数值
	UPDATE T0
		SET T0."Bdays" = (SELECT U0."Edays"+1 FROM #T1 U0 WHERE U0."Id" = T0."Id"-1 )
	FROM  #T1 T0
	WHERE 1=1 AND T0."Id" > 1;
		
	--判断是否重复区间值
	CNT := 0 ;
	SELECT COUNT(1) INTO CNT 
	FROM #T1 T0 
	LEFT JOIN #T1 T1 ON T0."Edays" = T1."Edays" AND T0."Id" <> T1."Id" 
	WHERE T1."Bdays" IS NOT NULL;
	IF :CNT > 0 THEN 
		SELECT N'不允许输入重复区间值!' "提示信息" FROM DUMMY;
		DROP TABLE #T1 ;
		RETURN;
	END IF; 	
	
	--取最大天数加+1
	SELECT Max(T0."Edays")+1 INTO Maxdays FROM #T1 T0 ;	
	--SELECT * FROM #T1 ;	
	
	--过账日期等于帐龄日期
	DocDateTo := :ToAgingDate ;
	
	/*
	--Boyum查询条件界面默认为1753.01.01
	IF IFNULL(:DueDateTo,'') = '1753.01.01' THEN 
		DueDateTo := :ToAgingDate;
	ELSE 
		DueDateTo := :DueDateTo;
	END IF;
	
	IF IFNULL(:TaxDateTo,'') = '1753.01.01' THEN 
		TaxDateTo := :ToAgingDate;
	ELSE 
		TaxDateTo := :TaxDateTo;
	END IF;
	*/

		
	--AG_DETAIL = 
	CREATE LOCAL TEMPORARY TABLE #T0 
	("CardCode" 	NVARCHAR(30),
	 "CardName"     NVARCHAR(100),
	 "CardType"	    NVARCHAR(1),
	 "TransType"    NVARCHAR(10),
	 "Name"			NVARCHAR(30),
	 "TransId"		INT,
	 "RefDate"		DATE,
	 "BETWEENDAYS"  INT,
	 "AcctCode"		NVARCHAR(30),
	 "Debit"		DECIMAL(19,2),
	 "Credit"		DECIMAL(19,2),
	 "Amount"		DECIMAL(19,2),
	 "Balance"		DECIMAL(19,2),
	 "BPLId"		INT  );
	INSERT INTO #T0
	SELECT T1."CardCode",T1."CardName",T1."CardType",T0."TransType",T6."Name",
		   CASE WHEN T2."TransType" = '30' THEN T2."TransId" ELSE T2."BaseRef" END "TransId",
		   CASE WHEN IFNULL(:IntervalType,'P') = 'P' THEN T2."RefDate" WHEN :IntervalType = 'D' THEN T2."DueDate" WHEN :IntervalType = 'T' THEN T2."TaxDate" END "RefDate",
	       CASE WHEN IFNULL(:IntervalType,'P') = 'D' THEN 0 ELSE DAYS_BETWEEN(T0."RefDate",T0."DueDate") END "BETWEENDAYS",
	       T3."AcctCode",	   
	       T0."Debit",
	       T0."Credit",
	       IFNULL(T5."Amount",0) "Amount",
	       T0."Debit"-T0."Credit"-IFNULL(T5."Amount",0) "Balance",
	       T4."BPLId"
	FROM JDT1 T0
	 INNER JOIN OJDT T2 ON T0."TransId" = T2."TransId"
	 INNER JOIN OACT T3 ON T0."Account" = T3."AcctCode" AND T3."LocManTran" = 'Y'
	 INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" 
	 INNER JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
	 LEFT JOIN "@U_AOBJL" T6 ON T2."TransType" = T6."Code"
	 LEFT JOIN
	 ( SELECT U0."TransId",U0."TransRowId",
	 		  SUM(CASE WHEN U0."IsCredit"='D' THEN U0."ReconSum" ELSE 0 END-CASE WHEN U0."IsCredit"='C' THEN U0."ReconSum" ELSE 0 END) AS "Amount"
	   FROM ITR1 U0
	   INNER JOIN OITR U1 ON U0."ReconNum" = U1."ReconNum"
	   WHERE U1."ReconDate" <= :ToAgingDate
	   GROUP BY U0."TransId",U0."TransRowId"
	 ) T5 ON T0."TransId" = T5."TransId" AND T0."Line_ID" = T5."TransRowId"
	WHERE T0."BPLId" = :BPLId
	  AND T1."CardType" = :CardType
	  AND T2."RefDate" <= :ToAgingDate
	  AND ( T1."CardCode" >= :CardCodeFrom OR IFNULL(:CardCodeFrom,'') = '' )
	  AND ( T1."CardCode" <= :CardCodeTo OR IFNULL(:CardCodeTo,'') = '' )
	  --AND ( T2."RefDate" >= :DocDateFrom OR IFNULL(:DocDateFrom,'') = '' )
	  --AND ( T2."RefDate" <= :DocDateTo OR IFNULL(:DocDateTo,'') = '' )
	  --AND ( T2."DueDate" >= :DueDateFrom OR IFNULL(:DueDateFrom,'') = '' )
	  --AND ( T2."DueDate" <= :DueDateTo OR IFNULL(:DueDateTo,'') = '' )
	  --AND ( T2."TaxDate" >= :TaxDateFrom OR IFNULL(:TaxDateFrom,'') = '' )
	  --AND ( T2."TaxDate" <= :TaxDateTo OR IFNULL(:TaxDateTo,'') = '' )
	  AND ( T3."AcctCode" = :ControlAct OR IFNULL(:ControlAct,'') = '' ) 
			
	--日记帐凭单分录
	UNION ALL
	SELECT T1."CardCode",T1."CardName",T1."CardType",'28' "TransType",'日记帐凭单分录' "Name",
		   T2."TransId" "TransId",
		   CASE WHEN IFNULL(:IntervalType,'P') = 'P' THEN T2."RefDate" WHEN :IntervalType = 'D' THEN T2."DueDate" WHEN :IntervalType = 'T' THEN T2."TaxDate" END "RefDate",
		   CASE WHEN IFNULL(:IntervalType,'P') = 'D' THEN 0 ELSE DAYS_BETWEEN(T0."RefDate",T0."DueDate") END "BETWEENDAYS",
		   T3."AcctCode",			   
	       T0."Debit",
	       T0."Credit",
	       0 "Amount",
	       T0."Debit"-T0."Credit" "Balance",
	       T4."BPLId"
	FROM BTF1 T0
	 INNER JOIN OBTF T2 ON T0."TransId" = T2."TransId"
	 INNER JOIN OACT T3 ON T0."Account" = T3."AcctCode" AND T3."LocManTran" = 'Y'
	 INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" 
	 INNER JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
	WHERE T0."BPLId" = :BPLId
	  AND T2."BtfStatus"='O'
	  AND T1."CardType" = :CardType
	  AND T2."RefDate" <= :ToAgingDate
	  AND ( T1."CardCode" >= :CardCodeFrom OR IFNULL(:CardCodeFrom,'') = '' )
	  AND ( T1."CardCode" <= :CardCodeTo OR IFNULL(:CardCodeTo,'') = '' )
	  --AND ( T2."RefDate" >= :DocDateFrom OR IFNULL(:DocDateFrom,'') = '' )
	  --AND ( T2."RefDate" <= :DocDateTo OR IFNULL(:DocDateTo,'') = '' )
	  --AND ( T2."DueDate" >= :DueDateFrom OR IFNULL(:DueDateFrom,'') = '' )
	  --AND ( T2."DueDate" <= :DueDateTo OR IFNULL(:DueDateTo,'') = '' )
	  --AND ( T2."TaxDate" >= :TaxDateFrom OR IFNULL(:TaxDateFrom,'') = '' )
	  --AND ( T2."TaxDate" <= :TaxDateTo OR IFNULL(:TaxDateTo,'') = '' )
	  AND ( T3."AcctCode" = :ControlAct OR IFNULL(:ControlAct,'') = '' )  
	  AND IFNULL(:IsIncJV,'') = 'Y'		
	
	--定制化凭证草稿
	UNION ALL
	SELECT T1."CardCode",T1."CardName",T1."CardType",'UJOUR' "TransType",'日记帐分录-草稿' "Name",
		   T2."DocEntry" "TransId",
		   T2."U_RefDate",
		   0 "BETWEENDAYS",
		   T3."AcctCode",			   
	       IFNULL(T0."U_Debit",0),
	       IFNULL(T0."U_Credit",0),
	       0 "Amount",
	       IFNULL(T0."U_Debit",0)-IFNULL(T0."U_Credit",0) "Balance",
	       T4."BPLId"
	FROM "@U_JOURNALENTRY1" T0
	 INNER JOIN "@U_JOURNALENTRY" T2 ON T0."DocEntry" = T2."DocEntry"
	 INNER JOIN OACT T3 ON T0."U_ControlAcct" = T3."AcctCode" AND T3."LocManTran" = 'Y'
	 INNER JOIN OCRD T1 ON T0."U_AcctCode" = T1."CardCode" 
	 INNER JOIN OBPL T4 ON T2."U_BPLId" = T4."BPLId"
	WHERE T2."U_BPLId" = :BPLId
	  AND T2."U_Status" = 'O'
	  AND T1."CardType" = :CardType
	  AND T2."U_RefDate" <= :ToAgingDate
	  AND ( T1."CardCode" >= :CardCodeFrom OR IFNULL(:CardCodeFrom,'') = '' )
	  AND ( T1."CardCode" <= :CardCodeTo OR IFNULL(:CardCodeTo,'') = '' )
	  AND ( T2."U_RefDate" >= :DocDateFrom OR IFNULL(:DocDateFrom,'') = '' )
	  AND ( T2."U_RefDate" <= :DocDateTo OR IFNULL(:DocDateTo,'') = '' )
	  AND IFNULL(:IsIncJV,'') = 'Y'
	;
	
	
	--SELECT T0."CardCode" AS "客户代码",T1."CardName" AS "客户名称",SUM(T0."Balance") AS "期末余额"
	--FROM #T0 T0
    --INNER JOIN OCRD T1 ON T0."CardCode" = T1."CardCode"
    --WHERE 1=1
    --GROUP BY t0."CardCode",t1."CardName"
    --ORDER BY t0."CardCode" ;
    
	--SELECT * FROM #T1 ;
	
	
	--D-按天
	CNT := 0 ;
	SELECT IFNULL((SELECT COUNT(1) FROM #T0),0) INTO CNT FROM DUMMY;
	
	IF :CNT > 0 THEN
		/*
		DECLARE CURSOR CUR FOR
		SELECT "Bdays","Edays" FROM #T1 ORDER BY "Id" ASC;
		OPEN CUR;
		FETCH CUR INTO Bdays,Edays;
		SqlStr := '' ;
		WHILE NOT CUR::NOTFOUND DO				
			SqlStr = :SqlStr||' SUM(CASE WHEN DAYS_BETWEEN(T0."RefDate", '''||:ToAgingDate||''') BETWEEN '||:Bdays||' AND '||:Edays||' THEN T0."Balance" ELSE 0 END ) " '||'['||:Bdays||'-'||:Edays||']'||'天",' ;		 	
			FETCH CUR INTO Bdays,Edays;			
		END WHILE;		
		CLOSE CUR;
		
		SqlStr := ' SELECT CASE WHEN T1."CardType" = ''C'' THEN ''客户'' ELSE ''供应商'' END "类型"
						  ,T3."Name" "财务单元"
						  ,T0."CardCode" AS "客户代码"
					      ,T1."CardName" AS "客户名称"
					      ,IFNULL(T4."CardName",T1."CardName") "上级客户名称"
					      ,T2."SlpName" AS "业务员"
				 		  , SUM(T0."Balance") AS "期末余额" , '||
				  :SqlStr||
				' SUM(CASE WHEN DAYS_BETWEEN(T0."RefDate",'''||:AgDate||''') >= '||:Maxdays||' THEN T0."Balance" ELSE 0 END) "'||:Maxdays||'天以上"' ;
		
		IF IFNULL(:IsZeroBal,'N') = 'Y' THEN 
			SqlStr :=  :SqlStr ||
					' FROM #T0 T0
					  INNER JOIN OCRD T1 ON T0."CardCode" = T1."CardCode"
					  LEFT JOIN OSLP T2 ON T1."SlpCode" = T2."SlpCode"
					  LEFT JOIN "@U_CBPTY6" T3 ON T1."U_CustClass6" = T3."Code"
					  LEFT JOIN OCRD T4 ON T1."U_CtSubLvlCd"=T4."CardCode" 
					  WHERE 1=1
					  GROUP BY t0."CardCode",t1."CardName",T2."SlpName",T3."Name",IFNULL(T4."CardName",T1."CardName"),
					  		   CASE WHEN T1."CardType" = ''C'' THEN ''客户'' ELSE ''供应商'' END
					  ORDER BY t0."CardCode" ' ;
		ELSE 
			SqlStr :=  :SqlStr ||
					' FROM #T0 T0
					  INNER JOIN OCRD T1 ON T0."CardCode" = T1."CardCode"
					  LEFT JOIN OSLP T2 ON T1."SlpCode" = T2."SlpCode"
					  LEFT JOIN "@U_CBPTY6" T3 ON T1."U_CustClass6" = T3."Code"
					  LEFT JOIN OCRD T4 ON T1."U_CtSubLvlCd"=T4."CardCode" 
					  WHERE 1=1					  
					  GROUP BY t0."CardCode",t1."CardName",T2."SlpName",T3."Name",IFNULL(T4."CardName",T1."CardName"),
					  		   CASE WHEN T1."CardType" = ''C'' THEN ''客户'' ELSE ''供应商'' END
					  HAVING SUM(T0."Balance") <> 0 
					  ORDER BY t0."CardCode" ' ;
		END IF;
		*/
		
		--Edit By Shwan 20180517：修改为区分账期内与超期的账龄逻辑
		DECLARE CURSOR CUR FOR
		SELECT "Bdays","Edays" FROM #T1 ORDER BY "Id" ASC;
		OPEN CUR;
		FETCH CUR INTO Bdays,Edays;
		SqlStr := '' ;
		
		WHILE NOT CUR::NOTFOUND DO				
			SqlStr = :SqlStr||' SUM(CASE WHEN DAYS_BETWEEN(T0."RefDate", '''||:ToAgingDate||''') BETWEEN CASE WHEN '''||:IntervalType||''' <> ''D'' THEN '||:Bdays||' +IFNULL(T5."BETWEENDAYS",0)+1 ELSE '||:Bdays||' END AND CASE WHEN '''||:IntervalType||''' <> ''D'' THEN '||:Edays||' +IFNULL(T5."BETWEENDAYS",0)+1 ELSE '||:Edays||' END THEN T0."Balance" ELSE 0 END ) " '||'['||:Bdays||'-'||:Edays||']'||'天",' ;		 	
			FETCH CUR INTO Bdays,Edays;			
		END WHILE;		
		CLOSE CUR;
		
		SqlStr := ' SELECT CASE WHEN T1."CardType" = ''C'' THEN ''客户'' ELSE ''供应商'' END "类型"
						  ,T3."Name" "财务单元"
						  ,T0."CardCode" AS "客户代码"
					      ,T1."CardName" AS "客户名称"
					      ,IFNULL(T4."CardName",T1."CardName") "上级客户名称"
					      ,T2."SlpName" AS "业务员"
					      , SUM(T0."Balance") "期末余额"
					      , SUM(CASE WHEN '''||:IntervalType||''' = ''D'' THEN 0.00 ELSE CASE WHEN DAYS_BETWEEN(T0."RefDate",'''||:AgDate||''') <= IFNULL(T5."BETWEENDAYS",0) THEN T0."Balance" ELSE 0 END END) "账期内"'||    --以P：过账日期 或 T：单据日期查看时，区分账期内与账期外
				 		  ', SUM(T0."Balance")-IFNULL(SUM(CASE WHEN '''||:IntervalType||''' = ''D'' THEN NULL ELSE CASE WHEN DAYS_BETWEEN(T0."RefDate",'''||:AgDate||''') <= IFNULL(T5."BETWEENDAYS",0) THEN T0."Balance" ELSE 0 END END),0) AS "账期外" ,'||
				  :SqlStr||
				' SUM(CASE WHEN DAYS_BETWEEN(T0."RefDate",'''||:AgDate||''') >= CASE WHEN '''||:IntervalType||''' <> ''D'' THEN '||:Maxdays||' +IFNULL(T5."BETWEENDAYS",0)+1 ELSE '||:Maxdays||' END THEN T0."Balance" ELSE 0 END) "'||:Maxdays||'天以上"' ;
		
		IF IFNULL(:IsZeroBal,'N') = 'Y' THEN 
			SqlStr :=  :SqlStr ||
					' FROM #T0 T0
					  INNER JOIN OCRD T1 ON T0."CardCode" = T1."CardCode"
					  LEFT JOIN OSLP T2 ON T1."SlpCode" = T2."SlpCode"
					  LEFT JOIN "@U_CBPTY6" T3 ON T1."U_CustClass6" = T3."Code"
					  LEFT JOIN OCRD T4 ON T1."U_CtSubLvlCd"=T4."CardCode"  
					  LEFT JOIN (SELECT "CardCode",MAX("BETWEENDAYS") "BETWEENDAYS" FROM #T0 GROUP BY "CardCode") T5 ON T0."CardCode"=T5."CardCode"
					  WHERE 1=1
					  GROUP BY t0."CardCode",t1."CardName",T2."SlpName",T3."Name",IFNULL(T4."CardName",T1."CardName"),
					  		   CASE WHEN T1."CardType" = ''C'' THEN ''客户'' ELSE ''供应商'' END
					  ORDER BY t0."CardCode" ' ;
		ELSE 
			SqlStr :=  :SqlStr ||
					' FROM #T0 T0
					  INNER JOIN OCRD T1 ON T0."CardCode" = T1."CardCode"
					  LEFT JOIN OSLP T2 ON T1."SlpCode" = T2."SlpCode"
					  LEFT JOIN "@U_CBPTY6" T3 ON T1."U_CustClass6" = T3."Code"
					  LEFT JOIN OCRD T4 ON T1."U_CtSubLvlCd"=T4."CardCode" 
					  LEFT JOIN (SELECT "CardCode",MAX("BETWEENDAYS") "BETWEENDAYS" FROM #T0 GROUP BY "CardCode") T5 ON T0."CardCode"=T5."CardCode"  --取客户最大BETWEENDAYS判断是否在账期内
					  WHERE 1=1					  
					  GROUP BY t0."CardCode",t1."CardName",T2."SlpName",T3."Name",IFNULL(T4."CardName",T1."CardName"),
					  		   CASE WHEN T1."CardType" = ''C'' THEN ''客户'' ELSE ''供应商'' END
					  HAVING SUM(T0."Balance") <> 0 
					  ORDER BY t0."CardCode" ' ;
		END IF;	
		
		--SELECT :SqlStr FROM DUMMY;
		EXECUTE IMMEDIATE (:SqlStr); 
		
	END IF;
	 
	DROP TABLE #T1;
	DROP TABLE #T0 ;
	
END ;
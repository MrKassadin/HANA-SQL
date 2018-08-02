/*SELECT FROM OBPL T0 WHERE T0.BPLname=[%0];*/
/*SELECT FROM OFPR T1 WHERE T1.F_REFDATE=[%1]*/
/*SELECT FROM OFPR T2 WHERE T2.T_REFDATE=[%2]*/
/*SELECT FROM OCRD T5 WHERE t5."U_CustClass6" LIKE '%[%5]%';*/
/*SELECT FROM "OCRD" T4 WHERE T4."CardName" LIKE '%[%4]%';*/
/*SELECT FROM "@U_CAOCND" T3 WHERE T3.U_ConBatch = '[%3]'*/

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
DECLARE BDATE DATE;
DECLARE EDATE DATE;
DECLARE BPLId int;
DECLARE ISVOURCHER NVARCHAR(10);

ISVOURCHER := '[3%]';
BDATE:=[%1];
EDATE:=[%2];

select "BPLId" into BPLId from OBPL where "BPLName" = '[%0]' ;
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';

IF :CNT = 0 THEN
   SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;	
ELSE    
   SELECT  t2."Name" "财务单元",
		   t0."CardCode" "客户代码",
		   t0."CardName" "客户名称",
		   T3."SlpName"  "业务员",
	       SUM(CASE WHEN to_date(T0."RefDate") < :BDATE THEN t0."Debit" - t0."Credit" ELSE 0 END) "期初余额",
	       SUM(CASE WHEN to_date(T0."RefDate") BETWEEN :BDATE AND :EDATE THEN t0."Debit" ELSE 0 END) "本期应收",
	       SUM(CASE WHEN to_date(T0."RefDate") BETWEEN :BDATE AND :EDATE THEN t0."Credit" ELSE 0 END) "本期实收",
	       SUM(CASE WHEN (to_date(T0."RefDate") BETWEEN year(to_date(:EDATE,'YYYY-MM-DD'))||'-01-01' AND :EDATE ) THEN t0."Debit" ELSE 0 END) "本年累计应收",
	       SUM(CASE WHEN (to_date(T0."RefDate") BETWEEN year(to_date(:EDATE,'YYYY-MM-DD'))||'-01-01' AND :EDATE ) THEN t0."Credit" ELSE 0 END) "本年累计实收",
		   SUM(CASE WHEN to_date(T0."RefDate") < :BDATE THEN t0."Debit" - t0."Credit" ELSE 0 END) +
	       SUM(CASE WHEN to_date(T0."RefDate") BETWEEN :BDATE AND :EDATE THEN t0."Debit" ELSE 0 END) -
	       SUM(CASE WHEN to_date(T0."RefDate") BETWEEN :BDATE AND :EDATE THEN t0."Credit" ELSE 0 END) "期末余额"
	FROM 
	 (  SELECT T1."CardCode",
			   T1."CardName",
		       T0."Debit",T0."Credit",T0."RefDate",T4."BPLId",T0."TransId"
		FROM JDT1 T0
		 JOIN OCRD T1 ON T0."ShortName" = t1."CardCode" AND T1."CardType" = 'C'
		 JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
		WHERE (T0."Account" LIKE '1122%')
	    union all
		SELECT T1."CardCode",
			   T1."CardName",
		       T0."Debit",T0."Credit",T0."RefDate",T4."BPLId",T0."TransId"
		FROM BTF1 T0
		 JOIN obtf t2 on t0."TransId" = t2."TransId" AND T0."BatchNum" = T2."BatchNum"
		 JOIN OCRD T1 ON T0."ShortName" = t1."CardCode" AND T1."CardType" = 'C'
		 JOIN OBPL T4 ON T0."BPLId" = T4."BPLId"
		WHERE (T0."Account" LIKE '1122%' ) and t2."BtfStatus"='O' AND IFNULL(:ISVOURCHER,'N')='Y'
	  ) t0
	JOIN OCRD T1 ON T0."CardCode" = t1."CardCode"
	LEFT JOIN "@U_CBPTY6" T2 ON T1."U_CustClass6" = T2."Code"
	inner join OSLP T3 on T1."SlpCode"=T3."SlpCode"
	WHERE t0."BPLId"= :BPLId AND T0."RefDate" <= :EDate
	  AND ( T2."Name" LIKE '%[%5]%' OR '[%5]' = '' OR '[%5]' IS NULL )
	  AND ( T1."CardName" LIKE '%[%4]%' OR '[%4]' = '' OR '[%4]' IS NULL )
	GROUP BY t0."CardCode",t0."CardName",t2."Name",T3."SlpName"
	ORDER BY t0."CardCode" ;

END IF;
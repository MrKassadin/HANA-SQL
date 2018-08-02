select
	T1."BPLName" AS "分支名称",
	T1."Account" AS "科目编码",
	T2."AcctName" AS "科目名称",
	T1."ProfitCode" AS "部门代码",
	sum(T1."Debit") AS "借方发生额"
	--sum(T1."Credit") AS "贷方发生额"
from OJDT T0
inner join JDT1 T1 ON T1."TransId"=T0."TransId"
inner join OACT T2 ON T2."AcctCode"=T1."Account"
where
	T1."Account" like '6602%'
	and T0."RefDate" Between '2017-11-01' and '2017-11-30'
group by
	T1."BPLName",
	T1."Account",
	T2."AcctName",
	T1."ProfitCode"
order by T1."Account";
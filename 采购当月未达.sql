set schema XN_FM;
select
	distinct
	case 
		when T3."DocEntry" is null then N'货值发票未到'
		when T6."DocEntry" is null and T5."DocEntry" is not null then N'运费发票未到'
		when T3."DocEntry" is null and T6."DocEntry" is null then N'货值运费发票皆未到'
	END AS "发票状态"
	,T0."NumAtCard" AS "合同号"
	,T0."DocNum" AS "收货单号"
	,T0."CardName" AS "供应商名称"
	,left(T0."DocDate",10) AS "收货时间"
	,T1."U_OcrName" AS "工厂"
	--,case when (T2."U_RPONumber" is null or T2."Canceled"='Y') then N'质检未完成或收货已取消' else to_char(T2."DocEntry") end AS "质检单号"
	,T2."DocEntry" AS "质检单号"
	,ifnull(T2."U_FQty"-ifnull(T4."Quantity",0),0) AS "结算数量"
	,ifnull(T2."U_FPrice",0) AS "结算单价"
	,ifnull(T2."U_FAmt",0) AS "结算金额"
	,ifnull(T5."LineTotal",0) AS "运费金额"
from "OPDN" T0
	inner join PDN1 T1 on T0."DocEntry"=T1."DocEntry"
	inner join "@U_QASR" T2 on T0."DocNum"=T2."U_RPONumber"
	left join "RPD1" T4 on T4."BaseEntry"=T0."DocEntry"
	left join "PCH1" T3 on T3."BaseEntry"=T0."DocEntry"
	left join "IPF1" T5 on T5."BaseEntry"=T0."DocEntry"
	left join "PCH1" T6 on T6."BaseEntry"=T5."DocEntry"
where
	(T3."DocEntry" is null
	or (T6."DocEntry" is null and T5."DocEntry" is not null))
	--and T1."TargetType" not in (20,21)
	--and T1."TargetType" =21
	--and T2."U_RPONumber" is not null
	and T2."Canceled"<>'Y'
order by T0."DocNum" DESC;

select concat(N'到',NULL) from dummy;

select * from "@U_QASR" where "U_RQuantity"<>0;

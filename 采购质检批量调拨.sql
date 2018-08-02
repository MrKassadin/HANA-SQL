CREATE PROCEDURE "U_PC_WareHouseTransferDetails"
(
	BPLId int,
	BDate DATE,
	EDate DATE,
	CardCode NVARCHAR(30),
	WhsCode NVARCHAR(30)
)
LANGUAGE SQLSCRIPT
AS
BEGIN

 
	
	SELECT 'N' "选择"
			, T0."DocEntry" "质检化验单号"
			, t0."U_RPONumber" "采购收货单号"
			, T0."U_DocDate" "化验日期"
			, T0."U_CardCode" "供应商代码"
			, T0."U_CardName" "供应商名称"
			, T0."U_ItemCode" "物料编号"
			, T0."U_ItemName" "物料名称"
			, T1."WhsCode" "从仓库代码"
			, T1."WhsName" "从仓库名称"
			, T1."U_WhsCode" "至仓库代码"
			, T1."U_WhsName" "至仓库名称"
			, ifnull(T0."U_RPOQty",0) "采购入库数量"
			, ifnull(T2."Quantity",0) "采购退货数量"
			, ifnull(T0."U_RPOQty",0) - ifnull(T2."Quantity",0) "调拨数量"
			, ifnull(T0."U_RPOQty",0) - ifnull(T2."Quantity",0) "确认调拨数量"
			--, T0."U_NoticeNumber" "通知单号"
			--, T0."U_NoticeLineNum" "通知单行号"
			,CASE WHEN  T0."U_AssayResult"='Y' THEN '合格'
				  WHEN  T0."U_AssayResult"='N' THEN '异常'
				  WHEN  T0."U_AssayResult"='R' THEN '退货'	
			 ELSE '-'
			 END "化验结果"	
			, CASE WHEN T0."U_CheckResult" ='A' THEN '等待'
				   WHEN T0."U_CheckResult" ='B' THEN '进厂'
				   WHEN T0."U_CheckResult" ='C' THEN '退货'
			  ELSE '-'
			  END "核检结果"
	FROM "@U_QASR"  T0	--化验单表头
	left JOIN --根据进厂通知单获取仓库对应表
		(
			SELECT T0."DocEntry" "DocNum", T1."LineId"
					, T1."U_PurchNumer" "U_PurchNumber", T1."U_PurchLineNum" "U_PurchLineNum"
					, T1."U_WhsCode" "WhsCode",T1."U_WhsName" "WhsName"
					, IFNULL(IFNULL(T2."WhsCode",T5."WhsCode"),T6."WhsCode") "U_WhsCode"  --Edit by shawn:2017/10/09
					, IFNULL(IFNULL(T2."WhsName",T5."WhsName"),T6."WhsName") "U_WhsName"  --Edit by shawn:2017/10/09
					--, IFNULL(T2."WhsCode",T5."WhsCode") "U_WhsCode"
					--, IFNULL(T2."WhsName",T5."WhsName") "U_WhsName"
				--	, T2."WhsCode",T2."WhsName",T5."WhsCode",T5."WhsName"
			FROM "@U_AOGI" T0 --进厂通知单主表
			JOIN "@U_OGI1" T1 ON T0."DocEntry"=T1."DocEntry" --进厂通知单-物料信息页签
			JOIN OITM T3 ON T1."U_ItemCode"=T3."ItemCode" --物料主数据
			JOIN OITB T4 ON T3."ItmsGrpCod"=T4."ItmsGrpCod" --物料组
			LEFT JOIN OWHS T2 ON T1."U_WhsCode"=T2."U_WhsCode"  AND T4."U_ItemGrpType" IN ('B','C') AND T2."U_WhsType"='11' --连接仓库主数据,物料组为原料,仓库类型为原料良品仓库
			LEFT JOIN OWHS T5 ON T1."U_WhsCode"=T5."U_WhsCode"  AND T4."U_ItemGrpType"='G' AND T5."U_WhsType"='71' --连接仓库主数据,物料组为包装物,仓库类型为包装物仓库
			LEFT JOIN OWHS T6 ON T1."U_WhsCode"=T6."U_WhsCode"  AND T4."U_ItemGrpType" = 'A' AND T6."U_WhsType"='31' --连接仓库主数据,物料组为半成品，成品,仓库类型为成品仓库 //Edit by shawn:2017/10/09，加入半成品与成品的仓库连接
		)T1 ON T0."U_NoticeNumber"=T1."DocNum" AND T0."U_NoticeLineNum"=T1."LineId"	
	left join --获取采购退货单数据
	    (       
	        select t1."DocNum",t0."ItemCode",sum(t0."Quantity") as "Quantity"
            from RPD1 t0 inner join OPDN t1 on t0."BaseEntry" = t1."DocEntry"
            where t0."BaseType" = '20' --来源数据为采购收货
            Group by t1."DocNum",t0."ItemCode"
	     )t2 on t2."DocNum" = t0."U_RPONumber" --采购退货单号连接质检化验单入库单号
	WHERE  T0."U_IsTrans"='N' --是否生成调拨单为N
	       AND T0."Canceled"='N' --取消状态
	       AND T0."U_CheckResult"='B' --检核结果为进厂 
	       AND (IFNULL(T0."U_TransNum" ,0)=0)--调拨单号不能为0
		   AND T0."U_BPLId"=:BPLId AND T0."U_DocDate" BETWEEN IFNULL(:BDate,T0."U_DocDate") AND IFNULL(:EDate,T0."U_DocDate")--获取分支号/起始日期/结束日期
	       AND T0."U_CardCode" = IFNULL(:CardCode,T0."U_CardCode")--业务伙伴代码
		   AND T1."WhsCode" = IFNULL(:WhsCode,T1."WhsCode")--仓库代码
           and t1."WhsCode" not in ('F100024') --由于广西百跃农牧发展有限公司业务特殊无逻辑规则,采购的原料存在广西南宁仓库,因此无需进行库存调拨,代码对其仓库数据进行屏蔽
		   AND  T0."U_RPOQty"<>0 --入库数量不能为0
			;

END
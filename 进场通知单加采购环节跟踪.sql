drop procedure U_ToFactoryPDTrancert;
CREATE PROCEDURE U_ToFactoryPDTrancert(BPLId int,DateFro nvarchar(20),DateTo nvarchar(20),SCardName nvarchar(20))
LANGUAGE SQLSCRIPT
	AS
	BEGIN
SELECT  T2."NumAtCard" "采购合同号",T0."DocEntry" as "通知单号", T0."U_DocDate" as "单据日期", T0."U_CardCode", T0."U_CardName", 		
		T1."LineId" "通知单行号",T1."U_OcrName1" "部门代码" ,T1."U_WhsName" "仓库名称",T1."U_ItemCode", T1."U_ItemName", T1."U_CarNumber", T1."U_CarBatchNum", 
		T1."U_KgQty" as "预计数量", T3."PriceAfVAT" as "合同毛价",
		CASE WHEN T1."U_IsTest"='Y' THEN '是' WHEN T1."U_IsTest"='N' THEN '否' ELSE '' END "是否化验" 
		,CASE WHEN  T1."U_IsWeigh"='Y'THEN '是' WHEN T1."U_IsWeigh"='N'THEN '否' ELSE '' END "是否过磅" 
		,CASE WHEN T1."U_DevFeeMeth"='Z' THEN '自付' WHEN T1."U_DevFeeMeth"='D' THEN '垫付'ELSE '无' END "运费结算方式" 
		,CASE WHEN T1."U_IsStdPack"='Y' THEN '是' WHEN  T1."U_IsStdPack"='N' THEN '否' END "是否标包"
		, T1."U_PurchNumer" "采购订单号"
		,CASE WHEN  T1."U_MaCalType"='1' THEN '以供方' WHEN T1."U_MaCalType"='2' THEN '以需方' ELSE '无' END  "原料结算依据"
		,(CASE WHEN T0."U_PayMethod"='Z' THEN '自付' WHEN T0."U_PayMethod"='D' THEN '垫付' ELSE '无' end ) as "运费付款方式"
		,T1."U_DevFeePrice", T1."U_StdPackWeight" 
		,T4."U_NAME" "操作人"
FROM "@U_AOGI"  T0 		
LEFT JOIN "@U_OGI1"  T1 ON T0."DocEntry" = T1."DocEntry"		
LEFT JOIN OPOR T2 on T1."U_PurchNumer" = T2."DocNum"		
LEFT JOIN POR1 T3 ON T2."DocEntry"=T3."DocEntry" AND T1."U_PurchLineNum" =T3."LineNum" AND T1."U_ItemCode"=T3."ItemCode" 		
LEFT JOIN OUSR T4 ON T0."Creator"=T4."USER_CODE"		
WHERE (T0."U_DocDate" BETWEEN :DateFro AND :DateTo) --获取界面数值		
  AND T0."U_CardName" like '%'||:SCardName||'%'  --获取界面数值		
  AND T0."U_BPLId" = :BPLId; --获取界面数值																																
	END
	
select top 100 * from "@U_AOGI"

CALL "XN_FM_0707".U_ToFactoryPDTrancert (1,20170601,20170906,'朝阳') 

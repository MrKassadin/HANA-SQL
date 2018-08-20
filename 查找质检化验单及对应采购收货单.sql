SELECT T0."DocEntry" "质检化验单号",T0."CreateDate" "质检化验单日期",T0."CreateTime" "质检化验单时间"
,T1."DocNum" "收货单号",T1."DocDate" "收货日期",T1."DocTime" "收货时间"
FROM "@U_QASR" T0
INNER JOIN OPDN T1 ON T0."U_RPONumber"=T1."DocNum"
WHERE "U_NoticeNumber" IN (5023,5024);
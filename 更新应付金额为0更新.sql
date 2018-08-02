set schema XN_FM;


--select t0."DocNum",t1."ItemCode",t1."Quantity",t1."LineTotal",t1."U_PayQty",t1."U_PayPrice",t1."U_PayAmt"
Update t1 set t1."U_PayQty" = t1."Quantity",t1."U_PayAmt" = t1."LineTotal",t1."U_PayPrice" = t1."LineTotal"/t1."Quantity" --更新语句
from OPDN t0 inner join PDN1 t1 on t0."DocEntry" = t1."DocEntry"
where t0."DocNum" in ('2114','2161','2162','2163','2164','2165','2166');

Update t0 set t0."U_FPrice" = A."LineTotal"/A."Quantity",t0."U_FQty" = A."Quantity",t0."U_FAmt" = A."LineTotal"
--select t0."DocEntry",t0."U_FPrice",t0."U_FQty",t0."U_FAmt",A."Quantity",A."LineTotal",A."LineTotal"/A."Quantity" as "Price"
from "@U_QASR" t0 --质检化验单主表
left join --获取采购收货记录相关结算金额信息
(
select t0."DocNum",t1."ItemCode",t1."Quantity",t1."LineTotal",t1."U_PayQty",t1."U_PayPrice",t1."U_PayAmt"
from OPDN t0 inner join PDN1 t1 on t0."DocEntry" = t1."DocEntry"
where t0."DocNum" in ('2114','2161','2162','2163','2164','2165','2166')--采购收货单号清单
)A on t0."U_ItemCode" = A."ItemCode" and t0."U_RPONumber" = A."DocNum"
where t0."U_RPONumber" in ('2114','2161','2162','2163','2164','2165','2166');--采购收货单号清单
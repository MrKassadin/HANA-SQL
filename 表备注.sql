--查询下述表具体表结构SQL:
SET SCHEMA "SYS";
SELECT
T0."TABLE_NAME" "表名",
T0."TABLE_TYPE" "表类型",
T1."POSITION" "列次序",
T1."COLUMN_NAME" "列名",
T1."LENGTH" "列长度"
FROM CS_TABLES_ T0
INNER JOIN CS_COLUMNS_ T1 ON T0."TABLE_OID"=T1."TABLE_OID"
WHERE SCHEMA_NAME='XN_FM'
AND TABLE_NAME IN ('@U_ITMFMTOBRD')
ORDER BY T0."TABLE_OID",T1."POSITION";

select * from ODIM;
select * from OCCT;
select * from ORTT;
select * from OCUP;
select * from VTR2;
select * from AEXT;--费用类型
select * from OEXT;--费用类型
select * from OFRC;--财务报表主表
select * from FRC1;--财务报表子表
select * from OFRT;--财务报表模板列表
select * from OFYM;
select * from OACT order by "AcctCode";--科目表
select top 100 * from OJDT;--日记账分录表
select top 100 * from JDT1;--日记账分录子表

U_COPCT --物料月末成本表
U_COMOH --制造费用主表 PROCEDURE "MTC_COST_30OHDistributeToProduct_01"
U_CMOH1 --PROCEDURE "MTC_COST_30OHDistributeToProduct_01"
U_COWOR  --生产订单
U_CWOR1

OIVL--仓库交易日志
OITL--库存交易日志(只包括在物料主数据中设定了"管理物料方式"为序列号和批次的物料,管理物料方式为无的物料不存在这张表中)
ITL1--子表存储了序列号/批次交易明细
OBTL--库位交易日志(OIVL."LogEntry"=OBTL."ITLEntry")
OBTN--批次主数据
OBIN--库位主数据

OITW--仓库-物料现存表
OITB--物料组表

"@MTC_CCHKDB"--成本检查配置主表
"@MTC_CCHKDB1"--成本检查配置子表
"U_CCHKDB"--成本检查结果主表
"U_CCHKDB1"--成本检查结果子表
SELECT * FROM U_COILV;--物料级别表

SELECT * FROM "OGAR";--总账科目表.路径:管理-设置-财务-总账科目确定-总账科目确定-高级

"@U_OPIT"--工厂产品对应表主表,路径:工具-默认表格
"@U_PIT1"--工厂产品对应表子表

"OMRV"--库存重估

SELECT * FROM "@U_CIOTRN";--库存交易事务主表,看到对应事务的具体编码如'C6'


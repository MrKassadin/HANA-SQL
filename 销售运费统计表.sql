/*SELECT FROM OBPL T0 WHERE T0."BPLName"=[%0];*/
/*SELECT FROM "OFPR" T1 WHERE T1."F_RefDate" >=[%1];*/
/*SELECT FROM "OFPR" T2 WHERE T2."T_RefDate" <=[%2];*/
/*SELECT FROM OCRD T5 WHERE t5."U_CustClass6" LIKE '%[%5]%';*/ 

DECLARE USERCODE NVARCHAR(30);
DECLARE CNT INT;
DECLARE BPLId int;
select "BPLId" into BPLId from OBPL where "BPLName" = '[%0]';
SELECT TOP 1 T0."UserCode" into USERCODE FROM USR5 T0 WHERE "SessionID"=CURRENT_CONNECTION ORDER BY T0."Date" DESC,T0."Time" DESC;
SELECT COUNT(1) INTO CNT FROM USR6 T0 JOIN OBPL T1 ON T0."BPLId"=T1."BPLId" WHERE T0."UserCode"=:USERCODE AND T1."BPLName"='[%0]';

IF :CNT = 0 THEN
	SELECT '没有当前所选分支的权限！' MSG FROM DUMMY;	
ELSE
  Delry_TMP = 
    SELECT N'交货' "Type",N'销售出库' "TrsName",T6."PrcName",T0."DocNum",'' "BasePrcName",T0."DocDate" ,MONTH(T0."DocDate") "Month",
    	   CASE WHEN T0."U_ShipExpSts" = '1' THEN N'已录入运费'
    	   	    WHEN T0."U_ShipExpSts" = '2' THEN N'已确认运费'
    	   	    WHEN T0."U_ShipExpSts" = '5' THEN N'已对账运费'
    	   	    WHEN T0."U_ShipExpSts" = '3' THEN N'已生成运费' 
    	   	    WHEN T0."U_ShipExpSts" = '4' THEN N'已过账运费' ELSE '' END "ShipExpSts",
    	  (SELECT "descript" FROM OTER WHERE "territryID" = CASE WHEN T40."CardCode" IS NOT NULL THEN T51."parent" ELSE T50."parent" END ) "Provnse",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T51."descript" ELSE T50."descript" END "City",
    	   CASE WHEN T0."U_DLNType" = '1' THEN '公司送货' WHEN T0."U_DLNType" = '2' THEN '客户自提' ELSE '-' END
	     ||N' - '
		 ||CASE WHEN T0."U_BusiType" = 'S01' THEN N'厂内销售出库' 
		 		WHEN T0."U_BusiType" = 'S02' THEN N'外设仓库出库' 
			  	WHEN T0."U_BusiType" = 'S03' THEN N'库存调拨（销售）' ELSE N'' END "DLNType",
    	   T1."U_SlpName",
    	   T1."U_BusiUnit",T1."U_SaleUnit",  	   
    	   T0."CardCode",
    	   T4."CardName" ,
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T40."CardCode" ELSE T0."CardCode" END "SubCardCd", 	
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T40."CardName" ELSE T4."CardName" END "SubCardNm",     
    	   T1."ItemCode",T2."ItemName",
    	   T1."Quantity" - IFNULL(T8."Quantity",0) "Quantity",  --扣减基于交货的退货量
    	   T0."U_ShipPrice",T0."U_ShipExpns",
    	   CASE WHEN ROW_NUMBER() OVER(PARTITION BY t1."DocEntry" ORDER BY T1."LineNum") = 1 THEN T0."U_TtlShpAmt" ELSE 0.00 END "U_TtlShpAmt" ,
    	   T0."U_CarCd" ,
    	   T41."CardName" "DLNShpNam",
    	   CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) = 1 
   		   	    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) ELSE '' END "ShipCdPhNm", --物流联系电话
		   T0."U_RspNum",IFNULL(T42."CardName",T0."U_GTSShipNam") "GTSShpNam",T0."U_GTSRegNum",
    	   T0."U_Driver",T0."U_TelPhNum",T0."U_DriverCd",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Address" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Address" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Address",  --下级客户地址
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Cellolar" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Cellolar",--下级客户联系电话
    	   T7."WhsName",
    	   IFNULL(T61."Name",T31."Name") "CdClass4",IFNULL(T62."Name",T32."Name") "CdClass5",IFNULL(T63."Name",T33."Name") "CdClass6",
    	   CASE WHEN T0."BPLId" = 1 THEN N'新农' WHEN T0."BPLId" = 5 THEN N'丰卉' WHEN T0."BPLId" = 6 THEN N'和畅' WHEN T0."BPLId" = 3 THEN N'新农翔' WHEN T0."BPLId" = 1 THEN N'郑州饲料' END "BPLName"	   
    FROM ODLN T0
    JOIN DLN1 T1 ON T0."DocEntry" = T1."DocEntry" 
    JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
    JOIN OCRD T4 ON T0."CardCode" = T4."CardCode"
    JOIN OBPL T5 ON T0."BPLId" = T5."BPLId"
    LEFT JOIN OPRC T6 ON T1."OcrCode" = t6."PrcCode"
    LEFT JOIN OWHS T7 ON T1."WhsCode" = T7."WhsCode"
    LEFT JOIN OCRD T40 ON T0."U_SubCardCd" = T40."CardCode"  --下级客户
    LEFT JOIN OCRD T41 ON T0."U_DlnShipCod" = T41."CardCode" --运输商
	LEFT JOIN OCRD T42 ON T0."U_GTSShipCod" = T42."CardCode" --开票商
	LEFT JOIN OTER T50 ON T50."territryID" = T4."Territory"
	LEFT JOIN OTER T51 ON T51."territryID" = T40."Territory"  
	LEFT JOIN "@U_CBPTY4" T31 ON T4."U_CustClass4" = T31."Code"
	LEFT JOIN "@U_CBPTY5" T32 ON T4."U_CustClass5" = T32."Code"
	LEFT JOIN "@U_CBPTY6" T33 ON T4."U_CustClass6" = T33."Code"
	LEFT JOIN "@U_CBPTY4" T61 ON T0."U_CustClass4" = T61."Code"
	LEFT JOIN "@U_CBPTY5" T62 ON T0."U_CustClass5" = T62."Code"
	LEFT JOIN "@U_CBPTY6" T63 ON T0."U_CustClass6" = T63."Code"
    LEFT JOIN ( select distinct t1."BaseEntry",t1."BaseLine" ,t0."DocNum" ,t1."BaseType",
								t1."Quantity",t1."DocEntry",T1."LineNum",t1."ObjType"
			    from RDN1 t1 
			    join ORDN t0 on t1."DocEntry" = t0."DocEntry"
			    join OITM T2 ON T1."ItemCode" = T2."ItemCode" 
			    where T0."CANCELED" <> 'Y' AND T1."BaseType" = 15 				--基于交货单的退货
			   ) t8 on t1."DocEntry" = t8."BaseEntry" and t1."LineNum" = t8."BaseLine" and t1."ObjType" = t8."BaseType"
    WHERE T5."BPLId" = :BPLId AND IFNULL(T0."U_TtlShpAmt" ,0.00) <> 0.00
      --AND T0."U_ShipExpSts" = '2'
      --AND IFNULL(T41."CardName",'') NOT LIKE '%虚拟%'
      AND (T63."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL ) 
      AND T0."CANCELED" <> 'Y' AND T1."BaseType" <> 15  --不考虑交货取消单与抵消单 
	;
  
  OIGN_TMP = 
    SELECT N'库存-收货' "Type",T81."Name"||' -> '||T6."PrcName" "TrsName",
    	   T6."PrcName",T0."DocNum",T82."PrcName" "BasePrcName",T0."DocDate" ,MONTH(T0."DocDate") "Month",
    	   CASE WHEN T0."U_ShipExpSts" = '1' THEN N'已录入运费'
    	   	    WHEN T0."U_ShipExpSts" = '2' THEN N'已确认运费'
    	   	    WHEN T0."U_ShipExpSts" = '5' THEN N'已对账运费'
    	   	    WHEN T0."U_ShipExpSts" = '3' THEN N'已生成运费' 
    	   	    WHEN T0."U_ShipExpSts" = '4' THEN N'已过账运费' ELSE '' END "ShipExpSts",
    	  (SELECT "descript" FROM OTER WHERE "territryID" = CASE WHEN T40."CardCode" IS NOT NULL THEN T51."parent" ELSE T50."parent" END ) "Provnse",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T51."descript" ELSE T50."descript" END "City",
    	   N'其他出入库-调拨' "DLNType",
    	   T1."U_SlpName",
    	   T1."U_BusiUnit",T1."U_SaleUnit",  	   
    	   T0."U_CstDept" "CardCode",
    	   T6."PrcName" "CardName",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T40."CardCode" ELSE T0."CardCode" END "SubCardCd", 	
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T40."CardName" ELSE T4."CardName" END "SubCardNm",     
    	   T1."ItemCode",T2."ItemName",
    	   T1."Quantity" "Quantity",  --扣减基于交货的退货量
    	   T0."U_ShipPrice",T0."U_ShipExpns",
    	   CASE WHEN ROW_NUMBER() OVER(PARTITION BY t1."DocEntry" ORDER BY T1."LineNum") = 1 THEN T0."U_TtlShpAmt" ELSE 0.00 END "U_TtlShpAmt" ,
    	   T0."U_CarCd" ,
    	   T41."CardName" "DLNShpNam",
    	   CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) = 1 
   		   	    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) ELSE '' END "ShipCdPhNm", --物流联系电话
		   T0."U_RspNum",IFNULL(T42."CardName",T0."U_GTSShipNam") "GTSShpNam",T0."U_GTSRegNum",
    	   T0."U_Driver",T0."U_TelPhNum",T0."U_DriverCd",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Address" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Address" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Address",  --下级客户地址
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Cellolar" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Cellolar",--下级客户联系电话
    	   T7."WhsName",
    	   IFNULL(T61."Name",T31."Name") "CdClass4",IFNULL(T62."Name",T32."Name") "CdClass5",IFNULL(T63."Name",T33."Name") "CdClass6",
    	   CASE WHEN T0."BPLId" = 1 THEN N'新农' WHEN T0."BPLId" = 5 THEN N'丰卉' WHEN T0."BPLId" = 6 THEN N'和畅' WHEN T0."BPLId" = 3 THEN N'新农翔' WHEN T0."BPLId" = 1 THEN N'郑州饲料' END "BPLName"	   
    FROM OIGN T0
    JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry" 
    JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
    LEFT JOIN OCRD T4 ON T0."CardCode" = T4."CardCode"
    LEFT JOIN OBPL T5 ON T0."BPLId" = T5."BPLId"
    LEFT JOIN OPRC T6 ON T0."U_CstDept" = t6."PrcCode"
    LEFT JOIN OWHS T7 ON T1."WhsCode" = T7."WhsCode"
    LEFT JOIN OCRD T40 ON T0."U_SubCardCd" = T40."CardCode"  --下级客户
    LEFT JOIN OCRD T41 ON T0."U_DlnShipCod" = T41."CardCode" --运输商
	LEFT JOIN OCRD T42 ON T0."U_GTSShipCod" = T42."CardCode" --开票商
	LEFT JOIN OTER T50 ON T50."territryID" = T4."Territory"
	LEFT JOIN OTER T51 ON T51."territryID" = T40."Territory"  
	LEFT JOIN "@U_CBPTY4" T31 ON T4."U_CustClass4" = T31."Code"
	LEFT JOIN "@U_CBPTY5" T32 ON T4."U_CustClass5" = T32."Code"
	LEFT JOIN "@U_CBPTY6" T33 ON T4."U_CustClass6" = T33."Code"
	LEFT JOIN "@U_CBPTY4" T61 ON T0."U_CustClass4" = T61."Code"
	LEFT JOIN "@U_CBPTY5" T62 ON T0."U_CustClass5" = T62."Code"
	LEFT JOIN "@U_CBPTY6" T63 ON T0."U_CustClass6" = T63."Code"
	LEFT JOIN "@U_CIOTRN" T81 ON T0."U_TrsName" = T81."Code"
	LEFT JOIN
	 (SELECT U0."DocNum",U1."PrcName"
	  FROM OIGE U0 
	  LEFT JOIN OPRC U1 ON U0."U_CstDept" = U1."PrcCode"
  	  WHERE U0."U_TrsName" = '601') T82 ON T0."U_SrcNum" = T82."DocNum"
    WHERE T5."BPLId" = :BPLId AND IFNULL(T0."U_TtlShpAmt" ,0.00) <> 0.00
      AND T1."BaseType" = '-1' AND T0."U_TrsName" IN('602')
      --AND T0."U_ShipExpSts" = '2'
      --AND IFNULL(T41."CardName",'') NOT LIKE '%虚拟%'
      AND (T63."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL )  ;
  
  OIGE_TMP = 
    SELECT N'库存-发货' "Type",T81."Name"||' -> '||T6."PrcName" "TrsName",
    	   T6."PrcName",T0."DocNum",T82."PrcName" "BasePrcName",T0."DocDate" ,MONTH(T0."DocDate") "Month",
    	   CASE WHEN T0."U_ShipExpSts" = '1' THEN N'已录入运费'
    	   	    WHEN T0."U_ShipExpSts" = '2' THEN N'已确认运费'
    	   	    WHEN T0."U_ShipExpSts" = '5' THEN N'已对账运费'
    	   	    WHEN T0."U_ShipExpSts" = '3' THEN N'已生成运费' 
    	   	    WHEN T0."U_ShipExpSts" = '4' THEN N'已过账运费' ELSE '' END "ShipExpSts",
    	  (SELECT "descript" FROM OTER WHERE "territryID" = CASE WHEN T40."CardCode" IS NOT NULL THEN T51."parent" ELSE T50."parent" END ) "Provnse",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T51."descript" ELSE T50."descript" END "City",
    	   N'其他出入库-调拨' "DLNType",
    	   T1."U_SlpName",
    	   T1."U_BusiUnit",T1."U_SaleUnit",  	   
    	   T0."U_CstDept" "CardCode",
    	   T6."PrcName" "CardName",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T40."CardCode" ELSE T0."CardCode" END "SubCardCd", 	
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN T40."CardName" ELSE T4."CardName" END "SubCardNm",     
    	   T1."ItemCode",T2."ItemName",
    	   -T1."Quantity" "Quantity",  --扣减基于交货的退货量
    	   T0."U_ShipPrice",T0."U_ShipExpns",
    	   CASE WHEN ROW_NUMBER() OVER(PARTITION BY t1."DocEntry" ORDER BY T1."LineNum") = 1 THEN T0."U_TtlShpAmt" ELSE 0.00 END "U_TtlShpAmt" ,
    	   T0."U_CarCd" ,
    	   T41."CardName" "DLNShpNam",
    	   CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) = 1 
   		   	    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) ELSE '' END "ShipCdPhNm", --物流联系电话
		   T0."U_RspNum",IFNULL(T42."CardName",T0."U_GTSShipNam") "GTSShpNam",T0."U_GTSRegNum",
    	   T0."U_Driver",T0."U_TelPhNum",T0."U_DriverCd",
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Address" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Address" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Address",  --下级客户地址
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Cellolar" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Cellolar",--下级客户联系电话
    	   T7."WhsName",
    	   IFNULL(T61."Name",T31."Name") "CdClass4",IFNULL(T62."Name",T32."Name") "CdClass5",IFNULL(T63."Name",T33."Name") "CdClass6",
    	   CASE WHEN T0."BPLId" = 1 THEN N'新农' WHEN T0."BPLId" = 5 THEN N'丰卉' WHEN T0."BPLId" = 6 THEN N'和畅' WHEN T0."BPLId" = 3 THEN N'新农翔' WHEN T0."BPLId" = 1 THEN N'郑州饲料' END "BPLName"	   
    FROM OIGE T0
    JOIN IGE1 T1 ON T0."DocEntry" = T1."DocEntry" 
    JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
    LEFT JOIN OCRD T4 ON T0."CardCode" = T4."CardCode"
    LEFT JOIN OBPL T5 ON T0."BPLId" = T5."BPLId"
    LEFT JOIN OPRC T6 ON T0."U_CstDept" = t6."PrcCode"
    LEFT JOIN OWHS T7 ON T1."WhsCode" = T7."WhsCode"
    LEFT JOIN OCRD T40 ON T0."U_SubCardCd" = T40."CardCode"  --下级客户
    LEFT JOIN OCRD T41 ON T0."U_DlnShipCod" = T41."CardCode" --运输商
	LEFT JOIN OCRD T42 ON T0."U_GTSShipCod" = T42."CardCode" --开票商
	LEFT JOIN OTER T50 ON T50."territryID" = T4."Territory"
	LEFT JOIN OTER T51 ON T51."territryID" = T40."Territory"  
	LEFT JOIN "@U_CBPTY4" T31 ON T4."U_CustClass4" = T31."Code"
	LEFT JOIN "@U_CBPTY5" T32 ON T4."U_CustClass5" = T32."Code"
	LEFT JOIN "@U_CBPTY6" T33 ON T4."U_CustClass6" = T33."Code"
	LEFT JOIN "@U_CBPTY4" T61 ON T0."U_CustClass4" = T61."Code"
	LEFT JOIN "@U_CBPTY5" T62 ON T0."U_CustClass5" = T62."Code"
	LEFT JOIN "@U_CBPTY6" T63 ON T0."U_CustClass6" = T63."Code"
	LEFT JOIN "@U_CIOTRN" T81 ON T0."U_TrsName" = T81."Code"
	LEFT JOIN
	 (SELECT U0."DocNum",U1."PrcName"
	  FROM OIGE U0 
	  LEFT JOIN OPRC U1 ON U0."U_CstDept" = U1."PrcCode"
  	  WHERE U0."U_TrsName" = '601') T82 ON T0."U_SrcNum" = T82."DocNum"
    WHERE T5."BPLId" = :BPLId AND IFNULL(T0."U_TtlShpAmt" ,0.00) <> 0.00
      AND T1."BaseType" = '-1' AND T0."U_TrsName" IN('602')
      --AND T0."U_ShipExpSts" = '2'
      --AND IFNULL(T41."CardName",'') NOT LIKE '%虚拟%'
      AND (T63."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL )  ;  
  	 
  StkTrsfr_TMP = 
    SELECT N'库存转储' "Type",
    	   T81."Name" "TrsName",
    	   T6."PrcName",T0."DocNum",'' "BasePrcName",T0."DocDate" ,MONTH(T0."DocDate") "Month",
		   CASE WHEN T0."U_ShipExpSts" = '1' THEN N'已录入运费'
    	   	    WHEN T0."U_ShipExpSts" = '2' THEN N'已确认运费'
    	   	    WHEN T0."U_ShipExpSts" = '5' THEN N'已对账运费'
    	   	    WHEN T0."U_ShipExpSts" = '3' THEN N'已生成运费' 
    	   	    WHEN T0."U_ShipExpSts" = '4' THEN N'已过账运费' ELSE '' END "ShipExpSts",
		   '' "Provnse",
    	   '' "City",
    	   '库存转储-调拨' "DLNType",
		   '' "U_SlpName",
		   '' "U_BusiUnit",'' "U_SaleUnit", 
		   CASE WHEN T0."U_TrsName" = '106' THEN T0."ToWhsCode" ELSE T0."CardCode" END "CardCode",
		   CASE WHEN T0."U_TrsName" = '106' THEN T1."WhsName" ELSE T0."CardName" END "CardName",
		   '' "SubToWhsCode" ,
		   '' "SubWhsName" ,
		   T3."ItemCode",T2."ItemName",
		   T3."Quantity" ,
		   T0."U_ShipPrice",T0."U_ShipExpns",
		   CASE WHEN ROW_NUMBER() OVER(PARTITION BY t3."DocEntry" ORDER BY T3."LineNum") = 1 THEN T0."U_TtlShpAmt" ELSE 0.00 END "U_TtlShpAmt" ,
		   T0."U_CarCd" ,
    	   T41."CardName" "DLNShpNam",
		   CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) = 1 
   		   	    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T41."CardCode" ) ELSE '' END "ShipCdPhNm", --物流联系电话
		   T0."U_RspNum",IFNULL(T42."CardName",T0."U_GTSShipNam") "GTSShpNam",T0."U_GTSRegNum",
		   T0."U_Driver",T0."U_TelPhNum",T0."U_DriverCd",
		   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Address" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Address" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Address",  --下级客户地址
    	   CASE WHEN T40."CardCode" IS NOT NULL THEN ( CASE WHEN ( SELECT COUNT(*) FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) = 1 
    	   												    THEN ( SELECT R0."Cellolar" FROM OCPR R0 WHERE R0."CardCode" = T40."CardCode" ) ELSE '' END )
    	   										ELSE ( SELECT U0."Cellolar" FROM OCPR U0 WHERE U0."CntctCode" = T0."CntctCode" )  END "Cellolar",--下级客户联系电话
		   T1."WhsName",
		   IFNULL(T61."Name",'') "CdClass4",IFNULL(T62."Name",'') "CdClass5",IFNULL(T63."Name",'') "CdClass6",
    	   CASE WHEN T0."BPLId" = 1 THEN N'新农' WHEN T0."BPLId" = 5 THEN N'丰卉' WHEN T0."BPLId" = 6 THEN N'和畅' WHEN T0."BPLId" = 3 THEN N'新农翔' WHEN T0."BPLId" = 1 THEN N'郑州饲料' END "BPLName"
	FROM OWTR T0
	JOIN WTR1 T3 ON T0."DocEntry" = T3."DocEntry"
	JOIN OITM T2 ON T2."ItemCode" = T3."ItemCode"
	LEFT JOIN OWHS T1 ON T0."ToWhsCode" = T1."WhsCode"
	LEFT JOIN OPRC T6 ON T3."OcrCode" = t6."PrcCode"
	LEFT JOIN OCRD T40 ON T0."U_SubCardCd" = T40."CardCode"  --下级客户
    LEFT JOIN OCRD T41 ON T0."U_DlnShipCod" = T41."CardCode" --运输商
	LEFT JOIN OCRD T42 ON T0."U_GTSShipCod" = T42."CardCode" --开票商
	LEFT JOIN "@U_CBPTY4" T61 ON T0."U_CustClass4" = T61."Code"
	LEFT JOIN "@U_CBPTY5" T62 ON T0."U_CustClass5" = T62."Code"
	LEFT JOIN "@U_CBPTY6" T63 ON T0."U_CustClass6" = T63."Code"
	LEFT JOIN "@U_CIOTRN" T81 ON T0."U_TrsName" = T81."Code"
	WHERE T0."BPLId" = :BPLId 
	  --AND T0."U_ShipExpSts" = '2'
	  AND T0."U_TrsName" in('105','106','107')
	  --AND IFNULL(T41."CardName",'') NOT LIKE '%虚拟%'
	  AND IFNULL(T0."U_TtlShpAmt",0.00) <> 0.00
	  AND (T63."Name" LIKE '%[%5]%' OR '[%5]'='' OR '[%5]' IS NULL )
	  AND T0."CANCELED" <> 'Y'   		  													   --取消单
      AND T0."DocEntry" not in ( select distinct "DocEntry" from WTR1 where "BaseType" = '0' ) --抵消单
   ;
   

	SELECT 
		   T0."ShipExpSts" "运费状态",T0."DocNum" "单据号",--T0."PrcName" "工厂",
		   T0."DocDate" "日期",T0."Month" "月份",
    	   T0."Provnse" "地区",T0."City" "城市",
    	   T0."Type" "单据",
    	   T0."DLNType" "类型",
    	   T0."TrsName" "事务",
    	   T0."BasePrcName" "调出方",
    	   T0."CardCode" "客户编码",
		   T0."CardName" "客户名称",
    	   T0."SubCardCd" "下级客户",
    	   T0."SubCardNm" "客户名称",     
    	   --T0."ItemCode" "物料编码",T0."ItemName" "物料名称",
    	   CASE WHEN T0."Type" = N'交货' THEN (SELECT SUM(U0."Quantity")/1000 FROM :Delry_TMP U0 WHERE U0."DocNum" = T0."DocNum") 
    	   		WHEN T0."Type" = N'库存-收货' THEN (SELECT SUM(U0."Quantity")/1000 FROM :OIGN_TMP U0 WHERE U0."DocNum" = T0."DocNum") 
    	   		WHEN T0."Type" = N'库存-发货' THEN (SELECT SUM(U0."Quantity")/1000 FROM :OIGE_TMP U0 WHERE U0."DocNum" = T0."DocNum") 
			    ELSE (SELECT SUM(R0."Quantity")/1000 FROM :StkTrsfr_TMP R0 WHERE R0."DocNum" = T0."DocNum") END  "数量（吨）",  
    	   T0."U_ShipPrice" "运费单价",T0."U_ShipExpns" "杂费",T0."U_TtlShpAmt" "运费总额",
    	   T0."BPLName" "分支",T0."DLNShpNam" "物流公司",T0."U_CarCd" "车牌号码",T0."ShipCdPhNm" "物流电话", 
    	   T0."U_SlpName" "业务员",--T0."U_BusiUnit" "区域经理",T0."U_SaleUnit" "经理主管",  	 
		   T0."CdClass4" "管理大区",T0."CdClass5" "销售单元",T0."CdClass6" "财务单元",  
		   T0."U_RspNum" "回单号码",T0."GTSShpNam" "开票公司",T0."U_GTSRegNum" "发票号",
    	   --T0."U_Driver" "司机姓名",T0."U_TelPhNum" "司机电话",T0."U_DriverCd" "行驶证号",
    	   T0."Cellolar" "联系电话",T0."Address" "送货地址",
    	   T0."WhsName" "发货仓库"
	FROM( SELECT * FROM :Delry_TMP
		  UNION ALL
		  SELECT * FROM :OIGN_TMP
		  UNION ALL
		  SELECT * FROM :OIGE_TMP
		  UNION ALL
		  SELECT * FROM :StkTrsfr_TMP
		 ) T0
	 JOIN OITM T4 ON T0."ItemCode" = T4."ItemCode"
	 LEFT JOIN OITB T3 ON T4."ItmsGrpCod" = T3."ItmsGrpCod"
	 LEFT JOIN "@U_CITTY2" T5 ON T4."U_Class2" = T5."Code"--物料种类
    WHERE T0."DocDate" BETWEEN '[%1]' AND '[%2]'
      AND IFNULL(T0."U_TtlShpAmt",0.00) <> 0.00
    ORDER BY T0."DocDate",T0."DLNType",T0."DocNum"
  	;

END IF;
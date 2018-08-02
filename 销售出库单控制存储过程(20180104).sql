CREATE PROCEDURE "U_PC_SalesDeliveryControl"
(
	in object_type nvarchar(20), 				-- SBO Object Type
	in transaction_type nchar(1),			-- [A]dd, [U]pdate, [D]elete, [C]ancel, C[L]ose
	in num_of_cols_in_key int,
	in list_of_key_cols_tab_del nvarchar(255),
	in list_of_cols_val_tab_del nvarchar(255),
	out errbox result
)
LANGUAGE SQLSCRIPT
AS
BEGIN


  DECLARE cnt int;
  DECLARE result nchar(1);
  errbox = SELECT '0' error,'OK' errormsg FROM dummy;

  IF :object_type='15' and (:transaction_type='A' or :transaction_type='U') THEN
	--销售交货必须有来源单据（BaseType<>'-1')
    SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15010');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "DLN1" AS T0
	         JOIN "ODLN" AS T1 ON (T0."DocEntry" = T1."DocEntry")
	    WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
	      AND T0."BaseType" NOT IN ('15','17') ;
	    IF :cnt>0 THEN errbox = SELECT '15010' error,
	                                   '错误提示：销售交货必须基于销售订单创建！' errormsg 
	                            FROM dummy;
        END IF;
	END IF;
  	
    --自定义字段业务类型为必填项!
    SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15020');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "ODLN" AS T0	
	    WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
	      AND IFNULL(T0."U_BusiType",'') = 'S03' ;	   
	    IF :cnt>0 THEN errbox = SELECT '15020' error,
	                                   '错误提示：业务类型为S03-库存调拨(销售)时，不允许生成 销售出库单!' errormsg 
	                            FROM dummy;
 								RETURN;      
        END IF;
	END IF;
	
	--销售交货如果基于销售开票单时，单据日期必须和销售订单单据日期一致
    SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15030');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "DLN1" AS T0
         INNER JOIN "ODLN" AS T1 ON (T0."DocEntry" = T1."DocEntry")
       	 LEFT JOIN (SELECT T1."DocEntry" ,T1."LineNum",T0."DocDate"
       	 			FROM ORDR T0
       	 			JOIN RDR1 T1 ON T0."DocEntry"=T1."DocEntry"	
       	 			) T2 ON T0."BaseEntry"=T2."DocEntry" AND T0."BaseLine"=T2."LineNum" 
	    WHERE T1."DocEntry" =:list_of_cols_val_tab_del 
	      AND T0."BaseType"=17 AND T1."DocDate"<>T2."DocDate";	   
	    IF :cnt>0 THEN errbox = SELECT '15030' error,
	                                   '错误提示：销售出库单的过账日期必须与销售发货单一致！' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	END IF;
	
	--添加销售交货时，不你基于多张销售订单
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15040');
    IF :result='Y' THEN
	    SELECT COUNT(DISTINCT T1."BaseRef") INTO cnt 
		FROM ODLN T0
		  INNER JOIN DLN1 T1 ON T0."DocEntry"=T1."DocEntry" 
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T1."BaseType"='17';	  	  
		IF :cnt>1 THEN errbox = SELECT '15040' error,
	      	                                   '错误提示：不能基于多张销售发货单创建销售交货单!'||:cnt errormsg 
	                            FROM dummy;
	                            RETURN;
        END IF;
	END IF;
	/*
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15041');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
		FROM ODLN T0
		  INNER JOIN DLN1 T1 ON T0."DocEntry"=T1."DocEntry" AND T1."BaseType" = 17
		  LEFT JOIN DLN1 T2 ON T1."BaseEntry" = T2."BaseEntry" AND T1."BaseType" = T2."BaseType" AND T1."DocEntry" <> T2."DocEntry"
		  LEFT JOIN ODLN T3 ON T2."DocEntry" = T3."DocEntry" AND T3."CANCELED" <> 'Y'
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T3."DocEntry" IS NOT NULL;	  	  
		IF :cnt > 0 THEN errbox = SELECT '15041' error,
	      	                                   '错误提示：销售发货单不允许重复出库!!' errormsg 
	                            FROM dummy;
	                            RETURN;
        END IF;
	END IF;
	*/
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15050');
    IF :result='Y' THEN
	    select count(1) into cnt
	    from ODLN T0
	     join DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
		 join "@U_SDSR1" T2 ON T1."ItemCode" = T2."U_ItemCode"
		 join "@U_SODSR" T3 ON T2."DocEntry" = T3."DocEntry" AND T0."CardCode" = t3."U_CardCode"AND T0."BPLId" = T3."U_BPLId"
		where T0."DocEntry" = :list_of_cols_val_tab_del 
		  and t3."DocEntry" is not null
		  and t3."U_DiscCode" = 'Z005';
	    
	    if :cnt > 0 then
		    update t1
		      set t1."U_SlpName" = T2."U_SlpName",T1."U_BusiUnit" = T2."U_RegSupName",T1."U_SaleUnit" = T2."U_SupMangName"
		    from ODLN T0
		     join DLN1 T1 ON T0."DocEntry" = T1."DocEntry"
			 join "@U_SDSR1" T2 ON T1."ItemCode" = T2."U_ItemCode"
			 join "@U_SODSR" T3 ON T2."DocEntry" = T3."DocEntry" AND T0."CardCode" = t3."U_CardCode" AND T0."BPLId" = T3."U_BPLId"
			where T0."DocEntry" = :list_of_cols_val_tab_del 
			  and t3."DocEntry" is not null
			  and t3."U_DiscCode" = 'Z005';
		end if ;
	END IF;
	
	--与源销售订单保持一致
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15060');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "DLN1" AS T0
         INNER JOIN "ODLN" AS T1 ON (T0."DocEntry" = T1."DocEntry")
       	 LEFT JOIN (SELECT T1."DocEntry" ,T1."LineNum",t1."OcrCode",t1."CogsOcrCod",T1."ObjType"
       	 				  ,T1."WhsCode",t1."U_BaseDisc",t1."U_SubBaseDisc",t1."U_SubPrice"
       	 			FROM ORDR T0
       	 			JOIN RDR1 T1 ON T0."DocEntry"=T1."DocEntry"	
       	 			) T2 ON T0."BaseEntry"=T2."DocEntry" AND T0."BaseLine"=T2."LineNum" AND T0."BaseType"= T2."ObjType"
	    WHERE T1."DocEntry" =:list_of_cols_val_tab_del 
	      AND T0."BaseType" = '17'
	      AND ( IFNULL( T0."CogsOcrCod",'') <> IFNULL(T2."CogsOcrCod",'') OR
	      	   	IFNULL( T0."OcrCode",'') <> IFNULL(T2."OcrCode",'') OR
	      	   	IFNULL( T0."U_BaseDisc",0.00) <> IFNULL(T2."U_BaseDisc",0.00)  OR
	            IFNULL( T0."U_SubBaseDisc",0.00) <> IFNULL(T2."U_SubBaseDisc",0.00) OR
	            IFNULL( T0."U_SubPrice",0.00) <> IFNULL(T2."U_SubPrice",0.00) OR
	      	   	T2."WhsCode" <> T0."WhsCode" );	   
	    IF :cnt>0 THEN errbox = SELECT '15060' error,
	                                   '错误提示：不允许修改物料行的 基础折扣、下级客户单价、工厂 、仓库等信息！' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	END IF;
	
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15070');
    IF :result='Y' THEN
	     SELECT COUNT(1) INTO cnt 
	    FROM "DLN1" AS T0
	      JOIN ODLN T2 ON T0."DocEntry" = T2."DocEntry"	
	      LEFT JOIN OPRC T1 ON T0."OcrCode" = T1."PrcCode"	
	    WHERE T0."DocEntry" = :list_of_cols_val_tab_del
	      AND T2."DocType" = 'I' 
	      AND ( ( IFNULL(T0."OcrCode",'') = '' ) OR
	         	( IFNULL(T0."OcrCode",'') <> '' AND IFNULL(T1."U_IsRvCtRlt",'') <> 'Y' AND IFNULL(T0."OcrCode",'') <> IFNULL(T0."CogsOcrCod",'') )  );
	    IF :cnt>0 THEN errbox = SELECT '15070' error,
	                                   '错误提示：请指定物料行 工厂 ，可点击放大镜进行 选择 或 刷新，且保持字段 工厂&销售成本-部门 一致!' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	END IF;
	
	--不允许修改
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15080');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "DLN1" AS T0
	      JOIN "ODLN" AS T1 ON T0."DocEntry" = T1."DocEntry" 
	      LEFT JOIN ( SELECT T1."DocEntry" ,T1."LineNum",t0."U_SubCardCd",t0."U_DlnShipCod"
	      					,T0."U_CustClass4",T0."U_CustClass5",T0."U_CustClass6"
       	 			  FROM ORDR T0
       	 			  JOIN RDR1 T1 ON T0."DocEntry"=T1."DocEntry"	
       	 			) T2 ON T0."BaseEntry"=T2."DocEntry" AND T0."BaseLine"=T2."LineNum" 
	    WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
	      AND T0."BaseType" = '17' 
	      AND ( IFNULL(T1."U_SubCardCd",'') <> IFNULL(T2."U_SubCardCd",'') OR
	      	   	--IFNULL(T1."U_DlnShipCod",'') <> IFNULL(T2."U_DlnShipCod",'') OR
	      	   	IFNULL(T1."U_CustClass4",'') <> IFNULL(T2."U_CustClass4",'') OR
	      		IFNULL(T1."U_CustClass5",'') <> IFNULL(T2."U_CustClass5",'') OR
	      		IFNULL(T1."U_CustClass6",'') <> IFNULL(T2."U_CustClass6",'')  );	   
	    IF :cnt >0 THEN errbox = SELECT '15080' error,
	                                   '错误提示：不允许修改 下级客户，运输商，管理大区，销售单元，财务单元等信息 ！' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	END IF;
	
	--不允许输入
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15090');
    IF :result='Y' THEN
	    SELECT COUNT(*) INTO cnt 
	    FROM "ODLN" AS T0
	    WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
	      AND ( IFNULL(T0."U_Z003",0.00) <> 0.00 OR
	      		IFNULL(T0."U_Z006",0.00) <> 0.00 OR
	      		IFNULL(T0."U_Z012",0.00) <> 0.00 OR
	      		IFNULL(T0."U_Z013",0.00) <> 0.00 );   
	    IF :cnt>0 THEN errbox = SELECT '15090' error,
	                                   '错误提示：现金折扣,返机费,随单折,任务折不允许输入!' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	END IF;
	
	--不允许修改
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15100');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "DLN1" AS T0
	      INNER JOIN "ODLN" AS T1 ON T0."DocEntry" = T1."DocEntry" 
	      LEFT JOIN RDR1 T2 ON T0."BaseEntry" = T2."DocEntry" AND T0."BaseLine" = T2."LineNum" AND T0."BaseType" = T2."ObjType"
	    WHERE T1."DocEntry" =:list_of_cols_val_tab_del 
	      AND T0."BaseType" = 17
	      AND T0."Quantity" > IFNULL(T2."Quantity",0);   
	    IF :cnt>0 THEN errbox = SELECT '15100' error,
	                                   '错误提示：出库单不允许超过销售发货单的数量；若要调整出库量，请先修改销售发货单!' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	END IF;
	
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15110');
     IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "ODLN" AS T0
	    WHERE T0."DocEntry" = :list_of_cols_val_tab_del
	      AND IFNULL(T0."DiscPrcnt",0.00) <> 0.00 ;   
	    IF :cnt>0 THEN errbox = SELECT '15110' error,
	                                   '错误提示：单据右下角的折扣比例不允许输入!' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	 END IF;
	
	--抵消单不允许修改任何信息
	SELECT result INTO result FROM U_FC_CheckControlPointStatus('2030', '15120');
    IF :result='Y' THEN
	    SELECT COUNT(1) INTO cnt 
	    FROM "DLN1" AS T0
	      JOIN "ODLN" AS T1 ON T0."DocEntry" = T1."DocEntry" 
	      LEFT JOIN ( SELECT T1."DocEntry" ,T1."LineNum",T0."DocDate"
	                         ,t0."U_SubCardCd",t0."U_DlnShipCod",t0."U_GTSShipCod"
	                         ,T0."U_DLNType",T0."U_FrMtType"
	                         ,T0."U_CstDept",T0."U_TtlShpAmt",T0."U_ShipPrice",T0."U_ShipExpns"
	                         ,T0."U_Z003",T0."U_Z006",T0."U_Z012",T0."U_Z013",t0."U_CreditDate"
       	 			  FROM ODLN T0
       	 			  JOIN DLN1 T1 ON T0."DocEntry"=T1."DocEntry"	
       	 			) T2 ON T0."BaseEntry"=T2."DocEntry" AND T0."BaseLine"=T2."LineNum" 
	    WHERE T1."DocEntry" = :list_of_cols_val_tab_del 
	      AND T0."BaseType" = '15'  --抵消单
	      AND ( IFNULL(T1."U_SubCardCd",'') <> IFNULL(T2."U_SubCardCd",'') OR
	      	   	IFNULL(T1."U_DlnShipCod",'') <> IFNULL(T2."U_DlnShipCod",'') OR
	      	   	IFNULL(T1."U_GTSShipCod",'') <> IFNULL(T2."U_GTSShipCod",'') OR
	      	   	IFNULL(T1."U_Z003",0.00) <> IFNULL(T2."U_Z003",0.00) OR
	      		IFNULL(T1."U_Z006",0.00) <> IFNULL(T2."U_Z006",0.00) OR
	      		IFNULL(T1."U_Z012",0.00) <> IFNULL(T2."U_Z012",0.00) OR
	      		IFNULL(T1."U_Z013",0.00) <> IFNULL(T2."U_Z013",0.00) OR
	      		IFNULL(T1."U_CreditDate",0) <> IFNULL(T2."U_CreditDate",0) OR
	      		IFNULL(T1."U_DLNType",'') <> IFNULL(T2."U_DLNType",'') OR
	      		IFNULL(T1."U_FrMtType",'') <> IFNULL(T2."U_FrMtType",'') OR
	      		IFNULL(T1."U_CstDept",'') <> IFNULL(T2."U_CstDept",'') OR
	      		IFNULL(T1."U_TtlShpAmt",0.00) <> IFNULL(T2."U_TtlShpAmt",0.00) OR
	      		IFNULL(T1."U_ShipPrice",0.00) <> IFNULL(T2."U_ShipPrice",0.00) OR
	      		IFNULL(T1."U_ShipExpns",0.00) <> IFNULL(T2."U_ShipExpns",0.00) OR
	      		IFNULL(T1."DocDate",'') <> IFNULL(T2."DocDate",'') 
	      	   );	   
	    IF :cnt >0 THEN errbox = SELECT '15120' error,
	                                   '错误提示：添加抵消单时，不允许修改任何自定义字段信息 ！' errormsg 
	                            FROM dummy;
        						RETURN;
        END IF;
	END IF;
	  	  	   
  END IF;
  
  
END;
SELECT T1.*
FROM SYS."CS_TABLES_" T0
INNER JOIN SYS."CS_COLUMNS_" T1 ON T0."TABLE_OID"=T1."TABLE_OID"
WHERE T0."SCHEMA_NAME"='XN_FM'
AND "TABLE_NAME"='@U_QASR'
;
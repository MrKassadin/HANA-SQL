--获取分公司经纬度
SELECT "BPLId","BPLName","Building"
FROM "OBPL"
WHERE "Building" IS NOT NULL;
set schema XN_FM;

EXPORT XN_FM."*" as binary INTO '/home/XN_FM/XN_FM_0324/' WITH  REPLACE  THREADS 10;
IMPORT XN_FM."*" from '/home/XN_FM/XN_FM_0324/' with rename schema  XN_FM to "XN_FM_0324" replace threads 10;

select * from "@U_CIOTRN";

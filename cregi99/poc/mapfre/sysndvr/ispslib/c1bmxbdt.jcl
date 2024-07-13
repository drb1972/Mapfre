)CM  PACKAGE SHIPMENT BATCH JCL -  BULK DATA TRANSFER - ISPSLIB(C1BMXBDT)
)CM
)CM  THIS SKELETON IS USED TO TRANSMIT STAGING DATASETS AND RUN JOBS VIA
)CM  BULK DATA TRANSFER - VERSION 2.
)CM
)CM  PTF C9223300 APPLIED TO ALLOW USE OF CONTROL CARD TEMPLATE SUPPORT
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM  TAILORING INSTRUCTIONS:
)CM
)CM  NO TAILORING NECESSARY
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
//* *============================================* ISPSLIB(C1BMXBDT) *
//* *==============================================================* *
//* *==============================================================* *
//* *==============================================================* *
//* *==============================================================* *
//&VNBXSTP EXEC PGM=BDTBATCH,REGION=2048K,COND=(12,LE,NDVRSHIP)
//SYSPRINT  DD SYSOUT=*
//SYMDUMP   DD DUMMY
//SYSUDUMP  DD SYSOUT=*
//SYSIN     DD DSN=&&&&XBDC,DISP=(OLD,PASS)

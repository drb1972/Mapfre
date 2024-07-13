)CM  PACKAGE SHIPMENT BATCH JCL -  XCOM FOR MVS - ISPSLIB(C1BMXCOM)
)CM
)CM  THIS SKELETON CONTAINS XCOM JCL.  THE &&XXCC DATASET WAS BUILT
)CM  BY THE PACKAGE SHIPMENT UTILITY AND CONTAINS COMMANDS TO TRANSFER
)CM  THE STAGING DATASETS TO THE REMOTE SITE(S).
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM  TAILORING INSTRUCTIONS:
)CM
)CM  1.  MODIFY THE "STEPLIB" AND "XCOMCNTL"
)CM      DSNAMES USING SITE SPECIFIC PREFIX, QUALIFIER, AND NAME.
)CM
)CM      "&I@PRFX..XCOM" IS THE PREFIX/QUALIFIER OF THE XCOM LIBRARIES.
)CM
)CM  2.  MODIFY THE DFLTAB=XCOMDFLT PARAMETER, IF NECESSARY.
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
//* *============================================* ISPSLIB(C1BMXCOM) *
//* *==============================================================* *
//* *==============================================================* *
//* *==============================================================* *
//* *==============================================================* *
//COMMANDI EXEC PGM=IEBUPDTE,PARM=NEW,COND=(12,LE,NDVRSHIP)
//SYSPRINT DD  DUMMY
//SYSUT2   DD  DISP=(NEW,CATLG),UNIT=SYSDA,
//             DSN=&VNBSHHLI..D&VNB6DATE..T&VNB6TIME..XCOMCMD.FILE,
//             SPACE=(TRK,(5,1,45)),
//             DCB=(RECFM=FB,LRECL=80)
//SYSUT1   DD  DUMMY
//SYSIN    DD  DISP=SHR,
//             DSN=&I@PRFX..&I@QUAL..CSIQOPTN(#PS#XCOM)
//* *==============================================================* *
//COMMANDP EXEC PGM=IEBUPDTE,PARM=MOD,COND=(12,LE,NDVRSHIP)
//SYSPRINT DD  DUMMY
//SYSUT1   DD  DISP=SHR,
//             DSN=&VNBSHHLI..D&VNB6DATE..T&VNB6TIME..XCOMCMD.FILE
//SYSUT2   DD  DISP=SHR,
//             DSN=&VNBSHHLI..D&VNB6DATE..T&VNB6TIME..XCOMCMD.FILE
//SYSIN    DD  DSN=&&&&XXCC,DISP=(OLD,PASS)
//* *==============================================================* *
//&VNBXSTP EXEC PGM=XCOMJOB,COND=(12,LE,NDVRSHIP),
//         PARM=('TYPE=SCHEDULE,DFLTAB=XCOMDFLT')
//STEPLIB  DD DISP=SHR,DSN=&I@PRFX..XCOM.LOADLIB
//         DD DISP=SHR,DSN=&I@PRFX..XCOM.DEFAULT.TABLES
//XCOMCNTL DD DISP=SHR,DSN=&I@PRFX..XCOM.XCOMCNTL
//SYSIN01  DD DISP=SHR,
//         DSN=&VNBSHHLI..D&VNB6DATE..T&VNB6TIME..XCOMCMD.FILE(CONTROL)
//* *==============================================================* *
//CONTROLD EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 DELETE &VNBSHHLI..D&VNB6DATE..T&VNB6TIME..XCOMCMD.FILE(CONTROL)

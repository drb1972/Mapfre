)SEL &C1SY = LJ
//&RMEM JOB 0,'NDVR &PKG',CLASS=A,MSGCLASS=Y,USER=PMFBCH,
//             SCHENV=ENDEVUP,REGION=64M&NOTIFY
)ENDSEL
)SEL &C1SY = IF | &C1SY = QI
//&RMEM JOB 0,'NDVR &PKG',CLASS=A,MSGCLASS=Y,USER=PMFBCH,
//             SCHENV=WCDMG##,REGION=400M&NOTIFY
)ENDSEL
)SEL &C1SY ^= LJ && &C1SY ^= IF && &C1SY ^= QI
//&RMEM JOB 0,'NDVR &PKG',CLASS=A,MSGCLASS=Y,USER=PMFBCH,
//             SCHENV=ENDEVUP,REGION=400M&NOTIFY
)ENDSEL
//JCLLIB   JCLLIB ORDER=(&PROCLIB)
//*
//*********************************************************************
//*                                                                   *
//* SKELETON CMSENDR                                                  *
//*                                                                   *
//* ENDEVOR PRODUCTION RELEASE: ENDEVOR RJOB                          *
//*                                                                   *
)SEL &EMERGNCY EQ YES
//* CHANGE: &CMR.           RELEASE TYPE: EMERGENCY (STAN/EMER)    *
)ENDSEL
)SEL &EMERGNCY NE YES
//* CHANGE: &CMR.           RELEASE TYPE: STANDARD  (STAN/EMER)    *
)ENDSEL
//*                                                                   *
//* ORIGINAL IMPLEMENTATION DATE: &SKDATE                            *
//*                         TIME: &SKTIME                            *
//*                                                                   *
//*********************************************************************
//** NDVRC1 - ENDEVOR INSPECT STEP                                   **
//*********************************************************************
//INSPECT  EXEC PGM=NDVRC1,PARM=ENBP1000,DYNAMNBR=1500
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSABEND DD SYSOUT=C
//ENPSCLIN DD *
 INSPECT PACKAGE '&PKG'
.
/*
//*********************************************************************
//** SPWARN - ABEND IF INSPECT RETURN CODE IS GREATER THAN FOUR      **
//*********************************************************************
//CHECKIT  IF INSPECT.RC GT 8 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** NDVRC1 - RUN A REPORT ON THE PACKAGE AS INPUT TO PACKSCAN       **
//*********************************************************************
//DELCHECK EXEC PGM=NDVRC1,PARM='C1BR1000'
//BSTRPTS  DD DSN=&&BSTRPT,DISP=(NEW,PASS,DELETE),
//             RECFM=FBA,LRECL=133,
//             SPACE=(TRK,(15,30),RLSE)
//BSTINP   DD *
     REPORT  72 .
     ENVIRONMENT * .
     PACKAGE  '&PKG'  .
     STATUS  APPROVED .
/*
//BSTPDS   DD DUMMY
//SMFDATA  DD DUMMY
//UNLINPT  DD DUMMY
//BSTPCH   DD DSN=&&TEMP,
//             DISP=(NEW,DELETE,DELETE),
//             RECFM=FB,LRECL=838,
//             SPACE=(TRK,(15,30),RLSE)
//BSTLST   DD SYSOUT=*
//SORTIN   DD SPACE=(TRK,(375,375),RLSE)
//SORTOUT  DD SPACE=(TRK,(375,375),RLSE)
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//*********************************************************************
//** SPWARN - ABEND IF DELCHECK RETURN CODE IS GREATER THAN ZERO     **
//*********************************************************************
//CHECKIT  IF DELCHECK.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** IRXJCL - PACKSCAN SCANS REPORT AND IF ANY ELEMENT DELETES THEN  **
//**          1) BUILD ARCHIVE SCL FOR NEXT STEP                     **
//**          2) BUILD JCL TO COPY ARCHIVE TO ACCUMULATED ARCHIVE    **
//*********************************************************************
//PACKSCAN EXEC PGM=IRXJCL,
//             PARM='PACKSCAN &SHIPHLQC &CMR'
)SEL &C1SY = EK
//SYSEXEC  DD DSN=PREV.FEV1.REXX,DISP=SHR
//         DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
)SEL &C1SY ^= EK
//SYSEXEC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
//REPIN    DD DSN=&&BSTRPT,
//             DISP=(OLD,DELETE)               /* FROM DELCHECK      */
//REPOUT   DD DSN=&&BSTRPTO,DISP=(,PASS,DELETE),
//             RECFM=FB,LRECL=80,
//             SPACE=(TRK,(15,30),RLSE)
//COPYJCL  DD DSN=&SHIPHLQC..ARCHIVE.COPYJCL,
//             DISP=(,CATLG,DELETE),
//             RECFM=FB,LRECL=80,
//             SPACE=(TRK,(3,1),RLSE)
//PKGSCL   DD DSN=&SHIPHLQC..ARCHIVE.PKGSCL,
//             DISP=(,CATLG,DELETE),
//             RECFM=FB,LRECL=80,
//             SPACE=(TRK,(3,1),RLSE)
//RSTSCL   DD DSN=&SHIPHLQC..ARCHIVE.RSTSCL,
//             DISP=(,CATLG,DELETE),
//             RECFM=FB,LRECL=80,
//             SPACE=(TRK,(3,1),RLSE)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF PACKSCAN RETURN CODE IS GREATER THAN FOUR     **
//*********************************************************************
//CHECKIT  IF PACKSCAN.RC GT 4 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** DELAGAIN IF NO DELETES TO ARCHIVE THEN DELETE THE DATASETS      **
//*********************************************************************
//*
//NODELS   IF PACKSCAN.RC EQ 4 THEN
//*
//DELAGAIN EXEC PGM=IEFBR14
//COPYJCL  DD DSN=&SHIPHLQC..ARCHIVE.COPYJCL,
//             DISP=(MOD,DELETE),
//             RECFM=FB,LRECL=80,
//             SPACE=(TRK,(3,1),RLSE)
//PKGSCL   DD DSN=&SHIPHLQC..ARCHIVE.PKGSCL,
//             DISP=(MOD,DELETE),
//             RECFM=FB,LRECL=80,
//             SPACE=(TRK,(3,1),RLSE)
//RSTSCL   DD DSN=&SHIPHLQC..ARCHIVE.RSTSCL,
//             DISP=(MOD,DELETE),
//             RECFM=FB,LRECL=80,
//             SPACE=(TRK,(3,1),RLSE)
//NODELS   ENDIF
//*
//*********************************************************************
//** NDVRC1 - IF PACKSCAN FOUND ELEMENT DELETES THEN ARCHIVE THE     **
//**          ELEMENTS USING THE SCL WRITTEN TO BSTRPTO TEMPORARY    **
//**          DATASET CREATED IN PACKSCAN STEP                       **
//*********************************************************************
//DOARHIV  IF PACKSCAN.RC EQ 0 THEN
//*
//ARCHIVE  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//C1TPDD01 DD RECFM=VB,LRECL=260,SPACE=(TRK,(75,75),RLSE)
//C1TPDD02 DD RECFM=VB,LRECL=260,SPACE=(TRK,(75,75),RLSE)
//C1TPLSIN DD RECFM=FB,LRECL=80,SPACE=(TRK,(75,75),RLSE)
//C1TPLSOU DD SPACE=(TRK,(75,75),RLSE)
//C1PLMSGS DD SYSOUT=*
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD RECFM=FBA,LRECL=121,BLKSIZE=6171,SYSOUT=*
//SYSABEND DD SYSOUT=C
//SYSOUT   DD SYSOUT=*
//ARCHIVE  DD DSN=&SHIPHLQC..ARCHIVE,
//             DISP=(NEW,CATLG,DELETE),
//             RECFM=VB,LRECL=27994,BLKSIZE=27998,
//             SPACE=(TRK,(75,300),RLSE)
//BSTIPT01 DD DSN=&&BSTRPTO,DISP=(OLD,DELETE,DELETE)
//*
//*********************************************************************
//** SPWARN - ABEND IF ARCHIVE RETURN CODE IS GREATER THAN FOUR      **
//*********************************************************************
//CHECKIT  IF ARCHIVE.RC GT 4 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//DOARCHIV ENDIF
//*
//*********************************************************************
//** IDCAMS - CHECK IF LISTING DSN EXISTS                            **
//*********************************************************************
//LISTCAT  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 LISTCAT ENTRIES(&SHIPHLQC..LISTINGS)
/*
//*********************************************************************
//** SPWARN - ABEND IF LISTCAT RETURN CODE IS GREATER THAN FOUR      **
//*********************************************************************
//CHECKIT  IF LISTCAT.RC GT 4 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** IDCAMS - CREATE VSAM FOR ELIB LISTING DSN - IF NOT ALREADY THERE**
//*********************************************************************
//IFNOLIST IF LISTCAT.RC = 4 THEN
//*
//DEFLIST  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DEFINE CLUSTER -
         (NAME(&SHIPHLQC..LISTINGS) -
         SHR(3 3) -
         RECORDSIZE(26616 26616) -
         CISZ(26624) -
         TRACKS(150 150) -
         NONINDEXED ) -
   DATA (NAME(&SHIPHLQC..LISTINGS.DATA) )
/*
//*********************************************************************
//** SPWARN - ABEND IF DEFLIST RETURN CODE IS GREATER THAN ZERO      **
//*********************************************************************
//CHECKIT  IF DEFLIST.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** BC1PNLIB  - INIT THE LISTING DSN                                **
//*********************************************************************
//*
//INITLIST EXEC PGM=BC1PNLIB
//LIST001  DD DSN=&SHIPHLQC..LISTINGS,DISP=OLD
//SYSPRINT DD SYSOUT=*
//BSTERR   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSIN    DD *
  INIT     DDNAME=LIST001
           PAGE SIZE = 26616
           ALLOCATE = (299,300)
           RESERVE PAGES = 260
           DIRECTORY PAGES = 7
          .
/*
//*********************************************************************
//** SPWARN - ABEND IF INITLIST RETURN CODE IS GREATER THAN ZERO     **
//*********************************************************************
//CHECKIT  IF INITLIST.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//IFNOLIST ENDIF
//*

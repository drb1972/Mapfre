&JOB1
&JOB2
&JOB3
&JOB4
//********************************************************************
//*   THIS JOB COPIES ELEMENT &ELE FROM WALKER
//*   INTO ELEMENT &NDVELE OF TYPE &TYPE IN ENVIRONMENT &ENVT
//********************************************************************
//*
//*+------------------------------------------------------------------+
//** DELETE   - TEMPORARY DATA SETS
//*+------------------------------------------------------------------+
//DELETE   EXEC PGM=IEFBR14,COND=EVEN
//DEL001   DD DSN=&ZPREFIX..WALKER.&NDVELE,
//             DISP=(MOD,DELETE,DELETE),SPACE=(TRK,1)
//DEL002   DD DSN=&ZPREFIX..BACKUP.&NDVELE,
//             DISP=(MOD,DELETE,DELETE),SPACE=(TRK,1)
//*
)SEL &TYPE = ERR
//*+------------------------------------------------------------------+
//* TSO      - CREATE ERR CARDS
//*+------------------------------------------------------------------+
//TSO      EXEC PGM=IKJEFT01
//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.ISPCLIB
//SYSTSPRT DD SYSOUT=*
//BACKUP   DD DISP=(,KEEP,DELETE),DSN=&ZPREFIX..BACKUP.&NDVELE,
//             SPACE=(TRK,(1,15),RLSE),
//             RECFM=FB,LRECL=80
//SYSTSIN  DD *
 EXECUTIL SEARCHDD(YES)
 %ERRCARDB &ELE
//*
)ENDSEL
//*
//*+------------------------------------------------------------------+
//** IOBKRSTR - EXTRACT ELEMENT FROM WALKER DB2 DATABASE
//*+------------------------------------------------------------------+
//IOBKRSTR EXEC PGM=WBSSBKR,DYNAMNBR=20
//STEPLIB  DD DSN=SYSDB2.SDSNLOAD,DISP=SHR
//         DD DSN=PREV.ACJ1.LOAD,DISP=SHR
//         DD DSN=PREV.BCJ1.LOAD,DISP=SHR
//         DD DSN=PREV.DCJ1.LOAD,DISP=SHR
//         DD DSN=PREV.FCJ1.LOAD,DISP=SHR
//         DD DSN=PREV.PCJ1.LOAD,DISP=SHR
//         DD DSN=PRCJ.BASE.LOAD,DISP=SHR       FOR EM
//DB2INPUT DD *
)SEL &ESY = CJ
DB3 DCJBATCH
)ENDSEL
)SEL &ESY = EM
DBT DCJBATCH
)ENDSEL
/*
)SEL &TYPE = ERR
//SYSIN    DD DSN=&ZPREFIX..BACKUP.&NDVELE,DISP=SHR
)ENDSEL
)SEL &TYPE ^= ERR
//SYSIN    DD *
)IM WALKS110
)ENDSEL
/*
//SYS013   DD DSN=&ZPREFIX..WALKER.&NDVELE,
//             DISP=(,KEEP,DELETE),SPACE=(TRK,(1,15),RLSE)
//SYSTSPRT DD SYSOUT=*
//SYS012   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//*+------------------------------------------------------------------+
//** NDVRBAT  - ADD ELEMENT INTO ENDEVOR
//*+------------------------------------------------------------------+
//NDVRBAT  EXEC PGM=NDVRC1,COND=(0,LT),DYNAMNBR=1500,
//             PARM='C1BM3000'
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=121
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//BSTIPT01 DD *
  ADD ELEMENT '&NDVELE'
   FROM DSNAME '&ZPREFIX..WALKER.&NDVELE'
   TO   ENV '&ENVT'  SYS '&ESY'  SUB '&ESYS'  TYP '&TYPE'
       OPTIONS  CCID '&CCID'
       COMMENT '&ELE'
       OVERRIDE SIGNOUT  UPDATE
   .
/*
//*+------------------------------------------------------------------+
//** DELETE   - TEMPORARY DATA SETS
//*+------------------------------------------------------------------+
//DELETE   EXEC PGM=IEFBR14,COND=EVEN
//DEL001   DD DSN=&ZPREFIX..WALKER.&NDVELE,
//             DISP=(MOD,DELETE,DELETE),SPACE=(TRK,1)
//DEL002   DD DSN=&ZPREFIX..BACKUP.&NDVELE,
//             DISP=(MOD,DELETE,DELETE),SPACE=(TRK,1)

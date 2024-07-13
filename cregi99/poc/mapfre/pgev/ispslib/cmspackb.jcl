//&RMEM JOB 0,'NDVR &CMR.P',CLASS=A,MSGCLASS=Y,USER=PMFBCH,
//             REGION=6M,SCHENV=ENDEVUP
//SETVAR   SET ID=PG,BNK=G,TLQ=
//JCLLIB   JCLLIB ORDER=(PGOS.&TLQ.BASE.PROCLIB)
//*
//*--SKELETON CMSPACKB - BACKOUT PACKAGE                             --
//*********************************************************************
//**                                                                 **
//**     ENDEVOR JCL FOR RESCHED, ABORT OR BACKOUT OF CHANGE         **
//**     RECORD &CMR
//**                                                                 **
//**     CALLED BY PROD/EV/EV1/REXX EVUTLITY                         **
//*********************************************************************
//*
//*********************************************************************
//** PACKOUT - BACKOUT ENDEVOR PACKAGE                               **
//*********************************************************************
//PACKOUT  EXEC PGM=NDVRC1,PARM='ENBP1000'
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//SYSTERM  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSABEND DD SYSOUT=C
//ENPSCLIN DD *
  BACKOUT PACKAGE &CMR.P  .
/*
//*********************************************************************
//** SPWARN - ABEND IF PACKOUT RETURN CODE GREATER THAN FOUR         **
//*********************************************************************
//CHECKIT  IF (PACKOUT.RC GT 4) THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF

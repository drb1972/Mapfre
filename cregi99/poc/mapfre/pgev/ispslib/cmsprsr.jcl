//*********************************************************************
//** SKELETON CMSPRSR                                                **
//** IEBUPDTE - CREATE PROCESS FILE AND ADD SUBMIT MEMBER            **
//*********************************************************************
//PROCESS  EXEC PGM=IEBUPDTE,PARM=NEW
//SYSPRINT DD SYSOUT=*
//SYSUT2   DD DSN=&SHIPHLQC..PROCESS.FILE,
//             DISP=(,CATLG),RECFM=FB,LRECL=80,BLKSIZE=15440,
//             SPACE=(TRK,(15,15,44),RLSE)
//SYSUT1   DD DUMMY
//SYSIN    DD DISP=SHR,DSN=SYSNDVR.CAI.SOURCE(#PS#NDM)
//*
//*********************************************************************
//** SPWARN - ABEND IF PROCESS STEP RETURN CODE IS GREATER THAN ZERO **
//*********************************************************************
//CHECKIT  IF PROCESS.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//*********************************************************************
//** IEBUPDTE - CREATE NDM SUBMIT CARDS - COPY PROCESS               **
//*********************************************************************
//NDMSUB   EXEC PGM=IEBUPDTE,PARM=MOD
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&SHIPHLQC..PROCESS.FILE,DISP=OLD
//SYSUT2   DD DSN=&SHIPHLQC..PROCESS.FILE,DISP=OLD
//SYSIN    DD DSN=&SHIPHLQC..XNWC,DISP=(OLD,DELETE)
//*
//*********************************************************************
//** SPWARN - ABEND IF NDMSUB RETURN CODE GREATER THAN ZERO          **
//*********************************************************************
//CHECKIT  IF NDMSUB.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*

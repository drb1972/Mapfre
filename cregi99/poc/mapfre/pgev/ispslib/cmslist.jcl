//*--SKELETON CMSLIST - DELETE EMPTY LISTING FILES                   --
//*********************************************************************
//** SUBMIT JOB TO DELETE EMPTY LISTING FILES
//*********************************************************************
//LISTDELE EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DATA,DLM=ZZ
//EVGLISTI JOB CLASS=N,MSGCLASS=Y
//* RUN THROUGH JCLPREP ON 14/03/2011 AT 08:49:58 BY STUARCA FOR QFOS
//*
//INQUIRE  EXEC PGM=BC1PNLIB
//LISTING  DD DSN=&SHIPHLQC..LISTINGS,DISP=SHR
//SYSPRINT DD DSN=&&REPORT,DISP=(NEW,PASS),
//             SPACE=(TRK,(2,5),RLSE),RECFM=FBA,
//             LRECL=134
//BSTERR   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSIN    DD *
  INQUIRE  DDNAME=LISTING .                                             00461000
/*                                                                      00461105
//CHECKIT  IF INQUIRE.RC NE 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
//SEARCH   EXEC PGM=ISRSUPC,PARM=(SRCHCMP,'ANYC')
//NEWDD    DD DSN=&&REPORT,DISP=(OLD,DELETE)
//OUTDD    DD SYSOUT=*
//SYSIN    DD *
SRCHFOR  '# MEMBERS:                        0 '
/*
//CHECKIT  IF SEARCH.RC GT 1 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//@CHECKL  IF SEARCH.RC = 1 THEN
//*
//DELETE   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE &SHIPHLQC..LISTINGS
/*
//@CHECKL  ENDIF
//CHECKIT  IF DELETE.RC NE 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
ZZ
//SYSUT2   DD SYSOUT=(A,INTRDR)

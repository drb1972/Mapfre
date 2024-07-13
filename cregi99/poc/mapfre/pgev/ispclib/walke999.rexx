PROC 0 DEBUG TEST
/*********************************************************************/
/* PROCEDURE WALKE999;  BATCH ALTERNATIVE TO WALKE100                */
/* ALLOW USER TO SPECIFY WALKER ELEMENT TO BE PROMOTED               */
/* FILE TAILOR A JOB TO EXTRACT THE ELEMENT FROM WALKER AND          */
/* AND ADD UPDATE IT TO ENDEVOR                                      */
/*                                                                   */
/* AMENDMENT HISTORY                                                 */
/* WHEN     WHO           WHY                                        */
/* 20/03/95 JOHN ABBOTT   ORIGINAL VERSION                           */
/* 21/03/95 JOHN ABBOTT   ALLOCATE TABLE LIBRARY FOR LIVE RUNNING    */
/* 27/07/95 STEVE PINSKER PROCESS ERR TYPES                          */
/* 28/08/97 JOHN WARD     SPECIAL VERSION FOR BULK LOAD              */
/*                                                                   */
/*********************************************************************/
ERROR DO
      SET RC = &LASTCC
      RETURN
      END
IF &DEBUG = DEBUG +
THEN DO
     CONTROL SYMLIST CONLIST LIST PROMPT
     ISPEXEC LIBDEF USRTABL DATASET ID('TTEV.BASE.ISPTLIB')
     IF &RC > 0 THEN GOTO PROBLEM
     ISPEXEC LIBDEF ISPSLIB DATASET ID('PREV.CEV1.ISPSLIB'    +
       'PREV.DEV1.ISPSLIB' 'PREV.FEV1.ISPSLIB' 'PREV.PEV1.ISPSLIB')
     IF &RC > 0 THEN GOTO PROBLEM
     END
ELSE DO
     CONTROL NOSYMLIST NOCONLIST NOLIST NOPROMPT
     ISPEXEC LIBDEF USRTABL DATASET ID('PGEV.BASE.ISPTLIB')
     IF &RC > 0 THEN GOTO PROBLEM
     ISPEXEC LIBDEF ISPSLIB DATASET ID('PGEV.BASE.ISPSLIB')
     IF &RC > 0 THEN GOTO PROBLEM
     END

ALLOC F(NEWELES) DA('TTRG.BASE.DATA(WALKE100)') SHR

ISPEXEC CONTROL ERRORS RETURN  /* I WILL HANDLE RC'S FROM ISPF */

ISPEXEC VGET (GTPECAPP GTPECLEV) PROFILE

IF &GTPECAPP = EV AND &GTPECLEV = USER +
THEN SET &TEST = TEST          /* ARE WE IN THE TEST ENVIRONMENT?  */

SET RC = 0                     /* TO STORE LAST RETURN CODE        */
SET CCID = C0122195            /* CONSTANT */
SET ENVT = UNIT                /* CONSTANT */
SET JOB1 = &STR(//TTRGJFWW JOB WARDJF,NOTIFY=WARDJF,CLASS=J)
SET JOB2 = &STR(//*)
SET JOB3 = &STR(//*)
SET JOB4 = &STR(//*)

/*********************************************************************/
/*  OPEN AND GET INPUT FILE                                          */
/*  CONTAINS TYPE IN COLS 1-3 AND NAME IN COL 5 ONWARDS              */
/*********************************************************************/
OPENFILE NEWELES INPUT
IF &RC > 0 +
THEN GOTO PROBLEM
DISPLAY: +
ERROR DO
     SET RC = &LASTCC
     IF &RC = 400 THEN GOTO FINISH
     ELSE GOTO PROBLEM
     END
GETFILE NEWELES
ERROR DO
      SET RC = &LASTCC
      RETURN
      END
SET TYPE = &SUBSTR(1:3,&NEWELES)
SET ELE = &SUBSTR(5:&SYSINDEX( ,&NEWELES,5)-1,&NEWELES)
WRITE &TYPE &ELE

/*********************************************************************/
/*  PAD ELEMENT WITH UNDERSCORES AS REQUIRED BY WALKER                */
/*********************************************************************/

SELECT &TYPE
WHEN (GMT | TGS | TID | DOP | MVT) +
     SET L = 3
WHEN (FID | SCR | VMS) +
     SET L = 8
WHEN (RPT | DOC) +
     SET L = 12
WHEN (NAM) +
     SET L = 30
WHEN (ERR) DO
     SET ELE = &SUBSTR(1:4,&ELE)
     GOTO SKIP
  END
END

SET ELE = &NRSTR(&ELE)______________________________
SET ELE = &SUBSTR(1:&L,&NRSTR(&ELE))
SKIP: +
ISPEXEC VPUT (ELE, TYPE, ENVT, CCID, JOB1, JOB2, JOB3, JOB4)

/*********************************************************************/
/*  LOOK THE ELEMENT UP IN THE TABLE                                 */
/*  RC=0 IF FOUND, RC=1 IF NOT FOUND                                 */
/*********************************************************************/
     ISPEXEC SELECT CMD(WALKE110 &DEBUG) MODE(FSCR)
     IF &RC > 1 THEN GOTO PROBLEM
     IF &RC = 0 THEN GOTO SUBMIT

/*********************************************************************/
/*  ADD ELEMENT TO TABLE                                             */
/*  RC=0 IF OK                                                       */
/*********************************************************************/
     SET RC = 0
     ISPEXEC SELECT CMD(WALKE120 &DEBUG) MODE(FSCR)
     IF &RC > 0 THEN GOTO PROBLEM

/*********************************************************************/
/*  SUBMIT JOB                                                       */
/*********************************************************************/
SUBMIT:  +
ISPEXEC FTOPEN TEMP
IF &RC > 8 THEN GOTO PROBLEM

     SET RC = 0
ISPEXEC FTINCL WALKS100
IF &RC > 0 THEN GOTO PROBLEM

ISPEXEC FTCLOSE
IF &RC > 0 THEN GOTO PROBLEM

IF &TEST = TEST +
THEN DO
     ISPEXEC VGET (ZTEMPN)
     IF &RC > 0 THEN GOTO PROBLEM

     ISPEXEC LMINIT DATAID(SKEL)  DDNAME(&ZTEMPN)
     IF &RC > 0 THEN GOTO PROBLEM

     ISPEXEC EDIT DATAID(&SKEL)
     IF &RC > 4 THEN GOTO PROBLEM

     ISPEXEC LMFREE DATAID(&SKEL)
     IF &RC > 4 THEN GOTO PROBLEM
END
ELSE DO
     ISPEXEC VGET (ZTEMPF)
     SUBMIT '&ZTEMPF'
END

GOTO DISPLAY

PROBLEM: +
ERROR DO
      SET RC = &LASTCC
      RETURN
      END
ISPEXEC FTCLOSE

FINISH: +
ERROR DO
      SET RC = &LASTCC
      RETURN
      END
CLOSFILE NEWELES
FREE F(NEWELES)
ISPEXEC LIBDEF USRTABL
ISPEXEC LIBDEF ISPSLIB

EXIT

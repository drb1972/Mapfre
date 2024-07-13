PROC 0 DEBUG TEST
/*********************************************************************/
/* PROCEDURE WALKE100                                                */
/* ALLOW USER TO SPECIFY WALKER ELEMENT TO BE PROMOTED               */
/* FILE TAILOR A JOB TO EXTRACT THE ELEMENT FROM WALKER AND          */
/* AND ADD UPDATE IT TO ENDEVOR                                      */
/*                                                                   */
/* AMENDMENT HISTORY                                                 */
/* WHEN     WHO          WHY                                         */
/* 20/03/95 JOHN ABBOTT  ORIGINAL VERSION                            */
/* 21/03/95 JOHN ABBOTT  ALLOCATE TABLE LIBRARY FOR LIVE RUNNING     */
/*                                                                   */
/*                                                                   */
/*********************************************************************/
IF &DEBUG = DEBUG +
     THEN CONTROL SYMLIST CONLIST LIST PROMPT
     ELSE CONTROL NOSYMLIST NOCONLIST NOLIST NOPROMPT


ISPEXEC LIBDEF USRTABL DATASET ID('PGEV.BASE.ISPTLIB')

ISPEXEC CONTROL ERRORS RETURN  /* I WILL HANDLE RC'S FROM ISPF */

ISPEXEC VGET (GTPECAPP GTPECLEV) PROFILE

IF &GTPECAPP = EV AND &GTPECLEV = USER +
THEN SET &TEST = TEST          /* ARE WE IN THE TEST ENVIRONMENT?  */

SET MSG =                      /* ISPF MESSSAGE ID FOR DISPLAY     */
SET CSR = ELE                  /* ISPF CURSUR POSITION FOR DISPLAY */
SET RC = 0                     /* TO STORE LAST RETURN CODE        */

/*********************************************************************/
/*  DISPLAY THE MAIN PANEL                                           */
/*********************************************************************/
DISPLAY: +
ISPEXEC DISPLAY PANEL(WALKP100) MSG(&MSG) CURSOR(&CSR)
SET RC = &LASTCC
IF &RC > 8 THEN GOTO PROBLEM

IF &RC = 8 +
     THEN GOTO FINISH

/*********************************************************************/
/*  GET VARIABLES FROM ISPF                                          */
/*********************************************************************/
ISPEXEC VGET (ELE TYPE CCID ENVT)
IF &LASTCC > 0 THEN GOTO PROBLEM

SET MSG =
SET CSR = ELE

/*********************************************************************/
/*  PERFORM VALIDATION                                               */
/*********************************************************************/
IF &SUBSTR(1:1,&STR(&CCID)) ^= C +
THEN DO
     SET MSG = WALKM100
     SET CSR = CCID
     GOTO DISPLAY
END

IF &STR(&ELE) ^= +
THEN DO
/*********************************************************************/
/*  ELEMENT FIELD ON SCREEN IS NOT BLANK                             */
/*  PAD IT WITH UNDERSCORES AS REQUIRED BY WALKER                    */
/*********************************************************************/

SELECT &TYPE
WHEN (GMT | TGS | TID) +
     SET L = 3
WHEN (FID | SCR | VMS) +
     SET L = 8
WHEN (RPT | DOC) +
     SET L = 12
WHEN (NAM) +
     SET L = 30
END

SET ELE = &NRSTR(&ELE)______________________________
SET ELE = &SUBSTR(1:&L,&NRSTR(&ELE))
ISPEXEC VPUT (ELE)

/*********************************************************************/
/*  LOOK THE ELEMENT UP IN THE TABLE                                 */
/*  RC=0 IF FOUND, RC=1 IF NOT FOUND                                 */
/*********************************************************************/
     ISPEXEC SELECT CMD(WALKE110 &DEBUG) MODE(FSCR)
     SET RC = &LASTCC
     IF &RC > 1 THEN GOTO FINISH
END
ELSE DO
/*********************************************************************/
/*  ELEMENT FIELD ON SCREEN IS BLANK                                 */
/*  LET THE USER SELECT AN ELEMENT FROM THE TABLE                    */
/*  RC=0 IF SELECTED,  RC=1 IF NOT SELECTED                          */
/*********************************************************************/
     ISPEXEC SELECT CMD(WALKE130 &DEBUG) MODE(FSCR)
     SET RC = &LASTCC
     IF &RC = 0 +
     THEN DO
          ISPEXEC VGET (ELE NDVELE)
          IF &LASTCC > 0 THEN GOTO PROBLEM
     END

     IF &RC > 1 THEN GOTO FINISH

     IF &RC = 1 +
     THEN DO
          SET MSG = WALKM105
          SET CSR = ELE
          GOTO DISPLAY
     END
END

/*********************************************************************/
/*  IF THE ELEMENT IS NOT ON THE TABLE ASK THE USER IF SHE WANTS     */
/*  TO ADD A NEW ELEMENT                                             */
/*********************************************************************/
IF &RC = 1 +
THEN DO
     ISPEXEC ADDPOP  ROW(12)   COLUMN(40)
     IF &LASTCC > 0 THEN GOTO PROBLEM

     ISPEXEC DISPLAY PANEL(WALKP110)
     IF &LASTCC > 0 THEN GOTO PROBLEM

     ISPEXEC REMPOP
     IF &LASTCC > 0 THEN GOTO PROBLEM

     ISPEXEC VGET REPLY
     IF &LASTCC > 0 THEN GOTO PROBLEM

     IF &REPLY = YES +
     THEN DO
          ISPEXEC SELECT CMD(WALKE120 &DEBUG) MODE(FSCR)
          IF &LASTCC > 0 THEN GOTO FINISH
          SET MSG = WALKM102
          SET CSR = ELE
          GOTO DISPLAY
     END
     ELSE GOTO DISPLAY
END

/*********************************************************************/
/*  CONFIRM THAT THE USER WANTS TO SUBMIT THE JOB                    */
/*********************************************************************/

ISPEXEC ADDPOP  ROW(12)   COLUMN(40)
IF &LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC DISPLAY PANEL(WALKP120)
IF &LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC REMPOP
IF &LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC VGET REPLY
IF &LASTCC > 0 THEN GOTO PROBLEM

IF &REPLY ^= YES +
THEN DO
     SET MSG = WALKM101
     SET CSR = ELE
     GOTO DISPLAY
END

/*********************************************************************/
/*  SUBMIT JOB                                                       */
/*********************************************************************/
ISPEXEC FTOPEN TEMP
IF &LASTCC > 8 THEN GOTO PROBLEM

ISPEXEC FTINCL WALKS100
IF &LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC FTCLOSE
IF &LASTCC > 0 THEN GOTO PROBLEM

IF &TEST = TEST +
THEN DO
     ISPEXEC VGET (ZTEMPN)
     IF &LASTCC > 0 THEN GOTO PROBLEM

     ISPEXEC LMINIT DATAID(SKEL)  DDNAME(&ZTEMPN)
     IF &LASTCC > 0 THEN GOTO PROBLEM

     ISPEXEC EDIT DATAID(&SKEL)
     IF &LASTCC > 4 THEN GOTO PROBLEM

     ISPEXEC LMFREE DATAID(&SKEL)
     IF &LASTCC > 0 THEN GOTO PROBLEM
END
ELSE DO
     ISPEXEC VGET (ZTEMPF)
     SUBMIT '&ZTEMPF'
END

/*********************************************************************/
/*  SAVE UPDATED VARIABLES IN THE PROFILE POOL                       */
/*********************************************************************/
ISPEXEC VPUT (ELE TYPE CCID ENVT JOB1 JOB2 JOB3 JOB4) PROFILE

SET MSG = WALKM104
SET CSR = ELE

GOTO DISPLAY

PROBLEM: +
ISPEXEC DISPLAY PANEL(WALKP000)

FINISH: +
ISPEXEC LIBDEF USRTABL

EXIT

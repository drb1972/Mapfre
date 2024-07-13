PROC 0 T() V() P() A() CL() DEBUG
/*********************************************************************/
/* PROCEDURE WALKE140                                                */
/* PROCESS LOCATE COMMAND FOR A TABLE DISPLAY SCREEN                 */
/*                                                                   */
/* PARAMETERS:                                                       */
/*   T = TABLE ID                                                    */
/*   V = VARIABLE ID USED AS SEARCH ARGUMENT                         */
/*   P = PANEL ID - TO REFRESH SCREEN                                */
/*   A = SEARCH ARGUMENT VALUE                                       */
/*   CL = CALLING MODULE CHAIN                                       */
/*                                                                   */
/* AMENDMENT HISTORY                                                 */
/* WHEN     WHO          WHY                                         */
/* 20/03/95 JOHN ABBOTT  ORIGINAL VERSION                            */
/*                                                                   */
/*                                                                   */
/*********************************************************************/
IF &DEBUG = DEBUG +
     THEN CONTROL SYMLIST CONLIST LIST PROMPT
     ELSE CONTROL NOSYMLIST NOCONLIST NOLIST NOPROMPT

SET URC = 0
SET UTBID = &T
SET UVID = &V
SET UPANID = &P
SET UARG = &STR(&A)
SET UARGL = &LENGTH(&STR(&UARG))
SET UTARG =

/* VALIDATE COMMAND                                                   */
IF &SUBSTR(1:2,&STR(&UARG)) = &STR(L ) THEN +
  DO
    SET UTARG = &SUBSTR(3:&LENGTH(&STR(&UARG)),&STR(&UARG))
  END
ELSE IF &UARGL > 4 THEN +
IF &SUBSTR(1:4,&STR(&UARG)) = &STR(LOC ) THEN +
  DO
    SET UTARG = &SUBSTR(5:&LENGTH(&STR(&UARG)),&STR(&UARG))
  END
ELSE IF &UARGL > 7 THEN +
IF &SUBSTR(1:7,&STR(&UARG)) = &STR(LOCATE ) THEN +
  DO
    SET UTARG = &SUBSTR(8:&LENGTH(&STR(&UARG)),&STR(&UARG))
  END
IF UTARG = THEN +
  GOTO UEND1

/* SKIP TO ROW                                                        */
SET &&UVID = &STR(&UTARG)
ISPEXEC TBSCAN &UTBID ARGLIST(&UVID) ROWID(UROWID) NOREAD +
        CONDLIST(GE)
SET URC = &LASTCC
IF &URC = 0 THEN +
  DO
    ISPEXEC TBSKIP &UTBID ROW(&UROWID) NOREAD
    ISPEXEC CONTROL DISPLAY LOCK
    ISPEXEC TBDISPL &UTBID PANEL(&UPANID) AUTOSEL(NO)
  END
ELSE +
  DO
    ISPEXEC SETMSG MSG(WALKM107)
    SET URC = 0
  END
/*                                                                    */
UEND1: +
EXIT CODE(&URC)

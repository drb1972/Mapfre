PROC 0 DEBUG
/*********************************************************************/
/* PROCEDURE WALKE120                                                */
/* ADDS A NEW WALKER ELEMENT TO THE TABLE                            */
/* CONTRUCTS ALIAS FROM TYPE AND NUMBER OF ROWS IN THE TABLE         */
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

ISPEXEC CONTROL ERRORS RETURN

ISPEXEC VGET (TYPE ELE)
IF LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC TBOPEN WALKT&TYPE WRITE LIBRARY(USRTABL)
IF LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC TBSTATS WALKT&TYPE ROWCURR(ROWS)
IF LASTCC > 0 THEN GOTO PROBLEM

SET ROWS = &SUBSTR(4:8,&STR(&ROWS))
SET NDVELE = &STR(&TYPE&ROWS)
SET DESC = &STR(ADDED BY &SYSUID ON &SYSDATE AT &SYSTIME)

ISPEXEC VPUT (ELE NDVELE DESC)
IF LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC TBADD WALKT&TYPE ORDER
IF LASTCC > 0 THEN GOTO PROBLEM

GOTO FINISH

PROBLEM: +
ISPEXEC CONTROL ERRORS CANCEL
ISPEXEC DISPLAY PANEL (WALKP000)

FINISH: +
ISPEXEC TBCLOSE WALKT&TYPE LIBRARY(USRTABL)
IF &LASTCC > 0 THEN GOTO PROBLEM

EXIT

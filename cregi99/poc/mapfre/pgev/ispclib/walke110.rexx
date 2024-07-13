PROC 0 DEBUG
/*********************************************************************/
/* PROCEDURE WALKE110                                                */
/* FINDS WALKER ELEMENT IN TABLE AND RETURNS THE ENDEVOR ALIAS       */
/* IF NOT FOUND GIVES RETURN CODE OF 1 TO CALLER                     */
/*                                                                   */
/* AMENDMENT HISTORY                                                 */
/* WHEN     WHO          WHY                                         */
/* 20/03/95 JOHN ABBOTT  ORIGINAL VERSION                            */
/* 09/06/95 JOHN ABBOTT  VPUT NDVELE TO MAKE IT AVAILABLE TO SKEL    */
/*                                                                   */
/*                                                                   */
/*********************************************************************/
IF &DEBUG = DEBUG +
     THEN CONTROL SYMLIST CONLIST LIST PROMPT
     ELSE CONTROL NOSYMLIST NOCONLIST NOLIST NOPROMPT


ISPEXEC CONTROL ERRORS RETURN

ISPEXEC VGET (TYPE ELE)
IF &LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC TBOPEN WALKT&TYPE LIBRARY(USRTABL) NOWRITE
IF &LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC TBGET WALKT&TYPE
SET RC = &LASTCC
IF &RC = 8 THEN GOTO NOTFOUND
IF &RC > 8 THEN GOTO PROBLEM
ISPEXEC VPUT NDVELE
IF &LASTCC > 0 THEN GOTO PROBLEM
GOTO DONE

NOTFOUND: +
ISPEXEC TBEND WALKT&TYPE
IF &LASTCC > 0 THEN GOTO PROBLEM
EXIT CODE(1)

PROBLEM: +
ISPEXEC CONTROL ERRORS CANCEL
ISPEXEC DISPLAY PANEL(WALKP000)

DONE: +
ISPEXEC TBEND WALKT&TYPE
IF &LASTCC > 0 THEN GOTO PROBLEM

EXIT CODE(0)

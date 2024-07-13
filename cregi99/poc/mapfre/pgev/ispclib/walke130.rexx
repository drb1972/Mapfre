PROC 0 DEBUG
/*********************************************************************/
/* PROCEDURE WALKE130                                                */
/* ALLOWS USER TO SELECT EXACTLY 1 WALKER ELEMENT FROM TABLE         */
/* IF NOTHING IS SELECTED GIVES RETURN CODE 1 TO CALLER              */
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

ISPEXEC VGET (TYPE)
IF &LASTCC > 0 THEN GOTO PROBLEM

ISPEXEC TBOPEN WALKT&TYPE NOWRITE LIBRARY(USRTABL)
IF &LASTCC > 0 THEN GOTO PROBLEM

SET CSR =
SET MSG =

DISPLAY: +
ISPEXEC TBDISPL WALKT&TYPE PANEL(WALKP130) MSG(&MSG) CURSOR(&CSR)
SET RC = &LASTCC
REDISP: +
IF &RC = 0 +
THEN DO
     ISPEXEC VGET (ZTDSELS ZCMD)
     IF &LASTCC > 0 THEN GOTO PROBLEM

     IF &ZTDSELS = 0 +
     THEN DO
          IF &LENGTH(&STR(&ZCMD)) > 2 +
          THEN DO

                ISPEXEC SELECT CMD(WALKE140         +
                                   T(WALKT&TYPE)    +
                                   V(ELE)           +
                                   P(WALKP130)      +
                                   A('&STR(&ZCMD)') +
                                   CL(WALKE130) &DEBUG ) +
                               MODE(FSCR)
                ISPEXEC TBDISPL WALKT&TYPE
                SET RC = &LASTCC
                GOTO REDISP

          END
          ELSE DO
               GOTO NOTHING
          END
     END
END
IF &RC = 4 +
THEN DO
     SET CSR = SEL
     SET MSG = WALKM106
     GOTO DISPLAY
END
IF &RC = 8 +
THEN DO
     GOTO NOTHING
END

IF &RC > 8 +
THEN DO
     GOTO PROBLEM
END

GOTO FINISH

NOTHING: +
ISPEXEC TBEND WALKT&TYPE
EXIT CODE(1)

PROBLEM: +
ISPEXEC CONTROL ERRORS CANCEL
ISPEXEC DISPLAY PANEL(WALKP000)
ISPEXEC TBEND WALKT&TYPE
EXIT CODE(&MAXCC)

FINISH: +
ISPEXEC TBEND WALKT&TYPE
EXIT CODE(0)

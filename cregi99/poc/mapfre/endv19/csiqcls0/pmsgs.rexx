PROC 0
/* CONTROL LIST CONLIST MSG END(END) NOCAPS */
ISPEXEC VGET (ZSCREEN ZPREFIX ZUSER ZSYSID)
/* ************************************************************** */
/* *  PREFIX(TSOID1)  USERID(TSOID1) ->                           */
/* *                  DSN=TSOID1.C1TEMPR_.PZSYSID.MSGS            */
/* *  NOPREFIX        USERID(TSOID1) ->                           */
/* *                  DSN=TSOID1.C1TEMPR_.PZSYSID.MSGS            */
/* *  PREFIX(TSO1D2)  USERID(TSOID1) ->                           */
/* *                  DSN=TSOID2.TSOID1.C1TEMPR_.PZSYSID.MSGS     */
/* ************************************************************** */
SET &CPUIDLN = &LENGTH(&ZSYSID)
/*  IF ZSYSID IS 8 BYTES LONG THEN USE ONLY 1ST 7 BYTES */
IF  &CPUIDLN = 8 THEN SET &CPUIDLN = 7
SET &CPUID = &SUBSTR(1:&CPUIDLN,&ZSYSID)

IF &C1DSN = &STR() THEN +
  DO
   IF &ZPREFIX = &STR() OR &ZPREFIX = &ZUSER THEN +
SET &C1DSN = &STR('&ZUSER..C1TEMPR&ZSCREEN..P&CPUID..MSGS')
   ELSE +
SET &C1DSN = &STR('&ZPREFIX..&ZUSER..C1TEMPR&ZSCREEN..P&CPUID..MSGS')
   END
IF &SYSDSN(&C1DSN) EQ OK THEN GOTO DISPLAY
/* ************************************************************** */
/* MESSAGE FILE COULD BE APPLIED.  BUILD THE DSNAME WITHOUT THE   */
/* SYSID AND THEN CHECK.                                          */
/* ************************************************************** */
   IF &ZPREFIX = &STR() OR &ZPREFIX = &ZUSER THEN +
SET &C1DSN = &STR('&ZUSER..C1TEMPR&ZSCREEN..MSGS')
   ELSE +
SET &C1DSN = &STR('&ZPREFIX..&ZUSER..C1TEMPR&ZSCREEN..MSGS')
/* END */

DISPLAY:+
ISPEXEC CONTROL ERRORS RETURN
ISPEXEC BROWSE DATASET(&C1DSN)
IF &LASTCC NE 0 THEN DO
  SET ZERRSM=&STR()
  SET ZERRLM=&STR(MESSAGE DATASET (&C1DSN) EMPTY OR NOT FOUND)
  SET ZERRALRM=YES
  ISPEXEC SETMSG MSG(ISRZ002)
END
EXIT CODE(&MAXCC)

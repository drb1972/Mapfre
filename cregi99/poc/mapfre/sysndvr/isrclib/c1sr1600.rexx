PROC 0 DEBUG()

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                */
/*                                                                   */
/* NAME: C1SR1600                                                    */
/*                                                                   */
/* PURPOSE: THIS CLIST WILL DRIVE THE PACKAGE SHIPMENT REPORTS       */
/*          SUB-DIALOG                                               */
/*                                                                   */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* SET UP DEBUGGING AND RUN PARAMETERS                               */
/*-------------------------------------------------------------------*/
 GLOBAL PNLCUR PNLMSG ENDISCLW
 IF &DEBUG = &STR(DEBUG) THEN +
   CONTROL MSG NOFLUSH LIST CONLIST SYMLIST NOPROMPT ASIS
 ELSE  +
   CONTROL NOMSG NOFLUSH NOLIST NOCONLIST NOSYMLIST NOPROMPT ASIS

/* INITIALIZE FIELDS USED ON THE  PANEL */
    ISPEXEC VGET ( VAREVNME SYS SBS TYPEN D DAYS )  PROFILE

    SET &RPT73 = &STR(_)
    SET &RPT74 = &STR(_)
    SET &RPT75 = &STR(_)
    SET &RPT76 = &STR(_)

    SET &PNLCUR = RPT73

/* DISPLAY THE PACKAGE SHIPMENT REPORT PANEL  */
/* THE REPORT JOB STEP                                               */

DISP: +
    ISPEXEC DISPLAY PANEL(C1SR1600)  +
                    CURSOR(&PNLCUR)  +
                    MSG   (&PNLMSG)

/*********************************************************************/
/*   CHECK FOR NON ZERO VALUE IN LASTCC                              */
/*   THIS CHECK ALLOWS FOR PF3 AND =X LOGIC TO WORK PROPERLY         */
/*********************************************************************/
    IF (&LASTCC ^= 0) THEN +
       GOTO FINI

/* RESET PANEL MESSAGE AND CURSOR POSTION                           */
    SET &PNLMSG   =
    SET &PNLCUR   = ZCMD


/* IF EDITS OK THEN SAVE VARIABLES                                  */
    ISPEXEC VPUT ( VARSPPKG VARDEST )  PROFILE

/* SET UP VALUES USED BY FILE TAILORING                             */
    SET &RPTCAT = &STR(SHP)
    SET &REPORT  = &STR()

/*------------------------------------------------------------------*/
/* SET UP AN ERROR HANDLING ROUTINE.  IF A SYNTAX ERROR IS RAISED   */
/* WHILE CHECKING THE REPORT SELECT CHARACTERS, WE ISSUE CISR016    */
/* AND REDISPLAY THE REPORT SELECTION PANEL, PLACING THE CURSOR     */
/* ON THE OFFENDING SELECTOR. NOTE THAT THE ERROR HANDLING IS       */
/* TURNED OFF AFTER THIS SECTION, SO THIS IS ONLY IN EFFECT FOR THE */
/* SELECTION CHARACTER TESTS.                                       */
/*------------------------------------------------------------------*/
  ERROR -
    DO
      SET &PNLMSG = CISR016
      SET &PNLCUR = &RPTNUM
      GOTO DISP
    END

    SET &RPTNUM = RPT73
    IF &STR(&RPT73) ^= &STR( ) AND +
       &STR(&RPT73) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 73)

    SET &RPTNUM = RPT74
    IF &STR(&RPT74) ^= &STR( ) AND +
       &STR(&RPT74) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 74)

    SET &RPTNUM = RPT75
    IF &STR(&RPT75) ^= &STR( ) AND +
       &STR(&RPT75) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 75)

    SET &RPTNUM = RPT76
    IF &STR(&RPT76) ^= &STR( ) AND +
       &STR(&RPT76) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 76)

    ERROR OFF

    IF &REPORT  = &STR() THEN DO
        SET &PNLMSG   = CISR003
        SET &PNLCUR   = RPT73
        GOTO DISP
     END

    ISPEXEC FTOPEN TEMP
    ISPEXEC FTINCL C1SR8100
    ISPEXEC FTCLOSE
    ISPEXEC VGET (ZTEMPF)

   ALLOC FILE(FTJCL) DA('&ZTEMPF')

/* SET UP ERROR ROUTINE FOR THE REPORTING INTERFACE */
  ERROR -
    DO
      SET &RC = &LASTCC
      IF (&RC = 400) THEN -
        SET &EOF = ON
      ELSE -
        DO
          SET &ERROR = ON
          WRITE AN I/O ERROR OCCURRED IN C1SR1600. RC=&RC
          GOTO FINI
        END
      RETURN
    END

  /*------------------------------------------------------------------*/
  /* COPY THE REPORT JCL CREATED BY FILE TAILORING TO THE NDVRJCL_    */
  /* FILE.                                                            */
  /*------------------------------------------------------------------*/
  ISPEXEC VGET (ZSCREEN)
  OPENFILE FTJCL INPUT
  OPENFILE NDVRJCL&ZSCREEN OUTPUT
  SET &ERROR = OFF
  SET &EOF = OFF

READJCL: -
  GETFILE FTJCL
  IF (&EOF = ON) THEN -
     GOTO EOFJCL
  SET &NDVRJCL&ZSCREEN = &FTJCL
  PUTFILE NDVRJCL&ZSCREEN
  GOTO READJCL

EOFJCL: -
  CLOSFILE FTJCL INPUT
  CLOSFILE NDVRJCL&ZSCREEN OUTPUT
  SET ENDISCLW = &STR(Y)

  FREE FILE(FTJCL)

  SET &PNLCUR = ZCMD
  SET &PNLMSG = CISR002

GOTO FINI

FINI: +
  EXIT

PROC 0 DEBUG()

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                */
/*                                                                   */
/* NAME: C1SR1100                                                    */
/*                                                                   */
/* PURPOSE: THIS CLIST WILL DRIVE THE MCF REPORT SUB-DIALOG.         */
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
    ISPEXEC VGET (VAREVNME SYS SBS TYPEN CIELM D DAYS S) PROFILE

    SET &RPT01 = &STR(_)
    SET &RPT02 = &STR(_)
    SET &RPT03 = &STR(_)
    SET &RPT04 = &STR(_)
    SET &RPT05 = &STR(_)
    SET &RPT06 = &STR(_)
    SET &RPT07 = &STR(_)
    SET &RPT08 = &STR(_)
    SET &RPT09 = &STR(_)
    SET &RPT10 = &STR(_)
    SET &RPT11 = &STR(_)
    SET &RPT12 = &STR(_)

    IF  &S   = &STR() THEN -
      DO
        SET &S = &STR(N)
      END

    SET &PNLCUR = RPT01
/*-------------------------------------------------------------------*/
/* DISPLAY THE MCF REPORT SELECTION PANEL AND OBTAIN THE REPORTS TO  */
/* BE GENERATED AND THE INVENTORY LOCATION INFORMATION.              */
/*-------------------------------------------------------------------*/

DISP: +
    ISPEXEC DISPLAY PANEL(C1SR1100)  +
                    CURSOR(&PNLCUR)  +
                    MSG(&PNLMSG)

    IF (&LASTCC ^= 0) THEN +
      GOTO FINI

    SET &PNLMSG = &STR()
    SET &PNLCUR = ZCMD

/*------------------------------------------------------------------*/
/* EDIT THE DIALOG PANEL VARIABLES                                  */
/*------------------------------------------------------------------*/
    IF &STR(&VAREVNME) = &STR() THEN DO
        SET &PNLMSG = CISR005             /* ENVIRONMENT REQUIRED */
        SET &PNLCUR = VAREVNME
        GOTO DISP
     END
    IF &STR(&VAREVNME) = &STR(*) THEN DO
        SET &PNLMSG = CISR005             /* ENVIRONMENT REQUIRED */
        SET &PNLCUR = VAREVNME
        GOTO DISP
     END

/* CHK SEARCH ENVIRONMENT MAPPING, "S" VALUES "Y" OR "N" ALLOWED */
    IF &S ^= &STR(Y) AND  +
       &S ^= &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = S
        GOTO DISP
     END

/* CHK DAYS VALUE, NULL OR 1 THRU 32767 ALLOWED */

 IF &DATATYPE(&STR(&DAYS)) ^= NUM THEN +
   DO
     IF  &STR(&DAYS) ^= &STR() THEN +
       DO
         SET &PNLMSG = CIIO045
         SET &PNLCUR = DAYS
         GOTO DISP
       END
     SET &DAYS = 7
   END

 IF ((&DAYS < 0) OR (&DAYS > 32767)) THEN +
   DO
     SET &PNLMSG = CIIO045
     SET &PNLCUR = DAYS
     GOTO DISP
   END

/* IF EDITS OK THEN SAVE VARIABLES                                  */
    ISPEXEC VPUT ( VAREVNME SYS SBS TYPEN CIELM D DAYS S)  PROFILE

/* SET UP VALUES USED BY FILE TAILORING                             */
   SET &RPTCAT = &STR(MCF)
   SET &REPORT = &STR()

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

   SET &RPTNUM = RPT01
   IF &STR(&RPT01) ^= &STR(_) AND +
      &STR(&RPT01) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 01)

   SET &RPTNUM = RPT02
   IF &STR(&RPT02) ^= &STR(_) AND +
      &STR(&RPT02) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 02)

   SET &RPTNUM = RPT03
   IF &STR(&RPT03) ^= &STR(_) AND +
      &STR(&RPT03) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 03)

   SET &RPTNUM = RPT04
   IF &STR(&RPT04) ^= &STR(_) AND +
      &STR(&RPT04) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 04)

   SET &RPTNUM = RPT05
   IF &STR(&RPT05) ^= &STR(_) AND +
      &STR(&RPT05) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 05)

   SET &RPTNUM = RPT06
   IF &STR(&RPT06) ^= &STR(_) AND +
      &STR(&RPT06) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 06)

   SET &RPTNUM = RPT07
   IF &STR(&RPT07) ^= &STR(_) AND +
      &STR(&RPT07) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 07)

   SET &RPTNUM = RPT08
   IF &STR(&RPT08) ^= &STR(_) AND +
      &STR(&RPT08) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 08)

   SET &RPTNUM = RPT09
   IF &STR(&RPT09) ^= &STR(_) AND +
      &STR(&RPT09) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 09)

   SET &RPTNUM = RPT10
   IF &STR(&RPT10) ^= &STR(_) AND +
      &STR(&RPT10) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 10)

   SET &RPTNUM = RPT11
   IF &STR(&RPT11) ^= &STR(_) AND +
      &STR(&RPT11) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 11)

   SET &RPTNUM = RPT12
   IF &STR(&RPT12) ^= &STR(_) AND +
      &STR(&RPT12) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 12)

  ERROR OFF

   IF &REPORT  = &STR() THEN -
     DO
       SET &PNLMSG = CISR003
       SET &PNLCUR = RPT01
       GOTO DISP
     END

   SET &SEMLIT = &STR()
   IF &S = &STR(Y) THEN +
     SET &SEMLIT = &STR(&SEARCH ENVIRONMENT MAPPING)

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
          WRITE AN I/O ERROR OCCURRED IN C1SR1100. RC=&RC
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

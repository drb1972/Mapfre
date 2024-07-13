PROC 0 DEBUG()

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
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
    ISPEXEC VGET (VAREVNME SYS SBS TYPEN D DAYS S VNTUPPER) PROFILE

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

/*  DEFAULT NUMBER OF DAYS TO 7 IF VALUE IS BLANK */
    IF  &DAYS = &STR() THEN -
      DO
        SET &DAYS = &STR(0007)
      END

/*  DEFAULT SEARCH MAP TO N IF VALUE IS BLANK */
    IF  &S   = &STR() THEN -
      DO
        SET &S = &STR(N)
      END

/*  DEFAULT UPPERCASE TO N IF VALUE IS BLANK */
    IF  &VNTUPPER = &STR() THEN -
      DO
        SET &VNTUPPER = &STR(Y)
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

/* IF THE UPPERCASE FLAG IS Y, USE THE SYSCAPS FUNCTION
/* TO UPPER CASE THE ELEMENT NAME
    IF  &VNTUPPER = &STR(Y) THEN -
      DO
        SET &VNT1ENME = &SYSCAPS(&STR(&VNT1ENME))
      END

/*------------------------------------------------------------------*/
/* CLEAR THE FIVE 51 CHARACTER VARIABLES
/*------------------------------------------------------------------*/
    SET &LINE1 = &STR()
    SET &LINE2 = &STR()
    SET &LINE3 = &STR()
    SET &LINE4 = &STR()
    SET &LINE5 = &STR()

    SET &LEN = &LENGTH(&STR(&VNT1ENME))

/*------------------------------------------------------------------*/
/* PARSE THE 255 CHAR VARIABLE INTO 5-51 CHAR VARIABLES WITH QUOTES
/* AT THE BEGINNING AND END OF EACH AND A COMMA IF IT CONTINUES
/*------------------------------------------------------------------*/
    IF &STR(&VNT1ENME) ^= &STR() THEN DO
      IF &LEN GT 51 THEN DO
        SET &LINE1 = &STR('&SUBSTR(1:51,&STR(&VNT1ENME))',)
        IF &LEN GT 102 THEN DO
          SET &LINE2 = &STR('&SUBSTR(52:102,&STR(&VNT1ENME))',)
          IF &LEN GT 153 THEN DO
            SET &LINE3 = &STR('&SUBSTR(103:153,&STR(&VNT1ENME))',)
            IF &LEN GT 204 THEN DO
              SET &LINE4 = &STR('&SUBSTR(154:204,&STR(&VNT1ENME))',)
              SET &LINE5 = &STR('&SUBSTR(205:&LEN,&STR(&VNT1ENME))' .)
             END
            ELSE +
              SET &LINE4 = &STR('&SUBSTR(154:&LEN,&STR(&VNT1ENME))' .)
           END
          ELSE +
            SET &LINE3 = &STR('&SUBSTR(103:&LEN,&STR(&VNT1ENME))' .)
         END
        ELSE +
          SET &LINE2 = &STR('&SUBSTR(52:&LEN,&STR(&VNT1ENME))' .)
       END
      ELSE +
        SET &LINE1 = &STR('&SUBSTR(1:&LEN,&STR(&VNT1ENME))' .)
     END


/* IF EDITS OK THEN SAVE VARIABLES                                  */
    ISPEXEC VPUT (VAREVNME SYS SBS TYPEN D DAYS S VNTUPPER) PROFILE

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

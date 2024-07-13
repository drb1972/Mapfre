PROC 0 DEBUG()

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: C1SR1500                                                    */
/*                                                                   */
/* PURPOSE: THIS CLIST WILL DRIVE THE UNLOAD DATA SET REPORT SUB-    */
/*  DIALOG                                                           */
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
    ISPEXEC VGET (VAREVNME SYS SBS TYPEN D VARSPPKG +
                  UNLDJCL1 UNLDJCL2 UNLDJCL3 VNTUPPER)  PROFILE

    SET &RPT50 = &STR(_)
    SET &RPT51 = &STR(_)
    SET &RPT52 = &STR(_)
    SET &RPT53 = &STR(_)
    SET &RPT54 = &STR(_)
    SET &RPT55 = &STR(_)

    SET &PNLCUR = RPT50

/*  DEFAULT UPPERCASE TO N IF VALUE IS BLANK */
    IF  &VNTUPPER = &STR() THEN -
      DO
        SET &VNTUPPER = &STR(Y)
      END

/* DISPLAY THE MCF RPT PANEL TO GET ALL THE NECESSARY INFORMATION FOR*/
/* THE REPORT JOB STEP                                               */

DISP: +
    ISPEXEC DISPLAY PANEL(C1SR1500)  +
                    CURSOR(&PNLCUR)  +
                    MSG   (&PNLMSG)

    IF (&LASTCC ^= 0) THEN -
       GOTO FINI

/* RESET PANEL MESSAGE AND CURSOR POSTION                           */
    SET &PNLMSG   =
    SET &PNLCUR   = ZCMD
    IF &LASTCC ^= 0 +
       THEN GOTO FINI

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
    ISPEXEC VPUT ( VAREVNME SYS SBS TYPEN D VARSPPKG +
                   UNLDJCL1 UNLDJCL2 UNLDJCL3 VNTUPPER)  PROFILE

/* SET UP VALUES USED BY FILE TAILORING                             */
    SET &RPTCAT = &STR(ULD)
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

   SET &RPTNUM = RPT50
    IF &STR(&RPT50) ^= &STR(_) AND +
       &STR(&RPT50) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 50)

   SET &RPTNUM = RPT51
    IF &STR(&RPT51) ^= &STR(_) AND +
       &STR(&RPT51) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 51)

   SET &RPTNUM = RPT52
    IF &STR(&RPT52) ^= &STR(_) AND +
       &STR(&RPT52) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 52)

   SET &RPTNUM = RPT53
    IF &STR(&RPT53) ^= &STR(_) AND +
       &STR(&RPT53) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 53)

   SET &RPTNUM = RPT54
    IF &STR(&RPT54) ^= &STR(_) AND +
       &STR(&RPT54) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 54)

   SET &RPTNUM = RPT55
    IF &STR(&RPT55) ^= &STR(_) AND +
       &STR(&RPT55) ^= &STR( ) THEN SET &REPORT = &STR(&REPORT 55)

    ERROR OFF

    IF &REPORT  = &STR() THEN DO
        SET &PNLMSG   = CISR003
        SET &PNLCUR   = RPT50
        GOTO DISP
     END

    IF &STR(&UNLDJCL1) = &STR() THEN DO
        SET &PNLMSG   = CISR004
        SET &PNLCUR   = UNLDJCL1
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
          WRITE AN I/O ERROR OCCURRED IN C1SR1500. RC=&RC
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

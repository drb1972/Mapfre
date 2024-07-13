PROC 0 DEBUG()

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: C1SR1100                                                    */
/*                                                                   */
/* PURPOSE: THIS CLIST WILL DRIVE THE SMF REPORT SUB-DIALOG.         */
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
    ISPEXEC VGET (VAREVNME SYS SBS TYPEN D DAYS +
                  SMFDSN VNTUPPER) PROFILE

    SET &RPT40 = &STR(_)
    SET &RPT41 = &STR(_)
    SET &RPT42 = &STR(_)
    SET &RPT43 = &STR(_)

    SET &PNLCUR = RPT40

/*  DEFAULT UPPERCASE TO N IF VALUE IS BLANK */
    IF  &VNTUPPER = &STR() THEN -
      DO
        SET &VNTUPPER = &STR(Y)
      END

/*  DEFAULT NUMBER OF DAYS TO 7 IF VALUE IS BLANK */
    IF  &DAYS = &STR() THEN -
      DO
        SET &DAYS = &STR(0007)
      END

/*-------------------------------------------------------------------*/
/* DISPLAY THE SMF REPORT PANEL AN COLLECT THE INFORMATION NEEDED TO */
/* GENERATE THE REPORT STEP.                                         */
/*-------------------------------------------------------------------*/

DISP: +
    ISPEXEC DISPLAY PANEL(C1SR1200)  +
                    CURSOR(&PNLCUR)  +
                    MSG(&PNLMSG)

    IF (&LASTCC ^= 0) THEN +
      DO
        SET &PNLMSG = &STR()
        SET &PNLCUR = &STR()
        GOTO FINI
      END

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

/*-------------------------------------------------------------------*/
/* EDIT THE PANEL VALUES                                             */
/*-------------------------------------------------------------------*/
    IF &STR(&SMFDSN) = &STR() THEN -
      DO
         SET &PNLMSG  = CISR006
         SET &PNLCUR  = SMFDSN
         GOTO DISP
      END

/* EDIT FOR VALID DATASET NAME */
    SET &FTPDSN =
    IF (&STR(&SMFDSN) ^= &STR()) THEN -
      DO
        IF &STR(') ^= &SUBSTR(1,&SMFDSN) THEN -
          DO
            ISPEXEC VGET (ZPREFIX)
            SET &TMPDSN = &STR('&ZPREFIX..&SMFDSN.')
            IF &STR(.) = &SUBSTR(2,&TMPDSN) THEN +
              DO
                SET &TMPDSN = &STR('&SMFDSN.')
              END
          END
        ELSE +
           SET &TMPDSN = &STR(&SMFDSN)

        SET &BGNDSN = 2
        SET &ENDDSN = &STR(&LENGTH(&STR(&TMPDSN)))
        IF  &STR(') = &SUBSTR(&ENDDSN,&TMPDSN) THEN +
          SET &ENDDSN = &EVAL(&ENDDSN - 1)
        SET &SMFDSNJ = &SUBSTR(&BGNDSN:&ENDDSN,&TMPDSN)

      END

/* IF EDITS OK THEN SAVE VARIABLES                                  */
    ISPEXEC VPUT (VAREVNME SYS SBS TYPEN D DAYS +
                  SMFDSN VNTUPPER) PROFILE

/* SET UP VALUES USED BY FILE TAILORING                             */
    SET &RPTCAT = &STR(SMF)
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

    SET &RPTNUM = RPT40
    IF &STR(&RPT40) ^= &STR( ) AND +
       &STR(&RPT40) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 40)

    SET &RPTNUM = RPT41
    IF &STR(&RPT41) ^= &STR( ) AND +
       &STR(&RPT41) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 41)

    SET &RPTNUM = RPT42
    IF &STR(&RPT42) ^= &STR( ) AND +
       &STR(&RPT42) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 42)

    SET &RPTNUM = RPT43
    IF &STR(&RPT43) ^= &STR( ) AND +
       &STR(&RPT43) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 43)

    ERROR OFF

    IF (&REPORT = &STR()) THEN -
      DO
         SET &PNLMSG = CISR003
         SET &PNLCUR = ZCMD
         GOTO DISP
      END

    ISPEXEC FTOPEN TEMP
    ISPEXEC FTINCL C1SR8100
    ISPEXEC FTCLOSE
    ISPEXEC VGET (ZTEMPF)

   ALLOC FILE(FTJCL) DA('&ZTEMPF')

/*-------------------------------------------------------------------*/
/* SET UP ERROR ROUTINE FOR THE REPORTING INTERFACE                  */
/*-------------------------------------------------------------------*/
  ERROR -
    DO
      SET &RC = &LASTCC
      IF (&RC = 400) THEN -
        SET &EOF = ON
      ELSE -
        DO
          SET &ERROR = ON
          WRITE AN I/O ERROR OCCURRED IN C1SR1200. RC=&RC
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

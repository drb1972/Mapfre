PROC 0 DEBUG()

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: C1SR1300                                                    */
/*                                                                   */
/* PURPOSE: THIS CLIST WILL DRIVE THE PACKAGE REPORTS SUB-DIALOG     */
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

    SET &RPT70 = &STR(_)
    SET &RPT71 = &STR(_)
    SET &RPT72 = &STR(_)
    SET &RPT7376 = &STR(_)
    SET &RPT6063 = &STR(_)

    SET &VNBPKGS0 = &STR(Y)
    SET &VNBPKGS1 = &STR(Y)
    SET &VNBPKGS2 = &STR(Y)
    SET &VNBPKGS3 = &STR(Y)
    SET &VNBPKGS4 = &STR(Y)
    SET &VNBPKGS5 = &STR(Y)
    SET &VNBPKGS6 = &STR(Y)
    SET &VNBPKGS7 = &STR(Y)
    SET &VNBPKGS8 = &STR(Y)

    SET &VNBXPHIS = &STR(Y)

    SET &PNLCUR = RPT70

/* DISPLAY THE PACKAGE REPORT PANEL  */
/* THE REPORT JOB STEP                                               */

DISP: +
    ISPEXEC DISPLAY PANEL(C1SR1300)  +
                    CURSOR(&PNLCUR)  +
                    MSG   (&PNLMSG)

/*********************************************************************/
/*   CHECK FOR NON ZERO VALUE IN LASTCC                              */
/*   THIS CHECK ALLOWS FOR PF3 AND =X LOGIC TO WORK PROPERLY         */
/*********************************************************************/
    IF (&LASTCC NE 0) THEN +
       GOTO FINI

/* RESET PANEL MESSAGE AND CURSOR POSTION                           */
    SET &PNLMSG   =
    SET &PNLCUR   = ZCMD

/* EDIT THE PANEL VALUES                                            */
/* CHECK STATUS FIELDS ONLY VALUES "Y" OR "N" ALLOWED */
    IF &VNBPKGS0 NE &STR(Y) AND  +
       &VNBPKGS0 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS0
        GOTO DISP
     END

    IF &VNBPKGS1 NE &STR(Y) AND  +
       &VNBPKGS1 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS1
        GOTO DISP
     END

    IF &VNBPKGS2 NE &STR(Y) AND  +
       &VNBPKGS2 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS2
        GOTO DISP
     END

    IF &VNBPKGS3 NE &STR(Y) AND  +
       &VNBPKGS3 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS3
        GOTO DISP
     END

    IF &VNBPKGS4 NE &STR(Y) AND  +
       &VNBPKGS4 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS4
        GOTO DISP
     END

    IF &VNBPKGS5 NE &STR(Y) AND  +
       &VNBPKGS5 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS5
        GOTO DISP
     END

    IF &VNBPKGS6 NE &STR(Y) AND  +
       &VNBPKGS6 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS6
        GOTO DISP
     END

    IF &VNBPKGS7 NE &STR(Y) AND  +
       &VNBPKGS7 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS7
        GOTO DISP
     END

    IF &VNBPKGS8 NE &STR(Y) AND  +
       &VNBPKGS8 NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBPKGS8
        GOTO DISP
     END

    IF &VNBXPHIS NE &STR(Y) AND  +
       &VNBXPHIS NE &STR(N) THEN  DO
        SET &PNLMSG   = CIIO048
        SET &PNLCUR   = VNBXPHIS
        GOTO DISP
     END


/* IF EDITS OK THEN SAVE VARIABLES                                  */
    ISPEXEC VPUT ( VARSPPKG RAPPROVE )  PROFILE

/* CHECK THE DATE VALUES USED.                                      */
CHKDATES:+
IF (&STR(&WADTE) NE &STR( )) THEN DO
    SET &WAMONTH = &STR(&SUBSTR(1:2,&WADTE))
    SET &WADAY = &STR(&SUBSTR(3:4,&WADTE))
    IF (&LENGTH(&WADTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = WADTE
       GOTO DISP
    END
    SET &WAYEAR = &STR(&SUBSTR(5:8,&WADTE))
    IF (&WAMONTH < 01) OR (&WAMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = WADTE
        GOTO DISP
    END
    IF (&WADAY < 01) OR (&WADAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = WADTE
        GOTO DISP
    END
END
IF (&STR(&WBDTE) NE &STR( )) THEN DO
    SET &WBMONTH = &STR(&SUBSTR(1:2,&WBDTE))
    SET &WBDAY = &STR(&SUBSTR(3:4,&WBDTE))
    IF (&LENGTH(&WBDTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = WBDTE
       GOTO DISP
    END
    SET &WBYEAR = &STR(&SUBSTR(5:8,&WBDTE))
    IF (&WBMONTH < 01) OR (&WBMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = WBDTE
        GOTO DISP
    END
    IF (&WBDAY < 01) OR (&WBDAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = WBDTE
        GOTO DISP
    END
END
IF (&STR(&CADTE) NE &STR( )) THEN DO
    SET &CAMONTH = &STR(&SUBSTR(1:2,&CADTE))
    SET &CADAY = &STR(&SUBSTR(3:4,&CADTE))
    IF (&LENGTH(&CADTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = CADTE
       GOTO DISP
    END
    SET &CAYEAR = &STR(&SUBSTR(5:8,&CADTE))
    IF (&CAMONTH < 01) OR (&CAMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = CADTE
        GOTO DISP
    END
    IF (&CADAY < 01) OR (&CADAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = CADTE
        GOTO DISP
    END
END
IF (&STR(&CBDTE) NE &STR( )) THEN DO
    SET &CBMONTH = &STR(&SUBSTR(1:2,&CBDTE))
    SET &CBDAY = &STR(&SUBSTR(3:4,&CBDTE))
    IF (&LENGTH(&CBDTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = CBDTE
       GOTO DISP
    END
    SET &CBYEAR = &STR(&SUBSTR(5:8,&CBDTE))
    IF (&CBMONTH < 01) OR (&CBMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = CBDTE
        GOTO DISP
    END
    IF (&CBDAY < 01) OR (&CBDAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = CBDTE
        GOTO DISP
    END
END
IF (&STR(&EADTE) NE &STR( )) THEN DO
    SET &EAMONTH = &STR(&SUBSTR(1:2,&EADTE))
    SET &EADAY = &STR(&SUBSTR(3:4,&EADTE))
    IF (&LENGTH(&EADTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = EADTE
       GOTO DISP
    END
    SET &EAYEAR = &STR(&SUBSTR(5:8,&EADTE))
    IF (&EAMONTH < 01) OR (&EAMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = EADTE
        GOTO DISP
    END
    IF (&EADAY < 01) OR (&EADAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = EADTE
        GOTO DISP
    END
END
IF (&STR(&EBDTE) NE &STR( )) THEN DO
    SET &EBMONTH = &STR(&SUBSTR(1:2,&EBDTE))
    SET &EBDAY = &STR(&SUBSTR(3:4,&EBDTE))
    IF (&LENGTH(&EBDTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = EBDTE
       GOTO DISP
    END
    SET &EBYEAR = &STR(&SUBSTR(5:8,&EBDTE))
    IF (&EBMONTH < 01) OR (&EBMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = EBDTE
        GOTO DISP
    END
    IF (&EBDAY < 01) OR (&EBDAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = EBDTE
        GOTO DISP
    END
END
IF (&STR(&TADTE) NE &STR( )) THEN DO
    SET &TAMONTH = &STR(&SUBSTR(1:2,&TADTE))
    SET &TADAY = &STR(&SUBSTR(3:4,&TADTE))
    IF (&LENGTH(&TADTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = TADTE
       GOTO DISP
    END
    SET &TAYEAR = &STR(&SUBSTR(5:8,&TADTE))
    IF (&TAMONTH < 01) OR (&TAMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = TADTE
        GOTO DISP
    END
    IF (&TADAY < 01) OR (&TADAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = TADTE
        GOTO DISP
    END
END
IF (&STR(&TBDTE) NE &STR( )) THEN DO
    SET &TBMONTH = &STR(&SUBSTR(1:2,&TBDTE))
    SET &TBDAY = &STR(&SUBSTR(3:4,&TBDTE))
    IF (&LENGTH(&TBDTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = TBDTE
       GOTO DISP
    END
    SET &TBYEAR = &STR(&SUBSTR(5:8,&TBDTE))
    IF (&TBMONTH < 01) OR (&TBMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = TBDTE
        GOTO DISP
    END
    IF (&TBDAY < 01) OR (&TBDAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = TBDTE
        GOTO DISP
    END
END
IF (&STR(&BADTE) NE &STR( )) THEN DO
    SET &BAMONTH = &STR(&SUBSTR(1:2,&BADTE))
    SET &BADAY = &STR(&SUBSTR(3:4,&BADTE))
    IF (&LENGTH(&BADTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = BADTE
       GOTO DISP
    END
    SET &BAYEAR = &STR(&SUBSTR(5:8,&BADTE))
    IF (&BAMONTH < 01) OR (&BAMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = BADTE
        GOTO DISP
    END
    IF (&BADAY < 01) OR (&BADAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = BADTE
        GOTO DISP
    END
END
IF (&STR(&BBDTE) NE &STR( )) THEN DO
    SET &BBMONTH = &STR(&SUBSTR(1:2,&BBDTE))
    SET &BBDAY = &STR(&SUBSTR(3:4,&BBDTE))
    IF (&LENGTH(&BBDTE) < 7) THEN DO
       SET &PNLMSG = CISR022
       SET &PNLCUR = BBDTE
       GOTO DISP
    END
    SET &BBYEAR = &STR(&SUBSTR(5:8,&BBDTE))
    IF (&BBMONTH < 01) OR (&BBMONTH > 12) THEN DO
        SET &PNLMSG = CIIO128
        SET &PNLCUR = BBDTE
        GOTO DISP
    END
    IF (&BBDAY < 01) OR (&BBDAY > 31) THEN DO
        SET &PNLMSG = CIIO129
        SET &PNLCUR = BBDTE
        GOTO DISP
    END
END

/********************************************************************/
/* DETERMINE IF THE AFTER DATE IS GREATER THAN BEFORE DATE          */
/********************************************************************/

    IF &WADTE = &STR( ) THEN GOTO CHKCDTE
    IF &WBDTE = &STR( ) THEN GOTO CHKCDTE
    SET &WADATE = &STR(&SUBSTR(5:8,&WADTE)&SUBSTR(1:4,&WADTE))
    SET &WBDATE = &STR(&SUBSTR(5:8,&WBDTE)&SUBSTR(1:4,&WBDTE))
    IF  &WADATE > &WBDATE  THEN DO
       SET &PNLMSG = CIIO123
       SET &PNLCUR = WADTE
       GOTO DISP
    END

CHKCDTE: +
    IF &CADTE = &STR( ) THEN GOTO CHKEDTE
    IF &CBDTE = &STR( ) THEN GOTO CHKEDTE
    SET &CADATE = &STR(&SUBSTR(5:8,&CADTE)&SUBSTR(1:4,&CADTE))
    SET &CBDATE = &STR(&SUBSTR(5:8,&CBDTE)&SUBSTR(1:4,&CBDTE))
    IF  &CADATE > &CBDATE  THEN DO
       SET &PNLMSG = CIIO124
       SET &PNLCUR = CADTE
       GOTO DISP
    END

CHKEDTE: +
    IF &EADTE = &STR( ) THEN GOTO CHKTDTE
    IF &EBDTE = &STR( ) THEN GOTO CHKTDTE
    SET &EADATE = &STR(&SUBSTR(5:8,&EADTE)&SUBSTR(1:4,&EADTE))
    SET &EBDATE = &STR(&SUBSTR(5:8,&EBDTE)&SUBSTR(1:4,&EBDTE))
    IF  &EADATE > &EBDATE  THEN DO
       SET &PNLMSG = CIIO125
       SET &PNLCUR = EADTE
       GOTO DISP
    END

CHKTDTE: +
    IF &TADTE = &STR( ) THEN GOTO CHKBDTE
    IF &TBDTE = &STR( ) THEN GOTO CHKBDTE
    SET &TADATE = &STR(&SUBSTR(5:8,&TADTE)&SUBSTR(1:4,&TADTE))
    SET &TBDATE = &STR(&SUBSTR(5:8,&TBDTE)&SUBSTR(1:4,&TBDTE))
    IF  &TADATE > &TBDATE  THEN DO
       SET &PNLMSG = CIIO126
       SET &PNLCUR = TADTE
       GOTO DISP
    END

CHKBDTE: +
    IF &BADTE = &STR( ) THEN GOTO ENDCHKDT
    IF &BBDTE = &STR( ) THEN GOTO ENDCHKDT
    SET &BADATE = &STR(&SUBSTR(5:8,&BADTE)&SUBSTR(1:4,&BADTE))
    SET &BBDATE = &STR(&SUBSTR(5:8,&BBDTE)&SUBSTR(1:4,&BBDTE))
    IF  &BADATE > &BBDATE  THEN DO
       SET &PNLMSG = CIIO127
       SET &PNLCUR = BADTE
       GOTO DISP
    END

/* SET UP VALUES USED BY FILE TAILORING                             */
ENDCHKDT:+
    SET &SLASH = &STR(/)

    IF &WADTE = &STR( ) THEN GOTO SETWBDTE
    SET &WADTE1 = &STR(&SUBSTR(1:2,&WADTE))
    SET &WADTE2 = &STR(&SUBSTR(3:4,&WADTE))
    SET &WADTE3 = &STR(&SUBSTR(7:8,&WADTE))
    SET &WADTEF = &STR(&WADTE1&SLASH&WADTE2&SLASH&WADTE3)
    SET &WADTE = &STR(&WADTEF)

SETWBDTE:+
    IF &WBDTE = &STR( ) THEN GOTO SETCADTE
    SET &WBDTE1 = &STR(&SUBSTR(1:2,&WBDTE))
    SET &WBDTE2 = &STR(&SUBSTR(3:4,&WBDTE))
    SET &WBDTE3 = &STR(&SUBSTR(7:8,&WBDTE))
    SET &WBDTEF = &STR(&WBDTE1&SLASH&WBDTE2&SLASH&WBDTE3)
    SET &WBDTE = &STR(&WBDTEF)

SETCADTE:+
    IF &CADTE = &STR( ) THEN GOTO SETCBDTE
    SET &CADTE1 = &STR(&SUBSTR(1:2,&CADTE))
    SET &CADTE2 = &STR(&SUBSTR(3:4,&CADTE))
    SET &CADTE3 = &STR(&SUBSTR(7:8,&CADTE))
    SET &CADTEF = &STR(&CADTE1&SLASH&CADTE2&SLASH&CADTE3)
    SET &CADTE = &STR(&CADTEF)

SETCBDTE:+
    IF &CBDTE = &STR( ) THEN GOTO SETEADTE
    SET &CBDTE1 = &STR(&SUBSTR(1:2,&CBDTE))
    SET &CBDTE2 = &STR(&SUBSTR(3:4,&CBDTE))
    SET &CBDTE3 = &STR(&SUBSTR(7:8,&CBDTE))
    SET &CBDTEF = &STR(&CBDTE1&SLASH&CBDTE2&SLASH&CBDTE3)
    SET &CBDTE = &STR(&CBDTEF)

SETEADTE:+
    IF &EADTE = &STR( ) THEN GOTO SETEBDTE
    SET &EADTE1 = &STR(&SUBSTR(1:2,&EADTE))
    SET &EADTE2 = &STR(&SUBSTR(3:4,&EADTE))
    SET &EADTE3 = &STR(&SUBSTR(7:8,&EADTE))
    SET &EADTEF = &STR(&EADTE1&SLASH&EADTE2&SLASH&EADTE3)
    SET &EADTE = &STR(&EADTEF)

SETEBDTE:+
    IF &EBDTE = &STR( ) THEN GOTO SETTADTE
    SET &EBDTE1 = &STR(&SUBSTR(1:2,&EBDTE))
    SET &EBDTE2 = &STR(&SUBSTR(3:4,&EBDTE))
    SET &EBDTE3 = &STR(&SUBSTR(7:8,&EBDTE))
    SET &EBDTEF = &STR(&EBDTE1&SLASH&EBDTE2&SLASH&EBDTE3)
    SET &EBDTE = &STR(&EBDTEF)

SETTADTE:+
    IF &TADTE = &STR( ) THEN GOTO SETTBDTE
    SET &TADTE1 = &STR(&SUBSTR(1:2,&TADTE))
    SET &TADTE2 = &STR(&SUBSTR(3:4,&TADTE))
    SET &TADTE3 = &STR(&SUBSTR(7:8,&TADTE))
    SET &TADTEF = &STR(&TADTE1&SLASH&TADTE2&SLASH&TADTE3)
    SET &TADTE = &STR(&TADTEF)

SETTBDTE:+
    IF &TBDTE = &STR( ) THEN GOTO SETBADTE
    SET &TBDTE1 = &STR(&SUBSTR(1:2,&TBDTE))
    SET &TBDTE2 = &STR(&SUBSTR(3:4,&TBDTE))
    SET &TBDTE3 = &STR(&SUBSTR(7:8,&TBDTE))
    SET &TBDTEF = &STR(&TBDTE1&SLASH&TBDTE2&SLASH&TBDTE3)
    SET &TBDTE = &STR(&TBDTEF)

SETBADTE:+
    IF &BADTE = &STR( ) THEN GOTO SETBBDTE
    SET &BADTE1 = &STR(&SUBSTR(1:2,&BADTE))
    SET &BADTE2 = &STR(&SUBSTR(3:4,&BADTE))
    SET &BADTE3 = &STR(&SUBSTR(7:8,&BADTE))
    SET &BADTEF = &STR(&BADTE1&SLASH&BADTE2&SLASH&BADTE3)
    SET &BADTE = &STR(&BADTEF)
SETBBDTE:+
    IF &BBDTE = &STR( ) THEN GOTO DATEFIN
    SET &BBDTE1 = &STR(&SUBSTR(1:2,&BBDTE))
    SET &BBDTE2 = &STR(&SUBSTR(3:4,&BBDTE))
    SET &BBDTE3 = &STR(&SUBSTR(7:8,&BBDTE))
    SET &BBDTEF = &STR(&BBDTE1&SLASH&BBDTE2&SLASH&BBDTE3)
    SET &BBDTE = &STR(&BBDTEF)
DATEFIN:+
    SET &RPTCAT = &STR(PKG)
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

    SET &RPTNUM = RPT70
    IF &STR(&RPT70) NE &STR( ) AND +
       &STR(&RPT70) NE &STR(_) THEN SET &REPORT = &STR(&REPORT 70)

    SET &RPTNUM = RPT71
    IF &STR(&RPT71) NE &STR( ) AND +
       &STR(&RPT71) NE &STR(_) THEN SET &REPORT = &STR(&REPORT 71)

    SET &RPTNUM = RPT72
    IF &STR(&RPT72) NE &STR( ) AND +
       &STR(&RPT72) NE &STR(_) THEN SET &REPORT = &STR(&REPORT 72)

    ERROR OFF

    IF &REPORT  = &STR() THEN DO
        SET &PNLMSG   = CISR003
        SET &PNLCUR   = RPT70
        GOTO DISP
     END

    SET &STATUS  = &STR()
    IF &VNBPKGS0 = &STR(Y) THEN SET &STATUS = &STR(&STATUS IN-ED)
    IF &VNBPKGS1 = &STR(Y) THEN SET &STATUS = &STR(&STATUS IN-AP)
    IF &VNBPKGS2 = &STR(Y) THEN SET &STATUS = &STR(&STATUS DE)
    IF &VNBPKGS3 = &STR(Y) THEN SET &STATUS = &STR(&STATUS APPROVED)
    IF &VNBPKGS4 = &STR(Y) THEN SET &STATUS = &STR(&STATUS EXE)
    IF &VNBPKGS5 = &STR(Y) THEN SET &STATUS = &STR(&STATUS AB)
    IF &VNBPKGS6 = &STR(Y) THEN SET &STATUS = &STR(&STATUS CO)
    IF &VNBPKGS7 = &STR(Y) THEN SET &STATUS = &STR(&STATUS BA)
    IF &VNBPKGS8 = &STR(Y) THEN SET &STATUS = &STR(&STATUS IN-EX)

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
          WRITE AN I/O ERROR OCCURRED IN C1SR1300. RC=&RC
          IF (&RC = 348) THEN -
            WRITE CHECK DEFAULT VALUES ON OPTION 0 (SPACE ETC).
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

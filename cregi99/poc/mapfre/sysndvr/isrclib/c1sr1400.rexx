PROC 0 DEBUG(DEBUG)

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                 */
/*                                                                   */
/* NAME: C1SR1400                                                    */
/*                                                                   */
/* PURPOSE: THIS CLIST IS USED TO DRIVE THE FOOTPRINT REPORT         */
/*          SUBDIALOG.                                               */
/*                                                                   */
/*-------------------------------------------------------------------*/
/*  CHANGE HISTORY:                                                  */
/*  ---------------------------------------------------------------- */
/*  WHO  |  DATE   | DESCRIPTION                                     */
/*  ---------------------------------------------------------------- */
/*  BRB     06/03    &F VARIABLE NOT INITIATED TO N                  */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* SET UP DEBUGGING AND RUN PARAMETERS                               */
/*-------------------------------------------------------------------*/
GLOBAL PNLCUR PNLMSG ENDISCLW
IF &DEBUG = &STR(DEBUG) THEN +
    CONTROL MSG NOFLUSH LIST CONLIST SYMLIST NOPROMPT ASIS
ELSE +
    CONTROL NOMSG NOFLUSH NOLIST NOCONLIST NOSYMLIST NOPROMPT ASIS

/*-------------------------------------------------------------------*/
/* INITIALIZE THE DIALOG PANEL FIELDS.                               */
/*-------------------------------------------------------------------*/
    ISPEXEC VGET (PRJ0 LIB0 TYP0 VAREVNME F) PROFILE

    SET &OTHDSN = &STR( )
    SET &RPT80 = &STR(_)
    SET &RPT81 = &STR(_)
    SET &RPT82 = &STR(_)
    SET &RPT83 = &STR(_)
    SET &FOODD = &STR(BSTPDS)

    IF  &STR(&F) NE &STR(N) THEN +
       SET &F = &STR(N)

    SET &PNLCUR = RPT80

/*-------------------------------------------------------------------*/
/* DISPLAY THE 'FOOTPRINT REPORT' PANEL TO ACQUIRE THE INFORMATION   */
/* NEEDED TO BUILD THE JOB STEP.                                     */
/*-------------------------------------------------------------------*/
DISP: +
    ISPEXEC DISPLAY PANEL(C1SR1400)  +
                    CURSOR(&PNLCUR)  +
                    MSG(&PNLMSG)

/*-------------------------------------------------------------------*/
/* IF THE USER ENTERED THE END COMMAND, EXIT THE DIALOG.             */
/*-------------------------------------------------------------------*/
    IF &LASTCC = 8 THEN +
       DO
         SET &PNLCUR = ZCMD
         SET &PNLMSG = &STR()
         GOTO FINI
       END

    SET &PNLMSG = &STR()
    SET &PNLCUR = ZCMD

    /*---------------------------------------------------------------*/
    /* EDIT THE PANEL FIELD VALUES.                                  */
    /*---------------------------------------------------------------*/
    SET &FTPDSN = &STR()
    SET &FTPMEM = &STR()
    IF &STR(&OTHDSN) ^= &STR() THEN +
      DO
        SET &TMPMEM = &STR()
        SET &TMPDSN = &STR(&OTHDSN)
        IF &STR(') ^= &SUBSTR(1,&OTHDSN) THEN +
          DO
            ISPEXEC VGET (ZPREFIX)
            SET &TMPDSN = &STR('&ZPREFIX..&OTHDSN.')
            IF &STR(.) = &SUBSTR(2,&TMPDSN) THEN +
              DO
                SET &TMPDSN = &STR('&OTHDSN.')
              END
          END

        SET &BGNDSN = 2
        SET &ENDPOS = &STR(&LENGTH(&STR(&TMPDSN)))
        IF &STR(') = &SUBSTR(&ENDPOS,&TMPDSN) THEN +
            SET &ENDPOS = &EVAL(&ENDPOS - 1)

        IF  ')' ^= &STR('&SUBSTR(&ENDPOS,&TMPDSN)') THEN +
            SET &ENDDSN = &ENDPOS
        ELSE +
          DO
            SET &ENDMEM = &EVAL(&ENDPOS - 1)
            SET &STOP   = &STR(N)
            DO WHILE &STOP ^= &STR(Y)
               IF  &STR('&SUBSTR(&ENDPOS,&TMPDSN)') = '(' THEN +
                 DO
                    SET &STOP = &STR(Y)
                    SET &BGNMEM = &EVAL(&ENDPOS + 1)
                    SET &ENDDSN = &EVAL(&ENDPOS - 1)
                 END
               ELSE +
                    SET &ENDPOS   = &EVAL(&ENDPOS - 1)

               IF &ENDPOS  = &STR(0) THEN +
                 DO
                   SET &PNLMSG   = CISR004  /* INVALID DATASET NAME */
                   SET &PNLCUR   = ZCMD
                   GOTO DISP
                 END

            END                             /* END OF DO...WHILE    */
            SET &FTPMEM = &SUBSTR(&BGNMEM:&ENDMEM,&TMPDSN)

          END
        SET &FTPDSN = &SUBSTR(&BGNDSN:&ENDDSN,&TMPDSN)
        IF (&STR(&ISPFMB) NE &STR( ) THEN +
           DO
            SET &FTPMEM = &STR(&ISPFMB)
           END
      END
    ELSE +
      DO
        IF &PRJ0 ^= &STR() THEN +
          DO
            SET &FTPDSN = &STR(&PRJ0..&LIB0..&TYP0)
            SET &FTPMEM =  &STR(&ISPFMB)
          END
      END

   IF &STR(&FTPDSN) = &STR() THEN +
     DO
        SET &PNLMSG   = CISR007
        SET &PNLCUR   = ZCMD
        GOTO DISP
     END

   SET &TFTPDSN = &STR(&FTPDSN)

   IF (&STR(&FTPMEM) ^= &STR()) THEN +
     DO
       IF (&SYSINDEX(&STR(*),&STR(&FTPMEM)) = 0) THEN +
         SET &TFTPDSN = &STR(&FTPDSN.(&FTPMEM.))

         SET &SYSDSNRC = &SYSDSN(&STR('&TFTPDSN'))

         GOTO GODNSRC
     END

   SET &SYSDSNRC = &SYSDSN(&STR('&TFTPDSN'))
GODNSRC:+
   IF &STR(&SYSDSNRC) ^= &STR(OK) THEN +
     DO
        IF &STR(&SUBSTR(1:7,&STR(&SYSDSNRC))) = &STR(INVALID) THEN +
          DO
            SET &PNLMSG   = CISR012
            SET &PNLCUR   = ZCMD
            GOTO DISP
          END
        ELSE IF &STR(&SYSDSNRC) = &STR(DATASET NOT FOUND) THEN +
               DO
                 SET &PNLMSG   = CISR011
                 SET &PNLCUR   = ZCMD
                 GOTO DISP
               END
        ELSE DO
               GOTO CHKFTP
               SET &PNLMSG   = CISR013
               SET &PNLCUR   = ZCMD
               GOTO DISP
             END
     END

/*------------------------------------------------------------------*/
/* CHECK THE 'FOOTPRINT FILE' OPTION.  VALID VALUES ARE 'Y' AND 'N'.*/
/*------------------------------------------------------------------*/
CHKFTP:+
    IF ((&F ^= &STR(Y)) AND (&F ^= &STR(N))) THEN +
      DO
        SET &PNLMSG = CIIO048
        SET &PNLCUR = F
        GOTO DISP
      END

      IF ((&F = &STR(Y)) THEN +
        DO
           GOTO CHKMBR
          IF (&STR(&FTPMEM) ^= &STR()) THEN +
            DO
/*------------------------------------------------------------------*/
/* FOOTPRINT FILE = Y, BUT A MEMBER NAME HAS BEEN ENTERED. THIS IS  */
/* NOT ALLOWED BECAUSE THE FOOTPRINT FILE MUST BE A SEQUENTIAL      */
/* DATASET. ISSUE AN ERROR AND SET THE CURSOR TO THE "MEMBER" FIELD */
/* IN ERROR.                                                        */
/*------------------------------------------------------------------*/
              SET &PNLMSG   = CISR017
              IF &STR(&OTHDSN) ^= &STR() THEN +
                DO
                  SET &PNLCUR   = OTHDSN
                  GOTO DISP
                END
              ELSE +
                DO
                  SET &PNLCUR   = ISPFMB
                  GOTO DISP
                END
            END
          IF &STR(&EXCMEM) ^= &STR() THEN +
              DO
                SET &PNLMSG   = CISR017
                SET &PNLCUR   = EXCMEM
                GOTO DISP
              END
/*------------------------------------------------------------------*/
/* FOOTPRINT FILE = Y, AND NO MEMBER NAME HAS BEEN SPECIFIED. CHECK */
/* THE DSNAME TO SEE IF IT'S  A SEQUENTIAL DATASET.  APPEND A       */
/* BOGUS MEMBER NAME "CHKPDS". IF THE SYSDSN INSTRUCTION RETURNS    */
/* ERROR MESSAGE:                                                   */
/*      "MEMBER SPECIFIED, BUT DATASET IS NOT PARTITIONED"          */
/* THEN WE HAVE A SEQUENTIAL DATASET, AND PROCESSING CAN CONTINUE   */
/*------------------------------------------------------------------*/
CHKMBR:+
          SET &SYSDSNRC = &SYSDSN(&STR('&TFTPDSN')
/*        SET &SYSDSNRC = &SYSDSN(&STR('&TFTPDSN(CHKPDS)') */

          IF &STR(&SYSDSNRC) ^= &STR(OK) THEN +
            DO
     IF &STR(&SUBSTR(8:16,&STR(&SYSDSNRC))) ^= &STR(SPECIFIED) THEN +
              DO
                 GOTO DSNOK
/*------------------------------------------------------------------*/
/* SYSDSN (DSN(CHKPDS)) SAYS THE DSNAME IS NOT SEQUENTIAL.          */
/* ISSUE AN ERROR AND SET THE CURSOR TO THE FIELD IN ERROR          */
/*------------------------------------------------------------------*/
                SET &PNLMSG   = CISR018
                IF &STR(&OTHDSN) ^= &STR() THEN +
                  DO
                    SET &PNLCUR   = OTHDSN
                    GOTO DISP
                  END
                ELSE +
                  DO
                    SET &PNLCUR   = ISPFMB
                    GOTO DISP
                  END
              END
            END
        END

/* IF EDITS OK THEN SAVE VARIABLES                                  */
DSNOK:+
    ISPEXEC VPUT ( PRJ0 LIB0 TYP0 VAREVNME)  PROFILE

/* SET UP VALUES USED BY FILE TAILORING                             */
    SET &RPTCAT = &STR(FTP)
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

    SET &RPTNUM = RPT80
    IF &STR(&RPT80) ^= &STR( ) AND +
       &STR(&RPT80) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 80)

    SET &RPTNUM = RPT81
    IF &STR(&RPT81) ^= &STR( ) AND +
       &STR(&RPT81) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 81)

    SET &RPTNUM = RPT82
    IF &STR(&RPT82) ^= &STR( ) AND +
       &STR(&RPT82) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 82)

    SET &RPTNUM = RPT83
    IF &STR(&RPT83) ^= &STR( ) AND +
       &STR(&RPT83) ^= &STR(_) THEN SET &REPORT = &STR(&REPORT 83)

    ERROR OFF

/*------------------------------------------------------------------*/
/* VERIFY THAT THE ENVIRONMENT NAME HAS BEEN SPECIFIED FOR RPT83    */
/*------------------------------------------------------------------*/
   IF &RPT83 NE &STR( ) AND &RPT83 NE &STR(_) THEN +
      DO
        IF &STR(&VAREVNME) = &STR() THEN  +
           DO
              SET &PNLMSG   = CISR005
              SET &PNLCUR   = VAREVNME
              GOTO DISP
           END
      END

    IF &REPORT  = &STR() THEN DO
        SET &PNLMSG   = CISR003
        SET &PNLCUR   = ZCMD
        GOTO DISP
     END


    IF  &F = &STR(Y) THEN DO
         SET &FOODD  = &STR(FOOTFILE)
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
          WRITE AN I/O ERROR OCCURRED IN C1SR1400. RC=&RC
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

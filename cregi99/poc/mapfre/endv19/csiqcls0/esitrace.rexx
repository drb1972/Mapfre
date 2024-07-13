PROC 0 START STOP               /* OPTIONS TO START AND STOP TRACE */ +
       CONSOLE DATASET TERMINAL /* DESTINATION OF TRACE OUTPUT     */ +
       SHR MOD OLD NEW          /* DATA SET ALLOCATION OPTIONS     */ +
       CAT KEEP                 /* TRACE DATA SET DISPOSITION      */ +
       DSN(ESI.TRACE)           /* TRACE DATA SET NAME             */ +
       DEBUG
/**********************************************************************/
/*  NAME       : ESITRACE                                             */
/*  DESCRIPTION: EXTERNAL SECURITY TRACE ALLOCATION CLIST             */
/*  FUNCTION   : THIS CLIST ALLOCATES THE ESI TRACE DATA SET WHICH    */
/*               WILL ACTIVATE TRACE SERVICES.                        */
/*  PARAMETERS :                                                      */
/*     START   : DEFAULT. STARTS THE TRACE AND ALLOCATES THE TRACE    */
/*               DATA SET.                                            */
/*     STOP    : TERMINATES THE TRACE AND FREES THE DATA SET.         */
/*     CONSOLE : CAUSES THE TRACE DATA SET TO BE ALLOCATED TO DUMMY   */
/*               AND TRACE RECORDS ARE WRITTEN TO THE CONSOLE.        */
/*     DATASET : DEFAULT.  ALL TRACE RECORDS WILL BE WRITTEN          */
/*               WRITTEN TO THE SPECIFIED DATA SET.                   */
/*     TERMINAL: CAUSES TRACE RECORDS TO BE WRITTEN TO THE TERMINAL.  */
/*     SHR     : DEFAULT. ALLOCATES THE TRACE DATA SET SHARED.        */
/*     MOD     : CAUSES NEW TRACE RECORDS TO BE ADDED TO THE END OF   */
/*               THE DATA SET.                                        */
/*     OLD     : ALLOCATES THE EXISTING DATA SET EXCLUSIVELY.         */
/*     NEW     : ALLOCATES A NEW TRACE DATA SET.                      */
/*     CAT     : CATALOGS THE TRACE DATA SET WHEN THE DATA SET IS     */
/*               CLOSED.                                              */
/*     KEEP    : KEEPS THE TRACE DATA SET WHEN THE DATA SET IS        */
/*               CLOSED.  THE DATA SET IS NOT CATALOGED.              */
/*     DSN()   : NAME OF THE TRACE DATA SET.  NOT REQUIRED WHEN       */
/*               CONSOLE IS SPECIFIED.                                */
/**********************************************************************/
/* CORRECTION HISTORY:                                                */
/*                                                                    */
/* DATE: BY: FIX #:    DESCRIPTION                                    */
/* ===== === ========= ============================================== */
/* 07/98 PC  P0001594  CORRECT STOP MESSAGE IF-THEN-ELSE STRUCTURE    */
/* 12/95 RAD P0000207  CORRECT DATA SET ALLOCATION TO THE TERMINAL    */
/* 04/95 RAD P78726 CORRECT DATA SET ALLOCATION TO THE TERMINAL, DA(*)*/
/**********************************************************************/

     IF &DEBUG = DEBUG THEN +
         CONTROL MSG LIST SYMLIST CONLIST FLUSH
     ELSE +
         CONTROL MSG NOLIST NOSYMLIST NOCONLIST FLUSH

     SET DSSTAT  = &STR(SHR)
     SET DSDISP  = &STR(KEEP)
     SET DSALLOC = &STR(START)
     SET ESIDDNM = &STR(EN$TRESI)
     SET ESIDSNM = &STR(&DSN)
     SET DEST    = &STR(TERMINAL)

     IF &START EQ &STR(START) && +
         &STOP EQ &STR(STOP) THEN +
         DO
            WRITE MULTIPLE DATA SET ALLOCATION VALUES SPECIFED
GETSTAT: +
            WRITENR SPECIFY ONLY ONE (1) ALLOCATION VALUE (START,STOP)
            READ &DSALLOC
            IF &DSALLOC NE &STR(START) && +
                &DSALLOC NE &STR(STOP) THEN +
                DO
                    WRITE INVALID DATA SET ALLOCATION SPECIFIED
                    GOTO GETSTAT
                END
         END
     ELSE +
         DO
             IF &START EQ &STR(START) THEN +
                 SET &DSALLOC = &STR(&START)
             IF &STOP EQ &STR(STOP) THEN +
                 SET &DSALLOC = &STR(&STOP)
         END

/*********************************************************************/
/* FUNCTION IS STOP. FREE THE DATA SET.                              */
/*********************************************************************/
     IF &DSALLOC = &STR(STOP) THEN +
         DO
             CONTROL LIST
             FREE DD(&ESIDDNM)
             SET RC=&LASTCC
             CONTROL NOLIST
             IF &RC = 0 THEN +
               DO
                 WRITE
                 WRITE ESI TRACE IS TERMINATED
               END
             ELSE +
               DO
                 WRITE
                 WRITE ESI TRACE DATA SET IS NOT CLOSED.  YOU MUST
                 WRITE FIRST EXIT TO FREE THE DATA SET AND STOP THE
                 WRITE ESITRACE.
                 WRITE
                 WRITE ESI TRACE REMAINS ACTIVE
               END
             EXIT CODE(0)
         END

     IF &SHR EQ &STR(SHR) && +
         &MOD EQ &STR(MOD) && +
         &OLD EQ &STR(OLD) && +
         &NEW EQ &STR(NEW) THEN +
         DO
            WRITE MULTIPLE DATA SET STATUS VALUES SPECIFED
GETDSST: +
            WRITENR SPECIFY ONLY ONE (1) STATUS (SHR,MOD,OLD,NEW)
            READ &DSSTAT
            IF &DSSTAT NE &STR(SHR) && +
                &DSSTAT NE &STR(MOD) && +
                &DSSTAT NE &STR(OLD) && +
                &DSSTAT NE &STR(NEW) THEN +
                DO
                    WRITE INVALID DATA SET STATUS SPECIFIED
                    GOTO GETDSST
                END
         END
     ELSE +
         DO
             IF &SHR EQ &STR(SHR) THEN +
                 SET &DSSTAT = &STR(&SHR)
             IF &MOD EQ &STR(MOD) THEN +
                 SET &DSSTAT = &STR(&MOD)
             IF &OLD EQ &STR(OLD) THEN +
                 SET &DSSTAT = &STR(&OLD)
             IF &NEW EQ &STR(NEW) THEN +
                 SET &DSSTAT = &STR(&NEW)
         END

     IF &CAT EQ &STR(CAT) && +
        &KEEP EQ &STR(KEEP) THEN +
        DO
            WRITE MULTIPLE DATA SET DISPOSITION VALUES SPECIFED
GETDISP: +
            WRITENR SPECIFY ONLY ONE (1) DISPOSITION(CAT,KEEP)
            READ &DSDISP
            IF &DSDISP NE &STR(CAT) && +
               &DSDISP NE &STR(KEEP) THEN +
               DO
                   WRITE INVALID DATA SET DISPOSITION SPECIFIED
                   GOTO GETDISP
               END
        END
     ELSE +
         DO
             IF &CAT EQ &STR(CAT) THEN +
                 SET &DSDISP = &STR(&CAT)
             IF &KEEP EQ &STR(KEEP) THEN +
                 SET &DSDISP = &STR(&KEEP)
         END

     IF &CONSOLE EQ &STR(CONSOLE) && +
        &TERMINAL EQ &STR(TERMINAL) && +
        &DATASET EQ &STR(DATASET) THEN +
        DO
            WRITE MULTIPLE DATA SET DESTINATION VALUES SPECIFED
GETDEST: +
            WRITENR SPECIFY ONLY ONE (1) DESTINATION (CONSOLE,DATASET,TERMINAL)
            READ &DEST
            IF &DEST NE &STR(CONSOLE) && +
               &DEST NE &STR(TERMINAL) && +
               &DEST NE &STR(DATASET) THEN +
               DO
                   WRITE INVALID DATA SET DESTINATION SPECIFIED
                   GOTO GETDEST
               END
        END
     ELSE +
         DO
             IF &CONSOLE EQ &STR(CONSOLE) THEN +
                 SET &DEST = &STR(CONSOLE)
             IF &TERMINAL EQ &STR(TERMINAL) THEN +
                 SET &DEST = &STR(&TERMINAL)
             IF &DATASET EQ &STR(DATASET) THEN +
                 SET &DEST = &STR(&DATASET)
         END

     CONTROL LIST
     SET RC = 69
     IF &DEST EQ &STR(CONSOLE) THEN +
         DO
             ALLOC DD(&ESIDDNM) DUMMY &DSSTAT &DSDISP SPACE(1 1) +
             CYL LRECL(133) BLKSIZE(6118) RECFM(F B) UNIT(SYSDA) +
             DSORG(PS)
             SET RC = &LASTCC
             SET TRDEST = &STR(THE CONSOLE)
         END
     IF &DEST EQ &STR(DATASET) THEN +
         DO
             ALLOC DD(&ESIDDNM) DA(&ESIDSNM) &DSSTAT &DSDISP    +
             LRECL(133) BLKSIZE(6118) RECFM(F B) CYL SPACE(1 1) +
             UNIT(SYSDA) DSORG(PS)
             SET RC = &LASTCC
             SET TRDEST = &STR(THE DATA SET &ESIDSNM)
         END
     IF &DEST EQ &STR(TERMINAL) THEN +
         DO
             ALLOC DD(&ESIDDNM) DA(*) +
             LRECL(133) BLKSIZE(6118) RECFM(F B) DSORG(PS)
             SET RC = &LASTCC
             SET TRDEST = &STR(YOUR TERMINAL)
         END
     CONTROL NOLIST

     SET RC = &LASTCC
     IF (&RC = 0) THEN +
         DO
             WRITE
             WRITE ESI TRACE HAS BEEN STARTED TO &TRDEST
         END
     ELSE +
         DO
             WRITE UNABLE TO ALLOCATE DDNAME TO &TRDEST
             WRITE ALLOCATION RC = &RC
             EXIT CODE(&RC)
         END

     EXIT

PROC 3 ACTION C1STG C1SYS DEBUG                                         00010000
/*-------------------------------------------------------------------*\ ------*/
/* AUTHOR: CRAIG HILTON (ENDEVOR SUPPORT)                            *\       */
/* DATE:   18/11/98                                                  *\       */
/*                                                                   *\       */
/* THIS CLIST IS EXECUTED BY THE ENDEVOR PROCESSORS RELATED TO TYPE  *\       */
/* VANISH.                                                           *\       */
/*                                                                   *\       */
/* IT REQUIRES THE FOLLOWING 3 PARAMETERS:                           *\       */
/* ACTION:   GENERATE / MOVE                                         *\       */
/* C1STG:    ENDEVOR STAGE ID                                        *\       */
/* C1SYS:    ENDEVOR SYSTEM ID                                       *\       */
/*                                                                   *\       */
/* THE INPUT FILE "CARDS" IS PROCESSED AND THE RECORDS CONTAINED ARE *\       */
/* VALIDATED.  RECORDS WITH A "*" IN COLUMN ONE ARE NOT PROCESSED.   *\       */
/*                                                                   *\       */
/* ALL OTHER RECORDS MUST CONSIST OF A PDS(MEMBER) SPECIFICATION     *\       */
/* WHICH EXISTS.  THIS CAN BE WITH OR WITHOUT QUOTES.                *\       */
/*                                                                   *\       */
/* IF ACTION IS SET TO "MOVE" AND C1STG IS SET TO "P" THEN IDCAMS    *\       */
/* DELETE CARDS ARE PRODUCED TO DDNAME "DELCARDS".                   *\       */
/*                                                                   *\       */
/* IF ANY OF THE PDS SPECIFICATIONS CONTAIN A FINAL QUALIFIER OF     *\       */
/* "CICS", THEN "FILE(CICS)"   IS APPENDED TO THE IDCAMS STATEMENT   *\       */
/*                                                                   *\       */
/* THE FOLLOWING RETURN-CODES ARE ISSUED:                            *\       */
/*   0 - PROCESSED/VERIFIED OKAY.                                    *\       */
/*   1 - PROCESSED/VERIFIED OKAY.  INPUT FILE CONTAINS "CICS" LIBS.  *\       */
/*   2 - PROCESSED/VERIFIED OKAY.  INPUT FILE CONTAINS "LOAD" LIBS.  *\       */
/*   3 - PROCESSED/VERIFIED OKAY.  INPUT FILE CONTAINS "LOAD" AND... *\       */
/*                                                  ..."CICS" LIBS   *\       */
/*  12 - VALIDATION OR CLIST ERROR OCCURED.                          *\       */
/*-------------------------------------------------------------------*\ ------*/
                                                                          000103
   IF &DEBUG = DEBUG THEN CONTROL   CONLIST   LIST   SYMLIST   MSG         00010
   ELSE                   CONTROL NOCONLIST NOLIST NOSYMLIST NOMSG         00010
   CONTROL MAIN NOFLUSH

/* INITIALISE VARIABLES                                                 ------*/
                                                                        ------*/
   SET MODE    =
   SET SPACES  = &STR(                                             )
   SET SHRCICS = N
   SET SHRLOAD = N
   SET EOF     = N
   SET RC      = 0
   SET ACTN    =
   SET DSNCNT  = 0
   SET BOPEN   = &STR((
   SET BCLOSE  = )
   SET FCICS   = &STR(.CICS(
   SET FLOAD   = &STR(.LOAD(


/* IF MOVING TO STAGE P, THEN OUTPUT FILE IS REQUIRED                   ------*/

   IF &ACTION EQ MOVE AND &C1STG = P THEN DO
     SET MODE  = DELETE
     OPENFILE DELCARDS OUTPUT
   END


/* CATER FOR EOF ON INPUT FILE                                          ------*/
/* AND HANDLE OTHER ERRORS                                              ------*/

   ERROR DO
     SET RCODE = &LASTCC
     IF &ACTN EQ WHO THEN RETURN

     IF &RCODE EQ 400 THEN DO
       CLOSFILE ERROR
       SET EOF = Y
       RETURN
     END
     ELSE DO
       ERROR OFF
       WRITE SERIOUS ERROR &RCODE
       SET RC  = 12
       GOTO F
     END
   END


/* OPEN FILES, READ FIRST RECORD.                                       ------*/

   OPENFILE CARDS INPUT
   OPENFILE ERROR OUTPUT

   GETFILE CARDS


/* MAIN LOOP: PROCESS ONE INPUT RECORD                                  ------*/

L: DO UNTIL &EOF EQ Y


/* GET DSNCNT UP TO 3 CHARACTERS.                                       ------*/

     SET DSNCNT = &DSNCNT + 1

     IF &DSNCNT LT +10       THEN SET DSNCNT = &STR(00&DSNCNT)
     ELSE IF &DSNCNT LT +100 THEN SET DSNCNT = &STR(0&DSNCNT)

/* COMMENT?                                                             ------*/

     IF &SUBSTR(1,&STR(&CARDS)) EQ &STR(*) THEN GOTO N


/* REMOVE ANY LEADING OR TRAILING SPACES

     SET ERR    =
     SET DSN    = &CARDS
     SET CNT    = 1

     DO WHILE &CNT LT 80 AND +
              &SUBSTR(&CNT,&STR(&DSN)) EQ &STR( )
       SET CNT = &CNT + 1
     END

     SET DSN    = &SUBSTR(&CNT:80,&STR(&DSN))
     SET LEN    = &LENGTH(&STR(&DSN))
     SET DSN    = &SUBSTR(1:&LEN,&STR(&DSN))


/* REMOVE QUOTES                                                        ------*/

     IF &STR(&SUBSTR(&LEN,&STR(&DSN))) EQ ' THEN DO
       SET DSN = &SUBSTR(1:&LEN-1,&STR(&DSN))
       SET LEN = &LEN - 1
     END

     IF &STR(&SUBSTR(1,&DSN))        EQ ' THEN DO
       SET DSN = &SUBSTR(2:&LEN,&STR(&DSN))
       SET LEN = &LEN - 1
     END


/* IF A FULL-STOP IS FOUND, THEN A DATASET NAME IS SPECIFIED,
/* SO EXTRACT IT FROM THE INPUT RECORD.  THE END OF THE DSN WILL
/* BE FOLLOWED BY A SPACE OR AN OPEN-BRACKET CHARACTER.

     IF &SYSINDEX(&STR(.),&STR(&DSN)) NE 0 THEN DO

       SET CNT = &SYSINDEX(&STR(&BOPEN),&STR(&DSN))

       IF &CNT EQ 0 THEN +
         SET CNT = &SYSINDEX(&STR( ),&STR(&DSN))

       IF &CNT EQ 0 THEN +
         SET ERR = MEMBER NAME NOT FOUND
       ELSE DO
         SET PDS = &SUBSTR(1:&CNT-1,&STR(&DSN))
         SET PDS = &PDS
         SET DSN = &SUBSTR(&CNT+1:&LEN,&STR(&DSN))
       END
     END
     ELSE DO
       IF &LASTPDS EQ  THEN SET &ERR = NO DSN SPECIFIED
       ELSE                 SET PDS = &LASTPDS
     END

     IF &ERR GT  THEN GOTO E



/* REMOVE CLOSING BRACKET (IF FOUND).                                   ------*/

     SET CNT   = &SYSINDEX(&STR(&BCLOSE),&STR(&DSN))
     IF &CNT GT  0 THEN +
       SET DSN = &STR(&SUBSTR(1:&CNT-1,&STR(&DSN)))


/* PROCESS THE MEMBER NAME. REMOVE LEADING SPACES:                      ------*/

     SET MEM    = &DSN
     SET CNT    = 1
     SET LEN    = &LENGTH(&MEM)

     DO WHILE &CNT LT &LEN AND +
              &SUBSTR(&CNT,&STR(&MEM)) EQ &STR( )
       SET CNT = &CNT + 1
     END

     SET MEM    = &SUBSTR(&CNT:&LEN,&STR(&MEM))


/* VALIDATIONS                                                          ------*/

     IF &C1SYS NE EV AND &SUBSTR(7:8,&STR(&PDS)) NE &C1SYS  THEN +
       SET ERR = DSN IS NOT OWNED BY SYSTEM &C1SYS

     IF &SUBSTR(1:6,&STR(&PDS))      NE PREV.P  THEN +
       SET ERR = DSN MUST BEGIN "PREV.P"

     IF &ERR NE  THEN GOTO E


/* CHECK THAT DSN/MEMBER EXISTS:                                        ------*/

     SET ERR  = &SYSDSN('&PDS(&MEM)')
     IF &ERR NE OK THEN GOTO E
     SET ERR  =


/*   MOVING TO STAGE P, SO BUILD THE IDCAMS DELETE CARDS   *\           ------*/
/*   AND CHECK THAT THE DATASET IS CURRENTLY AVAILABLE     *\           ------*/
/*

     IF &MODE EQ DELETE THEN DO

       SET DELCARDS = &STR(   DEL '&PDS(&MEM)')

       SET SHRDISP =

/* FOR CICS DATASETS ADD "FILE" CLAUSE AND SET RC TO 4.

       IF &SYSINDEX(&STR(&FCICS),&STR(&DELCARDS)) NE 0 THEN DO
         SET DELCARDS = &STR(&DELCARDS    FILE(CICS))
         SET SHRDISP  = Y
         SET SHRCICS  = Y
       END

/* FOR LOAD DATASETS ADD "FILE" CLAUSE AND SET RC TO 4.

       IF &SYSINDEX(&STR(&FLOAD),&STR(&DELCARDS)) NE 0 THEN DO
         SET DELCARDS = &STR(&DELCARDS    FILE(LOAD))
         SET SHRDISP  = Y
         SET SHRLOAD  = Y
       END


/* NON-CICS/LOAD DSN, SO CHECK THAT IT ISNT CURRENTLY ALLOCATED

       IF &SHRDISP EQ  THEN DO
         SET ACTN = WHO
         TSOEXEC W '&PDS'
         SET ACTN =
         IF &SYSCMDRC NE 0 THEN SET ERR = DATASET IN USE
       END

       PUTFILE DELCARDS
     END


/* DID AN ERROR OCCUR?                                                  ------*/

E:   IF &ERR NE  THEN DO
       SET ERROR = &STR(#&DSNCNT: &PDS(&MEM))
       SET LEN   = &LENGTH(&STR(&ERROR))

       IF &LEN GT 34 THEN SET FILLER =
       ELSE               SET FILLER = &SUBSTR(1:35-&LEN,&SPACES)

       SET ERROR = &STR(&ERROR &FILLER &ERR)
       SET RC    = 12
       PUTFILE ERROR
     END


N:   GETFILE CARDS
     SET LASTPDS = &PDS
   END                                                                  00149016
                                                                        00149016
/* IF WE ADDED "FILE" STATEMENTS, WORK OUT FINAL RC VALUE.

   IF &SHRCICS EQ Y THEN SET RC = &RC + 1
   IF &SHRLOAD EQ Y THEN SET RC = &RC + 2

F: IF MODE EQ DELETE THEN CLOSEFILE DELCARDS

   EXIT CODE(&RC)                                                       90016

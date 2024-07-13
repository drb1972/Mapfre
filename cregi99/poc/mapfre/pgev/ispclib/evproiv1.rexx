PROC 0 DEBUG
/*********************************************************************/
/* PROCEDURE EVPROIV1                                                */
/* ALLOW USER TO LOAD PRO-IV ELEMENTS INTO ENDEVOR.                  */
/* BUILT FOR THE "MT" APPLICATION (THE ONLY PRO-IV USERS AT PRESENT) */
/*                                                                   */
/* THIS PANEL OPENS ISPF TABLE EVPROIV AND DISPLAYS ALL RECORDS      */
/* USING PANEL EVPROIV1.                                             */
/*                                                                   */
/* THE USER ALSO SPECIFIES                                           */
/*     1) INPUT PARARMETER FILE (BUILT BY USER)                      */
/*     2) CCID                                                       */
/*     3) COMMENT                                                    */
/*     3) BOOTS MEMBER                                               */
/*     3) PARM MEMBER                                                */
/*                                                                   */
/* ONCE THIS INFORMATION IS ENTERED, ENDEVOR WILL CREATE "ADD" AND   */
/* "MOVE" SCL FOR ALL ELEMENTS SPECIFIED IN THE PARAMETER FILE.      */
/*                                                                   */
/* AMENDMENT HISTORY                                                 */
/* WHEN     WHO           WHY                                        */
/* 15/06/99 CRAIG HILTON  ORIGINAL VERSION                           */
/*                                                                   */
/*********************************************************************/
 IF &DEBUG = DEBUG THEN CONTROL SYMLIST CONLIST LIST PROMPT
 ELSE                   CONTROL NOSYMLIST NOCONLIST NOLIST NOPROMPT

/* ISPEXEC CONTROL ERRORS RETURN  /* I WILL HANDLE RC'S FROM ISPF */

 ISPEXEC LIBDEF USRTABL DATASET ID('PGEV.BASE.ISPTLIB')

 ISPEXEC VGET (ZUSER ZPREFIX) SHARED
 ISPEXEC VGET (C4COMM C4CCID C4PARMS) PROFILE

 ISPEXEC TBOPEN PROIV NOWRITE LIBRARY(USRTABL)

 SET MSG =                   /* ISPF MESSSAGE ID FOR TBDISPL     */
 SET CSR =                   /* ISPF CURSUR POSITION FOR TBDISPL */
 SET RC  = 0                 /* TO STORE LAST RETURN CODE        */
 SET C4CMRTYP = STANDARD     /* STANDARD/EMERGENCY CHANGE        */

 SET &SKELNM = &ZUSER..PROIV.JCL
 IF &SYSDSN(&SKELNM) NE OK THEN +
    ALLOC DS(&SKELNM) NEW CATALOG TRACKS DSORG(PS) +
    SPACE(1,10) LRECL(80) RECFM(F B)

 ISPEXEC LIBDEF ISPFILU DATASET ID(&SKELNM)
 ISPEXEC LIBDEF ISPFILE DATASET ID(&SKELNM)

/*************************************/
/*      DISPLAY THE MAIN PANEL       */
/*************************************/
 DISPLAY: +
 ISPEXEC TBDISPL PROIV PANEL(EVPROIV1) MSG(&MSG) CURSOR(&CSR)
 SET RC = &LASTCC

 SET MSG =
 SET CSR =

 IF &RC EQ 8 THEN GOTO FINISH                            /* PF3? */


/**************************************/
/* VERIFY CMR TYPE                    */
/* MUST BE "STANDARD" OR "EMERGENCY"  */
/**************************************/

 IF &C4CMRTYP NE STANDARD AND +
    &C4CMRTYP NE EMERGENCY THEN DO
    SET MSG = EVPR009E
    SET CSR = C4CMRTYP
    GOTO DISPLAY
 END


/***************/
/* VERIFY CCID */
/************************************/
/* 1. CMR# (WITH OR WITHOUT SUFFIX) */
/* 2. "NDVR#SUPPORT"                */
/* 3. PREFIX OF USERID              */
/************************************/

 IF &C4CCID EQ  THEN GOTO CCIDBAD

 SET LEN = &LENGTH(&STR(&C4CCID))

 IF &SUBSTR(1:1,&C4CCID) EQ C  AND +
    &LEN                 GE 8  AND +
    &LEN                 LE 11 AND +
    &DATATYPE(&SUBSTR(2:&LEN,&C4CCID)) EQ NUM THEN GOTO CCIDOK

 IF &C4CCID EQ NDVR#SUPPORT THEN GOTO CCIDOK

 IF &LEN GE &LENGTH(&ZUSER) THEN DO
    IF &SUBSTR(1:&LENGTH(&ZUSER),&C4CCID) EQ &ZUSER THEN GOTO CCIDOK
 END

CCIDBAD: +
 SET MSG = EVPR004E      /*"PLEASE ENTER VALID CCID"*/
 SET CSR = C4CCID
 GOTO DISPLAY

CCIDOK: +
 IF &LEN GT 8 THEN SET &C5CCID EQ &SUBSTR(1:8,&C4CCID)
 ELSE              SET &C5CCID EQ &C4CCID

/********************/
/* ADD QUOTES AND   */
/* VERIFY PARMS DSN */
/********************/

 IF &LENGTH(&C4PARMS) LT 6 THEN DO
    SET MSG = EVPR005E
    SET CSR = C4PARMS
    GOTO DISPLAY
 END

 SET &C5PARMS = &STR(&C4PARMS)

 SET LEN = &LENGTH(&STR(&C5PARMS))

 IF &STR(&SUBSTR(&LEN,&STR(&C5PARMS))) EQ &STR(') THEN DO
    SET C5PARMS = &STR(&SUBSTR(1:&LEN-1,&STR(&C5PARMS)))
    SET LEN     = &LEN - 1
 END

 IF &STR(&SUBSTR(1:1,&STR(&C5PARMS))) EQ &STR(') THEN DO
    SET C5PARMS = &STR(&SUBSTR(2:&LEN,&STR(&C5PARMS)))
 END
 ELSE DO
    SET C5PARMS = &STR(&ZPREFIX..&C5PARMS)
 END

 IF &SYSDSN('&C5PARMS') NE OK THEN DO
    SET MSG = EVPR005E
    SET CSR = C4PARMS
    GOTO DISPLAY
 END

/***************************/
/* CHECK COMMENT NOT BLANK */
/* AND REMOVE ANY QUOTES   */
/***************************/

 SET LEN = &LENGTH(&STR(&C4COMM))

 IF &LEN LE 2 THEN DO
    SET MSG = EVPR006E
    SET CSR = C4COMM
    GOTO DISPLAY
 END

 IF &STR(&SUBSTR(1:1,&STR(&C4COMM))) EQ &STR(') OR +
    &STR(&SUBSTR(1:1,&STR(&C4COMM))) EQ &STR(") THEN DO
    SET C4COMM = &SUBSTR(2:&LEN,&STR(&C4COMM))
    SET LEN = &LEN - 1
 END

 IF &STR(&LENGTH(&STR(&C4COMM)),&STR(C4COMM)) EQ &STR(") OR +
    &STR(&LENGTH(&STR(&C4COMM)),&STR(C4COMM)) EQ &STR(') THEN DO
    SET C4COMM = &SUBSTR(1:&LEN-1,&STR(&C4COMM))
 END

/************************************/
/* CHECK BOOTS MEMBER NOT BLANK     */
/************************************/

 IF &C4BOOTS EQ  THEN DO
    SET MSG = EVPR008E
    SET CSR = C4BOOTS
    GOTO DISPLAY
 END

/*************************************************************/
/* IF MORE THAN ONE ROW SELECTED, THEN CLEAR OUT SELECTIONS, */
/* AND ISSUE ERROR ("PLEASE DON'T DO THAT AGAIN").           */
/*************************************************************/

 IF &ZTDSELS GT 1 THEN DO
    DO WHILE &ZTDSELS GT 1
       SET C4SEL =
       ISPEXEC TBDISPL PROIV POSITION(CRP)  /* GET NEXT SELECTION*/
    END
    SET C4SEL =
    SET MSG   = EVPR001E                   /* SET ERROR MESSAGE */
    GOTO DISPLAY
 END

/******************************************************/
/* IF ONLY ONE SELECTION MADE, CHECK USER HAS ENTERED */
/* AN "S" AGAINST THE ROW, AND SUBMIT JOB.            */
/******************************************************/

 IF &ZTDSELS EQ 1 THEN DO
    IF &C4SEL EQ S THEN DO                     /* VALID SELECTION */
       SET C4DSN    =  &STR(&DSN)
       SET C4CICS   =  &STR(&CICS)
       SET MSG      =  EVPR003I

                    /****   ALWAYS SUBSYS 1 FOR EMER CHANGES  *****/

       IF &C4CMRTYP EQ STANDARD THEN SET C4SUBSYS =  &STR(&SUBSYS)
       ELSE SET C4SUBSYS = &STR(&SUBSTR(1:2,&SUBSYS)1)
    END
    ELSE DO                                        /* NOT AN "S" */
       SET C4SEL =
       SET MSG   = EVPR002E                 /* SET ERROR MESSAGE */
       GOTO DISPLAY
    END
    SET C4SEL =                              /* CLEAR SELECTION */
 END
 ELSE DO
    SET MSG = EVPR007I
    GOTO DISPLAY
 END

/****************************************************************
/****   ALL VALIDATION IS NOW PERFORMED  - BUILD PRO-IV JCL  ****
/****************************************************************

/****   START FILE TAILORING    *****/

 ISPEXEC FTOPEN
 SET &FTCC = &LASTCC
 IF &FTCC NE 0 THEN DO
    SET &CSR = ZCMD
    SET &MSG = EVXP004
    GOTO DISPLAY
 END

/*****  INCLUDE THE JOB  *****/

 ISPEXEC FTINCL EVPROIV1
 SET &FTCC = &LASTCC
 IF &FTCC NE 0 THEN DO
    ISPEXEC FTCLOSE
    SET &CSR = ZCMD
    SET &MSG = EVXP004
    GOTO DISPLAY
 END

/*** CLOSE FILE TAILORING ****/

 ISPEXEC FTCLOSE

/*** SUBMIT THE JCL: ***/

 CONTROL MSG
 SUB (&SKELNM)
 CONTROL NOMSG
 SET &ZCMD   =

/*****  POSITION CSR, SET MSG, AND DISPLAY PANEL ******/

 SET &CSR = ZCMD
 SET &MSG = EVXP005

 GOTO DISPLAY

 FINISH: +
 ISPEXEC TBEND PROIV
 ISPEXEC LIBDEF USRTABL
 ISPEXEC LIBDEF ISPFILU
 ISPEXEC LIBDEF ISPFILE
 ISPEXEC VPUT (C4COMM C4CCID C4PARMS) PROFILE
 EXIT CODE(0)

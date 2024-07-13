PROC 0 OPT(2) APPL(CTLI) DF() LL() UP() SP() PP() +
       DEBUG(NOBUG) RESET NOSITE NOUSER +
       I@PRFX(IPRFX) I@QUAL(IQUAL) RXLIB()

/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.                */
/*                                                                   */
/* FUNCTION: THIS CLIST ALLOWS THE USER TO INVOKE QUICK EDIT         */
/*  (THE PRODUCT) FROM WITHIN AN ISPF SESSION WITHOUT                */
/*  ALLOCATING THE PRODUCT LIBRARIES TO THE STANDARD ISPF LIBRARY    */
/*  DEFINITIONS.  THIS CLIST CALLS A SHARED REXX ROUTINE (ENDEVORS)  */
/*  TO PERFORM ALL LIBRARY ALLOCATIONS, LIBDEFS FOR PANELS(ISPPLIB)  */
/*  SKELETONS(ISPSLIB), MESSAGES(ISPMLIB) LOADMODULES(ISPLLIB),      */
/*  AND TABLES(ISPTLIB).  THE EXEC ALSO ESTABLISHES AN ALTERNATE     */
/*  CLIST LIBRARY THROUGH THE TSO/E ALTLIB SERVICE.                  */
/*                                                                   */
/*  THIS CLIST ESTABLISHES A DEFAULT FEATURE TO LAUNCH (OPT()) AND   */
/*  PASSES THE PRODUCT PREFIX FROM I@PRFX/I@QUAL, OR PP(), WHICH     */
/*  SHOULD BE TAILORED USING JOB BC1JJB03.                           */
/*                                                                   */
/*  OTHER PARAMETERS ARE OPTIONAL, INCLUDING:                        */
/*  PP() - SPECIFIES A PRODUCT PREFIX ALTERNATIVE TO I@PRFX/I@QUAL   */
/*  UP() - SPECIFIES A USER PREFIX TO ALLOCATE FIRST                 */
/*  SP() - SPECIFIES A SITE PREFIX, IF NEEDED TO CONTAIN ANY         */
/*         SITE SPECIFIC CUSTOMISATIONS/OVERRIDES                    */
/*  LL() - SPECIFIES LIST OF LPARS (SYSIDS) WHERE ENDEVOR IS         */
/*         EXPECTED TO BE FOUND IN LINKLIST/LPA OR STEPLIB           */
/*  DF(XX) CAN BE USED WITH THE DEFAULT ENUXSITE EXIT TO SPECIFY     */
/*         AN ALTERNATE C1DEFLTS SUFFIX                              */
/*  APPL(XXXX) CAN BE USED TO SELECT A DIFFERENT ISPF APPLICATION    */
/*         ID SO THAT DIFFERENT SETS OF PROFILE VARIABLES CAN BE     */
/*         SELECTED                                                  */
/*  RXLIB() CAN BE USED TO OVERRIDE THE LOCATION OF THE ENDEVORS     */
/*         ROUTINE.  IF NOT SPECIFIED IT DEFAULTS TO THE PRODUCT     */
/*         PREFIX .CSIQCLS0                                          */
/*  RESET  BY DEFAULT THESE ROUTINES WILL CACHE DISCOVERY RESULTS IN */
/*         THE USER'S PROFILE TO SPEED UP RE-ENTRY WHEN THE SAME     */
/*         LIBRARIES ARE USED REPEATEDLY.  USE THE RESET OPTION TO   */
/*         FORCE A RE-DISCOVERY TO "FIND" NEW OR RENAMED DATASETS.   */
/*                                                                   */
/*  NOSITE THE ENDEVORS REXX MAY BE TAILORED TO SPECIFY A DEFAULT    */
/*  NOUSER USER OR SITE PREFIX - USE THE NOSITE OR NOUSER TO DISABLE */
/*         THESE LIBRARIES TEMPORARILY.                              */
/*                                                                   */
/*    NOTE: THE AUTHORIZED PRODUCT MODULES MUST BE PLACED EITHER IN  */
/*          LPA, LINKLST OR STEPLIB LIBRARIES, THE ISPF ISPLLIB DD   */
/*          STATEMENT CAN NOT BE USED FOR THIS PURPOSE.              */
/*          TSOLIB/TASKLIB CAN BE USED IF PFT SO12864 IS APPLIED.    */
/*                                                                   */
/*-------------------------------------------------------------------*/
CONTROL NOLIST NOMSG NOFLUSH
SET &OPTIONS = &STR()

/* ESTABLISH THE PRODUCT PREFIX AND RXLIB IF NOT PROVIDED            */
IF ('&STR(&PP)' EQ '&STR()') THEN +
  SET &PP = &STR(&I@PRFX).&STR(&I@QUAL)
IF ('&STR(&RXLIB)' EQ '&STR()') THEN +
  SET &RXLIB = &STR(&PP).&STR(CSIQCLS0)
/* BUILD THE EXEC COMMAND USING THE RXLIB PARM                       */
SET &EXECCMD = &STR(EXEC '&STR(&RXLIB)(ENDEVORS)')

/* NOW BUILD THE PARM STRING WITH THE OPTIONAL PARAMETERS            */
IF ('&STR(&DF)' NE '&STR()') THEN +
  SET &OPTIONS = &STR(&OPTIONS) DF(&STR(&DF))
IF ('&STR(&UP)' NE '&STR()') THEN +
  SET &OPTIONS = &STR(&OPTIONS) UP(&STR(&UP))
IF ('&STR(&SP)' NE '&STR()') THEN +
  SET &OPTIONS = &STR(&OPTIONS) SP(&STR(&SP))
IF ('&STR(&LL)' NE '&STR()') THEN +
  SET &OPTIONS = &STR(&OPTIONS) LL(&STR(&LL))
/* APPEND THE SIMPLE KEYWORDS */
SET &OPTIONS = &STR(&OPTIONS) &STR(&RESET) &STR(&NOSITE) &STR(&NOUSER)

/*-------------------------------------------------------------------*/
/* CHECK ENVIRONMENT AND INVOKE APPLICATION USING SELECT OR EXEC     */
/*-------------------------------------------------------------------*/
IF (&STR(&SYSISPF) EQ &STR(ACTIVE)) THEN +
  DO
    /*---------------------------------------------------------------*/
    /* INVOKE SITE ISPF ALLOCATION ROUTINE (ENDEVORS)                */
    /*---------------------------------------------------------------*/
    ISPEXEC SELECT CMD(&STR(&EXECCMD) +
       'OPT(&STR(&OPT)) PP(&STR(&PP)) +
        APPL(&STR(&APPL)) DEBUG(&STR(&DEBUG)) &STR(&OPTIONS)' +
        ) NEWAPPL(&STR(&APPL)) MODE(FSCR)
  END
ELSE +
  DO
    /*---------------------------------------------------------------*/
    /* INVOKE SITE ISPF ALLOCATION ROUTINE                           */
    /*---------------------------------------------------------------*/
    WRITE &STR(*------------------------------------------------*)
    WRITE &STR(* RUNNING FROM TSO/E - ENDEVOR WITH TASKLIB      *)
    WRITE &STR(* LIBRARIES MUST BE APF AUTHORIZED.              *)
    WRITE &STR(*------------------------------------------------*)
    &STR(&EXECCMD) +
       'OPT(&STR(&OPT)) PP(&STR(&PP)) +
        APPL(&STR(&APPL)) DEBUG(&STR(&DEBUG)) &STR(&OPTIONS)'
  END
/*-------------------------------------------------------------------*/
/* TERMINATE WITH A RETURN CODE ZERO.                                */
/*-------------------------------------------------------------------*/
EXIT CODE(0)

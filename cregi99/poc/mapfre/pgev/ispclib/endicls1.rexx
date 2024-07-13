PROC 0 DEBUG(NO)
/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2010 CA. ALL RIGHTS RESERVED.                 */
/*                                                                   */
/* NAME: ENDICLS1                                                    */
/*                                                                   */
/* FUNCTION: THIS CLIST ALLOWS THE USER TO INVOKE THE QUICK-EDIT     */
/*  DIALOG WITHOUT ALLOCATION THE PRODUCT LIBRARIES TO THE STANDARD  */
/*  ISPF LIBRARY DEFINITIONS.  THE CLIST USES THE ISPF LIBDEF        */
/*  SERVICE TO ALLOCATE ALTERNATE PANEL, MESSAGE AND SKELETION JCL   */
/*  DATA SETS.                                                       */
/*  THE CLIST WILL ALSO ESTABLISH AN ALTERNATE CLIST LIBRARY THROUGH */
/*  THE TSO/E ALTLIB SERVICE.  THE ALTLIB SERVICE IS AVAILABLE ONLY  */
/*  WITH TSO/E VERSION 2 OR GREATER.  IF YOU ARE NOT RUNNING WITH    */
/*  TSO/E VERSION 2 THEN THE TWO ALTLIB COMMANDS MUST BE REMOVED OR  */
/*  COMMENTED.                                                       */
/*                                                                   */
/*   NOTE: ALL DATASET NAMES WILL HAVE TO BE CUSTOMIZED TO YOUR SITE */
/*  SPECIFICATIONS.                                                  */
/*                                                                   */
/*-------------------------------------------------------------------*/
CONTROL NOLIST NOMSG NOFLUSH
IF (&STR(&DEBUG) EQ YES) THEN +
  CONTROL LIST MSG NOFLUSH

/*-------------------------------------------------------------------*/
/* VERIFY THAT ISPF IS ACTIVE.  IF ISPF IS NOT ACTIVE, WRITE AN ERROR*/
/* MESSAGE AND TERMINATE THE CLIST.                                  */
/*-------------------------------------------------------------------*/
IF (&STR(&SYSISPF) NE &STR(ACTIVE)) THEN +
  DO
    WRITE &STR(*------------------------------------------------*)
    WRITE &STR(* THIS CLIST IS AVAILABLE ONLY IF ISPF IS ACTIVE *)
    WRITE &STR(*------------------------------------------------*)
    EXIT CODE(16)
  END

/*-------------------------------------------------------------------*/
/* ALLOCATE AN ALTERNATE CLIST LIBRARY.  IF YOU ARE NOT RUNNING UNDER*/
/* AT LEAST TSO/E VERSION 2 THEN YOU MUST REMOVE THE FOLLOWING       */
/* STATEMENT AND YOU WILL HAVE TO EITHER ADD THE ISRCLIB TO THE      */
/* SYSPROC LIBRARY OR COPY THE CONTENTS OF THE ISRCLIB INTO A DATASET*/
/* THAT IS PART OF THE SYSPROC CONCATENATION .                       */
/*-------------------------------------------------------------------*/
ALTLIB ACTIVATE APPLICATION(CLIST)    -
                           DATASET('PGEV.BASE.ISPCLIB' +
                                   'SYSNDVR.CAI.ISRCLIB')

/*-------------------------------------------------------------------*/
/* ALLOCATE THE CONLIB DATASET IF REQUIRED. USED GENERALLY FOR       */
/* TESTING AS NORMALLY PICKED UP FROM THE LINKLIST.                  */
/*-------------------------------------------------------------------*/
IF &CONLIB = &STR(YES) THEN DO
    FREE FI(CONLIB)
    ALLOC FI(CONLIB) DA('SYSNDVR.CAI.CONLIB') SHR
END

/*-------------------------------------------------------------------*/
/* USE THE ISPF LIBDEF SERVICE TO DEFINE ALTERNATE PANEL, MESSAGE    */
/* AND SKELETON LIBRARIES.                                           */
/*-------------------------------------------------------------------*/
ISPEXEC LIBDEF ISPPLIB DATASET ID ('PGEV.BASE.ISPPLIB' +
                                   'SYSNDVR.CAI.ISPPLIB')

ISPEXEC LIBDEF ISPMLIB DATASET ID ('PGEV.BASE.ISPMLIB' +
                                   'SYSNDVR.CAI.ISPMLIB')

ISPEXEC LIBDEF ISPSLIB DATASET ID ('PGEV.BASE.ISPSLIB' +
                                   'SYSNDVR.CAI.ISPSLIB')

ISPEXEC LIBDEF ISPTLIB DATASET ID ('PGEV.BASE.ISPTLIB')

/*-------------------------------------------------------------------*/
/* ALLOCATE THE API PRINT DD-NAME.                                   */
/*-------------------------------------------------------------------*/
FREE  F(APIPRINT)
ALLOC F(APIPRINT) DUMMY

/*-------------------------------------------------------------------*/
/* INVOKE THE QUICK-EDIT DIALOG.                                     */
/*-------------------------------------------------------------------*/
ISPEXEC SELECT CMD(ENDEVUP)  NOCHECK NEWAPPL(CTLI) PASSLIB
IF &LASTCC LE 4 THEN DO
   ISPEXEC SELECT PGM(ENDIE000) NOCHECK NEWAPPL(CTLI) PASSLIB
END

/*-------------------------------------------------------------------*/
/* FREE THE ISPF LIBDEF DEFINITIONS AND THE API DD-NAME.             */
/*-------------------------------------------------------------------*/
ISPEXEC LIBDEF ISPPLIB
ISPEXEC LIBDEF ISPMLIB
ISPEXEC LIBDEF ISPSLIB
ISPEXEC LIBDEF ISPTLIB
FREE F(APIPRINT)

/*-------------------------------------------------------------------*/
/* DEACTIVATE THE ALTERNATE CLIST LIBRARY.  THIS STATEMENT MUST BE   */
/* REMOVED IF YOU ARE RUNNING WITH A VERSION OF TSO THAT IS LESS THAN*/
/* TSO/E VERSION 2.                                                  */
/*-------------------------------------------------------------------*/
ALTLIB DEACTIVATE APPLICATION(CLIST)

/*-------------------------------------------------------------------*/
/* FREE THE CONLIB ALLOCATION.                                       */
/*-------------------------------------------------------------------*/
IF &CONLIB = &STR(YES) THEN DO
    FREE F(CONLIB)
END

/*-------------------------------------------------------------------*/
/* TERMINATE WITH A RETURN CODE ZERO.                                */
/*-------------------------------------------------------------------*/
EXIT CODE(0)

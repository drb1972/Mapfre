PROC 0 DEBUG(NO)
/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                 */
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
       DATASET('TSOXX4.ENDEVOR.V16.CSIQCLS0')

/*-------------------------------------------------------------------*/
/* ALLOCATE THE CONLIB DATASET.                                      */
/*-------------------------------------------------------------------*/
FREE FI(CONLIB)
ALLOC FI(CONLIB) DA('TSOXX4.ENDEVOR.V16.CSIQLOAD') SHR

/*-------------------------------------------------------------------*/
/* USE THE ISPF LIBDEF SERVICE TO DEFINE ALTERNATE PANEL, MESSAGE    */
/* AND SKELETON LIBRARIES.                                           */
/*-------------------------------------------------------------------*/
ISPEXEC LIBDEF ISPPLIB DATASET ID('TSOXX4.ENDEVOR.V16.CSIQPENU')
ISPEXEC LIBDEF ISPMLIB DATASET ID('TSOXX4.ENDEVOR.V16.CSIQMENU')
ISPEXEC LIBDEF ISPSLIB DATASET ID('TSOXX4.ENDEVOR.V16.CSIQSENU')
ISPEXEC LIBDEF ISPTLIB DATASET ID('TSOXX4.ENDEVOR.V16.CSIQTENU')

/*-------------------------------------------------------------------*/
/* INVOKE THE QUICK-EDITT DIALOG.                                    */
/*-------------------------------------------------------------------*/
ISPEXEC SELECT PGM(ENDIE000) NOCHECK NEWAPPL(CTLI) PASSLIB

/*-------------------------------------------------------------------*/
/* FREE THE ISPF LIBDEF DEFINITIONS.                                 */
/*-------------------------------------------------------------------*/
ISPEXEC LIBDEF ISPPLIB
ISPEXEC LIBDEF ISPMLIB
ISPEXEC LIBDEF ISPSLIB
ISPEXEC LIBDEF ISPTLIB

/*-------------------------------------------------------------------*/
/* DEACTIVATE THE ALTERNATE CLIST LIBRARY.  THIS STATEMENT MUST BE   */
/* REMOVED IF YOU ARE RUNNING WITH A VERSION OF TSO THAT IS LESS THAN*/
/* TSO/E VERSION 2.                                                  */
/*-------------------------------------------------------------------*/
ALTLIB DEACTIVATE APPLICATION(CLIST)

/*-------------------------------------------------------------------*/
/* FREE THE CONLIB ALLOCATION.                                       */
/*-------------------------------------------------------------------*/
FREE FI(CONLIB)

/*-------------------------------------------------------------------*/
/* TERMINATE WITH A RETURN CODE ZERO.                                */
/*-------------------------------------------------------------------*/
EXIT CODE(0)

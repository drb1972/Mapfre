/* REXX                                                              */
/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2010 CA. ALL RIGHTS RESERVED.                 */
/*                                                                   */
/* NAME: ENDIEIM1                                                    */
/*                                                                   */
/* PURPOSE: THIS IS A SAMPLE REXX EXEC THAT IS GIVEN CONTROL WHEN    */
/*  THE EDIT ELEMENT DIALOG USER SELECTS THE EDIT OR CREATE DIALOG   */
/*  OPTION.  THE EXEC CAN BE USED TO PERFORM ANY EDIT SESSION SET-UP */
/*  STEPS THAT THE USER MAY REQUIRE.  EXAMPLES INCLUDE SETTING THE   */
/*  CAPS ATTRIBUTE, DEFINING ADDITIONAL EDIT MACROS OR WRITING       */
/*  MESSAGES.                                                        */
/*                                                                   */
/*   NOTE: ENDIEIM1 CAN ALSO BE WRITTEN AS A CLIST.                  */
/*                                                                   */
/*-------------------------------------------------------------------*/
/*-------------------------------------------------------------------*/
/* UNCOMMENT THIS STATEMENT TO ENABLE THE REXX TRACE FACILITY.       */
/*-------------------------------------------------------------------*/
/*TRACE ALL                                  ENABLE REXX TRACE       */

/*-------------------------------------------------------------------*/
/* FIRST, RETRIEVE THE DIALOG VARIABLES FROM THE PROFILE POOL.       */
/* NOTE: UNCOMMENT THIS CODE TO ACTIVATE THE VGET REQUEST.           */
/*-------------------------------------------------------------------*/

  ADDRESS ISPEXEC
            'VGET (ENVBENV ENVBSYS ENVBSBS ENVBTYP ENVBSTGI ENVBSTGN
                   ENVSENV ENVSSYS ENVSSBS ENVSTYP ENVSSTGI ENVSSTGN
                   ENVELM  ENVPRGRP ENVCCID ENVCOM ENVGENE ENVOSIGN)
             PROFILE'

/*-------------------------------------------------------------------*/
/* USE THE BASE ELEMENT TYPE NAME TO DETERMINE THE APPROPRIATE EDIT  */
/* PROFILE TO BE USED WITH THE SESSION.                              */
/* NOTE: THIS IS ONLY AN EXAMPLE.  THE CODE WILL HAVE TO BE MODIFIED */
/* TO MAP THE INSTALLATIONS ELEMENT TYPE NAMES TO THE APPROPRIATE    */
/* EDIT PROFILES.                                                    */
/*-------------------------------------------------------------------*/
/*IF (ENVBTYP = COBOL) THEN             /* IF A COBOL PROGRAM    */  */
/*  ADDRESS ISREDIT 'PROFILE COBOL 0'                                */
/*                                                                   */
/*IF (ENVBTYP = ISRCE) THEN             /* IF A CLIST/REXX EXEC  */  */
/*  ADDRESS ISREDIT 'PROFILE CLIST 0'                                */

/*-------------------------------------------------------------------*/
/* LET ISPF TRY AND WORK OUT THE APPROPRIATE HILITE                  */
/*-------------------------------------------------------------------*/
"ISREDIT (PDSNAME) = DATASET"
X = LISTDSI("'"PDSNAME"'")

IF SYSLRECL < 256 THEN DO
  ADDRESS ISREDIT
  "HILITE AUTO"
  "HILITE PAREN"
  "HILITE FIND"
  "HILITE CURSOR"
END /* END DO */

EXIT 0

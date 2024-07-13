/*********************************************************************/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                */
/*                                                                   */
/* NAME: WIPHELP                                                     */
/*                                                                   */
/* FUNCTION: THIS ISPF/PDF EDIT MACRO IS USED TO SUPPORT THE WIPHELP */
/* COMMAND.  THE WIPHELP COMMAND WILL ALLOW THE USER TO DISPLAY ONLY */
/* THOSE LINES THAT ARE BEING INCLUDED FROM THE FILES SPECIFIED ON   */
/* THE WIPHELP COMMAND. ALL OTHER LINES ARE EXCLUDED FROM THE        */
/* DISPLAY.                                                          */
/*                                                                   */
/* SYNTAX: THE SYNTAX OF THE WIPHELP COMMAND IS                      */
/*    WIPHELP                                                        */
/*                                                                   */
/*  THE WIPHELP COMMAND DOES NOT ACCEPT ANY PARAMETERS.              */
/*                                                                   */
/*********************************************************************/

ISREDIT MACRO NOPROCESS

/*********************************************************************/
/* USE THE ISPEXEC SELECT SERVICE TO INVOKE THE ISPF TUTORIAL DRIVER.*/
/*  NOTE: THE CONTROL DISPLAY SAVE AND THE CONTROL DISPLAY RESTORE   */
/* SERVICES ARE REQUIRED WHEN CALLING ISPTUTOR FROM WITHIN AN EDIT   */
/* MACRO. REFER TO THE ISPF DIALOG MANAGEMENT GUIDE.                 */
/*********************************************************************/
ISPEXEC CONTROL DISPLAY SAVE
ISPEXEC SELECT PGM(ISPTUTOR) PARM(BC1TEDIT)
ISPEXEC CONTROL DISPLAY RESTORE

EXIT CODE(0)

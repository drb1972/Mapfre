/*********************************************************************/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                 */
/*                                                                   */
/* NAME: WIPCHANG                                                    */
/*                                                                   */
/* FUNCTION: THIS ISPF/PDF EDIT MACRO IS USED TO SUPPORT THE WIPCHANG*/
/* COMMAND.  THE WIPCHANG COMMAND WILL ALLOW THE USER TO DISPLAY ONLY*/
/* THOSE LINES THAT HAVE BEEN CHANGED (IE. BEEN INSERTED OR DELETED).*/
/* ALL OTHER LINES WILL BE EXCLUDED FROM THE DISPLAY.                */
/*                                                                   */
/* SYNTAX: THE SYNTAX OF THE WIPCHANG COMMAND IS                     */
/*    WIPCHANG                                                       */
/*  THE WIPCHANG COMMAND DOES NOT ACCEPT ANY PARAMETERS.             */
/*                                                                   */
/*********************************************************************/

ISREDIT MACRO (PARMS) NOPROCESS

/*********************************************************************/
/* SAVE THE CURRENT EDIT STATE AND SET THE RETURN CODE TO 0.         */
/*********************************************************************/
ISREDIT (STATUS) = USER_STATE
SET &RETCODE = 0

/*********************************************************************/
/*                                                                   */
/* USE THE ISPF/PDF EXCLUDE AND FIND COMMANDS TO SHOW ALL THE RECORDS*/
/* THAT MATCH THE FILE_IDS SPECIFIED BY THE USER.  ACCUMULATE THE    */
/* NUMBER OF RECORDS FOUND AND WRITE TOTAL AS A SHORT MESSAGE.       */
/*                                                                   */
/*********************************************************************/
ISREDIT RESET
ISREDIT UP MAX
ISREDIT EXCLUDE ALL

SET &FINDCNT = 0

ISREDIT FIND '%' ALL CHARS 1
ISREDIT (COUNT) = FIND_COUNTS
SET &FINDCNT = &COUNT

IF (&FINDCNT = 0) THEN  +
  DO
    ISREDIT RESET
    ISREDIT UP MAX
  END

SET &ZEDSMSG = &STR(&FINDCNT CHANGES FOUND)
SET &ZEDLMSG = &STR(&FINDCNT CHANGES WERE FOUND IN THE WIP MEMBER)
ISPEXEC SETMSG MSG(ISRZ001)

SET &RETCODE = 1

/*********************************************************************/
/* RESTORE THE USER STATE AND EXIT WITH THE MACRO RETURN CODE        */
/*********************************************************************/
ISREDIT USER_STATE = (STATUS)
EXIT CODE(&RETCODE)

/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 * This routine is run on a remote system to issue the message for   *
 * AO to pickup and update Infoman on the Qplex.                     *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

arg cmr status

address tso
"SEND 'EV000202 ENDEVOR CJOB:" cmr "COMPLETED - STATUS:" status,
 "',OPERATOR(11)"

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

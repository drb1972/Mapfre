/*-----------------------------REXX----------------------------------*\
 *  Send OPSWTO to demand job EVL0101D on the Qplex                  *
\*-------------------------------------------------------------------*/
trace n

arg cmr

/* This is an OPSMVS rexx so no says are possible, they go to the log*/

"execio * diskr input (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of INPUT failed'

/* Sed message to demand EVL0101D on the local destination           */
do i = 1 to line.0
  text = right(cmr,7) line.i
  address WTO "msgid(EV000101) text('"text"')"
end /* i = 1 to line.0 */

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

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

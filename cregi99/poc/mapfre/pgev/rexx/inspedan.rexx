/*-----------------------------REXX----------------------------------*\
 *  Build report 70 cards for the inspect job EVHTASKD               *
 *                                                                   *
 *  This Rexx runs under IRXJCL in job EVHTASKD                      *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace I
parse source . . rexxname .

say rexxname': Building the input to run Report 70 for all'
say rexxname': unexecuted Production packages that were'
say rexxname': successfully cast after 'date('N',date('B')-183,'B')

queue "    REPORT  70 .                                "
queue "    PACKAGE C%%%%%%%P .                         "
queue "    ENVIRONMENT * .                             "
queue "    STATUS  APPROVED IN-APPROVAL .              "
queue "    CAST   AFTER  "date('U',date('B')-183,'B')" ."

"execio 5 diskw OUTFILE (finis)"
if rc ^= 0 then call exception rc 'DISKW to OUTFILE failed'

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

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code

/*----- REXX --------------------------------------------------------*/
/* This routine reads the package report and builds inspect          */
/* statements for the next step in EVHTASKD                          */
/*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

"execio * diskr REPIN (stem rep. finis"
if rc ^= 0 then call exception rc 'DISKR of REPIN failed'

say rexxname': '
say rexxname': Here is the output from the package report'
say rexxname': '

/* Reproduce output to aid diagnostic (if required)                  */
do a = 1 to rep.0
  say substr(rep.a,2,130)
end /* a = 1 to rep.0 */

say rexxname': '
say rexxname': End of output from the package report'
say rexxname': '
say

do c = 1 to rep.0 /* loop through output to get package names        */

  pkgnum = substr(rep.c,4,7) /* middle part of the CMR               */

  /* check that the middle bit of the package is numeric             */
  if datatype(pkgnum) = 'NUM' then do

    package = substr(rep.c,3,9) /* extract package name              */

    queue ' INSPECT PACKAGE' package '.' /* queue command            */
    say rexxname': Found package' package 'to inspect.'

  end /* datatype(pkgnum) = 'NUM' */

end /* c = 1 to rep.0 */

"execio" queued() "diskw REPOUT (finis)"
if rc ^= 0 then call exception rc 'DISKW to REPOUT failed'

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

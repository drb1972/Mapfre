/*-----------------------------REXX----------------------------------*\
 *  Reads a list packages that are ready to be committed.            *
 *  It builds commit statements for all packages that have no Cjob   *
 *  member in CMJOBS.                                                *
 *                                                                   *
 *  Called in job EVHPACKW.                                          *
\*-------------------------------------------------------------------*/
trace n

arg cmjobs

say 'PKGCOMM:' Date() Time()
say 'PKGCOMM:'
say 'PKGCOMM: Cmjobs....:' cmjobs
say 'PKGCOMM:'

/* Read the list of packages to be committed                         */
"execio * diskr PKGS (stem pkgs. finis"
if rc ^= 0 then call exception rc 'DISKR of DDname PKGS failed'

/* Build commit SCL if the Cjob is not in CMJOBS                     */
do i = 1 to pkgs.0 /* Loop through the packages to be committed      */
  ccid = substr(pkgs.i,13,8)
  if sysdsn("'"cmjobs"("ccid")'") ^= 'OK' then do
    say 'PKGCOMM:' ccid'P will be commited.'
    queue ' COMMIT PACKAGE' ccid'P .'
  end /* sysdsn("'"cmjobs"("ccid")'") ^= 'OK' */
  else
    say 'PKGCOMM:' ccid'P will not be commited.'
end /* i = 1 to pkgs.0 */

"execio * diskw SCL (finis)"
if rc ^= 0 then call exception rc 'DISKW to SCL failed'

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

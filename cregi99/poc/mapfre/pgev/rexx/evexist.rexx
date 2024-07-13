/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 * It is used by EVGDIMPI as part of the DUMPRSTx type processing.   *
 *                                                                   *
 * This routine gets the DFDSS dump cards and validates the dataset  *
 * exists otherwise it drops the backup card.                        *
 *                                                                   *
 * If none of the datasets exist the backup step is skipped by       *
 * return code checking.                                             *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

arg autodsn

say 'EVEXIST:' Date() Time()
say 'EVEXIST:'

exit_rc = 0 /* set the initial value of the final return code        */

parse value autodsn with dsname'('mem')'
cmr     = 'C0'right(mem,6)
bmr     = 'B0'right(mem,6)
cjobout = dsname'('cmr')'
bjobout = dsname'('bmr')'
bjob    = 0 /* array for backouts                                    */
cjob    = 0 /* array for implementation                              */

/* Get the the contents of the promoted member                       */
"alloc f(AUTOIN) dsname('"autodsn"') shr"
if rc ^= 0 then call exception rc 'ALLOC of' autodsn 'failed.'

say 'EVEXIST: Dataset' autodsn 'has been allocated'
say 'EVEXIST:'

/* Get the the contents of the member                                */
'execio * diskr AUTOIN (stem dfdss. finis'
if rc ^= 0 then call exception rc 'DISKR of DDname AUTOIN failed.'

"free f(AUTOIN)" /* Release the allocation                           */

/* loop through the dfdss content                                    */
do a = 1 to dfdss.0 /* loop through each line                        */
  testdsn = strip(word(dfdss.a,1))

  /* Does the dataset exist                                          */
  if sysdsn("'"testdsn"'") = 'OK' then do
    cjob = cjob + 1
    impl.cjob = dfdss.a /* add to backout array                      */
  end /* sysdsn("'"testdsn"'") = 'OK' */

  else do
    bjob = bjob + 1
    back.bjob = ' DELETE' left(testdsn,22) /* idcams delete for bjob */
  end /* else */

end /* a = 1 to dfdss.0 */

do b = 1 to cjob
  rep = left(word(impl.b,1),22)
  say 'EVEXIST: Dataset' rep 'exists so it will be backed up.'
end /* b = 1 to cjob */

say 'EVEXIST:'

do c = 1 to bjob
  backdsn = left(word(back.c,2),22)
  say 'EVEXIST: Dataset' backdsn 'does not exist. No backup needed.'
end /* c = 1 to bjob */

back.0 = bjob
impl.0 = cjob

if cjob > 0 then do /* Anything in the Bjob array                    */
  /* Allocate the target file                                        */
  "alloc f(AUTOOUT) dsname('"cjobout"') shr"
  if rc ^= 0 then call exception rc 'ALLOC of' cjobout 'failed.'

  say 'EVEXIST:'
  say 'EVEXIST: Dataset' cjobout 'has been allocated'

  /* Write out the modified code                                     */
  'execio' impl.0 'diskw autoout (stem impl. finis'
  if rc ^= 0 then call exception rc 'DISKW to file' cjobout 'failed.'

  say 'EVEXIST: Datasets needing backup have been written.'

  "free f(AUTOOUT)" /* Release the allocation                        */

end /* cjob > 0 */

/* this else is only used when there are cjob cards                  */
else exit_rc = 2 /* high return code allows skip of next job step    */

if bjob > 0 then do /* Anything in the Bjob array                    */
  /* Allocate the target file                                        */
  "alloc f(AUTOOUT) dsname('"bjobout"') shr"
  if rc ^= 0 then call exception rc 'ALLOC of' bjobout 'failed.'

  say 'EVEXIST:'
  say 'EVEXIST: Dataset' bjobout 'has been allocated'

  /* Write out the modified code                                     */
  'execio' back.0 'diskw autoout (stem back. finis'
  if rc ^= 0 then call exception rc 'DISKW to file' bjobout 'failed.'

  say 'EVEXIST: Datasets not needing backup have been written.'

  "free f(AUTOOUT)" /* Release the allocation                        */

end /* bjob > 0 */

exit exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 queue rexxname':'
 queue rexxname':' comment'. RC='return_code
 queue rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

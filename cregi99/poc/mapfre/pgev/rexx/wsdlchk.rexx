/*-----------------------------REXX----------------------------------*\
 *  Check WSDL & XSD element names are standard.                     *
 *  Also check the first line to ensure that no encoding is          *
 *  specified.                                                       *
 *  Check the first character of the file is a < and not rubbish     *
\*-------------------------------------------------------------------*/
trace n

parse arg c1sy c1elmnt255 c1ty c1userid

say 'WSDLCHK:' Date() Time()
say 'WSDLCHK:'
say 'WSDLCHK: c1sy............:' c1sy
say 'WSDLCHK: c1elmnt255......:' c1elmnt255
say 'WSDLCHK: c1ty............:' c1ty
say 'WSDLCHK: c1userid........:' c1userid
say 'WSDLCHK:'

name_error_found = 'N'

thisjob = mvsvar('SYMDEF','JOBNAME')
say 'WSDLCHK: Job Name..:' thisjob
say 'WSDLCHK:'

/* Read the first line of the source and fail if encoding is found   */
"execio * diskr SOURCE (stem line. finis"
if rc > 1 then call exception rc "DISKR of SOURCE failed"

line1 = line.1
upper line1

if substr(line1,1,1) ^= '<' then do
  queue 'WSDLCHK: !!!! This element is invalid !!!!'
  queue 'WSDLCHK: The first character of the source must be a "<"'
  queue 'WSDLCHK: but the first line is:'
  queue 'WSDLCHK:' line.1
  queue 'WSDLCHK:'
end /* substr(line1,1,1) ^= '<' */

if pos('ENCODING',line1) > 0 then do
  queue 'WSDLCHK: You must not use encoding on the first line of your element.'
  queue 'WSDLCHK: The first line should be "<?xml version="n.n"?>"'
  queue 'WSDLCHK: The first line of your element is:'
  queue 'WSDLCHK:' line.1
  queue 'WSDLCHK:'
end /* pos('ENCODING',line1) > 0 */

/* Validate the element name                                         */
parse var c1elmnt255 program_name '.' extension
parse var program_name wrapper_pgm '_' rest

elt_sys_id = left(c1elmnt255,2)

ucase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
lcase = 'abcdefghijklmnopqrstuvwxyz'

/* Check that the element has a valid file extension                 */
c1ty_lower = translate(c1ty,lcase,ucase)
if extension ^= c1ty_lower then do
  queue 'WSDLCHK: Invalid file name : ' c1elmnt255
  queue 'WSDLCHK: File extension should be: .'c1ty_lower
  queue 'WSDLCHK:'
  if c1ty = 'WSDL' then
    name_error_found = 'Y'
end /* extension ^= c1ty_lower */

/* Check the first 2 characters of the element name = system name    */
if elt_sys_id ^= c1sy then do
  queue 'WSDLCHK: Invalid file name : ' c1elmnt255
  queue 'WSDLCHK: The first 2 characters of the file name must be the'
  queue 'WSDLCHK: same as the Endevor system name.'
  queue 'WSDLCHK:'
  if c1ty = 'WSDL' then
   name_error_found = 'Y'
end /* elt_sys_id ^= c1sy */

if c1ty = 'XSD' then do
  /* For CONRELE to work the max length for an XSD name is 49        */
  if Length(c1elmnt255) > 49 then do
    queue 'WSDLCHK: Invalid XSD name : ' c1elmnt255
    queue 'WSDLCHK: The maximum length of an XSD name is 49 characters'
    queue 'WSDLCHK:'
  end /* Length(c1elmnt255) > 49 */
end /* c1ty = 'XSD' */

if c1ty = 'WSDL' then do
  /* Check that the program name is the right length                 */
  if Length(program_name) > 32 then do
    queue 'WSDLCHK: Invalid program name : ' program_name
    queue 'WSDLCHK: The program name length must be 32 characters or less'
    queue 'WSDLCHK:'
    name_error_found = 'Y'
  end /* Length(program_name) > 32 */

  if Length(Wrapper_Pgm) ^= 8 then do
    queue 'WSDLCHK: Invalid wrapper name : ' Wrapper_Pgm
    queue 'WSDLCHK: The wrapper name must be 8 characters in length.'
    queue 'WSDLCHK:'
    name_error_found = 'Y'
  end /* Length(Wrapper_Pgm) ^= 8 */

  /* Check for elements with the same wrapper name                   */
  "execio * diskr CSVLIST (stem csv. finis"
  if rc > 1 then call exception rc "DISKR of CSVLIST failed"

  do i = 1 to csv.0
    csvtype   = substr(csv.i,49,8)
    csvelt255 = substr(csv.i,139,255)
    csvelt8   = left(csvelt255,8)
    if csvtype    = 'WSDL'             & ,
       csvelt8    = left(c1elmnt255,8) & ,
       csvelt255 ^= c1elmnt255         then do
      queue 'WSDLCHK: A WSDL with the same wrapper program name' ,
            'already exists in system' c1sy'.'
      queue 'WSDLCHK: The conflicting element is:'
      queue 'WSDLCHK: ' csvelt255
      queue 'WSDLCHK: This element is:'
      queue 'WSDLCHK: ' c1elmnt255
      queue 'WSDLCHK:'
    end /* csvelt255 ^= c1elmnt255 & ... */

  end /* i = 1 to csv.0 */

  if name_error_found = 'Y' then do
    queue 'WSDLCHK:',
        'The format of the input file is xxyyyzzz_meaningfullname'
    queue 'WSDLCHK: Where xx     - Endevor System Id   '
    queue 'WSDLCHK:     xxyyyzzz - Wrapper program associated with this csv.'
  end /* name_error_found = 'Y' */

end /* c1ty = 'WSDL' */

out.0 = queued()
do i = 1 to out.0
  parse pull out.i
end /* i = 1 to out.0 */

if out.0 > 0 then do
  'execio * diskw README (stem out. finis'
  if rc > 1 then call exception rc "DISKW to README failed"
  if thisjob = 'EAPISVR' then call send_email
  exit 8
end /* out.0 > 0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Send email back to user with the error message                    */
/*-------------------------------------------------------------------*/
Send_email:

 /* Work out job number                                              */
 ascb  = c2x(storage(224,4))
 assb  = c2x(storage(d2x(x2d(ascb)+336),4))
 jsab  = c2x(storage(d2x(x2d(assb)+168),4))
 jobid = storage(d2x(x2d(jsab)+20),8)
 say 'WSDLCHK: Job number:' jobid

 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(120) blksize(0) dsorg(ps)"

 queue 'FROM: mapfre.endevor@rsmpartners.com'

 say 'WSDLCHK: Sending email to  VERTIZOS@kyndryl.com'
 queue 'TO:  VERTIZOS@kyndryl.com'
 say 'WSDLCHK:'
 say

 queue 'SUBJECT: EPLEX - JOB' thisjob'('jobid')' c1elmnt255 '- failed'

 "execio" queued() "diskw SYSADDR (finis)"
 if rc > 1 then call exception rc 'DISKW to SYSADDR failed.'

 "alloc f(SYSDATA) new space(5,15) tracks
  recfm(f,b) lrecl(800) blksize(0) dsorg(ps)"
 "execio * diskw SYSDATA (stem out. finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed.'

 "exec 'SYSTSO.BASE.EXEC(SENDMAIL)' 'DEFAULT LOG(YES)'" exec
 if rc ^= 0 then call exception rc 'SENDMAIL failed.'

 "free fi(SYSADDR SYSDATA)"

return /* Send_email */

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

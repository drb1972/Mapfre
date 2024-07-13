/*-----------------------------REXX----------------------------------*\
 *  Send STDOUT report from a BAR deployment to the package casting  *
 *  userid.                                                          *
 *                                                                   *
 *  An example can be found in the BARDPLY procinc.                  *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg plex_envr c1en c1su c1stage

say rexxname':' Date() Time()
say rexxname':'
say rexxname': Plex_envr.......:' plex_envr
say rexxname': C1en............:' c1en
say rexxname': C1su............:' c1su
say rexxname': C1stage.........:' c1stage

/* Read the package report - if the deploy is in a package           */
"execio * diskr PKGLIST (stem pkg. finis"
if rc ^= 0 then call exception rc 'DISKR of PKGLIST failed'
if pkg.0 > 0 then do
  uid = substr(pkg.1,207,8)
  say rexxname': Cast uid........:' uid
end /* pkg.0 > 0 */

uid = strip(uid,,'40'x) /* Strip spaces                              */
uid = strip(uid,,'00'x) /* Strip nulls                               */
uid = strip(uid,,'40'x) /* Strip spaces                              */

/* Get the element name (BAR file name)                              */
"execio * diskr DATA (stem data. finis"
if rc ^= 0 then call exception rc 'DISKR of DATA failed'

c1elmnt255  = strip(data.1)
stdout_dir  = strip(data.2)
stdout_file = strip(data.3)
say rexxname': C1elmnt255......:' c1elmnt255
say rexxname': Stdout_dir......:' stdout_dir
say rexxname': Stdout_file.....:' stdout_file
say rexxname':'

if uid ^= '' then call send_email
else say rexxname': No email addresses supplied, no email sent'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Send email back to user with the STDOUT report                    */
/*-------------------------------------------------------------------*/
Send_email:

 /* Work out job number                                              */
 ascb  = c2x(storage(224,4))
 assb  = c2x(storage(d2x(x2d(ascb)+336),4))
 jsab  = c2x(storage(d2x(x2d(assb)+168),4))
 jobid = storage(d2x(x2d(jsab)+20),8)
 say rexxname': Job number:' jobid

 /* Work out job name                                                */
 thisjob = mvsvar('SYMDEF','JOBNAME')
 say rexxname': Job Name..:' thisjob
 say rexxname':'

 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(120) blksize(0) dsorg(ps)"

 queue 'FROM: mapfre.endevor@rsmpartners.com'

 if uid ^= '' then do
   say rexxname': Sending email to  VERTIZOS@kyndryl.com'
   queue 'TO:  VERTIZOS@kyndryl.com'
 end /* uid ^= '' */

 say rexxname':'
 say

 queue 'SUBJECT: EPLEX - JOB' thisjob'('jobid')' c1elmnt255 ,
       '- Deployment Report'

 "execio" queued() "diskw SYSADDR (finis)"
 if rc > 1 then call exception rc 'DISKW to SYSADDR failed'

 call read_USS_file stdout_dir || stdout_file 'stdout.'

 queue 'MIME-Version: 1.0'
 queue 'CONTENT-TYPE: MULTIPART/MIXED; BOUNDARY="SPLITLINE"'
 queue ' '
 queue '--SPLITLINE'
 queue ' '
 queue 'Deploy STDOUT report for' c1en c1su c1elmnt255
 queue ' '
 queue '--SPLITLINE'
 queue 'CONTENT-DISPOSITION: ATTACHMENT; FILENAME=Deploy log.txt'
 queue ' '

 "alloc f(SYSDATA) new space(5,15) tracks
  recfm(f,b) lrecl(800) blksize(0) dsorg(ps)"
 "execio * diskw SYSDATA"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed'

 "execio" stdout.0 "diskw SYSDATA (stem stdout."
 if rc > 1 then call exception rc 'DISKW to SYSDATA failed'

 queue '--SPLITLINE--'

 "execio 1 diskw SYSDATA (finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed'

 "exec 'SYSTSO.BASE.EXEC(SENDMAIL)' 'DEFAULT LOG(YES) MIME(YES)'" exec
 if rc ^= 0 then call exception rc 'SENDMAIL failed'

 "free fi(SYSADDR SYSDATA)"

return /* Send_email: */

/*-------------------------------------------------------------------*/
/* Read_USS_file - doesnt use readfile because of long record length */
/*-------------------------------------------------------------------*/
read_USS_file:
 parse arg file_path stem_name

 call syscalls 'ON'
 address syscall 'open (file_path)' O_rdonly 000
 if retval = -1 then call exception retval 'open failed' ,
                          errno errnojr file_path
 fd = retval

 /* Read the file into one big string                                */
 lump = ''
 do until retval = 0
   address syscall 'read' fd 'block 2048'
   if retval = -1 then call exception retval 'read failed' ,
                            errno errnojr file_path
   lump = lump || block
 end /* until retval = 0 */
trace i
 /* Split the string back in to records                              */
 remainder = ''
 x15       = x2c('15') /* End of line marker                         */
 do iii = 1
   x = pos(x15,lump)   /* Find the end of the line character         */
   if x = 0 then leave

   interpret stem_name'iii = left(lump,x-1)' /* Set the stem variable*/
   lump = substr(lump,x+1) /* Start on the next line                 */
 end /* iii = 1 */

 interpret stem_name'0 = iii - 1' /* Set the number of records found */
trace o
 address syscall 'close' fd
 call syscalls 'OFF'

return /* read_USS_file */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg('off')
 address tso "free fi(SYSADDR SYSDATA)" /* Free open files           */
 address tso 'delstack'           /* Clear down the stack            */
 z = msg('on')

 if return_code < 12 | return_code > 4095 then return_code = 12

exit return_code

/*-----------------------------REXX----------------------------------*\
 *  Send STDOUT report from a DEPLOY to the user(s)                  *
 *  It sends to the user who submitted the job and the email address *
 *  in the WSPROPS file if one exists.                               *
 *  Called by GDEPLOY and MDEPLOY                                    *
\*-------------------------------------------------------------------*/
trace n

arg plex_envr c1en c1su c1stage

say 'DPLYMAIL:' Date() Time()
say 'DPLYMAIL:'
say 'DPLYMAIL: Plex_envr.......:' plex_envr
say 'DPLYMAIL: C1en............:' c1en
say 'DPLYMAIL: C1su............:' c1su
say 'DPLYMAIL: C1stage.........:' c1stage

/* Read the package report - if the deploy is in a package           */
"execio * diskr PKGLIST (stem pkg. finis"
if rc ^= 0 then call exception rc 'DISKR of PKGLIST failed'
if pkg.0 > 0 then do
  uid = substr(pkg.1,207,8)
  say 'DPLYMAIL: Cast uid........:' uid
end /* pkg.0 > 0 */

uid = strip(uid,,' ') /* Strip spaces                                */
uid = strip(uid,,' ') /* Strip nulls                                 */
uid = strip(uid,,' ') /* Strip spaces                                */

/* Get the element name (EAR file name)                              */
"execio * diskr DATA (stem data. finis"
if rc ^= 0 then call exception rc 'DISKR of DATA failed'

c1elmnt255  = strip(data.1)
stdout_dir  = strip(data.2)
stdout_file = strip(data.3)
say 'DPLYMAIL: C1elmnt255......:' c1elmnt255
say 'DPLYMAIL: Stdout_dir......:' stdout_dir
say 'DPLYMAIL: Stdout_file.....:' stdout_file
say 'DPLYMAIL:'

call read_wsprops /* Find email addresses                            */

if uid          ^= '' | ,
   wsprops_addr ^= ''  then
  call send_email
else
  say 'DPLYMAIL: No email addresses supplied, no email sent'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Get the SCHENV for DEPLOY jobs from the WSPROPS file              */
/*-------------------------------------------------------------------*/
read_wsprops:

 wsprops_addr  = ''

 say 'DPLYMAIL: Searching for email addresses in WSPROPS'

 parse value c1elmnt255 with file '.' extn
 wsprops_file  = file'.properties'
 say 'DPLYMAIL: WSPROPS file name..:' wsprops_file

 /* Loop through the stages until we find a WSPROPS file             */
 subsys = c1su
 do i = 1 to 8 while substr(c1stage,i,1) ^= 'X'

   if plex_envr = 'DEV' then do
     stage = substr(c1stage,i,1)
     select
       when pos(stage,'AB') > 0 then envr = 'UNIT'
       when pos(stage,'CD') > 0 then envr = 'SYST'
       when pos(stage,'EF') > 0 then envr = 'ACPT'
       when pos(stage,'OP') > 0 then do
         envr   = 'PROD'
         subsys = left(c1su,2)'1'
       end /* pos(stage,'OP') > 0 */
       otherwise leave
     end /* select */

     full_filename = '/RBSG/endevor/'envr'/'stage || ,
                     subsys'/WSPROPS/'wsprops_file
   end /* plex_envr = 'DEV' */
   else
     full_filename = '/RBSG/endevor/PG'left(c1su,2) || ,
                     '/BASE/WSPROPS/'wsprops_file

   say 'DPLYMAIL: Testing for........:' full_filename

   command = 'ls' full_filename
   call bpxwunix command,,Out.,Err. /* Does the WSPROPS file exist?  */

   if err.0 = 0 then do /* WSPROPS file found so read it             */
     version = 'old'
     say 'DPLYMAIL: WSPROPS file found.:' full_filename
     call read_USS_file full_filename 'wsprops.'

     do zz = 1 to wsprops.0 /* Test version 2 format                 */
       parse value wsprops.zz with var_name '=' val
       if var_name = c1en'email' then do
         wsprops_addr = strip(val)
         wsprops_addr = strip(wsprops_addr,,'"')
         say 'DPLYMAIL: Email address found:' wsprops_addr
         leave zz
       end /* var_name = c1en'email' */
     end /* zz = 1 to wsprops.0 */

     if wsprops_addr = '' then do /* Test version 3 format           */
       ensu = c1en || right(c1su,1)
       do zz = 1 to wsprops.0
         if pos('streamProps',wsprops.zz) > 0 then do
           found   = 'N'
           version = 'new'
           if pos(ensu,wsprops.zz) > 0 then
             found   = 'Y'
           iterate
         end /* left(wsprops.zz,11) = 'streamProps' */
         if found = 'Y' then do
           parse value wsprops.zz with var_name ':' val
           if var_name = '"email"' then do
             val = space(val,0)
             val = strip(val,t,',')
             val = strip(val,b,'"')
             wsprops_addr = val
             say 'DPLYMAIL: Email address found:' wsprops_addr
             leave zz
           end /* var_name = '"email"' */
         end /* found = 'Y' */
       end /* do zz = 1 to wsprops.0 */
     end /* wsprops_addr = '' */

     leave i
   end /* err.0 = 0 */

 end /* i = 1 to 8 while substr(c1stage,i,1) ^= 'X' */

 if err.0 > 0 then do /* WSPROPS file not found                      */
   say 'DPLYMAIL: WSPROPS file not found in directory search order:' ,
       c1stage
   exit 12
 end /* err.0 > 0 */

 if wsprops_addr = '' then
   say 'DPLYMAIL: No email address found in WSPROPS file'

 say 'DPLYMAIL:'

return /* read_wsprops */

/*-------------------------------------------------------------------*/
/* Send email back to user with the STDOUT report                    */
/*-------------------------------------------------------------------*/
Send_email:

 /* Work out job number                                              */
 ascb      = c2x(storage(224,4))
 assb      = c2x(storage(d2x(x2d(ascb)+336),4))
 jsab      = c2x(storage(d2x(x2d(assb)+168),4))
 jobid     = storage(d2x(x2d(jsab)+20),8)
 say 'DPLYMAIL: Job number:' jobid

 /* Work out job name                                                */
 thisjob   = mvsvar('SYMDEF','JOBNAME')
 say 'DPLYMAIL: Job Name..:' thisjob
 say 'DPLYMAIL:'

 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(120) blksize(0) dsorg(ps)"

 queue 'FROM: mapfre.endevor@rsmpartners.com'

 if uid ^= '' then do
   say 'DPLYMAIL: Sending email to  VERTIZOS@kyndryl.com'
   queue 'TO:  VERTIZOS@kyndryl.com'
 end /* uid ^= '' */
 if wsprops_addr ^= '' then do
   say 'DPLYMAIL: Sending email to' wsprops_addr
   queue 'TO:  VERTIZOS@kyndryl.com'
 end /* wsprops_addr ^= '' */
 if version = 'old' then do
   say 'DPLYMAIL: Sending email to ¯ Endevor'
   queue 'TO: VERTIZOS@kyndryl.com'
 end /* version = 'old' */

 say 'DPLYMAIL:'
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
 if version = 'old' then do
   queue ' '
   queue '*** Your WSPROPS element does not conform to the        **'
   queue '*** latest standard layout. By continuing to use this   **'
   queue '*** format of WSPROPS you can expect to encounter       **'
   queue '*** issues with the production deployment and can delay **'
   queue '*** your implementation.                                **'
   queue '*** Please contact your WebSphere resource to provide   **'
   queue '*** the latest format WSPROPS file.                     **'
 end /* version = 'old' */
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

return /* Send_email */

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

 /* Read the file into one big lump                                  */
 lump = ''
 do until retval = 0
   address syscall 'read' fd 'block 2048'
   if retval = -1 then call exception retval 'read failed' ,
                            errno errnojr file_path
   lump = lump || block
 end /* until retval = 0 */

 /* Split the lump into records                                      */
 remainder = ''
 x15       = x2c('15') /* End of line marker                         */
 do iii = 1
   x = pos(x15,lump)   /* Find the end of the line                   */
   if x = 0 then leave

   interpret stem_name'iii = left(lump,x-1)' /* Set the stem variable*/
   lump = substr(lump,x+1) /* Start on the next line                 */
 end /* do iii = 1 */

 interpret stem_name'0 = iii - 1' /* Set the number of records found */

 address syscall 'close' fd
 call syscalls 'OFF'

return /* read_USS_file */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 "free fi(SYSADDR SYSDATA)"

 address tso 'delstack' /* Clear down the stack                      */

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso "FREE F(SYSADDR SYSDATA)"
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

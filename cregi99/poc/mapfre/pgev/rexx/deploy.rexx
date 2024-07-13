/*-----------------------------REXX----------------------------------*\
 *  Work out which deploy process to use                             *
\*-------------------------------------------------------------------*/
trace n

arg c1en c1stage c1su

say 'DEPLOY:' Date() Time()
say 'DEPLOY:'
say 'DEPLOY: C1en............:' c1en
say 'DEPLOY: C1stage.........:' c1stage
say 'DEPLOY: C1su............:' c1su
say 'DEPLOY:'

say 'DEPLOY: Searching for WSPROPS file...'
/* Get the element name and work out the WSPROPS file name          */
"execio * diskr FILENAME (stem c1elmnt255. finis"
if rc ^= 0 then call exception rc 'DISKR of FILENAME failed.'

c1elmnt255 = c1elmnt255.1
parse value c1elmnt255 with file '.' extn

wsprops_file  = file'.properties'
say 'DEPLOY: WSPROPS file name..:' wsprops_file

deploy_process = 'OLD'

/* Loop through the stages until we find a WSPROPS file             */
subsys = c1su
do i = 1 to 8 while substr(c1stage,i,1) ^= 'X'

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

  command = 'ls' full_filename
  call bpxwunix command,,Out.,Err. /* Does the WSPROPS file exist?   */

  if err.0 = 0 then do    /* WSPROPS file found so read it           */
    call read_USS_file full_filename 'wsprops.'

    do zz = 1 to wsprops.0 /* test version 2 format                  */
      parse value wsprops.zz with var_name '=' val
      if var_name = c1en'cellName' then do
        deploy_process = 'NEW'
        leave zz
      end /* var_name = c1en'cellName' */
    end /* do zz = 1 to wsprops.0 */

    if deploy_process = 'OLD' then do /* test version 3 format       */
      ensu = c1en || right(c1su,1)
      do zz = 1 to wsprops.0
        if pos('streamProps',wsprops.zz) > 0 then do
          found = 'N'
          if pos(ensu,wsprops.zz) > 0 then do
            found = 'Y'
            deploy_process = 'NEW'
          end /* pos(ensu,wsprops.zz) > 0 */
          iterate
        end /* left(wsprops.zz,11) = 'streamProps' */
        if found = 'Y' then do
          parse value wsprops.zz with var_name ':' val
          if var_name = '"cellName"' then do
            val = space(val,0)
            val = strip(val,t,',')
            val = strip(val,b,'"')
            leave zz
          end /* var_name = c1en'cellName' */
        end /* found = 'Y' */
      end /* do zz = 1 to wsprops.0 */
    end /* if deploy_process = 'OLD' */

    leave i
  end /* err.0 = 0 */

end /* do i = 1 to 8 while substr(c1stage,i,1) ^= 'X' */

if err.0 > 0 then do            /* WSPROPS file not found           */
  say 'DEPLOY: WSPROPS file not found in directory search order:' c1stage
  exit 12
end /* err.0 > 0 */
else
  say 'DEPLOY: WSPROPS file found:' full_filename

if deploy_process = 'NEW' then do
  say 'DEPLOY: Will use the NEW process'
  say 'DEPLOY: CellName:          ' val
  exit 1
end /* deploy_process = 'NEW' */
else
  say 'DEPLOY: Will use the OLD process'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

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

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

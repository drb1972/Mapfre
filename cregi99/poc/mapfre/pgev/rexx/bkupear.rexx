/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This Rexx is used by MDEPLOY to back up WBRESOLVED EAR files  | */
/* | and MEAR to back up WBSHPEAR EAR files before it is updated.  | */
/* |                                                               | */
/* | Used when moving to stage P only.                             | */
/* +---------------------------------------------------------------+ */
trace n

arg c1sy c1ccid lldir


/* Read the file name                                                */
"execio * diskr FILENAME (stem filename. finis"
if rc ^= 0 then call exception 12 'DISKR of FILENAME failed. RC='rc
filename = strip(filename.1)

say 'BKUPEAR: c1sy.......:' c1sy
say 'BKUPEAR: c1ccid.....:' c1ccid
say 'BKUPEAR: lldir......:' lldir
say 'BKUPEAR: filename...:' filename
say 'BKUPEAR:'

tgt        = 'PROD/P'c1sy'1/'lldir
stg        = 'PG'c1sy'/BASE/'lldir
stgp_file  = '/RBSG/endevor/'tgt'/'filename
bkup_dir   = '/RBSG/endevor/STAGING/B'right(c1ccid,7)'/'stg
bkup_file  = bkup_dir'/'filename

command = 'ls' stgp_file /* Does the stage P file already exist?     */
call bpxwunix command,,Out.,Err.

if err.0 = 0 then do                   /* File does exists           */
  command = 'ls' bkup_file /* Does the backup file already exist?    */
  call bpxwunix command,,Out.,Err.

  if err.0 > 0 then do                 /* File does not exist        */
    say 'BKUPEAR: Copy from  :' stgp_file
    say 'BKUPEAR:        to  :' bkup_file
    say 'BKUPEAR:'

    'bpxbatch sh mkdir -p -m 775' bkup_dir
    'bpxbatch sh cp -m 'stgp_file bkup_file
    if rc ^= 0 then call exception rc 'File copy failed.'

    call get_date_time bkup_file /* Get file mod time for reference     */

    /* Having copied the file the security and owner need to be set     */
    say 'BKUPEAR: Change permissions to 755 on' bkup_file
    say 'BKUPEAR:'
    'bpxbatch sh chmod -f 755' bkup_file
    if rc ^= 0 then call exception rc 'chmod failed.'

    say 'BKUPEAR: Change owner to PMFBCH on' bkup_file
    say 'BKUPEAR:'
    'bpxbatch sh chown -f PMFBCH' bkup_file
    if rc ^= 0 then call exception rc 'chown failed.'
  end /* err.0 > 0 */
  else
    say 'BKUPEAR: Backup file already exists.' bkup_file

end /* err.0 = 0 */

else
  say 'BKUPEAR: No stage P file to back up.' stgp_file

exit

/* +---------------------------------------------------------------+ */
/* | Get file modified date & time                                 | */
/* +---------------------------------------------------------------+ */
Get_date_time:
 parse arg file_name

 junk = syscalls('ON')           /* set up the pre defined variables */
 address syscall 'stat (file_name) dt.'

 address syscall 'gmtime' dt.st_mtime 'gm.'
 day = right(gm.tm_mday,2,0)     /* day   */
 sec = right(gm.tm_sec,2,0)      /* sec   */
 min = right(gm.tm_min,2,0)      /* min   */
 mo  = right(gm.tm_mon,2,0)      /* month */
 hr  = right(gm.tm_hour,2,0)     /* hour  */

 file_mod_time = gm.tm_year'-'mo'-'day' 'hr':'min':'sec

 say 'BKUPEAR: File modified time:' file_mod_time
 say 'BKUPEAR:'

return /* Get_date_time */

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
 say rexxname':'

exit return_code

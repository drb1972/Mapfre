/*-----------------------------REXX----------------------------------*\
 *  This Rexx is used by the Endevor shipment process (CJOB &        *
 *  BJOB) to implement & backout files in USS.                       *
 *                                                                   *
 *  An example of the JCL that invokes the REXX can be found in      *
 *  PGOS.BASE.CMJOBS in the members that begin with US*.             *
\*-------------------------------------------------------------------*/
trace n

arg run_type cmr

/* Are we running on the T or S plexes?                              */
plex = MVSVAR(sysplex) /* Which plex are we running on               */
if pos(plex,'PLEXT1 PLEXS1') > 0 then
  host_plex = 'Y'

say 'EVUSS04:'
select /* Validate that only acceptable options are passed           */
  when run_type = 'BJOB' then
    say 'EVUSS04: Back-out log:'
  when run_type = 'CJOB' then
    say 'EVUSS04: Implementation log:'
  otherwise
    call exception 12 'Unknown run type:' run_type
end /* end select                                                    */
say 'EVUSS04:'


/* Cycle through the input file (ELMLIST) processing the COPY        */
/* and/or DELETE statements                                          */

/* Read the element list from the merged shipment datasets           */
"execio * diskr ELMLIST (stem elmlist. finis"
if rc ^= 0 then call exception 12 'DISKR of ELMLIST failed. RC='rc

/* Loop through the element list and action each line                */
do p = 1 to elmlist.0

  action     = word(elmlist.p,1)
  tgt        = word(elmlist.p,2)
  short_name = left(word(elmlist.p,3),8)

  /* For implementation runs only (not backout)...                   */
  /* Dont update the PROD directory on the Tplex as the processor    */
  /* has already done this.                                          */
  if left(tgt,4) = 'PROD' & run_type = 'CJOB' & host_plex = 'Y' then
    iterate

  say 'EVUSS04:' COPIES('-',80)
  say 'EVUSS04: Action     :' action
  say 'EVUSS04: Target     :' tgt
  say 'EVUSS04:'

  tgt_file   = '/RBSG/endevor/'tgt

  /* Work out what the live directory will be for a mkdir if reqd    */
  last_slash = lastpos('/',tgt_file) - 1
  tgt_dir    = left(tgt_file,last_slash)
  /* Work out what the staging directories will be                   */
  stg_file   = '/RBSG/endevor/STAGING/'cmr'/'tgt
  bkup_file  = '/RBSG/endevor/STAGING/B'right(cmr,7)'/'tgt

  if run_type = 'CJOB' then call Implement_change
                       else call Backout_change

  /* On the Tplex the PROD directory needs backing out at the same   */
  /* time as the file is backed out of the BASE directory.           */
  if substr(tgt,6,4) = 'BASE' & ,
     run_type        = 'BJOB' & ,
     host_plex       = 'Y'    then do

    say 'EVUSS04:' COPIES('-',80)
    say 'EVUSS04: Backing out Tplex PROD directory'
    say 'EVUSS04:'

    /* Build up new variables to create the prod directory structure */
    parse value tgt_file with '/RBSG/endevor/' hlq '/BASE/' llqs
    sys      = right(hlq,2)
    tgt_file = '/RBSG/endevor/PROD/P'sys'1/'llqs

    call Backout_change

  end /* if substr(tgt,6,4) = 'BASE' & run_type = 'BJOB' etc...      */

end /* do p = 1 to elmlist.0 */

call write_changedb_info

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Implement Change, copy to /RBSG/endevor/PGxx/BASE/...             */
/*-------------------------------------------------------------------*/
Implement_change:

 select
   when action = 'COPY'   then
     call copy_file
   when action = 'DELETE' then
     call delete_file
   otherwise
     call exception 12 'Invalid action:' action
 end /* select */

return /* Implement_change */

/*-------------------------------------------------------------------*/
/* Backout Change, restore /RBSG/endevor/xxxx/...                    */
/*  from /RBSG/endevor/bkup/xxxx/...                                 */
/*-------------------------------------------------------------------*/
backout_change:

 /* Does the file exist in the backout directory                     */
 command = 'ls' bkup_file
 call bpxwunix command,,Out.,Err.

 if err.0 = 0 then       /* file found                               */
   call copy_file

 else do /* Delete target file                                       */

   say 'EVUSS04: Backup file:' bkup_file
   say 'EVUSS04:'
   say 'EVUSS04: No backout file found'
   say 'EVUSS04:'

   call delete_file

 end /* else */

return /* backout_change */

/*-------------------------------------------------------------------*/
/* Copy file                                                         */
/*-------------------------------------------------------------------*/
Copy_file:

 if run_type = 'CJOB' then
   src_file = stg_file
 else
   src_file = bkup_file

 say 'EVUSS04: Copy from  :' src_file
 say 'EVUSS04:        to  :' tgt_file
 say 'EVUSS04:'

 'bpxbatch sh mkdir -p -m 775' tgt_dir
 'bpxbatch sh rm -f 'tgt_file /* Delete before copy for security     */
 'bpxbatch sh cp -m 'src_file tgt_file
 if rc ^= 0 then call exception rc 'File copy failed.'

 call get_date_time tgt_file /* Get file mod time for change DB      */

 /* Having copied the file the security and owner need to be set     */
 say 'EVUSS04: Change permissions to 755 on' tgt_file
 say 'EVUSS04:'
 'bpxbatch sh chmod -f 755 'tgt_file
 if rc ^= 0 then call exception rc 'chmod failed.'

 if host_plex = 'Y' & substr(tgt_file,15,4) = 'PROD' then
   owner = 'ENDEVOR'
 else
   owner = 'USSDEPP'
 say 'EVUSS04: Change owner to' owner 'on  ' tgt_file
 say 'EVUSS04:'
 'bpxbatch sh chown -f 'owner tgt_file
 if rc ^= 0 then call exception rc 'chown failed.'

 /* Queue change database information                                */
 if host_plex             = 'Y'    & ,
    substr(tgt_file,20,4) = 'BASE' then
   queue short_name 'A' tgt_file file_mod_time

return /* Delete_file */

/*-------------------------------------------------------------------*/
/* Delete file                                                       */
/*-------------------------------------------------------------------*/
Delete_file:

 say 'EVUSS04: Deleting   :' tgt_file
 say 'EVUSS04:'

 /* Does the file exist in the target directory                      */
 command = 'ls' tgt_file
 call bpxwunix command,,Out.,Err.

 if err.0 = 0 then do    /* file found so delete                     */

   call get_date_time tgt_file /* Get file mod time for change DB    */

   'bpxbatch sh rm -f' tgt_file
   if rc ^= 0 then call exception rc 'File delete failed.'

   /* Queue change database information                              */
   if host_plex             = 'Y'    & ,
      substr(tgt_file,20,4) = 'BASE' then
     queue short_name 'D' tgt_file file_mod_time

 end /* err.0 = 0 */

 else do /* No file found to delete?                                 */
   say 'EVUSS04: File not found to delete'
   say 'EVUSS04:'
 end /* else */

return /* Delete_file */

/*-------------------------------------------------------------------*/
/* Get_date_time                                                     */
/*-------------------------------------------------------------------*/
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

 say 'EVUSS04: File modified time:' file_mod_time
 say 'EVUSS04:'

return /* Get_date_time */

/*-------------------------------------------------------------------*/
/* Write USS implementation information for the Change DB            */
/*-------------------------------------------------------------------*/
Write_changedb_info:

 info_dsn = 'PGEV.SHIP.'left(run_type,1)||right(cmr,7)'.USSINFO'

 say 'EVUSS04:' COPIES('-',80)
 say 'EVUSS04:'
 say 'EVUSS04: Writing USS file implementation log to'
 say 'EVUSS04: ' info_dsn

 /* Delete the USSINFO file in case this is a re-run                 */
 test = msg(off)
 "DELETE '"info_dsn"'"
 test = msg(on)

 "ALLOC F(USSINFO) DA('"info_dsn"') NEW" ,
 " CATALOG SPACE(2 15) TRACKS RECFM(F B) LRECL(300) BLKSIZE(0)"
 if rc ^= 0 then call exception rc 'ALLOC of' info_dsn 'failed'

 "execio" queued() "diskw USSINFO (finis"
 if rc ^= 0 then call exception rc 'DISKW to USSINFO failed.'

 "FREE f(USSINFO)"

return /* write_changedb_info */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 call write_changedb_info

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

/*-----------------------------REXX----------------------------------*\
 *  Reads a list of Cjobs on queue then opens all shipment           *
 *  datasets, sets the mod time of USS staging directories, and      *
 *  updates the C and BJOB JCL for each Cjob on queue so that the    *
 *  last referrenced date or accessed date is updated and the        *
 *  datasets/directories/JCL do not get deleted.                     *
\*-------------------------------------------------------------------*/
trace n

signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

call syscalls 'ON'

jobname = mvsvar('SYMDEF','JOBNAME')
if left(jobname,2) = 'TT' then cmhlq = 'TTEV'
                          else cmhlq = 'PGOS'

li_count= 0 /* Counter for LMDLIST dataset ids                       */
sysplex = mvsvar('sysplex')

if sysplex = 'PLEXE1' then wizhlq = 'PREV'
                      else wizhlq = 'PGEV'

today = date('S')
today = left(today,4)'/'substr(today,5,2)'/'right(today,2)
say 'REFER: Todays date is' today
say 'REFER:'

/* Read the list of Cjobs on the CA7 queue                           */
"execio * diskr CA7OUT (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of DDname CA7OUT failed'

do i = 7 to line.0 /* Loop through the Cjobs on queue                */
  if left(word(line.i,1),2) = 'C0' then do
    cjob = word(line.i,1)
    bjob = overlay('B',word(line.i,1))
    say 'REFER: Processing' cjob

    /* Update the changed date for the B & Cjobs                     */
    call update_cmjob cjob
    call update_cmjob bjob

    /* Set the modified time on the staging directories              */
    call setmod_ussdir cjob
    call setmod_ussdir bjob

    /* Get the PGEV.SHIP.D*.T* hlq from PGOS.BASE.CMJOBS(cjob)       */
    call read_cjob

    /* Get the shipment dataset lists                                */
    ds_count = 0 /* Total number of shipment datasets to read        */
    call get_dslists
    dsns.0   = ds_count

    /* Read each dataset to set the referred date                    */
    do zz = 1 to dsns.0
      say 'REFER:  ' dsns.zz
      if word(dsns.zz,3) = today then
        say 'REFER:   Refdate = today. Skipping'
      else
        call refer_dsn dsns.zz
    end /* zz = 1 to dsns.0 */
    say 'REFER:'
  end /* left(word(line.i,1),2) = 'C0' */

end /* i = 1 to line.0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Update_cmjob - Set the changed date on the B or Cjob JCL          */
/*-------------------------------------------------------------------*/
update_cmjob:
 arg mem

 "ispexec edit dataset('"cmhlq".BASE.CMJOBS("mem")') macro(cmjobupd)"
 if rc ^= 0 then call exception rc 'EDIT of' mem 'failed'
 say 'REFER:  ' cmhlq'.BASE.CMJOBS('mem') updated'

return /* update_cmjob: */

/*-------------------------------------------------------------------*/
/* setmod_ussdir - Set mod time of uss staging dir if it exists      */
/*-------------------------------------------------------------------*/
setmod_ussdir:
 arg dir

 stg_dir = '/RBSG/endevor/STAGING/'dir

 /* Does the directory exist?                                        */
 command = 'ls' stg_dir
 call bpxwunix command,,Out.,Err.
 if rc ^= 0 then call exception rc 'bpxwunix' command 'failed'

 if err.0 > 0 then
   say 'REFER:   No directories found for:' stg_dir
 else do
   command = 'find' stg_dir '-type d'
   call bpxwunix command,,Out.,Err.
   if rc ^= 0 then call exception rc 'bpxwunix' command 'failed'
   do cc = 1 to out.0
     command = 'touch' word(out.cc,1)
     call bpxwunix command,,Out.,Err.
     if rc ^= 0 then call exception rc 'bpxwunix' command 'failed'
     say 'REFER:  ' out.cc 'mod time set'
   end /* cc = 1 to out.0 */
 end /* else */

return /* setmod_ussdir: */

/*-------------------------------------------------------------------*/
/* Read_cjob - Read the Cjob to get the shipment ds hlq              */
/*-------------------------------------------------------------------*/
read_cjob:

 "alloc f(cjob) dsname('"cmhlq".BASE.CMJOBS("cjob")') shr"
 if rc ^= 0 then call exception rc 'ALLOC CMJOBS('cjob') failed'
 "execio * diskr cjob (stem cjob. finis"
 if rc ^= 0 then call exception rc 'DISKR of CMJOBS('cjob') failed'
 "free fi(cjob)"

 ship_hlqs = ''
 do x = 1 to cjob.0
   if word(cjob.x,2) = 'SHIPHLQS' then do
     ship_hlqs = word(cjob.x,3)
     say "REFER:   Shiphlqs = '"ship_hlqs"'"
     leave
   end /* word(cjob.x,2) = 'SHIPHLQS' */
 end /* x = 1 to cjob.0 */

return /* read_cjob: */

/*-------------------------------------------------------------------*/
/* Get_dslists - Get the list of datasets for each change            */
/*-------------------------------------------------------------------*/
get_dslists:

 if ship_hlqs ^= '' then
   call get_dslist ship_hlqs
 else
   say 'REFER:   No IEBCOPY step for:' cjob
 call get_dslist 'PGEV.SHIP.'cjob
 call get_dslist 'PGEV.SHIP.'bjob
 call get_dslist wizhlq'.PO*.*.'cjob
 call get_dslist wizhlq'.PO*.*.'bjob
 if sysplex = 'PLEXC1' then
   call get_dslist 'PGEV.LY1.'cjob
 if sysplex = 'PLEXD1' then
   call get_dslist 'PGEV.LG1.'cjob

return /* get_dslists: */

/*-------------------------------------------------------------------*/
/* Get_dslist - Get the list of datasets for each hlq                */
/*-------------------------------------------------------------------*/
get_dslist:
 arg hlqs

 li_count = li_count + 1
 li       = 'L'li_count

 address ispexec
 "LMDINIT LISTID(LISTID) LEVEL("hlqs")"
 if rc ^= 0 then call exception rc 'LMDINIT of' hlqs 'failed.'

 "LMDLIST LISTID("listid") OPTION(LIST) DATASET("li") STATS(YES)"
 if rc > 0 then
   say 'REFER:   No data sets   found for:' hlqs

 do zz = 1 while rc = 0
   ldsn = value(li)
   if zdlvol         <> '*VSAM*'       & ,
      right(ldsn,12) <> 'PROCESS.FILE' then do
     if left(hlqs,11) = 'PGEV.SHIP.D' then do
       if (sysplex = 'PLEXE1' & ,
           pos('PLEXE1',ldsn) > 0)  | ,
           sysplex      ^= 'PLEXE1' | ,
           right(ldsn,3) = '.FP'    then do
         /* On the Qplex only refer Qplex datasets                   */
         /* N.B. Cloned datasets have the source plex name in        */
           ds_count      = ds_count + 1
           dsns.ds_count = left(ldsn,45) zdldsorg zdlrdate zdlrecfm
       end /* sysplex = 'PLEXE1' & .. .*/
       else nop
     end /* left(hlqs,11) = 'PGEV.SHIP.D' */
     else do
       ds_count      = ds_count + 1
       dsns.ds_count = left(ldsn,45) zdldsorg zdlrdate zdlrecfm
     end /* else */
   end /* zdlvol <> '*VSAM*' & ... */
   "LMDLIST LISTID("listid") OPTION(LIST) DATASET("li") STATS(YES)"
 end /* zz = 1 while rc = 0 */

 "LMDLIST LISTID("listid") OPTION(FREE)"
 "LMDFREE LISTID("listid")"

 address tso

return /* get_dslist: */

/*-------------------------------------------------------------------*/
/* Refer_dsn - Set the dataset referred date                         */
/*-------------------------------------------------------------------*/
refer_dsn:
 arg dsn dsorg refer recfm
 say 'REFER:    Setting referred date'

 if dsorg = 'VS' then
   call idcams
 else do
   address ispexec
   "LMINIT DATAID(LISTID) dataset('"dsn"') enq(shr)"
   if rc ^= 0 then call exception rc 'LMINIT of' listid dsn 'failed'
   "LMOPEN DATAID("listid") OPTION(input)"
   if rc ^= 0 then call exception rc 'LMOPEN of' listid dsn 'failed'
   "LMCLOSE DATAID("listid")"
   if rc ^= 0 then call exception rc 'LMCLOSE of' listid dsn 'failed'
   "LMFREE DATAID("listid")"
   if rc ^= 0 then call exception rc 'LMFREE of' listid dsn 'failed'
   say 'REFER:    LMOPEN complete'
   address tso
 end /* else */

return /* refer_dsn: */

/*-------------------------------------------------------------------*/
/* IDCAMS  - Use IDCAMS EXAMINE to read the VSAM file                */
/*-------------------------------------------------------------------*/
idcams:

 test=msg(off)
 "free f(sysin sysprint)"
 test=msg(on)

 "alloc f(sysin) new space(2 2) cylinders recfm(f b) lrecl(80)"
 queue "  EXAMINE  NAME('"dsn"')"
 "execio 1 diskw sysin (finis)"
 if rc ^= 0 then call exception rc 'DISKW to SYSIN failed'

 "alloc f(sysprint) new space(2 2) cylinders recfm(f b) lrecl(133)"
 "call 'sys1.linklib(idcams)'"
 if rc > 12 then call exception rc 'EXAMINE of' dsn 'failed'
 /* RC 12 expected but referred date is set anyway                   */
 "free f(sysin sysprint)"

 say 'REFER:    EXAMINE complete'

return /* idcams */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso "FREE F(in cjob sysin sysprint)"
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit return_code

/*-----------------------------REXX----------------------------------*\
 *  Split output from the PDMS37 compare suite.                      *
 *                                                                   *
 *  Executed by : JOB EVGCMP3W                                       *
\*-------------------------------------------------------------------*/
trace n

arg stack_size hlq_pref sum_pref

say
say 'CMPSUMM:' DATE() TIME()
say 'CMPSUMM:  *** Input parameters ***'
say 'CMPSUMM:'
say 'CMPSUMM:  stack_size.' stack_size
say 'CMPSUMM:  hlq_pref...' hlq_pref
say 'CMPSUMM:  sum_pref...' sum_pref

exit_rc    = 0       /* Flag for errors found                        */
errors     = 0       /* Flag for errors found                        */
prev_llq   = ''      /* Previous llq                                 */
sum_count  = 0       /* Number or summary dsns                       */

/* Read the list of Cjobs on the CA7 queue                           */
"execio * diskr CJOBS (stem cjob. finis)"
if rc ^= 0 then call exception rc 'DISKR from CJOBS failed'
say
say 'CMPSUMM: There are' cjob.0 'Cjobs on queue'
say 'CMPSUMM: Building stem variables to exclude in progress members.'
do i = 1 to cjob.0
  cjob = substr(cjob.i,2,8)
  call read_xref_datasets cjob
  call read_xref_datasets 'B'substr(cjob,2,7)
end /* i = 1 to cjob.0 */

say
say
say 'CMPSUMM: Summarising the PDSM37 report output'
say 'CMPSUMM:'

mismatches = 0       /* Mismatch found                               */
started    = 0       /* Found 1st COMPARING line                     */
count      = 0       /* Number of output lines                       */
eof        = 0       /* end of file flag                             */

do forever
  call read_line     /* read a line from the report file             */
  if eof then leave

  if left(line,7) = '1PDSMAN' | ,
     left(line,3) = ' **'     then /* Ignore headers                 */
    iterate

  /* Found an inprogress member so skip all related lines            */
  /* Until we get to the next member name                            */
  if skip = 'Y' & substr(line,2,1)= ' ' then
    iterate
  else
    skip = 'N'

  if substr(line,2,9) = 'COMPARING' then do
    started = 1      /* 1st line after the SELECTS                   */

    if mismatches then /* If we found a mismatch                     */
      call write       /* then write out all the output              */
    else do            /* No mismatches                              */
      drop out.        /* so clear the output stem                   */
      count = 0        /* and reset the output counter               */
    end /* else */

    /* Read through all COMPARING DSN header lines                   */
    do until substr(line,57,3) ^= 'OS '
      dsn = word(substr(line,69),1)
      parse value dsn with hlq'.'mlq'.'llqs rest
      if length(llqs) > 9 then do
        llqs = left(llqs,9)
        llqs = strip(llqs,,'.')
      end /* length(llqs) > 9 */
      select /* Get the main dataset name from the COMPARE header    */
        when substr(dsn,6,4) = 'BASE' then  do
          write_llq = substr(dsn,3,2)'.BASE.'llqs
          leave
        end /* substr(dsn,6,4) = 'BASE' */
        when substr(dsn,3,2) = 'EV' then do
          write_llq = substr(dsn,7,2)'.PGEV.'llqs
          dsn = overlay('G',dsn,2) /* make it PGEV not PREV          */
        end /* substr(dsn,3,2) = 'EV' */
        otherwise /* just take the first qualifier                   */
          write_llq = hlq'.'llqs
      end /* select */
      count = count + 1
      out.count = line /* Build output for all lines                 */
      call read_line   /* Get the next line                          */
      if eof then call exception 12 'EOF reading DSN headers????'
    end /* until substr(line,57,3) ^= 'OS ' */

  end /* word(line,1) = 'COMPARING' */

  /* Add the line to the output stem varibale                        */
  if started then do
    count = count + 1
    out.count = line /* Build output for all lines                   */
  end /* started */
  else
    iterate /* carry on until we reach the first 'COMPARING'         */

  /* Find relevant lines */
  if substr(line,40,1) ^= ' ' & substr(line,57,3) = 'OS ' & ,
     substr(line,2,1)  ^= ' ' then do
    member = strip(word(line,1),l,'0') /* Remove printer cntl char   */
    /* Ignore the member mismatch if a change is in progress         */
    if symbol(member) ^= 'BAD' then
      zz = value(dsn'.'member)
    else
      zz = 'ignore'
    if zz ^= 'inprogress' then
      mismatches = 1
    else do
      count = count - 1 /* Dont print out this line                  */
      skip = 'Y'        /* Dont print out any more related lines     */
      say 'CMPSUMM:  Ignoring in-progress' dsn'('member')'
    end /* else */
  end /* substr(line,40,1) ^= ' ' & ... its a valid line */

end /* do forever */

/* One last time before we finish                                    */
if mismatches then
  call write
else
  drop out.

/* Write out the summary dataset list for the email                  */
if exit_rc = 1 then do
  "execio" sum_count "diskw SUMLIST (stem summary_dsn."
  if rc > 1 then call exception rc 'DISKW to SUMLIST failed'
end /* exit_rc = 1 */

say ' '
say 'cmpsumm: ' date() time()

exit exit_rc

/*---------------------- s u b r o u t i n e s ----------------------*/

/*-------------------------------------------------------------------*/
/* read the change database xref datasets to get the footprint       */
/* dataset names and the target dataset names.                       */
/*-------------------------------------------------------------------*/
read_xref_datasets:

 arg job

 a = outtrap("xref_dsns.",'*',concat)
 "listc level('PGEV.SHIP."job"') names"
 if rc ^= 0 then call exception rc 'listcat failed for PGEV.SHIP.'job

 do x = 1 to xref_dsns.0

   if word(xref_dsns.x,1) = 'NONVSAM' then do
     xref_dsn = "'"word(xref_dsns.x,3)"'"
     if right(xref_dsn,5) ^= "XREF'" then iterate
     say
     say 'CMPSUMM: Reading ***' xref_dsn  '***'
     say 'CMPSUMM:'

     "alloc fi(XREF) da("xref_dsn") shr"
     if rc ^= 0 then call exception rc 'Alloc of' xref_dsn 'failed'

     "execio * diskr XREF (stem xref. finis)"
     if rc ^= 0 then call exception rc 'DISKR of' xref_dsn 'failed'

     "free fi(XREF)"
     if rc ^= 0 then call exception rc 'Free of ddname XREF failed'

     /* Read the xref to get staging DSNs                            */
     /* Read the staging dsn.FP dataset and build stem var           */
     /* for each member listed                                       */
     do y = 1 to xref.0
       stem = word(xref.y,1)
       if left(stem,6) = 'fpdsn.' then do
         tgt_dsn = substr(stem,7)
         fp_dsn  = "'"word(xref.y,3)"'"
         call build_stem
       end /* left(stem,6) = 'fpdsn.' */
     end /* y = 1 to xref.0 */
   end /* word(xref_dsns.x,1) = 'NONVSAM' */

 end /* x = 1 to xref.0 */

return /* Read_xref_datasets */

/*-------------------------------------------------------------------*/
/* Build stem variables for members in progress                      */
/*-------------------------------------------------------------------*/
build_stem:

 say 'CMPSUMM:  Reading' fp_dsn

 "alloc fi(FP) da("fp_dsn") shr"
 if rc ^= 0 then call exception rc 'Alloc of' fp_dsn 'failed'

 "execio * diskr FP (stem fp. finis)"
 if rc ^= 0 then call exception rc 'DISKR of' fp_dsn 'failed'

 "free fi(FP)"
 if rc ^= 0 then call exception rc 'Free of ddname FP failed'

 /* Read the footprint dataset and build stem var for each member    */
 do z = 1 to fp.0
   mem = word(fp.z,2)
   say tgt_dsn'('mem') - inprogress'
   interpret tgt_dsn"."mem "= 'inprogress'"
 end /* z = 1 to fp.0 */

 say 'CMPSUMM:'

return /* build_stem */

/*-------------------------------------------------------------------*/
/* Read_line & strip comments                                        */
/*-------------------------------------------------------------------*/
read_line:

 if queued() = 0 then do
   /* N.B. Stack size is used to make the code more efficient        */
   "execio" stack_size "diskr RESULTS"
   if rc > 2 then call exception rc 'DISKR from RESULTS failed'
   if rc = 2 & , /* EOF                                              */
      queued() = 0 then do
     "execio 0 diskr RESULTS (finis"   /* close the file             */
     eof = 1
     return
   end /* rc = 2 & queued() = 0 */
 end /* queued() = 0 */

 pull line

return /* read_line */

/*-------------------------------------------------------------------*/
/* Write to the summary dataset                                      */
/*-------------------------------------------------------------------*/
write:

 exit_rc = 1 /* mismatches so set email trigger                      */

 summary_dsn = "'"hlq_pref'EV.NENDEVOR.COMPARE.'sum_pref'.'write_llq"'"
 sum_count   = sum_count + 1
 summary_dsn.sum_count = strip(summary_dsn,,"'")
 x = sysdsn(summary_dsn)
 if x ^= 'OK' then do
   say 'CMPSUMM: Allocating' summary_dsn
   "alloc fi(SUMMARY) da("summary_dsn") space(5,45)",
   "tracks lrecl(133) dsorg(ps) recfm(f b a)"
 end /* x ^= 'OK' */
 else do
   say 'CMPSUMM: Allocating' summary_dsn '*** DISP=MOD ***'
   "alloc fi(SUMMARY) da("summary_dsn") mod"
 end /* else */
 if rc ^= 0 then call exception rc 'Alloc of' summary_dsn 'failed'

 prev_llq = write_llq

 "execio" count "diskw SUMMARY (stem out."
 if rc > 1 then call exception rc 'DISKW to SUMMARY failed'
 count = 0
 drop out.

 mismatches = 0

 call close_summary

return /* write */

/*-------------------------------------------------------------------*/
/* Close SUMMARY                                                     */
/*-------------------------------------------------------------------*/
Close_summary:

 say 'CMPSUMM: Closing   ' summary_dsn
 say 'CMPSUMM:'

 "execio 0 diskw SUMMARY (finis"
 if rc ^= 0 then call exception rc 'DISKW to SUMMARY failed'

 "free fi(SUMMARY)"
 if rc ^= 0 then call exception rc 'FREE file SUMMARY failed'

return /* Close_summary */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
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

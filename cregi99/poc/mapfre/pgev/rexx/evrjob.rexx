/*-- REXX -----------------------------------------------------------*/
/*-                                                                 -*/
/*-  This is invoked when EVL0000D runs.                            -*/
/*-  It checks if there are any sequential files created by CMSSUB  -*/
/*-  and if there are it moves the Rjob JCL to PGOS.BASE.CMJOBS     -*/
/*-  and creates a full stream of commands for the batch terminal   -*/
/*-  step.                                                          -*/
/*-                                                                 -*/
/*-  Calls:      Rexx      - None                                   -*/
/*-              Skeletons - None                                   -*/
/*-                                                                 -*/
/*-------------------------------------------------------------------*/
/*-  Changed: Stuart Ashby 25th January 2007                        -*/
/*-           Amend comments and SAY statements                     -*/
/*-                                                                 -*/
/*-------------------------------------------------------------------*/
trace n
rjobdsn = 'TTMV.NENDEVOR.RELEASE.RJOB'
ca7dsn =  'TTMV.NENDEVOR.RELEASE.BTERM'

jobs = 0   /* Counter for number of Rjobs           */
ca7  = 0   /* Counter for number of batch terminals */

address ispexec
/*   Prepare PGOS.BASE.CMJOBS dataset for LMMOVES                 */
"LMINIT DATAID(TARGET)  DATASET('PGOS.BASE.CMJOBS') ENQ(SHR)"
if rc ^= 0 then call exception 16 'LMINIT of PGOS.BASE.CMJOBS failed' rc

/*   Get the names of the RJOB sequential files                      */
a = outtrap('rjob.','*',concat)
address tso "LISTC LEVEL('"rjobdsn"') NAMES"
a = outtrap('off')

do x=1 to rjob.0 /* display the output from the listcat              */
  say rjob.x
end /* do x=1 to rjob.0                                              */

if rc = 4 then do
  say 'EVRJOB: LISTC of' rjobdsn '= 4'
  say 'EVRJOB: No datasets to process'
  zispfrc = 4
  "vput (zispfrc) shared"
  exit 4
end /* rc = 4 */
if rc ^= 0 then call exception 16 'Return code from LISTC is' rc

/*   Process the RJOB datasets                                       */
do i = 1 to rjob.0 /* loop through the listcat output                */

  if pos(rjobdsn,rjob.i) > 1 then do
    jobs = jobs + 1
    rmem = 'R'substr(rjob.i,45,7)      /* Rjob name */
    cmr  = 'C'substr(rjob.i,45,7)      /* Change number */
    dsn  = rjobdsn'.'cmr               /* Input dataset */

    say 'EVRJOB:'
    say 'EVRJOB: Moving file' dsn
    say 'EVRJOB: into PGOS.BASE.CMJOBS member' rmem

    "LMINIT DATAID(SOURCE) DATASET('"dsn"') ENQ(SHR)"
    if rc ^= 0 then do
      call wait 60  /* Wait and try again */
      "LMINIT DATAID(SOURCE) DATASET('"dsn"') ENQ(SHR)"
      if rc ^= 0 then call exception 16 'LMINIT of' dsn 'failed RC='rc
    end /* rc ^= 0 */

    "LMMOVE FROMID("source") TODATAID("target") TOMEM("rmem") REPLACE"
    if rc ^= 0 then call exception 16 'LMMOVE failed, investigate RC='rc

    "LMFREE Dataid("source")"
    if rc ^= 0 then call exception 16 'LMFREE of' source 'failed RC='rc

  end /* if pos(rjobdsn,rjob.i) > 1 then do */

end /* do i=1 to rjob.0                                              */

/*   LMFREE the PGOS.BASE.CMJOBS dataset                             */
"LMFREE Dataid("target")"
if rc ^= 0 then call exception 16 'LMFREE of' target 'failed RC='rc

say 'EVRJOB:'
say 'EVRJOB:' jobs 'file(s) have been found to move to CMJOBS'

address tso

/*   Process the batch terminal datasets                             */
do i = 1 to rjob.0     /* loop through the Rjob listcat output again */

  if pos(rjobdsn,rjob.i) > 1 then do /* use rjob.i just incase another  */
                                     /* change record has been assigned */
    ca7 = ca7 + 1
    cmr = 'C'substr(rjob.i,45,7)     /* Change number */
    dsn = ca7dsn'.'cmr               /* Input dataset */

    say 'EVRJOB:'
    say 'EVRJOB: Moving file' dsn
    say 'EVRJOB: into temporary CA7 batch terminal dataset'

    "ALLOC F(BTCHCRD) DSNAME('"dsn"') SHR"      /* Allocate CA7 cards */
    if rc ^= 0 then do
      call wait 60  /* Wait and try again */
      "ALLOC F(BTCHCRD) DSNAME('"dsn"') SHR"
      if rc ^= 0 then call exception 16 'Alloc of' DSN 'failed RC='rc
    end /* rc ^= 0 */

    'EXECIO * DISKR BTCHCRD (STEM CARDS. FINIS' /* Read in all the records */
    if rc ^= 0 then call exception 16 'EXECIO read of' dsn 'failed RC='rc

    "FREE F(BTCHCRD)"                           /* free the allocation */

    do k = 1 to cards.0
      queue cards.k      /* put each record in to buffer */
    end

    "ISPEXEC LMERASE DATASET('"dsn"') PURGE(YES)"
    if rc ^= 0 then call exception 16 'LMERASE of' dsn 'failed RC='rc

  end /* if pos(rjobdsn,rjob.i) > 1 then do */

end /* do i=1 to rjob.0                                              */

"execio * diskw ca7cards (finis"  /* write out to merged dataset */
if rc ^= 0 then call exception 16 'DISKW to CA7CARDS failed RC='rc

say 'EVRJOB:'
say 'EVRJOB:' ca7 'file(s) have been copied for the batch terminal step'
exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/* +---------------------------------------------------------------+ */
/* | Just wait for a while                                         | */
/* +---------------------------------------------------------------+ */
wait:
 arg wait_time

 say 'EVRJOB:' time() dsn 'in use, waiting' wait_time 'seconds'
 call syscalls('ON')
 address syscall "sleep" wait_time
 call syscalls('OFF')

return

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 parse arg return_code comment

 if queued() > 0 then
   "execio * diskw ca7cards (finis"  /* write out to merged dataset */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname': Return code is' return_code
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit 12

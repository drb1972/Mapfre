/*-- REXX -----------------------------------------------------------*/
/*-                                                                 -*/
/*-  This is invoked when EVL0300D runs.                            -*/
/*-  It checks if there are any sequential files created by abort,  -*/
/*-  backout, or re-schedule processing.                            -*/
/*-  If there are it moves the utility JCL to PGOS.BASE.CMJOBS      -*/
/*-  and creates a full stream of commands for the batch terminal   -*/
/*-  step.                                                          -*/
/*-                                                                 -*/
/*-  Calls:      Rexx      - None                                   -*/
/*-              Skeletons - None                                   -*/
/*-                                                                 -*/
/*-------------------------------------------------------------------*/
trace n

mjobdsn = 'TTMV.NENDEVOR.UTILITY.MJOB'
ca7dsn  = 'TTMV.NENDEVOR.UTILITY.BTERM'

/* initialise variables                                              */
jobs = 0 /* A counter for the number of JCL datasets found           */
ca7  = 0 /* A counter for the number of CA7 datasets found           */
rsch = 0 /* set when reschedule is found in the Mjob JCL             */

address ispexec
/* Prepare PGOS.BASE.CMJOBS dataset for LMMOVES                      */
"LMINIT DATAID(TARGET) DATASET('PGOS.BASE.CMJOBS') ENQ(SHR)"
if rc ^= 0 then call exception rc 'LMINIT of PGOS.BASE.CMJOBS failed' rc

address tso
/* Get the names of the MJOB sequential files                        */
a = outtrap("MJOB.",'*',concat)
"LISTC LEVEL('"mjobdsn"') NAMES" /* idcams listcat of datasets       */
a = outtrap('off')

do x = 1 to mjob.0 /* display the output from the listcat            */
  say mjob.x
end /* do x = 1 to mjob.0                                            */

address ispexec
if rc = 4 then do
  say 'EVMJOB: LISTC of' Mjobdsn '= 4'
  say 'EVMJOB: No datasets to process'
  zispfrc = 4
  "vput (zispfrc) shared"
  exit 4
end /* rc = 4 */
if rc ^= 0 then call exception 16 'Return code from LISTC is' rc

/* Process the MJOB datasets                                         */
do i = 1 to mjob.0 /* loop through the listcat output                */

  if pos(mjobdsn,mjob.i) > 1 then do
    jobs = jobs + 1
    mmem = 'M'substr(mjob.i,45,7) /* Mjob name                       */
    cmr  = 'C'substr(mjob.i,45,7) /* Change number                   */
    dsn  = mjobdsn'.'cmr          /* Input dataset                   */
    say 'EVMJOB: MJOB dsn:' dsn

    address tso
    /* Allocate and read the MJOB                                    */
    "ALLOC F(MJOBJCL) DSNAME('"dsn"') SHR" /* Allocate JCL           */
    if rc ^= 0 then call exception rc 'Alloc of' dsn 'failed'

    'EXECIO * DISKR MJOBJCL (STEM MJCL. FINIS' /* Read all records   */
    if rc ^= 0 then call exception rc 'EXECIO read of' dsn 'failed'

    "FREE F(MJOBJCL)" /* free the allocation                         */
    if rc ^= 0 then call exception rc 'FREE of MJOBJCL failed'

    do a = 1 to mjcl.0 /* loop through the Mjob JCL                  */
      if pos('RESCHEDULE',mjcl.a) > 0 then rsch = 1 /* reschedule?   */
    end /* do a = 1 to mjcl.0                                        */

    if rsch = 0 then do /* this is not a re-schedule action          */

      /* Are there any archive datasets for restore                  */
      arcdsn = 'PGEV.SHIP.'cmr'.ARCHIVE.ARCHREST' /* set the dsname  */

      b = outtrap("ARCH.",'*',concat)
      "LISTC ENTRIES('"arcdsn"') ALL"

      if rc = 0 then do /* Archive dataset found                     */
        say 'EVMJOB: Archive JCL found:' arcdsn

        address ispexec
        /* allocate the arch restore dataset                         */
        "LMINIT DATAID(FROM) DATASET('"arcdsn"') ENQ(SHR)"
        if rc ^= 0 then call exception rc 'LMINIT of' arcdsn 'failed'

        /* allocate the JCL dataset                                  */
        "LMINIT DATAID(TO) DATASET('"dsn"') ENQ(MOD)"
        if rc ^= 0 then call exception rc 'LMINIT of' arcdsn 'failed'

        /* Copy from the arch restore dataset to the Mjob dataset    */
        "LMCOPY FROMID("from") TODATAID("to")"
        if rc ^= 0 then call exception rc 'LMCOPY to' dsn 'failed'

        /* release the arch restore dataset                          */
        "LMFREE Dataid("from")"
        if rc ^= 0 then call exception rc 'LMFREE of' arcdsn 'failed'

        say 'EVMJOB: Archive JCL added to Mjob'

        /* release the Mjob dataset                                  */
        "LMFREE Dataid("to")"
        if rc ^= 0 then call exception rc 'LMFREE of' dsn 'failed'

        /* delete the arch restore dataset                           */
        "LMERASE DATASET('"arcdsn"') PURGE(YES)"
        if rc ^= 0 then call exception rc 'LMERASE of' arcdsn 'failed'

      end /* if rc = 0 then do                                       */

    end /* if rsch = 0 then do                                       */

    say 'EVMJOB:'
    say 'EVMJOB: Moving file' dsn
    say 'EVMJOB: in to PGOS.BASE.CMJOBS member' mmem

    address ispexec
    "LMINIT DATAID(SOURCE) DATASET('"dsn"') ENQ(SHR)"
    if rc ^= 0 then do
      call wait 60 /* Wait and try again                             */
      "LMINIT DATAID(SOURCE) DATASET('"dsn"') ENQ(SHR)"
      if rc ^= 0 then call exception rc 'LMINIT of' dsn 'failed'
    end /* rc ^= 0                                                   */

    "LMMOVE FROMID("source") TODATAID("target") TOMEM("mmem") REPLACE"
    if rc ^= 0 then call exception rc 'LMMOVE to' target 'failed'

    "LMFREE Dataid("source")"
    if rc ^= 0 then call exception rc 'LMFREE of' source 'failed'

  end /* if pos(mjobdsn,mjob.i) > 1 then do                          */

  rsch = 0 /* reset the counter for re-schedule jobs                 */

end /* do i = 1 to mjob.0                                            */

address ispexec
/* LMFREE the PGOS.BASE.CMJOBS dataset                               */
"LMFREE Dataid("target")"
if rc ^= 0 then call exception rc 'LMFREE of' target 'failed'

say 'EVMJOB:'
say 'EVMJOB:' jobs 'file(s) have been found to move to CMJOBS'

address tso

/* Process the batch terminal datasets                               */
do i = 1 to mjob.0 /* go through the Mjob listcat output again       */

  if pos(mjobdsn,mjob.i) > 1 then do /* use mjob.i incase another    */
                                     /* CMR has been assigned        */
    ca7 = ca7 + 1
    cmr = 'C'substr(mjob.i,45,7) /* Change number                    */
    dsn = ca7dsn'.'cmr /* Input dataset                              */

    say 'EVMJOB:'
    say 'EVMJOB: Moving file' dsn
    say 'EVMJOB: in to temporary CA7 batch terminal dataset'

    "ALLOC F(BTCHCRD) DSNAME('"dsn"') SHR" /* Allocate CA7 cards     */
    if rc ^= 0 then do
      call wait 60  /* Wait and try again                            */
      "ALLOC F(BTCHCRD) DSNAME('"dsn"') SHR"
      if rc ^= 0 then call exception rc 'Alloc of' DSN 'failed'
    end /* rc ^= 0 */

    'EXECIO * DISKR BTCHCRD (STEM CARDS. FINIS' /* Read all records  */
    if rc ^= 0 then call exception rc 'EXECIO read of' dsn 'failed'

    "FREE F(BTCHCRD)" /* free the allocation                         */
    if rc ^= 0 then call exception rc 'FREE of BTCHCRD failed'

    do k = 1 to cards.0
      queue cards.k /* put each record in to buffer                  */
    end

    "ISPEXEC LMERASE DATASET('"dsn"') PURGE(YES)"
    if rc ^= 0 then call exception rc 'LMERASE of' dsn 'failed'

  end /* if pos(mjobdsn,mjob.i) > 1 then do                          */

end /* do i = 1 to mjob.0                                            */

"execio * diskw ca7cards (finis" /* write out to merged dataset      */
if rc ^= 0 then call exception rc 'Write to DDname CA7CARDS failed'

say 'EVMJOB:'
say 'EVMJOB:' ca7 'file(s) have been copied to batch terminal step'

exit

/*-------------------------------------------------------------------*/       */
/*                  S U B R O U T I N E S                            */
/*-------------------------------------------------------------------*/

/* +---------------------------------------------------------------+ */
/* | Just wait for a while                                         | */
/* +---------------------------------------------------------------+ */
wait:
 arg wait_time

 say 'EVMJOB:' time() dsn 'in use, waiting' wait_time 'seconds'
 call syscalls('ON')
 address syscall "sleep" wait_time
 call syscalls('OFF')

return

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 parse arg return_code comment

 /* write the current cards anyway                                   */
 "execio * diskw ca7cards (finis"  /* write out to merged dataset    */

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname': Return code is' return_code
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

 zispfrc = return_code
 address ispexec "VPUT (ZISPFRC) SHARED"

exit

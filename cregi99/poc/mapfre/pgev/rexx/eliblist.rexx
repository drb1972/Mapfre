/*------------------------------ REXX -------------------------------*\
 * ELIBLIST - Automates the re-organisation of the datasets coded    *
 * in PREV.REPORTS.FIXUP                                             *
 *                                                                   *
 * Is is called by EVGELB4I                                          *
\*-------------------------------------------------------------------*/
trace n

Arg prefix auto /* work file hlq & run jobs now?                     */

sysuid  = sysvar(sysuid) /* userid of job submitter                  */

/* set userid the job will run under                                 */
if prefix = 'PGEV' then do
  user  = 'HKPGEND'
  ndvr  = 'PGEV.BASE'
  class = 'N'
  jpfx  = 'EVGE'
  mcls  = 'Y'
end /* if prefix = 'PGEV' then do                                    */
else do
  user  = sysuid
  ndvr  = 'PREV.FEV1'
  class = '3'
  jpfx  = 'TTEV'
  mcls  = '0'
end /* else do                                                       */

waittime = 10 /*  time to sleep when waiting for jobs to finish      */
waitnum  = 500 /* number of sleeps before giving up                  */
waits = 0

ADDRESS tso

/* read in the CSV file                                              */
"execio * diskr report (stem report. finis"
if rc ^= 0 then call exception rc 'Read of DDname REPORT failed'

/* loop through each record, to check the definitions                */
do a = 1 to report.0
  prod = 'N' /* reset flag for every dataset                         */

  parse value report.a with dsn ',' alc ',' used ',' free ',' mems ',' odir ',',
  love ',' xtnd ',' xtnt ',' pgal ',' avgp ',' pguse ',' dpag ',' pgcyl ',',
  secal ',' secyl ',' reslm rest

  select /* find the dataset name in case it isn't CSV               */
    when pos(' has ',dsn) > 0 then do
      x   = pos(' has ',dsn)
      dsn = substr(dsn,1,x)
      csv = 'N'
    end /* when pos(' has ',dsn) > 0 then do */
    when pos(' is < ',dsn) > 0 then do
      x   = pos(' is < ',dsn)
      dsn = substr(dsn,1,x)
      csv = 'N'
    end /* when pos(' is le',dsn) > 0 then do */
    otherwise nop
  end /* end select */

  /* Remove any spaces                                               */
  dsn   = strip(dsn)
  desc  = substr(dsn,1,20)
  alc   = strip(alc)
  used  = strip(used)
  odir  = strip(odir)
  pgcyl = strip(pgcyl)

  /* if the dataset does not have PREV in it, then iterate           */
  if left(dsn,5) ^= 'PREV.' then do
    say 'ELIBLIST:'
    say 'ELIBLIST:' dsn 'is not PREV prefixed, bypassing.'
    say 'ELIBLIST:'
    iterate
  end /* if left(dsn,5) ^= 'PREV.' then do */

  say 'ELIBLIST: Processing dataset' dsn
  say 'ELIBLIST:'
  /* start to build the dynamic JCL                                  */
  address ispexec
  'ftopen temp'
  'ftincl' EVGELB5A
  if rc ^= 0 then call exception rc 'FTINCL of EVGELB5A failed'

  if pos('.LISTINGS',dsn) > 0 then do
    sy   = substr(dsn,7,2) /* Endevor system id                      */
    prod = 'Y'

    'ftincl' EVGELB5B
    if rc ^= 0 then call exception rc 'FTINCL of EVGELB5B failed'

  end /* if pos('.LISTINGS',dsn) > 0 then do */

  else prod = 'N' /* reset flag if not a listing                     */

  if csv  = 'Y' then do /* Only process a CSV list                   */

    /* tell us what is happening                                     */
    say 'ELIBLIST:'
    say 'ELIBLIST:' dsn 'has' alc 'cyls allocated and uses' used 'cyls'

    /* if the dataset does have PREV then calculate %age used        */
    if pos('PREV.',dsn) > 0 then do
      percent = trunc((used * 100) / alc)
      say 'ELIBLIST:' dsn 'is' percent 'percent used.'
    end /* if pos('PREV.',dsn) > 0 then do */

    select
      when odir > 0 then do /* Are there directory overflows?        */
        say 'ELIBLIST:' dsn 'has' odir 'directory overflows'
        say 'ELIBLIST: which is not optimal. Dataset will be processed'
        say 'ELIBLIST:'
        xtnd = 5
      end /* when odir > 0 then do */

      when pos('.LISTING',dsn) > 0 & pgcyl ^= 30 then do
        say 'ELIBLIST:' dsn 'has' pgcyl 'pages/cylinder'
        say 'ELIBLIST: which is not optimal. Dataset will be processed'
        say 'ELIBLIST:'
        xtnd = 5
      end /* when pos('.LISTING',dsn) > 0 & pgcyl ^= 30 then do */

   when trunc((pguse * 100) / alc) < 80 then do
     say 'ELIBLIST:' dsn 'is only' trunc((pguse * 100) / alc) 'used'
     say 'ELIBLIST: It will be re-sized'
     xtnd = '5' /* ensure the dataset is processed                   */
   end /* when trunc((pguse * 100) / alc) < 80 then do */

      when xtnd > 2 then do
        say 'ELIBLIST:' dsn 'has' xtnd 'dataset extends'
        say 'ELIBLIST: which is not optimal. Dataset will be processed'
        say 'ELIBLIST:'
        xtnd = 5
      end /* when xtnd > 2 then do */

      when alc < 5 then do /* if it is 5 cylinders or less ignore    */
        say 'ELIBLIST:' dsn 'has' alc 'cylinders primary allocation'
        say 'ELIBLIST: and will be bypassed'
        say 'ELIBLIST:'
        iterate
      end /* when alc < 5 then do */

      otherwise do
        say 'ELIBLIST:' dsn 'does not match any criteria'
        say 'ELIBLIST:'
        iterate
      end /* otherwise do */

    end /* select */

  end /* if x = 0 then do */

  /* set dataset variables                                           */
  pend1i  = prefix'.'dsn'.PEND1'
  pend2i  = prefix'.'dsn'.PEND2'
  pend3i  = prefix'.'dsn'.PEND3'

  'ftincl' EVGELB5C
  if rc ^= 0 then call exception rc 'FTINCL of EVGELB5C failed'

  'ftclose'
  'vget (ztempf)'

  /* allocate the pending files for EVGELB1I                         */
  address tso
  "alloc da('"pend1i"') fi(evgelb1i) NEW"

  /* having allocated the file, free it so the JCL can run           */
  "free fi(evgelb1i)"

  /* check the result of the pending dataset                         */
  if sysdsn("'"pend1i"'") <> 'OK' then do
    call exception 13 "SYSDSN command did not return 'OK'"
  end /* if sysdsn("'"pend1i"'") <> 'OK' then do */

  address tso
  "submit '"ztempf"'" /* submit first job                            */
  say 'ELIBLIST:'

  /* Do until the dataset doesn't exist any more                     */
  do until sysdsn("'"pend1i"'") = 'DATASET NOT FOUND'
    ADDRESS SYSCALL
    "SLEEP" waittime
    waits = waits + 1

    if waits = waitnum then do
      call exception 12 'STOPPED waiting for' pend1i
    end /* if waits = waitnum then do */

  end /* do until sysdsn("'"pend1i"'") <> 'OK' */

  waits = 0

  if auto = 'Y' then do

    /* allocate the pending files for EVGELB2I                       */
    address tso
    "alloc da('"pend2i"') fi(evgelb2i) NEW"

    /* having allocated the file, free it so the JCL can run         */
    "free fi(evgelb2i)"

    /* check the result of the pending dataset                       */
    if sysdsn("'"pend2i"'") <> 'OK' then do
      call exception 14 "SYSDSN command did not return 'OK'"
    end /* if sysdsn("'"pend2i"'") <> 'OK' then do */

    say 'ELIBLIST: Submitting PREV.ELIBLIST.CNTL(EVGELB2I)'

    address tso
    "submit 'PREV.ELIBLIST.CNTL(EVGELB2I)'" /* submit second job     */
    say 'ELIBLIST:'

    /* Do until the dataset doesn't exist any more                   */
    do until sysdsn("'"pend2i"'") = 'DATASET NOT FOUND'
      ADDRESS SYSCALL
      "SLEEP" waittime
      waits = waits + 1

      if waits = waitnum then do
        call exception 12 'STOPPED waiting for 'pend2i
      end /* if waits = waitnum then do */

    end /* do until sysdsn("'"pend2i"'") <> 'OK' */

    waits = 0

    /* allocate the pending files for EVGELB3I                       */
    address tso
    "alloc da('"pend3i"') fi(evgelb3i) NEW"

    /* having allocated the file, free it so the JCL can run         */
    "free fi(evgelb3i)"

    /* check the result of the pending dataset                       */
    if sysdsn("'"pend3i"'") <> 'OK' then do
      call exception 15 "SYSDSN command did not return 'OK'"
    end /* if sysdsn("'"pend3i"'") <> 'OK' then do */

    say 'ELIBLIST: Submitting PREV.ELIBLIST.CNTL(EVGELB3I)'

    address tso
    "submit 'PREV.ELIBLIST.CNTL(EVGELB3I)'" /* submit third job      */
    say 'ELIBLIST:'

    /* Do until the dataset doesn't exist any more                   */
    do until sysdsn("'"pend3i"'") = 'DATASET NOT FOUND'
      ADDRESS SYSCALL
      "SLEEP" waittime
      waits = waits + 1

      if waits = waitnum then do
        call exception 12 'STOPPED waiting for 'pend3i
      end /* if waits = waitnum then do */

    end /* do until sysdsn("'"pend3i"'") = 'DATASET NOT FOUND' */

  end /* if auto = 'Y' then do */

end /* do a = 1 to report.0                                          */

exit
/*---------------------- S U B R O U T I N E S ----------------------*/

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
   address ispexec "FTCLOSE"        /* Close any FTOPENed files      */
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code

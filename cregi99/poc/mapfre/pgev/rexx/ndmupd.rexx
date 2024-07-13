/*-----------------------------REXX----------------------------------*\
 *  Update NDM process members in place with return code checking,   *
 *  And add OPSWTO to demand Cjob on the target plex.                *
 *  Executed by step NDMUPD in Rjobs.                                *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg shiphlqc rjob c1sy

julian_date = Date('Julian')
say rexxname':' Date() Time()
say rexxname": Today's Julian Date..:" julian_date
say rexxname':'
say rexxname': SHIPHLQC.....:' shiphlqc
say rexxname': RJOB.........:' rjob
say rexxname': C1SY.........:' c1sy
say rexxname':'

ndmfile = shiphlqc'.PROCESS.FILE'

/* Read the input file with demand data                              */
'execio * diskr INPUT (stem cmrinfo. finis'
if rc ^= 0 then call exception rc 'DISKR of INPUT failed.'

/* Validate INPUT data, to avoid causing problems downstream         */
do i = 1 to cmrinfo.0
  target    = word(cmrinfo.i,1)
  impl_date = word(cmrinfo.i,3)
  /* validate date - N.B. Date of 00000 is valid                     */
  if ^datatype(impl_date,'Whole number') then
    call exception 12 'Invalid Date (YYDDD) "'impl_date'"',
                      'found in INPUT file for' target
  if length(impl_date) ^= 5 then
    call exception 12 'Invalid Date (YYDDD) "'impl_date'"',
                      'found in INPUT file for' target
  impl_date_yy  = left(impl_date,2)
  impl_date_ddd = right(impl_date,3)
  if impl_date_ddd > 366 then
    call exception 12 'Invalid Date (YYDDD) "'impl_date'"',
                      'found in INPUT file for' target
  if impl_date_ddd = 366 & (impl_date_yy // 4) ^= 0 then
    call exception 12 'Invalid Date (YYDDD) "'impl_date'"',
                      'found in INPUT file for' target
  if impl_date_ddd = 0 & impl_yy > 0 then
    call exception 12 'Invalid Date (YYDDD) "'impl_date'"',
                      'found in INPUT file for' target
  if impl_date ^= 0 & impl_date < julian_date then
    call exception 12 'Date in the past (YYDDD) "'impl_date'"',
                      'found in INPUT file for' target

  impl_time = word(cmrinfo.i,4)
  /* validate time                                                   */
  if ^datatype(impl_time,'Whole number') then
    call exception 12 'Invalid Time (HHMM) "'impl_time'"',
                      'found in INPUT file for' target
  if length(impl_time) ^= 4 then
    call exception 12 'Invalid Time (HHMM) "'impl_time'"',
                      'found in INPUT file for' target
  if impl_date = 0 & impl_time > 0 then
    call exception 12 'Invalid Date (YYDDD) "'impl_date'"',
                      'found in INPUT file for' target
  impl_time_hh  = left(impl_time,2)
  impl_time_mm  = right(impl_time,2)
  if impl_time_hh > 23 then
    call exception 12 'Invalid Time (HHMM) "'impl_time'"',
                      'found in INPUT file for' target
  if impl_time_mm > 59 then
    call exception 12 'Invalid Time (HHMM) "'impl_time'"',
                      'found in INPUT file for' target
end /* do i = 1 to cmrinfo.0 */

say rexxname': Updating members in' ndmfile
say rexxname':'

/* Get the list of members in the process file                       */
x = outtrap('tsoout.')
"listds '"ndmfile"' members"
if rc ^= 0 then call exception rc 'Error on listds of' ndmfile
x = outtrap("off")

/* Read each member from the process file and and cond code checks   */
do i = 7 to tsoout.0
  member = strip(tsoout.i)
  if member = '$$$SPACE' then iterate    /* pdsman spacemap          */
  if right(member,1) ^= 'P' then iterate /* Only ndm process members */

  s = 0 /* Reset step counter                                        */

  say rexxname': Updating member' member
  /* Allocate and read the member                                    */
  "alloc f(NDMMBR) dsname('"ndmfile"("member")') old"
  if rc ^= 0 then call exception rc 'ALLOC of' ndmfile'('member') failed.'
  'execio * diskr NDMMBR (stem line. finis'
  if rc ^= 0 then call exception rc 'DISKR of' ndmfile'('member') failed.'

  do z = 1 to line.0
    queue line.z
    if word(line.z,2)         = 'COPY' & ,
       left(word(line.z,1),4) = 'STEP' then do
      say rexxname':   Found step' word(line.z,1)
      s        = s + 1
      step.s   = word(line.z,1)
    end /* word(line.z,2) = 'COPY' & ... */
  end /* z = 1 to line.0 */

  queue ' '

  do z = 1 to s
    stepname = step.z
    queue 'CHEK'right(stepname,4) 'IF ('stepname 'GT 0) THEN'
    queue '           GOTO STEPBAD'
    if z = s then do /* It's the last step                            */
      queue '         ELSE'
      do ii = 1 to cmrinfo.0
        if left(member,6) = word(cmrinfo.ii,1) then do
          queue "STEPWTO    RUN TASK (PGM=OPSWTO PARM=(CL80 -"
          queue "           \'EV000101" right(rjob,7) ,
                word(cmrinfo.ii,2) "\ || - "
          queue "           \"subword(cmrinfo.ii,3)"'\ -"
          queue "           )) SNODE"
          leave ii
        end /* left(member,6) = word(cmrinfo.ii,1) */
      end /* ii = 1 to cmrinfo.0 */
      if ii = cmrinfo.0 + 1 then
        call exception 12 left(member,6) 'not found in INPUT file'
      queue '           EXIT'
      queue '         EIF'
      queue ' '
      queue "STEPBAD  RUN TASK (PGM=PRNOTIFY,PARM=(CL4'FAIL' -"
      queue "         CL44'JOBNAME="rjob "PLEASE INVESTIGATE')) SNODE"
    end /* z = s */
    else
      queue '         EIF'
  end /* z = 1 to line.0 */

  /* Write the process statements back out                           */
  'execio' queued() 'diskw NDMMBR (finis'
  if rc ^= 0 then call exception rc 'DISKW to' ndmfile'('member') failed.'
  "free f(NDMMBR)"

end /* i = 7 to tsoout.0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso "FREE F(NDMMBR)" /* Free files that may be open       */
   address tso 'delstack'       /* Clear down the stack              */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

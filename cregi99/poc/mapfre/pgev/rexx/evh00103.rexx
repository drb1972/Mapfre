/*-----------------------------REXX----------------------------------*\
 *  Read CA7 list of ENDEVOR jobs and build CA7 delete commands for  *
 *  jobs older than xdays.                                           *
\*-------------------------------------------------------------------*/
trace n

arg xdays locn

say 'EVH00103:' Date() Time()
say 'EVH00103:'
say 'EVH00103: xdays...........:' xdays
say 'EVH00103: locn............:' locn
say 'EVH00103:'

/* Ensure days to be kept is passed to rexx                          */
if xdays = '' then do
  say 'EVH00103: Variable xdays has not been passed'
  exit 12
end /* xdays = '' */

say 'EVH00103: Will delete jobs that are more than 'xdays' days old' ,
    'from CA7'locn'.'
say 'EVH00103:'

/* Read the CA7 report                                               */
"execio * diskr IN (stem in. finis)"
if rc ^= 0 then call exception rc 'DISKR of IN failed'

/* Write the CA7 report                                              */
"execio * diskw CA7OUT (stem in. finis)"
if rc ^= 0 then call exception rc 'DISKW to CA7OUT failed'

queue "JOB"

/* loop through list and check if older than xdays                   */
do i = 1 to in.0
  parse var in.i jobname sysname c1 c2 c3 c4 c5 c6 c7 c8 lastrun
  if sysname          = 'ENDEVOR'    & ,
     lastrun         ^= '00000/0000' & ,
     left(jobname,2) ^= 'EV'         & ,
     left(jobname,2) ^= 'B0'         then do
    lastrun = left(lastrun,5)
    call date_conv lastrun
  end /* sysname = 'ENDEVOR' & ... */
end /* i = 1 to in.0 */

say 'EVH00103:' queued()-1 'job definitions will be deleted'

/* Writeout delete statements                                        */
"execio" queued() "diskw OUT (finis)"
if rc ^= 0 then call exception rc 'DISKW to OUT failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* dateconv - convert report date from julian date to date(b)        */
/*                                                                   */
/*  converting from julian to date(b) format                         */
/*  every 4 years is a leap year                                     */
/*  every 100 years isnt a leap year                                 */
/*  every 400 years is a leap year                                   */
/*  this allows us to to have 2 dates in date(b) format which        */
/*  makes subtraction of days very easy without worrying about       */
/*  end of years etc.                                                */
/*                                                                   */
/*-------------------------------------------------------------------*/
date_conv:

 if left(lastrun,1) = '9' then lastrun = '19'lastrun
                          else lastrun = '20'lastrun

 newdate = ((((left(lastrun,4)-1)*365)-1) + substr(lastrun,5,3))
 leap    = left(lastrun,4) % 4
 c1leap  = left(lastrun,4) % 100
 c2leap  = left(lastrun,4) % 400
 newdate = newdate + leap - c1leap + c2leap

 if newdate < (date(b)-xdays) then do
   queue "DD,"jobname
   if left(jobname,2) ='C0' then
     queue "DD,"overlay('B',jobname)
 end /* newdate < (date(b)-45) */

return /* dateconv: */

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
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

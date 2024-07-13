/*-----------------------------REXX----------------------------------*\
 *  This REXX is used by the abort/re-schedule/backout               *
 *  processing to deal with the Cjobs and Bjobs on all CA7 tasks.    *
 *  AO brings the job on to the queue, edits the JCL and             *
 *  then releases it.                                                *
\*-------------------------------------------------------------------*/
trace n

arg opt cmr sheddate shedtime demand
say 'CMRUTIL: OPT      variable is' opt
say 'CMRUTIL: CMR      variable is' cmr
say 'CMRUTIL: SHEDDATE variable is' sheddate
say 'CMRUTIL: SHEDTIME variable is' shedtime
say 'CMRUTIL: DEMAND   variable is' demand

if cmr = 'ERR' then
  call exception 20 'Invalid CMR variable passed from EVL0300D'

select
  when opt = 'ABRT' then call abrt
  when opt = 'BACK' then call back
  when opt = 'RSCH' then call rsch
  otherwise do
    say 'CMRUTIL: Unknown option' opt 'passed'
    exit 3
  end /* otherwise */
end /* select */

/* Write out ca7 commands                                            */
"EXECIO" queued() "DISKW CA7CARDS (FINIS)"
if rc ^= 0 then call exception rc 'DISKW to CA7CARDS failed'

exit

/*--------------------- S U B R O U T I N E S -----------------------*/

/*-------------------------------------------------------------------*/
/* Cancel the Cjob off the queue for an abort                        */
/*-------------------------------------------------------------------*/
abrt:
 queue 'CANCEL,JOB=C'cmr',FORCE=YES,REASON=ENDEVOR ABORT'
 queue 'JOB'
 queue 'DD,C'cmr
 queue 'DD,B'cmr

return /* abrt: */

/*-------------------------------------------------------------------*/
/* Demand the Bjob on the queue for a backout                        */
/*-------------------------------------------------------------------*/
back:
 queue 'CLEAR'
 queue 'DBM'
 queue 'DEMAND,JOB=B'cmr',JCLID=5,SET=NDB,CLASS=6'

return /* back: */

/*-------------------------------------------------------------------*/
/* set "Due Out Time" as scheduled time + 5 minutes                  */
/* Cater for mins wrapping round the hour, and use the "RIGHT"       */
/* function to ensure that a 2 character field is always produced    */
/* for HH and MM.                                                    */
/*-------------------------------------------------------------------*/
rsch:
 if demand = 'ERR' then
   call exception 20 'Invalid demand command passed from EVL0300D'

 if sheddate = 'ERR' then
   call exception 20 'Invalid sheddate variable passed from EVL0300D'

 if shedtime = 'ERR' then
   call exception 20 'Invalid shedtime variable passed from EVL0300D'

 hours = substr(shedtime,1,2)
 mins  = substr(shedtime,3,2)
 mins  = mins + 5

 if mins > 59 then do
   mins  = mins  - 60
   hours = hours + 1
   if hours = 24 then hours = 00
 end /* mins > 59 */

 dotm = right(hours,2,'0')right(mins,2,'0')

 queue 'CANCEL,JOB=C'cmr',FORCE=YES,REASON=ENDEVOR RESCHEDULE'
 queue 'CLEAR'
 queue 'DBM'
 queue demand',JOB=C'cmr',DATE='sheddate|| , /* <- do not remove     */
       ',TIME='shedtime',LEADTM=5,CLASS=6,DOTM='dotm

return /* rsch: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 address tso 'delstack' /* Clear down the stack                      */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

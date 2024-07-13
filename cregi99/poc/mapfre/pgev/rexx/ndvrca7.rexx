/*-----------------------------REXX----------------------------------*\
 * build relevant ca7 command for the batch terminal depending upon  *
 * the parameters pass to the proc.                                  *
\*-------------------------------------------------------------------*/

/* parameters passed from EVL0101D                                   */
arg cmr sheddate shedtime ca7swap emer demand
say 'NDVRCA7: CMR      variable is' cmr
say 'NDVRCA7: SHEDDATE variable is' sheddate
say 'NDVRCA7: SHEDTIME variable is' shedtime
say 'NDVRCA7: EMER     variable is' emer
say 'NDVRCA7: DEMAND   variable is' demand

/* determine which system we are running on                          */
mvssys = mvsvar('sysname')
say 'NDVRCA7: Job is running on the' mvssys 'LPAR'

/* set "Due Out Time" as scheduled time + 5 minutes                  */
/* Cater for mins wrapping round the hour, and use the "RIGHT"       */
/* function to ensure that a 2 character field is always produced    */
/* for HH and MM.                                                    */
hours = substr(shedtime,1,2)
mins  = substr(shedtime,3,2)
mins  = mins +5

if mins > 59 then do
  mins  = mins  - 60
  hours = hours + 1
  if hours = 24 then hours = 00
end

dotm = right(hours,2,'0')right(mins,2,'0')

/* Build CA7 Cards to add Cjob & Bjob                                */
queue 'JOB'
queue 'ADD,B'cmr',SYSTEM=ENDEVOR,EXEC=Y,JCLID=5,RELOAD=X'
queue 'ADD,C'cmr',SYSTEM=ENDEVOR,EXEC=Y,JCLID=5,RELOAD=X'
queue 'DBM'

/* for the Qplex we add special resources                            */
if left(mvssys,1) = 'Q' then do
  queue 'RM.1'
  queue 'UPD,RM.1,JOB=B'cmr',OPT=A,SCHID=0,'
  queue 'RSRC=GRP.NDV.PREV.LIBRARIES,TYPE=SHR,FREE=F'
  queue 'DBM'
end /* left(mvssys,1) = 'Q' */

/* Take action, based on type of release:                            */
/* emergency release : demand with no hold                           */
/* standard  release : demand with date & time                       */
if emer = 'YES' then do /* Emergency release                         */
  say 'NDVRCA7: EMER variable is set to YES'
  say 'NDVRCA7: The Cjob is demanded without a HOLD'
  queue 'DEMAND,JOB=C'cmr',CLASS=6'
end /* emer = 'YES' */
else /* Standard release                                             */
  queue demand',JOB=C'cmr',DATE='sheddate || ,
        ',TIME='shedtime',LEADTM=5,CLASS=6,DOTM='dotm

/* writeout ca7cards                                                 */
"EXECIO "QUEUED()" DISKW CA7CARDS (FINIS)"
if rc ^= 0 then call exception rc 'DISKW to CA7CARDS failed'

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
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code

/*--------------------------REXX-----------------------------*\
 *  This REXX takes element master information for C0*       *
 *  elements in system OS* and creates totals reports for    *
 *  Batch Projects.                                          *
\*-----------------------------------------------------------*/

say 'WIZREP2: Analysing element list'
say 'WIZREP2:'

lastmon  = 'FIRST'
person.  = 0
lastdate = 'FIRST'
currnum  = 0
start    = 0
total    = 0
totday   = 0
totmon   = 0
num      = 0
month    = 0
grandtot = 0

/* Read the full element list                                        */
"execio * diskr REPIN2 (stem repa. finis"
if rc ^= 0 then call exception 12 'DISKR from REPIN2 failed. RC='rc

do g = 1 to repa.0
  ccid = substr(repa.g,39,8)
  sys  = substr(repa.g,23,2)
  type = strip(substr(repa.g,49,8))
  user = strip(substr(repa.g,245,8))
  change.ccid.sys.type = user
end /* do g = 1 to repa.0 */

/* Read list of elements with an action date from today - 120        */
"execio * diskr REPIN (stem repc. finis"
if rc ^= 0 then call exception 12 'DISKR from REPIN failed. RC='rc

/* Read list of users that have updated any element                  */
"execio * diskr USERLIST (stem repu. finis"
if rc ^= 0 then call exception 12 'DISKR from USERLIST failed. RC='rc

do c = 1 to repc.0
  currtyp  = strip(substr(repc.c,1,8))
  currsys  = substr(repc.c,10,2)
  currccid = substr(repc.c,13,8)
  currnum  = strip(substr(repc.c,22,8))
  currdat  = substr(repc.c,31,6)
  currmon  = substr(repc.c,33,2)
  totday   = totday + currnum
  totmon   = totmon + currnum
  curruser = change.currccid.currsys.currtyp
  person.curruser = person.curruser + currnum

  if (lastdate <> currdat) & (lastdate <> 'FIRST') then do
    queue '   '
    queue '                TOTAL FOR DATE' lastdate 'IS' totday
    queue '                ++++++++++++++++++++++++++++++++++++++++++'
    grandtot = grandtot + totday
    totday = 0
  end /* if (lastdate <> currdat) & (lastdate <> 'FIRST') then do */

  if (lastmon <> currmon) & (lastmon <> 'FIRST') then do

    queue '   '
    queue '¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯'
    queue 'TOTAL MEMBERS CHANGED IN MONTH' lastmon 'IS' totmon
    queue ' '
    queue 'TOTAL MEMBERS ADDED/DELETED BY USERS DURING MONTH' lastmon
    queue '¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯'
    queue ''

    do d = 1 to repu.0
      bloke = strip(substr(repu.d,1,8))

      if person.bloke > 0 then do
        queue 'TOT FOR' substr(repu.d,1,8) 'IS' person.bloke
        person.bloke = 0
      end /* if person.bloke > 0 then do */

    end /* do d = 1 to repu.0 */

    totmon = 0
    queue '____________________________________________'
    queue ''

  end /* if (lastmon <> currmon) & (lastmon <> 'FIRST') then do */

  lastdate = currdat
  lastmon  = currmon

  queue left(repc.c,21) right(strip(substr(repc.c,23,6),'l','0'),6) ,
        || '  'substr(repc.c,31,6)'     'curruser

end /* do c = 1 to repc.0 */

queue ' '
queue ' TOTAL SO FAR THIS MONTH PER USERID '
queue ' ---------------------------------- '

do d = 1 to repu.0
  bloke = strip(substr(repu.d,1,8))

  if person.bloke > 0 then do
    queue 'TOTAL SO FAR FOR' substr(repu.d,1,8) 'IS' person.bloke
    person.bloke = 0
  end /* if person.bloke > 0 then do */

end /* do d = 1 to repu.0 */

queue ' '
queue ' '
queue ' '
queue '            TOTAL SO FAR FOR MONTH' lastmon 'IS' totmon
queue '            ================================================='
queue '            TOTAL FOR LAST 120 DAYS IS' grandtot
queue ' '

"execio "queued()" diskw REPOUT1 (finis)"
if rc ^= 0 then call exception 12 'DISKW to REPOUT1 failed. RC='rc

exit

/*---------------------- S U B R O U T I N E S -----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack */
 do i = 1 to queued()
   pull
 end

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

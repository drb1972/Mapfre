/*-----------------------------REXX----------------------------------*\
 *  This REXX reads in a PDS member list and builds delete           *
 *  statements for members that are older than x days.               *
 *  E.g. Job EVG001PW to delete PGEV.PEV1.BINDJCL                    *
\*-------------------------------------------------------------------*/
trace n

arg xdays

say 'EVH00101:' Date() Time()
say 'EVH00101:'
say 'EVH00101: Xdays...........:' xdays /* Number of days to keep    */
say 'EVH00101:'

if xdays = '' then do
  say 'EVH00101: Number of of days is not valid'
  say 'EVH00101: Leaving routine with RC 5'
  exit 5
end /* xdays = '' then */

say 'EVH00101: Will delete jobs over' xdays 'days old'
say 'EVH00101:'

tstdate = date(b) - xdays
display = Date('e',tstdate,'b') /* Conv base date to european date  */
say 'EVH00101: Members older than' display 'will be deleted'
say 'EVH00101:'

queue ' EDITDIR OUTDD=DELPDS' /* Queue first statement               */

/* Read pdsman report                                                */
"execio * diskr IN (stem data. finis"
if rc ^= 0 then call exception rc 'DISKR of IN failed'

do i = 1 to data.0
  data = data.i
  /* Check if older than x days                                      */
  if substr(data,58,4) = 'None' then do
    chk1 = substr(data,23,4)||substr(data,17,2)||substr(data,20,2)
    chgdate = Date('b',chk1,'s')
    member  = substr(data,2,8)

    if chgdate < tstdate then do
      queue ' DELETE    MEMBER='member
      say 'EVH00101: Building delete statement for member' member
    end /* chgdate < tstdate */

  end /* substr(data,58,4) = 'None' */

end /* i = 1 to data.0 */

if queued() = 1 then do
  say 'EVH00101: There are no members to delete'
  exit 4
end /* queued() = 1 */
else do
  "execio * diskw OUT (finis"
  if rc ^= 0 then call exception 12 'DISKW to OUT failed RC='rc
end /* else */

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
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

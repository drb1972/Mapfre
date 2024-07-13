/*-----------------------------REXX----------------------------------*\
 *  Build PRINT MEMBER SCL and SPLIT lines for the scan list utility *
\*-------------------------------------------------------------------*/
trace n

arg type dsn

say 'SCAN2:' Date() Time()
say 'SCAN2:'
say 'SCAN2: Type............:' type
say 'SCAN2: DSN.............:' dsn
say 'SCAN2:'

/* Set up the type string to scan for                                */
if right(type,1) = '*' then
  typesel = substr(type,1,length(type)-1)
else
  typesel = type

selected = 0

"execio * diskr LISTMEMS (stem members. finis)"
if rc ^= 0 then call exception rc 'DISKR of LISTMEMS failed.'

/* Build the print member statements                                 */
do i = 1 to members.0
  lmember = strip(substr(members.i,72,10))
  element = left(lmember,length(lmember)-2)
  ltype   = substr(members.i,163,8)
  stype   = substr(ltype,1,length(typesel))
  if stype = typesel then do
    selected = selected + 1
    list.selected = lmember element ltype
    queue '  PRINT MEMBER A'selected 'FROM DDNAME SPLITER .'
    queue '  PRINT MEMBER' lmember 'FROM DDNAME LISTINGS .'
  end /* i = 1 to members.0 */
end /* stype = typesel */

if selected = 0 then do
  say 'SCAN2: No listings selected of type' type
  error.1 = 'SCAN2: No listings selected of type' type
  error.2 = 'SCAN2: From listing dataset' dsn
  "execio 2 diskw ERROR (stem error. finis"
  if rc ^= 0 then call exception rc 'DISKW to ERROR failed.'
  exit 12
end /* selected = 0 */

queue '  PRINT MEMBER A'selected+1 'FROM DDNAME SPLITER .'

"execio * diskw PRINTSCL (finis"
if rc ^= 0 then call exception rc 'DISKW to PRINTSCL failed.'

/* Build listing split members                                       */
queue './ ADD NAME=A'1
queue '----- Start of listing:' list.1 copies('-',25)
do i = 2 to selected
  queue './ ADD NAME=A'i
  xx = i - 1
  queue '----- End   of listing:' list.xx copies('-',25)
  queue '-----'
  queue '----- Start of listing:' list.i copies('-',25)
end /* i = 2 to selected */
queue './ ADD NAME=A'i
xx = i - 1
queue '----- End   of listing:' list.xx copies('-',25)

"execio * diskw SPLITS (finis"
if rc ^= 0 then call exception rc 'DISKW to SPLITS failed.'

say 'SCAN2:' selected 'listings selected for printing'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso delstack /* Clear down the stack                        */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

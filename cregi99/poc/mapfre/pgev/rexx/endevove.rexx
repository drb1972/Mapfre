/*-----------------------------REXX----------------------------------*\
 *  Create Endevor override library report                           *
 *  It is used by job EVGPOVEW                                       *
\*-------------------------------------------------------------------*/

trace n

/* initialise - initialise global variables                          */

exit_rc = 1
count = 0
stand_count = 0
done = 'NO'
non_standard = 'NO'

count = count + 1
except.count = ' '
count = count + 1
excp.count = ' There are no Endevor non-standard datasets located.'
count = count + 1
except.count = ' '

/* Read in LMDLIST report - exit if none found                       */
"EXECIO * DISKR in (STEM lin. FINIS)"
if rc ^= 0 then call exception rc 'DISKR of IN failed'

/* Look for any members, process if found                            */
do i = 1 to lin.0
  dsn = word(lin.i,1)
  if substr(dsn,1,4) ^= 'PREV' then iterate

  /* break down dataset name                                         */
  parse value dsn with node1 '.' node2 '.' node3 '.' node4 '.' extra
  if substr(node4,1,3) = 'SMG' then iterate

  if node4 ^= '' then do
    count = count + 1
    except.count = '          'dsn
    non_standard = 'YES'
  end /* node4 ^= '' */

  call process dsn

end /* i = 1 to lin.0 */

if done = 'NO' then do
  queue ''
  queue ' There are no Endevor Override Libraries that contain members.'
  queue ''
  exit_rc = 00
end /* done = 'NO' */

if non_standard = 'NO' then do
  stand_count = stand_count + 1
  stand.stand_count = ' '
  stand_count = stand_count + 1
  stand.stand_count = ' There are no Endevor Non-Standard',
                      'datasets located.'
  stand_count = stand_count + 1
  stand.stand_count = ' '
end /* non_standard = 'NO' */

else do /* build up output array                                     */
  stand_count       = stand_count + 1
  stand.stand_count = ' '
  stand_count       = stand_count + 1
  stand.stand_count = ' The following Endevor Override Libraries',
                      'found with non-standard name(s) :-'
  stand_count       = stand_count + 1
  stand.stand_count = ' '

  do ii = 4 to count
    stand_count       = stand_count + 1
    stand.stand_count = except.ii
  end /* ii = 4 to count */

  stand_count         = stand_count + 1
  stand.stand_count   = ' '
end /* else */

/* Write out results                                                 */
address TSO "EXECIO * DISKW excepts (STEM stand."
if rc ^= 0 then call exception rc 'DISKW to EXCEPTS failed'

queue ''
address TSO "EXECIO "queued()" DISKW out (FINIS"
if rc ^= 0 then call exception rc 'DISKW to OUT failed'

EXIT exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Process each dataset                                              */
/*-------------------------------------------------------------------*/
process:
parse arg dsn

say 'ENDEVOVE - Processing -' dsn

kount = 0

x = OUTTRAP("members.",'*',"CONCAT")
Address tso "listds '"dsn"' mem"
x = OUTTRAP("off")

do k = 7 to members.0
  member = strip(members.k)

  if member = '$$$SPACE' |,
     member = '$$$LIB'   then iterate

  char1 = substr(member,1,1)
  hex_char1 = c2x(substr(member,1,1))

  if hex_char1 = 'FE' then iterate

  say 'member =' member

  kount = kount + 1
  mem.kount = member
end /* k = 7 to members.0 */

if kount > 0 then call report dsn kount

return /* process: */

/*-------------------------------------------------------------------*/
/* Format report output if required                                  */
/*-------------------------------------------------------------------*/
report:
parse arg dsn kount

if done = 'NO' then do
  queue ''
  queue ' The following Endevor Override Libraries contain members :-'
  done = 'YES'
end /* done = 'NO' */

kkount = 0

queue ''
queue ' 'dsn' - contains the following members :-'
queue ''

do k = 1 to kount
  queue '          'mem.k
end

return /* report: */

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

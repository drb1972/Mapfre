/*-----------------------------REXX----------------------------------*\
 *  This REXX is used by move processors to build BSTCOPY select     *
 *  statements for outputs. E.g. MEAR, MWSDL.                        *
 *  It accepts input from a component list.                          *
\*-------------------------------------------------------------------*/
trace n

arg c1element c1stgid c1subsys input_llq

dsn     = 'PREV.'c1stgid || c1subsys'.'input_llq
len_llq = length(input_llq)

queue "  COPY O=OUTDD,I=INDD"

say 'POPCARDS: Reading the component list'

/* Read in the component list output                                 */
"execio * diskr C1PRINT (stem line. finis)"
if rc ^= 0 then call exception rc 'DISKR of C1PRINT failed'

/* Write the component list for debugging                            */
"execio" line.0 "diskw COMPLIST (stem line. finis"
if rc ^= 0 then call exception rc 'DISKW to COMPLIST failed'

say 'POPCARDS: Looping through' line.0 'records in the C1PRINT file'

do x = 1 to line.0
  if pos('OUTPUT COMPONENTS',line.x) > 0 then
    leave
end /* x = 1 to line.0 */

do i = x to line.0 while llq ^= input_llq
  if word(line.i,1) = 'STEP:' then do
    compdsn = word(line.i,5)
    llq     = right(compdsn,len_llq) /* DSN from the component list  */
  end /* word(line.i,1) = 'STEP:' */
end /* i = x to line.0 while llq ^= input_llq */

do a = i to line.0

  /* Stop at the next DSN in the component list                      */
  if word(line.a,1) = 'STEP:' then
    leave

  mem = word(line.a,2)
  ele = word(line.a,8)
  /* If the element name matches the component list elt name         */
  /* we can build a statement depending on the action.               */
  /* This exludes header records.                                    */
  if ele = c1element then do
    say 'POPCARDS:'
    say 'POPCARDS: Found entry' mem 'for the library' dsn
    say 'POPCARDS: will build the SELECT statement'

    queue "  SELECT MEMBER=(("mem",,R))"

  end /* ele = c1element */

end /* a = i to line.0 */

if queued() = 1 then do /* Stop full PDS copies                      */
  queue "  SELECT MEMBER=$$$$$$$$"
  say 'POPCARDS: No members found to copy'
  exit 4
end /* queued() = 1 */

"execio" queued() "diskw COMMANDS (finis"
if rc ^= 0 then call exception rc 'DISKW to COMMANDS failed'

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

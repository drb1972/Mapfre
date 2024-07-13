/*-----------------------------REXX----------------------------------*\
 *  Read a list of DSN masks and produce a DSN list for              *
 *  that mask.                                                       *
 *-------------------------------------------------------------------*
 *  For an example of the HLQ in parm then check proc EVGPOVEW       *
 *  For an example of the HLQ from DDname check proc EV#SHP1B        *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */
trace n

arg stats hlq
stats = strip(stats)
hlq   = strip(hlq)

if stats = '' then stats = 'YES'
if hlq   = '' then hlqm  = 'No HLQ specified, HLQS Ddname will be read'
              else hlqm  = hlq

say 'LMDLIST: ' DATE() TIME()
say 'LMDLIST:  *** Input parameters ***'
say 'LMDLIST:'
say 'LMDLIST: Stats.....' stats
say 'LMDLIST: HLQ.......' hlqm
say

if hlq = '' then do
  address tso
  "execio * diskr hlqs (stem hlqs. finis" /*  read mask(s)           */
  if rc <> 0 then call exception 'DISKR from HLQS failed. RC='rc
end /* hlq = '' then */
else do /* set up array details when passed in the parm field        */
  hlqs.0 = 1
  hlqs.1 = hlq
end /* else */

address ispexec

do i = 1 to hlqs.0 /* loop through dataset masks                     */
  hlq = strip(subword(hlqs.i,1),'b',"'") /* remove any quotes        */

  if length(hlq) = 0 then
     say 'LMDLIST: Invalid qualifier -' hlq

  say 'LMDLIST: Processing' hlq
  dsl = translate(hlq," ",".")
  if words(dsl) > 1 & ,
     right(hlq,1) <> "*" & ,
     length(word(dsl,words(dsl))) < 8 then hlq = hlq"*"

  "LMDINIT LISTID(LISTID) LEVEL("hlq")"
  if rc <> 0 then call exception 'LMDINIT for' hlq 'failed. RC='rc

  "LMDLIST LISTID("ListId") OPTION(SAVE) STATS("stats")"
  if rc > 0 then
    say 'LMDLIST: No data sets found for index:' hlq

  "LMDFREE LISTID("ListId")"
end /* i = 1 to hlqs.0 */

exit

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* This if is for ISPF in batch only                                */
 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code

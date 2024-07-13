/*-----------------------------REXX----------------------------------*\
 *  This rexx is used in the Abort processing for Wizard             *
 *  type changes. When an abort happens, this rexx will              *
 *  be run to backout the libraries at stage P.                      *
\*-------------------------------------------------------------------*/
parse arg ccid

ccidwee  = substr(ccid,2,7)
ds_count = 0
wiz      = 'NO'
mask     = "PREV.P%%1.*."ccid

address "ISPEXEC"
"LMDINIT LISTID(LISTIDV) LEVEL("mask")"
"LMDLIST LISTID("listidv") OPTION(LIST) DATASET(LDSN) STATS(NO)"
do while rc = 0
  ds_count = ds_count + 1
  stg_dsn.ds_count = ldsn
  "LMDLIST LISTID("listidv") OPTION(LIST) DATASET(LDSN) STATS(NO)"
end
"LMDLIST LISTID("listidv") OPTION(FREE)"

address TSO
do a = 1 to ds_count
  if pos('.FP',stg_dsn.a,10) = 0 then do
    if pos(ccid,stg_dsn.a) > 0 then wiz = 'YES'
    quals    = translate(stg_dsn.a,' ','.')
    type     = word(quals,3)
    abort_ds = left(stg_dsn.a,10)||type'.CMPARM(X'ccidwee')'
    call getabort
  end /* pos('.FP',stg_dsn.a,10) = 0 */
end /* a = 1 to ds_count */

if wiz = 'NO' then
  say 'WIZABORT: Not a wizard change'
else do
  push '//*'
  push '//EVGWIZAI JOB CLASS=A,MSGCLASS=Y'
  address TSO
  "execio "queued()" diskw BACKOUT (finis)"
  if rc ^= 0 then call exception rc 'DISKW to BACKOUT failed.'
end /* else */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Getabort - Read the Wizard abort JCL                              */
/*-------------------------------------------------------------------*/
getabort:

 "ALLOC F(BJCL) DSNAME('"abort_ds"') SHR"
 'execio * diskr BJCL (stem bjcl. finis'
 if rc ^= 0 then call exception rc 'DISKR of BJCL failed.'
 "FREE F(BJCL)"
 do b = 1 to bjcl.0
   line     = left(bjcl.b,75)
   hash_pos = pos('##',line)
   if hash_pos > 0 then
     line = overlay('PR',line,hash_pos)
   queue line
 end /* b = 1 to bjcl.0 */

return /* getabort */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

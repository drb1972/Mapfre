/*-----------------------------REXX----------------------------------*\
 *   This is invoked when EVGMJOBI runs.                             *
 *                                                                   *
 *   It checks if there is an archive dataset and if there is then   *
 *   create a temporary skeleton for EVUTLITY to FTINCL              *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

parse source . . rexxname . . . . addr .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg hlq /* passed from the batch job                                 */

arcdsn   = hlq'.SHIP.*.ARCHIVE.ARCHREST' /* set the dsname           */
testname = hlq'.SHIP.' /* variable for pos command                   */

address tso
b = outtrap("DSNS.",'*',concat)
"LISTC LEVEL('"arcdsn"') NAMES"
b = outtrap('off')

if rc = 4 then do
  say rexxname': LISTC of' arcdsn '= 4'
  say rexxname': No datasets to process'
  zispfrc = 4
  address ispexec "vput (zispfrc) shared"
  exit 4
end /* rc = 4 */

/* if the listcat came back with anything other than zero then exit  */
if rc ^= 0 then call exception rc 'LISTC failed.'

do c = 1 to dsns.0 /* display the output from the listcat            */
  say dsns.c
end /* c = 1 to dsns.0 */

say /* 1 blank line just for output formatting                       */

/* Process the archive JCL datasets                                  */
do a = 1 to dsns.0 /* loop through the listcat output                */

  if pos(testname,dsns.a) > 1 then do

    dsn  = strip(word(dsns.a,3)) /* get the dsn from listcat         */
    cmr  = substr(dsn,11,8)      /* CMR number                       */

    say rexxname': Archive JCL found:' dsn

    address ispexec
    /* Prepare tempdsn dataset for LMCOPY                            */
    "LMINIT DATAID(TARGET) DDNAME(TEMPSKEL) ENQ(SHR)"
    if rc ^= 0 then call exception rc 'LMINIT of TEMPSKEL failed.'

    /* Prepare the arch restore dataset for LMCOPY                   */
    "LMINIT DATAID(FROM) DATASET('"dsn"') ENQ(SHR)"
    if rc ^= 0 then call exception rc 'LMINIT of' dsn 'failed'

    /* Copy to the tempdsn dataset from archive dataset              */
    "LMCOPY FROMID("from") TODATAID("target") TOMEM("cmr")"
    if rc ^= 0 then call exception rc 'LMCOPY to' target 'failed.'

    /* release the archive dataset                                   */
    "LMFREE DATAID("from")"
    if rc ^= 0 then call exception rc 'LMFREE of' dsn 'failed.'

    /* release the tempdsn dataset                                   */
    "LMFREE DATAID("target")"
    if rc ^= 0 then call exception rc 'LMFREE of tempdsn failed.'

  end /* pos(testname,dsns.a) > 1 */

end /* a = 1 to dsns.0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address ispexec "FTCLOSE" /* Close any FTOPENed files             */
   address tso 'delstack'    /* Clear down the stack                 */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit return_code

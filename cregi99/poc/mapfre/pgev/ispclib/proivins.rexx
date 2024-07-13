/*-----------------------------REXX----------------------------------*\
 *  Create a PRO-IV BOOTS file which will be added to Endevor        *
 *  Called from the user menu option 7.2                             *
\*-------------------------------------------------------------------*/
arg debug

/* Debug Trace switch                                                */
if debug = 'DEBUG' then trace i
                   else trace n

/* Display panel to receive user info                                */
uid  = sysvar('sysuid')
pref = sysvar('syspref')

timequal = time('N')
hr       = substr(timequal,1,2)
mn       = substr(timequal,4,2)
sc       = substr(timequal,7,2)
slq      = 'T'hr || mn || sc

tempdsn = pref"."uid"."slq".TEMP1"

x = msg(off)
"FREE DD(ISPFILE)"
x = msg(on)

"ALLOC DD(ISPFILE) DA('"tempdsn"')",
       "NEW SPACE(1,1) CYLINDERS REUSE",
       "UNIT(SYSALLDA) CATALOG RECFM(F B) LRECL(80)"
if rc ^= 0 then call exception rc 'ALLOC of' tempdsn 'failed'

"ISPEXEC DISPLAY PANEL(PROIVINS)"
if rc ^= 0 then
  exit
else do
  "ISPEXEC VPUT (PROIVAPP C1SUB C1EN C1CCID PKGTYP CNTLDSN) PROFILE"

  c1sy = substr(c1sub,1,2)

  if pkgtyp = 'STD' then do
    env     = c1en
    stg     = 'VF'
    sid     = 'F'
  end /* pkgtyp = 'STD' */
  else do /* so pkgtyp = 'EMER'                                      */
    env     = 'PROD'
    stg     = 'VO'
    sid     = 'O'
  end /* else */

  select
    when proivapp = 'LIFE' then do
      dsuf = 'P'
      gsuf = 'E'
      esuf = 'C'
    end
    when proivapp = 'LOAN' then do
      dsuf = 'P'
      gsuf = 'E'
      esuf = 'C'
    end /* proivapp = 'LOAN' */
    when proivapp = 'SAVG' then do
      dsuf = 'S'
      gsuf = 'S'
      esuf = 'S'
    end /* proivapp = 'SAVG' */
    when proivapp = 'CALL' then do
      dsuf = 'X'
      gsuf = 'X'
      esuf = 'X'
    end /* proivapp = 'CALL' */
    otherwise nop
  end /* select */

  if rc = 0 then do
    "ISPEXEC FTOPEN"
    if rc ^= 0 then call exception rc 'FTOPEN failed'
    "ISPEXEC FTINCL PROIVI10"
    if rc ^= 0 then call exception rc 'FTINCL of PROIVI10 failed'
    "ISPEXEC FTCLOSE"
    if rc ^= 0 then call exception rc 'FTCLOSE failed'
    "ISPEXEC EDIT DATASET('"tempdsn"')"
    if rc > 4 then call exception rc 'EDIT of' tempdsn 'failed'
    say "Submit this JCL (Y/N)?"
    pull ans
    upper ans
    if ans = "Y" then
      "SUBMIT '"tempdsn"'"
  end /* rc = 0 */
end /* else */

"FREE DD(ISPFILE)"

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
   address ispexec "FTCLOSE"        /* Close any FTOPENed files      */
   address tso "FREE F(ISPFILE)"    /* Free files that may be open   */
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code

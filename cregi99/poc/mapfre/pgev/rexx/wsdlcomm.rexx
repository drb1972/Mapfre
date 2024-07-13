/*-----------------------------REXX----------------------------------*\
 *  Check common code file for WSDL copybooks,                       *
 *  and check that no COPYBOOK elements exist in the same system.    *
\*-------------------------------------------------------------------*/
trace n

arg c1sy copydsn

say 'WSDLCOMM:' Date() Time()
say 'WSDLCOMM:'
say 'WSDLCOMM: c1sy............:' c1sy
say 'WSDLCOMM: copydsn.........:' copydsn
say 'WSDLCOMM:'

exit_rc = 0

/* Read a list of similarly named elements                           */
"execio * diskr CSVLIST (stem csv. finis"
if rc ^= 0 then call exception rc 'DISKR of CSVLIST failed'

/* Create stem varable for any similarly named copybooks             */
do i = 1 to csv.0
  csvelt  = strip(substr(csv.i,39,8))
  csvtype = substr(csv.i,49,8)
  if csvtype = 'COPYBOOK' then
    copybook.csvelt = 'Y'
end /* i = 1 to csv.0 */

/* Get a list of copybooks from the temporary copybook dataset       */
x = outtrap('mems.')
"listds '"copydsn"' members"
if rc ^= 0 then call exception rc 'Error on listds for:' copydsn

/* Check the common code file and the copybook list for each member  */
do i = 7 to mems.0
  mem = strip(mems.i)
  if mem = '$$$SPACE' then
    iterate

  "call 'PREV.PEV1.LOAD(EVUNCOM)' '"mem",COPYBOOK,"c1sy"'"
  if rc > exit_rc then
    exit_rc = rc
  say "WSDLCOMM: Common code check for" left(mem,8)". RC =" rc

  /* Add a WSDL entry for the copybook so users can not add a        */
  /* copybook of the same name.                                      */
  "call 'PREV.PEV1.LOAD(EVUNCOM)' '"mem",WSDL,"c1sy"'"
  if rc > exit_rc then
    exit_rc = rc
  say "WSDLCOMM: Common code check for" left(mem,8)". RC =" rc

  if copybook.mem = 'Y' then do
    say   "WSDLCOMM: A copybook of the name '"mem"' already exists",
          "in system" c1sy
    queue " WSDLCOMM: A copybook of the name '"mem"' already exists",
          "in system" c1sy
    "execio 1 diskw README"
    if rc > 1 then call exception rc 'DISKW to README failed'
    if 8 > exit_rc then
      exit_rc = 8
  end /* copybook.mem = 'Y' */

end /* i = 7 to mems.0 */

exit exit_rc

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

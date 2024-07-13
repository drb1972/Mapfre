/*-----------------------------REXX----------------------------------*\
 *  Used on the Quick Edit panel.                                    *
 *  If the CCID or comment is a '@' then get the values from the     *
 *  existing element and replace them on the panel.                  *
 *  This is similar to using an '=' for CCID or comment but '='      *
 *  does not update the panel.                                       *
\*-------------------------------------------------------------------*/

/* If any of the location variables are blank then return            */
if qepelm   = '' | ,
   qepevnme = '' | ,
   qepsys   = '' | ,
   qepsbs   = '' | ,
   qeptyp   = '' then
  return

/* Set the stage name                                                */
select
  when qepevnme = 'UTIL' then stage = 'T'
  when qepevnme = 'UNIT' then stage = 'A'
  when qepevnme = 'SYST' then stage = 'C'
  when qepevnme = 'ACPT' then stage = 'E'
  when qepevnme = 'PROD' then stage = 'O'
  when qepevnme = 'ARCH' then stage = 'Y'
  otherwise return
end /* select */

address tso
/* Free in case there are hangovers. Do not code an exception call   */
test = msg(off)
"free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"
test = msg(on)

"alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

/* Build the input to the CSV utiltiy                                */
upper qepelm /* Only allowed for upper case elements                 */
inp.1 = '  LIST ELEMENT' qepelm
inp.2 = '    FROM ENV' qepevnme 'SYS' qepsys 'SUB' qepsbs
inp.3 = '         TYP' qeptyp 'STA' stage
inp.4 = '    OPTIONS SEARCH NOCSV .'
'execio 4 diskw csvipt01 (stem inp. finis)'
if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

/* Allocate files to process SCL                                     */
"alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

/* Allocate the necessary datasets                                  */
test = msg(off)
"alloc f(C1MSGSA) new space(1 1) tracks recfm(f b a) lrecl(134)"
if rc ^= 0 then call exception rc 'ALLOC of C1MSGSA failed.'
"alloc f(CSVMSGS1) new space(1 1) tracks recfm(f b a) lrecl(134)"
if rc ^= 0 then call exception rc 'ALLOC of CSVMSGS1 failed.'
"ALLOC F(BSTERR) SYSOUT(*)"
if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'
test = msg(on)

/* Invoke the CSV utility                                            */
address "LINKMVS" 'BC1PCSV0'
lnk_rc = rc

if lnk_rc = 4 then return /* Element not found                       */

if lnk_rc > 4 then do
  "execio * diskr csvmsgs1 (stem c1. finis"
  do i = 1 to c1.0
    say left(c1.i,79)
  end /* i = 1 to c1.0 */
  call exception lnk_rc 'Call to BC1PCSV0 failed'
end /* rc > 0 */

"free f(bsterr c1msgsa csvmsgs1 csvipt01)"

g = listdsi(apiextr file) /* Check for output                       */
if g = 0 then do
  "execio 1 diskr apiextr (stem elt. finis"
  "free f(apiextr)"
  elt_stg = substr(elt.1,65,1)
  if pos(elt_stg,'UPZ') = 0 then do
    if eevccid = '@' then
      eevccid = substr(elt.1,156,12)
    if eevcomm = '@' then
      eevcomm = substr(elt.1,168,40)
  end /* pos(elt_stg,'UPZ') = 0 */
  else do
    zrxrc  = 8
    zrxmsg = 'EVCC001E' /* Element at last stage so don't use it     */
  end /* else */
end /* g = 0 */

return

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso "free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 zrxrc = 8

exit return_code

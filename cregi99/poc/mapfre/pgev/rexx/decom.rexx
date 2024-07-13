/*-----------------------------REXX----------------------------------*\
 *  Reads a list of common elements in Endevor and removes           *
 *  records which are no longer common from the common code file.    *
\*-------------------------------------------------------------------*/
trace n

orphan = 0
common = 0

/* Read the API common element extract                               */
do until readrc = 2       /* loop til you just cant loop no more     */
  "execio 1 diskr common" /* read 1 line                             */
  readrc = rc             /* return code from execio                 */
  if readrc = 2 then leave
  if readrc > 2 then exit readrc /* I/O error                        */
  pull comline
  system  = left(comline,2)
  ele     = strip(substr(comline,4,8))
  type    = strip(substr(comline,13,8))
  wsdlele = substr(comline,31,5)
  if type = 'WSDL' then do
    apicom            = system || wsdlele || 'I'
    found_wsdl.apicom = 'yes'
    apicom            = system || wsdlele || 'O'
    found_wsdl.apicom = 'yes'
  end /* type = 'WSDL' */
  else do
    apicom       = system || ele
    found.apicom = 'yes'
  end /* else */
  say 'DECOM: API    SYS-' system 'ELE-' left(ele,8) ,
      'TYPE-' left(type,8) 'APICOMM-' apicom
end /* until readrc = 2 */

/* Read the common code file                                         */
"execio * diskr ACTUAL (stem act. finis"
if rc ^= 0 then call exception rc 'DISKR of ACTUAL failed'

do c = 1 to act.0

  comele  = strip(substr(act.c,1,8))
  comtyp  = substr(act.c,9,8)
  comsys  = substr(act.c,17,2)
  if comsys = '%%' then iterate
  comcode = comsys || comele
  if comtyp = 'COPYBOOK' | ,
     comtyp = 'WSDL'     then
    comcode_wsdl = comsys || left(comele,6)
  else
    comcode_wsdl = ''
  say 'DECOM: COMMON SYS-' comsys 'ELE-' left(comele,8) ,
      'TYPE-' left(comtyp,8) 'COMCODE-' left(comcode,10) ,
      'COMCODE_WSDL-' comcode_wsdl

  if found.comcode           <> 'yes' & ,
     found_wsdl.comcode_wsdl <> 'yes' then do
    say 'DECOM:      Element is no longer common' comsys ,
        left(comele,8) left(comtyp,8)
    orphan = orphan + 1
  end /* found.comcode <> 'yes' & ... */
  else do
    queue act.c
    common = common + 1
  end /* else */

end /* c = 1 to act.0 */

prevtot = act.0 - 2
say 'DECOM:'
say 'DECOM: There are ' right(common,10) 'common elements remaining'
say 'DECOM: There are ' right(orphan,10) 'orphaned elements to be' ,
    'removed'
say 'DECOM: There were' right(prevtot,10) 'common code entries before'

/* Queue dummy records to the file                                   */
queue "9999999999999999%%"
push  "                %%"
/* Write out the new file                                            */
"execio" queued() "diskw NEWCOM (finis)"
if rc ^= 0 then call exception rc 'DISKW to NEWCOM failed'

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

/*-----------------------------REXX----------------------------------*\
 *  Relate WSDL input & output components.                           *
 *  Relate XSD input components.                                     *
\*-------------------------------------------------------------------*/
trace n
parse arg c1en c1si c1stage c1su c1elmnt255

say 'WSDLREL:' Date() Time()
say 'WSDLREL:'
say 'WSDLREL: c1en............:' c1en
say 'WSDLREL: c1si............:' c1si
say 'WSDLREL: c1stage.........:' c1stage
say 'WSDLREL: c1su............:' c1su
say 'WSDLREL: c1elmnt255......:' c1elmnt255
say 'WSDLREL:'

wsdl = translate(c1elmnt255,' ','.')
parse value wsdl with wsdl_name extension

c1su3   = substr(c1su,3,1)
xsds    = 0
exit_rc = 0

say 'WSDLREL:'
say 'WSDLREL: Searching through the LOG file for XSDs'
say 'WSDLREL:'

do i = 1  until readrc = 2
  "execio 1 diskr LOG"
  readrc = rc
  if readrc > 2 then call exception rc 'DISKR of LOG failed'
  if readrc = 2 then leave
  parse pull line

  if subword(line,1,2) = 'ICM as' then
    leave
  parse value line with gunk msg fullname rest

  if msg = 'loaded:' & ,
     right(fullname,4) = '.xsd' then do
    names = translate(fullname,' ','/')
    x     = words(names)
    xsd   = subword(names,x)
    if xsd.xsd ^= 'found' then do
      xsd.xsd  = 'found'
      xsds     = xsds + 1
      xsd.xsds = xsd
    end /* xsd.xsd ^= 'found' */
  end /* msg = 'loaded:' & ... */

end /* i = 1  until readrc = 2 */

/* Read the list of all XSDs in all systems to get the short names   */
"execio * diskr XSDLIST (stem xsdlist. finis"
if rc ^= 0 then call exception rc 'DISKR of XSDLIST failed'

/* Relate WSDL                                                       */
queue "RELATE OBJECT"
queue "'*/"c1si || c1su"/WSDL/"c1elmnt255"' ."
queue "RELATE OBJECT"
queue "'*/"c1si"##"c1su3"/WSDL/GENDIR/"c1elmnt255"' ."

/* Relate XSDs as objects to list the full element names             */
say 'WSDLREL:' xsds 'loaded XSDs found'
do i = 1 to xsds
  say 'WSDLREL:' xsd.i
  /* XSD is related as an object for ACMQ searches                   */
  queue "RELATE OBJECT"
  queue "'"xsd.i"' ."

  /* Build FILEAID cards of XSD short names for component validation */
  xsd_found = 'N'
  do x = 1 to xsdlist.0
    if substr(xsdlist.x,10,255) = xsd.i then do
      if i = 1 then
        if xsds = 1 then
          copy.1 = '$$DD01 COPY MEMBER='left(xsdlist.x,8)
        else
          copy.1 = '$$DD01 COPY MEMBER=('left(xsdlist.x,8)','
      else
        if i = xsds then
          copy.i = '        'left(xsdlist.x,8)')'
        else
          copy.i = '        'left(xsdlist.x,8)','
      xsd_found  = 'Y'
      leave x
    end /* substr(xsdlist.x,10,255) = xsd.i */
  end /* i = 1 to xsdlist.0 */
  if xsd_found = 'N' then do
    delstack
    say 'WSDLREL: XSD not found in Endevor map' xsd.i
    queue 'WSDLREL: XSD not found in Endevor map'
    queue 'WSDLREL: ' xsd.i
    "execio * diskw README (finis"
    if rc ^= 0 then call exception rc 'DISKW to README failed'
    exit_rc = 12
  end /* xsd_found = 'N' */

end /* i = 1 to xsds */

/* Relate WSBINDs                                                    */
queue "RELATE OBJECT"
queue "'*/"c1si || c1su"/WSBIND/"wsdl_name".wsbind' ."
queue "RELATE OBJECT"
queue "'*/###"c1su3"/WSBIND/"wsdl_name".wsbind' ."

"execio * diskw RELATE (finis"
if rc ^= 0 then call exception rc 'DISKW to RELATE failed'

if xsds = 0 then
  exit_rc = 4
else do
  "execio" xsds "diskw FACARDS (stem copy. finis"
  if rc ^= 0 then call exception rc 'DISKW to FACARDS failed'
end /* else */

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

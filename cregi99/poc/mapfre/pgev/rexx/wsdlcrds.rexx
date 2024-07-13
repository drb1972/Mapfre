/*--------------------------REXX----------------------------*\
 *  This REXX is used by the MWSDL and DWSDL processors     *
 *  to build BSTCOPY select statement for MWSDL.            *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace n

arg c1element action c1stgid c1subsys

dsn = 'PREV.'c1stgid || c1subsys'.COPYBOOK'

queue "  COPY O=OUTDD,I=INDD"

say 'WSDLCRDS: Reading the component list'

/* Read in the component list output */
"execio * diskr C1PRINT (stem line. finis)"
if rc ^= 0 then do
  say 'WSDLCRDS: EXECIO of the C1PRINT ddname failed. RC='rc
  call exception 12
end

/* Write the component list for debugging */
"execio" line.0 "diskw COMPLIST (stem line. finis"
if rc ^= 0 then do
  say 'WSDLCRDS: EXECIO of the COMPLIST ddname failed. RC='rc
  call exception 12
end

say 'WSDLCRDS: Looping through the 'line.0' records in the C1PRINT file'

do i = 1 to line.0 while llq ^= 'COPYBOOK'
  if word(line.i,1) = 'STEP:' then
    llq = right(word(line.i,5),8) /* Dataset from the component list */
end

do a = i to line.0

  /* Stop at the next DSN in the component list */
  if word(line.a,1) = 'STEP:' then
    leave

  mem = word(line.a,2)
  ele = word(line.a,8)
  /* If the element name matches the component list elt name */
  /* we can build a statement depending on the action.       */
  /* This exludes header records.                            */
  if ele = c1element then do
    say 'WSDLCRDS:'
    say 'WSDLCRDS: Found entry' mem 'for the library' dsn
    say 'WSDLCRDS: will build the SELECT statement'

    queue "  SELECT MEMBER=(("mem",,R))"

  end /* if ele = c1element then do */

end /* end do */

"execio" queued() "diskw COMMANDS (finis"
if rc ^= 0 then do
  say 'WSDLCRDS: EXECIO of the COMMANDS ddname failed. RC='rc
  call exception 12
end

exit 0

/*-------------------------- S U B R O U T I N E S -------------------*/

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 arg return_code

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code

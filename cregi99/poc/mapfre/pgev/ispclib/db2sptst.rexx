/*-----------------------------REXX----------------------------------*\
 *  Check bind processor group matches the SPDEF procesor group for  *
 *  DB2 stored procedures.                                           *
 *                                                                   *
 *  Called by GDB2SP, GBIND, MDB2SP & MBIND                          *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

exit_rc = 0 /* set the initial exit return code                      */
parse arg c1element c1ty c1prgrp

say rexxname':' Date() Time()
say rexxname':'
say rexxname': Element......... :' c1element
say rexxname': Type............ :' c1ty
say rexxname': Processor group. :' c1prgrp
say rexxname':'

if c1ty   = 'BIND' then
  alttype = 'SPDEF'
else
  alttype = 'BIND '

/* read results of CSV step                                          */
'execio * diskr CSVLIST (stem csvlist. finis'
if rc ^= 0 then call exception rc 'DISKR of CSVLIST failed'

if csvlist.0 = 0 then exit 0 /* no records in the CSV report         */

altenv   = strip(substr(csvlist.1,15,8))
altsys   = strip(substr(csvlist.1,23,8))
altsub   = strip(substr(csvlist.1,31,8))
altstg   = strip(substr(csvlist.1,65,1))
altprgrp = substr(csvlist.1,71,8) /* processor group from CSV report */

if c1prgrp ^= altprgrp then do
  queue rexxname':'
  queue rexxname': Caution, BIND & SPDEF processor groups must match'
  queue rexxname':'
  queue rexxname': Caution for' c1ty 'element' c1element
  queue rexxname':' c1ty 'processor group' c1prgrp 'does not match'
  queue rexxname':' alttype 'processor group' altprgrp
  queue rexxname':'
  queue rexxname': The' c1element 'type' alttype 'was located in'
  queue rexxname': Environment ..' altenv
  queue rexxname': System .......' altsys
  queue rexxname': Subsystem ....' altsub
  queue rexxname': Stage ........' altstg
  queue rexxname':'
  'EXECIO' queued() 'DISKW READMESP (finis'
  if rc ^= 0 then call exception rc 'DISKW of READMESP failed'
  exit_rc = 20
end /* c1prgrp ^= altprgrp */

exit exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg('off')
 address tso 'delstack' /* Clear down the stack                      */
 z = msg('on')

 if return_code < 12 | return_code > 4095 then return_code = 12

exit return_code

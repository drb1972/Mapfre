/*-----------------------------REXX----------------------------------*\
 *  Just a simple FTINCL then edit or submit                         *
\*-------------------------------------------------------------------*/
trace n

arg skelid option

sysuid = sysvar('sysuid')

address ispexec
"VGET (zprefix) SHARED"
jobname = zprefix || left(skelid,4)

'ftopen temp'
'ftincl' skelid
if rc ^= 0 then call exception rc 'FTINCL of' skelid 'failed'
'ftclose'
'vget (ztempn)'
if option = 'S' then do
  'vget (ztempf)'
  address tso "submit '"ztempf"'"
end /* option = 'S' */
else do
  'vget (ztempn)'
  'lminit dataid(did) ddname('ztempn')'
  'edit dataid('did') macro(WAMACJ)'
  'lmclose dataid('did')'
  'lmfree  dataid('did')'
end /* else */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso delstack /* Clear down the stack                        */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

 if address() = 'ISPEXEC' then
   'ftclose'

 if left(address(),3) = 'ISP' then do
   zispfrc = return_code
   address ispexec "VPUT (ZISPFRC) SHARED"
 end /* left(address(),3) = 'ISP' */

exit return_code

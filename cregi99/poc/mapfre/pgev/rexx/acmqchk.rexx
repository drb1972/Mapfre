/*-----------------------------REXX----------------------------------*\
 *  Analyse ACMQ output from processors and only write output if     *
 *  relevant components are found.                                   *
 *  Executed by PROCINC ACMQ                                         *
\*-------------------------------------------------------------------*/
trace n

arg c1element c1ty

say 'ACMQCHK:' Date() Time()
say 'ACMQCHK:'
say 'ACMQCHK: C1element.......:' c1element
say 'ACMQCHK: C1ty............:' c1ty
say 'ACMQCHK:'

"execio * diskr ACMIN (stem acmq. finis"
if rc ^= 0 then call exception rc 'DISKR of ACMIN failed.'

found = 0

do i = 1 to acmq.0
  if datatype(substr(acmq.i,6,1)) = 'NUM' then do
    elt = substr(acmq.i,12,8)
    typ = substr(acmq.i,25,8)
    if elt = c1element             & ,
       (typ = c1ty | typ = 'BIND') then
      nop
    else do
      found = 1
      leave
    end /* else */
  end /* datatype(substr(acmq.i,7,1)) = 'NUM' */
end /* i = 1 to acmq.0 */

if found then do
  "execio * diskw ACMOUT (stem acmq. finis"
  if rc ^= 0 then call exception rc 'DISKW to ACMOUT failed.'
  exit 6
end /* found */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

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

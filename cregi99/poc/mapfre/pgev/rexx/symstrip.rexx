/*--------------------------REXX----------------------------*\
 *  This REXX takes CA CSV COPYBOOKS as input and selects   *
 *  only the response block variables.                      *
 *  E.g. TTIG.SYSNDVR.R14.CAI.CSIQOPTN(ECHALELM)            *
 *  It is used in GSYM.                                     *
\*----------------------------------------------------------*/
trace n

"execio * diskr in (stem line. finis"
if rc ^= 0 then call exception 12 'DISKR of IN failed. RC='rc

start_found = 0

do i = 1 to line.0

  /* Stop at the next 01 level                                       */
  if start_found & ,
     substr(line.i,8,2) = '01' then
    leave

  /* Start at the first 01 level that has RS. in the variable name   */
  if substr(line.i,8,2) = '01' & ,
     pos('-RS.',line.i) > 0    then
    start_found = 1

  if start_found then
    queue line.i

end

"execio" queued() "diskw out (finis"
if rc ^= 0 then call exception 12 'DISKW to OUT failed. RC='rc

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

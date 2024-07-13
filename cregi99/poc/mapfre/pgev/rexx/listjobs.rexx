/*-----------------------------REXX----------------------------------*\
 *  Rexx to list failed Endevor jobs in CA7 queues.                  *
 *  If any found, email results to Endevor Support mailbox           *
 *                                                                   *
 *  Executed in jobs EVHCHK%D.                                       *
\*-------------------------------------------------------------------*/
trace n

arg ca7locn

say 'LISTJOBS:' Date() Time()
say 'LISTJOBS:'
say 'LISTJOBS: Ca7locn.........:' ca7locn
say 'LISTJOBS:'
say 'LISTJOBS: Reviewing the output from CA7'ca7locn' for failed jobs'

total = 0 /* Total number of request responses                       */
err   = 0 /* Set the exit return code to 0                           */

"execio * diskr CA7IN (stem in. finis)"
if rc > 0 then call exception rc 'DISKR of CA7IN failed'

do j = 1 to in.0 /* Read the output from the batch terminal          */

  say in.j /* Write out the CA7 output line                          */
  jobname = word(in.j,1)

  select
    when pos('REQUEST COMPLETED',in.j) > 0 then total = total + 1

    when datatype(right(jobname,6),'N') then do /* Not ODDJOB jobs   */
      select
        when left(jobname,2) = 'R0' then call printerr /* Check Rjobs*/
        when left(jobname,2) = 'C0' then call printerr /* Check Cjobs*/
        when left(jobname,2) = 'B0' then call printerr /* Check Bjobs*/
        when left(jobname,2) = 'M0' then call printerr /* Check Mjobs*/
        otherwise nop
      end /* select */
    end /* datatype(substr(in.j,3,6),'N') */

    when left(jobname,2) = 'EV' then call printerr /* Check EVjobs   */

    otherwise nop
  end /* select */

end /* j = 1 to in.0 */

queue ' CA7LOCATION =' ca7locn '.' /* queue the output string        */

"execio" queued() "diskw ERROUT (finis)"
if rc > 0 then call exception rc 'DISKW to ERROUT failed'

if total < 5 then do
  err = 12
  say 'LISTJOBS:'
  say 'LISTJOBS: ERROR - THERE WAS A PROBLEM WITH THE BATCH TERMINAL'
  say 'LISTJOBS:       - Less than 8 LQ ca7 commands were processed '
  say 'LISTJOBS:       - Please check report above for errors       '
end /* total < 5 */

exit err

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Create output string and queue for writing later                  */
/*-------------------------------------------------------------------*/
printerr:

 in.j = strip(in.j,'t') /* remove trailing blanks                    */
 in.j = in.j' .' /* add a full stop to seperate each line            */
 queue in.j
 err = 1 /* set exit return code to trigger the e-mail               */

return /* printerr: */

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
   address tso 'delstack' /* Clear down the stack                    */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

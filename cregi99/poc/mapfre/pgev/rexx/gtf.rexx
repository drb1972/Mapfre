/*-----------------------------REXX----------------------------------*\
 *  Start or stop the GTF trace for the package dataset.             *
\*-------------------------------------------------------------------*/
trace n

arg action

say 'GTF:' Date() Time()
say 'GTF:'
say 'GTF: Action..........:' action
say 'GTF:'

select
  when action = 'START' then do
    /* Start the GTF trace                                           */
    call issue_command 'S GTFEV.GTFEV'

    /* Check that the trace has started                              */
    do z = 1 to 5
      say 'GTF: Check that GTFEV is active:' z
      call issue_command 'D A,GTFEV'

      do i = 1 to output.0
        if left(word(output.i,1),3) = 'OPS' then
          if word(output.i,2) = 'GTFEV' then do
            status = word(output.i,5)
            if status = 'NSW'    | ,
               status = 'NSWPRS' then
              leave z
          end /* word(output.i,2) = 'GTFEV' */
          else nop
        else
          if word(output.i,1) = 'GTFEV' then do
            status = word(output.i,4)
            if status = 'NSW'    | ,
               status = 'NSWPRS' then
              leave z
          end /* word(output.i,1) = 'GTFEV' */
      end /* i = 1 to output.0 */
      wait_a_bit = opswait(30)
    end /* z = 1 to 5 */

    if z = 6 then do
      say 'GTF: GTFEV task is not starting!'
      exit 98
    end /* z = 6 */

    /* Reply 'u' to WTOR issued from start trace command             */
    say 'GTF:'
    say 'GTF: Will reply U to WTOR issued from start trace command'
    call issue_command 'D R,L' /* Display current WTORs              */

    do i = 1 to output.0
      if left(word(output.i,1),3) = 'OPS' then
        if word(output.i,5) = 'AHL125A' then do
          rplyno = word(output.i,2)
          call issue_command 'R' rplyno',U'
          replied = 'Y'
          leave i
        end /* word(output.i,5) = 'AHL125A' */
        else nop
      else
        if word(output.i,4) = 'AHL125A' then do
          rplyno = word(output.i,1)
          call issue_command 'R' rplyno',U'
          replied = 'Y'
          leave i
        end /* word(output.i,4) = 'AHL125A' */
    end /* i = 1 to output.0 */

    if replied ^= 'Y' then do
      say 'Reply to WTOR has not worked'
      exit 99
    end /* replied ^= 'Y' */

    /* Start the VSAM Record Management Trace                        */
    call issue_command 'S IDAVDT'
    wait_a_bit = opswait(30)
    call issue_command 'F IDAVDT,READIN'

  end /* action = 'START' */

  when action = 'STOP' then do
    /* Stop the VSAM Record Management Trace                        */
    call issue_command 'STOP IDAVDT'
    /* Stop the GTF trace                                           */
    call issue_command 'P GTFEV'
  end /* action = 'STOP' */

  otherwise do
    say 'GTF: Invalid action -' action
    exit 12
  end /* otherwise */

end /* select */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Issue OPS command                                                 */
/*-------------------------------------------------------------------*/
issue_command:
 arg command

 say 'GTF:'
 say 'GTF: Executing command "'command'"'
 x = outtrap(output.)
 "OPSCMD COMMAND('"command"')"
 do i = 1 to output.0
   say output.i
 end /* i = 1 to output.0 */

return /* issue_command: */

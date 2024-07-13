/*--------------------------REXX----------------------------*\
 * This rexx checks for a processor group change when       *
 * an element is being moved.                               *
 * See processor DEAR for example JCL.                      *
 *----------------------------------------------------------*
 *  Author:     Endevor Support                             *
\*----------------------------------------------------------*/
trace n

proc_start = 0
exit_rc    = 0

say 'PRGRPCH: Checking for a processor group change'
say 'PRGRPCH:'

/* Wait 30 seconds to allow the output to be written to SDSF */
w = opswait(30)

jobname = mvsvar('SYMDEF',jobname)
if jobname = 'EAPISVR' then
  ddname = 'EN$DPMSG'
else
  ddname = 'C1MSGS1'

/* Read C1MSGS1 from SDSF */
sdsf.1 = "SET DISPLAY ON"               /* for debugging */
sdsf.2 = "PRE" jobname
sdsf.3 = "DA"
sdsf.4 = "SYSNAME *"
sdsf.5 = "FIND" jobname
sdsf.6 = "++?"
sdsf.7 = "FIND" ddname "LAST"
sdsf.8 = "++S"
sdsf.9 = "PRINT FILE EMSGS"
sdsf.10= "PRINT"
sdsf.11= "PRINT CLOSE"

"alloc f(ISFIN) new space(2 2) cylinders recfm(f b) lrecl(80)"
if rc ^= 0 then call exception 12 'Allocate ISFIN failed. RC='rc
"execio 11 diskw ISFIN (stem sdsf. finis"
if rc ^= 0 then call exception 12 'DISKW to ISFIN failed. RC='rc
"alloc f(EMSGS) new space(2 2) cylinders recfm(f b) lrecl(132)"
if rc ^= 0 then call exception 12 'Allocate EMSGS failed. RC='rc
"CALL *(ISFAFD)"            /* Call SDSF */
if rc ^= 0 then call exception 12 'Call SDSF failed. RC='rc
/* Read the output */
"EXECIO * DISKR EMSGS (STEM line. FINIS"
if rc ^= 0 then call exception 12 'DISKR from EMSGS failed. RC='rc
"free f(EMSGS ISFIN)"
if rc ^= 0 then call exception 12 'FREE EMSGS failed. RC='rc

/* Ok, look for C1G0012W - processor group change */
/* Only interested in the last action             */

/* Read the SDSF output backwards                                    */
say 'PRGRPCH: Reading' ddname 'to find if the processor group changes'
say 'PRGRPCH: '
do i = line.0 to 1 by -1
  if pos('C1G0143I',line.i) > 0 then do
    proc_start = i - 1 /* pick up previous message                   */
    proc_type  = word(line.i,6)
    proc_name  = word(line.i,8)
    say 'PRGRPCH: Found' proc_type 'processor called' proc_name,
        'starting at line' i
    say
    say strip(line.i)
    say
    leave
  end /* pos('C1G0143I',line.i) > 0 */
end /* i = line.0 to 1 */

if proc_start = 0 then do
  say 'PRGRPCH: Error - Message C1G0143I not found'
  exit 12
end /* if proc_start = 0 then do                                     */

/* Go back to locate previous message & check if proc group change   */
do i = proc_start to 1 by -1

  /* see if the previous line was a message                          */
  if substr(word(line.i,1),3,1) = ':' then do

    if pos('C1G0012W',line.i) > 0 then do
      say 'PRGRPCH: Processor group change found at line' i
      say
      say strip(line.i)
      say
      exit_rc = 1
      leave
    end /* pos('C1G0012W',line.i) > 0 */

    else leave /* it is a message but not C1G0012W                   */

  end /* if substr(word(line.i,1),3,1) = ':' then do                 */

  else iterate /* get the previous record as this one is not a msg   */

end /* do i = proc_start to 1 by -1                                  */

if exit_rc = 0 then say 'PRGRPCH: Processor group change not detected',
                        'or it is a delete from source'

exit exit_rc

/*---------------------- S U B R O U T I N E S -----------------------*/

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 parse arg return_code comment

 do i = 1 to queued() /* Clear down the stack */
   pull
 end

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

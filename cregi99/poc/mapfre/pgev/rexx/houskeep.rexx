/*-----------------------------REXX----------------------------------*\
 *  This routine reads CA7 batch terminal output when the Endevor    *
 *  housekeeping is being cancelled.                                 *
 *  It uses the resulting output to clear up the CA7 queues to       *
 *  ensure everything is in the correct status.                      *
\*-------------------------------------------------------------------*/
trace n

say
say 'HOUSKEEP:' Date() Time()
say 'HOUSKEEP:'
say 'HOUSKEEP: Endevor housekeeping has been cancelled,'
say 'HOUSKEEP:  CA7 request queue is being tidied up.'
say 'HOUSKEEP:'
say

/* set the initial value of variables                                */
already_cancelled = 0
e = 0 /* this counter will be used for building the email report     */

"execio * diskr CA7OUT (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of DDname CA7OUT failed.'

do a = 1 to line.0 /* loop through the CA7 batch terminal output     */
  say line.a
  select /*extract usable variables from the output                  */

    when left(word(line.a,1),2) = 'EV' then do /* is it an EV job?   */
      jobname = word(line.a,1)
      if jobname = 'EVHPXPED' then call evhpxped
    end /* left(word(line.a,1),2) = 'EV' */

    when word(line.a,2) = 'INTERNAL' then do
      rqmt = word(line.a,3)
      rqmt = substr(rqmt,5) /* remove the JOB= bit of the word       */
      if jobname = 'EVHPACKM' | ,
         jobname = 'EVHEMERD' | ,
         left(jobname,3) = 'EVD' | ,
         left(jobname,6) = 'EVH000' then
        call post_rqmt
    end /* word(line.a,2) = 'INTERNAL' */
    otherwise nop
  end /* select */

end /* a = 1 to line.0 */

if e = 0 then
  call exception 4 'No records on CA7P04 found!!'

'execio * diskw email (stem mail. finis'
if rc ^= 0 then call exception rc 'DISKW to DDname EMAIL failed.'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Issue CA7 commands to tidy up failed job                          */
/*-------------------------------------------------------------------*/
evhpxped:
 if already_cancelled = 1 then return /* already been here           */

 /* Use the CA7 API to post the virtual resource                     */
 call @CA7RXIF("P04 YE ",
   "PRSCF,JOB=EVHPXPED,DSN=ENDEVOR.DUMPS.RUNNING")

 if result <> 0 then do /* Error encountered from CA7/rexx           */
   do y = 1 to queued   /* Loop round error messages                 */
     pull ca7out.y      /* get next error message                    */
     say ca7out.y       /* Print to SYSTSPRT                         */
   end /* y = 1 to queued */
   call exception result 'CA7 PRCSF command has failed.'
 end /* result <> 0 */

 delstack /* Clear down the stack                                    */

 e = e + 1
 mail.e = 'HOUSKEEP issued PRSCF,JOB=EVHPXPED,DSN=ENDEVOR.DUMPS.RUNNING.'

 /* Use the CA7 API to cancel the failed job from CA7P04             */
 call @CA7RXIF("P04 YE CANCEL,JOB=EVHPXPED")

 if result <> 0 then do /* Error encountered from CA7/rexx           */
   do y = 1 to queued   /* Loop round error messages                 */
     pull ca7out.y      /* get next error message                    */
     say ca7out.y       /* Print to SYSTSPRT                         */
   end /* y = 1 to queued */
   call exception result 'CA7 PRCSF command has failed.'
 end /* result <> 0 */

 delstack /* Clear down the stack                                    */

 e = e + 1
 mail.e = 'HOUSKEEP issued CANCEL,JOB=EVHPXPED.'
 e = e + 1
 mail.e = ''

 already_cancelled = 1 /* set the flag after the first visit         */

return /* evhpxped: */

/*-------------------------------------------------------------------*/
/* Post outstanding job requirements                                 */
/*-------------------------------------------------------------------*/
post_rqmt:

 select

   when rqmt = 'EVH0SMFD' then return /* don't post this rqmt        */
   when rqmt = 'EVHEMERD' then return /* don't post this rqmt        */
   when rqmt = 'EVHPACKM' then return /* don't post this rqmt        */

   otherwise do
     /* Use the CA7 API to cancel the failed job from CA7P04         */
     call @CA7RXIF("P04 YE POST,JOB="jobname",DEPJOB="rqmt)

     if result <> 0 then do /* Error encountered from CA7/rexx       */
       do y = 1 to queued   /* Loop round error messages             */
         pull ca7out.y      /* get next error message                */
         say ca7out.y       /* Print to SYSTSPRT                     */
       end /* y = 1 to queued */
       call exception result 'CA7 PRCSF command has failed.'
     end /* result <> 0 */

     delstack /* Clear down the stack                                */

     e = e + 1
     mail.e = 'HOUSKEEP Posted requirement' rqmt 'from job' jobname'.'
   end /* otherwise */

return /* post_rqmt: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code

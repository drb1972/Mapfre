/*-----------------------------REXX----------------------------------*\
 *  Get job information to send back by email for TTEVUSS jobs.      *
 *  The JCL is built be rexx SUBSCL.                                 *
\*-------------------------------------------------------------------*/
trace n

arg uid

say 'JOBDTLS:' Date() Time()
say 'JOBDTLS:'

/* Read C1MSGS2                                                      */
"execio * diskr C1MSGSIN (stem c1msgs2. finis"
if rc ^= 0 then call exception rc 'DISKR of C1MSGSIN failed.'

/* Write C1MSGS2                                                     */
"execio * diskw C1MSGS2 (stem c1msgs2. finis"
if rc ^= 0 then call exception rc 'DISKW to C1MSGS2 failed.'

/* Work out job number                                               */
ascb      = c2x(storage(224,4))
assb      = c2x(storage(d2x(x2d(ascb)+336),4))
jsab      = c2x(storage(d2x(x2d(assb)+168),4))
jobid     = storage(d2x(x2d(jsab)+20),8)
say 'JOBDTLS: Job number' jobid

/* Work out job name                                                 */
thisjob   = mvsvar('SYMDEF','JOBNAME')
say 'JOBDTLS: Job Name  ' thisjob

status = 'SUCCESSFUL'
do i = 1 to c1msgs2.0
  if word(c1msgs2.i,1) = '*FAILED*' then
    status = '*FAILED*'
end

queue 'FROM: endevor@rbos.co.uk'
queue 'TO:' uid'@rbos.co.uk'
queue 'SUBJECT: JOB' thisjob'('jobid')' status

/* Write SYSADDR email header                                        */
"execio * diskw SYSADDR (finis"
if rc ^= 0 then call exception rc 'DISKW to SYSADDR failed.'

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

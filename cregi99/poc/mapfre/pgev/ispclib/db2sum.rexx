/*-----------------------------REXX----------------------------------*\
 *  Concatenate BIND summary output from multple element generates   *
 *  in one job.                                                      *
 *  Output goes to a single DD called BINDSUM.                       *
 *  See GBIND for sample JCL                                         *
\*-------------------------------------------------------------------*/
trace n

say 'DB2SUM:'

/* Allocate BINDTMP which is used to pass the concatenated summary   */
/* output from one action to the next.                               */
stat = MSG('off')
"alloc fi(BINDTMP) lrecl(134) NEW"
stat = MSG('on')
'execio * diskr BINDTMP (stem bindtmp. finis'
if rc ^= 0 then call exception 20 'DISKR of BINDTMP failed RC='rc

/* Read the SUMMARY output from this BIND action                     */
'execio * diskr SUMMARY (stem summary. finis'
if rc ^= 0 then call exception 20 'DISKR of SUMMARY failed RC='rc

/* Concatenate all output and write to the BINDTMP file to be picked */
/* up in the next action                                             */
"free  fi(BINDTMP)"
"alloc fi(BINDTMP) lrecl(134) NEW"
if bindtmp.0 > 0 then do
  'execio * diskw BINDTMP (stem bindtmp.'
  if rc ^= 0 then call exception 20 'DISKW to BINDTMP failed RC='rc
  queue copies('=',80)                         /* Add separator line */
  'execio 1 diskw BINDTMP'
end /* bindtmp.0 > 0 */
'execio * diskw BINDTMP (stem summary. finis'
if rc ^= 0 then call exception 20 'DISKW to BINDTMP failed RC='rc

/* Allocate the BINDSUM output DD, this is done in this rexx not     */
/* the processor so that only one file is allocated for mutiple      */
/* actions.                                                          */
/* The file is realloacted to put it at the end of the output DD list*/
if bindtmp.0 > 0 then do            /* Only do it for multiple binds */
  say 'DB2SUM: Concatenating BIND summary output to BINDSUM'
  stat = MSG('off')
  "free  fi(BINDSUM) delete"
  stat = MSG('on')
  "alloc fi(BINDSUM) SYSOUT"
  if bindtmp.0 > 0 then do
    'execio * diskw BINDSUM (stem bindtmp.'
    if rc ^= 0 then call exception 20 'DISKW to BINDSUM failed RC='rc
    queue copies('=',80)                       /* Add separator line */
    'execio 1 diskw BINDSUM'
  end /* bindtmp.0 > 0 */
  'execio * diskw BINDSUM (stem summary. finis'
  if rc ^= 0 then call exception 20 'DISKW to BINDSUM failed RC='rc
end /* bindtmp.0 > 0 */
else
  say 'DB2SUM: This is the first BIND so nothing to concatenate'

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

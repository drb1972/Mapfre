/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This Rexx is used by the MDEPLOY process to build the trigger | */
/* | file.                                                         | */
/* |                                                               | */
/* | Date     : March 2009                                         | */
/* |                                                               | */
/* | Name     : PGEV.BASE.REXX(EVTRGR)                             | */
/* | Author   : Stuart Ashby                                       | */
/* |                                                               | */
/* | The Processor JCL should look something like this:            | */
/* |                                                               | */
/* |   //EVUSS01  EXEC PGM=IRXJCL,MAXRC=0                          | */
/* |   -INC EVEXECR                                                | */
/* |   //SYSTSPRT DD SYSOUT=&SYSOUT                                | */
/* |   //TRIGGER  DD DISP=SHR,DSN=&USSTRGR(&C1ELEMENT)             | */
/* |   //FILENAME DD *                                             | */
/* |   &C1ELMNT255                                                 | */
/* |   //SYSTSIN  DD DUMMY                                         | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */
trace o

/* Read in and process the files to be shipped */
"execio * diskr FILENAME (stem filename. finis"
if rc > 0 then do
  say 'EVTRGR: Return code from the execio of ddname FILENAME was 'rc
  call exception 12
end /* if rc > 0 then do */

do i = 1 to filename.0
  say 'EVTRGR: USS element 'filename.i
  queue filename.i
end /* do i = 1 to filename.0 */

"EXECIO" queued() "DISKW TRIGGER"
if rc > 0 then do
  say 'EVTRGR: Return code from the execio of ddname TRIGGER was 'rc
  call exception 12
end /* if rc > 0 then do */

exit

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 arg return_code

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code

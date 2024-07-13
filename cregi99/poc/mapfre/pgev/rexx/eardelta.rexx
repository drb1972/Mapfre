/*--------------------------REXX-----------------------------*\
 *  This REXX is used by the MEAR processor to delete DBRMs  *
 *  from the target DBRMLIB if the SER file has been deleted *
 *  from the new DELTA EAR file.                             *
 *-----------------------------------------------------------*
 *  Author:     Emlyn Williams                               *
 *              Endevor Support                              *
\*-----------------------------------------------------------*/
trace n

arg c1element c1stgid c1subsys

say 'EARDELTA: Reading the component list'
"execio * diskr C1PRINT (stem line. finis)"
if rc ^= 0 then do
  say 'EARDELTA: Execio diskr of the C1PRINT ddname failed RC =' rc
  call exception 12
end /* if rc ^= 0 then do */

/* Write out the report output for debugging */
"execio" line.0 "diskw COMPLIST (stem line. finis)"
if rc ^= 0 then do
  say 'EARDELTA: Execio diskw of the COMPLIST ddname failed RC =' rc
  call exception 12
end /* if rc ^= 0 then do */

/* Build the name of the dataset the members will deleted from */
deldsn = 'PREV.'||c1stgid||c1subsys||'.DBRMLIB'
say 'EARDELTA: This is a MOVE of a delta EAR file.'
say 'EARDELTA: If any SERs have been deleted in this new delta EAR then'
say 'EARDELTA: the DBRMs will deleted from target dsn.' deldsn

address ispexec
"LMINIT DATAID(dataid) DATASET('"deldsn"') ENQ(SHRW)"
"LMOPEN DATAID("dataid") OPTION(OUTPUT)"

/* Loop through the rest of the component list to search for deleted */
/* SERs listed in the comments section of the component list.        */
do x = 1 to line.0
  if word(line.x,2) = 'Deleted:' then do
    member = word(line.x,3)
    say 'EARDELTA:  Deleting' member
    "LMMDEL DATAID("dataid") MEMBER("member")"
    say 'EARDELTA:  RC =' rc
    if rc > 8 then do
      say 'EARDELTA: Delete of member' member 'failed.'
      call exception 12
    end /* rc > 8 */
  end /* word(line.x,2) = 'Deleted:' */
end /* do x = a to line.0 */

if member = 'MEMBER' then         /* no matches */
  say 'EARDELTA: No SER files have been deleted from the EAR file.'

"LMCLOSE DATAID("dataid")"
"LMFREE DATAID("dataid")"

exit

/*-------------------------- S U B R O U T I N E S -------------------*/

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 arg return_code

 zispfrc = return_code
 address ispexec "VPUT (ZISPFRC) SHARED"

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code

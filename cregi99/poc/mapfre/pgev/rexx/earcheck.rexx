/*-----------------------------REXX----------------------------------*\
 *  This Rexx is used by the GEAR to ensure that the EAR name is     *
 *  aligned with current standards.                                  *
\*-------------------------------------------------------------------*/
trace n

cc = 0  /* Set the exit cc if there are no errors found              */

/* Read in and process the files to be shipped                       */
"execio * diskr PARMS (stem parms. finis"
if rc ^= 0 then call exception rc 'DISKR of DDname PARMS failed'

sys = word(parms.1,1)
ele = word(parms.1,2)

say 'EARCHECK: Sys.....:' sys
say 'EARCHECK: Ele.....:' ele

queue 'EARCHECK: Element is called "'ele'"'
queue 'EARCHECK:         in system  'sys
queue 'EARCHECK:'

/* Check the first two chars and the system match                    */
if left(ele,2) ^= sys then do
  queue 'EARCHECK: The first two characters of the EAR file do not'
  queue 'EARCHECK: match the system name.                         '
  queue 'EARCHECK:                                                '
  queue 'EARCHECK: !!!!!!   THIS IS NOT ALLOWED !!!!!!            '
  queue 'EARCHECK:                                                '
  queue 'EARCHECK: Please delete the element and add it with the  '
  queue 'EARCHECK: first two characters being the same as the     '
  queue 'EARCHECK: Endevor system name.                           '
  queue 'EARCHECK:                                                '
  cc = 8
end /* left(ele,2) ^= sys */

/* Check the file extension is .ear                                */
if right(ele,4) ^= '.ear' then do
  queue 'EARCHECK: The file extension is not .ear in lower case.  '
  queue 'EARCHECK:                                                '
  queue 'EARCHECK: !!!!!!   THIS IS NOT ALLOWED !!!!!!            '
  queue 'EARCHECK:                                                '
  queue 'EARCHECK: Please delete the element and add it with the  '
  queue 'EARCHECK: .ear extension in lower case.                  '
  queue 'EARCHECK:                                                '
  cc = 8
end /* right(ele,4) ^= '.ear' */

/* Check only one full stop in the name                            */
dots = translate(ele,' ','.')
if words(dots) > 2 then do
  queue 'EARCHECK: The file can only have one full stop in the name.'
  queue 'EARCHECK:                                                  '
  queue 'EARCHECK: !!!!!!   THIS IS NOT ALLOWED !!!!!!              '
  queue 'EARCHECK:                                                  '
  queue 'EARCHECK: Please delete the element and add it with the    '
  queue 'EARCHECK: only one full stop e.g. earfilename.ear          '
  queue 'EARCHECK:                                                  '
  cc = 8
end /* words(dots) > 2 */

/* Check the element name is 35 characters or less                 */
if length(ele) > 35 then do
  queue 'EARCHECK: The length of element' ele
  queue 'EARCHECK: is more than 35 characters.                     '
  queue 'EARCHECK:                                                 '
  queue 'EARCHECK: !!!!!!   THIS IS NOT ALLOWED !!!!!!             '
  queue 'EARCHECK:                                                 '
  queue 'EARCHECK: This causes an issue with the parm field on     '
  queue 'EARCHECK: BPXBATCH steps. Please delete the element and   '
  queue 'EARCHECK: add it in to Endevor with a name that is 35     '
  queue 'EARCHECK: characters or less including the .ear extension '
  queue 'EARCHECK:                                                 '
  cc = 8
end /* length(ele) > 35 */

if cc > 0 then do
  "execio * diskw README (finis"
  if rc ^= 0 then call exception rc 'DISKW to DDname README failed'
end /* cc > 0 */

exit cc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 queue rexxname':'
 queue rexxname':' comment
 queue rexxname': Exception called from line' sigl

exit return_code

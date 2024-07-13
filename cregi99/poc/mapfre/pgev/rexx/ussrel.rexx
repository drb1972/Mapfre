/*-----------------------------REXX----------------------------------*\
 *  Get a long name element and find its properties long name        *
 *  equivalent, then build the copy statement for the relate type    *
 *  step that should run in the next step.                           *
 *                                                                   *
 *  GBARDPLY has an example                                          *
 *                                                                   *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

say rexxname':'
short = '' /* Initial setting                                        */

/* read in the long name of the element                              */
"execio 1 diskr longname (stem name. finis"
if rc ^= 0 then call exception rc 'DISKR of LONGNAME failed'

/* read in the CSV output                                            */
"execio * diskr CSVLIST (stem csv. finis"
if rc ^= 0 then call exception rc 'DISKR of CSVLIST failed'

c1elmnt255 = strip(word(name.1,1))
c1ty       = strip(word(name.1,2))

/* set the related type                                              */
if c1ty = 'EAR' then do
  comp = 'WSPROPS'
  ext  = 'properties'
end /* c1ty = 'EAR' */
else do
  comp = 'BAROVER'
  ext  = 'txt'
end /* else */

say rexxname': Look for the' comp 'element related to' c1elmnt255,
  'type' c1ty
say rexxname':'

x = length(c1elmnt255) - 4 /* Element without extension              */

needle = left(c1elmnt255,x)'.'ext /* search string                   */
say rexxname': Related component name is' needle
say rexxname':'

/* loop though the CSV output                                        */
do a = 1 to csv.0
  if pos(needle,csv.a) = 139 then
    short = substr(csv.a,39,8)
end /* a = 1 to csv.0 */

if short = '' then call readme /* component name not found           */

/* build the fileaid statement                                       */
say rexxname': Command built "$$DD01 COPY MEMBER='short'"'
say rexxname':'
queue '$$DD01 COPY MEMBER='short

/* write out to the dataset                                          */
'execio' queued() 'diskw RELCMNDS (finis)'
if rc ^= 0 then call exception rc 'DISKW to RELCMNDS failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Issue an error message                                            */
/*-------------------------------------------------------------------*/
readme:
 queue '  No' comp 'called' needle 'was found in this system.'
 queue ''
 queue '  Please check that the' comp 'element with name' c1elmnt255
 queue '  has been added and moved to the current Endevor location.'
 queue ''
 queue '  If there are any issues then contact Endevor Support via'
 queue '  e-mail using endevor@rbs.co.uk  '

 'execio' queued() 'diskw README (finis)'
 if rc ^= 0 then call exception rc 'DISKW to README failed'

exit 12

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg('off')
 address tso 'delstack' /* Clear down the stack                      */
 z = msg('on')

 if return_code < 12 | return_code > 4095 then return_code = 12

exit return_code

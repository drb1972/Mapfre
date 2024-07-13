/*-----------------------------REXX----------------------------------*\
 *  Get a long name element and find its' properties long name       *
 *  equivalent, then build the copy statement for the relate type    *
 *  step that should run in the next step.                           *
 *                                                                   *
 *  GDEPLOY has an example                                           *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

say 'RELPROPS:'
short = '' /* Initial setting                                        */

/* read in the long name of the element                              */
"execio 1 diskr longname (stem name. finis"
if rc ^= 0 then call exception rc 'DISKR of LONGNAME failed'

/* read in the CSV output                                            */
"execio * diskr CSVLIST (stem csv. finis"
if rc ^= 0 then call exception rc 'DISKR of CSVLIST failed'

c1elmnt255 = strip(name.1) /* Get rid of all the blanks              */
say 'RELPROPS: Look for the properties related to' c1elmnt255
say 'RELPROPS:'

x = length(c1elmnt255) - 4 /* Element without extension              */

needle = left(c1elmnt255,x)'.properties' /* WSPROPS name             */
say 'RELPROPS: WSPROPS name should be' needle
say 'RELPROPS:'

/* loop though the CSV output                                        */
do a = 1 to csv.0
  if pos(needle,csv.a) = 139 then
    short = substr(csv.a,39,8)
end /* a = 1 to csv.0 */

if short = '' then call readme /* wsprops name not found             */

/* build the fileaid statement                                       */
say 'RELPROPS: Command built "$$DD01 COPY MEMBER='short'"'
say 'RELPROPS:'
queue '$$DD01 COPY MEMBER='short

/* write out to the dataset                                          */
'execio' queued() 'diskw RELCMNDS (finis)'
if rc ^= 0 then call exception rc 'DISKW of RELCMNDS failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Issue an error message                                            */
/*-------------------------------------------------------------------*/
readme:
 queue '  No element called' needle 'was found in this system.'
 queue ''
 queue '  Please check that the WSPROPS for this DEPLOY element has'
 queue '  been added and moved to the current Endevor location.'
 queue ''
 queue '  If there are any issues then contact Endevor Support via'
 queue '  e-mail using VERTIZOS@kyndryl.com'

 'execio' queued() 'diskw README (finis)'

exit 12

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 ADDRESS tso delstack /* Clear down the stack                        */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

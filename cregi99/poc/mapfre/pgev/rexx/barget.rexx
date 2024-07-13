/*-----------------------------REXX----------------------------------*\
 *  This Rexx is used find the WMBRESOLVED file in the map, starting *
 *  at the current location. The output are the commands to apply    *
 *  a location specific BAR override.                                *
 *                                                                   *
 *  This REXX may have a return code of 3 if the soure BAR file is   *
 *  not found.                                                       *
 *                                                                   *
 *  GBAROVER has an example.                                         *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

cc = 3 /* set the return code in case no files are found             */

/* Get the element name and the current environment                  */
"execio * diskr PARMS (stem parms. finis"
if rc ^= 0 then call exception rc 'DISKR of PARMS failed'

c1el = word(parms.1,1)
c1en = word(parms.1,2)
c1su = word(parms.1,3)
c1st = word(parms.1,4)
c1pr = word(parms.1,5)

/* build the BAR file name if this is an environment override        */
if c1pr = 'ENVRNMNT' then do
  ele = substr(c1el,1,length(c1el)-9)'.bar'
end /* c1pr = 'ENVRNMNT' */
else
  ele = substr(c1el,1,length(c1el)-4)'.bar'

say rexxname': '
say rexxname': The BAR override element name is' c1el
say rexxname':'
say rexxname': '
say rexxname': Location details of the current location specifc BAR',
            'override:'
say rexxname': BAR name .........:' ele
say rexxname': Environment ......:' c1en
say rexxname': Subsystem ........:' c1su
say rexxname': Stage name .......:' c1st
say rexxname': Processor Group ..:' c1pr
say rexxname': '

uss_hlq = '/RBSG/endevor' /* constant for the file location          */
loc_bar = uss_hlq'/'c1en'/'left(c1st,1)||c1su'/BAROVER/'c1el

/* set the llq of the directory structure                            */
if c1pr = 'GENERAL' then llq = 'WMBGENERAL'
                    else llq = 'WMBRESOLVED'

out_bar = uss_hlq'/'c1en'/'left(c1st,1)||c1su'/'llq'/'ele

/* loop through the stage name to find the correct file              */
do a = 1 to length(c1st)
  stg = substr(c1st,a,1) /* loop through each stage id               */

  /* convert stage id to environment                                 */
  select
    when pos(stg,'AB') > 0 then env = 'UNIT'
    when pos(stg,'CD') > 0 then env = 'SYST'
    when pos(stg,'EF') > 0 then env = 'ACPT'
    when pos(stg,'OP') > 0 then env = 'PROD'
    otherwise nop
  end /* select */

  /* if the stage id is X then the end of the map has been reached   */
  if stg = 'X' then
    if c1pr = 'GENERAL' then call no_bar_file
                        else call no_override_file

  /* change the subsystem to 1 at stage P                            */
  if stg = 'P' then mlq = 'P'left(c1su,2)'1'
               else mlq = stg||c1su

  /* set the appropriate output directory based on processor group   */
  if c1pr = 'GENERAL' then
    cur_bar = uss_hlq'/'env'/'mlq'/BAR/'ele
  else /* must be an environment override file                       */
    cur_bar = uss_hlq'/'env'/'mlq'/WMBGENERAL/'ele

  say rexxname': Looking for' cur_bar
  say rexxname':'

  /* Does the overriden BAR file exist?                              */
  command = 'ls' cur_bar
  call bpxwunix command,,Out.,Err.

  /* Check to see if the result of a general override exists         */
  if err.0 = 0 then do /* file found                                 */
    say rexxname':' cur_bar
    say rexxname': found for override file.'
    say rexxname': '

    cc = 0 /* Suitable input file found for the override             */

    leave /* exit out of the loop because the file has been found    */
  end /* err.0 = 0 */

end /* a = 1 to length(c1st) */

/* build the commands for the environment override file              */
if cc = 0 then do

  say rexxname': Building the following commands to apply the environment'
  say rexxname': override file.'
  say rexxname':'

  text = 'PGM /software/wmb/QDM1/bin/mqsiapplybaroverride'
  queue text
  say rexxname':' text

  text = ' -b' cur_bar
  queue text
  say rexxname':' text

  text = ' -p' loc_bar
  queue text
  say rexxname':' text

  text = ' -o' out_bar
  queue text
  say rexxname':' text

  text = ' -r'
  queue text
  say rexxname':' text
  say rexxname':'

  "execio * diskw OVERCMDS (finis"
  if rc ^= 0 then call exception rc 'DISKW to OVERCMDS failed'

  /* Build the readbar commands                                      */
  say rexxname': Build the readbar commands.'

  text = 'PGM /software/wmb/QDM1/bin/mqsireadbar'
  queue text
  say rexxname':' text

  text = '  -b' out_bar
  queue text
  say rexxname':' text

  text = '  -r'
  queue text
  say rexxname':' text
  say rexxname':'

  "execio * diskw PRINTBAR (finis"
  if rc ^= 0 then call exception rc 'DISKW to PRINTBAR failed'

end /* cc = 0 */

exit cc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* build the messages when the BAR file doesn't exist                */
/*-------------------------------------------------------------------*/
no_bar_file:
  queue rexxname':'
  queue rexxname': Whilst processing a general BAR override file,'
  queue rexxname': the source BAR file element was not found.'
  queue rexxname':'
  queue rexxname': File names are:-'
  queue rexxname': BAR element ..........:' ele 'type BAR'
  queue rexxname': General override .....:' c1el 'type BAROVER'
  queue rexxname':'
  queue rexxname': Please check that the BAR type element has been'
  queue rexxname': added and had no processing errors.'
  queue rexxname':'

  "execio * diskw README (finis"
  if rc ^= 0 then call exception rc 'DISKW to README failed'

  exit 3 /* exit with a return code to alloc ITE processing          */

return /* no_bar_file: */

/*-------------------------------------------------------------------*/
/* build the messages when the WMBRESOLVED file doesn't exist        */
/*-------------------------------------------------------------------*/
no_override_file:
  queue rexxname':'
  queue rexxname': Whilst processing an environment specific BAR'
  queue rexxname': override file, the resolved file created by the'
  queue rexxname': general override element was not found.'
  queue rexxname':'
  queue rexxname': File names are:-'
  queue rexxname': BAR element ..........:' ele 'type BAR'
  queue rexxname': General override .....:' c1el 'type BAROVER'
  queue rexxname': Environment override .:' c1el 'type BAROVER'
  queue rexxname':'
  queue rexxname': Please check that the general override element has'
  queue rexxname': been added and had no processing errors.'
  queue rexxname':'

  "execio * diskw README (finis"
  if rc ^= 0 then call exception rc 'DISKW to README failed'

  exit 3 /* exit with a return code to alloc ITE processing          */

return /* no_override_file: */

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

 if return_code < 12 then return_code = 12 /* - RCs can be invalid   */

exit return_code

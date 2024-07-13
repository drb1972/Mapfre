/*--------------------------REXX--------------------------------------*\
 * This rexx executes a batch of racf commands in a controlled manner *
 * by introducing a specified second time delay. Acceptable time      *
 * delay is a whole number between 2 and 9. If any other value is     *
 * specified the rexx will default to a value of 2.                   *
 * It also applies secured passwords to coded ALU commands.           *
 *--------------------------------------------------------------------*
 *  Author:     SUNDEEP GUPTA                                         *
 *  Created on  :  04/03/2002                                         *
 *--------------------------------------------------------------------*
 *                                                                    *
 *  Change History                                                    *
 *  ==============                                                    *
 *                                                                    *
 *  +----------+----------+----------------------------------------+  *
 *  |    By    |    On    |                 Details                |  *
 *  +----------+----------+----------------------------------------+  *
 *  | GUPTASA  | 01/12/08 | ADDED COMMENTS AND STANDARDISED SYNTAX |  *
 *  |          |          | IN READINESS FOR CODE MANAGEMENT       |  *
 *  |          |          | THROUGH ENDEVOR.                       |  *
 *  +----------+----------+----------------------------------------+  *
 *  | WILLIET  | 19/12/08 | Convert to Endevor Support standards   |  *
 *  |          |          | and add password protection.           |  *
 *  +----------+----------+----------------------------------------+  *
\*--------------------------------------------------------------------*/
trace n

/* Read in specified command delay time & test parameter */
arg wait_time test

if wait_time = '' then
  wait_time = 2

if test = 'TEST' then
  pass_dsn = 'TTEK.AUTO.PASSWORD'
else
  pass_dsn = 'PGSQ.AUTO.PASSWORD'

do until readrc = 2          /* loop til you just cant loop no more */
  "execio 1 diskr input (stem cmd." /* read 1 line                  */
  readrc = rc                /* return code from execio             */
  if readrc = 2 then leave   /* end of file                         */
  if readrc > 2 then do                 /* I/O error                */
    say 'RACFCMD:'
    say 'RACFCMD: Error reading DD INPUT. RC =' readrc
    call exception 12
  end
  cmd.1 = Strip(cmd.1)

  /* Check if command record is actually a comment or a blank line  */
  If (left(cmd.1,2) = '/*' | cmd.1 = ' ') Then
    iterate

  /* Check for command continuation character at end of line */
  Do While (right(cmd.1,1)='+'  |,
            right(cmd.1,1)='-') & readrc = 0

    /* If command continuation found read in next command record */
    "execio 1 diskr input"     /* read 1 line                         */
    readrc = rc                /* return code from execio             */
    if readrc > 2 then do                 /* I/O error                */
      say 'RACFCMD:'
      say 'RACFCMD: Error reading DD INPUT. RC =' readrc
      call exception 12
    end
    pull cmd_cont

    /* Keep reading in records and building command until no */
    /* continuation character found at end of line           */
    cmd_cont = Strip(cmd_cont)
    cmd.1    = left(cmd.1,length(cmd.1)-1) || cmd_cont

  End /* while (right(cmd.1,1)='+' | right(cmd.1,1)='-') & readrc = 0 */

  /* Check for password commands */
  cmdu = cmd.1
  upper cmdu
  pwd_pos = pos('%%PWD%%',cmdu)

  if pwd_pos > 0 then do
    userid = word(cmdu,2)
    dsn_mem = pass_dsn'('userid')'

    /* Check password member exists */
    if sysdsn("'"dsn_mem"'") <> 'OK' then do
      err.1 = 'RACFCMD: No password member found for' userid
      err.2 = 'RACFCMD:' dsn_mem 'not found.'
      err.3 = 'RACFCMD: Command = "'cmd.1'"'
      err.4 = 'RACFCMD:'
      "execio 4 diskw FAILURE (stem err."
      if rc > 1 then do
        say 'RACFCMD:'
        say 'RACFCMD: Error writting to DD FAILURE. RC =' rc
        call exception 12
      end
      iterate
    end /* sysdsn("'"dsn_mem"'") <> 'OK' */

    /* Read password member         */
    "alloc f(pass) dsname('"dsn_mem"') shr"
    'execio * diskr pass (stem pass. finis'
    if rc > 0 then do
      err.1 = 'RACFCMD: EXECIO error reading' dsn_mem
      err.2 = 'RACFCMD: Command = "'cmd.1'"'
      err.3 = 'RACFCMD:'
      "execio 3 diskw FAILURE (stem err."
      if rc > 1 then do
        say 'RACFCMD:'
        say 'RACFCMD: Error writting to DD FAILURE. RC =' rc
        call exception 12
      end
      iterate
    end /* rc > 0 */

    "free f(pass)"
    /* Replace %%pwd%% with the password from the PDS member */
    password = word(pass.1,1)
    cmd.1 = left(cmd.1,pwd_pos-1) || password || substr(cmd.1,pwd_pos+7)

    call issue_cmd 'SECURES' 'SECUREF'

  end /* pwd_pos > 0 */

  else
    call issue_cmd 'SUCCESS' 'FAILURE'

  /* Wait for the specified number of seconds (default is 2 seconds) */
  W = Opswait(wait_time)

end /* do until readrc = 2 */

exit

/*------------------ S U B R O U T I N E S ------------------*/

/*-----------------------------------*/
/* Issue one RACF command            */
/*-----------------------------------*/
issue_cmd:
 arg success_dd fail_dd

 /* Issue command */
 x = Outtrap('trap.',,'NOCONCAT')
 cmd.1
 cmdrc.1 = rc
 x = Outtrap("Off")

 /* If return code not 0 write command, rc and message to failure dd */
 If cmdrc.1 ^= 0 Then do
   "execio 1        diskw" fail_dd "(stem cmd."
   if rc > 1 then do
     say 'RACFCMD:'
     say 'RACFCMD: Error writting to DD' fail_dd'. RC =' rc
     call exception 12
   end
   "execio 1        diskw" fail_dd "(stem cmdrc."
   if rc > 1 then do
     say 'RACFCMD:'
     say 'RACFCMD: Error writting to DD' fail_dd'. RC =' rc
     call exception 12
   end
   "execio "trap.0" diskw" fail_dd "(stem trap."
   if rc > 1 then do
     say 'RACFCMD:'
     say 'RACFCMD: Error writting to DD' fail_dd'. RC =' rc
     call exception 12
   end
 end
 else do /* For zero return code write command to success dd */
   "execio 1 diskw" success_dd "(stem cmd."
   if rc > 1 then do
     say 'RACFCMD:'
     say 'RACFCMD: Error writting to DD' success_dd'. RC =' rc
     call exception 12
   end
 end /* else */

return

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
Exception:
 arg return_code

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code

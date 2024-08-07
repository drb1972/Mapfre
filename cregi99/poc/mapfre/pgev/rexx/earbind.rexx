/* REXX                                                              */
/* This REXX builds a list of DBRM names that will be added in       */
/* as a BINDMULT element created from the EAR file customise.        */
trace n
/* Process the fastcopy output                                       */

b = 0 /* Set DBRM counter to start after fixed parms                 */

/* Read in the FASTCOPY output                                       */
"execio * diskr listing(stem fastcopy. finis"
if rc ^= 0 then call exception rc 'DISKR of DDname LISTING failed'

do d=1 to fastcopy.0
  parse value fastcopy.d with mess mem rest

  if right(mess,7) = 'FCO141M' then do
    b = b + 1 /* increase DBRM counter                               */
    dbrms.b = mem ' ' /* Add null for ZFS file                       */
  end /* if right(mess,7) = 'FCO141M' then do                        */

end /* do d=1 to fastcopy.0                                          */

"EXECIO * DISKW BINDELT (stem dbrms. FINIS"
if rc ^= 0 then call exception rc 'DISKW of DDname BINDELT failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack */
 do i = 1 to queued()
   pull
 end

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

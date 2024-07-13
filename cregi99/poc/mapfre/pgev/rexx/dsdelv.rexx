/*+---REXX----------------------------------------------------------+*/
/*| rexx to scan the DSDEL element source to ensure that the entry  |*/
/*| is coded correctly.                                             |*/
/*|                                                                 |*/
/*| It is called in GDSDEL processor                                |*/
/*+-----------------------------------------------------------------+*/
trace n

err_log.0 = 0 /* Counter for the run_log stack                       */
maxrc     = 0 /* Set the exit return code to be zero                 */

/* read the source code                                              */
"execio * diskr source (stem source. finis"
if rc ^= 0 then call exception rc 'DISKR of DDname SOURCE failed'

call destsys /* load up the valid destination array                  */

/* read through each line of source                                  */
do a = 1 to source.0

  dsn = word(source.a,1) /* dataset that is being deleted            */

  if left(dsn,2) ^= 'PG' then do
    call err_log( "DSDELV: ")
    call err_log( "DSDELV:    Dataset" dsn "does not start PG")
    call err_log( "DSDELV: ")
    maxrc = 12
  end /* if left word(source.a,2) ^= 'PG' then do                    */

  if substr(dsn,6,4) ^= 'BASE' & substr(dsn,6,1) ^= 'P' then do
    call err_log( "DSDELV: ")
    call err_log( "DSDELV:    Dataset" dsn "is not Endevor controlled")
    call err_log( "DSDELV: ")
    maxrc = 12
  end /* if substr(dsn,6,4) ^= 'BASE' then do                        */

  do b = 2 to words(source.a) /* valid destinations?                 */

    suffix = word(source.a,b)
    name   = 'PLEX'suffix
    if pos(name,c1systemb.default) = 0 then do /* does dest exist    */
      call err_log( "DSDELV: ")
      call err_log( "DSDELV:    Destination" suffix "for" dsn " is ")
      call err_log( "DSDELV:    not coded as" name "in             ")
      call err_log( "DSDELV:    PGEV.BASE.DATA(DESTSYS)            ")
      call err_log( "DSDELV: ")
      maxrc = 12
    end /* if pos(name,c1system.default) = 0 then do                 */

  end /* do b = 2 to words(source.a)                                 */

end /* do a = 1 to source.0 */

"EXECIO * DISKW ERROR (FINI STEM err_log."
if rc ^= 0 then call exception rc 'DISKW of DDname ERROR failed'

exit maxrc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* err_log - Write a line to the log                                 */
/*-------------------------------------------------------------------*/
err_log:
 parse arg log_entry
 err_log.0 = err_log.0 + 1
 junk = value('err_log.'||err_log.0,log_entry)

return /* err_log:                                                   */

/*-------------------------------------------------------------------*/
/* Destsys - Interpret the DESTSYS data member                       */
/*-------------------------------------------------------------------*/
destsys:
 "execio * diskr DESTSYS (stem destsys. finis"
 if rc ^= 0 then call exception rc 'DISKR of DDname DESTSYS failed'

 do i = 1 to destsys.0
   interpret destsys.i
 end

return /* destsys:                                                   */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack */
 do i = 1 to queued()
   pull
 end

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

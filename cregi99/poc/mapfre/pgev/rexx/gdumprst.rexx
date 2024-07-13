/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 * This routine is run by the GDUMPRST processor to read the source  *
 * and validate the content before the source is migrated to PROD.   *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

arg c1ty

exit_rc = 0 /* set the initial value of the final return code        */

/* Get the the contents of the member                                */
'execio * diskr SOURCE (stem source. finis'
if rc ^= 0 then call exception rc 'DISKR of DDname SOURCE failed.'

call readint /* process PGEV.BASE.DATA(DESTSYS)                      */

/* validate the content of the element source                        */
do a = 1 to source.0 /* loop through each line                       */
  if left(source.a,2) ^= 'PG' then do
    queue 'GDUMPRST:'
    queue 'GDUMPRST: The dataset' word(source.a,1),
                   'is not valid for this'
    queue 'GDUMPRST: utility. Please amend the dataset name'
    queue 'GDUMPRST: or remove line' a 'of the source.'
    queue 'GDUMPRST:'
    exit_rc = 9
  end /* left(source.a,2) ^= 'PG' */

  do b = 2 to words(source.a) /* loop through the coded destinations */

    /* find out if the destination is valid against destsys          */
    if pos(word(source.a,b),list_destsb) = 0 then do
      queue 'GDUMPRST:'
      queue 'GDUMPRST: You have coded an invalid destination:- '
      queue 'GDUMPRST:'   word(source.a,b)
      queue 'GDUMPRST: Review line' a 'of the source,' ,
                     'you may have NUMBER ON.'
      queue 'GDUMPRST: '
      exit_rc = 10
    end /* pos(word(source.a,b),list_destsb) = 0 */

    if right(c1ty,1) = substr(word(source.a,b),5,1) then do
      queue 'GDUMPRST: '
      queue 'GDUMPRST: You have coded an invalid destination:- '
      queue 'GDUMPRST: '  word(source.a,b) ,
                      'on line' a 'of the source.'
      queue 'GDUMPRST: '
      queue 'GDUMPRST: The type you have used ('c1ty') is designed'
      queue 'GDUMPRST: to use' word(source.a,b) 'as the source and'
      queue 'GDUMPRST: not as a target destination'
      queue 'GDUMPRST: '
      exit_rc = 12
    end /* right(c1ty,1) = substr(word(source.a,b),5,1) */

  end /* b = 2 to words(source.a) */

end /* a = 1 to source.0 */

if queued() > 0 then
  "execio" queued() "diskw README (finis"
if rc > 0 then call exception rc 'Write to DDname README failed'

exit exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Read & interpret input data                                       */
/*-------------------------------------------------------------------*/
readint:

 "execio * diskr destsys (stem record. finis"
 if rc > 0 then call exception rc 'Read of DDname DESTSYS failed'

 do i = 1 to record.0
   interpret record.i /* make the text in to variables               */
 end /* i = 1 record.0 */

 /* Check to see if there are any overrides in DESTSYS               */
 if C1SYSTEMB.EV = "C1SYSTEMB.EV" then
   list_destsb = C1SYSTEMB.DEFAULT
 else
   list_destsb = C1SYSTEMB.EV

return /* readint: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 queue rexxname':'
 queue rexxname':' comment'. RC='return_code
 queue rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code

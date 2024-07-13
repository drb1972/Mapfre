/*-----------------------------REXX----------------------------------*\
 *  Two file merge of Element CSV extract and Infoman CMR data       *
 *  Used by the Endevor Spreadsheet process                          *
\*-------------------------------------------------------------------*/
trace n
/*---------------- CONSTANTS / INITIAL VALUES -----------------------*/
/* note: INFOMAN comment field starts in column 62                   */
cmr. = copies(' ',61)'No CMR found or change is in COMPLETE status'
prev_element_and_type = ''
duplicate             = 'D'
singleton             = 'S'

/*------------------------- MAIN LINE -------------------------------*/
parse source . . rexxname . . . . addr .
say rexxname':' Date() Time()

"execio * diskr element (stem ele. finis"
if rc ^= 0 then call exception rc 'DISKR of ELEMENT failed'

"execio * diskr infoman (stem inf. finis"
if rc ^= 0 then call exception rc 'DISKR of INFOMAN failed'

/* create infoman cmr look-up table keyed on CCID                    */
do i = 1 to inf.0
  parse var inf.i 1 ccid 9 .
  cmr.ccid = inf.i
end /* i = 1 to inf.0 */

/* check for duplicate elements and append infoman cmr info          */
do i = 1 to ele.0
  j = i + 1 /* j points to the next record                           */
  parse var ele.i 1    .              ,
                  49   curr_type      ,
                  57   .              ,
                  156  ccid           ,
                  164  .              ,
                  1055 curr_elmname   ,
                  1310 .
  /* set up key of current record                                    */
  curr_element_and_type = curr_elmname || curr_type

  if i < ele.0 then do
    parse var ele.j 1    .              ,
                    49   next_type      ,
                    57   .              ,
                    1055 next_elmname   ,
                    1310 .
    /* set up key of next record                                     */
    next_element_and_type = next_elmname || next_type
  end /* i < ele.0 */
  else
    next_element_and_type = ''

  /* check for matching keys (previous or next)                      */
  if curr_element_and_type = prev_element_and_type |,
     curr_element_and_type = next_element_and_type then
    duplicate_ind = duplicate
  else
    duplicate_ind = singleton

  /* replace embedded commas with spaces                             */
  change_management_rec = translate(cmr.ccid,' ',',')
  queue translate(ele.i,' ',',') ||,
        duplicate_ind            ||,
        change_management_rec
  prev_element_and_type = curr_element_and_type
end /* i = 1 to ele.0 */

"execio" queued() "diskw infoout (finis"
if rc ^= 0 then call exception rc 'DISKW to INFOOUT failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

/*-----------------------------REXX----------------------------------*\
 *  This Rexx removes trailing spaces before commas                  *
 *  to produce smaller CSV files                                     *
 *                                                                   *
 *  It is used by the Spreadsheet process via the Rexx and           *
 *  Skeleton ENDEVALL                                                *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

parse source . . rexxname .
say rexxname':' Date() Time()
say rexxname':'

blank_date = '    -  -  '
blank_time = '  :  '

"execio * diskr input (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of INPUT failed'

do i = 1 to line.0
  /* fix any incorrectly formatted blank dates (yyyy-mm-dd)         */
  blank_date_start = pos(blank_date,line.i)
  do while sign(blank_date_start)
    line.i = overlay(copies(' ',10),line.i,blank_date_start)
    blank_date_start = pos(blank_date,line.i,blank_date_start)
  end /* while sign(blank_date_start) */

  /* fix any incorrectly formatted blank times (hh:mm)              */
  blank_time_start = pos(blank_time,line.i)
  do while sign(blank_time_start)
    line.i = overlay(copies(' ',5),line.i,blank_time_start)
    blank_time_start = pos(blank_time,line.i,blank_time_start)
  end /* while sign(blank_time_start) */

  /* reverse string to make processing easier                       */
  reversed_input = reverse(strip(strip(line.i,,'00'x)))
  /* invoke lstrip internal function to remove spaces               */
  reversed_csv  = lstrip(reversed_input,pos(',',reversed_input))
  /* re-reverse string back to original direction                   */
  csv.i = reverse(reversed_csv)
end /* i = 1 to line.0 */
csv.0 = line.0

"execio * diskw output (stem csv. finis"
if rc ^= 0 then call exception rc 'DISKW of OUTPUT failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* lstrip                                                            */
/* This recursive subroutine removes spaces after commas             */
/* Note that it recursively invokes itself, to cope with varying     */
/* numbers of commas                                                 */
/* As start_pos always increases, and the subroutine returns         */
/* normally when no more commas are found, there is no danger of     */
/* an infinite recursion!                                            */
/*-------------------------------------------------------------------*/
lstrip: procedure /* all variables are local to the routine          */

 parse arg orig_string,start_pos
 if start_pos = '' then start_pos = 1

 start_pos = start_pos + 1
 /* split the string in two - up to the starting position, and       */
 /* everything after the starting position                           */
 interpret 'parse var orig_string 1 left_bit' start_pos 'right_bit'

 /* remove leading blanks from the latter                            */
 new_string = left_bit || strip(right_bit,'L')
 /* find the next comma                                              */
 new_pos = pos(',',new_string,start_pos)
 /* if there are more commas, recursively invoke the subroutine      */
 /* to process them                                                  */
 if sign(new_pos) then
   return lstrip(new_string,new_pos)
 /* no more commas, so return the stripped string in normal fashion  */
 else
   return new_string

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack' /* Clear down the stack                    */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

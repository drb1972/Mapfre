/*REXX*/
/*==================================================================*/
/*                                                                  */
/* Read through an HFS directory an if the read works loop through  */
/* and say each line                                                */
/*                                                                  */
/*==================================================================*/

parse arg infile .

call syscalls 'ON'
address syscall

'readfile' (infile) line.

if retval<>0 then
   say 'EVSAYHFS: Unable to read file' path'. Error: 'errno errnojr
else
  do n=1 to line.0
    say line.n
  end /* do n=1 to line.0 */

exit 0

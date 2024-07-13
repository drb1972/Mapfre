/*-----------------------------REXX----------------------------------*\
 *  This is run in the MEAR move processor for delta ear             *
 *  files and checks for an ear file in the next directory           *
 *  in the map. If one exists then we are overwriting an             *
 *  ear element and we must fail the move so that the                *
 *  element can not be moved further.                                *
 *  To allow for MOVE reruns after a MOVE failure a marker           *
 *  file is written for enhanced checking.                           *
 *                                                                   *
 *  It will also check for the existance of an EAR file all          *
 *  the way up the map to make sure that the base EAR                *
 *  element has not been deleted.                                    *
 *                                                                   *
 *  This is not run when moving to stage P.                          *
 *                                                                   *
 *  For deletes this will delete the marker file.                    *
\*-------------------------------------------------------------------*/
trace n

parse arg full_filename c1action c1senvmnt c1sstgid c1stage

say
say 'EARPLOD: Input parms..'
say 'EARPLOD: full_filename..:' full_filename
say 'EARPLOD: c1action.......:' c1action
say 'EARPLOD: c1senvmnt......:' c1senvmnt
say 'EARPLOD: c1sstgid.......:' c1sstgid
say 'EARPLOD: c1stage........:' c1stage
say 'EARPLOD:'

dot = lastpos('.',full_filename)
marker_full_filename = left(full_filename,dot)'delta_fail'

if c1action = 'DELETE' then do
  say 'EARPLOD: Deleting' marker_full_filename
  "bpxbatch sh rm -f" marker_full_filename
end /* c1action = 'DELETE' */
else do
  call check_base  /* Check all the way up the map                   */
  call check_files /* Check the next stage only                      */
end /* else */

exit 0

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Check for a base EAR file up the map                              */
/*-------------------------------------------------------------------*/
Check_base:

 say 'EARPLOD:'
 say 'EARPLOD: Checking for the existance of the EAR file up the map'
 say 'EARPLOD:'

 do i = 1 to 8 /* Start searching at the next stage up the map       */

   Base_c1si = substr(c1stage,i,1)
   select
     when pos(Base_c1si,'AB') > 0 then
       base_c1en = 'UNIT'
     when pos(Base_c1si,'CD') > 0 then
       base_c1en = 'SYST'
     when pos(Base_c1si,'EF') > 0 then
       base_c1en = 'ACPT'
     when pos(Base_c1si,'OP') > 0 then
       base_c1en = 'PROD'
     otherwise nop
   end /* select */
   BaseEAR = overlay(base_c1en,full_filename,15)
   BaseEAR = overlay(Base_c1si,BaseEAR,20)
   if Base_c1si = 'P' then
     BaseEAR = overlay('1',BaseEAR,23)
   say 'EARPLOD: Checking' BaseEAR

   command = 'ls' BaseEAR
   Call bpxwunix command,,Out.,Err.

   if err.0 = 0 then do /* File found so ok                          */
     say 'EARPLOD: Base EAR file found'
     leave
   end /* err.0 = 0 */

   if Base_c1si = 'P' then do /* End of the line                     */
     say 'EARPLOD: Base EAR file not found up the map. You can not move'
     say 'EARPLOD: a delta file when there is no base ear file.'
     say 'EARPLOD: The base EAR element must have been deleted.'
     exit 12
   end /* Base_c1si = 'P' */
 end /* i = 1 to 8 */

return /* Check_base: */

/*-------------------------------------------------------------------*/
/* Check for marker and EAR files                                    */
/*-------------------------------------------------------------------*/
Check_files:

 say 'EARPLOD:'
 say 'EARPLOD: Checking for the existance of the marker file in the' ,
     'target directory.'
 say 'EARPLOD:' marker_full_filename
 say 'EARPLOD:'

 command = 'ls' marker_full_filename
 Call bpxwunix command,,Out.,Err.

 say 'EARPLOD: Results for command "'command'"'
 if err.0 ^= 0 then do /* File not found so ok                       */
   do i = 1 to err.0
     say 'EARPLOD: STDERR -' err.i
   end /* i = 1 to err.0 */
   say 'EARPLOD:'
   say 'EARPLOD: Target marker file not found so will check EAR file'
 end /* err.0 ^= 0 */
 else do               /* File found                                 */
   do i = 1 to out.0
     say 'EARPLOD: STDOUT -' out.i
   end /* i = 1 to out.0 */
   say 'EARPLOD:'
   say 'EARPLOD: Marker file found. The move will fail so that the EAR'
   say 'EARPLOD: element can not be moved any further without being generated'
   exit 4
 end /* else */

 say 'EARPLOD:'
 say 'EARPLOD: Checking for the existance of the EAR file in the' ,
     'target directory.'
 say 'EARPLOD:' full_filename
 say 'EARPLOD:'

 command = 'ls' full_filename
 Call bpxwunix command,,Out.,Err.

 say 'EARPLOD: Results for command "'command'"'
 if err.0 ^= 0 then do /* File not found so ok                       */
   do i = 1 to err.0
     say 'EARPLOD: STDERR -' err.i
   end /* i = 1 to err.0 */
   say 'EARPLOD:'
   say 'EARPLOD: Target file not found so ok'
   exit 0
 end /* err.0 ^= 0 */
 else do               /* File found                                 */
   do i = 1 to out.0
     say 'EARPLOD: STDOUT -' out.i
   end /* i = 1 to out.0 */

   /* Ok so we've found the target file but it could be a rerun of a */
   /* move so we must check the file date & time.                    */
   junk = syscalls('ON') /* Set up the pre defined variables         */
   src_full_filename = overlay(c1senvmnt,full_filename,15)
   src_full_filename = overlay(c1sstgid,src_full_filename,20)
   address syscall "stat (src_full_filename) src."
   src_file_mod_time = src.st_mtime
   address syscall "stat (full_filename) tgt."
   tgt_file_mod_time = tgt.st_mtime
   say 'EARPLOD:'
   say 'EARPLOD: Checking source and target EAR file timestamps'
   say 'EARPLOD: Source file' src_full_filename
   say 'EARPLOD: Source file modified time' src_file_mod_time
   say 'EARPLOD: Target file' full_filename
   say 'EARPLOD: Target file modified time' tgt_file_mod_time

   if src_file_mod_time ^= tgt_file_mod_time then do /* Not a rerun  */
     say 'EARPLOD:'
     say 'EARPLOD: Target file found. The move will fail so that the' ,
         'EAR'
     say 'EARPLOD: element can not be moved any further without being' ,
         'generated at stage' c1stage
     say 'EARPLOD:'
     say 'EARPLOD: Creating marker file -' marker_full_filename
     slash           = lastpos('/',marker_full_filename)
     len             = length(marker_full_filename)
     file_len        = len - slash
     marker_filename = right(marker_full_filename,file_len)
     tgt_directory   = left(full_filename,slash-1)
     "bpxbatch sh cd" tgt_directory ";" ,
               "touch" marker_filename
     say 'EARPLOD: Create file RC =' rc
     if rc ^= 0 then call exception rc 'Create failed for' ,
                     tgt_directory marker_filename
     exit 4
   end /* src_file_mod_time ^= tgt_file_mod_time */
   else do
     say 'EARPLOD:'
     say 'EARPLOD: Target file found but this is a MOVE rerun so ok'
     exit 0
   end /* else */
 end /* else */

return /* Check_files: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

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

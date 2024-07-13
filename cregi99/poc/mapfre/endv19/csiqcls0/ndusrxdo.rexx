/* REXX - Sample routine redirect a user command to another user command
          Works like Alias, but can adjust values

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Use the 'D2' command to select the 'OLD' element for compare"
/* End of Preamble */

parse arg PassParm
UserCmd = "DO"           /* as if user Command DO were entered */
ADDRESS ISPEXEC "VPUT (USERCMD) SHARED"
call NDUSRSD# "'"PassParm"'" /* call Diff Line Cmd routine to store details */
EXIT 0

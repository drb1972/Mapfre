/* REXX - Sample User routine to invoke QuickEdit Batch Transfer
          for a single element

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Sample build TRANSFER scl for element/row selected"
/* End of Preamble */

parse arg PassParm
PassName = strip(PassParm,,"'")
ADDRESS ISPEXEC "VGET ("PASSNAME") SHARED"
interpret 'ALLVALS = 'PassName
ADDRESS ISPEXEC "VGET ("ALLVALS") SHARED"
/*
  insert logic here to store the selected rows if needed
*/
ADDRESS ISPEXEC
"SELECT CMD(ENDIE430 BUILD TRANSFER" USERROW USERROW ")"
/* ENDIE430 will have set the final line message retrieve it and return */
"TBTOP"  USERTABL
"TBSKIP" USERTABL "NUMBER("USERROW")"
USERMSG = EEVETDMS
"VPUT (USERMSG) SHARED"
EXIT 0

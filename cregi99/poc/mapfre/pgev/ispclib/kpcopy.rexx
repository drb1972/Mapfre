 /* This Rexx Exec will COPY which data set for the user */

 trace (OFF)
 x = msg('off')
 Address ISPEXEC "VGET (WDSN CDSN CMEM) PROFILE"

 If cdsn = "" | wdsn = ""
    Then do
      zedlmsg = "The Datasets required to complete the COPY function",
                "are not present.  Please check and Re-Enter."
      Address ISPEXEC "SETMSG MSG(ISRZ001)"
      CALL Exit_Exec
 End  /* End If Statement */

 /*-------------------------------------------------------------------*/
 /*                Strip dataset for processing                       */
 /*-------------------------------------------------------------------*/

 wdsn = STRIP(wdsn,,"'")
 PARSE VALUE wdsn WITH wdsn '(' wmem ')'
 cdsn = STRIP(cdsn,,"'")
 PARSE VALUE cdsn WITH cdsn '(' cdmem ')'

 /*-------------------------------------------------------------------*/
 /*           Check to see if the CDSN and WDSN are the same          */
 /*-------------------------------------------------------------------*/

 If cdsn||'('||cdmem||')' = wdsn||'('||wmem||')'
     Then do
       zedlmsg = "The 'TO DATASET' and 'FROM DATASET' can not be the",
                 "same for a successful copy.  Please check and",
                 "Re-Enter."
       Address ISPEXEC "SETMSG MSG(ISRZ001)"
       CALL Exit_Exec
       End  /* End If Statement */
     Else Do
   If   cdsn||'('||cmem||')' = wdsn||'('||wmem||')'
     Then do
       zedlmsg = "The 'TO DATASET' and 'FROM DATASET' can not be the",
                 "same for a successful copy.  Please check and",
                 "Re-Enter."
       Address ISPEXEC "SETMSG MSG(ISRZ001)"
       CALL Exit_Exec
       End  /* End If Statement */

 /*-------------------------------------------------------------------*/
 /*    Check to see if the the copying to dsn has multiple members    */
 /*-------------------------------------------------------------------*/

 If cmem ^= ""  &  cdmem ^= ""
    Then do
      zedlmsg = "The 'To Member' has multiple members specified.",
                "  Please check and Re-Enter."
      Address ISPEXEC "SETMSG MSG(ISRZ001)"
      CALL Exit_Exec
 End  /* End cmem & cdmem If Statememt */

 /*-------------------------------------------------------------------*/
 /*         Begin the dataset status checking                         */
 /*-------------------------------------------------------------------*/

 If SYSDSN(wdsn) = OK then
   Address ISPEXEC "LMINIT DATAID(indd) DATASET("wdsn")"
 Else do
   wdsn = "'"wdsn"'"
      If SYSDSN(wdsn) = OK
         Then do
           Address ISPEXEC "LMINIT DATAID(indd) DATASET("wdsn")"
         End /* End wdsn Do Loop */
         Else do
           zedlmsg = ""wdsn" was NOT found.  Check 'From Dataset' and",
                     "Re-Enter."
           Address ISPEXEC "SETMSG MSG(ISRZ001)"
           CALL Exit_Exec
         End /* End the 2nd wdsn If Statement */
 End  /* End the 1st wdsn If Statement */


 If SYSDSN(cdsn) = OK
    Then do
      Address ISPEXEC "LMINIT DATAID(outdd) DATASET("cdsn")"
      CALL Copy_Now
      CALL Clean_Up
      zedlmsg = "The copy function has completed successfully."
      Address ISPEXEC "SETMSG MSG(ISRZ001)"
      CALL Exit_Exec
    End  /* End cdsn 1st Do Loop */
    Else do
      cdsn = "'"cdsn"'"
        If SYSDSN(cdsn) = OK
           Then do
             Address ISPEXEC "LMINIT DATAID(outdd) DATASET("cdsn")"
             CALL Copy_Now
             CALL Clean_Up
             zedlmsg = "The copy function has completed successfully."
             Address ISPEXEC "SETMSG MSG(ISRZ001)"
             CALL Exit_Exec
           End  /* End cdsn 2nd Do Loop and If Statement */
 End  /* End cdsn 1st If Statement */

 /*-------------------------------------------------------------------*/
 /*         If all else fails enter this message and exit             */
 /*-------------------------------------------------------------------*/

 zedlmsg = ""cdsn" was NOT found.  Check 'To Dataset' and Re-Enter."
 Address ISPEXEC "SETMSG MSG(ISRZ001)"
 CALL Clean_Up


 Exit_Exec: EXIT

 /*-------------------------------------------------------------------*/
 /* This is the coping function and is CALLed when all check is done  */
 /* Check to see if CDSN is a PDS or SEQ dataset                      */
 /*-------------------------------------------------------------------*/

 COPY_NOW:
 corg = LISTDSI(cdsn)
 If SYSDSORG = 'PO' then
    If cmem = ""  then
       If cdmem = ""
          Then do
            zedlmsg = "A 'Member Name' MUST be specified when the",
                      "copying TO dataset is a PARTITIONED DATASET"
            Address ISPEXEC "SETMSG MSG(ISRZ001)"
            CALL Clean_Up
            CALL Exit_Exec
          End /* End Then Do from the If cdmem = "" Statement */
          Else do
            cmem = cdmem
            flag = YES
 End  /* End the If cdsn SYSDSORG = 'PO' Statement */
    Else flag = YES

 /*-------------------------------------------------------------------*/
 /*    Check to see if a member was added to a SEQUENTIAL file        */
 /*-------------------------------------------------------------------*/

 If flag ^= YES then
 If cmem = "" then
    If cdmem = "" then NOP
 Else Do
   zedlmsg = "The Copying to dataset is not a PARTITIONED",
             "DATASET and cannot contain a member."
   Address ISPEXEC "SETMSG MSG(ISRZ001)"
   CALL Clean_Up
   CALL Exit_Exec
 End /* End cmem Else Do Statement */
    Else Do
       zedlmsg = "The Copying to dataset is not a PARTITIONED",
                 "DATASET and cannot contain a member."
       Address ISPEXEC "SETMSG MSG(ISRZ001)"
       CALL Clean_Up
       CALL Exit_Exec
    End /* End cdmem Else Do Statement */

 /*-------------------------------------------------------------------*/
 /*    Check to see if WDSN is a PDS or SEQ dataset                   */
 /*-------------------------------------------------------------------*/

 worg = LISTDSI(wdsn)
 If SYSDSORG = 'PO' then
    If wmem = ""
       then do
         zedlmsg = "A member name MUST be specified when the copying",
                   "FROM dataset is a  PARTITIONED DATASET"
         Address ISPEXEC "SETMSG MSG(ISRZ001)"
         CALL Clean_Up
         CALL Exit_Exec
 End  /* End wdsn SYSDSORG If Statement */

 If wmem = "" then
    Address ISPEXEC "LMCOPY FROMID("indd") TODATAID("outdd")",
                    "TOMEM("cmem") REPLACE TRUNC"
 Else
    Address ISPEXEC "LMCOPY FROMID("indd") FROMMEM("wmem")",
                    "TODATAID("outdd") TOMEM("cmem") REPLACE TRUNC"

 /*-------------------------------------------------------------------*/
 /*    Now check the LMCOPY function return code for good completion  */
 /*-------------------------------------------------------------------*/

 If rc ^= 0 then
   If rc = 4
     then do
       zedlmsg = "The FROM dataset is empty.  Copy function has been",
                 "terminated.  Please check the dataset and Re-Enter."
       Address ISPEXEC "SETMSG MSG(ISRZ001)"
       CALL Clean_Up
       CALL Exit_Exec
     End /* End the If rc = 4 Statement */
     Else do
   If rc = 8
     then do
       zedlmsg = "The FROM dataset member is not found.  Copy function",
                 "has been terminated.  Please check the member and",
                 "Re-Enter."
       Address ISPEXEC "SETMSG MSG(ISRZ001)"
       CALL Clean_Up
       CALL Exit_Exec
     End /* End the If rc = 8 Statement */
 End /* End the If rc ^= 0 Statement */

 Return_Copy_now: RETURN

 /*-------------------------------------------------------------------*/
 /* This routine is CALLed to clean-up the LMINIT and LMCOPY function */
 /*-------------------------------------------------------------------*/

 Clean_Up:
 Address ISPEXEC "LMFREE DATAID("indd")"
 Address ISPEXEC "LMFREE DATAID("outdd")"
 Return_Clean_up: RETURN

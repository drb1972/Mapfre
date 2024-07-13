 /* This Rexx Exec will EDIT the WDSN from the user */

 trace (OFF)
 x = msg('off')

 Address ISPEXEC "VGET (WDSN) PROFILE"

 If wdsn = ""
    Then do
      zedlmsg = "There is NO dataset specified to EDIT at this time."
      Address ISPEXEC "SETMSG MSG(ISRZ001)"
      SIGNAL Exit_Exec
 End  /* End Do Loop */

 Address ISPEXEC
 "CONTROL ERRORS RETURN"
 "EDIT DATASET("wdsn")"

 If RC <= 4 Then SIGNAL Exit_Exec

 Address ISPEXEC "SETMSG MSG(&ZERRMSG)"
 SIGNAL Exit_Exec_NOW

 Exit_Exec:
 If RC = 0
   Then Do
     zedsmsg = "DATA SET SAVED"
     Address ISPEXEC "SETMSG MSG(ISRZ001)"
   End /* End the Then Do Statement */
 Exit_Exec_NOW: EXIT

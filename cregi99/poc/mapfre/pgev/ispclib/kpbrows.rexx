 /* This Rexx Exec will BROWSE the WDSN from the user */

 trace (OFF)
 x = msg('off')

 Address ISPEXEC "VGET (WDSN) PROFILE"

 If wdsn = ""
    Then do
      zedlmsg = "There is NO dataset specified to BROWSE at this time."
      Address ISPEXEC "SETMSG MSG(ISRZ001)"
      SIGNAL Exit_Exec
 End  /* End Do Loop */

 Address ISPEXEC
 "CONTROL ERRORS RETURN"
 "BROWSE DATASET("wdsn")"

 If RC <= 4 Then SIGNAL Exit_Exec

 Address ISPEXEC "SETMSG MSG(&ZERRMSG)"

 Exit_Exec: EXIT

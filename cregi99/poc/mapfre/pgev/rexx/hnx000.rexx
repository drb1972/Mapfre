/* REXX ****************************************************************
*
* HNX000 - User exit for the SDF II Extract utility
*
***********************************************************************/

Address ISPEXEC "ISPEXEC VGET (IUV62REQ) SHARED"

/*********************************************************************
* Process panel variable field
*********************************************************************/
If iuv62req='PEV' Then Do
  Address ISPEXEC,
    "ISPEXEC VGET (IUV62NAM IPVEOLIN IPVEOCOL IPVEOLEN IPVEONAM,
                   IPVEOFFO)"
  Q.1=left(IUV62NAM,8) right(IPVEOLIN,2,'0') right(IPVEOCOL,2,'0') ,
      right(IPVEOLEN,2,'0'),
      right(IPVEOFFO,1),
      left(IPVEONAM,20)
  Address TSO "EXECIO 1 DISKW HNX000V (STEM Q. "
End

Exit

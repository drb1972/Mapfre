/* REXX - Check if User has any NDUSRXXX in their CLIST/EXEC library  */
/*
          This routine is used to query the availabe User Routines
          and store the results in a shared pool variable to that
          QuickEdit can display the valid User Rtouintes (if any)
          they can quickly be validated.

          This routine may be enhanced by the customer to determine
          a user's lise of user routines in some other manner and
          or to tailor the displayed options.

          It is expected that all routines will respond to a
          DESCRIPTION call with their "one-line" description
          This will allow the NDUSRXXX to build their own help
          dynamically.

   Copyright (C) 2022 Broadcom. All rights reserved.

    */

C1QEUSRL = ""                  /* Initialise list                     */
C1QEUSRP = ""                  /* Initialise prompt list              */
C1QEUSRM = ""                  /* Initialise Message list             */


ADDRESS TSO "ALTLIB DISPLAY QUIET" /* Query allocated SYSEXEC/CLIST   */
ADDRESS ISPEXEC "VGET (IKJADM) SHARED"  /* Get number of allocations  */

IF IKJADM > 2 then          /* Did we get at least one CLIST or Exec? */
Do
  ikjVars = 'IKJADM3'       /* Initialise IKJADM variables list       */
  rutnFound = 0             /* Flag to indicate that routines found   */
  Do i = 4 to IKJADM
    ikjVars = ikjVars' IKJADM'i /* Build variables list for VGET call */
  End
  ADDRESS ISPEXEC "VGET ("ikjVars") SHARED"
  rutnListRC = 8            /* Set default list RC to 8               */

  settrap = outtrap(ddlist.)
  ADDRESS TSO 'LISTALC STATUS'      /* Get list of allocated datasets */
  settrap = outtrap(off)

  Do i = 3 to IKJADM        /* Loop to check all ALTLIB allocations   */
    interpret 'parse var IKJADM'i' msgid . "DDNAME=" ddn'
    rutnListRC = getDataSets(ddn,ddlist) /* Search NDUSRXxx members   */
  End
  If rutnFound == 1 then
  Do
    RC = populateUserVars() /* Fill user variables from the C1QEUSRL  */
  End
  Else                      /* All DD checked, no user routines found */
    Say "ENDIE440 INFO:No user routines NDUSRXxx found in CLIST libraries"
End
Else Say "ENDIE440 CAUTION:No Altlib Active"

C1QEUSRD = ""
/* Now call each routine to fetch their descriptions
do i = 1 to length(C1QEUSRL) by 2
   THISRTN = substr(C1QEUSRL,i,2)
   NDUSRX = "NDUSRX" || THISRTN
   interpret "result ="  NDUSRX || "('DESCRIPTION')"
   SAY ">"                LEFT(LEFT(THISRTN,2) "-" RESULT,80)
   C1QEUSRD = C1QEUSRD || Left(left(THISRTN,2) "-" result,80)
end
say ""
*/
ADDRESS ISPEXEC 'VPUT (C1QEUSRL C1QEUSRP C1QEUSRM C1QEUSRD) SHARED'

Exit

/* Routine to get datasets allocated to a dd name                     */
getDataSets:
ddn    = '  'arg(1)' '
ddlist = arg(2)

Do m = 1 to ddlist.0                /* Search for the dd name         */
  If strip(substr(ddlist.m,1,11)) = ddn then leave
End

If m > ddlist.0 then
  rc = 8                            /* rc 8 if dd name not found      */
Else do
  m = m-1
  Do until (m >= ddlist.0) | (substr(ddlist.p,1,3) <> '   ')
    dsn = ddlist.m                  /* get the dataset name           */
    rc = populateRutnList(dsn)      /* scan for NDUSRxx routines      */
    m = m + 2                       /* move to next dataset entry     */
    p = m + 1
  End
End

return rc

/* Routine to populate C1 variables with NDUSRXxx routines            */
populateRutnList:
dsn = arg(1)
ADDRESS ISPEXEC "LMINIT DATAID(FIRSTDID) DATASET('"dsn"'),
                 ENQ(SHR) ORG("FIRSTORG")"
If rc /= 0 Then     /*  >=4 - DSN not found or other error            */
Do
  Say "ENDIE440 Error:Invalid RC from LMINIT" RC
  Say ZERRMSG ":" STRIP(ZERRSM,T) "-" STRIP(ZERRLM,T)       /*SIQ16185*/
  return 12
End
Else do
  ADDRESS ISPEXEC 'LMOPEN  DATAID('FIRSTDID')'
  FIRSTMEM=""
  ADDRESS ISPEXEC 'LMMLIST DATAID('FIRSTDID') OPTION(LIST)
                   MEMBER(FIRSTMEM) PATTERN(NDUSRX*)'
  If RC /= 0 then   /*  >=4 - Empty member list or other error        */
  Do                /* Free storage and exit                          */
    ADDRESS ISPEXEC 'LMMLIST  DATAID('FIRSTDID') OPTION(FREE)'
    ADDRESS ISPEXEC 'LMCLOSE  DATAID('FIRSTDID')'
    ADDRESS ISPEXEC 'LMFREE   DATAID('FIRSTDID')'
    return 8
  End
  Else
  Do
    Do while RC = 0 /* Populate members list                          */
      shortRutnName = SUBSTR(FIRSTMEM,7,2,' ')
      If rutnAlreadyExist?(shortRutnName) == 0 then /* No duplicates? */
        C1QEUSRL = C1QEUSRL||shortRutnName      /* Add it to the list */
      ADDRESS ISPEXEC 'LMMLIST DATAID('FIRSTDID') OPTION(LIST)
                       MEMBER(FIRSTMEM) PATTERN(NDUSRX*)'
    End
    /* Free storage:                                                  */
    ADDRESS ISPEXEC 'LMMLIST  DATAID('FIRSTDID') OPTION(FREE)'
    ADDRESS ISPEXEC 'LMCLOSE  DATAID('FIRSTDID')'
    ADDRESS ISPEXEC 'LMFREE   DATAID('FIRSTDID')'

    rutnFound = 1  /* Indicate that user routines found               */
    return 0
  End
    /* This code shouldn't execute                                    */
  return 12
End
    /* This code shouldn't execute                                    */
return 12

/* Routine to populate user variables from C1QEUSRL                   */
populateUserVars:
Sa= "C1QEUSRL:" C1QEUSRL "Length:" length(C1QEUSRL)
C1QEUSRP = RIGHT(STRIP(LEFT(C1QEUSRL,2),'T'),2)
C1QEUSRM = STRIP(LEFT(C1QEUSRL,2),'T',' ')
if length(C1QEUSRL) > 2 then do
  do k = 3 to (length(C1QEUSRL)-2) by 2
    C1QEUSRP = C1QEUSRP || ' '  || STRIP(SUBSTR(C1QEUSRL,k,2),'T')
    C1QEUSRM = C1QEUSRM || ', ' || STRIP(SUBSTR(C1QEUSRL,k,2),'T')
  end
    C1QEUSRP = C1QEUSRP || ' '  || STRIP(SUBSTR(C1QEUSRL,k,2),'T')
    C1QEUSRM = C1QEUSRM ||', and '||STRIP(SUBSTR(C1QEUSRL,k,2),'T')
end
Sa= "C1QEUSRP:" C1QEUSRP
Sa= "C1QEUSRM:" C1QEUSRM
return 0

/* Routine to check C1QEUSRL for duplicates                           */
rutnAlreadyExist?:
rutn = STRIP(arg(1),'T')
Do j = 1 to (length(C1QEUSRL)) by 2
  If rutn == STRIP(SUBSTR(C1QEUSRL,j,2),'T') then return 1
End
return 0

/* REXX                                                              */
/*-------------------------------------------------------------------*/
/*                                                                   */
/* Copyright (C) 2022 Broadcom. All rights reserved.                 */
/*                                                                   */
/* NAME: ENXDEPLY                                                    */
/*                                                                   */
/* PURPOSE: This is the Deploy for Test Facility main driver program.*/
/*                                                                   */
/*-------------------------------------------------------------------*/
 /*  DEPLOY FOR TEST FACILITY  */
  TRACE O  ;

/* Initialize vars for WideScreen Support         */
  LONGPANL = "ENXPSELS"                     /* Default to pri scrn */
  SomeSeld = "NO"       /* default flag no selections made */
  CancelReq = "NO"      /* default flag cancel not requested yet*/
  ADDRESS ISPEXEC "VGET (ZAPPLID ZSCREEN zUSER zSYSID zPREFIX)"

  /* Decide on Temporary Dataset name prefix...                         */
  if zSYSID = SPECIAL then do              /* is this a special system? */
     /* insert system specific logic if required here                   */
     XFERDsPrefix = left(zUSER,3)||'.'|| ,
        zUser'.'STRIP(LEFT('E'||ZSYSID,8))||'.XFER'||ZSCREEN
     XFERTempDir  = '/tmp/'left(zUSER,3)||'/'|| ,
        STRIP(LEFT('E'||ZSYSID,8))||'/XFER'||ZSCREEN
     end
  else /* otherwise we use some sensible defautls                       */
    if zPrefix \= '',                      /* is Prefix set?  and NOT.. */
     & zPrefix \= zUSER then do            /* the same as userid?       */
       XFERDsPrefix = zPrefix ||'.'|| ,
          zUser'.'STRIP(LEFT('E'||ZSYSID,8)) || '.XFER'||ZSCREEN
       XFERTempDir  = '/tmp/'zPrefix||'/'||zUser||'/'|| ,
          STRIP(LEFT('E'||ZSYSID,8))||'/XFER'||ZSCREEN
       end
    else do                                /* otherwise use user name   */
       XFERDsPrefix = zUser ||'.'|| ,
          STRIP(LEFT('E'||ZSYSID,8)) || '.XFER' || ZSCREEN
       XFERTempDir  = '/tmp/'||zUser||'/'|| ,
          STRIP(LEFT('E'||ZSYSID,8))||'/XFER'||ZSCREEN
    end


  INPPKGE   = ' ' /* EOC - Forcing In Package Processing off??? */
/*
  Call Check_For_Package_Execution ;
*/
  ADDRESS ISPEXEC,
     "VPUT (INPPKGE) SHARED"

  If INPPKGE /= ' ' then, /* Package Processing */
     Do
     Mode = 'package'
     Call Process_Package_XFER ;
     Call Build_Package ;
     If CASTPKGE = "Y" then Call CAST_Package;
     Exit
     End                  /* Package Processing */

  Mode = 'element'
  SA= 'YOU ARE NOT DOING PACKAGE PROCESSING'
  ADDRESS ISPEXEC,
     "VGET (ZSCREEN) SHARED"

/* for table status...                                             */
/*  1 = table exists in the table input library chain              */
/*  2 = table does not exist in the table input library chain      */
/*  3 = table input library is not allocated.                      */
/*                                                                 */
/*  1 = table is not open in this logical screen                   */
/*  2 = table is open in NOWRITE mode in this logical screen       */
/*  3 = table is open in WRITE mode in this logical screen         */
/*  4 = table is open in SHARED NOWRITE mode in this logical screen*/
/*  5 = table is open in SHARED WRITE mode in this logical screen. */
/*                                                                 */
/* In Quick Edit ?                                */

  UseTable = "EN"ZSCREEN"IE250"
  ADDRESS ISPEXEC,
     "TBSTATS" UseTable "STATUS1(STATUS1) STATUS2(STATUS2)"
     IF STATUS2 /= 2 & STATUS2 /= 3 & STATUS2 /= 4 THEN,
        DO
        ADDRESS ISPEXEC "SETMSG MSG(ENXM010E)"  /* Invalid panel */
        EXIT                                    /* and get out   */
        END
/*
  UseTable = "EN"ZSCREEN"IE250"
  ADDRESS ISPEXEC,
     "TBSTATS" UseTable "STATUS1(STATUS1) STATUS2(STATUS2)"

     IF STATUS2 /= 2 & STATUS2 /= 3 & STATUS2 /= 4 then,
        do
/* no, so try LongName ???                                */
        UseTable = "LN"ZSCREEN"IE250"
        ADDRESS ISPEXEC,
        "TBSTATS" UseTable "STATUS1(STATUS1) STATUS2(STATUS2)"
        IF STATUS2 /= 2 & STATUS2 /= 3 & STATUS2 /= 4 then,
           do
/* finally, try In Endevor  ???                                */
           UseTable = "CIELMSL"ZSCREEN
           ADDRESS ISPEXEC,
           "TBSTATS" UseTable "STATUS1(STATUS1) STATUS2(STATUS2)"
           IF STATUS2 /= 2 & STATUS2 /= 3 & STATUS2 /= 4 then,
              do
              ADDRESS ISPEXEC "SETMSG MSG(ENXM010E)"  /* Invalid panel */
              exit                                    /* and get out   */
              end
           END
        END
*/
  ADDRESS ISPEXEC,
  "TBQUERY" UseTable "KEYS(KEYLIST) NAMES(VARLIST) ROWNUM(ROWNUM)"
  IF RC > 0 THEN EXIT

  ADDRESS ISPEXEC,
  "TBTOP" UseTable

  /*  Any element with a type found in the list below is
      eligible for XFER. Map elements are selected specifically
      if their processor group has a "B" or "C" in the 6th position */

  /* Example for controlling which Types are eligible for XFER..... */
  /*  XFER_TYPES = "COBOL ASMPGM CICSMAP " ; */

  COUNT = 0

  call Create_PickList_Table /* build table from wherever we came from */

  IF COUNT = 0 then,
     Do
     ADDRESS ISPEXEC "TBEND" PickLstTable  /* we're done with table */
     ADDRESS ISPEXEC "SETMSG MSG(ENXM010W)"  /* no match */
     EXIT
     End;

  Call Get_Subsystem_List ;    /* Use API to list target subs */

  Call First_Time_Preparations ;
  if PICKLIST \= 'Y',
   | countsel > 0 then,
     Do
     Call Build_Endevor_SCL ;
     If ACTION = 'DEPLOY  ' & CASTPKGE = "Y" then,
           Call CAST_Package;
     Call Submit_JCL ;
     End

  ADDRESS ISPEXEC "TBEND" PickLstTable  /* we're done with table */

  exit

Create_PickList_Table:

  SA= 'CREATE_Picklist_Table               ' ;

/*  We actually need to create a consistent / consolidated         */
/*  picklist table - i.e. pick/merge QE/Endevor/Package data       */
/*  "names"varlist" keys"keylist" WRITE" */

/*
     When you compare the layout of the Endevor CLASSIC
     and Q/E table it's obvious that the QuickEdit panels
     were developed by a different hand/era.  This table
     attempts to map the LongName, QuickEdit and Classic
     field names.  LongName for the most part matches Q/E
     since it was based on it, with it's "extra" fields
     having a prefix LN...  The Classic panels now have a
     lot of names some probably legacy and potentially
     duplicates that might just go away in a clean-up.
     For XFER the plan is to use a Q/E like table and
     simply copy the corresponding Classic names to the
     equivalent Q/E name... it's not pretty but it should
     work.  A stretch goal would be to support the extra
     LongName/Classic fields that are common...
     Q/E fields that are not displayed/sorted won't be mapped.

     LONGNAME QUICKEDIT CLASSIC  HEADING/Comment
     -------- --------- -------  ---------------------------
              EEVEIND   VNTRIND  +
     EEVETCCI EEVETCCI  ECTL#    CCID
     EEVETDMS EEVETDMS  TOFRNAME MESSAGE
     EEVETDSL EEVETDSL  STGSEQ#  STSEQ
     EEVETDVL EEVETDVL  ECVL     VVLL
     EEVETKEL EEVETKEL  ENTEN255 ELEMENT
     EEVETKEN EEVETKEN  EMENV    ENVIRON
     EEVETKSB EEVETKSB  EMSBS    SUBSYS
     EEVETKSI EEVETKSI  EMSTGID  STAGE
     EEVETKSN EEVETKSN  CLN8     STNAME
     EEVETKST EEVETKST  EMKSTGI  #ST
              EEVETKSX  EMSTGL#
     EEVETKSY EEVETKSY  EMSYS    SYSTEM
     EEVETKTY EEVETKTY  EMTYPE   TYPE
     EEVETNRC EEVETNRC  EMRC     NDRC
     EEVETNS  EEVETNS   ENSC     NS
              EEVETOEN
              EEVETOSB
              EEVETOSN
              EEVETOST
              EEVETOSX
              EEVETOSY
              EEVETOTY
     EEVETPGR EEVETPGR  EPRGRP   PROCGRP
     EEVETPRC EEVETPRC  EPRC     PRRC
              EEVETSEL
     EEVETSO  EEVETSO   EOWNRID  SIGNOUT
     EEVETUID EEVETUID  EMLUID   USERID
    *ESRFOUND ESRFOUND  ESRFOUND FOUND (AFTER SEARCH)
    *-*-*-*-* UN-MATCHED VARIABLES FOLLOW *-*-*-*-*-*-*-*-*-*-*-*-*-*-*
     LNCSVSEQ                    CSV SEQ NO.
     LNDESCRP                    DESCRIPTION
     LNDGCCID                    GEN CCID
     LNDPKGBO                    BACKAGE BACKED OUT
     LNDPKGDO
     LNDPKGIO
     LNDPKGIS
     LNDPKGLK                    PACKAGE LOCKED
     LNDRCCID                    RETRIEVE CCID
     LNELMNAM
     LNGEDATE           EMLPD    GEN DATE
     LNGETIME           EMLPT    GEN TIME
     LNLACOMM           EMCCOM   LAST ACT COMMENT
     LNLADATE           EMLDTE   LAST ACT DATE
     LNLASACT           ELSTACT  LAST ACTION
     LNLATIME           EMLT     LAST ACTION TIME
     LNLKDATE                    LOCKED DATE
     LNLKTIME                    LOCKED TIME
     LNLOCKED                    LOCKED IND
     LNMVDATE                    MOVE DATE
     LNMVTIME                    MOVE TIME
     LNUPDATE                    UPDATE DATE
     LNUPTIME                    UPDATE TIME
     USERDATA                    USER DATA
                        CITBLKEY TABLE KEY
                        CLN      STAGE DESCRIPT
                        CTLNBR
                        DESCRPT1 1
                        EMBCOMM
                        EMBDTE
                        EMBT
                        EMID
                        EMKENV   KEY ENV
                        EMKNAME  KEY ELE NAME
                        EMKSTGI  KEY STAGE ID
                        EMKSBS   KEY SUBSYS
                        EMKSYS   KEY SYSTEM
                        EMKTYPE  KEY TYPE
                        EMLLVL   LEVEL NUMBER OF VVLL
                        EMNAME   SHORT NAME
                        EMPD
                        EMPRFLG
                        EMSRCD   SOURCED?
                        EMVERS   VERSION NUMBER OF VVLL
                        EMXADATE
                        EMXBDATE
                        EMXGDATE GENERATE DATE YYYYJJJF
                        EMXLDATE LASTACT DATE  YYYYJJJF
                        EMXMDATE
                        EMXPDATE
                        EMXRDATE
                        EMXSDATE
                        ENTEN25L
                        ETA
                        SO
                        VEYDDN   MCF DDNAME?

      Picklist Namelist
         EEVEIND  EEVETCCI EEVETDMS EEVETDSL EEVETDVL EEVETKEL
         EEVETKEN EEVETKSB EEVETKSI EEVETKSN EEVETKST EEVETKSX
         EEVETKSY EEVETKTY EEVETNRC EEVETNS  EEVETPGR EEVETPRC
         EEVETSO  EEVETUID ESRFOUND EEVETSEL


*/
  PickLstTable = "EN"ZSCREEN"PKLST"; /*  set Pick List table name */

  ADDRESS ISPEXEC,
     "TBSTATS" PickLstTable "STATUS1(STATUS1) STATUS2(STATUS2)"
     if RC = 0,
      & STATUS3 = 3 then
        ADDRESS ISPEXEC "TBEND"   PickLstTable

  ADDRESS ISPEXEC,
    "TBCREATE" PickLstTable,
    'NAMES(EEVEIND  EEVETCCI EEVETDMS EEVETDSL EEVETDVL EEVETKEL ',
          'EEVETKEN EEVETKSB EEVETKSI EEVETKSN EEVETKST EEVETKSX ',
          'EEVETKSY EEVETKTY EEVETNRC EEVETNS  EEVETPGR EEVETPRC ',
          'EEVETSO  EEVETUID ESRFOUND EEVETSEL) NOWRITE ' ;

  ADDRESS ISPEXEC "TBTOP   "UseTable ;    /* Eoc if not Q/E table need to map*/

  Do row = 1 to ROWNUM
     ADDRESS ISPEXEC "TBSKIP "UseTable
     /* if coming from Endevor table, map the different field names */
     If Substr(UseTable,1,7) = 'CIELMSL' then do
        EEVEIND  = VNTRIND
        EEVETCCI = ECTL#
        EEVETDMS = TOFRNAME
        EEVETDSL = STGSEQ#
        EEVETDVL = ECVL
        EEVETKEL = ENTEN255
        EEVETKEN = EMENV
        EEVETKSB = EMSBS
        EEVETKSI = EMSTGID
        EEVETKSN = CLN8
        EEVETKST = EMKSTGI
        EEVETKSX = EMSTGL#
        EEVETKSY = EMSYS
        EEVETKTY = EMTYPE
        EEVETNRC = EMRC
        EEVETNS  = ENSC
        EEVETPGR = EPRGRP
        EEVETPRC = EPRC
        EEVETSO  = EOWNRID
        EEVETUID = EMLUID
        ESRFOUND = ESRFOUND
     end

     /* Eoc This test doesn't make sense at this point, we are just reading
        the input list of elements and we haven't gotten a target TOSUBSYS
        yet.  We could still have an empty element list (somehow, maybe after
        exclude all which would generate XFER010W")
        */
     IF TOSUBSYS = EEVETKSB THEN ITERATE ;

     EEVETSEL = '' /* blank out Sel     */
     EEVETDMS = '' /* blank out message */
     ADDRESS ISPEXEC "TBADD" PickLstTable /* EOC just add in order found " */
     COUNT = COUNT + 1;
     If COUNT = 1 then,   /* EOC - This looks unsafe, only use first row??? */
        Do              /* What if there are multiple rows? even multiple sys?*/
        Environment = EEVETKEN ; /* EOC - do we need all these extra vars     */
        ENVIRON     = EEVETKEN ; /* refactor to just use the table variables  */
        Stage       = EEVETKSI ;
        PKGSYSTM    = EEVETKSY ;
        SYSTEM      = EEVETKSY ;
        FROMSUBS    = EEVETKSB ;
        End;

     If (Environment /= EEVETKEN |,
         SYSTEM /= EEVETKSY |,
         FROMSUBS /= EEVETKSB) then,
        Do
        ADDRESS ISPEXEC "TBEND" PickLstTable
        ADDRESS ISPEXEC "SETMSG MSG(ENXM020E)"
        EXIT
        End;

  End; /* do row = 1 to rownum */

  Return;


Get_Subsystem_List:

   Sa= "Start of building Subsystem List"

   ADDRESS TSO,
   "ALLOC F(SYSIN)",
          "LRECL(80) BLKSIZE(800) SPACE(5,5)",
          "RECFM(F B) TRACKS ",
          "NEW UNCATALOG REUSE "     ;

   Queue 'AACTL MSGFILE SBSLIST       '
   tmp = 'ALSBS                       '
   tmp = OVERLAY(EEVETKEN,tmp,10) ;
   tmp = OVERLAY(EEVETKSY,tmp,19) ;
   tmp = OVERLAY('*',tmp,27) ;
   Queue tmp
   Queue 'RUN                         '
   Queue 'AACTLY                      '
   Queue 'RUN                         '
   Queue 'QUIT                        '
   ADDRESS TSO,
      "EXECIO" QUEUED() "DISKW SYSIN    (FINIS " ;

   ADDRESS TSO,
   "ALLOC F(SBSLIST)",
          "LRECL(200) BLKSIZE(24000) SPACE(5,5)",
          "RECFM(F B) TRACKS ",
          "NEW UNCATALOG REUSE "     ;

   ADDRESS TSO,
      "ALLOC F(SYSPRINT) DUMMY REUSE "

   ADDRESS TSO,
   "ALLOC F(MSGFILE)",
          "LRECL(121) BLKSIZE(0)     SPACE(5,5)",
          "RECFM(F B A) TRACKS ",
          "NEW UNCATALOG REUSE "     ;


   ADDRESS LINK "ENTBJAPI" ;
   IF RC > 4 THEN,
        Do
        ADDRESS ISPEXEC "LMINIT DATAID(DDID) DDNAME(MSGFILE)"
        ADDRESS ISPEXEC "VIEW DATAID(&DDID)"
        ADDRESS ISPEXEC "LMFREE DATAID(&DDID)"
        Return;
        End

   ADDRESS TSO "FREE  F(SYSIN)"
   ADDRESS TSO "FREE  F(MSGFILE)"

   ADDRESS TSO,
      "EXECIO * DISKR SBSLIST (STEM subs. Finis"
   SBSLIST = "" ;
   SBSDESC = "" ;
   Do num = 1 to subs.0
      SBS     = Strip(Substr(subs.num,30,8))
      NextSBS     = Strip(Substr(subs.num,133,8))
      DescSBS     = Strip(Substr(subs.num,83,50))
      If SBS = FROMSUBS then,
         If NextSBS = 'DEPLOY4T' then,
            Do
            ADDRESS ISPEXEC "SETMSG MSG(ENXM021E)"
            ADDRESS ISPEXEC "TBEND" PickLstTable
            Exit
            End
  /* Example for controlling which Subsystems ....... */
  /*         appear on the XFER panel    ....         */
  /*                                                  */
  /*  SBS_5#8 = Substr(SBS,5,4) ;                     */
  /*  SBS_1#1 = Substr(SBS,1,1) ;                     */
  /*                                                  */
  /* Note: It might be a good idea to ALSO set the    */
  /*       "EXCLUDE FROM DUPLICATE ELEMENT PROC O/P   */
  /*        TYPE CHECK:" to Y so that Test locations  */
  /*       don't flag as duplicate elements.          */
  /*                                                  */
  /*                                                  */
      If NextSBS /= 'DEPLOY4T' then iterate ;
  /*  If Datatype(SBS_5#8) = "NUM" then iterate ; */
      If SBS = EEVETKSB then iterate ;
      /* make sure they line up nice an attribute/separator & 8chr name*/
      SBSLIST = SBSLIST || '01'x || LEFT(SBS,8) ;
      /* Create an extra array string with the targets & descriptions*/
      /* With hex '01'x and '02'x for attribute control              */
      SBSDESC = SBSDESC || '01'x || LEFT(SBS,8),
                        || '02'x || LEFT(DESCSBS,50)
   End

   sa= "SBSLIST:" SBSLIST
   sa= "SBSDESC:" SBSDESC
   ADDRESS TSO "FREE  F(SBSLIST)"

   if SBSLIST = "" then do /* If we didn't find any valid subsystems  */
        ADDRESS ISPEXEC "SETMSG MSG(ENXM016E)"  /* No Valid Targets   */
        ADDRESS ISPEXEC "TBEND" PickLstTable    /* done with table    */
        Exit                                    /* and return to user */
      end
   Sa= "End building Subsystem List" SBSLIST

   Return

First_Time_Preparations:

  VARWKCMD =  "" ;
  ADDRESS ISPEXEC,
      "VGET (C1BJC1 C1BJC2 C1BJC3 C1BJC4) PROFILE "
  ADDRESS ISPEXEC,
      "VGET (EEVOCPBK) ASIS    "    /* EOC - not used? maybe copyback option*/
  ADDRESS ISPEXEC,
      "VGET (EEVOOSGN) ASIS    "    /* EOC - should be on ENXPPREP panel */
  SA= "S/O IS" EEVOOSGN

  Call Build_Package_Unique_Value ; /* get current date & time */
  /* Example for building the package name    ....... */
  PACKAGE = "X#" || PKGUNIQ ;
  position = 4;
  If Length(Strip(FROMSUBS)) > 4 then position = 5;
  Call Calculate_Date_Fields ;    /* for execution window */
  Do Forever

     ADDRESS ISPEXEC "DISPLAY  PANEL(ENXPPREP) "
     if rc > 0 then do
        ADDRESS ISPEXEC "SETMSG MSG(ENXM013W)"  /* request cancelled */
        ADDRESS ISPEXEC "TBEND" PickLstTable    /* we're done with table */
        exit                                  /* get out on END from ENXPPREP */
     end

     PACKAGE = Strip(PACKAGE);
     If Length(PACKAGE) < 16 then,
       Call Build_Package_Name_Suffix ; /* remainder of package name*/

     sa= Mode
     IF Mode /= 'element' |,
        PICKLIST /= 'Y' THEN Leave  ;

     countsel = 0
     ADDRESS ISPEXEC "CONTROL DISPLAY SAVE"
     Call Display_PickList_Table ;
     ADDRESS ISPEXEC "CONTROL DISPLAY RESTORE"
     if CancelReq = "YES",
      | VARWKCMD = "CANCEL" then do
        ADDRESS ISPEXEC "SETMSG MSG(ENXM013W)"  /* request cancelled */
        ADDRESS ISPEXEC "TBEND" PickLstTable    /* we're done with table */
        exit                                  /* get out on END from ENXPPREP */
     end
     if PICKLIST  = 'Y',                /* User asked for countsel list     */
      & countsel = 0 then do            /* but nothing selected yet         */
        PICKLIST  = 'N'                 /* reset PickList flag              */
        SomeSeld = "NO"                 /* reset Something selected flag    */
        ADDRESS ISPEXEC "SETMSG MSG(ENXM014W)"  /* Empty countsel list      */
     end
     If countsel > 0 then leave;        /* OR we have a countsel...         */
  End  /*  Do Forever */

  /*
  */
  Return ;

Build_Package_Name_Suffix:

     position = 4;
     If Length(Strip(TOSUBSYS)) > 4 then position = 5;
     PACKAGE = Overlay(Substr(TOSUBSYS,position,1),PACKAGE,13)
     PACKAGE = Substr(PACKAGE,1,13) ;
  /*                                                    */
     ADDRESS TSO,
     "ALLOC F(BSTIPT01) LRECL(80) BLKSIZE(8000) SPACE(5,5)",
            "RECFM(F B) TRACKS DSORG(PS)",
            "NEW UNCATALOG REUSE "     ;
     QUEUE "LIST PACKAGE ID '"Strip(Package)"*'"
     QUEUE "     TO FILE 'APIEXTR'          "
     QUEUE "     OPTIONS NOCSV .            "
     ADDRESS TSO,
     "Execio" QUEUED() "DISKW BSTIPT01 ( FINIS"

  /*
     ADDRESS TSO "ALLOC F(C1MSGS1) DA(*)"
     ADDRESS TSO "ALLOC F(BSTERR)  DA(*)"
  */

     ADDRESS TSO,
        "ALLOC F(C1MSGS1)",
            "LRECL(133) BLKSIZE(26600) SPACE(5,5)",
            "RECFM(F B) TRACKS ",
            "NEW UNCATALOG REUSE "     ;
     ADDRESS TSO "ALLOC F(BSTERR)  DUMMY"

  /*                                                    */
     ADDRESS TSO,
     "ALLOC F(APIEXTR) LRECL(1800) BLKSIZE(18000) SPACE(5,5)",
            "RECFM(F B) TRACKS DSORG(PS)",
            "NEW UNCATALOG REUSE "     ;
  /*                                                    */
     ADDRESS LINKMVS 'BC1PCSV0'
     myRC = RC

     ADDRESS TSO "FREE F(BSTIPT01)"
     ADDRESS TSO "FREE F(BSTERR)"

     IF myRC > 4 THEN,
        Do
        Say "My Return Code = " myRc ;
        ADDRESS ISPEXEC "LMINIT DATAID(DDID) DDNAME(C1MSGS1)"
        ADDRESS ISPEXEC "VIEW DATAID(&DDID)"
        ADDRESS ISPEXEC "LMFREE DATAID(&DDID)"
        PACKAGE = PACKAGE || '001'
        ADDRESS TSO "FREE F(APIEXTR)"
        Return;
        End

     ADDRESS TSO,
     "EXECIO * DISKR APIEXTR (STEM API. FINIS"

     ADDRESS TSO "FREE F(APIEXTR)"
     ADDRESS TSO "FREE F(C1MSGS1)"

  /* Now find the last of the existing packages         */

     LARGEST_VALUE = "000";
     LENGTH_ENTERED = LENGTH(PACKAGE) ;
     DO PKG = 1 TO API.0
        OldPackage = SUBSTR(API.PKG,13,16) ;
        OldPkgStatus = Strip(SUBSTR(API.PKG,116,12)) ;
        If OldPkgStatus = 'IN-EDIT' then iterate;
  /*    If OldPkgStatus = 'EXEC-FAILED' then iterate;  */
        TEMP = SUBSTR(OldPackage,(LENGTH_ENTERED+1)) ;
        IF TEMP > LARGEST_VALUE THEN LARGEST_VALUE = TEMP ;
     END /* DO PKG = 1 TO API.0 */

     INCREMENTS =  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" ;
     INCREMENTS =  "0123456789" ;
     FRST_CHAR  =  SUBSTR(INCREMENTS,1,1) ;
     LARGEST_VALUE = STRIP(LARGEST_VALUE,T) ;
     IF LENGTH(LARGEST_VALUE) + LENGTH_ENTERED < 16 THEN,
        DO
        TEMP = COPIES(FRST_CHAR,16) ;
        PACKAGE = substr(PACKAGE||LARGEST_VALUE||TEMP,1,16);
        END;
     ELSE,
        DO
        PACKAGE = PACKAGE||LARGEST_VALUE ;
        POINT  = LENGTH(PACKAGE)
          DO FOREVER
             LAST_CHAR = SUBSTR(PACKAGE,POINT,1) ;
             INCR_POS  = POS(LAST_CHAR,INCREMENTS) ;
             IF LAST_CHAR < FRST_CHAR THEN,
                DO
                PACKAGE = OVERLAY(FRST_CHAR,PACKAGE,POINT) ;
                LEAVE
                END
             IF INCR_POS > 0 &,
                INCR_POS < LENGTH(INCREMENTS) THEN,
                DO
                NEXT_CHAR = SUBSTR(INCREMENTS,(INCR_POS+1),1)
                PACKAGE = OVERLAY(NEXT_CHAR,PACKAGE,POINT) ;
                LEAVE
                END ;
             PACKAGE = OVERLAY(FRST_CHAR,PACKAGE,POINT) ;
             POINT = POINT - 1;
             IF POINT < LENGTH_ENTERED THEN EXIT(8)
          END /* DO FOREVER */
        END; /* IF LENGTH(LARGEST_VALUE) ... ELSE */



  Return ;


Display_PickList_Table:
  ADDRESS ISPEXEC "TBTOP" PickLstTable       ;

  ADDRESS ISPEXEC "SETMSG MSG(ENXM019I)" ;

  countsel = 0 ;
  VARWKCMD = "";     /* Reset the command */
  VARC1LR = PASSTHRU /* Enable Left/Right commands */
  DO FOREVER         /* Till user presses END or CANCEL */
     sa= "selected:" countsel
     ADDRESS ISPEXEC "TBDISPL" PickLstTable "PANEL("LONGPANL")"
     TBDRC = RC
     IF TBDRC >= 8 THEN,      /* user wants out */
        DO
        address ispexec "vget (zverb)" /* Cancel, End or Return? */
        if ZVERB == 'CANCEL' then do
           ADDRESS ISPEXEC "SETMSG MSG(ENXM013W)"  /* request cancelled */
           SomeSeld = "NO"                         /* reset countsel */
           CancelReq = "YES"                       /* getting out    */
        end;
        leave
     end;
     THISTOPR = ZTDTOP      /* save the top row so we can restore it */
     DO WHILE ZTDSELS > 0   /* process any modified rows */
        SA= 'ZTDSELS=' ZTDSELS 'ZTDTOP=' ZTDTOP
        sa= "PROCESSING ELEMENT " EEVETKEL C1ELTYPE
        IF Strip(EEVETSEL) = "S" then,
           Do
           EEVETSEL = ' '
           SomeSeld = "YES"
           If EEVETDMS /= '*SELECTED*' then countsel = countsel + 1 ;
           EEVETDMS = '*SELECTED*'
           ADDRESS ISPEXEC "TBPUT" PickLstTable  ;
           End;
        IF Strip(EEVETSEL) = "U" then,
           Do
           EEVETSEL = ' '
           If EEVETDMS  = '*SELECTED*' then countsel = countsel - 1 ;
           EEVETDMS = ' '
           ADDRESS ISPEXEC "TBPUT" PickLstTable  ;
           End;
        IF ZTDSELS = 1 then leave /* we got em all get out now */
        ADDRESS ISPEXEC "TBDISPL" PickLstTable ; /* get next */
        sa= 'ZTDSELS=' ZTDSELS 'RC=' rc
     end
     /* now process any primary commands */
     THISCMD = VARWKCMD;                /* get any command */
     VARWKCMD = "";                     /* reset the command */
     parse upper var THISCMD THISCMDW THISCMDP

     select
       when THISCMDW == ''              then NOP;
       when THISCMDW == 'LEFT'          then call Toggle_Screen;
       when THISCMDW == 'RIGHT'         then call Toggle_Screen;
       when THISCMDW == 'SELECT'        then call Select_All;
       when THISCMDW == 'ESORT' then do /* PS Sort request */
         ADDRESS ISPEXEC "SELECT CMD("THISCMD")"
       end
       when THISCMDW == 'CANCEL'        then do
           ADDRESS ISPEXEC "SETMSG MSG(ENXM013W)"  /* request cancelled */
           countsel = 0                            /* reset countsel */
           SomeSeld = "NO"                         /* reset SomeSel'd*/
           leave
        end;
     otherwise
       do
          VARWKCMD = THISCMD /* restore command so it can be corrected */
          ADDRESS ISPEXEC "SETMSG MSG(ENXM015E)" ; /* Cmd Not Recognized */
       end
     end /* select */
  /* re-position table */
  ADDRESS ISPEXEC "TBTOP   "PickLstTable ;
  ADDRESS ISPEXEC "TBSKIP  "PickLstTable" NUMBER("THISTOPR")"
  END;  /* Forever - DO until user presses End or cancel    */

  VARC1LR = ''       /* Allow standard Left/Right  */

  ADDRESS ISPEXEC "TBTOP" PickLstTable ;

  sa= "Selected:" SomeSeld countsel "of" count

/*  ADDRESS ISPEXEC "TBEND" PickLstTable ; EOC refactor cleanup */
  UseTable = PickLstTable ; /*  Use Pick List table now */
  Return ;

Build_Package_Unique_Value:

   PKGSTAGE   = Stage                 /* Package Prefix */
   EXECUTE    = "Y" ;                 /* Execute =     on */
   EXECUTE    = "N" ;                 /* Execute = not on */
                   /* Not needed if Package Automation is on */

   NUMBERS    = '123456789' ;
   CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ;
   TODAY = DATE(O) ;
   YEAR = SUBSTR(TODAY,1,2) + 1;
   YEAR = SUBSTR(CHARACTERS||CHARACTERS||CHARACTERS||CHARACTERS,YEAR,1)
   MONTH = SUBSTR(TODAY,4,2) ;
   MONTH = SUBSTR(CHARACTERS,MONTH,1) ;
   DAY = SUBSTR(TODAY,7,2) ;
   DAY = SUBSTR(CHARACTERS || NUMBERS,DAY,1) ;
   NOW  = TIME(L);
   HOUR = SUBSTR(NOW,1,2) ;
   IF HOUR = '00' THEN HOUR = '0'
   ELSE
   HOUR = SUBSTR(CHARACTERS,HOUR,1) ;

   MINUTE = SUBSTR(NOW,4,2) ;
   SECOND = SUBSTR(NOW,7,2) ;
   Fractn = SUBSTR(NOW,10,6) ;
   PKGUNIQ = YEAR || MONTH || DAY || HOUR ||,
         MINUTE || SECOND || Fractn ;

   Return ;

Calculate_Date_Fields:

  ADDRESS ISPEXEC               /* Default to QuickEdit CCID/Comment */
     "VGET  (EEVCCID EEVCOMM)"
  CCID     = EEVCCID
  COMMENT  = EEVCOMM

  GENERATE = "Y" ;

  TEMP     = DATE('N')
  DAY      = WORD(TEMP,1)
  IF LENGTH(DAY) < 2 THEN DAY = "0"DAY ;
  MON      = WORD(TEMP,2)
  YEAR     = SUBSTR(WORD(TEMP,3),3,2) ;
  IF LENGTH(YEAR) < 2 THEN YEAR = "0"YEAR ;
  BTSTDATE = DAY || MON || YEAR;
  ONSTDATE = DAY || MON || YEAR;

  TEMP     = TIME('N')
  BTSTTIME = SUBSTR(TEMP,1,5)
  BTSTTIME = "00:00"

  BTENDATE = "31DEC79"
  BTENTIME = "00:00"

  Return ;

Build_Endevor_SCL:

/* CASTPKGE = "Y"  */
   DESCRIPT = "Deployed to "TOSUBSYS,
              "by" USERID() "@" DATE() ;
   DESCRIPT = OVERLAY('    ',DESCRIPT,47) ;

   If ACTION = 'DEPLOY  ' then ,
      ADDRESS TSO,
      "ALLOC F(PKGESCL)",
             "LRECL(80) BLKSIZE(800) SPACE(5,5)",
             "RECFM(F B) TRACKS ",
             "NEW UNCATALOG REUSE "     ;
/*                                                                   */
   ELMTABLE = XFERDsPrefix".XFERELMS."Substr(PKGUNIQ,1,8) ;
   ADDRESS TSO,
   "ALLOC F(ELMTABLE) LRECL(80) BLKSIZE(24000) SPACE(1,5)",
          "RECFM(F B) TRACKS DSORG(PS) ",
          "DA('"ELMTABLE"')",
          "MOD CATALOG REUSE "     ;
   elm.0 = 0
/*                                                                   */

   If ACTION = 'DEPLOY  ' then ,
      Do
      Queue "SET TO SUBSYSTEM '"TOSUBSYS"'." ;

      Queue "SET OPTIONS CCID '"CCID"'"
      Queue "    COMMENT '"COMMENT"' "
      Queue "       WITH HISTORY BYPASS ELEMENT DELETE SYN  "
      if SIGNOUT2 \= '' then             /* Did user request specific signout?*/
         Queue "       SIGNOUT TO "SIGNOUT2
      else                               /* Otherwise use this ID or tailor...*/
         Queue "       SIGNOUT TO "USERID()
         /* Queue "       SIGNOUT TO "TOSUBSYS */
         /* Queue "       SIGNOUT TO "EEVETUID */
         /* Queue "      OVERRIDE SIGNOUT."    */

      IF EEVOOSGN = "Y" THEN,
         Queue "      OVERRIDE SIGNOUT."
      ELSE,
         Queue "      . "

      End; /* If ACTION = 'DEPLOY  ' */

   /* Eoc Use PickList table instead of Element_list */
   ADDRESS ISPEXEC "TBQUERY" PickLstTable " ROWNUM(PICKROWS)"
   ADDRESS ISPEXEC "TBTOP"   PickLstTable
   Do cnt = 1 to PickRows
      ADDRESS ISPEXEC "TBSKIP" PickLstTable
      if rc > 0 then do
         say "Unexpected RC from TBSKIP ("RC")."
         leave
      end
      If SomeSeld = "YES",
       & EEVETDMS /= '*SELECTED*' then iterate ;

      ele  = EEVETKEL /* EOC refactor cleanup use table names instead? */
      env  = EEVETKEN
      stg  = EEVETKSI
      sys  = EEVETKSY
      sub  = EEVETKSB
      typ  = EEVETKTY
      usr  = EEVETUID

      elm#  = elm.0+1
      elm.elm# = ' LIST ELEMENT '

      elm#  = elm#+1
      elm.elm# = '"'ele'"'

      elm#  = elm#+1
      elm.elm# = '   FROM ENVIRONMENT' env ' STAGE ' stg

      elm#  = elm#+1
      If ACTION = 'DEPLOY  ' then ,
         elm.elm# = "      SYSTEM" sys "SUBSYSTEM  '*' " ,
         " TYPE" typ
      Else,
         elm.elm# = "      SYSTEM" sys "SUBSYSTEM " TOSUBSYS ,
         " TYPE" typ
      elm#  = elm#+1
      elm.elm# = '      OPTIONS NOSEARCH '
      elm#  = elm#+1
      elm.elm# = '      TO FILE CSVOUTPT . '
      elm.0 = elm#

      If ACTION = 'DEPLOY  ' then ,
         Do
         Queue "TRANSFER ELEMENT"
         Queue '"'ele'"'
         Queue "       FROM ENVIRONMENT" env
         Queue "            SYSTEM" sys "SUBSYSTEM" sub
         Queue "            TYPE" typ "STAGE" stg
         Queue "       TO   ENVIRONMENT" env
         Queue "            SYSTEM" sys "SUBSYSTEM" TOSUBSYS
         Queue "            TYPE" typ "STAGE" stg
         Queue "       OPTIONS BYPASS ELEMENT DELETE .    "
     /*  Queue "               SIGNOUT TO " USERID() "." */
     /*  Queue "               SIGNOUT TO " usr      "." */
         End; /* If ACTION = 'DEPLOY  ' */
   End; /* Do cnt = 1 to PickRows    */

   ADDRESS TSO,
      "EXECIO * DISKW ELMTABLE ( Stem elm. FINIS " ;
   ADDRESS TSO "FREE F(ELMTABLE)"

  /* EOC - I think ELMTABL should live on for batch job to complete
     Bypass delete - review and refactor cleanup
   CALL OUTTRAP "out."
     ADDRESS TSO "DELETE '"ELMTABLE"'"
   CALL OUTTRAP "OFF"
 */

   /* eoc - the following line disables CLEANUP and REPORT functions */
   If ACTION /= 'DEPLOY  ' then Return

   ADDRESS TSO,
      "EXECIO" QUEUED() "DISKW PKGESCL  (FINIS " ;

   ADDRESS TSO,
      "ALLOC F(C1MSGS1)",
          "LRECL(133) BLKSIZE(26600) SPACE(5,5)",
          "RECFM(F B) TRACKS ",
          "NEW UNCATALOG REUSE "     ;

   ADDRESS TSO,
      "ALLOC F(ENPSCLIN)",
          "LRECL(80) BLKSIZE(800) SPACE(5,5)",
          "RECFM(F B) TRACKS ",
          "NEW UNCATALOG REUSE "     ;

   QUEUE " DEFINE PACKAGE '"PACKAGE"'"
   QUEUE "        IMPORT SCL FROM DDNAME 'PKGESCL'"
   QUEUE "  DESCRIPTION '"DESCRIPT"'"
/* QUEUE "        OPTIONS STANDARD  SHARABLE BACKOUT NOT ENABLED ." */
   QUEUE "        OPTIONS STANDARD  SHARABLE BACKOUT     ENABLED ."
   ADDRESS TSO,
      "EXECIO" QUEUED() "DISKW ENPSCLIN (FINIS " ;

   ADDRESS LINK "ENBP1000" ;
   IF RC > 4 THEN,
      Do
      Say "Could not build the package "PACKAGE
      ADDRESS ISPEXEC "LMINIT DATAID(DDID) DDNAME(C1MSGS1)"
      ADDRESS ISPEXEC "VIEW DATAID(&DDID)"
      ADDRESS ISPEXEC "LMFREE DATAID(&DDID)"
      EXIT(8)
      End

   ADDRESS TSO "FREE  F(C1MSGS1)"
   ADDRESS TSO "FREE  F(PKGESCL)"
   ADDRESS TSO "FREE  F(ENPSCLIN)"

   ADDRESS ISPEXEC "SETMSG MSG(ENXM017I)" ;

   return;

CAST_Package:

  ADDRESS ISPEXEC "SETMSG MSG(ENXM018I)" ;

  SclDsn = XFERDsPrefix".TEMPSCL."SUBSTR(PKGUNIQ,1,8)

  ADDRESS TSO,
  "ALLOC F(CASTSCL) DA('"SclDsn"')",
         "LRECL(80) BLKSIZE(800) SPACE(5,5)",
         "RECFM(F B) TRACKS ",
         "NEW CATALOG REUSE "     ;

  pkg = Overlay('*',PACKAGE,Length(PACKAGE))
  If VALIDATE = "N" then,
     Do
     QUEUE " CAST PACKAGE '"PACKAGE"'  "
     QUEUE "    OPTION DO NOT VALIDATE COMPONENT ."
     If EXECUTE = "Y" then,
        Do
        QUEUE " EXECUTE PACKAGE '"pkg"'  "
        QUEUE "    OPTIONS WHERE PACKAGE STATUS IS APPROVED    . "
        End
     End
  Else,
     Do
     QUEUE " CAST PACKAGE '"PACKAGE"' ."
     If EXECUTE = "Y" then,
        Do
        QUEUE " EXECUTE PACKAGE '"pkg"'  "
        QUEUE "    OPTIONS WHERE PACKAGE STATUS IS APPROVED    . "
        End
     End

  ADDRESS TSO,
     "EXECIO" QUEUED() "DISKW CASTSCL (FINIS " ;
  ADDRESS TSO "FREE  F(CASTSCL)"

  return;

Submit_JCL:

  PDVINCJC = "Y" /* EOC - using override JCL to add extra stuff... */
                 /*       It'd be much safer to use a regular      */
                 /*       skeleton                                 */

  PDVDD01  = "//*"
  If ACTION = 'DEPLOY  ' then,
     If CASTPKGE = "Y" then,
        Do
        PDVSCLDS = SclDsn ;
        PDVDD01  = "//DELETEME DD DISP=(OLD,DELETE),"
        PDVDD02  = "//         DSN="SclDsn
        End;
     Else, /* dont execute any JCL */
        return ;

  If ZSYSPROC = 'IKJACCTT' then,
     Do
     STEPLIB1= "CFDS.ENDEVOR.SANDBOX.USERTEST"
     PDVDD03="//STEPLIB DD DISP=SHR,DSN=CFDS.ENDEVOR.SANDBOX.USERTEST"
     PDVDD04="//#IMAGE  DD * "
     PDVDD05="  IKJACCTT  "
     PDVDD06="//**  Test Image Endevor *** "
     If Count > 25 then,
        PDVDD07="//*EN$CAP05 DD SYSOUT=* <- CAP on or off"
     End
  If ZSYSPROC = 'IKJACCNT' then,
     Do
     STEPLIB1="SYS1.ENDEVOR.USER"
     PDVDD03="//**  Prod Image Endevor *** "
     PDVDD04="//STEPLIB DD DISP=SHR,DSN=SYS1.ENDEVOR.USER"
     If Count > 25 then,
        PDVDD05="//*EN$CAP05 DD SYSOUT=* <- CAP on or off"
     End

   ADDRESS ISPEXEC "FTOPEN TEMP"
   ADDRESS ISPEXEC "FTINCL ENXSJCL "
   ADDRESS ISPEXEC "FTCLOSE "

   ADDRESS ISPEXEC "VGET (ZTEMPF ZTEMPN) ASIS" ;
   DEBUG = 'YES' ;
   DEBUG = 'NAW' ;
   X = OUTTRAP("OFF")
   IF DEBUG = 'YES' THEN,
      DO
      ADDRESS ISPEXEC "LMINIT DATAID(DDID) DDNAME(&ZTEMPN)"
      ADDRESS ISPEXEC "EDIT DATAID(&DDID)"
      ADDRESS ISPEXEC "LMFREE DATAID(&DDID)"
      END;
   ELSE,
      DO
      ADDRESS TSO "SUBMIT '"ZTEMPF"'" ;
      END;

   return;

Select_All:

      SomeSeld = "YES"
      ADDRESS ISPEXEC "TBTOP   "PickLstTable ;
      Do forever
         ADDRESS ISPEXEC "TBSKIP  "PickLstTable
         if rc > 0 then leave
         EEVETSEL = ' '
         If EEVETDMS /= '*SELECTED*' then countsel = countsel + 1 ;
         EEVETDMS = '*SELECTED*'
         ADDRESS ISPEXEC "TBPUT" PickLstTable  ;
      End;

      /* re-position table */
      ADDRESS ISPEXEC "TBTOP   "PickLstTable ;
      ADDRESS ISPEXEC "TBSKIP  "PickLstTable" NUMBER("THISTOPR")"

   Return;

Toggle_Screen:

   IF LONGPANL  == "ENXPSELS" THEN LONGPANL = "ENXPSEL2"
   ELSE LONGPANL = "ENXPSELS"

   Return;

Check_For_Package_Execution:

   ADDRESS ISPEXEC,
      "VGET (ZSCREEN ZSCREENC ZSCREENI) SHARED"

   position = zscreenc;
   Do forever
      If position < 2 then exit(8)
      If substr(zscreeni,(position-1),1) < '$' then leave;
      position = position - 1;
   End ;

   pkg       = Strip(substr(zscreeni,position,16)) ;
   SA= "Package =" pkg
   INPPKGE   = pkg

   Return

Process_Package_XFER:


  SA= "GETTING CURRENT LOCATIONS FROM ENDEVOR" ;
  ADDRESS TSO "ALLOC FI(C1MSGS1)  DUMMY SHR REUSE"
  ADDRESS TSO;

  "ALLOC FI(C1MSGS1) DUMMY SHR REUSE"
  "ALLOC FI(C1MSGS2) DUMMY SHR REUSE"
/*'ALLOC F(BSTERR)   DUMMY SHR REUSE '*/
/*'ALLOC F(BSTAPI)   DUMMY SHR REUSE '   */

  'ALLOC F(APILIST) LRECL(2048) BLKSIZE(22800) SPACE(5,5) ',
    'RECFM(V B) TRACKS NEW UNCATALOG REUSE ' ;

  'ALLOC F(APIMSGS) LRECL(133) BLKSIZE(13300) SPACE(5,5) ',
    'RECFM(F B) TRACKS NEW UNCATALOG REUSE ' ;

  ADDRESS LINKMVS 'APIALPKG' INPPKGE ;  /*  Get pkg header */
  ADDRESS TSO "EXECIO * DISKR APILIST (STEM pkghdr. finis"
  InpPackageStatus = Substr(pkghdr.1,116,12) ;
  InpPackageDescription = Substr(pkghdr.1,30,50) ;

  'ALLOC F(APILIST) LRECL(2048) BLKSIZE(22800) SPACE(5,5) ',
    'RECFM(V B) TRACKS NEW UNCATALOG REUSE ' ;
  ADDRESS LINKMVS 'APIALSUM' INPPKGE ;  /*  Get pkg Actions*/

  ADDRESS TSO "EXECIO * DISKR APILIST (STEM pkglst. finis"
  IF pkglst.0 = 0 then,
     Do
     Say 'Package' INPPKGE ' is not-found or not-CAST '
     Exit (8)
     End;

  ADDRESS ISPEXEC "VGET (ZSCREEN) SHARED"
  PickLstTable = "EN"ZSCREEN"PKLST"; /*  Use Pick List table  */

  ADDRESS ISPEXEC,
    "TBCREATE" PickLstTable,
    'NAMES(EEVETSEL EEVETKEL EEVETDMS EEVETKTY EEVETKEN EEVETKSI ',
          ' EEVETKSY EEVETKSB EEVETDVL EEVETUID) NOWRITE ' ;
/*  "names"varlist" keys"keylist" WRITE" */
/*  If we're processing a package we don't have a table to copy    */
/*  use minimum set of hard coded names...                         */
/*                                                                 */
/*  EOC if coming from a package we might not have access to       */
/*  all the extra details like ccid/comment/endevor RC/Proc RC     */
/*  etc. So maybe we need to do additional API queries for these   */
/*  ...which might be required anyway to ensure that old package   */
/*  contents are still valid.                                      */
/*                                                                 */
  plc = 191 ;  /* Assume Source fields */
  If STRIP(InpPackageStatus) = 'EXECUTED'  then  plc = 304 ;
  If STRIP(InpPackageStatus) = 'COMMITTED' then  plc = 304 ;
  If Substr(InpPackageDescription,47,4) = 'XFER' then plc = 191;
  Do ROWNUM = 1 to pkglst.0

     Elm_offset = C2D(ALSUM_RS_SELMOFF,2) + 1
     Elm_len = C2D(Substr(action,Elm_offset,02))
     EEVETKEL= Strip(Substr(action,Elm_offset+2,Elm_len))

/*   EEVETKEL = Substr(pkglst.ROWNUM,415,8) ; */
     EEVETKEN = Substr(pkglst.ROWNUM,plc,8) ;
     EEVETKSY = Substr(pkglst.ROWNUM,(plc+8),8) ;
     EEVETKSB = Substr(pkglst.ROWNUM,(plc+16),8) ;
     EEVETKTY = Substr(pkglst.ROWNUM,(plc+26),8) ;
     EEVETKSI = Substr(pkglst.ROWNUM,(plc+43),1) ;
     EEVETSEL = ' '
     EEVETDMS = ' '
     ADDRESS ISPEXEC "TBADD" PickLstTable
  End; /*  Do ROWNUM = 1 to pkglst.0 */
  COUNT = pkglst.0

  Call Get_Subsystem_List ;    /* Use API to list target subs */

  ADDRESS ISPEXEC "TBSORT" PickLstTable,
          "FIELDS(EEVETKEL,C,A) ";
  SA= 'COMPLETED TBSORT  ' ;
  ADDRESS ISPEXEC "TBTOP" PickLstTable       ;

  Call First_Time_Preparations ;

  Return ;


/* REXX */

  PARSE ARG waty FUNC

/* Set the correct procesor group */
  db2 = 'DQA0'

  ADDRESS ISPEXEC
  /*                                                  */
  /* GET ISPF VARIABLES                               */
  /*                                                  */

  "VGET (ZPREFIX)"             /* TSO PREFIX          */
  "VGET (ZSCREEN)"             /* ISPF SCREEN NUMBER  */
  "VGET (ZUSER)"               /* TSO USERID          */
  VAREVNME = 'UNIT'            /* ENDEVOR ENVIRONMENT */
  "VGET (CTLNBR)"              /* CCID                */
  "VGET (SBS)"                 /* ENDEVOR SUBSYSTEM   */
  sy = substr(sbs,1,2)         /* Endevor system      */
  "VGET (VNBRPRO)"             /* REQUEST DSN PROJECT */
  "VGET (VNBRGRP)"             /* REQUEST DSN GROUP   */
  "VGET (VNBRTYP)"             /* REQUEST DSN TYPE    */
  "VGET (VNBRMBR)"             /* REQUEST MEMBER      */
  "VGET (C1BJC1)"              /* JOBCARD 1           */
  "VGET (C1BJC2)"              /* JOBCARD 2           */
  "VGET (C1BJC3)"              /* JOBCARD 3           */
  "VGET (C1BJC4)"              /* JOBCARD 4           */


  sclcount = 0
  /*                                                    */
  /* DSN OF WALKER UNLOAD PDS                           */
  unloadlb = zprefix"."zuser".NDVTEMP."waty
  /* set stream                                         */
  stream = right(sbs,1)
  /*                                                    */
  /* SET DB2 ENVIRON                                    */

/* make sure the job card statements are not blank */
If C1BJC1 = '' then C1BJC1 = '//*'
If C1BJC2 = '' then C1BJC2 = '//*'
If C1BJC3 = '' then C1BJC3 = '//*'
If C1BJC4 = '' then C1BJC4 = '//*'

/*trace i*/
  select
     when sbs = "WA1" & db2 = 'DQA0' then db2env = "DQA0GWABATD1"
     when sbs = "WA2" & db2 = 'DQA0' then db2env = "DQA0GWABATD2"
     when sbs = "WA3" & db2 = 'DQA0' then db2env = "DQA0GWABATD3"
     when sbs = "WA4" & db2 = 'DQA0' then db2env = "DQA0GWABATD4"
   otherwise nop
  end /*end select*/

  ADDRESS TSO

  x = msg(off)
  "FREE  FI(WAREQ"ZSCREEN")"
  "FREE  FI(WAJCL"ZSCREEN")"
  x = msg(on)

  testdsn = "'"VNBRPRO"."VNBRGRP"."VNBRTYP"("VNBRMBR")'"
  x = sysdsn(testdsn)
  if x <> OK THEN DO
    ZEDSMSG = x
    ZEDLMSG = testdsn x

    address ispexec

    'SETMSG MSG(ISRZ001)'
    ADDRESS tso delstack
    EXIT 8
  end /* not ok */

  testdsn = "'TTWA.BASE.LOOKUP("waty")'"
  x = sysdsn(testdsn)
  if x <> OK THEN DO
    ZEDSMSG = x
    ZEDLMSG = testdsn x

    address ispexec

    'SETMSG MSG(ISRZ001)'
    ADDRESS tso delstack
    EXIT 8
  end /* not ok */

  address tso
  /*                                                    */
  /* ALLOCATE WALKER/ENDEVOR NAMES LOOKUP tABLE         */
  "ALLOC FI(WALOOK"ZSCREEN")"  ,
  "DA('"ZPREFIX".BASE.LOOKUP("waty")') SHR REUSE"

  /*                                                             */
  /* ALLOCATE REQUEST DATASET FOR LIST OF WALKER ELEMENTS TO ADD */

  address tso

  "ALLOC FI(WAREQ"ZSCREEN")" ,
  "DA('"VNBRPRO"."VNBRGRP"."VNBRTYP"("VNBRMBR")')"

  /*                                                             */
  /* ALLOCATE DATASET TO CONTAIN GENERATED JCL                   */
  "ALLOC FI(WAJCL"ZSCREEN")" ,
        "SPACE(1 1) TRACK LRECL(80) NEW REUSE"

  /*                                                             */
  /* READ LOOKUP TABLE AND LIST OF WALKER ELEMENTS TO DELETE     */
  "EXECIO * DISKR WALOOK"ZSCREEN "(STEM WALOOK. FINIS"
  "EXECIO * DISKR WAREQ"ZSCREEN  "(STEM WAREQ. FINIS"

  /*                                                             */
  /* STACK UP FIRST PART OF THE JCL                              */
  "NEWSTACK"
  /*                                                             */
  /* STACK UP JOBCARD                                            */
  queue C1BJC1
  queue C1BJC2
  queue C1BJC3
  queue C1BJC4
  /*                                                             */
  /* STEP TO DELETE PREVIOUS UNLOAD PDS FOR THIS TYPE            */
  queue"//DEL"waty "EXEC PGM=IDCAMS"
  queue"//*"
  queue"//* DELETE PDS FROM LAST RUN"
  queue"//*"
  queue"//SYSPRINT DD SYSOUT=Z"
  queue"//SYSIN    DD *"
  queue" DELETE "unloadlb" NVSAM"
  queue" SET MAXCC = 0  "
  queue"//*"
  /*                                                             */
  /* ALLOCATE NEW UNLOAD PDS FOR THIS TYPE                       */
  queue"//ALOC"waty "EXEC PGM=IEFBR14"
  queue"//*"
  queue"//* ALLOCATE PDS TO CONTAIN UNLOADED WALKER ELEMENTS"
  queue"//*"
  queue"//ALOC"waty  "DD DISP=(NEW,CATLG),DSN="unloadlb","
  queue"//   SPACE=(CYL,(1,15,45)),"
  queue"//   DCB=(RECFM=VB,LRECL=4100,BLKSIZE=31744)"
  queue"//*"

  /*                                                             */
  /* LOOP THROUGH LIST OF WALKER ELEMENTS TO ADD                 */
  /*                                                             */
  DO i = 1 to wareq.0

    /* loop through walker requests */
    /* ignore comments              */
    if substr(wareq.i,1,5) <> 'pants' then do

      reqwalk = word(wareq.i,1)
      /* loop through look up table   */
      matches = 0

      do l = 1 to walook.0

        /* save matches                                 */
        loowalk = word(walook.l,1)
        /*                                               */
        /* Save Endevor ele name for this walker element */
        if reqwalk == loowalk then do
           looende = word(walook.l,2)
           matches = matches + 1
        end /* match */

      end /*  loop through lookup */

      ADDRESS ISPEXEC

      select

      /*                                              */
      /* IF NO MATCH THEN ISSUE MESSAGE AND STOP      */
      when matches = 0 then do
         ADDRESS tso delstack
         zedsmsg = reqwalk 'not found'
         zedlmsg = reqwalk 'not found in lookup'
         'SETMSG MSG(ISRZ001)'
         Exit 8
      end /* matches = 0 */

      /*                                                    */
      /* IF > 1 MATCH IN LOOKUP THEN ISSUE MESSAGE AND STOP */
      when matches > 1 then do
         zedsmsg = 'Duplicates'
         zedlmsg = reqwalk 'duplicate in lookup'
         'SETMSG MSG(ISRZ001)'
         ADDRESS tso delstack
         Exit 8
      end /* matches > 0 */

      /*                                                      */
      /* IF 1 MATCH IN LOOKUP STACK A WALKER UNLOAD STEP      */
      otherwise do
         queue"//*"
         queue"//** IOBKRSTR - EXTRACT" Waty "FROM WALKER DB2"
         queue"//*"
         queue"//"looende "EXEC PGM=WBSSBKR,DYNAMNBR=20,REGION=4096K"
      /* if sbs = "WA2" then
           queue"//STEPLIB  DD DISP=SHR,DSN=SYSDB2."db2".SDSNEXIT.DECP"
           queue"//         DD DISP=SHR,DSN=SYSDB2."db2".SDSNLOAD"
           queue"//         DD DISP=SHR,DSN=TTWA.E2.LOAD"
         else do   */
           queue"//STEPLIB  DD DISP=SHR,DSN=SYSDB2."db2".SDSNEXIT.DECP"
           queue"//         DD DISP=SHR,DSN=SYSDB2."db2".SDSNLOAD"
           queue"//         DD DISP=SHR,DSN=PREV.RWA1.LOAD"
           queue"//         DD DISP=SHR,DSN=PREV.AWA"stream".LOAD"
           queue"//         DD DISP=SHR,DSN=PREV.BWA"stream".LOAD"
           queue"//         DD DISP=SHR,DSN=PREV.DWA"stream".LOAD"
           queue"//         DD DISP=SHR,DSN=PREV.FWA"stream".LOAD"
           queue"//         DD DISP=SHR,DSN=PREV.PWA1.LOAD"
           queue"//         DD DISP=SHR,DSN=PGWA.BASE.LOAD"
       /*end*/
         queue"//DB2INPUT DD  *"
         queue db2env
         queue"//SYSIN    DD  *"
         /*                                                      */
         /* IF TYPE ERR THEN CONVERT NUMERIC WALKER ELE TO CHAR  */
         select
           /*                                                      */
           /* FOR THIS TYPE STACK UP THE RELEVANT SYSIN STATEMENTS   */
           when waty = 'ERR' then do
             binnum = d2c(reqwalk,2)
             hexnum = d2x(reqwalk,4)

             queue"OBN      PN ®"
             queue"B**SSERR           "binnum
             queue"B**S1800           "binnum

           end /* ERR */
           when waty = 'COB' then do

             queue"OBN      PN _"
             queue"B**S3200           "REQWALK
             queue"B**S3290           C"REQWALK
             queue"B**S3300           C"REQWALK

           end      /* 'cob' */
           when waty = 'DOC' then do

             queue")TB 20"
             queue"OBN      PN _"
             queue"B**DGS***          GLOSSDOC"REQWALK
             queue"BGLOSSDOC !"REQWALK

           end      /* 'DOC' */
           when waty = 'DOP' then do

             queue"OBN      PN _"
             queue"B**S2000           "REQWALK
             queue"B**S2100           "REQWALK
             queue"B**S2200           "REQWALK
             queue"B**S2300           "REQWALK
             queue"B**S2400           "REQWALK
             queue"B**S2410           "REQWALK
             queue"B**S2420           "REQWALK
             queue"B**S2500           "REQWALK

           end      /* 'DOP' */
           when waty = 'FID' then do

             queue"OBN      PN _"
             queue"BRGSDATAD          "REQWALK
             queue"BRGSDATAR          "REQWALK

           end      /* 'FID' */
           when waty = 'GMT' then do

             queue"OBN      PN _"
             queue"B**GMT***          "REQWALK
             queue"B**S3290           M"REQWALK
             queue"B**S3300           M"REQWALK

           end      /* 'GMT' */
           when waty = 'MVT' then do

             queue"OBN    S P"
             queue"BSCC134            "REQWALK

           end      /* 'MVT' */
           when waty = 'NAM' then do

             queue"OBN      PN _"
             queue"B*IGSNAME          "REQWALK

           end      /* 'NAM' */
           when waty = 'RPT' then do

             queue"OBN      PN _"
             queue"B*RGSHDR*          "REQWALK
             queue"BRGSRUOL           "REQWALK

           end      /* 'RPT' */
           when waty = 'SCR' then do

             queue"OBN      PN _"
             queue"B**HELP**          "REQWALK
             queue"B**S1600           "REQWALK
             queue"B*SCREEN*          "REQWALK
             queue"B*SCRHDR*          "REQWALK

           end      /* 'SCR' */
           when waty = 'SVC' then do

             queue"OBN      PN _"
             queue"B**S3000           "REQWALK
             queue"B**S3100           "REQWALK
             queue"B**S3290           S"REQWALK
             queue"B**S3300           S"REQWALK
             queue"B**S3400           1"REQWALK
             queue"B**S3600           "REQWALK

           end      /* 'SVC' */
           when waty = 'TGS' then do

             queue"OBN      PN _"
             queue"B**S3290           T"REQWALK
             queue"B**S3300           T"REQWALK
             queue"B*TGSHDR           "REQWALK
             queue"B*TGSUOL           "REQWALK

           end      /* 'TGS' */
           when waty = 'TID' then do

             queue"OBN      PN _"
             queue"B**S1200           "REQWALK
             queue"BSCC134            "REQWALK

           end      /* 'TID' */
           when waty = 'VMS' then do

             queue"OBN      PN _"
             queue"B**VMSE**          "REQWALK
             queue"B**VMSR**          "REQWALK

           end      /* 'VMS' */
           otherwise do
              /*                                                   */
              /* IF UNKNOWN TYPE THEN FALL OVER                    */
              say waty 'unknown'
              ADDRESS tso delstack
              exit 12
           end /* otherwise */
         end /* select */
         /*                                                   */
         /* STACK REST OF UNLOAD STEP                         */
         chkstep = OVERLAY('@',looende,3)
         queue"//SYS013   DD  DISP=SHR,DSN="unloadlb"("looende")"
         queue"//SYSTSPRT DD  SYSOUT=*"
         queue"//SYS012   DD  DISP=(,PASS,DELETE),DSN=&&SYS012,"
         queue"//             SPACE=(CYL,(1,5),RLSE),"
         queue"//             RECFM=FBA,LRECL=133,BLKSIZE=0,DSORG=PS"
         queue"//SYSPRINT DD  SYSOUT=*"
         queue"//SYSOUT   DD  SYSOUT=*"
         queue"//*"
         queue"//* CHECK UNLOAD IS SUCCESSFUL"
         queue"//*"
         queue"//"chkstep "EXEC PGM=IKJEFT01,COND=(4,LT),"
         queue"//  PARM=('WAIOBKCK" waty reqwalk"',"
         queue"//        '" unloadlb looende"')"
         queue"//SYSTSPRT DD  SYSOUT=*"
         queue"//SYSEXEC  DD  DSN=PGEV.BASE.REXX,DISP=SHR"
         queue"//SYSTSIN  DD  DUMMY"
         queue"//REPORT   DD  DISP=(OLD,DELETE),DSN=&&SYS012"
         queue"//SYS012   DD  SYSOUT=*"

         /* sort if err to remove duff records */
         if waty = 'ERR' then do
     queue"//STEP020  EXEC PGM=SORT                              "
     queue"//SORTIN   DD DISP=SHR,DSN="unloadlb"("looende")"
     queue"//SORTOUT  DD DISP=SHR,DSN="unloadlb"("looende")"
     queue"//SORTWK01 DD SPACE=(CYL,(15,15)),UNIT=DASD           "
     queue"//SYSOUT   DD SYSOUT=*                                "
     queue"//SYSIN    DD *                                       "
     queue"  SORT FIELDS=COPY                                    "
     queue"  INCLUDE COND=(7,2,BI,EQ,X'"hexnum"',OR,5,2,CH,EQ,C'**')"
     queue"//*                                                   "
         end /*  end of add extra step to sort unloaded errs */

         /* unlock the TGS */
         if waty = 'TGS' then do
           unlstep = 'TGU' || substr(looende,4,5)
           queue"//*"
           queue"//* UNLOCK TGS"
           queue"//*"
           queue"//@100     IF" chkstep".RC = 0 THEN"
           queue"//"unlstep "EXEC PGM=FILEAID,COND=(4,LT)"
           queue"//SYSPRINT DD  SYSOUT=Z"
           queue"//SYSLIST  DD  SYSOUT=*"
           queue"//DD01     DD  DISP=SHR,DSN="unloadlb"("looende")"
           queue"//SYSIN    DD  *"
           queue"$$DD01 UPDATE STOP=(27,EQ,C'*TGSHDR')"
           queue"$$DD01 UPDATE REPL=(73,EQ,C'L',C' '),IN=2,PRINT=0"
           queue"//@100     ENDIF"
           queue"//*"
         end /* if waty = 'TGS' */

         /* SAVE ENDEVOR SCL TO ADD THIS ELEMENT              */
         /*                                                   */
         sclcount = sclcount + 1
         scl.sclcount = ,
         "  ADD ELE" looende
         sclcount = sclcount + 1

         scl.sclcount = ,
         "  FROM DSNAME '"unloadlb"'"
         sclcount = sclcount + 1

         scl.sclcount = ,
         "  TO  ENV "VAREVNME "SYS" sy "SUB" SBS "TYP" WATY
         sclcount = sclcount + 1

         scl.sclcount = ,
         "  OPTIONS  CCID '"ctlnbr"'"
         sclcount = sclcount + 1

         scl.sclcount = ,
         "  COMMENT  '"REQWALK"'"
         sclcount = sclcount + 1

         scl.sclcount = ,
         "  OVERRIDE SIGNOUT UPDATE"
         sclcount = sclcount + 1

         scl.sclcount = ,
         "  ."
      end /* 1 match */
      end /* select */
    end /* not comment */

  END
  address tso
  /*                                                   */
  /* STACK UP ENDEVOR STEP TO ADD ELEMENTS             */
  queue"//ADD"waty" EXEC PGM=NDVRC1,COND=(4,LT),DYNAMNBR=1500,"
  queue"//         PARM='C1BM3000',REGION=4M"
  queue"//*"
  queue"//SORTWK01 DD  UNIT=SYSDA,SPACE=(CYL,(20,10))"
  queue"//SORTWK02 DD  UNIT=SYSDA,SPACE=(CYL,(20,10))"
  queue"//SORTWK03 DD  UNIT=SYSDA,SPACE=(CYL,(20,10))"
  queue"//SORTWK04 DD  UNIT=SYSDA,SPACE=(CYL,(20,10))"
  queue"//C1SORTIO DD  SPACE=(CYL,(50,50)),"
  queue"//             RECFM=VB,LRECL=8296,BLKSIZE=8300"
  queue"//C1MSGS1  DD  SYSOUT=*"
  queue"//C1MSGS2  DD  SYSOUT=*"
  queue"//C1PRINT  DD  SYSOUT=*,"
  queue"//  DCB=(RECFM=FBA,LRECL=121,BLKSIZE=6171)"
  queue"//SYSOUT   DD  SYSOUT=*"
  queue"//SYSPRINT DD  SYSOUT=*"
  queue"//APIPRINT DD  SYSOUT=Z"
  queue"//BSTIPT01 DD  *"

  /*                                                   */
  /* STACK UP SCL STATEMENTS FOR ALL THE ELEMENTS      */
  do Q = 1 to sclcount
    queue scl.Q
  end /* Q = 1 to sclcount */

  /*                                                   */
  /* WRITE THE JCL                                     */
  queue ""
  "execio * diskw WAJCL"ZSCREEN "( finis"

  if func = 'J' then do
  /*                                                   */
  /* EDIT THE JCL                                      */
  address ispexec
  "lminit dataid(WAJCL) ddname(WAJCL"ZSCREEN") enq(shr)"
  "EDIT DATAID("WAJCL") MACRO(WAMACJ)"
  'lmfree dataid('WAJCL')'
  end /* J */
  else do
    ddjcl = "WAJCL"ZSCREEN

    x = listdsi(ddjcl file)
    "SUBMIT '"sysdsname"'"
  end /* S */
  /*                                                   */
  /* FREE                                              */
  ADDRESS TSO

  "FREE FI(WALOOK"ZSCREEN")"
  "FREE FI(WAREQ"ZSCREEN")"
  "FREE FI(WAJCL"ZSCREEN")"
  exit 0

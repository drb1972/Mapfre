/***rexx*********************************************************/      00010005
/** PROGRAM: EVGENPRM                                          **/      00020005
/** Author: Stuart Ashby/Craig Rex                             **/      00030005
/** DATE: Started 12/04/2005                                   **/      00040005
/**                                                            **/      00050005
/** Function: This rexx builds a panel which will allow ADSM   **/      00060005
/** to select the Generol objects to be promoted to ACPT       **/      00070005
/** or build a package in Endevor to ship to production.       **/      00070005
/****************************************************************/      00080005
arg target

top:
                                                                        00090005
trace i                                                                 00100070
y=msg(off)                                                              00110005
uid  = sysvar(sysuid)                                                   00120005
temptab = sysvar(sysuid)                                                00120005
pref = sysvar(syspref)                                                  00120005
sgtchk = 'N'

/* initialise the variable used for the step name when using ftincl */
no = 1                                                                  00130006
                                                                        00130006
/* variable that is set when the job card is included in the skeleton */00130007
  jobcard_true = 0                                                      00140087
                                                                        00140088
if target = 'ACPT' then do
 indsn = 'TTYY.GENEROL.SYST.DATA'
 "ALLOC DD(EVTDSN) DA('"indsn"') SHR"
 inlib1 = 'TTLN.G2.VGENEROL.SGTLIB1'
 inlib2 = 'TTLN.G2.VGENEROL.SGTLIB2'
 outlib1 = 'TTLN.G3.VGENEROL.SGTLIB1'
 outlib2 = 'TTLN.G3.VGENEROL.SGTLIB2'
 end

if target = 'PROD' then do
 indsn = 'TTYY.GENEROL.ACPT.DATA'
 "ALLOC DD(EVTDSN) DA('"indsn"') SHR"
  end

"DELETE '"pref"."UID".TEMP1.ISPTLIB'"
"DELETE '"pref"."UID".TEMP1.ISPTABL'"
"ALLOC DA('"pref"."UID".TEMP1.ISPTLIB') LIKE('PREV.OEV1.ISPTLIB')"
"ALLOC DA('"pref"."UID".TEMP1.ISPTABL') LIKE('PREV.OEV1.ISPTABL')"
"ISPEXEC LIBDEF ISPTABL DATASET,
      ID('"pref"."UID".TEMP1.ISPTABL')"
"ISPEXEC LIBDEF ISPTLIB DATASET,
      ID('"pref"."UID".TEMP1.ISPTLIB')"

panel:                                                                  00150005
                                                                        00160005
zcmd = ''                                                               00180005
address ispexec                                                         00190005
    "DISPLAY PANEL(EVGENPRM)"                                           00200007
                                                                        00210006
 /* If rc 8 then PF3 was pressed */                                     00220006
                                                                        00230006
 if rc = 8 then do                                                      00240006
   address tso
   "FREE DD(EVTDSN)"                                                    02403094
   "ISPEXEC LIBDEF ISPTLIB"
   "ISPEXEC LIBDEF ISPTABL"
   "DELETE '"pref"."UID".TEMP1.ISPTLIB'"
   "DELETE '"pref"."UID".TEMP1.ISPTABL'"
    exit
 end /* end do */
 else "VPUT (CHGNO TARGET C1SUB) PROFILE"                               00270010
                                                                        00280005
if zcmd = 'DONE' then signal submit                                     00290055

/* set initialise variables */                                          00340083
  n1 = 1                                                                00350015
  n2 = 1                                                                00350015
  n3 = 1                                                                00350015
  n4 = 1                                                                00350015
                                                                        00352083
/* Allocate master migration file for t the list of objects in */       00750061
address tso                                                             00550012
  "ALLOC DD(INFILE) DA('"indsn"') SHR"                                  00560024
  "EXECIO * DISKR INFILE (STEM MLIST. FINIS)"                           00570000

/* If CMR field isn't left blank then produce a subset of objects */    00750061
/* based on the CMR number */                                           00750061

   if chgno ^= '' then do
    do until n1 > mlist.0
    parse var mlist.n1 SGTLIB CMRNO ADT SUBLIB CMPNAM CMPTYP CHGTYP     00009600
    if cmrno = chgno then do
       sublist.n2 = mlist.n1
       n2 = n2 + 1
       n1 = n1 + 1
       end
    else do
    n1 = n1 + 1
    end
   end
  end                                                                   00580061
/* Create a temporary ISPF table to put the list of objects in */       00750061
"ISPEXEC TBCREATE "TEMPTAB",                                            00760061
 NAMES(W CMPNAM CMPTYP SUBLIB SGTLIB ADT CMRNO) WRITE"                  00760061

/* If CMR field is blank then process the whole file*/                  00750061
  if chgno = '' then do                                                 00770008
  n1 = 1
   do until n1 > mlist.0                                                00780000
    parse var mlist.n1 SGTLIB CMRNO ADT SUBLIB CMPNAM CMPTYP CHGTYP     00009600
    cmpnam = strip(cmpnam)                                              00800015
    cmptyp = strip(cmptyp)                                              00800015
    sublib = strip(sublib)                                              00800015
    sgtlib = strip(sgtlib)                                              00800015
    adt = strip(adt)                                                    00800015
    cmrno  = strip(cmrno)                                               00800015
    w = ' '                                                             00820027
                                                                        00860008
/* Add the data to a row in the table and increment the counter */      00870008
 "ISPEXEC TBADD " temptab                                               00880008
    n1 = n1 + 1                                                         00940000
   end                                                                  00950009
  end
  else do
/* If CMR field contains a number then process the subset */            00750061
   n4 = n2
   n2 = 1
   do until n3 >= n4                                                    00780000
    parse var sublist.n2 SGTLIB CMRNO ADT SUBLIB CMPNAM CMPTYP CHGTYP   00009600
    cmpnam = strip(cmpnam)                                              00800015
    cmptyp = strip(cmptyp)                                              00800015
    sublib = strip(sublib)                                              00800015
    sgtlib = strip(sgtlib)                                              00800015
    adt = strip(adt)                                                    00800015
    cmrno  = strip(cmrno)                                               00800015
    w = ' '                                                             00820027
/* Add the data to a row in the table and increment the counter */      00870008
 "ISPEXEC TBADD " temptab                                               00880008
    n2 = n2 + 1                                                         00940000
    n3 = n3 + 1                                                         00940000
  end /* end do */                                                      00950009
 end                                                                    00960008

/* Set the panel return code to zero */                                 00970008
"ISPEXEC TBTOP " temptab                                                00980008
prc = 0                                                                 00990008
cursor = 'CURSOR( )'                                                    01000008
csrrow = 'CSRROW(1)'                                                    01010008
message = 'MSG( )'                                                      01020008
                                                                        01030008
/* Do whilst the selection panel does not have PF3 entered       */     01040008
     do while prc ^= 8                                                  01050008
                                                                        01060008
     "ISPEXEC TBDISPL "temptab" PANEL(EVGENSEL)" message cursor csrrow ,01070008
        "AUTOSEL(NO) POSITION(CRP)"                                     01080008
                                                                        01090008
/* save the panel return code & get the line command in upper case */   01100008
        prc = rc                                                        01110008
        upper zcmd                                                      01120008
        upper y                                                         01130008
        cursor = 'CURSOR( )'                                            01140008
        csrrow = 'CSRROW(1)'                                            01150008
                                                                        01160008
 select                                                                 01170008
    when substr(zcmd,1,1) = 'L' then do
      parse var zcmd loc findit
      "ISPEXEC TBVCLEAR "temptab
       member = findit
        "ISPEXEC TBTOP "temptab
          "ISPEXEC TBSARG "temptab" NEXT NAMECOND(CMPNAM,EQ)"
            "ISPEXEC TBSCAN "TEMPTAB" POSITION(CRP)"
              if rc > 0 then  message = 'MSG(EVGE105E)'
                        else do
                               csrrow = 'CSRROW('CRP')'
                               cursor = 'CURSOR(Y)'
                               message = 'MSG( )'
                             end /* end else do */
                                     end /* end when do */
    when zcmd = 'S *' then do

/* set pointer to the top of the table */
 "ISPEXEC TBTOP "temptab

/* get the number of rows */
 "ISPEXEC TBQUERY "temptab" ROWNUM(QROWS) POSITION(CRP)"

 do i = 1 to qrows
/* From the top use TBSKIP to get next row */
                "ISPEXEC TBSKIP "temptab

/* Use TBGET to load table row, change w to be selected and put record
   the record back updated */
                "ISPEXEC TBGET "temptab
                 w = '*selected'
                  "ISPEXEC TBPUT "temptab

 end /* end do i = 1 to qrows */

    "ISPEXEC TBTOP "temptab
    "ISPEXEC TBSKIP "temptab "NUMBER("ztdtop")"
    message = 'MSG(EVGE104I)'
    end /* end when do */

 when zcmd = 'DONE' & target = 'ACPT' then do                           01830008
   "ISPEXEC FTOPEN TEMP"                                                01473087
   "ISPEXEC FTINCL EVGENMG1"                                            01476087
                                                                        01476187
/* set pointer to the top of the table */                               01571075
   "ISPEXEC TBTOP "TEMPTAB                                              01572075
                                                                        01573075
/* get the number of rows */                                            01574075
 "ISPEXEC TBQUERY "TEMPTAB" ROWNUM(QROWS) POSITION(CRP)"                01575075
 "ISPEXEC TBSKIP "TEMPTAB                                               01579075
 "ISPEXEC TBGET "TEMPTAB                                                01579475
  sgtnam = "SGTLIB" || sgtlib
 "ISPEXEC FTINCL EVGENMG3"                                              01476087
 "ISPEXEC FTINCL EVGENMG0"                                              01476087

 do j = 1 to qrows                                                      01577075
                                                                        01579175
/* Use TBGET to load table row, change w to be selected and put record  01579275
   the record back updated */                                           01579375
 "ISPEXEC TBGET "TEMPTAB                                                01579475

  if w = '*selected' then do                                            01579575

     select
      when cmptyp = 'P' then gentyp = 'PROGRAM'
      when cmptyp = 'W' then gentyp = 'WORK   '
      when cmptyp = 'M' then gentyp = 'MAP    '
      when cmptyp = 'R' then gentyp = 'RECORD '
      when cmptyp = 'F' then gentyp = 'FILE   '
      otherwise nop
     end

     sgtnam = "SGTLIB" || sgtlib

     if sgtnam = 'SGTLIB1' then do
        fromlib = 'FROMLIB1'
        tolib = 'TOLIB1'
     end

     if sgtnam = 'SGTLIB2' & sgtchk = 'N' then do
        "ISPEXEC TBSKIP " TEMPTAB "NUMBER(-1)"
        prevsgt = sgtlib
          if prevsgt = 1 then do
            sgtchk = 'Y'
            fromlib = 'FROMLIB2'
            tolib = 'TOLIB2'
           "ISPEXEC TBSKIP " TEMPTAB "NUMBER(1)"
            sgtnam = 'SGTLIB2'                                          00800015
           "ISPEXEC FTINCL EVGENMG3"                                    01579675
           "ISPEXEC FTINCL EVGENMG0"                                    01579675
          end
          else do
           fromlib = 'FROMLIB2'
           tolib = 'TOLIB2'
          end
     end
     "ISPEXEC FTINCL EVGENMG2"                                          01579675

     select
       when  sublib = 'RESIDENT' then do
        sublib = 'NONRES'
        "ISPEXEC FTINCL EVGENMG2"
       end

       when  sublib = 'NONRES'  then do
        sublib = 'RESIDENT'
        "ISPEXEC FTINCL EVGENMG2"
       end
       otherwise
      end

   end                                                                  01580182
/* From the top use TBSKIP to get next row */                           01578075
 "ISPEXEC TBSKIP "TEMPTAB                                               01579075
 end /* end do j = 1 to qrows */                                        01580575
                                                                        01580775
 "ISPEXEC TBCLOSE "TEMPTAB                                              01582081
 "ISPEXEC TBERASE "TEMPTAB                                              01583081
  memnam = adt || substr(chgno,3,6)
 "ISPEXEC FTINCL EVGENMG5"                                              01584085
 call submit
 end /* end select do */                                                01610030
                                                                        01620030
 when zcmd = 'DONE' & target = 'PROD' then do                           01830008
   "ISPEXEC FTOPEN TEMP"                                                01473087
                                                                        01476187
/* set pointer to the top of the table */                               01571075
   "ISPEXEC TBTOP "TEMPTAB                                              01572075
                                                                        01573075
/* get the number of rows */                                            01574075
 "ISPEXEC TBQUERY "TEMPTAB" ROWNUM(QROWS) POSITION(CRP)"                01575075
 "ISPEXEC TBSKIP "TEMPTAB                                               01579075
 "ISPEXEC TBGET "TEMPTAB                                                01579475
  sgtnam = "SGTLIB" || sgtlib
 "ISPEXEC FTINCL EVGENMG1"                                              01476087
 "ISPEXEC FTINCL EVGENMG6"                                              01476087
 "ISPEXEC FTINCL EVGENMG0"                                              01476087

 do j = 1 to qrows                                                      01577075
                                                                        01579175
/* Use TBGET to load table row, change w to be selected and put record  01579275
   the record back updated */                                           01579375
 "ISPEXEC TBGET "TEMPTAB                                                01579475

  if w = '*selected' then do                                            01579575

     select
      when cmptyp = 'P' then gentyp = 'PROGRAM'
      when cmptyp = 'W' then gentyp = 'WORK   '
      when cmptyp = 'M' then gentyp = 'MAP    '
      when cmptyp = 'R' then gentyp = 'RECORD '
      when cmptyp = 'F' then gentyp = 'FILE   '
      otherwise nop
     end

     sgtnam = "SGTLIB" || sgtlib

     if sgtnam = 'SGTLIB1' then do
        fromlib = 'FROMLIB1'
        tolib = 'TOLIB1'
     end

     if sgtnam = 'SGTLIB2' & sgtchk = 'N' then do
        "ISPEXEC TBSKIP " TEMPTAB "NUMBER(-1)"
        prevsgt = sgtlib
          if prevsgt = 1 then do
            sgtchk = 'Y'
            fromlib = 'FROMLIB2'
            tolib = 'TOLIB2'
           "ISPEXEC FTINCL EVGENMG7"                                    01579675
           "ISPEXEC TBSKIP " TEMPTAB "NUMBER(1)"
            sgtnam = 'SGTLIB2'                                          00800015
           "ISPEXEC FTINCL EVGENMG6"                                    01579675
           "ISPEXEC FTINCL EVGENMG0"                                    01579675
          end
          else do
           fromlib = 'FROMLIB2'
           tolib = 'TOLIB2'
          end
     end

     select
      when sublib = 'ACCESSCR' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'ACCOUNT' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'ALARM' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'BUTTONS' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'CREDCLMS' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'CUSTCON' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'DB2' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'FS' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'HOUSE' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'IMAGE' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'LOANCLMS' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'MAXI' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'MIS' then do
       subbck = 'HOLDMIS'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'MOTOR' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'NCMCL' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'NONRES' then do
       subbck = 'HOLDNON'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'NSMCL' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'NSMOT' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'NSNONRES' then do
       subbck = 'HOLDNON'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'NSRES' then do
       subbck = 'HOLDRES'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'PET' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'RESIDENT' then do
       subbck = 'HOLDRES'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'SPR' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'TABLES' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      when sublib = 'TRAVEL' then do
       subbck = 'HOLD'
      "ISPEXEC FTINCL EVGENMG8"                                         01579675
      end
      otherwise nop
      end


     "ISPEXEC FTINCL EVGENMG2"                                          01579675

     select
       when  sublib = 'RESIDENT' then do
        sublib = 'NONRES'
        subbck = 'HOLDNON'
        "ISPEXEC FTINCL EVGENMG8"
        "ISPEXEC FTINCL EVGENMG2"
       end

       when  sublib = 'NONRES'  then do
        sublib = 'RESIDENT'
        subbck = 'HOLDRES'
        "ISPEXEC FTINCL EVGENMG8"
        "ISPEXEC FTINCL EVGENMG2"
       end
       otherwise
      end

   end                                                                  01580182
/* From the top use TBSKIP to get next row */                           01578075
 "ISPEXEC TBSKIP "TEMPTAB                                               01579075
 end /* end do j = 1 to qrows */                                        01580575
                                                                        01580775
 "ISPEXEC TBCLOSE "TEMPTAB                                              01582081
 "ISPEXEC TBERASE "TEMPTAB                                              01583081
  memnam = adt || substr(chgno,3,6)
 "ISPEXEC FTINCL EVGENMG7"                                              01584085
 call submit
 end /* end select do */                                                01610030
 otherwise                                                              01760008
 end /* end select */                                                   01770008
                                                                        01780008
/* loop while there are selected rows */                                01790008
    do while ZTDSELS > 0                                                01800008
                                                                        01810008
 select                                                                 01820008
 when zcmd = 'BACK' then do                                             01830008
                                "ISPEXEC TBCLOSE "temptab               01840008
                                "ISPEXEC TBERASE "temptab               01850008
                                 signal panel                           01860008
                              end /* end do */                          01870008
                                                                        01880008
 when zcmd = 'S *' then do

/* set pointer to the top of the table */
 "ISPEXEC TBTOP "temptab

/* get the number of rows */
 "ISPEXEC TBQUERY "temptab" ROWNUM(QROWS) POSITION(CRP)"

  do i = 1 to qrows
/* From the top use TBSKIP to get next row */
                "ISPEXEC TBSKIP "temptab

/* Use TBGET to load table row, change w to be selected and put record
   the record back updated */
                "ISPEXEC TBGET "temptab
                 w = '*selected'
                  "ISPEXEC TBPUT "temptab

  end /* end do i = 1 to qrows */

    "ISPEXEC TBTOP "temptab
    "ISPEXEC TBSKIP "temptab "NUMBER("ztdtop")"
    message = 'MSG(CMTB104I)'
 end /* end when do */




 otherwise nop                                                          01890008
 end /* end select */                                                   01900008
                                                                        01910008
/* When a line command is issued, update the table */                   01920008
 select                                                                 01930008
    when y = 'S' then do                                                01940008
                                                                        01960028
                       w = '*selected'                                  01970008
                        "ISPEXEC TBPUT "TEMPTAB                         01980013
                         csrrow = 'CSRROW('CRP')'                       01990008
                         cursor = 'CURSOR(Y)'                           02000008
                         message = 'MSG(EVGE102I)'                      02010008
                      end /* end do for SELECT = S */                   02020008
    when y = 'X' then do                                                02030008
                       w = '         '                                  02050008
                        "ISPEXEC TBPUT "TEMPTAB                         02060013
                         csrrow = 'CSRROW('CRP')'                       02070008
                         cursor = 'CURSOR(Y)'                           02080008
                         message = 'MSG(EVGE103I)'                      02090008
                      end /* end do for SELECT = S */                   02100008
 otherwise do                                                           02110008
            cursor = 'CURSOR(Y)'                                        02120008
           end /* end do */                                             02130008
                                                                        02140008
 end /* end select */                                                   02150008
                                                                        02160008
  if ztdsels > 1 then do                                                02170008
                "ISPEXEC TBDISPL "TEMPTAB cursor csrrow "POSITION(CRP)" 02180015
                      end /*end do */                                   02190008
                 else                                                   02200008
                   ztdsels = 0                                          02210008
                                                                        02220008
    end /* end do while ztdsels > 0 */                                  02230008
                                                                        02240008
/* reset cursor to the top of the table */                              02250008
/*  "ISPEXEC TBTOP "TEMPTAB                                             02260008
    "ISPEXEC TBSKIP "TEMPTAB" NUMBER("ztdtop")"  */                     02270008
                                                                        02280008
     end /* end do while prc ^=8 */                                     02290008
                                                                        02300017
    "ISPEXEC TBCLOSE "TEMPTAB                                           02310017
      "ISPEXEC TBERASE "TEMPTAB                                         02320017
                                                                        02330069
 /* release the temp member list files */                               02340071
 address tso                                                            02350071
   "FREE DD(INFILE)"                                                    02370069
 signal panel                                                           02380066
 if rc ^= 0 then do
"ISPEXEC LIBDEF ISPTLIB"
"ISPEXEC LIBDEF ISPTABL"
"DELETE '"pref"."UID".TEMP1.ISPTLIB'"
"DELETE '"pref"."UID".TEMP1.ISPTABL'"
exit                                                                    02390060

submit:                                                                 02400060
 "ISPEXEC FTCLOSE"                                                      02400196
 "ISPEXEC VGET (ZTEMPN)"
 "ISPEXEC LMINIT DATAID(DID) DDNAME("ZTEMPN")"
 "ISPEXEC EDIT DATAID(&DID)"
 "ISPEXEC LMCLOSE DATAID(&DID)"
 "ISPEXEC LMFREE  DATAID(&DID)"
 address tso
  "FREE DD(INFILE)"                                                     02401094
  signal panel
                                                                        02430060

/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* Build TestStream                                                 */  00030041
/********************************************************************/  00040000
arg debug .                                                             00050078
if debug = 'DEBUG' then trace a                                         00060056
call ppcinit                                                            00070087
address ISPEXEC                                                         00080042
"VGET (STREAMID LOGDSN STRMPRFX)"                                       00090058
"CONTROL ERRORS RETURN"                                                 00100000
/********************************************************************/  00110041
/* Get/Allocate the Log File                                        */  00120041
/********************************************************************/  00130041
call ppcloga logdsn || "." || streamid debug                            00140087
if result = 99 then exit 99                                             00150059
/********************************************************************/  00160021
/* Main Processing Loop                                             */  00170021
/********************************************************************/  00180021
"DISPLAY PANEL(PPCBLD)"                                                 00190086
do while rc < 8                                                         00200000
  if zcmd ^= ' ' then do                                                00210033
    "VGET (TRACKER SHOWLOG)"                                            00220033
    "LMDINIT LISTID(L) LEVEL(" || strmprfx ,                            00230072
                               || streamid ,                            00240072
                               || ".F0" ,                               00250072
                               || tracker ,                             00260072
                               || ".CNTL)"                              00270072
    "LMDLIST LISTID(&L)"                                                00280072
    if rc = 4 then do                                                   00290072
      startext = date() time() userid() 'Tracker ID' tracker            00300072
      "VPUT STARTEXT"                                                   00310072
      call ppclogw 'Build' buildtyp 'Started :' startext                00320087
      if result = 99 then exit 99                                       00330091
      call ppclogw copies('*',80)                                       00340087
      if result = 99 then exit 99                                       00350091
      errmsgs  = 0                                                      00360098
      warnmsgs = 0                                                      00370098
      "VPUT (ERRMSGS WARNMSGS)"                                         00380098
      call ppctab streamid debug                                        00390087
      "TBSKIP PPCTAB"                                                   00400087
      do while rc = 0                                                   00410072
        call validate                                                   00420072
        "TBSKIP PPCTAB"                                                 00430087
      end                                                               00440072
      "TBTOP PPCTAB"                                                    00450087
      "CONTROL DISPLAY SAVE"                                            00460072
      "VGET (ERRMSGS WARNMSGS)"                                         00470098
      if showlog = 'Y' | errmsgs > 0 | zcmd = 'CHECK' then do           00480098
        "VIEW DATASET('"logdsn"."streamid"') MACRO(PPCEM02)"            00490087
      end                                                               00500072
      if errmsgs = 0 then do                                            00510098
        call genjcl                                                     00520072
      end                                                               00530072
      call ppclogw 'Build' buildtyp 'Ended   :' ,                       00540087
                     date() time() userid() ,                           00550072
                    'Tracker ID' tracker                                00560072
      if result = 99 then exit 99                                       00570091
      "CONTROL DISPLAY RESTORE"                                         00580072
    end                                                                 00590072
    else do                                                             00600072
      zedsmsg = ''                                                      00610072
      zedlmsg = 'CNTL Datasets Already Exist For Tracker' ,             00620072
                 tracker 'and Stream' streamid||'.              ',      00630072
                'They need to be deleted to rerun' ,                    00640072
                 '('||strmprfx||streamid||'.F0'||tracker||'.**.CNTL)'   00650072
      address ISPEXEC                                                   00660072
      "SETMSG MSG(ISRZ001)"                                             00670072
    end                                                                 00680072
    "LMDFREE LISTID(&L)"                                                00690072
  end                                                                   00700072
  "DISPLAY"                                                             00710012
end                                                                     00720012
/********************************************************************/  00730021
/* The End - Tidy up time                                           */  00740021
/********************************************************************/  00750021
"TBEND PPCTAB"                                                          00760087
address TSO                                                             00770002
"FREE F(LOG)"                                                           00780002
exit                                                                    00790000
/********************************************************************/  00800021
/* Validate all the datasets in the table                           */  00810021
/********************************************************************/  00820021
validate:                                                               00830001
                                                                        00840068
  call ppcchkds 'ERROR  ' trgtdsn                                       00850096
                                                                        00860099
  if tostage = 'O' then do                                              00870089
    call ppcchkds 'WARNING' testdsn                                     00880096
    if result = 4 then do                                               00890097
      testdsn = ''                                                      00900068
    end                                                                 00910068
    address ISPEXEC "TBMOD PPCTAB"                                      00920090
  end                                                                   00930068
  else do                                                               00940068
    call ppcchkds 'ERROR  ' testdsn                                     00950096
  end                                                                   00960099
                                                                        00970090
  call ppcchkds 'WARNING' ndvrdsnd                                      00980099
  if result = 4 then do                                                 00990099
    ndvrdsnd = ''                                                       01000099
    address ISPEXEC "TBMOD PPCTAB"                                      01010099
  end                                                                   01020099
  call ppcchkds 'WARNING' ndvrdsnf                                      01030099
  if result = 4 then do                                                 01040099
    ndvrdsnf = ''                                                       01050099
    address ISPEXEC "TBMOD PPCTAB"                                      01060099
  end                                                                   01070099
  call ppcchkds 'WARNING' ndvrdsnp                                      01080099
  if result = 4 then do                                                 01090099
    ndvrdsnp = ''                                                       01100099
    address ISPEXEC "TBMOD PPCTAB"                                      01110099
  end                                                                   01120099
                                                                        01130023
  if buildtyp = 'COMPLETE' then do                                      01140094
    call ppcchkds 'ERROR  ' proddsn                                     01150096
  end                                                                   01160094
                                                                        01170023
  call ppcchkds 'WARNING' overdsn                                       01180096
  if result = 4 then do                                                 01190097
    overdsn = ''                                                        01200042
    address ISPEXEC "TBMOD PPCTAB"                                      01210087
  end                                                                   01220042
                                                                        01230009
return                                                                  01240001
/********************************************************************/  01250022
/* Generate the JCL                                                 */  01260042
/********************************************************************/  01270022
genjcl:                                                                 01280022
/********************************************************************/  01290042
/* Production IEBCOPY JCL                                           */  01300042
/********************************************************************/  01310042
  if buildtyp = 'COMPLETE' then call iebcopy 'PROD'                     01320079
/********************************************************************/  01330042
/* Test IEBCOPY JCL                                                 */  01340042
/********************************************************************/  01350042
  call iebcopy 'TEST'                                                   01360057
/********************************************************************/  01370042
/* Override IEBCOPY JCL                                             */  01380042
/********************************************************************/  01390042
  call iebcopy 'OVER'                                                   01400080
/********************************************************************/  01410042
/* SAS JCL to generate IEBCOPY Select statements & SUB the IEBCOPIES*/  01420042
/********************************************************************/  01430042
  "FTOPEN TEMP"                                                         01440042
  "FTINCL PPCBUILD"                                                     01450085
  if buildtyp = 'COMPLETE' then call subjcl 'X'                         01460079
                                call subjcl 'T'                         01470079
                                call subjcl 'O'                         01480080
  "FTCLOSE"                                                             01490042
  "VGET (ZTEMPN ztempf) SHARED"                                         01500042
  select                                                                01510025
    when zcmd = 'JCL' then do                                           01520070
      "LMINIT DATAID(DATAID) DDNAME(" || ztempn || ")"                  01530025
      "EDIT DATAID(" || dataid || ")"                                   01540069
      "LMFREE DATAID(" dataid ")"                                       01550025
    end                                                                 01560025
    otherwise nop                                                       01570069
  end                                                                   01580025
return                                                                  01590022
/********************************************************************/  01600042
/* FILE TAILORING FOR IEBCOPY                                       */  01610061
/********************************************************************/  01620042
iebcopy:                                                                01630042
  arg loc                                                               01640061
  l = substr(loc,1,1)                                                   01650063
  if l = 'P' then l = 'X'                                               01660074
  cntlpds = strmprfx || ,                                               01670061
            streamid || ,                                               01680061
            '.F0'    || ,                                               01690065
            tracker  || ,                                               01700063
            '.CNTL'                                                     01710061
  address ISPEXEC                                                       01720061
  if sysdsn("'"cntlpds"'") = 'OK' then do                               01730061
    address TSO "ALLOC F(ISPFILE) DA('" || cntlpds || "') SHR REUSE"    01740061
  end                                                                   01750061
  else do                                                               01760061
    address TSO "ALLOC F(ISPFILE) DA('" || cntlpds || "') NEW REUSE" ,  01770061
               "CATALOG LRECL(80) RECFM(F B) DSORG(PO) DSNTYPE(LIBRARY)"01780061
  end                                                                   01790061
  "FTOPEN"                                                              01800042
  "FTINCL PPCIEBC"                                                      01810085
  "FTCLOSE NAME(" || l || "0" || tracker || ")"                         01820065
  address TSO "FREE F(ISPFILE)"                                         01830062
  call ppclogw 'IEBCOPY JCL Generated in  :' cntlpds date() time()      01840087
  if result = 99 then exit 99                                           01850091
return                                                                  01860042
/********************************************************************/  01870042
/* FTINCL IEBGENER JCL To The Internal Reader                       */  01880042
/********************************************************************/  01890042
subjcl:                                                                 01900042
  arg l                                                                 01910045
  "FTINCL PPCIEBG"                                                      01920085
return                                                                  01930042

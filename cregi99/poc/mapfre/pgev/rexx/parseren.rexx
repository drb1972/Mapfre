/*REXX*****************************************************************/00010002
/*                                                                    */00020002
/* Program Name : PARSEREN                                            */00030003
/*                                                                    */00040002
/* Author       : John Wade / Srinivas Reddy                          */00050005
/*                                                                    */00060002
/* Date Written : 08 April 2009                                       */00070005
/*                                                                    */00080002
/* Type         : REXX routine                                        */00090005
/*                                                                    */00100002
/* How to Invoke: Invoked under Endevor CICS compile                  */00110015
/*                                                                    */00120002
/* Description  : EXEC to read a CICS source program written in COBOL */00130005
/*                and police the use of CICS APIs and use of RESP in  */00140005
/*                These APIs. It also reports thread safty of the     */00150005
/*                current program.                                    */00160005
/*                                                                    */00170005
/* Parameters   : None                                                */00180002
/*                                                                    */00190005
/* Input File(s): None                                                */00200005
/*                                                                    */00210002
/* Input File(s): COBOL source program                                */00220005
/* Calls        : none                                                */00230033
/* Call ed By    : None                                               */00240033
/* Panels       : N/A                                                 */00250005
/* Skeletons    : N/A                                                 */00260005
/**********************************************************************/00270002
                                                                        00280005
/*Trace ?R     */                                                       00290044
                                                                        00300043
Call  Initialization                                                    00310033
                                                                        00320002
Call  MainProcess                                                       00330033
                                                                        00340002
Call  Termination                                                       00350033
                                                                        00360002
Exit(0)                                                                 00370002
                                                                        00380002
/*--------------------------------------------------------------------*/00390003
/* Initialization process                                             */00400005
/*--------------------------------------------------------------------*/00410003
                                                                        00420002
Initialization:                                                         00430002
/*-----------*/                                                         00440033
                                                                        00450002
  Say 'PARSEREN: '                                                      00460003
  Say 'PARSEREN: Entering Initialization: subroutine'                   00470003
  Say 'PARSEREN: '                                                      00480003
                                                                        00490002
 /**************************************************************/       00500005
 /*  Do not change the initial settings of any of these        */       00510015
 /* variables.                                                 */       00520005
 /**************************************************************/       00530005
  Rv_Record_No             = 0                                          00540011
  Rv_Return_Code           = 0                                          00550005
  Rv_End_File              = 0                                          00560015
  Rv_CICS_EXEC_Count       = 0                                          00570005
  Rv_Records_In_Stack      = 0                                          00580005
  Rc_Error_Code            = 32                                         00590005
  Rc_Warning_Code          = 28                                         00600005
  Rc_Reminder_Code         = 24                                         00610005
  Rv_Errors_Ctr            = 0                                          00620044
  Rv_Warnings_Ctr          = 0                                          00630044
  Rv_Reminders_Ctr         = 0                                          00640005
  Rv_Error_List_Stem.0     = 0                                          00650005
  Rv_Warning_List_Stem.0   = 0                                          00660005
  Rv_Reminder_List_Stem.0  = 0                                          00670005
  Rv_Line_Limit            = 12                                         00680005
  Rv_Stack_Size            = 500                                        00690033
                                                                        00690176
  Rv_TS_Error_Ctr          = 0                                          00690276
  Rv_TS_Warning_Ctr        = 0                                          00690376
  Rv_TS_Error_Stem.0       = 0                                          00690476
  Rv_TS_Warning_Stem.0     = 0                                          00690576
                                                                        00700005
  Rf_Write_ThrdSafe_File   = 0                                          00700176
  Rf_Db2_Present           = 0                                          00700285
  Rf_MQ_Present            = 0                                          00700385
  Rf_Call_present          = 0                                          00700485
                                                                        00700585
  line_limit = 12                                                       00710008
                                                                        00720002
                                                                        00730008
  Rc_READ = 'EXECIO' Rv_Stack_Size 'DISKR INFILE'                       00740033
  RC_WRITE_LINE  = 'EXECIO 1 DISKW ciccheck '                           00750008
  RC_WRITE_FINIS = 'EXECIO 1 DISKW ciccheck (FINIS)'                    00760008
                                                                        00770008
  RC_WRITE_TS_LINE  = 'EXECIO 1 DISKW thrdsafe '                        00770176
  RC_WRITE_TS_FINIS = 'EXECIO 1 DISKW thrdsafe (FINIS)'                 00770276
                                                                        00770376
  Call  Set_CICS_API_Vars                                               00780033
                                                                        00790002
Return                                                                  00800002
                                                                        00810002
                                                                        00820002
/*--------------------------------------------------------------------*/00830003
/* Define All relavent CICS API variables                             */00840008
/*--------------------------------------------------------------------*/00850003
                                                                        00860002
Set_CICS_API_Vars:                                                      00870008
/*-------------*/                                                       00880008
                                                                        00890002
  Say 'PARSEREN: '                                                      00900008
  Say 'PARSEREN: Entering Set_CICS_API_Vars: subroutine'                00910008
  Say 'PARSEREN: '                                                      00920008
                                                                        00930008
  Rc_Banned_Berbs          =  "ALLOCATE" ,                              00940008
                              "CONVERSE" ,                              00950008
                              "CONNECT"  ,                              00960008
                              "IGNORE"   ,                              00970013
                              "FREE"     ,                              00980013
                              "ENQ"      ,                              00990013
                              "DEQ"      ,                              01000013
                              "CANCEL"   ,                              01010013
                              "WAIT"     ,                              01020013
                              "POST"                                    01030013
                                                                        01040008
  Rc_No_Resp_Queries       =  " "   ,                                   01050008
                              "ABDUMP" ,                                01060013
                              "ABPROGRAM" ,                             01070013
                              "ASRAINTRPT" ,                            01080013
                              "ASRAKEY" ,                               01090013
                              "ASRAPSW" ,                               01100013
                              "ASRAREGS" ,                              01110013
                              "ASRASPC" ,                               01120013
                              "ASRASTG" ,                               01130013
                              "BRIDGE" ,                                01140013
                              "CMDSEC" ,                                01150013
                              "INITPARM" ,                              01160013
                              "INITPARMLEN" ,                           01170013
                              "LANGINUSE" ,                             01180013
                              "NATLANGINUSE" ,                          01190013
                              "NEXTTRANSID" ,                           01200013
                              "OPCLASS" ,                               01210013
                              "OPERKEYS" ,                              01220013
                              "OPID" ,                                  01230013
                              "OPSECURITY" ,                            01240013
                              "ORGABCODE" ,                             01250013
                              "RESSEC" ,                                01260013
                              "RESTART" ,                               01270013
                              "TASKPRIORITY" ,                          01280013
                              "TCTUALENG" ,                             01290013
                              "TERMCODE" ,                              01300013
                              "TERMPRIORITY" ,                          01310013
                              "TRANPRIORITY" ,                          01320013
                              "TWALENG" ,                               01330013
                              "USERPRIORITY" ,                          01340013
                              " "                                       01350013
                                                                        01360013
  Rc_No_Resp_Assigns       =  " "   ,                                   01370008
                              "ABCODE" ,                                01380013
                              "ABDUMP" ,                                01390013
                              "ABPROGRAM" ,                             01400013
                              "APPLID" ,                                01410013
                              "ASRAINTRPT" ,                            01420013
                              "ASRAKEY" ,                               01430013
                              "ASRAPSW" ,                               01440013
                              "ASRAREGS" ,                              01450013
                              "ASRASPC" ,                               01460013
                              "ASRASTG" ,                               01470013
                              "BRIDGE" ,                                01480013
                              "CHANNEL",                                01490096
                              "CMDSEC" ,                                01491095
                              "CWALENG" ,                               01500013
                              "FCI" ,                                   01510013
                              "INITPARM" ,                              01520013
                              "INITPARMLEN" ,                           01530013
                              "INVOKINGPROG" ,                          01540013
                              "LANGINUSE" ,                             01550013
                              "NATLANGINUSE" ,                          01560013
                              "NEXTTRANSID" ,                           01570013
                              "OPCLASS" ,                               01580013
                              "OPERKEYS" ,                              01590013
                              "OPID" ,                                  01600013
                              "OPSECURITY" ,                            01610013
                              "ORGABCODE" ,                             01620013
                              "PROGRAM"   ,                             01630013
                              "RESSEC" ,                                01640013
                              "RESTART" ,                               01650013
                              "RETURNPROG" ,                            01660013
                              "STARTCODE" ,                             01670013
                              "SYSID" ,                                 01680013
                              "TASKPRIORITY" ,                          01690013
                              "TCTUALENG" ,                             01700013
                              "TERMCODE" ,                              01710013
                              "TERMPRIORITY" ,                          01720013
                              "TRANPRIORITY" ,                          01730013
                              "TWALENG" ,                               01740013
                              "USERID" ,                                01750013
                              "USERNAME" ,                              01760013
                              "USERPRIORITY" ,                          01770013
                              " "                                       01780013
                                                                        01790008
  Rc_No_Resp_Verbs         =  "ABEND"     ,                             01800015
                              "ADDRESS"   ,                             01810013
                              "ASKTIME"   ,                             01820013
                              "HANDLE"    ,                             01830013
                              "IGNORE"    ,                             01840013
                              "PUSH"      ,                             01850013
                              "SUSPEND"                                 01860015
                                                                        01870013
                                                                        01880015
  Rv_COBOL_Prohibited_Verbs_Stem.1    = "ACCEPT"                        01890015
  Rv_COBOL_Prohibited_Verbs_Stem.2    = "OPEN"                          01900015
  Rv_COBOL_Prohibited_Verbs_Stem.3    = "CLOSE"                         01910015
  Rv_COBOL_Prohibited_Verbs_Stem.4    = "ACCEPT"                        01920015
  Rv_COBOL_Prohibited_Verbs_Stem.5    = "START"                         01930015
  Rv_COBOL_Prohibited_Verbs_Stem.6    = "REWRITE"                       01940015
  Rv_COBOL_Prohibited_Verbs_Stem.7    = "WRITE"                         01950015
  Rv_COBOL_Prohibited_Verbs_Stem.8    = "DELETE"                        01960015
                                                                        01970015
  Rv_COBOL_Prohibited_Verbs_Stem.0    = 8                               01980015
                                                                        01990062
                                                                        02000062
  Rv_Req_Cmd_Stem.1         = "CHANNEL E DELETE CONTAINER"              02010072
  Rv_Req_Cmd_Stem.2         = "CHANNEL E GET CONTAINER"                 02020072
  Rv_Req_Cmd_Stem.3         = "CHANNEL E MOVE CONTAINER"                02030072
  Rv_Req_Cmd_Stem.4         = "CHANNEL E PUT CONTAINER"                 02040072
  Rv_Req_Cmd_Stem.5         = "CHANNEL E STARTBROWSE CONTAINER"         02050072
  Rv_Req_Cmd_Stem.6         = "RESP2 E INVOKE WEBSERVICE"               02060072
                                                                        02100062
  Rv_Req_Cmd_Stem.0         = 6                                         02110099
                                                                        02120062
  Rv_Omit_Cmd_Stem.1        = "URI E INVOKE WEBSERVICE"                 02130072
  Rv_Omit_Cmd_Stem.2        = "SHARED E GETMAIN"                        02131099
  Rv_Omit_Cmd_Stem.3        = "GASET  E EXTRACT EXIT"                   02132099
  Rv_Omit_Cmd_Stem.4        = "CWA W ADDRESS"                           02133099
                                                                        02140062
  Rv_Omit_Cmd_Stem.0        = 4                                         02150099
                                                                        02160062
  /* Thread safe inhibiters APIs are in the following member*/          02170073
  /* SYSCTS.CTS310A.SDFHSAMP(DFHEIDTH)                      */          02180073
                                                                        02190073
  Rv_Thrd_Safe_inh_Stem.1   = "EXTRACT EXIT GASET"                      02200072
  Rv_Thrd_Safe_inh_Stem.2   = "GETMAIN SHARED"                          02210084
  Rv_Thrd_Safe_inh_Stem.3   = "ADDRESS CWA"                             02220084
                                                                        02230062
  Rv_Thrd_Safe_inh_Stem.0   = 3                                         02240082
                                                                        02250062
  /* Non Thread safe APIs are in the following member       */          02260073
  /* SYSCTS.CTS310A.SDFHSAMP(DFHEIDNT)                      */          02270073
                                                                        02280073
  Rv_non_Thrd_safe_Stem.1   = "RECEIVE "                                02290072
  Rv_non_Thrd_safe_Stem.2   = "SEND "                                   02300072
  Rv_non_Thrd_safe_Stem.3   = "CONVERSE "                               02310072
  Rv_non_Thrd_safe_Stem.4   = "ISSUE EODS "                             02320072
  Rv_non_Thrd_safe_Stem.5   = "ISSUE COPY "                             02330072
  Rv_non_Thrd_safe_Stem.6   = "WAIT TERMINAL "                          02340072
  Rv_non_Thrd_safe_Stem.7   = "ISSUE LOAD "                             02350072
  Rv_non_Thrd_safe_Stem.8   = "WAIT SIGNAL "                            02360072
  Rv_non_Thrd_safe_Stem.9   = "ISSUE RESET "                            02370072
  Rv_non_Thrd_safe_Stem.10  = "ISSUE DISCONNECT "                       02380072
  Rv_non_Thrd_safe_Stem.11  = "ISSUE ENDOUTPUT "                        02390072
  Rv_non_Thrd_safe_Stem.12  = "ISSUE ERASEAUP "                         02400072
  Rv_non_Thrd_safe_Stem.13  = "ISSUE ENDFILE "                          02410072
  Rv_non_Thrd_safe_Stem.14  = "ISSUE PRINT "                            02420072
  Rv_non_Thrd_safe_Stem.15  = "ISSUE SIGNAL "                           02430072
  Rv_non_Thrd_safe_Stem.16  = "ALLOCATE "                               02440072
  Rv_non_Thrd_safe_Stem.17  = "FREE "                                   02450072
  Rv_non_Thrd_safe_Stem.18  = "POINT "                                  02460072
  Rv_non_Thrd_safe_Stem.19  = "BUILD ATTACH "                           02470072
  Rv_non_Thrd_safe_Stem.20  = "EXTRACT ATTACH "                         02480072
  Rv_non_Thrd_safe_Stem.21  = "EXTRACT TCT "                            02490072
  Rv_non_Thrd_safe_Stem.22  = "WAIT CONVID "                            02500072
  Rv_non_Thrd_safe_Stem.23  = "EXTRACT PROCESS "                        02510072
  Rv_non_Thrd_safe_Stem.24  = "ISSUE ABEND "                            02520072
  Rv_non_Thrd_safe_Stem.25  = "CONNECT PROCESS "                        02530072
  Rv_non_Thrd_safe_Stem.26  = "ISSUE CONFIRMATION "                     02540072
  Rv_non_Thrd_safe_Stem.27  = "ISSUE ERROR "                            02550072
  Rv_non_Thrd_safe_Stem.28  = "ISSUE PREPARE "                          02560072
  Rv_non_Thrd_safe_Stem.29  = "ISSUE PASS "                             02570072
  Rv_non_Thrd_safe_Stem.30  = "EXTRACT LOGONMSG "                       02580072
  Rv_non_Thrd_safe_Stem.31  = "EXTRACT ATTRIBUTES "                     02590072
  Rv_non_Thrd_safe_Stem.32  = "READ "                                   02600072
  Rv_non_Thrd_safe_Stem.33  = "WRITE FILE "                             02610072
  Rv_non_Thrd_safe_Stem.34  = "REWRITE "                                02620072
  Rv_non_Thrd_safe_Stem.35  = "DELETE FILE "                            02630072
  Rv_non_Thrd_safe_Stem.36  = "UNLOCK "                                 02640072
  Rv_non_Thrd_safe_Stem.37  = "STARTBR "                                02650072
  Rv_non_Thrd_safe_Stem.38  = "READNEXT "                               02660072
  Rv_non_Thrd_safe_Stem.39  = "READPREV "                               02670072
  Rv_non_Thrd_safe_Stem.40  = "RESETBR "                                02680072
  Rv_non_Thrd_safe_Stem.41  = "WRITEQ TD "                              02690072
  Rv_non_Thrd_safe_Stem.42  = "READQ TD "                               02700072
  Rv_non_Thrd_safe_Stem.43  = "DELETEQ TD "                             02710072
  Rv_non_Thrd_safe_Stem.44  = "LINK PROGRAM "                           02720072
  Rv_non_Thrd_safe_Stem.45  = "DELAY "                                  02730072
  Rv_non_Thrd_safe_Stem.46  = "POST "                                   02740072
  Rv_non_Thrd_safe_Stem.47  = "START "                                  02750072
  Rv_non_Thrd_safe_Stem.48  = "RETRIEVE "                               02760074
  Rv_non_Thrd_safe_Stem.49  = "CANCEL "                                 02770074
  Rv_non_Thrd_safe_Stem.50  = "WAIT EVENT "                             02780074
  Rv_non_Thrd_safe_Stem.51  = "JOURNAL "                                02790074
  Rv_non_Thrd_safe_Stem.52  = "WRITE JOURNALNUM "                       02800074
  Rv_non_Thrd_safe_Stem.53  = "WAIT JOURNAL "                           02810074
  Rv_non_Thrd_safe_Stem.54  = "WAIT JOURNALNUM "                        02820074
  Rv_non_Thrd_safe_Stem.55  = "WRITE JOURNALNAME "                      02830074
  Rv_non_Thrd_safe_Stem.56  = "WAIT JOURNALNAME "                       02840074
  Rv_non_Thrd_safe_Stem.57  = "SYNCPOINT "                              02850074
  Rv_non_Thrd_safe_Stem.58  = "RESYNC "                                 02860074
  Rv_non_Thrd_safe_Stem.59  = "RECEIVE MAP "                            02870074
  Rv_non_Thrd_safe_Stem.60  = "SEND MAP "                               02880074
  Rv_non_Thrd_safe_Stem.61  = "SEND TEXT "                              02890074
  Rv_non_Thrd_safe_Stem.62  = "SEND PAGE "                              02900074
  Rv_non_Thrd_safe_Stem.63  = "PURGE MESSAGE "                          02910074
  Rv_non_Thrd_safe_Stem.64  = "ROUTE "                                  02920074
  Rv_non_Thrd_safe_Stem.65  = "RECEIVE PARTN "                          02930074
  Rv_non_Thrd_safe_Stem.66  = "SEND PARTNSET "                          02940074
  Rv_non_Thrd_safe_Stem.67  = "SEND CONTROL "                           02950074
  Rv_non_Thrd_safe_Stem.68  = "TRACE "                                  02960074
  Rv_non_Thrd_safe_Stem.69  = "ENTER TRACEID "                          02970074
  Rv_non_Thrd_safe_Stem.70  = "DUMP "                                   02980074
  Rv_non_Thrd_safe_Stem.71  = "DUMP TRANSACTION "                       02990074
  Rv_non_Thrd_safe_Stem.72  = "ENABLE "                                 03000074
  Rv_non_Thrd_safe_Stem.73  = "ENDBR "                                  03010074
  Rv_non_Thrd_safe_Stem.74  = "ENDBROWSE ACTIVITY "                     03020074
  Rv_non_Thrd_safe_Stem.75  = "ENDBROWSE EVENT "                        03030074
  Rv_non_Thrd_safe_Stem.76  = "ENDBROWSE PROCESS "                      03040074
  Rv_non_Thrd_safe_Stem.77  = "ENDBROWSE TIMER "                        03050074
  Rv_non_Thrd_safe_Stem.78  = "ISSUE ADD "                              03060074
  Rv_non_Thrd_safe_Stem.79  = "ISSUE ERASE "                            03070074
  Rv_non_Thrd_safe_Stem.80  = "ISSUE REPLACE "                          03080074
  Rv_non_Thrd_safe_Stem.81  = "ISSUE ABORT "                            03090074
  Rv_non_Thrd_safe_Stem.82  = "ISSUE QUERY "                            03100074
  Rv_non_Thrd_safe_Stem.83  = "ISSUE END "                              03110074
  Rv_non_Thrd_safe_Stem.84  = "ISSUE RECEIVE "                          03120074
  Rv_non_Thrd_safe_Stem.85  = "ISSUE NOTE "                             03130074
  Rv_non_Thrd_safe_Stem.86  = "ISSUE WAIT "                             03140074
  Rv_non_Thrd_safe_Stem.87  = "ISSUE SEND "                             03150074
  Rv_non_Thrd_safe_Stem.88  = "BIF DEEDIT "                             03160074
  Rv_non_Thrd_safe_Stem.89  = "DEFINE COUNTER "                         03170074
  Rv_non_Thrd_safe_Stem.90  = "GET COUNTER "                            03180074
  Rv_non_Thrd_safe_Stem.91  = "UPDATE COUNTER "                         03190074
  Rv_non_Thrd_safe_Stem.92  = "DELETE COUNTER "                         03200074
  Rv_non_Thrd_safe_Stem.93  = "REWIND COUNTER "                         03210074
  Rv_non_Thrd_safe_Stem.94  = "QUERY COUNTER "                          03220074
  Rv_non_Thrd_safe_Stem.95  = "DEFINE DCOUNTER "                        03230074
  Rv_non_Thrd_safe_Stem.96  = "GET DCOUNTER "                           03240074
  Rv_non_Thrd_safe_Stem.97  = "UPDATE DCOUNTER "                        03250074
  Rv_non_Thrd_safe_Stem.98  = "DELETE DCOUNTER "                        03260074
  Rv_non_Thrd_safe_Stem.99  = "REWIND DCOUNTER "                        03270074
  Rv_non_Thrd_safe_Stem.100 = "QUERY DCOUNTER "                         03280074
  Rv_non_Thrd_safe_Stem.101 = "DISABLE "                                03290074
  Rv_non_Thrd_safe_Stem.102 = "EXTRACT EXIT "                           03300074
  Rv_non_Thrd_safe_Stem.103 = "DEFINE REQUESTMODEL "                    03310074
  Rv_non_Thrd_safe_Stem.104 = "DELETE REQUESTMODEL "                    03320074
  Rv_non_Thrd_safe_Stem.105 = "CREATE PROGRAM "                         03330074
  Rv_non_Thrd_safe_Stem.106 = "CREATE MAPSET "                          03340074
  Rv_non_Thrd_safe_Stem.107 = "CREATE PARTITIONSET "                    03350074
  Rv_non_Thrd_safe_Stem.108 = "CREATE TRANSACTION "                     03360074
  Rv_non_Thrd_safe_Stem.109 = "CREATE PROFILE "                         03370074
  Rv_non_Thrd_safe_Stem.110 = "CREATE TYPETERM "                        03380074
  Rv_non_Thrd_safe_Stem.111 = "CREATE TERMINAL "                        03390074
  Rv_non_Thrd_safe_Stem.112 = "CREATE SESSIONS "                        03400074
  Rv_non_Thrd_safe_Stem.113 = "CREATE FILE "                            03410074
  Rv_non_Thrd_safe_Stem.114 = "CREATE LSRPOOL "                         03420074
  Rv_non_Thrd_safe_Stem.115 = "CREATE PARTNER "                         03430074
  Rv_non_Thrd_safe_Stem.116 = "CREATE TRANCLASS "                       03440074
  Rv_non_Thrd_safe_Stem.117 = "CREATE TDQUEUE "                         03450074
  Rv_non_Thrd_safe_Stem.118 = "CREATE JOURNALMODEL "                    03460074
  Rv_non_Thrd_safe_Stem.119 = "CREATE DB2CONN "                         03470074
  Rv_non_Thrd_safe_Stem.120 = "CREATE DB2ENTRY "                        03480074
  Rv_non_Thrd_safe_Stem.121 = "CREATE DB2TRAN "                         03490074
  Rv_non_Thrd_safe_Stem.122 = "CREATE PROCESSTYPE "                     03500074
  Rv_non_Thrd_safe_Stem.123 = "CREATE TSMODEL "                         03510074
  Rv_non_Thrd_safe_Stem.124 = "CREATE ENQMODEL "                        03520074
  Rv_non_Thrd_safe_Stem.125 = "CREATE REQUESTMODEL "                    03530074
  Rv_non_Thrd_safe_Stem.126 = "CREATE DOCTEMPLATE "                     03540074
  Rv_non_Thrd_safe_Stem.127 = "CREATE TCPIPSERVICE "                    03550074
  Rv_non_Thrd_safe_Stem.128 = "CREATE PIPELINE "                        03560074
  Rv_non_Thrd_safe_Stem.139 = "CREATE URIMAP "                          03570074
  Rv_non_Thrd_safe_Stem.130 = "CREATE WEBSERVICE "                      03580074
  Rv_non_Thrd_safe_Stem.131 = "CREATE CORBASERVER "                     03590074
  Rv_non_Thrd_safe_Stem.132 = "CREATE DJAR "                            03600074
  Rv_non_Thrd_safe_Stem.133 = "DEFINE ACTIVITY "                        03610074
  Rv_non_Thrd_safe_Stem.134 = "DEFINE PROCESS "                         03620074
  Rv_non_Thrd_safe_Stem.135 = "RUN ACTIVITY "                           03630074
  Rv_non_Thrd_safe_Stem.136 = "RUN ACQPROCESS "                         03640074
  Rv_non_Thrd_safe_Stem.137 = "ACQUIRE PROCESS "                        03650074
  Rv_non_Thrd_safe_Stem.138 = "ACQUIRE ACTIVITYID "                     03660074
  Rv_non_Thrd_safe_Stem.149 = "RESET ACTIVITY "                         03670074
  Rv_non_Thrd_safe_Stem.140 = "CHECK ACTIVITY "                         03680074
  Rv_non_Thrd_safe_Stem.141 = "CANCEL ACTIVITY "                        03690074
  Rv_non_Thrd_safe_Stem.142 = "CANCEL ACQPROCESS "                      03700074
  Rv_non_Thrd_safe_Stem.143 = "SUSPEND ACTIVITY "                       03710074
  Rv_non_Thrd_safe_Stem.144 = "SUSPEND ACQPROCESS "                     03720074
  Rv_non_Thrd_safe_Stem.145 = "RESUME ACTIVITY "                        03730074
  Rv_non_Thrd_safe_Stem.146 = "RESUME ACQPROCESS "                      03740074
  Rv_non_Thrd_safe_Stem.147 = "DELETE ACTIVITY "                        03750074
  Rv_non_Thrd_safe_Stem.148 = "LINK ACQPROCESS "                        03760074
  Rv_non_Thrd_safe_Stem.159 = "LINK ACTIVITY "                          03770074
  Rv_non_Thrd_safe_Stem.150 = "CANCEL ACQACTIVITY "                     03780074
  Rv_non_Thrd_safe_Stem.151 = "RUN ACQACTIVITY "                        03790074
  Rv_non_Thrd_safe_Stem.152 = "LINK ACQACTIVITY "                       03800074
  Rv_non_Thrd_safe_Stem.153 = "SUSPEND ACQACTIVITY "                    03810074
  Rv_non_Thrd_safe_Stem.154 = "RESUME ACQACTIVITY "                     03820074
  Rv_non_Thrd_safe_Stem.155 = "CHECK ACQPROCESS "                       03830074
  Rv_non_Thrd_safe_Stem.156 = "CHECK ACQACTIVITY "                      03840074
  Rv_non_Thrd_safe_Stem.157 = "RESET ACQPROCESS "                       03850074
  Rv_non_Thrd_safe_Stem.158 = "DEFINE EVENT "                           03860074
  Rv_non_Thrd_safe_Stem.159 = "DELETE EVENT "                           03870074
  Rv_non_Thrd_safe_Stem.160 = "ADD SUBEVENT "                           03880074
  Rv_non_Thrd_safe_Stem.161 = "REMOVE SUBEVENT "                        03890074
  Rv_non_Thrd_safe_Stem.162 = "TEST EVENT "                             03900074
  Rv_non_Thrd_safe_Stem.163 = "RETRIEVE REATTACH "                      03910074
  Rv_non_Thrd_safe_Stem.164 = "RETRIEVE SUBEVENT "                      03920074
  Rv_non_Thrd_safe_Stem.165 = "DEFINE TIMER "                           03930074
  Rv_non_Thrd_safe_Stem.166 = "DELETE TIMER "                           03940074
  Rv_non_Thrd_safe_Stem.167 = "CHECK TIMER "                            03950074
  Rv_non_Thrd_safe_Stem.168 = "FORCE TIMER "                            03960074
  Rv_non_Thrd_safe_Stem.169 = "INQUIRE RRMS "                           03970074
  Rv_non_Thrd_safe_Stem.170 = "EXTRACT TCPIP "                          03980074
  Rv_non_Thrd_safe_Stem.171 = "EXTRACT CERTIFICATE "                    03990074
  Rv_non_Thrd_safe_Stem.172 = "INQUIRE AUTINSTMODEL "                   04000074
  Rv_non_Thrd_safe_Stem.173 = "DISCARD AUTINSTMODEL "                   04010074
  Rv_non_Thrd_safe_Stem.174 = "INQUIRE PARTNER "                        04020074
  Rv_non_Thrd_safe_Stem.175 = "DISCARD PARTNER "                        04030074
  Rv_non_Thrd_safe_Stem.176 = "INQUIRE PROFILE "                        04040074
  Rv_non_Thrd_safe_Stem.177 = "DISCARD PROFILE "                        04050074
  Rv_non_Thrd_safe_Stem.178 = "INQUIRE FILE "                           04060074
  Rv_non_Thrd_safe_Stem.179 = "SET FILE "                               04070074
  Rv_non_Thrd_safe_Stem.180 = "DISCARD FILE "                           04080074
  Rv_non_Thrd_safe_Stem.181 = "INQUIRE PROGRAM "                        04090074
  Rv_non_Thrd_safe_Stem.182 = "SET PROGRAM "                            04100074
  Rv_non_Thrd_safe_Stem.183 = "DISCARD PROGRAM "                        04110074
  Rv_non_Thrd_safe_Stem.184 = "INQUIRE TRANSACTION "                    04120074
  Rv_non_Thrd_safe_Stem.185 = "SET TRANSACTION "                        04130074
  Rv_non_Thrd_safe_Stem.186 = "DISCARD TRANSACTION "                    04140074
  Rv_non_Thrd_safe_Stem.187 = "INQUIRE TERMINAL "                       04150074
  Rv_non_Thrd_safe_Stem.188 = "SET NETNAME "                            04160074
  Rv_non_Thrd_safe_Stem.189 = "DISCARD TERMINAL "                       04170074
  Rv_non_Thrd_safe_Stem.190 = "SET TERMINAL "                           04180074
  Rv_non_Thrd_safe_Stem.191 = "INQUIRE NETNAME "                        04190074
  Rv_non_Thrd_safe_Stem.192 = "SET SYSTEM "                             04200074
  Rv_non_Thrd_safe_Stem.193 = "INQUIRE SYSTEM "                         04210074
  Rv_non_Thrd_safe_Stem.194 = "SPOOLOPEN INPUT "                        04220074
  Rv_non_Thrd_safe_Stem.195 = "SPOOLOPEN OUTPUT "                       04230074
  Rv_non_Thrd_safe_Stem.196 = "SPOOLREAD "                              04240074
  Rv_non_Thrd_safe_Stem.197 = "SPOOLWRITE "                             04250074
  Rv_non_Thrd_safe_Stem.198 = "SPOOLCLOSE "                             04260074
  Rv_non_Thrd_safe_Stem.199 = "INQUIRE CONNECTION "                     04270074
  Rv_non_Thrd_safe_Stem.200 = "SET CONNECTION "                         04280074
  Rv_non_Thrd_safe_Stem.201 = "PERFORM ENDAFFINITY "                    04290074
  Rv_non_Thrd_safe_Stem.202 = "DISCARD CONNECTION "                     04300074
  Rv_non_Thrd_safe_Stem.203 = "INQUIRE MODENAME "                       04310074
  Rv_non_Thrd_safe_Stem.204 = "SET MODENAME "                           04320074
  Rv_non_Thrd_safe_Stem.205 = "INQUIRE TDQUEUE "                        04330074
  Rv_non_Thrd_safe_Stem.206 = "SET TDQUEUE "                            04340074
  Rv_non_Thrd_safe_Stem.207 = "DISCARD TDQUEUE "                        04350074
  Rv_non_Thrd_safe_Stem.208 = "INQUIRE TASK LIST "                      04360074
  Rv_non_Thrd_safe_Stem.209 = "SET TASK "                               04370074
  Rv_non_Thrd_safe_Stem.210 = "INQUIRE STORAGE "                        04380074
  Rv_non_Thrd_safe_Stem.211 = "INQUIRE TCLASS "                         04390074
  Rv_non_Thrd_safe_Stem.212 = "SET TCLASS "                             04400074
  Rv_non_Thrd_safe_Stem.213 = "DISCARD TRANCLASS "                      04410074
  Rv_non_Thrd_safe_Stem.214 = "INQUIRE TRANCLASS "                      04420074
  Rv_non_Thrd_safe_Stem.215 = "SET TRANCLASS "                          04430074
  Rv_non_Thrd_safe_Stem.216 = "WAITCICS "                               04440074
  Rv_non_Thrd_safe_Stem.217 = "INQUIRE SUBPOOL "                        04450074
  Rv_non_Thrd_safe_Stem.218 = "INQUIRE JOURNALNUM "                     04460074
  Rv_non_Thrd_safe_Stem.219 = "SET JOURNALNUM "                         04470074
  Rv_non_Thrd_safe_Stem.220 = "DISCARD JOURNALNAME "                    04480074
  Rv_non_Thrd_safe_Stem.221 = "INQUIRE JOURNALNAME "                    04490074
  Rv_non_Thrd_safe_Stem.222 = "SET JOURNALNAME "                        04500074
  Rv_non_Thrd_safe_Stem.223 = "INQUIRE VOLUME "                         04510074
  Rv_non_Thrd_safe_Stem.224 = "SET VOLUME "                             04520074
  Rv_non_Thrd_safe_Stem.225 = "PERFORM SECURITY "                       04530074
  Rv_non_Thrd_safe_Stem.226 = "INQUIRE DUMPDS "                         04540074
  Rv_non_Thrd_safe_Stem.227 = "SET DUMPDS "                             04550074
  Rv_non_Thrd_safe_Stem.228 = "INQUIRE TRANDUMPCODE "                   04560074
  Rv_non_Thrd_safe_Stem.229 = "SET TRANDUMPCODE "                       04570074
  Rv_non_Thrd_safe_Stem.230 = "INQUIRE SYSDUMPCODE "                    04580074
  Rv_non_Thrd_safe_Stem.231 = "SET SYSDUMPCODE "                        04590074
  Rv_non_Thrd_safe_Stem.232 = "INQUIRE VTAM "                           04600074
  Rv_non_Thrd_safe_Stem.233 = "SET VTAM "                               04610074
  Rv_non_Thrd_safe_Stem.234 = "INQUIRE AUTOINSTALL "                    04620074
  Rv_non_Thrd_safe_Stem.235 = "SET AUTOINSTALL "                        04630074
  Rv_non_Thrd_safe_Stem.236 = "INQUIRE DELETSHIPPED "                   04640074
  Rv_non_Thrd_safe_Stem.237 = "SET DELETSHIPPED "                       04650074
  Rv_non_Thrd_safe_Stem.238 = "PERFORM DELETSHIPPED "                   04660074
  Rv_non_Thrd_safe_Stem.239 = "QUERY SECURITY "                         04670074
  Rv_non_Thrd_safe_Stem.240 = "WRITE OPERATOR "                         04680074
  Rv_non_Thrd_safe_Stem.241 = "CICSMESSAGE "                            04690074
  Rv_non_Thrd_safe_Stem.242 = "INQUIRE IRC "                            04700074
  Rv_non_Thrd_safe_Stem.243 = "SET IRC "                                04710074
  Rv_non_Thrd_safe_Stem.244 = "INQUIRE STATISTICS "                     04720074
  Rv_non_Thrd_safe_Stem.245 = "SET STATISTICS "                         04730074
  Rv_non_Thrd_safe_Stem.246 = "PERFORM STATISTICS "                     04740074
  Rv_non_Thrd_safe_Stem.247 = "COLLECT STATISTICS "                     04750074
  Rv_non_Thrd_safe_Stem.248 = "EXTRACT STATISTICS "                     04760074
  Rv_non_Thrd_safe_Stem.249 = "INQUIRE MONITOR "                        04770074
  Rv_non_Thrd_safe_Stem.250 = "SET MONITOR "                            04780074
  Rv_non_Thrd_safe_Stem.251 = "PERFORM RESETTIME "                      04790074
  Rv_non_Thrd_safe_Stem.252 = "SIGNON "                                 04800074
  Rv_non_Thrd_safe_Stem.253 = "SIGNOFF "                                04810074
  Rv_non_Thrd_safe_Stem.254 = "VERIFY PASSWORD "                        04820074
  Rv_non_Thrd_safe_Stem.255 = "CHANGE PASSWORD "                        04830074
  Rv_non_Thrd_safe_Stem.256 = "PERFORM SHUTDOWN "                       04840074
  Rv_non_Thrd_safe_Stem.257 = "INQUIRE TRACEDEST "                      04850074
  Rv_non_Thrd_safe_Stem.258 = "SET TRACEDEST "                          04860074
  Rv_non_Thrd_safe_Stem.259 = "INQUIRE TRACEFLAG "                      04870074
  Rv_non_Thrd_safe_Stem.260 = "SET TRACEFLAG "                          04880074
  Rv_non_Thrd_safe_Stem.261 = "INQUIRE TRACETYPE "                      04890074
  Rv_non_Thrd_safe_Stem.262 = "SET TRACETYPE "                          04900074
  Rv_non_Thrd_safe_Stem.263 = "INQUIRE DSNAME "                         04910074
  Rv_non_Thrd_safe_Stem.264 = "SET DSNAME "                             04920074
  Rv_non_Thrd_safe_Stem.265 = "INQUIRE EXCI "                           04930074
  Rv_non_Thrd_safe_Stem.266 = "PERFORM DUMP "                           04940074
  Rv_non_Thrd_safe_Stem.267 = "INQUIRE TSQUEUE "                        04950074
  Rv_non_Thrd_safe_Stem.268 = "SET TSQUEUE "                            04960074
  Rv_non_Thrd_safe_Stem.269 = "INQUIRE TSQNAME "                        04970074
  Rv_non_Thrd_safe_Stem.270 = "SET TSQNAME "                            04980074
  Rv_non_Thrd_safe_Stem.271 = "INQUIRE TSPOOL "                         04990074
  Rv_non_Thrd_safe_Stem.272 = "INQUIRE TSMODEL "                        05000074
  Rv_non_Thrd_safe_Stem.273 = "DISCARD TSMODEL "                        05010074
  Rv_non_Thrd_safe_Stem.274 = "ACQUIRE TERMINAL "                       05020074
  Rv_non_Thrd_safe_Stem.275 = "INQUIRE REQID "                          05030074
  Rv_non_Thrd_safe_Stem.276 = "WRITE MESSAGE "                          05040074
  Rv_non_Thrd_safe_Stem.277 = "INQUIRE UOW "                            05050074
  Rv_non_Thrd_safe_Stem.278 = "SET UOW "                                05060074
  Rv_non_Thrd_safe_Stem.279 = "CREATE CONNECTION "                      05070074
  Rv_non_Thrd_safe_Stem.280 = "INQUIRE ENQ "                            05080074
  Rv_non_Thrd_safe_Stem.281 = "INQUIRE UOWLINK "                        05090074
  Rv_non_Thrd_safe_Stem.282 = "SET UOWLINK "                            05100074
  Rv_non_Thrd_safe_Stem.283 = "INQUIRE UOWDSNFAIL "                     05110074
  Rv_non_Thrd_safe_Stem.284 = "INQUIRE ENQMODEL "                       05120074
  Rv_non_Thrd_safe_Stem.285 = "SET ENQMODEL "                           05130074
  Rv_non_Thrd_safe_Stem.286 = "DISCARD ENQMODEL "                       05140074
  Rv_non_Thrd_safe_Stem.287 = "INQUIRE JOURNALMODEL "                   05150074
  Rv_non_Thrd_safe_Stem.288 = "DISCARD JOURNALMODEL "                   05160074
  Rv_non_Thrd_safe_Stem.289 = "INQUIRE STREAMNAME "                     05170074
  Rv_non_Thrd_safe_Stem.290 = "INQUIRE PROCESSTYPE "                    05180074
  Rv_non_Thrd_safe_Stem.291 = "SET PROCESSTYPE "                        05190074
  Rv_non_Thrd_safe_Stem.292 = "DISCARD PROCESSTYPE "                    05200074
  Rv_non_Thrd_safe_Stem.293 = "INQUIRE ACTIVITYID "                     05210074
  Rv_non_Thrd_safe_Stem.294 = "INQUIRE CONTAINER "                      05220074
  Rv_non_Thrd_safe_Stem.295 = "INQUIRE EVENT "                          05230074
  Rv_non_Thrd_safe_Stem.296 = "INQUIRE PROCESS "                        05240074
  Rv_non_Thrd_safe_Stem.297 = "STARTBROWSE ACTIVITY "                   05250074
  Rv_non_Thrd_safe_Stem.298 = "GETNEXT ACTIVITY "                       05260074
  Rv_non_Thrd_safe_Stem.299 = "GETNEXT EVENT "                          05270074
  Rv_non_Thrd_safe_Stem.300 = "GETNEXT PROCESS "                        05280074
  Rv_non_Thrd_safe_Stem.301 = "GETNEXT TIMER "                          05290074
  Rv_non_Thrd_safe_Stem.302 = "STARTBROWSE EVENT "                      05300074
  Rv_non_Thrd_safe_Stem.303 = "STARTBROWSE PROCESS "                    05310074
  Rv_non_Thrd_safe_Stem.304 = "INQUIRE TIMER "                          05320074
  Rv_non_Thrd_safe_Stem.305 = "STARTBROWSE TIMER "                      05330074
  Rv_non_Thrd_safe_Stem.306 = "INQUIRE CFDTPOOL "                       05340074
  Rv_non_Thrd_safe_Stem.307 = "INQUIRE REQUESTMODEL "                   05350074
  Rv_non_Thrd_safe_Stem.308 = "DISCARD REQUESTMODEL "                   05360074
  Rv_non_Thrd_safe_Stem.309 = "INQUIRE TCPIPSERVICE "                   05370074
  Rv_non_Thrd_safe_Stem.310 = "SET TCPIPSERVICE "                       05380074
  Rv_non_Thrd_safe_Stem.311 = "DISCARD TCPIPSERVICE "                   05390074
  Rv_non_Thrd_safe_Stem.312 = "INQUIRE TCPIP "                          05400074
  Rv_non_Thrd_safe_Stem.313 = "SET TCPIP "                              05410074
  Rv_non_Thrd_safe_Stem.314 = "INQUIRE WEB "                            05420074
  Rv_non_Thrd_safe_Stem.315 = "SET WEB "                                05430074
  Rv_non_Thrd_safe_Stem.316 = "INQUIRE JVMPOOL "                        05440074
  Rv_non_Thrd_safe_Stem.317 = "SET JVMPOOL "                            05450074
  Rv_non_Thrd_safe_Stem.318 = "INQUIRE JVMPROFILE "                     05460074
  Rv_non_Thrd_safe_Stem.319 = "INQUIRE CLASSCACHE "                     05470074
  Rv_non_Thrd_safe_Stem.320 = "SET CLASSCACHE "                         05480074
  Rv_non_Thrd_safe_Stem.321 = "PERFORM CLASSCACHE "                     05490074
  Rv_non_Thrd_safe_Stem.322 = "INQUIRE JVM "                            05500074
  Rv_non_Thrd_safe_Stem.323 = "INQUIRE CORBASERVER "                    05510074
  Rv_non_Thrd_safe_Stem.324 = "SET CORBASERVER "                        05520074
  Rv_non_Thrd_safe_Stem.325 = "PERFORM CORBASERVER "                    05530074
  Rv_non_Thrd_safe_Stem.326 = "DISCARD CORBASERVER "                    05540074
  Rv_non_Thrd_safe_Stem.327 = "INQUIRE DJAR "                           05550074
  Rv_non_Thrd_safe_Stem.328 = "PERFORM DJAR "                           05560074
  Rv_non_Thrd_safe_Stem.329 = "DISCARD DJAR "                           05570074
  Rv_non_Thrd_safe_Stem.330 = "INQUIRE BEAN "                           05580074
  Rv_non_Thrd_safe_Stem.331 = "INQUIRE BRFACILITY "                     05590074
  Rv_non_Thrd_safe_Stem.332 = "SET BRFACILITY "                         05600074
  Rv_non_Thrd_safe_Stem.333 = "INQUIRE DISPATCHER "                     05610074
  Rv_non_Thrd_safe_Stem.334 = "SET DISPATCHER "                         05620074
  Rv_non_Thrd_safe_Stem.335 = "INQUIRE MVSTCB "                         05630074
                                                                        05640072
  Rv_non_Thrd_safe_Stem.0   = 335                                       05641083
                                                                        05642085
  Rv_NT_Exception_Stem.1   = "CANCEL ABEND   "                          05642197
                                                                        05642297
  Rv_NT_Exception_Stem.0    = 1                                         05642397
                                                                        05642497
  Rv_MQ_Verbs_Stem.1        = "'MQCONN'"                                05643085
  Rv_MQ_Verbs_Stem.2        = "'MQDISC'"                                05644085
  Rv_MQ_Verbs_Stem.3        = "'MQOPEN'"                                05645085
  Rv_MQ_Verbs_Stem.4        = "'MQCLOSE'"                               05646085
  Rv_MQ_Verbs_Stem.5        = "'MQGET'"                                 05647085
  Rv_MQ_Verbs_Stem.6        = "'MQPUT'"                                 05648085
  Rv_MQ_Verbs_Stem.7        = "'MQPUT1'"                                05649085
  Rv_MQ_Verbs_Stem.8        = "'MQINQ'"                                 05649185
                                                                        05649285
  Rv_MQ_Verbs_Stem.0        = 8                                         05649387
                                                                        05649485
Return                                                                  05650072
                                                                        05660072
                                                                        05670072
                                                                        05680072
/*--------------------------------------------------------------------*/05690072
/* Main Process                                                       */05700072
/*--------------------------------------------------------------------*/05710072
                                                                        05720072
MainProcess:                                                            05730072
/*-------*/                                                             05740072
                                                                        05750072
  Say 'PARSEREN: '                                                      05760072
  Say 'PARSEREN: Entering MainProcess: subroutine'                      05770072
  Say 'PARSEREN: '                                                      05780072
                                                                        05790072
  Rf_Proc_Div_Start = 0                                                 05791099
                                                                        05792099
  Do  While Rv_End_File = 0                                             05800072
                                                                        05810072
      Call  Read_Input_Record                                           05820072
                                                                        05830072
      If  Rv_End_File Then                                              05840072
      Do                                                                05850072
          Leave                                                         05860072
      End                                                               05870072
                                                                        05880072
      If  substr(Rv_Input_Record,7,1) = '*' Then                        05890072
      Do                                                                05900072
          Iterate                                                       05910072
      End                                                               05920072
                                                                        05930072
      If  Find(Rv_Input_Record, "PROCEDURE DIVISION") > 0  ,            05930199
       |  Find(Rv_Input_Record, "PROCEDURE DIVISION.") > 0 Then         05930299
      Do                                                                05930399
          Rf_Proc_Div_Start = 1                                         05930499
      End                                                               05930799
                                                                        05930899
      If  Rf_Proc_Div_Start = 0 Then                                    05931099
      Do                                                                05931199
          Iterate                                                       05931299
      End                                                               05931399
                                                                        05932099
      Call  Process_Record                                              05940072
                                                                        05950072
  End                                                                   05960072
                                                                        05970072
  Call  Write_Parsing_Report                                            05980072
                                                                        05990072
  Call  Write_ThreadSafe_Report                                         05991082
                                                                        05992082
Return                                                                  06000072
                                                                        06010072
                                                                        06020072
/*--------------------------------------------------------------------*/06030072
/* Process the input record                                           */06040072
/*--------------------------------------------------------------------*/06050072
                                                                        06060072
Process_Record:                                                         06070072
/*------------*/                                                        06080072
                                                                        06090072
  Say 'PARSEREN: '                                                      06100072
  Say 'PARSEREN: Entering Process_Record: subroutine'                   06110072
  Say 'PARSEREN: '                                                      06120072
                                                                        06130072
  Rv_EXEC_SQL_Pos = Find(Rv_Input_Record,"EXEC SQL")                    06140085
                                                                        06150072
  If  Rv_EXEC_SQL_Pos > 0 Then                                          06150185
  Do                                                                    06150285
      Rf_Db2_Present   = 1                                              06150385
  End                                                                   06150485
                                                                        06150585
  If  Rf_MQ_Present = 0 Then                                            06150687
  Do                                                                    06150787
      Call Check_For_MQ_Calls                                           06150887
  End                                                                   06150987
                                                                        06151087
  Rv_EXEC_pos = Find(Rv_Input_Record,"EXEC CICS")                       06151185
                                                                        06152085
  If  Rv_EXEC_pos > 0 Then                                              06160072
  Do                                                                    06170072
      Rv_Start_Record_No = Rv_Record_No                                 06180072
                                                                        06190072
      Rf_Complete_command = 1                                           06200072
                                                                        06210072
      Call  Parse_EXEC_CICS                                             06220072
                                                                        06230072
      If  Rf_Complete_command Then                                      06240072
      Do                                                                06250072
          Call  Analyse_EXEC_CICS                                       06260072
      End                                                               06270072
                                                                        06280072
      Else Do                                                           06290072
          Rv_Out_Recod  = '*!!* Error **** Incomplete CICS command',    06300072
              'found at '  Rv_Start_Record_No '.'                       06310072
                                                                        06320072
          Call  Write_Out_Record                                        06330072
                                                                        06340072
          Call  Store_error                                             06350072
                                                                        06360072
          Rv_Out_Recod  = 'It is not possible to analyse this' ,        06370072
                          'command.'                                    06380072
          Call  Write_Out_Record                                        06390072
                                                                        06400072
          Rv_Out_Recod   = 'Please correct this and re-submit.'         06410072
          Call  Write_Out_Record                                        06420072
      End                                                               06430072
                                                                        06440072
  End                                                                   06450072
  Else Do                                                               06460072
      Call  Check_For_COBOL_Verbs                                       06470072
      Call  Check_For_COBOL_Calls                                       06471085
  End                                                                   06480072
                                                                        06490072
Return                                                                  06500072
                                                                        06510072
/*--------------------------------------------------------------------*/06520072
/*  Process EXEC CICS - read and accumulate to END-EXEC.              */06530072
/*  If we Find "EXEC CICS in here, there is a missing                 */06540072
/*  END-EXEC somewhere.                                               */06550072
/*--------------------------------------------------------------------*/06560072
                                                                        06570072
Parse_EXEC_CICS:                                                        06580072
/*-------------*/                                                       06590072
                                                                        06600072
  Say 'PARSEREN: '                                                      06610072
  Say 'PARSEREN: Entering Parse_EXEC_CICS: subroutine'                  06620072
  Say 'PARSEREN: '                                                      06630072
                                                                        06640072
  If  Words(Rv_Input_Record) < Rv_EXEC_pos + 2 Then                     06650072
  Do                                                                    06660072
      Rv_CICS_Statement = ''                                            06670072
  End                                                                   06680072
  Else Do                                                               06690072
      Rv_Temp_Record = SubWord(Rv_Input_Record , (Rv_EXEC_pos + 2) )    06700072
      Rv_End_EXEC_Pos = Pos("END-EXEC",Rv_Temp_Record)                  06710072
      If  Rv_End_EXEC_Pos > 0 Then                                      06720072
      Do                                                                06730072
          Rv_CICS_Statement = ,                                         06740072
                 SubStr(Rv_Temp_Record, 1 ,(Rv_End_EXEC_Pos - 1) )      06750072
          Call   Regularise_EXEC_CICS                                   06760072
         Return                                                         06770072
      End                                                               06780072
      Else Do                                                           06790072
         Rv_CICS_Statement =  Rv_Temp_Record                            06800072
      End                                                               06810072
  End                                                                   06820072
                                                                        06830072
  Rf_Read_End = 0                                                       06840072
                                                                        06850072
  Say 'Statement : ' Rv_CICS_Statement                                  06860072
                                                                        06870072
  Do  Until Rf_Read_End                                                 06880072
                                                                        06890072
      Call  Read_Input_Record                                           06900072
                                                                        06910072
      Say 'Inp Record: ' Rv_Input_Record                                06920072
                                                                        06930072
      If  Rv_End_File Then                                              06940072
      Do                                                                06950072
          Rf_Complete_command = 0                                       06960072
         Return                                                         06970072
      End                                                               06980072
                                                                        06990072
      Rv_EXEC_pos = Find(Rv_Input_Record, "EXEC CICS" )                 07000072
                                                                        07010072
      If  Rv_EXEC_pos > 0 Then                                          07020072
      Do                                                                07030072
          Rv_Out_Recod  = '*!!* Error. Consecutive EXEC CICS commands ',07040072
                   'with no END-EXEC in between.'                       07050072
          Call  Write_Out_Record                                        07060072
                                                                        07070072
          Call  Store_error                                             07080072
                                                                        07090072
          Rv_Out_Recod  = '            Analysis will be incomplete. '   07100072
          Call  Write_Out_Record                                        07110072
                                                                        07120072
          Rv_Out_Recod  = '            Preprocessor will reject this ', 07130072
                  'so please correct before re-submission.'             07140072
                                                                        07150072
          Call  Write_Out_Record                                        07160072
      End                                                               07170072
                                                                        07180072
      Rv_End_EXEC_pos = Pos("END-EXEC",Rv_Input_Record)                 07190072
                                                                        07200072
      If  Rv_End_EXEC_pos = 0 Then                                      07210072
      Do                                                                07220072
          Rv_CICS_Statement = Rv_CICS_Statement Rv_Input_Record         07230072
          Say 'st1:  ' Rv_CICS_Statement                                07240072
      End                                                               07250072
      Else Do                                                           07260072
          Rf_Read_End = 1                                               07270072
          Rv_Temp_Record =  ,                                           07280072
                      SubStr(Rv_Input_Record,1,(Rv_End_EXEC_pos - 1))   07290072
                                                                        07300072
          If  Words(Rv_Temp_Record) > 0 Then                            07310072
          Do                                                            07320072
              Rv_CICS_Statement = Rv_CICS_Statement Rv_Temp_Record      07330072
          End                                                           07340072
          Say 'st2:  ' Rv_CICS_Statement                                07350072
      End                                                               07360072
  End                                                                   07370072
                                                                        07380072
          Say 'st3:  ' Rv_CICS_Statement                                07390072
  Call  Regularise_EXEC_CICS                                            07400072
                                                                        07410072
Return                                                                  07420072
                                                                        07430072
/*--------------------------------------------------------------------*/07440072
/*  Regularise statement format and simplify for processing           */07450072
/*--------------------------------------------------------------------*/07460072
                                                                        07470072
Regularise_EXEC_CICS:                                                   07480072
/*------------------*/                                                  07490072
                                                                        07500072
  Say 'PARSEREN: '                                                      07510072
  Say 'PARSEREN: Entering Regularise_EXEC_CICS: subroutine'             07520072
  Say 'PARSEREN: '                                                      07530072
                                                                        07540072
  Rv_New_String = ''                                                    07550072
  Rf_All_Found = 0                                                      07560072
                                                                        07570072
  Do  Until Rf_All_Found                                                07580072
      Rv_Open_Bracket_Pos = pos("(",Rv_CICS_Statement)                  07590072
                                                                        07600072
      If  Rv_Open_Bracket_Pos = 0 Then                                  07610072
      Do                                                                07620072
          Rf_All_Found = 1                                              07630072
      End                                                               07640072
      Else Do                                                           07650072
          PARSE VALUE Rv_CICS_Statement WITH Rv_Before "(" ,            07660072
                                             Rv_CICS_Statement          07670072
                                                                        07680072
          Rv_New_String = Rv_New_String Strip(Rv_Before) "("            07690072
                                                                        07700072
          PARSE VALUE Rv_CICS_Statement WITH Rv_Before ")" ,            07710072
                                             Rv_CICS_Statement          07720072
                                                                        07730072
          Rv_New_String = Rv_New_String || Rv_Before || ")"             07740072
      End                                                               07750072
   End                                                                  07760072
                                                                        07770072
   Rv_New_String = Rv_New_String strip(Rv_CICS_Statement)               07780072
                                                                        07790072
   Rv_CICS_Statement = ''                                               07800072
                                                                        07810072
   Rv_No_Words = Words(Rv_New_String)                                   07820072
   Do  Rv_W_Ctr = 1 To Rv_No_Words                                      07830072
       Rv_CICS_Statement = Rv_CICS_Statement ||  ,                      07840072
                           ' ' || Word(Rv_New_String, Rv_W_Ctr)         07850072
   End                                                                  07860072
                                                                        07870072
Return                                                                  07880072
                                                                        07890072
                                                                        07900072
/*--------------------------------------------------------------------*/07910072
/*  Analyse CICS statement by type (and subtype If necessary          */07920072
/*--------------------------------------------------------------------*/07930072
                                                                        07940072
Analyse_EXEC_CICS:                                                      07950072
/*---------------*/                                                     07960072
                                                                        07970072
  Say 'PARSEREN: '                                                      07980072
  Say 'PARSEREN: Entering Analyse_EXEC_CICS: subroutine'                07990072
  Say 'PARSEREN: '                                                      08000072
                                                                        08010072
  Parse var Rv_CICS_Statement Rv_CICS_Verb Rv_CICS_Parameters           08020072
                                                                        08030072
  Rv_Verb_Qualifier = word(Rv_CICS_Parameters,1)                        08040072
                                                                        08050072
  /*------------------------------------------------------------*/      08060072
  /*  General checks - use of NOHANDLE                          */      08070072
  /*------------------------------------------------------------*/      08080072
                                                                        08090072
  If  Find(Rv_CICS_Statement,'NOHANDLE') > 0 Then                       08100072
  Do                                                                    08110072
      If  Find(Rc_No_Resp_Verbs,Rv_CICS_Verb) = 0 Then                  08120072
      Do                                                                08130072
          Rv_Out_Recod  = '*!!* Error **** - NOHANDLE must be' ,        08140072
                         'replaced by RESP'                             08150072
          Call  Write_Out_Record                                        08160072
          Call  Store_error                                             08170072
       End                                                              08180072
       Else Do                                                          08190072
          Rv_Out_Recod  = ,                                             08200072
            '*!!* Warning **** - NOHANDLE / RESP have no effect on ',   08210072
              COMMAND Rv_Verb_Qualifier                                 08220072
          Call  Write_Out_Record                                        08230072
          Call  Store_warning                                           08240072
       End                                                              08250072
  End                                                                   08260072
                                                                        08270072
  /*------------------------------------------------------------*/      08280072
  /*  General checks - SYSID (apart from ASSIGN SYSID)          */      08290072
  /*------------------------------------------------------------*/      08300072
  If  Rv_CICS_Verb <> 'ASSIGN' Then                                     08310072
  Do                                                                    08320072
      Call  Get_argument 'SYSID' Rv_CICS_Statement                      08330072
      Rv_Arg_Result     = result                                        08340072
      If  Rv_Arg_Result <> ' ' Then                                     08350072
      Do                                                                08360072
          Rv_Out_Recod  = '*!!* Error **** - SYSID must not be' ,       08370072
                          'specified'                                   08380072
          Call  Write_Out_Record                                        08390072
          Call  Store_error                                             08400072
       End                                                              08410072
  End                                                                   08420072
                                                                        08430072
  /*------------------------------------------------------------*/      08440072
  /*  Checks to be applied to specific commands or groups       */      08450072
  /*------------------------------------------------------------*/      08460072
  Select                                                                08470072
    When  Find(Rc_Banned_Berbs, Rv_CICS_Verb) > 0 Then                  08480072
      Do                                                                08490072
          Rv_Out_Recod  = '*!!* Error **** - COMMAND ' Rv_CICS_Verb ,   08500072
                       ' not allowed'                                   08510072
          Call  Write_Out_Record                                        08520072
          Call  Store_error                                             08530072
     End                                                                08540072
                                                                        08550072
    When  Rv_CICS_Verb = "ABEND" Then                                   08560072
      Do                                                                08570072
          Rv_Out_Recod  = '*!!* Warning **** - ABEND should only',      08580099
           'be used where it is not possible to'                        08590097
          Call  Write_Out_Record                                        08600072
          Rv_Out_Recod  = '                    communicate back to',    08601099
           'the initiating program, examples include'                   08602097
          Call  Write_Out_Record                                        08603097
          Rv_Out_Recod  = '                    invalid or absent',      08604099
           'COMMAREAs, no CHANNEL received or'                          08605097
          Call  Write_Out_Record                                        08606097
          Rv_Out_Recod  = '                    unable to PUT',          08607099
           'a CONTAINER.'                                               08608097
          Call  Write_Out_Record                                        08609097
          Call  Store_warning                                           08610072
     End                                                                08620072
                                                                        08630072
    When  Rv_CICS_Verb = "WRITE" Then                                   08640072
      Do                                                                08650072
          If  Rv_Verb_Qualifier = 'OPERATOR' Then                       08660072
          Do                                                            08670072
              Rv_Out_Recod  = '*!!* Warning **** - WRITE OPERATOR',     08680072
                              'must only'                               08690072
              Call  Write_Out_Record                                    08700072
              Rv_Out_Recod  =  '                   be used via SPZCERR.'08710099
              Call  Write_Out_Record                                    08720072
              Call  Store_warning                                       08730072
         End                                                            08740072
     End                                                                08750072
                                                                        08760072
    When  Rv_CICS_Verb = "SYNCPOINT" Then                               08770072
      Do                                                                08780072
          Call  Get_argument 'RESP' Rv_CICS_Statement                   08790072
          Rv_Arg_Result     = result                                    08800072
          If  Rv_Arg_Result <> ' ' ,                                    08810072
           &  Rv_Arg_Result <> 'ROLLBACK' Then                          08820072
          Do                                                            08830072
              Rv_Out_Recod  = '*!!* Error **** - SYNCPOINT' ,           08840072
                              'failure must '                           08850072
              Call  Write_Out_Record                                    08860072
              Rv_Out_Recod  = '                   ' ,                   08870072
                           'not be trapped.  Allow it to ABEND.'        08880072
              Call  Write_Out_Record                                    08890072
              Call  Store_error                                         08900072
          End                                                           08910072
     End                                                                08920072
                                                                        08930072
    When  Rv_CICS_Verb = "RETURN" Then                                  08940072
      Do                                                                08950072
          Rf_Check_Resp = 0                                             08960072
          Call  Get_argument 'COMMAREA' Rv_CICS_Statement               08970072
          Rv_Arg_Result     = result                                    08980072
          If  Rv_Arg_Result <> ' ' Then                                 08990072
          Do                                                            09000072
              Rf_Check_Resp = 1                                         09010072
          End                                                           09020072
                                                                        09030072
          Call  Get_argument 'TRANSID' Rv_CICS_Statement                09040072
          Rv_Arg_Result     = result                                    09050072
                                                                        09060072
          If  Rv_Arg_Result <> ' ' Then                                 09070072
          Do                                                            09080072
              Rf_Check_Resp = 1                                         09090072
          End                                                           09100072
                                                                        09110072
          Call  Get_argument 'INPUTMSG' Rv_CICS_Statement               09120072
          Rv_Arg_Result     = result                                    09130072
          If  Rv_Arg_Result <> ' ' Then                                 09140072
          Do                                                            09150072
              Rf_Check_Resp = 1                                         09160072
          End                                                           09170072
                                                                        09180072
          Call  Get_argument 'ENDACTIVITY' Rv_CICS_Statement            09190072
          Rv_Arg_Result     = result                                    09200072
          If  Rv_Arg_Result <> ' ' Then                                 09210072
          Do                                                            09220072
              Rf_Check_Resp = 1                                         09230072
          End                                                           09240072
                                                                        09250072
          If  Rf_Check_Resp Then                                        09260072
          Do                                                            09270072
              Call  Check_resp                                          09280072
          End                                                           09290072
     End                                                                09300072
                                                                        09310072
    When  Rv_CICS_Verb = "LINK" Then                                    09320072
      Do                                                                09330072
          Call  Get_argument 'TRANSID' Rv_CICS_Statement                09340072
          Rv_Arg_Result     = result                                    09350072
          If  Rv_Arg_Result <> ' ' Then                                 09360072
          Do                                                            09370072
              Rv_Out_Recod  = ,                                         09380072
              '*!!* Error **** - TRANSID must not be specified on LINK' 09390072
                                                                        09400072
              Call  Write_Out_Record                                    09410072
              Call  Store_error                                         09420072
          End                                                           09430072
                                                                        09440072
          If  Find(Rv_CICS_Statement,'SYNCONRETURN') > 0 Then           09450072
          Do                                                            09460072
              Rv_Out_Recod  = '*!!* Error **** - SYNCONRETURN' ,        09470072
                      ' must not be specified on LINK'                  09480072
              Call  Write_Out_Record                                    09490072
              Call  Store_error                                         09500072
          End                                                           09510072
     End                                                                09520072
                                                                        09530072
    When  Rv_CICS_Verb = "ASSIGN" Then                                  09540072
      Do                                                                09550072
          Parse VALUE Rv_Verb_Qualifier WITH Rv_Object '(' Rv_Rest      09560072
          If  Find(Rc_No_Resp_Assigns,Rv_Object) = 0 Then               09570072
          Do                                                            09580072
              Call  Check_resp                                          09590072
          End                                                           09600072
          Else Do                                                       09610072
              If  Find(Rc_No_Resp_Queries,Rv_Object) > 0 Then           09620072
              Do                                                        09630072
                  Rv_Out_Recod  = '*!!* Warning **** - check that' ,    09640072
                  'the ASSIGN option is really needed!'                 09650072
                  Call  Write_Out_Record                                09660072
                  Call  Store_warning                                   09670072
              End                                                       09680072
          End                                                           09690072
     End                                                                09700072
                                                                        09710072
    When  Rv_CICS_Verb = "FORMATTIME" Then                              09720072
      Do                                                                09730072
          Call  Get_argument 'RESP'                                     09740072
          Rv_Arg_Result     = result                                    09750072
          If  Rv_Arg_Result = ' ' Then                                  09760072
          Do                                                            09770072
              Rv_Out_Recod  = '*!!* Reminder **** - check',             09780072
              'that the value '                                         09790072
              Call  Write_Out_Record                                    09800072
              Rv_Out_Recod  = '                   ' ,                   09810072
               'acquired by ABSTIME has not been changed '              09820072
              Call  Write_Out_Record                                    09830072
              Call  Store_reminder                                      09840072
          End                                                           09850072
     End                                                                09860072
                                                                        09870072
    When  Rv_CICS_Verb = "GETMAIN"  Then                                09880072
      Do                                                                09890072
          If  Find(Rv_CICS_Statement,"NOSUSPEND") = 0 Then              09900072
          Do                                                            09910072
              Rv_Out_Recod  = '*!!* Error **** ' ,                      09920072
                    'GETMAIN must use NOSUSPEND option'                 09930072
              Call  Write_Out_Record                                    09940072
              Call  Store_error                                         09950072
              Call  Check_resp                                          09960072
          End                                                           09970072
     End                                                                09980072
                                                                        09990072
    When  Rv_CICS_Verb = "WRITEQ" Then                                  10000072
      Do                                                                10010072
          If  Rv_Verb_Qualifier = "TS" Then                             10020072
          Do                                                            10030072
             If  Find(Rv_CICS_Statement,'NOSUSPEND') = 0 Then           10040072
             Do                                                         10050072
                 Rv_Out_Recod  = '*!!* Error **** ' ,                   10060072
                      'You MUST code NOSUSPEND with WRITEQ TS, '        10070072
                 Call  Write_Out_Record                                 10080072
                 Rv_Out_Recod  = '                   ' ,                10090072
                     'or you will wait till someone deletes from TS.'   10100072
                 Call  Write_Out_Record                                 10110072
                 Call  Store_error                                      10120072
             End                                                        10130072
                                                                        10140072
             Rv_Out_Recod  = '*!!* Reminder **** ' ,                    10150072
               'If RESP of "NOSPACE" is detected you MUST',             10160072
               'issue DELETEQ '                                         10170072
             Call  Write_Out_Record                                     10180072
             Rv_Out_Recod  = '                   ' ,                    10190072
                             'or the whole region will freeze. '        10200072
             Call  Write_Out_Record                                     10210072
             Call  Store_reminder                                       10220072
             Call  Check_resp                                           10230072
          End                                                           10240072
     End                                                                10250072
                                                                        10260072
    When  Find(Rc_No_Resp_Verbs,Rv_CICS_Verb) > 0 Then                  10270072
      Do                                                                10280072
          NOP                                                           10290072
     End                                                                10300072
                                                                        10310072
    otherwise                                                           10320072
        Call  Check_resp                                                10330072
  End                                                                   10340072
                                                                        10350072
  Call Check_Required_Comd_Parms                                        10360072
                                                                        10370072
  Call Check_Omit_Comd_Parms                                            10380072
                                                                        10390072
  Call Check_For_Threadsafe_Inhibiter                                   10391075
                                                                        10392075
  Call Check_For_Non_Threadsafe_APIs                                    10393075
                                                                        10394075
Return                                                                  10400072
                                                                        10410072
                                                                        10420072
/*--------------------------------------------------------------------*/10430072
/* Check required command parameters                                  */10440072
/*--------------------------------------------------------------------*/10450072
Check_Required_Comd_Parms:                                              10460072
/*-----------------------*/                                             10470072
                                                                        10480072
  Say 'PARSEREN: '                                                      10490072
  Say 'PARSEREN: Entering Check_Required_Comd_Parms: subroutine'        10500072
  Say 'PARSEREN: '                                                      10510072
                                                                        10520072
  Do  Rv_Req_Ctr = 1 To Rv_Req_Cmd_Stem.0                               10530072
                                                                        10540072
      Rv_Curr_Req_Rec =  Rv_Req_Cmd_Stem.Rv_Req_Ctr                     10550072
                                                                        10560072
      Rv_Curr_Req_Parm = Word(Rv_Curr_Req_Rec, 1)                       10570072
                                                                        10580072
      Rv_Curr_Type = Word(Rv_Curr_Req_Rec, 2)                           10590072
                                                                        10600072
      Rv_Loop_Count =   Words(Rv_Curr_Req_Rec)                          10610072
                                                                        10620072
      Rv_CICS_Stmt  = SubWord(Rv_Curr_Req_Rec , 3)                      10630072
                                                                        10640072
      Rf_Look_For_Req_Parm = 1                                          10650072
                                                                        10660072
      Do  Rv_Wrd_Ctr = 3 To Rv_Loop_Count                               10670072
                                                                        10680072
          Rv_Curr_CICS_Verb = Word(Rv_Curr_Req_Rec,Rv_Wrd_Ctr)          10690072
                                                                        10700072
          If  WordPos(Rv_Curr_CICS_Verb , Rv_CICS_Statement) = 0 Then   10710072
          Do                                                            10720072
              Rf_Look_For_Req_Parm = 0                                  10730072
              Leave                                                     10740072
          End                                                           10750072
      End                                                               10760072
                                                                        10770072
      If  Rf_Look_For_Req_Parm  Then                                    10780072
      Do                                                                10790072
          If  WordPos(Rv_Curr_Req_Parm , Rv_CICS_Statement) = 0 Then    10800072
          Do                                                            10810072
                                                                        10820072
              Call Process_Req_Parm_Error                               10830072
                                                                        10840072
          End                                                           10850072
      End                                                               10860072
  End                                                                   10870072
                                                                        10880072
                                                                        10890072
Return                                                                  10900072
                                                                        10910072
                                                                        10920072
/*--------------------------------------------------------------------*/10930072
/* Process Required parameter error                                   */10940072
/*--------------------------------------------------------------------*/10950072
Process_Req_Parm_Error:                                                 10960072
/*--------------------*/                                                10970072
                                                                        10980072
  Say 'PARSEREN: '                                                      10990072
  Say 'PARSEREN: Entering Process_Req_Parm_Error: subroutine'           11000072
  Say 'PARSEREN: '                                                      11010072
                                                                        11020072
  Select                                                                11030072
    When  Rv_Curr_Type = "E" Then                                       11040072
      Do                                                                11050072
          Rv_Out_Recod  = '*!!* Error **** -'  ,                        11060072
                          Rv_Curr_Req_Parm 'must be specified on ' ,    11070072
                          Rv_CICS_Stmt                                  11080072
          Call  Write_Out_Record                                        11090072
          Call  Store_error                                             11100072
                                                                        11110072
                                                                        11120072
     End                                                                11130072
                                                                        11140072
    When  Rv_Curr_Type = "W" Then                                       11150072
      Do                                                                11160072
          Rv_Out_Recod  = '*!!* Warning **** - '  ,                     11170099
                          Rv_Curr_Req_Parm 'may be required on ' ,      11180072
                          Rv_CICS_Stmt                                  11190072
          Call  Write_Out_Record                                        11200072
          Call  Store_warning                                           11210072
                                                                        11220072
     End                                                                11230072
                                                                        11240072
    Otherwise                                                           11250072
                                                                        11260072
           Rv_Out_Recod  = '*!!* Reminder **** - ' ,                    11270099
                           Rv_Curr_Req_Parm 'might be required on ' ,   11280072
                           Rv_CICS_Stmt                                 11290072
          Call  Write_Out_Record                                        11300072
          Call  Store_reminder                                          11310072
                                                                        11320072
  End                                                                   11330072
                                                                        11340072
Return                                                                  11350072
                                                                        11360072
                                                                        11370072
/*--------------------------------------------------------------------*/11380072
/* Check must omit command parameters                                 */11390072
/*--------------------------------------------------------------------*/11400072
Check_Omit_Comd_Parms:                                                  11410072
/*-------------------*/                                                 11420072
                                                                        11430072
  Say 'PARSEREN: '                                                      11440072
  Say 'PARSEREN: Entering Check_Omit_Comd_Parms: subroutine'            11450072
  Say 'PARSEREN: '                                                      11460072
                                                                        11470072
  Do  Rv_Omt_Ctr = 1 To Rv_Omit_Cmd_Stem.0                              11480072
                                                                        11490072
      Rv_Curr_Omt_Rec =  Rv_Omit_Cmd_Stem.Rv_Omt_Ctr                    11500072
                                                                        11510072
      Rv_Curr_Omt_Parm = Word(Rv_Curr_Omt_Rec, 1)                       11520072
                                                                        11530072
      Rv_Curr_Type = Word(Rv_Curr_Omt_Rec, 2)                           11540072
                                                                        11550072
      Rv_Loop_Count =   Words(Rv_Curr_Omt_Rec)                          11560072
                                                                        11570072
      Rv_CICS_Stmt  = SubWord(Rv_Curr_Omt_Rec , 3)                      11580072
                                                                        11590072
      Rf_Look_For_Omt_Parm = 1                                          11600072
                                                                        11610072
      Do  Rv_Wrd_Ctr = 3 To Rv_Loop_Count                               11620072
                                                                        11630072
          Rv_Curr_CICS_Verb = Word(Rv_Curr_Omt_Rec,Rv_Wrd_Ctr)          11640072
                                                                        11650072
          If  WordPos(Rv_Curr_CICS_Verb , Rv_CICS_Statement) = 0 Then   11660072
          Do                                                            11670072
              Rf_Look_For_Omt_Parm = 0                                  11680072
              Leave                                                     11690072
          End                                                           11700072
      End                                                               11710072
                                                                        11720072
      If  Rf_Look_For_Omt_Parm  Then                                    11730072
      Do                                                                11740072
          If  WordPos(Rv_Curr_Omt_Parm , Rv_CICS_Statement) ^= 0 Then   11750072
          Do                                                            11760072
              Call Process_Omit_Parm_Error                              11770072
                                                                        11780072
          End                                                           11790072
      End                                                               11800072
  End                                                                   11810072
                                                                        11820072
                                                                        11830072
Return                                                                  11840072
                                                                        11850072
                                                                        11860072
/*--------------------------------------------------------------------*/11870072
/* Process must omit parameter error                                  */11880072
/*--------------------------------------------------------------------*/11890072
Process_Omit_Parm_Error:                                                11900072
/*---------------------*/                                               11910072
                                                                        11920072
  Say 'PARSEREN: '                                                      11930072
  Say 'PARSEREN: Entering Process_Omit_Parm_Error: subroutine'          11940072
  Say 'PARSEREN: '                                                      11950072
                                                                        11960072
  Select                                                                11970072
    When  Rv_Curr_Type = "E" Then                                       11980072
      Do                                                                11990072
          Rv_Out_Recod  = '*!!* Error **** -'  ,                        12000072
                          Rv_Curr_Omt_Parm 'must not be specified on ' ,12010072
                          Rv_CICS_Stmt                                  12020072
          Call  Write_Out_Record                                        12030072
          Call  Store_error                                             12040072
                                                                        12050072
                                                                        12060072
     End                                                                12070072
                                                                        12080072
    When  Rv_Curr_Type = "W" Then                                       12090072
      Do                                                                12100072
          Rv_Out_Recod  = '*!!* Warning **** - '  ,                     12110099
                          Rv_Curr_Omt_Parm 'may have some implications',12120099
                                           'using with',                12121099
                          Rv_CICS_Stmt                                  12130072
          Call  Write_Out_Record                                        12140072
          Call  Store_warning                                           12150072
                                                                        12160072
     End                                                                12170072
                                                                        12180072
    Otherwise                                                           12190072
                                                                        12200072
           Rv_Out_Recod  = '*!!* Reminder **** - ' ,                    12210099
                      Rv_Curr_Omt_Parm 'might have some implications',  12241099
                                           'using with',                12241199
                           Rv_CICS_Stmt                                 12242099
          Call  Store_reminder                                          12250072
          Call  Write_Out_Record                                        12251099
                                                                        12260072
  End                                                                   12270072
                                                                        12280072
Return                                                                  12290072
                                                                        12300072
/*--------------------------------------------------------------------*/12301075
/* Check for any Threadsafe Inhibiter CICS APIs                       */12302075
/*--------------------------------------------------------------------*/12303075
Check_For_Threadsafe_Inhibiter:                                         12304075
/*----------------------------*/                                        12305075
                                                                        12305175
  Say 'PARSEREN: '                                                      12306075
  Say 'PARSEREN: Entering Check_For_Threadsafe_Inhibiter: subroutine'   12307075
  Say 'PARSEREN: '                                                      12308075
                                                                        12308175
  Do  Rv_Inh_Ctr = 1 To Rv_Thrd_Safe_inh_Stem.0                         12309075
                                                                        12309175
      Rv_Curr_Inh_Rec =  Rv_Thrd_Safe_inh_Stem.Rv_Inh_Ctr               12309275
      Rv_Loop_Count =   Words(Rv_Curr_Inh_Rec)                          12309375
      Rv_CICS_Stmt  = Rv_Curr_Inh_Rec                                   12309475
      Rf_Look_For_Inh_Parm = 1                                          12309575
                                                                        12309675
      Do  Rv_Wrd_Ctr = 1 To Rv_Loop_Count                               12309775
          Rv_Curr_CICS_Verb = Word(Rv_Curr_Inh_Rec,Rv_Wrd_Ctr)          12309875
          If  WordPos(Rv_Curr_CICS_Verb , Rv_CICS_Statement) = 0 Then   12309975
          Do                                                            12310075
              Rf_Look_For_Inh_Parm = 0                                  12310175
              Leave                                                     12310275
          End                                                           12310375
      End                                                               12310475
      If  Rf_Look_For_Inh_Parm  Then                                    12310575
      Do                                                                12310675
                                                                        12310775
          Rv_Out_Recod  = '*!!* Error **** - ',                         12310884
                          'must avoid threadsafe inhibiter - ',         12310984
                           Rv_CICS_Stmt                                 12311076
          Call  Write_TS_Record                                         12311176
          Call  Store_TS_Error                                          12311276
                                                                        12311376
                                                                        12311476
      End                                                               12311575
  End                                                                   12311675
                                                                        12311775
Return                                                                  12311875
                                                                        12311976
                                                                        12312076
/*--------------------------------------------------------------------*/12312176
/* Check for any non Threadsafe CICS APIs usage                       */12312276
/*--------------------------------------------------------------------*/12312376
Check_For_Non_Threadsafe_APIs:                                          12312476
/*----------------------------*/                                        12312576
                                                                        12312676
  Say 'PARSEREN: '                                                      12312776
  Say 'PARSEREN: Entering Check_For_Non_Threadsafe_APIs: subroutine'    12312876
  Say 'PARSEREN: '                                                      12312976
                                                                        12313076
  Do  Rv_Nta_Ctr = 1 To Rv_non_Thrd_safe_Stem.0                         12313176
                                                                        12313276
      Rv_Curr_Nta_Rec =  Rv_non_Thrd_safe_Stem.Rv_Nta_Ctr               12313376
      Rv_Loop_Count =   Words(Rv_Curr_Nta_Rec)                          12313476
      Rv_CICS_Stmt  = Rv_Curr_Nta_Rec                                   12313576
      Rf_Look_For_Nta_Parm = 1                                          12313676
                                                                        12313776
      if Rv_Curr_Nta_Rec            = 'REWRITE' & ,                     12313777
         word(Rv_CICS_Statement,1) ^= 'REWRITE' then                    12313778
        Rf_Look_For_Nta_Parm = 0                                        12313779
      else                                                              12313780
      Do  Rv_Wrd_Ctr = 1 To Rv_Loop_Count                               12313876
          Rv_Curr_CICS_Verb = Word(Rv_Curr_Nta_Rec,Rv_Wrd_Ctr)          12313976
          If  WordPos(Rv_Curr_CICS_Verb , Rv_CICS_Statement) = 0 Then   12314076
          Do                                                            12314176
              Rf_Look_For_Nta_Parm = 0                                  12314276
              Leave                                                     12314376
          End                                                           12314476
      End                                                               12314576
      If  Rf_Look_For_Nta_Parm  Then                                    12314676
      Do                                                                12314776
          Call Check_For_Exceptions                                     12314997
                                                                        12315676
      End                                                               12315776
      If  Rf_Look_For_Nta_Parm  Then                                    12315897
      Do                                                                12315997
                                                                        12316097
          Rv_Out_Recod  = '*!!* Warning **** - ' ,                      12316197
                          'non-threadsafe API usage - ' ,               12316297
                           Rv_CICS_Stmt                                 12316397
          Call  Write_TS_Record                                         12316499
          Call  Store_TS_Warning                                        12316599
          If  Rv_CICS_Stmt = "LINK PROGRAM "  Then                      12316699
          Do                                                            12316799
              Rv_Out_Recod  = '                    ' ,                  12316899
                              'Please ignore this message ' ,           12316999
                              'if it is a local LINK'                   12317099
              Call  Write_TS_Record                                     12317199
          End                                                           12317299
                                                                        12317397
                                                                        12317497
      End                                                               12317597
  End                                                                   12317697
                                                                        12317797
Return                                                                  12317897
                                                                        12318097
/*--------------------------------------------------------------------*/12320072
/* Check for any ecxeptiond for nonthreadsafe APIs                    */12330097
/*--------------------------------------------------------------------*/12340072
Check_For_Exceptions:                                                   12350097
/*------------------*/                                                  12360097
                                                                        12370072
  Say 'PARSEREN: '                                                      12380072
  Say 'PARSEREN: Entering Check_For_Exceptions: subroutine'             12390097
  Say 'PARSEREN: '                                                      12400072
                                                                        12410072
  Do Rv_the_Ctr = 1 To Rv_NT_Exception_Stem.0                           12420097
                                                                        12430097
      Rv_Curr_the_Rec =  Rv_NT_Exception_Stem.Rv_the_Ctr                12440097
      Rv_Loop_Count =   Words(Rv_Curr_the_Rec)                          12450097
      /*Rv_CICS_Stmt  = Rv_Curr_the_Rec*/                               12460099
                                                                        12461097
      Rf_TS_Exception      = 1                                          12470099
                                                                        12480097
      Do  Rv_Wrd_Ctr = 1 To Rv_Loop_Count                               12490097
          Rv_Curr_CICS_Verb = Word(Rv_Curr_the_Rec,Rv_Wrd_Ctr)          12500097
          If  WordPos(Rv_Curr_CICS_Verb , Rv_CICS_Statement) = 0 Then   12510097
          Do                                                            12511097
              Rf_TS_Exception      = 0                                  12512099
              Leave                                                     12513097
          End                                                           12514097
      End                                                               12515097
                                                                        12515197
      If  Rf_TS_Exception Then                                          12516097
      Do                                                                12517097
          Rf_Look_For_Nta_Parm = 0                                      12519097
      End                                                               12519697
  End                                                                   12520897
                                                                        12520997
                                                                        12521072
Return                                                                  12530072
                                                                        12540072
                                                                        12550072
/*--------------------------------------------------------------------*/12551097
/* Store a warning for End of program listing                         */12552097
/*--------------------------------------------------------------------*/12553097
Check_resp:                                                             12554097
/*--------*/                                                            12555097
                                                                        12556097
  Say 'PARSEREN: '                                                      12557097
  Say 'PARSEREN: Entering Check_resp: subroutine'                       12558097
  Say 'PARSEREN: '                                                      12559097
                                                                        12559197
                                                                        12559297
  Call  Get_argument 'RESP' Rv_CICS_Statement                           12559397
  Rv_Arg_Result     = result                                            12559497
  If  Rv_Arg_Result = ' ' Then                                          12559597
  Do                                                                    12559697
      Rv_Out_Recod  = '*!!* Error **** - COMMAND ',                     12559797
                      Rv_CICS_Verb ' has no RESP'                       12559897
      Call  Write_Out_Record                                            12559997
      Call  Store_error                                                 12560097
  End                                                                   12560197
                                                                        12560297
Return                                                                  12560397
                                                                        12560497
                                                                        12560597
/*--------------------------------------------------------------------*/12561097
/* Extract a keyword and parameter from the statement string.         */12570072
/*--------------------------------------------------------------------*/12580072
Get_argument:                                                           12590072
/*----------*/                                                          12600072
                                                                        12610072
  Say 'PARSEREN: '                                                      12620072
  Say 'PARSEREN: Entering Get_argument: subroutine'                     12630072
  Say 'PARSEREN: '                                                      12640072
                                                                        12650072
  Parse Arg Rv_Inp_Keyword Rv_Inp_String                                12660072
                                                                        12670072
  Rv_getA_pos = Find(Rv_Inp_String,Rv_Inp_Keyword)                      12680072
  If  Rv_getA_pos = 0 Then                                              12690072
  Do                                                                    12700072
     Return ' '                                                         12710072
  End                                                                   12720072
  Else Do                                                               12730072
      Rv_getA_value = Word(Rv_Inp_String,(Rv_getA_pos+1))               12740072
      If  Rv_getA_value = '(' Then                                      12750072
      Do                                                                12760072
          Rv_getA_value = Word(Rv_Inp_String,(Rv_getA_pos+2))           12770072
          Rv_getA_value = Strip(Rv_getA_value,'L','(')                  12780072
          Rv_getA_value = Strip(Rv_getA_value,'T',')')                  12790072
      End                                                               12800072
  End                                                                   12810072
                                                                        12820072
Return Rv_getA_value                                                    12830072
                                                                        12840072
/*--------------------------------------------------------------------*/12850072
/*  Code to read next source code line.                               */12860072
/*--------------------------------------------------------------------*/12870072
                                                                        12880072
                                                                        12890072
Read_Input_Record:                                                      12900072
/*---------------*/                                                     12910072
                                                                        12920072
  Say 'PARSEREN: '                                                      12930072
  Say 'PARSEREN: Entering Read_Input_File: subroutine'                  12940072
  Say 'PARSEREN: '                                                      12950072
                                                                        12960072
  If  Rv_Records_In_Stack = 0 Then Do                                   12970072
      Rc_READ                                                           12980072
      If  RC ^= 0 & RC ^= 2 Then                                        12990072
      Do                                                                13000072
          Rv_Err_Section = "Read_Input_File"                            13010072
          Rv_Err_No      = "MS001"                                      13020072
          Rv_Err_Type    = "D"                                          13030072
                                                                        13040072
          Rv_Err.1 = "Unable to read the input file  - " INFILE         13050072
          Rv_Err.2 = "Return Code from Read is : " RC                   13060072
          Rv_Err.3 = "Can not processing with this Error "              13070072
          Rv_Err.4 = "Process will be terminating         "             13080072
          Rv_Err.0 = 4                                                  13090072
                                                                        13100072
          Call  Process_Error                                           13110072
      End                                                               13120072
                                                                        13130072
      Rv_Records_In_Stack = QUEUED()                                    13140072
  End                                                                   13150072
                                                                        13160072
  If  Rv_Records_In_Stack = 0 Then                                      13170072
  Do                                                                    13180072
      Rv_End_File = 1                                                   13190072
     Return                                                             13200072
  End                                                                   13210072
                                                                        13220072
  Parse Pull Rv_Record_Temp                                             13230072
                                                                        13240072
                                                                        13250072
  Rv_Records_In_Stack  = Rv_Records_In_Stack  - 1                       13260072
                                                                        13270072
  Rv_Record_No         = Rv_Record_No  + 1                              13280072
                                                                        13290072
  /* Snip off possible sequence numbers in columns 1-6 / 73-78 */       13300072
  Rv_Input_Record = "      " || SubStr(Rv_Record_Temp,7,66)             13310072
                                                                        13320072
  Rv_Out_Recod = Format(Rv_Record_No,5) Substr(Rv_Input_Record,7)       13330072
                                                                        13340072
  Upper Rv_Input_Record                                                 13341091
                                                                        13342091
  /*                                                                    13350072
  Rv_Out_Recod = Right(Rv_Record_No,5,'0')    ,                         13360072
                 SubStr(Rv_Input_Record,7)                              13370072
  */                                                                    13380072
                                                                        13380176
  Rf_Write_ThrdSafe_File     = 1                                        13380276
                                                                        13380376
  Call  Write_Out_Record                                                13390072
                                                                        13400072
                                                                        13410072
Return                                                                  13420072
                                                                        13430072
                                                                        13440072
/*--------------------------------------------------------------------*/13450072
/* Check for any COBOL prohibited Verbs                               */13460072
/*--------------------------------------------------------------------*/13470072
                                                                        13480072
                                                                        13481085
/*--------------------------------------------------------------------*/13482085
/* Check for any COBOL prohibited Verbs                               */13483085
/*--------------------------------------------------------------------*/13484085
                                                                        13485085
Check_For_COBOL_Verbs:                                                  13490072
/*-------------------*/                                                 13500072
                                                                        13510072
  Say 'PARSEREN: '                                                      13520072
  Say 'PARSEREN: Entering Check_For_COBOL_Verbs: subroutine'            13530085
  Say 'PARSEREN: '                                                      13540072
                                                                        13550072
  Do  Rv_Cp_Ctr = 1 To Rv_COBOL_Prohibited_Verbs_Stem.0                 13560072
                                                                        13570072
      Rv_COBOL_Prh_Verb =  Rv_COBOL_Prohibited_Verbs_Stem.Rv_Cp_Ctr     13580072
                                                                        13590072
      If  Find(Rv_Input_Record,Rv_COBOL_Prh_Verb) > 0 Then              13600087
      Do                                                                13610087
           Rv_Start_Record_No = Rv_Record_No                            13620087
           Rv_Out_Recod  = ,                                            13630087
             '*!!* Reminder **** - please check context of ' ,          13640087
             '"' || Rv_COBOL_Prh_Verb || '"'                            13650087
                                                                        13660072
           Call  Write_Out_Record                                       13670087
                                                                        13680072
           Rv_Out_Recod  = ,                                            13690087
             '                     Use as a COBOL verb ' ,              13700087
             'is not allowed in CICS '                                  13710087
                                                                        13720072
           Call  Write_Out_Record                                       13730087
                                                                        13740072
           Call  Store_reminder                                         13750087
                                                                        13760072
      End                                                               13770087
  End                                                                   13780072
                                                                        13790072
Return                                                                  13800072
                                                                        13810072
                                                                        13820072
                                                                        13821085
/*--------------------------------------------------------------------*/13822085
/* Check for any COBOL Call present in the program                    */13823085
/*--------------------------------------------------------------------*/13824085
                                                                        13825085
Check_For_COBOL_Calls:                                                  13826085
/*-------------------*/                                                 13827085
                                                                        13828085
  Say 'PARSEREN: '                                                      13829085
  Say 'PARSEREN: Entering Check_For_COBOL_Calls: subroutine'            13829185
  Say 'PARSEREN: '                                                      13829285
                                                                        13829385
  If word(substr(Rv_Input_Record,8,64),1) = 'CALL' Then                 13829885
  Do                                                                    13829985
       Rf_Call_present    = 1                                           13830085
       Rv_Start_Record_No = Rv_Record_No                                13830185
       Rv_Out_Recod  = ,                                                13830285
         "*!!* Warning **** - This program can not be" ,                13830399
         "defined as a thread "                                         13830499
                                                                        13830585
       Call  Write_TS_Record                                            13830685
                                                                        13830785
       Rv_Out_Recod  = ,                                                13830885
         "                     safe program unless all",                13831092
         "the calling programs"                                         13831199
                                                                        13831285
       Call  Write_TS_Record                                            13831385
                                                                        13831485
       Rv_Out_Recod  = ,                                                13831585
         "                     are also thread safe"                    13831792
                                                                        13831885
       Call  Write_TS_Record                                            13831985
                                                                        13832085
       Call  Store_TS_Warning                                           13832185
                                                                        13832285
  End                                                                   13832385
                                                                        13832485
Return                                                                  13832585
                                                                        13832685
                                                                        13832787
/*--------------------------------------------------------------------*/13832887
/* Check for any MQ Call present in the program                       */13832987
/*--------------------------------------------------------------------*/13833087
                                                                        13833187
Check_For_MQ_Calls:                                                     13833287
/*----------------*/                                                    13833387
                                                                        13833487
  Say 'PARSEREN: '                                                      13833587
  Say 'PARSEREN: Entering Check_For_MQ_Calls   : subroutine'            13833687
  Say 'PARSEREN: '                                                      13833787
                                                                        13833887
  Do  Rv_Mq_Ctr = 1 To  Rv_MQ_Verbs_Stem.0                              13833987
                                                                        13834087
      Rv_MQ_Verb =  Rv_MQ_Verbs_Stem.Rv_Mq_Ctr                          13834187
                                                                        13834287
      If  Find(Rv_Input_Record,Rv_MQ_Verb) > 0 Then                     13834387
      Do                                                                13834487
           Rf_MQ_Present  = 1                                           13834587
           Leave                                                        13834687
      End                                                               13835987
  End                                                                   13836087
                                                                        13836187
                                                                        13838987
Return                                                                  13839087
                                                                        13839187
                                                                        13839287
/*--------------------------------------------------------------------*/13839387
/* Store a warning for End of program listing                         */13840072
/*--------------------------------------------------------------------*/13850072
                                                                        13860072
Store_warning:                                                          13870072
/*-----------*/                                                         13880072
                                                                        13890072
  Say 'PARSEREN: '                                                      13900072
  Say 'PARSEREN: Entering Store_warning: subroutine'                    13910072
  Say 'PARSEREN: '                                                      13920072
                                                                        13930072
  If  Rv_Start_Record_No > Rv_Warning_List_Stem.Rv_Warnings_Ctr Then    13940072
  Do                                                                    13950072
      Rv_Warnings_Ctr = Rv_Warnings_Ctr + 1                             13960072
      Rv_Warning_List_Stem.Rv_Warnings_Ctr = Rv_Start_Record_No         13970072
  End                                                                   13980072
                                                                        13990072
  If  Rv_Return_Code < Rc_Warning_Code Then                             14000072
  Do                                                                    14010072
      Rv_Return_Code = Rc_Warning_Code                                  14020072
  End                                                                   14030072
                                                                        14040072
Return                                                                  14050072
                                                                        14060072
/*--------------------------------------------------------------------*/14070072
/* Store an error for End of program listing                          */14080072
/*--------------------------------------------------------------------*/14090072
                                                                        14100072
Store_error:                                                            14110072
/*---------*/                                                           14120072
                                                                        14130072
  Say 'PARSEREN: '                                                      14140072
  Say 'PARSEREN: Entering Store_error: subroutine'                      14150072
  Say 'PARSEREN: '                                                      14160072
                                                                        14170072
  If  Rv_Start_Record_No > Rv_Error_List_Stem.Rv_Errors_Ctr Then        14180072
  Do                                                                    14190072
      Rv_Errors_Ctr   = Rv_Errors_Ctr  + 1                              14200072
      Rv_Error_List_Stem.Rv_Errors_Ctr = Rv_Start_Record_No             14210072
  End                                                                   14220072
                                                                        14230072
  If  Rv_Return_Code < Rc_Error_Code Then                               14240072
  Do                                                                    14250072
      Rv_Return_Code = Rc_Error_Code                                    14260072
  End                                                                   14270072
                                                                        14280072
Return                                                                  14290072
                                                                        14300072
/*--------------------------------------------------------------------*/14310072
/* Store a reminder for End of program listing                        */14320072
/*--------------------------------------------------------------------*/14330072
                                                                        14340072
Store_reminder:                                                         14350072
/*------------*/                                                        14360072
                                                                        14370072
  Say 'PARSEREN: '                                                      14380072
  Say 'PARSEREN: Entering Store_reminder: subroutine'                   14390072
  Say 'PARSEREN: '                                                      14400072
                                                                        14410072
  If  Rv_Start_Record_No > Rv_Reminder_List_Stem.Rv_Reminders_Ctr Then  14420072
  Do                                                                    14430072
      Rv_Reminders_Ctr = Rv_Reminders_Ctr + 1                           14440072
      Rv_Reminder_List_Stem.Rv_Reminders_Ctr = Rv_Start_Record_No       14450072
  End                                                                   14460072
                                                                        14470072
  If  Rv_Return_Code < Rc_Reminder_Code Then                            14480072
  Do                                                                    14490072
      Rv_Return_Code = Rc_Reminder_Code                                 14500072
  End                                                                   14510072
                                                                        14520072
Return                                                                  14530072
                                                                        14540072
                                                                        14540176
/*--------------------------------------------------------------------*/14540276
/* Store an error for End of program listing                          */14540376
/*--------------------------------------------------------------------*/14540476
                                                                        14540576
Store_TS_Error:                                                         14540676
/*------------*/                                                        14540776
                                                                        14540876
  Say 'PARSEREN: '                                                      14540976
  Say 'PARSEREN: Entering Store_TS_Error: subroutine'                   14541076
  Say 'PARSEREN: '                                                      14541176
                                                                        14541276
  If  Rv_Start_Record_No > Rv_TS_Error_Stem.Rv_TS_Error_Ctr Then        14541376
  Do                                                                    14541476
      Rv_TS_Error_Ctr = Rv_TS_Error_Ctr + 1                             14541576
      Rv_TS_Error_Stem.Rv_TS_Error_Ctr = Rv_Start_Record_No             14541676
  End                                                                   14541776
                                                                        14541876
                                                                        14541976
Return                                                                  14542476
                                                                        14542576
                                                                        14542676
/*--------------------------------------------------------------------*/14542776
/* Store a Warning for End of program listing                         */14542876
/*--------------------------------------------------------------------*/14542976
                                                                        14543076
Store_TS_Warning:                                                       14543176
/*--------------*/                                                      14543276
                                                                        14543376
  Say 'PARSEREN: '                                                      14543476
  Say 'PARSEREN: Entering Store_TS_Warning: subroutine'                 14543576
  Say 'PARSEREN: '                                                      14543676
                                                                        14543776
  If  Rv_Start_Record_No > Rv_TS_Warning_Stem.Rv_TS_Warning_Ctr Then    14543876
  Do                                                                    14543976
      Rv_TS_Warning_Ctr = Rv_TS_Warning_Ctr + 1                         14544076
      Rv_TS_Warning_Stem.Rv_TS_Warning_Ctr = Rv_Start_Record_No         14544176
  End                                                                   14544276
                                                                        14544376
                                                                        14544476
Return                                                                  14544576
                                                                        14544676
                                                                        14544776
/*--------------------------------------------------------------------*/14550072
/* Code to write/list records                                         */14560072
/*--------------------------------------------------------------------*/14570072
                                                                        14580072
Write_Out_Record:                                                       14590072
/*--------------*/                                                      14600072
                                                                        14610072
  Say 'PARSEREN: '                                                      14620072
  Say 'PARSEREN: Entering Write_Out_Record: subroutine'                 14630072
  Say 'PARSEREN: '                                                      14640072
                                                                        14650072
  Push Rv_Out_Recod                                                     14660072
                                                                        14670072
  RC_WRITE_LINE                                                         14680072
                                                                        14680176
  If  Rf_Write_ThrdSafe_File Then                                       14680276
  Do                                                                    14680376
      Push Rv_Out_Recod                                                 14680476
      RC_WRITE_TS_LINE                                                  14680576
      Rf_Write_ThrdSafe_File = 0                                        14680676
  End                                                                   14680876
                                                                        14690072
Return                                                                  14700072
                                                                        14710072
                                                                        14710176
/*--------------------------------------------------------------------*/14710276
/* Code to write/list records                                         */14710376
/*--------------------------------------------------------------------*/14710476
                                                                        14710576
Write_TS_Record:                                                        14710676
/*--------------*/                                                      14710776
                                                                        14710876
  Say 'PARSEREN: '                                                      14710976
  Say 'PARSEREN: Entering Write_TS_Record: subroutine'                  14711076
  Say 'PARSEREN: '                                                      14711176
                                                                        14711276
  Push Rv_Out_Recod                                                     14711376
                                                                        14711476
  RC_WRITE_TS_LINE                                                      14711576
                                                                        14711676
                                                                        14712376
Return                                                                  14712476
                                                                        14720072
/*--------------------------------------------------------------------*/14730072
/* Write out the parser summary repot                                 */14740072
/*--------------------------------------------------------------------*/14750072
                                                                        14760072
Write_Parsing_Report:                                                   14770072
/*------------------*/                                                  14780072
                                                                        14790072
  Say 'PARSEREN: '                                                      14800072
  Say 'PARSEREN: Entering Write_Parsing_Report: subroutine'             14810072
  Say 'PARSEREN: '                                                      14820072
                                                                        14830072
  Rv_Out_Recod  = ' '                                                   14840072
  Call  Write_Out_Record                                                14850072
  Call  Write_Out_Record                                                14860072
                                                                        14870072
                                                                        14880072
  Rv_Out_Recod  = 'Parsing completed - maximum return code was: ' ,     14890072
                  Format(Rv_Return_Code,3)                              14900072
  Call Write_Out_Record                                                 14910072
  Rv_Out_Recod  = ' '                                                   14920072
  Call Write_Out_Record                                                 14930072
                                                                        14940072
  Rv_Out_Recod  = 'Error count was     :' Format(Rv_Errors_Ctr,5)       14950072
                                                                        14960072
  Call Write_Out_Record                                                 14970072
                                                                        14980072
  Rv_Out_Recod  = ' '                                                   14990072
  Call Write_Out_Record                                                 15000072
                                                                        15010072
  If  Rv_Errors_Ctr > 0 Then                                            15020072
  Do                                                                    15030072
      Rv_Out_List = ' '                                                 15040072
      Rv_Line_Count = 0                                                 15050072
      Do  i = 1 To Rv_Errors_Ctr                                        15060072
          Rv_Out_List = Rv_Out_List format(Rv_Error_List_Stem.i,5)      15070072
          Rv_Line_Count = Rv_Line_Count + 1                             15080072
          If  Rv_Line_Count = Rv_Line_Limit Then                        15090072
          Do                                                            15100072
              Rv_Out_Recod  = Rv_Out_List                               15110072
              Call Write_Out_Record                                     15120072
              Rv_Out_List = ' '                                         15130072
              Rv_Line_Count = 0                                         15140072
          End                                                           15150072
      End                                                               15160072
                                                                        15170072
      If  Rv_Out_List <> ' ' Then                                       15180072
      Do                                                                15190072
          Rv_Out_Recod  = Rv_Out_List                                   15200072
          Call Write_Out_Record                                         15210072
      End                                                               15220072
  End                                                                   15230072
                                                                        15240072
  Rv_Out_Recod  = ' '                                                   15250072
  Call Write_Out_Record                                                 15260072
  Call Write_Out_Record                                                 15270072
  Rv_Out_Recod  = 'Warning count was   :' ,                             15280072
                   Format(Rv_Warnings_Ctr,5)                            15290072
  Call Write_Out_Record                                                 15300072
                                                                        15310072
  If  Rv_Warnings_Ctr > 0 Then                                          15320072
  Do                                                                    15330072
      Rv_Out_List = ' '                                                 15340072
      Rv_Line_Count = 0                                                 15350072
      Do  i = 1 To Rv_Warnings_Ctr                                      15360072
          Rv_Out_List = Rv_Out_List format(Rv_Warning_List_Stem.i,5)    15370072
          Rv_Line_Count = Rv_Line_Count + 1                             15380072
          If  Rv_Line_Count = Rv_Line_Limit Then                        15390072
          Do                                                            15400072
              Rv_Out_Recod  = Rv_Out_List                               15410072
              Call Write_Out_Record                                     15420072
              Rv_Out_List = ' '                                         15430072
              Rv_Line_Count = 0                                         15440072
          End                                                           15450072
      End                                                               15460072
                                                                        15470072
      If  Rv_Out_List <> ' ' Then                                       15480072
      Do                                                                15490072
          Rv_Out_Recod  = Rv_Out_List                                   15500072
          Call Write_Out_Record                                         15510072
      End                                                               15520072
  End                                                                   15530072
                                                                        15540072
  Rv_Out_Recod  = ' '                                                   15550072
  Call Write_Out_Record                                                 15560072
  Call Write_Out_Record                                                 15570072
  Rv_Out_Recod  = 'Reminder count was   :' ,                            15580072
                  Format(Rv_Reminders_Ctr,5)                            15590072
  Call Write_Out_Record                                                 15600072
  Rv_Out_Recod  = ' '                                                   15610072
  Call Write_Out_Record                                                 15620072
                                                                        15630072
  If  Rv_Reminders_Ctr > 0 Then                                         15640072
  Do                                                                    15650072
      Rv_Out_List = ' '                                                 15660072
      Rv_Line_Count = 0                                                 15670072
      Do  i = 1 To Rv_Reminders_Ctr                                     15680072
          Rv_Out_List = Rv_Out_List Format(Rv_Reminder_List_Stem.i,5)   15690072
          Rv_Line_Count = Rv_Line_Count + 1                             15700072
          If  Rv_Line_Count = Rv_Line_Limit Then                        15710072
          Do                                                            15720072
              Rv_Out_Recod  = Rv_Out_List                               15730072
              Call  Write_Out_Record                                    15740072
              Rv_Out_List = ' '                                         15750072
              Rv_Line_Count = 0                                         15760072
          End                                                           15770072
      End                                                               15780072
                                                                        15790072
      If  Rv_Out_List <> ' ' Then                                       15800072
      Do                                                                15810072
          Rv_Out_Recod  = Rv_Out_List                                   15820072
          Call  Write_Out_Record                                        15830072
      End                                                               15840072
  End                                                                   15850072
                                                                        15860072
  Rv_Out_Recod  = " "                                                   15870072
  Call  Write_Out_Record                                                15880072
  Rv_Out_Recod  = " Meanings of return code levels: "                   15890072
  Call  Write_Out_Record                                                15900072
  Rv_Out_Recod  = " =============================== "                   15910072
  Call  Write_Out_Record                                                15920072
  Rv_Out_Recod  = " "                                                   15930072
  Call  Write_Out_Record                                                15940072
  Rv_Out_Recod  = " Return code  24  = Reminder "                       15950072
  Call  Write_Out_Record                                                15960072
  Rv_Out_Recod  = " "                                                   15970072
  Call  Write_Out_Record                                                15980072
  Rv_Out_Recod  = ,                                                     15990072
      "   This means that there are potential danger spots in your"     16000072
  Call  Write_Out_Record                                                16010072
  Rv_Out_Recod  = ,                                                     16020072
      "   code that need a visual check, because the analysis cannot"   16030072
  Call  Write_Out_Record                                                16040072
  Rv_Out_Recod  = ,                                                     16050072
      "   be automated, OR that you are using unusual options. "        16060072
  Call  Write_Out_Record                                                16070072
  Rv_Out_Recod  = ,                                                     16080072
      "   There may not be anything wrong at all."                      16090072
  Call  Write_Out_Record                                                16100072
  Rv_Out_Recod  = ,                                                     16110072
      "             "                                                   16120072
  Call  Write_Out_Record                                                16130072
  Call  Write_Out_Record                                                16140072
  Rv_Out_Recod  = ,                                                     16150072
      " Return code  28  = Warning "                                    16160072
  Call  Write_Out_Record                                                16170072
  Rv_Out_Recod  = ,                                                     16180072
      "             "                                                   16190072
  Call  Write_Out_Record                                                16200072
  Rv_Out_Recod  = ,                                                     16210072
      "   This means that you are using functions that are constricted "16220072
  Call  Write_Out_Record                                                16230072
  Rv_Out_Recod  = ,                                                     16240072
      "   in their use.  The EXEC cannot ascertain whether you comply " 16250072
  Call  Write_Out_Record                                                16260072
  Rv_Out_Recod  = ,                                                     16270072
      "   or not.  You need to check the context before going to TDA. " 16280072
  Call  Write_Out_Record                                                16290072
  Rv_Out_Recod  = ,                                                     16300072
      "             "                                                   16310072
  Call  Write_Out_Record                                                16320072
  Rv_Out_Recod  = ,                                                     16330072
      "             "                                                   16340072
  Call  Write_Out_Record                                                16350072
  Rv_Out_Recod  = ,                                                     16360072
      " Return code 32  = Error "                                       16370072
  Call  Write_Out_Record                                                16380072
  Rv_Out_Recod  = ,                                                     16390072
      " "                                                               16400072
  Call  Write_Out_Record                                                16410072
  Rv_Out_Recod  = ,                                                     16420072
      "   This means that you are using some Command or Option "        16430072
  Call  Write_Out_Record                                                16440072
  Rv_Out_Recod  = ,                                                     16450072
      "   which will not be passed by TDA. "                            16460072
  Call  Write_Out_Record                                                16470072
  Rv_Out_Recod  = ,                                                     16480072
      " "                                                               16490072
  Call  Write_Out_Record                                                16500072
  Rv_Out_Recod  = ,                                                     16510072
      "  Whatever return code the PARSER gives, subsequent processing"  16520072
  Call  Write_Out_Record                                                16530072
  Rv_Out_Recod  = ,                                                     16540072
      "  WILL be done."                                                 16550072
  Call  Write_Out_Record                                                16560072
  Rv_Out_Recod  = ' '                                                   16570072
  Call  Write_Out_Record                                                16580072
                                                                        16590072
Return                                                                  16600072
                                                                        16610072
                                                                        16610176
                                                                        16610276
/*--------------------------------------------------------------------*/16610376
/* Write out the Threadsafe summary repot                             */16610476
/*--------------------------------------------------------------------*/16610576
                                                                        16610676
Write_ThreadSafe_Report:                                                16610776
/*---------------------*/                                               16610876
                                                                        16610976
  Say 'PARSEREN: '                                                      16611076
  Say 'PARSEREN: Entering Write_ThreadSafe_Report: subroutine'          16611176
  Say 'PARSEREN: '                                                      16611276
                                                                        16611376
  Rv_Out_Recod  = ' '                                                   16611476
  Call  Write_TS_Record                                                 16611576
  Call  Write_TS_Record                                                 16611676
                                                                        16611776
                                                                        16611876
  Rv_Out_Recod  = 'Threadsafe analysis  completed successfully: '       16611976
                                                                        16612076
  Call Write_TS_Record                                                  16612176
  Rv_Out_Recod  = ' '                                                   16612276
  Call Write_TS_Record                                                  16612376
                                                                        16612476
  Rv_Out_Recod  = 'Error count was     :' Format(Rv_TS_Error_Ctr,5)     16612582
                                                                        16612676
  Call Write_TS_Record                                                  16612776
                                                                        16612876
  Rv_Out_Recod  = ' '                                                   16612976
  Call Write_TS_Record                                                  16613076
                                                                        16613176
  If  Rv_TS_Error_Ctr > 0 Then                                          16613276
  Do                                                                    16613376
      Rv_Out_List = ' '                                                 16613476
      Rv_Line_Count = 0                                                 16613576
      Do  i = 1 To Rv_TS_Error_Ctr                                      16613676
          Rv_Out_List = Rv_Out_List format(Rv_TS_Error_Stem.i,5)        16613776
          Rv_Line_Count = Rv_Line_Count + 1                             16613876
          If  Rv_Line_Count = Rv_Line_Limit Then                        16613976
          Do                                                            16614076
              Rv_Out_Recod  = Rv_Out_List                               16614176
              Call Write_TS_Record                                      16614276
              Rv_Out_List = ' '                                         16614376
              Rv_Line_Count = 0                                         16614476
          End                                                           16614576
      End                                                               16614676
                                                                        16614776
      If  Rv_Out_List <> ' ' Then                                       16614876
      Do                                                                16614976
          Rv_Out_Recod  = Rv_Out_List                                   16615076
          Call Write_TS_Record                                          16615176
      End                                                               16615276
  End                                                                   16615376
                                                                        16615476
  Rv_Out_Recod  = ' '                                                   16615576
  Call Write_TS_Record                                                  16615676
  Call Write_TS_Record                                                  16615776
  Rv_Out_Recod  = 'Warning count was   :' ,                             16615876
                   Format(Rv_TS_Warning_Ctr,5)                          16615976
  Call Write_TS_Record                                                  16616076
                                                                        16616176
  If  Rv_TS_Warning_Ctr  > 0 Then                                       16616276
  Do                                                                    16616376
      Rv_Out_List = ' '                                                 16616476
      Rv_Line_Count = 0                                                 16616576
      Do  i = 1 To Rv_TS_Warning_Ctr                                    16616676
          Rv_Out_List = Rv_Out_List format(Rv_TS_Warning_Stem.i,5)      16616776
          Rv_Line_Count = Rv_Line_Count + 1                             16616876
          If  Rv_Line_Count = Rv_Line_Limit Then                        16616976
          Do                                                            16617076
              Rv_Out_Recod  = Rv_Out_List                               16617176
              Call Write_TS_Record                                      16617276
              Rv_Out_List = ' '                                         16617376
              Rv_Line_Count = 0                                         16617476
          End                                                           16617576
      End                                                               16617676
                                                                        16617776
      If  Rv_Out_List <> ' ' Then                                       16617876
      Do                                                                16617976
          Rv_Out_Recod  = Rv_Out_List                                   16618076
          Call Write_TS_Record                                          16618176
      End                                                               16618276
  End                                                                   16618376
  Rv_Out_Recod  = " "                                                   16618482
  Call  Write_TS_Record                                                 16618582
  Rv_Out_Recod  = " Meanings of Error and Warning messages: "           16618682
  Call  Write_TS_Record                                                 16618782
  Rv_Out_Recod  = " ======================================= "           16618882
  Call  Write_TS_Record                                                 16618982
  Rv_Out_Recod  = " "                                                   16619082
  Call  Write_TS_Record                                                 16620082
  Rv_Out_Recod  = ,                                                     16621082
      " ----- Warning -----"                                            16621182
  Call  Write_TS_Record                                                 16621282
  Rv_Out_Recod  = ,                                                     16621382
      "             "                                                   16621482
  Call  Write_TS_Record                                                 16621582
  Rv_Out_Recod  = ,                                                     16621682
      "   This means that you are using non-thread safe CICS APIs. This"16621782
  Call  Write_TS_Record                                                 16621882
  Rv_Out_Recod  = ,                                                     16621982
      "   might cause a TCB switch. This means that potential increase" 16622082
                                                                        16622182
  Call  Write_TS_Record                                                 16622282
  Rv_Out_Recod  = ,                                                     16622382
    "   in CPU and elapsed time. If possible you should combine all"    16622494
  Call  Write_TS_Record                                                 16622582
  Rv_Out_Recod  = ,                                                     16622694
    "   non thread safe APIs together. "                                16622794
  Call  Write_TS_Record                                                 16622894
                                                                        16623294
  Rv_Out_Recod  = ,                                                     16623394
      "   If you are calling either SPZCERR or any DATE routine , you  "16623494
  Call  Write_TS_Record                                                 16623594
  Rv_Out_Recod  = ,                                                     16623694
      "   can ignore this warning as these routines are thread safe.   "16623794
  Call  Write_TS_Record                                                 16623894
                                                                        16623994
  Rv_Out_Recod  = ,                                                     16624094
      "             "                                                   16624194
  Call  Write_TS_Record                                                 16624294
  Rv_Out_Recod  = ,                                                     16624394
      "             "                                                   16624494
  Call  Write_TS_Record                                                 16624594
                                                                        16624694
  Rv_Out_Recod  = ,                                                     16624794
      " -----  Error  ---- "                                            16624894
  Call  Write_TS_Record                                                 16624994
  Rv_Out_Recod  = ,                                                     16625094
      " "                                                               16625194
  Call  Write_TS_Record                                                 16625294
  Rv_Out_Recod  = ,                                                     16625394
      "   This means that you are using some thread safe inhibiter"     16625494
  Call  Write_TS_Record                                                 16625594
  Rv_Out_Recod  = ,                                                     16625694
      "   CICS APIs. You can not define your program as a thread safe"  16625794
  Call  Write_TS_Record                                                 16625894
  Rv_Out_Recod  = ,                                                     16625994
      "   program. Please note that if you are only reading data from"  16626094
  Call  Write_TS_Record                                                 16626194
  Rv_Out_Recod  = ,                                                     16626294
       "   CWA and this is the only API shown as an Error, please"      16626394
  Call  Write_TS_Record                                                 16626494
  Rv_Out_Recod  = ,                                                     16626594
       "   ignore this error.  "                                        16626694
  Call  Write_TS_Record                                                 16626794
  Rv_Out_Recod  = ' '                                                   16626894
  Call  Write_TS_Record                                                 16626994
  Rv_Out_Recod  = ' '                                                   16627094
  Call  Write_TS_Record                                                 16627194
                                                                        16627294
  Rv_Out_Recod  = " Summary of Thread safe analysis:        "           16627394
  Call  Write_TS_Record                                                 16627494
  Rv_Out_Recod  = " ================================ "                  16627594
  Call  Write_TS_Record                                                 16627694
  Rv_Out_Recod  = ,                                                     16628385
      " "                                                               16628485
  Call  Write_TS_Record                                                 16628585
                                                                        16628685
  If  Rf_Db2_Present | Rf_MQ_Present Then                               16628794
  Do                                                                    16628885
      If  Rv_TS_Error_Ctr > 0 Then                                      16628985
      Do                                                                16629085
          Rv_Out_Recod  = ,                                             16629185
           "   This program uses either DB2 or MQ." ,                   16629285
           "However, This program can not "                             16629391
          Call  Write_TS_Record                                         16629485
          Rv_Out_Recod  = ,                                             16629585
           "   be exploited by the CICS OTE as" ,                       16629685
           "this program has some thread safe inhibiters."              16629794
          Call  Write_TS_Record                                         16629885
          Rv_Out_Recod  = ,                                             16629985
           "   Please note that" ,                                      16630090
           "for MQ you need CTS 3.2."                                   16630191
          Call  Write_TS_Record                                         16630285
          Rv_Out_Recod  = " "                                           16630385
          Call  Write_TS_Record                                         16630485
      End                                                               16630585
      Else Do                                                           16630685
          Rv_Out_Recod  = ,                                             16630785
           "   This program uses either DB2 or MQ." ,                   16630885
           "This program can be "                                       16630991
          Call  Write_TS_Record                                         16631085
          Rv_Out_Recod  = ,                                             16631185
           "   exploited by the CICS OTE. Please note that" ,           16631285
           "for MQ you need CTS 3.2."                                   16631391
          Call  Write_TS_Record                                         16631485
                                                                        16631588
          Rv_Out_Recod  = " "                                           16632085
          Call  Write_TS_Record                                         16632185
                                                                        16632289
          If  Rf_Call_present   Then                                    16632385
          Do                                                            16632485
              Rv_Out_Recod  = ,                                         16632585
              "   This program can not be defined as" ,                 16632685
              "a thread safe program until all"                         16632791
              Call  Write_TS_Record                                     16632885
                                                                        16632985
              Rv_Out_Recod  = ,                                         16633085
              "   the calling programs" ,                               16633785
              "are also thread safe."                                   16633891
              Call  Write_TS_Record                                     16633993
                                                                        16634085
              Rv_Out_Recod  = ,                                         16634285
              "   If you are calling either SPZCERR",                   16634385
              "or any DATE routine , you  "                             16634491
              Call  Write_TS_Record                                     16634585
              Rv_Out_Recod  = ,                                         16634685
              "   can ignore this warning as these",                    16634785
              "routines are thread safe.   "                            16634891
              Call  Write_TS_Record                                     16634985
                                                                        16635085
          End                                                           16635185
      End                                                               16635285
  End                                                                   16635385
                                                                        16635485
Return                                                                  16635985
                                                                        16636085
                                                                        16636185
                                                                        16636285
/*--------------------------------------------------------------------*/16637072
/* Process Error                                                      */16640072
/*--------------------------------------------------------------------*/16650072
                                                                        16660072
Process_Error:                                                          16670072
/*---------*/                                                           16680072
                                                                        16690072
  Say 'PARSEREN: '                                                      16700072
  Say 'PARSEREN: Entering Process_Error: subroutine'                    16710072
  Say 'PARSEREN: '                                                      16720072
                                                                        16730072
  Say 'PARSEREN: Error processing Started 'Date("S") || Time("L")       16740072
  Say 'PARSEREN:'                                                       16750072
  Say 'PARSEREN: Error number                   : 'Rv_Err_No            16760072
  Say 'PARSEREN: Error occured in section       : 'Rv_Err_Section       16770072
  Say 'PARSEREN:'                                                       16780072
                                                                        16790072
  Do  Rv_Err_Ctr = 1 To Rv_Err.0                                        16800072
      Say 'PARSEREN: Rv_Err.Rv_Err_Ctr = 'Rv_Err.Rv_Err_Ctr             16810072
  End                                                                   16820072
                                                                        16830072
  Select                                                                16840072
    When Rv_Err_Type    = "D" Then                                      16850072
      Do                                                                16860072
        Call  termination                                               16870072
        Exit(20)                                                        16880072
     End                                                                16890072
    When Rv_Err_Type    = "S" Then                                      16900072
      Do                                                                16910072
        Call  termination                                               16920072
        Exit(12)                                                        16930072
     End                                                                16940072
    When Rv_Err_Type    = "E" Then                                      16950072
      Do                                                                16960072
        Call  termination                                               16970072
        Exit(8)                                                         16980072
     End                                                                16990072
    When Rv_Err_Type    = "I" Then                                      17000072
      Do                                                                17010072
        Call  termination                                               17020072
        NOP                                                             17030072
     End                                                                17040072
                                                                        17050072
    Otherwise                                                           17060072
      Do                                                                17070072
        Call  termination                                               17080072
        Exit(4)                                                         17090072
     End                                                                17100072
  End                                                                   17110072
                                                                        17120072
                                                                        17130072
Return                                                                  17140072
                                                                        17150072
                                                                        17160072
/*--------------------------------------------------------------------*/17170072
/* Termination  Process                                               */17180072
/*--------------------------------------------------------------------*/17190072
                                                                        17200072
Termination:                                                            17210072
/*-------*/                                                             17220072
                                                                        17230072
                                                                        17240072
  Say 'PARSEREN: '                                                      17250072
  Say 'PARSEREN: Entering Termination: subroutine'                      17260072
  Say 'PARSEREN: '                                                      17270072
                                                                        17280072
  Exit (Rv_Return_Code)                                                 17290072
                                                                        17300072
Return                                                                  17310072
                                                                        17320072

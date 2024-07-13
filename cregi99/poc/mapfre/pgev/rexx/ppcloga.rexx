/********************************************************************/  00010000
/* Get/Allocate the Log File                                        */  00020000
/********************************************************************/  00030000
arg logdsn debug .                                                      00040002
msg_stat = msg('OFF')                                                   00050004
if debug = 'DEBUG' then trace all                                       00060002
address TSO "ALLOC F(LOG) DA('"logdsn"') MOD REUSE" ,                   00070005
            "AVGREC(K) AVBLOCK(80) SPACE(10,5)"                         00080005
if rc ^= 0 then do                                                      00090000
  address ISPEXEC                                                       00100006
  "VGET STREAMID"                                                       00110006
  x = msg(msg_stat)                                                     00120004
  zedsmsg = streamid 'In Use'                                           00130000
  zedlmsg = streamid 'Logfile' ,                                        00140004
            logdsn 'Already Allocated To Another User'                  00150004
  "SETMSG MSG(ISRZ001)"                                                 00160006
  exit 99                                                               00170001
end                                                                     00180000
x = msg(msg_stat)                                                       00190004

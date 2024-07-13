/********************************************************************/  00010000
/* Write A Log Message                                              */  00020000
/********************************************************************/  00030000
logit:                                                                  00040000
  arg msg                                                               00050000
  msg_stat = msg('OFF')                                                 00060002
  address TSO                                                           00070000
  "NEWSTACK"                                                            00080000
  queue msg                                                             00090000
  "EXECIO 1 DISKW LOG (FINIS"                                           00100000
  if rc ^= 0 then do                                                    00110002
    address ISPEXEC                                                     00120002
    "VGET (STREAMID LOGDSN)"                                            00130002
    x = msg(msg_stat)                                                   00140002
    zedsmsg = streamid 'Logfile Full'                                   00150002
    zedlmsg = 'Logfile' ,                                               00160002
              left(logdsn || '.' || streamid 'Full',80) ,               00170002
              'Please Delete or Rename' ,                               00180002
              'it will then be Re-Allocatted on next use'               00190002
    "SETMSG MSG(ISRZ001)"                                               00200002
    exit 99                                                             00210002
  end                                                                   00220002
  "DELSTACK"                                                            00230000
  x = msg(msg_stat)                                                     00240002
return                                                                  00250000

/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* JCLPREP Input JCL Libraries                                      */  00030000
/********************************************************************/  00040000
arg jcldsn debug .                                                      00050000
if debug = 'DEBUG' then trace a                                         00060000
call ppcinit                                                            00070011
address ISPEXEC                                                         00080000
"CONTROL ERRORS RETURN"                                                 00090000
"VGET (STREAMID STRMENVT)"                                              00100005
if jcldsn = '' | jcldsn = 'NONE' then do                                00110003
  jprepid = streamid                                                    00120003
  jcldsn  = strmenvt || 'OS.' || streamid || '.BASE.ENVT.JOBS'          00130010
end                                                                     00140003
else do                                                                 00150004
  jprepid = substr(jcldsn,pos('.F0')+1,8)                               00160004
end                                                                     00170003
"FTOPEN TEMP"                                                           00180000
"FTINCL PPCJCLP"                                                        00190009
"FTCLOSE"                                                               00200000
"VGET ZTEMPN"                                                           00210000
"LMINIT DATAID(DATAID) DDNAME(" || ztempn || ")"                        00220000
"EDIT DATAID(" || dataid || ")"                                         00230000
"LMFREE DATAID(" dataid ")"                                             00240000
exit                                                                    00250000

/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* Set TestStream Application Defaults                              */  00030001
/********************************************************************/  00040000
arg debug                                                               00050000
if debug = 'DEBUG' then trace all                                       00060000
strmbase = 'PG'                                                         00070008
strmenvt = 'PG'                                                         00080010
strmtlq  = 'PG'                                                         00090004
strmendv = 'PREV'                                                       00100004
strmpkge = 'PGEV'                                                       00101007
strmprfx = 'TTEM.PCM.'                                                  00110003
strmdsn  = 'TTEM.PCM.STREAM'                                            00120002
logdsn   = 'TTEM.PCM.LOG'                                               00130002
systmdsn = 'TTEM.PCM.SYSTEM'                                            00140002
cntldsn  = 'TTEM.PCM.DATA'                                              00150002
address ISPEXEC                                                         00160001
"VPUT (STRMBASE STRMENVT STRMTLQ STRMENDV STRMPKGE)"                    00170005
"VPUT (STRMPRFX STRMDSN LOGDSN SYSTMDSN CNTLDSN)"                       00180003

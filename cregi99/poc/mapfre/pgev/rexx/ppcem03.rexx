/* Rexx    trace a */                                                   00010000
/********************************************************************/  00020000
/* Edit Macro                                                       */  00030000
/* to convert Endevor output libraries to streamed libraries        */  00040000
/********************************************************************/  00050000
address ISREDIT                                                         00060000
"MACRO"                                                                 00070000
cc = 00                                                                 00080000
address ISPEXEC                                                         00090000
"VGET STREAMID"                                                         00100002
"TBTOP PPCTAB"                                                          00110005
"TBSKIP PPCTAB"                                                         00120005
do while rc = 0                                                         00130000
  address ISREDIT "CHANGE" testdsn trgtdsn all                          00140000
  address ISPEXEC "TBSKIP PPCTAB"                                       00150005
end                                                                     00160000
address ISREDIT                                                         00170000
"FIND 'PREV' FIRST"                                                     00180002
do while rc = 0                                                         00190002
  "(LINE) = LINE .ZCSR"                                                 00200002
  parse var line filler1 'DSN=' testdsn                                 00210002
  call ppclogw 'ERROR   : STREAM DATASET FOR ENDEVOR OUTPUT LIBRARY'    00220005
  if result = 99 then exit 99                                           00230006
  call ppclogw '        :' strip(testdsn) 'NOT FOUND IN' streamid       00240005
  if result = 99 then exit 99                                           00250006
  cc = 99                                                               00260000
  "FIND 'PREV'"                                                         00270002
end                                                                     00280000
if cc = 99 then "CANCEL"                                                00290002
           else "END"                                                   00300002
exit                                                                    00310002

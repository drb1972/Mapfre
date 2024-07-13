/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* Edit Macro to find start of current processing in the log        */  00030000
/********************************************************************/  00040000
address ISREDIT                                                         00050000
"MACRO"                                                                 00060001
address ISPEXEC "VGET STARTEXT"                                         00070001
"FIND '" || startext || "' FIRST"                                       00080004
"(E) = LINENUM .ZCSR"                                                   00090007
e = e - 1                                                               00100007
"LABEL" e "= .END"                                                      00110007
"EXCLUDE P'=' ALL .ZFIRST .END"                                         00120007
"FIND '" || startext || "' FIRST NX"                                    00130007
"LOCATE .ZCSR"                                                          00140006
exit(1)                                                                 00150000

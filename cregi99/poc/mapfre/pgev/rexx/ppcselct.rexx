/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* Select TestStream and validate it exists in Master List          */  00030000
/********************************************************************/  00040000
arg debug                                                               00050000
if debug = 'DEBUG' then trace all                                       00060000
err = 'Y'                                                               00070000
call ppcinit                                                            00080009
address ISPEXEC                                                         00090000
"VGET STRMDSN"                                                          00100000
"CONTROL ERRORS RETURN"                                                 00110000
"DISPLAY PANEL(PPCSELCT) CURSOR(STREAMID)"                              00120008
do while err = 'Y'                                                      00130000
  "VGET STREAMID"                                                       00140000
  select                                                                00150002
    when streamid = '' then do                                          00160004
      "EDIT DATASET('" || strmdsn || "'"                                00170003
    end                                                                 00180002
    when streamid ^= '' then do                                         00190002
      err = 'N'                                                         00200002
      m = msg()                                                         00210002
      z = msg('OFF')                                                    00220002
      memberok = sysdsn("'" || strmdsn || "(" || streamid || ")'")      00230002
      z = msg(m)                                                        00240002
      if memberok ^= 'OK' then do                                       00250002
        err = 'Y'                                                       00260002
        zedsmsg = streamid 'Not Found'                                  00270002
        zedlmsg = strmdsn ':' streamid memberok                         00280002
        "SETMSG MSG(ISRZ001)"                                           00290002
      end                                                               00300002
    end                                                                 00310002
    otherwise nop                                                       00320002
  end                                                                   00330002
  if err = 'Y' then "DISPLAY PANEL(PPCSELCT) CURSOR(STREAMID)"          00340008
end                                                                     00350000
exit                                                                    00360000

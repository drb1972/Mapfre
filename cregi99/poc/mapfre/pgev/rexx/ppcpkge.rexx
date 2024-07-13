/*-----------------------------REXX----------------------------------*\ 00000100
 *  Copy Endevor Package Shipment Staging Datasets                   *  00000200
 *  directly to a TestStream                                         *  00000210
\*-------------------------------------------------------------------*/ 00000300
trace n                                                                 00000400
                                                                        00040003
arg debug .                                                             00060003
if debug = 'DEBUG' then trace all                                       00070003
                                                                        00070004
call ppcinit                                                            00080015
                                                                        00080016
address ISPEXEC                                                         00090003
"VGET (STREAMID LOGDSN STRMPKGE)"                                       00100008
"DISPLAY PANEL(PPCPKGE)"                                                00110014
do while rc = 0                                                         00120011
  "LMDINIT LISTID(L) LEVEL(" || ,                                       00130011
                    strmpkge || ,                                       00140011
              ".SHIP.*.*.F0" || ,                                       00150011
                   trackero  || ,                                       00160011
              ".CHANGE.INFO)"                                           00170011
  "CONTROL DISPLAY SAVE"                                                00180011
  "LMDDISP LISTID(&L)"                                                  00190011
  if rc ^= 0 then do                                                    00200011
    zedsmsg = zerrsm                                                    00210011
    zedlmsg = zerrlm                                                    00220011
    "SETMSG MSG(ISRZ001)"                                               00230011
  end                                                                   00240011
  "CONTROL DISPLAY RESTORE"                                             00250011
  "LMDFREE LISTID(&L)"                                                  00260011
  "DISPLAY"                                                             00270011
end /* do while rc = 0 */                                               00280011
                                                                        00280012
exit                                                                    00280013

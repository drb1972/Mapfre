/* REXX */                                                              00010000
  PARSE ARG WTY FUNC                                                    00011012
  TRACE N                                                               00012033
  ADDRESS ISPEXEC                                                       00020007
  "VGET (ZPREFIX)"                                                      00021007
  "VGET (VNBRPRO)"                                                      00021317
  "VGET (VNBRGRP)"                                                      00021417
  "VGET (VNBRTYP)"                                                      00021517
  "VGET (VNBRMBR)"                                                      00021617
  IF FUNC = M THEN DO                                                   00022021
     "LMINIT DATAID(EDT) DATASET('TTWA.BASE.LOOKUP')"                   00022228
     CC = RC                                                            00022732
     MEM = WTY                                                          00023430
  END /* M */                                                           00023530
  ELSE DO                                                               00024021
     "LMINIT DATAID(EDT) DATASET('"VNBRPRO"."VNBRGRP"."VNBRTYP"')"      00024128
     CC = RC                                                            00024232
     MEM = VNBRMBR                                                      00025228
  END                                                                   00026021
  IF CC > 0 THEN DO                                                     00026132
     ZEDSMSG = ZERRSM                                                   00026335
     ZEDLMSG = ZERRLM                                                   00026434
     'SETMSG MSG(ISRZ001)'                                              00026532
     EXIT CC                                                            00026632
  END /* RC > 0 */                                                      00026732
  "EDIT DATAID("EDT") MEMBER("MEM") MACRO(WAMAC"FUNC")"                 00026826

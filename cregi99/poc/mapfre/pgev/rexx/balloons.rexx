PROC 0                                                                  00010000
SET COUNT=1                                                             00020000
DO WHILE &COUNT LT  5                                                   00030000
     SET PANEL=1                                                        00040000
     DO WHILE &PANEL LT  3                                              00050000
          ISPEXEC CONTROL DISPLAY LOCK                                  00060000
          ISPEXEC DISPLAY PANEL(BLOON&PANEL)                            00070000
          SET PANEL=&PANEL+1                                            00080000
          END                                                           00090000
     SET COUNT=&COUNT+1                                                 00100000
     END                                                                00110000
ISPEXEC DISPLAY PANEL(BLOON1)                                           00120000

//DELETES  EXEC PGM=IEFBR14                                             00010000
//*                                                                     00020000
)DOT PPCTABA                                                            00030005
//&TYPE    DD DSN=&TRGTDSN,                                             00040002
//         DISP=(MOD,DELETE),UNIT=3390,SPACE=(TRK,1)                    00050000
//*                                                                     00060000
)ENDDOT                                                                 00070000

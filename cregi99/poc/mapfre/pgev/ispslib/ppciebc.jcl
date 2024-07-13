//&L.0&TRACKER  JOB ,'BUILD &BUILDTYP &STREAMID',                       00010024
//          MSGCLASS=0,NOTIFY=&&SYSUID,CLASS=G                          00020000
//*                                                                     00030000
//* COPY &LOC LIBRARIES TO STREAMED LIBRARIES                           00040016
//*                                                                     00050008
)DOT PPCTAB                                                             00060027
)SEL &LOC = PROD                                                        00070016
)SET DSN = &PRODDSN                                                     00080007
)IM PPCIEBC1                                                            00090027
)ENDSEL                                                                 00100006
)SEL &LOC = TEST                                                        00110016
)SEL &NDVRDSNP NE &Z                                                    00120006
)SET LOC = P1                                                           00130018
)SET DSN = &NDVRDSNP                                                    00140007
)IM PPCIEBC1                                                            00150027
)ENDSEL                                                                 00160006
)SEL &NDVRDSNF NE &Z                                                    00170006
)SET LOC = F                                                            00180018
)SET DSN = &NDVRDSNF                                                    00190007
)IM PPCIEBC1                                                            00200027
)ENDSEL                                                                 00210006
)SEL &NDVRDSND NE &Z                                                    00220006
)SET LOC = D                                                            00230018
)SET DSN = &NDVRDSND                                                    00240007
)IM PPCIEBC1                                                            00250027
)ENDSEL                                                                 00260006
)SEL &TESTDSN NE &Z                                                     00270022
)SET LOC = TEST                                                         00280018
)SET DSN = &TESTDSN                                                     00290015
)IM PPCIEBC1                                                            00300027
)ENDSEL                                                                 00310009
)ENDSEL                                                                 00320022
)SEL &LOC = OVER                                                        00330016
)SEL &OVERDSN NE &Z                                                     00340006
)SET DSN = &OVERDSN                                                     00350007
)IM PPCIEBC1                                                            00360027
)ENDSEL                                                                 00370006
)ENDSEL                                                                 00380009
)ENDDOT                                                                 00390006

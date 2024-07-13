//F0&TRACKER JOB ,'&BUILDTYP &STREAMID BUILD',                          00010041
//         MSGCLASS=0,NOTIFY=&&SYSUID,CLASS=G                           00020008
//*                                                                     00030000
//* SAS JOB TO WORK OUT WHICH LIBRARY TO COPY EACH MEMBER FROM          00040001
//* I.E. PROD, TEST(ENDEVOR MAP) OR OVERRIDE                            00050007
//* AND GENERATE THE IEBCOPY CONTROL STATEMENTS                         00060022
//*                                                                     00070007
//* IT THEN SUBMITS P(ROD), T(EST) AND O(VER) JOBS                      00080007
//* TO PERFORM THE IEBCOPIES                                            00090007
//*                                                                     00100017
)DOT PPCTAB                                                             00110045
//&TYPE     EXEC PROC=SAS,WORK='12000,12000',                           00120035
//         OPTIONS='NONEWS,NOCENTER'                                    00130031
//*                                                                     00140024
)CM                     PRODUCTION LIBRARY                              00150001
)SEL &BUILDTYP EQ COMPLETE                                              00160041
)SET LOC = PROD                                                         00170027
)SET DSN = &PRODDSN                                                     00180003
)IM PPCBLDDS                                                            00190045
)ENDSEL                                                                 00200000
)CM                     TEST SOFTWARE LIBRARIES                         00210036
)CM                     ENDEVOR P1 LIBRARY                              00220001
)CM                                                                     00230037
)SEL &NDVRDSNP NE &Z                                                    00240000
)SET LOC = P1                                                           00250027
)SET DSN = &NDVRDSNP                                                    00260003
)IM PPCBLDDS                                                            00270045
)ENDSEL                                                                 00280000
)CM                     ENDEVOR F LIBRARY                               00290001
)SEL &NDVRDSNF NE &Z                                                    00300000
)SET LOC = F                                                            00310027
)SET DSN = &NDVRDSNF                                                    00320003
)IM PPCBLDDS                                                            00330045
)ENDSEL                                                                 00340000
)CM                     ENDEVOR D LIBRARY                               00350001
)SEL &NDVRDSND NE &Z                                                    00360000
)SET LOC = D                                                            00370027
)SET DSN = &NDVRDSND                                                    00380003
)IM PPCBLDDS                                                            00390045
)ENDSEL                                                                 00400000
)CM                     ENDEVOR TEST LIBRARY                            00410002
)SEL &TESTDSN NE &Z                                                     00420040
)SET LOC = TEST                                                         00430027
)SET DSN = &TESTDSN                                                     00440003
)IM PPCBLDDS                                                            00450045
)ENDSEL                                                                 00460040
)CM                     OVERRIDE LIBRARY                                00470001
)SEL &OVERDSN NE &Z                                                     00480000
)SET LOC = OVER                                                         00490027
)SET DSN = &OVERDSN                                                     00500003
)IM PPCBLDDS                                                            00510045
)ENDSEL                                                                 00520000
)CM                                                                     00530005
//SYSIN    DD *                                                         00540000
)CM                                                                     00550002
)IM PPCSAS01 NT                                                         00560045
)CM                                                                     00570002
)SEL &BUILDTYP EQ COMPLETE                                              00580041
%MEMS(PROD,9);                                                          00590002
)ENDSEL                                                                 00600000
)SEL &NDVRDSNP NE &Z                                                    00610000
%MEMS(P1,7);                                                            00620002
)ENDSEL                                                                 00630000
)SEL &NDVRDSNF NE &Z                                                    00640000
%MEMS(F,6);                                                             00650002
)ENDSEL                                                                 00660000
)SEL &NDVRDSND NE &Z                                                    00670000
%MEMS(D,5);                                                             00680046
)ENDSEL                                                                 00690000
)SEL &TESTDSN NE &Z                                                     00700040
%MEMS(TEST,2);                                                          00710002
)ENDSEL                                                                 00720040
)SEL &OVERDSN NE &Z                                                     00730000
%MEMS(OVER,1);                                                          00740002
)ENDSEL                                                                 00750000
)CM                                                                     00760002
)IM PPCSAS02 NT                                                         00770045
)IM PPCSAS03 NT                                                         00780045
)CM                                                                     00790002
)SEL &BUILDTYP EQ COMPLETE                                              00800041
%RITE(PROD);                                                            00810002
)ENDSEL                                                                 00820002
)SEL &NDVRDSNP NE &Z                                                    00830002
%RITE(P1);                                                              00840002
)ENDSEL                                                                 00850002
)SEL &NDVRDSNF NE &Z                                                    00860002
%RITE(F);                                                               00870002
)ENDSEL                                                                 00880002
)SEL &NDVRDSND NE &Z                                                    00890002
%RITE(D);                                                               00900046
)ENDSEL                                                                 00910002
)SEL &TESTDSN NE &Z                                                     00920040
%RITE(TEST);                                                            00930002
)ENDSEL                                                                 00940040
)SEL &OVERDSN NE &Z                                                     00950002
%RITE(OVER);                                                            00960002
)ENDSEL                                                                 00970002
/*                                                                      00980002
)ENDDOT                                                                 00990000

/* Rexx */ /*trace a*/                                                  00010002
address TSO "ALTLIB ACTIVATE APPLICATION(EXEC) QUIET UNCOND" ,          00020002
            "DSNAME('TTEM.PCM.EXEC' 'PGEV.BASE.REXX')"                  00030002
address ISPEXEC                                                         00040000
"LIBDEF ISPPLIB DATASET ID('TTEM.PCM.PLIB' 'PGEV.BASE.ISPPLIB') STACK"  00050001
"LIBDEF ISPSLIB DATASET ID('TTEM.PCM.SLIB' 'PGEV.BASE.ISPSLIB') STACK"  00060001
                                                                        00070000
"SELECT PANEL(PPCUTIL) NEWAPPL(PCM) PASSLIB"                            00080000
                                                                        00090000
address TSO "ALTLIB DEACTIVATE APPLICATION(EXEC)"                       00100002
"LIBDEF ISPPLIB"                                                        00110000
"LIBDEF ISPSLIB"                                                        00120000

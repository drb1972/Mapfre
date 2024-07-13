//*--SKELETON CMSCDUP1                                               --
//*********************************************************************
//** ADD RC CHECKS TO NDM PROCESS MEMBERS                            **
//*********************************************************************
//NDMUPD   EXEC PGM=IKJEFT1B,
//             PARM='%NDMUPD &SHIPHLQC &RMEM &C1SY'
)SEL &C1SY = EK
//SYSEXEC  DD DSN=PREV.FEV1.REXX,DISP=SHR
//         DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
)SEL &C1SY ^= EK
//SYSEXEC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//INPUT    DD *

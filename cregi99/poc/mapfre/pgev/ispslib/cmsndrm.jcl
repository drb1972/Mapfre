//*--SKELETON CMSNDRM  - EVDESTCP STEP START                         --
//*********************************************************************
//** USED BY CMSSUB TO CREATE THE DESTCOPY STEP IN THE RJOB THAT     **
//** RUNS THE EVDESTCP REXX                                          **
//**                                                                 **
//** &SUF IS THE CHANGE NUMBER WITHOUT THE C                      **
//** &C1SY IS THE ENDEVOR SYSTEM NAME                                **
//** CREATE CLONED NDM PROCESSES FOR EACH DESTID                     **
//*********************************************************************
//EVDESTCP EXEC PGM=IKJEFT1B,PARM='EVDESTCP &SUF &C1SY'
)SEL &C1SY = EK
//SYSPROC  DD DSN=PREV.FEV1.REXX,DISP=SHR
//         DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
)SEL &C1SY ^= EK
//SYSPROC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
//SYSTSPRT DD SYSOUT=*

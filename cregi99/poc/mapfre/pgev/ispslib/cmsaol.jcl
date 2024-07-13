//*--SKELETON CMSAOL   - DEMAND EVL0101D ON LOCAL PLEX               --
//*********************************************************************
//** DEMAND EVL0101D ON LOCAL PLEX                                   **
//*********************************************************************
//OPSWTO   EXEC PGM=OI,PARM='CMSAOL &CMR'
)SEL &C1SY = EK
//SYSEXEC  DD DSN=PREV.FEV1.REXX,DISP=SHR
//         DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
)SEL &C1SY ^= EK
//SYSEXEC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
//INPUT    DD *
&DSHLQS &CHDATE &CHTIME &DEMAND &CA7
/*
//*

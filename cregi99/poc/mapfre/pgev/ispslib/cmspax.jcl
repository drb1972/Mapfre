//*--SKELETON CMSPAX   - ZIP UP USS DIRECTORIES/FILES                --
//*
//*********************************************************************
//** IKJEFT1B - BUILD USS AND C:D COMMANDS.                          **
//*********************************************************************
//EVUSS02  EXEC PGM=IKJEFT1B
)SEL &C1SY = EK
//SYSEXEC  DD DSN=PREV.FEV1.REXX,DISP=SHR
//         DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
)SEL &C1SY ^= EK
//SYSEXEC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
//SYSTSPRT DD SYSOUT=*
//USS01LOG DD SYSOUT=*
//DESTSYS  DD DISP=SHR,DSN=PGEV.BASE.DATA(DESTSYS)
//BPXCMDS  DD DISP=(,PASS),DSN=&&BPXCMDS,
//             SPACE=(TRK,(15,15),RLSE),LRECL=400,RECFM=FB
//NDMDATA  DD DISP=(,PASS),DSN=&&NDMDATA,
//             SPACE=(TRK,(15,15),RLSE),LRECL=80,RECFM=FB
//SYSTSIN  DD *
 %EVUSS02  -
 &CMR
/*
//CHECKUSS IF EVUSS02.RC EQ 1 THEN
//*********************************************************************
//** IKJEFT1B - RUN USS PAX COMMAND TO ZIP UP THE DIRECTORIES        **
//*********************************************************************
//USSPAX   EXEC PGM=IKJEFT1B
//SYSTSPRT DD SYSOUT=*
//STDOUT   DD SYSOUT=*
//STDERR   DD SYSOUT=*
//SYSTSIN  DD DISP=(OLD,DELETE),DSN=&&BPXCMDS
//*
//*********************************************************************
//** SPWARN - ABEND IF USSPAX RETURN CODE GREATER THAN ZERO          **
//*********************************************************************
//ABENDPAX IF USSPAX.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN
//ABENDPAX ENDIF
//*
//*********************************************************************
//** DMBATCH  - TRANSFER THE PAX FILE TO REMOTE PLEXES VIA C:D, THEN **
//**            RUN PAX TO EXPLODE THE DATASET AND DELETE IT.        **
//*********************************************************************
//USSDM    EXEC PGM=DMBATCH,PARM=(YYSLYNN)
//DMNETMAP DD DSN=PGTN.CD.CD02.Q1.NETMAP,DISP=SHR
//DMMSGFIL DD DSN=PGTN.CD.MSG,DISP=SHR
)SEL &C1SY = EK
//DMPUBLIB DD DSN=PREV.FEV1.NDMDATA,DISP=SHR                            00000500
//         DD DSN=PGEV.BASE.NDMDATA,DISP=SHR                            00000700
)ENDSEL
)SEL &C1SY ^= EK
//DMPUBLIB DD DSN=PGEV.BASE.NDMDATA,DISP=SHR                            00000500
)ENDSEL
//DMPRINT  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYSIN    DD DISP=(OLD,DELETE),DSN=&&NDMDATA
//*
//*********************************************************************
//** SPWARN - ABEND IF DMBATCH RETURN CODE GREATER THAN ZERO         **
//*********************************************************************
//ABENDNDM IF USSDM.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN
//ABENDNDM ENDIF
//*
//*********************************************************************
//** IKJEFT1B - REMOVE PAX FILES AFTER SUCCESSFUL C:D TRANSMIT       **
//*********************************************************************
//USSPAXRM EXEC PGM=IKJEFT1B
//SYSTSPRT DD SYSOUT=*
//STDOUT   DD SYSOUT=*
//STDERR   DD SYSOUT=*
//SYSTSIN  DD *
 BPXBATCH sh rm -f /RBSG/endevor/STAGING/&CMR..pax.Z
 BPXBATCH sh rm -f /RBSG/endevor/STAGING/&BKID..pax.Z
/*
//*********************************************************************
//** SPWARN - ABEND IF USSPAX RETURN CODE GREATER THAN ZERO          **
//*********************************************************************
//CHECKRM  IF USSPAXRM.RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN
//CHECKRM  ENDIF
//*
//CHECKUSS ENDIF
//*
//*********************************************************************
//** SPWARN - ABEND IF EVUSS02 RETURN CODE GREATER THAN ONE          **
//*********************************************************************
//ABENDUSS IF EVUSS02.RC GT 1 THEN
//*
//SPWARN   EXEC @SPWARN
//ABENDUSS ENDIF
//*

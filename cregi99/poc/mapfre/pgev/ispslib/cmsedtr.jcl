//*--SKELETON CMSEDTR  - NDVEDIT/EVAUDIT STEP                        --
//*
//*********************************************************************
//** USED BY CMSSUB TO CREATE THE NDVEDIT AND EVAUDIT STEPS          **
//**                                                                 **
//** IT WILL BE INCLUDED FOR EASH ENTRY ON THE C1SYSTEMB CARD IN THE **
//** MEMBER PREV.PEV1.DATA(DESTSYS)                                  **
//*********************************************************************
//&STEPNAME   EXEC PGM=IKJEFT1B,DYNAMNBR=99
)SEL &C1SY = EK
//SYSPROC  DD DSN=PREV.FEV1.REXX,DISP=SHR
//         DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
)SEL &C1SY ^= EK
//SYSPROC  DD DSN=&EVBASE..BASE.REXX,DISP=SHR
)ENDSEL
//JCL      DD DSN=&CJOBDSET,
//             DISP=OLD                        /* UPDATED BY NDVEDIT */
//JCLB     DD DSN=&BJOBDSET,
//             DISP=OLD                        /* UPDATED BY NDVEDIT */
//DESTVAR  DD DSN=&ENDVVAR,
//             DISP=SHR                        /* INPUT TO NDVEDIT   */
//EVBOH001 DD DISP=SHR,DSN=PGEV.BASE.ISPSLIB(EVBOH001)
//SUBMIT   DD DCB=(RECFM=FB,LRECL=80),SYSOUT=(A,INTRDR)
//SUBMIT2  DD DCB=(RECFM=FB,LRECL=80),SYSOUT=(A,INTRDR)
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//APIPRINT DD SYSOUT=*
//HLAPILOG DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
)SEL &LOCAL EQ YES
//SYSTSIN  DD *
  NDVEDIT &CMR &LIBTYP LOCAL &DESTID &C1SY
/*
)ENDSEL
)SEL &EMERGNCY EQ YES
//SYSTSIN  DD *
  NDVEDIT &CMR &LIBTYP EMERGENCY &DESTID &C1SY
/*
)ENDSEL
)SEL &EMERGNCY NE YES AND &LOCAL NE YES
//SYSTSIN  DD *
  NDVEDIT &CMR &LIBTYP STANDARD &DESTID &C1SY
/*
)ENDSEL
//*********************************************************************
//** SPWARN - ABEND IF &STEPNAME RETURN CODE IS GREATER THAN ZERO    **
//*********************************************************************
//CHECKIT  IF &STEPNAME..RC GT 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*

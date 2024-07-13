//&RMEM JOB 0,'NDVR &CMR.P',CLASS=A,MSGCLASS=Y,USER=PMFBCH,
//             REGION=6M
//SETVAR   SET ID=PG,BNK=G,TLQ=
//JCLLIB   JCLLIB ORDER=(PGOS.&TLQ.BASE.PROCLIB)
//*
//*--SKELETON CMSRSCH  - TOP OF AO STEP                              --
//*********************************************************************
//** DEMAND &STPNAME ON EACH PLEX                                    **
//*********************************************************************
//&STPNAME EXEC PGM=OI,PARM='EVPKG010 &CMR &OPTION'
//SYSEXEC  DD DISP=SHR,DSN=PGAO.BASE.EXEC
//INPUT    DD *

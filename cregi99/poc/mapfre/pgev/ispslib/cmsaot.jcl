//*                                                                     00000020
//*--SKELETON CMSAOT   - TOP OF AO STEP                              -- 00000030
//********************************************************************* 00000100
//** DEMAND &STPNAME ON EACH PLEX                                    ** 00000300
//********************************************************************* 00000400
//&STPNAME EXEC PGM=OI,PARM='EVPKG010 &CMR &OPTION'                     00000500
//SYSEXEC  DD DISP=SHR,DSN=PGAO.BASE.EXEC                               00000600
//INPUT    DD *                                                         00000700

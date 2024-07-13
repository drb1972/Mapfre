)CM *-----------------------------------------------------------------*
)CM *                                                                 *
)CM *  COPYRIGHT (C) 1986-2012 CA. ALL RIGHTS RESERVED.               *
)CM *                                                                 *
)CM * NAME: C1SR8100                                                  *
)CM *                                                                 *
)CM *THIS SKELETON IS USED TO GENERATE REPORTS FOR BATCH.             *
)CM *                                                                 *
)CM * ISPSLIB(SCMM@SYM) - IMBEDDED MBR TO SET STANDARD VARIABLES,     *
)CM *                     TAILORED BY THE HOST SITE.                  *
)CM * ISPSLIB(SCMM@LIB) - IMBEDDED STEPLIB/CONLIB CONCATENATIONS,     *
)CM *                     TAILORED BY THE HOST SITE.                  *
)CM *-----------------------------------------------------------------*
)IM SCMM@SYM
//*********************************************************************
//*             REPORTS JCL                                           *
//*********************************************************************
//NDVRPTS  EXEC PGM=NDVRC1,PARM='C1BR1000'
//*********************************************************************
//**                                                                 **
//*     THE FOLLOWING DDNAME STATEMENTS WILL BE BUILT BY THE          *
//*         REPORTING INTERFACE.      THEY ARE USED                   *
//*         FOR THE FOLLOWING REASONS.                                *
//*                                                                   *
//*     BSTINP   - SPECIFY SELECTION CRITERIA HERE                    *
//*     BSTPDS   - DSN OF LIBRARY FOR FOOTPRINT REPORTS               *
//*     BSTIPT   - ADDITIONAL INCLUDE/EXCLUDE SYNTAX FOR              *
//*                FOOTPRINT REPORTS                                  *
//*     SMFDATA  - DSN OF SMF INPUT                                   *
//*     UNLINPT  - DSN OF UNLOAD TAPE OR FILE                         *
//**                                                                 **
//*********************************************************************
//BSTRPTS  DD SYSOUT=*                              REPORT OUTPUT
//BSTINP   DD *                                     SELECTION CRITERIA
     REPORT &REPORT .
)SEL &RPTCAT   NE PKG
)SEL &VAREVNME NE &Z
     ENVIRONMENT &VAREVNME .
)ENDSEL
)ENDSEL
)SEL &RPTCAT   = PKG
     ENVIRONMENT * .
)ENDSEL
)SEL &RPTCAT   = MCF OR  &RPTCAT = SMF OR &RPTCAT = ULD
)SEL &SYS NE &Z
     SYSTEM      &SYS .
)ENDSEL
)SEL &SBS NE &Z
     SUBSYSTEM   &SBS .
)ENDSEL
)SEL &CIELM NE  &Z
     ELEMENT     &CIELM .
)ENDSEL
)SEL &TYPEN NE  &Z
     TYPE        &TYPEN .
)ENDSEL
)SEL &D NE  &Z
     STAGE       &D .
)CM  )ENDSEL
)CM  )SEL &RPTCAT  = ULD
)CM  )SEL &VARSPPKG NE &Z
)CM      PACKAGE  '&VARSPPKG'  .
)CM  )ENDSEL
)ENDSEL
)ENDSEL
)SEL &RPTCAT   = SHP
)SEL &VARSPPKG NE &Z
     PACKAGE '&VARSPPKG'  .
)ENDSEL
)SEL &VARDEST  NE &Z
     DESTINATION '&VARDEST' .
)ENDSEL
)SEL &RPTNUM = RPT74 OR &RPTNUM = RPT75 OR &RPTNUM = RPT76
)SEL &SADTE NE &Z AND &SBDTE NE &Z
     SHIPPED AFTER &SADTE BEFORE &SBDTE .
)ENDSEL
)SEL &SADTE NE &Z AND &SBDTE  = &Z
     SHIPPED AFTER &SADTE .
)ENDSEL
)SEL &SADTE  = &Z AND &SBDTE NE &Z
     SHIPPED BEFORE &SBDTE .
)ENDSEL
)ENDSEL
)ENDSEL
)SEL &RPTCAT   = MCF OR  &RPTCAT = SMF
)SEL &DAYS NE  &Z
     DAYS        &DAYS .
)ENDSEL
)ENDSEL
)SEL &RPTCAT   = MCF
)SEL &S =  Y
     SEARCH ENVIRONMENT MAPPING.
)ENDSEL
)ENDSEL
)SEL &RPTCAT  = PKG
)SEL &VARSPPKG NE &Z
     PACKAGE  '&VARSPPKG'  .
)ENDSEL
)SEL &RAPPROVE NE &Z
     APPROVER '&RAPPROVE'  .
)ENDSEL
)SEL &RGROUP   NE &Z
     GROUP    '&RGROUP'    .
)ENDSEL
)SEL &VNBXPHIS EQ Y
     PROMOTION HISTORY  .
)ENDSEL
)SEL &STATUS NE &Z
     STATUS &STATUS .
)ENDSEL
)SEL &WADTE NE &Z AND &WBDTE NE &Z
     WINDOW AFTER &WADTE BEFORE &WBDTE .
)ENDSEL
)SEL &WADTE NE &Z AND &WBDTE  = &Z
     WINDOW AFTER &WADTE .
)ENDSEL
)SEL &WADTE  = &Z AND &WBDTE NE &Z
     WINDOW BEFORE &WBDTE .
)ENDSEL
)SEL &CADTE NE &Z AND &CBDTE NE &Z
     CREATE AFTER &CADTE BEFORE &CBDTE .
)ENDSEL
)SEL &CADTE NE &Z AND &CBDTE  = &Z
     CREATE AFTER &CADTE .
)ENDSEL
)SEL &CADTE  = &Z AND &CBDTE NE &Z
     CREATE BEFORE &CBDTE .
)ENDSEL
)SEL &EADTE NE &Z AND &EBDTE NE &Z
     EXECUTE AFTER &EADTE BEFORE &EBDTE .
)ENDSEL
)SEL &EADTE NE &Z AND &EBDTE  = &Z
     EXECUTE AFTER &EADTE .
)ENDSEL
)SEL &EADTE  = &Z AND &EBDTE NE &Z
     EXECUTE BEFORE &EBDTE .
)ENDSEL
)SEL &TADTE NE &Z AND &TBDTE NE &Z
     CAST   AFTER &TADTE BEFORE &TBDTE .
)ENDSEL
)SEL &TADTE NE &Z AND &TBDTE  = &Z
     CAST   AFTER &TADTE .
)ENDSEL
)SEL &TADTE  = &Z AND &TBDTE NE &Z
     CAST   BEFORE &TBDTE .
)ENDSEL
)SEL &BADTE NE &Z AND &BBDTE NE &Z
     BACKEDOUT AFTER &BADTE BEFORE &BBDTE .
)ENDSEL
)SEL &BADTE NE &Z AND &BBDTE  = &Z
     BACKEDOUT AFTER &BADTE .
)ENDSEL
)SEL &BADTE  = &Z AND &BBDTE NE &Z
     BACKEDOUT BEFORE &BBDTE .
)ENDSEL
)SEL &SADTE NE &Z AND &SBDTE NE &Z
     SHIPPED AFTER &SADTE BEFORE &SBDTE .
)ENDSEL
)SEL &SADTE NE &Z AND &SBDTE  = &Z
     SHIPPED AFTER &SADTE .
)ENDSEL
)SEL &SADTE  = &Z AND &SBDTE NE &Z
     SHIPPED BEFORE &SBDTE .
)ENDSEL
)ENDSEL
)SEL &RPTCAT = FTP AND &FTPDSN NE &Z
)SEL &FOODD  NE BSTPDS
     FOOTPRINT DDNAME &FOODD .
)ENDSEL
//&FOODD  DD DSN=&FTPDSN.,
//             DISP=SHR                             FOOTPRINT DATA SET
)ENDSEL
)SEL &RPTCAT = FTP
//BSTIPT   DD *                                     FOOTPRINT CRITERIA
)ENDSEL
)SEL &RPTCAT = FTP
   ANALYZE .
)SEL &FTPMEM NE &Z AND &C1DSPTNM NE &Z
   INCLUDE MEMBERS &FTPMEM THRU &C1DSPTNM .
)ENDSEL
)SEL &FTPMEM NE &Z AND &C1DSPTNM  = &Z
   INCLUDE MEMBERS &FTPMEM  .
)ENDSEL
)SEL &EXCMEM NE &Z AND &EXCMEMT NE &Z
   EXCLUDE MEMBERS &EXCMEM THRU &EXCMEMT .
)ENDSEL
)SEL &EXCMEM NE &Z AND &EXCMEMT  = &Z
   EXCLUDE MEMBERS &EXCMEM .
)ENDSEL
)SEL &EXCCST NE &Z AND &EXCCSTT NE &Z
   EXCLUDE CSECTS  &EXCCST THRU &EXCCSTT .
)ENDSEL
)SEL &EXCCST NE &Z AND &EXCCSTT  = &Z
   EXCLUDE CSECTS  &EXCCST .
)ENDSEL
)ENDSEL
)SEL &RPTCAT NE FTP
//BSTPDS   DD DUMMY                                 FOOTPRINT DATA SET
)ENDSEL
)SEL &RPTCAT NE SMF
//SMFDATA  DD DUMMY                                 SMF DATA SET
)ENDSEL
)SEL &RPTCAT = SMF
//SMFDATA  DD DSN=&SMFDSNJ.,
//             DISP=SHR                             SMF DATA SET
)ENDSEL
)SEL &RPTCAT NE ULD
//UNLINPT  DD DUMMY                                  UNLOAD DATA SET
)ENDSEL
)SEL &RPTCAT = ULD
//UNLINPT  DD &UNLDJCL1
)SEL &UNLDJCL2 NE &Z
&UNLDJCL2
)ENDSEL
)SEL &UNLDJCL3 NE &Z
&UNLDJCL3
)ENDSEL
)ENDSEL
)SEL &RPTNUM = RPT56 OR &RPTNUM = RPT57 OR &RPTNUM = RPT58
//ARCINPT  DD &ARCHJCL1
)SEL &ARCHJCL2 NE &Z
&ARCHJCL2
)ENDSEL
)SEL &ARCHJCL3 NE &Z
&ARCHJCL3
)ENDSEL
)ENDSEL
//*********************************************************************
//***                                                               ***
//**                  MISCELLANEOUS FILES                            **
//***                                                               ***
//*********************************************************************
//BSTPCH   DD DSN=&&TEMP,DISP=(NEW,DELETE),
//             SPACE=(TRK,(15,30)),
//             RECFM=FB,LRECL=838
//BSTLST   DD SYSOUT=*
//SORTIN   DD SPACE=(CYL,(150,15))
//SORTOUT  DD SPACE=(CYL,(150,15))
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=C
//SYMDUMP  DD DUMMY

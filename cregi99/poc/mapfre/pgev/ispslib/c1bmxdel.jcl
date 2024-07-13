)CM  PACKAGE SHIPMENT BATCH JCL -  REMOTE SITE JCL      ISPSLIB(C1BMXDEL)
)CM
)CM  JCL TO DELETE PRODUCTION MEMBERS AND REMOTE STAGING DATASETS AT THES.
)CM  REMOTE SITE.  THIS MEMBER IS READ/WRITTEN AT THE HOST SITE BY THE
)CM  SHIPMENT STAGING UTILITY AND IS EXECUTED AT THE REMOTE SITE.
)CM
)CM  THIS IS  N-O-T  AN ISPF SKELETON.  ALL SKELETON CONTROL STATEMENTS
)CM  (CLOSE PARENTHESIS IN COLUMN 1) WILL BE IGNORED.
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM  TAILORING INSTRUCTIONS:
)CM
)CM  NO TAILORING IS NECESSARY FOR THIS JCL.
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM  CUSTOMISATION CHANGE LOG
)CM
)CM  CHANGE                                                   REFERENCE
)CM  =======================================================  =========
)CM  REMOVE SUPPLIED )CM CARDS
)CM  COSMETIC CHANGE TO JCL COMMENT CARDS
)CM  STEPNAME CHANGED FROM DELETE TO STEP015                  @C01
)CM  ADD CONDITIONAL SPWARN STEP                              @C02
)CM
//*********************************************************************
//** SPWARN - EXECUTE IF PREVIOUS STEP IEBCOPY STEP010 FAILS          *
//*********************************************************************
//CHECKIT  IF (RC GT 4) THEN                                   /*@C02*/
//*                                                            /*@C02*/
//SPWARN   EXEC @SPWARN                                        /*@C02*/
//CA11NR   DD DUMMY                                            /*@C02*/
//         ENDIF                                               /*@C02*/
//* *----------------------------------------------* C1BMXRJC(C1BMXDEL)
//* *  REMOTE SITE JOBSTEP TO DELETE FILES WHICH
//* *  WERE CREATED BY THE EXECUTION OF THE PACKAGE
//* *-----------------------------------------------------------------*
//*
//STEP015  EXEC PGM=IDCAMS                                     /*@C01*/
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *

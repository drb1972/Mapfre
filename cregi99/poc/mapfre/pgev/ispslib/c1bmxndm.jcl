)CM  PACKAGE SHIPMENT BATCH JCL -  NETWORK DM XMISSION - ISPSLIB(C1BMXND
)CM
)CM  THIS SKELETON IS USED TO TRANSMIT STAGING DATASETS AND "RUN JOB" CO
)CM  VIA NETWORK DATA MOVER (SYSTEMS CENTER).
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM  TAILORING INSTRUCTIONS:
)CM
)CM  1.  MODIFY THE "LINKLIB", "NETMAP", "MSG", AND "PROCESS.LIB"
)CM      DSNAMES USING SITE SPECIFIC PREFIX, QUALIFIER, AND NAME.
)CM
)CM  3.  MODIFY THE SIGNON STATEMENT USING SITE SPECIFIC SIGNON DATA.
)CM      ADDITIONAL KEYWORDS MAY BE ADDED.  NDM CONTROL STATEMENTS
)CM      OTHER THAN SIGNON MAY ALSO BE ADDED.  REFER TO NETWORK DM
)CM      DOCUMENTATION FOR MORE INFORMATION.  IF A SIGNON STATEMENT
)CM      IS NOT NEEDED, DELETE THE SIGNON AND "DD  *" STATEMENTS AND
)CM      CODE "SYSIN" STARTING IN COLUMN 3 OF THE "&&&&XNWC" DD STATE-
)CM      MENT.
)CM
)CM  CONTAINS C9221790 - NDM SUPPORT USING C1BMX060
)CM  CONTAINS C9225600 - DUMMY IEBUPDTE SYSPRINT
)CM
)CM  ISPSLIB(SCMM@SYM) - IMBEDDED MBR TO SET STANDARD VARIABLES,
)CM                      TAILORED BY THE HOST SITE.
)IM SCMM@SYM
//* *============================================* ISPSLIB(C1BMXNDM) *
//* *==============================================================* *
//* *==============================================================* *
//* *==============================================================* *
//* *==============================================================* *
//PROCESSI EXEC PGM=IEBUPDTE,PARM=NEW,COND=(12,LE,NDVRSHIP)
//SYSPRINT DD  DUMMY
//SYSUT2   DD  DISP=(NEW,CATLG),
//             DSN=&ZPREFIX..D&VNB6DATE..T&VNB6TIME..CONNCMD.FILE,
//             SPACE=(CYL,(1,1,25)),
//             RECFM=FB,LRECL=80
//SYSUT1   DD  DUMMY
//SYSIN    DD  DISP=SHR,
//             DSN=&I@PRFX..&I@QUAL..SOURCE(#PS#NDM)
//* *==============================================================* *
//PROCESSP EXEC PGM=IEBUPDTE,PARM=MOD,COND=(12,LE,NDVRSHIP)
//SYSPRINT DD  DUMMY
//SYSUT1   DD  DISP=OLD,
//             DSN=&ZPREFIX..D&VNB6DATE..T&VNB6TIME..CONNCMD.FILE
//SYSUT2   DD  DISP=OLD,
//             DSN=&ZPREFIX..D&VNB6DATE..T&VNB6TIME..CONNCMD.FILE
//SYSIN    DD  DSN=&&&&XNWC,DISP=(OLD,PASS)
//* *==============================================================* *
//&VNBXSTP EXEC PGM=DMBATCH,COND=(12,LE,NDVRSHIP)
//DMNETMAP DD  DISP=SHR,                   NDM NETWORK MAP
//             DSN=SYSNDM.MOD000.NETMAP
//DMMSGFIL DD  DISP=SHR,                   NDM MESSAGE DATASET
//             DSN=SYSNDM.MOD000.MSG
//DMPUBLIB DD  DISP=SHR,
//             DSN=&ZPREFIX..D&VNB6DATE..T&VNB6TIME..CONNCMD.FILE
//SYSPRINT DD  SYSOUT=*    ******************************************
//NDMCMNDS DD  SYSOUT=*    *      ****      REPORTS      ****       *
//DMPRINT  DD  SYSOUT=*    ******************************************
//SYSUDUMP DD  SYSOUT=*
//SYMDUMP  DD DUMMY
//SYSIN    DD  *
 SIGNON USERID=&ZUSER      NODE=IIII
//         DD  DISP=SHR,
//         DSN=&ZPREFIX..D&VNB6DATE..T&VNB6TIME..CONNCMD.FILE(SUBMIT)
//* *==============================================================* *
//SUBMITD  EXEC PGM=IDCAMS,COND=(12,LE,NDVRSHIP)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 DELETE &ZPREFIX..D&VNB6DATE..T&VNB6TIME..CONNCMD.FILE(SUBMIT) NONVSAM

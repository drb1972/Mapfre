/*--------------------------REXX----------------------------*\
 *  Build QMF data migration JCL                            *
 *----------------------------------------------------------*
 *  Author:     Endevor Support                             *
\*----------------------------------------------------------*/
trace n
arg changeid system jobtype

/*                                                           */
/*  Write the header                                         */
/*                                                           */
say "--- Q M F S U B ---"   date() time()
say "QMFSUB:" changeid system
say "QMFSUB:"
say "QMFSUB: PROCESSING GSI QMF"
say "QMFSUB:"

/*  Read the //CONTROL file                                  */
/*  Contains all the QMF types                               */
"execio * diskr control  (stem type. finis"
if rc > 0 then exit(10) ;

/*  Read the DB2 info                                        */
type = word(type.1,1)
mem = 'S' || substr(changeid,2,7)
dsn = "PGEV.P"system"1.QMF#"type
"alloc fi("mem") da('"dsn"("mem")') shr"
if rc > 0 then do
  say 'QMFSUB: error on alloc ' mem dsn
  exit rc
end
say 'QMFSUB:   Reading Member:' mem
say 'QMFSUB:'
"execio * diskr" mem "(stem card. finis"
if rc > 0 then do
  say 'QMFSUB: error on diskr' mem sysdsname
  exit rc
end
"free fi("mem")"

do x = 1 to card.0
  db2sub = word(card.x,1)   /* DB2 subsys    */
  owner  = word(card.x,2)   /* DB2 owner     */
  say 'QMFSUB:   DB2sub -' db2sub
  say 'QMFSUB:   Owner  -' owner
  jobname = "EVQMF" || substr(db2sub,1,3)
  jcllines = 0
  queue "//" || jobname "JOB CLASS=N,MSGCLASS=Y,SCHENV=" || ,
               db2sub",USER="owner
  queue "/*JOBPARM SYSAFF=ANY"
  queue "//*"
  queue "//*          Change" changeid "QMF Processing"
  queue "//*"
  queue "//*          JCL Built by QMFSUB"
  queue "//*          JCL stored in PGEV.PEV1.QMFJCL"
  queue "//*"

  /*                                                           */
  /* Loop through the types & build QMF JCL for each           */
  /*                                                           */
  do i = 1 to type.0
    type = word(type.i,1)
    say 'QMFSUB:   Building JCL for type ' type
    select
      when jobtype = 'CJOB' & x = 1 then
        parmpre = 'P' /* prod */
      when jobtype = 'CJOB' & x = 2 then
        parmpre = 'T' /* training */
      when jobtype = 'BJOB' & x = 1 then
        parmpre = 'B' /* prod backout */
      when jobtype = 'BJOB' & x = 2 then
        parmpre = 'X' /* training backout */
      otherwise exit 12
    end /* select */
    parmmem = parmpre || substr(changeid,2,7)
    parmdsn = 'PGEV.P'system'1.QMF#'type'('parmmem')'
    queue "//*+-------------------------------------------------------+"
    queue "//*| QMF"type"  RUN QMF TO DO THE BACKUP, DELETE, INSERT    "
    queue "//*+-------------------------------------------------------+"
    queue "//QMF"type"  EXEC PGM=IKJEFT1B                                "
    queue "//STEPLIB  DD DSN=SYSDB2."db2sub".SDSQEXIT,DISP=SHR         "
    queue "//         DD DSN=SYSDB2."db2sub".SDSQLOAD,DISP=SHR         "
    queue "//         DD DSN=SYSDB2."db2sub".SDSNEXIT.DECP,DISP=SHR    "
    queue "//         DD DSN=SYSDB2."db2sub".SDSNLOAD,DISP=SHR         "
    queue "//SYSPROC  DD DSN=SYSDB2."db2sub".SDSQCLTE,DISP=SHR         "
    queue "//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                   "
    queue "//         DD DSN=SYSDB2."db2sub".SDSQEXCE,DISP=SHR         "
    queue "//ISPPLIB  DD DSN=SYSDB2."db2sub".SDSQPLBE,DISP=SHR         "
    queue "//         DD DSN=SYS1.SISPPENU,DISP=SHR                    "
    queue "//         DD DSN=SYS1.SISFPLIB,DISP=SHR                    "
    queue "//ISPMLIB  DD DSN=SYSDB2."db2sub".SDSQMLBE,DISP=SHR         "
    queue "//         DD DSN=SYS1.SISPMENU,DISP=SHR                    "
    queue "//         DD DSN=SYS1.SISFMLIB,DISP=SHR                    "
    queue "//ISPSLIB  DD DSN=SYSDB2."db2sub".SDSQSLBE,DISP=SHR         "
    queue "//         DD DSN=SYS1.SISPSENU,DISP=SHR                    "
    queue "//         DD DSN=SYS1.SISPSLIB,DISP=SHR                    "
    queue "//         DD DSN=SYS1.SISFSLIB,DISP=SHR                    "
    queue "//ISPTLIB  DD DSN=SYS1.SISPTENU,DISP=SHR                    "
    queue "//         DD DSN=SYS1.SISFTLIB,DISP=SHR                    "
    queue "//ISPPROF  DD DSN=&&PROF,DISP=(,DELETE,DELETE),             "
    queue "//             DATACLAS=PDSEFB80                            "
    queue "//ADMGGMAP DD DSN=SYSDB2."db2sub".SDSQMAPE,DISP=SHR         "
    queue "//ADMCFORM DD DSN=SYSDB2."db2sub".SDSQCHRT,DISP=SHR         "
    queue "//DSQUCFRM DD DSN=SYSDB2."db2sub".SDSQCHRT,DISP=SHR         "
    queue "//DSQPNLE  DD DSN=SYSDB2."db2sub".DSQPNLE,DISP=SHR          "
    queue "//DSQEDIT  DD RECFM=FBA,LRECL=79,BLKSIZE=4029,              "
    queue "//            DISP=NEW,SPACE=(CYL,(1,1))                    "
    queue "//DSQSPILL DD DSN=&&SPILL,DISP=(NEW,DELETE),                "
    queue "//            SPACE=(CYL,(1,1),RLSE),                       "
    queue "//            RECFM=F,LRECL=4096,BLKSIZE=4096               "
    queue "//EDT      DD DSN=&EDIT,SPACE=(1688,(40,12))                "
    queue "//UTL      DD DSN=&SYSUT1,SPACE=(TRK,(10,5))                "
    queue "//DSQPRINT DD SYSOUT=*,RECFM=FBA,LRECL=133,BLKSIZE=1330     "
    queue "//DSQDEBUG DD SYSOUT=*                                      "
    queue "//DSQUDUMP DD SYSOUT=*,RECFM=VBA,LRECL=125,BLKSIZE=1632     "
    queue "//SYSUDUMP DD SYSOUT=*                                      "
    queue "//SYSPRINT DD SYSOUT=*                                      "
    queue "//SYSTSPRT DD SYSOUT=*                                      "
    queue "//SYSTSIN  DD *                                             "
    queue " ISPSTART PGM(DSQQMFE) +                                    "
    queue "  PARM(M=B,I=GENERAL.MIGDATA(&&PROC1='"parmdsn"',+          "
    queue "       &&PROC2='PGEV.BASE.QMFPROC(PMIGDATA)'),+             "
    queue "       S="db2sub",P=QMFPLAN) NEWAPPL                        "
    queue " END                                                        "
    queue "/*                                                          "
    queue "//*"
    queue "//* SPWARN if QMF"type" fails"
    queue "//QMF"type"B        EXEC PGM=SPWARN,COND=(5,GE,QMF"type")"
    queue "//CA11NR           DD  DUMMY"
    queue "//STEPLIB          DD  DSN=PGSP.BASE.LOAD,DISP=SHR"
    queue "//SYSPRINT         DD  SYSOUT=*,FCB=S001"
    queue "//*"
    say 'QMFSUB:'
  end /* do i = 1 to type.0 */
end /* do x = 1 to words(card.1) */

/* Write out JCL for this JOB                */
"execio * diskw SUBMIT (finis"
if rc > 0 then do
  say 'QMFSUB: error writing JCL to ddname SUBMIT'
  exit rc
end /* end do */
say 'QMFSUB:'
say 'QMFSUB:  JCL Written   '

exit

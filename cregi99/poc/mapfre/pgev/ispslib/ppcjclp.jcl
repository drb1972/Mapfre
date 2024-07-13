//JCLPREP  JOB ,'JCLPREP ID : &JPREPID',                                00010008
//         CLASS=C,MSGCLASS=0,REGION=0M,NOTIFY=&&SYSUID,TIME=1440       00020004
//*****************************************************************     00030001
//* JCL PREP                                                            00040001
//*****************************************************************     00050001
//*                                                                     00060001
//DELETE  EXEC PGM=IDCAMS                                               00070001
//SYSOUT    DD SYSOUT=*                                                 00080001
//SYSPRINT  DD SYSOUT=*                                                 00090001
//SYSIN     DD *                                                        00100001
 DELETE TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT PRG                         00110010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.WRITE PRG                            00120010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.WRITEPDS PRG                         00130010
 SET MAXCC = 0                                                          00140001
/*                                                                      00150001
//JCLPREP EXEC PGM=JCLPREP,DYNAMNBR=10                                  00160001
//STEPLIB   DD DISP=SHR,DSN=SYSJCLP.BASE.LOAD                           00170001
//*                                                                     00180001
//DDIN      DD DISP=SHR,DSN=&JCLDSN                                     00190009
//*                                                                     00200001
//DDXEFP    DD DSN=TTEM.PCM.&JPREPID..JCLPREP.WRITEPDS,                 00210010
//             UNIT=DASD,                                               00220001
//             SPACE=(CYL,(10,2,400),RLSE),                             00230001
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120),                    00240001
//             DISP=(NEW,CATLG,CATLG)                                   00250001
//DDRPT     DD DSN=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT,                 00260010
//             UNIT=DASD,                                               00270001
//             SPACE=(CYL,(85,2),RLSE),                                 00280001
//             DCB=(RECFM=FBA,LRECL=121,BLKSIZE=3146),                  00290001
//             DISP=(NEW,CATLG,CATLG)                                   00300001
//DDXEFW    DD DSN=TTEM.PCM.&JPREPID..JCLPREP.WRITE,                    00310010
//             UNIT=DASD,                                               00320001
//             SPACE=(CYL,(20,2),RLSE),                                 00330001
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120),                    00340001
//             DISP=(NEW,CATLG,CATLG)                                   00350001
//*                                                                     00360001
//DDOPT     DD *                                                        00370001
**********************************************************************  00380001
* GENERATE THE MAXCOL OPTIONS                                        *  00390001
**********************************************************************  00400001
                                                                        00410001
MAXCOL DD=68                                                            00420001
MAXCOL EXEC=68                                                          00430001
MAXCOL PROC=68                                                          00440001
MAXCOL JOB=68                                                           00450001
MAXCOL OUTPUT=68                                                        00460001
                                                                        00470001
*******************************************************************     00480001
* REFORMATTING ALIGNMENT OPTIONS                                  *     00490001
*******************************************************************     00500001
                                                                        00510001
VERB DD=12,SPACE=1                                                      00520001
CONTCOL DD=16                                                           00530001
PARM DD=2                                                               00540001
PARM DCB=9                                                              00550001
VERB EXEC=12,SPACE=1                                                    00560001
CONTCOL EXEC=16                                                         00570001
PARM EXEC=4                                                             00580001
VERB PROC=12,SPACE=1                                                    00590001
CONTCOL PROC=16                                                         00600001
PARM PROC=1                                                             00610001
VERB JOB=12,SPACE=1                                                     00620001
CONTCOL JOB=16                                                          00630001
PARM JOB=9                                                              00640001
VERB OUTPUT=12,SPACE=1                                                  00650001
CONTCOL OUTPUT=16                                                       00660001
PARM OUTPUT=1                                                           00670001
VERB PEND=12,SPACE=1                                                    00680001
                                                                        00690001
*******************************************************************     00700001
* COMMENT PROCESSING OPTIONS                                      *     00710001
*******************************************************************     00720001
                                                                        00730001
COMMENT AFFINITY,NOSDEL,NOBOX,DELB                                      00740001
JUSTIFY INLINE=40                                                       00750001
ADDBLANK NONE                                                           00760001
ADDBLANK EXEC                                                           00770001
                                                                        00780001
*******************************************************************     00790001
* PARAMETER REORDERING OPTIONS                                    *     00800001
*******************************************************************     00810001
                                                                        00820001
ALPHA OUTPUT                                                            00830001
ALPHA JOB                                                               00840001
NOREORDER DCB                                                           00850001
REORDER DCB,FIRST=RECFM,LRECL,BLKSIZE,DSORG,KEYLEN                      00860001
NOREORDER DD                                                            00870001
REORDER DD,FIRST=DSN,DISP,DCB,DDNAME,LIKE,OUTPUT,RECORG,SYSOUT,SPACE    00880001
REORDER DD,LAST=PROTECT,STORCLAS,SUBSYS,TERM,UCS,UNIT,VOL               00890001
TRUNCATE RIGHT                                                          00900001
                                                                        00910001
*******************************************************************     00920001
* OTHER JCLPREP OPTIONS                                           *     00930001
*******************************************************************     00940001
                                                                        00950001
ESA                                                                     00960001
STATUS MSG=0,TERM=16                                                    00970001
                                                                        00980001
**********************************************************************  00990001
* GENERATE SEQUENCE OPTIONS                                          *  01000001
**********************************************************************  01010001
                                                                        01020001
NOSEQ                                                                   01030001
REPORT OPTIONS,INFILE,OUTFILE,XEF,SUMMARY                               01040001
                                                                        01050001
*******************************************************************     01060001
* GENERATE DSMN OPTIONS FOR REPORT DATASET ALLOCATION             *     01070001
*******************************************************************     01080001
                                                                        01090001
DSMNRPDS DSN=TTEM.PCM.&JPREPID..JCLPREP.REPORT                          01100010
DSMNRPDS BLKSIZE=3146,LRECL=121,RECFM=FB,DSORG=SEQ                      01110001
DSMNRPDS UNIT(SYSDA)                                                    01120001
DSMNRPDS ALOCTYPE=T,PRIMARY=15,SECOND=30                                01130001
                                                                        01140001
*******************************************************************     01150001
* XEF (RULES) OPTIONS                                             *     01160001
*******************************************************************     01170001
                                                                        01180001
XEF WRITE                                                               01190001
XEFDSN PROS.NJCLPREP.PREP412(P$RULE1)                                   01200007
                                                                        01210001
*******************************************************************     01220001
* GENERATE DSMN OPTIONS FOR WRITEPDS DATASET ALLOCATION           *     01230001
*******************************************************************     01240001
                                                                        01250001
DSMNWPDS DSN=TTEM.PCM.&JPREPID..JCLPREP.WRITEPDS                        01260010
DSMNWPDS BLKSIZE=3120,LRECL=80,RECFM=FB,DSORG=PDS                       01270001
DSMNWPDS UNIT(SYSDA)                                                    01280001
DSMNWPDS ALOCTYPE=T,PRIMARY=15,SECOND=30                                01290001
                                                                        01300001
*******************************************************************     01310001
* GENERATE DSMN OPTIONS FOR XEF WRITE DATASET ALLOCATION          *     01320001
*******************************************************************     01330001
                                                                        01340001
DSMNWDS DSN=TTEM.PCM.&JPREPID..JCLPREP.WRITE                            01350010
DSMNWDS BLKSIZE=3120,LRECL=80,RECFM=FB,DSORG=SEQ                        01360001
DSMNWDS UNIT(SYSDA)                                                     01370001
DSMNWDS ALOCTYPE=T,PRIMARY=15,SECOND=30                                 01380001
                                                                        01390001
XEFOPT CHECK JCL                                                        01400001
XEFOPT STATMSG=0                                                        01410001
XEFOPT CARDLIST 3 SYSIN                                                 01420001
XEFOPT MERGED LIST                                                      01430001
XEFOPT SECURITY                                                         01440001
XEFOPT USEREXIT ALLCARDS                                                01450001
XEFOPT PRODJOB                                                          01460001
XEFOPT XMEM                                                             01470001
XEFOPT @SMS 2                                                           01480001
XEFOPT @SMSSRC ACDS                                                     01490001
XEFOPT NO@SMSINFO                                                       01500001
XEFOPT ESA                                                              01510001
                                                                        01520001
*******************************************************************     01530001
* 'ADDITIONAL' OPTIONS FROM ADDITIONAL OPTIONS PANEL              *     01540001
*******************************************************************     01550001
                                                                        01560001
XEFOPT PRCLOC                                                           01570001
XEFOPT COMNODEL                                                         01580001
XEFOPT PROCLIB=PGOS.&JPREPID..BASE.PROCLIB                              01590008
XEFOPT PRCORDER=7123456                                                 01600001
* RESERVED. SEE THE OPTIONS REPORT FOR  XEFDSN DSN                      01610001
* RESERVED. SEE THE OPTIONS REPORT FOR  XEFOPT MEMBERNAME=XXXXXXXX      01620001
/*                                                                      01630001
//DDRUN     DD *                                                        01640001
*******************************************************************     01650001
* JCLPREP INPUT/OUTPUT CONTROL OPTIONS                            *     01660001
*******************************************************************     01670001
PDS                                                                     01680001
/*                                                                      01690001
//DELETE EXEC PGM=IDCAMS                                                01700001
//SYSOUT   DD SYSOUT=*                                                  01710001
//SYSPRINT DD SYSOUT=*                                                  01720001
//SYSIN    DD *                                                         01730001
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG                                  01740010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG.ERRORS                           01750010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG.SEC                              01760010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG.STOR                             01770010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG.INCLUDE                          01780010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG.GDGINDEX                         01790010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG.GDGS                             01800010
 DELETE TTEM.PCM.&JPREPID..JCLPREP.MSG.DSNNOTR9                         01810010
 SET MAXCC = 0                                                          01820001
/*                                                                      01830001
//**********************************************************************01840001
//MESSAGES EXEC PGM=SORT                                                01850001
//**********************************************************************01860001
//SYSPRINT DD SYSOUT=*                                                  01870001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT          01880010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG,                       01890010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT    01900010
//SYSOUT   DD SYSOUT=*                                                  01910001
//SYSIN    DD *                                                         01920001
   SORT FIELDS=COPY                                                     01930001
   INCLUDE COND=((6,3,CH,EQ,C'JCP',                                     01940001
              OR,50,3,CH,EQ,C'PDS'))                                    01950001
/*                                                                      01960001
//**********************************************************************01970001
//STORAGE1 EXEC PGM=SORT                                                01980001
//**********************************************************************01990001
//SYSPRINT DD SYSOUT=*                                                  02000001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG               02010010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.STOR,                  02020010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.MSG         02030010
//SYSOUT   DD SYSOUT=*                                                  02040001
//SYSIN    DD *                                                         02050001
   SORT FIELDS=COPY                                                     02060001
   INCLUDE COND=((6,8,CH,EQ,C'JCP0546E',                                02070001
             OR,((6,8,CH,EQ,C'JCP0429E')),                              02080001
             OR,((6,8,CH,EQ,C'JCP0541W')),                              02090001
             OR,((6,8,CH,EQ,C'JCP0451E'),AND,(24,2,CH,EQ,C'PR')),       02100001
             OR,((6,8,CH,EQ,C'JCP0451E'),AND,(24,2,CH,EQ,C'PN')),       02110001
             OR,((6,8,CH,EQ,C'JCP0451E'),AND,(24,2,CH,EQ,C'PG')),       02120001
             OR,((6,8,CH,EQ,C'JCP0451E')),                              02130001
             OR,((6,8,CH,EQ,C'JCP0618W'))))                             02140008
/*                                                                      02150001
//**********************************************************************02160001
//STORAGE2 EXEC PGM=SORT                                                02170001
//**********************************************************************02180001
//SYSPRINT DD SYSOUT=*                                                  02190001
//SORTIN   DD DISP=SHR,                                                 02200001
//            DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.STOR                   02210010
//SORTOUT  DD DISP=OLD,                                                 02220001
//            DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.STOR                   02230010
//SYSOUT   DD SYSOUT=*                                                  02240001
//SYSIN    DD *                                                         02250001
   SORT FIELDS=COPY                                                     02260001
   OMIT COND=(((24,2,CH,EQ,C'PN'),AND,(34,4,CH,EQ,C'LOAD')),            02270001
            OR,((24,2,CH,EQ,C'PR'),AND,(34,4,CH,EQ,C'LOAD')),           02280001
            OR,((24,2,CH,EQ,C'PN'),AND,(34,4,CH,EQ,C'DATA')),           02290001
            OR,((24,2,CH,EQ,C'PR'),AND,(34,4,CH,EQ,C'DATA')),           02300001
            OR,((24,2,CH,EQ,C'PN'),AND,(34,4,CH,EQ,C'CLIS')),           02310001
            OR,((24,2,CH,EQ,C'PR'),AND,(34,4,CH,EQ,C'CLIS')),           02320001
            OR,((24,2,CH,EQ,C'PN'),AND,(34,4,CH,EQ,C'DB2D')),           02330001
            OR,((24,2,CH,EQ,C'PR'),AND,(34,4,CH,EQ,C'DB2D')),           02340001
            OR,((24,2,CH,EQ,C'PN'),AND,(34,3,CH,EQ,C'SQL')),            02350001
            OR,((24,2,CH,EQ,C'PR'),AND,(34,3,CH,EQ,C'SQL')),            02360001
            OR,(24,2,CH,EQ,C'PR'),                                      02370001
            OR,(29,4,CH,EQ,C'EMER'),                                    02380001
            OR,(40,2,CH,EQ,C'PR'))                                      02390001
/*                                                                      02400001
//**********************************************************************02410001
//STORAGE3 EXEC PGM=SORT                                                02420001
//**********************************************************************02430001
//SYSPRINT DD SYSOUT=*                                                  02440001
//SORTIN   DD DISP=SHR,                                                 02450001
//            DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.STOR                   02460010
//SORTOUT  DD DISP=OLD,                                                 02470001
//            DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.STOR                   02480010
//SYSOUT   DD SYSOUT=*                                                  02490001
//SYSIN    DD *                                                         02500001
 SORT FIELDS=(1,57,CH,A)                                                02510001
 SUM FIELDS=NONE                                                        02520001
/*                                                                      02530001
//**********************************************************************02540001
//SECURITY EXEC PGM=SORT                                                02550001
//**********************************************************************02560001
//SYSPRINT DD SYSOUT=*                                                  02570001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG               02580010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.SEC,                   02590010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.MSG         02600010
//SYSOUT   DD SYSOUT=*                                                  02610001
//SYSIN    DD *                                                         02620001
 INCLUDE COND=(6,8,CH,EQ,C'JCP0544E')                                   02630001
 SORT FIELDS=(1,121,CH,A)                                               02640001
 SUM FIELDS=NONE                                                        02650001
/*                                                                      02660001
//**********************************************************************02670001
//ERRORS   EXEC PGM=SORT                                                02680001
//**********************************************************************02690001
//SYSPRINT DD SYSOUT=*                                                  02700001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG               02710010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.ERRORS,                02720010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.MSG         02730010
//SYSOUT   DD SYSOUT=*                                                  02740001
//SYSIN    DD *                                                         02750001
   SORT FIELDS=COPY                                                     02760001
   OMIT COND=((13,1,CH,EQ,C'I',                                         02770001
             OR,39,2,CH,EQ,C'ID',                                       02780001
             OR,39,3,CH,EQ,C'BNK',                                      02790001
             OR,39,3,CH,EQ,C'TLQ',                                      02800001
             OR,16,10,CH,EQ,C'PGM=SPWARN',                              02810001
             OR,25,14,CH,EQ,C'PRSP.BASE.LOAD',                          02820001
             OR,6,8,CH,EQ,C'JCP0429E',                                  02830001
             OR,6,8,CH,EQ,C'JCP0530W',                                  02840001
             OR,6,8,CH,EQ,C'JCP0962F',                                  02850001
             OR,6,8,CH,EQ,C'JCP0933E',                                  02860001
             OR,6,8,CH,EQ,C'JCP0497E',                                  02870001
             OR,6,8,CH,EQ,C'JCP0423E',                                  02880001
             OR,6,8,CH,EQ,C'JCP0452E',                                  02890001
             OR,6,8,CH,EQ,C'JCP0409E',                                  02900001
             OR,6,8,CH,EQ,C'JCP0472E',                                  02910001
             OR,6,8,CH,EQ,C'JCP0542E',                                  02920001
             OR,6,8,CH,EQ,C'JCP0906W',                                  02930001
             OR,6,8,CH,EQ,C'JCP0905W',                                  02940001
             OR,6,8,CH,EQ,C'JCP0903W',                                  02950001
             OR,6,8,CH,EQ,C'JCP5104W',                                  02960001
             OR,6,8,CH,EQ,C'JCP0618W',                                  02970001
             OR,6,8,CH,EQ,C'JCP0523W',                                  02980001
             OR,6,8,CH,EQ,C'JCP0544E',                                  02990001
             OR,6,8,CH,EQ,C'JCP0541W',                                  03000001
             OR,6,8,CH,EQ,C'JCP0542W',                                  03010001
             OR,6,8,CH,EQ,C'JCP0546E',                                  03020001
             OR,6,8,CH,EQ,C'JCP0937E',                                  03030001
             OR,6,8,CH,EQ,C'JCP0930E',                                  03040001
             OR,6,8,CH,EQ,C'JCP0618W',                                  03050001
             OR,6,8,CH,EQ,C'JCP0662W',                                  03060001
             OR,6,8,CH,EQ,C'JCP0472W',                                  03070001
             OR,6,8,CH,EQ,C'JCP5103W',                                  03080001
             OR,6,8,CH,EQ,C'JCP0911W',                                  03090001
             OR,6,8,CH,EQ,C'JCP0545W',                                  03100001
             OR,6,8,CH,EQ,C'JCP0456E',                                  03110001
             OR,6,8,CH,EQ,C'JCP5105W',                                  03120001
             OR,6,8,CH,EQ,C'JCP0438W',                                  03130001
             OR,((24,2,CH,EQ,C'PG'),AND,(34,4,CH,EQ,C'LOAD')),          03140001
             OR,((24,2,CH,EQ,C'PG'),AND,(34,4,CH,EQ,C'DATA')),          03150001
             OR,((24,2,CH,EQ,C'PG'),AND,(34,4,CH,EQ,C'CLIS')),          03160001
             OR,((24,2,CH,EQ,C'PG'),AND,(34,4,CH,EQ,C'DB2D')),          03170001
             OR,((24,2,CH,EQ,C'PG'),AND,(34,3,CH,EQ,C'SQL')),           03180001
             OR,((6,8,CH,EQ,C'JCP0451E'),AND,(24,2,CH,EQ,C'PN')),       03190001
             OR,((6,8,CH,EQ,C'JCP0451E'),AND,(24,2,CH,EQ,C'PG'))))      03200001
/*                                                                      03210001
//**********************************************************************03220001
//INCLUDES EXEC PGM=SORT                                                03230001
//**********************************************************************03240001
//SYSPRINT DD SYSOUT=*                                                  03250001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT          03260010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.INCLUDE,               03270010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT    03280010
//SYSOUT   DD SYSOUT=*                                                  03290001
//SYSIN    DD *                                                         03300001
 INCLUDE COND=((2,8,CH,EQ,C'JCP0411I'),                                 03310001
          AND,(11,7,CH,EQ,C'INCLUDE'))                                  03320001
 SORT FIELDS=(19,8,CH,A)                                                03330001
 SUM FIELDS=NONE                                                        03340001
/*                                                                      03350001
//**********************************************************************03360001
//MISSGDGS EXEC PGM=SORT                                                03370001
//**********************************************************************03380001
//SYSPRINT DD SYSOUT=*                                                  03390001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT          03400010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.GDGINDEX,              03410010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT    03420010
//SYSOUT   DD SYSOUT=*                                                  03430001
//SYSIN    DD *                                                         03440001
   SORT FIELDS=COPY                                                     03450001
   INCLUDE COND=((2,13,CH,EQ,C'--> JCP0546E '),                         03460001
              OR,(2,13,CH,EQ,C'-->         '''))                        03470001
/*                                                                      03480001
//**********************************************************************03490001
//GDGERRS  EXEC PGM=SORT                                                03500001
//**********************************************************************03510001
//SYSPRINT DD SYSOUT=*                                                  03520001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT          03530010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.GDGS,                  03540010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT    03550010
//SYSOUT   DD SYSOUT=*                                                  03560001
//SYSIN    DD *                                                         03570001
   SORT FIELDS=COPY                                                     03580001
   INCLUDE COND=((6,8,CH,EQ,C'JCP0596E'))                               03590001
/*                                                                      03600001
//**********************************************************************03610001
//STRMERR1 EXEC PGM=SORT                                                03620001
//**********************************************************************03630001
//SYSPRINT DD SYSOUT=*                                                  03640001
//SORTIN   DD DISP=SHR,DSN=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT          03650010
//SORTOUT  DD DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.DSNNOTR9,              03660010
//            DISP=(,CATLG),LIKE=TTEM.PCM.&JPREPID..JCLPREP.BATCHRPT    03670010
//SYSOUT   DD SYSOUT=*                                                  03680001
//SYSIN    DD *                                                         03690001
   SORT FIELDS=COPY                                                     03700001
   INCLUDE COND=((50,10,CH,EQ,C'PDS MEMBER'),                           03710001
             OR,((15,5,CH,EQ,C'DSN=T'),AND,(2,1,CH,EQ,C'X')),           03720001
             OR,((16,5,CH,EQ,C'DSN=T'),AND,(2,1,CH,EQ,C'X')),           03730001
             OR,((17,5,CH,EQ,C'DSN=T'),AND,(2,1,CH,EQ,C'X')),           03740001
             OR,((15,5,CH,EQ,C'DSN=P'),AND,(2,1,CH,EQ,C'X')),           03750001
             OR,((16,5,CH,EQ,C'DSN=P'),AND,(2,1,CH,EQ,C'X')),           03760001
             OR,((17,5,CH,EQ,C'DSN=P'),AND,(2,1,CH,EQ,C'X')))           03770001
/*                                                                      03780001
//**********************************************************************03790001
//STRMERR2 EXEC PGM=SORT                                                03800001
//**********************************************************************03810001
//SYSPRINT DD SYSOUT=*                                                  03820001
//SORTIN   DD DISP=SHR,                                                 03830001
//            DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.DSNNOTR9               03840010
//SORTOUT  DD DISP=OLD,                                                 03850001
//            DSN=TTEM.PCM.&JPREPID..JCLPREP.MSG.DSNNOTR9               03860010
//SYSOUT   DD SYSOUT=*                                                  03870001
//SYSIN    DD *                                                         03880001
   SORT FIELDS=COPY                                                     03890001
   INCLUDE COND=((23,4,CH,NE,C'.&JPREPID..'),                           03900008
               AND,(24,4,CH,NE,C'.&JPREPID..'),                         03910008
               AND,(25,4,CH,NE,C'.&JPREPID..'),                         03920008
               AND,(19,15,CH,NE,C'PGDF.BASE.CLIST'),                    03930001
               AND,(20,15,CH,NE,C'PGDF.BASE.CLIST'),                    03940001
               AND,(21,15,CH,NE,C'PGDF.BASE.CLIST'),                    03950001
               AND,(19,14,CH,NE,C'PGSP.BASE.LOAD'),                     03960001
               AND,(20,14,CH,NE,C'PGSP.BASE.LOAD'),                     03970001
               AND,(21,14,CH,NE,C'PGSP.BASE.LOAD'))                     03980001
/*                                                                      03990001

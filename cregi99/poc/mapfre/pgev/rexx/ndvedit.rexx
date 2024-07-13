/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 *  This routine is used to enhance the JCL build by the shipment    *
 *  process for implementation (cjob) & backout (bjob).              *
 *                                                                   *
 *  For an example look at any R0* member in PGEV.AUTO.CMJOBS on the *
 *  Qplex.                                                           *
 *                                                                   *
 * Assumptions:                                                      *
 *  //OAR.. JCL statements are DD statements used to define the      *
 *          shipment destination.                                    *
 *                                                                   *
 *  The DD statement for a staging dataset is the statement          *
 *  immediately prior to its corresponding //OAR dd statement.       *
 *                                                                   *
 *====                                                           ====*
 *  An "R" job calls this REXX for each destination.                 *
 *                                                                   *
 *  Input parameter RUNTYPE:                                         *
 *  "LOCAL"    = processing LOCAL JCL, don't update message          *
 *  "STANDARD" = processing Remote JCL for standard CMR              *
 *  "EMERGENCY"= processing Remote JCL for emergency CMR             *
 *                                                                   *
 *  The final parameter of the message can be set to three values:   *
 *  "NO"   =   no special processing                                 *
 *  "YES"  =   Switch job for DB2 processing                         *
 *  "PRO4" =   Do not demand "C" job.                                *
 *====                                                           ====*
 * The triggers variable is for the universal NDVEDIT process.       *
 *                                                                   *
 * Simply add you trigger value to the triggers variable below       *
 *  e.g. CDMLOGIC for PREV.PFJ1.CDMLOGIC                             *
 * and add the following variables                                   *
 *  <trigger>_scan - Variable to compare e.g.                        *
 *                 - lastqual or left(qual4,4) or qual3, qual4 etc.  *
 *  <trigger>_bpos - Where to add the Bjob JCL (see below)           *
 *  <trigger>_cpos - Where to add the Cjob JCL (see below)           *
 *   Values for above are 'before_iebcopy' 'after_iebcopy' 'evgussdi'*
 *  <trigger>_bsub - Subroutine to call for Bjob JCL (can be null)   *
 *  <trigger>_csub - Subroutine to call for Cjob JCL                 *
 *  <trigger>_bdel  - Add JCL for a //DEL ddname in the Bjob         *
 *  <trigger>_cdel  - Add JCL for a //DEL ddname in the Cjob         *
 *                                                                   *
 * Then add your JCL subroutine(s) at the end (before exception)     *
 *  Use the trigger name as the first part of the subroutine name    *
 *  E.g cdmlogic_jcl                                                 *
 *                                                                   *
 * The following variables will be available to the subroutine(s):   *
 *  jobtype              - value 'CJOB' or 'BJOB'                    *
 *  <trigger>_count      - The number of trigger datasets found      *
 *  <trigger>_dsn.       - Stem of target  dataset names             *
 *  <trigger>_stagedsn.  - Stem of staging dataset names             *
 *  <trigger>_stagedsnq. - Stem of Qplex staging dataset names       *
 *  cmjobname            - C0nnnnnn or B0nnnnnn                      *
 *  changeid specific runtype dest system_name trigger plexid        *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

/* The triggers must be in the order you want the JCL to be added    */
triggers = 'USS AIXSCRPT AIXCNTL CDMLOGIC CDMPCSVB CUSTCNTL' ,
           'DEPLOY DFHCSD DLICSD DSDEL DUMPRST' ,
           'MSTRMAP2 AOXPS' ,
           'SHIPDP SHIPOH SPDRDP SPCRDP SPRFDP SQLDP' ,
           'SVPARM RULES WALKJCL'

/* triggers_clone are triggers that are NOT switched off on clones   */
triggers_clone = 'USS DSDEL RULES SVPARM'

aixcntl_scan  = 'qual3'             /* To compare with trigger value */
aixcntl_bpos  = 'evgussdi'          /* Where to add the JCL          */
aixcntl_cpos  = 'evgussdi'          /* Where to add the JCL          */
aixcntl_bsub  = 'aixcntl_jcl'       /* Bjob JCL subroutine call      */
aixcntl_csub  = 'aixcntl_jcl'       /* Cjob JCL subroutine call      */
aixcntl_bdel  = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
aixcntl_cdel  = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

aixscrpt_scan = 'qual3'             /* To compare with trigger value */
aixscrpt_bpos = 'evgussdi'          /* Where to add the JCL          */
aixscrpt_cpos = 'evgussdi'          /* Where to add the JCL          */
aixscrpt_bsub = 'aixscrpt_jcl'      /* Bjob JCL subroutine call      */
aixscrpt_csub = 'aixscrpt_jcl'      /* Cjob JCL subroutine call      */
aixscrpt_bdel = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
aixscrpt_cdel = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

aoxps_scan    = 'lastqual'          /* To compare with trigger value */
aoxps_bpos    = 'after_iebcopy'     /* Where to add the JCL          */
aoxps_cpos    = 'after_iebcopy'     /* Where to add the JCL          */
aoxps_bsub    = 'aoxps_jcl'         /* Bjob JCL subroutine call      */
aoxps_csub    = 'aoxps_jcl'         /* Cjob JCL subroutine call      */
aoxps_bdel    = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
aoxps_cdel    = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

cdmlogic_scan = 'lastqual'          /* To compare with trigger value */
cdmlogic_bpos = 'evgussdi'          /* Where to add the JCL          */
cdmlogic_cpos = 'evgussdi'          /* Where to add the JCL          */
cdmlogic_bsub = ''                  /* Bjob JCL subroutine call      */
cdmlogic_csub = 'cdmlogic_jcl'      /* Cjob JCL subroutine call      */
cdmlogic_bdel = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
cdmlogic_cdel = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

cdmpcsvb_scan = 'lastqual'          /* To compare with trigger value */
cdmpcsvb_bpos = 'evgussdi'          /* Where to add the JCL          */
cdmpcsvb_cpos = 'evgussdi'          /* Where to add the JCL          */
cdmpcsvb_bsub = 'cdmpcsvb_jcl'      /* Bjob JCL subroutine call      */
cdmpcsvb_csub = 'cdmpcsvb_jcl'      /* Cjob JCL subroutine call      */
cdmpcsvb_bdel = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
cdmpcsvb_cdel = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

custcntl_scan = 'lastqual'          /* For type CUSTMAP              */
custcntl_bpos = 'after_iebcopy'     /* Where to add the JCL          */
custcntl_cpos = 'after_iebcopy'     /* Where to add the JCL          */
custcntl_bsub = ''                  /* Bjob JCL subroutine call      */
custcntl_csub = 'custcntl_jcl'      /* Cjob JCL subroutine call      */
custcntl_bdel = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
custcntl_cdel = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

deploy_scan   = 'left(lastqual,6)'  /* To compare with trigger value */
deploy_bpos   = 'evgussdi'          /* Where to add the JCL          */
deploy_cpos   = 'evgussdi'          /* Where to add the JCL          */
deploy_bsub   = 'deploy_jcl'        /* Bjob JCL subroutine call      */
deploy_csub   = 'deploy_jcl'        /* Cjob JCL subroutine call      */
deploy_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
deploy_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

dfhcsd_scan   = 'lastqual'          /* To compare with trigger value */
dfhcsd_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
dfhcsd_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
dfhcsd_bsub   = 'csd_jcl'           /* Bjob JCL subroutine call      */
dfhcsd_csub   = 'csd_jcl'           /* Cjob JCL subroutine call      */
dfhcsd_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
dfhcsd_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

dlicsd_scan   = 'lastqual'          /* To compare with trigger value */
dlicsd_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
dlicsd_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
dlicsd_bsub   = 'csd_jcl'           /* Bjob JCL subroutine call      */
dlicsd_csub   = 'csd_jcl'           /* Cjob JCL subroutine call      */
dlicsd_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
dlicsd_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

dsdel_scan    = 'lastqual'          /* To compare with trigger value */
dsdel_bpos    = 'after_iebcopy'     /* Where to add the JCL          */
dsdel_cpos    = 'after_iebcopy'     /* Where to add the JCL          */
dsdel_bsub    = 'dsdel_jcl'         /* Bjob JCL subroutine call      */
dsdel_csub    = 'dsdel_jcl'         /* Cjob JCL subroutine call      */
dsdel_bdel    = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
dsdel_cdel    = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

dumprst_scan   = 'left(lastqual,7)' /* To compare with trigger value */
dumprst_bpos   = 'before_iebcopy'   /* Where to add the JCL          */
dumprst_cpos   = 'after_iebcopy'    /* Where to add the JCL          */
dumprst_bsub   = 'dumprst_jcl_b'    /* Bjob JCL subroutine call      */
dumprst_csub   = 'dumprst_jcl_i'    /* Cjob JCL subroutine call      */
dumprst_bdel   = 'N'                /* Build JCL on //DEL DDs in Bjob*/
dumprst_cdel   = 'N'                /* Build JCL on //DEL DDs in Cjob*/

mstrmap2_scan = 'lastqual'          /* To compare with trigger value */
mstrmap2_bpos = 'after_iebcopy'     /* Where to add the JCL          */
mstrmap2_cpos = 'after_iebcopy'     /* Where to add the JCL          */
mstrmap2_bsub = ''                  /* Bjob JCL subroutine call      */
mstrmap2_csub = 'mstrmap2_jcl'      /* Cjob JCL subroutine call      */
mstrmap2_bdel = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
mstrmap2_cdel = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

rules_scan    = 'qual4'             /* To compare with trigger value */
rules_bpos    = 'after_iebcopy'     /* Where to add the JCL          */
rules_cpos    = 'after_iebcopy'     /* Where to add the JCL          */
rules_bsub    = 'rules_jcl'         /* Bjob JCL subroutine call      */
rules_csub    = 'rules_jcl'         /* Cjob JCL subroutine call      */
rules_bdel    = 'Y'                 /* Build JCL on //DEL DDs in Bjob*/
rules_cdel    = 'Y'                 /* Build JCL on //DEL DDs in Cjob*/

shipdp_scan   = 'left(lastqual,6)'  /* To compare with trigger value */
shipdp_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
shipdp_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
shipdp_bsub   = ''                  /* Bjob JCL subroutine call      */
shipdp_csub   = 'db2_jcl'           /* Cjob JCL subroutine call      */
shipdp_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
shipdp_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

shipoh_scan   = 'left(lastqual,6)'  /* To compare with trigger value */
shipoh_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
shipoh_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
shipoh_bsub   = 'shipoh_jcl'        /* Bjob JCL subroutine call      */
shipoh_csub   = 'shipoh_jcl'        /* Cjob JCL subroutine call      */
shipoh_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
shipoh_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

spdrdp_scan   = 'left(lastqual,6)'  /* To compare with trigger value */
spdrdp_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
spdrdp_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
spdrdp_bsub   = 'db2_jcl'           /* Bjob JCL subroutine call      */
spdrdp_csub   = 'db2_jcl'           /* Cjob JCL subroutine call      */
spdrdp_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
spdrdp_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

spcrdp_scan   = 'left(lastqual,6)'  /* To compare with trigger value */
spcrdp_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
spcrdp_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
spcrdp_bsub   = 'db2_jcl'           /* Bjob JCL subroutine call      */
spcrdp_csub   = 'db2_jcl'           /* Cjob JCL subroutine call      */
spcrdp_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
spcrdp_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

sprfdp_scan   = 'left(lastqual,6)'  /* To compare with trigger value */
sprfdp_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
sprfdp_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
sprfdp_bsub   = 'db2_jcl'           /* Bjob JCL subroutine call      */
sprfdp_csub   = 'db2_jcl'           /* Cjob JCL subroutine call      */
sprfdp_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
sprfdp_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

sqldp_scan    = 'left(lastqual,5)'  /* To compare with trigger value */
sqldp_bpos    = 'before_iebcopy'    /* Where to add the JCL          */
sqldp_cpos    = 'after_iebcopy'     /* Where to add the JCL          */
sqldp_bsub    = 'sqldp_jcl'         /* Bjob JCL subroutine call      */
sqldp_csub    = 'sqldp_jcl'         /* Cjob JCL subroutine call      */
sqldp_bdel    = 'Y'                 /* Build JCL on //DEL DDs in Bjob*/
sqldp_cdel    = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

svparm_scan   = 'left(lastqual,6)'  /* To compare with trigger value */
svparm_bpos   = 'after_iebcopy'     /* Where to add the JCL          */
svparm_cpos   = 'after_iebcopy'     /* Where to add the JCL          */
svparm_bsub   = 'svparm_jcl'        /* Bjob JCL subroutine call      */
svparm_csub   = 'svparm_jcl'        /* Cjob JCL subroutine call      */
svparm_bdel   = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
svparm_cdel   = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

uss_scan      = 'lastqual'          /* To compare with trigger value */
uss_bpos      = 'after_iebcopy'     /* Where to add the JCL          */
uss_cpos      = 'after_iebcopy'     /* Where to add the JCL          */
uss_bsub      = 'uss_jcl'           /* Bjob JCL subroutine call      */
uss_csub      = 'uss_jcl'           /* Cjob JCL subroutine call      */
uss_bdel      = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
uss_cdel      = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

walkjcl_scan  = 'lastqual'          /* To compare with trigger value */
walkjcl_bpos  = 'after_iebcopy'     /* Where to add the JCL          */
walkjcl_cpos  = 'after_iebcopy'     /* Where to add the JCL          */
walkjcl_bsub  = 'walkjcl_jcl'       /* Bjob JCL subroutine call      */
walkjcl_csub  = 'walkjcl_jcl'       /* Cjob JCL subroutine call      */
walkjcl_bdel  = 'N'                 /* Build JCL on //DEL DDs in Bjob*/
walkjcl_cdel  = 'N'                 /* Build JCL on //DEL DDs in Cjob*/

/* Check if user is the production release user - for the ship hlq   */
resourcename = 'PREW.PACKAGE.EXECUTE.*.CP.*'
classname    = 'FACILITY'
a = outtrap('rescheck.','*')
address tso "RESCHECK RESOURCE("resourcename") ,
             CLASS("classname")"
reschkrc = rc
a = outtrap('off')
if reschkrc = 0 then shiphlq = 'PGEV.SHIP'
                else shiphlq = 'TTEV.SHIP'

/* CA7 parameters                                                    */
switch_CA7  = 'NO'
sysaff      = ''
ca7_stepno  = 0 /* Counter for CA7 demand step numbers in ca7_demand */

/* Get parameters change management no. and whether a specific chng  */
parse arg changeid specific runtype dest system_name

plexid = substr(dest,5,1)

say rexxname':' Date() Time()
say rexxname': '
say rexxname': Change id passed from the JCL:' changeid
say rexxname': Specific/Global              :' specific
say rexxname': Runtype                      :' runtype
say rexxname': Dest                         :' dest
say rexxname': System name                  :' system_name
say rexxname': '

/* Read table and set variables                                      */
"execio * diskr destvar (stem destvar. finis"
if rc ^= 0 then call exception rc 'DISKR of DESTVAR failed'

do i = 1 to destvar.0
  interpret destvar.i
end /* i = 1 to destvar.0 */

/* OBTAIN allocated DSNS FOR JCL AND JCLB                            */
/* JCL  is the DDname associated with the Cjob                       */
/* JCLB is the DDname associated with the Bjob                       */
x = listdsi(JCL  file)
dsn_AHJOB = sysdsname
say rexxname': DDNAME JCL allocated to' dsn_AHJOB
say rexxname': '

x = listdsi(JCLB file)
dsn_CHJOB = sysdsname
say rexxname': DDNAME JCLB allocated to' dsn_CHJOB
say rexxname': '

/* Start Ship Pass Update Shipment Output Datasets                   */
say rexxname': Shipping Update'
say rexxname': '
say rexxname': Update DSNS from' mapcheck'.Pxx1.yyyyyy'
say rexxname':               to' substr(mapcheck,5,2)'xx.BASE.yyyyyy'
say rexxname': '

/* set var for shipment translation                                  */
pos2 = 9
pos3 = 10

/* Set the JCL dataset names                                         */
i = index(dsn_AHJOB,"AHJOB")
if i > 0 then dsn_ARJOB = overlay("ARJOB",dsn_AHJOB,i,5)
         else dsn_ARJOB = dsn_AHJOB

say rexxname': REMOTE JCL will be' dsn_ARJOB
say rexxname': '

i = index(dsn_CHJOB,"CHJOB")
if i > 0 then dsn_CRJOB = overlay("CRJOB",dsn_CHJOB,i,5)
         else dsn_CRJOB = dsn_CHJOB

say rexxname': REMOTE BACKOUT will be' dsn_CRJOB
say rexxname': '

/* Shipment Update for Bjob JCL                                      */
call ship_update 1 JCLB

/* Shipment Update for Cjob JCL                                      */
call ship_update 2 JCL

if specific <> 'G' then do
  say rexxname': '
  say rexxname': This is a specific change.'
end /* specific <> 'G' */

/* Start backout JCL processing                                      */
jobtype   = 'BJOB'
cmjobname = overlay('B',changeid)
card.     = ''

"execio * diskr jclb  (stem card. finis"
if rc ^= 0 then call exception rc 'DISKR of JCLB failed'

say rexxname':'
say rexxname':' card.0 'Lines of backout JCL read'
say rexxname':'

/* Start of pass Three - Analyse Bjob                                */
Say rexxname': +--------------------------------------------+'
Say rexxname': ! Pass 3 scanning for relevant items in Bjob !'
Say rexxname': +--------------------------------------------+'

call analysejclu         /* Universal trigger process                */
call analysejcl '//OCR'  /* Old       trigger process                */

if specific <> 'G' then call editdel  '//DEL'

if csfddl = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT detected the DDL target'
  say rexxname': '
  say rexxname': Trigger DSN :' ddl.dsn
  say rexxname': DDL DSN     :' ddl.stagedsn
end /* csfddl = 'yes' */

if coldstar = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT detected the COLDSTAR target'
  say rexxname': '
  say rexxname': Trigger DSN :' coldstar.dsn
  say rexxname': Staging DSN :' coldstar.stagedsn
end /* coldstar = 'yes' */

if jobin = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT detected the JOBIN target'
  say rexxname': '
  say rexxname': Trigger DSN :' jobin.dsn
  say rexxname': Staging DSN :' jobin.stagedsn
end /* jobin = 'yes' */

if affinity = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT detected the AFFINITY target'
  say rexxname': '
  say rexxname': Trigger DSN :' affinity.dsn
  say rexxname': Staging DSN :' affinity.stagedsn
end /* affinity = 'yes' */

say rexxname': '
say rexxname': +---------------+'
say rexxname': ! End of Pass 3 !'
say rexxname': +---------------+'
say rexxname':'

/* Start of pass four - Update  Bjob                                 */
Say rexxname': +--------------------------------------------+'
Say rexxname': ! Start of Pass 4 modifying the Bjob JCL     !'
Say rexxname': +--------------------------------------------+'

do current = 1 to card.0 /* Loop through backout JCL again           */

  /* If this is the jobcard AND we have found Ideal processing       */
  /* AND it is on the Nplex then add a SCHENV parameter              */
  if current < 3        & ,
     (pnlbjob  = 'YES' | ,
      pgmbjob  = 'YES' | ,
      sqlpbjob = 'YES') & ,
     pos('USER=',card.current) > 0 & ,
     dest = 'PLEXN1'    then do
    card.current = strip(card.current)
    card.current = strip(card.current,,',')','
    queue card.current /* write out line                             */
    queue '//             SCHENV=MUFPRDUP'
    iterate
  end /* current < 3 & ... */

  queue card.current /* write out line                               */

  /* Find before IEBCOPY eyecatcher                                  */
  if card.current = '//*-- NDVEDIT STEPS BEFORE IEBCOPY --' then do
    queue "//*                                                        "

    /*   If required insert the QMF JCL                              */
    if qmfcount > 0 then
      call qmfaddjcl 'BJOB'

    /*   If required insert JCL for the universal trigger process    */
    call trigger_call 'before_iebcopy'

    queue '//*-- END OF NDVEDIT STEPS BEFORE IEBCOPY --'

  end /* card.current = '// -- NDVEDIT STEPS BEFORE IEBCOPY --' */

  /* Find after  IEBCOPY eyecatcher                                  */
  if card.current = '//*-- NDVEDIT STEPS AFTER IEBCOPY --' then do
    queue "//*                                                        "

    /*   If required insert the RACF JCL                             */
    if racfjob = 'yes' then do
      say rexxname': '
      say rexxname': NDVEDIT detected RACF shipment'
      say rexxname': RACF command execution JCL will be added'
      call addracfjcl 'BJOB'
    end /* racfjob = 'yes' */

    if backpro4 = 'YES' then do
      call pro4appl
      call addpro4jclb
      backpro4 = 'no'
    end /* backpro4 = 'YES' */

    if backpro4i = 'YES' then call addpro4ib

    if sqlpbjob = 'YES' then do
      /* if first promote of the element then backout will           */
      /* delete the member. This means no reason to do the identify  */
      if sqlplan.stagedsn = '' then iterate
      /* use the routine to build the Bjob jcl using the base dsn    */
      call sqlplanjcl sqlplan.stagedsn sqlplan.dsn sqlplan bjob
    end /* sqlpbjob = 'YES' */

    if pnlbjob = 'YES' then do
      /* if first promote of the element then backout will           */
      /* delete the member. This means no reason to do the identify  */
      if ship_SHIPPNL_stagedsn = '' then iterate
      /* use the routine to build the Bjob jcl to identify the backed*/
      /* out code                                                    */
      call idealjcl ship_SHIPPNL_stagedsn ship_SHIPPNL_dsn pnl bjob
    end /* pnlbjob = 'YES' */

    if pgmbjob = 'YES' then do
      /* if this is first promote of the element then backout will   */
      /* delete the member. This means no reason to do the identify  */
      if ship_SHIPPGM_stagedsn = '' then iterate
      /* use the routine to build the Bjob jcl to identify the       */
      /* backed out code                                             */
      call idealjcl ship_SHIPPGM_stagedsn ship_SHIPPGM_dsn pgm bjob
    end /* pgmbjob = 'YES' */

    /* Insert backout jcl for batch services wizard changes          */
    /* step will insert iebcopy step for each member                 */
    if wizard = 'YES' then do
      say rexxname': Wizard backout JCL inserted before line:' current

      do i = 1 to wizcount
        "ALLOC F(BJCL) DSNAME('"wizdsn.i"("bjcl")') SHR"
        'EXECIO * DISKR BJCL (STEM BJCLX. FINIS'
        "FREE F(BJCL)"

        do a = 1 to bjclx.0
          call wiz_update bjclx.a
          queue thiswiz
        end /* a = 1 to bjclx.0 */

      end /* i = 1 to wizcount */

    end /* wizard = yes */
    /* Insert backout jcl for batch services wizard changes          */
    /* step will insert iebcopy step for each member                 */
    if wizard = 'YES' & runtype = 'LOCAL' then do
      say rexxname': Additional Wizard backout JCL inserted'
      do i = 1 to wizcount
        "ALLOC F(XJCL) DSNAME('"wizdsn.i"("xjcl")') SHR"
        'EXECIO * DISKR XJCL (STEM XJCLX. FINIS'
        "FREE F(XJCL)"
        do a = 1 to xjclx.0
          call wiz_update xjclx.a
          queue thiswiz
        end /* a = 1 to xjcl.0 */
      end /* i = 1 to wizcount */
    end /* wiz & runtype */


    /*   If required insert the CSF DDL JCL                          */
    if csfddl = 'yes' then call ddladdjcl

    /*   If required insert the COLDSTAR JCL                         */
    if coldstar = 'yes' then call coldstaraddjcl

    /*   If required insert the JOBIN JCL                            */
    if jobin = 'yes' then call jobinaddjcl

    /*   If required insert the AFFINITY JCL                         */
    if affinity = 'yes' then call affinityaddjcl

    /*   If required insert JCL for the universal trigger process    */
    call trigger_call 'after_iebcopy'

    queue '//*-- END OF NDVEDIT STEPS AFTER IEBCOPY --'

  end /* card.current = '// -- NDVEDIT STEPS AFTER  IEBCOPY --' */

end /* current = 1 to card.0 */

say rexxname':'
say rexxname':' queued() 'Lines of backout JCL to be written.'

/* Write out the lines which have been queued                        */
"execio * diskw jclb  (finis"
if rc ^= 0 then call exception rc 'DISKW to JCLB failed'

Say rexxname': '
Say rexxname': +---------------+'
Say rexxname': ! End of Pass 4 !'
Say rexxname': +---------------+'
Say rexxname': '

/* Start Change  JCL processing                                      */
jobtype   = 'CJOB'
cmjobname = changeid
card.     = ''

"execio * diskr jcl   (stem card. finis"
if rc ^= 0 then call exception rc 'DISKR of JCL failed'

say rexxname':'
say rexxname':' card.0 'Lines of change JCL read'
say rexxname':'

/* Start of pass five  - Analyse C job                               */
ca7_stepno = 0 /* Counter for CA7 demand step numbers in ca7_demand  */

say rexxname': +--------------------------------------------+'
say rexxname': ! Pass 5 scanning for relevant items in Cjob !'
say rexxname': +--------------------------------------------+'

call analysejclu         /* Universal trigger process                */
call analysejcl '//OAR'  /* Old       trigger process                */

/* Process the information found in pass five,                       */
/* to deduce what updates are required in pass six                   */

if pro4 = 'EMERGENCY' then do
  say rexxname': '
  say rexxname': This is an emergency change, releasing to .BOOTS'
  say rexxname': JCL will be added to demand the PRO-IV utility jobs.'
  say rexxname': '
  say rexxname': Found BOOTS'
  say rexxname': Destination DSN:' mt.dsn
  say rexxname': Staging DSN    :' mt.stagedsn
  say rexxname': '
  pro4bkup = 'yes'
end /* pro4 = 'EMERGENCY' */

if pro4 = 'LOCAL' then do
  say rexxname': '
  say rexxname': This is an standard change, releasing to .BOOTS'
  say rexxname': at the LOCAL site, so no updates will be made.'
end /* pro4 = 'LOCAL' */

if pro4 = 'STANDARD' then do
  say rexxname': '
  say rexxname': This is an standard change, releasing to .BOOTS'
  say rexxname': at the remote site.  Message will be set to "PRO4".'
  pro4bkup = 'yes'
end /* pro4 = 'STANDARD' */

if pro4bkup = 'yes' then
  call pro4appl

if speccount > 0 then
  do x = 1 to speccount
    say rexxname': '
    say rexxname': Specific Target DSN:' spec.dsn.x
    say rexxname': Specific Stage DSN :' spec.stagedsn.x
  end /* x = 1 to speccount */

if csfddl = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT created JCL for CSF DDLs'
  say rexxname': DDL JCL wil be added.'
  say rexxname': '
  say rexxname': Found DDL.'
  say rexxname': Destination DSN:' ddl.dsn
  say rexxname': Staging DSN    :' ddl.stagedsn
end /* csfddl = 'yes' */

if coldstar = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT created JCL for COLDSTAR copies'
  say rexxname': COLDSTAR JCL wil be added.'
  say rexxname': '
  say rexxname': Destination DSN:' coldstar.dsn
  say rexxname': Staging DSN    :' coldstar.stagedsn
end /* coldstar = 'yes' */

if jobin = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT created JCL for JOBIN members'
  say rexxname': CA7 API JCL may be added.'
  say rexxname': '
  say rexxname': Destination DSN:' jobin.dsn
  say rexxname': Staging DSN    :' jobin.stagedsn
end /* jobin = 'yes' */

if affinity = 'yes' then do
  say rexxname': '
  say rexxname': NDVEDIT created JCL for AFFINITY copies'
  say rexxname': AFFINITY JCL wil be added.'
  say rexxname': '
  say rexxname': Destination DSN:' affinity.dsn
  say rexxname': Staging DSN    :' affinity.stagedsn
end /* affinity = 'yes' */

if qmfcount > 0 then do
  say rexxname': '
  say rexxname': NDVEDIT detected' qmfcount,
      'QMF targets'
  say rexxname': QMF JCL will be added.'
  do x = 1 to qmfcount
    say rexxname': '
    say rexxname': Trigger DSN:' qmf.dsn.x
    say rexxname': Application:' qmf.appl.x
    say rexxname': QMF code   :' qmf.target.x
  end  /* x = 1 to qmfcount */
end /* qmfcount > 0 */

say rexxname': '
say rexxname': +---------------+'
say rexxname': ! End of Pass 5 !'
say rexxname': +---------------+'
say rexxname': '

/* Start of pass six  -  Update C job                                */

x = 1 /* "x" is used to count through OAR statements                 */

say rexxname': +----------------------------------------+'
Say rexxname': ! Start of Pass 6 modifying the Cjob JCL !'
Say rexxname': +----------------------------------------+'

do current=1 to card.0 /* Loop through the JCL again                 */

  /* If this is the jobcard AND we have found Ideal processing       */
  /* AND it is on the Nplex then add a SCHENV parameter              */
  if current < 3        & ,
     (pnlcjob  = 'YES' | ,
      pgmcjob  = 'YES' | ,
      sqlpcjob = 'YES') & ,
     pos('USER=',card.current) > 0 & ,
     dest = 'PLEXN1'    then do
    card.current = strip(card.current)
    card.current = strip(card.current,,',')','
    queue card.current /* write out line                             */
    queue '//             SCHENV=MUFPRDUP'
    iterate
  end /* current < 3 & ... */

  /* Add shiphlqs eyecatcher for REFER REXX in case there is no      */
  /* IEBCOPY step for this Cjob.                                     */
  if card.current = '//*-- NDVEDIT STEPS BEFORE IEBCOPY --' then do
    queue "//*   SHIPHLQS" left(dsn_ahjob,25)
    queue "//*                                                        "
  end /* card.current = '// -- NDVEDIT STEPS BEFORE IEBCOPY --' */

  queue card.current /* write out line                               */

  /* Find before IEBCOPY eyecatcher                                  */
  if card.current = '//*-- NDVEDIT STEPS BEFORE IEBCOPY --' then do
    queue "//*                                                        "

    if speccount > 0 then do
      dsnsdone=''
      queue '//STEP05 EXEC PGM=IEFBR14'
      do i = 1 to speccount
        if wordpos(spec.dsn.i,dsnsdone) = 0 then do
          queue "//SPEC"right(i,4,'0')" DD DSN="spec.dsn.i","
          queue "//       DISP=(NEW,CATLG),"
          queue "//       LIKE="spec.stagedsn.i","
          queue "//       DCB="spec.stagedsn.i","
          queue "//       UNIT=DASD,DATACLAS=PDSNCOMP"
          dsnsdone = dsnsdone spec.dsn.i
        end /* wordpos(spec.dsn.i,dsnsdone) = 0 */
      end /* i = 1 to speccount */
    end /* speccount > 0 */

    /* If wizard type change insert jcl for each change ,            */
    /* wizcount is the number of changes being made                  */

    if wizard = 'YES' then do
      do i = 1 to wizcount
        "ALLOC F(IJCL) DSNAME('"wizdsn.i"("ijcl")') SHR"
        'EXECIO * DISKR IJCL (STEM IJCLX. FINIS'
        "FREE F(IJCL)"
        say rexxname': Wizard Cjob JCL inserted before line:' current
        do a = 1 to ijclx.0
          call wiz_update ijclx.a
          queue thiswiz
        end  /* end of loop through jcl */
        if dest = 'PLEXE1' then do
          /* Add in progress CMPARM delete member JCL                */
          "ALLOC F(PJCL) DSNAME('"wizdsn.i"("pjcl")') SHR"
          'EXECIO * DISKR PJCL (STEM PJCLX. FINIS'
          "FREE F(PJCL)"
          do a = 1 to pjclx.0
            queue pjclx.a
          end  /* end of loop through jcl */
        end  /* dest = PLEXE1 */
      end  /* loop until end of wizcount */
    end  /* end of wizard insert for cjob */

    if pro4bkup = 'yes' then do /* banking PRO4                      */
      call addpro4bkup
      if dest = "PLEXP1" then do
        call addevd888d
      end /* plexp1 */
      queue "//****************************************************"
      queue "//**       STEP010 COPY FROM STAGING LIBRARIES        "
      queue "//****************************************************"
    end /* pro4bkup = 'yes' */

    if pro4ibkup = 'YES' then do
      call addipro4bkup
      if pro4ilife = 'YES' then
        call addibkapp 'L LIFE' lifeload lifeexec lifedev lifegen
      if pro4iloan = 'YES' then
        call addibkapp 'P LOAN' obbload loanexec loandev loangen
      if pro4isavg = 'YES' then
        call addibkapp 'S SAVG' obbload savgexec savgdev savggen
      if pro4icall = 'YES' then
        call addibkapp 'X CALL' obbload callexec calldev callgen
      call pro4iappl
    end /* pro4ibkup = 'yes' */

    /* use the routine to build the Cjob jcl using the staging dsn   */
    if sqlpcjob = 'YES' then
      call sqlplanjcl sqlplan.stagedsn sqlplan.dsn sqlplan cjob

    /*   If required insert JCL for the universal trigger process    */
    call trigger_call 'before_iebcopy'

    queue '//*-- END OF NDVEDIT STEPS BEFORE IEBCOPY --'

  end /* card.current = '// -- NDVEDIT STEPS BEFORE IEBCOPY --' */

  /* Find after  IEBCOPY eyecatcher                                  */
  if card.current = '//*-- NDVEDIT STEPS AFTER IEBCOPY --' then do
    queue "//*                                                        "

    if pnlcjob = 'YES' then
      /* use the routine to build the Cjob jcl using the staging dsn */
      call idealjcl ship_SHIPPNL_stagedsn ship_SHIPPNL_dsn pnl cjob

    if pgmcjob = 'YES' then
      /* use the routine to build the Cjob jcl using the staging dsn */
      call idealjcl ship_SHIPPGM_stagedsn ship_SHIPPGM_dsn pgm cjob

    /*   If required insert the RACF JCL                             */
    if racfjob = 'yes' then do
      say rexxname': '
      say rexxname': NDVEDIT detected RACF shipment'
      say rexxname': RACF command execution JCL will be added'
      call addracfjcl 'CJOB'
    end /* racfjob = 'yes' */

    /*   If required insert the Pro-IV JCL                           */
    if pro4 = 'EMERGENCY' then do
      say rexxname': '
      say rexxname': Inserting PRO-IV JCL before line:' current
      call addpro4jcl
    end /* pro4 = 'EMERGENCY' */

    /*   If required insert the CSF DDL JCL                          */
    if csfddl = 'yes' then call ddladdjcl

    /*   If required insert the COLDSTAR JCL                         */
    if coldstar = 'yes' then call coldstaraddjcl

    /*   If required insert the JOBIN JCL                            */
    if jobin = 'yes' then call jobinaddjcl

    /*   If required insert the AFFINITY JCL                         */
    if affinity = 'yes' then call affinityaddjcl

    /*   If required insert the QMF JCL                              */
    if qmfcount > 0 then call qmfaddjcl 'CJOB'

    /*   If required insert JCL for the universal trigger process    */
    call trigger_call 'after_iebcopy'

    queue '//*-- END OF NDVEDIT STEPS AFTER IEBCOPY --'

  end /* card.current = '// -- NDVEDIT STEPS AFTER  IEBCOPY --' */

end /* card.current */

/* Write out the lines which have been queued                        */
say rexxname':'
say rexxname': 'queued() 'Lines of JCL to be written.'

"execio * diskw jcl   (finis"
if rc > 0 then do
  say rexxname': Error writing change JCL. RC=' rc
  exit(40)
end /* if rc > 0 */

Say rexxname': '
Say rexxname': +---------------+'
Say rexxname': ! End of Pass 6 !'
Say rexxname': +---------------+'
Say rexxname': '

/* Create and Submit BINDBACK job(s)                                 */
if wordpos(dest,adddb2jcl) > 0 then
  if spcrdp_count > 0 | shipdp_count > 0 then call db2back

say rexxname': '
say rexxname': End of run'
say rexxname': '

exit(0)

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Translate shipment datasets                                       */
/*-------------------------------------------------------------------*/

ship_update:

 PARSE ARG pass ddname

 Say rexxname': +------------------------------------------+'
 Say rexxname': ! Pass 'pass' Shipment Translation for DD: 'ddname' !'
 Say rexxname': +------------------------------------------+'

 "execio * diskr "ddname " (stem ship. finis"
 if rc > 0 then exit(5) ;

 /*------------------------------------------------------------------*/
 /* Read through all the JCL statements                              */
 /*------------------------------------------------------------------*/

 do c = 1 to ship.0

   if INDEX(ship.c,mapcheck) ^= 0 then do
     say rexxname': '
     say rexxname': Updating From:' ship.c
     DSNPOS  = INDEX(ship.c,mapcheck)
     DSNPOS1 = DSNPOS+6
     DSNPOS2 = DSNPOS+pos2
     DSNPOS3 = DSNPOS+pos3
     ship.c  = OVERLAY(SUBSTR(ship.c,DSNPOS3,2),ship.c,DSNPOS1)
     ship.c  = OVERLAY('BASE',ship.c,DSNPOS2)
     say rexxname': '
     say rexxname': Updating To  :' ship.c
   end /* INDEX(ship.c,mapcheck) ^= 0 */

   /* For cloned shipments change the name of syscics.base.proclib   */
   if wordpos(dest,clones) > 0 then do
     dsnpos = index(ship.c,'SYSCICS.BASE.PROCLIB')
     if dsnpos > 0 then do
       say rexxname': '
       say rexxname': Updating From:' ship.c
       dsnpos = dsnpos - 1
       ship.c = left(ship.c,dsnpos) || ,
                'PGEV.PSP1.CICSPROC.PPLEX'
       say rexxname': '
       say rexxname': Updating To  :' ship.c
     end /* dsnpos > 0 */
   end /* wordpos(dest,clones) > 0 */

   /* Only ship the PGAO.BASE.xxxx.RULES/REXX libraries that match   */
   /* the target PLEX, for example we will only ship;                */
   /*                                                                */
   /*    PGAO.BASE.PINF.RULES to PLEXP1                              */
   /*    PGAO.BASE.MSEC.REXX  to PLEXM1                              */
   /*                                                                */
   /* The first character of the 3 qualifier must match the fifth    */
   /* character of the PLEX name. All other libraries will be        */
   /* suffixed with '.DUMMY'                                         */
   dsnpos = index(ship.c,PGAO.BASE)
   if dsnpos > 0 then do
     cquals = translate(substr(ship.c,dsnpos),' ','.')
     qual3  = word(cquals,3)
     qual4  = word(cquals,4)
     qual5  = word(cquals,5)
     if (qual4 = 'RULES' | qual4 = 'REXX') & qual5 = '' then do

       If left(Qual3,1) <> substr(dest,5,1) then do
         say rexxname': '
         say rexxname': Updating From:' ship.c
         ship.c = strip(ship.c)'.DUMMY'
         say rexxname': '
         say rexxname': Updating To  :' ship.c
       end /* left(Qual3,1) <> substr(dest,5,1) */

     end /* (qual4 = 'RULES' | qual4 = 'REXX') & qual5 = '' */

   end /* dsnpos > 0 */

   /* Only ship the PGSQ.BASE.%RACFCMD libraries that match the      */
   /* target PLEX for cloned shipments. E.g.                         */
   /*                                                                */
   /*    PGSQ.BASE.PRACFCMD   to PLEXP1                              */
   /*    PGSQ.BASE.MRACFCMD   to PLEXM1                              */
   /*                                                                */
   /* The first character of the 3 qualifier must match the fifth    */
   /* character of the PLEX name. All other libraries will be        */
   /* suffixed with '.DUMMY'                                         */
   dsnpos = index(ship.c,PGSQ.BASE)

   if dsnpos > 0 then do
     cquals = translate(substr(ship.c,dsnpos),' ','.')
     qual3  = word(cquals,3)

     if right(qual3,7) = 'RACFCMD' then do

       if left(qual3,1) <> substr(dest,5,1) then do
         say rexxname': '
         say rexxname': Updating From:' ship.c
         ship.c = strip(ship.c)'.DUMMY'
         say rexxname': '
         say rexxname': Updating To  :' ship.c
       end /* left(Qual3,1) <> substr(dest,5,1) */

     end /* right(qual3,7) = 'RACFCMD' */

   end /* dsnpos > 0 */

   /* Only ship the PGSY.BASE.APPPROC% datasets that match the       */
   /* target PLEX for cloned shipments. E.g.                         */
   /*                                                                */
   /*    PGSY.BASE.APPPROCP   to PLEXP1                              */
   /*    PGSY.BASE.APPPROCQ   to PLEXQ1                              */
   /*                                                                */
   /* The last character of the 3rd qualifier must match the fifth   */
   /* character of the PLEX name. All other datasets will be renamed */
   /* to PGEV.PSY1.qualifier                                         */
   dsnpos = pos('PGSY.BASE',ship.c)

   if dsnpos > 0 then do
     cquals = translate(substr(ship.c,dsnpos),' ','.')
     qual3  = word(cquals,3)

     if left(qual3,7) = 'APPPROC' then do
       if right(qual3,1) <> substr(dest,5,1) then do
         say rexxname': '
         say rexxname': Updating From:' ship.c
         dsnpos = dsnpos - 1
         ship.c = left(ship.c,dsnpos)'PGEV.PSY1.'qual3
         say rexxname': '
         say rexxname': Updating To  :' ship.c
       end /* if right(qual3,1) <> substr(dest,5,1) then do */

     end /* if left(qual3,7) = 'APPPROC' then do */

   end /* dsnpos > 0 */

   queue ship.c

 end /* c=1 to ship.0 */

 say rexxname': '
 say rexxname': +---------------+'
 say rexxname': ! End of Pass' pass '!'
 say rexxname': +---------------+'
 say rexxname': '

 /* Save updated Cjcl                                                */
 "execio * diskw "ddname " (finis"
 if rc > 0 then exit(40) ;

return /* ship_update: */

/*-------------------------------------------------------------------*/
/* Wiz_update - Replace wizard hlqs                                  */
/*-------------------------------------------------------------------*/
wiz_update:

 parse arg thiswiz

 hlqpos=index(thiswiz,'DSN=##')
 baspos=index(thiswiz,'.BASE.')
 if hlqpos ^= 0 then do
   wizdsn = substr(thiswiz,hlqpos)
   say rexxname': Wizard replacing' wizdsn
   if baspos ^= 0 then
     thiswiz=overlay(wizbase,thiswiz,hlqpos)
   else
     thiswiz=overlay(wizpre,thiswiz,hlqpos)

   wizdsn = substr(thiswiz,hlqpos)
   say rexxname':        with     ' wizdsn
 end /* hlqpos do */

return /* wiz_update: */

/*-------------------------------------------------------------------*/
/* Universal trigger processing                                      */
/*  Scans for dataset triggers based on the variables at the top     */
/*  of this rexx exec.                                               */
/*-------------------------------------------------------------------*/
analysejclu:

 /* Set counters to zero                                             */
 do gg = 1 to words(triggers)
   interpret word(triggers,gg)'_count = 0'
 end /* gg = 1 to words(triggers) */

 /* Set the ddname(s) to scan for                                    */
 if jobtype = 'BJOB' then scanstr = '//OCR //DEL'
                     else scanstr = '//OAR //DEL'

 /* Loop through the JCL                                             */
 do i = 1 to card.0
   ddtype = left(card.i,5)

   if wordpos(ddtype,scanstr) > 0 then do /* OCR, OAR or DEL         */

     parse value card.i with '//' tddn junk 'DSN=' dsnl rest
     parse value dsnl with dsn ',' rest

     /* Set each qualifier in the target dataset name                */
     parse value dsn with qual1 '.' qual2 '.' qual3 '.' qual4

     /* Set the last qualifier of the target dataset name            */
     lastqual = substr(dsn,lastpos('.',dsn)+1)

     /* Loop through the triggers variable to see if we get a match  */
     do gg = 1 to words(triggers)
       trigger = word(triggers,gg)

       /* Should we add JCL for cloned shipments for this trigger?   */
       if wordpos(dest,clones)        > 0 & ,
          pos(trigger,triggers_clone) = 0 then /* not USS, DSDEL etc */
         iterate gg

       /* Should we add JCL for DELete DD names?                     */
       if left(tddn,3)          = 'DEL' & ,
          value(trigger'_'left(jobtype,1)'DEL') ^= 'Y'   then
         iterate gg

       /* Set the string that we search for for this trigger         */
       find_arg = value(trigger'_scan') /* I.e. qual3 or qual4 etc.  */
       interpret 'find_str =' find_arg

       if trigger = find_str then do
         staging = ''
         sddn    = ''

         if left(tddn,3) = 'DEL' then do
           interpret trigger'_count =' trigger'_count + 1'
           interpret trigger'_dsn.'trigger'_count       =' dsn
           interpret trigger'_stagedsn.'trigger'_count  = ""'
           interpret trigger'_stagedsnq.'trigger'_count = ""'
         end /* left(tddn,3) = 'DEL' */

         else do

           /* Get the staging dataset name                           */
           do x = i-1 to 1 by -1 /* Loop backwards thru the JCL      */
             if pos('DSN=',card.x) > 0 then do
               parse value card.x with start 'DSN=' dsnl rest
               parse value dsnl with staging ',' rest
             end /* pos('DSN=',card.x) > 0 */
             if left(card.x,3) ^= '// ' then do
               parse value card.x with '//' sddn rest
               leave x
             end /* left(card.x,3) ^= '// ' */
           end /* x = i-1 to 1 by -1 */

           if staging = '' then do
             say rexxname': Staging dataset not found for' tddn dsn
             exit 12
           end /* staging = '' */

           interpret trigger'_count =' trigger'_count + 1'
           interpret trigger'_dsn.'trigger'_count      =' dsn
           interpret trigger'_stagedsn.'trigger'_count =' staging

           /* Work out the Qplex staging dataset name                */
           stgdsnq = overlay('H',staging,35,1)
           stgdsnq = overlay(shiphlq,stgdsnq) /* For the test harnes */
           interpret trigger'_stagedsnq.'trigger'_count = stgdsnq'

         end /* else */

         say rexxname':'
         say rexxname': NDVEDIT detected the' trigger 'trigger'
         say rexxname':   Trigger DSN :' left(tddn,8) dsn
         say rexxname':   Staging DSN :' left(sddn,8) staging

       end /* trigger = find_str */

     end /* gg = 1 to words(triggers) */

   end /* scanstr = substr(card.i,1,5) */

 end /* i = 1 to card.0 */

return /* analysejclu: */

/*-------------------------------------------------------------------*/
/* Loop through the JCL looking for //OAR statements.                */
/*                                                                   */
/* Save the 'from' and 'to' line numbers of //OAR DD statements      */
/*                                                                   */
/* Save the final qualifier if it's a specific change                */
/*-------------------------------------------------------------------*/
analysejcl:
 arg scanstr /* '//OAR' for Cjob or '//OCR' for Bjob                 */

 oarcount      = 0 /* Count of //OAR.. DD statements                 */
 speccount     = 0 /* Count of specific DSNs                         */
 SHIPPGM_count = 0 /* Count of Ideal PGM DSNs Nplex                  */
 SHIPPNL_count = 0 /* Count of Ideal PNL DSNs Nplex                  */
 wizcount      = 0
 qmfcount      = 0 /* Count of QMF DSNs                              */
 /*wizard       = 'NO'           not reset after bjcl check as       */
 pro4          = 'NO'
 pro4ilife     = 'NO'
 pro4iloan     = 'NO'
 pro4isavg     = 'NO'
 pro4icall     = 'NO'
 pro4bkup      = 'NO'
 parmdsn       = 'NO'
 coldstar      = 'NO' /* COLDSTAR file updates                       */
 jobin         = 'NO' /* JOBIN type                                  */
 affinity      = 'NO' /* AFFINITY file updates                       */
 csfddl        = 'NO' /* CSF DDL update for LN                       */
 sqlpcjob      = 'NO' /* Ideal SQLplan updates                       */
 pnlcjob       = 'NO' /* Ideal Panel updates                         */
 pgmcjob       = 'NO' /* Ideal Program updates                       */
 sqlpbjob      = 'NO' /* Ideal SQLplan backout                       */
 pnlbjob       = 'NO' /* Ideal Panel backout                         */
 pgmbjob       = 'NO' /* Ideal Program backout                       */
 racfjob       = 'NO' /* RACF commands                               */

 do current=1 to card.0

   if INDEX(card.current,'MT.BASE.BOOTS') > 0 then BACKPRO4 = 'YES'

   if INDEX(card.current,'BASE.BOOTSL') > 0 then do
     BACKPRO4I = 'YES'
     pro4ibkup = 'YES'
     pro4ilife = 'YES'
     lifeload  = 'PGLL.PROIV.BATCH.LOADLIB'
     pro4load  = 'PGLL.PROIV.BATCH.LOADLIB'
     lifedev   = 'PGLL.VPROIV.DEVELOP.MIGRATE'
     lifegen   = 'PGLL.VPROIV.GENFILE.MIGRATE'
     lifeexec  = 'PGLL.VPROIV.EXEC.MIGRATE'
     tpfdev    = 'PGLX.VPROIV.DEVELOP.MIGRATE'
     tpfgen    = 'PGLX.VPROIV.GENFILE.MIGRATE'
     tpfexec   = 'PGLX.VPROIV.EXEC.MIGRATE'
     insdev    = lifedev
     insgen    = lifegen
     insexec   = lifeexec
     lifedevt  = 'PGLL.VPROIV.DEVELOP.TRAIN.MIGRATE'
     lifegent  = 'PGLL.VPROIV.GENFILE.TRAIN.MIGRATE'
     lifeexect = 'PGLL.VPROIV.EXEC.TRAIN.MIGRATE'
   end /* INDEX(card.current,'BASE.BOOTSL') > 0 */

   if INDEX(card.current,'BASE.BOOTSP') > 0 then do
     BACKPRO4I = 'YES'
     pro4ibkup = 'YES'
     pro4iloan = 'YES'
     obbload  = 'PGLZ.PROIV.BATCH.LOADLIB'
     pro4load = 'PGLZ.PROIV.BATCH.LOADLIB'
     loandev  = 'PGLZ.VPROIV.DEVELOP'
     loangen  = 'PGLZ.VPROIV.GENFILE'
     loanexec = 'PGLZ.VPROIV.EXEC'
     insdev   = loandev
     insgen   = loangen
     insexec  = loanexec
     loandevt = 'PGLZ.VPROIV.DEVELOP.TRAIN'
     loangent = 'PGLZ.VPROIV.GENFILE.TRAIN'
     loanexect = 'PGLZ.VPROIV.EXEC.TRAIN'
   end /* INDEX(card.current,'BASE.BOOTSP') > 0 */

   if INDEX(card.current,'BASE.BOOTSS') > 0 then do
     BACKPRO4I = 'YES'
     pro4ibkup = 'YES'
     obbload  = 'PGLZ.PROIV.BATCH.LOADLIB'
     pro4load = 'PGLZ.PROIV.BATCH.LOADLIB'
     pro4isavg = 'YES'
     savgdev  = 'PGLZ.VPROIV.DEVELOS'
     savggen  = 'PGLZ.VPROIV.GENFILS'
     savgexec = 'PGLZ.VPROIV.EXES'
     insdev   = savgdev
     insgen   = savggen
     insexec  = savgexec
     savgdevt = 'PGLZ.VPROIV.DEVELOS.TRAIN'
     savggent = 'PGLZ.VPROIV.GENFILS.TRAIN'
     savgexect = 'PGLZ.VPROIV.EXES.TRAIN'
   end /* INDEX(card.current,'BASE.BOOTSS') > 0 */

   if INDEX(card.current,'BASE.BOOTSX') > 0 then do
     BACKPRO4I = 'YES'
     pro4ibkup = 'YES'
     obbload  = 'PGLZ.PROIV.BATCH.LOADLIB'
     pro4load = 'PGLZ.PROIV.BATCH.LOADLIB'
     pro4icall = 'YES'
     calldev  = 'PGLZ.VPROIV.DEVELOX'
     callgen  = 'PGLZ.VPROIV.GENFILX'
     callexec = 'PGLZ.VPROIV.EXEX'
     insdev   = calldev
     insgen   = callgen
     insexec  = callexec
     calldevt = 'PGLZ.VPROIV.DEVELOX.TRAIN'
     callgent = 'PGLZ.VPROIV.GENFILX.TRAIN'
     callexect = 'PGLZ.VPROIV.EXEX.TRAIN'
   end /* INDEX(card.current,'BASE.BOOTSX') > 0 */

   if INDEX(card.current,'.SQLPLAN') > 0 & ,
      INDEX(card.current,'//OAR') > 0 then sqlpcjob = 'YES'

   if INDEX(card.current,'.SQLPLAN') > 0 & ,
      INDEX(card.current,'//OCR') > 0 then sqlpbjob = 'YES'

   if INDEX(card.current,'.PLJ1.SHIPPNL') > 0 & ,
      INDEX(card.current,'//OAR') > 0 then pnlcjob  = 'YES'

   if INDEX(card.current,'.PLJ1.SHIPPNL') > 0 & ,
      INDEX(card.current,'//OCR') > 0 then pnlbjob  = 'YES'

   if INDEX(card.current,'.PLJ1.SHIPPGM') > 0 & ,
      INDEX(card.current,'//OAR') > 0 then pgmcjob  = 'YES'

   if INDEX(card.current,'.PLJ1.SHIPPGM') > 0 & ,
      INDEX(card.current,'//OCR') > 0 then pgmbjob  = 'YES'

   /* Check for existance of CMPARM updates. If the jcl is updating  */
   /* a CMPARM dataset, e.g. PREV.POS1.DB2DATAN.CMPARM then this     */
   /* is a Batch Services change that uses the WIZARD processor      */
   /* group to facility large scale changes. If this is the case     */
   /* addiditional JCL is added to the Cjob and Bjob                 */
   if pos('.CMPARM',card.current) > 0 &,
      pos('BASE.CMPARM',card.current) = 0 then do
     wizard = 'YES'
     wizcount = wizcount + 1
     wee = card.current
     if pos('.BASE.',card.current) > 0 then do
       wizsys  = substr(wee,pos('DSN=',wee)+6,2)
       wizllqs = strip(substr(wee,pos('DSN=',wee)+14))
       wizdsn.wizcount = 'PREV.P'wizsys'1.'wizllqs
     end /* pos('.base.',card.current) */
     else
       wizdsn.wizcount = 'PR'strip(substr(wee,pos('DSN=',wee)+6))
     Say rexxname': FOUND CMPARM UPDATE 'wizdsn.wizcount
     ijcl = 'I'substr(changeid,2,7)
     pjcl = 'P'substr(changeid,2,7)
     bjcl = 'B'substr(changeid,2,7)
     xjcl = 'X'substr(changeid,2,7)

     say rexxname': additional change jcl in      ' ,
         wizdsn.wizcount'('ijcl')'
     say rexxname': additional dev change jcl in  ' ,
         wizdsn.wizcount'('pjcl')'
     say rexxname': additional backout jcl in     ' ,
         wizdsn.wizcount'('bjcl')'
     say rexxname': additional dev backout jcl in ' ,
         wizdsn.wizcount'('xjcl')'

   end /* end cmparm */

   /* Set the value of scanstr to //DEL if the change contains       */
   /* pro4 elements for RBS Insurance.  This is because the          */
   /* element name is the CMR number and therefore unique.           */
   if backpro4i = 'YES' and scanstr = '//OCR' then scanstr = '//DEL'

   /* Look for OAR DD statements                                     */
   if scanstr = substr(card.current,1,5) then do /* If line begins   */
     ddlabel = substr(card.current,1,10)         /* //OAR..          */
     oarcount = oarcount + 1                     /* Count it.        */
     oarstart.oarcount = current                 /* Save line no.    */
     dsn.oarcount = ''                           /* Reset dsn        */
     sdd.oarcount = ddlabel                      /* Save OARnn       */

     /* Put all the lines of this JCL statement into DDLINES         */
     ddlines = card.current /* load first line                       */
     dd      = current + 1 /* start @ next line                      */

     do while substr(card.dd,1,3) = '// ' /* Add on the next         */
       ddlines = ddlines || card.dd /* line of JCL                   */
       dd = dd + 1
     end /* while substr(card.dd,1,3) = '// ' */

     oarend.oarcount = dd /* Next valid line after OAR               */

     /* Find the low level qualifier on the DSN= clause              */
     parse value ddlines with word1 'DSN=' dsn.oarcount rest
     parse value dsn.oarcount with dsn.oarcount ',' rest
     temp = dsn.oarcount

     do while temp ^= ''
       parse value temp with qual '.' temp
     end /* while temp ^= '' */

     /* Get each qualifier in the target dataset name                */
     parse value dsn.oarcount with qual1 '.' qual2 '.' qual3 '.' qual4

     /*Find the staging datset name in the previous DD statment.     */
     /*Assume the previous DD name corresponds to the current        */
     if qual = 'PARM',
      | qual = 'PARML', /* Pro 4 Life parm                           */
      | qual = 'PARMP', /* Pro 4 Loans parm                          */
      | qual = 'PARMS', /* Pro 4 Savings parm                        */
      | qual = 'PARMX', /* Pro 4 Caller parm                         */
      | qual = 'COLDSTAR',
      | qual = 'JOBIN',
      | qual = 'AFFINITY',
      | qual = 'DDL',
      | qual = 'BOOTS',
      | qual = 'BOOTSL',  /* Pro 4 Life boots                        */
      | qual = 'BOOTSX',  /* Pro 4 Caller boots                      */
      | qual = 'BOOTSS',  /* Pro 4 Savings boots                     */
      | qual = 'BOOTSP',  /* Pro 4 Loans boots                       */
      | qual = 'SHIPPNL', /* Ideal panels                            */
      | qual = 'SHIPPGM', /* Ideal programs                          */
      | qual = 'SQLPLAN', /* Ideal SQLplans                          */
      | substr(qual,1,4) = 'QMF#' ,
      | right(qual,7) = 'RACFCMD', /* RACF commands                  */
      | specific <> 'G' then do

       previous = current - 1       /* Point at line before current  */
       ddlines = ''                 /* Reset the area to save lines  */
       stageline = 0

       do x = previous to 1 by -1               /* Loop backwards    */
         parse var card.x word1 word2 word3     /* until             */
         if stageline = 0 & pos('DSN=',card.x) > 0 then
           stageline = x
         if word2 = 'EXEC' then leave           /* start of step     */
         ddlines = ddlines || card.x            /* concatenate lines */
       end /* x = previous to 1 by -1 */

       parse value ddlines with word1 'DSN=' staging rest

       parse value staging with staging ',' rest

       if staging ^= '' then do
         if wordpos(qual,triggers) = 0 then do
           say rexxname': '
           say rexxname': Found' qual 'Destination DSN:' dsn.oarcount
           say rexxname': Found' qual 'Staging DSN    :' staging
         end

         /*  Ideal PNL updates                                       */
         if qual = 'SHIPPNL' then do
           ship_SHIPPNL_dsn = dsn.oarcount
           ship_SHIPPNL_stagedsn = staging
         end /* qual = 'SHIPPNL' */

         /*  Ideal PGM updates                                       */
         if qual = 'SHIPPGM' then do
           ship_SHIPPGM_dsn = dsn.oarcount
           ship_SHIPPGM_stagedsn = staging
         end /* qual = 'SHIPPGM' */

         /* PARM is used in conjunction with banking PRO-IV apps     */
         if qual = 'PARM' then do
           parmdsn = 'yes'
           parm.dsn = dsn.oarcount
           parm.stagedsn = staging
         end /* qual = 'PARM' */

         /* PARML is used in conjunction with PRO-IV Life            */
         if qual = 'PARML' then do
           parmdsn = 'yes'
           parm.dsn = dsn.oarcount
           parml.stagedsn = staging
           parm.stagedsn  = staging /* backward compatibility        */
         end /* qual = 'PARML' */

         /* PARMS is used in conjunction with PRO-IV Savings         */
         if qual = 'PARMS' then do
           parmdsn = 'yes'
           parm.dsn = dsn.oarcount
           parms.stagedsn = staging
           parm.stagedsn  = staging /* backward compatibility        */
         end /* qual = 'PARMS' */

         /* PARMP is used in conjunction with PRO-IV Loans           */
         if qual = 'PARMP' then do
           parmdsn = 'yes'
           parm.dsn = dsn.oarcount
           parmp.stagedsn = staging
           parm.stagedsn  = staging /* backward compatibility        */
         end /* qual = 'PARMP' */

         /* PARMX is used in conjunction with PRO-IV Caller          */
         if qual = 'PARMX' then do
           parmdsn = 'yes'
           parm.dsn = dsn.oarcount
           parmx.stagedsn = staging
           parm.stagedsn  = staging /* backward compatibility        */
         end /* qual = 'PARMX' */

         /* COLDSTAR is used for populating the COLDSTAR file        */
         if qual = 'COLDSTAR' then do
           coldstar = 'yes'
           coldstar.dsn = dsn.oarcount
           coldstar.stagedsn = staging
         end /* qual = 'COLDSTAR' */

         /* JOBIN is used to demand jobs on to the Pplex             */
         if qual = 'JOBIN' then do
           jobin = 'yes'
           jobin.dsn = dsn.oarcount
           jobin.stagedsn = staging
         end /* qual = 'JOBIN' */

         /* AFFINITY is used for populating the AFFINITY file        */
         if qual = 'AFFINITY' then do
           affinity = 'yes'
           affinity.dsn = dsn.oarcount
           affinity.stagedsn = staging
         end /* qual = 'AFFINITY' */

         if qual = 'DDL' then do  /* create ddl                      */
           csfddl = 'yes'
           ddl.dsn = dsn.oarcount
           ddl.stagedsn  = staging
         end /* qual = 'DDL' */

         /* BOOTSL is used in conjunction with PRO-IV Life           */
         if qual = 'BOOTSL' then do  /* create BOOTSL                */
           pro4life = 'yes'
           pro4i.dsn = dsn.oarcount
           pro4l.stagedsn  = staging
         end /* .BOOTSL.. */

         /* BOOTSP is used in conjunction with PRO-IV Loans          */
         if qual = 'BOOTSP' then do  /* create BOOTSP                */
           pro4loan = 'yes'
           pro4i.dsn = dsn.oarcount
           pro4p.stagedsn  = staging
         end /* qual = 'BOOTSP' */

         /* BOOTSS is used in conjunction with PRO-IV Savings        */
         if qual = 'BOOTSS' then do  /* create BOOTSS                */
           pro4savg = 'yes'
           pro4i.dsn = dsn.oarcount
           pro4s.stagedsn  = staging
         end /* qual = 'BOOTSS' */

         /* BOOTSX is used in conjunction with PRO-IV Caller         */
         if qual = 'BOOTSX' then do  /* create BOOTSX                */
           pro4call = 'yes'
           pro4i.dsn = dsn.oarcount
           pro4x.stagedsn  = staging
         end /* qual = 'BOOTSX' */

         /* PNL is used in conjunction Ideal                         */
         if qual = 'PNL' then do  /* create Ideal PNL                */
           pnljob.dsn = dsn.oarcount
           pnljob.stagedsn  = staging
         end /* qual = 'PNL' */

         /* PGM is used in conjunction Ideal                         */
         if qual = 'PGM' then do  /* create Ideal PGM                */
           pgmjob.dsn = dsn.oarcount
           pgmjob.stagedsn  = staging
         end /* qual = 'PGM' */

         /* SQLPLAN is used in conjunction Ideal                     */
         if qual = 'SQLPLAN' then do  /* create Ideal RPT            */
           sqlplan.dsn = dsn.oarcount
           sqlplan.stagedsn  = staging
         end /* qual = 'SQLPLAN' */

         /* Check to see if this is a                                */
         /* Banking PRO-IV release:                                  */
         /* For emergency releases, determine the DSN                */
         /* of the BOOTS dataset.                                    */
         if qual = 'BOOTS' then do
           pro4 = runtype    /*"STANDARD","LOCAL","EMERGENCY"*/

           if runtype = 'EMERGENCY' then do
             mt.dsn = dsn.oarcount
             mt.stagedsn = staging
             pro4job = substr(mt.dsn,3,2)
           end /* runtype = 'EMERGENCY' */

         end /* qual = 'BOOTS' */

         /*  QMF data migration                                      */
         if substr(qual,1,4) = 'QMF#' then do
           qmfcount = qmfcount + 1
           qmf.dsn.qmfcount = dsn.oarcount
           qmf.stagedsn.qmfcount = staging
           qmf.appl.qmfcount = substr(dsn.oarcount,7,2)
           qmf.target.qmfcount = substr(dsn.oarcount,15,3)
         end /* substr(qual,1,4) = 'QMF#' */

         /* RACF COMMANDS                                            */
         if right(qual,7) = 'RACFCMD' then do
           racfdsn   = dsn.oarcount
           racfsys   = substr(racfdsn,3,2)
           racfstage = staging
           if racfsys = 'SQ' then   /* Only the SQ system            */
             racfjob   = 'yes'
         end /* right(qual,7) = 'RACFCMD' */

       end /* staging ^= '' */

       if specific <> 'G' then do
         speccount = speccount + 1
         spec.dsn.speccount = dsn.oarcount
         spec.stagedsn.speccount = staging
         dsnquals = translate(dsn.oarcount,' ','.')
         pointer = oarstart.oarcount
         jclline = card.pointer
         if word(dsnquals,3) = 'CICS' then
           specdsn  = 'PGEV.'changeid'.'word(dsnquals,3)
         else
           specdsn  = word(dsnquals,1)'.'changeid'.'word(dsnquals,3)
         if word(dsnquals,3) = 'P#11CICS' then
           specdsn  = 'PGEV.'changeid'.CICS'
         baspos   = POS('DSN=',jclline) + 4
         card.pointer = OVERLAY(specdsn,jclline,baspos)
         spec.dsn.speccount = specdsn
       end /* specific <> 'G' */

     end /* llq match found */

   end /* End of If //OAR.. */

 end  /* current=1 to card.0 */

 /* Switch off all additional JCL for cloned shipments               */
 /* except the integration proving environment the Fplex that        */
 /* needs to be kept in line with the Eplex.                         */
 if wordpos(dest,clones) > 0 then if dest ^= 'PLEXF1' then do

   backpro4     = 'NO'
   backpro4i    = 'NO'
   pro4         = 'NO'
   pro4ins      = 'NO'
   pro4bkup     = 'NO'
   parmdsn      = 'NO'
   coldstar     = 'NO'
   jobin        = 'NO'
   sqlpcjob     = 'NO'
   pnlcjob      = 'NO'
   pgmcjob      = 'NO'
   sqlpbjob     = 'NO'
   pnlbjob      = 'NO'
   pgmbjob      = 'NO'
 end /* end dest,clones */

return /* analysejcl: */

/*-------------------------------------------------------------------*/
/* Modify dataset name on DEL statement for specific change          */
/*-------------------------------------------------------------------*/
editdel:
 arg scanstr /* '//DEL' for Cjob or '//OCR' for Bjob                 */

 delcount = 0 /* Count of //del.. DD statements                      */

 do current=1 to card.0

   /* Look for DEL DD statements                                     */
   if scanstr = substr(card.current,1,5) then do /* If line begins   */
     jclline = card.current
     baspos   = POS('DSN=',jclline) + 4
     deldsn   = substr(jclline,baspos,44)
     deldsn   = strip(deldsn)
     dsnquals = translate(deldsn,' ','.')
     if word(dsnquals,3) = 'CICS' then
       specdsn  = 'PGEV.'changeid'.'word(dsnquals,3)
     else
       specdsn  = word(dsnquals,1)'.'changeid'.'word(dsnquals,3)
     if word(dsnquals,3) = 'P#11CICS' then
       specdsn  = 'PGEV.'changeid'.CICS'
     card.current = OVERLAY(specdsn,jclline,baspos)
   end /* End of If //DEL.. */

 end  /* current=1 to card.0 */

return /* editdel: */

/*-------------------------------------------------------------------*/
/*  Process RBS banking PRO-IV application code                      */
/*-------------------------------------------------------------------*/
pro4appl:
 if parmdsn <> 'yes' then do
   say rexxname': NO .PARM dataset shipped'
   say rexxname': Error in PRO-IV package'
   "DROPBUF" /* clear queued commands                                */
   exit 13
 end /* parmdsn <> 'yes' */
 say rexxname': Found PRO4 .PARM'
 say rexxname': Destination DSN:' parm.dsn
 say rexxname': Staging DSN    :' parm.stagedsn
 if index(parm.stagedsn,".AR") > 0 then
   i = index(parm.stagedsn,".AR")
 else
   i = index(parm.stagedsn,".CR")

 host_parmdsn = overlay(".AH",parm.stagedsn,i,3)
 say rexxname': Staging DSN on Q1PLEX :' host_parmdsn
 t = outtrap('TSOOUT.')
 "listds '"host_parmdsn"' members"
 cc = rc

 if cc ^= 0 then do
   say rexxname': Error on LISTDS' host_parmdsn
   exit cc
 end /* cc ^= 0 */

 memcount = 0 /* How many real members are to be processed           */

 do t = 7 to tsoout.0
   pro4mem = STRIP(tsoout.t)

   if pro4mem = '$$$SPACE' then iterate /* pdsman spacemap           */

   memcount = memcount + 1

   pro4app = substr(pro4mem,1,2)
   rbspro4 = 'PRMT.PRO4.'pro4app
   nwbpro4 = 'PNMT.PRO4.'pro4app
   if memcount = 2 then do
     say rexxname': '
     say rexxname': More then 1 member found in' parm.stagedsn
     exit 14
   end /* memcount = 2 */

 end /* t = 7 to tsoout.0 */
return /* pro4appl: */

/*-------------------------------------------------------------------*/
/*  Process RBS Insurance PRO-IV application code                    */
/*-------------------------------------------------------------------*/
pro4iappl:
 if parmdsn <> 'yes' then do
   say rexxname': NO .PARM dataset shipped'
   say rexxname': Error in PRO-IV package'
   exit 13
 end /* parmdsn <> 'yes' */
 say rexxname': Found PRO4 .PARM'
 say rexxname': Destination DSN:' parm.dsn
 say rexxname': Staging DSN    :' parm.stagedsn
 if index(parm.stagedsn,".AR") > 0 then
   i = index(parm.stagedsn,".AR")
 else
   i = index(parm.stagedsn,".CR")
 host_parmdsn = overlay(".AH",parm.stagedsn,i,3)
 say rexxname': Staging DSN on Q1PLEX :' host_parmdsn

 t = outtrap('TSOOUT.')
 say rexxname': Processing' tsoout.0 'members '
 "listds '"host_parmdsn"' members"
 cc = rc

 if cc ^= 0 then do
   say rexxname': Error on LISTDS' host_parmdsn
   exit cc
 end /* cc ^= 0 */

 do t = 7 to tsoout.0
   pro4name = STRIP(tsoout.t)

   if pro4name = '$$$SPACE' then iterate /* pdsman spacemap          */

   spwstep = strip(left(pro4name,7))'B'
   say rexxname': Insurance PRO-IV JCL inserted for' pro4name
   queue "//***************************************************       "
   queue "//** CREATE TEMP VSAM DATASETS TO UNLOAD BOOTSTRAP **       "
   queue "//***************************************************       "
   queue "//ALLOC    EXEC PGM=IDCAMS                                  "
   queue "//SYSPRINT DD SYSOUT=*                                      "
   queue "//SYSIN    DD *                                             "
   if pro4ilife = yes then do
   queue " DELETE PGEV."changeid".LL.GENFILE                          "
   queue " DELETE PGEV."changeid".LL.DEVELOP                          "
   queue " DELETE PGEV."changeid".LL.EXEC                             "
   queue " SET MAXCC = 0                                              "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LL.GENFILE) -                 "
   queue "        MODEL(PGEV.MODEL.GENFILE))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LL.DEVELOP) -                 "
   queue "        MODEL(PGEV.MODEL.DEVELOP))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LL.EXEC) -                    "
   queue "        MODEL(PGEV.MODEL.EXEC))                             "
   end /* pro4ilife = yes */
   if pro4iloan = yes then do
   queue " DELETE PGEV."changeid".LZ.GENFILE                          "
   queue " DELETE PGEV."changeid".LZ.DEVELOP                          "
   queue " DELETE PGEV."changeid".LZ.EXEC                             "
   queue " SET MAXCC = 0                                              "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.GENFILE) -                 "
   queue "        MODEL(PGEV.MODEL.GENFILE))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.DEVELOP) -                 "
   queue "        MODEL(PGEV.MODEL.DEVELOP))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.EXEC) -                    "
   queue "        MODEL(PGEV.MODEL.EXEC))                             "
   end /* pro4iloan = yes */
   if pro4isavg = yes then do
   queue " DELETE PGEV."changeid".LZ.GENFILS                          "
   queue " DELETE PGEV."changeid".LZ.DEVELOS                          "
   queue " DELETE PGEV."changeid".LZ.EXES                             "
   queue " SET MAXCC = 0                                              "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.GENFILS) -                 "
   queue "        MODEL(PGEV.MODEL.GENFILE))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.DEVELOS) -                 "
   queue "        MODEL(PGEV.MODEL.DEVELOP))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.EXES) -                    "
   queue "        MODEL(PGEV.MODEL.EXEC))                             "
   end /* pro4isavg = yes */
   if pro4icall = yes then do
   queue " DELETE PGEV."changeid".LZ.GENFILX                          "
   queue " DELETE PGEV."changeid".LZ.DEVELOX                          "
   queue " DELETE PGEV."changeid".LZ.EXEX                             "
   queue " SET MAXCC = 0                                              "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.GENFILX) -                 "
   queue "        MODEL(PGEV.MODEL.GENFILE))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.DEVELOX) -                 "
   queue "        MODEL(PGEV.MODEL.DEVELOP))                          "
   queue " DEFINE CLUSTER -                                           "
   queue "        (NAME(PGEV."changeid".LZ.EXEX) -                    "
   queue "        MODEL(PGEV.MODEL.EXEC))                             "
   end /* pro4icall = yes */
   queue "/*                                                          "
   queue "//***************************************************       "
   queue "//** SPWARN IF VSAM DEFINES FAIL                   **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (ALLOC.RUN AND ALLOC.RC GT 0) THEN            "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*"
   if pro4ilife = yes then do
   queue "//***************************************************       "
   queue "//** UNLOAD PDS MEMBER TO TEMP VSAM FILE           **       "
   queue "//***************************************************       "
   queue "//UNLOADLL EXEC PGM=GVRESTOR                                "
   queue "//SYSPRINT DD SYSOUT=*,FCB=S001                             "
   queue "//SNAPDD   DD SYSOUT=*,FCB=S001                             "
   queue "//SYSUDUMP DD SYSOUT=C,FCB=S001                             "
   queue "//TAPE0    DD DSN="pro4l.stagedsn"("changeid"),             "
   queue "//         DISP=SHR                                         "
   queue "//LLEXEC   DD DSN=PGEV."changeid".LL.EXEC,DISP=OLD          "
   queue "//LLDEV    DD DSN=PGEV."changeid".LL.DEVELOP,DISP=OLD       "
   queue "//LLGEN    DD DSN=PGEV."changeid".LL.GENFILE,DISP=OLD       "
   queue "//SYSIN    DD *                                             "
   queue " RESTORE                                                    "
   queue " CLUSTER                                                    "
   queue " CL=PREV.PRO4.LL.EXEC REUSE DDNAME=LLEXEC                   "
   queue " CL=PREV.PRO4.LL.DEVELOP REUSE DDNAME=LLDEV                 "
   queue " CL=PREV.PRO4.LL.GENFILE REUSE DDNAME=LLGEN                 "
   queue "/*                                                          "
   queue "//***************************************************       "
   queue "//**       SPWARN IF FAVER UNLOAD FAILED           **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (UNLOADLL.RUN AND UNLOADLL.RC GT 0) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 LIFE UPDATES         **       "
   queue "//***************************************************       "
   queue "//PRO4IL   EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR                       "
   queue "//PROXECI  DD DSN=PGEV."changeid".LL.EXEC,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LL.DEVELOP,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LL.GENFILE,DISP=SHR       "
   queue "//PROXECO  DD DSN="lifeexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="lifedev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="lifegen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parml.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IL.RUN AND PRO4IL.RC GT 0) THEN          "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 TPF UPDATES          **       "
   queue "//***************************************************       "
   queue "//PRO4IT   EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR                       "
   queue "//PROXECI  DD DSN=PGEV."changeid".LL.EXEC,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LL.DEVELOP,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LL.GENFILE,DISP=SHR       "
   queue "//PROXECO  DD DSN="tpfexec",DISP=SHR                        "
   queue "//PRODEVO  DD DSN="tpfdev",DISP=SHR                         "
   queue "//GENFILO  DD DSN="tpfgen",DISP=SHR                         "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parml.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IT.RUN AND PRO4IT.RC GT 0) THEN          "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 LIFE TRAINING UPDATES**       "
   queue "//***************************************************       "
   queue "//PRO4ILT  EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR                       "
   queue "//PROXECI  DD DSN=PGEV."changeid".LL.EXEC,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LL.DEVELOP,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LL.GENFILE,DISP=SHR       "
   queue "//PROXECO  DD DSN="lifeexect",DISP=SHR"
   queue "//PRODEVO  DD DSN="lifedevt",DISP=SHR"
   queue "//GENFILO  DD DSN="lifegent",DISP=SHR"
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parml.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4ILT.RUN AND PRO4ILT.RC GT 0) THEN        "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//* DELETE MAIL FILES                              **       "
   queue "//***************************************************       "
   queue "//STEP010  EXEC PGM=IEFBR14                                 "
   queue "//MAILHEAD DD DSN=PZLL.NLI00.PRO4.MAILHEAD,                 "
   queue "//             DISP=(MOD,DELETE),SPACE=(CYL,(70,30))        "
   queue "//MAILATTC DD DSN=PZLL.NLI00.PRO4.MAILATTC,                 "
   queue "//             DISP=(MOD,DELETE),SPACE=(CYL,(70,30))        "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//* REDEFINE MAIL FILES                            **       "
   queue "//***************************************************       "
   queue "//STEP020  EXEC PGM=IEFBR14                                 "
   queue "//MAILHEAD DD DSN=PZLL.NLI00.PRO4.MAILHEAD,                 "
   queue "//             DISP=(MOD,CATLG),                            "
   queue "//             RECFM=FB,LRECL=90,BLKSIZE=900,               "
   queue "//             SPACE=(CYL,(70,30))                          "
   queue "//MAILATTC DD DSN=PZLL.NLI00.PRO4.MAILATTC,                 "
   queue "//             DISP=(MOD,CATLG),                            "
   queue "//             RECFM=FB,LRECL=250,BLKSIZE=2500,             "
   queue "//             SPACE=(CYL,(70,30))                          "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** UPDATE LIFE VERSION MANAGEMENT SYSTEM         **       "
   queue "//***************************************************       "
   queue "//VMUPDT   EXEC PGM=PROMVS,                                 "
   queue "//             PARM='CODIV=LDS,OPER=LDS,FUNCTION=VMXFRU01'  "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR                       "
   queue "//PROEXEC  DD DSN="insexec",DISP=SHR                        "
   queue "//GENFILE  DD DSN="insgen",DISP=SHR                         "
   queue "//PROPRNT  DD SYSOUT=*                                      "
   queue "//SYSOUT   DD SYSOUT=*                                      "
   queue "//SYSPRINT DD SYSOUT=*                                      "
   queue "//PROMSG   DD SYSOUT=*                                      "
   queue "//*                                                         "
   queue "//LPAD     DD DSN=PZLL.VLI00.LPAD,DISP=SHR                  "
   queue "//LVVMS    DD DSN=PZLL.VLI00.LVVMS.BATCH,DISP=SHR           "
   queue "//LSTF     DD DSN=PZLL.VLI00.LSTF,DISP=SHR                  "
   queue "//LPARAM1  DD DISP=SHR,                                     "
   queue "//             DSN="parml.stagedsn"("changeid")             "
   queue "//LPARAM2  DD DSN=PGEV.BASE.DATA(VMACPT),DISP=SHR           "
   queue "//LPARAM3  DD DSN=PGEV.BASE.DATA(VMPROD),DISP=SHR           "
   queue "//LPARAM4  DD *                                             "
   queue " "changeid"                                                 "
   queue "/*                                                          "
   queue "//MAILATTC DD DSN=PZLL.NLI00.PRO4.MAILATTC,DISP=SHR         "
   queue "//MAILHEAD DD DSN=PZLL.NLI00.PRO4.MAILHEAD,DISP=SHR         "
   queue "//LSTV     DD DSN=PZLL.VLI00.LSTV,DISP=SHR                  "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF VERSION MANAGEMENT UPDATE FAILS     **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (VMUPDT.RUN AND VMUPDT.RC GT 0) THEN          "
   queue "//*                                                         "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SENDMAIL TO CONFIRM THE UPDATE HAS RUN        **       "
   queue "//***************************************************       "
   queue "//SENDMAIL EXEC PGM=IKJEFT1B                                "
   queue "//SYSEXEC  DD DSN=PGLN.BASE.REXX,DISP=SHR                   "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//SYSTSIN  DD DSN=PZLL.NLI00.MAILPARM,DISP=SHR              "
   queue "//SYSTCPD  DD DSN=SYS1.TCPPARMS(TCPDATA),DISP=SHR           "
   queue "//SYSHEAD  DD DSN=PZLL.NLI00.PRO4.MAILHEAD,DISP=SHR         "
   queue "//SYSATTC  DD DSN=PZLL.NLI00.PRO4.MAILATTC,DISP=SHR         "
   queue "//SYSBODY  DD DSN=PZLL.NLI00.DEFAULT.MAILBODY,DISP=SHR      "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF EMAIL FAILS                         **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (SENDMAIL.RUN AND SENDMAIL.RC GT 0) THEN      "
   queue "//*                                                         "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   end /* pro4ilife = yes */
   if pro4iloan = yes then do
   queue "//***************************************************       "
   queue "//** UNLOAD PDS MEMBER TO TEMP VSAM FILE           **       "
   queue "//***************************************************       "
   queue "//UNLOADLP EXEC PGM=GVRESTOR                                "
   queue "//SYSPRINT DD SYSOUT=*,FCB=S001                             "
   queue "//SNAPDD   DD SYSOUT=*,FCB=S001                             "
   queue "//SYSUDUMP DD SYSOUT=C,FCB=S001                             "
   queue "//TAPE0    DD DSN="pro4p.stagedsn"("changeid"),             "
   queue "//         DISP=SHR                                         "
   queue "//LPEXEC   DD DSN=PGEV."changeid".LZ.EXEC,DISP=OLD          "
   queue "//LPDEV    DD DSN=PGEV."changeid".LZ.DEVELOP,DISP=OLD       "
   queue "//LPGEN    DD DSN=PGEV."changeid".LZ.GENFILE,DISP=OLD       "
   queue "//SYSIN    DD *                                             "
   queue " RESTORE                                                    "
   queue " CLUSTER                                                    "
   queue " CL=PREV.PRO4.LZ.EXEC REUSE DDNAME=LPEXEC                   "
   queue " CL=PREV.PRO4.LZ.DEVELOP REUSE DDNAME=LPDEV                 "
   queue " CL=PREV.PRO4.LZ.GENFILE REUSE DDNAME=LPGEN                 "
   queue "/*                                                          "
   queue "//***************************************************       "
   queue "//** SPWARN IF FAVER UNLOAD FAILED                 **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (UNLOADLP.RUN AND UNLOADLP.RC GT 0) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 LOAN UPDATES         **       "
   queue "//***************************************************       "
   queue "//PRO4IP   EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".LZ.EXEC,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LZ.DEVELOP,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LZ.GENFILE,DISP=SHR       "
   queue "//PROXECO  DD DSN="loanexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="loandev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="loangen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parmp.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IP.RUN AND PRO4IP.RC GT 0) THEN          "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 LOAN TRAINING UPDATES**       "
   queue "//***************************************************       "
   queue "//PRO4IPT  EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".LZ.EXEC,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LZ.DEVELOP,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LZ.GENFILE,DISP=SHR       "
   queue "//PROXECO  DD DSN="loanexect",DISP=SHR                      "
   queue "//PRODEVO  DD DSN="loandevt",DISP=SHR                       "
   queue "//GENFILO  DD DSN="loangent",DISP=SHR                       "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parmp.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IPT.RUN AND PRO4IPT.RC GT 0) THEN        "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   end /* pro4iloan = yes */
   if pro4isavg = yes then do
   queue "//***************************************************       "
   queue "//** UNLOAD PDS MEMBER TO TEMP VSAM FILE           **       "
   queue "//***************************************************       "
   queue "//UNLOADLS EXEC PGM=GVRESTOR                                "
   queue "//SYSPRINT DD SYSOUT=*,FCB=S001                             "
   queue "//SNAPDD   DD SYSOUT=*,FCB=S001                             "
   queue "//SYSUDUMP DD SYSOUT=C,FCB=S001                             "
   queue "//TAPE0    DD DSN="pro4s.stagedsn"("changeid"),             "
   queue "//         DISP=SHR                                         "
   queue "//LSEXEC   DD DSN=PGEV."changeid".LZ.EXES,DISP=OLD          "
   queue "//LSDEV    DD DSN=PGEV."changeid".LZ.DEVELOS,DISP=OLD       "
   queue "//LSGEN    DD DSN=PGEV."changeid".LZ.GENFILS,DISP=OLD       "
   queue "//SYSIN    DD *                                             "
   queue " RESTORE                                                    "
   queue " CLUSTER                                                    "
   queue " CL=PREV.PRO4.LZ.EXES REUSE DDNAME=LSEXEC                   "
   queue " CL=PREV.PRO4.LZ.DEVELOS REUSE DDNAME=LSDEV                 "
   queue " CL=PREV.PRO4.LZ.GENFILS REUSE DDNAME=LSGEN                 "
   queue "/*                                                          "
   queue "//***************************************************       "
   queue "//** SPWARN IF FAVER UNLOAD FAILED                 **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (UNLOADLS.RUN AND UNLOADLS.RC GT 0) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 SAVG UPDATES         **       "
   queue "//***************************************************       "
   queue "//PRO4IS   EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".LZ.EXES,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LZ.DEVELOS,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LZ.GENFILS,DISP=SHR       "
   queue "//PROXECO  DD DSN="savgexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="savgdev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="savggen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parms.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IS.RUN AND PRO4IS.RC GT 0) THEN          "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 SAVG TRAINING UPDATES**       "
   queue "//***************************************************       "
   queue "//PRO4IST  EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".LZ.EXES,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LZ.DEVELOS,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LZ.GENFILS,DISP=SHR       "
   queue "//PROXECO  DD DSN="savgexect",DISP=SHR                      "
   queue "//PRODEVO  DD DSN="savgdevt",DISP=SHR                       "
   queue "//GENFILO  DD DSN="savggent",DISP=SHR                       "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parms.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IST.RUN AND PRO4IST.RC GT 0) THEN        "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   end /* pro4isavg = yes */
   if pro4icall = yes then do
   queue "//***************************************************       "
   queue "//** UNLOAD PDS MEMBER TO TEMP VSAM FILE           **       "
   queue "//***************************************************       "
   queue "//UNLOADLX EXEC PGM=GVRESTOR                                "
   queue "//SYSPRINT DD SYSOUT=*,FCB=S001                             "
   queue "//SNAPDD   DD SYSOUT=*,FCB=S001                             "
   queue "//SYSUDUMP DD SYSOUT=C,FCB=S001                             "
   queue "//TAPE0    DD DSN="pro4x.stagedsn"("changeid"),             "
   queue "//         DISP=SHR                                         "
   queue "//LXEXEC   DD DSN=PGEV."changeid".LZ.EXEX,DISP=OLD          "
   queue "//LXDEV    DD DSN=PGEV."changeid".LZ.DEVELOX,DISP=OLD       "
   queue "//LXGEN    DD DSN=PGEV."changeid".LZ.GENFILX,DISP=OLD       "
   queue "//SYSIN    DD *                                             "
   queue " RESTORE                                                    "
   queue " CLUSTER                                                    "
   queue " CL=PREV.PRO4.LZ.EXEX REUSE DDNAME=LXEXEC                   "
   queue " CL=PREV.PRO4.LZ.DEVELOX REUSE DDNAME=LXDEV                 "
   queue " CL=PREV.PRO4.LZ.GENFILX REUSE DDNAME=LXGEN                 "
   queue "/*                                                          "
   queue "//***************************************************       "
   queue "//** SPWARN IF FAVER UNLOAD FAILED                 **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (UNLOADLX.RUN AND UNLOADLX.RC GT 0) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//**   APPLY RBS INSURANCE PRO4 CALL UPDATES       **       "
   queue "//***************************************************       "
   queue "//PRO4IX   EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".LZ.EXEX,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LZ.DEVELOX,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LZ.GENFILX,DISP=SHR       "
   queue "//PROXECO  DD DSN="callexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="calldev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="callgen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parmx.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IX.RUN AND PRO4IX.RC GT 0) THEN          "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** APPLY RBS INSURANCE PRO4 CALL TRAINING UPDATES**       "
   queue "//***************************************************       "
   queue "//PRO4IXT  EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".LZ.EXEX,DISP=SHR          "
   queue "//PRODEVI  DD DSN=PGEV."changeid".LZ.DEVELOX,DISP=SHR       "
   queue "//GENFILI  DD DSN=PGEV."changeid".LZ.GENFILX,DISP=SHR       "
   queue "//PROXECO  DD DSN="callexect",DISP=SHR                      "
   queue "//PRODEVO  DD DSN="calldevt",DISP=SHR                       "
   queue "//GENFILO  DD DSN="callgent",DISP=SHR                       "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN="parmx.stagedsn"("changeid")                 "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF PROUTVV FAILS                       **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4IXT.RUN AND PRO4IXT.RC GT 0) THEN        "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
 end /* pro4icall = yes */
return /* pro4iappl: */

/*-------------------------------------------------------------------*/
/*  CSF DDL JCL                                                      */
/*-------------------------------------------------------------------*/
ddladdjcl:
 say rexxname': '
 say rexxname': DDL JCL inserted before line: 'current
 ddlstgdsnq = overlay("H",ddl.stagedsn,35,1)
 say rexxname': list directory of' ddlstgdsnq
 t = outtrap('TSOOUT.')
 "listds '"ddlstgdsnq"' members"
 cc = rc

 if cc ^= 0 then do
   say rexxname': error on listds' ddlstgdsnq
   do t = 1 to tsoout.0
     say tsoout.t
   end /* t = 1 to tsoout.0 */
   exit cc
 end /* cc ^= 0 */

 do t = 7 to tsoout.0
   ddlname = STRIP(tsoout.t)

   if ddlname = '$$$SPACE' then iterate /* pdsman spacemap           */

   spwstep = strip(left(ddlname,7))'B'
   say rexxname': DDL JCL inserted for' ddlname
   queue "//*****************************************************"
   queue "//**       BUILD JCL FOR CSF DDL UPDATES              *"
   queue "//*****************************************************"
   queue "//"ddlname "EXEC PGM=IDCAMS"
   queue "//SYSPRINT DD SYSOUT=*"
   queue "//INDDD1   DD DSN="ddl.stagedsn"("ddlname"),"
   queue "//             DISP=SHR"
   queue "//OUTDD1   DD DSN=PGLN.VBASE."ddlname",DISP=SHR"
   queue "//SYSIN    DD *"
   queue " REPRO INFILE(INDDD1) OUTFILE(OUTDD1) REPLACE REUSE"
   queue "/*"
   queue "//*******************************************************"
   queue "//**       SPWARN IF BUILD CSF DDL UPDATE FAILED       **"
   queue "//*******************************************************"
   queue "//"spwstep "EXEC PGM=SPWARN,COND=(0,EQ,"ddlname")        "
   queue "//STEPLIB   DD DSN=PGSP.BASE.LOAD,DISP=SHR               "
   queue "//SYSPRINT  DD SYSOUT=*,FCB=S001                         "
   queue "//*                                                      "
 end /* tsoout */

return /* ddladdjcl: */

coldstaraddjcl:

 say rexxname': '
 say rexxname': COLDSTAR JCL inserted before line:' current
 coldstgdsnq = overlay("H",coldstar.stagedsn,35,1)
 plexid = substr(coldstgdsnq,31,1)
 say rexxname': list directory of' coldstgdsnq
 say rexxname': '
 t = outtrap('TSOOUT.')
 "listds '"coldstgdsnq"' members"
 cc = rc

 if cc ^= 0 then do
   say rexxname': '
   say rexxname': error on listds' coldstgdsnq
   say rexxname': '
   do t = 1 to tsoout.0
     say tsoout.t
   end /* t = 1 to tsoout.0 */
   exit cc
 end /* cc ^= 0 */

 do t = 7 to tsoout.0
   coldstar_plex = STRIP(tsoout.t)

   if coldstar = '$$$SPACE' then iterate /* pdsman spacemap          */

   say rexxname':  Processing element' coldstar_plex
   if substr(coldstar_plex,1,1) ^= substr(coldstgdsnq,31,1) then do
     say rexxname': '
     say rexxname': Skipping the COLDSTAR JCL as the plex'
     say rexxname': identifier' plexid 'as identified in position 31'
     say rexxname': from dataset' coldstar.stagedsn
     say rexxname': does not match character 1 from member' coldstar_plex
     say rexxname': '
     iterate
   end /* substr(coldstar_plex,1,1) ^= substr(coldstgdsnq,31,1) */

   say rexxname': Icetool JCL inserted for' coldstar_plex
   queue "//*************************************************************"
   queue "//**       BUILD JCL FOR COLDSTAR FILE UPDATE                **"
   queue "//*************************************************************"
   queue "//JSTEP010 EXEC PGM=ICETOOL                                    "
   queue "//PDS      DD DISP=SHR,                                        "
   queue "//             DSN="coldstar.stagedsn"("coldstar_plex")"
   queue "//QSAM     DD DISP=SHR,                                        "
   queue "//             DSN=PGSP.BASE.COLDSTAR."coldstar_plex
   queue "//SYSPRINT DD SYSOUT=*                                         "
   queue "//SYSOUT   DD SYSOUT=*                                         "
   queue "//DFSMSG   DD SYSOUT=*                                         "
   queue "//TOOLMSG  DD SYSOUT=*                                         "
   queue "//SYMNOUT  DD SYSOUT=*                                         "
   queue "//MULTCNTL DD *                                                "
   queue "  OUTFIL FNAMES=QSAM                                           "
   queue "/*                                                             "
   queue "//TOOLIN   DD *                                                "
   queue "     COPY FROM(PDS) USING(MULT)                                "
   queue "/*                                                             "
   queue "//CHECK01  IF JSTEP010.RC NE 0 THEN                            "
   queue "//*************************************************************"
   queue "//** SPWARN IF MERGE OF COLDSTAR FILE UPDATE                 **"
   queue "//*************************************************************"
   queue "//JSTEP020 EXEC @SPWARN                                        "
   queue "//CHECK01  ENDIF                                               "
   queue "//*                                                            "
 end /* t = 7 to tsoout.0 */

return /* coldstaraddjcl: */

jobinaddjcl:

 if dest <> 'PLEXP1' then do
   say rexxname': '
   say rexxname': JOBIN type processing is not required on any plex'
   say rexxname': except PLEXP1.                                   '
   say rexxname': '

   return

 end /* dest <> 'PLEXP1' */

 say rexxname': '
 say rexxname': JOBIN JCL inserted before line:' current
 jobinstgdsnq = overlay("H",jobin.stagedsn,35,1)

 say rexxname': list directory of' jobinstgdsnq
 say rexxname': '
 t = outtrap('TSOOUT.')
 "listds '"jobinstgdsnq"' members"
 cc = rc

 if cc ^= 0 then do
   say rexxname': '
   say rexxname': error on listds' jobinstgdsnq
   say rexxname': '
   do t = 1 to tsoout.0
     say tsoout.t
   end /* t = 1 to tsoout.0 */
   exit cc
 end /* cc ^= 0 */

 do t = 7 to tsoout.0

   jobname = STRIP(tsoout.t)

   if jobname = '$$$SPACE' then iterate /* pdsman spacemap           */

   say rexxname': Processing element' jobname

   last_char = right(jobname,1)

   /* if the job is RBS brand the set ca7 to FROW else use P02       */
   if substr(jobname,3,1) = 'R' then ca7 = 'FROW'
   else ca7 = 'P02'

   say rexxname': CA7 API JCL will be added to demand'
   say rexxname': 'jobname' on to CA7'ca7
   say rexxname': '

   queue "//*************************************************************"
   queue "//**       USE THE CA7 API TO DEMAND THE JOB ON TO CA7.      **"
   queue "//*************************************************************"
   queue "//CA7API   EXEC @CA7RXIF,TARGETC7="ca7",TLQ=,ERRCHK=YE"
   queue "//STEP010.CA7CMND DD *                                         "
   queue "DEMAND,JOB="jobname
   queue "/*                                                             "
   queue "//CHECKCA7 IF RC NE 0 THEN                                     "
   queue "//*************************************************************"
   queue "//** SPWARN IF CA7 API CALL FAILS                            **"
   queue "//*************************************************************"
   queue "//SPWARN   EXEC @SPWARN                                        "
   queue "//CHECKCA7 ENDIF                                               "
   queue "//*                                                            "
 end /* t = 7 to tsoout.0 */

return /* jobinaddjcl: */

affinityaddjcl:

 say rexxname': '
 say rexxname': AFFINITY JCL inserted before line:' current
 affnstgdsnq = overlay("H",affinity.stagedsn,35,1)
 say rexxname': list directory of' affnstgdsnq
 say rexxname': '
 t = outtrap('TSOOUT.')
 "listds '"affnstgdsnq"' members"
 cc = rc

 if cc ^= 0 then do
   say rexxname': '
   say rexxname': error on listds' affnstgdsnq
   say rexxname': '
   do t = 1 to tsoout.0
     say tsoout.t
   end /* t = 1 to tsoout.0 */
   exit cc
 end /* cc ^= 0 */

 do t = 7 to tsoout.0
   aff_mem = STRIP(tsoout.t)

   if aff_mem = '$$$SPACE' then iterate /* pdsman spacemap           */

   say rexxname': Processing element' aff_mem

   say rexxname': Icetool JCL inserted for' aff_mem
   queue "//*************************************************************"
   queue "//**       BUILD JCL FOR AFFINITY FILE UPDATE                **"
   queue "//*************************************************************"
   queue "//JSTEP010 EXEC PGM=ICETOOL                                    "
   queue "//PDS      DD DISP=SHR,                                        "
   queue "//             DSN="affinity.stagedsn"("aff_mem")"
   queue "//QSAM     DD DISP=SHR,DSN=PGSP.BASE.AFFINITY                  "
   queue "//SYSPRINT DD SYSOUT=*                                         "
   queue "//SYSOUT   DD SYSOUT=*                                         "
   queue "//DFSMSG   DD SYSOUT=*                                         "
   queue "//TOOLMSG  DD SYSOUT=*                                         "
   queue "//SYMNOUT  DD SYSOUT=*                                         "
   queue "//MULTCNTL DD *                                                "
   queue "  OUTFIL FNAMES=QSAM                                           "
   queue "/*                                                             "
   queue "//TOOLIN   DD *                                                "
   queue "     COPY FROM(PDS) USING(MULT)                                "
   queue "/*                                                             "
   queue "//CHECK01  IF JSTEP010.RC NE 0 THEN                            "
   queue "//*************************************************************"
   queue "//** SPWARN IF MERGE OF AFFINITY FILE UPDATE                 **"
   queue "//*************************************************************"
   queue "//JSTEP020 EXEC @SPWARN                                        "
   queue "//CHECK01  ENDIF                                               "
   queue "//*                                                            "
 end /* t = 7 to tsoout.0 */

return /* affinityaddjcl: */

/*-------------------------------------------------------------------*/
/*  Add QMF data migration jcl                                       */
/*-------------------------------------------------------------------*/
qmfaddjcl:
 arg jobtype
 if jobtype = 'CJOB' then
   memname = changeid
 else
   memname = overlay('B',changeid)
 system = qmf.appl.1 /* system is always the same                    */
 queue "//*************************************************************"
 queue "//**       BUILD JCL FOR QMF DATA MIGRATION                  **"
 queue "//*************************************************************"
 queue "//SUBBER   EXEC PGM=IKJEFT1B,PARM='QMFSUB" changeid system jobtype"'"
 queue "//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.REXX                     "
 queue "//SYSTSPRT DD SYSOUT=*                                         "
 queue "//SYSTSIN  DD DUMMY                                            "
 queue "//SUBMIT   DD DISP=OLD,DSN=PGEV.PEV1.QMFJCL("memname")        "

 /*------------------------------------------------------------------*/
 /* add in QMF datasets                                              */
 /* and set up the actions for each QMF type                         */
 /*------------------------------------------------------------------*/
 do b = 1 to qmfcount /* qmf types        */
   queue "//QMF"qmf.target.b"   DD DISP=SHR,DSN="qmf.dsn.b
 end /* b = 1 to qmfcount */

 /*------------------------------------------------------------------*/
 /* set up a target card for each QMF type                           */
 /*------------------------------------------------------------------*/
 queue "//CONTROL  DD *"
 qmftypes = '' /* to build a list of types that have been added      */
 do b = 1 to qmfcount
   tgt = qmf.target.b
   queue tgt
 end /* b = 1 to qmfcount */

 queue "/*                                                             "
 queue "//*************************************************************"
 queue "//**       SPWARN IF BUILD OF JCL FAILED                     **"
 queue "//*************************************************************"
 queue "//SUBBERB  EXEC PGM=SPWARN,COND=(0,EQ,SUBBER)                  "
 queue "//STEPLIB  DD DSN=PGSP.BASE.LOAD,DISP=SHR                      "
 queue "//SYSPRINT DD SYSOUT=*,FCB=S001                                "
 queue "//*                                                            "
 queue "//*************************************************************"
 queue "//**       SUBMIT JCL TO INTRDR                              **"
 queue "//*************************************************************"
 queue "//SUBMIT   EXEC PGM=IEBGENER                                   "
 queue "//SYSUT1   DD DISP=SHR,DSN=PGEV.PEV1.QMFJCL("memname")        "
 queue "//SYSUT2   DD SYSOUT=(A,INTRDR)                                "
 queue "//SYSIN    DD DUMMY                                            "
 queue "//SYSPRINT DD SYSOUT=*                                         "
 queue "//*                                                            "
 queue "//*************************************************************"
 queue "//**       SPWARN IF SUBMIT TO INTRDR FAILED                 **"
 queue "//*************************************************************"
 queue "//SUBMITB  EXEC PGM=SPWARN,COND=(0,EQ,SUBMIT)                  "
 queue "//STEPLIB  DD DSN=PGSP.BASE.LOAD,DISP=SHR                      "
 queue "//SYSPRINT DD SYSOUT=*,FCB=S001                                "
 queue "//*                                                            "

return /* qmfaddjcl */

/*-------------------------------------------------------------------*/
/*  ADD DB2 bind / stored procedure jcl                              */
/*-------------------------------------------------------------------*/
db2_jcl:
 /* This routine is for binds & SPs so is only needed once           */
 if db2_done = jobtype then return

 db2_done = jobtype

 queue "//*************************************************************"
 queue "//**       BUILD JCL FOR GSI DB2 ACTIONS                     **"
 queue "//*************************************************************"
 queue "//SUBBER   EXEC PGM=IKJEFT1B,PARM='DB2SUB" cmjobname specific"'"
 queue "//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.REXX                      "
 queue "//SYSTSPRT DD SYSOUT=*                                         "
 queue "//SYSTSIN  DD DUMMY                                            "
 queue "//LOOKUP   DD DISP=SHR,DSN=PGEV.BASE.DATA(DB2TAB)              "
 queue "//SUBMIT   DD DISP=OLD,DSN=PGEV.PEV1.BINDJCL("cmjobname")"

 /* Add in staging datasets                                          */
 /* And set up the actions for each target DB2 subsystem             */
 actions. = ''
 do b = 1 to spdrdp_count /* drop sp cards                           */
   tgt         = substr(spdrdp_dsn.b,15,4)
   actions.tgt = actions.tgt 'SPDR'
   queue "//SPDR"tgt "DD DISP=SHR,DSN="spdrdp_stagedsn.b
 end /* b = 1 to spdrdp_count */
 do b = 1 to spcrdp_count /* create sp cards                         */
   tgt         = substr(spcrdp_dsn.b,15,4)
   actions.tgt = actions.tgt 'SPCR'
   queue "//SPCR"tgt "DD DISP=SHR,DSN="spcrdp_stagedsn.b
 end /* b = 1 to spcrdp_count */
 if jobtype = 'CJOB' then
   do b = 1 to shipdp_count /* bind cards                            */
     tgt         = substr(shipdp_dsn.b,15,4)
     actions.tgt = actions.tgt 'BIND'
     queue "//BIND"tgt "DD DISP=SHR,DSN="shipdp_stagedsn.b
   end /* b = 1 to shipdp_count */
 do b = 1 to sprfdp_count /* refresh sp cards                        */
   tgt         = substr(sprfdp_dsn.b,15,4)
   actions.tgt = actions.tgt 'WLM'
   queue "//SPRF"tgt "DD DISP=SHR,DSN="sprfdp_stagedsn.b
 end /* b = 1 to sprfdp_count */

 /* Set up a target card for each DB2 subsystem                      */
 queue "//CONTROL  DD *"
 dbtargets = '' /* to build a list of targets that have been added   */
 if jobtype = 'CJOB' then
   do b = 1 to shipdp_count
     system    = substr(shipdp_dsn.b,7,2)
     tgt       = substr(shipdp_dsn.b,15,4)
     dbtargets = dbtargets tgt
     queue "TARGET" tgt "SYSTEM" system "ACTIONS" actions.tgt
   end /* b = 1 to shipdp_count */
 do b = 1 to spdrdp_count
   tgt = substr(spdrdp_dsn.b,15,4)
   if wordpos(tgt,dbtargets) = 0 then do
     system    = substr(spdrdp_dsn.b,7,2)
     dbtargets = dbtargets tgt
     queue "TARGET" tgt "SYSTEM" system "ACTIONS" actions.tgt
   end
 end /* b = 1 to spcrdp_count */
 do b = 1 to spcrdp_count
   tgt = substr(spcrdp_dsn.b,15,4)
   if wordpos(tgt,dbtargets) = 0 then do
     system    = substr(spcrdp_dsn.b,7,2)
     dbtargets = dbtargets tgt
     queue "TARGET" tgt "SYSTEM" system "ACTIONS" actions.tgt
   end
 end /* b = 1 to spcrdp_count */
 do b = 1 to sprfdp_count
   tgt = substr(sprfdp_dsn.b,15,4)
   if wordpos(tgt,dbtargets) = 0 then do
     system    = substr(spcrdp_dsn.b,7,2)
     dbtargets = dbtargets tgt
     queue "TARGET" tgt "SYSTEM" system "ACTIONS" actions.tgt
   end
 end /* b = 1 to sprfdp_count */

 queue "/*                                                             "
 queue "//*************************************************************"
 queue "//**       SPWARN IF BUILD OF JCL FAILED                     **"
 queue "//*************************************************************"
 queue "//SUBBERB  EXEC PGM=SPWARN,COND=(0,EQ,SUBBER)                  "
 queue "//STEPLIB  DD DSN=PGSP.BASE.LOAD,DISP=SHR                      "
 queue "//SYSPRINT DD SYSOUT=*,FCB=S001                                "
 queue "//*                                                            "
 queue "//*************************************************************"
 queue "//**       SUBMIT JCL TO INTRDR                              **"
 queue "//*************************************************************"
 queue "//SUBMIT   EXEC PGM=IEBGENER                                   "
 queue "//SYSUT1   DD DISP=SHR,DSN=PGEV.PEV1.BINDJCL("cmjobname")"
 queue "//SYSUT2   DD SYSOUT=(A,INTRDR)                                "
 queue "//SYSIN    DD DUMMY                                            "
 queue "//SYSPRINT DD SYSOUT=*                                         "
 queue "//*                                                            "
 queue "//*************************************************************"
 queue "//**       SPWARN IF SUBMIT TO INTRDR FAILED                 **"
 queue "//*************************************************************"
 queue "//SUBMITB  EXEC PGM=SPWARN,COND=(0,EQ,SUBMIT)                  "
 queue "//STEPLIB  DD DSN=PGSP.BASE.LOAD,DISP=SHR                      "
 queue "//SYSPRINT DD SYSOUT=*,FCB=S001                                "
 queue "//*                                                            "

return /* db2_jcl: */

/*-------------------------------------------------------------------*/
/*  Sqldp_jcl - ADD SQL execution JCL                                */
/*-------------------------------------------------------------------*/
sqldp_jcl:

 sqlsr_count = 0  /* Count of SQL source target DSNs                 */

 /* To build backout JCL you need the staging dataset names of the   */
 /* SQL source as well as the trigger staging datasets.              */

 /* Read the Cjob JCL                                                */
 "execio * diskr jcl (stem cjob. finis"
 if rc ^= 0 then call exception rc 'DISKR of JCL failed'

 /* Loop through the Cjob and look for SQL targets                   */
 do i = 1 to cjob.0
   if left(cjob.i,5) = '//OAR' then do

     parse value cjob.i with '//' tddn junk 'DSN=' dsnl rest
     parse value dsnl   with dsn ',' rest
     parse value dsn    with qual1 '.' qual2 '.' qual3 '.' qual4

     if left(qual3,3) = 'SQL' & ,
        length(qual3) < 5     then do /* Get SQL staging DSNs        */

       /* Get the staging dataset name                               */
       staging = ''
       do x = i-1 to 1 by -1 /* Loop backwards thru the JCL          */
         if pos('DSN=',cjob.x) > 0 then
           parse value cjob.x with start 'DSN=' staging ',' rest
         if left(cjob.x,3) ^= '// ' then
           leave x
       end /* x = i-1 to 1 by -1 */

       if staging = '' then
         call exception 12 'Staging dsn not found in Cjob for' dsn

       /* Found a SQL and stg dataset so save the details            */
       sqlsr_count                = sqlsr_count + 1
       sqlsr_q3.sqlsr_count       = qual3
       sqlsr_stagedsn.sqlsr_count = strip(staging)
       say rexxname':   SQL Cjob target  DSN for backout:' dsn
       say rexxname':   SQL Cjob Staging DSN for backout:' staging

     end /* left(qual3,3) = 'SQL' & ... */

   end /* left(cjob.i,5) = '//OAR' */
 end /* i = 1 to cjob.0 */

 if jobtype = 'BJOB' then do
   /* Its a backout job.                                             */
   /* For auto backout read the Cjob and get a list of auto backout  */
   /* target and staging DSNs. I.e. Only execute auto backout SQL    */
   /* if it was delivered in the Cjob.                               */

   sqldp_count     = 0  /* Clear down the SQLDP variables            */
   sqldp_dsn       = ''
   sqldp_stagedsn. = ''

   /* Loop through the Cjob and look for auto backout targets        */
   do i = 1 to cjob.0
     if left(cjob.i,5) = '//OAR' then do

       parse value cjob.i with '//' tddn junk 'DSN=' dsnl rest
       parse value dsnl   with dsn ',' rest
       parse value dsn    with qual1 '.' qual2 '.' qual3 '.' qual4

       if substr(qual3,7,1) = 'A'     & , /* Auto backout            */
          left(qual3,5)     = 'SQLDP' then do

         /* Get the staging dataset name                             */
         staging = ''
         do x = i-1 to 1 by -1 /* Loop backwards thru the JCL        */
           if pos('DSN=',cjob.x) > 0 then
             parse value cjob.x with start 'DSN=' staging ',' rest
           if left(cjob.x,3) ^= '// ' then
             leave x
         end /* x = i-1 to 1 by -1 */

         if staging = '' then
           call exception 12 'Staging dsn not found in Cjob for' dsn

         /* Found a tgt and stg dataset so save the details          */
         sqldp_count                = sqldp_count + 1
         sqldp_dsn.sqldp_count      = dsn
         sqldp_stagedsn.sqldp_count = strip(staging)
         say rexxname':   SQL Cjob target  DSN for backout:' dsn
         say rexxname':   SQL Cjob Staging DSN for backout:' staging

       end /* substr(qual3,7,1) = 'A' & ... */

     end /* left(cjob.i,5) = '//OAR' */
   end /* i = 1 to cjob.0 */
 end /* jobtype = 'BJOB' */

 /* Add JCL to create the SQL execution job(s)                       */
 if sqldp_count > 0 then do
   queue "//"copies('*',69)
   queue "//**       BUILD JCL FOR GSI SQL EXECUTION                  "
   queue "//"copies('*',69)
   queue "//SUBBER   EXEC PGM=IKJEFT1B,PARM='SQLSUB" changeid"'"
   queue "//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.REXX                   "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//SYSTSIN  DD DUMMY                                         "
   queue "//DB2PARMS DD DISP=SHR,DSN=PGEV.BASE.ISPCLIB(DB2PARMS)      "

   /* Add in staging datasets for SQL source for BJOBs               */
   do b = 1 to sqlsr_count
     queue "//"left(sqlsr_q3.b,8) "DD DISP=SHR,DSN="sqlsr_stagedsn.b
   end /* b = 1 to sqlsr_count */

   /* Add in staging datasets for triggers                           */
   do b = 1 to sqldp_count
     suffix  = right(sqldp_dsn.b,5)
     dsgroup = substr(suffix,3,1)
     type    = substr(suffix,4,1)
     inst    = substr(suffix,5,1)
     tgt     = substr(suffix,3,3)
     select
       when type = '0' then sqlmem = 'C'substr(changeid,3,6) || inst
       when type = 'B' then sqlmem = 'B'substr(changeid,3,6) || inst
       when type = 'A' then sqlmem = 'A'substr(changeid,3,6) || inst
       otherwise call exception 12 'Invalid SQL typ:' type 'in' suffix
     end /*select */

     queue "//SQL"tgt"   DD DISP=SHR,DSN="sqldp_stagedsn.b
     queue "//SUBMT"tgt" DD DISP=OLD,DSN=PGEV.AUTO.SQLJCL"dsgroup || ,
           "("sqlmem")"
   end /* b = 1 to sqldp_count */

   /* Set up a target card for each DB2 subsystem & instance         */
   queue "//CONTROL  DD *"
   do b = 1 to sqldp_count
     suffix = right(sqldp_dsn.b,5)
     tgt    = substr(suffix,3,3)
     queue "TARGET" tgt "SYSTEM" system_name
   end /* b = 1 to sqldp_count */

   queue "/*                                                          "
   queue "//"copies('*',69)
   queue "//**       SPWARN IF BUILD OF JCL FAILED                    "
   queue "//"copies('*',69)
   queue "//SUBBERB  EXEC @SPWARN,COND=(0,EQ,SUBBER)                  "
   queue "//*                                                         "

   /* Add auto submit JCL                                            */
   do b = 1 to sqldp_count
     suffix  = right(sqldp_dsn.b,5)
     dsgroup = substr(suffix,3,1)
     type    = substr(suffix,4,1)
     inst    = substr(suffix,5,1)
     tgt     = substr(suffix,3,3)
     /* Dont submit non auto backout SQL                             */
     if (jobtype = 'CJOB' & type = '0') | ,
        (jobtype = 'BJOB' & type = 'A') then do
       select
         when type = '0' then sqlmem = 'C'substr(changeid,3,6) || inst
         when type = 'A' then sqlmem = 'A'substr(changeid,3,6) || inst
         otherwise call exception 12 'Invalid type:' type 'in' suffix
       end /*select */
       queue "//"copies('*',69)
       queue "//**       SUBMIT JCL TO INTRDR                         "
       queue "//"copies('*',69)
       queue "//SUBMT"tgt" EXEC PGM=IEBGENER                          "
       queue "//SYSUT1   DD DISP=SHR,DSN=PGEV.AUTO.SQLJCL"dsgroup || ,
             "("sqlmem")"
       queue "//SYSUT2   DD SYSOUT=(A,INTRDR)                         "
       queue "//SYSIN    DD DUMMY                                     "
       queue "//SYSPRINT DD SYSOUT=*                                  "
       queue "//*                                                     "
       queue "//"copies('*',69)
       queue "//**       SPWARN IF SUBMIT TO INTRDR FAILED            "
       queue "//"copies('*',69)
       queue "//SUBCK"tgt"  EXEC @SPWARN,COND=(0,EQ,SUBMT"tgt")       "
       queue "//*                                                     "
     end /* (jobtype = 'CJOB' & type = '0') | ... */
   end /* b = 1 to sqldp_count */
 end /* sqldp_count > 0 */

return /* sqldp_jcl: */

/*-------------------------------------------------------------------*/
/* Set up a member names for Ideal identify steps                    */
/*-------------------------------------------------------------------*/
idealjcl:
 arg dsn base type job

 /* Set Qplex llq of AH0 or CH0 because they                         */
 /* exist on the Qplex but the job will run on the Nplex             */
 pdsn = dsn

 i = pos("AR0",pdsn)
 if i > 0 then
   pdsn = overlay("AH0",pdsn,i,3)

 i = pos("CR0",pdsn)
 if i > 0 then
   pdsn = overlay("CH0",pdsn,i,3)

 /* If we are building the jcl for a Cjob then use the staging lib   */
 /* but if it is a bjob then get the member from the staging datasets*/
 /* but use the base dataset as actual input                         */
 if job = cjob then from = dsn
               else from = base

 /* Get a member list of the staging dataset                         */
 say rexxname': list directory of' dsn
 t = outtrap('TSOOUT.')
 "listds '"pdsn"' members"
 cc = rc

 if cc ^= 0 then do /* Is there an error in the listds?              */
   say rexxname': error on listds' dsn
   do t = 1 to tsoout.0
     say tsoout.t
   end /* t = 1 to tsoout.0 */
   exit cc
 end /* cc ^= 0 */

 if tsoout.0 < 7 then do
   say rexxname': Not enough members to process'
   exit 28
 end /* tsoout.0 < 8 */

 queue "//*                                                           "
 queue "//******************************************************      "
 queue "//**   IDENTIFY PROGRAMS FOR IDEAL TYPE" type "IN PROD        "
 queue "//******************************************************      "
 queue "//IDL"type"   EXEC PGM=IDBATCH,PARM='IDEAL'                   "
 queue "//STEPLIB  DD DSN=SYSCADB.IPC.PROD.SC00OPTS,DISP=SHR          "
 queue "//         DD DSN=SYSCADB.IDEAL.PROD.CUSLIB,DISP=SHR          "
 queue "//         DD DSN=SYSCADB.IPC.PROD.CUSLIB,DISP=SHR            "
 queue "//         DD DSN=SYSCADB.DATACOM.PROD.CUSLIB,DISP=SHR        "
 queue "//         DD DSN=SYSCADB.IDEAL.PROD.CAILIB,DISP=SHR          "
 queue "//         DD DSN=SYSCADB.IPC.PROD.CAILIB,DISP=SHR            "
 queue "//         DD DSN=SYSCADB.DATACOM.PROD.CAILIB,DISP=SHR        "
 queue "//         DD DSN=PGLJ.BASE.LOAD,DISP=SHR                     "
 queue "//*                                                           "
 queue "//ADRLOG   DD SYSOUT=*              IDEAL ERROR LOG           "
 queue "//AUXPRINT DD SYSOUT=*              PSS SYSOUT                "
 queue "//PRTLIST  DD SYSOUT=*              PRINT LISTING             "
 queue "//COMPLIST DD SYSOUT=*              COMPILE LISTING           "
 queue "//RUNLIST  DD SYSOUT=*              RUN LISTING               "
 queue "//LIST     DD SYSOUT=*                                        "
 queue "//VPEWTM   DD SYSOUT=*              SIMULATED PNL OUT         "
 queue "//SYSDIAL  DD SYSOUT=*              IDEAL DIAL SYSOUT         "
 queue "//SYSOUT   DD SYSOUT=*                                        "
 queue "//SYSPRINT DD SYSOUT=*                                        "
 queue "//SYSDBOUT DD SYSOUT=*                                        "
 queue "//*                                                           "
 queue "//ADRTRC   DD SPACE=(2000,2000)                               "
 queue "//ADRLIB   DD DISP=SHR,DSN=SYSCADB.IDEAL.PROD.ADRLIB          "
 queue "//ADRPNL   DD DISP=SHR,DSN=SYSCADB.IDEAL.PROD.ADRPNL          "
 queue "//ADROUT   DD DISP=SHR,DSN=SYSCADB.IDEAL.PROD.ADROUT          "
 queue "//*                                                           "
 queue "//IDDAT    DD DSN=PGLJ.PROD.IDDAT,DISP=SHR                    "
 queue "//IDDVW    DD DSN=PGLJ.PROD.IDDVW,DISP=SHR                    "
 queue "//*                                                           "
 queue "//IDL$IDO  DD DSN=PGLJ.PROD.IDL$IDO,DISP=SHR                  "
 queue "//IDL$IDP  DD DSN=PGLJ.PROD.IDL$IDP,DISP=SHR                  "
 queue "//IDL$IDS  DD DSN=PGLJ.PROD.IDL$IDS,DISP=SHR                  "
 queue "//IDLACCO  DD DSN=PGLJ.PROD.IDLACCO,DISP=SHR                  "
 queue "//IDLACCP  DD DSN=PGLJ.PROD.IDLACCP,DISP=SHR                  "
 queue "//IDLACCS  DD DSN=PGLJ.PROD.IDLACCS,DISP=SHR                  "
 queue "//IDLCLMO  DD DSN=PGLJ.PROD.IDLCLMO,DISP=SHR                  "
 queue "//IDLCLMP  DD DSN=PGLJ.PROD.IDLCLMP,DISP=SHR                  "
 queue "//IDLCLMS  DD DSN=PGLJ.PROD.IDLCLMS,DISP=SHR                  "
 queue "//IDLCLNO  DD DSN=PGLJ.PROD.IDLCLNO,DISP=SHR                  "
 queue "//IDLCLNP  DD DSN=PGLJ.PROD.IDLCLNP,DISP=SHR                  "
 queue "//IDLCLNS  DD DSN=PGLJ.PROD.IDLCLNS,DISP=SHR                  "
 queue "//IDLDBAO  DD DSN=PGLJ.PROD.IDLDBAO,DISP=SHR                  "
 queue "//IDLDBAP  DD DSN=PGLJ.PROD.IDLDBAP,DISP=SHR                  "
 queue "//IDLDBAS  DD DSN=PGLJ.PROD.IDLDBAS,DISP=SHR                  "
 queue "//IDLFINO  DD DSN=PGLJ.PROD.IDLFINO,DISP=SHR                  "
 queue "//IDLFINP  DD DSN=PGLJ.PROD.IDLFINP,DISP=SHR                  "
 queue "//IDLFINS  DD DSN=PGLJ.PROD.IDLFINS,DISP=SHR                  "
 queue "//IDLMISO  DD DSN=PGLJ.PROD.IDLMISO,DISP=SHR                  "
 queue "//IDLMISP  DD DSN=PGLJ.PROD.IDLMISP,DISP=SHR                  "
 queue "//IDLMISS  DD DSN=PGLJ.PROD.IDLMISS,DISP=SHR                  "
 queue "//IDLMUSO  DD DSN=PGLJ.PROD.IDLMUSO,DISP=SHR                  "
 queue "//IDLMUSP  DD DSN=PGLJ.PROD.IDLMUSP,DISP=SHR                  "
 queue "//IDLMUSS  DD DSN=PGLJ.PROD.IDLMUSS,DISP=SHR                  "
 queue "//IDLNUSO  DD DSN=PGLJ.PROD.IDLNUSO,DISP=SHR                  "
 queue "//IDLNUSP  DD DSN=PGLJ.PROD.IDLNUSP,DISP=SHR                  "
 queue "//IDLNUSS  DD DSN=PGLJ.PROD.IDLNUSS,DISP=SHR                  "
 queue "//IDLSCHO  DD DSN=PGLJ.PROD.IDLSCHO,DISP=SHR                  "
 queue "//IDLSCHP  DD DSN=PGLJ.PROD.IDLSCHP,DISP=SHR                  "
 queue "//IDLSCHS  DD DSN=PGLJ.PROD.IDLSCHS,DISP=SHR                  "
 queue "//IDLVEHO  DD DSN=PGLJ.PROD.IDLVEHO,DISP=SHR                  "
 queue "//IDLVEHP  DD DSN=PGLJ.PROD.IDLVEHP,DISP=SHR                  "
 queue "//IDLVEHS  DD DSN=PGLJ.PROD.IDLVEHS,DISP=SHR                  "
 queue "//*                                                           "
 queue "//IDSORTMS DD SYSOUT=*                                        "
 queue "//SORTWK01 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK02 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK03 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK04 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK05 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK06 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//*                                                           "
 queue "//SYSIN    DD DSN=PGEV.BASE.DATA(IDEND),DISP=SHR              "

 /* Member names start from item 7 in a listds command               */
 do u = 7 to tsoout.0
   mem = strip(tsoout.u)

   if mem = '$$$SPACE' then iterate /* Pdsman spacemap               */

   say rexxname': '
   say rexxname': Processing member' tsoout.u

   queue "//         DD DSN=PGEV.PLJ1.SHIP"type"("mem"),DISP=SHR      "
 end /* u = 7 to tsoout.0 */

 queue "//*                                                           "
 queue "//CHECKIT  IF (IDL"type".RUN AND IDL"type".RC GT 4) THEN      "
 queue "//SPWARN   EXEC @SPWARN                                       "
 queue "//CHECKIT  ENDIF                                              "
 queue "//*                                                           "
 queue "//******************************************************      "
 queue "//**   IDENTIFY PROGRAM FOR IDEAL TYPE "type" IN TRNG         "
 queue "//******************************************************      "
 queue "//TDL"type"   EXEC PGM=IDBATCH,PARM='IDEAL'                   "
 queue "//STEPLIB  DD DSN=SYSCADB.IPC.PROD.SC00OPTS,DISP=SHR          "
 queue "//         DD DSN=SYSCADB.IDEAL.TRNG.CUSLIB,DISP=SHR          "
 queue "//         DD DSN=SYSCADB.IPC.TRNG.CUSLIB,DISP=SHR            "
 queue "//         DD DSN=SYSCADB.DATACOM.TRNG.CUSLIB,DISP=SHR        "
 queue "//         DD DSN=SYSCADB.IDEAL.TRNG.CAILIB,DISP=SHR          "
 queue "//         DD DSN=SYSCADB.IPC.TRNG.CAILIB,DISP=SHR            "
 queue "//         DD DSN=SYSCADB.DATACOM.TRNG.CAILIB,DISP=SHR        "
 queue "//         DD DSN=PGLJ.BASE.LOAD,DISP=SHR                     "
 queue "//*                                                           "
 queue "//ADRLOG   DD SYSOUT=*              IDEAL ERROR LOG           "
 queue "//AUXPRINT DD SYSOUT=*              PSS SYSOUT                "
 queue "//PRTLIST  DD SYSOUT=*              PRINT LISTING             "
 queue "//COMPLIST DD SYSOUT=*              COMPILE LISTING           "
 queue "//RUNLIST  DD SYSOUT=*              RUN LISTING               "
 queue "//LIST     DD SYSOUT=*                                        "
 queue "//VPEWTM   DD SYSOUT=*              SIMULATED PNL OUT         "
 queue "//SYSDIAL  DD SYSOUT=*              IDEAL DIAL SYSOUT         "
 queue "//SYSOUT   DD SYSOUT=*                                        "
 queue "//SYSPRINT DD SYSOUT=*                                        "
 queue "//SYSDBOUT DD SYSOUT=*                                        "
 queue "//*                                                           "
 queue "//ADRTRC   DD SPACE=(2000,2000)                               "
 queue "//ADRLIB   DD DISP=SHR,DSN=SYSCADB.IDEAL.TRNG.ADRLIB          "
 queue "//ADRPNL   DD DISP=SHR,DSN=SYSCADB.IDEAL.TRNG.ADRPNL          "
 queue "//ADROUT   DD DISP=SHR,DSN=SYSCADB.IDEAL.TRNG.ADROUT          "
 queue "//*                                                           "
 queue "//IDDAT    DD DSN=PGLJ.TRNG.IDDAT,DISP=SHR                    "
 queue "//IDDVW    DD DSN=PGLJ.TRNG.IDDVW,DISP=SHR                    "
 queue "//*                                                           "
 queue "//IDL$IDO  DD DSN=PGLJ.TRNG.IDL$IDO,DISP=SHR                  "
 queue "//IDL$IDP  DD DSN=PGLJ.TRNG.IDL$IDP,DISP=SHR                  "
 queue "//IDL$IDS  DD DSN=PGLJ.TRNG.IDL$IDS,DISP=SHR                  "
 queue "//*                                                           "
 queue "//IDSORTMS DD SYSOUT=*                                        "
 queue "//SORTWK01 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK02 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK03 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK04 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK05 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//SORTWK06 DD SPACE=(4096,250,,,ROUND)                        "
 queue "//*                                                           "
 queue "//SYSIN    DD DSN=PGEV.BASE.DATA(IDEND),DISP=SHR              "

 /* Member names start from item 7 in a listds command               */
 do u = 7 to tsoout.0
   mem = strip(tsoout.u)

   if mem = '$$$SPACE' then iterate /* Pdsman spacemap               */

   say rexxname': '
   say rexxname': Processing member' tsoout.u

   queue "//         DD DSN=PGEV.PLJ1.SHIP"type"("mem"),DISP=SHR      "
 end /* u = 7 to tsoout.0 */

 queue "//*                                                           "
 queue "//CHECKIT  IF (TDL"type".RUN AND TDL"type".RC GT 4) THEN      "
 queue "//SPWARN   EXEC @SPWARN                                       "
 queue "//CHECKIT  ENDIF                                              "
 queue "//*                                                           "

return /* idealjcl: */

/*-------------------------------------------------------------------*/
/* Set up a member names for Ideal identify steps                    */
/*-------------------------------------------------------------------*/
sqlplanjcl:
 arg dsn base type job

 /* Set Qplex qualifier of PREV and llq of AH0 or CH0 because they   */
 /* exist on the Qplex but the job will run on the Nplex             */
 pdsn = dsn

 i = pos("AR0",pdsn)
 if i > 0 then
   pdsn = overlay("AH0",pdsn,i,3)

 i = pos("CR0",pdsn)
 if i > 0 then
   pdsn = overlay("CH0",pdsn,i,3)

 /* If we are building the jcl for a Cjob then use the staging lib   */
 /* but if it is a Bjob then get the member from the staging datasets*/
 /* but use the base dataset as actual input                         */
 if job = cjob then from = dsn
               else from = base

 /* get a member list of the staging dataset                         */
 say rexxname': list directory of' dsn
 t = outtrap('TSOOUT.')
 "listds '"pdsn"' members"
 cc = rc

 if cc ^= 0 then do /* Is there an error in the listds?              */
   say rexxname': error on listds' dsn
   do t = 1 to tsoout.0
     say tsoout.t
   end
   exit cc
 end /* cc ^= 0 */

 /* Member names start from item 7 in a lsitds command               */
 s = 0 /* Reset the step number to zero                              */
 do u = 7 to tsoout.0
   s = s + 1 /* Increment the step number                            */
   mem = strip(tsoout.u)

   if mem = '$$$SPACE' then iterate /* Pdsman spacemap               */

   say rexxname': '
   say rexxname': Processing member' tsoout.u

   queue "//***************************************************       "
   queue "//**   IMPORT SQLPLAN IN TO THE PROD MUF                    "
   queue "//***************************************************       "
   queue "//PLAN"s"    EXEC PGM=DDTRSLM                               "
   queue "//STEPLIB  DD DSN=SYSCADB.IDEAL.PROD.CUSLIB,DISP=SHR        "
   queue "//         DD DSN=SYSCADB.IPC.PROD.CUSLIB,DISP=SHR          "
   queue "//         DD DSN=SYSCADB.DATACOM.PROD.CUSLIB,DISP=SHR      "
   queue "//         DD DSN=SYSCADB.IDEAL.PROD.CAILIB,DISP=SHR        "
   queue "//         DD DSN=SYSCADB.IPC.PROD.CAILIB,DISP=SHR          "
   queue "//         DD DSN=SYSCADB.DATACOM.PROD.CAILIB,DISP=SHR      "
   queue "//*                                                         "
   queue "//CXX      DD DSN=PGZ0.PROD.CXX.SPDACTRL,DISP=SHR           "
   queue "//DDSNAP   DD SYSOUT=*                                      "
   queue "//SNAPER   DD SYSOUT=*                                      "
   queue "//SYSOUT   DD SYSOUT=*                                      "
   queue "//SYSPRINT DD SYSOUT=*                                      "
   queue "//SYSPUNCH DD DUMMY                                         "
   queue "//SYSUDUMP DD SYSOUT=C                                      "
   queue "//TRANSF   DD DSN="from"("mem"),"
   queue "//             DISP=SHR                                     "
   queue "//SYSIN    DD *                                             "
   queue "SET USER DBA BLIMEY;                                        "
   queue "IMPORT ALL PLAN;                                            "
   queue "/*                                                          "
   queue "//*                                                         "
   queue "//CHECKIT  IF (PLAN"s".RUN AND PLAN"s".RC GT 4) THEN        "
   queue "//SPWARN"s"  EXEC @SPWARN                                   "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//**   IMPORT SQLPLAN IN TO THE TRNG MUF                    "
   queue "//***************************************************       "
   queue "//TPLN"s"    EXEC PGM=DDTRSLM                               "
   queue "//STEPLIB  DD DSN=SYSCADB.IDEAL.TRNG.CUSLIB,DISP=SHR        "
   queue "//         DD DSN=SYSCADB.IPC.TRNG.CUSLIB,DISP=SHR          "
   queue "//         DD DSN=SYSCADB.DATACOM.TRNG.CUSLIB,DISP=SHR      "
   queue "//         DD DSN=SYSCADB.IDEAL.TRNG.CAILIB,DISP=SHR        "
   queue "//         DD DSN=SYSCADB.IPC.TRNG.CAILIB,DISP=SHR          "
   queue "//         DD DSN=SYSCADB.DATACOM.TRNG.CAILIB,DISP=SHR      "
   queue "//*                                                         "
   queue "//CXX      DD DSN=PGZ0.TRNG.CXX.SPDACTRL,DISP=SHR           "
   queue "//DDSNAP   DD SYSOUT=*                                      "
   queue "//SNAPER   DD SYSOUT=*                                      "
   queue "//SYSOUT   DD SYSOUT=*                                      "
   queue "//SYSPRINT DD SYSOUT=*                                      "
   queue "//SYSPUNCH DD DUMMY                                         "
   queue "//SYSUDUMP DD SYSOUT=C                                      "
   queue "//TRANSF   DD DSN="from"("mem"),"
   queue "//             DISP=SHR                                     "
   queue "//SYSIN    DD *                                             "
   queue "SET USER DBA BLIMEY;                                        "
   queue "IMPORT ALL PLAN;                                            "
   queue "/*                                                          "
   queue "//*                                                         "
   queue "//CHECKIT  IF (TPLN"s".RUN AND TPLN"s".RC GT 4) THEN        "
   queue "//SPWARN"s"  EXEC @SPWARN                                   "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
 end /* u = 7 to tsoout.0 */

return /* sqlplanjcl: */

/*-------------------------------------------------------------------*/
/* add PRO4 backup jcl                                               */
/*-------------------------------------------------------------------*/
addpro4bkup:
 queue "//****************************************************      "
 queue "//** DEFINE BANKING PRO4 BACKUP VSAM FILES          **      "
 queue "//****************************************************      "
 queue "//DEFINE  EXEC PGM=IDCAMS                                   "
 queue "//SYSPRINT DD SYSOUT=*                                      "
 queue "//SYSIN    DD *                                             "
 queue " DELETE PGEV."changeid".BACKUP.DEVELOP CLUSTER PURGE          "
 queue " DELETE PGEV."changeid".BACKUP.EXEC    CLUSTER PURGE          "
 queue " DELETE PGEV."changeid".BACKUP.GENFILE CLUSTER PURGE          "
 queue " SET MAXCC = 0                                              "
 queue " DEFINE CLUSTER -                                           "
 queue "    (NAME(PGEV."changeid".BACKUP.DEVELOP) -                   "
 queue "     MODEL("rbspro4".DEVELOP)) -                            "
 queue "     DATA -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.DEVELOP.DATA) -              "
 queue "     MODEL("rbspro4".DEVELOP.DATA)) -                       "
 queue "    INDEX -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.DEVELOP.INDEX) -             "
 queue "     MODEL("rbspro4".DEVELOP.INDEX))                        "
 queue " DEFINE CLUSTER -                                           "
 queue "    (NAME(PGEV."changeid".BACKUP.GENFILE) -                   "
 queue "     MODEL("rbspro4".GENFILE)) -                            "
 queue "    DATA -                                                  "
 queue "    (NAME(PGEV."changeid".BACKUP.GENFILE.DATA) -              "
 queue "     MODEL("rbspro4".GENFILE.DATA)) -                       "
 queue "    INDEX -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.GENFILE.INDEX) -             "
 queue "     MODEL("rbspro4".GENFILE.INDEX))                        "
 queue " DEFINE CLUSTER -                                           "
 queue "    (NAME(PGEV."changeid".BACKUP.EXEC) -                      "
 queue "     MODEL("rbspro4".EXEC)) -                               "
 queue "     DATA -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.EXEC.DATA) -                 "
 queue "     MODEL("rbspro4".EXEC.DATA)) -                          "
 queue "     INDEX -                                                "
 queue "    (NAME(PGEV."changeid".BACKUP.EXEC.INDEX) -                "
 queue "     MODEL("rbspro4".EXEC.INDEX))                           "
 queue "/*                                                          "
 queue "//****************************************************      "
 queue "//** SPWARN IF DEFINE FAILED                        **      "
 queue "//****************************************************      "
 queue "//CHECKIT  IF (DEFINE.RUN AND DEFINE.RC GT 0) THEN          "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//**INITIALISE PRO4 EXEC FILE                       **      "
 queue "//****************************************************      "
 queue "//EXEC     EXEC PGM=SFINITA,PARM=PHYSICAL                   "
 queue "//STEPLIB  DD DSN=PGMT.BASE.LOAD,DISP=SHR                   "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSFILE  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR        "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//**       SPWARN IF EXEC FAILED                    **      "
 queue "//****************************************************      "
 queue "//CHECKIT  IF (EXEC.RUN AND EXEC.RC GT 0) THEN              "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//**INITIALISE DEVELOP FILE                         **      "
 queue "//****************************************************      "
 queue "//DEVELOP  EXEC PGM=SFINITA,PARM=PHYSICAL                   "
 queue "//STEPLIB  DD DSN=PGMT.BASE.LOAD,DISP=SHR                   "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSFILE  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR     "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//**       SPWARN IF DEVELOP FAILED                 **      "
 queue "//****************************************************      "
 queue "//CHECKIT  IF (DEVELOP.RUN AND DEVELOP.RC GT 0) THEN        "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//** INITIALISE GENFILE FILE                        **      "
 queue "//****************************************************      "
 queue "//GENFILE  EXEC PGM=SFINITA,PARM=PHYSICAL                   "
 queue "//STEPLIB  DD DSN=PGMT.BASE.LOAD,DISP=SHR                   "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSFILE  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR     "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//** SPWARN IF GENFILE FAILED                       **      "
 queue "//****************************************************      "
 queue "//CHECKIT  IF (GENFILE.RUN AND GENFILE.RC GT 0) THEN        "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//** BACKUP PRO4 FUNCTIONS TO BE COPIED             **      "
 queue "//****************************************************      "
 queue "//PRO4BKP  EXEC PGM=PROUTVV                                 "
 queue "//STEPLIB  DD DSN=PGMT.BASE.LOAD,DISP=SHR                   "
 queue "//PROXECI  DD DSN="rbspro4".EXEC,DISP=SHR                   "
 queue "//PRODEVI  DD DSN="rbspro4".DEVELOP,DISP=SHR                "
 queue "//GENFILI  DD DSN="rbspro4".GENFILE,DISP=SHR                "
 queue "//PROXECO  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR        "
 queue "//PRODEVO  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR     "
 queue "//GENFILO  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR     "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSIN    DD DISP=SHR,                                     "
 queue "//         DSN="parm.stagedsn"("pro4mem")"
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//** SPWARN IF PRO4BKP FAILED                       **      "
 queue "//****************************************************      "
 queue "//CHECKIT  IF (PRO4BKP.RUN AND PRO4BKP.RC GT 4) THEN        "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//PARMBKUP EXEC PGM=IEBGENER                                "
 queue "//FCOPYIN  DD DUMMY                                         "
 queue "//SYSPRINT DD SYSOUT=*                                      "
 queue "//SYSUT1   DD DISP=SHR,                                     "
 queue "//         DSN="parm.stagedsn"("pro4mem")"
 queue "//SYSUT2   DD DSN=PGEV."changeid".BACKUP.PARMS,               "
 queue "//            DISP=(NEW,CATLG),                             "
 queue "//            DCB=(LRECL=80,RECFM=FB,DSORG=PS),             "
 queue "//            SPACE=(CYL,(5,5))                             "
 queue "//SYSIN    DD DUMMY                                         "
 queue "//*                                                         "
return /* addpro4bkup: */

/*-------------------------------------------------------------------*/
/* add banking PRO4 EVD888D step                                     */
/*-------------------------------------------------------------------*/
addevd888d:
 queue "//****************************************************"
 queue "//** Run step to load EVD888D on Ca7FROW              "
 queue "//****************************************************"
 queue "//STEP005  EXEC @SASBSTR,                            "
 queue "//             LOCN=FROW,                            "
 queue "//             HLQ=PROS,                             "
 queue "//             TERMNO=0                              "
 queue "//SYSIN    DD *                                      "
 queue "DEMAND,JOB=EVD4888D                                  "
 queue "/*                                                   "
 queue "//SYSPRINT DD DSN=&&CA7FR,DISP=(NEW,PASS),           "
 queue "//             SPACE=(TRK,(16,16)),RECFM=FB,         "
 queue "//             LRECL=80                              "
 queue "//******************************                     "
 queue "//*   VALIDATE THE CA7 OUTPUT  *                     "
 queue "//******************************                     "
 queue "//*                                                  "
 queue "//STEP007  EXEC PGM=IRXJCL,                          "
 queue "//             PARM='CA7CHECK'                       "
 queue "//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                     "
 queue "//SYSTSPRT DD SYSOUT=*                               "
 queue "//SYSTSIN  DD SYSOUT=*                               "
 queue "//CA7IN    DD DSN=&&CA7FR,DISP=(OLD,DELETE)          "
 queue "//CA7OUT   DD SYSOUT=*                               "
return /* addevd888d: */

/*-------------------------------------------------------------------*/
/* add insurance PRO4 backup steps                                   */
/*-------------------------------------------------------------------*/
addipro4bkup:
 queue "//***************************************************       "
 queue "//** DEFINE INSURANCE PRO4 BACKUP VSAM FILES       **       "
 queue "//***************************************************       "
 queue "//DEFINE  EXEC PGM=IDCAMS                                   "
 queue "//SYSPRINT DD SYSOUT=*                                      "
 queue "//SYSIN    DD *                                             "
 queue " DELETE PGEV."changeid".BACKUP.DEVELOP CLUSTER PURGE          "
 queue " DELETE PGEV."changeid".BACKUP.EXEC    CLUSTER PURGE          "
 queue " DELETE PGEV."changeid".BACKUP.GENFILE CLUSTER PURGE          "
 queue " SET MAXCC = 0                                              "
 queue " DEFINE CLUSTER -                                           "
 queue "    (NAME(PGEV."changeid".BACKUP.DEVELOP) -                   "
 queue "     MODEL(PGEV.MODEL.DEVELOP)) -                             "
 queue "     DATA -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.DEVELOP.DATA) -              "
 queue "     MODEL(PGEV.MODEL.DEVELOP.DATA)) -                        "
 queue "    INDEX -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.DEVELOP.INDEX) -             "
 queue "     MODEL(PGEV.MODEL.DEVELOP.INDEX))                         "
 queue " DEFINE CLUSTER -                                           "
 queue "    (NAME(PGEV."changeid".BACKUP.GENFILE) -                   "
 queue "     MODEL(PGEV.MODEL.GENFILE)) -                             "
 queue "     DATA -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.GENFILE.DATA) -              "
 queue "     MODEL(PGEV.MODEL.GENFILE.DATA)) -                        "
 queue "    INDEX -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.GENFILE.INDEX) -             "
 queue "     MODEL(PGEV.MODEL.GENFILE.INDEX))                         "
 queue " DEFINE CLUSTER -                                           "
 queue "    (NAME(PGEV."changeid".BACKUP.EXEC) -                      "
 queue "     MODEL(PGEV.MODEL.EXEC)) -                                "
 queue "     DATA -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.EXEC.DATA)        -          "
 queue "     MODEL(PGEV.MODEL.EXEC.DATA)) -                           "
 queue "    INDEX -                                                 "
 queue "    (NAME(PGEV."changeid".BACKUP.EXEC.INDEX)       -          "
 queue "     MODEL(PGEV.MODEL.EXEC.INDEX))                            "
 queue "/*                                                          "
 queue "//***************************************************       "
 queue "//** SPWARN IF DEFINE FAILED                       **       "
 queue "//***************************************************       "
 queue "//CHECKIT  IF (DEFINE.RUN AND DEFINE.RC GT 0) THEN          "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//**INITIALISE PRO4 EXEC FILE                      **       "
 queue "//***************************************************       "
 queue "//EXEC     EXEC PGM=SFINITA,PARM=PHYSICAL                   "
 queue "//STEPLIB  DD DSN="pro4load",DISP=SHR                       "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSFILE  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR        "
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//** SPWARN IF EXEC FAILED                         **       "
 queue "//***************************************************       "
 queue "//CHECKIT  IF (EXEC.RUN AND EXEC.RC GT 0) THEN              "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//**INITIALISE DEVELOP FILE                        **       "
 queue "//***************************************************       "
 queue "//DEVELOP  EXEC PGM=SFINITA,PARM=PHYSICAL                   "
 queue "//STEPLIB  DD DSN="pro4load",DISP=SHR                       "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSFILE  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR     "
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//** SPWARN IF DEVELOP FAILED                      **       "
 queue "//***************************************************       "
 queue "//CHECKIT  IF (DEVELOP.RUN AND DEVELOP.RC GT 0) THEN        "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//** INITIALISE GENFILE FILE                       **       "
 queue "//***************************************************       "
 queue "//GENFILE  EXEC PGM=SFINITA,PARM=PHYSICAL                   "
 queue "//STEPLIB  DD DSN="pro4load",DISP=SHR                       "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSFILE  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR     "
 queue "//*                                                         "
 queue "//****************************************************      "
 queue "//** SPWARN IF GENFILE FAILED                       **      "
 queue "//****************************************************      "
 queue "//CHECKIT  IF (GENFILE.RUN AND GENFILE.RC GT 0) THEN        "
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
return /* addipro4bkup: */

/*-------------------------------------------------------------------*/
/* add insurance PRO4 app specific steps                             */
/*-------------------------------------------------------------------*/
addibkapp:
 arg iapp1 iapp iload iexec idev igen
 queue "//***************************************************       "
 queue "//** SINGLE STREAM" iapp "PRO4 UPDATE              **       "
 queue "//***************************************************       "
 queue "//LOCK"iapp" EXEC PGM=IEFBR14                            "
 queue "//DD01     DD DSN=PGEV.PLN1.PRO4LOCK."iapp",DISP=OLD"
 queue "//***************************************************       "
 queue "//** BACKUP" iapp "FUNCTIONS BEFORE UPDATE           **"
 queue "//***************************************************       "
 queue "//BKUP"iapp" EXEC PGM=PROUTVV                            "
 queue "//STEPLIB  DD DSN="iload",DISP=SHR                       "
 queue "//PROXECI  DD DSN="iexec",DISP=SHR                       "
 queue "//PRODEVI  DD DSN="idev",DISP=SHR                        "
 queue "//GENFILI  DD DSN="igen",DISP=SHR                        "
 queue "//PROXECO  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR        "
 queue "//PRODEVO  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR     "
 queue "//GENFILO  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR     "
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSIN    DD DISP=SHR,                                     "
 interpret 'queue "//         DSN="parm'iapp1'.stagedsn"('changeid')"'
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//** SPWARN IF BKUP"iapp" FAILS                       "
 queue "//***************************************************       "
 queue "//CHECKIT  IF (BKUP"iapp".RUN AND BKUP"iapp".RC GT 4) THEN"
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//** BACKUP SHIPPED PARM FILES                     **       "
 queue "//***************************************************       "
 queue "//BKPARM"iapp1 " EXEC PGM=IEBGENER"
 queue "//FCOPYIN  DD DUMMY                                         "
 queue "//SYSPRINT DD SYSOUT=*                                      "
 queue "//SYSUT1   DD DISP=SHR,   /*" iapp" */                      "
 interpret 'queue "//         DSN="parm'iapp1'.stagedsn"("changeid")"'
 queue "//SYSUT2   DD DSN=PGEV."changeid"."iapp".BACKUP.PARMS,"
 queue "//            DISP=(NEW,CATLG),                             "
 queue "//            LRECL=80,RECFM=FB,                            "
 queue "//            SPACE=(CYL,(5,5))                             "
 queue "//SYSIN    DD DUMMY                                         "
 queue "//*                                                         "
 queue "//***************************************************       "
 queue "//** SPWARN IF PARM BACKUP FAILS                   **       "
 queue "//***************************************************       "
 queue "//CHECKIT  IF (BKPARM"iapp1".RUN AND BKPARM"iapp1".RC GT 0) THEN"
 queue "//SPWARN   EXEC @SPWARN                                     "
 queue "//CHECKIT  ENDIF                                            "
 queue "//*                                                         "
return /* addibkapp: */

/*-------------------------------------------------------------------*/
/* add insurance PRO4 pro4 backout                                   */
/*-------------------------------------------------------------------*/
addpro4ib:
 if pro4ilife = 'YES' then do
   queue "//****************************************************      "
   queue "//** BACKOUT RBS INSURANCE PRO-IV ELEMENTS          **      "
   queue "//****************************************************      "
   queue "//PRO4BAKL EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR                       "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="lifeexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="lifedev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="lifegen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".LIFE.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF BACKOUT FAILED                      **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4BAKL.RUN AND PRO4BAKL.RC GT 4) THEN      "
   queue "//*                                                         "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//****************************************************      "
   queue "//** BACKOUT RBS INSURANCE PRO-IV TPF ELEMENTS      **      "
   queue "//****************************************************      "
   queue "//PRO4BAKT EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR                       "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="tpfexec",DISP=SHR                        "
   queue "//PRODEVO  DD DSN="tpfdev",DISP=SHR                         "
   queue "//GENFILO  DD DSN="tpfgen",DISP=SHR                         "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".LIFE.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF BACKOUT FAILED                      **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4BAKT.RUN AND PRO4BAKT.RC GT 4) THEN      "
   queue "//*                                                         "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** BACKOUT RBS INSURANCE LIFE  TRAINING ELEMENTS **       "
   queue "//***************************************************       "
   queue "//PRO4BKLT EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR                       "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="lifeexect",DISP=SHR"
   queue "//PRODEVO  DD DSN="lifedevt",DISP=SHR"
   queue "//GENFILO  DD DSN="lifegent",DISP=SHR"
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".LIFE.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF TRAINING BACKOUT FAILED             **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4BKLT.RUN AND PRO4BKLT.RC GT 4) THEN      "
   queue "//*                                                         "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//***************************************************       "
   queue "//* DELETE MAIL FILES                              **       "
   queue "//***************************************************       "
   queue "//STEP010  EXEC PGM=IEFBR14                                 "
   queue "//MAILHEAD DD DSN=PZLL.NLI00.PRO4.MAILHEAD,                 "
   queue "//             DISP=(MOD,DELETE),SPACE=(CYL,(70,30))        "
   queue "//MAILATTC DD DSN=PZLL.NLI00.PRO4.MAILATTC,                 "
   queue "//             DISP=(MOD,DELETE),SPACE=(CYL,(70,30))        "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//* REDEFINE MAIL FILES                            **       "
   queue "//***************************************************       "
   queue "//STEP020  EXEC PGM=IEFBR14                                 "
   queue "//MAILHEAD DD DSN=PZLL.NLI00.PRO4.MAILHEAD,                 "
   queue "//             DISP=(MOD,CATLG),                            "
   queue "//             RECFM=FB,LRECL=90,BLKSIZE=900,               "
   queue "//             SPACE=(CYL,(70,30))                          "
   queue "//MAILATTC DD DSN=PZLL.NLI00.PRO4.MAILATTC,                 "
   queue "//             DISP=(MOD,CATLG),                            "
   queue "//             RECFM=FB,LRECL=250,BLKSIZE=2500,             "
   queue "//             SPACE=(CYL,(70,30))                          "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** UPDATE LIFE VERSION MANAGEMENT SYSTEM         **       "
   queue "//***************************************************       "
   queue "//VMUPDT   EXEC PGM=PROMVS,                                 "
   queue "//             PARM='CODIV=LDS,OPER=LDS,FUNCTION=VMXFRU01'  "
   queue "//STEPLIB  DD DSN="lifeload",DISP=SHR"
   queue "//PROEXEC  DD DSN="lifeexec",DISP=SHR"
   queue "//GENFILE  DD DSN="lifegen",DISP=SHR"
   queue "//PROPRNT  DD SYSOUT=*                                      "
   queue "//SYSOUT   DD SYSOUT=*                                      "
   queue "//SYSPRINT DD SYSOUT=*                                      "
   queue "//PROMSG   DD SYSOUT=*                                      "
   queue "//*                                                         "
   queue "//LPAD     DD DSN=PZLL.VLI00.LPAD,DISP=SHR                  "
   queue "//LVVMS    DD DSN=PZLL.VLI00.LVVMS.BATCH,DISP=SHR           "
   queue "//LSTF     DD DSN=PZLL.VLI00.LSTF,DISP=SHR                  "
   queue "//LPARAM1  DD DISP=SHR,                                     "
   queue "//             DSN=PGEV."changeid".LIFE.BACKUP.PARMS        "
   queue "//LPARAM2  DD DSN=PGEV.BASE.DATA(VMACPT),DISP=SHR           "
   queue "//LPARAM3  DD DSN=PGEV.BASE.DATA(VMPROD),DISP=SHR           "
   queue "//LPARAM4  DD *                                             "
   queue " "changeid"  BACKED OUT"
   queue "/*                                                          "
   queue "//MAILATTC DD DSN=PZLL.NLI00.PRO4.MAILATTC,DISP=SHR         "
   queue "//MAILHEAD DD DSN=PZLL.NLI00.PRO4.MAILHEAD,DISP=SHR         "
   queue "//LSTV     DD DSN=PZLL.VLI00.LSTV,DISP=SHR                  "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF VERSION MANAGEMENT UPDATE FAILS     **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (VMUPDT.RUN AND VMUPDT.RC GT 0) THEN          "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SENDMAIL TO CONFIRM THE UPDATE HAS RUN        **       "
   queue "//***************************************************       "
   queue "//SENDMAIL EXEC PGM=IKJEFT1B                                "
   queue "//SYSEXEC  DD DSN=PGLN.BASE.REXX,DISP=SHR                   "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//SYSTSIN  DD DSN=PZLL.NLI00.MAILPARM,DISP=SHR              "
   queue "//SYSTCPD  DD DSN=SYS1.TCPPARMS(TCPDATA),DISP=SHR           "
   queue "//SYSHEAD  DD DSN=PZLL.NLI00.PRO4.MAILHEAD,DISP=SHR         "
   queue "//SYSATTC  DD DSN=PZLL.NLI00.PRO4.MAILATTC,DISP=SHR         "
   queue "//SYSBODY  DD DSN=PZLL.NLI00.DEFAULT.MAILBODY,DISP=SHR      "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF EMAIL FAILS                         **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (SENDMAIL.RUN AND SENDMAIL.RC GT 0) THEN      "
   queue "//*                                                         "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
 end /* pro4ilife = 'yes' */

 if pro4iloan = 'YES' then do
   queue "//****************************************************      "
   queue "//** BACKOUT RBS INSURANCE PRO-IV ELEMENTS          **      "
   queue "//****************************************************      "
   queue "//PRO4BAKP EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="loanexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="loandev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="loangen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".LOAN.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//****************************************************      "
   queue "//** SPWARN IF BACKOUT FAILED                       **      "
   queue "//****************************************************      "
   queue "//CHECKIT  IF (PRO4BAKP.RUN AND PRO4BAKP.RC GT 4) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//****************************************************      "
   queue "//** BACKOUT RBS INSURANCE LOAN TRAINING ELEMENTS   **      "
   queue "//****************************************************      "
   queue "//PRO4BKPT EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="loanexect",DISP=SHR                      "
   queue "//PRODEVO  DD DSN="loandevt",DISP=SHR                       "
   queue "//GENFILO  DD DSN="loangent",DISP=SHR                       "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".LOAN.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//****************************************************      "
   queue "//** SPWARN IF TRAINING BACKOUT FAILED              **      "
   queue "//****************************************************      "
   queue "//CHECKIT  IF (PRO4BKPT.RUN AND PRO4BKPT.RC GT 4) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
 end /* pro4iloan = 'yes' */

 if pro4isavg = 'YES' then do
   queue "//****************************************************      "
   queue "//** BACKOUT RBS INSURANCE PRO-IV ELEMENTS          **      "
   queue "//****************************************************      "
   queue "//PRO4BAKS EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="savgexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="savgdev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="savggen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".SAVG.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//****************************************************      "
   queue "//** SPWARN IF BACKOUT FAILED                       **      "
   queue "//****************************************************      "
   queue "//CHECKIT  IF (PRO4BAKS.RUN AND PRO4BAKS.RC GT 4) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//****************************************************      "
   queue "//** BACKOUT RBS INSURANCE LOAN  TRAINING ELEMENTS  **      "
   queue "//****************************************************      "
   queue "//PRO4BKST EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="savgexect",DISP=SHR                      "
   queue "//PRODEVO  DD DSN="savgdevt",DISP=SHR                       "
   queue "//GENFILO  DD DSN="savggent",DISP=SHR                       "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".SAVG.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//****************************************************      "
   queue "//** SPWARN IF TRAINING BACKOUT FAILED              **      "
   queue "//****************************************************      "
   queue "//CHECKIT  IF (PRO4BKST.RUN AND PRO4BKST.RC GT 4) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
 end /* pro4isavg = 'yes' */

 if pro4icall = 'YES' then do
   queue "//***************************************************       "
   queue "//** BACKOUT RBS INSURANCE PRO-IV ELEMENTS         **       "
   queue "//***************************************************       "
   queue "//PRO4BAKX EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="callexec",DISP=SHR                       "
   queue "//PRODEVO  DD DSN="calldev",DISP=SHR                        "
   queue "//GENFILO  DD DSN="callgen",DISP=SHR                        "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".CALL.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF BACKOUT FAILED                      **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4BAKX.RUN AND PRO4BAKX.RC GT 4) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** BACKOUT RBS INSURANCE LOAN  TRAINING ELEMENTS **       "
   queue "//***************************************************       "
   queue "//PRO4BKXT EXEC PGM=PROUTVV                                 "
   queue "//STEPLIB  DD DSN="obbload",DISP=SHR                        "
   queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR      "
   queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR   "
   queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR   "
   queue "//PROXECO  DD DSN="callexect",DISP=SHR                      "
   queue "//PRODEVO  DD DSN="calldevt",DISP=SHR                       "
   queue "//GENFILO  DD DSN="callgent",DISP=SHR                       "
   queue "//PRINTR   DD SYSOUT=*                                      "
   queue "//SYSIN    DD DISP=SHR,                                     "
   queue "//         DSN=PGEV."changeid".CALL.BACKUP.PARMS            "
   queue "//*                                                         "
   queue "//***************************************************       "
   queue "//** SPWARN IF TRAINING BACKOUT FAILED             **       "
   queue "//***************************************************       "
   queue "//CHECKIT  IF (PRO4BKXT.RUN AND PRO4BKXT.RC GT 4) THEN      "
   queue "//SPWARN   EXEC @SPWARN                                     "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
 end /* pro4icall = 'yes' */
return /* addpro4ib: */

/*-------------------------------------------------------------------*/
/* add DFHCSD or DLICSD JCL                                          */
/*-------------------------------------------------------------------*/
csd_jcl:

 stgdsn = value(trigger'_stagedsn.1')

 do i = 1 to words(towers_list)
   tower_name = word(towers_list,i)
   /* Use the first and last chars of the tower for job & member     */
   tower   = left(tower_name,1,1)||right(tower_name,1,1)
   jobname = 'EVLCSD'tower
   member  = overlay(tower,changeid)

   newstack /* New stack for adding JCL to CA7 demand steps          */

   queue "//"jobname" JOB 1,CLASS=N,MSGCLASS=Y,USER=GRP               "
   queue "//*                                                         "
   queue "//* JCL BUILT BY PACKAGE CMR -" changeid jobtype
   queue "//*                                                         "
   queue "//JCLLIB   JCLLIB ORDER=PGOS.BASE.PROCLIB                   "
   queue "//*                                                         "
   queue "//JSTEP010 EXEC SPCSDUPT,TOWER="tower_name",                "
   queue "//             STGDSN="stgdsn

   /* Add the CA7 demand JCL to the job                              */
   call ca7_demand jobname member 'DEFAULT'

 end /* i = 1 to words(towers) */

return /* csd_jcl: */

/*-------------------------------------------------------------------*/
/* add walker cjob JCL                                               */
/*-------------------------------------------------------------------*/
walkjcl_jcl:

 mem_cnt = 0 /* keep track of how many members we have to process    */
 job_cnt = 0 /* keep track of how many jobs have to be stored        */
 stgdsnq = walkjcl_stagedsnq.1

 /* Get a list of members in the staging dataset                     */
 t = outtrap('tsoout.')
 "listds '"stgdsnq"' members"
 if rc ^= 0 then call exception rc 'Error on listds of' stgdsnq

 /* Read the each member form the staging dataset & build JCL steps  */
 do t = 7 to tsoout.0
   member = strip(tsoout.t)
   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   /* if there are more than 31 members then we need another jobcard */
   if mem_cnt = 31 then do /* have we processed 31 members already   */

     /* if the maximum return code of all the previous steps is not  */
     /* then add an fail the job.                                    */
     queue "//CHECK    IF RC NE 0 THEN                                "
     call add_implfail_spwarn_jcl
     queue "//CHECK    ENDIF                                          "

     /* Add an IMPL flag step in case the job is being re-run        */
     call add_impl_jcl
     queue "//                                                        "

     /* Add the CA7 demand JCL to the job                            */
     call ca7_demand 'EVGWALKI' cm_mem 'P02'

     mem_cnt = 0 /* Reset member counter                             */

   end /* mem_cnt = 31 */

   if mem_cnt = 0 then do /* create a job card                       */

     job_cnt = job_cnt + 1 /* Increment the jobcounter array         */

     cm_mem  = 'W'right(job_cnt,2,'0')||right(changeid,5)

     newstack /* New stack for adding JCL to CA7 demand steps        */

     queue "//EVGWALKI JOB 1,'CMR "changeid"',CLASS=N,MSGCLASS=Y,     "
     queue "//             USER=GRP                                   "
     queue "//*                                                       "
     queue "//********************************************************"
     queue "//** THIS JCL IS STORED IN PGEV.AUTO.CMJOBS("cm_mem")     "
     queue "//********************************************************"
     queue "//*                                                       "

   end /* mem_cnt = 0 */

   mem_cnt = mem_cnt + 1 /* found a member to process                */

   /* Get the contents of each member                                */
   "alloc f(MEMBER) dsname('"stgdsnq"("member")') shr"
   if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('member') failed.'
   'execio * diskr MEMBER (stem line. finis'
   if rc ^= 0 then call exception rc 'EXECIO of' stgdsnq'('member') failed.'
   "free f(MEMBER)"

   /* queue the JCL from the promted members                         */
   do a = 1 to line.0
     queue line.a
   end /* a = 1 to line.0 */

 end /* t = 7 to tsoout.0 */

 /* Add the CA7 demand JCL to the job                                */
 call ca7_demand 'EVGWALKI' cm_mem 'P02'

return /* walkjcl_jcl: */

/*-------------------------------------------------------------------*/
/* Add AO update JCL                                                 */
/*-------------------------------------------------------------------*/
rules_jcl:

 if system_name ^= 'AO'    | ,
    qual5        = 'DUMMY' then return

 queue "//************************************************************"
 queue "//** UPDATE OPSMVS FOR AO RULES UPDATES                       "
 queue "//************************************************************"
 queue "//AOUPDATE EXEC PGM=IKJEFT1B                                  "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//SYSTSIN  DD *                                               "
 queue " SEND 'EV000003 PGOS.BASE.CMJOBS("cmjobname")'"
 queue "/*                                                            "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SPWARN IF AO UPDATE FAILS                                "
 queue "//************************************************************"
 queue "//CHECKIT  IF AOUPDATE.RC NE 0 THEN                           "
 queue "//SPWARN   EXEC @SPWARN                                       "
 queue "//CHECKIT  ENDIF                                              "
 queue "//*                                                           "

return /* rules_jcl: */

/*-------------------------------------------------------------------*/
/* Add UUJMA GLV refresh message                                     */
/*-------------------------------------------------------------------*/
aoxps_jcl:

 say rexxname':'

 stgdsnq = aoxps_stagedsnq.1

 memcount = 0 /* counter for members founds in dsn for destination   */

 /* Get a list of members in the staging dataset                     */
 t = outtrap('tsoout.')
 "listds '"stgdsnq"' members"
 if rc ^= 0 then call exception rc 'Error on listds of' stgdsnq

 /* Read the each member form the staging dataset & build JCL steps  */
 do t = 7 to tsoout.0
   member = strip(tsoout.t)
   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   /* if the member isn't related to the plex then return            */
   if member ^= right(dest,2) then do
     say rexxname': Member' member 'is not related to Plex' ||,
       right(dest,2)'. Processing is bypassed for AOXPS.'

     iterate /* no processing required                               */
   end /* member ^= 'plexid' */

   memcount = 1 /* we need to add some jcl for this destination      */
   say rexxname': Member' member 'found for AOXPS processing'

 end /* t = 7 to tsoout.0 */

 if memcount = 0 then return /* nothing valid found, no JCL to add   */

 queue "//************************************************************"
 queue "//** ISSUE MESSAGE TO REFRESH THE UUJMA GLVS FOR" destid
 queue "//************************************************************"
 queue "//UUJMAGLV EXEC PGM=IKJEFT1B                                  "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//SYSTSIN  DD *                                               "
 queue " SEND 'OSGLVUPD UUJMA FILE READY FOR AO'"
 queue "/*                                                            "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SPWARN IF AO UPDATE FAILS                                "
 queue "//************************************************************"
 queue "//CHECKIT  IF UUJMAGLV.RC NE 0 THEN                           "
 call add_implfail_spwarn_jcl
 queue "//CHECKIT  ENDIF                                              "
 queue "//*                                                           "

return /* aoxps_jcl: */

/*-------------------------------------------------------------------*/
/* add pro4 cjob jcl                                                 */
/*-------------------------------------------------------------------*/
addpro4jcl:
 queue "//*******************************************************************"
 queue "//* Start of insert of PRO-IV JCL by Rexx NDVEDIT               *****"
 queue "//*******************************************************************"
 queue "//*******************************************************************"
 queue "//* DEMAND ALL THREE PRO-IV LOAD JOBS FOR SYSTEM" pro4job
 queue "//*******************************************************************"
 queue "//STEP018  EXEC @SASBSTR,                                            "
 queue "//             HLQ=PROS,                                             "
 queue "//             LOCN=FROW,                                            "
 queue "//             TERMNO=0                                              "
 queue "//SYSIN    DD *                                                      "
 queue "DEMAND,JOB="pro4job"HHFMMI,SET=NTR                                   "
 queue "DEMAND,JOB="pro4job"HHFPLI,SET=NTR                                   "
 queue "DEMAND,JOB="pro4job"HHFNLI,SET=NTR                                   "
 queue "/*                                                                   "
 queue "//*                                                                  "
 queue "//*******************************************************************"
 queue "//**    SPWARN IF CA7 BATCH TERMINAL FAILED                        **"
 queue "//*******************************************************************"
 queue "//STEP018B  EXEC PGM=SPWARN,COND=(4,GE,STEP018.@SASBSTR)             "
 queue "//STEPLIB   DD  DSN=PGSP.BASE.LOAD,DISP=SHR                          "
 queue "//SYSPRINT  DD  SYSOUT=*,FCB=S001                                    "
 queue "//*******************************************************************"
 queue "//* End of insert of PRO-IV JCL by Rexx NDVEDIT                    **"
 queue "//*******************************************************************"
return /* addpro4jcl: */

/*-------------------------------------------------------------------*/
/* add pro4 backout jcl                                              */
/*-------------------------------------------------------------------*/
addpro4jclb:
 queue "//****************************************************      "
 queue "//** BACKOUT PRO4 FUNCTIONS TO PG                   **      "
 queue "//****************************************************      "
 queue "//PRO4RBS  EXEC PGM=PROUTVV                                 "
 queue "//STEPLIB  DD DSN=PGMT.BASE.LOAD,DISP=SHR                   "
 queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR        "
 queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR     "
 queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR     "
 queue "//PROXECO  DD DSN="rbspro4".EXEC,DISP=SHR"
 queue "//PRODEVO  DD DSN="rbspro4".DEVELOP,DISP=SHR"
 queue "//GENFILO  DD DSN="rbspro4".GENFILE,DISP=SHR"
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSIN    DD DISP=SHR,                                     "
 queue "//         DSN=PGEV."changeid".BACKUP.PARMS                   "
 queue "//****************************************************      "
 queue "//** BACKOUT PRO4 FUNCTIONS TO PN                   **      "
 queue "//****************************************************      "
 queue "//PRO4NWB  EXEC PGM=PROUTVV                                 "
 queue "//STEPLIB  DD DSN=PGMT.BASE.LOAD,DISP=SHR                   "
 queue "//PROXECI  DD DSN=PGEV."changeid".BACKUP.EXEC,DISP=SHR        "
 queue "//PRODEVI  DD DSN=PGEV."changeid".BACKUP.DEVELOP,DISP=SHR     "
 queue "//GENFILI  DD DSN=PGEV."changeid".BACKUP.GENFILE,DISP=SHR     "
 queue "//PROXECO  DD DSN="nwbpro4".EXEC,DISP=SHR"
 queue "//PRODEVO  DD DSN="nwbpro4".DEVELOP,DISP=SHR"
 queue "//GENFILO  DD DSN="nwbpro4".GENFILE,DISP=SHR"
 queue "//PRINTR   DD SYSOUT=*                                      "
 queue "//SYSIN    DD DISP=SHR,                                     "
 queue "//         DSN=PGEV."changeid".BACKUP.PARMS                   "
 queue "//****************************************************     "
return /* addpro4jclb: */

/*-------------------------------------------------------------------*/
/* shipoh_jcl - Add Off host Binds steps                             */
/*-------------------------------------------------------------------*/
shipoh_jcl:
 say rexxname': '
 say rexxname': Steps BINDOH1 through BINDOH4 added for Off Host Binds'

 call ndmdata_skel

 if jobtype = 'CJOB' then do
   namejob2 = overlay('D',changeid)
   rType    = 'I'
 end /* jobtype = 'CJOB' */
 else do
   namejob2 = overlay('E',changeid)
   rType    = 'B'
 end /* else */

 queue "//*******************************************************************"
 queue "//***** START OF INSERTS FOR OFF HOST BINDS BY REXX NDVEDIT *********"
 queue "//*******************************************************************"
 queue "//**      CREATE SEQUENTIAL FILES CONTAINING ALL OFF HOST BIND     **"
 queue "//**      STATEMENTS FOR TRANSFER TO BIND SERVERS..                **"
 queue "//*******************************************************************"
 queue "//BINDOH1  EXEC PGM=FILEAID                                          "
 queue "//SYSPRINT DD SYSOUT=*                                               "
 do n = 1 to shipoh_count
   nn          = right(n,2,0)
   staging_lib = shipoh_stagedsn.n
   merge_lib   = substr(staging_lib,1,lastpos('.',staging_lib)) || ,
                 system_name || substr(shipoh_dsn.n,15,4)
   queue "//DD"nn"     DD DISP=SHR,DSN="staging_lib
   queue "//DD"nn"O    DD DSN="merge_lib","
   queue "//            LIKE="staging_lib","
   queue "//            DCB="staging_lib","
   queue "//            DISP=(NEW,CATLG),DSORG=PS"
 end /* n = 1 to shipoh_count */
 queue "//SYSIN    DD *"
 do n = 1 to shipoh_count
   nn = right(n,2,0)
   queue "$$DD"nn" COPY ERRS=0"
 end /* n = 1 to shipoh_count */
 queue "/*                                                                   "
 queue "//*******************************************************************"
 queue "//**      SPWARN IF MERGE OF BINDOH PDS' FAIL.                     **"
 queue "//*******************************************************************"
 queue "//BINDOH1A EXEC PGM=SPWARN,COND=(0,EQ,BINDOH1)                       "
 queue "//STEPLIB  DD DSN=PGSP.BASE.LOAD,DISP=SHR                            "
 queue "//SYSPRINT DD SYSOUT=*,FCB=S001                                      "
 queue "//*                                                                  "
 queue "//*******************************************************************"
 queue "//**      TRANSFER BIND STATEMENTS TO BIND SERVERS.                **"
 queue "//*******************************************************************"
 queue "//BINDOH2  EXEC PGM=DMBATCH,PARM=(YYSLYNN)                           "
 queue "//DMNETMAP DD DISP=SHR,DSN=PGTN.CD.CD02.P1.NETMAP                    "
 queue "//DMMSGFIL DD DISP=SHR,DSN=PGTN.CD.MSG                               "
 queue "//DMPUBLIB DD DISP=SHR,DSN=PGOS.BASE.NDMPROC                         "
 queue "//DMPRINT  DD SYSOUT=*                                               "
 queue "//SYSIN    DD *                                                      "
 do n = 1 to shipoh_count
   serv_num = right(shipoh_dsn.n,2)
   if boh_SNODE.serv_num = 'BOH_SNODE.'serv_num then do
     say rexxname': Error with destination variables, no variables',
         "defined for '"merge_lib"'."
     say rexxname': The DESTVAR member requires updating.'
     exit(12)
   end
   do t = 1 to evbohsk.0
     interpret queue evbohsk.t
   end /* t = 1 to evbohsk.0 */
 end /* n = 1 to shipoh_count */
 queue "//*                                                                  "
 queue "//CHECKOH2 IF (BINDOH2.RC NE 0) THEN                                 "
 queue "//*******************************************************************"
 queue "//**      SPWARN IF MERGE OF BINDOH PDS' FAIL.                     **"
 queue "//*******************************************************************"
 queue "//BINDOH2A EXEC @SPWARN                                              "
 queue "//*                                                                  "
 queue "//CHECKOH2 ENDIF                                                     "
 queue "//*******************************************************************"
 queue "//*  ADD "namejob2" TO BASE.CMJOBS                                  **"
 queue "//*******************************************************************"
 queue "//BINDOH3  EXEC PGM=IEBGENER                                         "
 queue "//SYSPRINT DD SYSOUT=*                                               "
 queue "//SYSUT2   DD DISP=SHR,DSN=PGOS.BASE.CMJOBS("namejob2")              "
 queue "//SYSUT1   DD DATA,DLM=$$                                            "
 queue "//"namejob2" JOB 1,'NDVR "changeid"',CLASS=A,MSGCLASS=Y,USER=GRP     "
 queue "//*******************************************************************"
 queue "//*  ANALYSE BIND OUTPUT FOR CMR "changeid"                         **"
 queue "//*******************************************************************"
 queue "//EVBNDCHK EXEC PGM=IKJEFT1B,REGION=6M,                              "
 queue "//     PARM='EVBNDCHK SQL0092N PGDF.BINDOH."system_name"."changeid"'"
 queue "//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.REXX                            "
 queue "//SYSTSPRT DD SYSOUT=*                                               "
 queue "//SYSTSIN  DD DUMMY                                                  "
 queue "//*                                                                  "
 queue "$$                                                                   "
 queue "//SYSIN    DD DUMMY                                                  "
 queue "//*                                                                  "
 queue "//CHECKOH3 IF (BINDOH3.RC NE 0) THEN                                 "
 queue "//*******************************************************************"
 queue "//**         SPWARN IF WRITE TO CMJOBS FAILS FOR ANY REASON        **"
 queue "//*******************************************************************"
 queue "//BINDOH3A EXEC @SPWARN                                              "
 queue "//CHECKOH3 ENDIF                                                     "
 queue "//*                                                                  "
 queue "//*******************************************************************"
 queue "//*       ADD" namejob2 "TO P02 (CA7)                              **"
 queue "//*******************************************************************"
 queue "//BINDOH4  EXEC @SASBSTR,HLQ=PGOS,LOCN=P02                           "
 queue "//SYSIN    DD *                                                      "
 queue "DBM                                                                  "
 queue "JOB                                                                  "
 queue "ADD,"namejob2",SYSTEM=ENDEVOR,JCLID=005,CLASS=A                      "
 queue "//*                                                                  "

return /* shipoh_jcl: */

/*-------------------------------------------------------------------*/
/* ndmdata_skel - Read NDMDATA skeleton for shipoh                   */
/*-------------------------------------------------------------------*/
ndmdata_skel:
 "execio * diskr EVBOH001 (stem EVBOHSK. finis"
 if rc > 0 then exit(5)

 do s = 1 to evbohsk.0
  if pos('<SNODE>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<SNODE>' part2
    evbohsk.s = part1'"'||'boh_SNODE.serv_num'||'"'part2
  end
  if pos('<NEWNAME>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<NEWNAME>' part2
    evbohsk.s = part1'"'||'cmjobname'||'"'part2
  end
  if pos('<SERVER>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<SERVER>' part2
    evbohsk.s = part1'"'||'boh_SERVER.serv_num'||'"'part2
  end
  if pos('<BINDFILE>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<BINDFILE>' part2
    evbohsk.s = part1'"'||'merge_lib'||'"'part2
  end
  if pos('<L>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<L>' part2
    evbohsk.s = part1'"'||'boh_DRIVE.serv_num'||'"'part2
  end
  if pos('<D>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<D>' part2
    evbohsk.s = part1'"'||'boh_DBSID.serv_num'||'"'part2
  end
  if pos('<SY>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<SY>' part2
    evbohsk.s = part1'"'||'system_name'||'"'part2
  end
  if pos('<CMR>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<CMR>' part2
    evbohsk.s = part1'"'||'changeid'||'"'part2
  end
  if pos('<I>',evbohsk.s) > 0 then do
    parse var evbohsk.s part1 '<I>' part2
    evbohsk.s = part1'"'||'rType'||'"'part2
  end
  evbohsk.s = '"'Strip(evbohsk.s,'T')'"'
 end /* s = 1 to evbohsk.0 */

return /* ndmdata_skel: */

/*-------------------------------------------------------------------*/
/* Add USS steps                                                     */
/*-------------------------------------------------------------------*/
uss_jcl:

 newstack /* New stack for adding JCL to CA7 demand steps            */

 queue "//EVGUSSDI JOB CLASS=A,MSGCLASS=Y,USER=USSDEPP,               "
 queue "//             REGION=400M                                    "
 queue "//JCLLIB   JCLLIB ORDER=(PGOS.BASE.PROCLIB)                   "
 queue "//*                                                           "
 queue "//*   CHANGE" changeid "USS UPDATES                           "
 queue "//*                                                           "
 queue "//*   JCL BUILT BY JOB" changeid
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** MERGE USS TRIGGER PDS LIBRARIES                          "
 queue "//************************************************************"
 queue "//EVUSS01  EXEC PGM=FILEAID                                   "
 queue "//SYSPRINT DD SYSOUT=*                                        "
 queue "//SYSLIST  DD SYSOUT=*                                        "

 do b = 1 to uss_count /* USS datasets                               */
   if b = 1 then
     queue "//DD01     DD DISP=SHR,DSN="uss_stagedsn.b
   else
     queue "//         DD DISP=SHR,DSN="uss_stagedsn.b
 end /* b = 1 to uss_count */

 queue "//DD01O    DD DSN=&&ELMLIST,DATACLAS=DSIZE10,                 "
 queue "//             DISP=(NEW,PASS),LRECL=500,RECFM=FB             "
 queue "//SYSIN    DD *                                               "
 queue "$$DD01 COPY ERRS=0                                            "
 queue "/*                                                            "
 queue "//************************************************************"
 queue "//** SPWARN IF MERGE OF USS TRIGGER PDS' FAILS                "
 queue "//************************************************************"
 queue "//CHECK01  IF EVUSS01.RC NE 0 THEN                            "
 queue "//EVUSS01A EXEC @SPWARN                                       "
 queue "//CHECK01  ENDIF                                              "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SORT THE TRIGGER STATEMENTS                              "
 queue "//************************************************************"
 queue "//SORT     EXEC PGM=SORT                                      "
 queue "//SORTIN   DD DSN=&&ELMLIST,DISP=(OLD,DELETE)                 "
 queue "//SORTOUT  DD DSN=&&ELMLISTS,DATACLAS=DSIZE10,                "
 queue "//             DISP=(NEW,PASS),LRECL=500,RECFM=FB             "
 queue "//SYSOUT   DD SYSOUT=*                                        "
 queue "//SYSIN    DD *                                               "
 queue "  SORT FIELDS=(1,1,CH,D)                                      "
 queue "/*                                                            "
 queue "//************************************************************"
 queue "//** SPWARN IF SORT FAILS                                     "
 queue "//************************************************************"
 queue "//CHECK0S  IF SORT.RC NE 0 THEN                               "
 queue "//SORTA    EXEC @SPWARN                                       "
 queue "//CHECK0S  ENDIF                                              "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** COPY USS FILES FROM STAGING TO PRODUCTION                "
 queue "//************************************************************"
 queue "//EVUSS04  EXEC PGM=IKJEFT1B,PARM='%EVUSS04" jobtype changeid"'"
 queue "//SYSPROC  DD DSN=PGEV.BASE.REXX,DISP=SHR                     "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//STDOUT   DD SYSOUT=*                                        "
 queue "//ELMLIST  DD DSN=&&ELMLISTS,DISP=(OLD,DELETE)                "
 queue "//SYSTSIN  DD DUMMY                                           "
 queue "/*                                                            "
 queue "//************************************************************"
 queue "//** SPWARN IF COPY OF USS FILES FAILS                        "
 queue "//************************************************************"
 queue "//CHECK04  IF EVUSS04.RC NE 0 THEN                            "
 queue "//EVUSS04A EXEC @SPWARN                                       "
 queue "//CHECK04  ENDIF                                              "
 queue "//*                                                           "

 /*------------------------------------------------------------------*/
 /*   If required insert JCL for the universal trigger process       */
 /*------------------------------------------------------------------*/
 /* First save some variables as the subroutine is already running   */
 trigger_save         = trigger
 count_save           = gg
 curr_pos_in_jcl_save = curr_pos_in_jcl

 call trigger_call 'evgussdi'

 /* Restore the saved variables                                      */
 trigger         = trigger_save
 gg              = count_save
 curr_pos_in_jcl = curr_pos_in_jcl_save

 /* For Qplex backout add JCL to update the static directories       */
 /* and create some JCL for USS abort processing.                    */
 if jobtype = 'BJOB' & dest = 'PLEXE1' then do
   call stticprm_jcl
   call uss_abort_jcl
 end /* jobtype = 'BJOB' & dest = 'PLEXE1' */

 /* Add the CA7 demand JCL to the job                                */
 call ca7_demand 'EVGUSSDI' 'US'right(changeid,6) 'DEFAULT'

return /* uss_jcl: */

/*-------------------------------------------------------------------*/
/* Add RACF steps                                                    */
/*-------------------------------------------------------------------*/
addracfjcl:
 arg jobtype

 racfstgq = overlay("H",racfstage,35,1)

 x = OUTTRAP("members.",'*',"CONCAT")
 "listds '"racfstgq"' mem"
 x = OUTTRAP("off")

 jcl_written = 'NO'
 do k = 7 to members.0
   member = strip(members.k)

   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   char1  = left(member,1)

   if (jobtype = 'CJOB' & char1 = 'C') | ,
      (jobtype = 'BJOB' & char1 = 'B') then do
     queue "//*********************************************************"
     queue "//**       EXECUTE RACF COMMANDS                         **"
     queue "//*********************************************************"
     queue "//"member"  EXEC PGM=IKJEFT1B                              "
     queue "//SYSEXEC   DD DISP=SHR,DSN=PGEV.BASE.REXX                "
     queue "//SYSTSPRT  DD SYSOUT=*                                    "
     queue "//SYSIN     DD DUMMY                                       "
     queue "//SYSOUT    DD SYSOUT=*                                    "
     queue "//SYSUDUMP  DD SYSOUT=C                                    "
     queue "//SYSTSIN   DD *                                           "
     queue " %RACFCMD 2                                                "
     queue "/*                                                         "
     queue "//SUCCESS   DD SYSOUT=*                                    "
     queue "//FAILURE   DD SYSOUT=*                                    "
     queue "//SECURES   DD DSN=PGSQ."changeid".SECURES("member"),"
     queue "//             DISP=(MOD,CATLG,KEEP),                      "
     queue "//             SPACE=(TRK,(15,90,89)),LRECL=133"
     queue "//SECUREF   DD DSN=PGSQ."changeid".SECUREF("member"),"
     queue "//             DISP=(MOD,CATLG,KEEP),                      "
     queue "//             SPACE=(TRK,(15,90,89)),LRECL=133"
     queue "//INPUT     DD DISP=SHR,DSN="racfdsn"("member")"
     queue "//*"
     jcl_written = 'YES'
   end /* (jobtype = 'CJOB' & char1 = 'C') | ..... */
 end /* do k = 7 to members.0 */

 if jcl_written = 'YES' then do
   queue "//CHECK01   IF (ABEND OR RC GT 4) THEN                       "
   queue "//***********************************************************"
   queue "//** SPWARN IF RACF COMMANDS FAIL                          **"
   queue "//***********************************************************"
   queue "//SPWARN    EXEC @SPWARN                                     "
   queue "//CHECK01   ENDIF                                            "
   queue "//*                                                          "
 end /* jcl_written = 'YES' */

return /* addracfjcl: */

/*-------------------------------------------------------------------*/
/* Create and Submit BINDBACK job(s)                                 */
/*-------------------------------------------------------------------*/
db2back:

 test = msg('off') /* Turn off messages                              */

 "FREE f(SAVEJCL)" /* Free the JCL file if it is alloacted           */

 /* Delete the BINDBACK JCL in case this is a re-run                 */
 "DELETE '"shiphlq"."changeid".BINDBACK'"

 test = msg('on') /* Turn messages back on                           */

 /* Allocate a dataset to save the BINDBACK JCL for reference        */
 "ALLOC F(SAVEJCL) DA('"shiphlq"."changeid".BINDBACK') NEW" ,
   "CATALOG SPACE(2  2) TRACKS RECFM(F B) LRECL(80) BLKSIZE(0)"
 if rc ^= 0 then call exception rc 'ALLOC of SAVEJCL failed'

 do b = 1 to shipdp_count
   say rexxname':'
   say rexxname': BINDBACK processing invoked'
   say rexxname':'
   call db2_process_back 'BINDBACK' shipdp_stagedsnq.b shipdp_dsn.b
 end /* b = 1 to shipdp_count */

 do b = 1 to spcrdp_count
   Say rexxname':'
   say rexxname': SPBACK processing invoked'
   Say rexxname':'
   call db2_process_back 'CREATEBACK' spcrdp_stagedsnq.b spcrdp_dsn.b
 end /* b = 1 to spcrdp_count */

 'execio 0 DISKW SAVEJCL (finis'
 if rc ^= 0 then call exception rc 'DISKW to SAVEJCL failed'
 "FREE f(SAVEJCL)" /* Free the JCL file                              */

return /* db2back: */

/*-------------------------------------------------------------------*/
/* DB2 bind back process to submit bind job on the Qplex             */
/*-------------------------------------------------------------------*/
db2_process_back:
 arg backtype stage_dsn tgt_dsn

 tgt  = substr(tgt_dsn,15,4)
 grp  = substr(tgt,3,1)
 rjob = overlay('R',changeid)
 c1en = 'ACPT'

 if backtype = 'BINDBACK' then do
   dbrmlib_dsn  = "PREV.P"system_name"1.DBRMLIB"
   dbrmlib_card = "//DBRMLIB  DD DISP=SHR,DSN="dbrmlib_dsn
   stepname     = 'BIND'
 end /* backtype = 'BINDBACK' */
 else do /* backtype = 'SPBACK' */
   dbrmlib_card = '//*'
   stepname     = 'SPDEF'
 end /* else */

 sysplex = mvsvar('SYSPLEX')
 if sysplex = 'PLEXS1' then do
   schenv  = ''
   newtgt  = overlay('S',tgt,2)
   jobparm = '/*JOBPARM SYSAFF=SAOS'
 end /* plexid = 'PLEXS1' */
 else do
   newtgt  = overlay('Q',tgt,2)
   schenv  = ',SCHENV='newtgt'BIND'
   jobparm = '//*'
 end /* else */

 /* Create BACK job                                                  */
 jcl.1  = "//EVGBCK"grp"I JOB 1,'NDVR "changeid"',CLASS=N,USER=PMFBCH,"
 jcl.2  = "//            MSGCLASS=Y"schenv
 jcl.3  = jobparm
 jcl.4  = "//*  CHANGE" changeid "QPLEX DB2" backtype "PROCESSING"
 jcl.5  = "//*                                                        "
 jcl.6  = "//*  JCL BUILT BY" rjob "& NDVEDIT AND STORED IN DATASET   "
 jcl.7  = "//*  "shiphlq"."changeid".BINDBACK                         "
 jcl.8  = "//*                                                        "
 /* Use IKJEFT01 so that failures do not stop the next action        */
 jcl.9  = "//"stepname "    EXEC PGM=IKJEFT01,DYNAMNBR=99             "
 jcl.10 = "//STEPLIB  DD DISP=SHR,DSN=SYSDB2."newtgt".SDSNEXIT.DECP   "
 jcl.11 = "//         DD DISP=SHR,DSN=SYSDB2."newtgt".SDSNLOAD        "
 if system_name = 'EK' then
   jcl.12 = "//SYSEXEC  DD DISP=SHR,DSN=PREV.FEV1.REXX                "
 else
   jcl.12 = "//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.REXX                "
 jcl.13 = "//         DD DISP=SHR,DSN=PGEV.BASE.REXX                  "
 if system_name = 'EK' then
   jcl.14 = "//         DD DISP=SHR,DSN=PREV.FEV1.ISPCLIB             "
 else
   jcl.14 = "//         DD DISP=SHR,DSN=PGEV.BASE.ISPCLIB             "
 jcl.15 = "//         DD DISP=SHR,DSN=PGEV.BASE.ISPCLIB               "
 jcl.16 = dbrmlib_card
 jcl.17 = "//SUMMARY  DD SYSOUT=*                                     "
 jcl.18 = "//SQLOUT   DD SYSOUT=*                                     "
 jcl.19 = "//SYSTSPRT DD SYSOUT=*                                     "
 jcl.20 = "//SYSTSIN  DD *                                            "
 jclcnt = 20

 /* Build cards for each member found                                */
 x = outtrap("members.",'*',"CONCAT")
 "listds '"stage_dsn"' mem"
 x = outtrap("off")

 do k = 7 to members.0
   member    = strip(members.k)
   char1     = substr(member,1,1)
   hex_char1 = c2x(substr(member,1,1))
   if hex_char1 = 'FE' then iterate /* Backout member                */
   if member = '$$$SPACE' | member = '$$$LIB' then iterate
   member     = left(member,8,' ')
   jclcnt     = jclcnt + 1
   jcl.jclcnt = '%DB2QPROC' member system_name'1' c1en backtype 'ALL'
 end /* k = 7 to members.0 */

 jclcnt     = jclcnt + 1
 jcl.jclcnt = '/*'

 /* Write to internal reader to submit the bindback JCL              */
 'execio * diskw SUBMIT2 (stem jcl. finis'
 if rc ^= 0 then call exception rc 'DISKW to SUBMIT2 failed'

 'execio' jclcnt 'DISKW SAVEJCL (stem jcl.'
 if rc ^= 0 then call exception rc 'DISKW to SAVEJCL failed'

return /* db2_process_back: */

/*-------------------------------------------------------------------*/
/* Add JCL for Websphere deployments                                 */
/*-------------------------------------------------------------------*/
deploy_jcl:

 /* Reads the WSPROPS file to get the cell name which is the SCHENV  */
 /* Will submit one job per DEPLOY - because the SCHENV could be     */
 /* different for each EAR file.                                     */

 stgdsnq = deploy_stagedsnq.1

 t = outtrap('TSOOUT.') /* Get a member list from the staging DS     */
 "listds '"stgdsnq"' members"
 if rc ^= 0 then do
   say rexxname':'
   do t = 1 to tsoout.0
     say rexxname': 'tsoout.t
   end /* t = 1 to tsoout.0 */
   call exception rc 'Error on listds of' stgdsnq
 end /* if rc ^= 0 then do */

 do t = 7 to tsoout.0 /* Loop through the DEPLOY trigger members     */
   dply_mem = STRIP(tsoout.t)

   if dply_mem = '$$$SPACE' then iterate /* pdsman spacemap          */

   say rexxname':'
   say rexxname': Reading DEPLOY member' dply_mem

   /* Read the deploy trigger file to get the ear file name          */
   "ALLOC F(DEPLOY) DSNAME('"stgdsnq"("dply_mem")') SHR"
   if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('dply_mem') fail'
   'EXECIO * DISKR DEPLOY (STEM DPLY. FINIS'
   if rc ^= 0 then call exception rc 'DISKR of' stgdsnq'('dply_mem') fail'
   "FREE F(DEPLOY)"

   ear_name = strip(dply.1)

   say rexxname': Building deployment JCL for file' ear_name

   /* Read the WSPROPS file to work out the SCHENV                   */
   parse value ear_name with file '.' extn
   wsprops_file  = '/RBSG/endevor/PROD/P'system_name || ,
                   '1/WSPROPS/'file'.properties'
   say rexxname': WSPROPS file name..:' wsprops_file

   command = 'ls' wsprops_file /* Does the WSPROPS file exist?       */
   call bpxwunix command,,Out.,Err.
   if err.0 ^= 0 then call exception 12 wsprops_file 'not found.'

   call read_USS_file wsprops_file 'wsprops.'

   deploy_schenv = ''
   do zz = 1 to wsprops.0
     parse value wsprops.zz with var_name '=' val
     if var_name = 'PRODcellName' then do
       deploy_schenv = strip(val)
       deploy_schenv = strip(deploy_schenv,,'"')
       leave zz
     end /* var_name = 'PRODcellName' */
   end /* do zz = 1 to wsprops.0 */
   if deploy_schenv = '' then do     /* test version 3 format        */
     do zz = 1 to wsprops.0
       if pos('streamProps',wsprops.zz) > 0 then do
         found = 'N'
         if pos('PROD1',wsprops.zz) > 0 then
           found = 'Y'
         iterate
       end /* left(wsprops.zz,11) = 'streamProps' */
       if found = 'Y' then do
         parse value wsprops.zz with var_name ':' val
         if var_name = '"cellName"' then do
           val = space(val,0)
           val = strip(val,'t',',')
           val = strip(val,'b','"')
           deploy_schenv = val
           leave zz
         end /* var_name = c1en'cellName' */
       end /* found = 'Y' */
     end /* do zz = 1 to wsprops.0 */
   end /* if deploy_schenv = '' */

   if deploy_schenv = '' then do /* Cell name (SCHENV) not found     */
     deploy_process = 'OLD'
     schenv         = 'PKOS'

     if system_name = 'LN' /* Insurance runs on NCOS                 */
       then schenv = 'NCOS'

     say rexxname': String "PRODcellName=" not found in WSPROPS file.'
     say rexxname': Will use the old deploy process.'
   end /* deploy_schenv = '' */
   else do
     schenv = deploy_schenv
     say rexxname': Cell_name "PRODcellName='deploy_schenv'"'
     say rexxname': Setting SCHENV to' deploy_schenv
     say rexxname': Temp setting SCHENV to PKOS' /* until the SEs are */
     schenv = 'PKOS'                            /* set up            */

     if system_name = 'LN' /* Insurance runs on NCOS                 */
       then schenv = 'NCOS'

   end /* else */

   newstack /* New stack for adding JCL to CA7 demand steps          */

   queue "//EVGDPLYI JOB 1,CLASS=N,MSGCLASS=Y,USER=USSDEPP,         "
   queue "//         SCHENV="schenv",REGION=1024M                   "
   queue "//*                                                       "
   queue "//* JCL BUILT BY PACKAGE CMR -" changeid
   queue "//*                                                       "
   if deploy_process = 'OLD' then do
     queue "//********************************************************"
     queue "//** DO A WEBSPHERE DEPLOYMENT USING THE RESOLVED EAR FILE"
     queue "//** RBSDeploy uses the parms                             "
     queue "//** env                                                  "
     queue "//** stage id                                             "
     queue "//** subsystem                                            "
     queue "//** extension                                            "
     queue "//** longfile name of the ear                             "
     queue "//** optional switch of -w to do a deployment only        "
     queue "//********************************************************"
     queue "//DEPLOY   EXEC PGM=BPXBATCH,                             "
     queue "//         PARM='sh /RBSG/endevor/PGWT/BASE/USSREXX" || ,
           "/RBSDeploy PROD"
     queue "//             P "system_name"1 EAR "ear_name" -w'"
     queue "//SYSTSPRT DD SYSOUT=*                                    "
     queue "//SYSPRINT DD SYSOUT=*                                    "
     queue "//SYSUDUMP DD SYSOUT=C                                    "
     queue "//STDOUT   DD SYSOUT=*,RECFM=VB,LRECL=1200                "
     queue "//STDERR   DD SYSOUT=*,RECFM=VB,LRECL=1200                "
     queue "//STDENV   DD *                                           "
     queue "_BPX_BATCH_SPAWN=YES                                      "
     queue "_BPX_SHAREAS=NO                                           "
     queue "/*                                                        "
     queue "//CHECKIT  IF DEPLOY.RC NE 0 THEN                         "
     call add_implfail_spwarn_jcl
     queue "//CHECKIT  ENDIF                                          "
   end /* deploy_process = 'OLD' */
   else do
     stdout  = ear_name'.out'
     stderr  = ear_name'.err'
     logpath = '/u/pgwt/websphere/audit/logs/deployments/'
     queue "//********************************************************"
     queue "//** WEBSPHERE DEPLOYMENT OF" ear_name
     queue "//********************************************************"
     queue "//DEPLOY   EXEC PGM=BPXBATCH,                             "
     queue "//         PARM='sh /RBSG/endevor/PGWT/BASE/BIN/" || ,
           "RBSDeploy2.sh"
     queue "//             PROD P" system_name"1" ear_name"'"
     queue "//SYSTSPRT DD SYSOUT=*                                    "
     queue "//SYSUDUMP DD SYSOUT=C                                    "
     queue "//STDOUT   DD PATH='"logpath || left(stdout,10)"-"
     queue "//             "substr(stdout,11)"',"
     queue "//            PATHOPTS=(OWRONLY,OCREAT),                  "
     queue "//            PATHMODE=(SIRWXU,SIRWXG,SIRWXO)             "
     queue "//STDERR   DD PATH='"logpath || left(stderr,10)"-"
     queue "//             "substr(stderr,11)"',"
     queue "//            PATHOPTS=(OWRONLY,OCREAT),                  "
     queue "//            PATHMODE=(SIRWXU,SIRWXG,SIRWXO)             "
     queue "//STDENV   DD *                                           "
     queue "_BPX_BATCH_SPAWN=YES                                      "
     queue "_BPX_SHAREAS=NO                                           "
     queue "/*                                                        "
     queue "//********************************************************"
     queue "//** PRINT THE OUTPUT TO THE SPOOL                        "
     queue "//********************************************************"
     queue "//PRINT    EXEC PGM=IKJEFT1B,COND=EVEN                    "
     queue "//OUT      DD PATH='"logpath || left(stdout,10)"-"
     queue "//             "substr(stdout,11)"'"
     queue "//ERR      DD PATH='"logpath || left(stderr,10)"-"
     queue "//             "substr(stderr,11)"'"
     queue "//SYSTSPRT DD SYSOUT=*                                    "
     queue "//STDOUT   DD SYSOUT=*,LRECL=800,RECFM=FB                 "
     queue "//STDERR   DD SYSOUT=*,LRECL=800,RECFM=FB                 "
     queue "//SYSTSIN  DD *                                           "
     queue " OCOPY INDD(OUT) OUTDD(STDOUT)                            "
     queue " OCOPY INDD(ERR) OUTDD(STDERR)                            "
     queue "/*                                                        "
     queue "//********************************************************"
     queue "//** SEND STDOUT IN EMAIL TO ADDRESS IN WSPROPS           "
     queue "//********************************************************"
     queue "//EMAIL    EXEC PGM=IKJEFT1B,                             "
     queue "//             PARM='%DPLYMAIL PRD PROD" system_name"1 P' "
     queue "//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                 "
     queue "//SYSTSPRT DD SYSOUT=*                                    "
     queue "//SYSTSIN  DD DUMMY                                       "
     queue "//PKGLIST  DD DUMMY                                       "
     queue "//DATA     DD *                                           "
     queue ear_name
     queue logpath
     queue stdout
     queue "/*                                                        "
     queue "//CHECKIT  IF DEPLOY.RC NE 0 OR                           "
     queue "//            PRINT.RC  NE 0 OR                           "
     queue "//            EMAIL.RC  NE 0 THEN                         "
     call add_implfail_spwarn_jcl
     queue "//CHECKIT  ENDIF                                          "
   end /* else */

   /* Add the CA7 demand JCL to the job                              */
   call add_impl_jcl
   call ca7_demand 'EVGDPLYI' 'DP't||right(changeid,4) 'DEFAULT'

 end /* do t = 7 to tsoout.0 */

return /* deploy_jcl: */

/*-------------------------------------------------------------------*/
/* Add AIXSCRPT file transfer JCL                                    */
/*-------------------------------------------------------------------*/
aixscrpt_jcl:

 /* This JCL is only added on the QPlex but as the trigger file is   */
 /* the AIXSCRPT.USS file which goes to all plexes we need this check*/
 if dest ^= 'PLEXE1' then return

 newstack /* New stack for adding JCL to CA7 demand steps            */

 queue "//WTGAIXSI JOB 1,CLASS=N,MSGCLASS=Y,USER=USSDEPP              "
 queue "//*                                                           "
 queue "//* JCL BUILT BY PACKAGE CMR -" changeid
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SEND SCRIPTS TO THE AIX WEBSPHERE SERVERS VIA sFTP       "
 queue "//************************************************************"
 queue "//CPYSCRPT EXEC PGM=IKJEFT1B,REGION=256M                      "
 queue "//SYSTSIN  DD *                                               "
 queue " BPXBATCH SH +                                                "
 queue " /RBSG/endevor/PGWT/BASE/BIN/deployChanges.sh +               "
 queue "       -c"changeid
 queue "/*                                                            "
 queue "//STDOUT   DD SYSOUT=*                                        "
 queue "//STDERR   DD SYSOUT=*,LRECL=2048,RECFM=VB                    "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//*                                                           "
 queue "//CHECKIT  IF CPYSCRPT.RC NE 0 THEN                           "
 call add_implfail_spwarn_jcl
 queue "//CHECKIT  ENDIF                                              "

 if aixcntl_count = 0 then do /* No AIXCNTL trigger so add demand    */
   /* Add the CA7 demand JCL to the job                              */
   call add_impl_jcl
   call ca7_demand 'WTGAIXSI' 'WTAI'right(changeid,4) 'P04'
 end /* aixcntl_count = 0 */

return /* aixscrpt_jcl: */

/*-------------------------------------------------------------------*/
/* Add AIXCNTL file propagate JCL                                    */
/*-------------------------------------------------------------------*/
aixcntl_jcl:

 /* This JCL is only added on the QPlex but as the trigger file is   */
 /* the AIXCNTL.USS file which goes to all plexes we need this check */
 if dest ^= 'PLEXE1' then return

 if jobtype = 'CJOB' then
   action = 'IMPLEMENTATION'
 else
   action = 'BACKOUT'

 if aixscrpt_count = 0 then do /* No AIXSCRPT trigger so add jobcard */
   newstack /* New stack for adding JCL to CA7 demand steps          */

   queue "//WTGAIXSI JOB 1,CLASS=N,MSGCLASS=Y,USER=USSDEPP            "
   queue "//*                                                         "
   queue "//* JCL BUILT BY PACKAGE CMR -" changeid
   queue "//*                                                         "
 end /* aixscrpt_count = 0 */

 queue "//************************************************************"
 queue "//** PROCESS SCRIPTS ON THE AIX WEBSPHERE SERVERS             "
 queue "//************************************************************"
 queue "//PROCSCRP EXEC PGM=IKJEFT1B,REGION=256M                      "
 queue "//SYSTSIN  DD *                                               "
 queue " BPXBATCH SH +                                                "
 queue " /RBSG/endevor/PGWT/BASE/BIN/propagateChanges.sh +            "
 queue "       -c"changeid "+                                         "
 queue "       -a"action
 queue "/*                                                            "
 queue "//STDOUT   DD SYSOUT=*                                        "
 queue "//STDERR   DD SYSOUT=*,LRECL=2048,RECFM=VB                    "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//*                                                           "
 queue "//CHECKIT  IF PROCSCRP.RC NE 0 THEN                           "
 call add_implfail_spwarn_jcl
 queue "//CHECKIT  ENDIF                                              "

 /* Add the CA7 demand JCL to the job                                */
 call add_impl_jcl
 call ca7_demand 'WTGAIXSI' 'WTAI'right(changeid,4) 'P04'

return /* aixcntl_jcl: */

/*-------------------------------------------------------------------*/
/* Add DSDEL processing JCL                                          */
/*-------------------------------------------------------------------*/
dsdel_jcl:

 stgdsnq = dsdel_stagedsnq.1

 /* julian day for this year                                         */
 juldays = right(date(j),3)

 /* start building the JCL stream                                    */
 queue "//************************************************************"
 queue "//** RENAME THE DATASET FOR HSM TO DELETE                     "
 queue "//************************************************************"
 queue "//RENAME   EXEC PGM=IDCAMS                                    "
 queue "//SYSPRINT DD SYSOUT=*                                        "
 queue "//SYSIN    DD *                                               "
 queue "  SET MAXCC = 0                                               "

 /* Loop through the shipment dataset to delete each dataset         */
 t = outtrap('TSOOUT.')
 "listds '"stgdsnq"' members"
 if rc ^= 0 then do
   do t = 1 to tsoout.0
     say rexxname': 'tsoout.t
   end /* t = 1 to tsoout.0 */
   call exception rc 'Error on listds of' stgdsnq
 end /* rc ^= 0 */

 do t = 7 to tsoout.0 /* loop through the members from the 7th item  */
   member = STRIP(tsoout.t)

   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   /* Read the DSDEL trigger file to find what datasets to delete    */
   "ALLOC F(MEMBER) DSNAME('"stgdsnq"("member")') SHR"
   if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('member') failed.'
   'EXECIO * DISKR MEMBER (STEM MEMBER. FINIS'
   if rc ^= 0 then call exception rc 'DISKR of' stgdsnq'('member') failed.'
   "FREE F(MEMBER)"

   do a = 1 to member.0

     do b = 2 to words(member.a)

       if word(member.a,b) = right(dest,2) then do
         say rexxname':  Writing ALTER command for' word(member.a,1)

         if jobtype = 'CJOB' then do /* implementation?              */
           ds1 = word(member.a,1)
           ds2 = word(member.a,1)".SMGEV"juldays
         end /* jobtype = 'CJOB' */

         else do /* backout                                          */
           ds1 = word(member.a,1)".SMGEV"juldays
           ds2 = word(member.a,1)
         end /* else */

         queue "    ALTER -"
         queue "    "ds1 "-"
         queue "    NEWNAME("ds2")"
         queue "    IF LASTCC GT 0 THEN SET MAXCC = 16"

       end /* word(member.a,b) = right(dest,2) */

     end /* b = 2 to words(member.a) */

   end /* a = 1 to member.0 */

 end /* t = 7 to tsoout.0 */

 queue "/*                                                            "
 queue "//CHECKIT  IF RENAME.RC NE 0 THEN                             "
 call add_implfail_spwarn_jcl
 queue "//CHECKIT  ENDIF                                              "
 queue "//*                                                           "

return /* dsdel_jcl: */

/*-------------------------------------------------------------------*/
/*  Process DUMPRST* dataset content at backout                      */
/*-------------------------------------------------------------------*/
dumprst_jcl_b:
 call readint 'DESTINFO' /* set up all the plex specific variables   */

 call readint 'DESTSYS' /* set up all the plex destinations          */

 do z = 1 to dumprst_count /* loop through datasets                  */

   pid      = right(dumprst_dsn.z,1)'1'
   stgdsnq  = strip(dumprst_stagedsnq.z)
   netmap   = 'PGTN.CD.CD02.'pid'.NETMAP'

   /* if target dataset not for this dest then get next record       */
   if pid ^= right(dest,2) then iterate

   /* Get the the contents of the basemember                         */
   "alloc f(BOUT) dsname('"stgdsnq"("changeid")') shr"
   if rc ^= 0 then
     call exception rc 'ALLOC of' stgdsnq'('changeid') failed.'

   'execio * diskr BOUT (stem backout. finis'
   if rc ^= 0 then
     call exception rc 'DISKR of' stgdsnq'('changeid') failed.'
   "free f(BOUT)"

   do a = 1 to backout.0 /* source lines from the base dataset       */

     do b = 2 to words(backout.a)
       plex = word(backout.a,b) /* get the target plex               */
       actions.plex = 'Y' /* build up an array                       */
     end /* b = 2 to words(source.a) */

   end /* a = 1 to backout.0 */

   /* if there are actions to process the build the additional JCL   */
   do y = 1 to words(list_destsb)
     rdst = word(list_destsb,y) /* target destination                */

     if actions.rdst = 'Y' then do

       tbkp = 'PGEV.DUMP.'rdst'.'changeid'.BKP' /* cjob dump dataset */
       bout = 'B'right(changeid,7)
       node = cd.rdst /* target C:D node from destinfo               */
       /* amend qplex c:d node                                       */
       if node = 'LOCAL' then
         node = 'CD.OS390.Q102'

       queue '//************************************************************'
       queue '//** CREATE A TEMPORARY NDM PROCESS                           '
       queue '//************************************************************'
       queue '//TEMPNDM  EXEC PGM=IEBGENER'
       queue '//SYSPRINT DD SYSOUT=*                                        '
       queue '//SYSUT1   DD *                                               '
       queue 'EVGDOUTI PROCESS SNODE='node
       queue 'EVGDOUTI RUN TASK (PGM=DMRTSUB, -                             '
       queue '     PARM=("DSN=PGEV.BASE.JCL(EVGDOUTI),DISP=SHR", -          '
       queue '                     "TBKP 'tbkp'",  -'
       queue '                     "CMR  'changeid'", -'
       queue '                     "BMR  'bout'", -'
       queue '                     )) SNODE                                 '
       queue '/*                                                            '
       queue '//SYSUT2   DD DSN=&&PROCESS(EVGDOUTI),DISP=(NEW,PASS),        '
       queue '//             SPACE=(TRK,(2,1,44)),LRECL=80,                 '
       queue '//             RECFM=FB                                       '
       queue '//SYSIN    DD DUMMY                                           '
       queue '//*                                                           '
       queue '//CHECKIT  IF TEMPNDM.RC GT 0 THEN'

       call add_implfail_spwarn_jcl /* add failure step              */

       queue '//CHECKIT  ENDIF                                              '
       queue '//*                                                           '
       queue '//************************************************************'
       queue '//** TRANSMIT THE BACKOUT JOB TO THE TARGET PLEX              '
       queue '//************************************************************'
       queue '//RESTORE  EXEC PGM=DMBATCH,PARM=(YYSLYNN),REGION=8M          '
       queue '//DMNETMAP DD DSN='netmap',DISP=SHR'
       queue '//DMMSGFIL DD DSN=PGTN.CD.MSG,DISP=SHR                        '
       queue '//DMPUBLIB DD DSN=&&PROCESS,DISP=(OLD,DELETE)                 '
       queue '//DMPRINT  DD SYSOUT=*                                        '
       queue '//SYSIN    DD *                                               '
       queue ' SIGNON                                                       '
       queue ' SUBMIT PROC=EVGDOUTI PRTY=12 CLASS=1 SNODE='node
       queue ' SIGNOFF                                                      '
       queue '/*                                                            '
       queue '//CHECKIT  IF RESTORE.RC GT 0 THEN                            '

       call add_implfail_spwarn_jcl /* add failure step              */

       queue '//CHECKIT  ENDIF                                              '
       queue '//*                                                           '

     end /* actions.rdst = 'Y' */

   end /* y = 1 to words(list_destsb) */

 end /* z = 1 to dumprst_count */

return /* dumprst_jcl_b: */

/*-------------------------------------------------------------------*/
/*  Process DUMPRST* dataset content at implemention                 */
/*-------------------------------------------------------------------*/
dumprst_jcl_i:
 actions. = ''

 call readint 'DESTINFO' /* set up all the plex specific variables   */

 call readint 'DESTSYS' /* set up all the plex destinations          */

 do z = 1 to dumprst_count /* loop through datasets                  */

   pid      = right(dumprst_dsn.z,1)'1' /*  base dataset name        */
   stgdsnq  = strip(dumprst_stagedsnq.z) /* staging dataset on Qplex */
   netmap   = 'PGTN.CD.CD08.'pid'.NETMAP' /* Source netmap           */
   tidyname = 'TIDYUP'pid
   dumpname = 'DUMPIT'pid
   chckname = 'CHECK'pid
   sdsn     = 'PGEV.DUMP.PLEX'pid'.'changeid /* source dataset       */

   /* if target dataset not for this dest then get next record       */
   if pid ^= right(dest,2) then iterate

   /* Get the the contents of the promoted member                    */
   "alloc f(MEMBER) dsname('"stgdsnq"("changeid")') shr"
   if rc ^= 0 then
     call exception rc 'ALLOC of' stgdsnq'('changeid') failed.'
   'execio * diskr MEMBER (stem source. finis'
   if rc ^= 0 then
     call exception rc 'DISKR of' stgdsnq'('changeid') failed.'
   "free f(MEMBER)"

   /* build the DFDSS dump JCL on the source plex                    */
   queue '//************************************************************'
   queue '//** TIDY UP THE DUMP DATASET IN CASE IT EXISTS               '
   queue '//************************************************************'
   queue '//'tidyname' EXEC PGM=IEFBR14'
   queue '//DD1      DD DISP=(MOD,DELETE),SPACE=(TRK,(0,0)),            '
   queue '//             DSN='sdsn
   queue '//*                                                           '
   queue '//************************************************************'
   queue '//** DUMP THE DATASETS ON THE SOURCE PLEX                     '
   queue '//************************************************************'
   queue '//'dumpname' EXEC PGM=ADRDSSU,REGION=8M'
   queue '//SYSPRINT DD SYSOUT=*                                        '
   queue '//OUTPUT   DD DSN='sdsn','
   queue '//             DISP=(NEW,CATLG),                              '
   queue '//             SPACE=(CYL,(150,150),RLSE),LRECL=1021,         '
   queue '//             RECFM=U,FREE=CLOSE                             '
   queue '//SYSIN    DD *                                               '
   queue ' DUMP DATASET -                                               '
   queue '      (INCLUDE( -                                             '

   do a = 1 to source.0
     dsn.a = strip(word(source.a,1))
     queue '       'dsn.a' -' /* put the dataset name on the queue   */

     /* loop through the destinations per dataset and build an array */
     /* to drive how many runtask steps have to be built.            */
     do b = 2 to words(source.a)
       plex = word(source.a,b) /* get the target plex                */
       actions.plex = actions.plex dsn.a /* build up an array        */
     end /* b = 2 to words(source.a) */

   end /* a = 1 to source.0 */

   queue '      ))                -                                   '
   queue '      OUTDDNAME(OUTPUT) -                                   '
   queue '      CANCELERROR       -                                   '
   queue '      COMPRESS          -                                   '
   queue '      OPTIMIZE(4)       -                                   '
   queue '      TOL(ENQF)                                             '
   queue '/*                                                          '
   queue '//CHECKIT  IF 'dumpname'.RC GT 8 THEN'

   call add_implfail_spwarn_jcl /* add failure step                  */

   queue '//CHECKIT  ENDIF                                            '
   queue '//*                                                         '

   /* if there are actions to process the build the additional JCL   */
   do c = 1 to words(list_destsb)
     tdst = word(list_destsb,c) /* target destination                */

     /* build the JCL for Cjob or Bjob based on jobtype              */
     if length(actions.tdst) > 0 then
       call senddump tdst

   end /* c = 1 to words(list_destsb) */

 end /* z = 1 to dumprst_count */

return /* dmprstl_jcl_i: */

/*-------------------------------------------------------------------*/
/* Read & interpret input data                                       */
/*-------------------------------------------------------------------*/
readint:

 arg ddname

 /* Alloc the file                                                   */
 "alloc f("ddname") dsname('PGEV.BASE.DATA("ddname")') shr"
 if rc ^= 0 then call exception rc 'ALLOC of' ddname 'failed.'

 /* Get the contents of the file                                     */
 "execio * diskr" ddname "(stem record. finis"
 if rc > 0 then call exception rc 'Read of DDname' ddname 'failed'

 "free f("ddname")" /* free the file                                 */

 do i = 1 to record.0
   interpret record.i /* make the text in to variables               */
 end /* i = 1 record.0 */

 /* Check to see if there are any overrides in DESTSYS               */
 if ddname = 'DESTSYS' then do
   if C1SYSTEMB.EV = "C1SYSTEMB.EV" then
     list_destsb = C1SYSTEMB.DEFAULT
   else
     list_destsb = C1SYSTEMB.EV
 end /* ddname = 'DESTSYS' */

return /* readint: */

/*-------------------------------------------------------------------*/
/* build the JCL to send the dump and run task commands              */
/*-------------------------------------------------------------------*/
senddump:
 arg tdst

 dfdss.   = '' /* initialise the dfdss array                         */
 node     = cd.tdst
 tdsn     = 'PGEV.DUMP.'tdst'.'changeid /* target dataset            */
 tbkp     = 'PGEV.DUMP.'tdst'.'changeid'.BKP' /* target dataset      */
 auto     = 0 /* initialise counter for dump datasets                */

 /* Build some variables required for EVGDIMPI job on remote plex    */
 autodsn  = 'PGEV.AUTO.DATA'
 automem  = right(tdst,2)||right(changeid,6)
 sendauto = autodsn'('automem')'

 /* define some step names                                           */
 temptask = 'TMPPRC'right(tdst,2)
 transfer = 'SNDFLE'right(tdst,2)
 runtask  = 'RUNTSK'right(tdst,2)

 /* amend qplex c:d node                                             */
 if node = 'LOCAL' then
   node = 'CD.OS390.Q102'

 /* change the node to be the correct one for file transfers         */
 node = OVERLAY('8',node,13)

 queue '//************************************************************'
 queue '//** CREATE A TEMPORARY NDM PROCESS                           '
 queue '//************************************************************'
 queue '//'temptask' EXEC PGM=IEBGENER'
 queue '//SYSPRINT DD SYSOUT=*                                        '
 queue '//SYSUT1   DD *                                               '
 queue 'EVGDIMPI PROCESS SNODE='node
 queue 'EVGDIMPI RUN TASK (PGM=DMRTSUB, -                             '
 queue '     PARM=("DSN=PGEV.BASE.JCL(EVGDIMPI),DISP=SHR", -          '
 queue '                     "TDSN 'tdsn'", -'
 queue '                     "TBKP 'tbkp'",  -'
 queue '                     "CMR  'changeid'", -'
 queue '                     "AUTODSN 'sendauto'", -'
 queue '                     )) SNODE                                 '
 queue '/*                                                            '
 queue '//SYSUT2   DD DSN=&&PROCESS(EVGDIMPI),DISP=(NEW,PASS),        '
 queue '//             SPACE=(TRK,(2,1,44)),LRECL=80,                 '
 queue '//             RECFM=FB                                       '
 queue '//SYSIN    DD DUMMY                                           '
 queue '//*                                                           '
 queue '//CHECKIT  IF 'temptask'.RC GT 0 THEN'

 call add_implfail_spwarn_jcl /* add failure step                    */

 queue '//CHECKIT  ENDIF                                              '
 queue '//*                                                           '
 queue '//************************************************************'
 queue '//** TRANSMIT THE DUMP DATASET TO THE TARGET PLEX             '
 queue '//************************************************************'
 queue '//'transfer' EXEC PGM=DMBATCH,PARM=(YYSLYNN),REGION=8M'
 queue '//DMNETMAP DD DSN='netmap',DISP=SHR'
 queue '//DMMSGFIL DD DSN=PGTN.CD.MSG,DISP=SHR                        '
 queue '//DMPUBLIB DD DSN=PGEV.BASE.NDMDATA,DISP=SHR                  '
 queue '//DMPRINT  DD SYSOUT=*                                        '
 queue '//SYSIN    DD *                                               '
 queue ' SIGNON                                                       '
 queue ' SUBMIT PROC=NDMCOPY SNODE='node' -'
 queue ' MAXDELAY=00:10:00  -                                         '
 queue '           &F1="'sdsn'" -'
 queue '           &F2="'tdsn'" -'
 queue '           &DISPI="SHR" -                                     '
 queue '           &DISPO="RPL,CATLG"                                 '
 queue ' SIGNOFF                                                      '
 queue '/*                                                            '
 queue '//CHECKIT  IF 'transfer'.RC GT 0 THEN'

 call add_implfail_spwarn_jcl /* add failure step                    */

 queue '//CHECKIT  ENDIF                                              '
 queue '//*                                                           '
 queue '//************************************************************'
 queue '//** SUBMIT THE RUNTASK                                       '
 queue '//************************************************************'
 queue '//'runtask' EXEC PGM=DMBATCH,PARM=(YYSLYNN),REGION=8M'
 queue '//DMNETMAP DD DSN='netmap',DISP=SHR'
 queue '//DMMSGFIL DD DSN=PGTN.CD.MSG,DISP=SHR                        '
 queue '//DMPUBLIB DD DSN=&&PROCESS,DISP=(OLD,DELETE)                 '
 queue '//DMPRINT  DD SYSOUT=*                                        '
 queue '//SYSIN    DD *                                               '
 queue ' SIGNON                                                       '
 queue ' SUBMIT PROC=EVGDIMPI PRTY=12 CLASS=1                         '
 queue ' SIGNOFF                                                      '
 queue '/*                                                            '
 queue '//CHECKIT  IF 'runtask'.RC GT 0 THEN'

 call add_implfail_spwarn_jcl /* add failure step                    */

 queue '//CHECKIT  ENDIF                                              '
 queue '//*                                                           '

return /* senddump: */

/*-------------------------------------------------------------------*/
/*  Process Mstrmap application code                                 */
/*-------------------------------------------------------------------*/
mstrmap2_jcl:

 stgdsnq = mstrmap2_stagedsnq.1

 t = outtrap('TSOOUT.')
 "listds '"stgdsnq"' members"
 if rc ^= 0 then call exception rc 'Error on LISTDS of' stgdsnq

 do t = 7 to tsoout.0
   member = strip(tsoout.t)
   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   /* Read the shipment file to get the control data                 */
   "ALLOC F(shipmt) DSNAME('"stgdsnq"("member")') SHR"
   if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('member') failed.'
   "execio * diskr shipmt (stem mstrmap2. finis"
   if rc ^= 0 then call exception rc 'DISKR of' stgdsnq'('member') failed.'
   "FREE F(shipmt)"

   appid  = word(mstrmap2.1,1)
   inst   = word(mstrmap2.1,2)
   target = word(mstrmap2.1,3)
   owner  = word(mstrmap2.2,1)

   newstack /* New stack for adding JCL to CA7 demand steps          */

   queue "//LN"inst"MSTRI JOB 1,CLASS=N,MSGCLASS=Y,USER="owner
   queue "//SETVAR   SET ID=P"inst",BNK="inst",TLQ=                   "
   queue "//*                                                         "
   queue "//* JCL BUILT BY PACKAGE CMR -" changeid
   queue "//*                                                         "
   queue "//JCLLIB   JCLLIB ORDER=PGOS.BASE.PROCLIB                   "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** RUN MSTRMAP UTILITY DTLURDMO                           "
   queue "//**********************************************************"
   queue "//JSTEP010 EXEC LN#MSTRI,                                   "
   queue "//             PWXALIAS=SYSPWX."inst||appid",               "
   queue "//             PWXALIA1=PGPX."inst||appid",                 "
   queue "//             MEMBER="member",                             "
   queue "//             TARGET="target
   queue "//*                                                         "

   /* Add the CA7 demand JCL to the job                              */
   call ca7_demand 'LN'inst'MSTRI' 'LN'inst'M'right(changeid,4) 'P03'

 end  /* t = 7 to tsoout.0 */

return /* mstrmap2_jcl: */

/*-------------------------------------------------------------------*/
/*  Add CUSTMAP (CUSTCNTL) JCL                                       */
/*-------------------------------------------------------------------*/
custcntl_jcl:

 stgdsnq = custcntl_stagedsnq.1

 t = outtrap('TSOOUT.')
 "listds '"stgdsnq"' members"
 if rc ^= 0 then call exception rc 'Error on LISTDS of' stgdsnq

 do t = 7 to tsoout.0
   member = strip(tsoout.t)
   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   /* Read the shipment file to get the control data                 */
   "ALLOC F(shipmt) DSNAME('"stgdsnq"("member")') SHR"
   if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('member') failed.'
   "execio * diskr shipmt (stem custcntl. finis"
   if rc ^= 0 then call exception rc 'DISKR of' stgdsnq'('member') failed.'
   "FREE F(shipmt)"

   ssid     = word(custcntl.1,1)
   appid    = word(custcntl.1,2)
   epol     = word(custcntl.1,3)
   inst     = word(custcntl.1,4)
   brandnum = word(custcntl.1,5)
   target   = word(custcntl.1,6)
   owner    = word(custcntl.2,1)

   newstack /* New stack for adding JCL to CA7 demand steps          */

   queue "//LN"inst"CUSTI JOB 1,CLASS=N,MSGCLASS=Y,USER="owner
   queue "//SETVAR   SET ID=P"inst",BNK="inst",TLQ=                   "
   queue "//*                                                         "
   queue "//* JCL BUILT BY PACKAGE CMR -" changeid
   queue "//*                                                         "
   queue "//JCLLIB   JCLLIB ORDER=PGOS.BASE.PROCLIB                   "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//**       BUILD JCL FOR CUSTMAP FILE UPDATE                "
   queue "//**********************************************************"
   queue "//JSTEP010 EXEC LN#CUSTI,                                   "
   queue "//             PWXALIAS=SYSPWX."inst||appid",               "
   queue "//             PWXALIA1=PGPX."inst||appid",                 "
   queue "//             TARGET="target",                             "
   queue "//             EPOL="epol",                                 "
   queue "//             SSID="ssid",                                 "
   queue "//             QUAL=GRP,                                    "
   queue "//             BRAND="brandnum
   queue "//*                                                         "

   /* Add the CA7 demand JCL to the job                              */
   call ca7_demand 'LN'inst'CUSTI' 'LN'inst'C'right(changeid,4) 'P03'

   newstack /* New stack for adding JCL to CA7 demand steps          */

   queue "//LN"inst"PXCUI JOB 1,CLASS=N,MSGCLASS=Y,USER="owner
   queue "//SETVAR   SET ID=P"inst",BNK="inst",TLQ=                   "
   queue "//*                                                         "
   queue "//* JCL BUILT BY PACKAGE CMR -" changeid
   queue "//*                                                         "
   queue "//JCLLIB   JCLLIB ORDER=PGOS.BASE.PROCLIB                   "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//**       BUILD JCL FOR CUSTMAP PWX FILE UPDATE            "
   queue "//**********************************************************"
   queue "//JSTEP010 EXEC LN#PXCUI,                                   "
   queue "//             PWXALIAS=SYSPWX."inst||appid",               "
   queue "//             PWXALIA1=PGPX."inst||appid",                 "
   queue "//             TARGET="target",                             "
   queue "//             EPOL="epol",                                 "
   queue "//             SSID="ssid",                                 "
   queue "//             QUAL=GRP,                                    "
   queue "//             BRAND="brandnum
   queue "//*                                                         "

   /* Add the CA7 demand JCL to the job                              */
   call ca7_demand 'LN'inst'PXCUI' 'LN'inst'P'right(changeid,4) 'P03'

 end  /* t = 7 to tsoout.0 */

return /* custcntl_jcl: */

/*-------------------------------------------------------------------*/
/* Add CDMLOGIC JCL                                                  */
/*-------------------------------------------------------------------*/
cdmlogic_jcl:

 step_number = 0
 stgdsnq     = cdmlogic_stagedsnq.1

 /* Get a list of members in the staging dataset                     */
 t = outtrap('tsoout.')
 "listds '"stgdsnq"' members"
 if rc ^= 0 then call exception rc 'Error on listds of' stgdsnq

 newstack /* New stack for adding JCL to CA7 demand steps            */

 /* Set up the job card                                              */
 queue "//FMGCDMLI JOB 1,CLASS=N,MSGCLASS=Y,REGION=256M,USER=GRP      "
 queue "//*                                                           "
 queue "//* JCL BUILT BY PACKAGE CMR -" changeid
 queue "//*              JOB         - EVGUSSDI                       "
 queue "//*                                                           "
 queue "//JCLLIB   JCLLIB ORDER=PGOS.BASE.PROCLIB                     "

 /* Loop through the shipment dataset to read the each member        */
 do t = 7 to tsoout.0 /* loop through the members                    */
   member = strip(tsoout.t)

   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   /* Get the processor group from each member                       */
   "alloc f(MEMBER) dsname('"stgdsnq"("member")') shr"
   if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('member') failed'
   'execio * diskr MEMBER (stem line. finis'
   if rc ^= 0 then call exception rc 'DISKR of' stgdsnq'('member') failed'
   "free f(MEMBER)"

   full_file_name  = word(line.1,1)
   parse value full_file_name with file_name '.' ext

   processor_group = word(line.2,1)
   select /* The processor group must be lower case                  */
     when processor_group = 'IMPORT' then processor_group = 'import'
     when processor_group = 'UPDATE' then processor_group = 'update'
     when processor_group = 'DEPLOY' then processor_group = 'deploy'
     otherwise nop
   end /* select */

   step_number = step_number + 1
   step#       = right(step_number,3,'0')

   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** PROCESS CDMLOGIC FILE" full_file_name
   queue "//**********************************************************"
   queue "//CDML"step#"  EXEC PGM=IKJEFT1B                            "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//STDOUT   DD PATH='/u/pg/home/grp/"full_file_name".out',"
   queue "//            PATHOPTS=(OWRONLY,OCREAT,OTRUNC),             "
   queue "//            PATHMODE=(SIRWXU,SIRWXG,SIRWXO)               "
   queue "//STDERR   DD PATH='/u/pg/home/grp/"full_file_name".err',"
   queue "//            PATHOPTS=(OWRONLY,OCREAT,OTRUNC),             "
   queue "//            PATHMODE=(SIRWXU,SIRWXG,SIRWXO)               "
   queue "//SYSTSIN  DD *                                             "
   queue "  BPXBATCH SH +                                             "
   queue "  /RBSG/endevor/PGFM/BASE/BIN/deploy.sh +                   "
   queue "  /usr/lpp/java/J6.0 +                                      "
   queue "  /software/apache-ant/bin/ant.sh +                         "
   queue "  /RBSG/endevor/PGFM/BASE/ANT +                             "
   queue "  /RBSG/endevor/PGFM/BASE/JAVALIB +                         "
   queue "  /RBSG/endevor/PGFM/BASE/PROPERTIES/PRODlogic.properties + "
   queue "  /RBSG/endevor/PGFJ/BASE/CDMLOGIC/"full_file_name "+"
   queue "  /RBSG/endevor/PGFJ/BASE/PROPERTIES/"file_name".properties +"
   queue " " processor_group
   queue "/*                                                          "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** COPY THE OUTPUT                                        "
   queue "//**********************************************************"
   queue "//CDMO"step#" EXEC PGM=IKJEFT1B,COND=EVEN                   "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//INFILE1  DD PATH='/u/pg/home/grp/"full_file_name".err',"
   queue "//            PATHOPTS=ORDONLY,PATHDISP=DELETE              "
   queue "//INFILE2  DD PATH='/u/pg/home/grp/"full_file_name".out',"
   queue "//            PATHOPTS=ORDONLY,PATHDISP=DELETE              "
   queue "//OUTFILE1 DD DSN=&&MAILDATA,DISP=(MOD,PASS),               "
   queue "//            RECFM=VB,LRECL=2000,BLKSIZE=0,DATACLAS=DSIZE10"
   queue "//SYSOUT   DD SYSOUT=*,RECFM=VB,LRECL=2000                  "
   queue "//INFILE3  DD DSN=PGFM.BASE.DATA(CDMLFAIL),DISP=SHR         "
   queue "//OUTFILE3 DD DSN=&&MAILHDRF,DISP=(,PASS,DELETE),           "
   queue "//            RECFM=VB,LRECL=2000,BLKSIZE=0,DATACLAS=DSIZE10"
   queue "//INFILE4  DD DSN=PGFM.BASE.DATA(CDMLMAIL),DISP=SHR         "
   queue "//OUTFILE4 DD DSN=&&MAILHDRS,DISP=(,PASS,DELETE),           "
   queue "//            RECFM=VB,LRECL=2000,BLKSIZE=0,DATACLAS=DSIZE10"
   queue "//SYSTSIN  DD *                                             "
   queue "  OCOPY INDD(INFILE1)  OUTDD(OUTFILE1)                      "
   queue "  OCOPY INDD(INFILE2)  OUTDD(OUTFILE1)                      "
   queue "  OCOPY INDD(OUTFILE1) OUTDD(SYSOUT)                        "
   queue "  OCOPY INDD(INFILE3)  OUTDD(OUTFILE3)                      "
   queue "  OCOPY INDD(INFILE4)  OUTDD(OUTFILE4)                      "
   queue "/*                                                          "
   queue "//*                                                         "
   queue "//CHECKIT  IF CDMO"step#".RC NE 0 THEN                      "
   call add_implfail_spwarn_jcl
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//CHECKIT  IF CDML"step#".RC NE 0 THEN                      "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** EMAIL THE OUTPUT ON FAILURE                            "
   queue "//**********************************************************"
   queue "//CDME"step#" EXEC PGM=IKJEFT1B,                            "
   queue "//             PARM='%SENDMAIL DEFAULT LOG(YES)'            "
   queue "//SYSPROC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                 "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//SYSTSIN  DD DUMMY                                         "
   queue "//SYSADDR  DD DSN=PGFM.BASE.DATA(CDMLADDF),DISP=SHR         "
   queue "//SYSDATA  DD DSN=&&MAILHDRF,DISP=(OLD,DELETE)              "
   queue "//         DD DSN=&&MAILDATA,DISP=(OLD,DELETE)              "
   call add_implfail_spwarn_jcl
   queue "//*                                                         "
   queue "//CHECKIT  ELSE                                             "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** EMAIL THE OUTPUT ON SUCCESS                            "
   queue "//**********************************************************"
   queue "//CDMM"step#" EXEC PGM=IKJEFT1B,                            "
   queue "//             PARM='%SENDMAIL DEFAULT LOG(YES)'            "
   queue "//SYSPROC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                 "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//SYSTSIN  DD DUMMY                                         "
   queue "//SYSADDR  DD DSN=PGFM.BASE.DATA(CDMLADDR),DISP=SHR         "
   queue "//SYSDATA  DD DSN=&&MAILHDRS,DISP=(OLD,DELETE)              "
   queue "//         DD DSN=&&MAILDATA,DISP=(OLD,DELETE)              "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** SPWARN IF IF CDMM"step#" FAILS                         "
   queue "//**********************************************************"
   queue "//CHECKIT  IF CDMM"step#".RC NE 0 THEN                      "
   queue "//SPWARN   EXEC @SPWARN,COND=EVEN                           "
   queue "//CHECKIT  ENDIF                                            "
 end /* t = 7 to tsoout.0 */

 /* Add the CA7 demand JCL to the job                                */
 call add_impl_jcl
 call ca7_demand 'FMGCDMLI' 'FMCD'right(changeid,4) 'FROW'

return /* cdmlogic_jcl: */

/*-------------------------------------------------------------------*/
/* Add CDMPCSVB JCL                                                  */
/*-------------------------------------------------------------------*/
cdmpcsvb_jcl:

 step_number = 0
 stgdsnq = cdmpcsvb_stagedsnq.1

 /* Get a list of members in the staging dataset                     */
 t = outtrap('tsoout.')
 "listds '"stgdsnq"' members"
 if rc ^= 0 then call exception rc 'Error on listds of' stgdsnq

 newstack /* New stack for adding JCL to CA7 demand steps            */

 /* Set up the job card                                              */
 queue "//FMGPCSVI JOB 1,CLASS=N,MSGCLASS=Y,REGION=256M,USER=GRP      "
 queue "//*                                                           "
 queue "//* JCL BUILT BY PACKAGE CMR -" changeid
 queue "//*              JOB         - EVGUSSDI                       "
 queue "//*                                                           "
 queue "//JCLLIB   JCLLIB ORDER=PGOS.BASE.PROCLIB                     "

 /* Read the each member form the staging dataset & build JCL steps  */
 do t = 7 to tsoout.0
   member = strip(tsoout.t)
   if member = '$$$SPACE' then iterate /* pdsman spacemap            */

   /* Get the USS file name from each member                         */
   "alloc f(MEMBER) dsname('"stgdsnq"("member")') shr"
   if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('member') failed.'
   'execio * diskr MEMBER (stem line. finis'
   if rc ^= 0 then call exception rc 'DISKR of' stgdsnq'('member') failed.'
   "free f(MEMBER)"

   full_file_name  = word(line.1,1)
   parse value full_file_name with file_name '.' ext

   step_number = step_number + 1
   step#       = right(step_number,3,'0')

   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** PROCESS CDMPCSVB FILE" full_file_name
   queue "//**********************************************************"
   queue "//CSVP"step#"  EXEC PGM=IKJEFT1B                            "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//STDOUT   DD PATH='/u/pg/home/grp/"full_file_name".out',"
   queue "//            PATHOPTS=(OWRONLY,OCREAT,OTRUNC),             "
   queue "//            PATHMODE=(SIRWXU,SIRWXG,SIRWXO)               "
   queue "//STDERR   DD PATH='/u/pg/home/grp/"full_file_name".err',"
   queue "//            PATHOPTS=(OWRONLY,OCREAT,OTRUNC),             "
   queue "//            PATHMODE=(SIRWXU,SIRWXG,SIRWXO)               "
   queue "//SYSTSIN  DD *                                             "
   queue "  BPXBATCH SH +                                             "
   queue "  /RBSG/endevor/PGFM/BASE/CDMP/bin/run_create_props.sh +    "
   queue "  /RBSG/endevor/PGFM/BASE/CDMP/bin +                        "
   queue "  /usr/lpp/java/J6.0/bin/java +                             "
   queue "  /usr/lpp/software/db2/DPL0JB/jcc DPL0 GFMOD0P0 INFO +     "
   queue "  /RBSG/endevor/PGFJ/BASE/CDMPCSVB/"full_file_name "+"
   queue "  "file_name
   queue "/*                                                          "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** COPY THE OUTPUT                                        "
   queue "//**********************************************************"
   queue "//CSVO"step#" EXEC PGM=IKJEFT1B,COND=EVEN                   "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//INFILE1  DD PATH='/u/pg/home/grp/"full_file_name".err',"
   queue "//            PATHOPTS=ORDONLY,PATHDISP=DELETE              "
   queue "//OUTFILE1 DD DSN=&&STDERR,DISP=(NEW,PASS),                 "
   queue "//            RECFM=VB,LRECL=2000,BLKSIZE=0                 "
   queue "//STDERR   DD SYSOUT=*,RECFM=VB,LRECL=2000                  "
   queue "//SYSTSIN  DD *                                             "
   queue "  OCOPY INDD(INFILE1) OUTDD(STDERR)                         "
   queue "  OCOPY INDD(INFILE1) OUTDD(OUTFILE1)                       "
   queue "/*                                                          "
   queue "//*                                                         "
   queue "//CHECKIT  IF CSVP"step#".RC NE 0 OR                        "
   queue "//            CSVO"step#".RC NE 0 THEN                      "
   call add_implfail_spwarn_jcl
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//CSVC"step#" EXEC PGM=IRXJCL,PARM='FMPROPCK ERROR WARN'    "
   queue "//SYSEXEC  DD DISP=SHR,DSN=PGFM.BASE.REXX                   "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//STDERR   DD DSN=&&STDERR,DISP=(OLD,DELETE)                "
   queue "//*                                                         "
   queue "//CHECKIT  IF CSVC"step#".RC NE 0 THEN                      "
   call add_implfail_spwarn_jcl
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** COPY THE OUTPUT                                        "
   queue "//**********************************************************"
   queue "//CSVM"step#" EXEC PGM=IKJEFT1B                             "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//INFILE1  DD DISP=SHR,DSN=PGFM.BASE.DATA(PROPMAIL)         "
   queue "//OUTFILE1 DD DSN=&&MAILHDR,DISP=(NEW,PASS),                "
   queue "//            RECFM=VB,LRECL=1000                           "
   queue "//INFILE2  DD PATH='/u/pg/home/grp/"full_file_name".out',"
   queue "//            PATHOPTS=ORDONLY,PATHDISP=DELETE              "
   queue "//OUTFILE2 DD DSN=&&MAILDATA,DISP=(NEW,PASS),               "
   queue "//            RECFM=VB,LRECL=1000                           "
   queue "//SYSTSIN  DD *                                             "
   queue "  OCOPY INDD(INFILE1) OUTDD(OUTFILE1)                       "
   queue "  OCOPY INDD(INFILE2) OUTDD(OUTFILE2)                       "
   queue "/*                                                          "
   queue "//**********************************************************"
   queue "//** SPWARN IF IF CSVM FAILS                                "
   queue "//**********************************************************"
   queue "//CHECKIT  IF CSVM"step#".RC NE 0 THEN                      "
   queue "//SPWARN   EXEC @SPWARN,COND=EVEN                           "
   queue "//CHECKIT  ENDIF                                            "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** EMAIL THE OUTPUT                                       "
   queue "//**********************************************************"
   queue "//CSVE"step#" EXEC PGM=IKJEFT1B,                            "
   queue "//             PARM='%SENDMAIL DEFAULT LOG(YES)'            "
   queue "//SYSPROC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                 "
   queue "//SYSTSPRT DD SYSOUT=*                                      "
   queue "//SYSTSIN  DD DUMMY                                         "
   queue "//SYSADDR  DD DSN=PGFM.BASE.DATA(PROPADDR),DISP=SHR         "
   queue "//SYSDATA  DD DSN=&&MAILHDR,DISP=(OLD,DELETE)               "
   queue "//         DD DSN=&&MAILDATA,DISP=(OLD,DELETE)              "
   queue "//*                                                         "
   queue "//**********************************************************"
   queue "//** SPWARN IF IF CSVE FAILS                                "
   queue "//**********************************************************"
   queue "//CHECKIT  IF CSVE"step#".RC NE 0 THEN                      "
   queue "//SPWARN   EXEC @SPWARN,COND=EVEN                           "
   queue "//CHECKIT  ENDIF                                            "
 end /* t = 7 to tsoout.0 */

 /* Add the CA7 demand JCL to the job                                */
 call add_impl_jcl
 call ca7_demand 'FMGPCSVI' 'FMCS'right(changeid,4) 'FROW'

return /* cdmpcsvb_jcl: */

/*-------------------------------------------------------------------*/
/* Add SYSVIEW parms copy JCL                                        */
/*-------------------------------------------------------------------*/
svparm_jcl:

 do i = 1 to svparm_count

   if right(svparm_dsn.i,1) ^= plexid then
     iterate
   else do
     queue "//********************************************************"
     queue "//** COPY TO LIVE SYSVIEW PARMLIB                         "
     queue "//********************************************************"
     queue "//SVCOPY EXEC PGM=IEBCOPY                                 "
     queue "//FCOPYON  DD DUMMY                                       "
     queue "//SYSPRINT DD SYSOUT=*                                    "
     queue "//PDSIN    DD DISP=SHR,DSN="svparm_stagedsn.1
     queue "//PDSOUT   DD DISP=SHR,DSN=PGSY.CASYVIEW.CNM4BPRM."plexid"1"
     queue "//SYSIN    DD *                                           "
     queue " COPY      INDD=((PDSIN,R)),OUTDD=PDSOUT                  "
     queue "/*                                                        "
     queue "//*                                                       "
     queue "//CHECK    IF SVCOPY.RC GT 4 THEN                         "
     call add_implfail_spwarn_jcl
     queue "//CHECK    ENDIF                                          "
   end /* else */

 end /* i = 1 to svparm_dsn.0 */

return /* svparm_jcl: */

/*-------------------------------------------------------------------*/
/*   Add JCL to backout the Qplex static directories.                */
/*   Bjob only - static directories are updated by the processor     */
/*-------------------------------------------------------------------*/
Stticprm_jcl:

 /* Read the relationships file                                      */
 stticprm = '/RBSG/endevor/PGEV/BASE/TXT/STTICPRM'
 Address syscall 'readfile' stticprm 'stt.'
 if rc ^= 0 then call exception rc 'READFILE' stticprm 'failed.'

 do i = 1 to stt.0
   interpret stt.i
 end /* i = 1 to stt.0 */

 stt_jcl_added = 0 /* Only add the JCL once                          */

 /* Loop through the .USS staging datasets looking for static types  */

 do b = 1 to uss_count
   ussqs = translate(uss_dsn.b,' ','.')
   qual3 = word(ussqs,3)
   if stticvar.qual3.1 ^= 'STTICVAR.'qual3'.1' then do
     if ^stt_jcl_added then do
       stt_jcl_added = 1 /* Only add the JCL once                    */
       queue "//*                                                     "
       queue "//******************************************************"
       queue "//** STTICUPD - UPDATE THE STATIC DIRECTORIES           "
       queue "//******************************************************"
       queue "//STTICUPD EXEC PGM=BPXBATCH                            "
       queue "//STDOUT   DD SYSOUT=*                                  "
       queue "//STDERR   DD SYSOUT=*                                  "
       queue "//STDPARM  DD *                                         "
       queue "sh /RBSG/endevor/PGEV/BASE/USSREXX/STTICUPD             "
       queue "   PROD PROD P P O" system_name"1" system_name"1 MULTI  "
       queue "   REFRESH MULTI                                        "
     end /* ^stt_jcl_added */

     /* Get the file names                                           */
     stgdsnq = uss_stagedsnq.b
     /* Get a list of members in the staging dataset                 */
     t = outtrap('tsoout.')
     "listds '"stgdsnq"' members"
     if rc ^= 0 then call exception rc 'Error on listds of' stgdsnq

     /* Read the each member form the staging dataset                */
     do t = 7 to tsoout.0
       member = strip(tsoout.t)
       if member = '$$$SPACE' then iterate /* pdsman spacemap        */

       /* Get the USS file name from each member                     */
       "alloc f(MEMBER) dsname('"stgdsnq"("member")') shr"
       if rc ^= 0 then call exception rc 'ALLOC of' stgdsnq'('member') failed.'
       'execio * diskr MEMBER (stem line. finis'
       if rc ^= 0 then call exception rc 'DISKR of' stgdsnq'('member') failed.'
       "free f(MEMBER)"

       fullname = translate(word(line.1,2),' ','/')
       file_name = word(fullname,4)
       queue file_name qual3
     end /* t = 7 to tsoout.0 */

   end /* stticvar.qual3.1 ^= 'STTICVAR.'qaul3'.1' */

 end /* b = 1 to uss_count */

 if stt_jcl_added then do
   queue "/*                                                          "
   queue "//*                                                         "
   queue "//CHECKIT  IF STTICUPD.RC NE 0 THEN                         "
   call add_implfail_spwarn_jcl
   queue "//CHECKIT  ENDIF                                            "
   call add_impl_jcl
   say rexxname':'
   say rexxname': NDVEDIT added JCL for STATIC directory backout'
 end /* stt_jcl_added */

return /* Stticprm_jcl: */

/*-------------------------------------------------------------------*/
/* Create the JCL for USS elements used in abort processing          */
/*-------------------------------------------------------------------*/
uss_abort_jcl:

 rjob     = 'R'substr(changeid,2,7)
 abortmem = 'A'substr(changeid,2,7)
 abortdsn = shiphlq'.'changeid'.USSABORT'

 /* Allocate a dataset to save the ABORT JCL                         */
 "ALLOC F(ABORTJCL) DA('"abortdsn"') NEW" ,
   "CATALOG SPACE(5 15) TRACKS RECFM(F B) LRECL(80) DIR(44)"
 if rc ^= 0 then call exception rc 'ALLOC of ABORTJCL failed'

 "FREE F(ABORTJCL)" /* release the new dataset                       */
 if rc ^= 0 then call exception rc 'FREE of ABORTJCL failed'

 "alloc f(ABORTMEM) dsname('"abortdsn"("abortmem")') OLD"
 if rc ^= 0 then call exception rc 'ALLOC of' abortdsn'('abortmem') failed.'

 newstack /* New stack for building the abort jcl                    */

 queue "//*   CHANGE" changeid "USS ABORT JCL                         "
 queue "//*   MEMBER BUILT BY" rjob " AND WILL BE USED IN THE EVENT   "
 queue "//*   THAT THE CMR IS SET TO ABORT BY THE EVGABRTI JOB.       "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** MERGE USS TRIGGER PDS LIBRARIES                          "
 queue "//************************************************************"
 queue "//EVUSS01  EXEC PGM=FILEAID                                   "
 queue "//SYSPRINT DD SYSOUT=*                                        "
 queue "//SYSLIST  DD SYSOUT=*                                        "

 do b = 1 to uss_count /* USS datasets                               */
   if b = 1 then
     queue "//DD01     DD DISP=SHR,DSN="uss_stagedsn.b
   else
     queue "//         DD DISP=SHR,DSN="uss_stagedsn.b
 end /* b = 1 to uss_count */

 queue "//DD01O    DD DSN=&&ELMLIST,DATACLAS=DSIZE10,                 "
 queue "//             DISP=(NEW,PASS),LRECL=500,RECFM=FB             "
 queue "//SYSIN    DD *                                               "
 queue "$$DD01 COPY ERRS=0                                            "
 queue "/*                                                            "
 queue "//************************************************************"
 queue "//** SPWARN IF MERGE OF USS TRIGGER PDS' FAILS                "
 queue "//************************************************************"
 queue "//CHECK01  IF EVUSS01.RC NE 0 THEN                            "
 queue "//EVUSS01A EXEC @SPWARN                                       "
 queue "//CHECK01  ENDIF                                              "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SORT THE TRIGGER STATEMENTS                              "
 queue "//************************************************************"
 queue "//SORT     EXEC PGM=SORT                                      "
 queue "//SORTIN   DD DSN=&&ELMLIST,DISP=(OLD,DELETE)                 "
 queue "//SORTOUT  DD DSN=&&ELMLISTS,DATACLAS=DSIZE10,                "
 queue "//             DISP=(NEW,PASS),LRECL=500,RECFM=FB             "
 queue "//SYSOUT   DD SYSOUT=*                                        "
 queue "//SYSIN    DD *                                               "
 queue "  SORT FIELDS=(1,1,CH,D)                                      "
 queue "/*                                                            "
 queue "//************************************************************"
 queue "//** SPWARN IF SORT FAILS                                     "
 queue "//************************************************************"
 queue "//CHECK0S  IF SORT.RC NE 0 THEN                               "
 queue "//SORTA    EXEC @SPWARN                                       "
 queue "//CHECK0S  ENDIF                                              "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** COPY USS FILES FROM STAGING TO PRODUCTION                "
 queue "//************************************************************"
 queue "//EVUSS04  EXEC PGM=IKJEFT1B,PARM='%EVUSS04 ABORT" changeid"'"
 queue "//SYSPROC  DD DSN=PGEV.BASE.REXX,DISP=SHR                     "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//STDOUT   DD SYSOUT=*                                        "
 queue "//ELMLIST  DD DSN=&&ELMLISTS,DISP=(OLD,DELETE)                "
 queue "//SYSTSIN  DD DUMMY                                           "
 queue "/*                                                            "
 queue "//************************************************************"
 queue "//** SPWARN IF COPY OF USS FILES FAILS                        "
 queue "//************************************************************"
 queue "//CHECK04  IF EVUSS04.RC NE 0 THEN                            "
 queue "//EVUSS04A EXEC @SPWARN                                       "
 queue "//CHECK04  ENDIF                                              "
 queue "//*                                                           "

 'EXECIO * DISKW ABORTMEM (FINIS'
 if rc ^= 0 then call exception rc 'DISKW to ABORTMEM failed'

 delstack /* remove the stack created for this routine               */

return /* uss_abort_jcl: */

/*-------------------------------------------------------------------*/
/* Read_USS_file - doesnt use readfile because of long record length */
/*-------------------------------------------------------------------*/
read_USS_file:
 parse arg file_path stem_name

 call syscalls 'ON'
 address syscall 'open (file_path)' O_rdonly 000
 if retval = -1 then call exception retval 'open failed' ,
                          errno errnojr file_path
 fd = retval

 /* Read the file into one big lump                                  */
 lump = ''
 do until retval = 0
   address syscall 'read' fd 'block 2048'
   if retval = -1 then call exception retval 'read failed' ,
                            errno errnojr file_path
   lump = lump || block
 end /* until retval = 0 */

 /* Split the lump into records                                      */
 remainder = ''
 x15       = x2c('15') /* End of line marker                         */
 do iii = 1
   x = pos(x15,lump)   /* Find the end of the line                   */
   if x = 0 then leave

   interpret stem_name'iii = left(lump,x-1)' /* Set the stem variable*/
   lump = substr(lump,x+1) /* Start on the next line                 */
 end /* iii = 1 */

 interpret stem_name'0 = iii - 1' /* Set the number of records found */

 address syscall 'close' fd
 call syscalls 'OFF'

return /* read_USS_file: */

/*-------------------------------------------------------------------*/
/*   If required insert JCL for the universal trigger process        */
/*-------------------------------------------------------------------*/
trigger_call:

 parse arg curr_pos_in_jcl /* Where we add the extra JCL             */

 do gg = 1 to words(triggers) /* Loop through the triggers           */
   trigger = word(triggers,gg)
   if jobtype = 'CJOB' then do
     subroutine_name = value(trigger'_csub')
     required_pos    = value(trigger'_cpos')
   end /* jobtype = 'CJOB' */
   else do
     subroutine_name = value(trigger'_bsub')
     required_pos    = value(trigger'_bpos')
   end /* else */

   if value(trigger'_count') > 0               & , /* trigger found  */
      required_pos           = curr_pos_in_jcl & , /* correct posn   */
      subroutine_name       ^= ''              then do

     curr_lines = queued()
     interpret 'call' subroutine_name
     new_lines  = queued()

     if curr_lines ^= new_lines then do
       say rexxname':' /* Subroutines might not add JCL              */
       say rexxname': NDVEDIT added JCL for' trigger
     end /* curr_lines ^= new_lines */

   end /* value(trigger'_count') > 0 & ... */

 end /* gg = 1 to words(triggers) */

return /* trigger_call: */

/*-------------------------------------------------------------------*/
/* Add JCL to set the CMR to IMPLFAIL or BACKFAIL and SPWARN         */
/*-------------------------------------------------------------------*/
add_implfail_spwarn_jcl:

 /* Depending on the jobtype, the Infoman status needs to be set     */
 if jobtype = 'CJOB' then status = 'IMPLFAIL'
                     else status = 'BACKFAIL'

 stepname = 'SETCMR'left(status,1)'F'

 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SET THE CMR TO" status "AND SPWARN ON FAILURE            "
 queue "//************************************************************"
 queue "//"stepname "EXEC PGM=IKJEFT1B,COND=EVEN                      "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//SYSTSIN  DD *                                               "
 queue " SEND 'EV000202 ENDEVOR CJOB:" changeid ,
       "COMPLETED - STATUS:" status"'"
 queue "/*                                                            "
 queue "//SPWARN   EXEC @SPWARN,COND=EVEN                             "

return /* add_implfail_spwarn_jcl: */

/*-------------------------------------------------------------------*/
/* Add JCL to set the CMR to IMPL or BACKOUT                         */
/*-------------------------------------------------------------------*/
add_impl_jcl:

 /* Depending on the jobtype, the Infoman status needs to be set     */
 if jobtype = 'CJOB' then status = 'IMPL'
                     else status = 'BACKOUT'

 stepname = left('SETCMR'left(status,1),8)

 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** ON SUCCESSFUL RUN/RERUN, SET THE CMR TO" status
 queue "//************************************************************"
 queue "//"stepname "EXEC PGM=IKJEFT1B                                "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//SYSTSIN  DD *                                               "
 queue " SEND 'EV000202 ENDEVOR CJOB:" changeid ,
       "COMPLETED - STATUS:" status"'"
 queue "/*                                                            "

return /* add_impl_jcl: */

/*-------------------------------------------------------------------*/
/* Add JCL to save JCL and demand through CA7                        */
/*-------------------------------------------------------------------*/
ca7_demand:
 arg ca7_jobname ca7_member ca7_locn

 if ca7_locn = 'DEFAULT' then
   ca7_locn = ca7.dest

 if ca7_locn = 'FROW' then ca7hlq = 'PROS'
                      else ca7hlq = 'PGOS'

 /* Set up the step names                                            */
 ca7_stepno = ca7_stepno + 1
 ca7_step1  = 'CA7S'right(ca7_stepno,3,'0')
 ca7_step2  = 'CA7D'right(ca7_stepno,3,'0')
 ca7_step3  = 'CA7C'right(ca7_stepno,3,'0')

 dlm = right(ca7_stepno,2,'0') /* DATA delimiter                     */

 /* Read JCL from the newstack (written in the calling subroutine)   */
 ca7_line.0 = queued()
 do ca7_count = 1 to ca7_line.0
   parse pull ca7_line.ca7_count
 end /* ca7_count = 1 to ca7_line.0 */

 delstack

 /* Store the JCL & demand the job                                   */
 queue "//*-----------------------------------------------------------"
 queue "//** START OF DEMAND FOR" right(trigger,8)    "- DLM="dlm
 queue "//*-----------------------------------------------------------"
 queue "//************************************************************"
 queue "//** SAVE" trigger "JCL TO PGEV.AUTO.CMJOBS("ca7_member")     "
 queue "//************************************************************"
 queue "//"ca7_step1"  EXEC PGM=ICEGENER                              "
 queue "//SYSPRINT DD SYSOUT=*                                        "
 queue "//SYSUT1   DD DATA,DLM="dlm

 do ca7_count = 1 to ca7_line.0
   queue ca7_line.ca7_count
 end /* ca7_count = 1 to ca7_line.0 */

 drop ca7_line.
 queue dlm
 queue "//SYSUT2   DD DISP=SHR,DSN=PGEV.AUTO.CMJOBS("ca7_member")     "
 queue "//SYSIN    DD DUMMY                                           "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SPWARN IF ICEGENER FAILS                                 "
 queue "//************************************************************"
 queue "//CHECKIT  IF ("ca7_step1".RUN AND "ca7_step1".RC GT 0) THEN  "
 queue "//SPWARN   EXEC @SPWARN                                       "
 queue "//CHECKIT  ENDIF                                              "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** DEMAND" trigger "JOB" ca7_jobname "IN CA7"ca7_locn
 queue "//************************************************************"
 queue "//"ca7_step2" EXEC @SASBSTR,HLQ="ca7hlq",LOCN="ca7_locn
 queue "//LOCKDSN  DD DSN=PGEV.NENDEVOR."ca7_jobname".CA7LOCK,        "
 queue "//             DISP=(MOD,DELETE),FREE=CLOSE,SPACE=(TRK,(1,1)) "
 queue "//SYSIN    DD *                                               "
 queue "JOB                                                           "
 queue "UPD,"ca7_jobname",JCLMBR="ca7_member",JCLID=6                 "
 queue "DBM                                                           "
 queue "DEMAND,JOB="ca7_jobname
 queue "/*                                                            "
 queue "//SYSPRINT DD DSN=&&CA7OUT,DISP=(NEW,PASS),                   "
 queue "//             SPACE=(TRK,(5,5),RLSE),RECFM=FB,               "
 queue "//             LRECL=80                                       "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** CHECK THE CA7 OUTPUT FOR ERRORS                          "
 queue "//************************************************************"
 queue "//"ca7_step3"  EXEC PGM=IRXJCL,PARM='CA7CHECK'                "
 queue "//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                     "
 queue "//SYSTSPRT DD SYSOUT=*                                        "
 queue "//CA7IN    DD DSN=&&CA7OUT,DISP=(OLD,DELETE)                  "
 queue "//CA7OUT   DD SYSOUT=*                                        "
 queue "//SYSTSIN  DD DUMMY                                           "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//** SPWARN IF CA7 BATCH TERMINAL FAILS                       "
 queue "//************************************************************"
 queue "//CHECKIT  IF ("ca7_step3".RUN AND" ca7_step3".RC GT 0) THEN  "
 queue "//SPWARN   EXEC @SPWARN                                       "
 queue "//CHECKIT  ENDIF                                              "
 queue "//*-----------------------------------------------------------"
 queue "//** END   OF DEMAND FOR" right(trigger,8)    "- DLM="dlm
 queue "//*-----------------------------------------------------------"
 queue "//*                                                           "

return /* ca7_demand: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT non ISPF            */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg('off')

 qstack /* query how many stacks there are                           */
 do i = 1 to rc /* loop through the number of open stacks            */
   address tso 'delstack' /* Clear down the nested stacks            */
 end /* i = 1 to rc */

 z = msg('on')

 if return_code < 12 | return_code > 4095 then return_code = 12

exit return_code

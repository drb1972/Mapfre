/*-----------------------------REXX----------------------------------*\
 *  This Rexx is used by the Endevor archiving process and is        *
 *  run during the Rjob execution to convert a package detail        *
 *  report into Archive SCL, plus the Restore from archive SCL       *
 *  in case a Package Backout is required.                           *
 *                                                                   *
 *  INPUT PARMs                                                      *
 *   SHIPHLQC: Endevor high level qualifier                          *
 *   CCID    : Endevor CCID                                          *
 *                                                                   *
 *  INPUT DDNAMEs                                                    *
 *   REPIN   : Package Detail report (BSTRPT)                        *
 *                                                                   *
 *  OUTPUT DDNAMEs                                                   *
 *   REPOUT  : Endevor SCL to Archive elements targeted              *
 *             for deleteion.                                        *
 *                                                                   *
 *   RSTSCL  : Endevor SCL to Restore Elements from ARCH env         *
 *             should a Package Backout be required.                 *
 *                                                                   *
 *   PKGSCL  : Package SCL to build, Cast and Execute a package      *
 *             for the above Restore SCL.                            *
 *                                                                   *
 *   COPYJCL : Batch Job to Copy Archived data from the temporary    *
 *             archive (PGEV.SHIP.Cnnnnnnn.ARCHIVE) to the ARCH      *
 *             environment.                                          *
 *             Includes log of Elements deleted to be written to     *
 *             PREV.PROD.DELETE.LOG                                  *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

parse arg shiphlqc ccid

/* Read all lines from package detail report                         */
"execio * diskr REPIN (stem rep. finis"
if rc ^= 0 then call exception rc 'DISKR of REPIN failed'

archive = 4 /* Set default rc to 4 - if no deletes found RC will be 4*/
dl      = 0
al      = 0
xl      = 0
tl      = 0

do c = 1 to rep.0 while subword(rep.c,2,1) ^= 'PKMR401I'
  /* Find the CAST Userid which is on the APPROVED line.             */
  if cuser = 'CUSER' & pos('APPROVED',rep.c) = 24 then
    cuser = substr(rep.c,81,8)

  /* Skip thro loop until we find the element lock messages          */
  if word(rep.c,2) = 'C1G0000I' then
    ele  = word(rep.c,4)

  if word(rep.c,2) = 'C1G0506I' then do
    sys   = word(rep.c,6)
    stage = word(rep.c,10)
    typ   = word(rep.c,12)

    /* Find Delete action details and obtain element details.        */
    if stage = 'P' then do /* Its a DELETE                           */

      /* First time thro build the SCL set statements.               */
      if archive = 4 then do
        call build_setscl
        archive = 0
      end /* archive = 4 */

      /* Build Archive SCL for current element.                      */
      call add_arcscl("ARCHIVE ELEMENT")
      call add_arcscl(" '"ele"'")
      call add_arcscl(" FROM SYS" sys "SUB" sys"1 TYPE" typ ".")

      /* Build Transfer To ARCH SCL for current element.             */
      call add_trnscl("TRANSFER ELEMENT")
      call add_trnscl(" '"ele"'")
      call add_trnscl(" FROM SYS" sys "SUB" sys"1 TYPE" typ ".")

      /* Build Restore SCL for current element.                      */
      call add_rstscl("TRANSFER ELEMENT")
      call add_rstscl(" '"ele"'")
      call add_rstscl(" FROM SYS" sys "SUB" sys"1 TYPE" typ ".")

      /* Write message to ISPF log (dunno why?)                      */
      say "Element" ele "type" typ "selected for archiving"

      /* Build DELETE LOG entry                                      */
      Call build_dellog
    end /* stage = 'P' */
  end /* word(rep.c,2) = 'C1G0506I' */
end /* do c = 1 to rep.0 while subword(rep.c,2,1) ^= 'PKMR401I' */

/* If archive RC still 4, then no Deletes in package so Exit.        */
if archive = 4 then exit archive

"execio * diskw REPOUT (finis stem arcscl.)"
if rc ^= 0 then call exception rc 'DISKW of REPOUT failed'

"execio * diskw RSTSCL (finis stem rstscl.)"
if rc ^= 0 then call exception rc 'DISKW of RSTSCL failed'

call package_scl /* Build and write Package SCL                      */

call archive_jcl /* Build and write BATCH COPY job.                  */

exit archive

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Build BATCH COPY job and place in stem variables (ajcl.)          */
/* Also write to ISPF log this qwerky little message below.          */
/*-------------------------------------------------------------------*/
archive_jcl:
 say "                                                           "
 say " The above element(s) that you have deleted will be        "
 say " archived to the ARCH environment in the" sys "system.     "

 ajcl.1  = "//EVGARCHI JOB 0,CLASS=N,MSGCLASS=Y,                      "
 ajcl.2  = "//             SCHENV=CMAN                                "
 ajcl.3  = "/*JOBPARM LINES=9999                                      "
 ajcl.4  = "//*--------------------------------------------------     "
 ajcl.5  = "//*                                                       "
 ajcl.6  = "//* JOB PRODUCED BY PACKSCAN REXX IN JOB R"right(ccid,7)
 ajcl.7  = "//*                                                       "
 ajcl.8  = "//* ENDEVOR PRODUCTION RELEASE: ENDEVOR ARCHIVE JOB       "
 ajcl.9  = "//*                                                       "
 ajcl.10 = "//* CHANGE: "ccid
 ajcl.11 = "//*                                                       "
 ajcl.12 = "//*--------------------------------------------------     "
 ajcl.13 = "//*  TRANSFER ARCHIVED ELEMENTS TO ARCH ENVIRONMENT       "
 ajcl.14 = "//*--------------------------------------------------     "
 ajcl.15 = "//NDVRBAT  EXEC PGM=NDVRC1,DYNAMNBR=1500,                 "
 ajcl.16 = "//             PARM='C1BM3000'                            "
 ajcl.17 = "//PSPOFF   DD DUMMY                                       "
 ajcl.18 = "//SORTWK01 DD SPACE=(CYL,(15,15))                         "
 ajcl.19 = "//SORTWK02 DD SPACE=(CYL,(15,15))                         "
 ajcl.20 = "//SORTWK03 DD SPACE=(CYL,(15,15))                         "
 ajcl.21 = "//SORTWK04 DD SPACE=(CYL,(15,15))                         "
 ajcl.22 = "//C1SORTIO DD SPACE=(CYL,(50,50)),                        "
 ajcl.23 = "//             RECFM=VB,LRECL=32760                       "
 ajcl.24 = "//APIPRINT DD SYSOUT=*                                    "
 ajcl.25 = "//HLAPILOG DD SYSOUT=*                                    "
 ajcl.26 = "//C1MSGS1  DD SYSOUT=*                                    "
 ajcl.27 = "//C1MSGS2  DD SYSOUT=*                                    "
 ajcl.28 = "//C1PRINT  DD SYSOUT=*,RECFM=FBA,LRECL=133                "
 ajcl.29 = "//SYSPRINT DD SYSOUT=*                                    "
 ajcl.30 = "//SYSUDUMP DD SYSOUT=C                                    "
 ajcl.31 = "//SYSOUT   DD SYSOUT=*                                    "
 ajcl.32 = "//SYMDUMP  DD DUMMY                                       "
 ajcl.33 = "//ARCHIVE  DD DSN="shiphlqc".ARCHIVE,DISP=SHR"
 ajcl.34 = "//BSTIPT01 DD *                                           "
 count   = 34

 do i = 1 to trnscl.0
   count      = count + 1
   ajcl.count = trnscl.i
 end /* do i = 1 to trnscl.0                                         */

 count      = count + 1
 ajcl.count = "//*                                                    "
 count      = count + 1
 ajcl.count = "//CHECKIT IF RC GT 8 THEN                              "
 count      = count + 1
 ajcl.count = "//@SPWARN EXEC @SPWARN                                 "
 count      = count + 1
 ajcl.count = "//CHECKIT ENDIF                                        "
 count      = count + 1
 ajcl.count = "//*                                                    "
 count      = count + 1
 ajcl.count = "//*--------------------------------------------------  "
 count      = count + 1
 ajcl.count = "//*  DELETE INTERMEDIATE ARCHIVE FILE                  "
 count      = count + 1
 ajcl.count = "//*--------------------------------------------------  "
 count      = count + 1
 ajcl.count = "//ARCHDEL EXEC PGM=IEFBR14                             "
 count      = count + 1
 ajcl.count = "//DD1      DD DSN="shiphlqc".ARCHIVE,"
 count      = count + 1
 ajcl.count = "//            DISP=(OLD,DELETE)                        "
 count      = count + 1
 ajcl.count = "//*                                                    "
 count      = count + 1
 ajcl.count = "//CHECKIT IF ARCHDEL.RC GT 4 THEN                      "
 count      = count + 1
 ajcl.count = "//@SPWARN EXEC @SPWARN                                 "
 count      = count + 1
 ajcl.count = "//CHECKIT ENDIF                                        "
 count      = count + 1
 ajcl.count = "//*                                                    "
 count      = count + 1
 ajcl.count = "//UPDLOG EXEC PGM=IEBGENER                             "
 count      = count + 1
 ajcl.count = "//SYSPRINT DD SYSOUT=*                                 "
 count      = count + 1
 ajcl.count = "//SYSUT1 DD  *                                         "

 do i = 1 to dellog.0
   count      = count + 1
   ajcl.count = dellog.i
 end /* do i = 1 to dellog.0                                         */

 count      = count + 1
 ajcl.count = "//SYSUT2   DD  DISP=MOD,DSN=PREV.PROD.DELETE.LOG       "
 count      = count + 1
 ajcl.count = "//SYSIN    DD DUMMY                                    "
 count      = count + 1
 ajcl.count = "//*                                                    "
 count      = count + 1
 ajcl.count = "//CHECKIT  IF UPDLOG.RC NE 0 THEN                      "
 count      = count + 1
 ajcl.count = "//@SPWARN  EXEC @SPWARN                                "
 count      = count + 1
 ajcl.count = "//CHECKIT  ENDIF                                       "

 "execio" count "diskw COPYJCL (finis stem ajcl.)"
 if rc ^= 0 then call exception rc 'DISKW of COPYJCL failed'

return /* archive_jcl:                                               */

/*-------------------------------------------------------------------*/
/* Build and write Package SCL to build, cast and execute an         */
/* emergency Package to process the Restore SCL.                     */
/*-------------------------------------------------------------------*/
package_scl:
 pscl.1  = "DELETE PACKAGE 'PMFBCH"ccid"' ."
 pscl.2  = "DEFINE PACKAGE 'PMFBCH"ccid"'"
 pscl.3  = '  DESCRIPTION "RESTORE DELETED ELEMENTS"'
 pscl.4  = "  IMPORT SCL FROM DDNAME SCL"
 pscl.5  = "          DO NOT APPEND"
 pscl.6  = "  OPTIONS EMERGENCY PACKAGE"
 pscl.7  = "          SHARABLE PACKAGE"
 pscl.8  = "          BACKOUT IS ENABLED"
 pscl.9  = "          EXECUTION WINDOW FROM" Left(date('E'),2)||,
          translate(Left(date('M'),3))||Right(date('E'),2),
          "00:00 TO 31DEC79 00:00"
 pscl.10 = "  NOTES=('BATCH AUTOMATION - RECOVER ELEMENTS FOR BACKOUT')"
 pscl.11 = " ."
 pscl.12 = " CAST    PACKAGE 'PMFBCH"ccid"' ."
 pscl.13 = " EXECUTE PACKAGE 'PMFBCH"ccid"' ."
 pscl.0 = 13

 "execio * diskw PKGSCL (finis stem pscl.)"
 if rc ^= 0 then call exception rc 'DISKW of PKGSCL failed'

return /* package_scl:                                               */

/*-------------------------------------------------------------------*/
/* Build the SET SCL statements that need to be at the front         */
/* of both the Archive and Restore SCL deck.                         */
/*-------------------------------------------------------------------*/
Build_setscl:
 call add_arcscl("SET TO DDNAME ARCHIVE .           ")
 call add_arcscl("SET OPTIONS BYPASS ELEMENT DELETE ")
 call add_arcscl("     COMMENT 'DELETED'            ")
 call add_arcscl("     CCID    '"ccid"' .           ")
 call add_arcscl("SET FROM ENV PROD STAGE NUMBER 2 .")

 call add_rstscl("SET TO ENV PROD STAGE NUMBER 2 .                ")
 call add_rstscl("SET OPTIONS BYPASS GENERATE PROCESSOR SIGNIN    ")
 call add_rstscl("     IGNORE GENERATE FAILED OVERRIDE SIGNOUT    ")
 call add_rstscl("     BYPASS ELEMENT DELETE SYNCHRONIZE          ")
 call add_rstscl("     COMMENT 'RESTORE ELEMENT, "ccid"P BACK OUT'")
 call add_rstscl("     CCID    'NDVR#SUPPORT' WITH HISTORY .      ")
 call add_rstscl("SET FROM ENV ARCH STAGE NUMBER 2 .              ")

 call add_trnscl("SET TO ENV ARCH STAGE NUMBER 2 .            ")
 call add_trnscl("SET OPTIONS BYPASS GENERATE PROCESSOR SIGNIN")
 call add_trnscl("     OVERRIDE SIGNOUT SYNCHRONIZE           ")
 call add_trnscl("     COMMENT 'ARCHIVE FROM PROD "ccid"P'    ")
 call add_trnscl("     CCID    'NDVR#SUPPORT' WITH HISTORY .  ")
 call add_trnscl("SET FROM DDNAME ARCHIVE                     ")
 call add_trnscl("         ENV PROD STAGE NUMBER 2 .          ")

return /* Build_setscl:                                              */

/*-------------------------------------------------------------------*/
/* Add the SCL statement to the next stem variable. (ARCSCL.)        */
/*-------------------------------------------------------------------*/
add_arcscl:
 parse arg arc_scl
 al        = al + 1
 arcscl.al = arc_scl
 arcscl.0  = al

return /* add_arcscl:                                                */

/*-------------------------------------------------------------------*/
/* Add the SCL statement to the next stem variable. (RSTSCL.)        */
/*-------------------------------------------------------------------*/
add_rstscl:
 parse arg rst_scl
 xl        = xl + 1
 rstscl.xl = rst_scl
 rstscl.0  = xl

return /* add_rstscl:                                                */

/*-------------------------------------------------------------------*/
/* Add the SCL statement to the next stem variable. (TRNSCL.)        */
/*-------------------------------------------------------------------*/
add_trnscl:
 parse arg trn_scl
 tl        = tl + 1
 trnscl.tl = trn_scl
 trnscl.0  = tl

return /* add_trnscl:                                                */

/*-------------------------------------------------------------------*/
/* Add the DELLOG entry to the next stem variable. (DELLOG.)         */
/*-------------------------------------------------------------------*/
build_dellog:
 if length(ele) > 8 then do
   dl        = dl + 1
   dellog.dl = ele
   dl        = dl + 1
   dellog.dl = "        " sys left(typ,8) "'"date()"' '"time() || ,
               "' '"ccid"' '"strip(cuser)"'"
 end /* if length(ele) > 8 then do                                   */

 else do
   dl        = dl + 1
   dellog.dl = left(ele,8) sys left(typ,8)  "'"date()"' '"time() || ,
               "' '"ccid"' '"strip(cuser)"'"
 end /* else do                                                      */

 dellog.0 = dl

return /* build_dellog:                                              */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso 'delstack' /* Clear down the stack                      */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code

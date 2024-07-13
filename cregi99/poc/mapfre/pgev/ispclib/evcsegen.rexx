/***rexx*********************************************************/      00010000
/** PROGRAM: EVCSEGEN                                          **/      00020000
/** Author: Stuart Ashby                                       **/      00030000
/** DATE: Started 01/11/2005                                   **/      00040000
/**                                                            **/      00050000
/** Function: This rexx uses the Endevor API to show where an  **/      00060000
/** element is in Endevor for casegen processing               **/      00070000
/****************************************************************/      00080000
                                                                        00090000
trace o                                                                 00100000
x=msg(off)                                                              00110000
uid  = sysvar(sysuid)                                                   00120000
hlq  = sysvar(syspref)                                                  00120000
                                                                        00140000
/* set up ISPTABL dataset */
address ispexec "libdef isptabl dataset id('TTYY.CASE.ISPTABL') stkadd"
if RC ^= 0 then
  say 'Tlib LIBDEF override failed'

panel:                                                                  00150000
                                                                        00270000
/* Display input panel */                                               00310000
zcmd = ''                                                               00320000
w = ''                                                                  00320000
address ispexec                                                         00330000
    "DISPLAY PANEL(EVCSEGEN)"                                           00340000
                                                                        00350000
 /* If rc 8 then PF3 was pressed */                                     00360000
 if rc = 8 then exit                                                    00380000
                                                                        00410000
 if rc = 0 then do                                                      00470000
"VGET (TELM) PROFILE"                                                   00480024
                                                                        01750000
/* Allocate ddnames required by API */
   address tso                                                          01960000
       "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR)"                01970000
       "DEL 'TTYY."UID".ENDEVOR.API'"                                   01980000
       "ALLOC DD(SYSOUT) SYSOUT"                                        01990000
       "ALLOC DD(SYSPRINT) SYSOUT"                                      02000000
       "ALLOC DD(BSTERR) SYSOUT"                                        02010000
       "ALLOC DD(APIMSGS) LRECL(133) RECFM(F B) BLKSIZE(0)"             02020000
                                                                        02030000
       "ALLOC DD(APIEXTR) DA('TTYY."UID".ENDEVOR.API') LRECL(2048) NEW, 02040000
       RECFM(V B) DSORG(PS) BLKSIZE(22800) SPACE(75,75) TRACKS REUSE"   02050000
                                                                        02060000
       "ALLOC FI(SYSIN) SPACE(1,1) TRACKS,                              02070000
                         LRECL(80) RECFM(F) BLKSIZE(80) REUSE"          02080000
                                                                        02090000
 /* build up the sysin command */                                       02100000
   telm = left(telm,10)
                                                                        02110000
command.1 = 'AACTL APIMSGS APIEXTR'                                     02120000
command.2 = 'ALELMPAA UNIT    ALJ      LJ1     'telm'DIF'               02130024
command.3 = 'RUN'                                                       02140000
command.4 = 'AACTLY'                                                    02150000
command.5 = 'RUN'                                                       02160000
command.6 = 'QUIT'                                                      02170000
                                                                        02180000
 /* write the sysin */                                                  02220000
                                                                        02230000
   "EXECIO * DISKW SYSIN (STEM COMMAND. FINIS"                          02240000
                                                                        02250000
/* Call Endevor assuming that NDVRC1 is already active */               02260000
 address tso                                                            02280000
    "CALL 'SYSNDVR.CAI.AUTHLIB(ENTBJAPI)'"                              02290009

/* Check return code and execute Endevor from a link listed library     02310000
   if the previous call fails rc 12 */                                  02320000
                                                                        02330000
  select                                                                02340000
    when rc = 0 then do                                                 02350000
       "FREE DD(SYSOUT)"                                                02360000
       "FREE DD(SYSPRINT)"                                              02370000
       "FREE DD(BSTERR)"                                                02380000
       "FREE DD(APIMSGS)"                                               02390000
       "FREE DD(APIEXTR)"                                               02400000
       "FREE DD(SYSIN)"                                                 02410000
                     end /* end do */                                   02420000
    when rc = 12 then do                                                02430000
     rcode = 12                                                         02440000
     "CALL 'SYSNDVR.CAI.AUTHLIB(NDVRC1)' 'ENTBJAPI'"                    02450009
     rcode = rcode + rc                                                 02460000
       "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR,SYSIN)"          02470000
                      end /* end do */                                  02480000
    otherwise do                                                        02490000
              say 'RETURN CODE IS' rc                                   02500000
              signal the_end                                            02510000
              end /* end do */                                          02520000
  end /* end select */                                                  02530000

/* sort the API extract into stage id order */                          02740000
                                                                        02760000
/* Build the sort statement */
sort.1 = " SORT FIELDS=(65,1,CH,A,57,8,CH,A)"                           02770000
                                                                        02790000
/* Delete files that may be knocking around from the last run */
       "DEL 'TTYY."UID".API.SORTED'"                                    02800000
       "DEL 'TTYY."UID".SORT.SYSIN'"                                    02810000
/* Allocate the ddnames required */
       "ALLOC DD(SORTIN) DA('TTYY."UID".ENDEVOR.API') SHR REU"          02820000
                                                                        02830000
       "ALLOC DD(SORTOUT) DA('TTYY."UID".API.SORTED') LRECL(2048) NEW,  02840000
       RECFM(V B) DSORG(PS) BLKSIZE(22800) SPACE(75,75) TRACKS REUSE"   02850000
                                                                        02860000
       "ALLOC DD(SYSIN) DA('TTYY."UID".SORT.SYSIN') LRECL(80) NEW,
       RECFM(F B) DSORG(PS) BLKSIZE(0) SPACE(1,1) TRACKS REUSE"
                                                                        02860000
       "ALLOC DD(SYSOUT) SYSOUT"                                        02900000
                                                                        02910000
 /* write the sort sysin */                                             02920000
   "EXECIO * DISKW SYSIN (STEM SORT. FINIS"                             02940000
                                                                        02930000
 /* run the sort */
   address ispexec                                                      02990000
       "SELECT PGM(SORT)"                                               03000000
                                                                        03010000
            indsn = "TTYY."uid||".API.SORTED"                           03020000
                          end /* end do */                              03030000
 if rc ^= 0 then do                                                     03040000
    say "Sort failed, contact Endevor Support. +44 (0)123 963 8560"     03050000
                    signal the_end                                      03060000
                 end /* End do */                                       03070000
            else do /* tidy up after sort */                            03080000
                    address tso                                         03090000
                       "FREE DD(SYSOUT)"                                03100000
                       "FREE DD(SYSIN)"                                 03110000
                       "FREE DD(SORTIN)"                                03120000
                       "FREE DD(SORTOUT)"                               03130000
                       "DEL 'TTYY."UID".SORT.SYSIN'"                    03140000
                         icnt = 1 /* set initial value for counter */   03150000
                         ocnt = 1 /* set initial value for counter */   03160000
                 end /* end do */                                       03170000
                                                                        03180000
/* Load the API extracted records in to a table */                      03190000
   address tso                                                          03200000
                                                                        03210000
      "ALLOC DD(INFILE) DA('"indsn"') SHR"                              03220000
                                                                        03230000
/* Read in the API extract file */                                      03240000
      "EXECIO * DISKR INFILE (STEM dslist. FINIS)"                      03250000

/* if the api extract file is empty, then set a message and go back
   to the primary panel */
if dslist.0 = 0 then do
messinv = 'No elements found, check the spelling. If it is'             00710000
messinv2 = 'correct, make sure Endevor is started in your TSO session'  00710000
                       "ISPEXEC ADDPOP"                                 00720000
                         "ISPEXEC DISPLAY PANEL(EVCSEGN3)"              00730000
                       "ISPEXEC REMPOP"                                 00740000
                 signal panel /* display primary panel for correction */00760000
                     end /* end do */
                                                                        03260000
/* Create a temp table */                                               03270000
"ISPEXEC TBCREATE "uid" NAMES(W ENV SYS SUB ELE TYP STG PRO CCI COM)
 WRITE"
      do until icnt > dslist.0                                          03290000
                                                                        03300000
/* Build up the column data */                                          03310000
       env = substr(dslist.icnt,15,4)                                   03330000
       sys = substr(dslist.icnt,23,2)                                   03340000
       sub = substr(dslist.icnt,31,3)                                   03350000
       ele = substr(dslist.icnt,39,8)                                   03360000
       typ = substr(dslist.icnt,49,8)                                   03370000
       stg = substr(dslist.icnt,57,1)                                   03380000
       pro = substr(dslist.icnt,71,8)                                   03381040
       cci = substr(dslist.icnt,156,12)                                 03390000
       com = substr(dslist.icnt,168,40)                                 03400000
                                                                        03410000
       ele = strip(ele)
       typ = strip(typ)
                                                                        03410000
/* Add the data to a row in the table */                                03480000
 "ISPEXEC TBADD "uid                                                    03490000
 icnt = icnt + 1                                                        03500000
 ocnt = ocnt + 1                                                        03510000
      end /* end do until icnt > dslist.0 */                            03520000
"ISPEXEC TBTOP "uid                                                     03530000
"FREE DD(INFILE)"                                                       03540000
                                                                        03550000
/* Set the panel return code to zero */                                 03560000
prc = 0                                                                 03570000
cursor = 'CURSOR( )'                                                    03580000
csrrow = 'CSRROW(1)'                                                    03590000
message = 'MSG( )'                                                      03600000
                                                                        03610000
/* Display the table in scrollable panel format         */              03620000
  "ISPEXEC TBTOP "uid                                                   03630000
                                                                        03640000
scl_select:                                                             03650037
                                                                        03660037
/* Do whilst the selection panel does not have PF3 entered       */     03670000
     do while prc ^= 8                                                  03680000
                                                                        03690000
     "ISPEXEC TBDISPL "uid" PANEL(EVCSEGN2)" message cursor csrrow ,    03700000
        "AUTOSEL(NO) POSITION(CRP)"                                     03710000
                                                                        03720000
/* save the panel return code & get the line command in upper case */   03730000
        prc = rc                                                        03740000
        upper zcmd                                                      03750000
        cursor = 'CURSOR( )'                                            03770000
        csrrow = 'CSRROW(1)'                                            03780000
                                                                        03790000
 select                                                                 03800000
    when zcmd = 'BACK' then do                                          03810000
                              call tidy_up                              03820000
                                signal panel                            03840000
                            end /* end do */                            03850000
    when zcmd = 'END' then do                                           03860000
                               signal the_end                           03920000
                           end /* end do */                             03930000
    when zcmd = 'SUB' then do                                           03860000
                          /* Allocate ISPFILE for FTINCL statements */
                          dsname = hlq||'.'||uid||'.EVCSEGEN.JCL'
                          ADDRESS TSO
                           "ALLOC DA('"dsname"') NEW CATALOG SPACE(5,5),
                            RECFM(F,B) LRECL(80) BLKSIZE(0) DSORG(PS),
                            F(ISPFILE)"


                            /* Set table to the top */
                            "ISPEXEC TBTOP "uid

                                /* get the number of rows */
                     "ISPEXEC TBQUERY "uid" ROWNUM(QROWS) POSITION(CRP)"

            /* counter is used to test how many elements are selected */
                                counter = 0

                          /* loop for the number of rows in the table */
                              do i = 1 to qrows

                           /* From the top use TBSKIP to get next row */
                                "ISPEXEC TBSKIP "uid

/* Use TBGET to load table row, change w to be selected and put record
   the record back updated */
                "ISPEXEC TBGET "uid
                 if w = '*Selected' then do
                                          counter = counter + 1
                                           /* build the JCL */
                                           "ISPEXEC FTOPEN"             03870000
                                            "ISPEXEC FTINCL EVCSEGEN"   03920000
                                             "ISPEXEC FTCLOSE"
                                              ADDRESS TSO
                                            /* submit the JCL */
                                           "SUBMIT '"dsname"'"
                                           "FREE F(ISPFILE)"
                             "DEL '"dsname"'" /* Delete the ISPFILE */

 if rc = 0 then say 'Job TTYYCSEG submitted for processing'
  else say 'Submit failed, contact Endevor Support +44 (0)123 963 8560'

                                         end /* if w = '*selected' */

                              end /* do i = 1 to qrows */

                            if counter = 0 then do
                                              message = 'MSG(CSEG002E)'
                                               signal scl_select        03970000
                                                end /* end do */

                             call tidy_up                               02800000
                               signal panel
                           end /* end do */                             03930000
    when zcmd = 'RETURN' then do                                        03940000
                                call tidy_up                            02800000
                                  signal panel                          03970000
                              end /* end do */                          03980000
    otherwise nop                                                       08420000
 end /* end select */                                                   08430000
                                                                        08960006
/* loop while there are selected rows */
    do while ZTDSELS > 0

select
    when y = 'X' then do
                        w = '         '
                         "ISPEXEC TBPUT "uid
                         cnt = strip(crp,l,0)
                         csrrow = 'CSRROW('crp')'
                         cursor = 'CURSOR(Y)'
                          message = 'MSG(CSEG002I)'
                      end
    when y = 'S' then do
                        w = '*Selected'
                         "ISPEXEC TBPUT "uid
                         cnt = strip(crp,l,0)
                         csrrow = 'CSRROW('crp')'
                         cursor = 'CURSOR(Y)'
                         message = 'MSG(CSEG001I)'
                      end
    otherwise do                                                        08420000
                 cursor = 'CURSOR(Y)'
              end /* end do */                                          03980000

end /* end select */
                                                                        08960006
 if ztdsels > 1 then do
               "ISPEXEC TBDISPL "uid cursor csrrow "POSITION(CRP)"
                     end /*end do */
                else
                  ztdsels = 0

    end /* end do while ztdsels > 0 */
                                                                        08960006
end /* do while */
 call tidy_up
 signal panel

/* SUBROUTINES */

tidy_up:
/* Close the ISPF table, and delete the API datasets */
 "ISPEXEC TBCLOSE "uid                                                  03950000
 "ISPEXEC TBERASE "uid                                                  03950000
   "DEL 'TTYY."UID".ENDEVOR.API'"                                       01980000
     "DEL 'TTYY."UID".API.SORTED'"                                      02800000
 return

the_end:                                                                08970000
                                                                        08980000
    "ISPEXEC TBCLOSE "uid                                               09140000
    "ISPEXEC TBERASE "uid                                               09140000
address TSO
       "DEL 'TTYY."UID".ENDEVOR.API'"                                   01980000
       "DEL 'TTYY."UID".API.SORTED'"                                    02800000
 exit                                                                   09160000

/*--------------------------REXX----------------------------*\
 *  Create DB2 parameters based on BIND processor group     *
 *                                                          *
 *----------------------------------------------------------*
 *                                                          *
 *  This produces standard GSI bind parameter with the      *
 *  following exceptions:                                   *
 *                                                          *
 *  Character 6 = 'P' - Extra production bind to owner      *
 *  DLIUK & qualifier DLPUK, collection CPRG                *
 *                                                          *
 *  DL international - Extra production bind for training:  *
 *  Italy owner = IDTIT, qual = IDTIT                       *
 *  Germany owner = LDTDE, qual = LDTDE                     *
 *  Collections are suffixed by a T0 (e.g. CIRGT0)          *
 *                                                          *
 *  Off host binds have a collection suffix of OH           *
 *                                                          *
 *  Char 4 = Z - RBS only - single bind to qualifier RBSQ   *
 *  in prod, normal RBS binds in dev (used in the BB system)*
 *                                                          *
 *  Char 4 = W - GRP only - single bind to qualifier GRPHW0 *
 *  in prod, normal GRP binds in dev (For Peoplesoft)       *
 *                                                          *
 *  Char 4 = Q or P - Extra bind in dev & prod. Q suffix on *
 *  the collection and qualifier in prod, Q replaces the    *
 *  environment character in dev                            *
 *                                                          *
 *  Char 4 = V - If it's a KUBIE bind then do an extra prod *
 *  bind with a V suffix on the collection and qualifier    *
 *                                                          *
 *  Char 4 = 1 - Single bind with qualifier suffix <sys>1   *
 *  in prod, normal binds in dev                            *
 *                                                          *
 *  Char 4 = 2 - Single bind with qualifier suffix <sys>2   *
 *  in prod, normal binds in dev                            *
 *                                                          *
 *  Char 4 = 3 - Single bind with qualifier suffix <sys>3   *
 *  in prod, normal binds in dev                            *
\*----------------------------------------------------------*/
trace n
arg bindpg c1en c1su c1ty

sysid = mvsvar(sysname) /* System id */
if sysvar('SYSENV') ^= 'FORE' then
  do
    say
    say 'DB2PARMS:' DATE() TIME() 'PROCESSING ON' sysid
    say 'DB2PARMS:  *** INPUT PARMS ***'
    say 'DB2PARMS:'
    say 'DB2PARMS:  BINDPG.........'bindpg
    say 'DB2PARMS:  C1EN...........'c1en
    say 'DB2PARMS:  C1SU...........'c1su
    say 'DB2PARMS:  C1TY...........'c1ty
    say 'DB2PARMS:'
    say 'DB2PARMS:  *** END OF INPUT PARMS ***'
  end

/* Set variables */
call Set_variables
/* Validate variables and processor group */
call Validate

if sysvar('SYSENV') ^= 'FORE' then
  do
    say 'DB2PARMS:'
    say 'DB2PARMS:  *** OUTPUT PARMS ***'
  end

/* Set the Datasharing group & process characters 6_7 for each group. */
/* This will build n sets of DB2 paramters for use by the calling     */
/* REXX.                                                              */
do i = 1 to words(dbgrp.pgchr2) /* Loop for each group               */
  dbsub33  = word(dbgrp.pgchr2,i)
  dbsub = dbpref || dbsub33 || '0'
  do z = 1 to words(instances.pgchr6_7) /* Loop for each instance    */
    db2inst = word(instances.pgchr6_7,z)
    call process
    /* If its a prod DLI bind then we have to do an extra            */
    /* bind to the training collection in the same group.            */
    if c1en = 'PROD' & pos(db2inst,'IL') > 0 then
      call process 'DLITRAIN'
    /* If character 4 is a Q or P then we do an extra bind           */
    /* with a Q. (P is the Stored procedure version of Q)            */
    if pgchr4 = 'Q' | pgchr4 = 'P' then
      call process 'Q'
    /* If character 4 is a V then we do an extra KUBIE  bind         */
    /* with a V suffix.                                              */
    if pgchr4 = 'V' & db2inst = 'K' & c1en = 'PROD' then
      call process 'V'
  end /* do z = 1 to words(instances.pgchr6_7)                       */
end /* do i = 1 to words(dbgrp.pgchr2)                               */

if sysvar('SYSENV') ^= 'FORE' then
  do
    say 'DB2PARMS:'
    say 'DB2PARMS:  *** END OF OUTPUT PARMS ***'
    say 'DB2PARMS:' DATE() TIME()
    say
  end

exit 0

/*---------------------- S U B R O U T I N E S ----------------------*/

/* +---------------------------------------------------------------+ */
/* !  Set Variables                                                ! */
/* +---------------------------------------------------------------+ */
Set_variables:

 pgchr1   = substr(bindpg,1,1)
 pgchr2   = substr(bindpg,2,1)
 pgchr3   = substr(bindpg,3,1)
 pgchr4   = substr(bindpg,4,1)
 pgchr5   = substr(bindpg,5,1)
 pgchr6_7 = substr(bindpg,6,2)
 pgchr8   = substr(bindpg,8,1)

 db2proj  = left(c1su,2)
 db2clone = right(c1su,1)

 /* PROCESSOR GROUP CHARACTER 2 */

 /* Set the db2 datasharing group(s) */
 /* N.B. If adding/changing position 2 characters then you must also
      change BINDPARM, DBIND, GBIND & MBIND, & DB2TAB
      generate DDB2SP, GDB2SP, MDB2SP
    And for new datasharing groups..
      add shipment rules and change DB2URLKUP                        */
 dbgrp.A = 'A'                 /* See note above */
 dbgrp.B = 'B'                 /* See note above */
 dbgrp.C = 'C'                 /* See note above */
 dbgrp.D = 'D'                 /* See note above */
 dbgrp.E = 'E'                 /* See note above */
 dbgrp.F = 'F'                 /* See note above */
 dbgrp.G = 'G'                 /* See note above */
 dbgrp.H = 'D'                 /* See note above */
 dbgrp.K = 'K'                 /* See note above */
 dbgrp.L = 'L'                 /* See note above */
 dbgrp.1 = 'A B C D E F G K L' /* See note above */
 dbgrp.2 = 'A B'               /* See note above */

 /* PROCESSOR GROUP CHARACTER 3 */

 /* Isolation             Degree                Release              */
 dbiso.A = 'CS'        ;  dbdeg.A = 'ANY'    ;  dbrel.A = 'COMMIT'
 dbiso.B = 'CS'        ;  dbdeg.B = '1'      ;  dbrel.B = 'COMMIT'
 dbiso.D = 'CS'        ;  dbdeg.D = '1'      ;  dbrel.D = 'DEALLOCATE'
 dbiso.E = 'CS'        ;  dbdeg.E = '1'      ;  dbrel.E = 'COMMIT'
 dbiso.F = 'CS'        ;  dbdeg.F = '1'      ;  dbrel.F = 'COMMIT'
 dbiso.K = 'CS'        ;  dbdeg.K = '1'      ;  dbrel.K = 'COMMIT'
 dbiso.R = 'RR'        ;  dbdeg.R = '1'      ;  dbrel.R = 'COMMIT'
 dbiso.T = 'CS'        ;  dbdeg.T = '1'      ;  dbrel.T = 'COMMIT'
 dbiso.U = 'UR'        ;  dbdeg.U = '1'      ;  dbrel.U = 'COMMIT'
 dbiso.V = 'CS'        ;  dbdeg.V = '1'      ;  dbrel.V = 'COMMIT'
 dbiso.X = 'CS'        ;  dbdeg.X = '1'      ;  dbrel.X = 'COMMIT'
 dbiso.Y = 'CS'        ;  dbdeg.Y = '1'      ;  dbrel.Y = 'COMMIT'

 /* Reopt                 Validate              Keepdynamic        */
 dbreo.A = 'NOREOPT'   ;  dbval.A = 'BIND'   ;  dbkdyn.A = 'NO'
 dbreo.B = 'NOREOPT'   ;  dbval.B = 'BIND'   ;  dbkdyn.B = 'NO'
 dbreo.D = 'NOREOPT'   ;  dbval.D = 'BIND'   ;  dbkdyn.D = 'NO'
 dbreo.E = 'NOREOPT'   ;  dbval.E = 'BIND'   ;  dbkdyn.E = 'YES'
 dbreo.F = 'NOREOPT'   ;  dbval.F = 'BIND'   ;  dbkdyn.F = 'NO'
 dbreo.K = 'NOREOPT'   ;  dbval.K = 'BIND'   ;  dbkdyn.K = 'YES'
 dbreo.R = 'NOREOPT'   ;  dbval.R = 'BIND'   ;  dbkdyn.R = 'NO'
 dbreo.T = 'NOREOPT'   ;  dbval.T = 'RUN'    ;  dbkdyn.T = 'NO'
 dbreo.U = 'NOREOPT'   ;  dbval.U = 'BIND'   ;  dbkdyn.U = 'NO'
 dbreo.V = 'REOPT'     ;  dbval.V = 'BIND'   ;  dbkdyn.V = 'NO'
 dbreo.X = 'NOREOPT'   ;  dbval.X = 'BIND'   ;  dbkdyn.X = 'NO'
 dbreo.Y = 'NOREOPT'   ;  dbval.Y = 'BIND'   ;  dbkdyn.Y = 'NO'

 /* Dynamicrules            Blocking             Currentdata
                            off host only        production only     */
 dbdynr.A = 'RUN'      ;  dbblkn.A='ALL'     ;   dbcur.A = 'NO'
 dbdynr.B = 'BIND'     ;  dbblkn.B='ALL'     ;   dbcur.B = 'NO'
 dbdynr.D = 'RUN'      ;  dbblkn.D='ALL'     ;   dbcur.D = 'NO'
 dbdynr.E = 'BIND'     ;  dbblkn.E='ALL'     ;   dbcur.E = 'NO'
 dbdynr.F = 'BIND'     ;  dbblkn.F='ALL'     ;   dbcur.F = 'NO'
 dbdynr.K = 'RUN'      ;  dbblkn.K='ALL'     ;   dbcur.K = 'NO'
 dbdynr.R = 'RUN'      ;  dbblkn.R='ALL'     ;   dbcur.R = 'NO'
 dbdynr.T = 'RUN'      ;  dbblkn.T='ALL'     ;   dbcur.T = 'NO'
 dbdynr.U = 'RUN'      ;  dbblkn.U='ALL'     ;   dbcur.U = 'NO'
 dbdynr.V = 'RUN'      ;  dbblkn.V='ALL'     ;   dbcur.V = 'NO'
 dbdynr.X = 'RUN'      ;  dbblkn.X='ALL'     ;   dbcur.X = 'NO'
 dbdynr.Y = 'RUN'      ;  dbblkn.Y='UNAMBIG' ;   dbcur.Y = 'YES'

 /* Encoding                                                         */

 dbenc.A = 'EBCDIC'    ;
 dbenc.B = 'EBCDIC'    ;
 dbenc.D = 'EBCDIC'    ;
 dbenc.E = 'UNICODE'   ;
 dbenc.F = 'UNICODE'   ;
 dbenc.K = 'EBCDIC'    ;
 dbenc.R = 'EBCDIC'    ;
 dbenc.T = 'EBCDIC'    ;
 dbenc.U = 'EBCDIC'    ;
 dbenc.V = 'EBCDIC'    ;
 dbenc.X = 'EBCDIC'    ;
 dbenc.Y = 'EBCDIC'    ;

 /* PROCESSOR GROUP CHARACTER 6_7 */

 /* Set the db2 instance(s) */

 prodonly_inst = 'P'   /* Switch off dev binds for these instances */

 instances.AX = 'O U X Y Z T'    ; desc.AX = "ALL_INS"
 instances.BA = 'R N J K'        ; desc.BA = "ALL_BNKS"
 instances.BX = 'N R'            ; desc.BX = "NWB+RBS"
 instances.CX = 'R N J K G'      ; desc.CX = "ALL_BNKS+GRP"
 instances.DA = 'O U X Y Z T'    ; desc.DA = "ALL_INS"
 instances.DG = 'O U X Y Z T G'  ; desc.DG = "ALL_INS+GRP"
 instances.DP = 'O U X Y Z T P'  ; desc.DP = "ALL_INS+DLPUK"
 instances.DU = 'Z T'            ; desc.DU = "DLI"
 instances.DX = 'R N J K'        ; desc.DX = "ALL_BNKS"
 instances.EX = 'I'              ; desc.EX = "DLI_IT"
 instances.FX = 'L'              ; desc.FX = "DLI_GER"
 instances.GA = 'R N J K G'      ; desc.GA = "ALL_BNKS+GRP"
 instances.GB = 'N R G'          ; desc.GB = "NWB+RBS+GRP"
 instances.GU = 'J K G'          ; desc.GU = "ULS_N+S_+GRP"
 instances.GX = 'G'              ; desc.GX = "GRP"
 instances.IX = 'I'              ; desc.IX = "DLI_IT"
 instances.JX = 'J'              ; desc.JX = "ULSTER_N"
 instances.KX = 'K'              ; desc.KX = "ULSTER_S"
 instances.LX = 'J K'            ; desc.LX = "ULS_N+S"
 instances.MX = 'J K G'          ; desc.MX = "ULS_N+S_+GRP"
 instances.NX = 'N'              ; desc.NX = "NWB"
 instances.OX = 'O'              ; desc.OX = "PRT"
 instances.PX = 'P'              ; desc.PX = "DLPUK"
 instances.QA = 'G R N J K Q'    ; desc.QA = "ALL_BNKS+Q+G"
 instances.QB = 'R N J K Q'      ; desc.QB = "ALL_BNKS+QMU"
 instances.QC = 'N R Q'          ; desc.QC = "NWB+RBS+QMU"
 instances.QJ = 'J Q'            ; desc.QJ = "ULSTER_N+QMU"
 instances.QK = 'K Q'            ; desc.QK = "ULSTER_S+QMU"
 instances.QM = 'Q'              ; desc.QM = "QMU"
 instances.QN = 'N Q'            ; desc.QN = "NWB+QMU"
 instances.QR = 'R Q'            ; desc.QR = "RBS+QMU"
 instances.QU = 'J K Q'          ; desc.QU = "ULS_N+S+QMU"
 instances.QX = 'Q'              ; desc.QX = "QMU"
 instances.RN = 'N R'            ; desc.RN = "NWB+RBS"
 instances.RX = 'R'              ; desc.RX = "RBS"
 instances.SX = 'N R G'          ; desc.SX = "NWB+RBS+GRP"
 instances.TX = 'T'              ; desc.TX = "DLTUK"
 instances.UA = 'J K'            ; desc.UA = "ULS_N+S"
 instances.UX = 'U'              ; desc.UX = "PRU"
 instances.WI = 'O U X Y Z T W'  ; desc.WI = "ALL_INS+WMU"
 instances.WO = 'O W'            ; desc.WO = "PRT+WMU"
 instances.WT = 'T W'            ; desc.WT = "DLTUK+WMU"
 instances.WU = 'U W'            ; desc.WU = "PRU+WMU"
 instances.WX = 'W'              ; desc.WX = "WMU"
 instances.WY = 'Y W'            ; desc.WY = "CHL+WMU"
 instances.WZ = 'Z W'            ; desc.WZ = "DLI+WMU"
 instances.XX = 'X'              ; desc.XX = "TPF"
 instances.YX = 'Y'              ; desc.YX = "CHL"
 instances.ZX = 'Z'              ; desc.ZX = "DLI"

 /* Set the production owner and qualifier for each instance */
 prodown.A = 'ABN'               ; prodqual.A = 'ABN'
 prodown.G = 'GRP'               ; prodqual.G = 'GRP'
 prodown.J = 'JUBUK'             ; prodqual.J = 'JUBUK'
 prodown.I = 'IDLIT'             ; prodqual.I = 'IDLIT'
 prodown.K = 'KUBIE'             ; prodqual.K = 'KUBIE'
 prodown.L = 'LDLDE'             ; prodqual.L = 'LDLDE'
 prodown.N = 'NWB'               ; prodqual.N = 'NWB'
 prodown.R = 'RBS'               ; prodqual.R = 'RBS'
 prodown.T = 'DLTUK'             ; prodqual.T = 'DLTUK'
 prodown.O = 'PRTUK'             ; prodqual.O = 'PRTUK'
 prodown.P = 'DLIUK'             ; prodqual.P = 'DLPUK' /* different */
 prodown.Q = 'QMU'               ; prodqual.Q = 'QMU'
 prodown.U = 'PRUUK'             ; prodqual.U = 'PRUUK'
 prodown.W = 'WMU'               ; prodqual.W = 'WMU'
 prodown.X = 'TPFUK'             ; prodqual.X = 'TPFUK'
 prodown.Y = 'CHLUK'             ; prodqual.Y = 'CHLUK'
 prodown.Z = 'DLIUK'             ; prodqual.Z = 'DLIUK'

 /* Set up a training bind for DL Italy & Germany */
 trainown.I  = 'IDTIT'
 trainown.L  = 'LDTDE'
 trainqual.I = 'IDTIT'
 trainqual.L = 'LDTDE'

 /* DB2 environment */
 select
   when c1en = 'UNIT' then db2env1 = 'D'
   when c1en = 'SYST' then db2env1 = 'S'
   when c1en = 'ACPT' then db2env1 = 'U'
   when c1en = 'PROD' then db2env1 = 'P'
   otherwise do
     say 'DB2PARMS: Endevor Environment' c1en 'Invalid'
     exit 12
   end /* end otherwise */
 end

 /* Select special for character 8 (Development only) */
 select
   when pos(pgchr8,'PQRSTUX') > 0 then do /* Controls dev envr binds */
     qualsuff = db2clone
     collsuff = db2clone
   end /* pos(pgchr8,'PQRSTUX') > 0 */
   when pgchr8 = '@' then do        /* @ means qualifier as subsys 1 */
     qualsuff = '1'
     collsuff = db2clone
   end /* pgchr8 = '@' */
   otherwise do /* Anything else overrides the suffix on qual & coll */
     qualsuff = pgchr8
     collsuff = pgchr8
   end /* otherwise */
 end /* select */

 /* Set the DB2 datasharing group prefix */
 sysplex = mvsvar(sysplex)                  /* GSI plexes are PLEX%1 */
 select
   when substr(sysplex,5,1) = 'S' then          /* We're on the Splex */
     dbpref = 'DS'
   when c1en = 'PROD' then
     dbpref = 'DP'
   otherwise
     dbpref = 'DQ'
 end /* select */

return

/* +--------------------------------------------------------------+ */
/* !  Validate variables and processor group                      ! */
/* +--------------------------------------------------------------+ */
Validate:

 /* Check offhost parameters                                         */
 if right(c1ty,2) = 'OH' & c1en ^= 'PROD' then do
   say "DB2PARMS:  Environment must be PROD for off host binds"
   exit 12
 end

 /* Validate the processor group name */
 if pos(pgchr1,'X#') = 0 then do
   say "DB2PARMS:  Processor Group character 1 invalid - '"pgchr1"'"
   exit 12
 end
 if dbgrp.pgchr2 = 'DBGRP.'pgchr2 then do
   say "DB2PARMS: Invalid bind processor Group character 2 - '"pgchr2"'"
   exit 12
 end
 if dbiso.pgchr3 = 'DBISO.'pgchr3 then do
   say "DB2PARMS: Missing DBISO variable - '"pgchr3"'"
   exit 12
 end
 if dbdeg.pgchr3 = 'DBDEG.'pgchr3 then do
   say "DB2PARMS: Missing DBDEG variable - '"pgchr3"'"
   exit 12
 end
 if dbrel.pgchr3 = 'DBREL.'pgchr3 then do
   say "DB2PARMS: Missing DBREL variable - '"pgchr3"'"
   exit 12
 end
 if dbreo.pgchr3 = 'DBREO.'pgchr3 then do
   say "DB2PARMS: Missing DBREO variable - '"pgchr3"'"
   exit 12
 end
 if dbval.pgchr3 = 'DBVAL.'pgchr3 then do
   say "DB2PARMS: Missing DBVAL variable - '"pgchr3"'"
   exit 12
 end
 if dbkdyn.pgchr3 = 'DBKDYN.'pgchr3 then do
   say "DB2PARMS: Missing DBKDYN variable - '"pgchr3"'"
   exit 12
 end
 if dbdynr.pgchr3 = 'DBDYNR.'pgchr3 then do
   say "DB2PARMS: Missing DBDYNR variable - '"pgchr3"'"
   exit 12
 end
 if dbblkn.pgchr3 = 'DBBLKN.'pgchr3 then do
   say "DB2PARMS: Missing dbblkn variable - '"pgchr3"'"
   exit 12
 end

 /* This is in the BB system only */
 if pgchr4 = 'Z' & pgchr6_7 ^= 'RX' then do
   say "DB2PARMS: Z in character 4 is only valid with RBS binds"
   exit 12
 end

 /* This is for Peoplesoft only */
 if pgchr4 = 'W' & pgchr6_7 ^= 'GX' then do
   say "DB2PARMS: W in character 4 is only valid with GRP binds"
   exit 12
 end

 /* This is for a non X value in position 5                          */
 if pgchr5 ^= 'X' & pos(pgchr4,'012345') = 0 then do
   say 'DB2PARMS: Non X in position 5 is only valid with 012345' ,
       'in position 4'
   exit 12
 end

 if instances.pgchr6_7 = 'INSTANCES.'pgchr6_7 then do
   say "DB2PARMS: Invalid bind processor Group character 6 & 7 - '"pgchr6_7"'"
   exit 12
 end
 if desc.pgchr6_7 = 'DESC.'pgchr6_7 then do
   say "DB2PARMS: Missing Processor Group description for - '"pgchr6_7"'"
   exit 12
 end

 /* Check all production variables are defined */
 do x = 1 to words(instances.pgchr6_7)
   db2inst = word(instances.pgchr6_7,x)
   if prodown.db2inst = 'PRODOWN.'db2inst then do
     say 'DB2PARMS: Production owner not defined for instance -' db2inst
     exit 12
   end
   if prodqual.db2inst = 'PRODQUAL.'db2inst then do
     say 'DB2PARMS: Production qual not defined for instance -' db2inst
     exit 12
   end
 end

return
/* +--------------------------------------------------------------+ */
/* !  Process - Build DB2 values                                  ! */
/* +--------------------------------------------------------------+ */
process:
 arg proctype

 dbiso   = dbiso.pgchr3
 dbcur   = dbcur.pgchr3
 dbdeg   = dbdeg.pgchr3
 dbrel   = dbrel.pgchr3
 dbreo   = dbreo.pgchr3
 dbval   = dbval.pgchr3
 dbkdyn  = dbkdyn.pgchr3
 dbdynr  = dbdynr.pgchr3
 dbblkn  = dbblkn.pgchr3
 dbenc   = dbenc.pgchr3
 prodown = prodown.db2inst

 if c1en = 'PROD' then do

   if pgchr1 = '#' then
     collsuff = db2proj
   else
     collsuff = 'RG'

   dbqual = prodqual.db2inst
   dbown  = prodown.db2inst

   if right(c1ty,2) = 'OH' then
     dbcoll = 'C'db2inst || collsuff'OH'
   else
     dbcoll = 'C'db2inst || collsuff

   dbwlm  = 'n/a'
   dbracf = 'n/a'

   select
     when proctype = 'DLITRAIN' then do /* DLI extra training bind */
       dbqual = trainqual.db2inst
       dbown  = trainown.db2inst
       dbcoll = dbcoll'T0'
     end /* proctype = 'DLITRAIN' */
     when proctype = 'Q' then do /* Char 4 = 'Q' - extra bind */
       dbqual = dbqual'Q'
       dbcoll = dbcoll'Q'
     end /* proctype = 'Q' */
     when proctype = 'V' then do /* Char 4 = 'V' - KUBIE extra bind */
       dbqual = dbqual'V'
       dbcoll = dbcoll'V'
     end /* proctype = 'V' */
     otherwise nop
   end /* select */

   /* Add suffix based on pgchr4                                     */
   select
     when pos(pgchr4,'012345') > 0 then
       dbqual = dbqual || db2proj || pgchr4
     /* Single bind to GRPHW0                                        */
     when pgchr4 = 'W' then dbqual = dbqual'HW0'
     /* This is used in the BB system only - single bind to RBSQ     */
     when pgchr4 = 'Z' then dbqual = dbqual'Q'
     otherwise nop
   end /* select */

   /* Positon 5 of the proc group overrides all values for dbqual    */
   if pgchr5 ^= 'X' then
     dbqual = db2inst || db2proj'O'pgchr5 || pgchr4'P0'

 end /* c1en = 'PROD' */

 else do /* Not PROD */
   if wordpos(db2inst,prodonly_inst) > 0 then
     return

   if proctype = 'Q' then
     db2env = 'Q'
   else
     db2env = db2env1

   /* Positon 5 of the proc group overrides all values for dbqual    */
   if pgchr5 ^= 'X' then
     dbqual = db2inst || db2proj'O'pgchr5 || pgchr4 || db2env || qualsuff
   else
     dbqual = db2inst || dbsub33 || db2proj || db2env || qualsuff
   dbown  = dbqual
   dbcoll = 'C'db2inst || db2proj || db2env || collsuff
   dbwlm  = dbsub'AE'db2env || collsuff
   dbracf = 'D'db2inst || dbsub33 || db2proj || db2env || collsuff'A'

   dbcur   = 'NO' /* Always NO in development                        */

 end /* else */

 pgrdesc = desc.pgchr6_7

 /* set processor group description */
 select
   when pos(pgchr4,'QPZ') > 0 then
     pgrdesc = pgrdesc"Q"
   when pgchr4 = 'W' then
     pgrdesc = pgrdesc"HW0"
   when pos(pgchr4,'012345') > 0 then
     pgrdesc = pgrdesc'/'db2proj || pgchr4
   otherwise nop
 end
 if pgchr5 ^= 'X' then
   pgrdesc = pgrdesc || pgchr5

 pgrdesc = "'"pgrdesc"'"

if sysvar('SYSENV') ^= 'FORE' then
  do
    say 'DB2PARMS:'
    say 'DB2PARMS: SET DBSUB  =' dbsub
    say 'DB2PARMS: SET DBQUAL =' dbqual
    say 'DB2PARMS: SET DBOWN  =' dbown
    say 'DB2PARMS: SET DBCOLL =' dbcoll
    say 'DB2PARMS: SET DBWLM  =' dbwlm
    say 'DB2PARMS: SET DBRACF =' dbracf
    say 'DB2PARMS: SET DB2INST=' db2inst
    say 'DB2PARMS: SET DBISO  =' dbiso
    say 'DB2PARMS: SET DBCUR  =' dbcur
    say 'DB2PARMS: SET DBDEG  =' dbdeg
    say 'DB2PARMS: SET DBREL  =' dbrel
    say 'DB2PARMS: SET DBREO  =' dbreo
    say 'DB2PARMS: SET DBVAL  =' dbval
    say 'DB2PARMS: SET DBKDYN =' dbkdyn
    say 'DB2PARMS: SET DBDYNR =' dbdynr
    say 'DB2PARMS: SET DBBLKN =' dbblkn
    say 'DB2PARMS: SET DBENC  =' dbenc
    say 'DB2PARMS: SET PRODOWN =' prodown
    say 'DB2PARMS: ENDSET'
  end

 queue dbsub dbqual dbown dbcoll dbwlm dbracf db2inst pgrdesc ,
       dbiso dbcur dbdeg dbrel dbreo dbval dbkdyn dbdynr dbblkn ,
       prodown dbenc

return

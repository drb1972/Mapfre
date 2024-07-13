/*-      REXX                                                    -*/
/*----------------------------------------------------------------*/
trace o
Arg element action enty env1 env2 stg1 stg2 sys subs ccid comments
/*----------------------------------------------------------------*/
/*-                                                              -*/
/*-                                                              -*/
/*- NAME    : GENSCL                                             -*/
/*-                                                              -*/
/*- PURPOSE : This REXX is called from within an Endevor         -*/
/*-           processor for types of DIF and SQLCOPY.            -*/
/*-           The REXX interrogates the DIF file to determine    -*/
/*-           which environment it was generated in and then     -*/
/*-           creates Endevor SCL to perform an ADD action       -*/
/*-           against the Cobol source and/or the the BMS Map.   -*/
/*-                                                              -*/
/*- UPDATED : DATE       BY   DESCRIPTION                        -*/
/*-           01-FEB-96  PB6  Initial creation of this REXX      -*/
/*-           20-FEB-96  PB6  Include delete options             -*/
/*-                                                              -*/
/*----------------------------------------------------------------*/

/*----------------------------------------------------------------*/
/*-      Initialise variables                                    -*/
/*----------------------------------------------------------------*/
Init_vars:
  scl = 0
  rel = 0
/*----------------------------------------------------------------*/
/*-      Check input element type                                -*/
/*----------------------------------------------------------------*/
Check_diff:
 Select
   When enty = 'DIF' & length(element) = 6 then do
     object = 'Q' || substr(element,1,1) || 'B' || substr(element,2,5)
     type = 'COBB'
     call generate_scl
     call generate_rele
   End
   When enty = 'DIF' & length(element) = 5 then do
     object = 'QSC' || element
     type = 'COBC'
     call generate_scl
     call generate_rele
     object = 'MP' || element
     type = 'MAPBMS'
     call generate_scl
     call generate_rele
   End
   Otherwise NOP
 End

/*----------------------------------------------------------------*/
/*-      Write SCL to output dataset                             -*/
/*----------------------------------------------------------------*/
Write_scl:
 If scl <> 0 then "EXECIO * DISKW SCLOUT (stem out. finis"
 If rel <> 0 then "EXECIO * DISKW RELOUT (stem lnk. finis"

/*----------------------------------------------------------------*/
/*-      Exit routine                                            -*/
/*----------------------------------------------------------------*/
Exit:
 Exit(0)

/*----------------------------------------------------------------*/
/*-      Generate SCL                                            -*/
/*----------------------------------------------------------------*/
Generate_scl:
 Select
   When action = 'ADD' then call generate_add
   When action = 'UPDATE' then call generate_add
   When action = 'MOVE' then call generate_mve
   When action = 'DELETE' then call generate_mve
   Otherwise NOP
 End
Return

/*----------------------------------------------------------------*/
/*-      Generate ADD                                            -*/
/*----------------------------------------------------------------*/
Generate_add:
 scl = scl + 1
 out.scl = "SET FROM DDNAME '" || type || "' ."
 scl = scl + 1
 out.scl = "SET TO ENVIRONMENT '" || env1 || "' SYSTEM '" || sys || ,
                "' SUBSYSTEM '" || subs || "'"
 scl = scl + 1
 out.scl = "         TYPE '" || type || "' STAGE NUMBER 1 ."
 scl = scl + 1
 out.scl = "SET STOPRC 12 ."
 scl = scl + 1
 out.scl = "SET OPTIONS CCID '" || ccid || "' COMMENTS '" || ,
                comments || " ' UPDATE DELETE "
 If type = 'DDL' then do
   scl = scl + 1
   out.scl = "         OVERRIDE SIGNOUT"
 End

 If type = 'MAPBMS' then do
   scl = scl + 1
   out.scl = "         PROC GROUP = 'XXLMXXIX' OVE"
 End

 If type = 'COBB' then do
   pref = substr(object,2,1)
   if pref = 'S' | pref = 'F' then do
   scl = scl + 1
   out.scl = "         PROC GROUP = 'EXDMEXDX' OVE"
   end
   if pref = 'P' then do
   scl = scl + 1
   out.scl = "         PROC GROUP = 'BXDMEXDX' OVE"
   end
 End

 If type = 'COBC' then do
   scl = scl + 1
   out.scl = "         PROC GROUP = 'BXDMEXDX' OVE"
 End

 out.scl = out.scl || " ."
 scl = scl + 1
 out.scl = "     ADD ELEMENT  '" || object || "' ."
 scl = scl + 1
 out.scl = " "
Return

/*----------------------------------------------------------------*/
/*-      Generate MOVE (or DELETE)                               -*/
/*----------------------------------------------------------------*/
Generate_mve:
 scl = scl + 1
 out.scl = "SET FROM ENVIRONMENT '" || env1 || "' SYSTEM '" || sys || ,
            "' SUBSYSTEM '" || subs || "'"
 scl = scl + 1
 out.scl = "         TYPE '"type"' STAGE " || stg1 || " ."
 scl = scl + 1
 out.scl = "SET OPTIONS COMMENTS '" || comments || "'"
 scl = scl + 1
 out.scl = "   CCID '" || ccid || "' ."
 scl = scl + 1
 out.scl = "     " || action || " ELEMENT  '" || object || "' ."
Return

/*----------------------------------------------------------------*/
/*-      Generate CONRELE                                        -*/
/*----------------------------------------------------------------*/
Generate_rele:
 envr = env1
 stge = stg1
 If action = 'MOVE' then do
   envr = env2
   stge = stg2
 End
 rel = rel + 1
 lnk.rel = "RELATE ELEMENT " || object
 rel = rel + 1
 lnk.rel = "   LOC"
 rel = rel + 1
 lnk.rel = "   ENVIRONMENT = '" || envr || "'"
 rel = rel + 1
 lnk.rel = "   SYSTEM      = '" || sys || "'"
 rel = rel + 1
 lnk.rel = "   SUBSYSTEM   = '" || subs || "'"
 rel = rel + 1
 lnk.rel = "   TYPE        = '" || type || "'"
 rel = rel + 1
 lnk.rel = "   STAGE       = " || stge
 rel = rel + 1
 lnk.rel = "   OUTPUT"
 rel = rel + 1
 lnk.rel = "   ."
Return

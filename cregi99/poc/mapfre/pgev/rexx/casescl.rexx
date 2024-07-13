/*-      REXX                                                    -*/
/*----------------------------------------------------------------*/
 Arg element envr proj ccid .
/*----------------------------------------------------------------*/
/*-                                                              -*/
/*- COPYRIGHT (C) : NIG SKANDIA                        14-MAR-96 -*/
/*-                                                              -*/
/*- NAME    : CASESCL                                            -*/
/*-                                                              -*/
/*- PURPOSE : This REXX is called during the Casegen generate.   -*/
/*-           The input SCL is generated to ADD the DIF member   -*/
/*-           to ENDEVOR.                                        -*/
/*-           Also dependant on the DIF type set the return      -*/
/*-           code to copy the BMS MAP to a PDS member           -*/
/*-                                                              -*/
/*- UPDATED : DATE       BY   DESCRIPTION                        -*/
/*-           15/05/96   PB6  IMPROVE ELEMENT NAME VALIDATION    -*/
/*-                                                              -*/
/*----------------------------------------------------------------*/

/*----------------------------------------------------------------*/
/*-      Initialise variables                                    -*/
/*----------------------------------------------------------------*/
Init_vars:
 lc = 0
 scl = 0
 sys = ' '
 subsys = ' '

/*----------------------------------------------------------------*/
/*-      Processing steps (Ignore numeric checks if TRAINING)    -*/
/*----------------------------------------------------------------*/
 If lc = 0 then call Validate_length
 If lc < 4 then call Validate_project
 If lc < 4 then call Generate_scl

Exit:
 Exit(lc)

Validate_length:
/*----------------------------------------------------------------*/
/*-      Check DIF file name is either 5 or 6 characters         -*/
/*----------------------------------------------------------------*/
  Select
    When length(element) = 5 then do
      elm_prj = substr(element,1,1)
      elm_num = substr(element,2,4)
      lc = 3
    End
    When length(element) = 6 then do
      elm_prj = substr(element,2,1)
      elm_num = substr(element,3,4)
    End
    Otherwise
      errmsg = 'DIF FILE NAME IS AN INVALID LENGTH'
      Call errors
  End
Return

Validate_numeric:
/*----------------------------------------------------------------*/
/*-      Check DIF file name has four figure numeric ending      -*/
/*----------------------------------------------------------------*/
  If datatype(elm_num) <> 'NUM' then do
    errmsg = elm_num 'PORTION OF NAME' element 'SHOULD BE NUMERIC'
    Call errors
  End
Return

Validate_project:
/*----------------------------------------------------------------*/
/*-      Check project letter matches the project code           -*/
/*----------------------------------------------------------------*/
  "EXECIO * DISKR SCLMAP (STEM map. FINIS"

  Do a = 1 to map.0
    prjcode = word(map.a,1)
    If elm_prj = prjcode then do
      sys = word(map.a,2)
      subsys = word(map.a,3)
    End
  End

  If proj <>  subsys then do
    errmsg = 'FOR' elm_prj 'THE PROJECT SHOULD BE' subsys 'NOT' proj
    Call errors
  End
Return

Generate_scl:
/*----------------------------------------------------------------*/
/*-      Generate the Endevor SCL                                -*/
/*----------------------------------------------------------------*/
 scl = scl + 1
 out.scl = "ADD ELEMENT '" || element || "'"
 scl = scl + 1
 out.scl = "  FROM DDNAME 'DIFIN'"
 scl = scl + 1
 out.scl = "  TO   ENV 'UNIT' SYS 'LJ' SUBSYSTEM 'LJ1'"
 scl = scl + 1
 out.scl = "         TYPE 'DIF'"
 scl = scl + 1
 out.scl = "  OPTIONS CCID '" || ccid || "' COMMENTS 'CASEGEN' " ,
           || "UPDATE DELETE OVE"
 scl = scl + 1
 out.scl = " . "

 If scl <> 0 then "EXECIO * DISKW SCLOUT (STEM out. FINIS"
Return

Errors:
/*----------------------------------------------------------------*/
/*-      Issue error message and set non zero return code        -*/
/*----------------------------------------------------------------*/
  Say errmsg
  lc = 8
Return

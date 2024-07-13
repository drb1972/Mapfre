/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* Edit System/Stream Control Information                           */  00030030
/********************************************************************/  00040000
arg typ debug                                                           00050007
if debug = 'DEBUG' then trace all                                       00060000
call ppcinit                                                            00070029
address ISPEXEC                                                         00080013
"VGET STRMPRFX"                                                         00090013
dsn = strmprfx || typ                                                   00100013
"VPUT DSN"                                                              00110009
"CONTROL ERRORS RETURN"                                                 00120009
"DISPLAY PANEL(PPCADM0) CURSOR(ID)"                                     00130028
do while rc < 8                                                         00140000
  select                                                                00150002
    when id = '  ' then call selmem  dsn                                00160031
    when id = '$$' then call memlist dsn                                00170030
    when id = '**' then call editmem dsn '#' || typ || 'S'              00180031
    otherwise do                                                        00190002
      address TSO                                                       00200002
      "ALLOC F(IN) REU DA('" || dsn || "(#" || typ || "S)') SHR"        00210024
      "EXECIO * DISKR IN (STEM R. FINIS"                                00220002
      "FREE F(IN)"                                                      00230002
      address ISPEXEC                                                   00240002
/********************************************************************/  00250030
/* Check to see if the system/stream selected                       */  00260030
/* is defined in the # member                                       */  00270030
/********************************************************************/  00280030
      do i = 1 to r.0                                                   00290002
        if substr(r.i,1,1) = '*' then iterate                           00300021
        if id = substr(r.i,1,2) then leave                              00310021
      end                                                               00320002
      if i <= r.0 then do                                               00330010
        call editmem dsn id                                             00340031
        if result = 0 & typ = 'STREAM' then do                          00350031
          "EDIT DATASET('" || dsn || "(" || id || ")') MACRO(PPCEM01)"  00360029
        end                                                             00370011
      end                                                               00380011
      else do                                                           00390002
        zedsmsg = id 'Not Found'                                        00400005
        zedlmsg = id 'Not Found In #' || typ || 'S Member of' dsn       00410024
        "SETMSG MSG(ISRZ001)"                                           00420002
      end                                                               00430002
    end                                                                 00440002
  end                                                                   00450002
  "DISPLAY PANEL(PPCADM0)"                                              00460030
end                                                                     00470000
exit                                                                    00480000
/********************************************************************/  00490030
/* Display Member List to get Member Name                           */  00500030
/********************************************************************/  00510030
selmem:                                                                 00520030
  arg dataset                                                           00530031
  address ISPEXEC                                                       00540031
  "LMINIT  DATAID(DATAID) DATASET('" || dataset || "')"                 00550031
  "LMOPEN  DATAID(" || dataid || ")"                                    00560031
  "LMMDISP DATAID(" || dataid || ")" ,                                  00570031
                    || "OPTION(DISPLAY) MEMBER(*) COMMANDS(S) FIELD(1)" 00580031
  if substr(zlmember,1,1) ^= '#' then id = zlmember                     00590032
  "LMCLOSE DATAID(" || dataid || ")"                                    00600031
  "LMFREE  DATAID(" dataid ")"                                          00610031
return                                                                  00620030
/********************************************************************/  00630030
/* Display Member List to process some members ...........          */  00640030
/********************************************************************/  00650030
memlist:                                                                00660030
arg dataset                                                             00670030
  address ISPEXEC                                                       00680031
  "LMINIT  DATAID(DATAID) DATASET('" || dataset || "')"                 00690031
  "MEMLIST DATAID(" || dataid || ") FIELD(9)"                           00700031
  "LMFREE  DATAID(" dataid ")"                                          00710031
return                                                                  00720030
/********************************************************************/  00730031
/* Edit Selected Member                                             */  00740031
/********************************************************************/  00750031
editmem:                                                                00760031
  arg dataset member                                                    00770031
  address ISPEXEC                                                       00780031
  "EDIT DATASET('" || dataset || "(" || member || ")'"                  00790031
  if rc = 14 then do                                                    00800031
    zedsmsg = zerrsm                                                    00810031
    zedlmsg = zerrlm                                                    00820031
    "SETMSG MSG(ISRZ001)"                                               00830031
  end                                                                   00840031
return rc                                                               00850031

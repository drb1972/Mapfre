/* Rexx */                                                              00010000
/********************************************************************/  00020000
/* UP - Update TestStream Production Components                     */  00030000
/* OV - Update TestStream Override Components                       */  00040000
/* OX - Delete TestStream Override Components                       */  00050000
/********************************************************************/  00060000
arg prodover debug .                                                    00070000
if debug = 'DEBUG' then trace a                                         00080000
call ppcinit                                                            00090000
address ISPEXEC                                                         00100000
"VGET (STREAMID LOGDSN CNTLDSN)"                                        00110000
cntldsnm = cntldsn || "(" || prodover                                   00120000
select                                                                  00130000
  when prodover = 'UP' then updttype = 'PRODUCTION UPDATE'              00140000
  when prodover = 'OV' then updttype = 'OVERRIDE UPDATE'                00150000
  when prodover = 'OX' then updttype = 'OVERRIDE DELETES'               00160000
end                                                                     00170000
"VPUT PRODOVER"                                                         00180000
"CONTROL ERRORS RETURN"                                                 00190000
/********************************************************************/  00200000
/* Get/Allocate the Log File                                        */  00210000
/********************************************************************/  00220000
call ppcloga logdsn || "." || streamid debug                            00230000
if result = 99 then exit 99                                             00240000
/********************************************************************/  00250000
/* Main Processing Loop                                             */  00260000
/********************************************************************/  00270000
"DISPLAY PANEL(PPCUPDT) CURSOR(TRACKER)"                                00280000
do while rc = 0                                                         00290000
/********************************************************************/  00300000
/* Edit Control Member & then process (if exists, if not empty)     */  00310000
/********************************************************************/  00320000
  call editcntl                                                         00330000
  if sysdsn("'" || cntldsnm || tracker || ")'") = 'OK' then do          00340000
    call ppctttb streamid "'" || cntldsnm || tracker || ")'" debug      00350000
    "TBSTATS PPCTTTB ROWCURR(ROWCNT)"                                   00360000
    if rowcnt > 0 then do                                               00370000
      startext = date() time() userid() 'TRACKER' tracker               00380000
      "VPUT (TRACKER STARTEXT)"                                         00390000
      call ppclogw updttype 'STARTED :' startext                        00400000
      if result = 99 then exit 99                                       00410000
      call ppclogw copies('*',80)                                       00420000
      if result = 99 then exit 99                                       00430000
      e_msgs = 0                                                        00440000
      call ppctab streamid debug                                        00450000
/********************************************************************/  00460000
/* Validate Update or Delete requests                               */  00470000
/********************************************************************/  00480000
      "TBTOP PPCTTTB"                                                   00490000
      "TBSKIP PPCTTTB"                                                  00500000
      do while rc = 0                                                   00510000
        save_e = e_msgs                                                 00520000
        "TBTOP PPCTAB"                                                  00530002
        select                                                          00540000
          when prodover = 'UP' then do                                  00550002
            proddsn = datadsn                                           00560002
            "TBSCAN PPCTAB ARGLIST(PRODDSN)"                            00570002
          end                                                           00580002
          when prodover = 'OV' then do                                  00590002
            overdsn = datadsn                                           00600002
            "TBSCAN PPCTAB ARGLIST(OVERDSN)"                            00610002
          end                                                           00620002
          when prodover = 'OX' then do                                  00630002
            overdsn = datadsn                                           00640002
            "TBSCAN PPCTAB ARGLIST(OVERDSN)"                            00650002
          end                                                           00660002
        end                                                             00670000
        if rc = 0 then do                                               00680000
                                                                        00690002
          select                                                        00700002
            when prodover = 'UP' then updtdsn = proddsn                 00710002
            when prodover = 'OV' then updtdsn = overdsn                 00720002
            when prodover = 'OX' then updtdsn = overdsn                 00730002
          end                                                           00740002
                                                                        00750000
          call memchk updtdsn                                           00760000
                                                                        00770000
/********************************************************************/  00780000
/* For Production Updates                                           */  00790000
/* check for conflicts with Endevor output libraries                */  00800000
/********************************************************************/  00810000
          if prodover = 'UP' then do                                    00820000
            call conflict ndvrdsnp                                      00830002
            select                                                      00840000
              when stage = 'F' then do                                  00850000
                call conflict ndvrdsnf                                  00860002
              end                                                       00870000
              when stage = 'D' then do                                  00880000
                call conflict ndvrdsnf                                  00890002
                call conflict ndvrdsnd                                  00900002
              end                                                       00910000
              when stage = 'B' then do                                  00920000
                call conflict ndvrdsnf                                  00930002
                call conflict ndvrdsnd                                  00940002
                call conflict ndvrdsnb                                  00950002
              end                                                       00960000
            end                                                         00970000
          end                                                           00980000
                                                                        00990000
          if save_e ^= e_msgs then do                                   01000000
            call ppclogw copies('-',80)                                 01010000
            if result = 99 then exit 99                                 01020000
          end                                                           01030000
        end                                                             01040000
        else do                                                         01050000
          call ppclogw 'ERROR   :' trgtdsn 'TARGET DATASET NOT FOUND'   01060000
          if result = 99 then exit 99                                   01070000
          call ppclogw '        : IN' streamid 'STREAM DEFINITION'      01080000
          if result = 99 then exit 99                                   01090000
          call ppclogw '        :' updtdsn 'SPECIFIED AS SOURCE'        01100000
          if result = 99 then exit 99                                   01110000
          e_msgs = e_msgs + 1                                           01120000
        end                                                             01130000
                                                                        01140000
        "TBSKIP PPCTTTB"                                                01150000
                                                                        01160000
      end                                                               01170000
                                                                        01180000
      if showlog = 'Y' | e_msgs > 0 then do                             01190000
        "VIEW DATASET('"logdsn"."streamid"') MACRO(PPCEM02)"            01200000
      end                                                               01210000
                                                                        01220000
/********************************************************************/  01230000
/* No errors, then generate the JCL                                 */  01240000
/********************************************************************/  01250000
      if e_msgs = 0 then do                                             01260000
        l = substr(updttype,1,1)                                        01270000
        "TBTOP PPCTTTB"                                                 01280000
        "FTOPEN TEMP"                                                   01290000
        "FTINCL PPCUPDT"                                                01300003
        "FTCLOSE"                                                       01310000
        "VGET (ZTEMPN ztempf) SHARED"                                   01320000
        "LMINIT DATAID(DATAID) DDNAME(" || ztempn || ")"                01330000
         "EDIT DATAID(" || dataid || ")"                                01340000
         "LMFREE DATAID(" dataid ")"                                    01350000
      end                                                               01360000
                                                                        01370000
      call ppclogw updttype 'ENDED   :' startext                        01380000
      if result = 99 then exit 99                                       01390000
    end                                                                 01400000
  end                                                                   01410000
  "DISPLAY PANEL(PPCUPDT) CURSOR(TRACKER)"                              01420000
end                                                                     01430000
/********************************************************************/  01440000
/* The End - Tidy up time                                           */  01450000
/********************************************************************/  01460000
"TBEND PPCTTTB"                                                         01470000
"TBEND PPCTAB"                                                          01480000
address TSO "FREE F(LOG)"                                               01490000
exit                                                                    01500000
/********************************************************************/  01510000
/* Edit Control Requests Library                                    */  01520000
/********************************************************************/  01530000
editcntl:                                                               01540000
 if sysdsn("'" || cntldsnm || tracker || ")'") = 'MEMBER NOT FOUND' ,   01550000
 then mac = 'MACRO(PPCEM04)'                                            01560000
 else mac = ''                                                          01570000
 address ISPEXEC                                                        01580000
"EDIT DATASET('" || cntldsnm || tracker || ")')" mac                    01590000
return                                                                  01600000
/********************************************************************/  01610000
/* Check if Member exists                                           */  01620000
/********************************************************************/  01630000
memchk:                                                                 01640000
  arg dsn                                                               01650000
  chkres = sysdsn("'" || dsn || "(" || member || ")'")                  01660000
  select                                                                01670000
    when chkres = 'OK' then nop                                         01680000
    when chkres = 'MEMBER NOT FOUND' then do                            01690000
      call ppclogw 'ERROR  : MEMBER' member 'NOT FOUND IN' dsn          01700000
      if result = 99 then exit 99                                       01710000
      e_msgs = e_msgs + 1                                               01720000
    end                                                                 01730000
    when chkres = 'DATASET NOT FOUND' then do                           01740000
      call ppclogw 'ERROR  : DATASET NOT FOUND' dsn                     01750000
      if result = 99 then exit 99                                       01760000
      e_msgs = e_msgs + 1                                               01770000
    end                                                                 01780000
    otherwise do                                                        01790000
say 'UNEXPECTED CONDITION :'                                            01800000
say dsn member chkres                                                   01810000
    end                                                                 01820000
  end                                                                   01830000
return                                                                  01840000
/********************************************************************/  01850000
/* Check if Conflicting member exists                               */  01860000
/********************************************************************/  01870000
conflict:                                                               01880000
  arg dsn                                                               01890000
  if dsn = '' then return                                               01900001
  memmsg = sysdsn(dsn)                                                  01910000
  select                                                                01920000
    when memmsg = 'DATASET NOT FOUND' then nop                          01930001
    when memmsg = 'MEMBER NOT FOUND'  then nop                          01940001
    when memmsg = 'OK' then do                                          01950000
      call ppclogw 'ERROR   :' member 'IN' updtdsn                      01960000
      if result = 99 then exit 99                                       01970000
      call ppclogw '        : EXISTS   IN' dsn                          01980000
      if result = 99 then exit 99                                       01990000
      e_msgs = e_msgs + 1                                               02000000
    end                                                                 02010000
    otherwise                                                           02020000
  end                                                                   02030000
return                                                                  02040000

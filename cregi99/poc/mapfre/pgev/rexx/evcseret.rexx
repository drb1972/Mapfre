/* REXX ******************************************************/
/* rexx - to read a CaseGen DIF source member, build some    */
/*        Endevor SCL to retrieve the elements affected and  */
/*        also build the transfer statements for CPBD0101 to */
/*        send code the DIF to the CaseGen server            */
/*************************************************************/
trace n
parse arg dif ccid

"EXECIO * DISKR ELEMENT (STEM CODE. FINIS)"

do a = 1 to code.0 while prog = 'PROG'

  select
    when type = 'TYPE' & ,     /* Only use the first found "Version" */
      pos('Version',code.a) > 0 then do
      /* break the string down */
      parse value code.a with ver eq type rest
      /* strip off the extra comma */
      type = strip(type,'T',',')
      if wordpos(type,'ONLINE BATCH') = 0 then do
        say 'EVCSERET: Version must be ONLINE or BATCH on line' a
        say 'EVCSERET: Line' a 'is:'
        say code.a
        exit 8
      end
      say 'EVCSERET: Version found on line' a
      say 'EVCSERET: Line' a 'is:'
      say code.a
    end /* pos('Version',code.a) */

    when pos('PROGREV',code.a) > 0 then do
      /* break the string down */
      parse value code.a with c p r q b prog rest
      /* strip off the extra quotes */
      prog = strip(prog,'B','"')
      say 'EVCSERET: PROGREV found on line' a
      say 'EVCSERET: Line' a 'is:'
      say code.a

      /* Build the SCL & the transfer statements */
      queue 'RETRIEVE ELEMENT 'prog
      queue 'FROM ENVIRONMENT UNIT'
      queue '     SYSTEM LJ'
      queue '     SUBSYSTEM LJ1'
      if type = 'ONLINE' then
        queue '     TYPE COBC'
      else
        queue '     TYPE COBB'
      queue '     STAGE A'
      queue 'TO DSNAME "TTYY.CASEGEN.SOURCE"'
      queue '  OPTIONS COMMENT "RETRIEVE TO CASEGEN SERVER"'
      if type = 'BATCH' then
        queue '  SEARCH'
      queue '   CCID 'ccid' REPLACE'
      queue '   .'

      if type = 'ONLINE' then do
        map = 'MP'||right(prog,5)
        queue 'RETRIEVE ELEMENT 'map
        queue 'FROM ENVIRONMENT UNIT'
        queue '     SYSTEM LJ'
        queue '     SUBSYSTEM LJ1'
        queue '     TYPE MAPBMS'
        queue '     STAGE A'
        queue 'TO DSNAME "TTYY.CASEGEN.SOURCE"'
        queue '  OPTIONS COMMENT "RETRIEVE TO CASEGEN SERVER"'
        queue '   CCID 'ccid' REPLACE'
        queue '   .'
      end /* type = 'ONLINE' */

      "EXECIO * DISKW SCL (FINIS"
      say 'EVCSERET: SCL written'

      queue ' TRANSFER TARGET=LAN,LRECL=00080,BUFSZ=00080,'
      queue '   PATH=H:\NIG\TEST\DIF\'type'\HOM\,FILE='dif',EXTENSION=DIF,'
      queue '   DSNAME=TTYY.CASEGEN.SOURCE,MEMBER='dif

      "EXECIO * DISKW DOWNLOAD (FINIS"
      say 'EVCSERET: Transfer written'

    end /* pos('PROGREV',code.a) */
    otherwise nop
  end /* end select */
end /* do A=1 to code.0 */

exit

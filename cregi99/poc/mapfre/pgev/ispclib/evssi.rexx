/* REXX */
TRACE n
 parse arg element stgnum
 address tso
 /* search datasets allocated to LIB1 - 5 if stgnum is 2 */
 /* otherwise search datasets allocated to LIB2 - LIB5   */
 if stgnum = 2 then start = 1
    else start = 2
 DO I = start TO 5
   x = listdsi(lib || i   file)
   select
     when sysreason = 2 then iterate
     when sysreason = 0 then do

         status = sysdsn("'"sysdsname"("element")'")
         if status = 'OK' then do
           leave
         end /* */

     end /* sysreason = 0 */
     otherwise do

       say sysmsglvl1
       say sysmsglvl2
       exit sysreason

     end /* otherwise */
   end /* select */
 end /* loop */
 say sysdsname element status
 /* If member found generate amblist */
 if status = 'OK' then do
   QUEUE '  LISTLOAD MEMBER=('element'),OUTPUT=MODLIST,DDN=LIB'i
   "EXECIO "QUEUED()" DISKW SYSIN (FINIS)"
   address "LINKMVS" "AMBLIST"
   if rc > 4 then do
     say 'AMBLIST for SYSDSNAME ELEMENT failed' rc
     exit rc
   end /* amblist rc > 4 */
   do until readrc = 2          /* start looping through amblist */
     "execio 1 diskr sysprint"  /* read 1 line of amblist report */
     readrc = rc                /* return code from execio       */
     if readrc > 2 then do                    /* I/O error        */
        say 'Error reading sysprint from amblist' readrc    /*    */
        exit readrc
     end /* error reading amblist */
     pull line                  /* store line                    */
     w = FIND(line,'SSI:')
     if w > 0 then do
        w = w + 1
        ssi = word(line,w)
        say 'OLDSSI:' ssi
        if ssi = 'NONE' then do
          say 'SSI version set to 1'
          queue ' SETSSI 00000001'
        end /* NONE */
        else do
           ssi = x2d(ssi)
           ssi = ssi + 1
           say 'NEWSSI:' ssi
           ssi = d2x(ssi,8)
           queue ' SETSSI' ssi
           say 'SSI version incremented'
        end /* */
        leave
     end /* w > 0 */
     if readrc > 2 then do                    /* I/O error        */
        say 'Error reading sysprint from amblist' readrc    /*    */
        exit readrc
     end /* error reading amblist */
   end /* loop through amblist */
  end /* status OK */
  else do
      queue ' SETSSI 00000001'
      say 'SSI version set to 1'
  end /*      */
  "EXECIO "QUEUED()" DISKW SSI (FINIS)"
 EXIT 0

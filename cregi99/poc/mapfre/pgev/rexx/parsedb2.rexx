 /* REXX */                                                             00040001
 /*                                                            */       00050001
  debug = 0 /* switch off various say statements */                     00060001
  new_debug = 0 /* switch off latest debugging code */                  00070001
 /**************************************************************/       00080001
 /*                                                            */       00090001
 /*  EXEC to read a DB2  source program written in COBOL,      */       00100001
 /*  and police the use of commands.                           */       00110001
 /*                                                            */       00120001
 /*  This code basically assumes valid SQL - it does not take  */       00130001
 /*  on the Pre-Processor functions.  Items monitored are      */       00140001
 /*                                                            */       00150001
 /*  Reminder level:                                           */       00160001
 /*                                                            */       00170001
 /*  1) DELETE with no WHERE clause.                           */       00180001
 /*  2) UPDATE with no WHERE clause.                           */       00190001
 /*  3) Qualified table name in SELECT (these are not easy     */       00200001
 /*     to detect without a total parse of the statement,      */       00210001
 /*     and there may be false alarms).                        */       00220001
 /*                                                            */       00230001
 /*  Warning level:                                            */       00240001
 /*                                                            */       00250001
 /*  1) Absence of INCLUDE for SQLCA.                          */       00260001
 /*  2) CURSOR declared for update not used subsequently.      */       00270001
 /*  3) DCLGEN coded explicitly rather than INCLUDEd.          */       00280001
 /*  4) Presence of WHENEVER with CONTINUE.                    */       00290001
 /*                                                            */       00300001
 /*  Error level:                                              */       00310001
 /*                                                            */       00320001
 /*  1) Presence of WHENEVER other than CONTINUE               */       00330001
 /*  2) SELECT * in SELECTs, format 2 INSERTs, and CURSOR      */       00340001
 /*     declarations.                                          */       00350001
 /*  3) INSERT with no Column list.                            */       00360001
 /*                                                            */       00370001
 /**************************************************************/       00380001
 /*                                                            */       00390001
 /*  This procedure was written by John Wade.                  */       00400001
 /*                                                            */       00410001
 /**************************************************************/       00420001
                                                                        00430001
 signal on novalue                                                      00440001
                                                                        00450001
 /**************************************************************/       00460001
 PARSE SOURCE opsys type execname execdd execdsn,          /*LS*/       00470001
              execinv hostenv tsoenv usertok               /*LS*/       00480001
 /**************************************************************/       00490001
 /*  The efficiency of the read process is increased with the  */       00500001
 /* stack_size variable.  It can be increased, but if you      */       00510001
 /* hit ABENDs for GETMAIN failure, reduce it.                 */       00520001
 /**************************************************************/       00530001
    stack_size = 500                                                    00540001
 call Initialise                                                        00550001
 call Build_file_IO                                                     00560001
 do while end_file = 0                                                  00570001
    call Get_record                                                     00580001
    if end_file then leave                                              00590001
    if substr(record,7,1) = '*' then iterate                            00600001
 /**************************************************************/       00610001
 /* Process each record as it comes                            */       00620001
 /* EXEC SQL statements will almost always span across         */       00630001
 /* multiple input records.                                    */       00640001
 /**************************************************************/       00650001
    EXEC_pos = wordpos("EXEC SQL",record)                               00660001
    if EXEC_pos > 0 then do                                             00670001
       start_recno = recno                                              00680001
       complete_command = 1                                             00690001
 /**************************************************************/       00700001
 /* We are now into a real SQL statement, and have analysis    */       00710001
 /* to do on each.  We call Parse_EXEC_SQL for that.           */       00720001
 /* We expect to get a proper END-EXEC at the end of each      */       00730001
 /* statement, or we indicate an error.                        */       00740001
 /**************************************************************/       00750001
       call Parse_EXEC_SQL                                              00760001
       if complete_command then do                                      00770001
 /**************************************************************/       00780001
 /* Analyse_EXEC_SQL is a router for the various kinds of      */       00790001
 /* SQL verb.  We call this where we have a complete SQL stmt. */       00800001
 /**************************************************************/       00810001
          do i_i_i = 1 to maxlevel                                      00820001
             statement = string.i_i_i                                   00830001
             call Analyse_EXEC_SQL                                      00840001
          end                                                           00850001
       end                                                              00860001
       else do                                                          00870001
          outrec = heade 'Incomplete SQL command found at ' ,           00880001
                    start_recno '.'                                     00890001
          call Writer                                                   00900001
          call Store_error                                              00910001
          outrec = head 'It is not possible to analyse this command.'   00920001
          call Writer                                                   00930001
          outrec = head 'Please correct this and re-submit.'            00940001
          call Writer                                                   00950001
       end                                                              00960001
       iterate                                                          00970001
    end                                                                 00980001
 /**************************************************************/       00990001
 /* End of processing this record or SQL statement             */       01000001
 /**************************************************************/       01010001
 end                                                                    01020001
 /**************************************************************/       01030001
 /*  end of main processing loop                               */       01040001
 /**************************************************************/       01050001
 /*  Now must check to see if we had an INCLUDE for SQLCA      */       01060001
 /*  and whether there were unexploited update cursors.        */       01070001
 /**************************************************************/       01080001
 outrec = ' '                                                           01090001
 if include_for_SQLCA = 0 then do                                       01100001
    outrec = headw 'No INCLUDE for SQLCA'                               01110001
    call Writer                                                         01120001
    call Store_warning                                                  01130001
 end                                                                    01140001
 if cursor_no > 0 then do                                               01150001
    do i = 1 to cursor_no                                               01160001
       if cursor_used.i = 0 then do                                     01170001
          outrec = ' '                                                  01180001
          call Writer                                                   01190001
          outrec = heade 'Cursor ' cursor_name.i ' was declared ' ,     01200001
                   'for update '                                        01210001
          call Writer                                                   01220001
          outrec = head 'but was not referenced in DELETE or UPDATE.'   01230001
          call Writer                                                   01240001
          call store_error                                              01250001
       end                                                              01260001
    end                                                                 01270001
 end                                                                    01280001
 /**************************************************************/       01290001
 /* We now have to pull out the statement numbers for all      */       01300001
 /* statements that were flagged with errors, and to print     */       01310001
 /* some guidance on interpretation.                           */       01320001
 /**************************************************************/       01330001
 outrec = ' '                                                           01340001
 call Writer                                                            01350001
 call Writer                                                            01360001
 outrec = 'Parsing completed - maximum return code was: ' ,             01370001
     format(return_code,3)                                              01380001
 call Writer                                                            01390001
 outrec = ' '                                                           01400001
 call Writer                                                            01410001
 call Print_error_list                                                  01420001
 call Print_warning_list                                                01430001
 call Print_reminder_list                                               01440001
 call Print_explanations                                                01450001
 outrec = ' '                                                           01460001
 call Writer                                                            01470001
 outrec = 'Note that the return of a non-zero return code does NOT'     01480001
 call Writer                                                            01490001
 outrec = 'terminate the ENdevor processing.'                           01500001
 call Writer                                                            01510001
 outrec = ' '                                                           01520001
 call Writer                                                            01530001
 return return_code                                                     01540001
 /**************************************************************/       01550001
 /*  end of main procedure                                     */       01560001
 /**************************************************************/       01570001
 /**************************************************************/       01580001
 /*  Parse_EXEC SQL - read and accumulate to END-EXEC.         */       01590001
 /*  (If we find "EXEC SQL" in here, there is a missing        */       01600001
 /*  END-EXEC somewhere.)                                      */       01610001
 /**************************************************************/       01620001
 Parse_EXEC_SQL:                                                        01630001
   drop string.                                                         01640001
   if words(record) < EXEC_pos + 2 then                                 01650001
      statement = ''                                                    01660001
   else do                                                              01670001
      temp_record = subword(record,EXEC_pos+2)                          01680001
      END_EXEC_pos = pos("END-EXEC",temp_record) ,                      01690001
                   + pos("END-EXEC.",temp_record)                       01700001
      if END_EXEC_pos > 0 then do                                       01710001
         statement = substr(temp_record,1,END_EXEC_pos-1)               01720001
         call Regularise_EXEC_SQL                                       01730001
         return                                                         01740001
      end                                                               01750001
      else do                                                           01760001
         statement = temp_record                                        01770001
      end                                                               01780001
   end                                                                  01790001
   read_end = 0                                                         01800001
   do until read_end                                                    01810001
      call Get_record                                                   01820001
 /**************************************************************/       01830001
 /*  If we reach end-file in this context, the last EXEC SQL   */       01840001
 /*  in the program has no END-EXEC.                           */       01850001
 /**************************************************************/       01860001
      if end_file then do                                               01870001
         complete_command = 0                                           01880001
         return                                                         01890001
      end                                                               01900001
      if substr(record,7,1) = '*' then iterate                          01910001
 /**************************************************************/       01920001
 /*  If we find another EXEC SQL before the sought-for         */       01930001
 /*  END-EXEC, there is a missing END-EXEC.  We have no way    */       01940001
 /*  of knowing how much we've read through on the way, and    */       01950001
 /*  in any case this program has a defect that needs to be    */       01960001
 /*  corrected.                                                */       01970001
 /**************************************************************/       01980001
      EXEC_pos = find(record,"EXEC SQL")                                01990001
      if EXEC_pos > 0 then do                                           02000001
         outrec = heade 'Consecutive EXEC SQL commands ' ,              02010001
                  'with no END-EXEC in between.'                        02020001
         call Writer                                                    02030001
         call Store_error                                               02040001
         outrec = head 'Analysis will be incomplete. '                  02050001
         call Writer                                                    02060001
         outrec = head 'Preprocessor will reject this, ' ,              02070001
         call Writer                                                    02080001
         outrec = head 'so please correct before re-submission.'        02090001
         call Writer                                                    02100001
      end                                                               02110001
      END_EXEC_pos = pos("END-EXEC",record)                             02120001
      if END_EXEC_pos = 0 then do                                       02130001
         statement = statement strip(record)                            02140001
      end                                                               02150001
      else do                                                           02160001
         read_end = 1                                                   02170001
         temp_record = substr(record,1,END_EXEC_pos-1)                  02180001
         if words(temp_record) > 0 then                                 02190001
            statement = statement strip(temp_record)                    02200001
      end                                                               02210001
   end                                                                  02220001
   call Regularise_EXEC_SQL                                             02230001
 return                                                                 02240001
 /**************************************************************/       02250001
 /*  Regularise statement format and simplify for processing.  */       02260001
 /*  First thing is to remove redundant blanks.                */       02270001
 /*  Change all literal values in quotes to asterisks, to      */       02280001
 /*  ensure that we get no false "FIND" hits in later code     */       02290001
 /*  (e.g. the string "SELECT *" in a WHERE clause literal!)   */       02300001
 /*  Lastly we change all commas to ensure a blank fore and    */       02310001
 /*  aft - this allows REXX word functions to be used.         */       02320001
 /*  Likewise all ( and ).                                     */       02330001
 /*  We then remove all function references to simplify what   */       02340001
 /*  is left.                                                  */       02350001
 /**************************************************************/       02360001
 Regularise_EXEC_SQL:                                                   02370001
  /* */                                                                 02380001
  /* */                                                                 02390001
    if debug = 2 & statement <> ' ' then do                             02400001
       say "Statement to be regularised:"                               02410001
       junk = statement                                                 02420001
       call List_statement                                              02430001
    end                                                                 02440001
 /**************************************************************/       02450001
 /* Ensure spaces round bracketed code                         */       02460001
 /**************************************************************/       02470001
   newstring = ''                                                       02480001
   all_found = 0                                                        02490001
   do until all_found                                                   02500001
      pos = pos("(",statement)                                          02510001
      if pos = 0 then all_found = 1                                     02520001
      else do                                                           02530001
         PARSE VALUE statement WITH before "(" statement                02540001
         newstring = newstring strip(before) "("                        02550001
         PARSE VALUE statement WITH before ")" statement                02560001
         newstring = newstring  before  ")"                             02570001
      end                                                               02580001
   end                                                                  02590001
   newstring = newstring strip(statement)                               02600001
 /**************************************************************/       02610001
 /* Take out redundant blanks and rebuild in var "statementx"  */       02620001
 /**************************************************************/       02630001
   statementx = ''                                                      02640001
   j = words(newstring)                                                 02650001
   do i = 1 to j                                                        02660001
      statementx = statementx word(newstring,i)                         02670001
   end                                                                  02680001
 /* Put a weird character on the end to simplify end of string code */  02690001
   statementx = statementx '¯'                                          02700001
   quote = 0                                                            02710001
   double_quote = 0                                                     02720001
   len = length(statementx) - 1                                         02730001
   statement = " "                                                      02740001
 /*                                                                     02750001
   if debug then do                                                     02760001
      say 'statement stripped'                                          02770001
      junk = statementx                                                 02780001
      call List_statement                                               02790001
   end                                                                  02800001
    */                                                                  02810001
 /**************************************************************/       02820001
 /* Fix apostrophes in literals.                               */       02830001
 /**************************************************************/       02840001
   do i = 1 to len                                                      02850001
      test_char1 = substr(statementx,i,1)                               02860001
      test_char2 = substr(statementx,i+1,1)                             02870001
      select                                                            02880001
         when quote & test_char1 = "'" & test_char2 <> "'" then do      02890001
            quote = 0                                                   02900001
            statement = statement || "'"                                02910001
         end                                                            02920001
         when quote & test_char1 = "'" & test_char2 = "'" then do       02930001
            statement = statement || "*"                                02940001
            i = i + 1                                                   02950001
         end                                                            02960001
         when ^ quote & test_char1 = "'" & test_char2 = "'" then do     02970001
            statement = statement || test_char1 || test_char2           02980001
            i = i + 1                                                   02990001
         end                                                            03000001
         when ^ quote & test_char1 = "'" & test_char2 <> "'" then do    03010001
            statement = statement || "'"                                03020001
            quote = 1                                                   03030001
         end                                                            03040001
         otherwise                                                      03050001
            if quote then do                                            03060001
              statement = statement || '*'                              03070001
            end                                                         03080001
            else do                                                     03090001
               statement = statement || test_char1                      03100001
            end                                                         03110001
      end                                                               03120001
   end                                                                  03130001
 /**************************************************************/       03140001
 /* Ensure all commas are preceded and followed by blank.      */       03150001
 /* This means that they can be processed by word functions.   */       03160001
 /**************************************************************/       03170001
   string = statement                                                   03180001
   statement = ''                                                       03190001
   all_done = 0                                                         03200001
   do until all_done                                                    03210001
      if pos(',',string) = 0 then do                                    03220001
         all_done = 1                                                   03230001
         statement = statement string                                   03240001
      end                                                               03250001
      else do                                                           03260001
         parse VALUE string with front ',' back                         03270001
         statement = statement front ','                                03280001
         string = back                                                  03290001
      end                                                               03300001
   end                                                                  03310001
 /**************************************************************/       03320001
 /* Ensure all "("    are preceded and followed by blank.      */       03330001
 /* This means that they can be processed by word functions.   */       03340001
 /**************************************************************/       03350001
   string = statement                                                   03360001
   statement = ''                                                       03370001
   all_done = 0                                                         03380001
   do until all_done                                                    03390001
      if pos('(',string) = 0 then do                                    03400001
         all_done = 1                                                   03410001
         statement = statement string                                   03420001
      end                                                               03430001
      else do                                                           03440001
         parse VALUE string with front '(' back                         03450001
         statement = statement front '('                                03460001
         string = back                                                  03470001
      end                                                               03480001
   end                                                                  03490001
 /**************************************************************/       03500001
 /* Ensure all ")"    are preceded and followed by blank.      */       03510001
 /* This means that they can be processed by word functions.   */       03520001
 /**************************************************************/       03530001
   string = statement                                                   03540001
   statement = ''                                                       03550001
   all_done = 0                                                         03560001
   do until all_done                                                    03570001
      if pos(')',string) = 0 then do                                    03580001
         all_done = 1                                                   03590001
         statement = statement string                                   03600001
      end                                                               03610001
      else do                                                           03620001
         parse VALUE string with front ')' back                         03630001
         statement = statement front ')'                                03640001
         string = back                                                  03650001
      end                                                               03660001
   end                                                                  03670001
  /* */                                                                 03680001
 /**************************************************************/       03690001
 /* Now jettison all known function references - they only     */       03700001
 /* confuse the issue, and can't (currently) have table        */       03710001
 /* names in their argument strings.                           */       03720001
 /**************************************************************/       03730001
   if debug then do                                                     03740001
      say 'Entering new test code'                                      03750001
   end                                                                  03760001
   drop string.                                                         03770001
   level = 1                                                            03780001
   maxlevel = 1                                                         03790001
   prevlevel = 1                                                        03800001
   string.level = ' '                                                   03810001
   do i = 1 to length(statement)                                        03820001
      char = substr(statement,i,1)                                      03830001
      if char = '(' then do                                             03840001
         string.level = string.level '<<>>'                             03850001
         prevlevel = level                                              03860001
         level = maxlevel + 1                                           03870001
         maxlevel = level                                               03880001
         string.level = ' '                                             03890001
      end                                                               03900001
      string.level = string.level||char                                 03910001
      if char = ')' then do                                             03920001
         level = prevlevel                                              03930001
      end                                                               03940001
   end                                                                  03950001
  /* */                                                                 03960001
 return                                                                 03970001
 /* from Regularise_EXEC_SQL */                                         03980001
 /**************************************************************/       03990001
 /*  Analyse SQL  statement by type and subtype if necessary   */       04000001
 /**************************************************************/       04010001
 Analyse_EXEC_SQL:                                                      04020001
    parse var statement verb parameters                                 04030001
 /**************************************************************/       04040001
 /*  FROM specs and UNION occur in lots of statements.         */       04050001
 /**************************************************************/       04060001
    call Find_qualified_tablenames                                      04070001
    call Check_for_UNION                                                04080001
    call Check_for_SELECT_ASTERISK                                      04090001
 /**************************************************************/       04100001
 /*  Checks to be applied to specific commands or groups       */       04110001
 /**************************************************************/       04120001
  select                                                                04130001
 /**************************************************************/       04140001
 /*  Currently there are no SQL verbs that are banned, but     */       04150001
 /*  the code was inherited from the CICS Parser where some    */       04160001
 /*  CICS commands are banned.  This could be useful in the    */       04170001
 /*  future, so the code is left in place.                     */       04180001
 /**************************************************************/       04190001
    when find(banned_verbs,verb) > 0 then do                            04200001
       outrec = heade 'COMMAND ' verb ,                                 04210001
                ' not allowed without specific DBA approval.'           04220001
       call Writer                                                      04230001
       call Store_error                                                 04240001
    end                                                                 04250001
    when verb = "SELECT" then do                                        04260001
       call Process_SELECT                                              04270001
    end                                                                 04280001
    when verb = "INSERT" then do                                        04290001
       call Process_INSERT                                              04300001
    end                                                                 04310001
    when verb = "DELETE" then do                                        04320001
       call Process_DELETE                                              04330001
    end                                                                 04340001
    when verb = "UPDATE" then do                                        04350001
       call Process_UPDATE                                              04360001
    end                                                                 04370001
    when verb = "WHENEVER" then do                                      04380001
       call Process_WHENEVER                                            04390001
    end                                                                 04400001
    when verb = "INCLUDE" then do                                       04410001
       call Process_INCLUDE                                             04420001
    end                                                                 04430001
    when verb = "LOCK" then do                                          04440001
       call Process_LOCK                                                04450001
    end                                                                 04460001
    when verb = "CREATE" then do                                        04470001
       call Process_CREATE                                              04480001
    end                                                                 04490001
    when verb = "DECLARE" then do                                       04500001
       call Process_DECLARE                                             04510001
    end                                                                 04520001
    otherwise nop                                                       04530001
  end                                                                   04540001
  return                                                                04550001
 /**************************************************************/       04560001
 /* Analyse and process SELECT statements                      */       04570001
 /* Have they used SELECT * - directly or in SUBSELECT         */       04580001
 /**************************************************************/       04590001
  Process_SELECT:                                                       04600001
  /*                                                                    04610001
    call Check_for_SELECT_ASTERISK                                      04620001
     */                                                                 04630001
    if wordpos('COUNT (*)',parameters) > 0 then do                      04640001
       outrec = headw 'Do not use COUNT(*) solely to check existence'   04650001
       call Writer                                                      04660001
       outrec = head  'Please discuss with DBA for better ways.'        04670001
       call Writer                                                      04680001
       call Store_error                                                 04690001
    end                                                                 04700001
    if wordpos('MAX',parameters) > 0 ,                                  04710001
     | wordpos('MIN',parameters) > 0 then do                            04720001
       outrec = headr 'Please check that you have coded a NULL' ,       04730001
                      'indicator variable. '                            04740001
       call Writer                                                      04750001
       outrec = head  'Failure to do so can lead to incorrect results'. 04760001
       call Writer                                                      04770001
       call Store_reminder                                              04780001
    end                                                                 04790001
  return                                                                04800001
 /**************************************************************/       04810001
 /* Analyse and process DELETE statements                      */       04820001
 /* 1 Have they DELETEd with no WHERE clause?                  */       04830001
 /**************************************************************/       04840001
  Process_DELETE:                                                       04850001
    if wordpos('WHERE',parameters) = 0 then do                          04860001
       outrec = headw 'Did you intend to empty the table?'              04870001
       call Writer                                                      04880001
       call Store_warning                                               04890001
    end                                                                 04900001
    posd = wordpos('WHERE CURRENT OF',parameters)                       04910001
    if posd > 0 then do                                                 04920001
       posd = posd + 3                                                  04930001
       cname = word(parameters,posd)                                    04940001
       cno = wordpos(cname,cursor_list)                                 04950001
       cursor_used.cno = 1                                              04960001
    end                                                                 04970001
  return                                                                04980001
 /**************************************************************/       04990001
 /* Analyse and process UPDATE statements                      */       05000001
 /* 1 Have they UPDATEd with no WHERE clause?                  */       05010001
 /**************************************************************/       05020001
  Process_UPDATE:                                                       05030001
    if wordpos('WHERE',parameters) = 0 then do                          05040001
       outrec = headw 'Did you intend to update the whole table?'       05050001
       call Writer                                                      05060001
       call Store_warning                                               05070001
    end                                                                 05080001
    posc = wordpos('WHERE CURRENT OF',parameters)                       05090001
    if posc > 0 then do                                                 05100001
       posc = posc + 3                                                  05110001
       cname = word(parameters,posc)                                    05120001
       cno = wordpos(cname,cursor_list)                                 05130001
       cursor_used.cno = 1                                              05140001
    end                                                                 05150001
  return                                                                05160001
 /**************************************************************/       05170001
 /* Analyse and process CREATE                                 */       05180001
 /**************************************************************/       05190001
  Process_CREATE:                                                       05200001
    outrec = headw 'Please confirm use of CREATE with your DBA.'        05210001
    call Writer                                                         05220001
    call store_warning                                                  05230001
  return                                                                05240001
 /**************************************************************/       05250001
 /* Analyse and process LOCK                                   */       05260001
 /**************************************************************/       05270001
  Process_LOCK:                                                         05280001
     outrec = heade 'Please review use of LOCK TABLE with your DBA.'    05290001
     call Writer                                                        05300001
     call store_reminder                                                05310001
  return                                                                05320001
 /**************************************************************/       05330001
 /* Analyse and process INCLUDE                                */       05340001
 /* Check for presence of SQLCA                                */       05350001
 /**************************************************************/       05360001
  Process_INCLUDE:                                                      05370001
    if find(parameters,'SQLCA') > 0 then do                             05380001
       include_for_SQLCA = 1                                            05390001
    end                                                                 05400001
  return                                                                05410001
 /**************************************************************/       05420001
 /* Analyse and process WHENEVER                               */       05430001
 /**************************************************************/       05440001
  Process_WHENEVER:                                                     05450001
    if wordpos('CONTINUE',parameters) > 0 then do                       05460001
       outrec = headr 'WHENEVER ' parameters                            05470001
       call Writer                                                      05480001
       outrec = head 'is superfluous. ' ,                               05490001
                'Always check SQLCODE/SQLSTATE.'                        05500001
       call Writer                                                      05510001
       call Store_warning                                               05520001
    end                                                                 05530001
    else do                                                             05540001
       outrec = heade 'WHENEVER ' parameters                            05550001
       call Writer                                                      05560001
       outrec = head 'should not be coded. ' ,                          05570001
                'Always check SQLCODE/SQLSTATE.'                        05580001
       call Writer                                                      05590001
       call Store_error                                                 05600001
    end                                                                 05610001
  return                                                                05620001
 /**************************************************************/       05630001
 /* Analyse and process DECLARE statements.  Cases covered:    */       05640001
 /* 1)  GLOBAL TEMPORARY TABLE                                 */       05650001
 /* 2)  CURSOR                                                 */       05660001
 /* 3)  TABLE (DCLGEN)                                         */       05670001
 /* There may be other DECLARE options - the code asks for     */       05680001
 /* John Wade to be notified if any are found.                 */       05690001
 /**************************************************************/       05700001
 Process_DECLARE:                                                       05710001
    if wordpos('GLOBAL TEMPORARY TABLE',parameters) > 0 then do         05720001
       outrec = headw 'Please review use of TEMP TABLE with your DBA.'  05730001
       call Writer                                                      05740001
       call store_warning                                               05750001
       return                                                           05760001
    end                                                                 05770001
    if find(parameters,'CURSOR') > 0 then do                            05780001
       if wordpos('FOR UPDATE',parameters) > 0 then do                  05790001
          cname = word(parameters,1)                                    05800001
          cursor_no = cursor_no + 1                                     05810001
          cursor_list = cursor_list cname                               05820001
          cursor_name.cursor_no = cname                                 05830001
          cursor_used.cursor_no = 0                                     05840001
       end                                                              05850001
       return                                                           05860001
    end                                                                 05870001
    if word(parameters,2) = 'TABLE' then do                             05880001
       outrec = heade 'DCLGENs should be brought in by INCLUDE.'        05890001
       call Writer                                                      05900001
       call store_error                                                 05910001
       return                                                           05920001
    end                                                                 05930001
    outrec = headr 'Unidentified form of DECLARE. ' ,                   05940001
             'Sorry - please check it.'                                 05950001
    call Writer                                                         05960001
    call store_error                                                    05970001
    outrec = head     'If valid please contact John Wade to get ' ,     05980001
             'this code amended.'                                       05990001
    call Writer                                                         06000001
    call store_error                                                    06010001
 return                                                                 06020001
 /**************************************************************/       06030001
 /* Analyse and process INSERT statements                      */       06040001
 /* 1) Is column list present                                  */       06050001
 /* 2) For Format 2 INSERT, have they used SELECT *            */       06060001
 /**************************************************************/       06070001
  Process_INSERT:                                                       06080001
 /**************************************************************/       06090001
 /* Identify whether it is INSERT .. VALUES or INSERT .. SELECT*/       06100001
 /**************************************************************/       06110001
    table_name = word(parameters,2)                                     06120001
    insert_valid = 0                                                    06130001
    values_pos = wordpos('VALUES',parameters)                           06140001
    if values_pos > 0 then do                                           06150001
       insert_valid = 1                                                 06160001
       insert_type = 'VALUES'                                           06170001
    end                                                                 06180001
    select_pos = wordpos('SELECT',parameters)                           06190001
    if select_pos > 0 then do                                           06200001
       insert_valid = 1                                                 06210001
       insert_type = 'SELECT'                                           06220001
    end                                                                 06230001
 /**************************************************************/       06240001
 /* Complain if we have both VALUES and SUBSELECT, or if we    */       06250001
 /* have neither - we can;t really proceed with the analysis.  */       06260001
 /**************************************************************/       06270001
    if ^ insert_valid then do                                           06280001
       outrec = heade ,                                                 06290001
                'INSERT has neither VALUES nor SELECT option '          06300001
       call Writer                                                      06310001
       call Store_error                                                 06320001
       return                                                           06330001
    end                                                                 06340001
    if values_pos > 0 & select_pos > 0 then do                          06350001
       outrec = heade ,                                                 06360001
                'INSERT has VALUES and a SUBSELECT '                    06370001
       call Writer                                                      06380001
       call Store_error                                                 06390001
       return                                                           06400001
    end                                                                 06410001
    column_list_found = 1                                               06420001
    if values_pos = 3 ,                                                 06430001
     | select_pos = 3 then do                                           06440001
       outrec = heade ,                                                 06450001
                'INSERT has no Column List '                            06460001
       call Writer                                                      06470001
       call Store_error                                                 06480001
       column_list_found = 0                                            06490001
    end                                                                 06500001
 /*                                                                     06510001
    if insert_type = 'SELECT' then do                                   06520001
       call Check_for_SELECT_ASTERISK                                   06530001
    end                                                                 06540001
    */                                                                  06550001
  return                                                                06560001
  Process_DECLARE_DCLGEN:                                               06570001
 /**************************************************************/       06580001
 /* This code is left n place, but is no longer called.  The   */       06590001
 /* standard states that DCLGENs should be dynamically brought */       06600001
 /* in by INCLUDE, not coded in line.                          */       06610001
 /**************************************************************/       06620001
     table_name = word(parameters,1)                                    06630001
     qual_pos = pos('.',table_name)                                     06640001
     if qual_pos > 0 then do                                            06650001
        table_qualifier = substr(table_name,1,qual_pos-1)               06660001
        table_name_pure = substr(table_name,qual_pos+1)                 06670001
        outrec = headw ,                                                06680001
                'DCLGEN for ' table_name_pure 'Is qualified by '        06690001
        call Writer                                                     06700001
        outrec = head table_qualifier||'.  Please check.'               06710001
        call Writer                                                     06720001
        call Store_warning                                              06730001
     end                                                                06740001
  return                                                                06750001
 /**************************************************************/       06760001
 /* Check UNION statements and ask if UNION ALL would be       */       06770001
 /* better.                                                    */       06780001
 /**************************************************************/       06790001
  Check_for_UNION:                                                      06800001
     stringu = statement                                                06810001
     do forever                                                         06820001
        upos = wordpos('UNION',stringu)                                 06830001
        if upos = 0 then do                                             06840001
           return                                                       06850001
        end                                                             06860001
        if word(stringu,upos+1) <> 'ALL' then do                        06870001
           outrec = headw 'Please discuss with DBA - ' ,                06880001
                    'would UNION ALL be better?'                        06890001
           call Writer                                                  06900001
           call store_warning                                           06910001
           return                                                       06920001
        end                                                             06930001
        stringu = subword(stringu,upos+1)                               06940001
     end                                                                06950001
  return                                                                06960001
 /**************************************************************/       06970001
 /* SELECT * is banned in all contexts.                        */       06980001
 /**************************************************************/       06990001
  Check_for_SELECT_ASTERISK:                                            07000001
    if word(parameters,1) = '*' then do                                 07010001
       outrec = heade 'SELECT * is unacceptable.'                       07020001
       call Writer                                                      07030001
       outrec = head 'Please code an explicit column list.'             07042002
       call Writer                                                      07050001
       outrec = head '(Ignore this if you coded "SELECT COUNT (*)")'    07051003
       call Writer                                                      07052003
       call Store_error                                                 07060001
    end                                                                 07070001
  return                                                                07080001
 /**************************************************************/       07090001
 /* Try to find evidence of qualified table names.  it is      */       07100001
 /* easy to find the start of a FROM list, but very hard       */       07110001
 /* to find where it ends, with the possibility of nested      */       07120001
 /* SELECT AS in the middle of the list.                       */       07130001
 /**************************************************************/       07140001
 Find_qualified_tablenames:                                             07150001
    if word(statement,1) = 'DECLARE' ,                                  07160001
     & word(statement,3) = 'TABLE' then return                          07170001
    if wordpos(word(statement,1),no_tnames_list) > 0 then return        07180001
    current_level = 1                                                   07190001
    highest_level = 1                                                   07200001
    all_done = 0                                                        07210001
    string.1 = statement                                                07220001
    if debug then do                                                    07230001
       say ' '                                                          07240001
       say 'Scanning for qualified table names'                         07250001
       say ' '                                                          07260001
       junk = statement                                                 07270001
       call List_statement                                              07280001
       say ' '                                                          07290001
       call List_stack                                                  07300001
       say ' '                                                          07310001
    end                                                                 07320001
    do until all_done                                                   07330001
       if pos('(',string.current_level) = 0 then do                     07340001
          if current_level = highest_level then do                      07350001
             all_done = 1                                               07360001
             iterate                                                    07370001
          end                                                           07380001
          else do                                                       07390001
             current_level = current_level + 1                          07400001
             if debug then do                                           07410001
                say ' '                                                 07420001
                say 'Gone to level ' current_level                      07430001
             end                                                        07440001
          end                                                           07450001
       end                                                              07460001
       bracket_count = 0                                                07470001
       call find_bracketed_text                                         07480001
       if bracket_found then do                                         07490001
          call stow_bracketed_text                                      07500001
       end                                                              07510001
    end                                                                 07520001
    do i = 1 to highest_level                                           07530001
       if debug then do                                                 07540001
          say 'String ' i ' started ===>'                               07550001
          junk = string.i                                               07560001
          call List_statement                                           07570001
          say ' <== '                                                   07580001
       end                                                              07590001
       statementx = string.i                                            07600001
       call Report_qualified_tablenames                                 07610001
       statementx = string.i                                            07620001
       call Check_joined_tables                                         07630001
    end                                                                 07640001
 return                                                                 07650001
 find_bracketed_text:                                                   07660001
    bracket_found = 0                                                   07670001
    do i = 1 to length(string.current_level)                            07680001
       tester = substr(string.current_level,i,1)                        07690001
       if tester = '(' then do                                          07700001
          if bracket_count = 0 then do                                  07710001
             start_bracket = i                                          07720001
          end                                                           07730001
          bracket_count = bracket_count + 1                             07740001
          bracket_found = 1                                             07750001
       end                                                              07760001
       if tester = ')' then do                                          07770001
          bracket_count = bracket_count - 1                             07780001
          if bracket_count = 0 then do                                  07790001
             end_bracket = i                                            07800001
             i = length(string.current_level)                           07810001
             bracket_length = end_bracket - start_bracket               07820001
          end                                                           07830001
       end                                                              07840001
    end                                                                 07850001
 return                                                                 07860001
 stow_bracketed_text:                                                   07870001
    if debug then do                                                    07880001
       say ' '                                                          07890001
       say '"stow_bracketed_text entered"'                              07900001
       say ' '                                                          07910001
    end                                                                 07920001
    highest_level = highest_level + 1                                   07930001
    string.highest_level ,                                              07940001
    = substr(string.current_level,start_bracket+1,bracket_length-2)     07950001
    if debug then do                                                    07960001
       if string.current_level <> save_string then do                   07970001
         save_string = string.current_level                             07980001
         call List_stack                                                07990001
       end                                                              08000001
       else do                                                          08010001
          say '**** are we in a loop?'                                  08020001
          say 'start_bracket  =     ' start_bracket                     08030001
          say '  end_bracket  =     ' end_bracket                       08040001
          say 'bracket_length =     ' bracket_length                    08050001
          say 'current string =     '                                   08060001
          junk = string.current_level                                   08070001
          call List_statement                                           08080001
          say 'highest_level  =     ' highest_level                     08090001
          say 'working back through strings ... '                       08100001
          do xxx = 1 to highest_level                                   08110001
             print_string = string.xxx                                  08120001
             say ' '                                                    08130001
             say format(xxx,3)                                          08140001
             junk = print_string                                        08150001
             call List_statement                                        08160001
          end                                                           08170001
          exit 999                                                      08180001
       end                                                              08190001
    end                                                                 08200001
 /* */                                                                  08210001
 /* */                                                                  08220001
    temp1 = substr(string.current_level,1,start_bracket-1)              08230001
    temp2 = substr(string.current_level,end_bracket+1)                  08240001
    string.current_level = temp1 '¯¯' temp2                             08250001
 /* */                                                                  08260001
    if debug then do                                                    08270001
       say 'current string from  '                                      08280001
       junk = temp1                                                     08290001
       call List_statement                                              08300001
       say '                     '                                      08310001
       say '   and               '                                      08320001
       say '                     '                                      08330001
       junk = temp2                                                     08340001
       call List_statement                                              08350001
       say '                     '                                      08360001
       say 'previous string    = '                                      08370001
       x = current_level - 1                                            08380001
       junk = string.x                                                  08390001
       call List_statement                                              08400001
       say '                     '                                      08410001
    end                                                                 08420001
  return                                                                08430001
 /**************************************************************/       08440001
 /* Look for standard FROM-lists                               */       08450001
 /**************************************************************/       08460001
  Report_qualified_tablenames:                                          08470001
      stringx = statementx                                              08480001
      if debug then do                                                  08490001
         junk = stringx                                                 08500001
         call List_statement                                            08510001
         say ' '                                                        08520001
      end                                                               08530001
      do forever                                                        08540001
         if wordpos('SELECT',stringx) = 0 then return                   08550001
         parse VALUE stringx WITH front 'FROM' main_set                 08560001
         wpos1 = wordpos('WHERE',main_set)                              08570001
         if wpos1 = 0 then wpos1 = 99999                                08580001
         wpos2 = wordpos('ORDER BY',main_set)                           08590001
         if wpos2 = 0 then wpos2 = 99999                                08600001
         wpos3 = wordpos('GROUP BY',main_set)                           08610001
         if wpos3 = 0 then wpos3 = 99999                                08620001
         wpos4 = wordpos('JOIN',main_set)                               08630001
         if wpos4 = 0 then wpos4 = 99999                                08640001
         wpos5 = wordpos('ON',main_set)                                 08650001
         if wpos5 = 0 then wpos5 = 99999                                08660001
         wpos = min(wpos1,wpos2,wpos3,wpos4,wpos5)                      08670001
         if wpos > 0 ,                                                  08680001
          & wpos < 99999 then do                                        08690001
            table_list = subword(main_set,1,wpos)                       08700001
            stringx = subword(main_set,wpos+1)                          08710001
        end                                                             08720001
        else do                                                         08730001
           table_list = main_set                                        08740001
           stringx = ''                                                 08750001
        end                                                             08760001
        if debug then do                                                08770001
           say 'Table_list '                                            08780001
           say table_list                                               08790001
           say ' '                                                      08800001
        end                                                             08810001
        dotpos = pos('.',table_list)                                    08820001
        if dotpos > 0 then do                                           08830001
           tfront = substr(table_list,1,dotpos-1)                       08840001
           tfront = word(tfront,words(tfront))                          08850001
           tback  = word(substr(table_list,dotpos),1)                   08860001
           tname = tfront||tback                                        08870001
           if tfront <> 'SYSIBM'    ,                                   08880001
            & datatype(front,'N') = 0 ,                                 08890001
            & datatype(back,'N')  = 0    then do                        08900001
              outrec = headr 'Possible qualified table name ' ,         08910001
                             tname ||'.'                                08920001
              call Writer                                               08930001
              call Store_reminder                                       08940001
              outrec = head 'Please check.'                             08950001
              call Writer                                               08960001
              qualified_report = 1                                      08970001
           end                                                          08980001
        end                                                             08990001
     end                                                                09000001
  return                                                                09010001
 /**************************************************************/       09020001
 /* Look for table names following "JOIN"                      */       09030001
 /**************************************************************/       09040001
  Check_joined_tables:                                                  09050001
     do forever                                                         09060001
        if wordpos('JOIN',statementx) = 0 then do                       09070001
           return                                                       09080001
        end                                                             09090001
        parse VALUE statementx WITH front 'JOIN' back                   09100001
        tname = word(back,1)                                            09110001
        dotpos = pos('.',tname)                                         09120001
        if dotpos > 0 then do                                           09130001
           tfront = substr(tname,1,dotpos-1)                            09140001
           if tfront <> 'SYSIBM'    ,                                   09150001
            & datatype(front,'N') = 0 ,                                 09160001
            & datatype(back,'N')  = 0    then do                        09170001
              outrec = headr 'Possible qualified table name ' ,         09180001
                             tname ||'.'                                09190001
              call Writer                                               09200001
              call Store_reminder                                       09210001
              outrec = head 'Please check.'                             09220001
              call Writer                                               09230001
              qualified_report = 1                                      09240001
           end                                                          09250001
        end                                                             09260001
        statementx = back                                               09270001
     end                                                                09280001
  return                                                                09290001
 /**************************************************************/       09300001
 /* Store a warning for end of program listing                 */       09310001
 /**************************************************************/       09320001
 Store_warning:                                                         09330001
    if start_recno > warning_list.warnings then do                      09340001
       warnings = warnings + 1                                          09350001
       warning_list.warnings = start_recno                              09360001
    end                                                                 09370001
    if return_code < warning_code then do                               09380001
       return_code = warning_code                                       09390001
    end                                                                 09400001
 return                                                                 09410001
 /**************************************************************/       09420001
 /* Store an error for end of program listing                  */       09430001
 /**************************************************************/       09440001
 Store_error:                                                           09450001
    if start_recno > error_list.errors then do                          09460001
       errors = errors + 1                                              09470001
       error_list.errors = start_recno                                  09480001
    end                                                                 09490001
    if return_code < error_code then do                                 09500001
       return_code = error_code                                         09510001
    end                                                                 09520001
 return                                                                 09530001
 /**************************************************************/       09540001
 /* Store a reminder for end of program listing                */       09550001
 /**************************************************************/       09560001
 Store_reminder:                                                        09570001
    if start_recno > reminder_list.reminders then do                    09580001
       reminders = reminders + 1                                        09590001
       reminder_list.reminders = start_recno                            09600001
    end                                                                 09610001
    if return_code < reminder_code then do                              09620001
       return_code = reminder_code                                      09630001
    end                                                                 09640001
 return                                                                 09650001
 /**************************************************************/       09660001
 /* Extract a keyword and parameter from the statement string. */       09670001
 /**************************************************************/       09680001
 Get_argument:                                                          09690001
       Parse Arg keyword string                                         09700001
       getA_pos = find(string,keyword)                                  09710001
       if getA_pos = 0 then return ' '                                  09720001
       else do                                                          09730001
          getA_value = word(string,(getA_pos+1))    /* sk */            09740001
          if getA_value = '('                                           09750001
          then getA_value = word(string,(getA_pos+2))                   09760001
          getA_value = strip(getA_value,'L','(')                        09770001
          getA_value = strip(getA_value,'T',')')                        09780001
       end                                                              09790001
 return getA_value                                                      09800001
 /**************************************************************/       09810001
 /* End of extract a keyword and parameter from the statement. */       09820001
 /**************************************************************/       09830001
 Push_record:                                                           09840001
 /**************************************************************/       09850001
 /*  Code to push line back into stack.                        */       09860001
 /**************************************************************/       09870001
    push ' '||record                                                    09880001
    recno = recno - 1                                                   09890001
    records_in_stack = records_in_stack + 1                             09900001
 return                                                                 09910001
 Get_record:                                                            09920001
 /**************************************************************/       09930001
 /*  Code to read next source code line.                       */       09940001
 /**************************************************************/       09950001
 if records_in_stack = 0 then do                                        09960001
    READ                                                                09970001
    if rc ^= 0 & rc ^= 2 then signal Disk_read_error                    09980001
    records_in_stack = QUEUED()                                         09990001
 end                                                                    10000001
 if records_in_stack = 0 then do                                        10010001
    end_file = 1                                                        10020001
    return                                                              10030001
 end                                                                    10040001
 parse pull Get_record_temp                                             10050001
 /* say 'Input:' Get_record_temp */                                     10060001
 /**************************************************************/       10070001
 /*  Snip off possible sequence numbers in columns 1-6 / 73-78 */       10080001
 /**************************************************************/       10090001
 record = "      "||substr(Get_record_temp,7,66)                        10100001
 recno = recno + 1                                                      10110001
 records_in_stack = records_in_stack - 1                                10120001
 /* say 'Output:' record */                                             10130001
 outrec = format(recno,5) substr(record,7)                              10140001
 call Writer                                                            10150001
 return                                                                 10160001
 Writer:                                                                10170001
 /**************************************************************/       10180001
 /*  Code to write/list records                                */       10190001
 /**************************************************************/       10200001
 /*    say outrec    */                                                 10210001
       push outrec                                                      10220001
       WRITE_LINE                                                       10230001
 return                                                                 10240001
 /**************************************************************/       10250001
 /* Print list of statements containing error-level messages.  */       10260001
 /**************************************************************/       10270001
 Print_error_list:                                                      10280001
 outrec = 'Error count was     :' format(errors,5)                      10290001
 call Writer                                                            10300001
 outrec = ' '                                                           10310001
 call Writer                                                            10320001
 if errors > 0 then do                                                  10330001
    outlist = ' '                                                       10340001
    line_count = 0                                                      10350001
    do i = 1 to errors                                                  10360001
       outlist = outlist format(error_list.i,5)                         10370001
       line_count = line_count + 1                                      10380001
       if line_count = line_limit then do                               10390001
          outrec = outlist                                              10400001
          call Writer                                                   10410001
          outlist = ' '                                                 10420001
          line_count = 0                                                10430001
       end                                                              10440001
    end                                                                 10450001
    if outlist <> ' ' then do                                           10460001
       outrec = outlist                                                 10470001
       call Writer                                                      10480001
    end                                                                 10490001
 end                                                                    10500001
 return                                                                 10510001
 /****************************************************************/     10520001
 /* Print list of statements containing warning-level messages.  */     10530001
 /****************************************************************/     10540001
 Print_warning_list:                                                    10550001
 outrec = ' '                                                           10560001
 call Writer                                                            10570001
 call Writer                                                            10580001
 outrec = 'Warning count was   :' format(warnings,5)                    10590001
 call Writer                                                            10600001
 outrec = ' '                                                           10610001
 call Writer                                                            10620001
 if warnings > 0 then do                                                10630001
    outlist = ' '                                                       10640001
    line_count = 0                                                      10650001
    do i = 1 to warnings                                                10660001
       outlist = outlist format(warning_list.i,5)                       10670001
       line_count = line_count + 1                                      10680001
       if line_count = line_limit then do                               10690001
          outrec = outlist                                              10700001
          call Writer                                                   10710001
          outlist = ' '                                                 10720001
          line_count = 0                                                10730001
       end                                                              10740001
    end                                                                 10750001
    if outlist <> ' ' then do                                           10760001
       outrec = outlist                                                 10770001
       call Writer                                                      10780001
    end                                                                 10790001
 end                                                                    10800001
 return                                                                 10810001
 /****************************************************************/     10820001
 /* Print list of statements containing reminder-level messages. */     10830001
 /****************************************************************/     10840001
 Print_reminder_list:                                                   10850001
 outrec = ' '                                                           10860001
 call Writer                                                            10870001
 call Writer                                                            10880001
 outrec = 'Reminder count was   :' format(reminders,5)                  10890001
 call Writer                                                            10900001
 outrec = ' '                                                           10910001
 call Writer                                                            10920001
 if reminders > 0 then do                                               10930001
    outlist = ' '                                                       10940001
    line_count = 0                                                      10950001
    do i = 1 to reminders                                               10960001
       outlist = outlist format(reminder_list.i,5)                      10970001
       line_count = line_count + 1                                      10980001
       if line_count = line_limit then do                               10990001
          outrec = outlist                                              11000001
          call Writer                                                   11010001
          outlist = ' '                                                 11020001
          line_count = 0                                                11030001
       end                                                              11040001
    end                                                                 11050001
    if outlist <> ' ' then do                                           11060001
       outrec = outlist                                                 11070001
       call Writer                                                      11080001
    end                                                                 11090001
 end                                                                    11100001
 return                                                                 11110001
 /****************************************************************/     11120001
 /* Print explanations of content of output listing.             */     11130001
 /****************************************************************/     11140001
 Print_explanations:                                                    11150001
 outrec = " "                                                           11160001
 call Writer                                                            11170001
 outrec = " Meanings of return code levels: "                           11180001
 call Writer                                                            11190001
 outrec = " =============================== "                           11200001
 call Writer                                                            11210001
 outrec = " "                                                           11220001
 call Writer                                                            11230001
 outrec = " Return code  24  = Reminder "                               11240001
 call Writer                                                            11250001
 outrec = " "                                                           11260001
 call Writer                                                            11270001
 outrec = ,                                                             11280001
     "   This means that there are potential danger spots in your"      11290001
 call Writer                                                            11300001
 outrec = ,                                                             11310001
     "   code that need a visual check, because the analysis cannot"    11320001
 call Writer                                                            11330001
 outrec = ,                                                             11340001
     "   be automated, OR that you are using unusual options. "         11350001
 call Writer                                                            11360001
 outrec = ,                                                             11370001
     "   There may not be anything wrong at all."                       11380001
 call Writer                                                            11390001
 outrec = ,                                                             11400001
     "             "                                                    11410001
 call Writer                                                            11420001
 call Writer                                                            11430001
 outrec = ,                                                             11440001
     " Return code  28  = Warning "                                     11450001
 call Writer                                                            11460001
 outrec = ,                                                             11470001
     "             "                                                    11480001
 call Writer                                                            11490001
 outrec = ,                                                             11500001
     "   This means that you are using functions that are constricted " 11510001
 call Writer                                                            11520001
 outrec = ,                                                             11530001
     "   in their use.  The EXEC cannot ascertain whether you comply "  11540001
 call Writer                                                            11550001
 outrec = ,                                                             11560001
     "   or not.  You need to check the context before going to TDA. "  11570001
 call Writer                                                            11580001
 outrec = ,                                                             11590001
     "             "                                                    11600001
 call Writer                                                            11610001
 outrec = ,                                                             11620001
     "             "                                                    11630001
 call Writer                                                            11640001
 outrec = ,                                                             11650001
     " Return code 32  = Error "                                        11660001
 call Writer                                                            11670001
 outrec = ,                                                             11680001
     " "                                                                11690001
 call Writer                                                            11700001
 outrec = ,                                                             11710001
     "   This means that you are using some Command or Option "         11720001
 call Writer                                                            11730001
 outrec = ,                                                             11740001
     "   which will not be passed by TDA. "                             11750001
 call Writer                                                            11760001
 outrec = ,                                                             11770001
     " "                                                                11780001
 call Writer                                                            11790001
 call Writer                                                            11800001
 return                                                                 11810001
 /**************************************************************/       11820001
 /*  Code to set variables to initial states.                  */       11830001
 /**************************************************************/       11840001
 Initialise:                                                            11850001
 /**************************************************************/       11860001
 /*  Do not change the initial settings of any of these        */       11870001
 /* variables.                                                 */       11880001
 /**************************************************************/       11890001
    recno = 0                                                           11900001
    return_code = 0                                                     11910001
    end_file = 0                                                        11920001
    EXECct = 0                                                          11930001
    records_in_stack = 0                                                11940001
    nuller = "'*'"                                                      11950001
    realone = "' '"                                                     11960001
    error_code      = 32                                                11970001
    warning_code    = 28                                                11980001
    reminder_code   = 24                                                11990001
    errors     = 0                                                      12000001
    warnings   = 0                                                      12010001
    reminders  = 0                                                      12020001
    error_list.0 = 0                                                    12030001
    warning_list.0 = 0                                                  12040001
    reminder_list.0 = 0                                                 12050001
    abstime    = ' '                                                    12060001
    absline    = 0                                                      12070001
    include_for_SQLCA    = 0                                            12080001
    heade      = '*!!* Error    **** '                                  12090001
    headw      = '*!!* Warning  **** '                                  12100001
    headr      = '*!!* Reminder **** '                                  12110001
    head       = '                   '                                  12120001
    banned_verbs = 'PREPARE' ,                                          12130001
                   'DROP'                                               12140001
    line_limit = 12                                                     12150001
    cursor_no  = 0                                                      12160001
    cursor_list  = ''                                                   12170001
    no_tnames_list = 'SET' ,                                            12180001
                     'PREPARE'                                          12190001
    functions_list = 'AVG'               ,                              12200001
                     'COUNT'             ,                              12210001
                     'COUNT_BIG'         ,                              12220001
                     'MAX'               ,                              12230001
                     'MIN'               ,                              12240001
                     'STDDEV'            ,                              12250001
                     'STDDEV_POP'        ,                              12260001
                     'STDDEV_SAMP'       ,                              12270001
                     'SUM'               ,                              12280001
                     'VARIANCE'          ,                              12290001
                     'VAR'               ,                              12300001
                     'VAR_POP'           ,                              12310001
                     'VAR_SAMP'          ,                              12320001
                     'VARIANCE_SAMP'     ,                              12330001
                     'ABS'               ,                              12340001
                     'ABSVAL'            ,                              12350001
                     'ACOS'              ,                              12360001
                     'ADD_MONTHS'        ,                              12370001
                     'ASIN'              ,                              12380001
                     'ATAN'              ,                              12390001
                     'ATANH'             ,                              12400001
                     'ATAN2'             ,                              12410001
                     'BLOB'              ,                              12420001
                     'CCSID_ENCODING'    ,                              12430001
                     'CEILING'           ,                              12440001
                     'CEIL'                                             12450001
    functions_list = functions_list      ,                              12460001
                     'CHAR'              ,                              12470001
                     'CLOB'              ,                              12480001
                     'COALESCE'          ,                              12490001
                     'CONCAT'            ,                              12500001
                     'COS'               ,                              12510001
                     'COSH'              ,                              12520001
                     'DATE'              ,                              12530001
                     'DAY'               ,                              12540001
                     'DAYOFMONTH'        ,                              12550001
                     'DAYOFWEEK'         ,                              12560001
                     'DAYOFWEEKISO'      ,                              12570001
                     'DAYOFYEAR'         ,                              12580001
                     'DAYS'              ,                              12590001
                     'DBCLOB'            ,                              12600001
                     'DECIMAL'           ,                              12610001
                     'DEC'               ,                              12620001
                     'DEGREES'           ,                              12630001
                     'DIGITS'            ,                              12640001
                     'DOUBLE'            ,                              12650001
                     'DOUBLE_PRECISION'  ,                              12660001
                     'EXP'               ,                              12670001
                     'FLOAT'             ,                              12680001
                     'FLOOR'             ,                              12690001
                     'GENERATE_UNIQUE'   ,                              12700001
                     'GRAPHIC'           ,                              12710001
                     'HEX'               ,                              12720001
                     'HOUR'              ,                              12730001
                     'IDENTITY_VAL_LOCAL' ,                             12740001
                     'IFNULL'            ,                              12750001
                     'INSERT'            ,                              12760001
                     'INTEGER'           ,                              12770001
                     'INT'               ,                              12780001
                     'JULIAN_DAY'        ,                              12790001
                     'LAST_DAY'          ,                              12800001
                     'LCASE'             ,                              12810001
                     'LOWER'                                            12820001
    functions_list = functions_list      ,                              12830001
                     'LEFT'              ,                              12840001
                     'LENGTH'            ,                              12850001
                     'LN'                ,                              12860001
                     'LOCATE'            ,                              12870001
                     'LOG10'             ,                              12880001
                     'LTRIM'             ,                              12890001
                     'MAX'               ,                              12900001
                     'MICROSECOND'       ,                              12910001
                     'MIDNIGHT_SECONDS'  ,                              12920001
                     'MIN'               ,                              12930001
                     'MINUTE'            ,                              12940001
                     'MOD'               ,                              12950001
                     'MONTH'             ,                              12960001
                     'MQPUBLISH'         ,                              12970001
                     'MQREAD'            ,                              12980001
                     'MQREADCLOB'        ,                              12990001
                     'MQRECEIVE'         ,                              13000001
                     'MQRECEIVECLOB'     ,                              13010001
                     'MQSEND'            ,                              13020001
                     'MQSUBSCRIBE'       ,                              13030001
                     'MQUNSUBSCRIBE'     ,                              13040001
                     'MULTIPLY_ALT'      ,                              13050001
                     'NEXT_DAY'          ,                              13060001
                     'NULLIF'            ,                              13070001
                     'POSSTR'            ,                              13080001
                     'POWER'             ,                              13090001
                     'QUARTER'           ,                              13100001
                     'RADIANS'           ,                              13110001
                     'RAISE_ERROR'       ,                              13120001
                     'RAND'              ,                              13130001
                     'REAL'              ,                              13140001
                     'REPEAT'            ,                              13150001
                     'RIGHT'             ,                              13160001
                     'ROUND'             ,                              13170001
                     'ROUND_TIMESTAMP'                                  13180001
    functions_list = functions_list      ,                              13190001
                     'ROWID'             ,                              13200001
                     'RTRIM'             ,                              13210001
                     'SECOND'            ,                              13220001
                     'SIGN'              ,                              13230001
                     'SIN'               ,                              13240001
                     'SINH'              ,                              13250001
                     'SMALLINT'          ,                              13260001
                     'SPACE'             ,                              13270001
                     'SQRT'              ,                              13280001
                     'STRIP'             ,                              13290001
                     'SUBSTR'            ,                              13300001
                     'TAN'               ,                              13310001
                     'TANH'              ,                              13320001
                     'TIME'              ,                              13330001
                     'TIMESTAMP'         ,                              13340001
                     'TIMESTAMP_FORMAT'  ,                              13350001
                     'TRUNC_TIMESTAMP'   ,                              13360001
                     'UCASE'             ,                              13370001
                     'UPPER'             ,                              13380001
                     'VARCHAR'           ,                              13390001
                     'VARCHAR_FORMAT'    ,                              13400001
                     'VARGRAPHIC'        ,                              13410001
                     'WEEK'              ,                              13420001
                     'WEEK_ISO'          ,                              13430001
                     'YEAR'              ,                              13440001
                     'MQREADALL'         ,                              13450001
                     'MQREADALLCLOB'     ,                              13460001
                     'MQRECEIVEALL'      ,                              13470001
                     'MQRECEIVEALLCLOB'                                 13480001
 return                                                                 13490001
 Build_file_IO:                                                         13500001
    READ = 'EXECIO' stack_size 'DISKR INFILE'                           13510001
    WRITE_LINE = 'EXECIO 1 DISKW DB2CHECK '                             13520001
    WRITE_FINIS = 'EXECIO 1 DISKW DB2CHECK (FINIS)'                     13530001
 return                                                                 13540001
 Disk_read_error:                                                       13550001
    say 'Error has arisen during disk file read.'                       13560001
    exit 8                                                              13570001
                                                                        13580001
 List_stack:                                                            13590001
    if highest_level > 0 then do                                        13600001
       do y_y_y = highest_level to 1 by -1                              13610001
          say ' '                                                       13620001
          say 'Content of stack item ' format(y_y_y,3)                  13630001
          junk = string.y_y_y                                           13640001
          call List_statement                                           13650001
       end                                                              13660001
    end                                                                 13670001
    return                                                              13680001
                                                                        13690001
 List_statement:                                                        13700001
    if junk = ' ' then do                                               13710001
       say '>>null<<'                                                   13720001
       return                                                           13730001
    end                                                                 13740001
    do x_x_x = 1 to length(junk) by 60                                  13750001
       say substr(junk,x_x_x,60)                                        13760001
    end                                                                 13770001
 return                                                                 13780001
                                                                        13790001
 NOVALUE:                                                               13800001
  say 'An error was caused by an uninitialised value in statement ' ,   13810001
      SIGL                                                              13820001
  say "SOURCELINE"(sigl)                                                13830001
  say ' '                                                               13840001
  say 'The Parser was unable to complete analysis of this program.'     13850001
  say 'This can happen in cases where the from-lists are hard to ' ,    13860001
      'identify.'                                                       13870001
  say 'It does not imply that the program is in error.'                 13880001
  say ' '                                                               13890001
  say 'Further Endevor processing is not affected by this.'             13900001
  say ' '                                                               13910001
  say ' Value of start_recno            : ' start_recno                 13920001
  say ' '                                                               13930001
  say ' Value of reminders              : ' reminders                   13940001
  say ' '                                                               13950001
  say ' Value of reminder_list.reminders: ' reminder_list.reminders     13960001
  say ' '                                                               13970001
  exit 0                                                                13980001

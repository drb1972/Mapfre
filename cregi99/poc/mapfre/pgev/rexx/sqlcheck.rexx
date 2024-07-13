/*--------------------------REXX----------------------------*\
 *  Check SQL elements for:                                 *
 *  - Correct table qualifier                               *
 *  - Matching SELECT before UPDATE/DELETE/INSERT           *
 *  - COMMIT after full table delete                        *
 *  - WHERE is coded on UPDATE/DELETE/INSERT                *
 *  - and more                                              *
 *                                                          *
 *  This rexx is executed from GSQL.                        *
\*----------------------------------------------------------*/
trace n

parse arg c1element c1prgrp c1sy c1ccid stack_size c1comment
say
say 'SQLCHECK: ' DATE() TIME()
say 'SQLCHECK:  *** Input parameters ***'
say 'SQLCHECK:'
say 'SQLCHECK:  c1element..' c1element
say 'SQLCHECK:  c1prgrp....' c1prgrp
say 'SQLCHECK:  c1sy.......' c1sy
say 'SQLCHECK:  c1ccid.....' c1ccid
say 'SQLCHECK:  stack_size.' stack_size
say 'SQLCHECK:  c1comment..' c1comment

valid_cmds = 'SELECT INSERT DELETE UPDATE COMMIT LOCK SET ALTER'

errors = 0  /* Flag for errors found                                 */
schema = '' /* Table qualifier if SET CURRENT SCHEMA is used         */

if left(c1prgrp,3) ^= 'SQL' then
  call db2parms_call   /* Get the prod qualifier for this proc group */

call build_stmts   /* Read the SQL and build the stem variables */

sel_tbl_list = ''         /* List of select table names       */
sel_list     = ''         /* Positions of unprocessed selects */

/* Now check the each SQL statement is valid        */
do i = 1 to stmt_count

  command = word(stmt.i,1)

  /* Check each command */
  select

    /* Check the command is valid (DROP etc are not coded) */
    when wordpos(command,valid_cmds) = 0 then do
      call write 'SQLCHECK: Line' line_num.i
      call write 'SQLCHECK: Command' command 'is not allowed'
      call write 'SQLCHECK: Statement:' left(stmt.i,100)
      call write
    end /* wordpos(command,valid_cmds) = 0 */

    /* Check SET statements are valid      */
    when command = 'SET' then do
      if left(word(stmt.i,2),6)       ^= 'SCHEMA'         & ,
         left(word(stmt.i,2),14)      ^= 'CURRENT_SCHEMA' & ,
         left(subword(stmt.i,2,2),14) ^= 'CURRENT SCHEMA' & ,
         left(subword(stmt.i,2,2),13) ^= 'CURRENT SQLID'  then do
        call write 'SQLCHECK: Line' line_num.i
        call write 'SQLCHECK: Command' subword(stmt.i,2,2) 'is not allowed'
        call write 'SQLCHECK: Statement:' left(stmt.i,100)
        call write
      end
      else
        call check_schema
    end /* command = 'SET' */

    when command = 'ALTER' then
       if word(stmt.i,2) ^= 'TABLESPACE' | ,
         wordpos('LOCKSIZE',stmt.i) = 0  then do
        call write 'SQLCHECK: Line' line_num.i
        call write 'SQLCHECK: ONLY ALTER TABLESPACE .... LOCKSIZE... is allowed'
        call write 'SQLCHECK: Statement:' left(stmt.i,100)
        call write ' '
      end /* word(stmt.i,2) ^= 'TABLESPACE' .... */

    when command = 'LOCK' & ,
         wordpos('IN EXCLUSIVE MODE',stmt.i) > 0 & ,
         left(c1comment,7) ^= '**FORCE' then do
      call write 'SQLCHECK: Line' line_num.i
      call write 'SQLCHECK: "LOCK TABLE tablename IN EXCLUSIVE MODE"' ,
                 'found.'
      call write 'SQLCHECK: This will make the table unavailable while',
                 'the SQL is running.'
      call write 'SQLCHECK: Are you sure you want to continue?'
      call write 'SQLCHECK: If you do then GENERATE or UPDATE the SQL element'
      call write 'SQLCHECK: with an Endevor comment of' ,
                 '"**FORCE <rest of comment>"'
      call write 'SQLCHECK: Statement:' left(stmt.i,100)
      call write ' '
    end /* command = 'LOCK' & .... */

    /* Check SELECT */
    when command = 'SELECT' then do
      /* Check the table qualifiers match the processor group */
      if left(c1prgrp,3) ^= 'SQL' then
        call check_qualifier
      sel_list = sel_list i
    end /* command = 'SELECT' */

    /* Check UPDATE DELETE INSERT */
    when wordpos(command,'UPDATE DELETE INSERT') > 0 then do
      if command ^= 'INSERT' then
        /* Check a where clause exists */
        call check_where
      /* Check a prev SELECT table matches the current table */
      call check_select 'preceded' 'previous'
      /* Check the table qualifiers match the processor group */
      if left(c1prgrp,3) ^= 'SQL' then
        call check_qualifier
    end /* wordpos(command,'UPDATE DELETE INSERT') > 0 */

    otherwise nop

  end /* select */

end /* i = 1 to stmt_count */

/* Now go backwards through the statements to ensure that updating */
/* statements have a following matching SELECT statement           */
sel_tbl_list = ''         /* List of select table names       */
sel_list     = ''         /* Positions of unprocessed selects */
do i = stmt_count to 1 by -1
  command = word(stmt.i,1)
  select
    when command = 'SELECT' then
      sel_list = sel_list i
    when wordpos(command,'UPDATE DELETE INSERT') > 0 then
      /* Check a following SELECT table matches the current table */
      call check_select 'followed' 'following'
    otherwise nop
  end /* select */
end

/* If any errors have been written then close the README file */
if errors then
  call close_readme

say 'SQLCHECK: ' DATE() TIME()

exit

/*---------------------- S U B R O U T I N E S -----------------------*/

/*-------------------------------------------------------------------*/
/* DB2parms_call                                                     */
/*-------------------------------------------------------------------*/
db2parms_call:

/* Temporary overrides until the processor groups are sorted out     */
prgrp      = c1prgrp
prgrp_pos6 = substr(prgrp,6,1)
select
  when prgrp_pos6 = 'L' then   /* DL Germany                         */
    prgrp = overlay('F',prgrp,6)
  when prgrp_pos6 = 'I' then   /* DL Italy                           */
    prgrp = overlay('E',prgrp,6)
  otherwise nop
end /* select                                                        */

prgrp = 'X'right(prgrp,7) /* If its a backout group                  */

 x = db2parms(prgrp 'PROD' c1sy'1' 'SQL')  /* Call db2parms          */
 if x ^= 0 then
   call exception 16 'Call to DB2PARMS failed. RC =' x

 lines = queued()

 do i = 1 to lines
   pull data.i
 end

 if lines > 1 & ,
    pos(prgrp_pos6,'E F I L Z' > 0) then do
   say 'SQLCHECK: Processor group' c1prgrp 'is multi instance.'
   say 'SQLCHECK: Type SQL is only valid for single instance executions'
   exit 12
 end /* lines > 1 */

 parse value data.1 with dbsub dbqual dbown dbcoll dbwlm dbracf ,
                         db2inst desc dbiso dbcur dbdeg dbrel dbreo ,
                         dbval dbkdyn dbdynr dblkn prodown dbenc

 say 'SQLCHECK: Recieved parms from DB2PARMS:'
 say 'SQLCHECK: DBQUAL.........' dbqual
 say

 dbqual_len = length(dbqual)

return /* db2parms_call */

/*---------------------------------------------------------------*/
/* Build statements                                              */
/*---------------------------------------------------------------*/
build_stmts:

 stmt_count    = 0         /* Statement counter          */
 sql_line      = 0         /* SQL input file line number */
 remainder     = ''        /* Any words after a ;        */
 quote_found   = 'N'       /* To handle text in quotes   */
 bracket_found = 'N'       /* To handle /* */ comments   */
 full_stmt     = ''        /* Built up full statement    */

 do forever              /* until the eof */

   if remainder ^= '' then do /* if there are words after a semicolon */
     line      = remainder
     line_num  = sql_line
     remainder = ''
   end /* remainder ^= '' */
   else do
     call read_line        /* Read the next line from the file  */
     if eof = 'Y' then
       leave
   end /* else */

   call strip_line         /* strip the line of comments & text */

   if full_stmt = '' then  /* first line of a statement         */
     line_num  = sql_line

   full_stmt = full_stmt line  /* build up the full statement   */

   if eo_stmt = 'Y' then   /* found a semicolon so end of stmt  */
     call set_stmt_vars

 end /* do forever */

 if full_stmt ^= '' then   /* last line */
   call set_stmt_vars

 say
 say 'SQLCHECK: Total number of SQL statements =' stmt_count
 say

return /* build_stmts */

/*---------------------------------------------------------------*/
/* Read_line - Get a line from the SQL element                   */
/*---------------------------------------------------------------*/
read_line:

 if queued() = 0 then do
   /* N.B. Stack size is used to make the code more efficient */
   "execio" stack_size "diskr SQL"
   readrc = rc
   if readrc   = 2 & ,        /* EOF */
      queued() = 0 then do
     "execio 0 diskr SQL (finis"   /* close the file */
     eof = 'Y'
     return
   end /* readrc   = 2 & queued() = 0 */
   if readrc > 2 then                     /* I/O error                */
     call exception 20 'Execio diskr from SQL failed RC =' rc
 end /* queued() = 0 */

 sql_line = sql_line + 1      /* Total lines read                     */
 pull line
 line = left(line,72)

 if line = '' then /* If the line is blank */
   call read_line

return /* read_line */

/*---------------------------------------------------------------*/
/* Strip_line - Remove comments and text between quotes          */
/*---------------------------------------------------------------*/
strip_line:

 found1 = 'N'       /* Found a bracketed comment or quoted text */

 select

   /* If the first character is an * then its a comment line */
   when full_stmt    = ''  & ,
        left(line,1) = '*' then
     line = ''

   when quote_found   = 'Y' then /* There was a quote on the last   */
     call remove_quote           /* line, look for endquote on this */

   when bracket_found = 'Y' then  /* There was a bracket on the last */
     call remove_bracket          /* line, look for endbrckt on this */

   otherwise do
     com_pos   = pos('--',line)
     qt_st_pos = pos("'",line)
     br_st_pos = pos('/*',line)
     semi_pos  = pos(';',line)
     /* Set all not found values to a high value */
     /* to make comparing easier                 */
     if com_pos = 0 then
       com_pos = 100
     if qt_st_pos = 0 then
       qt_st_pos = 100
     if br_st_pos = 0 then
       br_st_pos = 100
     if semi_pos = 0 then
       semi_pos = 100

     /* We dont want to strip text btwn quotes from a SET statement */
     if  word(full_stmt,1)  = 'SET' | ,
         (full_stmt     = ''     & ,
           word(line,1) = 'SET') then
       qt_st_pos = 100

     /* Find out which is the first (if there are any) */
     select
       when semi_pos < qt_st_pos & ,
            semi_pos < br_st_pos & ,
            semi_pos < com_pos   then do     /* Semicolon found 1st   */
         remainder = substr(line,semi_pos+1)
         line      = left(line,semi_pos-1)
         eo_stmt = 'Y'                       /* End of statement      */
       end

       when com_pos < qt_st_pos & ,
            com_pos < br_st_pos & ,
            com_pos < semi_pos  then         /* -- comment found 1st  */
         line = left(line,com_pos-1)         /* Remove the comment    */

       when qt_st_pos < com_pos   & ,
            qt_st_pos < br_st_pos & ,
            qt_st_pos < semi_pos  then       /* Quote found 1st       */
         call remove_quote                   /* Remove txt btwn quotes*/

       when br_st_pos < com_pos   & ,
            br_st_pos < qt_st_pos & ,
            br_st_pos < semi_pos  then       /* Bracketed comment 1st */
         call remove_bracket                 /* Remove txt btwn brckts*/

       otherwise nop

     end /* select */
   end /* otherwise */
 end /* select */

 if quote_found   = 'N' & ,
    bracket_found = 'N' & ,
    found1        = 'Y' then    /* Found a complete comment or quote */
   call strip_line              /* so check the rest of the line     */

return /* strip_line */

/*---------------------------------------------------------------*/
/* Remove_quote - Remove anything between quotes                 */
/*---------------------------------------------------------------*/
remove_quote:

 qt_st_pos = pos("'",line)

 if quote_found = 'Y' then          /* - Quote found on previous line */
   if qt_st_pos = 0 then            /* - but not on this line         */
     line = ''                      /* - so this line is all text     */
   else do                          /* - End quote found on this line */
     line = substr(line,qt_st_pos+1) /* remove all before quote   */
     quote_found = 'N'
     found1 = 'Y'
   end /* else */
 else
   if qt_st_pos > 0 then do           /* - Found a quote on this line   */
     quote_found = 'Y'
     qt_end_pos = pos("'",line,qt_st_pos+1)
     if qt_end_pos > 0 then do
       line = left(line,qt_st_pos-1) '""' substr(line,qt_end_pos+1)
       quote_found = 'N'
       found1 = 'Y'
     end /* qt_end_pos > 0 */
     else
       line = left(line,qt_st_pos-1) '""'
   end /* qt_st_pos > 0 */

return /* remove_quote */

/*---------------------------------------------------------------*/
/* Remove_bracket - Remove bracketed comments                    */
/*                  (These I believe are valid in DB2V9)         */
/*---------------------------------------------------------------*/
remove_bracket:

 br_st_pos = pos('/*',line)

 if bracket_found = 'Y' then
 /* br_st_pos = 0       then */
   br_st_pos = 1

 if br_st_pos > 0 then do
   bracket_found = 'Y'
   br_end_pos = pos('*/',line)
   if br_end_pos > 0 then do
     line = left(line,br_st_pos-1) substr(line,br_end_pos+2)
     bracket_found = 'N'
     found1 = 'Y'
   end /* br_end_pos > 0 */
   else
     line = left(line,br_st_pos-1)
 end /* br_st_pos > 0 */

return /* remove_bracket */

/*---------------------------------------------------------------*/
/* Set_stmt_vars                                                 */
/*---------------------------------------------------------------*/
set_stmt_vars:

   full_stmt = translate(full_stmt,' ','05'x) /* convert to spaces */
   full_stmt = strip(space(full_stmt),l,'(')
   if word(full_stmt,1) = 'SELECT*' then
     full_stmt = 'SELECT *' subword(full_stmt,2)

   if full_stmt ^= '' then do
     /* Got the full statement so save it */
     stmt_count = stmt_count + 1
     line_num.stmt_count = line_num
     stmt.stmt_count     = full_stmt
     say 'Line' right(line_num.stmt_count,7)':' stmt.stmt_count

     /* Set up the list of table name(s) for each statement */
     command = word(full_stmt,1)
     if wordpos(command,'UPDATE DELETE INSERT SELECT') > 0 then do
       select
         when command = 'UPDATE' then
           tbl_pos = 2
         when wordpos(command,'DELETE INSERT') > 0 then
           tbl_pos = 3
         when command = 'SELECT' then
           tbl_pos = wordpos('FROM',full_stmt) + 1
         otherwise nop
       end /* select */
       tbl_name = word(full_stmt,tbl_pos)
       nxt_word = tbl_pos + 1
       call resolve_table_name nxt_word full_stmt
       if command = 'SELECT' then    /* could have multiple tables */
         call get_select_tables full_stmt
       tbl.stmt_count = tbl_name

     end /* wordpos(command,'UPDATE DELETE INSERT SELECT') > 0 */
   end /* full_stmt ^= ' ' */

   full_stmt = ''        /* Built up full statement    */
   eo_stmt   = 'N'

return /* set_stmt_vars */

/*---------------------------------------------------------------*/
/* Get_select_tables - Get the table names from a SELECT stmt.   */
/* E.g. SELECT * FROM tbl1 a, tbl2 b, tbl3,c ......              */
/*---------------------------------------------------------------*/
get_select_tables:
arg clause

 parse var clause with . 'SELECT' . 'FROM' tables 'WHERE' .
 nxt_word = 2
 do until pos(',',subword(tables,nxt_word)) = 0
   select
     when right(word(tables,nxt_word),1) = ',' then do
       nxt_word = nxt_word + 1
       tbl_name = tbl_name word(tables,nxt_word)
       nxt_word = nxt_word + 1
     end
     when left(word(tables,nxt_word+1),1) = ',' then do
       nxt_word = nxt_word + 1
       tbl_name = tbl_name strip(word(tables,nxt_word),l',')
       nxt_word = nxt_word + 1
     end
     when word(tables,nxt_word+1) = ',' then do
       nxt_word = nxt_word + 2
       tbl_name = tbl_name word(tables,nxt_word)
       nxt_word = nxt_word + 1
     end
     otherwise do
       x = pos(',',subword(tables,nxt_word))
       tbl_name = tbl_name substr(word(tables,nxt_word),x+1)
       nxt_word = nxt_word + 1
     end
   end /* select */
   call resolve_table_name nxt_word tables
 end /* do until pos(',',subword(tables,nxt_word)) */

 /* If theres a UNION clause then get the rest of the table names */
 union_pos = wordpos('UNION',clause,nxt_word)
 if union_pos > 0 then do
   tbl_pos = wordpos('FROM',clause,union_pos) + 1
   tbl_name = tbl_name word(full_stmt,tbl_pos)
   call get_select_tables subword(clause,union_pos+1)
 end

return /* get_select_tables */

/*---------------------------------------------------------------*/
/* Resolve table name                                            */
/* Qualified tables can have spaces - SELECT * FROM GRP . TABLE  */
/*---------------------------------------------------------------*/
Resolve_table_name:
 arg nxt_word tables

 select
   when right(tbl_name,1) = '.' then do
     tbl_name = tbl_name || word(tables,nxt_word)
     nxt_word = nxt_word + 1
   end
   when word(tables,nxt_word) = '.' then do
     nxt_word = nxt_word + 1
     tbl_name = tbl_name'.'word(tables,nxt_word)
     nxt_word = nxt_word + 1
   end
   when left(word(tables,nxt_word),1) = '.' then do
     tbl_name = tbl_name || word(tables,nxt_word)
     nxt_word = nxt_word + 1
   end
   otherwise nop
 end /* select */

 x = pos('(',tbl_name)
 if x > 0 then
   tbl_name = left(tbl_name,x-1)
 tbl_name = strip(tbl_name,t,',')

return /* Resolve_table_name */

/*---------------------------------------------------------------*/
/* check_schema    - Check and get the schema name               */
/*---------------------------------------------------------------*/
check_schema:

 /* Get the schema name from the SET statement */
 stmt = space(stmt.i,0)         /* strip out spaces */
 eq_pos = pos('=',stmt)
 if eq_pos > 0 then
   new_schema = substr(stmt,eq_pos+1)
 else
   new_schema = word(stmt.i,words(stmt.i)) /* its the last word */
 new_schema = strip(new_schema,t,';')
 new_schema = strip(new_schema,,"'")

 /* You cant change the schema from one thing to another */
 if schema ^= '' & ,
    schema ^= new_schema then do
   call write 'SQLCHECK: Line' line_num.i
   call write 'SQLCHECK: You can not change the CURRENT SCHEMA' ,
              'from' schema 'to' new_schema
   call write 'SQLCHECK: Statement:' left(stmt.i,100)
   call write ' '
 end
 schema = new_schema

return /* check_schema */

/*---------------------------------------------------------------*/
/* Check_where     - Check a WHERE clause exists                 */
/*---------------------------------------------------------------*/
check_where:

 where_pos = wordpos('WHERE',stmt.i)
 if where_pos = 0  then do
   if command = 'DELETE' then do
     zz = i + 1
     if word(stmt.zz,1) ^= 'COMMIT' then do
       call write 'SQLCHECK: Line' line_num.i
       call write 'SQLCHECK: Full table DELETE statements must be' ,
                  'immediately followed'
       call write 'SQLCHECK: by a COMMIT statement.'
       call write 'SQLCHECK: Statement:' left(stmt.i,100)
       call write ' '
     end
   end
   if left(c1comment,7) ^= '**FORCE' then do
     call write 'SQLCHECK: Line' line_num.i
     call write 'SQLCHECK:' command 'statements should have WHERE coded.'
     select
       when command = 'DELETE' then
         call write 'SQLCHECK: Without a WHERE it will empty the table.'
       when command = 'UPDATE' then
         call write 'SQLCHECK: Without a WHERE it will update the',
                    'whole column.'
       otherwise nop
     end /* select */
     call write 'SQLCHECK: Are you sure you want to continue?'
     call write 'SQLCHECK: If you do then GENERATE or UPDATE the SQL element'
     call write 'SQLCHECK: with an Endevor comment of' ,
                '"**FORCE <rest of comment>"'
     call write 'SQLCHECK: Statement:' left(stmt.i,100)
     call write ' '
   end /* left(c1comment,7) ^= '**FORCE' */
 end /* where_pos = 0 */

return /* check_where */

/*---------------------------------------------------------------*/
/* Check_select    - Check the table name on the INSERT,         */
/*                   UPDATE or DELETE statements has a matching  */
/*                   preceeding or following SELECT statement.   */
/*---------------------------------------------------------------*/
check_select:

 parse arg comm1 comm2

 /* Get the table name for the current statement.            */
 /* There will only be one table for an UPDATE/INSERT/DELETE */
 tbl_name = tbl.i
 if pos('.',tbl_name) > 0 then
   parse value tbl_name with qual '.' tbl_name

 /* Build up the list of previous/next select table names */
 if sel_list ^= '' then do
   do z = 1 to words(sel_list)
     sel_stmt_no = word(sel_list,z)
     sel_tbls  = translate(tbl.sel_stmt_no,' ','.')
     do zz = 1 to words(sel_tbls)
       tbl = word(sel_tbls,zz)
       if wordpos(tbl,sel_tbl_list) = 0 then
         sel_tbl_list = sel_tbl_list tbl
     end
   end
   sel_list = ''
 end

 /* Is there a matching SELECT statement */
 if wordpos(tbl_name,sel_tbl_list) = 0 then do
   call write 'SQLCHECK: Line' line_num.i
   call write 'SQLCHECK:' command 'statements must be' comm1 ,
              'by a matching select statement'
   call write 'SQLCHECK: Statement:' left(stmt.i,100)
   call write ' '
 end

return /* check_select */

/*---------------------------------------------------------------*/
/* Check_qualifier - table qualifier = processor group instance  */
/*---------------------------------------------------------------*/
check_qualifier:

 tbl_name = tbl.i
 tbl_qualifier = ''

 if pos('.',tbl_name) > 0 then
   parse value tbl_name with tbl_qualifier '.' .
 else
   if schema ^= '' then
     tbl_qualifier = schema

 if tbl_qualifier = '' then do
   call write 'SQLCHECK: Line' line_num.i
   call write 'SQLCHECK: No table qualifier specified'
   call write 'SQLCHECK: Statement:' left(stmt.i,100)
   call write ' '
 end /* dotpos = 0 */
 else do
   if substr(prgrp,5,1) = 'X' then do
     tbl_qualifier_t = tbl_qualifier
     dbqual_t        = dbqual
   end /* substr(prgrp,5,1) = 'X' */
   else do /* Ignore char 4 for quals with database type set */
     tbl_qualifier_t = overlay('%',tbl_qualifier,4)
     dbqual_t        = overlay('%',dbqual,4)
   end /* else */
   if left(tbl_qualifier_t,dbqual_len) ^= dbqual_t then do
     call write 'SQLCHECK: Line' line_num.i
     call write 'SQLCHECK: Processor group' c1prgrp 'is for qualifier',
                dbqual_t
     call write 'SQLCHECK: but the SQL statement has a table' ,
                'qualifier of' tbl_qualifier_t
     call write ' '
   end /* tbl_qualifier ^= dbqual */
 end /* else */

return /* check_qualifier */

/*---------------------------------------------------------------*/
/* Write 1 line to the ouput                                     */
/*---------------------------------------------------------------*/
write:
 parse arg outline

 if errors = 0 then do
   x = listdsi(SQL file)
   outline.1 = ''
   outline.2 = 'SQLCHECK: Checking element' c1element
   outline.3 = 'SQLCHECK: Member:' sysdsname'('c1element')'
   outline.4 = ''
   outlines = 4
   do zz = 1 to stmt_count
     outlines = outlines + 1
     outline.outlines = 'Line' right(line_num.zz,7)':' stmt.zz
   end
   outlines = outlines + 1
   outline.outlines = ' '
   "execio" outlines "diskw README (stem outline."
   if rc > 1 then
     call exception 16 'Execio diskw to README failed RC =' rc
   drop outline.
   errors = 1
 end

 outline.1 = outline
 "execio 1 diskw README (stem outline."
 if rc > 1 then
   call exception 16 'Execio diskw to README failed RC =' rc

return /* write */

/*---------------------------------------------------------------*/
/* Close readme                                                 */
/*---------------------------------------------------------------*/
Close_Readme:

 out.1 = '  If you can not resolve this error yourself then either' ,
         'contact'
 out.2 = 'VERTIZOS@kyndryl.com '
 out.4 = ''

 "execio 4 diskw README (finis stem out."
 if rc ^= 0 then
   call exception 16 'Execio diskw to README failed RC =' rc

exit 12 /* Close_Readme */

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 /* clear down the stem variables */
 drop outline.
 drop line_num.
 drop stmt.

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

 if return_code = 20 then do /* EXECIO DISKR error */
   outline.1 = 'SQLCHECK: You have encountered a read error on file',
               'SQL for element' c1element
   outline.2 = 'SQLCHECK: This may be due "Storage not available"' ,
               'if the SQL member is large.'
   outline.3 = 'SQLCHECK: Try increasing the region size on you job',
               'card by temporarily'
   outline.4 = 'SQLCHECK: coding ",REGION=128M"'
   "execio 4 diskw README (finis stem outline."
   if rc ^= 0 then
     say 'SQLCHECK: Execio diskw to README failed RC =' rc
 end /* return_code = 20 */

exit return_code

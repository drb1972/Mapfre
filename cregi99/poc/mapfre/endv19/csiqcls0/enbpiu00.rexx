/*     REXX                                                           */
/*     Copyright (C) 2022 Broadcom. All rights reserved.              */
/*                                                                    */
/*     For doing "Table" Searches and variable substitutions similar  */
/*     to that done by ISPF file tailoring.                           */
/*                                                                    */
/*     TBL#TOOL is a former name for ENBPIU00.                        */
/*                                                                    */
/*     The ENBPIU00 tool is a generic "Table lookup" Rexx routine.    */
/*     It processes all or selected rows of an input table. For each  */
/*     processed row, output is written based on the row's content    */
/*     and a selected "Model" (similar to a dialog skeleton).         */
/*                                                                    */
/*     Values for symbolics are provided within the table, or an      */
/*     alternative source, then expanded within the "Model" to        */
/*     produce output.                                                */
/*                                                                    */
/*                                                                    */
/*     Features-                                                      */
/*     - Allows simple, user-friendly methods for                     */
/*       defining input data and for formatting of outputs            */
/*     - Provides optional searching for                              */
/*       user-provided search criteria                                */
/*     - Frequently a simple alternative to writing your              */
/*       own program                                                  */
/*                                                                    */
/*     Unlike file tailoring, ENBPIU00 has these advantages-          */
/*     - Does not require ISPF services... ie can run under IRXJCL    */
/*       or as a compiled rexx or load module.                        */
/*     - Allows variable names to be a mixture of upper and lower     */
/*       case characters, and up to 250 characters in length. Not     */
/*       limited to 8 character upper case variable names like        */
/*       file tailoring.                                              */
/*     - Provides a "smart" variable substitution. Only variables     */
/*       that have values assigned to them are substituted.           */
/*       Other variables are written to the output still without      */
/*       being substituted.  This feature allows a cascading          */
/*       affect where you may want to use multiple tables to          */
/*       provide values for substitutions against a single table.     */
/*       You can use ENBPIU00 to bypass substitutions for PROC        */
/*       variables, Endevor variables and others that you want        */
/*       remain untouched.  You do not have to count the periods      */
/*       as you do in file tailoring. If needed, you can use a        */
/*       $delimiter value when concatentaing variables. For           */
/*       example, if $delimiter = "^"  then,                          */
/*          &variable#1^&variable#2                                   */
/*       concatenates values correctly.                               */
/*     - Provides a dynamic specification for inputs and outputs.     */
/*       There must be one input file given a name of TABLE.          */
/*                                                                    */
/*     Files used by ENBPIU00 include the following-                  */
/*     o TABLE - required input file in one of 3 allowed formats-     */
/*          1) A report image. The first line contains a special      */
/*             character in column 1 which defines the line as a      */
/*             'heading'.  All remaining lines of the Table are       */
/*             detail rows of the Table. Variable names are the       */
/*             words found found in the heading. The 'heading'        */
/*             uses dash '-' or asterisk '*' or plus-sign '+'         */
/*             characters to surround the variable names, and         */
/*             define the starting and ending positions of each       */
/*             column of data within the table.                       */
/*          2) A fixed-data format. Each field falls into a fixed     */
/*             position. No 'heading' is present. Instead, a          */
/*             DDname of POSITION defines the beginning and           */
/*             ending locations for each variable. Variable names     */
/*             (and their locations) are defined in the POSITION      */
/*             file.                                                  */
/*          3) A Comma Separated Value format. This type of table     */
/*             does not easily support searching of tables since the  */
/*             variables are defined by the CSV header.               */
/*          4) A word-counted table. The first line contains a        */
/*             special character in column 1 which defines the        */
/*             line as a 'heading'. All remaining lines of the        */
/*             Table are detail rows of the Table. Variable names     */
/*             are the words found found in the heading. Data         */
/*             within the table does not fall within specific         */
/*             positions, but are identified as the words of each     */
/*             row. For example, the first word in the heading        */
/*             provides a variable name to be used for the first      */
/*             word of each row. The n'th word in the heading         */
/*             provides a variable name to be used for the n'th       */
/*             work of each row. The heading must not contain         */
/*             dash '-' or asterisk '*' or plus-sign '+'              */
/*             characters.                                            */
/*                                                                    */
/*           If the user does not specify which kind of table         */
/*           is being provided, ENBPIU00 attempts to determine        */
/*           the table type on its own.                               */
/*           The user can specify the table type by specifying a      */
/*           value for $Table_Type in the OPTIONS input.              */
/*           Example statements include-                              */
/*               $Table_Type = "Standard"                             */
/*               $Table_Type = "CSV"                                  */
/*               $Table_Type = "positions"                            */
/*           Specify "Standard" for 'report image' and                */
/*               word-counted tables. ENBPIU00 will process the       */
/*               heading of a 'report image' table, calculate         */
/*               field starting and ending positions, then            */
/*               operate on the table as a fixed-data table.          */
/*                                                                    */
/*     o MODEL - (1 or more input files) A MODEL is a DD name         */
/*               which provides a generalized output format. The      */
/*               model is 'expanded' by ENBPIU00 to produce           */
/*               output. The data within the MODEL may contain        */
/*               variable names defined on the Table, or by           */
/*               OPTIONS statements. Variable names within the        */
/*               Model which have not been assigned a value by        */
/*               the Table or OPTIONS are not expanded. There         */
/*               must be at least one MODEL, but there may be         */
/*               multiples. By default the DD name for the Model      */
/*               is MODEL.  However the DD name for a Model may       */
/*               be specified as a column on a TABLE, assigned by     */
/*               an OPTIONS statement, or named within a              */
/*               'PARMLIST'.                                          */
/*               By default ENBPIU00 expands a Model for each row     */
/*               selected from the Table for processing. The user     */
/*               however, may force additional Model expansions by    */
/*               coding an OPTIONS statement. For example-            */
/*                  x = BuildFromMODEL('MYMODL')                      */
/*               where 'MYMODL' is a DD name in the executing step.   */
/*                                                                    */
/*     o OPTIONS - (1 or more input files)                            */
/*                 to provide overrides if any. You may use           */
/*                 "//OPTIONS DD DUMMY" if there are no               */
/*                 overrides. There must be at least one OPTIONS      */
/*                 file for the ENBPIU00 step, but you may use        */
/*                 multiples. The name 'OPTIONS' can be changed       */
/*                 by references on a table or by being named         */
/*                 within a 'PARMLIST'.  Any valid single-line        */
/*                 Rexx statement can be coded within the             */
/*                 contents of the OPTIONS file. All variables        */
/*                 that are assigned values in the OPTIONS file       */
/*                 are eligible to be used in the Model               */
/*                 substitution.                                      */
/*                                                                    */
/*                 If you have OPTIONS input that is untrustworthy    */
/*                 then have them referenced by a statement like this:*/
/*                                                                    */
/*                 x = IncludeQuotedOptions(<ddname>)                 */
/*                                                                    */
/*                 Where <ddname> is the DDname for the               */
/*                 untrustworthy Options statements. ENBPIU00 will    */
/*                 only interpret those statements formated as:       */
/*                     keyword = 'value'                              */
/*                     keyword = "value"                              */
/*                     keyword = <number>                             */
/*                 All others are skipped.                            */
/*                                                                    */
/*                 Uses of the OPTIONS file include-                  */
/*                 - Calculating new variables from variables on the  */
/*                   Table, or other sources.                         */
/*                 - Providing override values for variables on       */
/*                   the Table.                                       */
/*                 - Setting or checking internal ENBPIU00            */
/*                   variable values.                                 */
/*                 - Cause multiple Table searches.                   */
/*                 Any single, standard REXX statements may be        */
/*                 included within OPTIONS. For example,              */
/*                    DB2_SUBSYS = 'DB2Q'                             */
/*                 REXX variables assigned values in OPTIONS and      */
/*                 which appear as a header on the table, keep        */
/*                 the value assigned in OPTIONS. This feature        */
/*                 enables OPTIONS to provide override values to      */
/*                 entries on the Table.                              */
/*                                                                    */
/*                 If C1STAGE is a variable (from the Table or        */
/*                 OPTIONS) and its value matches a prefix for an     */
/*                 OPTIONS statement, then the prefix is              */
/*                 truncated and the resulting statement is           */
/*                 evaluated. For example, a column in the table      */
/*                 is DB2-SUBSYS, and is given a value of 'DB2Q',     */
/*                 then the following OPTIONS would change the        */
/*                 value to 'DB2R' at the Endevor QA stage.           */
/*                                                                    */
/*                 //OPTIONS DD  *                                    */
/*                   C1STAGE = &C1STAGE                               */
/*                   QA_DB2_SUBSYS =  'DB2R'                          */
/*                                                                    */
/*     o POSITION - (optional input file)                             */
/*                  Must be provided only when the Table appears      */
/*                  in a A fixed-data format. Positions must          */
/*                  contain variable names and start & stop           */
/*                  locations when the Table is fixed-format.         */
/*                                                                    */
/*     o PARMLIST - (optional input file) Used only when multiple     */
/*              scans of a table are to be performed. With each       */
/*              scan you may provide a "Model", an output DD          */
/*              name, an OPTIONS DD name, and an ENBPIU00             */
/*              parameter string value. The jobstep parameter         */
/*              string value must be 'PARMLIST' to utilize the        */
/*              PARMLIST input. An input DDname of PARMLIST must      */
/*              be provided that lists one or more search             */
/*              requests for a single Table. The format of the        */
/*              search request in the PARMLIST file is-               */
/*                                                                    */
/*                <Model> <Tblout> <Options> <Calling Parm value>     */
/*              Where-                                                */
/*              <Model> -  the name of an input Model DD or '*'       */
/*                         to use the default name (MODEL), or        */
/*                         allow OPTIONS to specify a name, or        */
/*                         the name to be designated on the           */
/*                         TABLE.                                     */
/*              <Tblout>-  the name of an output Tblout DD or '*'     */
/*                         to use the default name (TBLOUT), or       */
/*                         allow OPTIONS to specify a name, or        */
/*                         the name to be designated on the           */
/*                         TABLE.                                     */
/*              <Options>- the name of an input Options DD or '*'     */
/*                         to use the default name (OPTIONS).         */
/*              <Calling Parm value> - 'A' / number / 'M' and search  */
/*                                     values as described above in   */
/*                                     the Calling Parm value format. */
/*     o TBLOUT - (1 or more output DD names)                         */
/*                Variables from TABLE and/or OPTIONS are expanded    */
/*                within a MODEL and written to a TBLOUT file.        */
/*                There must be at least one TBLOUT, but there may    */
/*                be multiples. The 'TBLOUT' DD name may be           */
/*                specified by references on a TABLE, by OPTIONS      */
/*                statements, or by references on a 'PARMLIST'.       */
/*                                                                    */
/*     By default, TABLE, MODEL, TBLOUT and OPTIONS are DD names      */
/*     in the ENBPIU00 step.  You can use TABLE variables or          */
/*     OPTIONS statements to specify multiple MODEL and TBLOUT        */
/*     files.  Whatever names you specify must also be DD names       */
/*     in the ENBPIU00 step.                                          */
/*                                                                    */
/*     The simplest method of execution causes each row of a          */
/*     Table to be processed with one MODEL. Both TABLE and           */
/*     MODEL are DD names in the jobstep of a ENBPIU00 execution.     */
/*     Each row of the TABLE is used for substitution of variables    */
/*     in the MODEL, and the result is written to the output DDname   */
/*     TBLOUT.                                                        */
/*                                                                    */
/*     Calling Parameters-                                            */
/*       You can use a single PARM value to be passed to ENBPIU00, or */
/*       you can specify multiple Parm values to be used in a single  */
/*       execution of ENBPIU00 within a PARMLIST file.                */
/*       The Calling Parm value specifies which method Parms are      */
/*       provided.                                                    */
/*                                                                    */
/*     Calling Parm value format-                                     */
/*       The first word in the parameter string indicates which       */
/*       rows of the Table are to be processed-                       */
/*          A - indicates all rows of Table are to be processed.      */
/*         <number> - indicates a fixed number of rows.               */
/*                    Optionally search values may also be provided.  */
/*          M - indicates only rows matching the provided             */
/*              search values. The search values must appear          */
/*              in the Calling Parm string following the 'M'.         */
/*          PARMLIST - a PARMLIST file is being used to provide       */
/*              multiple PARM values for a single execution of        */
/*              ENBPIU00. If the first word in the Calling Parm is    */
/*              'PARMLIST' then, all other values in the Calling Parm */
/*              are ignored. A PARMLIST DD must be provided in the    */
/*              step to provide one or more parm search values.       */
/*                                                                    */
/*                                                                    */
/*     You can specify search values in the PARM string, for an       */
/*     'M' option or a <number> option.  Multiple values may be       */
/*     present, but must be separated by at least one space. Each     */
/*     of these are paired as a search value with a column from       */
/*     the table.  The first value is used as selection criteria      */
/*     for the first column in the table.  The second value (if       */
/*     provided) is used as selection critieria for the second        */
/*     column in the table.  Each subsequent value provided is        */
/*     used as selection critieria for the next column in the         */
/*     table.  When a row is found which contains values that         */
/*     Match  all passed PARMs, then the row is selected. If no       */
/*     rows $Match, then a return-code 4 is returned. If the          */
/*     Table depends on a POSITION dd to define the fields, then      */
/*     the matching is made using the order or definitions.           */
/*                                                                    */
/*     For example,                                                   */
/*         if the PARM='1 Green Apples'                               */
/*            then using a top to bottom search, the first row        */
/*               that has 'Green' in the first column and             */
/*               'Apples' in the second column is the row selected.   */
/*                                                                    */
/*     If the "A"  (all rows) option is designated, then no other     */
/*     parameters are necessary.                                      */
/*                                                                    */
/*     OPTIONs can cause ENBPIU00 to search a table multiple          */
/*     times when-                                                    */
/*     - The ENBPIU00 parameter indicates searching 'M' for           */
/*       one table column                                             */
/*     - OPTIONS provides an override for the Search column           */
/*       variable and specifies multiple space-delimited              */
/*       values.  ENBPIU00 searches the table for each                */
/*       space-delimited value.                                       */
/*                                                                    */
/*     For example. If LIST-TYPE is the first column in the TABLE.    */
/*     And OPTIONS contains this statement-                           */
/*         LIST-TYPE = 'BIND1 BIND2'                                  */
/*     ... causes a search through the table where                    */
/*         LIST-TYPE = 'BIND1'                                        */
/*     ... and a second search through the table where                */
/*         LIST-TYPE = 'BIND2'                                        */
/*                                                                    */

   trace O

/* Is ENBPIU00 allocated? If yes, then turn on Trace  */
   isItThere = ,
     BPXWDYN("INFO FI(ENBPIU00) INRTDSN(DSNVAR) INRDSNT(myDSNT)")
   If isItThere = 0 then Trace r

   ARG $parms;
   /* Validate Parameter string value */
   $ParmListCallingParm = WORD($parms,1) ;
   IF DATATYPE($ParmListCallingParm) = "NUM" THEN NOP
   ELSE
   IF WORDPOS($ParmListCallingParm,"A PARMLIST M") > 0 THEN NOP
   ELSE
      DO
      SAY 'Invalid Parameter list - ' $ParmListCallingParm ;
      say ' Valid values are:'
      say '   A - ALL '
      say '   M - Multiple matching <search values> '
      say '   # - A number of rows - with or without <search values> '
      say '   PARMLIST - Mult Parms specified in PARMLIST ';
      exit (12)
      end;

/* Establish Defaults and initial values            */

   $command = '' ;
   $date = date() ;
   $delimiter = "^" ;
   $LastTBLOUT = ' '
   $List_Read_Models = " " ;
   $List_Read_Options = " " ;
   $ListTBLOUTs = ' '           /* List of output DD names          */
   $MultiplePDSmemberOuts = 'N' /* Set to 'Y' if mult PDS mbr outputs */
   $my_rc = -999999 ;           /* Until set to another value */
   $nomessages = 'N'            /* Bypass messages Y/N        */
   $numbers   = '0123456789.'   /* chars for numeric values   */
   $QuietMessages = 'N'         /* Bypass messages Y/N        */
   $NumberModelsAndTblouts= 1 ; /* Number of MODEL inputs */
   $OptionsVariables = ' ' ;
   $OptionCommentChar = "*" ;   /* For Options comments   */
   /* List of variables available with every ENBPIU00 step */
   $OtherVariables = "$running_sysname $row# $tbl ",
                     "$my_rc $CallingOptionsForHeading ",
                     "$Matches $date $time" ;
   $row# = 0 ;
   $running_sysname = MVSVAR(SYSNAME) ;
   $StripData = 'Y' ;
   $Table_Type = "Standard" ;   /* Default until otherwise */
   $TableCommentPrefix = "**";  /* For TABLE   comments   */
   $TableHeadingChar  = "*" ;   /* For TABLE   heading    */
   $tbl  = 0 ;                  /* Pointer to table row   */
   TBLOUT = 'TBLOUT' ;          /* Default name of Output DD   */
   $TBLOUTSaved. = 0 ;          /* if using $Multiple.... dflt to 0 */
   $time = time() ;

/* If not using PARMLIST, read through  OPTIONS */
   IF $ParmListCallingParm /= "PARMLIST" THEN, /* Mults in PARMLIST */
      /* Must have OPTIONS  */
      Do
      $OPTIONS = 'OPTIONS'
      Call ReadSaveAndInterpretOPTIONS ;
      End ; /* IF $ParmListCallingParm /= "PARMLIST" */

/* Read Table into stem array named $tablerec.  */
    IF DATATYPE($ParmListCallingParm) = "NUM" &,
       Words($parms) = 1 then,
       Do
       /* Read only requested number of rows from table               */
       /* ... not counting heading or comment rows.                   */
       $len = Length($TableCommentPrefix)
         Do Forever
           "EXECIO 1 DISKR TABLE "
           If RC > 0 then Leave
           Parse Pull $tablerecord
           If $Table_Type = "Standard" &,
              Substr($tablerecord,1,$len) = $TableCommentPrefix then,
              Iterate ;
           $tbl = $tbl + 1;
           $tablerec.$tbl = $tablerecord
           If $tbl > $ParmListCallingParm then Leave ;
         End /* Do Forever */
       $tablerec.0 = $tbl
       "EXECIO 0 DISKR TABLE (FINIS " /* Close Table */
       End /*IF DATATYPE($ParmListCallingParm) */
    Else,
       "EXECIO * DISKR TABLE (STEM $tablerec. FINIS"

   If RC > 1 then,
      Do
      Say "Failed to Read input file TABLE " RC
      EXIT (12)
      End;

   IF $ParmListCallingParm = "PARMLIST" THEN,  /* Mults in PARMLIST */
      Do
      Call Read_PARMLIST;
      $OPTIONS = Word($parmvalue.1,3) ;
      Call ReadSaveAndInterpretOPTIONS ;
      End ; /* IF $ParmListCallingParm /= "PARMLIST" */

/* Initialize Search parms from parm string      */
   $tbl = 1 ;
/* $Heading_Variable_count */
   If $Table_Type = "positions" then,
      Do
      "EXECIO * DISKR POSITION (STEM $positions. FINIS"
      if rc > 0 then,
         Do
         Say
         "Cannot find POSITION input"
         Exit(8)
         End
  /*  Call Process_Heading; */
      Call Process_$positions;
      End
   Else,
   If $Table_Type = "CSV" then,
      Call Process_CSV_Line1
   Else,
      Do
      $Table_Type = "Standard"
      CALL DetermineTableTypeAndLocateHeading ;
      End;

   IF $ParmListCallingParm = "PARMLIST" THEN,  /* Mults in PARMLIST */
      Call Process_PARMLIST;
   Else,
      Do
      IF $search_PARMS_COUNT >  $Heading_Variable_count THEN,
         DO
         SAY 'FEWER TABLE COLUMNS THAN SEARCH $parms'
         EXIT (12)
         END;
      $All_VARIABLES = $OptionsVariables,
              $table_variables $OtherVariables;
      CALL Process_One_Parm_Value ;
      End

   If $MultiplePDSmemberOuts = 'Y' then,
      Call WriteTBLOUTS_at_End

   IF $my_rc = -999999 then $my_rc = 0;
   EXIT ($my_rc) ;

Read_PARMLIST:

/* Read PARMLIST File and process each record as if a calling
   PARMS value                                                */
   "EXECIO * DISKR PARMLIST (STEM $parmvalue. FINIS"
   If RC > 1 then,
        Do
        Say 'PARMLIST DD is missing'
        Exit (12)
        End;
   $LastOPTIONS_DD = ' ' /* Last used OPTIONS DD */
   $multiple_searches = 'Y'
   Return;

Process_PARMLIST:

   Do $prm# = 1 to $parmvalue.0
      $parms = $parmvalue.$prm#
      if Words($parms) < 4 then,
         Do
         Say 'PARMLIST record is invalid:' $parms
         iterate ;
         End;
      If WORD($parms,1)  = '*' then, /* Use Model if specified*/
         MODEL = 'MODEL'
      Else,
         MODEL = WORD($parms,1)

      If WORD($parms,2)  = '*' then, /* Use Tblout if specified*/
         TBLOUT = 'TBLOUT'
      Else,
         TBLOUT = WORD($parms,2)

      /* if our input is a former output, Close it first */
      /*    ... we are cascading within a single step    */
      If Wordpos(MODEL,$ListTBLOUTs) > 0 then,
         Do
         "EXECIO 0 DISKW "MODEL "(FINIS "
         If RC > 1 then,
            Do
            Say "Failed to Close" MODEL  RC
            EXIT (12)
            End;
         End;

      if WORD($parms,3)  = '*' then, /* Use OPTIONS   specified*/
         $OPTIONS = 'OPTIONS'
      Else,
         $OPTIONS = WORD($parms,3)
      /* Reset Table pointer values */
      $row# = 0 ;
      $tbl  = 0 ;
      Call ReadSaveAndInterpretOPTIONS ;

   /* Examine the remainder of the PARM value - A/M/#  */
      $parms = Substr($parms,Wordindex($parms,4)) ;
      $ParmListCallingParm = WORD($parms,1) ;
      IF DATATYPE($ParmListCallingParm) = "NUM" THEN NOP
      ELSE
      IF WORDPOS($ParmListCallingParm,"A M") > 0 THEN NOP
      ELSE,
         DO
         SAY 'Invalid $ParmListCallingParm value' $ParmListCallingParm ;
         say '  VALID values are:'
         say '     A -ALL M - Multiple matching '
         say '     M - Multiple matching '
         iterate ;
         end;

      $All_VARIABLES = $OptionsVariables,
              $table_variables $OtherVariables;
      CALL Process_One_Parm_Value ;
   End ; /* Do $prm# = 1 to $parmvalue.0 */

   Return ;

ReadSaveAndInterpretOPTIONS :

   /* Read file containing OPTIONS       */
   /*   and EXAMINE OPTIONS (OPTIONS) FOR KEY VALUES   */
   IF $OPTIONS /= $LastOPTIONS_DD Then, /* Last used OPTIONS DD */
      DO
      Drop $OPT. ;
      "EXECIO * DISKR " $OPTIONS "(STEM $OPT. FINIS "
      If RC > 1 then,
         Do
         Say "Failed to Read OPTIONS file " $OPTIONS RC
         EXIT (12)
         End;
      $LastOPTIONS_DD = $OPTIONS ;
      End;
   IF $OPT.0 > 0 THEN,
      Do
      CALL Identify_$OptionsVariables;
      $CallingOptionsForHeading = 'Y'
      SIGNAL ON Syntax
      ReturnWhere = 'ReadSaveAndInterpretOPTIONSZ'
      CALL InterpretOPTIONS ;
ReadSaveAndInterpretOPTIONSZ:
      $CallingOptionsForHeading = 'N'
      end;

   Return ;

Process_One_Parm_Value :

   $search_PARMS_COUNT = WORDS($parms) - 1 ;
   if $search_PARMS_COUNT = 0 THEN $searching = 'N'
   ELSE                            $searching = 'Y' ;
   If $searching = 'Y' then,
      Call Build_Search_criteria ;

   $Matches = 0 ;

/*********************************************************************/
/*   If searching through a table, the first search word can be     **/
/****given multiple values in the OPTIONS. Example-                 **/
/****SEARCH1 = 'VALUE1 VALUE2 VALUE3'                               **/
/****In this case, ENBPIU00 will process each value specified-      **/
/****   a search will be made for VALUE1, then                      **/
/****   a search will be made for VALUE2, then                      **/
/****   a search will be made for VALUE3                            **/
/*********************************************************************/
   If $searching = 'Y' then,
      do
      $primary_VARIABLE = WORD($table_variables,1) ;
      $temp_word = value($primary_VARIABLE) ;
      IF DATATYPE($temp_word,S) = 1 THEN,
         $temp = "$primary_VALUE = " $temp_word ;
      ELSE,
         $temp = "$primary_VALUE = '" || $temp_word || "'" ;
      INTERPRET $temp ;
      end;

   IF WORDS($primary_VALUE) > 1 THEN, /* "LIST-TYPE" OPTION SPECIFIED */
      DO
      $LIST_$primary_VALUES = $primary_VALUE ;
      IF $my_rc = -999999 then,
         Do
         IF WORDS($LIST_$primary_VALUES) < 5 then,
            $my_rc = 2;
         ELSE $my_rc = 4;
         End
      $multiple_searches = 'Y'
        DO $listcnt = 1 TO WORDS($LIST_$primary_VALUES)
           $primary_VALUE = WORD($LIST_$primary_VALUES,$listcnt) ;
           $temp = $primary_VARIABLE " = '"$primary_VALUE"'" ;
           $temp = "$srch_"$primary_VARIABLE " = '"$primary_VALUE"'" ;
           INTERPRET $temp ;
           CALL $Search_TABLE;
           $position_PREFIX = POS('-',$primary_VALUE) ; /* 2 FOR 1 */
           IF $position_PREFIX > 1 THEN,
              DO
              $primary_VALUE = ,
                    SUBSTR($primary_VALUE,1,($position_PREFIX - 1))
              CALL $Search_TABLE;
              END
        END; /* DO $listcnt = 1 TO WORDS($LIST_$primary_VALUES) */
      END; /* IF WORDS($LIST_$primary_VALUES) > 0 */
   ELSE,
      DO
      IF $my_rc = -999999 then,
         $my_rc = 0;
      CALL $Search_TABLE;
      END; /* IF $primary_VALUE /= ' ' (NO "LIST-TYPE" $OPTION) */

   Return ;

DetermineTableTypeAndLocateHeading :

/* Look for heading record. Determine what kind of Table we have */

   $TableCommentPrflen = Length($TableCommentPrefix)
   DO $tbl = 1 TO $tablerec.0      /* Look for header or CSV format*/
      IF SUBSTR($tablerec.$tbl,1,$TableCommentPrflen) = ,
         $TableCommentPrefix then iterate;
      IF SUBSTR($tablerec.$tbl,1,1) = $TableHeadingChar then,
         Do
         CALL Process_Heading;
         RETURN;
         End
      IF SUBSTR($tablerec.$tbl,1,1) = '"' |,
         SUBSTR($tablerec.$tbl,1,1) = ',' |,
         ( SUBSTR($tablerec.$tbl,1,1) = ' ' &,
            Pos(',',$tablerec.$tbl) > 0 ) |,
         SUBSTR($tablerec.$tbl,1,2) = ' "' then,
         Do
         CALL Process_CSV_Line1 ;
         RETURN;
         End
      Else,             /* See if POSITION data is provided */
         Do
         "EXECIO * DISKR POSITION (STEM $positions. FINIS"
         If rc = 0 then,
            CALL Process_$positions ;
         Else,
            Do
            say "Cannot determine the table type - "
            say " With heading / with POSITION / CSV .         "
            exit (12)
            End; /* if rc > 0 then */
         end; /* else */
   End;  /* DO $tbl = 1 TO $tablerec.0 */

   Return ;

$Search_TABLE :

   $FoundAtLeast1TableEntry = 'N' ;

   $TableCommentPrflen = Length($TableCommentPrefix)
   DO $tbl = 1 TO $tablerec.0           /* Search Table */
      sa = $tablerec.$tbl
/*    Read through each record (row) of Table                        */
      IF SUBSTR($tablerec.$tbl,1,$TableCommentPrflen) = ,
         $TableCommentPrefix then iterate;
      IF SUBSTR($tablerec.$tbl,1,1) = $TableHeadingChar then iterate;
      If $Table_Type = "CSV" & $tbl = 1 then iterate ;
      If $Table_Type = "positions" then $row# = $tbl
      Else                              $row# = $tbl - 1 ;
      $Match = 'Y' ;
      $SkipRow = 'N' ;
      Call Evaluate_Table_row ;
      IF $Match = 'N' THEN ITERATE ;
      If $SkipRow = 'Y' then ITERATE ;
      IF $quitsearch  = 'Y' THEN leave   ;
/*                                                                   */
/*    SELECTED A TABLE ENTRY ...                                     */
/*                                                                   */
      $Matches = $Matches + 1 ;
      If $table_variable = "$Temp_RC" then,
         $my_rc = $Temp_RC ;
      IF DATATYPE($ParmListCallingParm) = "NUM" THEN,
         IF $Matches > $ParmListCallingParm THEN,
            DO
            $tbl = $tablerec.0 ;
            LEAVE ;
            END;
 /*                                                          */
      IF $OPT.0 > 0 THEN,
         DO
         $SAVE_primary_VALUE = Value($primary_VARIABLE)
         CALL InterpretOPTIONS ; /* APPLY OVERRIDES FROM OPTIONS */
         $primary_VALUE = $SAVE_primary_VALUE ;
         If $SkipRow = 'Y' then ITERATE ;
         $tmp =  $primary_VARIABLE "='"$SAVE_primary_VALUE"'"
         Interpret $tmp
         END;
 /*                                                          */
      IF $Match = 'N' THEN $Matches = $Matches - 1 ;
 /*                                                          */
      IF $Match = 'Y' THEN,
         Do
         If $NumberModelsAndTblouts= 1 then,
            $$x = BuildFromMODEL(MODEL) ;
         Else,
            Do $mdl# = 1 to $NumberModelsAndTblouts
               MODEL  = 'MODEL'$mdl#
               TBLOUT = 'TBLOUT'$mdl#
               $$x = BuildFromMODEL(MODEL) ;
            End  /* Do $mdl# = 1 to $NumberModelsAndTblouts */
         End ;   /* IF $Match = 'Y'  */

      IF $OPT.0 > 0 THEN,
         DO
         IF $searching = 'Y' THEN,
            do
            $primary_VARIABLE = WORD($table_variables,1) ;
            Call Restore_Search_criteria ;
            end
         END;
 /*                                                          */
      IF DATATYPE($ParmListCallingParm) = "NUM" &,
         $Matches >= $ParmListCallingParm THEN,
            LEAVE ;
 /*   LEAVE ;                                                */
      ITERATE ;
   END; /* DO $tbl = 1 .... */

   IF $FoundAtLeast1TableEntry = 'N' THEN,
      DO
      SAY 'No Table entries were selected using Parameter value ',
          $parms ;
      If $multiple_searches /= 'Y' then,
         EXIT (4) ;
      END ; /* IF $FoundAtLeast1TableEntry = 'N' */

   RETURN;

Build_Search_criteria :

   Searching_Display = " " ;

   Do $parmcnt = 1 to $search_PARMS_COUNT
      $temp_word =  word($table_variables,$parmcnt) ;
      if wordpos($temp_word,$OptionsVariables) > 0 then,
         DO
         $temp = "$srch_" || $temp_word "=" $temp_word ;
         INTERPRET $temp ;
         ITERATE ;
         END
      $temp_valu = word($parms,($parmcnt+1)) ;

  /*  IF DATATYPE($temp_valu,S) = 1 THEN,  */
      IF WORDPOS($temp_valu,$All_VARIABLES) > 0 then,
         $temp = "$srch_" || $temp_word " = " $temp_valu ;
      ELSE,
         $temp = "$srch_" || $temp_word " = '" || $temp_valu || "'" ;
      Searching_Display = Searching_Display $temp_word'='$temp_valu ;
      INTERPRET $temp ;
   end; /* do $parmcnt = 1 to $search_PARMS_COUNT */

   $temp = " $primary_VALUE = " word($table_variables,1)
   $temp = " $primary_VALUE = $srch_" || $temp_word
   INTERPRET $temp ;

   If $nomessages /= "Y" & $QuietMessages /= 'Y' then,

   RETURN;

Restore_Search_criteria :

   Do $parmcnt = 1 to $search_PARMS_COUNT
      $temp_word =  word($table_variables,$parmcnt) ;
      $temp = $temp_word " = $srch_" || $temp_word ;
      INTERPRET $temp ;
   end; /* do $parmcnt = 1 to $search_PARMS_COUNT */

   RETURN;

Evaluate_Table_row :
/*    Assign heading variables to values from next table record      */

   If $Match = "N" then return ;

   If $Table_Type = "CSV"       then,
      $detail  = Strip($tablerec.$tbl) || ','
   Else,
      $detail  = $tablerec.$tbl

   DO $column = 1 TO $Heading_Variable_count
      $table_variable = WORD($table_variables,$column) ;
      If $table_variable = "$my_rc" then,
         $table_variable = "$Temp_RC"

      /* Positions are used for identifying Table Columns */
      If $Table_Type = "positions" then,
         Do
         $start = $Starting_$position.$table_variable ;
         $stop  = $Ending_$position.$table_variable ;
         $stop  = $stop - $start + 1;
         $temp_valu = substr($tablerec.$tbl,$start,$stop);
  /*
         $temp_valu =,
              Translate($temp_valu,$replaceComma,',');
  */
         If $StripData = 'Y' then,
            $temp_valu = strip($temp_valu) ;
         If $temp_valu = "" then $temp_valu = " ";
         $temp = $table_variable "= $temp_valu" ;
         INTERPRET $temp;
         end; /* If $Table_Type = "positions" */

      /* Table is a CSV file */
      If $Table_Type = "CSV"       then,
         Do
         DROP $word. ;
         /* Find the data for the current $column */
         $dlmchar = Substr($detail,1,1);

         If $dlmchar = "'" then,
            Do
            /* parsing with single quote  */
            PARSE VAR $detail "'" $temp_value "'," $detail ;
            /* replace single quotes with double quotes */
            $temp_value = Translate($temp_value,'"',$dlmchar);
            End
         Else,
         If $dlmchar = '"' then,
            Do
            /* parsing with double quote  */
            PARSE VAR $detail '"' $temp_value '",' $detail ;
            /* replace double quotes with single quotes */
            $temp_value = Translate($temp_value,"'",$dlmchar);
            End
         Else,
            Do
            /* parsing with comma chars   */  ,
            PARSE VAR $detail $temp_value ',' $detail ;
            $dlmchar = '"'
            End

         if Length($temp_value) < 1 then $temp_value = ' '
         $rslt = $dlmchar || $temp_value || $dlmchar
         $temp = WORD($table_variables,$column) "=" $rslt
         INTERPRET $temp;
         End; /* If $Table_Type = "CSV"  */

      /* Table is a Standard header file */
      If $Table_Type = "Standard"  then,
         Do
         $temp_value = WORD($tablerec.$tbl,$column);
         $temp = TRANSLATE($table_variable,'_','-') ;
         $temp = $temp || "= $temp_value"
         INTERPRET $temp;
         END; /* Else,   */


    /* Compare Table values with search criteria                 */
      IF $searching = 'Y' & $column <= $search_PARMS_COUNT then,
         do
         $temp = "If" $table_variable "= '*' then ",
                 $table_variable "=  $srch_" || $table_variable ;
         INTERPRET $temp;
         $temp    = VALUE($table_variable) ;
         $templen = Length(VALUE($table_variable)) ;
         $tempend = substr(VALUE($table_variable),$templen);
         if $tempend = "*" & $templen > 1 then,
            Do
            $templen = $templen - 1 ;
            $temp1a = VALUE("$srch_" || $table_variable);
            $temp1b = Substr($temp1a,1,$templen);
            $temp2a = VALUE($table_variable);
            $temp2b = Substr($temp2a,1,$templen);
            if $temp1b = $temp2b then,
               Do
               $temp = $table_variable "=  $srch_" || $table_variable ;
               INTERPRET $temp;
               End;
            End; /* if $tempend = "*" & $templen > 1 */
         $cmpval1 = Value($table_variable);
         $cmpval2 = Value('$srch_'$table_variable)
         Upper $cmpval1 $cmpval2 ;
         /* Now check to see if a search parm value is wildcarded*/
         $where = pos('*',$cmpval2)
         If $where > 1 then,
            Do
            If Substr($cmpval1,1,($where-1))/=,
               Substr($cmpval2,1,($where-1)) then,
               $Match = 'N'
            Iterate
            End
         /*                                                      */
         If $cmpval2 = '*' then Iterate;
         If $cmpval1 /= $cmpval2 then,
            $Match = 'N'
         End /* If $searching ....  */
   END; /* DO $column = ... */

   RETURN;

BuildFromMODEL :

   If $row# = 0 then Return $UseModel ;

   Arg $UseModel ;

   $SavedModel = MODEL
   MODEL = $UseModel;

   If $nomessages /= "Y" & $QuietMessages /= 'Y' then,
   SAY "Output Built from" LEFT(MODEL,8),
       " to" LEFT(TBLOUT,8),
       " using Parms:" Strip($parms)

   MODEL  = STRIP(MODEL)
   $opened = WordPos(MODEL,$List_Read_Models)

   if $opened = 0 then,
      do
      "EXECIO * DISKR "MODEL "(STEM $Model. FINIS" ;
      IF RC > 1 THEN,
         DO
         SAY 'Cannot find MODEL File ' MODEL
         EXIT(12)
         END;
      Do $cnt = 0 to $Model.0
         $Stem.MODEL.$cnt = $Model.$cnt
      end; /* Do $cnt = 0 to $Model.0 */
      $List_Read_Models = MODEL $List_Read_Models ;
      end; /* if $opened = 0 then */
   else,
      Do $cnt = 0 to $Stem.MODEL.0
         $Model.$cnt = $Stem.MODEL.$cnt ;
      end; /* Do $cnt = 0 to $Stem.MODEL.0 */

   CALL ExpandModelFromVariables ;

   /* Keep a list of TBLOUT output DD's               */
   If Wordpos(TBLOUT,$ListTBLOUTs) = 0 then,
         $ListTBLOUTs = TBLOUT $ListTBLOUTs ;

   If $LastTBLOUT /= ' ' & $LastTBLOUT /= TBLOUT then,
      Do
      "EXECIO 0 DISKW "$LastTBLOUT" (FINIS"   ;
      If RC > 1 then,
         Do
         Say "Failed to Write to DDName " $LastTBLOUT RC
         EXIT (12)
         End;
      End;
   If $MultiplePDSmemberOuts = 'Y' then,
      /*Mult mbrs of same PDS are targeted by TBLOUTS ....
         Set to 'Y' if mult PDS mbr outputs */
      Call SaveTBLOUTS_for_End ;
   Else,
      Do
      "EXECIO * DISKW "TBLOUT "(STEM $Model.";
      If RC > 1 then,
         Do
         Say "Failed to Write to DDName " TBLOUT RC
         EXIT (12)
         End;
      End;

   $LastTBLOUT = TBLOUT ;
   DROP $Model. ;

   $FoundAtLeast1TableEntry = 'Y' ;
   MODEL = $SavedModel ;

   Return $UseModel

ExpandModelFromVariables :
   DO $LINE = 1 TO $Model.0
      $PLACE_VARIABLE = 1;
      CALL EvaluateSymbolics ;
      END; /* DO $LINE = 1 TO $Model.0 */

   RETURN;

EvaluateSymbolics :
   /*                                                       */
   /* Thru this section, flow through the program uses      */
   /* SIGNAL calls to enable the SIGNAL ON SYNTAX statement */

   $PLACE_VARIABLE = POS('&',$Model.$LINE,$PLACE_VARIABLE)
   IF $PLACE_VARIABLE = 0 THEN RETURN
   $temp_$LINE = TRANSLATE($Model.$LINE,' ',',.()"/\+-*|=&');
   $temp_$LINE = TRANSLATE($temp_$LINE,' ',"'"$delimiter);
   $table_word = WORD(SUBSTR($temp_$LINE,($PLACE_VARIABLE+1)),1);
   $table_word = TRANSLATE($table_word,'_','-') ;
   $varlen = LENGTH($table_word) + 1 ;

   If WORDPOS($table_word,$All_VARIABLES) = 0 then,
      do
      $PLACE_VARIABLE = $PLACE_VARIABLE + 1 ;
      Signal EvaluateSymbolics
      end;

   /* If the upcoming INTERPRET results in a Syntax error   */
   /*    we are prepared to attempt the INTERPET in a       */
   /*    different way, and Signal back into the normal flow*/
   $temp_word = VALUE($table_word) ;
   SIGNAL ON Syntax
   ReturnWhere = 'EvaluateSymbolicsContinued'
   $temp = "SYMBVALUE = '"$temp_word"'" ;
   $tryCommand = $temp
   INTERPRET $temp;
EvaluateSymbolicsContinued :

   $tail = SUBSTR($Model.$LINE,($PLACE_VARIABLE+$varlen)) ;
   if Substr($tail,1,1) = $delimiter then,
      $tail = SUBSTR($tail,2) ;
   IF $PLACE_VARIABLE > 1 THEN,
      $Model.$LINE = ,
         SUBSTR($Model.$LINE,1,($PLACE_VARIABLE-1)) ||,
         SYMBVALUE || $tail ;
   else,
      $Model.$LINE = ,
         SYMBVALUE || $tail ;

   Signal EvaluateSymbolics

SYNTAX:

   If ReturnWhere = 'EvaluateSymbolicsContinued' then,
      Do
      SIGNAL OFF Syntax
      INTERPRET "SYMBVALUE = $temp_word" ;
      Interpret  'Signal' ReturnWhere
      End
   Say 'Unable to interpret command:'
   Say $tryCommand
   Exit(08)

Identify_$OptionsVariables :
   DO L# = 1 TO $OPT.0
      $OPTION = STRIP($OPT.L#) ;
      $OPTION_LEN = LENGTH($OPTION) ;
      IF $OPTION_LEN = 0 THEN ITERATE ;
      $temp = LASTPOS("=",$OPTION)
      if $temp =0 then iterate;

      $temp_line = substr($OPTION,1,($temp-1)) ;
      $temp_line = TRANSLATE($temp_line,' ','=') ;
      $keyword = WORD($temp_line,WORDS($temp_line));
      $keyword = TRANSLATE($keyword,'_','-') ;
      if wordpos($keyword,$OptionsVariables) = 0 then,
         $OptionsVariables = $OptionsVariables $keyword ;
   End /* DO L# = 1 TO $OPT.0  */

   RETURN;

InterpretOPTIONS :

   $Continuation = ''
   $command = '' ;

   DO L# = 1 TO $OPT.0
      IF SUBSTR($OPT.L#,1,1) = $OptionCommentChar then ITERATE ;
      $OPTION = STRIP($OPT.L#) ;
      $OPTION_LEN = LENGTH($OPTION) ;
      IF $OPTION_LEN = 0 THEN ITERATE ;
      $command_LEN = Max(LENGTH($command),1) ;
      LastCharPart1 = SUBSTR($command' ',$command_LEN,1)
      FirstCharPart2= SUBSTR($OPTION,1,1)
      If (FirstCharPart2 ="'" | FirstCharPart2 ='"') &,
         (LastCharPart1  ="'" | LastCharPart1  ='"') Then,
         $Continuation = '||'
      Else,
         $Continuation = '' ;
      IF SUBSTR($OPTION,$OPTION_LEN,1) = ',' |,
         SUBSTR($OPTION,$OPTION_LEN,1) = '+' |,
         SUBSTR($OPTION,$OPTION_LEN,1) = '-' THEN,
         DO
         $OPTION = SUBSTR($OPTION,1,$OPTION_LEN-1) ;
         $OPTION = STRIP($OPTION) ;
         $command = $command || $Continuation || $OPTION ;
         ITERATE ;
         END ;
      $command = $command || $Continuation || $OPTION ;
      $temp = LASTPOS("=",$command)
      if $temp > 1 then,
         do
         $temp_line = substr($command,1,($temp-1)) ;
         $temp_line = TRANSLATE($temp_line,' ','=') ;
         $keyword = WORD($temp_line,WORDS($temp_line));
         $position = WORDINDEX($temp_line,WORDS($temp_line));
         end;
      else,
         do
         $temp_line = TRANSLATE($command,' ','=') ;
         $keyword = WORD($temp_line,1) ;
         $position = WORDINDEX($temp_line,1) ;
         end;

      $keyword = TRANSLATE($keyword,'_','-') ;
      $command = OVERLAY($keyword,$command,$position) ;
      $len_stage = LENGTH(C1STAGE) + 1;
      IF $len_stage >= LENGTH($command) THEN NOP ;
      ELSE,
      IF SUBSTR($command,1,$len_stage) = C1STAGE || '_' THEN,
         DO
         $len_stage = $len_stage + 1;
         $command = SUBSTR($command,$len_stage) ;
         END; /* IF SUBSTR($command,1,$len_stage) = C1STAGE*/
      $LEN_SAVE_primary_VALUE = LENGTH($SAVE_primary_VALUE) + 1;
      IF $LEN_SAVE_primary_VALUE >= LENGTH($command) THEN NOP ;
      ELSE,
      IF SUBSTR($command,1,$LEN_SAVE_primary_VALUE) =,
         $SAVE_primary_VALUE || '_' THEN,
         DO
         $LEN_SAVE_primary_VALUE = $LEN_SAVE_primary_VALUE + 1;
         $command = SUBSTR($command,$LEN_SAVE_primary_VALUE) ;
         END; /* IF SUBSTR($command,1.....   */
      $tryCommand = $command
      INTERPRET $command ;
      INTERPRET_RC = RC;
      $command = '' ;
      If $SkipRow = 'Y' then Leave
   END; /* DO L# = 1 TO $OPT.0 */

   If $NumberModelsAndTblouts> 1 then,
      $MultiplePDSmemberOuts = 'Y'

   RETURN;

IncludeQuotedOptions:
/* Options built by others might not be trustworthy.                  */
/* Use this routine in such conditions to interpret only those that   */
/* have values contained in quotes, or values that are numeric.       */

   Arg $UserOptDDname;

   /*  Process only quoted Rexx assignment statements from User */
   $USROPTS = STRIP($UserOptDDname) ;
   /*  Already Read this OPtions file as input ?                */
   $options# = WordPos($USROPTS,$List_Read_Options)

   If $options# = 0 then,
      Do
      $List_Read_Options = $List_Read_Options $USROPTS ;
      $options# = WordPos($USROPTS,$List_Read_Options)
      "EXECIO * DISKR" $USROPTS "(Stem $Opts."$options#". Finis"
      IF RC > 8 THEN,
         DO
         SAY 'Cannot find OPTIONS File ' $USROPTS
         EXIT(12)
         END;
      End; /* if $options# = 0 then */

   /*  Process only quoted Rexx assignment statements from User */
   DO $Uop# = 1 TO $Opts.$options#.0
      $UserOption = STRIP($Opts.$options#.$Uop#) ;
      IF SUBSTR($UserOption,1,1) = $OptionCommentChar then ITERATE ;
      If Words($UserOption) < 1                   then ITERATE ;
      Do 20;    /* Supporting only 20 quoted lines wi continuations */
         $lastchar = Substr($UserOption,Length($UserOption))
         If Pos($lastchar,',-+') = 0 then Leave;
         $UserOption = STRIP(STRIP($UserOption,'T',$lastchar))
         $lastchar = Substr($UserOption,Length($UserOption))
         $Uop# = $Uop# + 1
         $continueOption = STRIP($Opts.$options#.$Uop#) ;
         $firstchar = Substr($continueOption,1,1)
         If ($lastchar  = "'" | $lastchar  = "'") &,
             $firstchar = $lastchar then,
             $UserOption = Strip($UserOption,'T',$lastchar) ||,
                       Strip($continueOption,'L',$firstchar)
         Else,
             $UserOption = $UserOption $continueOption
      End /* Do 20 */

      PARSE VAR $UserOption $keyword '=' $UserOptionValue ;
      $UserOptionValue = Strip($UserOptionValue)

      $firstchar = Substr($UserOptionValue,1,1)
      $nextQuote = 0
      If ($firstchar = "'" | $firstchar = '"') then,
         $nextQuote = Pos($firstchar,$UserOptionValue,2)
      /* Only statements in acceptable format are iterpreted:  */
      /*        keyword = 'value'                              */
      /*        keyword = "value"                              */
      /*        keyword = <number>                             */
      $rslt =  VERIFY($UserOptionValue,$numbers)
      If $rslt = 0 then Nop;
      Else,
      if Words($keyword) /= 1 |,
         ($firstchar /= "'" & $firstchar /= '"') |,
         ($nextQuote /= Length($UserOptionValue)) then,
         Do
         If $nomessages = 'N' then,
            Say 'ENBPIU00: Invalid to Interpret:',
                $UserOption ;
         Iterate ;
         End /* If Words.....   */
      if wordpos($keyword,$OptionsVariables) = 0 then,
         $OptionsVariables = $OptionsVariables $keyword ;
      If $nomessages = 'N' then Say $UserOption
      Interpret $UserOption

   End /* DO $Uop# = 1 TO $Opts.$options#.0 */

   RETURN $UserOptDDname

Process_Heading :

   $LastWord = Word($tablerec.$tbl,Words($tablerec.$tbl));
   If DATATYPE($LastWord) = 'NUM' then,
      Do
      Say 'Please remove sequence numbers from the Table'
      Exit(12)
      End

   $tmprec = Substr($tablerec.$tbl,2) ;
   $PositionSpclChar = POS('-',$tmprec) ;
   If $PositionSpclChar = 0 then,
      $PositionSpclChar = POS('*',$tmprec) ;
   $tmpreplaces = '-,.'$TableHeadingChar ;
   $tmprec = TRANSLATE($tmprec,' ',$tmpreplaces);
   $table_variables = strip($tmprec);
   $Heading_Variable_count = WORDS($table_variables) ;
   If $PositionSpclChar = 0 then,
      return ;
   If $Heading_Variable_count /=,
      Words(Substr($tablerec.$tbl,2)) then,
      Do
      Say 'Invalid table Heading:' $tablerec.$tbl
      exit(12)
      End

   $heading = Overlay(' ',$tablerec.$tbl,1); /* Space leading * */
   Do $pos = 1 to $Heading_Variable_count
      $headingVariable = Word($table_variables,$pos) ;
      If $headingVariable = "$my_rc" then,
         $headingVariable = "$Temp_RC"
      $tmp = Wordindex($heading,$pos) ;
      $Starting_$position.$headingVariable = $tmp
      $tmp = $tmp + Length(Word($heading,$pos)) -1 ;
      $Ending_$position.$headingVariable = $tmp
   end; /* DO $pos = 1 to $Heading_Variable_count */

   $Table_Type = "positions" ;
   Return ;

Process_$positions :
   $table_variables = " " ;
   $Heading_Variable_count = $positions.0 ;
   DO $pos = 1 to $Heading_Variable_count;
      if substr($positions.$pos,1,1) = "*" then iterate ;
      $word1 = word($positions.$pos,1) ;
      $word1 = translate($word1,'_','-');
      $word2 = word($positions.$pos,2) ;
      $word3 = word($positions.$pos,3) ;
      if datatype($word1,S) /= 1 then,
         do
         say "Value not valid for variable name - " $word1 ;
         exit (12)
         end
      if datatype($word2,N) /= 1 then,
         do
         say "Value not valid for variable starting $position - ",
             $word2 ;
         exit (12)
         end
      if datatype($word3,N) /= 1 then,
         do
         say "Value not valid for variable ending   $position - ",
             $word3 ;
         exit (12)
         end
      $Starting_$position.$word1 = $word2;
      $Ending_$position.$word1 = $word3;
      $table_variables = $table_variables $word1 ;
   end; /* DO $pos = 1 to $Heading_Variable_count */

   $Table_Type = "positions" ;

   return ;

Process_CSV_Line1 :

   $tablerec.$tbl = Space(Translate($tablerec.$tbl,' ',"/'-")) ;

   $heading = $tablerec.$tbl ;
   $heading = TRANSLATE($heading,'@@$$##','()/\%.') ;
   $table_variables = "" ;
   $repeaters = "" ;

   DO FOREVER
      PARSE VAR $heading $value ',' $heading ;
      $value = STRIP($value) ;
      $value = TRANSLATE($value,'_',' ') ;
      $value = STRIP($value,B,'"');
      SAY "CSV Variable:" $value ;
      if WordPOS($value,$table_variables) > 0 &,
         Wordpos($value,$repeaters) = 0 then,
           $repeaters = $repeaters $value ;
      $table_variables = $table_variables $value       ;
      IF WORDS($heading) = 0 THEN LEAVE;
   END; /* DO FOREVER */

   If Words($repeaters) > 0 then,
      DO
      $new_list = " " ;
      $count. = 0 ;
        Do $cnt = 1 TO WORDS($table_variables)
           $value = WORD($table_variables,$cnt)
           If WORDPOS($value,$repeaters) > 0 then,
              Do
              $count.$value = $count.$value + 1;
              $value = $value"#"$count.$value ;
              End;
           $new_list = $new_list $value;
        End ; /* Do $cnt = 1 to Words($table_variables) */
      $table_variables = $new_list ;
      End ; /* If Words($repeaters) = 0 */

   $Heading_Variable_count = WORDS($table_variables) ;
   $Table_Type = "CSV" ;

   return ;

SaveTBLOUTS_for_End :

   $tbout# = $TBLOUTSaved.TBLOUT.0 ;
   Do $md# = 1 to $Model.0
      $next# = $tbout# + $md# ;
      $TBLOUTSaved.TBLOUT.$next# = $Model.$md#
   End
   $TBLOUTSaved.TBLOUT.0 = $next# ;

   Return ;

WriteTBLOUTS_at_End :

   Do $tbout# = 1 to Words($ListTBLOUTs) ;
      TBLOUT = Word($ListTBLOUTs,$tbout#)
      Drop $Model.
      Do $md# = 0 to $TBLOUTSaved.TBLOUT.0
         $Model.$md# = $TBLOUTSaved.TBLOUT.$md#
      End
      "EXECIO * DISKW "TBLOUT "(STEM $Model. Finis";
      If RC > 1 then,
         Do
         Say "Failed to Write to DDName " TBLOUT RC
         EXIT (12)
         End;
   End
   Return ;


FAILURE:
   SAY ' \\\\\ SYNTAX ERROR //// ' ;
   SAY '<<<<RETURN CODE = 8>>>>' ;
   EXIT (12) ;

ERROR:
   SAY ' \\\\\ SYNTAX ERROR //// ' ;
   SAY '<<<<RETURN CODE = 8>>>>' ;
   EXIT (12) ;

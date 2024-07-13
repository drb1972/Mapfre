/*-----------------------------REXX----------------------------------*\
 *  This Rexx takes two component lists (normally two versions of the*
 *  same member name) and matches them together, generally on        *
 *  stepname and member name, highlighting where they are            *
 *  different                                                        *
 *  It can be invoked via option 10 of the user menu                 *
\*-------------------------------------------------------------------*/
trace n
parse source . . rexxname .

arg clpgi clpgs clro cloc cldo clic

mode = sysvar("sysenv")
if mode ^= 'FORE' then do
  say rexxname':' Date() Time()
  say rexxname':'
  say rexxname': clpgi...........:' clpgi '(processor group info)'
  say rexxname': clpgs...........:' clpgs '(processor group symbolics)'
  say rexxname': clro............:' clro  '(related objects)'
  say rexxname': cloc............:' cloc  '(output components)'
  say rexxname': cldo............:' cldo  '(differences only)'
  say rexxname': clic............:' cldo  '(input components)'
  say rexxname':'
  if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i
end /* mode ^= 'FORE' */

true               = 1
false              = 0

rpt_input_compnts  = true
rpt_processor_info = false
rpt_symbolic_info  = false
rpt_related_objcts = true
rpt_output_compnts = false
rpt_changes_only   = true

if clpgi = 'YES' then rpt_processor_info = true
if clpgs = 'YES' then rpt_symbolic_info  = true
if clro  = 'NO'  then rpt_related_objcts = false
if cloc  = 'YES' then rpt_output_compnts = true
if cldo  = 'NO'  then rpt_changes_only   = false
if clic  = 'NO'  then rpt_input_compnts  = false
/* process old component list report                                 */
"execio * diskr complst1 (stem complist. finis"
if rc ^= 0 then call exception rc 'DISKR of COMPLST1 failed'

do i = 1 to 13 /* process header details                             */

  environment_pos = wordpos('ENVIRONMENT:',complist.i) + 1
  if environment_pos > 1 then
    old_environment = word(complist.i,environment_pos)

  system_pos      = wordpos(' SYSTEM:',complist.i)     + 1
  if system_pos > 1 then
    old_system      = word(complist.i,system_pos)

  subsystem_pos   = wordpos('SUBSYSTEM:',complist.i)   + 1
  if subsystem_pos > 1 then
    old_subsystem   = word(complist.i,subsystem_pos)

  element_pos     = wordpos('ELEMENT:',complist.i)     + 1
  if element_pos > 1 then
    old_element     = word(complist.i,element_pos)

  type_pos        = wordpos('  TYPE:',complist.i)      + 1
  if type_pos > 1 then
    if word(complist.i,type_pos - 2) ^= 'DELTA' then
      old_type        = word(complist.i,type_pos)

  stage_id_pos    = wordpos('STAGE ID:',complist.i)    + 2
  if stage_id_pos > 2 then
    old_stage_id    = word(complist.i,stage_id_pos)

end /* i = 1 to 13 */

call process_cmpnt_list_print

call sort_old_cmpnt_list_data

/* process new component list report                                 */
"execio * diskr complst2 (stem complist. finis"
if rc ^= 0 then call exception rc 'DISKR of COMPLST2 failed'

do i = 1 to 13 /* process header details                             */

  environment_pos = wordpos('ENVIRONMENT:',complist.i) + 1
  if environment_pos > 1 then
    new_environment = word(complist.i,environment_pos)

  system_pos      = wordpos(' SYSTEM:',complist.i)     + 1
  if system_pos > 1 then
    new_system      = word(complist.i,system_pos)

  subsystem_pos   = wordpos('SUBSYSTEM:',complist.i)   + 1
  if subsystem_pos > 1 then
    new_subsystem   = word(complist.i,subsystem_pos)

  element_pos     = wordpos('ELEMENT:',complist.i)     + 1
  if element_pos > 1 then
    new_element     = word(complist.i,element_pos)

  type_pos        = wordpos('  TYPE:',complist.i)      + 1
  if type_pos > 1 then
    if word(complist.i,type_pos - 2) ^= 'DELTA' then
      new_type        = word(complist.i,type_pos)

  stage_id_pos    = wordpos('STAGE ID:',complist.i)    + 2
  if stage_id_pos > 2 then
    new_stage_id    = word(complist.i,stage_id_pos)

end /* i = 1 to 13 */

call process_cmpnt_list_print

call sort_new_cmpnt_list_data

/* compare and process 2 sets of stem variables                      */
call compare_cmpnt_lists

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Process a component list print report                             */
/*-------------------------------------------------------------------*/
process_cmpnt_list_print:

 source_level_found       = false
 element_found            = false
 symbols_found            = false
 input_compnts_found      = false
 output_compnts_found     = false
 related_objects_found    = false

 sect_count               = 0
 input_step_ddname_count  = 0
 output_step_ddname_count = 0
 input_step_ddname.       = ''
 input_step_ddname.0      = input_step_ddname_count
 output_step_ddname.      = ''
 output_step_ddname.0     = output_step_ddname_count
 rel_obj.                 = ''
 rel_obj.0                = 0

 do i = 14 to complist.0 /* skip first 13 lines, already processed   */

   parse value complist.i with word1 word2 word3 word4 word5 word6,
               word7 word8 word9 word10 word11 word12 word13 word14

   if word1 = '' then iterate /* ignore blank lines                  */

   if strip(word1,,'-') = '' & strip(word2,,'-') = '' then iterate

   if strip(word1,,'-') = '' then do /* new section of output        */
     sect_count = 0
     old_section = section
     select
       when word2 = 'SOURCE' & word3 = 'LEVEL' then do
         source_level_found = true
         section = word2 word3
         if mode ^= 'FORE' then
           say rexxname': Source Level Section found'
       end /* word2 = 'SOURCE' & word3 = 'LEVEL' */

       when word2 = 'ELEMENT' then do
         element_found = true
         section = word2
         if mode ^= 'FORE' then
           say rexxname': Element Section found'
       end /* word2 = 'ELEMENT' */

       when word2 = 'PROCESSOR' then do
         processor_found = true
         section = word2
         if mode ^= 'FORE' then
           say rexxname': Processor Section found'
       end /* word2 = 'PROCESSOR' */

       when word2 = 'SYMBOL' then do
         symbols_found = true
         section = word2
         if mode ^= 'FORE' then
           say rexxname': Symbols Section found'
         symbol. = ''
       end /* word2 = 'SYMBOL' */

       when word2 = 'INPUT' & word3 = 'COMPONENTS' then do
         input_compnts_found = true
         section    = word2 word3
         if mode ^= 'FORE' then
           say rexxname': Input Components Section found'
         old_step   = ''
         old_ddname = ''
       end /* word2 = 'INPUT' & word3 = 'COMPONENTS' */

       when word2 = 'OUTPUT' & word3 = 'COMPONENTS' then do
         output_compnts_found = true
         section = word2 word3
         if mode ^= 'FORE' then
           say rexxname': Output Components Section found'
       end /* word2 = 'OUTPUT' & word3 = 'COMPONENTS' */

       when word2 = 'RELATED' & word3 = 'OBJECTS' then do
         related_objects_found = true
         section = word2 word3
         if mode ^= 'FORE' then
           say rexxname': Related Objects Section found'
       end /* word2 = 'RELATED' & word3 = 'OBJECTS' */

       otherwise do
         section = 'UNKNOWN - IGNORE'
         if mode ^= 'FORE' then do
           say rexxname': Unknown Section'
           say rexxname':' word2 word3 word4
           say rexxname': Ignoring'
         end /* mode ^= 'FORE' */
       end /* otherwise */
     end /* select */

     iterate /* finished processing this record, get next one        */

   end /* strip(word1,,-') = '' */

   sect_count = sect_count + 1
   select
     when section = 'SOURCE LEVEL' then
       call source_level_info

     when section = 'ELEMENT' then
       call element_info

     when section = 'PROCESSOR' then
       call processor_info

     when section = 'SYMBOL' then
       call symbol_processing

     when section = 'INPUT COMPONENTS' then
       select
         when word1 = 'STEP:' then call process_step_and_dd_and_dsn
         when left(word1,1) = '%' then call process_cmpnt_detail
         when left(word1,1) = '+' then call process_cmpnt_detail
         otherwise sect_count = sect_count - 1
       end /* select */

     when section = 'RELATED OBJECTS' then do
       rel_obj.sect_count = word2
       rel_obj.0          = sect_count
     end /* section = 'RELATED OBJECTS' */

     when section = 'OUTPUT COMPONENTS' then
       select
         when word1 = 'STEP:' then call process_step_and_dd_and_dsn
         when left(word1,1) = '%' then call process_cmpnt_detail
         when left(word1,1) = '+' then call process_cmpnt_detail
         otherwise sect_count = sect_count - 1
       end /* select */

     otherwise /* Unknown section - loop through and ignore          */
       if mode ^= 'FORE' then
         say rexxname':' section sect_count':' complist.i
   end /* select */

 end /* i = 14 to complist.0 */

return /* process_cmpnt_list_print: */

/*-------------------------------------------------------------------*/
/* sort old component list data where necessary for compares         */
/*-------------------------------------------------------------------*/
sort_old_cmpnt_list_data:

 /* source level data is singleton so no sort necessary, just copy   */
 old_source_level_vvll       = source_level_vvll
 old_source_level_sync       = source_level_sync
 old_source_level_user       = source_level_user
 old_source_level_date       = source_level_date /* last action date */
 old_source_level_time       = source_level_time /* last action time */
 old_source_level_line_count = source_level_line_count
 old_source_level_ccid       = source_level_ccid
 old_source_level_comment    = source_level_comment

 /* element data is singleton so no sort necessary, just copy        */
 old_element_vvll            = element_vvll
 old_element_date            = element_date /* source date           */
 old_element_time            = element_time /* source time           */
 old_element_system          = element_system
 old_element_subsystem       = element_subsystem
 old_element_name            = element_name
 old_element_type            = element_type
 old_element_group           = element_group
 old_element_stage           = element_stage
 old_element_ste             = element_ste
 old_element_environment     = element_environment
 old_element_processor       = element_processor

 /* processor data is singleton so no sort necessary, just copy      */
 old_processor_vvll          = processor_vvll
 old_processor_date          = processor_date
 old_processor_time          = processor_time
 old_processor_system        = processor_system
 old_processor_subsystem     = processor_subsystem
 old_processor_name          = processor_name
 old_processor_type          = processor_type
 old_processor_group         = processor_group
 old_processor_stage         = processor_stage
 old_processor_ste           = processor_ste
 old_processor_environment   = processor_environment
 old_processor_processor     = processor_processor

 /* symbolics are in alphabetic order no sort necessary, just copy   */
 old_symbol.  = ''
 old_symbol.0 = symbol.0
 do i = 1 to symbol.0
   old_symbol.i   = symbol.i
   val            = symbol.i
   old_symbol.val = symbol.val
 end /* i = 1 to symbol.0 */

 /* sort list of related objects                                     */
 old_rel_obj.  = ''
 old_rel_obj.0 = 0
 if related_objects_found then do
   stemname      = 'rel_obj.'     /* input to bubble sort            */
   sort_stemname = 'old_rel_obj.' /* output to bubble sort           */
   showlist      = stemname sort_stemname
   call sort_stem
 end /* related_objects_found */

 /* sort list of input component step / ddname combinations          */
 old_input_step_ddname.  = ''
 old_input_step_ddname.0 = 0
 if input_compnts_found then do
   stemname      = 'input_step_ddname.'     /* input to bubble sort  */
   sort_stemname = 'old_input_step_ddname.' /* output to bubble sort */
   showlist      = stemname sort_stemname
   call sort_stem

   /* sort each of input component step / ddname stem-variables      */
   do i = 1 to old_input_step_ddname.0
     stemname        = old_input_step_ddname.i
     sorted_stemname = 'old_input_'old_input_step_ddname.i
     interpret sorted_stemname "= ''"
     sort_stemname   = sorted_stemname
     showlist        = stemname  sort_stemname
     call sort_stem

     interpret 'x =' sort_stemname'0'
     do j = 1 to x
       interpret 'key =' sort_stemname'j'
       interpret sort_stemname'key =' stemname'key'
     end /* j = 1 to x */
   end /* i = 1 to old_input_step_ddname.0 */
 end /* input_compnts_found */

 /* sort list of output component step / ddname combinations         */
 old_output_step_ddname.  = ''
 old_output_step_ddname.0 = 0
 if output_compnts_found then do
   stemname      = 'output_step_ddname.'     /* input to bubble sort */
   sort_stemname = 'old_output_step_ddname.' /* output to bubble sort*/
   showlist      = stemname sort_stemname
   call sort_stem

   /* sort each of output component step / ddname stem-variables     */
   do i = 1 to old_output_step_ddname.0
     stemname        = old_output_step_ddname.i
     sorted_stemname = 'old_output_'old_output_step_ddname.i
     interpret sorted_stemname "= ''"
     sort_stemname   = sorted_stemname
     showlist        = stemname sort_stemname
     call sort_stem

     interpret 'x =' sort_stemname'0'
     do j = 1 to x
       interpret 'key =' sort_stemname'j'
       interpret sort_stemname'key =' stemname'key'
     end /* j = 1 to x */
   end /* i = 1 to old_output_step_ddname.0 */
 end /* output_compnts_found */

return /* sort_old_cmpnt_list_data: */

/*-------------------------------------------------------------------*/
/* sort new component list data where necessary for compares         */
/*-------------------------------------------------------------------*/
sort_new_cmpnt_list_data:

 /* source level data is singleton so no sort necessary, just copy   */
 new_source_level_vvll       = source_level_vvll
 new_source_level_sync       = source_level_sync
 new_source_level_user       = source_level_user
 new_source_level_date       = source_level_date /* last action date */
 new_source_level_time       = source_level_time /* last action time */
 new_source_level_line_count = source_level_line_count
 new_source_level_ccid       = source_level_ccid
 new_source_level_comment    = source_level_comment

 /* element data is singleton so no sort necessary, just copy        */
 new_element_vvll            = element_vvll
 new_element_date            = element_date /* source date           */
 new_element_time            = element_time /* source time           */
 new_element_system          = element_system
 new_element_subsystem       = element_subsystem
 new_element_name            = element_name
 new_element_type            = element_type
 new_element_group           = element_group
 new_element_stage           = element_stage
 new_element_ste             = element_ste
 new_element_environment     = element_environment
 new_element_processor       = element_processor

 /* processor data is singleton so no sort necessary, just copy      */
 new_processor_vvll          = processor_vvll
 new_processor_date          = processor_date
 new_processor_time          = processor_time
 new_processor_system        = processor_system
 new_processor_subsystem     = processor_subsystem
 new_processor_name          = processor_name
 new_processor_type          = processor_type
 new_processor_group         = processor_group
 new_processor_stage         = processor_stage
 new_processor_ste           = processor_ste
 new_processor_environment   = processor_environment
 new_processor_processor     = processor_processor

 /* symbolics are in alphabetic order no sort necessary, just copy   */
 new_symbol.  = ''
 new_symbol.0 = symbol.0
 do i = 1 to symbol.0
   new_symbol.i   = symbol.i
   val            = symbol.i
   new_symbol.val = symbol.val
 end /* i = 1 to symbol.0 */

 /* sort list of related objects                                     */
 new_rel_obj.  = ''
 new_rel_obj.0 = 0
 if related_objects_found then do
   stemname      = 'rel_obj.' /* input to bubble sort              */
   sort_stemname = 'new_rel_obj.' /* output to bubble sort           */
   showlist      = stemname sort_stemname
   call sort_stem
 end /* related_objects_found */

 /* sort list of input component step / ddname combinations          */
 new_input_step_ddname.  = ''
 new_input_step_ddname.0 = 0
 if input_compnts_found then do
   stemname      = 'input_step_ddname.' /* input to bubble sort      */
   sort_stemname = 'new_input_step_ddname.' /* output to bubble sort */
   showlist      = stemname sort_stemname
   call sort_stem

   /* sort each of input component step / ddname stem-variables      */
   do i = 1 to new_input_step_ddname.0
     stemname        = new_input_step_ddname.i
     sorted_stemname = 'new_input_'new_input_step_ddname.i
     interpret sorted_stemname "= ''"
     sort_stemname   = sorted_stemname
     showlist        = stemname  sort_stemname
     call sort_stem

     interpret 'x =' sort_stemname'0'
     do j = 1 to x
       interpret 'key =' sort_stemname'j'
       interpret sort_stemname'key =' stemname'key'
     end /* j = 1 to x */
   end /* i = 1 to new_input_step_ddname.0 */
 end /* input_compnts_found */

 /* sort list of output component step / ddname combinations         */
 new_output_step_ddname.  = ''
 new_output_step_ddname.0 = 0
 if output_compnts_found then do
   stemname      = 'output_step_ddname.' /* input to bubble sort     */
   sort_stemname = 'new_output_step_ddname.' /* output to bubble sort*/
   showlist = stemname sort_stemname
   call sort_stem

   /* sort each of output component step / ddname stem-variables     */
   do i = 1 to new_output_step_ddname.0
     stemname        = new_output_step_ddname.i
     sorted_stemname = 'new_output_'new_output_step_ddname.i
     interpret sorted_stemname "= ''"
     sort_stemname   = sorted_stemname
     showlist        = stemname  sort_stemname
     call sort_stem

     interpret 'x =' sort_stemname'0'
     do j = 1 to x
       interpret 'key =' sort_stemname'j'
       interpret sort_stemname'key =' stemname'key'
     end /* j = 1 to x */
   end /* i = 1 to new_output_step_ddname.0 */
 end /* output_compnts_found */

return /* sort_new_cmpnt_list_data: */

/*-------------------------------------------------------------------*/
/* compare and process sorted component lists                        */
/*-------------------------------------------------------------------*/
compare_cmpnt_lists:

 if new_element ^= old_element then changed_text = '** Changed **'
                               else changed_text = ''
 rpt_line = 'NEW Element  :',
            left(new_element,17),
            'OLD Element  :',
            left(old_element,17),
            changed_text,
            ''
 queue rpt_line

 if new_subsystem ^= old_subsystem then changed_text = '** Changed **'
                                   else changed_text = ''
 rpt_line = '    Subsystem:',
            left(new_subsystem,17),
            '    Subsystem:',
            left(old_subsystem,17),
            changed_text,
            ''
 queue rpt_line

 if new_stage_id ^= old_stage_id then changed_text = '** Changed **'
                                 else changed_text = ''
 rpt_line = '    Stage    :',
            left(new_stage_id,17),
            '    Stage    :',
            left(old_stage_id,17),
            changed_text,
            ''
 queue rpt_line

 if new_type ^= old_type then changed_text = '** Changed **'
                         else changed_text = ''
 rpt_line = '    Type     :',
            left(new_type,17),
            '    Type     :',
            left(old_type,17),
            changed_text,
            ''
 queue rpt_line

 changed_text = ''
 if new_element_date ^= old_element_date then
   changed_text = '** Changed **'
 if new_element_time ^= old_element_time then
   changed_text = '** Changed **'
 rpt_line = '    Source Dt:',
            left(new_element_date,7),
            left(new_element_time,9),
            '    Source Dt:',
            left(old_element_date,7),
            left(old_element_time,9),
            changed_text,
            ''
 queue rpt_line

 if new_element_group ^= old_element_group then
   changed_text = '** Changed **'
 else
   changed_text = ''
 rpt_line = '    Prc Group:',
            left(new_element_group,17),
            '    Prc Group:',
            left(old_element_group,17),
            changed_text,
            ''
 queue rpt_line

 changed_text = ''
 rpt_line     = '    Comp Lst VVLL:',
                left(new_source_level_vvll,17),
                'Comp Lst VVLL:',
                left(old_source_level_vvll,17),
                changed_text,
                ''
 queue rpt_line

 queue ' '

 "EXECIO 8 DISKW report"
 if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

 if rpt_input_compnts then do
   if rpt_changes_only then do
     queue 'CHANGED INPUT COMPONENTS'
     queue '========================'
   end /* rpt_changes_only */
   else do
     queue 'INPUT COMPONENTS'
     queue '================'
   end /* else */
   "EXECIO 2 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

   hdr_not_printed = true
   i               = 1 /* new_input_step_ddname stem counter         */
   j               = 1 /* old_input_step_ddname stem counter         */
   do while i <= new_input_step_ddname.0 |,
            j <= old_input_step_ddname.0
     new_stepdd_name = new_input_step_ddname.i
     old_stepdd_name = old_input_step_ddname.j
     if new_stepdd_name = '' then new_stepdd_name = 'FF'X
     if old_stepdd_name = '' then old_stepdd_name = 'FF'X
     if new_stepdd_name < old_stepdd_name then do
       changed_text    = '<== NEW Only'
       step_ddname = strip(translate(new_stepdd_name,' ','_'),'T','.')
       step            = word(step_ddname,1)
       ddname          = word(step_ddname,2)
       hdr_line        = 'Processor Step:',
                         left(step,8),
                         'DDName:',
                         left(ddname,32),
                         changed_text,
                         ''
       hdr_not_printed = true
       step_ddname     = 'new_input_'new_stepdd_name
       call report_singleton_step_ddname
       i = i + 1
     end /* new_stepdd_name < old_stepdd_name */
     else
       if new_stepdd_name > old_stepdd_name then do
         changed_text    = '<== OLD Only'
         step_ddname = strip(translate(old_stepdd_name,' ','_'),'T','.')
         step            = word(step_ddname,1)
         ddname          = word(step_ddname,2)
         hdr_line        = 'Processor Step:',
                           left(step,8),
                           'DDName:',
                           left(ddname,32),
                           changed_text,
                           ''
         hdr_not_printed = true
         step_ddname     = 'old_input_'old_stepdd_name
         call report_singleton_step_ddname
         j = j + 1
       end /* new_stepdd_name > old_stepdd_name */
       else do /* old and new step name and ddname match             */
         changed_text    = ''
         step_ddname = strip(translate(old_stepdd_name,' ','_'),'T','.')
         step            = word(step_ddname,1)
         ddname          = word(step_ddname,2)
         hdr_line        = 'Processor Step:',
                           left(step,8),
                           'DDName:',
                           left(ddname,32),
                           changed_text,
                           ''
         hdr_not_printed = true
         step_ddname     = old_stepdd_name
         old_step_ddname = 'old_input_'step_ddname
         new_step_ddname = 'new_input_'step_ddname
         showlist        = old_step_ddname new_step_ddname
         call report_matching_step_ddname
         i = i + 1
         j = j + 1
       end /* else */
   end /* while i <= new_input_step_ddname.0 | ... */

   queue ' '
   "EXECIO 1 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

 end /* rpt_input_compnts */

 if rpt_output_compnts then do
   if rpt_changes_only then do
     queue 'CHANGED OUTPUT COMPONENTS'
     queue '========================='
   end /* rpt_changes_only */
   else do
     queue 'OUTPUT COMPONENTS'
     queue '================='
   end /* else */
   "EXECIO 2 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

   hdr_not_printed = true
   i               = 1 /* new_output_step_ddname stem counter        */
   j               = 1 /* old_output_step_ddname stem counter        */
   do while i <= new_output_step_ddname.0 |,
            j <= old_output_step_ddname.0
     new_stepdd_name = new_output_step_ddname.i
     old_stepdd_name = old_output_step_ddname.j
     if new_stepdd_name = '' then new_stepdd_name = 'FF'X
     if old_stepdd_name = '' then old_stepdd_name = 'FF'X
     if new_stepdd_name < old_stepdd_name then do
       changed_text    = '<== NEW Only'
       step_ddname = strip(translate(new_stepdd_name,' ','_'),'T','.')
       step            = word(step_ddname,1)
       ddname          = word(step_ddname,2)
       hdr_line        = 'Processor Step:',
                         left(step,8),
                         'DDName:',
                         left(ddname,32),
                         changed_text,
                         ''
       hdr_not_printed = true
       step_ddname     = 'new_output_'new_stepdd_name
       call report_singleton_step_ddname
       i = i + 1
     end /* new_stepdd_name < old_stepdd_name */
     else
       if new_stepdd_name > old_stepdd_name then do
         changed_text    = '<== OLD Only'
         step_ddname = strip(translate(old_stepdd_name,' ','_'),'T','.')
         step            = word(step_ddname,1)
         ddname          = word(step_ddname,2)
         hdr_line        = 'Processor Step:',
                           left(step,8),
                           'DDName:',
                           left(ddname,32),
                           changed_text,
                           ''
         hdr_not_printed = true
         step_ddname     = 'old_output_'old_stepdd_name
         call report_singleton_step_ddname
         j = j + 1
       end /* new_stepdd_name > old_stepdd_name */
       else do /* old and new step name and ddname match             */
         changed_text    = ''
         step_ddname = strip(translate(old_stepdd_name,' ','_'),'T','.')
         step            = word(step_ddname,1)
         ddname          = word(step_ddname,2)
         hdr_line        = 'Processor Step:',
                           left(step,8),
                           'DDName:',
                           left(ddname,32),
                           changed_text,
                           ''
         hdr_not_printed = true
         step_ddname     = old_stepdd_name
         old_step_ddname = 'old_output_'step_ddname
         new_step_ddname = 'new_output_'step_ddname
         showlist        = old_step_ddname new_step_ddname
         call report_matching_step_ddname
         i = i + 1
         j = j + 1
       end /* else */
   end /* while i <= new_output_step_ddname.0 | ... */

   queue ' '
   "EXECIO 1 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

 end /* rpt_output_compnts */

 if rpt_processor_info then do
   queue 'PROCESSOR GROUP INFO'
   queue '===================='
   queue ' '
   "EXECIO 3 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
   if new_element_group ^= old_element_group then
     changed_text = '** Changed **'
   else
     changed_text = ''
   rpt_line = 'NEW Prc Group:',
              left(new_element_group,17),
              'OLD Prc Group:',
              left(old_element_group,17),
              changed_text,
              ''
   queue rpt_line

   if new_processor_name ^= old_processor_name then
     changed_text = '** Changed **'
   else
     changed_text = ''
   rpt_line = '    Processor:',
              left(new_processor_name,17),
              '    Processor:',
              left(old_processor_name,17),
              changed_text,
              ''
   queue rpt_line

   changed_text = ''
   if new_processor_date ^= old_processor_date then
     changed_text = '** Changed **'
   if new_processor_time ^= old_processor_time then
     changed_text = '** Changed **'
   rpt_line = '    Fprint Dt:',
              left(new_processor_date,7),
              left(new_processor_time,9),
              '    Fprint Dt:',
              left(old_processor_date,7),
              left(old_processor_time,9),
              changed_text,
              ''
   queue rpt_line

   if new_processor_stage ^= old_processor_stage then
     changed_text = '** Changed **'
   else changed_text = ''
   rpt_line = '    Prc Stage:',
              left(new_processor_stage,17),
              '    Prc Stage:',
              left(old_processor_stage,17),
              changed_text,
              ''
   queue rpt_line

   queue ' '

   "EXECIO 5 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

 end /* rpt_processor_info */

 if rpt_symbolic_info then do
   if rpt_changes_only then do
     queue 'CHANGED GENERATE PROCESSOR SYMBOLS'
     queue '=================================='
   end /* rpt_changes_only */
   else do
     queue 'GENERATE PROCESSOR SYMBOLS'
     queue '=========================='
   end /* else */
   queue ' '
   "EXECIO 3 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
   rpt_line = left(' ',2),
                 left('Name',8),
                 left('NEW Value',48),
                 left('OLD Value (if different)',48),
                 ''
   queue rpt_line
   rpt_line = left(' ',2),
                 left('----',8),
                 left('---------',48),
                 left('------------------------',48),
                 ''
   queue rpt_line
   "EXECIO 2 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

   i = 1 /* new_symbol stem counter                                  */
   j = 1 /* old_symbol stem counter                                  */
   do while i <= new_symbol.0 | j <= old_symbol.0
     new_symbol_name = new_symbol.i
     old_symbol_name = old_symbol.j
     if new_symbol_name = '' then new_symbol_name = 'FF'X
     if old_symbol_name = '' then old_symbol_name = 'FF'X
     if new_symbol_name < old_symbol_name then do
       changed_text = '**'
       rpt_line     = left(changed_text,2),
                      left(new_symbol_name,8),
                      left(new_symbol.new_symbol_name,48),
                      left(' ',48),
                      ''
       queue rpt_line
       i = i + 1
     end /* new_symbol_name < old_symbol_name */
     else
       if new_symbol_name > old_symbol_name then do
         changed_text = '**'
         rpt_line     = left(changed_text,2),
                        left(old_symbol_name,8),
                        left(' ',48),
                        left(old_symbol.old_symbol_name,48),
                        ''
         queue rpt_line
         j = j + 1
       end /* new_symbol_name > old_symbol_name */
       else do
         new_value = new_symbol.new_symbol_name
         old_value = old_symbol.old_symbol_name
         if new_value ^= old_value then
           changed_text = '**'
         else do
           changed_text = ' '
           old_value    = ''
         end /* else */
         if ^rpt_changes_only | changed_text = '**' then do
           rpt_line = left(changed_text,2),
                      left(new_symbol_name,8),
                      left(new_value,48),
                      left(old_value,48),
                      ''
           queue rpt_line
         end /* ^rpt_changes_only | changed_text = '**' */
         i = i + 1
         j = j + 1
       end /* else */
     if ^rpt_changes_only | changed_text = '**' then
       "EXECIO 1 DISKW report"
       if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
   end /* until i >= new_symbol.0 & j >= old_symbol.0 */
   queue ' '
   "EXECIO 1 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
 end /* rpt_symbolic_info */

 if rpt_related_objcts then do
   if rpt_changes_only then do
     queue 'CHANGED RELATED OBJECTS'
     queue '======================='
   end /* rpt_changes_only */
   else do
     queue 'RELATED OBJECTS'
     queue '==============='
   end /* else */
   queue ' '
   "EXECIO 3 DISKW report"

   i = 1 /* new_rel_obj stem counter                                 */
   j = 1 /* old_rel_obj stem counter                                 */
   do while i <= new_rel_obj.0 | j <= old_rel_obj.0
     new_rel_obj_name = new_rel_obj.i
     old_rel_obj_name = old_rel_obj.j
     if new_rel_obj_name = '' then new_rel_obj_name = 'FF'X
     if old_rel_obj_name = '' then old_rel_obj_name = 'FF'X
     if new_rel_obj_name < old_rel_obj_name then do
       changed_text = '<== NEW Only'
       rel_obj_name = new_rel_obj_name
       if length(rel_obj_name) < 57 then
         rel_obj_name = left(rel_obj_name,57)
       rpt_line = '**',
                  'NEW:',
                  rel_obj_name,
                  changed_text,
                  ''
       queue rpt_line
       "EXECIO 1 DISKW report"
       i = i + 1
     end /* new_rel_obj_name < old_rel_obj_name */
     else
       if new_rel_obj_name > old_rel_obj_name then do
         changed_text = '<== OLD Only'
         rel_obj_name = old_rel_obj_name
         if length(rel_obj_name) < 57 then
           rel_obj_name = left(rel_obj_name,57)
         rpt_line = '**',
                    'OLD:',
                    rel_obj_name,
                    changed_text,
                    ''
         queue rpt_line
         "EXECIO 1 DISKW report"
         j = j + 1
       end /* new_rel_obj_name > old_rel_obj_name */
       else do /* i.e. new_rel_obj_name = old_rel_obj_name           */
         if ^rpt_changes_only then do
           changed_text = ''
           rel_obj_name = old_rel_obj_name
           if length(rel_obj_name) < 57 then
             rel_obj_name = left(rel_obj_name,57)
           rpt_line = '  ',
                      'NEW:',
                      rel_obj_name,
                      changed_text,
                      ''
           queue rpt_line
           rpt_line = '  ',
                      'OLD:',
                      rel_obj_name,
                      changed_text,
                      ''
           queue rpt_line
           "EXECIO 2 DISKW report"
         end /* ^rpt_changes_only */
         i = i + 1
         j = j + 1
       end /* else */
   end /* until i >= new_rel_obj.0 & j >= old_rel_obj.0 */
   queue ' '
   "EXECIO 1 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
 end /* rpt_symbolic_info */


 "EXECIO 0 DISKW report (FINIS"
 if rc ^= 0 then call exception rc 'DISKW of REPORT failed'

return /* compare_cmpnt_lists: */

/*-------------------------------------------------------------------*/
/* Process source level information records                          */
/*-------------------------------------------------------------------*/
source_level_info:

 if sect_count > 1 then
   parse var complist.i 1   .,
                        4   source_level_vvll,
                        9   source_level_sync,
                        14  source_level_user,
                        23  source_level_date,
                        31  source_level_time,
                        37  source_level_line_count,
                        46  source_level_ccid,
                        59  source_level_comment,
                        99  .

return /* source_level_info: */

/*-------------------------------------------------------------------*/
/* Process element information records                               */
/*-------------------------------------------------------------------*/
element_info:

 if sect_count = 2 then
   parse var complist.i 1   .,
                        14  element_vvll,
                        20  element_date,
                        28  element_time,
                        34  element_system,
                        43  element_subsystem,
                        52  element_name,
                        63  element_type,
                        72  element_group,
                        82  element_stage,
                        86  element_ste,
                        89  element_environment,
                        98  element_processor,
                        107 .

return /* element_info: */

/*-------------------------------------------------------------------*/
/* Process processor information records                             */
/*-------------------------------------------------------------------*/
processor_info:

 if sect_count = 2 then
   parse var complist.i 1   .,
                        14  processor_vvll,
                        20  processor_date,
                        28  processor_time,
                        34  processor_system,
                        43  processor_subsystem,
                        52  processor_name,
                        63  processor_type,
                        72  processor_group,
                        82  processor_stage,
                        86  processor_ste,
                        89  processor_environment,
                        98  processor_processor,
                        107 .

return /* processor_info: */

/*-------------------------------------------------------------------*/
/* Process symbol records                                            */
/*-------------------------------------------------------------------*/
symbol_processing:

 if sect_count ^= 1 then do /* ignore column headings                */
   parse var complist.i 1   .,
                        14  symbol_where_defined,
                        27  symbol_name,
                        41  symbol_value,
                        107 .
   symbol_name        = strip(symbol_name)
   symbol_value       = strip(symbol_value)
   x                  = sect_count - 1
   symbol.x           = symbol_name
   symbol.0           = x
   symbol.symbol_name = symbol_value
 end /* sect_count ^= 1 */

return /* symbol_processing: */

/*-------------------------------------------------------------------*/
/* Process change of Step, DDname and/or Dataset name                */
/*-------------------------------------------------------------------*/
process_step_and_dd_and_dsn:

 step = word2
 parse var complist.i . 'DD=' ddname ' ' . 'DSN=' dsname ' ' .
 if old_step ^= step | old_ddname ^= ddname then do
   step_ddname       = left(step,9,'_') || ddname || '.'
   step_ddname_count = 0
   if section = 'INPUT COMPONENTS' then do
     input_step_ddname_count  = input_step_ddname_count + 1
     input_step_ddname.input_step_ddname_count   = step_ddname
     input_step_ddname.0      = input_step_ddname_count
   end /* section = 'INPUT COMPONENTS' */
   else do
     output_step_ddname_count = output_step_ddname_count + 1
     output_step_ddname.output_step_ddname_count = step_ddname
     output_step_ddname.0     = output_step_ddname_count
   end /* else */

   old_step = step
   old_ddname = ddname
 end /* old_step ^= step | old_ddname ^= ddname */

return /* process_step_and_dd_and_dsn: */

/*-------------------------------------------------------------------*/
/* Process input component source detail line                        */
/*-------------------------------------------------------------------*/
process_cmpnt_detail:

 step_ddname_count = step_ddname_count + 1
 member            = word2
 fprnt_date        = word4
 fprnt_time        = word5
 fprnt_system      = word6
 fprnt_subsystem   = word7
 fprnt_element     = word8
 fprnt_type        = word9
 fprnt_stage       = word10
 fprnt_site        = word11
 fprnt_environment = word12

 interpret step_ddname || step_ddname_count' = member'
 interpret step_ddname'0 = step_ddname_count'
 interpret step_ddname || member' = dsname',
                                'fprnt_date',
                                'fprnt_time',
                                'fprnt_system',
                                'fprnt_subsystem'

return /* process_cmpnt_detail: */

/*-------------------------------------------------------------------*/
/* Sort the contents of a stem variable using bubblesort             */
/* to invoke this section, set up the following variables:           */
/*   stemname - contains the name of the stem variable to be sorted  */
/*   sort_stemname - contains the name of the stem variable that     */
/*                   holds the sorted output in numbered items       */
/*                                                                   */
/* Note that it ONLY sorts numeric tails to the stem variable, and   */
/* assumes that <stemname>.0 contains the highest numeric tail for   */
/* <stemname>.  Any non-numeric tails are NOT copied to the          */
/* output sort_stemname                                              */
/*                                                                   */
/*-------------------------------------------------------------------*/
sort_stem:
Procedure expose stemname sort_parms sort_stemname (showlist),
                 true false

 interpret 'i =' stemname'0'
 if i > 0 then do
   do j = 1 to i
     interpret 'msgs.j =' stemname'j'
   end /* j = 1 to i */
   msgs.0 = i
   call bubble_sort
   do j = 1 to i
     interpret sort_stemname'j = msgs.j'
   end /* j = 1 to i */
   interpret sort_stemname'0 = i'
 end /* i > 0 */

return /* sort_stem: */

/*-------------------------------------------------------------------*/
/*  Bubble sort for messages                                         */
/*-------------------------------------------------------------------*/
bubble_sort:
Procedure Expose msgs. false true

 sorted = false

 if msgs.0 <= 1 then sorted = true
 do i = msgs.0 to 1 by -1 while ^sorted
   sorted = true /* Assume the items are sorted                      */
   do j = 2 to i
     m = j-1
     if msgs.m > msgs.j then do /* If the items are out of order swap*/
       a      = msgs.m
       msgs.m = msgs.j
       msgs.j = a
       sorted = false /* We swapped two items, so were not sorted yet*/
     end /* if msgs.m > msgs.j */
   end /* j = 2 to i */
 end /* i = msgs.0 to 1 by -1 until sorted = 1 */

return /* bubble_sort: */

/*-------------------------------------------------------------------*/
/* report contents where step / dd name exists only for one list     */
/*-------------------------------------------------------------------*/
report_singleton_step_ddname:
procedure expose step_ddname save_trace,
                 hdr_not_printed hdr_line,
                 false,
                 (step_ddname)
 interpret 'x =' step_ddname'0'
 do y = 1 to x
   interpret 'member =' step_ddname'y'
   interpret 'compnt_line =' step_ddname || member
   parse value compnt_line with,
                              dsname,
                              fprnt_date,
                              fprnt_time,
                              fprnt_system,
                              fprnt_subsystem,
                              .
   new_or_old   = ''
   changed_text = ''
   if length(dsname) < 29 then dsname = left(dsname,29)
   rpt_line = '**',
              left(member,9),
              left(new_or_old,04),
              left(fprnt_date,7),
              left(fprnt_time,5),
              left(fprnt_subsystem,3),
              dsname,
              changed_text,
              ''
   if hdr_not_printed then do
     queue ' '
     queue hdr_line
     "EXECIO 2 DISKW report"
     hdr_not_printed = false
   end /* hdr_not_printed */
   queue rpt_line
   "EXECIO 1 DISKW report"
   if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
 end /* y = 1 to x */

return /* report_singleton_step_ddname: */

/*-------------------------------------------------------------------*/
/* report contents where matching step / ddname exist for both lists */
/*-------------------------------------------------------------------*/
report_matching_step_ddname:
procedure expose save_trace old_step_ddname,
                 new_step_ddname member,
                 hdr_not_printed hdr_line false,
                 rpt_changes_only,
                 (showlist)
 interpret 'p =' new_step_ddname'0'
 interpret 'q =' old_step_ddname'0'
 i = 1 /* value(new_step_ddname) stem counter                        */
 j = 1 /* value(old_step_ddname) stem counter                        */
 do until i >= p & j >= q
   interpret 'new_member =' new_step_ddname'i'
   interpret 'old_member =' old_step_ddname'j'
   if new_member = '' then new_member = 'FF'x
   if old_member = '' then old_member = 'FF'x
   if new_member < old_member then do
     interpret 'compnt_line =' new_step_ddname || new_member
     parse value compnt_line with,
                                dsname,
                                fprnt_date,
                                fprnt_time,
                                fprnt_system,
                                fprnt_subsystem,
                                .
     changed_text = '** Changed **'
     new_or_old   = 'NEW:'
     if length(dsname) < 29 then dsname = left(dsname,29)
     rpt_line = '**',
                left(new_member,9),
                left(new_or_old,04),
                left(fprnt_date,7),
                left(fprnt_time,5),
                left(fprnt_subsystem,3),
                dsname,
                changed_text,
                ''
     if hdr_not_printed then do
       queue ' '
       queue hdr_line
       "EXECIO 2 DISKW report"
       if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
       hdr_not_printed = false
     end /* hdr_not_printed */
     queue rpt_line
     "EXECIO 1 DISKW report"
     if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
     i = i + 1
   end /* new_member < old_member */
   else do
     if new_member > old_member then do
       interpret 'compnt_line =' old_step_ddname || old_member
       parse value compnt_line with,
                                  dsname,
                                  fprnt_date,
                                  fprnt_time,
                                  fprnt_system,
                                  fprnt_subsystem,
                                  .
       changed_text = '** Changed **'
       new_or_old   = 'OLD:'
       if length(dsname) < 29 then dsname = left(dsname,29)
       rpt_line = '**',
                  left(old_member,9),
                  left(new_or_old,04),
                  left(fprnt_date,7),
                  left(fprnt_time,5),
                  left(fprnt_subsystem,3),
                  dsname,
                  changed_text,
                  ''
       if hdr_not_printed then do
         queue ' '
         queue hdr_line
         "EXECIO 2 DISKW report"
         if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
         hdr_not_printed = false
       end /* hdr_not_printed */
       queue rpt_line
       "EXECIO 1 DISKW report"
       if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
       j = j + 1
     end /* new_member > old_member */
     else do
       interpret 'compnt_line =' old_step_ddname || old_member
       parse value compnt_line with,
                                  dsname,
                                  fprnt_date,
                                  fprnt_time,
                                  fprnt_system,
                                  fprnt_subsystem,
                                  .
       old_fprnt_date = fprnt_date
       old_fprnt_time = fprnt_time
       old_dsname     = dsname
       interpret 'compnt_line =' new_step_ddname || new_member
       parse value compnt_line with,
                                  dsname,
                                  fprnt_date,
                                  fprnt_time,
                                  fprnt_system,
                                  fprnt_subsystem,
                                  .
       changed_text = ' '
       changed_ind  = '  '
       if fprnt_date ^= old_fprnt_date |,
          fprnt_time ^= old_fprnt_time then do
         changed_text = '** Changed **'
         changed_ind  = '**'
       end /* fprnt_date ^= old_fprnt_date | ... */

       if fprnt_date = ' ' & dsname ^= old_dsname then do
         changed_text = '** Changed **'
         changed_ind  = '**'
       end /* fprnt_date = ' ' & dsname ^= old_dsname */
       new_or_old   = 'NEW:'
       if length(dsname) < 29 then dsname = left(dsname,29)
       rpt_line = changed_ind,
                  left(new_member,9),
                  left(new_or_old,04),
                  left(fprnt_date,7),
                  left(fprnt_time,5),
                  left(fprnt_subsystem,3),
                  dsname,
                  changed_text,
                  ''
       if ^rpt_changes_only | changed_ind = '**' then do
         if hdr_not_printed then do
           queue ' '
           queue hdr_line
           "EXECIO 2 DISKW report"
           if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
           hdr_not_printed = false
         end /* hdr_not_printed */
         queue rpt_line
       end /* ^rpt_changes_only | changed_ind = '**' */
       interpret 'compnt_line =' old_step_ddname || old_member
       parse value compnt_line with,
                                  dsname,
                                  fprnt_date,
                                  fprnt_time,
                                  fprnt_system,
                                  fprnt_subsystem,
                                  .
       new_or_old   = 'OLD:'
       changed_text = '  '
       if length(dsname) < 29 then dsname = left(dsname,29)
       rpt_line = '  ',
                  left(' ',9),
                  left(new_or_old,04),
                  left(fprnt_date,7),
                  left(fprnt_time,5),
                  left(fprnt_subsystem,3),
                  dsname,
                  changed_text,
                  ''
       if ^rpt_changes_only | changed_ind = '**' then do
         queue rpt_line
         "EXECIO 2 DISKW report"
         if rc ^= 0 then call exception rc 'DISKW of REPORT failed'
       end /* ^rpt_changes_only | changed_ind = '**' */
       i = i + 1
       j = j + 1
     end /* else */
   end /* else */
 end /*  i >= p & j >= q */

return /* report_matching_step_ddname: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code

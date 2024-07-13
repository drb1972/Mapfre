/* Rexx - This Rexx inserts hint lines into the ECOLS member */

address ISREDIT
"MACRO (PARMS)"
"BUILTIN RESET SPECIAL" /* reset any notes or warnings  */
ShowNote: /* add a few notes to help new users  */
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "To save issue END or SAVE',
                                      'command."'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "To omit column use * on line 1."'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  ] TYPE(OUTPUT) COLOR(GREEN) ',
                                      'CAPS(OFF) INTENS(LOW)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  ! TYPE(OUTPUT) COLOR(PINK)  ',
                                      'CAPS(OFF) INTENS(LOW)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  @ TYPE(OUTPUT) COLOR(BLUE)  ',
                                      'CAPS(OFF) INTENS(LOW)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  ¢ TYPE(OUTPUT) COLOR(WHITE) ',
                                      'CAPS(OFF) INTENS(HIGH)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  ¬ TYPE(OUTPUT) COLOR(RED)   ',
                                      'CAPS(OFF)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  ¦ TYPE(OUTPUT) COLOR(TURQ)  ',
                                      'CAPS(OFF)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  £ TYPE(OUTPUT) COLOR(YELLOW)',
                                      'CAPS(OFF)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "The attribute characters you may',
                                      'use are as follows:"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "To Reset to default, use the',
                                      'RESET command"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "using M|A|B Line commands."'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "Simply arrange the rows in the',
                                      'order you want,"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "Columns below the line will scroll."'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "Columns above the line are fixed."'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "Move the separator line to fix',
                                      'column in position."'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "Set Len column to change the',
                                      'width of each column."'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = MSGLINE  "Notes/Help                        "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
return

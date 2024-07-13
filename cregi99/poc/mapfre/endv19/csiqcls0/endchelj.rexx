/* REXX - THIS REXX INSERTS HINT LINES INTO THE ECOLS MEMBER */

ADDRESS ISREDIT
"MACRO (PARMS)"
"BUILTIN RESET SPECIAL" /* RESET ANY NOTES OR WARNINGS  */
SHOWNOTE: /* ADD A FEW NOTES TO HELP NEW USERS */
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "á¡¢ àþà®àpà¸äàENDàuàjà¸SAVE',
                                      'ä«äuä]äóàãã.áuä "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "äfä[äwàãçå<0àþà®àpà¸äà',
                                      '1ä[äbä]ãÍàp*àãç¶á¶ä "'
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
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  [ TYPE(OUTPUT) COLOR(TURQ)  ',
                                      'CAPS(OFF)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "  £ TYPE(OUTPUT) COLOR(YELLOW)',
                                      'CAPS(OFF)"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "ç¶á¶åFå|àoå_ã>á­ç2à¸äàã6á^àªànàeàÞâ:"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "äòä¤äêä®änàpäÞä±äîänàþà®àpà¸äà',
                                      'RESETä«äuä]äóàãç¶á¶ä "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "ä[äbä]àã¢§å¨àªå¥(|àpç@àK.Càdà®ä "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " M|A|Bä[äbä]äáä«äuä]äóàãç¶á¶àýäà"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "ä[äbä]àÐàÞá^àªäfä[äwà¸äþähä¨äìä®ä "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "ä[äbä]àÐàÞá;àªäfä[äwà¸¢máXä "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "áèåÁàÞä[äbä]àãñÍáUàýäàäfä[äwàã¢máXä "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE "åÝäfä[äwàª¢;àãå?¢_àþà®àpà¸äà',
                                      'LENäfä[äwàãáSáXä "'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
'ISREDIT LINE_AFTER .ZLAST = MSGLINE  "ñàåÄáó¢pâ/äsä®äP"'
'ISREDIT LINE_AFTER .ZLAST = NOTELINE " "'
RETURN

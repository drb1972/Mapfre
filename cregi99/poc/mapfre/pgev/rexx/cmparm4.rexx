/* REXX */

ADDRESS TSO
PARSE ARG ELEMENT

queue '****************************************************************'
queue '                                                                '
queue 'SORRY, YOU CANNOT DELETE MEMBERS FROM STAGE P THAT CONTAIN      '
queue 'WIZARD STATEMENTS. USING THE WIZARD PROCESSOR GROUP BYPASSES    '
queue 'AUTOMATIC SOURCE CHANGE TRACKING WHICH IN TURN SPEEDS UP THE    '
queue 'PROPAGATION PROCESS.                                            '
queue '                                                                '
queue 'THE SOURCE HISTORY IS MAINTAINED BY KEEPING THE STAGING DATASETS'
queue 'USED BY ENDEVOR AT STAGE F AND O. IF YOU DELETED 'ELEMENT' FROM '
queue 'STAGE P, THERE WOULD BE NO WAY OF TRACKING THE LIST OF          '
queue 'MEMBERS THAT RELATED TO A PARTICULAR CHANGE.                    '
queue '                                                                '
queue ' PLEASE CONTACT ENDEVOR SUPPORT FOR MORE INFORMATION.           '
queue '****************************************************************'

"EXECIO * DISKW README (FINIS"

EXIT 12

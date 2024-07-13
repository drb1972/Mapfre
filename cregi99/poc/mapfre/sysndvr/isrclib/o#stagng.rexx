IF System = ' ' | Subsystem = ' ' | Output = ' ' THEN $SkipRow = 'Y'
SuffixAll = '&Type.&Procgrp.V&num'
SuffixTyp = '&Type.V&num'
SuffixVer = 'V&num'
Suffix = SuffixAll
IF Procgrp = ' ' THEN Suffix = SuffixTyp
IF Type = ' ' THEN Suffix = SuffixVer
FromDataSet = '&FrmPrfx.&System.&Subsystem.&Suffix'
IF DATATYPE(Lvls) /= 'NUM' THEN Lvls = 0
DO num = 0 TO (Lvls-1); num=right(num,2,'0'); CALL BuildFromMODEL; END
num=right(num,2,'0')

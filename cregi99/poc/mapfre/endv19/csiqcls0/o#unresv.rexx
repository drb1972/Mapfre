MODEL = ELMTBL
If ElemTble = ' ' then MODEL = NOELMTBL
If Output = ' ' then $SkipRow = 'Y'
If FromDataSet = ' ' then FromDataSet = "UNRESOLVED!"
If System = ' ' then System = "UNRESOLVED!"
If Subsystem = ' ' then Subsystem = "UNRESOLVED!"
If Type = ' ' then Type = "UNRESOLVED!"
If Procgrp = ' ' then Procgrp = "UNRESOLVED!"
If DfltCCID = ' ' then DfltCCID = "UNRESOLVED!"
If DfltComment = ' ' then DfltComment = "UNRESOLVED!"
GenOption = "BYPASS GENERATE PROCESSOR"
If Generate = 'Y' then GenOption = " "

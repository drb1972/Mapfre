Sys = System
Cat = Category
SysCatClause = "SYSTEM ''" || Sys || "'' " || "CATEGORY ''" || Cat || "''"
IF Sys = ' ' & Cat = ' ' THEN SysCatClause = ' '
IF Sys = ' ' & Cat /= ' ' THEN SysCatClause = "CATEGORY ''" || Cat || "''"
IF Sys /= ' ' & Cat = ' ' THEN SysCatClause = "SYSTEM ''" || Sys || "''"

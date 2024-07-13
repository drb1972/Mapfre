IF Output = ' ' THEN $SkipRow = 'Y'
str = '&SJ$' || Output
PART1 = '//' || str || " DD DISP=SHR,DSN=" || '&LBPRFX' || '..'
str = Strip(str)
PART2 = PART1 || 'IMPORT' || '(' || str || ')'
DataRow = PART2

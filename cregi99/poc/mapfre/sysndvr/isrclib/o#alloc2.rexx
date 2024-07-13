  $pld = PreferredListingDatasetType
  DatasetType = PreferredBaseDatasetType
  IF Node = 'DELTA' THEN $SkipRow = 'Y'
  IF Node = 'LISTLIB' & $pld = 'ELIB' THEN $SkipRow = 'Y'
  IF Node = 'LLISTLIB' & $pld = 'ELIB' THEN $SkipRow = 'Y'
  IF Node = 'LISTLIB' THEN DatasetType = PreferredListingDatasetType
  IF Node = 'LLISTLIB' THEN DatasetType = PreferredListingDatasetType

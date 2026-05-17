# DiskCleanup.Improved.ps1

## Overview

`DiskCleanup.Improved.ps1` is an improved version of `DiskCleanup.ps1`.

The original script performs local disk cleanup tasks by removing temporary files, old logs, user temp data, IIS logs, ConfigMgr cache content, and recycle bin items. The improved script keeps the same intent but adds safer execution patterns, better structure, parameterization, and support for `-WhatIf`.

---

## What the original script does

Original file: `DiskCleanup.ps1`

### Original behavior
1. Defines a list of filesystem locations to clean
2. Starts a transcript under `C:\Windows\Temp`
3. Runs `delprof2.exe` if present
4. Removes files and directories from several fixed paths
5. Deletes user temp content
6. Deletes temporary internet files
7. Deletes IIS logs
8. Clears ConfigMgr cache through COM
9. Empties recycle bin content
10. Stops the transcript

### Issues in the original script
- hardcoded cleanup paths and transcript path
- destructive operations without `WhatIf`
- minimal error visibility
- no parameters
- no structured result output
- no ability to selectively enable or disable cleanup areas
- questionable `delprof2` command formatting
- limited documentation

---

## What the improved script does

Improved file: `DiskCleanup.Improved.ps1`

### Improved behavior
The improved script:
- supports configurable cleanup paths
- supports optional cleanup of:
  - user temp files
  - temporary internet files
  - IIS logs
  - ConfigMgr cache
  - recycle bin
- supports optional `delprof2` execution
- returns structured result objects
- starts and stops a transcript safely
- supports `-WhatIf` and confirmation behavior
- uses helper functions for maintainability

---

## Key improvements

- Added `CmdletBinding(SupportsShouldProcess = $true)`
- Added `-WhatIf` compatibility
- Added parameters for cleanup behavior
- Added safer transcript handling
- Added structured result output
- Added helper functions:
  - `Remove-PathContentSafely`
  - `Invoke-DelProfCleanup`
  - `Clear-CcmCache`
  - `Clear-RecycleBinContent`
- Added clearer error handling
- Added comment-based help

---

## Parameters

### `-CleanupPaths`
One or more file or folder patterns to clean.

The script includes the original cleanup locations as defaults.

### `-IncludeUserTemp`
Also cleans user temp folders:
```powershell
C:\Users\*\AppData\Local\Temp\*
```

### `-IncludeTemporaryInternetFiles`
Also cleans:
```powershell
C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*
```

### `-IncludeIisLogs`
Also cleans:
```powershell
C:\inetpub\logs\LogFiles\*
```

### `-IncludeCcmCache`
Attempts to clear Microsoft Configuration Manager client cache through COM.

### `-IncludeRecycleBin`
Attempts to remove recycle bin contents.

### `-DelProfPath`
Path to `delprof2.exe`.

**Default**
```powershell
C:\Scripts\delprof2.exe
```

### `-DelProfDays`
Age threshold used for `delprof2`.

**Default**
```powershell
60
```

### `-TranscriptPath`
Transcript log file path.

By default, the script writes a timestamped log under:
```powershell
C:\Windows\Temp
```

---

## How to use the script

> This script was not executed here and should only be run in the correct target environment.

### Default usage
```powershell
.\DiskCleanup.Improved.ps1
```

### Safe preview with WhatIf
```powershell
.\DiskCleanup.Improved.ps1 -WhatIf
```

### Include additional cleanup areas
```powershell
.\DiskCleanup.Improved.ps1 -IncludeUserTemp -IncludeTemporaryInternetFiles -IncludeIisLogs
```

### Include ConfigMgr cache and recycle bin cleanup
```powershell
.\DiskCleanup.Improved.ps1 -IncludeCcmCache -IncludeRecycleBin
```

### Use a custom transcript path
```powershell
.\DiskCleanup.Improved.ps1 -TranscriptPath C:\Temp\DiskCleanup.log
```

---

## Expected output

The script returns structured objects such as:

```powershell
TargetPath    : C:\Windows\Temp\
Result        : Success
RemovedCount  : 42
ErrorMessage  :
```

and action-level objects such as:

```powershell
Action       : CCMCache
Result       : Success
RemovedCount : 10
ErrorMessage :
```

---

## Prerequisites

Before using in the correct environment:
- run with appropriate privileges
- ensure the account can remove files from the target locations
- ensure COM access exists if using ConfigMgr cache cleanup
- ensure `delprof2.exe` exists if profile cleanup is required

---

## Safety notes

This script performs destructive cleanup operations.
Use:
```powershell
-WhatIf
```
first when reviewing changes in the proper environment.

---

## Files involved

- Original script: `DiskCleanup.ps1`
- Improved script: `DiskCleanup.Improved.ps1`
- Documentation: `DiskCleanup.Improved.md`

---

## Important note

This improved script was created through static analysis only.
It was **not executed on this machine**, because this is not the correct runtime environment for these infrastructure scripts.

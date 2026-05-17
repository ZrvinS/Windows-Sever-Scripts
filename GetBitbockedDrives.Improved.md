# GetBitbockedDrives.Improved.ps1

## Overview

`GetBitbockedDrives.Improved.ps1` is an improved version of `GetBitbockedDrives.ps1`.

The original script retrieves BitLocker drive information from a list of remote servers and writes the results to a text file. The improved version adds structured output, better validation, safer error handling, and CSV reporting by default.

---

## What the original script does

Original file: `GetBitbockedDrives.ps1`

### Original behavior
1. Reads server names from `.\servers.txt`
2. Runs `Get-BitLockerVolume` remotely for each server
3. Selects BitLocker-related properties
4. Writes the output to `.\BitlockResult.txt`

### Issues in the original script
- hardcoded file paths
- no parameter support
- no explicit reachability validation
- no clear failure reporting
- text output only
- no documentation

---

## What the improved script does

Improved file: `GetBitbockedDrives.Improved.ps1`

### Improved behavior
The improved version:
- accepts server names from a file or parameter
- optionally checks connectivity before remoting
- retrieves BitLocker volume information remotely
- returns structured objects with per-server status
- writes CSV output by default
- supports text output when needed

---

## Key improvements

- added parameters for input and output
- added server list validation
- added structured result objects
- added CSV support by default
- added append support
- added safer per-server error handling
- added comment-based help

---

## Parameters

### `-ServerListPath`
Path to the input server list file.

**Default**
```powershell
.\servers.txt
```

### `-ComputerName`
Optional list of server names. Overrides the file-based server list.

### `-OutputPath`
Report path.

**Default**
```powershell
.\BitLockerDriveReport.csv
```

### `-Append`
Appends to the existing report file.

### `-SkipPingTest`
Skips the ICMP reachability test before remote execution.

---

## How to use the script

> This script was not executed here.

### Default usage
```powershell
.\GetBitbockedDrives.Improved.ps1
```

### Specify servers directly
```powershell
.\GetBitbockedDrives.Improved.ps1 -ComputerName server01,server02
```

### Custom report output
```powershell
.\GetBitbockedDrives.Improved.ps1 -OutputPath .\reports\BitLockerDriveReport.csv
```

### Append to an existing report
```powershell
.\GetBitbockedDrives.Improved.ps1 -Append
```

---

## Expected output

Example object:

```powershell
ComputerName         : SERVER01
VolumeType           : OperatingSystem
MountPoint           : C:
EncryptionPercentage : 100
ProtectionStatus     : On
QueryStatus          : Success
ErrorMessage         :
```

Failure example:

```powershell
ComputerName         : SERVER02
VolumeType           :
MountPoint           :
EncryptionPercentage :
ProtectionStatus     :
QueryStatus          : Failed
ErrorMessage         : Server not reachable by ICMP ping.
```

---

## Output behavior

The improved script prefers CSV output.

### CSV output
If `-OutputPath` ends with `.csv`, the script exports data using `Export-Csv`.

### Text output
If a non-CSV path is supplied, the script writes a formatted text file.

---

## Files involved

- Original script: `GetBitbockedDrives.ps1`
- Improved script: `GetBitbockedDrives.Improved.ps1`
- Documentation: `GetBitbockedDrives.Improved.md`

---

## Important note

This improved script was created through static analysis only.
It was **not executed on this machine**, because this is not the correct runtime environment for these infrastructure scripts.

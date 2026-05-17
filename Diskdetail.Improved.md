# Diskdetail.Improved.ps1

## Overview

`Diskdetail.Improved.ps1` is an improved version of `Diskdetail.ps1`.

The original script retrieves disk size and free space information from a list of servers and writes the output to a text file. The improved version adds validation, structured output, better remoting hygiene, and CSV support by default.

---

## What the original script does

Original file: `Diskdetail.ps1`

### Original behavior
1. Reads server names from `.\servers.txt`
2. Tests server connectivity with `Test-Connection`
3. Uses WMI to retrieve logical disk information
4. Calculates size and free space in GB
5. Writes output to `.\output.txt`

### Issues in the original script
- hardcoded input and output paths
- no parameterization
- no structured failure handling
- text output only
- uses older `Get-WmiObject`
- output can mix objects and plain text strings

---

## What the improved script does

Improved file: `Diskdetail.Improved.ps1`

### Improved behavior
The improved script:
- accepts servers from a file or direct parameters
- optionally skips ping testing
- queries remote disk information using CIM
- returns structured objects
- exports reports to CSV by default
- supports text output when needed
- captures per-server failure information

---

## Key improvements

- added parameters for server input and output file path
- switched to `Get-CimInstance`
- added reusable helper functions
- added structured error reporting
- added CSV report support by default
- added append mode
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
Optional list of server names. Overrides the file input.

### `-OutputPath`
Output report path.

**Default**
```powershell
.\DiskDetailReport.csv
```

### `-Append`
Appends to the output file if it already exists.

### `-SkipPingTest`
Skips the ICMP reachability check.

---

## How to use the script

> This script was created by static analysis and was not executed here.

### Default usage
```powershell
.\Diskdetail.Improved.ps1
```

### Direct server input
```powershell
.\Diskdetail.Improved.ps1 -ComputerName server01,server02
```

### Custom report path
```powershell
.\Diskdetail.Improved.ps1 -OutputPath .\reports\DiskDetailReport.csv
```

### Append to an existing report
```powershell
.\Diskdetail.Improved.ps1 -Append
```

---

## Expected output

Example object:

```powershell
ComputerName : SERVER01
DriveId      : C:
SizeGB       : 250.00
FreeSpaceGB  : 94.25
QueryStatus  : Success
ErrorMessage :
```

Failure example:

```powershell
ComputerName : SERVER02
DriveId      :
SizeGB       :
FreeSpaceGB  :
QueryStatus  : Failed
ErrorMessage : Server not reachable by ICMP ping.
```

---

## Output behavior

The improved script prefers CSV output.

### CSV output
If `-OutputPath` ends with `.csv`, the data is exported with `Export-Csv`.

### Text output
If a non-CSV output path is supplied, the script writes a formatted text file.

---

## Files involved

- Original script: `Diskdetail.ps1`
- Improved script: `Diskdetail.Improved.ps1`
- Documentation: `Diskdetail.Improved.md`

---

## Important note

This improved script was created through static analysis only.
It was **not executed on this machine**, because this is not the correct runtime environment for these infrastructure scripts.

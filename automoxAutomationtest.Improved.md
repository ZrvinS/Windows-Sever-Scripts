# automoxAutomationtest.Improved.ps1

## Overview

`automoxAutomationtest.Improved.ps1` is an improved version of `automoxAutomationtest.ps1`.

The original script appears to be a local automation validation script that:
- checks a Windows service
- creates a directory on a network share
- collects process information
- inspects installed software from the uninstall registry

The improved version converts these actions into a structured and documented script with configurable inputs and CSV-capable reporting.

---

## What the original script does

Original file: `automoxAutomationtest.ps1`

### Original behavior
1. Checks the `BITS` service
2. Attempts to create the same directory twice on:
   - `\\Mcktorcfps01\wksmgmt\Public\`
3. Gets process data and converts it to CSV text
4. Queries installed software for names matching `Quest Change*`

### Issues in the original script
- duplicate directory creation command
- no parameters
- no reusable functions
- no structured export to files
- no centralized error handling
- no result summary
- no documentation
- fixed hardcoded values

---

## What the improved script does

Improved file: `automoxAutomationtest.Improved.ps1`

### Improved behavior
The improved version:
- checks a configurable Windows service
- optionally creates a test directory on a configurable path
- collects process inventory
- searches installed software using a configurable pattern
- exports process and software results to report files
- supports CSV output by default
- returns a structured summary object
- handles individual failures more safely

---

## Key improvements

- Added `CmdletBinding()`
- Added parameters for all major hardcoded values
- Removed duplicate directory creation logic
- Added helper functions:
  - `Export-StructuredData`
  - `Get-InstalledApplication`
- Added better error handling
- Added configurable CSV output paths
- Added append support
- Added comment-based help
- Added structured summary output

---

## Parameters

### `-ServiceName`
Name of the Windows service to inspect.

**Default**
```powershell
BITS
```

### `-DirectoryName`
Directory name to create on the target path.

**Default**
```powershell
AmitTest
```

### `-DirectoryPath`
Parent path for the directory creation step.

**Default**
```powershell
\\Mcktorcfps01\wksmgmt\Public\
```

### `-SoftwarePattern`
Pattern used to search installed applications in the uninstall registry.

**Default**
```powershell
Quest Change*
```

### `-ProcessOutputPath`
Report path for process inventory.

**Default**
```powershell
.\ProcessReport.csv
```

### `-SoftwareOutputPath`
Report path for software inventory.

**Default**
```powershell
.\InstalledSoftwareReport.csv
```

### `-SkipDirectoryCreation`
Skips the network directory creation step.

### `-Append`
Appends to existing report files.

---

## How to use the script

> This script was not executed in this environment.

### Default usage
```powershell
.\automoxAutomationtest.Improved.ps1
```

### Change the service and directory name
```powershell
.\automoxAutomationtest.Improved.ps1 -ServiceName Spooler -DirectoryName ValidationFolder
```

### Skip directory creation and write reports to a custom folder
```powershell
.\automoxAutomationtest.Improved.ps1 -SkipDirectoryCreation -ProcessOutputPath .\reports\Processes.csv -SoftwareOutputPath .\reports\Software.csv
```

### Append to existing CSV files
```powershell
.\automoxAutomationtest.Improved.ps1 -Append
```

---

## Expected output

The script returns a structured summary object containing:
- service check result
- directory creation result
- process output path
- software output path
- process count
- software match count

It also writes report files for:
- process inventory
- software inventory

---

## Output behavior

The improved script prefers CSV output for report-style data.

### CSV output
If the output paths end with `.csv`, the data is exported using `Export-Csv`.

### Text output
If a non-CSV file path is supplied, a formatted text report is written instead.

---

## Prerequisites

Before using in the proper environment:
- the account must have permission to query services and processes
- the account must have permission to access the target UNC path
- the registry paths for uninstall information must be accessible

---

## Files involved

- Original script: `automoxAutomationtest.ps1`
- Improved script: `automoxAutomationtest.Improved.ps1`
- Documentation: `automoxAutomationtest.Improved.md`

---

## Important note

This improved script was created by static analysis only.
It was **not executed on this machine**, because this is not the correct runtime environment for these infrastructure scripts.

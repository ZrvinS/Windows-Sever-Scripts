# FirmwareVersionFromILO.Improved.ps1

## Overview

`FirmwareVersionFromILO.Improved.ps1` is an improved version of `FirmwareVersionFromILO.ps1`.

The original script connects to HPE iLO endpoints, retrieves firmware inventory, and writes the output to a text file. The improved version adds parameterization, structured result handling, validation, and CSV report support.

---

## What the original script does

Original file: `FirmwareVersionFromILO.ps1`

### Original behavior
1. Changes to the user documents folder
2. Imports the HPE iLO PowerShell module
3. Reads iLO addresses from `.\ilolist.txt`
4. Uses hardcoded iLO credentials
5. Connects to each iLO
6. Retrieves firmware inventory
7. Writes output to `.\iloFirmareVersion.txt`

### Issues in the original script
- hardcoded credentials
- hardcoded working directory behavior
- no parameter support
- no structured reporting
- limited error handling
- includes undefined variables in output
- text output only

---

## What the improved script does

Improved file: `FirmwareVersionFromILO.Improved.ps1`

### Improved behavior
The improved version:
- reads iLO addresses from a file or direct parameter
- accepts credentials as parameters
- validates the module path
- imports the HPE iLO module safely
- retrieves firmware inventory in a structured way
- exports results to CSV by default
- records failed iLO connections with error details

---

## Key improvements

- removed hardcoded credential values
- added parameters for module path, address input, and output file path
- added reusable address loading and export helpers
- added structured output objects
- added CSV report support by default
- added append support
- added comment-based help

---

## Parameters

### `-ILOListPath`
Path to the iLO address list file.

**Default**
```powershell
.\ilolist.txt
```

### `-Address`
Optional list of iLO addresses. Overrides `-ILOListPath`.

### `-UserName`
iLO user name.

### `-Password`
iLO password.

### `-ModulePath`
Path to the HPE iLO PowerShell module manifest.

### `-OutputPath`
Report path.

**Default**
```powershell
.\IloFirmwareVersionReport.csv
```

### `-Append`
Appends to the output file.

---

## How to use the script

> This script was not executed here.

### Default file-based usage
```powershell
.\FirmwareVersionFromILO.Improved.ps1 -UserName admin -Password secret
```

### Direct address usage
```powershell
.\FirmwareVersionFromILO.Improved.ps1 -Address ilo01,ilo02 -UserName admin -Password secret
```

### Custom output path
```powershell
.\FirmwareVersionFromILO.Improved.ps1 -UserName admin -Password secret -OutputPath .\reports\IloFirmwareVersionReport.csv
```

---

## Expected output

Example object:

```powershell
ILOAddress   : ilo01
Name         : iLO
Version      : 2.82
Location     : System Board
Status       : Success
ErrorMessage :
```

Failure example:

```powershell
ILOAddress   : ilo02
Name         :
Version      :
Location     :
Status       : Failed
ErrorMessage : Authentication failed.
```

---

## Output behavior

The improved version prefers CSV output.

### CSV output
If `-OutputPath` ends with `.csv`, the data is written using `Export-Csv`.

### Text output
If a non-CSV path is used, a formatted text report is written.

---

## Files involved

- Original script: `FirmwareVersionFromILO.ps1`
- Improved script: `FirmwareVersionFromILO.Improved.ps1`
- Documentation: `FirmwareVersionFromILO.Improved.md`

---

## Important note

This improved script was created through static analysis only.
It was **not executed on this machine**, because this is not the correct runtime environment for these infrastructure scripts.

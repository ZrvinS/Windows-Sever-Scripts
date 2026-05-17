# 3NodeClusterValidation.Improved.ps1

## Overview

`3NodeClusterValidation.Improved.ps1` is an improved version of `3NodeClusterValidation.ps1`.

Its purpose is to validate whether a remote cluster has at least three nodes and to export the result in a structured report. The improved version adds validation, safer remoting, structured output, better error handling, and configurable report generation.

---

## What the original script does

Original file: `3NodeClusterValidation.ps1`

### Original behavior
1. Reads server names from `.\servers.txt`
2. Tests connectivity with `Test-Connection`
3. Creates a PowerShell session to each server
4. Runs `Get-ClusterNode` remotely
5. Checks whether the cluster contains at least three nodes
6. Exports results to `.\ClusterNodesReport.csv`

### Issues in the original script
- hardcoded input and output paths
- no parameter support
- weak error reporting
- inconsistent handling of session creation failures
- no centralized validation
- limited documentation
- session lifecycle could be handled more safely
- no option to append output or change file format/path

---

## What the improved script does

Improved file: `3NodeClusterValidation.Improved.ps1`

### Improved behavior
The improved script:
- accepts server names from a file or directly from parameters
- optionally skips the ping test
- validates input before processing
- creates a remote session per server
- collects cluster node information from the target
- determines whether the cluster has three or more nodes
- returns structured objects to the pipeline
- exports the results to CSV by default
- supports text output if a non-CSV file path is used
- records failures per server in a dedicated `ErrorMessage` field

---

## Key improvements

- Added `CmdletBinding()`
- Added reusable helper functions
- Added support for:
  - `-ServerListPath`
  - `-ComputerName`
  - `-OutputPath`
  - `-Append`
  - `-SkipPingTest`
  - `-IncludeTimestamp`
- Improved session cleanup with `finally`
- Added structured result objects
- Added per-server query status reporting
- Added configurable output format with CSV support by default
- Added comment-based help

---

## Parameters

### `-ServerListPath`
Path to a text file containing one server name per line.

**Default**
```powershell
.\servers.txt
```

### `-ComputerName`
List of server names passed directly to the script.

If supplied, this overrides `-ServerListPath`.

### `-OutputPath`
Path to the report file to create.

**Default**
```powershell
.\ClusterNodesReport.csv
```

If the output path ends with `.csv`, the script exports CSV.
Otherwise, it writes a formatted text report.

### `-Append`
Appends to the report file if it already exists.

### `-SkipPingTest`
Skips the ICMP connectivity test and attempts remoting directly.

### `-IncludeTimestamp`
Adds a `CollectionTime` property to each output object.

---

## How to use the script

> This script was not executed here. Use it only in the correct infrastructure environment.

### Default usage
```powershell
.\3NodeClusterValidation.Improved.ps1
```

### Direct server input
```powershell
.\3NodeClusterValidation.Improved.ps1 -ComputerName node01,node02
```

### Custom CSV output path
```powershell
.\3NodeClusterValidation.Improved.ps1 -ServerListPath .\servers.txt -OutputPath .\reports\ClusterNodesReport.csv
```

### Append to an existing report
```powershell
.\3NodeClusterValidation.Improved.ps1 -OutputPath .\reports\ClusterNodesReport.csv -Append
```

### Include timestamp and verbose output
```powershell
.\3NodeClusterValidation.Improved.ps1 -ComputerName node01,node02 -IncludeTimestamp -Verbose
```

---

## Expected output

Example object:

```powershell
ComputerName : NODE01
Reachable    : True
QueryStatus  : Success
ClusterNode1 : NODE01
ClusterNode2 : NODE02
ClusterNode3 : NODE03
NodeCount    : 3
IsThreeNode  : True
ErrorMessage :
```

Failure example:

```powershell
ComputerName : NODE04
Reachable    : False
QueryStatus  : Failed
ClusterNode1 :
ClusterNode2 :
ClusterNode3 :
NodeCount    : 0
IsThreeNode  : False
ErrorMessage : Server not reachable by ICMP ping.
```

---

## Prerequisites

Before using the script in the correct environment:
- PowerShell remoting must be enabled
- the target must allow remote session creation
- the account must have required privileges
- `Get-ClusterNode` must be available on the target server
- cluster-related cmdlets/modules must be installed on the target

---

## Output behavior

The improved version prefers CSV output for reporting.

### CSV output
If `-OutputPath` ends with `.csv`, output is written using `Export-Csv`.

### Text output
If `-OutputPath` does not end with `.csv`, the script writes a formatted text report.

---

## Files involved

- Original script: `3NodeClusterValidation.ps1`
- Improved script: `3NodeClusterValidation.Improved.ps1`
- Documentation: `3NodeClusterValidation.Improved.md`

---

## Important note

This improved script was created through static analysis only.
It was **not run on this machine**, because this is not the correct runtime environment for these infrastructure scripts.

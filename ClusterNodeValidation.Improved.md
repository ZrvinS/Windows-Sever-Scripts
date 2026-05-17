# ClusterNodeValidation.Improved.ps1

## Overview

`ClusterNodeValidation.Improved.ps1` is an improved and safer version of the original `ClusterNodeValidation.ps1`.

The original script:
- reads server names from `.\Servers.txt`
- runs `Get-ClusterGroup` remotely against each server
- tries to select unique owner nodes
- writes the output to `ClusterNodeResult.txt`

The improved script keeps the same core purpose, but makes the behavior clearer, safer, and easier to maintain.

---

## What the original script does

Original file: `ClusterNodeValidation.ps1`

### Original behavior
1. Reads server names from `.\Servers.txt`
2. Loops through each server
3. Uses `Invoke-Command` to run `Get-ClusterGroup` remotely
4. Selects cluster-related properties
5. Writes the final output to `ClusterNodeResult.txt`

### Issues in the original script
- No parameter support
- No input validation
- No error handling
- Property typo/misuse:
  - `Onwernode` is misspelled
  - `select -ExcludeProperty Onwernode` does not match intended logic
- Output is not strongly structured
- Failures from one or more servers are not captured clearly
- Hardcoded input and output paths
- No documentation or usage examples

---

## What the improved script does

Improved file: `ClusterNodeValidation.Improved.ps1`

### Improved behavior
The improved script:
1. Accepts server names from either:
   - a text file using `-ServerListPath`
   - direct input using `-ComputerName`
2. Validates that the input file exists and contains valid server names
3. Connects to each server with `Invoke-Command`
4. Runs `Get-ClusterGroup` remotely
5. Returns structured objects containing:
   - `ComputerName`
   - `Reachable`
   - `QueryStatus`
   - `ClusterGroupName`
   - `OwnerNode`
   - `GroupState`
   - `ErrorMessage`
   - optionally `CollectionTime`
6. Writes the results to:
   - text output by default
   - CSV if the output file name ends with `.csv`
7. Returns objects to the pipeline for further use
8. Handles remote errors cleanly per server

---

## Key improvements made

### 1. Added parameters
The improved version removes hardcoded dependency on fixed paths by introducing:
- `-ServerListPath`
- `-ComputerName`
- `-OutputPath`
- `-Append`
- `-IncludeTimestamp`

### 2. Added validation
The script now validates:
- whether the server list file exists
- whether the file contains usable values
- whether server names are non-empty

### 3. Structured output
Instead of emitting partially transformed data, the script now returns consistent PowerShell objects.

This makes it easier to:
- export to CSV
- filter failed systems
- use the results in other scripts
- troubleshoot remoting issues

### 4. Better error handling
Each remote server is processed in a protected `try/catch` flow so failures are captured in the result set instead of silently breaking the script.

### 5. Better reporting
The script supports:
- plain text report output
- CSV report output
- optional append mode
- optional timestamps

### 6. Cleaner code structure
The logic is divided into helper functions:
- `Get-TargetServers`
- `Get-ClusterNodeValidationResult`

This makes the script easier to read, support, and extend.

### 7. Safer scripting practices
The script uses:
- `CmdletBinding()`
- `Set-StrictMode -Version Latest`
- `$ErrorActionPreference = 'Stop'`

These help surface coding and runtime problems more reliably.

---

## Parameters

### `-ServerListPath`
Path to a file containing one server name per line.

**Default:**
```powershell
.\Servers.txt
```

### `-ComputerName`
A list of server names passed directly to the script.

If this parameter is provided, it takes precedence over `-ServerListPath`.

**Example:**
```powershell
-ComputerName node01,node02,node03
```

### `-OutputPath`
Path to the report file to create.

**Default:**
```powershell
.\ClusterNodeResult.txt
```

If the file path ends with `.csv`, the script exports CSV.

### `-Append`
If specified, appends to the output file instead of overwriting it.

### `-IncludeTimestamp`
If specified, adds a `CollectionTime` property to each output object.

---

## How to use the script

> Do not run this script unless you are in the correct target environment with PowerShell remoting and cluster access configured.

### Example 1: Use default input and output files
```powershell
.\ClusterNodeValidation.Improved.ps1
```

Behavior:
- reads servers from `.\Servers.txt`
- writes the report to `.\ClusterNodeResult.txt`

### Example 2: Specify servers directly
```powershell
.\ClusterNodeValidation.Improved.ps1 -ComputerName node01,node02
```

Behavior:
- skips reading `Servers.txt`
- queries only the specified servers

### Example 3: Export to CSV
```powershell
.\ClusterNodeValidation.Improved.ps1 -ServerListPath .\MyServers.txt -OutputPath .\ClusterNodeResult.csv
```

Behavior:
- reads servers from `MyServers.txt`
- exports structured CSV output

### Example 4: Append to an existing report
```powershell
.\ClusterNodeValidation.Improved.ps1 -OutputPath .\ClusterNodeResult.csv -Append
```

### Example 5: Include timestamps and verbose logging
```powershell
.\ClusterNodeValidation.Improved.ps1 -ComputerName node01,node02 -IncludeTimestamp -Verbose
```

---

## Expected output

### PowerShell object output
The script returns objects like:

```powershell
ComputerName     : node01
Reachable        : True
QueryStatus      : Success
ClusterGroupName : Cluster Group
OwnerNode        : node01
GroupState       : Online
ErrorMessage     :
CollectionTime   : 18-05-2026 01:44:00
```

### Failure example
```powershell
ComputerName     : node02
Reachable        : False
QueryStatus      : Failed
ClusterGroupName :
OwnerNode        :
GroupState       :
ErrorMessage     : Access is denied.
```

---

## Prerequisites

Before using the script in the proper environment, ensure:
- PowerShell remoting is enabled
- target servers are reachable
- the account running the script has permission for remote execution
- the failover clustering module/cmdlets are available on the target hosts
- `Get-ClusterGroup` works remotely on the target systems

---

## Files created

Depending on parameters, the script creates:
- a text report, for example:
  - `ClusterNodeResult.txt`
- or a CSV report, for example:
  - `ClusterNodeResult.csv`

No original project file is modified.

---

## Why this version is better

This version is better than the original because it is:
- easier to understand
- easier to reuse
- safer to run in the correct environment
- easier to troubleshoot
- less dependent on hardcoded assumptions
- more suitable for automation and reporting

---

## Related files

- Original script: `ClusterNodeValidation.ps1`
- Improved script: `ClusterNodeValidation.Improved.ps1`

---

## Important note

This improved script was created by static analysis only.
It was **not executed on this machine**, because this environment is not the correct runtime environment for these infrastructure scripts.

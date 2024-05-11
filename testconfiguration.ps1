[xml]$xmldata = Get-Content(".\configuration.xml")
$data = $xmldata.global

function serverpull($process) {

    Get-Service -Name $process
}


& $data.functions.function -process bits
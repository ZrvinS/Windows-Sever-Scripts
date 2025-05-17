Import-Module "C:\Program Files\WindowsPowerShell\Modules\hpeilocmdlets.4.4.0\HPEiLOCmdlets.psd1"

    $iloconnection = Connect-HPEiLO -Address $ilo -Username $ilouser -Password $ilopassword -DisableCertificateAuthentication
    
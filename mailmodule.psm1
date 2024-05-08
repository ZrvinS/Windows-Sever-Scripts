 function sendmail {
    [CmdletBinding()]
    param (
        
        # Parameter help description
        [Parameter(ValueFromPipeline)]
        [switch]
        $message,
        [string]
        $Messagetosend = "Test mail"
    )
    
    begin {
        $cred = Import-Clixml -Path ".\cred.xml"
        $sendMailMessageSplat = @{
            From = 'automationnttdata@outlook.com'
            To = 'automationnttdata@outlook.com'
            Subject = 'Service Monitoring'
            Body = $Messagetosend
            DeliveryNotificationOption = 'OnSuccess', 'OnFailure'
            SmtpServer = 'smtp-mail.outlook.com'
            Port = 587
            UseSSL = $true
            Credential = New-Object System.Management.Automation.PSCredential($cred)
        }        
    }
    
    process {
      
            Send-MailMessage @sendMailMessageSplat 
       
    }
    
    end {
        
    }
 }




 function sendmail {
    [CmdletBinding()]
    param (
        
        # Parameter help description
        [Parameter(ValueFromPipeline)]
        [switch]
        $message,
        [string]
        $bodmsg = "Test mail"
    )
    
    begin {
        $cred = Import-Clixml -Path ".\cred.xml"
        $sendMailMessageSplat = @{
            From = 'automationnttdata@outlook.com'
            To = 'automationnttdata@outlook.com'
            Subject = 'Service Monitoring'
            Body = $bodmsg
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




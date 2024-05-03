$cred = Import-Clixml -Path ".\cred.xml"

Write-Output($cred);
$sendMailMessageSplat = @{
    From = 'automationnttdata@outlook.com'
    To = 'automationnttdata@outlook.com'
    Subject = 'Sending the Attachment'
    Body = "This is a Test Automation Mail, please ignore"
    DeliveryNotificationOption = 'OnSuccess', 'OnFailure'
    SmtpServer = 'smtp-mail.outlook.com'
    Port = 587
    UseSSL = $true
    
    Credential = New-Object System.Management.Automation.PSCredential($cred)
    
}

Send-MailMessage @sendMailMessageSplat 

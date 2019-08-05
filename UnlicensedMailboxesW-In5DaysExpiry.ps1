#Grab all unlicensed mailboxes
$unlicensedMailboxes = Get-Mailbox -Resultsize Unlimited | where {($_.recipienttypedetails -ne "Discoverymailbox") -and ($_.recipienttypedetails -ne "SharedMailbox") -and ($_.recipienttypedetails -ne "EquipmentMailbox") -and ($_.recipienttypedetails -ne "SchedulingMailbox") -and ($_.recipienttypedetails -ne "RoomMailbox") -and ($_.skuassigned -ne "True")} | Select-Object name,skuassign*

#Create formatting for Message Body in HTML
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

#For each to find the mailboxes that were created within the past 25 days from the list. It then confirms they were created within the last 60 days (this is just in case there are legacy boxes that dont adhere to the 30 days licenses requirement, rare but happens, this helps to avoid a huge list of boxes you don't care about).
foreach ($mailbox in $unlicensedMailboxes){
    $dateTimeNow = Get-Date
    $timeCreated = Get-Mailbox -Identity $mailbox.name | Select -ExpandProperty WhenCreated
    $createdWithinPast25Days = Get-Mailbox -Identity $mailbox.name | where {$dateTimeNow -gt $timeCreated.AddDays(25)} | Select-Object Name,Alias,WhenCreated, recipienttypedetails
    foreach ($box in $createdWithinPast25Days){
        if ($timeCreated.AddDays(60) -lt $dateTimeNow ) {

        } else{
            #builds the message body with each mailbox found that fits the criteria and needs attention
            $message.body += $box | ConvertTo-Html -Head $style
        }
    }
}

#creates SMTP for sending email
$smtpServer = "server.email.com"
$smtpFrom = "alerts@domain.com"
$smtpTo = "user@domain.com"
$messageSubject = "List of Unlicensed Users within 5 days of expiry"

#Builds Message Body/Subject
$message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
$message.Subject = $messageSubject
$message.IsBodyHTML = $true

#Finishes SMTP and Sends email
$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($message)

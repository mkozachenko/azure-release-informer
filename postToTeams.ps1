# & ".\getData.ps1"
$slotName = '$(slotname)'
$branch = '$(branch)'
$jsonget = '$(PrWidTable)'
$prTable = @{}

# Конвертируем полученный JSON в Hashtable
(ConvertFrom-Json $jsonget).psobject.properties | ForEach-Object { $prTable[$_.Name] = $_.Value }

# Определяем, на какую площадку делается релиз. Если на staging - подставляем это значение 
if ($slotName -eq "`$`(slotname)") {
    $slotName = 'staging'
}

$webhookDevelopers = '$(devHook)'
$webhookTeam1 = '$(team1Hook)'
$webhookTeam2 = '$(team2Hook)'
$webhookTeam3 = '$(team3Hook)'
$webhookTeam4 = '$(team4Hook)'
$webhookTeam5 = '$(team5Hook)'

$slotsTeam1 = 'dev1', 'dev2', 'dev3'
$slotsTeam2 = 'dev4', 'dev5', 'dev6'
$slotsTeam3 = 'dev7', 'dev8', 'dev9'
$slotsTeam4 = 'dev10', 'dev11', 'dev12'
$slotsTeam5 = 'qa'

if ($slotName -in $slotsTeam1) {
    Write-Host 'Buyer team'
    $webhook = $webhookTeam1
}
elseif ($slotName -in $slotsTeam2) {
    Write-Host 'Platfrorm team'
    $webhook = $webhookTeam2
}
elseif ($slotName -in $slotsTeam3) {
    Write-Host 'Seller team'
    $webhook = $webhookTeam3
}
elseif ($slotName -in $slotsTeam4) {
    Write-Host 'Service team'
    $webhook = $webhookTeam4
}
elseif ($slotName -in $slotsTeam5) {
    Write-Host 'QA team'
    $webhook = $webhookTeam5
}
else {
    Write-Host 'No team'
    $webhook = $webhookDevelopers
}
# Подготавливаем хедер с авторизацией
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($accessToken))
$Headers = @{
    Authorization = "Basic $encodedCreds"
    Accept        = "application/json"
}

# Заготовка сообщения, которое будет высылаться
$JSONBody = [PSCustomObject][Ordered]@{
    "@type"      = "MessageCard"
    "@context"   = "http://schema.org/extensions"
    "summary"    = "Релиз ветки $branch"
    "themeColor" = '0078D7'
    "title"      = "$(Release.RequestedFor) запускает релиз ветки $branch на $slotName"
    "sections"   = @()
}

# Для каждого найденного ПР создаем section с соответствующим текстом и найденными PBI
if ($prTable.Count -ne 0) {
    $i = 0
    foreach ($tableItem in $prTable.GetEnumerator()) {
        $prLink = $tableItem.Name
        $JSONBody.sections += [Ordered]@{
            "text"     = ""
            "facts"    = @()
            "markdown" = $true
        }
        $JSONBody.sections[$i]["text"] = "PR: ${prLink}"
        foreach ($id in $tableItem.Value) {
            $response = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/wit/workitems/${id}?api-version=5.1" -Headers $Headers
            $contentBody = ConvertFrom-Json -InputObject $response.Content
            $title = $contentBody.fields.'System.Title';
            $JSONBody.sections[$i]["facts"] += @{
                "name"  = $id
                "value" = "[$title](https://{organization}.visualstudio.com/{project}/_workitems/edit/$id)"
            }
        }
        $i++;
    }
} # Если ПР отсутствует, так и пишем
else {
    $JSONBody.sections += @{
        "text" = "Pull Request не найден"
    }
}

# Отправляем сообщение в Teams
$TeamMessageBody = ConvertTo-Json $JSONBody -Depth 100
Invoke-RestMethod -Body $TeamMessageBody -ContentType "application/json; charset=utf-8" -Method Post -Uri "$webhook"

Write-Host "Teams message body: "
Write-Host $TeamMessageBody

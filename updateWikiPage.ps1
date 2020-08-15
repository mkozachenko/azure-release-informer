# & ".\getData.ps1"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($accessToken))
$wikiPagePath = '$(wikiPagePath)'
$jsonget = '$(PrWidTable)'
$prTable = @{}
$currentDate = Get-Date -Format "dd/MM/yyyy HH:mm UTC(K)"
$HeadersGet = @{
    'Authorization' = "Basic $encodedCreds"
    'Accept'        = "application/json"
} 

# Конвертируем полученный JSON в Hashtable
(ConvertFrom-Json $jsonget).psobject.properties | ForEach-Object { $prTable[$_.Name] = $_.Value }

# Получаем версию и содержимое статьи
$wikiPage = Invoke-WebRequest -Method Get -Uri "https://dev.azure.com{organization}/{project}/_apis/wiki/wikis/{wikiName}/pages?path=$wikiPagePath&recursionLevel=full&includeContent=True&api-version=5.1" -Headers $HeadersGet
$wikiVersion = $wikiPage.Headers.ETag
$wikiPageContent = ($wikiPage.Content | ConvertFrom-Json).content
$updatedContent = $wikiPageContent
$HeadersPatch = @{
    'Authorization' = "Basic $encodedCreds"
    'Accept'        = "application/json"
    'If-Match'      = $wikiVersion
}

# Если есть ПР, записываем их и связанные PBI в вики
if ($prTable.Count -ne 0) {
    foreach ($tableItem in $prTable.GetEnumerator()) {
        $prLink = $tableItem.Name
        $pbiID = "- **PBI:**"
        foreach ($id in $tableItem.Value) {
            $pbiID += @"

#$id 
"@
        }
        # Формируем новую запись в статью
        $loopContent = @"

# $prLink

[Release on $currentDate]($(Release.ReleaseWebURL))

$pbiID
        
----

"@
        $newContent = $newContent + $loopContent      
    }
} # Если не нашлось ни одного ПР - так и пишем
else {
    $newContent = @"

# Pull Request отсутствует

[Release on $currentDate]($(Release.ReleaseWebURL)) 
"@
}
$updatedContent = $updatedContent + $newContent

$pagePutUrl = "https://dev.azure.com/{organization}/{project}/_apis/wiki/wikis/{wikiName}/pages?path=$wikiPagePath&api-version=5.1"
$JSONBody = @{
    'Uri'         = $pagePutUrl
    'Headers'     = $HeadersPatch
    'Method'      = 'Put'
    'ContentType' = 'application/json; charset=utf-8'
    'body'        = @{content = $updatedContent } | ConvertTo-Json
}

Invoke-RestMethod @JSONBody
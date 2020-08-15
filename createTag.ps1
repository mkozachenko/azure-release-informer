# & ".\getData.ps1"
$branch = '$(Release.Artifacts.{artifactName}.SourceBranchName)'
$tagList = @()
$currentSprintReleases = @()

# Хэдер для работы с кодом
$encodedCredsCode = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($codeAccessToken))
$HeadersCode = @{
    'Authorization' = "Basic $encodedCredsCode"
    'Accept'        = "application/json"
} 

# Хэдер для работы с беклогом
$encodedCredsWorkItems = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($backlogAccessToken))
$HeadersWorkItems = @{
    'Authorization' = "Basic $encodedCredsWorkItems"
    'Accept'        = "application/json"
} 

# Получаем имя текущего спринта
$sprintCurrent = Invoke-WebRequest -Method Get -Uri "https://dev.azure.com/{organization}/{project}/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=5.1" -Headers $HeadersWorkItems
$currentSprintName = (ConvertFrom-Json -InputObject $sprintCurrent.Content).value.name

if($branch -eq "master"){
    # Собираем все существующие в репозитории теги
    $responseTagList = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/refs?filter=tags/&peelTags=True&api-version=5.1" -Headers $HeadersCode
    $contentTagList = (ConvertFrom-Json -InputObject $responseTagList.Content).value

    # Собираем данные по всем найденным тегам, отсеиваем те, по которым не удалось получить информацию
    foreach ($tagObject in $contentTagList) {
        $tagId = $tagObject.objectId
        try {
            $tagDetail = Invoke-RestMethod -Method Get -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/annotatedtags/${tagId}?api-version=5.1-preview.1" -Headers $HeadersCode
            $tagList += $tagDetail
        }
        catch {
            Write-Host "TagID <"$tagId"> Error: "
            Write-Host $_.ErrorDetails
        }
    }
    
    # Среди тегов ищем те, в имени которых указан релиз в текущем спринте
    foreach($tag in $tagList){
        $tagname = $tag.name
        if($tagname -match "release-$currentSprintName\.\d+"){
            Write-Host "Matched: " $tagname
            $currentSprintReleases += $tagname
        }
    }

    # Если такие теги есть - находим каунт релиза в спринте и увеличиваем на 1
    if($currentSprintReleases.count -ne 0){
        $lastReleaseName = $currentSprintReleases | Sort-Object -Descending | Select-Object -First 1
        $releaseCnt = ($lastReleaseName -replace "\w+-\d+\.","" -as [int]) + 1
        $newTagName = "release-$currentSprintName.$releaseCnt"
    } # Если нет - создаем новый тег с каунтом 1
    else {
        $newTagName = "release-$currentSprintName.1"
    }

    # Получаем верхний коммит в мастере
    $responseGetCommit = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/commits?searchCriteria.itemVersion.version=${branch}&`$top=1&api-version=5.1" -Headers $HeadersCode
    $contentGetCommit = (ConvertFrom-Json -InputObject $responseGetCommit.Content).value

    # Создаем тег, привязываем его к найденному коммиту
    $JSONBody = @{
        "name"      = $newTagName
        "message"    = $contentGetCommit.comment
        "taggedObject"   = @{
            "objectId" = $contentGetCommit.commitId
        }
    }

    $tagCreateBody = ConvertTo-Json $JSONBody -Depth 100
    Invoke-RestMethod -Body $tagCreateBody -ContentType "application/json; charset=utf-8" -Method Post -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/annotatedtags?api-version=5.1-preview.1" -Headers $HeadersCode
} else {
    Write-Output "Release branch should be MASTER"
}
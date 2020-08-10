$branch = '$(Release.Artifacts.ArtifactName.All.SourceBranchName)';
$defaultBranch = "master"
$prIds = @()
$PrWidTable = @{}

# Подготавливаем хедер с авторизацией
$accessToken = "yourToken"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($accessToken))
$Headers = @{
    Authorization = "Basic $encodedCreds"
    Accept        = "application/json"
}

# Ищем пулл-реквест
$responsePrApi = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/pullrequests?api-version=5.1&searchCriteria.status=all&searchCriteria.targetRefName=refs/heads/master&searchCriteria.sourceRefName=refs/heads/$branch" -Headers $Headers
$pullRequest = ConvertFrom-Json -InputObject $responsePrApi.Content

# Если ПР найден - сохраняем айди и идем дальше
if ($pullRequest.count -ne 0) {
    $prIds += $pullRequest.value[0].pullRequestId
} # Если ПР не найден, но ветка master - ищем разницу по тегам
elseif ($branch -eq $defaultBranch) {
    $commitFound = 'False'
    $commitSkip = 0
    $commitTop = 100
    $commitsFromTag = @()
    $commitsGather = @()
    # Собираем все существующие в репозитории теги
    $responseTagList = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/refs?filter=tags/&peelTags=True&api-version=5.1" -Headers $Headers
    $contentTagList = (ConvertFrom-Json -InputObject $responseTagList.Content).value
    # Собираем данные по всем найденным тегам, отсеиваем те, по которым не удалось получить информацию
    foreach ($tag in $contentTagList) {
        $tagId = $tag.objectId
        try {
            $tagObject = Invoke-RestMethod -Method Get -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/annotatedtags/${tagId}?api-version=5.1-preview.1" -Headers $Headers
            $commitsFromTag += $tagObject.taggedObject.objectId
        }
        catch {
            Write-Host "TagID <"$tagId"> Error: "
            Write-Host $_.ErrorDetails
        }
    }

    # Берем по 100 верхних коммитов ветки и ищем в них коммит, к которому привязан найденный тег. Собираем коммиты, находящиеся сверху и до тега
    :rootLoop while ($commitFound -ne 'True') {
        $responseGetCommits = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/commits?searchCriteria.itemVersion.version=${branch}&`$skip=${commitSkip}&`$top=${commitTop}&api-version=5.1" -Headers $Headers
        $contentGetCommits = (ConvertFrom-Json -InputObject $responseGetCommits.Content).value
        foreach ($commit in $contentGetCommits) {
            if ($commitsFromTag -contains $commit.commitId) {
                $commitFound = 'True'
                break rootLoop;
            }
            else {
                $commitsGather += $commit
            }
        }
        $commitSkip += 100
    }

    # В собранных коммитах ищем мердж-коммиты ПР и собираем из них айдишики ПР
    foreach ($commit in $commitsGather) {
        $comment = $commit.comment
        $matchedComment = [regex]::matches($comment, '^Merged PR \d+').value -replace "[A-Za-z\s]", ""
        # Добавляем в массив только найденные пулл-реквесты
        if ($matchedComment -ne "") {
            $prIds += $matchedComment
        }
    }
} 

# Если нашли хотя бы один ПР - достаем данные из него
if ($prIds.count -ne 0) {
    foreach ($prId in $prIds) {
        $uniqIds = @()
        $prCommittedIds = @()
        $prRelatedIds = @()

        $responsePr = Invoke-WebRequest -Method Get -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/pullrequests/${prId}?api-version=5.1" -Headers $Headers
        $contentPr = ConvertFrom-Json -InputObject $responsePr.Content
        $pullRequestName = $contentPr.title

        # Достаем все привязанные таски из пул-реквеста
        $responsePrItems = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/pullRequests/${prId}/workitems?api-version=5.1" -Headers $Headers
        $contentPrItems = ConvertFrom-Json -InputObject $responsePrItems.Content
        $prRelatedIds += ($contentPrItems.value).id
    
        # Достаем все коммиты из пулл-реквеста
        $responsePrCommits = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/pullRequests/${prId}/commits?api-version=5.1" -Headers $Headers
        $contentPrCommits = ConvertFrom-Json -InputObject $responsePrCommits.Content

        # Проходимся по всем коммитам, ищем в комментариях ссылки на ворк-айтемы (вида #123456), найденные складываем в массив
        foreach ($c in $contentPrCommits.value) {
            $commit = $c.commitId
            $responseCommitList = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/commits/${commit}?api-version=5.1" -Headers $Headers
            $contentCommitList = ConvertFrom-Json -InputObject $responseCommitList.Content
            $commitComment = $contentCommitList.comment
            $matchedId = [regex]::matches($commitComment, '#\d+').value -replace "#", ""
            # Добавляем в массив только непустые результаты
            if ($matchedId -ne "") {
                $prCommittedIds += $matchedId
            }
        }
        # Склеиваем массивы ворк-айтемов из пулл-реквеста и из коммитов
        $prSummaryIds = $prRelatedIds + $prCommittedIds

        foreach ($workItemId in $prSummaryIds) {
            # Пытаемся достать ворк-айтем по указанному ID. Если получаем ошибку - переходим к следующему элементу цикла
            try {
                $responseWorkItems = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/wit/workitems/${workItemId}?`$expand=relations&api-version=5.1" -Headers $Headers
            }
            catch [system.Exception] {
                "Cannot find WorkItem with ID: " + $workItemId
                Continue;
            }
            $contentWorkItems = ConvertFrom-Json -InputObject $responseWorkItems.Content
            # Если workItem является таском, то достаем его родителя
            if ($contentWorkItems.fields.'System.WorkItemType' -eq 'Task') {
                $parentId = $contentWorkItems.fields.'System.Parent';
                if(-not [string]::IsNullOrEmpty($parentId)){
                    $responseWorkItemParent = Invoke-WebRequest -Uri "https://dev.azure.com/{organization}/{project}/_apis/wit/workitems/${parentId}?api-version=5.1" -Headers $Headers
                    $contentWorkItemParent = ConvertFrom-Json -InputObject $responseWorkItemParent.Content
                    $workItemId = $contentWorkItemParent.id
                } else {
                    Write-Host "NO PARENT FOR" $workItemId
                }
            }
            # Дубликаты не добавляем
            if ($uniqIds -contains $workItemId) {}
            else {            
                $uniqIds += $workItemId;
            }
        }
        $PrWidTable.Add("[$pullRequestName]({standart link to PR in your project}/pullrequest/${prId})", $uniqIds)
    }   
} 

Write-Output "###### Pull Requests:"
Write-Output $PrWidTable

# Конвертируем в JSON для передачи на следующий таск в пайплайне
$PrWidTableJson = ConvertTo-Json $PrWidTable -Compress

Write-Host ('##vso[task.setvariable variable=branch]'+$branch)
Write-Host ('##vso[task.setvariable variable=PrWidTable]'+$PrWidTableJson)

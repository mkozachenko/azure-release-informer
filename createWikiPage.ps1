$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":xajv7oeegbpycfvijhbrqs4cx7auyvuagrg5pzewpho32ptoirma"))
$wikiPagePath = '/Release Notes'
$pageExist = 'False'
$Headers = @{
    'Authorization' = "Basic $encodedCreds"
    'Accept'        = "application/json"
} 

# Определяем имя текущего спринта
$sprintCurrent = Invoke-WebRequest -Method Get -Uri "https://dev.azure.com/{organization}/{project}/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=5.1" -Headers $Headers
$currentSprintName = (ConvertFrom-Json -InputObject $sprintCurrent.Content).value.name

# Собираем список названий статей внутри Release Notes
$wikiPage = Invoke-WebRequest -Method Get -Uri "https://dev.azure.com/{organization}/{project}/_apis/wiki/wikis/{wikiName}/pages?path=$wikiPagePath&recursionLevel=full&includeContent=True&api-version=5.1" -Headers $Headers
$pages = (ConvertFrom-Json -InputObject $wikiPage.Content).subPages.path

$pagePath = $wikiPagePath+"/"+$currentSprintName+" sprint"

# Проверяем список статей на наличие статьи для текущего спринта. Если статьи для спринта нет, создаем её
foreach ($pageURL in $pages){
    if ($pageURL -eq $pagePath){
        $pageExist = 'True'
        break
    }
}
if ($pageExist -ne 'True'){
    $JSONBody = @{
        'Uri'         = "https://dev.azure.com/{organization}/{project}/_apis/wiki/wikis/{wikiName}/pages?path=$pagePath&api-version=5.1"
        'Headers'     = $Headers
        'Method'      = 'Put'
        'ContentType' = 'application/json; charset=utf-8'
        'body'        = @{content = "[[_TOC_]]"} | ConvertTo-Json
    }
    Invoke-RestMethod @JSONBody
}

Write-Host ('##vso[task.setvariable variable=wikiPagePath]'+$pagePath)

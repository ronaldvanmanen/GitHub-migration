param (
    [Parameter(Mandatory=$true)][string] $githubUsername,
    [Parameter(Mandatory=$true)][securestring] $githubToken,
    [Parameter(Mandatory=$true)][string] $forgejoUsername,
    [Parameter(Mandatory=$true)][securestring] $forgejoToken
)

$packages = Invoke-RestMethod `
    -Uri "https://api.github.com/users/${githubUsername}/packages?package_type=nuget" `
    -Method Get `
    -Headers @{
        'Accept'='application/vnd.github+json'
        'X-GitHub-Api-Version'='2026-03-10'
        'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)"
    } `
    -FollowRelLink

$packages | ForEach-Object { $_} | ForEach-Object {
    $packageName = $_.name

    $packageMetadata = Invoke-RestMethod `
        -Uri "https://api.github.com/users/${githubUsername}/packages/nuget/${packageName}" `
        -Method Get `
        -Headers @{
            'Accept'='application/vnd.github+json'
            'X-GitHub-Api-Version'='2026-03-10'
            'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)"
        }

    $packageRepository = $packageMetadata.repository.name

    Write-Output "Link package ${packageName} to repository ${packageRepository}"

    Invoke-RestMethod `
        -Uri "https://forgejo.int.ragnvaldr.com/api/v1/packages/${forgejoUsername}/nuget/${packageName}/-/link/${packageRepository}" `
        -Method Post `
        -Headers @{
            'Accept'='application/json'
            'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $forgejoToken -AsPlainText)"
        }
}

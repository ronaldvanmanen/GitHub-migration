param (
    [Parameter(Mandatory=$true)][string] $githubUsername,
    [Parameter(Mandatory=$true)][securestring] $githubToken
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

    Write-Output "Get all versions of ${packageName}..."

    $packageVersions = Invoke-RestMethod `
        -Uri "https://api.github.com/users/${githubUsername}/packages/nuget/${packageName}/versions" `
        -Method Get `
        -Headers @{
            'Accept'='application/vnd.github+json'
            'X-GitHub-Api-Version'='2026-03-10'
            'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)"
        }

    $packageVersions | ForEach-Object {
        $packageVersion = $_.name
        Write-Output "Download package ${packageName}.${packageVersion}.nupkg..."
        Invoke-WebRequest `
            -Uri "https://nuget.pkg.github.com/${githubUsername}/download/${packageName}/${packageVersion}/${packageName}.${packageVersion}.nupkg" `
            -Headers @{ 'Authorization'="token $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)" } `
            -OutFile ".\packages\${packageName}.${packageVersion}.nupkg"
    }
}

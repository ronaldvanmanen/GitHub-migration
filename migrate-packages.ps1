param (
    [Parameter(Mandatory=$true)][string] $githubUsername,
    [Parameter(Mandatory=$true)][string] $githubToken,
    [Parameter(Mandatory=$true)][string] $forgejoUsername,
    [Parameter(Mandatory=$true)][string] $forgejoToken
)

Write-Output "Generate nuget.config ..."
$forgejoPackageSource = "Forgejo"
dotnet new nugetconfig --force
dotnet nuget remove source "nuget" --configfile nuget.config
dotnet nuget add source "https://forgejo.int.ragnvaldr.com/api/packages/${forgejoUsername}/nuget/index.json" `
    --name $forgejoPackageSource `
    --username $forgejoUsername `
    --password "$(ConvertFrom-SecureString -SecureString $forgejoToken -AsPlainText)" `
    --configfile nuget.config

Write-Output "Get list of all NuGet packages on GitHub..."
$packages = Invoke-RestMethod `
    -Uri "https://api.github.com/users/${githubUsername}/packages?package_type=nuget" `
    -Method Get `
    -Headers @{
        'Accept'='application/vnd.github+json'
        'X-GitHub-Api-Version'='2026-03-10'
        'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)"
    } `
    -FollowRelLink

Write-Output "Process all NuGet packages from GitHub..."
$packages | ForEach-Object { $_} | ForEach-Object {
    $packageName = $_.name

    Write-Output "Get all versions of NuGet package ${packageName} on GitHub..."
    $packageVersions = Invoke-RestMethod `
        -Uri "https://api.github.com/users/${githubUsername}/packages/nuget/${packageName}/versions" `
        -Method Get `
        -Headers @{
            'Accept'='application/vnd.github+json'
            'X-GitHub-Api-Version'='2026-03-10'
            'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)"
        }

    Write-Output "Process all versions of NuGet package ${packageName}..."
    $packageVersions | ForEach-Object {
        $packageVersion = $_.name
        Write-Output "Download package ${packageName}.${packageVersion}.nupkg from GitHub..."
        $packagePath = ".\packages\${packageName}.${packageVersion}.nupkg"
        Invoke-WebRequest `
            -Uri "https://nuget.pkg.github.com/${githubUsername}/download/${packageName}/${packageVersion}/${packageName}.${packageVersion}.nupkg" `
            -Headers @{ 'Authorization'="token $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)" } `
            -OutFile $packagePath
        
        Write-Output "Upload package ${packageName}.${packageVersion}.nupkg to Forgejo..."
        dotnet nuget push `
            --source $forgejoPackageSource `
            --api-key "$(ConvertFrom-SecureString -SecureString $forgejoToken -AsPlainText)" `
            --skip-duplicate `
            $packagePath
    }

    Write-Output "Get metadata of package ${packageName} on GitHub..."
    $packageMetadata = Invoke-RestMethod `
        -Uri "https://api.github.com/users/${githubUsername}/packages/nuget/${packageName}" `
        -Method Get `
        -Headers @{
            'Accept'='application/vnd.github+json'
            'X-GitHub-Api-Version'='2026-03-10'
            'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $githubToken -AsPlainText)"
        }

    $packageRepository = $packageMetadata.repository.name
    Write-Output "Link package ${packageName} to repository ${packageRepository}..."
    Invoke-RestMethod `
        -Uri "https://forgejo.int.ragnvaldr.com/api/v1/packages/${forgejoUsername}/nuget/${packageName}/-/link/${packageRepository}" `
        -Method Post `
        -Headers @{
            'Accept'='application/json'
            'Authorization'="Bearer $(ConvertFrom-SecureString -SecureString $forgejoToken -AsPlainText)"
        }
}

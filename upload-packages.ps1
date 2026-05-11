param (
    [Parameter(Mandatory=$true)][string] $forgejoUsername,
    [Parameter(Mandatory=$true)][securestring] $forgejoToken
)

$forgejoPackageSource = "forgejo"
dotnet new nugetconfig --force
dotnet nuget remove source "nuget" --configfile nuget.config
dotnet nuget add source "https://forgejo.int.ragnvaldr.com/api/packages/${forgejoUsername}/nuget/index.json" `
    --name $forgejoPackageSource `
    --username $forgejoUsername `
    --password "$(ConvertFrom-SecureString -SecureString $forgejoToken -AsPlainText)" `
    --configfile nuget.config

$packages = Get-ChildItem .\packages\*.nupkg

$packages | ForEach-Object {
    dotnet nuget push `
        --source $forgejoPackageSource `
        --api-key "$(ConvertFrom-SecureString -SecureString $forgejoToken -AsPlainText)" `
        --skip-duplicate `
        $_.FullName
}

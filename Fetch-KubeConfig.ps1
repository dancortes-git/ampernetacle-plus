param(
    [Parameter(Mandatory=$true)]
    [string]$KubeHost,
    [Parameter(Mandatory=$true)]
    [string]$KubeUser,
    [Parameter(Mandatory=$true)]
    [string]$SshPrivateKeyFileName
)

Write-Host "Retrieving kubeconfig from ${KubeUser}@${KubeHost}"

$kubeconfig = ".\kubeconfig"

scp -o StrictHostKeyChecking=no -i ${SshPrivateKeyFileName} `
    "${KubeUser}@${KubeHost}:~/.kube/config" `
    $kubeconfig

$content = Get-Content $kubeconfig -Raw
$content = $content -replace "10\.0\.0\.11", $KubeHost
Set-Content $kubeconfig $content

icacls $kubeconfig /inheritance:r
icacls $kubeconfig /grant:r "$($env:USERNAME):(F)"

Write-Host "Kubeconfig successfully retrieved"
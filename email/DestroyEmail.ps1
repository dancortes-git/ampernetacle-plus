Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$env:TF_IN_AUTOMATION = "1"

[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Invoke-OciSessionAuthenticate {
    Write-Host "Executing: oci session authenticate"
    Write-Host "Choose the region and complete the browser authentication flow."
    Write-Host "When the OCI CLI prompts for the profile name, type 'DEFAULT' and press Enter."

    & oci session authenticate

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: oci session authenticate"
    }
}

function Invoke-TerraformCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $commandText = "terraform $($Arguments -join ' ')"

    Write-Host "Executing: $commandText"

    & terraform @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $commandText"
    }
}

function Get-HclStringValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $content = Get-Content -LiteralPath $Path -Raw
    $pattern = "(?m)^\s*$([regex]::Escape($Name))\s*=\s*`"([^`"]+)`""
    $match = [regex]::Match($content, $pattern)

    if (-not $match.Success) {
        throw "Could not find HCL string value '${Name}' in ${Path}"
    }

    return $match.Groups[1].Value
}

function Get-CurrentUserId {
    Write-Host "Retrieving current OCI user OCID..."

    try {
        $output = & oci iam user get-current-user --query "data.id" --raw-output 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Could not retrieve current user OCID. Exit code: ${LASTEXITCODE}. Ensure OCI CLI is installed and authenticated."
        }

        if ([string]::IsNullOrWhiteSpace($output)) {
            throw "Current user OCID is empty. Ensure OCI CLI session is valid."
        }

        return $output.Trim()
    }
    catch {
        Write-Error "Error retrieving current user: $_"
        throw
    }
}

function Invoke-EmailTerraformDestroy {
    $rootPath = Split-Path -Parent $PSScriptRoot
    $backendPath = Join-Path $rootPath "backend.hcl"
    $rootStatePath = Join-Path $rootPath "state.tf"

    $bucketName = Get-HclStringValue -Path $backendPath -Name "bucket"
    $ociNamespace = Get-HclStringValue -Path $backendPath -Name "namespace"
    $rootKey = Get-HclStringValue -Path $rootStatePath -Name "key"

    $env:TF_VAR_bucket = $bucketName
    $env:TF_VAR_oci_namespace = $ociNamespace
    $env:TF_VAR_root_key = $rootKey

    Push-Location -LiteralPath $PSScriptRoot

    try {
        Invoke-OciSessionAuthenticate

        $smtpUserId = Get-CurrentUserId
        $env:TF_VAR_smtp_user_id = $smtpUserId

        Invoke-TerraformCommand @(
            "init",
            "-backend-config=bucket=$bucketName",
            "-backend-config=namespace=$ociNamespace"
        )

        Invoke-TerraformCommand @(
            "destroy"
        )
    }
    finally {
        Pop-Location
    }
}

Invoke-EmailTerraformDestroy

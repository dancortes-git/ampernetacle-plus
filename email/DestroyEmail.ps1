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

function Get-OciProfileValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $configPath = $env:OCI_CLI_CONFIG_FILE

    if ([string]::IsNullOrWhiteSpace($configPath)) {
        $configPath = Join-Path $env:USERPROFILE ".oci\config"
    }

    return Get-OciProfileValueFromPath -Path $configPath -Name $Name -Required
}

function Get-OciProfileValueFromPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [switch]$Required
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "OCI CLI config file not found at ${Path}. Ensure OCI CLI session is authenticated."
    }

    $inDefaultProfile = $false
    $pattern = "^\s*$([regex]::Escape($Name))\s*=\s*([^#;\s]+)"

    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*\[(.+)\]\s*$') {
            $inDefaultProfile = $matches[1] -eq "DEFAULT"
            continue
        }

        if ($inDefaultProfile -and $line -match $pattern) {
            return $matches[1].Trim('"').Trim("'")
        }
    }

    if ($Required) {
        throw "Could not find '${Name}' in OCI CLI DEFAULT profile. Run oci session authenticate and choose the DEFAULT profile."
    }

    return $null
}

function Get-OciConfigPath {
    $configPath = $env:OCI_CLI_CONFIG_FILE

    if ([string]::IsNullOrWhiteSpace($configPath)) {
        $configPath = Join-Path $env:USERPROFILE ".oci\config"
    }

    return $configPath
}

function Resolve-OciPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if ($Path.StartsWith("~")) {
        return Join-Path $env:USERPROFILE $Path.Substring(1).TrimStart("\", "/")
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path (Split-Path -Parent $ConfigPath) $Path
}

function ConvertFrom-Base64Url {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $base64 = $Value.Replace("-", "+").Replace("_", "/")

    switch ($base64.Length % 4) {
        2 { $base64 += "==" }
        3 { $base64 += "=" }
        1 { throw "Invalid base64url value in OCI security token." }
    }

    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64))
}

function Find-UserOcidInJson {
    param(
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string]) {
        if ($Value -match '^ocid1\.user\.') {
            return $Value
        }

        return $null
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($item in $Value.Values) {
            $result = Find-UserOcidInJson -Value $item
            if ($result) {
                return $result
            }
        }
    }

    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            $result = Find-UserOcidInJson -Value $property.Value
            if ($result) {
                return $result
            }
        }
    }

    return $null
}

function Get-CurrentUserIdFromSecurityToken {
    $configPath = Get-OciConfigPath
    $tokenPath = Get-OciProfileValueFromPath -Path $configPath -Name "security_token_file"

    if ([string]::IsNullOrWhiteSpace($tokenPath)) {
        throw "Could not find 'user' or 'security_token_file' in OCI CLI DEFAULT profile. Run oci session authenticate and choose the DEFAULT profile."
    }

    $resolvedTokenPath = Resolve-OciPath -Path $tokenPath -ConfigPath $configPath

    if (-not (Test-Path -LiteralPath $resolvedTokenPath)) {
        throw "OCI security token file not found at ${resolvedTokenPath}. Run oci session authenticate again."
    }

    $token = (Get-Content -LiteralPath $resolvedTokenPath -Raw).Trim()
    $parts = $token -split "\."

    if ($parts.Count -lt 2) {
        throw "OCI security token does not look like a JWT. Run oci session authenticate again."
    }

    $payloadJson = ConvertFrom-Base64Url -Value $parts[1]
    $payload = $payloadJson | ConvertFrom-Json
    $userId = Find-UserOcidInJson -Value $payload

    if ([string]::IsNullOrWhiteSpace($userId)) {
        throw "Could not find a user OCID inside the OCI security token. Run oci session authenticate again."
    }

    return $userId
}

function Get-CurrentUserId {
    Write-Host "Retrieving current OCI user OCID from DEFAULT profile..."

    $configPath = Get-OciConfigPath
    $userId = Get-OciProfileValueFromPath -Path $configPath -Name "user"

    if ([string]::IsNullOrWhiteSpace($userId)) {
        $userId = Get-CurrentUserIdFromSecurityToken
    }

    if ([string]::IsNullOrWhiteSpace($userId)) {
        throw "Current user OCID is empty. Ensure OCI CLI session is valid."
    }

    return $userId
}

function Get-OciProfileRegion {
    Write-Host "Retrieving OCI region from DEFAULT profile..."

    $region = Get-OciProfileValue -Name "region"

    if ([string]::IsNullOrWhiteSpace($region)) {
        throw "OCI region is empty. Ensure OCI CLI session is valid."
    }

    return $region
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

        $region = Get-OciProfileRegion
        $env:TF_VAR_region = $region

        Invoke-TerraformCommand @(
            "init",
            "-backend-config=bucket=$bucketName",
            "-backend-config=namespace=$ociNamespace",
            "-backend-config=auth=SecurityToken",
            "-backend-config=config_file_profile=DEFAULT",
            "-backend-config=region=$region"
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

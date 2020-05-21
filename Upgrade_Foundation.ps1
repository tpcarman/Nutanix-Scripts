<#
.SYNOPSIS  
    Upgrades CVM Foundation to a specified version
.DESCRIPTION
    Upgrades CVM Foundation to a specified version
.NOTES
    Version:        1.0.0
    Author:         Tim Carman
    Twitter:        @tpcarman
    Github:         tpcarman
.PARAMETER Version
    Specifies the desired Foundation version
.PARAMETER CVMs
    Specifies the CVM IPs to upgrade Foundation
.PARAMETER ShowLogs
    Shows the Foundation logs
.EXAMPLE
    PS C:\> .\Upgrade_Foundation -Version '4.5.3' -CVMs 10.199.119.125,10.199.119.130 -ShowLogs
#>
#region Script Parameters
[CmdletBinding(
    PositionalBinding = $false
)]
param (
    [Parameter(
        Position = 0,
        Mandatory = $true,
        HelpMessage = 'Please provide the desired foundation version'
    )]
    [ValidateNotNullOrEmpty()]
    [String] $Version,

    [Parameter(
        Position = 1,
        Mandatory = $true,
        HelpMessage = 'Please provide the CVM IP addresses'
    )]
    [ValidateNotNullOrEmpty()]
    [Array] $CVMs,

    [Parameter(
        Position = 2,
        Mandatory = $false,
        HelpMessage = 'Shows the foundation logs'
    )]
    [ValidateNotNullOrEmpty()]
    [Switch] $ShowLogs = $false
)
#endregion Script Parameters

#region Script Body
foreach ($CVM in $CVMs) {
    $api = "http://" + $CVM + ":8000/foundation"
    # Collect Foundation Information
    $Inventory = Invoke-RestMethod -Uri ($api + '/components/inventory') -Method GET
    $FoundationVersion = Invoke-RestMethod -Uri ($api + '/version') -Method GET
    # If Foundation version less than desired version, perform update
    if ($FoundationVersion -lt $Version) {
        $Update = Invoke-RestMethod -Uri ($api + '/is_update_available') -Method POST
        if ($Update.update_available) {
            $UpdateVersion = $Update.update.version_id
            Write-Host "Upgrading to Foundation $UpdateVersion on CVM $CVM" -ForegroundColor Green
            try {
                Invoke-RestMethod -Uri ($api + '/auto_update_foundation') -Method GET
            }
            catch {
                Write-Error $_
            }
        }
        else {
            Write-Host "Foundation upgrade not available for CVM $CVM" -ForegroundColor Green
        }
    }
    else {
        Write-Host "Foundation $FoundationVersion is already installed on CVM $CVM" -ForegroundColor Green
    }
    # Show Foundation Logs
    if ($ShowLogs) {
        Write-Host 'Foundation Log' -ForegroundColor Cyan
        Invoke-RestMethod -Uri ($api + '/service_log') -Method GET

        Write-Host 'Foundation Update Log' -ForegroundColor Cyan
        Invoke-RestMethod -Uri ($api + '/get_update_log') -Method GET
    }
}
#endregion Script Body
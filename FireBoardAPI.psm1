function convert-DataSetToHashTable {
    <#
    .SYNOPSIS
       Returns a hash table for data set passed in.  This is used to pivot a data set.
    #>
    param(
        [Parameter(ValueFromPipeline)]$DataRow
    )

    process {
        $Columns = $DataRow | Get-Member | Where-Object { $_.MemberType -in ('Property', 'NoteProperty') } | Select-Object Name | Sort-Object Name
        $HashTable = [ordered]@{}
        foreach ($Column in $Columns) {
            $HashTable.Add($Column.Name, $($DataRow.$($Column.Name)) )
        }
        $HashTable
    }
}
function Get-FireboardAPIKey {
    <#
    .SYNOPSIS
       Gets the api key for your fireboard.io account
    #>
    $Cred = Get-Credential -Message 'Enter your fireboard.io credentials'

    # Convert the SecureString to plain text for use with the JSON payload.
    $CredPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Cred.Password))

    $response = Invoke-RestMethod -Method POST -Uri 'https://fireboard.io/api/rest-auth/login/' -Verbose:$false -Headers @{
        'Content-Type' = 'application/json'
    } -Body "{`"username`":`"$($Cred.UserName)`",`"password`":`"$($CredPassword)`"}"
    $response.key
}
function get-FireboardSession {
    param(
        [Parameter(Mandatory)]
        [string]$APIKey
        ,
        [Parameter(Mandatory)]
        [string]$SessionID
    )

    $response = Invoke-RestMethod -Method Get -Uri "https://fireboard.io/api/v1/sessions/$($SessionID).json" -Verbose:$false -Headers @{
        'Authorization' = "Token $($APIKey)"
    }

    $response
}
function get-FireboardSessionTimeSeries {
    <#
    .SYNOPSIS
       Returns a time series data set for a given session
    #>
    param(

        [Parameter(Mandatory)]
        [string]$APIKey
        , [Parameter(Mandatory)]
        [string]$SessionID
    )

    $response = Invoke-RestMethod -Method Get -Uri "https://fireboard.io/api/v1/sessions/$($SessionID)/chart.json" -Verbose:$false -Headers @{
        'Authorization' = "Token $($APIKey)"
    }

    $response
}
function get-FireboardList {
    <#
    .SYNOPSIS
       Base function to return sets of records from fireboard.io
    #>
    param(

        [Parameter(Mandatory)]
        [string]$APIKey
        , [Parameter(Mandatory)]
        [string]$ListType
    )

    $response = Invoke-RestMethod -Method Get -Uri "https://fireboard.io/api/v1/$($ListType).json" -Verbose:$false -Headers @{
        'Authorization' = "Token $($APIKey)"
    }

    $response
}
function Get-FireboardDevice {
    <#
    .SYNOPSIS
       Returns details for a given device associated with your fireboard.io account
    #>
    param(

        [Parameter(Mandatory)]
        [string]$APIKey
    )
    get-FireboardList -APIKey $APIKey -ListType 'devices'
}
function get-FireboardSessionList {
    <#
    .SYNOPSIS
       Returns a list of all sessions associated with your fireboard.io account
    #>
    param(

        [Parameter(Mandatory)]
        [string]$APIKey
    )
    get-FireboardList -APIKey $APIKey -ListType 'sessions'
}
function get-FireboardRequest {
    <#
    .SYNOPSIS
       Base function to query fireboard.io for a given device and request type
    #>
    param(

        [Parameter(Mandatory)]
        [string]$APIKey,
        [Parameter(Mandatory)]
        [string]$DeviceId,
        [Parameter(Mandatory)]
        [string]$RequestType
    )

    $response = Invoke-RestMethod -Method Get -Uri "https://fireboard.io/api/v1/devices/$($DeviceId)/$($RequestType)" -Verbose:$false -Headers @{
        'Authorization' = "Token $($APIKey)"
    }

    $response
}
function get-FireboardTemp {
    <#
    .SYNOPSIS
       Gets current temperature for a given device.  Device must be turned on and connected to the internet.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$APIKey,
        [Parameter(Mandatory)]
        [string]$DeviceId
    )
    get-fireboardrequest -APIKey $APIKey -DeviceId $DeviceId -RequestType 'temps'
}
function get-FireboardDeviceInfo {
    <#
    .SYNOPSIS
       Returns device information for a given deviceid
    #>
    param(

        [Parameter(Mandatory)]
        [string]$APIKey,
        [Parameter(Mandatory)]
        [string]$DeviceId
    )

    $response = Invoke-RestMethod -Method Get -Uri "https://fireboard.io/api/v1/devices/temps/$($DeviceId)" -Verbose:$false -Headers @{
        'Authorization' = "Token $($APIKey)"
    }

    $response
}
function ConvertFrom-UnixTime {
    <#
    .SYNOPSIS
       inline function to convert unix time to datetime
    #>
    param(

        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [int]$UnixTime
    )
    process {
    $epoch = New-Object System.DateTime 1970, 1, 1, 0, 0, 0, 0
    [datetime] $epoch.AddSeconds($UnixTime)
    }
}
function ConvertTo-LocalTime {
    <#
    .SYNOPSIS
    inline function to convert utc datetime to local datetime
    #>
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [datetime]$DateTime
    )
    process{
    $DateTime.ToLocalTime()
    }
}
function join-HashTable {
    <#
    .SYNOPSIS
       Combines 2 hash tables into a single hash table
    #>
    param(

        [Parameter(Mandatory)]
        [hashtable]$Hash1,
        [Parameter(Mandatory)]
        [hashtable]$Hash2
    )
    $Hash1.GetEnumerator() | ForEach-Object {
        $Hash2.Add($_.Key, $_.Value)
    }
    $Hash2
}
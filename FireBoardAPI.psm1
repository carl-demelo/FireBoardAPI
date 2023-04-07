function Convert-FromCurl {
    <#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    $CurlString =@"
curl "https://fireboard.io/api/v1/sessions.json" -H "Authorization: Token 9944bb9966cc22cc9418ad846dd0e4bbdfc6ee4b"
"@

Convert-FromCurl -CurlString $CurlString

Output:
Invoke-RestMethod -Method POST -Uri 'https://localhost:8080/confluence/rest/api/content' -Verbose:$false -Headers @{
    'Content-Type' = 'application/json'
} -Body '{ "type":"page" ,"title":"A Test Page" , "space":{ "key":"SPACE" } , "ancestors" : [ { "id": "115328548" } ] ,"body":{ "storage":{ "value":"<h1>Child Macro Test</h1><p>Foo Bar Blah</p><p> <ac:structured-macro ac:name="children"> <ac:parameter ac:name="reverse">true</ac:parameter> <ac:parameter ac:name="sort">creation</ac:parameter> <ac:parameter ac:name="style">h4</ac:parameter> <ac:parameter ac:name="page"> <ac:link> <ri:page ri:content-title="Home"/> </ac:link> </ac:parameter> <ac:parameter ac:name="excerpt">none</ac:parameter> <ac:parameter ac:name="first">99</ac:parameter> <ac:parameter ac:name="depth">2</ac:parameter> <ac:parameter ac:name="all">true</ac:parameter> </ac:structured-macro> </p>","representation":"storage"}}}'

#>

    param(
        [string]$CurlString
    )
    if (-not $(Get-Module Curl2PS)) {
        Import-Module Curl2PS
    }

    <#  #>
    ConvertTo-IRM $CurlString -CommandAsString
}
function convert-DataRowToHashTable {
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
    }
end {
    $HashTable
}
}
function Convert-HashTableToDataTable {
    <#
    .SYNOPSIS
       Returns a data set for a hash table passed in.  This is used to unpivot a data set.
    #>
    param(
        $Hashtable
    )
    $DataTable = New-Object System.Data.DataTable

    for ($Col = 0; $Col -lt $Hashtable[0].Keys.count; $Col++) {
        $DataTable.Columns.Add($($Hashtable[0].Keys)[$Col]) | Out-Null
    }

    for ($row = 1; $row -lt $Hashtable.name.count; $row++) {
        $dr = $DataTable.NewRow()
        for ($RowCol = 0; $RowCol -lt $Hashtable[0].Keys.count; $RowCol++) {
            if (-not [string]::isnullorempty($($($Hashtable[$row].Keys)[$RowCol]))) {
                $dr.$($($Hashtable[$row].Keys)[$RowCol]) = $($($Hashtable[$row].Values)[$RowCol])
            }
        }
        $DataTable.Rows.Add($dr)
    }
    return $DataTable
}
function Get-FireboardAPIKey {
    <#
    .SYNOPSIS
       Gets the api key for your fireboard.io account
    #>
    $Cred = Get-Credential -Message 'Enter your fireboard.io credentials' -Title 'Fireboard.io Credentials'

    $response = Invoke-RestMethod -Method POST -Uri 'https://fireboard.io/api/rest-auth/login/' -Verbose:$false -Headers @{
        'Content-Type' = 'application/json'
    } -Body "{`"username`":`"$($Cred.UserName)`",`"password`":`"$($Cred.Password)`"}"
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
    }
    end{
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
function add-HashTable {
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
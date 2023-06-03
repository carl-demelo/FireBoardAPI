function convert-DataRowToHashTable {
    <#
    .SYNOPSIS
       Returns a hash table for data set passed in.  This is used to pivot a data set.
    #>
    param(
        
        [Parameter(ValueFromPipeline)]$DataRow
    )
  
    $Columns = $DataRow | Get-Member | Where-Object { $_.MemberType -in ('Property', 'NoteProperty') } | Select-Object Name | Sort-Object Name
    $HashTable = [ordered]@{}
    foreach ($Column in $Columns) {
        $HashTable.Add($Column.Name, $($DataRow.$($Column.Name)) ) 
    }
  
    return $HashTable
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
# function to insert an image into a excel worksheet.  Use the ImportExcel module to create the worksheet
function Import-ImageToExcelWorksheet {
    <#
    .SYNOPSIS
       Inserts an image into an excel worksheet
    #>
    param(
        
        [Parameter(Mandatory)]
        [string]$ImageFile
        ,
        [Parameter(Mandatory)]
        [string]$WorksheetName
        ,
        [Parameter(Mandatory)]
        [string]$ExcelFile
        ,
        [Parameter(Mandatory)]
        [int]$Row
        ,
        [Parameter(Mandatory)]
        [int]$Column
        ,
        [Parameter(Mandatory)]
        [int]$Width
        ,
        [Parameter(Mandatory)]
        [int]$Height
    )
    $Excel = Import-Excel -Path $ExcelFile
    $Excel | Add-Image -ImageFile $ImageFile -WorksheetName $WorksheetName -Row $Row -Column $Column -Width $Width -Height $Height
    $Excel | Export-Excel -Path $ExcelFile -Show
}
function Get-FireboardAPIKey {
    <#
    .SYNOPSIS
       Gets the api key for your fireboard.io account
    #>
    <#     param(
        
        [Parameter(Mandatory)]
        [string]$Username,
        [Parameter(Mandatory)]
        [string]$Password
    ) #>
    $Cred = Get-Credential -Message 'Enter your https://fireboard.io/ account credentials'
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
function get-FireboardSessions {
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
    $epoch = New-Object System.DateTime 1970, 1, 1, 0, 0, 0, 0
    [datetime] $epoch.AddSeconds($UnixTime)
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
    $DateTime.ToLocalTime()
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

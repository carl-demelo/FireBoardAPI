<#
.SYNOPSIS
    Module to wrap the REST API interface for FireBoard products https://docs.fireboard.io/app/api.html
.DESCRIPTION
Use PowerShell for your next BBQ!!!!

Well maybe not exactly, but you can use my new PowerShell module that I started which wraps the FireBoard rest API interface.  With FireBoardAPI you can monitor live values for temperature setpoints, temperature valuesfor all attached sensors and monitor the usage of servo (Auger Drive) motors, retrieve and plot historic sessions and gather meta data about your hardware.

FireBoard makes products to track temperatures and drive smart enabled grill products, the Yoder YS-640S pictured is the one that I use. 

The module is compatible with FireBoard products that are cloud enabled, an account at https://fireboard.io/ is required for usage.

Author: Carl Demelo 2023
Follow me on linkedin: https://www.linkedin.com/in/carl-demelo/

.NOTES
    File Name: get-FireBoardExample.ps1
.LINK
Get the example script from GitHub:
    https://github.com/carl-demelo/FireBoardAPI
    
Get the module from the PowerShell Gallery:
    https://www.powershellgallery.com/packages/FireBoardAPI/
.EXAMPLE
    .\get-FireBoardExample.ps1 -FilePath "C:\Temp\" -TableStyle 'Medium3'
#>

param (
    [Parameter()]
    [string]$FilePath =".\"
    , [string]$TableStyle = 'Medium3'
)

if (-not (Get-Module -Name FireBoardAPI -ListAvailable)) {
   throw "You must install the FireBoardAPI module before using this script. Use: Install-Module -Name FireBoardAPI"
   return
}else{
    Import-Module FireBoardAPI
}

# This function uses get-credential to prompt for a username and password and retireves an API key for the account.  Please note that the the credentials are passed to the FireBoard API in plain text and are not encrypted.  The API key is returned and can be used for subsequent calls to the API.
# We pass the API key to the other functions to authenticate the calls.
try {
$APIKey = Get-FireboardAPIKey

#Retrieve a list of all sessions for the account, we should restrict this to a specific date range, but for now we will just get all sessions.  I use Out-GridView to display the list of sessions and allow the user to select the session that they want to view.  The selected session is passed to the next function.
$Session = get-FireboardSessionList -APIKey $APIKey | Select-Object Created, title, Description , Start_Time, End_Time, Duration, id | Out-GridView -Title 'Fireboard Sessions' -PassThru

#Retrieve the session summary for the selected session.  The session summary contains the session meta data and the owner meta data.  The session meta data contains the session title, description, start time, end time, duration and active flag.  The owner meta data contains the username and email address of the owner of the session.  The session summary is converted to a hash table and the session meta data and owner meta data is added to the hash table.  The hash table is then passed to the Export-Excel module to create an Excel workbook with a single worksheet.  The worksheet is named 'Summary' and the table name is also 'Summary'.  The table is then exported to the Excel workbook.  The workbook is then saved and closed.
$SessionSumary = get-FireboardSession -APIKey $APIKey -SessionID $($Session.id)

# Combine the session meta data and owner meta data into a single hash table
$SessionSummaryHash = @{}
$SessionSummaryHash = join-HashTable -Hash1 $SessionSummaryHash -Hash2 $(convert-DataSetToHashTable -DataRow $($SessionSumary | Select-Object Title, Description, Start_Time, End_Time, Duration, Active))
$SessionSummaryHash = join-HashTable -Hash1 $SessionSummaryHash -Hash2 $(convert-DataSetToHashTable -DataRow $($SessionSumary.owner | Select-Object Username, Email))
$SessionSummaryHash = join-HashTable -Hash1 $SessionSummaryHash -Hash2 $(convert-DataSetToHashTable -DataRow $($SessionSumary.devices | Select-Object Hardware_ID, Model, @{Name = 'GrillModelNumber'; Expression = { $_.title } }, Channel_Count))
$sessionts = get-FireboardSessionTimeSeries -APIKey $APIKey -SessionID $($Session.id) 

# The session time series data is returned as an array of objects.  Each object contains the channel id, channel label, the x and y values.  The x values are the time stamps and the y values are the temperature values.  The x and y values are arrays of values.  The x and y values are combined into a single array of objects.  The array of objects is then passed to the Export-Excel module to create an Excel workbook with a single worksheet.  The worksheet is named 'TimeSeriesData' and the table name is also 'TimeSeriesData'.  The table is then exported to the Excel workbook.  The workbook is then saved and closed.
$SessionTimeSeriesData = @()

# Extract each channel id and then extract the x and y values for each channel id.  The x and y values are combined into a single array of objects.  The array of objects is then passed to the Export-Excel module to create an Excel workbook with a single worksheet.  The worksheet is named 'TimeSeriesData' and the table name is also 'TimeSeriesData'.  The table is then exported to the Excel workbook.  The workbook is then saved and closed.
foreach ($ChannelID in $($sessionts.channel_id | Select-Object -Unique) ) {
    for ($i = 0; $i -lt $($sessionts | Where-Object { $_.channel_id -EQ $ChannelID } | Select-Object -ExpandProperty x).Count; $i++) {

        $SessionTimeSeriesData += [PSCustomObject]@{
            'DateTime'     = $($sessionts | Where-Object { $_.channel_id -EQ $ChannelID } | Select-Object -ExpandProperty x)[$i] | ConvertFrom-UnixTime | ConvertTo-LocalTime
            'ChannelID'    = $ChannelID
            'ChannelLabel' = $($sessionts | Where-Object { $_.channel_id -EQ $ChannelID }).label
            'Temperature'  = $($($sessionts | Where-Object { $_.channel_id -EQ $ChannelID } | Select-Object -ExpandProperty y))[$i]
            'DegreeType'   = switch ($($sessionts | Where-Object { $_.channel_id -EQ $ChannelID }).DegreeType) {
                1 { 'Celsius' }
                2 { 'Fahrenheit' }
                Default { 'Unknown' }
            }
        }
    }
}

$FileName = "$($FilePath)FireBoardSessionDetail_$(Get-Date -Format 'yyyyMMddHHmmss').xlsx"

# Create the Excel workbook and add the Summary worksheet
$Sheet = 'Summary'
Write-Information "Adding sheet $($Sheet) to workbook $($FileName)"

# Splatting is used to pass the parameters to the Export-Excel module
$Parameters = @{
	Path = $FileName
	WorksheetName = $Sheet
	PassThru = $true
	AutoSize = $true
	TableName = $Sheet
}
$Excel = $SessionSummaryHash.GetEnumerator() | Select-Object Name, Value | Export-Excel @Parameters 

# Get the worksheet object and apply some basic formatting
$WSObject = $Excel.Workbook.Worksheets[$Sheet]
Set-ExcelRange -Worksheet $WSObject  -Range "a1:z9000" -HorizontalAlignment Left
$Excel.Save()

$TableName = 'TimeSeriesData'

$Parameters = @{
	ExcelPackage = $Excel
	WorksheetName = 'Summary'
    StartRow = 15
    StartColumn = 1
    EndRow = 35
    EndColumn = 20
	AutoSize = $true
	TableName = $TableName
	TableStyle = $TableStyle
	PassThru = $true
   # PivotTableName    = "$($TableName)Chart";
    ChartType         = "Line";
    IncludePivotChart = $true;
    ShowCategory      = $false;
    NoTotalsInPivot   = $true;
   # PivotFilter       = "ChannelLabel";
    PivotColumns      = "ChannelLabel";
    PivotRows         = "DateTime";
    PivotData         = @{ 'Temperature' = 'Average' };
  #  LegendPosition    = 'Bottom';
}
$Excel = $SessionTimeSeriesData | Select-Object DateTime, ChannelID, ChannelLabel, Temperature, DegreeType | Export-Excel @Parameters

# Apply some basic formatting
Add-ConditionalFormatting -Worksheet $WSObject -Range "D15:D10000" -DataBarColor Red

# Save the workbook and close it.  If the Show parameter is set to $true, the workbook will be displayed when the script completes.
$Excel.Save()
Close-ExcelPackage -ExcelPackage $Excel -Show
}
catch {
    $Err = $_ | Out-String
    Write-Error "An error occurred while processing the script.  The error is: $Err"
}
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = '.'
    , [Parameter(Mandatory = $false)]
    [string]$FileName = 'FireBoardData'
)
<#
.SYNOPSIS
    Example of using the FireBoardAPI module to get data from the FireBoard API
.DESCRIPTION
    This script is an example of using the FireBoardAPI module to get data from the FireBoard API. 
    Prompt for the FireBoard API key
    Prompt for the session to get data from.  
    Get the session data along with session time series data and export to a Excel workbook.
.EXAMPLE
    .\get-FireBoardExample.ps1 -Path 'C:\temp' -FileName 'FireBoardData'
.NOTES
    This script requires the FireBoardAPI module to be installed as well as the ImportExcel module.
    The FireBoardAPI module can be installed from the PowerShell Gallery using the following command:
    Install-Module -Name FireBoardAPI

    The ImportExcel module can be installed from the PowerShell Gallery using the following command:
    Install-Module -Name ImportExcel
#>

$FileName = "$($Path)\$FileName_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"

$TableStyle = 'Medium3'
#REQUIRES -Module FireBoardAPI
#REQUIRES -Module ImportExcel
# Import the FireBoardAPI module
Import-Module FireBoardAPI
import-Module ImportExcel

$APIKey = Get-FireboardAPIKey
$Session = get-FireboardList -APIKey $APIKey -ListType 'sessions' | Select-Object Created, title, Description , Start_Time, End_Time, Duration, id | Out-GridView -Title 'Fireboard Sessions' -PassThru

$SessionSumary = get-FireboardSession -APIKey $APIKey -SessionID $($Session.id)

$SessionSummaryHash = @{}
$SessionSummaryHash = add-HashTable -Hash1 $SessionSummaryHash -Hash2 $(convert-DataRowToHashTable -DataRow $($SessionSumary | Select-Object Title, Description, Start_Time, End_Time, Duration, Active))
$SessionSummaryHash = add-HashTable -Hash1 $SessionSummaryHash -Hash2 $(convert-DataRowToHashTable -DataRow $($SessionSumary.owner | Select-Object Username, Email))
$SessionSummaryHash = add-HashTable -Hash1 $SessionSummaryHash -Hash2 $(convert-DataRowToHashTable -DataRow $($SessionSumary.devices | Select-Object Hardware_ID, Model, @{Name = 'GrillModelNumber'; Expression = { $_.title } }, Channel_Count))
$sessionts = get-FireboardSessionTimeSeries -APIKey $APIKey -SessionID $($Session.id) 

$SessionTimeSeriesData = @()

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

$Sheet = 'Summary'

Write-Information "Creating new Excel file $($FileName)"
Write-Information "Adding sheet $($Sheet) to workbook $($FileName)"
$Excel = $SessionSummaryHash.GetEnumerator() | Select-Object Name, Value | Export-Excel -Path $FileName -WorksheetName $Sheet -PassThru -AutoSize -TableName $Sheet 
$WSObject = $Excel.Workbook.Worksheets[$Sheet]
Set-ExcelRange -Worksheet $WSObject  -Range "a1:z9000" -HorizontalAlignment Left
$Excel.Save()
$Sheet = 'TimeSeriesData'

$Excel = $SessionTimeSeriesData | Select-Object DateTime, ChannelID, ChannelLabel, Temperature, DegreeType | Export-Excel -ExcelPackage $Excel -WorksheetName $Sheet -AutoSize -TableName $Sheet -TableStyle $TableStyle -PassThru -IncludePivotChart -ChartType Line
# Apply some basic formatting
$WSObject = $Excel.Workbook.Worksheets[$Sheet]
Add-ConditionalFormatting -Worksheet $WSObject -Range "D2:D10000" -DataBarColor Red

$Excel.Save()
Close-ExcelPackage -ExcelPackage $Excel -Show


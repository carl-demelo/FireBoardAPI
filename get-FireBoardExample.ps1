$OutputFilePath = 'C:\FireBoard\Output\'  + (Get-Date -Format 'yyyyMMddHHmmss') + '.xlsx'
Import-Module FireBoardAPI

$TableStyle = 'Medium3'

$APIKey = Get-FireboardAPIKey
$Session = get-FireboardSessionList -APIKey $APIKey | Select-Object Created, title, Description , Start_Time, End_Time, Duration, id | Out-GridView -Title 'Fireboard Sessions' -PassThru

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

$FileName = "$($OutputFilePath)FireBoardSessionDetail_$(Get-Date -Format 'yyyyMMddHHmmss').xlsx" 
$Sheet = 'Summary'
Write-Information "Adding sheet $($Sheet) to workbook $($FileName)"
$Parameters = @{
	Path = $FileName
	WorksheetName = $Sheet
	PassThru = $true
	AutoSize = $true
	TableName = $Sheet
}
$Excel = $SessionSummaryHash.GetEnumerator() | Select-Object Name, Value | Export-Excel @Parameters 

$WSObject = $Excel.Workbook.Worksheets[$Sheet]
Set-ExcelRange -Worksheet $WSObject  -Range "a1:z9000" -HorizontalAlignment Left
$Excel.Save()
$Sheet = 'TimeSeriesData'

$Parameters = @{
	ExcelPackage = $Excel
	WorksheetName = $Sheet
	AutoSize = $true
	TableName = $Sheet
	TableStyle = $TableStyle
	PassThru = $true
	IncludePivotChart = $true
	ChartType = 'Line'
}
$Excel = $SessionTimeSeriesData | Select-Object DateTime, ChannelID, ChannelLabel, Temperature, DegreeType | Export-Excel @Parameters
# Apply some basic formatting
$WSObject = $Excel.Workbook.Worksheets[$Sheet]
Add-ConditionalFormatting -Worksheet $WSObject -Range "D2:D10000" -DataBarColor Red

$Excel.Save()

Close-ExcelPackage -ExcelPackage $Excel -Show


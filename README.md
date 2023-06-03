# FireBoardAPI Module

The FireBoardAPI is a PowerShell-based API designed to interact with the FireBoard BBQ grill controller. This API enables users to retrieve data from BBQ grills that are equipped with a FireBoard control unit. The FireBoard is a device that logs time series temperature data for wood pellet BBQ grills, and some models can control the cooking temperature wirelessly.

The FireBoard controller is compatible with various BBQ grills and smokers, including popular models from major brands such as Yoder Smokers, Weber Smokey Mountain Cooker, Big Green Egg, Traeger Pellet Grills, Pit Boss Pellet Grills, Green Mountain Grills, Kamado Joe, Oklahoma Joe's, and Napoleon Grills.

## Requirements

To use the FireBoardAPI, you need to own a FireBoard device and have an active Fireboard.io cloud account. Go to https://www.fireboard.com/ to see available cloud enabled products.

After creating your account you will need to generate an API key.  This key is kept privately and is used as part of the authentication to the REST API.

Once you have your account and API Key, you can explore some fo the commands with the get-FireBoardExample.ps1 script.  The script provides an example for connecting to your account and retrieving hardware metadata and session information.

## Installation

Simple installation:
Minimum PowerShell version
5.0

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/FireBoardAPI/).   

```powershell
Install-Module -Name FireBoardAPI
```

## Usage

The module provides several functions that can be used to interact with the FireBoard API:

- `Get-FireboardAPIKey`: Retrieves the API key from the FireBoard website.
- `Get-FireboardDevice`: Retrieves deviceID for a specific FireBoard device.
- `get-FireboardDeviceInfo`: Retrieves information about a specific FireBoard device.
- `get-FireboardList`:
- `get-FireboardRequest`: Retrieves information from the FireBoard API.
- `get-FireboardSession`: Retrieves session information for a specific FireBoard device.
- `get-FireboardSessionList`: Retrieves a list of sessions for a specific FireBoard device.
- `get-FireboardSessionTimeSeries`: Retrieves time series data for a specific FireBoard session.
- `get-FireboardTemp`: Retrieves temperature information for a specific FireBoard device.

### get-FireBoardExample.ps1

The get-FireBoardExample.ps1 example script uses the ImportExcel module by Doug Finke to create workbooks containg the firboard information and timeseries data for sessions.

## Attribution

Many thanks to Doug Finke for the awesome `ImportExcel` module, which enables PowerShell integration with Excel. You can find the module on [GitHub](https://github.com/dfinke/ImportExcel).

## Author

This module was written by Carl Demelo.

- GitHub: [https://github.com/carl-demelo/](https://github.com/carl-demelo/)
- LinkedIn: [https://www.linkedin.com/in/carl-demelo](https://www.linkedin.com/in/carl-demelo)

## License

This project is [licensed under the Apache 2.0 license](LICENSE).

## Changelog

### 1.0.0

- Initial release
- Added functions to retrieve device information, session information, and time series data.
- Added example script to retrieve device information and time series data for sessions.

### 1.1.5

- Added function to retrieve API key from FireBoard website.
- Enhanced example script to retrieve device information and time series data for sessions.

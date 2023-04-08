# Cooking with PowerShell!

#### The FireBoardAPI is a PowerShell-based API designed to interact with the FireBoard BBQ grill controller. This API enables users to retrieve data from BBQ grills that are equipped with a FireBoard control unit. The FireBoard is a device that logs time series temperature data for wood pellet BBQ grills, and some models can control the cooking temperature wirelessly.



The FireBoard controller is compatible with various BBQ grills and smokers, including popular models from major brands such as Yoder Smokers, Weber Smokey Mountain Cooker, Big Green Egg, Traeger Pellet Grills, Pit Boss Pellet Grills, Green Mountain Grills, Kamado Joe, Oklahoma Joe's, and Napoleon Grills. However, it's important to note that not all models of these brands may be compatible, so it's best to check the specifications of both your grill and the FireBoard controller before making a purchase. Additionally, some models may require additional adapters or cables to connect the FireBoard controller to the grill.

#### Requirements
To use the FireBoardAPI, you need to own a FireBoard device and have an active Fireboard.io cloud account. Go to https://www.fireboard.com/ to see available cloud enabled products.

After creating your account you will need to generate an API key.  This key is kept privately and is used as part of the authentication to the REST API.

Once you have your account and API Key, you can explore some fo the commands with the get-FireBoardExample.ps1 script.  The script provides an example for connecting to your account and retrieving hardware metadata and session information. 

# Installation
Simple installation:
Minimum PowerShell version
5.0

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/FireBoardAPI/).   

```powershell
Install-Module -Name FireBoardAPI
```

# Example
##  get-FireBoardExample.ps1
The get-FireBoardExample.ps1 example script uses the ImportExcel module by Doug Finke to create workbooks containg the firboard information and timeseries data for sessions. The ImportExcel module is an excellent tool for creating and managing Excel workbooks in PowerShell, and you can find it here: <br/>

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/ImportExcel/).   

```powershell
Install-Module -Name ImportExcel
```

# Summary
If you're interested in exploring the capabilities of the FireBoardAPI, you can refer to the get-FireBoardExample.ps1 script for a usage example. Keep in mind that any FireBoard device that supports a cloud account should work with this module.

In summary, FireBoardAPI is a powerful tool for anyone who owns a compatible grill and FireBoard controller. By utilizing this API, you can retrieve data from your grill and use it to make informed decisions about your cooking process

<br/>

Author(s)
Carl Demelo


# Contact Me:
[LinkedIN](https://www.linkedin.com/in/carl-demelo/)

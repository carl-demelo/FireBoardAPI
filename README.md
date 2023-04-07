# FireBoardAPI
Powershell API for the Fireboard BBQ grill controller

Gets data from BBQ grills having a FireBoard control unit.  What's a fireboard?  It is a device that logs time series temperature data for wood pellet BBQ grills.  Some of the devices control the cooking temperature, wireless. 

Yoder grills have models utiizing Fireboard, I have the YS640.  It's also a popular add on to those grills that do not have a built in controller.

See get-FireBoardExample.ps1 for example usage.  The get-FireBoardExample.ps1 script retrieves a cooking session temperature as time series data and exports to MS EXcel workbook using the AWESOME ImportExcel module by Doug Finke, get it here https://github.com/dfinke/ImportExcel

 Any fireboard device that supports a cloud account should work with this module.  
 
 Pre-requisites:
 You need to own a Fireboard device and have an active Fireboard.io cloud account.
 If you are using the example then install the ImportExcel module first: install-module ImportExcel

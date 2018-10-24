#------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: fix_monitor_apps.ps1
# Description: Reimports Monitoring Apps, recreates Data connections, switches data connections to use certificate auth
# Dependencies: Script most be ran from Central Node as the Qlik Sense Service Account
# 
#   Version    Date        Author         Change Notes
#   0.1        2018-08-30  Eric Thomas    Initial Version 
#   0.2        2018-09-23                 Added Support for June 2018 Data Connections + Accounts for default password change between versions
#   0.3        2018-10-07                 Added Temporary error handling as random Red Text is scary 
#   0.4        2018-10-24                 Changed Data Connection updates from a 'Find/Replace' to directly updating the JSON Object value
#
#   To-Do list: Add FQDN to Archived Logs folder data connection
#
#------------------------------------------------------------------------------------------------------------------------------

#Prepare Connection information
#--------------------------------------
#Build Header
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Qlik-XrfKey",'NzU0NTIwMDAwNTIy')
$headers.Add("X-Qlik-User",'UserDirectory=internal; UserId=sa_api')

#Obtain Certficate
$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where {$_.Subject -like '*QlikClient*'}
#$thumbprint = Get-ChildItem -Path cert:\CurrentUser\my | Where {$_.Subject -like '*QlikClient*'}|Select Thumbprint
#$thumbprint = $thumbprint.Thumbprint

#Build FQDN
# Gets the configured hostname from the host.cfg file
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
# Convert the base64 encoded install name for Sense to UTF data
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))

#Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

#Get Password to be used with Certificate
$response = Read-host "Please enter a password that will be used for Client Certificate Authentication" -AsSecureString
$passwordCert = New-Object System.Net.NetworkCredential("Blank",$response)

#Disabling Errors here as Red Text is scary and tells us "The file already exists" or 
# that a data connection could not be found 
$ErrorActionPreference = "SilentlyContinue"

#Export the Certificate
#--------------------------------------
$certBody = '{  
   "MachineNames":[  
      "'+$($FQDN)+'"
   ],
   "certificatePassword":"'+$($passwordCert.Password)+'",
   "includeSecretsKey":true,
   "exportFormat":"Windows"
}'

Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/CertificateDistribution/exportcertificates?xrfkey=NzU0NTIwMDAwNTIy" -Method Post -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $certBody

#Move the Certifcate for the REST Connector
#--------------------------------------
Move-Item -Path C:\ProgramData\Qlik\Sense\Repository\"Exported Certificates"\$($FQDN) -Destination C:\ProgramData\Qlik\Sense\Engine\Certificates


#Rename Data Connections
#--------------------------------------
#

#Monitor_apps_rest_app
#---------------------------
$RESTapp = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_app')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 

#Filter out ID value
$RESTappID = $RESTapp.id

#GET the DataConnection JSON
$RESTappDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert

#Modify App Name
$RESTappDC.name = 'monitor_apps_REST_app-old'

#Convert Response to JSON
$RESTappDC = $RESTappDC | ConvertTo-Json

Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappDC

#
#Repeat Through all Monitoring app Data Connections
#
#Monitor_apps_rest_appobject
#---------------------------
$RESTappObject = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_appobject')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTappObjectID = $RESTappObject.id
$RESTappObjectDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTappObjectDC.name = 'monitor_apps_REST_appobject-old'
$RESTappObjectDC = $RESTappObjectDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappObjectDC
#Monitor_apps_rest_event
#---------------------------
$RESTevent = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_event')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTeventID = $RESTevent.id
$RESTeventDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTeventDC.name = 'monitor_apps_REST_event-old'
$RESTeventDC = $RESTeventDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTeventDC
#Monitor_apps_rest_license_access
#---------------------------
$RESTLicenseAccess = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_access')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseAccessID = $RESTLicenseAccess.id
$RESTLicenseAccessDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseAccessDC.name = 'monitor_apps_REST_license_access-old'
$RESTLicenseAccessDC = $RESTLicenseAccessDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseAccessDC
#Monitor_apps_rest_license_analyzer
#---------------------------
$RESTLicenseAnalyzer = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_analyzer')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseAnalyzerID = $RESTLicenseAnalyzer.id
$RESTLicenseAnalyzerDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAnalyzerID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseAnalyzerDC.name = 'monitor_apps_REST_license_analyzer-old'
$RESTLicenseAnalyzerDC = $RESTLicenseAnalyzerDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAnalyzerID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseAnalyzerDC
#Monitor_apps_rest_license_login
#---------------------------
$RESTLicenseLogin = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_login')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseLoginID = $RESTLicenseLogin.id
$RESTLicenseLoginDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseLoginDC.name = 'monitor_apps_REST_license_login-old'
$RESTLicenseLoginDC = $RESTLicenseLoginDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseLoginDC
#Monitor_apps_rest_license_overview
#---------------------------
$RESTLicenseOverview = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_overview')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseOverviewID = $RESTLicenseOverview.id
$RESTLicenseOverviewDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseOverviewID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseOverviewDC.name = 'monitor_apps_REST_license_overview-old'
$RESTLicenseOverviewDC = $RESTLicenseOverviewDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseOverviewID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseOverviewDC
#Monitor_apps_rest_license_professional
#---------------------------
$RESTLicenseProfessional = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_professional')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseProfessionalID = $RESTLicenseProfessional.id
$RESTLicenseProfessionalDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseProfessionalID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseProfessionalDC.name = 'monitor_apps_REST_license_professional-old'
$RESTLicenseProfessionalDC = $RESTLicenseProfessionalDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseProfessionalID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseProfessionalDC
#Monitor_apps_rest_license_user
#---------------------------
$RESTLicenseUser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseUserID = $RESTLicenseUser.id
$RESTLicenseUserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseUserDC.name = 'monitor_apps_REST_license_user-old'
$RESTLicenseUserDC = $RESTLicenseUserDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseUserDC
#Monitor_apps_rest_task
#---------------------------
$RESTtask = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_task')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTtaskID = $RESTtask.id
$RESTtaskDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTtaskDC.name = 'monitor_apps_REST_task-old'
$RESTtaskDC = $RESTtaskDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTtaskDC
#Monitor_apps_rest_user
#---------------------------
$RESTuser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTuserID = $RESTuser.id
$RESTuserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTuserDC.name = 'monitor_apps_REST_user-old'
$RESTuserDC = $RESTuserDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTuserDC
#--------------------------------------

#Upload Operations Monitor
#--------------------------------------
#Build File Path
$fileLocation = $env:ProgramData+"\Qlik\Sense\Repository\DefaultApps\"+"Operations Monitor.qvf"

#Read Data
$FileContent = [IO.File]::ReadAllBytes($fileLocation)

#Perform Upload
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/upload?keepData=true&name=Operations+Monitor-New&xrfkey=NzU0NTIwMDAwNTIy" -Method Post -Headers $headers -ContentType 'application/vnd.qlik.sense.app' -Certificate $cert -Body $FileContent

#Upload License Monitor
#--------------------------------------
#Build File Path
$fileLocation = $env:ProgramData+"\Qlik\Sense\Repository\DefaultApps\"+"License Monitor.qvf"

#Read Data
$FileContent = [IO.File]::ReadAllBytes($fileLocation)

#Perform Upload
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/upload?keepData=true&name=License+Monitor-New&xrfkey=NzU0NTIwMDAwNTIy" -Method Post -Headers $headers -ContentType 'application/vnd.qlik.sense.app' -Certificate $cert -Body $FileContent

#Swap Data Connections to Cert Auth
#--------------------------------------

#Monitor_apps_rest_app
#---------------------------
$RESTapp = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_app')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 

#Filter out ID value
$RESTappID = $RESTapp.id

#GET the DataConnection JSON
$RESTappDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert

#Switch Data Connection to Cert Auth
$RESTappDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/app/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTappDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"

#Convert Response to JSON
$RESTappDC = $RESTappDC | ConvertTo-Json

Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappDC

#Repeat Through all Monitoring app Data Connections
#
#Monitor_apps_rest_appobject
#---------------------------
$RESTappObject = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_appobject')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTappObjectID = $RESTappObject.id
$RESTappObjectDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTappObjectDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/app/object/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTappObjectDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTappObjectDC = $RESTappObjectDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappObjectDC
#Monitor_apps_rest_event
#---------------------------
$RESTevent = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_event')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTeventID = $RESTevent.id
$RESTeventDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTeventDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/event/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTeventDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTeventDC = $RESTeventDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTeventDC
#Monitor_apps_rest_license_access
#---------------------------
$RESTLicenseAccess = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_access')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseAccessID = $RESTLicenseAccess.id
$RESTLicenseAccessDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseAccessDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/license/accesstypeinfo;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTLicenseAccessDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTLicenseAccessDC = $RESTLicenseAccessDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseAccessDC
#Monitor_apps_rest_license_analyzer
#---------------------------
$RESTLicenseAnalyzer = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_analyzer')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseAnalyzerID = $RESTLicenseAnalyzer.id
$RESTLicenseAnalyzerDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAnalyzerID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseAnalyzerDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/license/analyzeraccesstype/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTLicenseAnalyzerDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTLicenseAnalyzerDC = $RESTLicenseAnalyzerDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAnalyzerID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseAnalyzerDC
#Monitor_apps_rest_license_login
#---------------------------
$RESTLicenseLogin = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_login')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseLoginID = $RESTLicenseLogin.id
$RESTLicenseLoginDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseLoginDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/license/loginaccesstype/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTLicenseLoginDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTLicenseLoginDC = $RESTLicenseLoginDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseLoginDC
#Monitor_apps_rest_license_overview
#---------------------------
$RESTLicenseOverview = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_overview')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseOverviewID = $RESTLicenseOverview.id
$RESTLicenseOverviewDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseOverviewID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseOverviewDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/license/accesstypeoverview;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTLicenseOverviewDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTLicenseOverviewDC = $RESTLicenseOverviewDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseOverviewID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseOverviewDC
#Monitor_apps_rest_license_professional
#---------------------------
$RESTLicenseProfessional = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_professional')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseProfessionalID = $RESTLicenseProfessional.id
$RESTLicenseProfessionalDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseProfessionalID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseProfessionalDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/license/professionalaccesstype/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTLicenseProfessionalDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTLicenseProfessionalDC = $RESTLicenseProfessionalDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseProfessionalID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseProfessionalDC
#Monitor_apps_rest_license_user
#---------------------------
$RESTLicenseUser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseUserID = $RESTLicenseUser.id
$RESTLicenseUserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseUserDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/license/useraccesstype/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTLicenseUserDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTLicenseUserDC = $RESTLicenseUserDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseUserDC
#Monitor_apps_rest_task
#---------------------------
$RESTtask = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_task')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTtaskID = $RESTtask.id
$RESTtaskDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTtaskDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/task/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTtaskDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTtaskDC = $RESTtaskDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTtaskDC
#Monitor_apps_rest_user
#---------------------------
$RESTuser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTuserID = $RESTuser.id
$RESTuserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTuserDC.connectionstring = "CUSTOM CONNECT TO 'provider=QvRestConnector.exe;url=https://$($FQDN):4242/qrs/user/full;timeout=999;method=GET;sendExpect100Continue=true;autoDetectResponseType=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=true;useCertificate=FromFile;certificateStoreLocation=LocalMachine;certificateStoreName=My;certificateFilePath=$($FQDN)\client.pfx;trustedLocations=qrs_proxy%2https://localhost:4244;queryParameters=xrfkey%20000000000000000;addMissingQueryParametersToFinalRequest=false;queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api;PaginationType=None;'"
$RESTuserDC.password = "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
$RESTuserDC = $RESTuserDC | ConvertTo-Json
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTuserDC
#--------------------------------------

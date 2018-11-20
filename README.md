# QlikSenseScripts

DISCLAIMER
 
This tool is provided free of charge and is not supported. fix_monitor_apps.ps1 is not an official Qlik product and is provided without warranty. Use of this script is entirely at the user's own risk.
  
If you would like to use this script, download and run as your Qlik Sense Service Account on the Central Node. 
 
• Old Data connections used by the Monitoring Apps will be renamed e.g. monitor_apps_REST_app > monitor_apps_REST_app-old etc.
• The Operations Monitor and License Monitor will be imported to recreate the data connections name Operations Monitor-New etc. (they can also be used to test if the issue was with the currently published apps) 
• The Data Connections will be modifed to use certificate authorization instead of Windows Authentication (This will create a password protected Certificate at [ProgramData]\Qlik\Sense\Engine\Certificates using the name of the Central Node) - You will need to delete this folder if the script is ever ran again.
 
Nothing is deleted by running this script only renamed. If you would like to revert back prior to running the script, just swap the Data connections back.
 
Additional considerations:
In multi-node environments where the central node does not perform reloads, the certificate generated will have to be moved to the corresponding folders on the other nodes: By Default, [ProgramData]\Qlik\Sense\Engine\Certificates\<Central Node Name> (keep the folder name the same)

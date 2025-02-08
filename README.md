# Trigger Troubleshooter

Trigger Troubleshooter takes a trigger name, retrieves its filter, scope, and schedule, then performs a test on live data. It gathers data within the trigger’s scope, validates it against the defined filter/schedule, checks if the fields are being observed by the monitor, and displays the results.  

Disclaimer: The results from this script does not guarantee the trigger will fire due to many factors. But this will be close.

## Script Action

• Provide a trigger name to test against live data.  
• The script will:  
  – Download the latest TriggerTroubleshooter module from GitHub (unless an offline path is provided).  
  – Import the module.  
  – Run the Test-Trigger function.  
  – Optionally collect a Support Trigger Dump.

Notes:
- Only objects within the trigger’s scope are processed. To limit output, narrow the trigger’s scope.
- Using the "Process All Records" option may produce a large volume of output, depending on the trigger and scope.
- The "Records Per Folder" option takes a specified number of records from each folder. For instance, if you have 10 folders and choose 2 records per folder, up to 20 records will be processed (assuming each folder has at least 2 records).
- You can save the results to a file using "Path to Save Results" option.

## Supported Triggers (Pending Tests)

- Advanced Logical Disk  
- Advanced Folder  
- Advanced Session  
- Advanced Computer  
- Service 
- Events 
- User Logged Off  
- User Logged On  
- Scheduled
- Machine Down
- Process Started
- Process Ended
- Session State Changed

## Non-Supported Triggers
- Stress

## Example

### Trigger Configuration

![Trigger Filter](photos/triggerfilter.png)

### Script Action Parameters

![SBA Parameters](photos/sbaParameters.png)

### Script Action Result

![SBA Result](photos/sbaresult.png)

## Result header explanation

### Key  
- An internal table propety for any record

### In Schedule
- Every trigger has a [schedule](https://support.controlup.com/docs/schedule-settings?highlight=Trigger%20Schedule) associated with it
- This will test the assocaited schedule against the monitor's time

### Are Properties Observed
- This checks the Observables Runtime table to see if the properties are being obesrved by the monitor
- This will be false depending on the type of trigger

### Will Fire
- If the trigger conditions are met, this will be True
# TriggerTroubleshooter

# What does it do
Takes a trigger name, gets the filter, scope, and schedule, gets the data in the scope from observables, tests it against the filter/schedule, sees if the fields are being observed by the monitor, and outputs the results 
Has the option to use Export-CUQuery to test all records.

# What works (Need to finish testing)
- Service
- Advanced Logical Disk
- Advanced Folder
- Advanced Session
- Advanced Computer
- User logged off

# Example

## Trigger Configuration
![alt text](photos/triggerfilter.png)

## SBA Parameters
![alt text](photos/sbaParameters.png)

## SBA Result
![alt text](photos/sbaresult.png)

# To Do
- Process Events trigger differently
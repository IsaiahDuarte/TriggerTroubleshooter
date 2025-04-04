# Trigger Troubleshooter - The Test Button

Trigger Troubleshooter is a utility that takes a trigger name, retrieves its filter, scope, and schedule, and then performs a test on live data. It gathers data within the trigger's scope, validates it against the specified filter and schedule, checks if the relevant fields are being monitored, and displays the results.

Note: The results produced by this script do not guarantee that the trigger will fire, as there are many influencing factors. However, the results should be very close to what you can expect.

**Requirements:** Version 9.0.5 or later

--------------------------------------------------

## Script Action Overview

When you provide a trigger name, the script tests it against live data and reports the results. Here are some important points to note:

- **Scope Limitation:**  
  Only objects within the trigger's defined scope are processed. To limit the output, narrow the trigger’s scope as needed.

- **Output Volume:**  
  Choosing the "Process All Records" option might produce a large volume of output, depending on the trigger and its scope.

- **Record Limiting:**  
  The "Record" option allows you to specify a certain number of records to process.

- **Saving Results:**  
  You can save the output to a file by using the "Path to Save Results" parameter. This requires a fully qualified file path (e.g., C:\temp\output.txt).

--------------------------------------------------

## Simulate Trigger

Trigger Troubleshooter also offers the ability to simulate a trigger based on the one you provide. The simulation works by:

1. Sanitizing the columns available for simulation.
2. Creating a new trigger.
3. Simulating the conditions (for example, maximizing CPU usage) on the computer specified by the "Simulate on Computer" parameter.

### Supported Trigger Simulations

- **Advanced Machine Triggers:**  
  - CPU  
  - MemoryInUse  
  *Note: If both MemoryInUse and CPU columns are present, CPU will be chosen and MemoryInUse will be dropped.*

- **Windows Event Triggers:**  
  - Category  
  - EntryType  
  - EventID  
  - Log  
  - Message  
  - Source

- **Advanced Logical Disk Triggers:**  
  - DiskKBps  
  - DiskReadKBps  
  - DiskWriteKBps  
  - FreeSpacePercentage

- **Process Start/Stop:**  
  - Name  
  *Note: This is using Get-Command and Registry App Paths to find an exe path*

### Expected Output for a Simulated Trigger

For a successful simulation, the output will look similar to:
```text
--------------------------------------------------
Simulation result: True
--------------------------------------------------
```

No follow-up actions will be taken on simulated triggers.

*Note:* For the "Simulate on Computer" parameter, provide the sName value from the Computers table. You can obtain this value using:  
(Get-CUComputers -Match "MyComputerName").Name

--------------------------------------------------

## Non-Supported Triggers

- Stress

--------------------------------------------------

## Example

Below are examples of the trigger configuration, script action parameters, and script action result screens.

### Trigger Configuration

![Trigger Filter](photos/triggerfilter.png)

### Script Action Parameters

![SBA Parameters](photos/sbaParameters.png)

### Script Action Result

![SBA Result](photos/sbaresult.png)

--------------------------------------------------

## Result Header Explanation

- **Key:**  
  An internal table property representing any record.

- **Identity:**  
  A mapped field derived from the trigger that provides a unique identifier for the tested record.

- **In Schedule:**  
  Every trigger has an associated [schedule](https://support.controlup.com/docs/schedule-settings?highlight=Trigger%20Schedule). This field indicates whether the schedule aligns with the monitor’s current time.

- **Are Properties Observed:**  
  Checks whether the specified properties are being monitored by referring to the Observables Runtime table. Depending on the trigger type (e.g., Windows Event, Process Started, Process Stopped), this value might be false.

- **Last Inspection Time:**  
  The time when the monitor last evaluated the trigger.

- **Will Fire:**  
  Indicates whether the trigger conditions are met. If all conditions are met, this will be True.

## Setup

1. Download the latest release from the official repository:  
   https://github.com/IsaiahDuarte/TriggerTroubleshooter/releases

   - File Breakdown:
     - ScriptAction.ps1: Contains the main Trigger Troubleshooter logic.
     - ScriptAction-Simulated.ps1: A helper script used for simulating triggers.
     - Trigger Troubleshooter.xml: The primary XML file to import as a script action.
     - Trigger Troubleshooter - Simulated Test.xml: Required for script actions when using Simulated Trigger functionality.
     - TriggerTroubleshooter.zip: A ZIP archive containing the TriggerTroubleshooter module.

2. For just using within the ControlUp Console, you only need the two XML files (Trigger Troubleshooter.xml and Trigger Troubleshooter - Simulated Test.xml).

3. Import the XML files into ControlUp by following these instructions:  
   https://support.controlup.com/docs/script-based-actions-sba#import-an-sba

4. After importing the script actions into your ControlUp environment, update the Trigger Troubleshooter settings so that the script is executed from a monitor server. See the settings screenshot for guidance:  
   ![Settings Screenshot](photos/sbaSettings.png)

   - If you plan to run simulated tests, ensure that you use a dedicated service account with permissions to manage triggers and execute the TriggerTroubleshooter - Simulated Test script action.

5. Once configured, you can start the Trigger Troubleshooter action. Right-click on any computer (the script will always execute on a monitor server) and choose Trigger Troubleshooter.  
   • Important: Do not run “Trigger Troubleshooter - Simulated Test” directly—this script is invoked automatically when simulating a trigger.

*Note:*  
For the "Simulate on Computer" parameter, input the sName value from the Computers table. You can retrieve this value by running:  
(Get-CUComputers -Match "MyComputerName").Name
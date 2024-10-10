Alex 15 March 2024

To compile Espresso in an executable:
* Start from a clean slate:
  * Close and reopen MATLAB.
  * Restore the default path (command `restoredefaultpath`).
  * Run Espresso and close it.
* Reset dependencies:
  * Double-click on `Espresso.prj` file to start the Application Compiler with existing settings.
  * Remove the "main file" (`Espresso.m`) to remove all the files required. This might take a few seconds.
  * Remove any remaining files and folders in the list of files required.
  * Add `Espresso.m` again as a "main file" and wait for the application compiler to find all required files. This might take a few seconds.
  * Add folders `assets` and `Espresso_resources` to the list.
  * If it is there, uncheck the "Hyperspectral Imaging Library Support Package" from the list of "Suggested Support Packages".
  * Remove the files `icon_24.png` and `LICENSE` from the list of "Files installed for your end user", then add them again (respectively from the `Espresso_resources` folder and the root folder).
* Update the version number:
  * In the setup file name ("Packaging Options" panel, "Runtime downloaded from web" field).
  * In the "application information" panel.
  * In the "Default installation folder" field.
* Details:
  * All paths in "Settings" should be in the "Espresso\bin" folder.
  * If missing, the icon, splash screen image, and half-splash image are all in the `Espresso_resources` folder.
  * If anything is missing from the "Application information", copy contents of README file.
  * In "Additional runtime settings", make sure the "Create log file" box is UNchecked.
* Finalize:
  * Click on "Save".
  * Click on "Package".

Note: material for old compiling approach (before using the Application Compiler) are backed up in the `obsolete\old_compiling` folder.
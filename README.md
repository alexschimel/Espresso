![](https://github.com/alexschimel/Espresso/blob/master/Espresso_resources/banner.png)

# *Espresso* 

Multibeam water-column visualization and processing.

[![](https://github.com/alexschimel/Espresso/blob/master/Espresso_resources/download.png)](https://github.com/alexschimel/Espresso/releases/download/v1/espresso_v1_setup.exe)

## Description

*Espresso* is a free and open-source app to visualize and process water-column data acquired by multibeam echosounders. The main feature of this tool is the possibility to vertically echo-integrate water-column data so as to visualize and examine anomalies.

*Espresso* uses the [CoFFee multibeam data processing toolbox](https://github.com/alexschimel/CoFFee) (hence the name). It is coded in [MATLAB](https://www.mathworks.com/products/matlab.html), but is also available as a standalone application that does not require a MATLAB licence (see the Dependencies and Installing sections).

Relevant features:
* Support Kongsberg .all/.wcd, Kongsberg .kmall/.kmwcd, and Reson-Teledyne .s7k formats.
* Mask unwanted data (seafloor echo and below, outer-beams, inner-range, outer-range).
* Filter the sidelobe artefact.
* Vertical echo-integration over the whole water-column, or in horizontal slices defined relative to the water-surface (i.e. in depth) or to the bottom (i.e. in height).
* Visualize data stacked in range or depth.
* Export echo-integration mosaics.
* Geopicking features as polygons or points, and export as shapefiles.

 ![](https://github.com/alexschimel/Espresso/blob/master/Espresso_resources/screenshot.png)

## Getting Started

### Dependencies

* For the source code:
  * [MATLAB](https://www.mathworks.com/products/matlab.html). The code was developed with version R2020b, but it may work on earlier/later versions.
  * Some [MATLAB toolboxes](https://www.mathworks.com/products.html):
    * Mapping Toolbox
    * Image Processing Toolbox
    * Statistics and Machine Learning Toolbox
    * Signal Processing Toolbox
  * [The *CoFFee* toolbox](https://github.com/alexschimel/CoFFee)
* For the compiled executable: [MATLAB Runtime v9.9](https://www.mathworks.com/products/compiler/matlab-runtime.html).
  * Note: if you install the app using the binary installer, the setup wizard will automatically detect whether you have the correct version of MATLAB Runtime installed and, if not, allow you to download and install it then.

### Installing

* For the source code: 
  * Clone or download this repository, as well as the repository of [*CoFFee*](https://github.com/alexschimel/CoFFee), onto your machine.
* For the compiled executable: 
  * Preferably, [download the binary installer from the releases page](https://github.com/alexschimel/Espresso/releases), execute the installer, and follow the instructions of the setup wizard. The setup wizard will check if you have the appropriate version of MATLAB Runtime installed and, if not, let you download and install it. Note that the setup wizard requires an internet connection.
  * Alternatively, you can simply [download the binary executable and accompanying files from the releases page](https://github.com/alexschimel/Espresso/releases) and double-click the .exe file to run the application without installing it. Note that you still need to have the appropriate version of MATLAB Runtime installed.

### Executing program

* For the source code: Start MATLAB, navigate to the root directory of the *Espresso* code, and type `Espresso` in the Command Window.
  * Note: The first time you run *Espresso* from the source code, you will be prompted to provide the location of a folder containing the *CoFFee* toolbox. *Espresso* will check if the version of that toolbox is the one with which the app was built. If the version of *CoFFee* is not the one expected, you will receive a warning letting you know you might experience issues, and recommending you download (or check out) the appropriate version.
* For the compiled executable: Execute the installed program.
  * Note: The first time you run *Espresso* after installation, it might take a while for the app to appear. Be patient. It will be faster the next times.

Note: At start-up, *Espresso* creates a `Espresso` user folder (normally, C:\Users\USERNAME\Documents\Espresso). This folder contains a configuration file for the app, and is the default folder for any exports from the app. This folder or any of its contents can be deleted safely (although if you delete the configuration file, this will reset the app configuration).

## Help

Head over to the [wiki](https://github.com/alexschimel/Espresso/wiki) for documentation (to do).

For more information, contact the authors.

## Updates

If you want to receive notifications of future releases (recommended), you may create a github account, and on this repository click on 'Watch', then 'Custom', and choose 'Releases'. Verify in your GitHub settings that you are set to receive 'Watching' notifications.

## Authors

* Alexandre Schimel ([The Geological Survey of Norway](https://www.ngu.no), alexandre.schimel@ngu.no)
* Yoann Ladroit (Kongsberg Discovery)
* Sally Watson (NIWA)

## Version History

[See the releases page](https://github.com/alexschimel/Espresso/releases)

## License

Distributed under the MIT License. See `LICENSE` file for more information.
If you use the software, you must acknowledge all authors listed. An article is in preparation for reference. 

## See Also

All apps based on CoFFee:
* [*Grounds*](https://github.com/alexschimel/Grounds): Elevation Change Analysis
* [*Espresso*](https://github.com/alexschimel/Espresso): Multibeam water-column visualization and processing
* [*Iskaffe*](https://github.com/alexschimel/Iskaffe): Multibeam backscatter quality control

## Acknowledgments

None to date.

## References 

None to date.

## For developers

[See the 'For developers' section on the *CoFFee* page](https://github.com/alexschimel/CoFFee)

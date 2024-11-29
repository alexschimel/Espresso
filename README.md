![](https://github.com/alexschimel/Espresso/blob/master/Espresso_resources/banner.png)

# *Espresso* 

Multibeam water-column visualization and processing.

[![](https://github.com/alexschimel/Espresso/blob/master/Espresso_resources/download.png)](https://github.com/alexschimel/Espresso/releases/download/v1.2/espresso_v120_setup.exe)

## Description

*Espresso* is a free and open-source app to visualize and process water-column data acquired by multibeam echosounders. The main feature of this tool is the possibility to vertically echo-integrate water-column data so as to visualize and examine acoustic anomalies.

*Espresso* uses the [CoFFee multibeam data processing toolbox](https://github.com/alexschimel/CoFFee) (hence the name). It is coded in [MATLAB](https://www.mathworks.com/products/matlab.html), but is also available as a standalone application that does not require a MATLAB licence (see the [Dependencies](#dependencies) and [Installing](#installing) sections).

Relevant features:
* Support Kongsberg .all/.wcd, Kongsberg .kmall/.kmwcd, and Teledyne .s7k (Reson, Norbit) formats.
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
  * Clone this repository, as well as the repository of [*CoFFee*](https://github.com/alexschimel/CoFFee), with [git or a git client](https://git-scm.com/).
  * Note that a few files are managed with [git-lfs](https://git-lfs.com/) so you will need to have this installed before you clone this repository.
  * Simply downloading the source code will not work since you will miss the files that require git-lfs.
* For the compiled executable: 
  * Preferably, [download the binary installer from the releases page](https://github.com/alexschimel/Espresso/releases), execute the installer, and follow the instructions of the setup wizard. The setup wizard will check if you have the appropriate version of MATLAB Runtime installed and, if not, let you download and install it. Note that the setup wizard requires an internet connection.
  * Alternatively, you can simply [download the binary executable and accompanying files from the releases page](https://github.com/alexschimel/Espresso/releases) and double-click the .exe file to run the application without installing it. Note that you still need to have the appropriate version of MATLAB Runtime installed.

### Executing program

* For the source code: Start MATLAB, navigate to the root directory of the *Espresso* code, and type `Espresso` in the Command Window.
  * Note: The first time you run *Espresso* from the source code, you will be prompted to provide the location of a folder containing the *CoFFee* toolbox. *Espresso* will check if the version of that toolbox is the one with which the app was built. If the version of *CoFFee* is not the one expected, you will receive a warning message letting you know you might experience issues and recommending you download (or check out) the appropriate version.
* For the compiled executable: Execute the installed program.
  * Note: The first time you run *Espresso* after installation, it might take a while for the app to appear. Be patient. It will be faster the next times.

Note: At start-up, *Espresso* creates an `Espresso` user folder (normally, C:\Users\USERNAME\Documents\Espresso). This folder contains a configuration file for the app, and is the default folder for any exports from the app. It is safe to delete this folder or any of its contents (although if you delete the configuration file, this will reset the app configuration).

## Help

Head over to the [wiki](https://github.com/alexschimel/Espresso/wiki) for documentation (in progress).

There is also [a playlist of tutorials on Alex Schimel's Youtube channel](https://youtube.com/playlist?list=PLWo0Tmonl7YAuzV8f2Zr39_zUw-wmLD_H&si=TG0jZskuOc-B-fOH) (in progress).

If you have any issues, first check the project's [Issues](https://github.com/alexschimel/Espresso/issues) to search for a fix. Otherwise, let the authors know by [creating a new issue](https://github.com/alexschimel/Espresso/issues/new). Ideally, share the Espresso log to provide insight in the issue. 

For more help, contact the [authors](#authors-and-contributors).

## Past versions and updates

See the [releases](https://github.com/alexschimel/Espresso/releases) page for past released versions. 

If you want to receive notifications of future releases (recommended), you may create a github account, and on this repository click on 'Watch', then 'Custom', and choose 'Releases'. Verify in your GitHub settings that you are set to receive 'Watching' notifications.

## About

### Authors and contributors

* Alexandre Schimel (The Geological Survey of Norway, alexandre.schimel@ngu.no)
* Yoann Ladroit (Kongsberg Discovery)
* Shyam Chand (The Geological Survey of Norway)

### Copyright

2017-2024
* Alexandre Schimel (The Geological Survey of Norway)
* Yoann Ladroit (Kongsberg Discovery)
* The National Institute of Water and Atmospheric Research (NIWA), New Zealand

### License

The _Espresso_ software and source code are distributed under the MIT License. See `LICENSE` file for details.

_Espresso_ uses several pieces of third-party code, each being distributed under its own license. Each piece of code is contained in a separate sub-folder of the 'toolboxes' folder and includes the corresponding license file.

### Citation/Credit

If you use the software, please acknowledge Alexandre Schimel (The Geological Survey of Norway), Yoann Ladroit (Kongsberg Discovery), and Sally Watson (NIWA). 

For citation, a dedicated article is in preparation. In the meantime, preferably cite [Schimel et al. (2024a)](https://doi.org/10.5194/egusphere-egu24-11043), [Turco et al. (2022)](https://doi.org/10.3389/feart.2022.834047), and [Porskamp et al. (2022)](https://doi.org/10.1002/lno.12160).

## See Also

### Apps based on CoFFee
* [*Grounds*](https://github.com/alexschimel/Grounds): Elevation Change Analysis
* [*Espresso*](https://github.com/alexschimel/Espresso): Multibeam water-column visualization and processing
* [*Iskaffe*](https://github.com/alexschimel/Iskaffe): Multibeam backscatter quality control

### References 

Articles about or using _Espresso_:
* Turco, F., Ladroit, Y., Watson, S. J., Seabrook, S., Law, C. S., Crutchley, G. J., Mountjoy, J., Pecher, I. A., Hillman, J. I. T., Woelz, S., & Gorman, A. R. (2022). Estimates of Methane Release From Gas Seeps at the Southern Hikurangi Margin, New Zealand. Frontiers in Earth Science, 10, 1–20. https://doi.org/10.3389/feart.2022.834047
* Porskamp, P., Schimel, A. C. G., Young, M., Rattray, A., Ladroit, Y., & Ierodiaconou, D. (2022). Integrating multibeam echosounder water‐column data into benthic habitat mapping. Limnology and Oceanography, 1–13. https://doi.org/10.1002/lno.12160
* Schimel, A., Ladroit, Y., & Watson, S. (2024a). Espresso: Open source software for the visualization of multibeam water column data. HYDRO International, 28(3), 22–25. [Link to online version of article](https://www.hydro-international.com/content/article/espresso-open-source-software-for-the-visualization-of-multibeam-water-column-data)
* Schimel, A., Ladroit, Y., & Watson, S. (2024b). Espresso: An Open-Source Software Tool for Visualizing and Analysing Multibeam Water-Column Data. EGU General Assembly 2024, Vienna, Austria, 14–19 Apr 2024, EGU24-11043. https://doi.org/10.5194/egusphere-egu24-11043. [Download the poster](https://github.com/alexschimel/Espresso/files/14979881/EGU24_Espresso_poster.pdf)

## For developers

[See the 'For developers' section on the *CoFFee* page](https://github.com/alexschimel/CoFFee)

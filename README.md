![](https://github.com/alexschimel/Espresso/blob/master/Espresso_resources/banner.png)

# *Espresso* 

Multibeam water-column visualization and processing.

[![](https://github.com/alexschimel/Espresso/blob/master/Espresso_resources/download.png)](https://github.com/alexschimel/Espresso/releases/download/v1.2/espresso_v120_setup.exe)

[![Language](https://img.shields.io/badge/MATLAB-R2020b-orange)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/alexschimel/Espresso)](https://github.com/alexschimel/Espresso/releases)
[![Last Commit](https://img.shields.io/github/last-commit/alexschimel/Espresso)](https://github.com/alexschimel/Espresso/commits/master)
[![Docs](https://img.shields.io/badge/Docs-Wiki-blue)](https://github.com/alexschimel/Espresso/wiki)

[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/alexschimel)
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://paypal.me/alexschimel)

### Description

*Espresso* is a free and open-source app to visualize and process water-column data acquired by multibeam echosounders. The main feature of this tool is the possibility to vertically echo-integrate water-column data so as to visualize and examine acoustic anomalies "from above".

*Espresso* uses the [CoFFee multibeam data processing toolbox](https://github.com/alexschimel/CoFFee) (hence the name). It is coded in [MATLAB](https://www.mathworks.com/products/matlab.html), but is also available as a standalone application that does not require a MATLAB licence (see the [Dependencies](#dependencies) and [Installing](#installing) sections).

### Relevant features
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
* For the compiled executable:
  * [MATLAB Runtime v9.9](https://www.mathworks.com/products/compiler/matlab-runtime.html)
  * Note: if you install the app using the binary installer, the setup wizard will automatically detect whether you have the correct version of MATLAB Runtime installed and, if not, allow you to download and install it then.

### Installing

* For the source code: 
  * Clone this repository, as well as the repository of [*CoFFee*](https://github.com/alexschimel/CoFFee), with [git or a git client](https://git-scm.com/).
  * Note that a few files are managed with [git-lfs](https://git-lfs.com/) so you will need to have this installed before you clone this repository. Simply downloading the source code will not work since you will miss the files that require git-lfs.
* For the compiled executable: 
  * Preferably, [download the binary installer from the releases page](https://github.com/alexschimel/Espresso/releases), execute the installer, and follow the instructions of the setup wizard. The setup wizard will check if you have the appropriate version of MATLAB Runtime installed and, if not, let you download and install it. Note that the setup wizard requires an internet connection.
  * Alternatively, you can simply [download the binary executable and accompanying files from the releases page](https://github.com/alexschimel/Espresso/releases) and double-click the .exe file to run the application without installing it. Note that you still need to have the appropriate version of MATLAB Runtime installed.

### Executing program

* For the source code:
  * Start MATLAB, navigate to the root directory of the *Espresso* code, and type `Espresso` in the Command Window.
  * Note: The first time you run *Espresso* from the source code, you will be prompted to provide the location of a folder containing the *CoFFee* toolbox. *Espresso* will check if the version of that toolbox is the one with which the app was built. If the version of *CoFFee* is not the one expected, you will receive a warning message letting you know you might experience issues and recommending you download (or check out) the appropriate version.
* For the compiled executable:
  * Execute the installed program.
  * Note: The first time you run *Espresso* after installation, it might take a while for the app to appear. Be patient. It will be faster the next times.

Note: At start-up, *Espresso* creates an `Espresso` user folder (normally, C:\Users\USERNAME\Documents\Espresso). This folder contains a configuration file for the app, and is the default folder for any exports from the app. It is safe to delete this folder or any of its contents (although if you delete the configuration file, this will reset the app configuration).

## Help

### Documentation

Head over to the [wiki](https://github.com/alexschimel/Espresso/wiki) for documentation (in progress).

There is also [a playlist of tutorials on Alex Schimel's Youtube channel](https://youtube.com/playlist?list=PLWo0Tmonl7YAuzV8f2Zr39_zUw-wmLD_H&si=TG0jZskuOc-B-fOH) (in progress).

### Support

Unfortunately, there is little support available at present. If you experience any error or malfunctioning, please start with the [Issues](https://github.com/alexschimel/Espresso/issues) section. Search both open and closed Issues to see if your experience has already been addressed or reported. If you find a match, please comment on that Issue. [Create a new Issue](https://github.com/alexschimel/Espresso/issues/new) if your problem has not yet been reported. In both cases, provide as much information as possible (sonar model and data format, screenshots, sequence leading to the problem, etc.) and share the Espresso log showing the error. You can also send an example of raw data causing the problem to the [authors](#authors-and-contributors). Send the smallest files possible.

For more help, contact the [authors](#authors-and-contributors).

### Feature request

If you wish to suggest a new feature or enhancement, also use the [Issues](https://github.com/alexschimel/Espresso/issues) section. Search the current [Issues labeled "enhancement"](https://github.com/alexschimel/Espresso/issues?q=label%3Aenhancement) and react or comment to listed features and enhancements you wish to see, in order to improve their visibility. Otherwise, [create a new Issue](https://github.com/alexschimel/Espresso/issues/new) and apply the "enhancement" label.

### Past versions and updates

See the [releases](https://github.com/alexschimel/Espresso/releases) page for past released versions. 

If you want to receive notifications of future releases (recommended), click on 'Watch', then 'Custom', and choose 'Releases'. Verify in your GitHub settings that you are set to receive 'Watching' notifications.

## About

### Authors and contributors

* Alexandre Schimel (alex.schimel@proton.me)
* Yoann Ladroit (Kongsberg Discovery)
* Shyam Chand (The Geological Survey of Norway)

### Copyright

2017-2025
* Alexandre Schimel
* Yoann Ladroit (Kongsberg Discovery)
* The National Institute of Water and Atmospheric Research (NIWA), New Zealand

### License

The *Espresso* software and source code are distributed under the MIT License. See `LICENSE` file for details.

*Espresso* uses several pieces of third-party code, each being distributed under its own license. Each piece of code is contained in a separate sub-folder of the 'toolboxes' folder and includes the corresponding license file.

### Citation/Credit

If you use *Espresso*, please acknowledge the copyright holders: Alexandre Schimel, Yoann Ladroit (Kongsberg Discovery), and Sally Watson (NIWA). 

For citation, a dedicated article is in preparation. In the meantime, preferably cite [Schimel et al. (2024a)](https://doi.org/10.5194/egusphere-egu24-11043), [Turco et al. (2022)](https://doi.org/10.3389/feart.2022.834047), and [Porskamp et al. (2022)](https://doi.org/10.1002/lno.12160).

### Support This Project 💖

If you use *Espresso* in your research, teaching, or professional work, please consider supporting its development. Your support helps cover development time, MATLAB license costs, and ensures continued availability of free, open-source tools for multibeam sonar data analysis.

For **monthly support**, consider [sponsoring on GitHub](https://github.com/sponsors/alexschimel). For **one-time donations**, you can use [PayPal](https://paypal.me/alexschimel).

## See Also

### Apps based on CoFFee
* [*Espresso*](https://github.com/alexschimel/Espresso): Multibeam water-column visualization and processing
* [*Iskaffe*](https://github.com/alexschimel/Iskaffe): Multibeam backscatter quality control
* [*Grounds*](https://github.com/alexschimel/Grounds): Elevation Change Analysis

### References 

Articles about or using *Espresso*:
* Zainal, M. Z., Che Hasan, R., Abu Husain, M. K., Schimel, A. C. G., Mohd Zaki, N. A., & Zakariya, R. (2026). Improving the mapping of coral reefs with multibeam echosounder water column data. Estuarine, Coastal and Shelf Science, 332, 109744. https://doi.org/10.1016/j.ecss.2026.109744
* Berry, J., & Nanlal, C. (2025). Assessment of the application of each multibeam echosounder data product for monitoring of Laminaria digitata in the UK. Frontiers in Remote Sensing, 6. https://doi.org/10.3389/frsen.2025.1521958
* Bäcklin, V. (2025). Identification of gas seeps associated with fracture zones in the southwestern Baltic Sea using open-source software. Bachelor Thesis, Stockholm University.
* Schimel, A., Ladroit, Y., & Watson, S. (2024b). Espresso: An Open-Source Software Tool for Visualizing and Analysing Multibeam Water-Column Data. EGU General Assembly 2024, Vienna, Austria, 14–19 Apr 2024, EGU24-11043. https://doi.org/10.5194/egusphere-egu24-11043. [Download the poster](https://github.com/alexschimel/Espresso/files/14979881/EGU24_Espresso_poster.pdf)
* Schimel, A. C. G., Ladroit, Y., & Watson, S. (2024). Espresso: Open source software for the visualization of multibeam water column data. HYDRO International, 28(3), 22–25. [Link to online version of article](https://www.hydro-international.com/content/article/espresso-open-source-software-for-the-visualization-of-multibeam-water-column-data)
* Turco, F., Ladroit, Y., Watson, S. J., Seabrook, S., Law, C. S., Crutchley, G. J., Mountjoy, J., Pecher, I. A., Hillman, J. I. T., Woelz, S., & Gorman, A. R. (2022). Estimates of Methane Release From Gas Seeps at the Southern Hikurangi Margin, New Zealand. Frontiers in Earth Science, 10(March), 1–20. https://doi.org/10.3389/feart.2022.834047
* Porskamp, P., Schimel, A. C. G., Young, M., Rattray, A., Ladroit, Y., & Ierodiaconou, D. (2022). Integrating multibeam echosounder water‐column data into benthic habitat mapping. Limnology and Oceanography, 67(8), 1701–1713. https://doi.org/10.1002/lno.12160

## For developers

[See the 'For developers' section on the *CoFFee* page](https://github.com/alexschimel/CoFFee?tab=readme-ov-file#for-developers).

See additional information for compiling *Espresso* in [espresso_compile_readme.md](https://github.com/alexschimel/Espresso/blob/master/espresso_compile_readme.md).

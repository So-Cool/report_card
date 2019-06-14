# Report Card Generator for KnowRob OpenEase system #
This package extends functionality of KnowRob system with robot's *log analysis*, *data extraction* and *report card generation*. The details of the project are available [here][RCGblog] and the *wiki* [here][RCGwiki].

## Prerequisites ##
This package was developed and tested under Linux Ubuntu 14.04 *trusty* and given below installation instructions correspond to this operating system.

This package require the following dependencies:

- R
    * `r-base`
    * `r-base-dev`
- SWI Prolog (compiled with Java interface)
    * `swi-prolog`
    * `swi-prolog-java`
- LaTeX
    * `texlive-full`

moreover, `SWI-Prolog`'s [`real`][real] package is required.

## Package installation ##
First merge `report_card` package into your `catkin` workspace (given that your current directory is head of workspace)
``` bash
cd src
wstool merge "https://raw.githubusercontent.com/So-Cool/report_card/master/rosinstall"
wstool update
```

Now you can either install the dependencies either by hand or automatically.

### Manual (recommended) ###

``` bash
sudo apt-get install software-properties-common

sudo apt-add-repository ppa:swi-prolog/stable
sudo apt-get update
sudo apt-get install swi-prolog
sudo apt-get install swi-prolog-java

sudo add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/“
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo apt-get update
sudo apt-get install r-base
sudo apt-get install r-base-dev

sudo apt-get install texlive-full
```

The next step is to install `real` pack. Start SWI-Prolog with
``` bash
swipl
```

and do
``` prolog
pack_install(real).
```

and follow the instructions given on the screen.

### Automatic ###
To automatically install the above dependencies do
``` bash
rosdep install --ignore-src --from-paths ./report_card
```

This will install all system level dependencies. The `real` package is installed then based on instruction given in `CMake`.  
To make sure you have the latest releases of all dependencies you should first do
``` bash
sudo apt-get install software-properties-common
sudo add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/“
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo apt-add-repository ppa:swi-prolog/stable
sudo apt-get update
```

---

Finally, move back to your workspace and compile the package
``` bash
cd ..
catkin_make -DCATKIN_WHITELIST_PACKAGES="report_card"
```

This installation instruction assumes that you already have a working catkin workspace and you just wish to add `report_card` package to it. If you want to do a full installation of catkin together with the package please refer to instructions given [here][catkin].

## Basic usage ##
To run the package do
``` bash
rosrun rosprolog rosprolog report_card
```

and within Prolog
``` prolog
%% Load an experiment log
load_experiment('path/to/log/file.owl').
%% Generate basic report card
generate_report_card.
```

More details are available in the project documentation.

## TODO ##
- [ ] Create a wiki page for the project `http://wiki.ros.org/report_card`.
- [ ] Generate the documentation for the project.
- [ ] Write a user guide for the project.
- [ ] Include in the readme how to report bugs (error output and a compressed directory).

[RCGblog]: http://So-Cool.github.io/ReportCardGenerator/
[RCGwiki]: http://wiki.ros.org/report_card
[real]:    http://www.swi-prolog.org/pack/list?p=real
[catkin]:  http://So-Cool.github.io/ReportCardGenerator/2015/05/29/development/

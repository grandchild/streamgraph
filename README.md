# StreamGraph

**StreamGraph** is a graphical programming frontend to [**StreamIt**](http://groups.csail.mit.edu/cag/streamit/index.shtml), a streaming application programming language and compiler designed for

> efficient and effective mapping to a wide variety of target architectures, including commercial-off-the-shelf uniprocessors, multicore architectures, and clusters of workstations

**StreamGraph** is designed to provide a convenient graphical representation and editing environment for *StreamIt* code by removing some of the complexity inherent in the concepts of *StreamIt*.

Notably it:
* alleviates the need for explicit definition of *Pipelines* and *Splitjoins*
* facilitates the creation and editing of *Filters* and *connections* between components
* and makes the flow of the datastream more visible.

## Contents
* [Prerequisites](#prerequisites)
 + [StreamGraph](#streamgraph-1)
 + [Java 1.5](#java-15)
 + [Streamit](#streamit)
 + [Perl Packages](#perl-packages)
 + [Configuration](#configuration)
 + [Result](#result)
* [Starting StreamGraph](#starting-streamgraph)

## Prerequisites

###### StreamGraph
* [Download](https://gitlab.tubit.tu-berlin.de/streamgraph/streamgraph/repository/archive.zip?ref=master) or [git-clone](https://gitlab.tubit.tu-berlin.de/streamgraph/streamgraph.git) the latest version of this repository and extract it anywhere you like. This location will be referred to as `streamgraph/`.

The rest of the downloads (*Java 5* & *Streamit*) can be downloaded/extracted into that directory (it's not mandatory though).


###### Java 1.5
*StreamIt* is old software and needs a version 5 JDK.
* In Arch-Linux-based distributions you can install [`jdk5`](https://aur.archlinux.org/packages/jdk5/) from the AUR. Don't set it as default Java version, just use the location `/usr/lib/jvm/java-5-jdk/` when configuring below.
* For other distributions download Java 5 via these `curl` commands. Choose the 64- or 32bit download.
```
curl -b oraclelicense=a -LO http://download.oracle.com/otn-pub/java/jdk/1.5.0_22/jdk-1_5_0_22-linux-amd64.bin
curl -b oraclelicense=a -LO http://download.oracle.com/otn-pub/java/jdk/1.5.0_22/jdk-1_5_0_22-linux-i586.bin
```
(Note that the `-b ...` flag implies that you accept the [Oracle Binary Code License Agreement](http://www.oracle.com/technetwork/java/javase/downloads/java-se-archive-license-1382604.html)!)

Run the downloaded file and the JDK will self-extract after you accept its license. The resulting location will be referred to as `jdk1.5.0_22/`.

###### Streamit
* Download the [*StreamIt* binary release](http://groups.csail.mit.edu/cag/streamit/restricted/streamit-2.1.1.tar.gz) and extract the containing folder. This location will be referred to as `streamit-2.1.1/`.

* Since the *StreamIt* "binary" release isn't actually all binary, you still have to build some of it—and patch it first (edit the paths!):
  ```bash
cd streamit-2.1.1
patch -p0 -i streamgraph/streamit-build/streamit211-fix-init_instance-save_state.patch
export JAVA=jdk1.5.0_22/bin/java
export STREAMIT_HOME=/streamit-2.1.1/ # This path needs to be ABSOLUTE!
./configure
make CFLAGS='-fpermissive -O2 -I.' # Add -fpermissive flag
```

Note that *StreamGraph* doesn't actually use *StreamIt*'s `streamit-2.1.1/strc` compiler perl script, but a slightly customized version, located at `streamgraph/source/resources/sgstrc`.

###### Perl Packages
You will need to install the following perl packages:

| Module         | Debian Package        | Arch Package       |
| :------------: | :-------------------: | :----------------: |
| Gtk2           | libgtk2-perl          | gtk2-perl          |
| Gnome2::Canvas | libgnome2-canvas-perl | gnomecanvas-perl   |
| Graph          | libgraph-perl         | perl-graph *(AUR)* |
| Glib           | libglib-perl          | glib-perl          |
| Moo            | libmoo-perl           | perl-moo           |
| GraphViz       | libgraphviz-perl      | perl-graphviz      |
| YAML           | libyaml-perl          | perl-yaml          |


* Debian: `libgtk2-perl libgnome2-canvas-perl libgraph-perl libglib-perl libmoo-perl libgraphviz-perl libyaml-perl`
* Arch: `gtk2-perl gnomecanvas-perl perl-graph glib-perl perl-moo perl-graphviz perl-yaml`

###### Configuration
* Create a file at `streamgraph/source/streamgraph.conf` and fill in the absolute paths to the locations you created above so the file looks like this (`---` must be included):
  ```yaml
---
java_5_dir: 'jdk1.5.0._22'
streamit_home: 'streamit-2.1.1'
```

  + (Alternatively you can just start *StreamGraph* at this point and it will create an empty configuration in the right place for you. *StreamGraph* will run, but it will not compile with *StreamIt* until you fill in the paths.)

###### Result
Your *StreamGraph* directory might look somewhat like this now:
```
streamgraph
├── jdk1.5.0_22
├── streamit-2.1.1
├── streamit-build
├── source
│   ├── bin
│   │   └── helloworld.pl
│   ├── lib
│   ├── helloworld.sigraph
│   ├── streamgraph.conf
│   └── ...
├── doc
├── README.md
└── ...
```

## Starting StreamGraph
```bash
cd streamgraph/source/
perl bin/helloworld.pl helloworld.siggraph
```

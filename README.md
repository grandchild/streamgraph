# StreamGraph

![Preview](https://raw.github.com/grandchild/streamgraph/master/doc/demoPower.png)

**StreamGraph** is a graphical programming frontend to [**StreamIt**](http://groups.csail.mit.edu/cag/streamit/index.shtml), a streaming application programming language and compiler designed for

> efficient and effective mapping to a wide variety of target architectures, including commercial-off-the-shelf uniprocessors, multicore architectures, and clusters of workstations

**StreamGraph** is designed to provide a convenient graphical representation and editing environment for *StreamIt* code by removing some of the complexity inherent in the concepts of *StreamIt*.

Notably it:
* alleviates the need for explicit definition of *Pipelines* and *Splitjoins*
* facilitates the creation and editing of *Filters* and *connections* between components
* and makes the flow of the datastream more visible.

## Installation
Refer to [Install.md](doc/Install.md) in the `doc` directory for instructions on how to install StreamGraph.

## Starting StreamGraph
```bash
cd streamgraph/source/
perl bin/streamgraph.pl helloworld.siggraph
```
![Preview](https://raw.github.com/grandchild/streamgraph/master/doc/streamgraph.png)

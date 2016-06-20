### Location of unpacked StreamIt tree
STREAMIT_HOME=$HOME/dev/streamit/streamit-2.1.1

### Location of ANTLR jar file (test: 'java antlr.tool')
# ANTLRJAR=/usr/share/java/antlr.jar
ANTLRJAR=$HOME/dev/streamgraph/streamit-build/antlr.jar

### Update CLASSPATH
CLASSPATH=.:${CLASSPATH}
CLASSPATH=${CLASSPATH}:${ANTLRJAR}
CLASSPATH=${CLASSPATH}:${STREAMIT_HOME}/streamit.jar

### Update the shell path
PATH=${PATH}:${STREAMIT_HOME}

export STREAMIT_HOME CLASSPATH PATH

cd $STREAMIT_HOME
echo $STREAMIT_HOME

./configure
make

#!/bin/bash

currentBranch=$(git rev-parse --abbrev-ref HEAD)
echo "will compare the branch ${currentBranch}"
mvn clean install pitest:scmMutationCoverage -DoriginBranch=$currentBranch -DdestinationBranch=origin/master

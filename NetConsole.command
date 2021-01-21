#!/bin/bash

cd "`dirname "$0"`"
xcrun --sdk macosx swift run NetConsole $@

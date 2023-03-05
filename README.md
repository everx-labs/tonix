# **Tonix**

* A set of libraries with assorted helper functions for system smart-contract development

## Pre-requisites

    make: GNU make 4.2.1 or newer
    jq 1.6 or newer
    wget (for "tools" target)

## Installation steps

    make tools: installs TON Solidity compiler and associated binaries

## Components

* opt:         optional packages
* opt/core:    PoC coreutils
* opt/dev:     disassembly
* opt/shell:   PoC shell
* usr:         user utilities and libraries
* usr/include: header files
* usr/src/lib: libraries

To build an optional component:

```shell
cd opt/<component>
make
```

### `opt/mesh` example user interface for smart contract

```shell
cd opt/mesh
make
bash me.sh
```

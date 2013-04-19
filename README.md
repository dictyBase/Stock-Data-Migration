# Stock Data Migration
Migration of stock (strain & plasmid) data from legacy schema to standard [Chado](http://gmod.org/wiki/Chado_Tables)

[![Build Status](https://secure.travis-ci.org/dictyBase/Stock-Data-Migration.png?branch=develop)](https://travis-ci.org/dictyBase/Stock-Data-Migration)

### Background
_TODO_

### Data components

```text
stock
	|- strain
		|- strain, inventory, genotype, phenotype, cvterm, pub, orders

	|- plasmid
		|- plasmid, inventory, genotype, phenotype

phenotype
```

### Data Models

1. [stock inventory](data/models/stock_inventory.md)

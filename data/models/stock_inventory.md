## Data model for stock inventory

### Rationale
Inventory is not a biological property of a `stock`. One `stock` can have multiple inventories. In our case, the maximum inventories a `stock` has is 5. `stockcollection` is the stock center which dictributes the stock(strains). In our case, we have only one `stockcollection` - _'dicty stock center'_. [Chado](http://gmod.org/wiki/Chado_Tables#Table:_stock) schema does not directly support storing inventory data.  

### Data Models
We propose 2 models to store the inventory data in Chado schema.
	1. Inventory is the property of the `stockcollection`
	2. Inventory is the property of the `stock`

#### Model-1


#### Model-2

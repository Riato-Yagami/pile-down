class_name DataCatalog
extends Resource

## Definitions enabled by the game, in their intended presentation/runtime order.
@export var enabled_data: Array[Data] = []


func all() -> Array[Data]:
	return enabled_data.duplicate()

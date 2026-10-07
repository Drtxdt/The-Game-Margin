class_name SaveData
extends RefCounted

const VERSION=1

static func fresh() -> Dictionary:
	return {"version":VERSION,"flags":{},"bound":[],"held":[],"major":"physics","san_max":Balance.ORIGINAL_SANITY,"san":Balance.ORIGINAL_SANITY,"hp":Balance.MAX_HEALTH,"checkpoint":"gate","checkpoint_pos":[150.0,570.0],"visited":[],"echoes":{},"deaths":[],"seconds":0.0,"notes":[],"completed":false}

static func number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func pair(value: Variant) -> bool:
	return value is Array and value.size()==2 and number(value[0]) and number(value[1])

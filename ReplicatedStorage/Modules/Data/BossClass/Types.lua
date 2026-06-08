local Types = {}

export type Boss = {
	boss_name: string,
	health: number,
	hp_scale: number,
	max_health: number,
	speed: number,
	area: string,
	phase: number,
	transformed_health: number,
	level: number,
	maid: any,
	model: Model?,
	engine: any,
	
	onHealthChange: (Boss) -> () | nil;
}

return Types
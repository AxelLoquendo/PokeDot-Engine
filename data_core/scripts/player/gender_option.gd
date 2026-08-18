extends Resource

class_name GenderOption  
  
@export var boy_id: EventObjects.PlayerID = EventObjects.PlayerID.OBJ_EVENT_GFX_RED_FRLG  
@export var neutral_id: EventObjects.PlayerID = EventObjects.PlayerID.NONE  
@export var girl_id: EventObjects.PlayerID = EventObjects.PlayerID.OBJ_EVENT_GFX_LEAF_FRLG  
  
func resolve(gender: int) -> EventObjects.PlayerID:  
	match gender:  
		0: return boy_id  
		1: return girl_id  
	return EventObjects.PlayerID.NONE

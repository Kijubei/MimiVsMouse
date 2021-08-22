extends StaticBody

export var color = Color(0.15, 0.39, 0.45, 1)

onready var mesh = $MeshInstance

func _ready():
#	mesh.get_surface_material(0).albedo_color = color
	var material = SpatialMaterial.new()
	material.albedo_color = color
	mesh.set_surface_material(0, material)

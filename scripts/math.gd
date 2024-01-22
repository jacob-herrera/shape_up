extends Node

func perpendicular_vector(input: Vector3) -> Vector3:
	var output := Vector3.ZERO
	var v3max = input.max_axis_index()
	var v3min = input.min_axis_index()
	
	output[v3max] = input[v3min]
	output[v3min] = -input[v3max]
	
	return output.normalized()

func random_point_in_circle(radius: float, exponent: float = 0.5) -> Vector3:
	var output := Vector3.ZERO
	var random := RandomNumberGenerator.new()
	var direction := random.randf_range(-PI, PI)
	# default exponent should make the distribution equal over the area instead of equal over the radius (i.e. biased towards center)
	var deviation := deg_to_rad(pow(random.randf_range(0.0, 1.0), exponent) * radius)
	
	# returns XY coordinate of an unit circle and Z as the radius in case you'd ever need to work with the components separately
	output = Vector3(cos(direction), sin(direction), deviation)
	
	return output

func random_unit_vector_in_cone(input: Vector3, angle: float) -> Vector3:
	angle = clamp(angle, 0.0, 89.0)
	var output := Vector3.ZERO
	
	# generate vectors perpendicular to the forward vector (spread plane)
	var forward := input
	var right := perpendicular_vector(input)
	var up := forward.cross(right)
	
	# pick a point within a circle
	var offset = random_point_in_circle(angle)
	
	# create a vector towards the point above
	output = \
		forward + \
		right * offset.x * tan(offset.z) + \
		up * offset.y * tan(offset.z)
	
	return output

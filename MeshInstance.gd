extends MeshInstance


export(SpatialMaterial) var material = null
var elev_data = []


func calc_surface_normal(vert1, vert2, vert3): # calculate a normal using 3 vertices
	var U = (vert2 - vert1)
	var V = (vert3 - vert1)

	var x = (U.y * V.z) - (U.z * V.y)
	var y = (U.z * V.x) - (U.x * V.z)
	var z = (U.x * V.y) - (U.y * V.x)

	return Vector3(x, y, z).normalized()



func calc_surface_normal_newell_method(vert_arr): # Newell's Method of calculating normals
	var normal = Vector3(0, 0, 0)

	var curr_vert = Vector3()
	var next_vert = Vector3()
	for i in range(0, vert_arr.size()):
		curr_vert = vert_arr[i]
		next_vert = vert_arr[(i + 1) % vert_arr.size()]

		normal.x = normal.x + ((curr_vert.y - next_vert.y) * (curr_vert.z + next_vert.z))
		normal.y = normal.y + ((curr_vert.z - next_vert.z) * (curr_vert.x + next_vert.x))
		normal.z = normal.z + ((curr_vert.x - next_vert.x) * (curr_vert.y + next_vert.y))

	return normal.normalized()


func lla_to_xyz(lon, lat, alt): # Lon Lat Alt to x y z converter.
	var cosLat = cos(deg2rad(lat))
	var sinLat = sin(deg2rad(lat))
	var cosLon = cos(deg2rad(lon))
	var sinLon = sin(deg2rad(lon))
	var rad = 50.0 + alt;
	var x = rad * cosLat * cosLon
	var y = rad * sinLat
	var z = rad * cosLat * sinLon
	return Vector3(x, y, z)


func get_elev_data(x, y): # get elevation data using coordinates
	if x > 359:
		x -= 360
	if y > 179:
		y -= 180
	return elev_data[x][y]


func _ready():
	var img = Image.new()
	img.load('res://Resources/heightmap.png')
	img.lock()

	for x in range(360):
		elev_data.append([])
		for y in range(180):
			var alt = img.get_pixel(x, y).gray() * 10
			elev_data[x].append(alt)

	img.unlock()


	var surftool = SurfaceTool.new()

	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surftool.set_material(material)
	var vert1 = Vector3()
	var vert2 = Vector3()
	var vert3 = Vector3()
	var vert4 = Vector3()
	var normal0 = Vector3()
	var normal1 = Vector3()
	var normal2 = Vector3()
	var normal3 = Vector3()

	for x in range(-180, 180):
		for y in range(-90, 90):
			var corner0 = lla_to_xyz(x + 1, y    , get_elev_data(x+181, y+90))
			var corner1 = lla_to_xyz(x + 1, y + 1, get_elev_data(x+181, y+91))
			var corner2 = lla_to_xyz(x    , y + 1, get_elev_data(x+180, y+91))
			var corner3 = lla_to_xyz(x    , y    , get_elev_data(x+180, y+90))

			if y < 91 and y > 88:
				normal0 = Vector3(0, 1, 0)
				normal1 = Vector3(0, 1, 0)
				normal2 = Vector3(0, 1, 0)
				normal3 = Vector3(0, 1, 0)
			elif y < -88 and y > -91:
				normal0 = Vector3(0, -1, 0)
				normal1 = Vector3(0, -1, 0)
				normal2 = Vector3(0, -1, 0)
				normal3 = Vector3(0, -1, 0)
			else:
				vert1 = lla_to_xyz(x + 2, y - 1, get_elev_data(x+180+2, y+90-1))
				vert2 = lla_to_xyz(x + 2, y + 1, get_elev_data(x+180+2, y+90+1))
				vert3 = lla_to_xyz(x + 0, y + 1, get_elev_data(x+180+0, y+90+1))
				vert4 = lla_to_xyz(x + 0, y - 1, get_elev_data(x+180+0, y+90-1))
				normal0 = -calc_surface_normal_newell_method([vert1, vert2, vert3, vert4])
				vert1 = lla_to_xyz(x + 2, y + 0, get_elev_data(x+180+2, y+90+0))
				vert2 = lla_to_xyz(x + 2, y + 2, get_elev_data(x+180+2, y+90+2))
				vert3 = lla_to_xyz(x + 0, y + 2, get_elev_data(x+180+0, y+90+2))
				vert4 = lla_to_xyz(x + 0, y + 0, get_elev_data(x+180+0, y+90+0))
				normal1 = -calc_surface_normal_newell_method([vert1, vert2, vert3, vert4])
				vert1 = lla_to_xyz(x + 1, y + 0, get_elev_data(x+180+1, y+90+0))
				vert2 = lla_to_xyz(x + 1, y + 2, get_elev_data(x+180+1, y+90+2))
				vert3 = lla_to_xyz(x - 1, y + 2, get_elev_data(x+180-1, y+90+2))
				vert4 = lla_to_xyz(x - 1, y + 0, get_elev_data(x+180-1, y+90+0))
				normal2 = -calc_surface_normal_newell_method([vert1, vert2, vert3, vert4])
				vert1 = lla_to_xyz(x + 1, y - 1, get_elev_data(x+180+1, y+90-1))
				vert2 = lla_to_xyz(x + 1, y + 1, get_elev_data(x+180+1, y+90+1))
				vert3 = lla_to_xyz(x - 1, y + 1, get_elev_data(x+180-1, y+90+1))
				vert4 = lla_to_xyz(x - 1, y - 1, get_elev_data(x+180-1, y+90-1))
				normal3 = -calc_surface_normal_newell_method([vert1, vert2, vert3, vert4])

			# bottom left
			surftool.add_normal(normal0)
			surftool.add_vertex(corner0)

			# top left
			surftool.add_normal(normal1)
			surftool.add_vertex(corner1)

			# top right
			surftool.add_normal(normal2)
			surftool.add_vertex(corner2)

			# bottom right
			surftool.add_normal(normal3)
			surftool.add_vertex(corner3)

			# bottom left
			surftool.add_normal(normal0)
			surftool.add_vertex(corner0)

			# top right
			surftool.add_normal(normal2)
			surftool.add_vertex(corner2)

			surftool.index()

	self.set_mesh(surftool.commit())

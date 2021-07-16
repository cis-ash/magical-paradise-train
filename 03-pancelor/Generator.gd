extends Node2D

var dev
var dev_showhint

onready var map=$"../State/NavdiBoardTileMap"
onready var player=$"../player"
onready var cheese=$"../cheese"

var debug_font

export(int)var ICE_TILE=10
export(int)var FLOOR_TILE=12
export(int)var WALL_TILE=11 # probably want to just check .solid somehow?
#const ymin=-7
#const ymax=6
#const xmin=-8
#const xmax=7
const ymin=-10
const ymax=9
const xmin=-10
const xmax=9
const dirx=[-1,1,0,0]
const diry=[0,0,-1,1]
var reachable={} # a mapping: cell => min distance
var rng=0

func _ready():
	dev=true
#	dev_showhint=dev
#	rng=13
	
	if dev:
		debug_font = Control.new().get_font("font")
	randomize()
	generate()

func _process(_delta):
	if dev:
		dev_process()

func dev_process():
	if Input.is_action_just_pressed("ui_focus_next"):
		dev_showhint=not dev_showhint
		update()

	var delta=0
	if Input.is_action_just_pressed("ui_home"):
		delta-=1
	if Input.is_action_just_pressed("ui_end"):
		delta+=1
	if delta!=0:
		rng+=delta
		print("seed ",rng)
		generate(rng)
		
func randi_range(a,b):
	return int(randf()*(b-a)+a)

#func rand_loc():
#	var x=randi_range(xmin+1,xmax)
#	var y=randi_range(ymin+1,ymax)
#	return Vector2(x,y)
	
func generate(rng_seed=null):
	if rng_seed:
		seed(rng_seed)
		
	var unused_cells=[]
	# fill center with ice
	for y in range(ymin+1,ymax-1+1):
		for x in range(ymin+1,ymax-1+1):
			map.set_cell(x,y,ICE_TILE)
			unused_cells.append(Vector2(x,y))
	# L/R walls
	for y in range(ymin,ymax+1):
		map.set_cell(xmin,y,WALL_TILE)
		map.set_cell(xmax,y,WALL_TILE)
	# U/D walls
	for x in range(xmin,xmax+1):
		map.set_cell(x,ymin,WALL_TILE)
		map.set_cell(x,ymax,WALL_TILE)
	
	unused_cells.shuffle()
	reachable.clear()
	var start=unused_cells.pop_back()
	map.set_cellv(start,FLOOR_TILE)
	player.set_start_cell(start)

	var max_dist=6
	var should_finish=false
	var i=0
	while true:
		i+=1
		if i>=100 or unused_cells.size()<3: # sentinel, trips decently often
			print("could not generate; doing fallback")
			max_dist=0
			should_finish=true
			for c in reachable:
				max_dist=max(max_dist,reachable[c])
			
		# maybe break if complex enough
		var far_locs=[]
		for c in reachable:
			if reachable[c]>=max_dist:
				far_locs.append(c)
				if far_locs.size()>10:
					should_finish=true
#		print(i," ",far_locs.size())
		if should_finish:
			print("generating after %d try(s)"%i)
			cheese.set_cell(choose(far_locs))
			break
		# not done yet; change the board and try again
		map.set_cellv(unused_cells.pop_back(),FLOOR_TILE)
		map.set_cellv(unused_cells.pop_back(),WALL_TILE)
		map.set_cellv(unused_cells.pop_back(),WALL_TILE)
		reachable=explore(start)
	update()

func choose(a:Array):
	var ix=randi_range(0,a.size())
	return a[ix]
	
func explore(start: Vector2):
	# data holders for the algorithm
	var mindist={}
	var next_dist=0
	var now_queue # queue of reachable places in dist steps
	var next_queue=[]
	
	# prime the pump
	next_queue.append(start)
	mindist[start]=next_dist
	
	while next_queue.size()>0:
		next_dist+=1
		now_queue=next_queue
		next_queue=[]
		while now_queue.size()>0:
			var loc_template=now_queue.pop_back()
			
			assert(loc_template in mindist)
			# try moving in each direction
			for b in range(4):
				var dx=dirx[b]
				var dy=diry[b]
				var loc=Vector2(loc_template)
				var loc_to_enqueue
				while loc_to_enqueue==null:
					var next_loc=loc+Vector2(dx,dy)
					var next_tile=map.get_cellv(next_loc)
					if next_tile==WALL_TILE:
						loc_to_enqueue=loc
					elif next_tile==FLOOR_TILE:
						loc_to_enqueue=next_loc
					elif next_tile==ICE_TILE:
						loc=next_loc
					else:
						assert(false,"bad tile %d"%next_tile)
				if not loc_to_enqueue in mindist:
					# guaranteed to be the minimum distance b/c 
					# this is BFS and this is the first time
					# we've seen it
					next_queue.append(loc_to_enqueue)
					mindist[loc_to_enqueue]=next_dist
	return mindist
	
func _draw():
	if not dev_showhint:
		return
	var red=Color(1,0,0,0.25)
	for c in reachable:
		var center=map.map_to_center(c)
		var dist = reachable[c]
		draw_rect(Rect2(center.x-2,center.y-2,4,4),red)
		draw_string(debug_font, center, str(dist))
	






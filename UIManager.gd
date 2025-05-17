func show_splash():
	$Splash.visible = true
	$Game.visible = false

func start_game():
	$Splash.visible = false
	$Game.visible = true
	get_node("/root/Spawner").reset()
	get_node("/root/Board").reset()

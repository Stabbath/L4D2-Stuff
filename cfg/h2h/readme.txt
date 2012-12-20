Head to head is a fun competitive config built around the basic idea of cutting out all the randomness of L4D2 AI. How? By removing nearly all forms of it.

Main features:
-	No commons outside of boomer hordes. A few events are buggy though, and so a very small number of them (like 8) can spawn at the beginning regardless.
-	No witch.
-	No SI bots, not even when you get tank.
-	No AI tanks. They will instantly die if the tank goes AI, unless it was because of the player disconnecting.
-	Tank only gets LOS rage within 1300 game units of survivors. To put it in visual terms, on dark carni 1, it’s approx. the distance from the fence behind the survivor spawn to the hood of the first cab.
-	Tank gets 35 seconds of grace before frustration loss, followed by 2 bars of 15 seconds.
-	Tank can select which type of rock to throw (thanks to vintik for his plugin):
	-	Shove: Two-handed overhead
	-	Shove+Reload: Overhand
	-	Shove+Use: Underhand
-	Spawn timers are set to 8 seconds.
-	Pickups take 3.5 seconds instead of 5.
-	Uses damage scoring.
-	Custom map distances to hopefully reflect the difficulty of maps with a lot less commons.
-	The duration of boomer vomits is reduced to 75%.
-	The cooldown on the boomer’s vomit is reduced to 50%.
-	Spawn sack order is 100% reliable.
-	SI get their ghosts a couple of seconds earlier.
-	Minimum time between common infected hits registering lowered to 0.25 from 0.33.

Everything else is standard promod.

Note: Finales, being horde-free like everything else, will essentially consist of SI hits on the way to the end, and each finale’s respective 1-3 tanks. Also usually time for a hit in between each tank on classic finales.

Version History:
1.0: Released.
1.0.1:
	- boomer_mobs_amount_mult set to 0.9 from 1.0 (decreasing amount of common from a boomer horde)
	- increased z_throttle_hit_interval_normal to 0.25 from 0.2
	- spawn time reduced to 8 seconds from 11
	- z_frustration_spawn_delay increased to 50 from 35
	- z_frustration_lifetime increased to 18 from 15
To-do:
	- make sure spawn sack order is working, need to spectate a game and write everything down and shit
	- more balance/difficulty testing
	- map distances good?
	- make sure players know that they are getting early ghosts: make sure they still have a timer (might have to add one and show via hint messages), or at least have a hint message telling them what's happening or something
	- make sure tank attack control is working
	//
	
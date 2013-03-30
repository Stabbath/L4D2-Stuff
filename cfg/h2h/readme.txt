Head to head is a fun competitive config built around the basic idea of cutting out all the randomness of L4D2 AI. How? By removing nearly all forms of it.

Main features:
-	No commons outside of boomer hordes. A few events are buggy though, and so a very small number of them (like 8) can spawn at the beginning regardless.
-	No witch.
-	No SI bots, not even when you get tank.
-	No AI tanks. They will instantly die if the tank goes AI, unless it was because of the player disconnecting.
-	Tank can select which type of rock to throw (thanks to vintik for his plugin):
	-	Shove: Two-handed overhead
	-	Shove+Reload: Overhand
	-	Shove+Use: Underhand
-	Spawn timers are set to 8 seconds.
-	When the tank spawns and for the whole tank fight, spawn timers will be set to 17 seconds. When the tank dies they'll be set back to 8.
-	Pickups take 3 seconds instead of 5.
-	Players start with 1 medkit each.
-	Medkits take 3 seconds instead of 5.
-	The duration of boomer vomits is reduced to 75%.
-	The cooldown on the boomer’s vomit is reduced to 50%.
-	The size of boomer mobs is reduced to 75%.
-	Uses damage scoring.
-	Custom map distances to hopefully reflect the difficulty of maps with a lot less commons.

Things that are broken:
-	Spawn sack order is 100% reliable.

To-do:
 	- change standardised_spawns since i forgot there always has to be at least 1 boomer/spitter which affects spawns
	- more balance/difficulty testing
	- map distances good?
	- tank rock selection bugged?
	
	- add melee_control with default damage settings
	- use controlled rage gains on extended tank control when that's been coded


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
1.0.2:
	- removed pre-spawn ghosts
	- added tank fight spawn timer toggling: made tank fights normal (promod) again, with normal spawn timers and normal LOS range and frustration
	- spawn timers revert back to 8 seconds when tank dies
	- los range still capped, but at 2500 now instead of 1300
	- boomer_mobs_amount_mult set to 0.75 from 0.9
	- set z_throttle_hit_interval_normal back to 0.33 (default) from 0.25
1.0.3:
	- disabled tank los range
	- added giving of 1 medkit per player on leaving saferoom
	- first_aid_kit_use_duration set to 3 seconds from 5 (default)
	- survivor pickup time reduced to 3 seconds from 3.5 
	

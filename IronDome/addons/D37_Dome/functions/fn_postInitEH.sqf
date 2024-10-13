if(!isServer) exitWith {};

addMissionEventHandler ["ProjectileCreated", {
	params ["_projectile"];

	[_projectile, civilian] spawn IRON_DOME37_fnc_initshells;
}];

//https://github.com/Dankan37/Arma-3-Iron-Dome/issues/2
//Thanks to wersal454
addMissionEventHandler ["ArtilleryShellFired", {
	params ["_vehicle", "_weapon", "_ammo", "_gunner", "_instigator", "_artilleryTarget", "_targetPosition", "_shell"];

	//Store the shell side 
	_shell setVariable ["_shellSide", side _gunner, true];
}];
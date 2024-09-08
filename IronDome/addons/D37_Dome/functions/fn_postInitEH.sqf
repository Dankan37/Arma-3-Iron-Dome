if(!isServer) exitWith {};

addMissionEventHandler ["ProjectileCreated", {
	params ["_projectile"];

	[_projectile] spawn IRON_DOME37_fnc_initshells;
}];
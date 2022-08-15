//Optimized version of the shells initialization script 
private _entities = param[0];

private _initializedShells = missionNamespace getVariable ["_initializedShells", []];
private _outArray = _initializedShells;
{
	//Placed here because two crams may initialize the same entity twice
	if(_x in _initializedShells) then {continue};
	_outArray pushback _x;
	
	_x spawn {
		_x = _this;
		_isCruiseMissile = _x isKindOf "ammo_Missile_CruiseBase";

		//Detection loop
		while {alive _x} do {
			//Needs this quick! 
			_entities = [];
			isNil {
				_entities = (_x nearObjects ["BulletBase", 5]);
				_entities append (_x nearObjects ["MissileBase", 30]);
			};

			if(_isCruiseMissile) then {
				_entities = _entities select {!(_x isKindOf "ammo_Missile_CruiseBase")};
			};
		
			if(count _entities > 0) then {
				_mine = createMine ["APERSMine", getPosATL _x, [], 0];
				_mine setDamage 1;

				//systemChat (str _x + " was destroyed!");

				//Cleanup
				["_targetedShells", _x, "remove"] call IRON_DOME37_fnc_handleTargets;
				["_initializedShells", _x, "remove"] call IRON_DOME37_fnc_handleTargets;
				deletevehicle _x;
			};
			sleep 0.04; //Assuming the missile flies at 2000m/s a radious of 40 meters needs a 0.04 seconds resolution
		};
	};
}foreach _entities;

missionNamespace setVariable ["_initializedShells", _outArray];
true;
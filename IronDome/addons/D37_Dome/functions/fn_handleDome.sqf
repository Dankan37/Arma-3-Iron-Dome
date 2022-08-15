_unit       = param[0];
_distance   = param[1, 4500];
_tgtLogic 	= param[2, 1];
//Speed, guidance, N, ignore direct, time to max, delay between shots
_weaponPar	= param[3, [420/3.6, 0, 4, false, 14, 1]];
_typeArray 	= param[4, ["ShellBase","RocketBase","MissileBase","SubmunitionBase"]];
_ignored	= param[5, ["MissileBase"]];



//Stops previous dome script, starts new one
_unit setVariable ["DomeInit", false, true];
waitUntil {(_unit getVariable ["DomeRunning", false]) == false};
_unit setVariable ["DomeInit", true, true];

//Save values
_unit setVariable ["WeaponsPar", _weaponPar];
_unit setVariable ["DomeRunning", true];

if(!isServer) exitWith {};

//Chase camera behind the missile 
allowAttach = false;
//Handle the missile
_unit addEventHandler ["Fired", {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
	_target = _unit getVariable ["currentTarget", objNull];
	if(isNull _target) exitWith {};

	_parameters = _unit getVariable "WeaponsPar";
	[_projectile, _target, _parameters] spawn IRON_DOME37_fnc_guidanceLaws;
	if(allowAttach) then {
			_projectile spawn {
			allowAttach = false;

			_cam = "camera" camCreate (ASLToAGL eyePos player);
			_cam attachTo [_this, [3,-15,0]];
			_cam cameraEffect ["external", "back"];
			_cam camCommitPrepared 0;
			waitUntil { camCommitted _cam };


			waitUntil {!alive _this};
			_cam cameraEffect ["terminate", "back"];
			camDestroy _cam;
			allowAttach = true;
		};
	};
}];

//_unit setVehicleRadar 1;
_unit setVariable ["alarmEnabled", false];
//Toggle incoming alarm
_unit addAction ["Toggle alarm", {
	params ["_target", "_caller", "_actionId", "_arguments"];
	_state = !(_target getVariable ["alarmEnabled", true]);
	_target setVariable ["alarmEnabled", _state];

	_out = "";
	if(_state) then {
		_out = "ON";
	} else {
		_out = "OFF";
	};

	_id = owner _caller;
	["Alarm state: " + _out] remoteExec ["hint", _id];

}, nil, 9, false, false, "", "!(_this in _target)", 10];

//Change logic
_unit setVariable ["_tgtLogic", _tgtLogic];
_unit addAction ["Change targeting mode", {
	params ["_target", "_caller", "_actionId", "_arguments"];
	_tgtLogic = _target getVariable ["_tgtLogic", 0];

	_tgtLogic = _tgtLogic + 1;
	if(_tgtLogic > 3) then {
		_tgtLogic = 0;
	};

	_out = "";
	switch (_tgtLogic) do {
		case 0: {
			_out = "Random selection";
		};
		case 1: {
			_out = "Distance/Speed bias";
		};
		case 2: {
			_out = "Threat bias";
		};
		default {_out = "No targeting"};
	};

	_id = owner _caller;
	["Logic changed to: " + _out] remoteExec ["hint", _id];

	_target setVariable	["_tgtLogic", _tgtLogic];
}, nil, 10, false, false, "", "!(_this in _target)", 10];

//Makes it better 
{
	_x setSkill 1;
}foreach crew _unit;

//Performance optimizations
_emptyLoops = 0;
_delay = 0.5;

//If the launcher has to be pointed
_needsAiming 	= _weaponPar select 3;
_shotsDelay		= _weaponPar select 5;

//Main loop
_loops = ((count _typeArray) - 1);

//If a new dome is initialized
_isActive = true;
_timeActive = time;

while {alive _unit and (someAmmo _unit) and _isActive} do {
	if(time - _timeActive > 5) then {
		_isActive = _unit getVariable ["DomeInit",true];
		_timeActive = time;
	};

	_tgtLogic = _unit getVariable ["_tgtLogic", 0];
	_entities = [];
	_targetedShells = [];
	_target = objNull;

	//Detection script
	isNil {
		_targetedShells = missionNamespace getVariable ["_targetedShells", []];
		for "_i" from 0 to _loops do {
			_near = _unit nearObjects [_typeArray select _i, _distance];
			_entities append _near;
		};

		//Initialized shells
		_entities = _entities select {!(_x isKindOf "MissileBase") or (_x isKindOf "ammo_Missile_CruiseBase")};
		_entities = (_entities select {!(_x in _targetedShells)});

		//Pick a target
		if(count _entities > 0) then {
			[_entities] call IRON_DOME37_fnc_initshells;
			_target = [_entities, _unit, _tgtLogic] call IRON_DOME37_fnc_pickTarget;

			if(!isNull _target) then {
				["_targetedShells", _target, "add"] call IRON_DOME37_fnc_handleTargets;
			};
		};
	};

	if(!isNull _target) then {
		_emptyLoops = 0;
		_delay = 0.5;
		//Init all the entities
		
		//Different targets require different initial conditions for the missile
		//Originally used to check minimum angle, unused
		/*
			_aslDiff = ((_pos select 2) - ((getPosASL _unit) select 2));
			_angleToTgt = atan(_aslDiff/(_unit distance2d _target)); //y / x 
			_angleToTgt = (_angleToTgt - 0.1) max 0;
			_angleToTgt = _angleToTgt/90;
		*/
		
		//Engagement logic
		_time = time;
		_wep =  currentWeapon _unit;

		//Must aim
		if(_needsAiming) then {
			//Makes the launcher point upward
			_pos = (getPosASL _target);
			_increment = 3500;
			if(_target isKindOf "ammo_Missile_CruiseBase") then {
				_increment = 0;
			};
			_pos set [2, (_pos select 2) + _increment ];
			_unit doWatch _pos;

			waitUntil {([_unit, _pos] call IRON_DOME37_fnc_watchQuality > 0.8) or (time - _time) > 7};
			sleep 1;
		};
			
		if(!alive _target) exitWith {};

		//If this was aimed upward continue, else abort
		if((((_unit weaponDirection _wep) select 2) > 0.1) or !_needsAiming) then {
			isNil{_unit setVariable ["currentTarget", _target];};

			//event handler takes care of the missile
			_unit fire _wep;

			//Safety cleanup 
			_target spawn {
				sleep 25;
				if(alive _this) then {
					["_targetedShells", _this, "remove"] call IRON_DOME37_fnc_handleTargets;
				};
			};

			//Minimum delay between shots
			sleep _shotsDelay;	
		} else {
			isNil {
				["_targetedShells", _target, "remove"] call IRON_DOME37_fnc_handleTargets;
			};
		};
	} else {
		//Lowers the amount of checks per second when nothing is found
		_delay = 1;
		_emptyLoops = (_emptyLoops + 1);
		if(_emptyLoops > 30) then {
			_delay = 1.5;
			_unit doWatch objNull;
		};
	};
	sleep _delay;
};

_unit doWatch objNull;
removeallActions _unit;

_unit setVariable ["DomeRunning", false];
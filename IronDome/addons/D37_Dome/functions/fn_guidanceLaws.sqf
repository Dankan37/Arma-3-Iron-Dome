//params ["_missile", "_target", "_speed",];
private _missile 	= param[0];
private _target 	= param[1];
private _parameters = param[2];

//Speed, guidance, N
private _speed 		= _parameters select 0;
private _guidance 	= _parameters select 1;
private _N 			= _parameters select 2;
private _timeToMax	= _parameters select 4;

//Lofting - Not used 
/*
if(_loft and ((vectorDir _missile) select 2) < 0.65) then {
	_currentDir = vectorDir _missile;
	_currZDir = _currentDir select 2;
	_targetDir = 0.9;

	_timeToUp = 1;
	_diff = _targetDir - _currZDir;
	_step = _diff / _timeToUp;

	_time = time;
	while{(time - _time) < 8 or (_missile distance _target) < 1500} do {
		_currentDir = vectorDir _missile;
		_currZDir = (_currentDir select 2);
		_dirIncrement = (time - _time) * _step;
		_currentDir set [2, (_currZDir + _dirIncrement)];
		
		//Set new speed
		_guidVel = ((vectorNormalized _currentDir) vectorMultiply 30 * (1 + time - _time));
		_missile setVectorDir _guidVel;
		_missile setVelocity _guidVel;	
		sleep 0.025;
	};
};
*/

if(isNull _target) exitWith {};

//Weird issue with APN when engaging missiles idk 
_targetIsMissile = (_target isKindOf "MissileBase");

//Variables for the missile and logic
private _increment = 0.02;
private _currSpeed = _speed / 100;
private _k = 1;
private _initialDist = (_missile distance _target);
private _closeEncounter = false;
private _medianLoops = 5;

_lowestDist = _initialDist;
_incrementSpeed = (_speed - _currSpeed) / _timeToMax;

//Vectorial quantities
_guidVel = [0,0,0];
_leadAcc = [0,0,0];
_lastB = [0,0,0];
_tgtAccNorm = [0,0,0];

private _time = time;
_loop = 0;
while {alive _target and alive _missile} do {
	//Elapsed time
	_deltaT = (time - _time);

	//Speed
	_currSpeed = _currSpeed + _incrementSpeed * _deltaT;
	_currSpeed = _currSpeed min _speed;

	//LOS
	_posA = getPosASL _missile;
	_posB = getPosASL _target;
	_LOS = _posB vectorDiff _posA;
	_steering = _posA vectorFromTo _posB;
	_dist = _missile distance _target;

	//Relative velocity
	_velA = velocity _missile;
	_velB = velocity _target;
	_relVelocity = _velB vectorDiff _velA;

	if(_dist < _lowestDist) then {
		_lowestDist = _dist;
	};

	//Was close
	if(_dist < 1000) then {
		_closeEncounter = true;
	};
	//Now is far
	if(_closeEncounter and (_dist > 1500)) then {
		_mine = createMine ["DemoCharge_F", getPosATL _missile, [], 0];
		_mine setDamage 1;
		deletevehicle _missile;
	};

	switch (_guidance) do {
		//APN
		case 0: {
			//Impact Time Control Cooperative Guidance Law Design Based on Modified Proportional Navigation
			//https://www.mdpi.com/2226-4310/8/8/231/pdf
			//formula [30]
			_tGo = (_dist/(speed _missile)*(1+ ((acos(_velA vectorCos _steering)/90)^2)/(2*(2 * _N - 1))));
			if(isNil "_tgo") then {continue};

			//Zero effort miss
			_ZEM = _LOS vectorAdd (_relVelocity vectorMultiply _tGo);
			_losZEM = _ZEM vectorDotProduct _steering;
			_nrmZEM = (_ZEM vectorDiff (_steering vectorMultiply _losZEM));

			//Weird behaviour when attacking missiles
			if(!_targetIsMissile) then {
				if(_loop == _medianLoops) then {
				//Target accelleration 
					_tgtAcc = _leadAcc vectorMultiply (1/_medianLoops);
					_tgtAccLos = _tgtAcc vectorDotProduct _steering;
					_tgtAccNorm = _tgtAcc vectorDiff (_steering vectorMultiply _tgtAccLos); 		
					_loop = 0;		
				} else {
					_tgtAcc = (_velB vectorDiff _lastB) vectorMultiply (1/_increment);
					_lastB = _velB;
					_leadAcc = _leadAcc vectorAdd _tgtAcc;
					_loop = _loop + 1;
				};
			};

			//augmented prop nav with ZEM and lowered proportional gain
			_leadAcc = (_nrmZEM vectorMultiply _N) vectorMultiply (1/(_tGo ^ 2)) vectorAdd (_tgtAccNorm vectorMultiply (_N/4));
			_guidVel = (_leadAcc vectorMultiply _increment) vectorAdd _velA;
		};

		//PN
		case 1: {
			//Calculate omega
			_rotation = _LOS vectorCrossProduct _relVelocity;
			_distance = _LOS vectorDotProduct _LOS;
			_rotation = _rotation vectorMultiply (1/_distance);
			
			//Desired accelleration to intercept
			_leadAcc = (_relVelocity vectorMultiply _N) vectorCrossProduct _rotation;
			_guidVel = (_leadAcc vectorMultiply _increment) vectorAdd _velA;
		};

		//Pure pursuit
		case 2: {
			_guidVel = _steering;
		}
	};

	//Set new speed
	_guidVel = ((vectorNormalized _guidVel) vectorMultiply _currSpeed);
	_missile setVectorDir _guidVel;
	_missile setVelocity _guidVel;	

	//drawLine3D [_posA, _posA vectorAdd _LOS, [1,1,1,1]];
	sleep _increment;
};

//Clean up
["_targetedShells", _target, "remove"] call IRON_DOME37_fnc_handleTargets;

//If the target died or the missile timedout make it blow in mid air
if(alive _missile) then {
	waitUntil {(getposATL _missile select 2) > 100};
	if(alive _target) then {
		sleep random 1;
	};
	
	deletevehicle _missile;
	_mine = createMine ["DemoCharge_F", getPosATL _missile, [], 0];
	_mine setDamage 1;
};


true;
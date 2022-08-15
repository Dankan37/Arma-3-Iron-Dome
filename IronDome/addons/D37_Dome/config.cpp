class cfgPatches 
{
    class D37_dome
    {
        units[] = {"B_SAM_System_01_F_DOME"};
		weapons[] = {"B_SAM_System_01_F_DOME"};
		requiredVersion = 0.1;
		requiredAddons[] = {"A3_Static_F_Jets_SAM_System_01","A3_Static_F_Jets_SAM_System_02"};
    };
};

class CfgFunctions
{
	class IRON_DOME37
	{
        tag = "IRON_DOME37";
		file = "D37_dome\functions";
        class main {        
            class handleDome {};
            class watchQuality {};
            class guidanceLaws {};
            class initShells {};
            class pickTarget {};
            class handleTargets {};
        };
	};
};

class CfgSounds
{
	class CRAMALARM
	{
		name = "CRAM_Alarm";
		sound[] = {"D37_cram\Sound\CRAM_ALARM.ogg", 1.0, 1.0};
		titles[] = {0, ""};
	};
};

//["SAM_System_01_base_F","StaticMGWeapon","StaticWeapon","LandVehicle","Land","AllVehicles","All"]
class cfgVehicles {
    class AllVehicles;
	class Land: AllVehicles {};
	class LandVehicle: Land {};
	class StaticWeapon: LandVehicle {};
	class StaticMGWeapon: StaticWeapon {};
	class SAM_System_01_base_F: StaticMGWeapon{
		class EventHandlers;
		class Turrets {
			class MainTurret;
		};
	};

	class B_SAM_System_01_F: SAM_System_01_base_F {
		class EventHandlers: EventHandlers {
			class DOME37 {
				init = "[_this select 0, 3000, 2] spawn IRON_DOME37_fnc_handleDome;";
			};
		};
	};

    class B_SAM_System_01_F_DOME: B_SAM_System_01_F {
        displayName = "Iron Dome";
        class EventHandlers: EventHandlers {
			class DOME37 {
				init = "[_this select 0, 3000, 2] spawn IRON_DOME37_fnc_handleDome;";
			};
		};

        class Turrets: Turrets {
            class MainTurret: MainTurret {
                initElev = 89;
                maxelev = 90;
                minelev = 89;

				magazines[] = {"magazine_Missile_dome_x21"};
            };
        };
    };

	class SAM_System_03_base_F:StaticMGWeapon {
		class EventHandlers;
	};
	class B_SAM_System_03_F: SAM_System_03_base_F {
		class EventHandlers: EventHandlers {
			class DOME37 {
				init = "[_this select 0, 7500, 2, [1100/3.6, 0, 4, true, 30, 3]] spawn IRON_DOME37_fnc_handleDome;";
			};
		};
	};

	class SAM_System_04_base_F:StaticMGWeapon {
		class EventHandlers;
	};
	class O_SAM_System_04_F: SAM_System_04_base_F {
		class EventHandlers: EventHandlers {
			class DOME37 {
				init = "[_this select 0, 7500, 2, [1100/3.6, 0, 4, true, 30, 3]] spawn IRON_DOME37_fnc_handleDome;";
			};
		};
	};

	class SAM_System_02_base_F: StaticMGWeapon {
		class EventHandlers;
	};
	class B_SAM_System_02_F: SAM_System_02_base_F {
		class EventHandlers: EventHandlers {
			class DOME37 {
				init = "[_this select 0, 4500, 2, [800/3.6, 0, 3, true, 15, 4]] spawn IRON_DOME37_fnc_handleDome;";
			};
		};
	};
};

//["ammo_Missile_ShortRangeAABase","MissileBase","MissileCore","Default"]
class cfgAmmo {
	class MissileCore;
	class MissileBase: MissileCore {};
	class ammo_Missile_ShortRangeAABase: MissileBase {};
	class ammo_Missile_rim116: ammo_Missile_ShortRangeAABase {};

	class ammo_Missile_dome: ammo_Missile_rim116 {
		thrust = 10;
		thrustTime = 16;
		timeToLive = 30;
	};
};

//["VehicleMagazine","CA_Magazine","Default"]
class cfgMagazines {
	class CA_Magazine;
	class VehicleMagazine: CA_Magazine {};
	class magazine_Missile_rim116_x21: VehicleMagazine {};

	class magazine_Missile_dome_x21: magazine_Missile_rim116_x21 {
		ammo = "ammo_Missile_dome";
	};	
};

class cfgWeapons {
	class LauncherCore;
	class MissileLauncher: LauncherCore {};
	class weapon_rim116Launcher: MissileLauncher {
		magazines[] += {"magazine_Missile_dome_x21"};
	};
};

//weapons[] = {"weapon_rim116Launcher"};
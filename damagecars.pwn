

#include <a_samp>

public OnFilterScriptInit()
{
    print("Vehicle Damage Enabler [Alpha v1.0]");
	return 1;
}

VehicleHasDriver(vehicleid) //Not sure who originally made this function, this is with my small edit
{
	for(new i=0; i<= MAX_PLAYERS; i++)
 	{
  		if(IsPlayerInAnyVehicle(i))
    	{
        	if(GetPlayerVehicleID(i) == vehicleid)
         	{
        		if(GetPlayerState(i) == PLAYER_STATE_DRIVER)
          		{
          			return 1;
            	}
           	}
     	}
 	}
	return 0;
}

IsAirModel(modelid) //Thanks and credits goes to AmigaBlizzard for showing me this function
{
    switch(modelid)
    {
        case 460, 476, 511, 512, 513, 519, 520, 553, 577, 592, 593, 417, 425, 447, 469, 487, 488, 497, 548, 563:
		return 1;
    }
    return 0;
}

public OnPlayerWeaponShot(playerid, WEAPON:weaponid, BULLET_HIT_TYPE:hittype, hitid, Float:fX, Float:fY, Float:fZ)

{
	if(hittype == 2 && !VehicleHasDriver(hitid))
	{
		new wID = weaponid;
   		new Float:vHealth; GetVehicleHealth(hitid, vHealth);
 		if(IsAirModel(GetVehicleModel(hitid)) == 1)
 		{
		 	if(wID == 28 || wID == 32) SetVehicleHealth(hitid, vHealth - 8);
 			if(wID == 22 || wID == 29) SetVehicleHealth(hitid, vHealth - 10);
		 	if(wID == 30 || wID == 31) SetVehicleHealth(hitid, vHealth - 12);
			if(wID == 23) SetVehicleHealth(hitid, vHealth - 16);
			if(wID == 33) SetVehicleHealth(hitid, vHealth - 30);
			if(wID == 27) SetVehicleHealth(hitid, vHealth - 48);
			if(wID == 34) SetVehicleHealth(hitid, vHealth - 50);
			if(wID == 24 || wID == 38) SetVehicleHealth(hitid, vHealth - 56);
			if(wID == 25 || wID == 26) SetVehicleHealth(hitid, vHealth - 60);
   		}
		else
		{
			if(wID == 28 || wID == 32) SetVehicleHealth(hitid, vHealth - 20);
 			if(wID == 22 || wID == 29) SetVehicleHealth(hitid, vHealth - 25);
			if(wID == 30 || wID == 31) SetVehicleHealth(hitid, vHealth - 30);
			if(wID == 23) SetVehicleHealth(hitid, vHealth - 40);
			if(wID == 33) SetVehicleHealth(hitid, vHealth - 75);
			if(wID == 27) SetVehicleHealth(hitid, vHealth - 120);
			if(wID == 34) SetVehicleHealth(hitid, vHealth - 125);
			if(wID == 24 || wID == 38) SetVehicleHealth(hitid, vHealth - 140);
			if(wID == 25 || wID == 26) SetVehicleHealth(hitid, vHealth - 150);
		}
	}
	return 1;
}

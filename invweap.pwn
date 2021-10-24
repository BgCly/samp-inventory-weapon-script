#if defined DONT_REMOVE

	SA:MP Inventory & Weapon system

	* Creator : LuminouZ (vyn)

#endif 

#include <a_samp>
#include <zcmd>
#include <sscanf2>

#define forex(%0,%1) for(new %0 = 0; %0 < %1; %0++)

#define MAX_INVENTORY 6

#define DIALOG_GIVEAMOUNT		1
#define DIALOG_GIVETO    		2

new PlayerText:INVBOX[MAX_PLAYERS];
new PlayerText:OPTIONBOX[MAX_PLAYERS];
new PlayerText:CLOSETD[MAX_PLAYERS];
new PlayerText:USETD[MAX_PLAYERS];
new PlayerText:GIVETD[MAX_PLAYERS];
new PlayerText:MODELTD[MAX_PLAYERS][MAX_INVENTORY];
new PlayerText:INVTD[MAX_PLAYERS][3];
new PlayerText:INDEXTD[MAX_PLAYERS][MAX_INVENTORY];
new PlayerText:AMOUNTTD[MAX_PLAYERS][MAX_INVENTORY];
new PlayerText:NAMETD[MAX_PLAYERS][MAX_INVENTORY];

IsModelWeapon(model) 
{
    new const g_aWeaponModels[] = {
		0, 331, 333, 334, 335, 336, 337, 338, 339, 341, 321, 322, 323, 324,
		325, 326, 342, 343, 344, 0, 0, 0, 346, 347, 348, 349, 350, 351, 352,
		353, 355, 356, 372, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366,
		367, 368, 368, 371
    };
    for (new i = 0; i < sizeof(g_aWeaponModels); i ++) if (g_aWeaponModels[i] == model) {
        return 1;
	}
	return 0;
}

enum e_pdata
{
	pSelectItem,
	pTarget,
	pGuns[13],
	pAmmo[13],
};
new PlayerData[MAX_PLAYERS][e_pdata];

enum inventoryData
{
	invExists,
	invID,
	invItem[32 char],
	invModel,
	invQuantity
};

new InventoryData[MAX_PLAYERS][MAX_INVENTORY][inventoryData];

new const g_aWeaponSlots[] = {
	0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 8, 8, 8, 0, 0, 0, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 4, 6, 6, 7, 7, 7, 7, 8, 12, 9, 9, 9, 11, 11, 11
};

GetWeaponModel(weaponid) 
{
    new const g_aWeaponModels[] = {
		0, 331, 333, 334, 335, 336, 337, 338, 339, 341, 321, 322, 323, 324,
		325, 326, 342, 343, 344, 0, 0, 0, 346, 347, 348, 349, 350, 351, 352,
		353, 355, 356, 372, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366,
		367, 368, 368, 371
    };
    if (1 <= weaponid <= 46)
        return g_aWeaponModels[weaponid];

	return 0;
}

enum e_InventoryItems
{
	e_InventoryItem[32],
	e_InventoryModel
};


new const g_aInventoryItems[][e_InventoryItems] =
{
	{"Desert Eagle", 348},
	{"Shotgun", 349},
	{"Cellphone", 330},
	{"MP5", 353},
	{"AK-47", 355}
};

static Inventory_Clear(playerid)
{
	static
	    string[64];

	forex(i, MAX_INVENTORY)
	{
	    if (InventoryData[playerid][i][invExists])
	    {
	        InventoryData[playerid][i][invExists] = 0;
	        InventoryData[playerid][i][invModel] = 0;
	        InventoryData[playerid][i][invQuantity] = 0;
		}
	}
	return 1;
}

static GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
 	GetPlayerName(playerid,name,sizeof(name));
	return name;
}

static Inventory_GetItemID(playerid, item[])
{
	forex(i, MAX_INVENTORY)
	{
	    if (!InventoryData[playerid][i][invExists])
	        continue;

		if (!strcmp(InventoryData[playerid][i][invItem], item)) return i;
	}
	return -1;
}

static Inventory_GetFreeID(playerid)
{
	if (Inventory_Items(playerid) >= 20)
		return -1;

	forex(i, MAX_INVENTORY)
	{
	    if (!InventoryData[playerid][i][invExists])
	        return i;
	}
	return -1;
}

static Inventory_Items(playerid)
{
    new count;

    forex(i, MAX_INVENTORY) if (InventoryData[playerid][i][invExists]) {
        count++;
	}
	return count;
}

static Inventory_Count(playerid, item[])
{
	new itemid = Inventory_GetItemID(playerid, item);

	if (itemid != -1)
	    return InventoryData[playerid][itemid][invQuantity];

	return 0;
}

static PlayerHasItem(playerid, item[])
{
	return (Inventory_GetItemID(playerid, item) != -1);
}

static Inventory_Set(playerid, item[], model, amount)
{
	new itemid = Inventory_GetItemID(playerid, item);

	if (itemid == -1 && amount > 0)
		Inventory_Add(playerid, item, model, amount);

	else if (amount > 0 && itemid != -1)
	    Inventory_SetQuantity(playerid, item, amount);

	else if (amount < 1 && itemid != -1)
	    Inventory_Remove(playerid, item, -1);

	return 1;
}

static Inventory_SetQuantity(playerid, item[], quantity)
{
	new
	    itemid = Inventory_GetItemID(playerid, item);

	if (itemid != -1)
	{
	    InventoryData[playerid][itemid][invQuantity] = quantity;
	}
	return 1;
}

static Inventory_Remove(playerid, item[], quantity = 1)
{
	new
		itemid = Inventory_GetItemID(playerid, item);

	if (itemid != -1)
	{
	    if (InventoryData[playerid][itemid][invQuantity] > 0)
	    {
	        InventoryData[playerid][itemid][invQuantity] -= quantity;
		}
		if (quantity == -1 || InventoryData[playerid][itemid][invQuantity] < 1)
		{
		    InventoryData[playerid][itemid][invExists] = false;
		    InventoryData[playerid][itemid][invModel] = 0;
		    InventoryData[playerid][itemid][invQuantity] = 0;
		}
		return 1;
	}
	return 0;
}

static Inventory_Add(playerid, item[], model, quantity = 1)
{
	new
		itemid = Inventory_GetItemID(playerid, item);

	if (itemid == -1)
	{
	    itemid = Inventory_GetFreeID(playerid);

	    if (itemid != -1)
	    {
	        InventoryData[playerid][itemid][invExists] = true;
	        InventoryData[playerid][itemid][invModel] = model;
	        InventoryData[playerid][itemid][invQuantity] = quantity;

	        strpack(InventoryData[playerid][itemid][invItem], item, 32 char);
	        return itemid;
		}
		return -1;
	}
	else
	{
	    InventoryData[playerid][itemid][invQuantity] += quantity;
	}
	return itemid;
}

ResetWeapons(playerid)
{
	ResetPlayerWeapons(playerid);

	for (new i = 0; i < 13; i ++)
	{
		PlayerData[playerid][pGuns][i] = 0;
		PlayerData[playerid][pAmmo][i] = 0;
	}
	return 1;
}

ResetWeapon(playerid, weaponid)
{
	ResetPlayerWeapons(playerid);

	for (new i = 0; i < 13; i ++) {
	    if (PlayerData[playerid][pGuns][i] != weaponid) {
	        GivePlayerWeapon(playerid, PlayerData[playerid][pGuns][i], PlayerData[playerid][pAmmo][i]);
		}
		else {
            PlayerData[playerid][pGuns][i] = 0;
            PlayerData[playerid][pAmmo][i] = 0;
	    }
	}
	return 1;
}

stock GetWeapon(playerid)
{
	new weaponid = GetPlayerWeapon(playerid);

	if (1 <= weaponid <= 46 && PlayerData[playerid][pGuns][g_aWeaponSlots[weaponid]] == weaponid)
 		return weaponid;

	return 0;
}

GiveWeaponToPlayer(playerid, weaponid, ammo)
{
	if (weaponid < 0 || weaponid > 46)
	    return 0;

	PlayerData[playerid][pGuns][g_aWeaponSlots[weaponid]] = weaponid;
	PlayerData[playerid][pAmmo][g_aWeaponSlots[weaponid]] += ammo;

	return GivePlayerWeapon(playerid, weaponid, ammo);
}

static CreatePlayerInventory(playerid)
{
	NAMETD[playerid][0] = CreatePlayerTextDraw(playerid, 468.000000, 193.000000, "NONE");
	PlayerTextDrawFont(playerid, NAMETD[playerid][0], 2);
	PlayerTextDrawLetterSize(playerid, NAMETD[playerid][0], 0.158333, 0.949999);
	PlayerTextDrawTextSize(playerid, NAMETD[playerid][0], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, NAMETD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, NAMETD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, NAMETD[playerid][0], 1);
	PlayerTextDrawColor(playerid, NAMETD[playerid][0], 255);
	PlayerTextDrawBackgroundColor(playerid, NAMETD[playerid][0], 255);
	PlayerTextDrawBoxColor(playerid, NAMETD[playerid][0], 50);
	PlayerTextDrawUseBox(playerid, NAMETD[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid, NAMETD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, NAMETD[playerid][0], 0);

	NAMETD[playerid][1] = CreatePlayerTextDraw(playerid, 546.000000, 193.000000, "NONE");
	PlayerTextDrawFont(playerid, NAMETD[playerid][1], 2);
	PlayerTextDrawLetterSize(playerid, NAMETD[playerid][1], 0.158333, 0.949999);
	PlayerTextDrawTextSize(playerid, NAMETD[playerid][1], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, NAMETD[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, NAMETD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, NAMETD[playerid][1], 1);
	PlayerTextDrawColor(playerid, NAMETD[playerid][1], 255);
	PlayerTextDrawBackgroundColor(playerid, NAMETD[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, NAMETD[playerid][1], 50);
	PlayerTextDrawUseBox(playerid, NAMETD[playerid][1], 0);
	PlayerTextDrawSetProportional(playerid, NAMETD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, NAMETD[playerid][1], 0);

	NAMETD[playerid][2] = CreatePlayerTextDraw(playerid, 469.000000, 261.000000, "NONE");
	PlayerTextDrawFont(playerid, NAMETD[playerid][2], 2);
	PlayerTextDrawLetterSize(playerid, NAMETD[playerid][2], 0.158333, 0.949999);
	PlayerTextDrawTextSize(playerid, NAMETD[playerid][2], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, NAMETD[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, NAMETD[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, NAMETD[playerid][2], 1);
	PlayerTextDrawColor(playerid, NAMETD[playerid][2], 255);
	PlayerTextDrawBackgroundColor(playerid, NAMETD[playerid][2], 255);
	PlayerTextDrawBoxColor(playerid, NAMETD[playerid][2], 50);
	PlayerTextDrawUseBox(playerid, NAMETD[playerid][2], 0);
	PlayerTextDrawSetProportional(playerid, NAMETD[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, NAMETD[playerid][2], 0);

	NAMETD[playerid][3] = CreatePlayerTextDraw(playerid, 546.000000, 261.000000, "NONE");
	PlayerTextDrawFont(playerid, NAMETD[playerid][3], 2);
	PlayerTextDrawLetterSize(playerid, NAMETD[playerid][3], 0.158333, 0.949999);
	PlayerTextDrawTextSize(playerid, NAMETD[playerid][3], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, NAMETD[playerid][3], 0);
	PlayerTextDrawSetShadow(playerid, NAMETD[playerid][3], 0);
	PlayerTextDrawAlignment(playerid, NAMETD[playerid][3], 1);
	PlayerTextDrawColor(playerid, NAMETD[playerid][3], 255);
	PlayerTextDrawBackgroundColor(playerid, NAMETD[playerid][3], 255);
	PlayerTextDrawBoxColor(playerid, NAMETD[playerid][3], 50);
	PlayerTextDrawUseBox(playerid, NAMETD[playerid][3], 0);
	PlayerTextDrawSetProportional(playerid, NAMETD[playerid][3], 1);
	PlayerTextDrawSetSelectable(playerid, NAMETD[playerid][3], 0);
	
	NAMETD[playerid][4] = CreatePlayerTextDraw(playerid, 469.000000, 328.000000, "NONE");
	PlayerTextDrawFont(playerid, NAMETD[playerid][4], 2);
	PlayerTextDrawLetterSize(playerid, NAMETD[playerid][4], 0.158333, 0.949999);
	PlayerTextDrawTextSize(playerid, NAMETD[playerid][4], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, NAMETD[playerid][4],0);
	PlayerTextDrawSetShadow(playerid, NAMETD[playerid][4], 0);
	PlayerTextDrawAlignment(playerid, NAMETD[playerid][4], 1);
	PlayerTextDrawColor(playerid, NAMETD[playerid][4], 255);
	PlayerTextDrawBackgroundColor(playerid, NAMETD[playerid][4], 255);
	PlayerTextDrawBoxColor(playerid, NAMETD[playerid][4], 50);
	PlayerTextDrawUseBox(playerid, NAMETD[playerid][4], 0);
	PlayerTextDrawSetProportional(playerid, NAMETD[playerid][4], 1);
	PlayerTextDrawSetSelectable(playerid, NAMETD[playerid][4], 0);

	NAMETD[playerid][5] = CreatePlayerTextDraw(playerid, 546.000000, 328.000000, "NONE");
	PlayerTextDrawFont(playerid, NAMETD[playerid][5], 2);
	PlayerTextDrawLetterSize(playerid, NAMETD[playerid][5], 0.158333, 0.949999);
	PlayerTextDrawTextSize(playerid, NAMETD[playerid][5], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, NAMETD[playerid][5], 0);
	PlayerTextDrawSetShadow(playerid, NAMETD[playerid][5], 0);
	PlayerTextDrawAlignment(playerid, NAMETD[playerid][5], 1);
	PlayerTextDrawColor(playerid, NAMETD[playerid][5], 255);
	PlayerTextDrawBackgroundColor(playerid, NAMETD[playerid][5], 255);
	PlayerTextDrawBoxColor(playerid, NAMETD[playerid][5], 50);
	PlayerTextDrawUseBox(playerid, NAMETD[playerid][5], 0);
	PlayerTextDrawSetProportional(playerid, NAMETD[playerid][5], 1);
	PlayerTextDrawSetSelectable(playerid, NAMETD[playerid][5], 0);

	INVBOX[playerid] = CreatePlayerTextDraw(playerid, 532.000000, 184.000000, "_");
	PlayerTextDrawFont(playerid, INVBOX[playerid], 1);
	PlayerTextDrawLetterSize(playerid, INVBOX[playerid], 0.579164, 23.299999);
	PlayerTextDrawTextSize(playerid, INVBOX[playerid], 298.500000, 155.000000);
	PlayerTextDrawSetOutline(playerid, INVBOX[playerid], 1);
	PlayerTextDrawSetShadow(playerid, INVBOX[playerid], 0);
	PlayerTextDrawAlignment(playerid, INVBOX[playerid], 2);
	PlayerTextDrawColor(playerid, INVBOX[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, INVBOX[playerid], 255);
	PlayerTextDrawBoxColor(playerid, INVBOX[playerid], 135);
	PlayerTextDrawUseBox(playerid, INVBOX[playerid], 1);
	PlayerTextDrawSetProportional(playerid, INVBOX[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, INVBOX[playerid], 0);

	CLOSETD[playerid] = CreatePlayerTextDraw(playerid, 400.000000, 307.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, CLOSETD[playerid], 4);
	PlayerTextDrawLetterSize(playerid, CLOSETD[playerid], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, CLOSETD[playerid], 48.000000, 16.000000);
	PlayerTextDrawSetOutline(playerid, CLOSETD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, CLOSETD[playerid], 0);
	PlayerTextDrawAlignment(playerid, CLOSETD[playerid], 1);
	PlayerTextDrawColor(playerid, CLOSETD[playerid], -741092455);
	PlayerTextDrawBackgroundColor(playerid, CLOSETD[playerid], 255);
	PlayerTextDrawBoxColor(playerid, CLOSETD[playerid], 50);
	PlayerTextDrawUseBox(playerid, CLOSETD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, CLOSETD[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, CLOSETD[playerid], 1);

	USETD[playerid] = CreatePlayerTextDraw(playerid, 400.000000, 338.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, USETD[playerid], 4);
	PlayerTextDrawLetterSize(playerid, USETD[playerid], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, USETD[playerid], 48.000000, 16.000000);
	PlayerTextDrawSetOutline(playerid, USETD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, USETD[playerid], 0);
	PlayerTextDrawAlignment(playerid, USETD[playerid], 1);
	PlayerTextDrawColor(playerid, USETD[playerid], -741092455);
	PlayerTextDrawBackgroundColor(playerid, USETD[playerid], 255);
	PlayerTextDrawBoxColor(playerid, USETD[playerid], 50);
	PlayerTextDrawUseBox(playerid, USETD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, USETD[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, USETD[playerid], 1);

	GIVETD[playerid] = CreatePlayerTextDraw(playerid, 400.000000, 370.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, GIVETD[playerid], 4);
	PlayerTextDrawLetterSize(playerid, GIVETD[playerid], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, GIVETD[playerid], 48.000000, 16.000000);
	PlayerTextDrawSetOutline(playerid, GIVETD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, GIVETD[playerid], 0);
	PlayerTextDrawAlignment(playerid, GIVETD[playerid], 1);
	PlayerTextDrawColor(playerid, GIVETD[playerid], -741092455);
	PlayerTextDrawBackgroundColor(playerid, GIVETD[playerid], 255);
	PlayerTextDrawBoxColor(playerid, GIVETD[playerid], 50);
	PlayerTextDrawUseBox(playerid, GIVETD[playerid], 1);
	PlayerTextDrawSetProportional(playerid, GIVETD[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, GIVETD[playerid], 1);

	OPTIONBOX[playerid] = CreatePlayerTextDraw(playerid, 423.000000, 301.000000, "_");
	PlayerTextDrawFont(playerid, OPTIONBOX[playerid], 1);
	PlayerTextDrawLetterSize(playerid, OPTIONBOX[playerid], 0.600000, 10.300003);
	PlayerTextDrawTextSize(playerid, OPTIONBOX[playerid], 298.500000, 57.000000);
	PlayerTextDrawSetOutline(playerid, OPTIONBOX[playerid], 1);
	PlayerTextDrawSetShadow(playerid, OPTIONBOX[playerid], 0);
	PlayerTextDrawAlignment(playerid, OPTIONBOX[playerid], 2);
	PlayerTextDrawColor(playerid, OPTIONBOX[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, OPTIONBOX[playerid], 255);
	PlayerTextDrawBoxColor(playerid, OPTIONBOX[playerid], 135);
	PlayerTextDrawUseBox(playerid, OPTIONBOX[playerid], 1);
	PlayerTextDrawSetProportional(playerid, OPTIONBOX[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, OPTIONBOX[playerid], 0);

	INDEXTD[playerid][0] = CreatePlayerTextDraw(playerid, 465.000000, 192.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, INDEXTD[playerid][0], 4);
	PlayerTextDrawLetterSize(playerid, INDEXTD[playerid][0], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, INDEXTD[playerid][0], 56.500000, 56.000000);
	PlayerTextDrawSetOutline(playerid, INDEXTD[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, INDEXTD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, INDEXTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, INDEXTD[playerid][0], -741092455);
	PlayerTextDrawBackgroundColor(playerid, INDEXTD[playerid][0], 255);
	PlayerTextDrawBoxColor(playerid, INDEXTD[playerid][0], 50);
	PlayerTextDrawUseBox(playerid, INDEXTD[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, INDEXTD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, INDEXTD[playerid][0], 1);

	INDEXTD[playerid][1] = CreatePlayerTextDraw(playerid, 543.000000, 192.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, INDEXTD[playerid][1], 4);
	PlayerTextDrawLetterSize(playerid, INDEXTD[playerid][1], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, INDEXTD[playerid][1], 56.500000, 56.000000);
	PlayerTextDrawSetOutline(playerid, INDEXTD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, INDEXTD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, INDEXTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, INDEXTD[playerid][1], -741092455);
	PlayerTextDrawBackgroundColor(playerid, INDEXTD[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, INDEXTD[playerid][1], 50);
	PlayerTextDrawUseBox(playerid, INDEXTD[playerid][1], 1);
	PlayerTextDrawSetProportional(playerid, INDEXTD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, INDEXTD[playerid][1], 1);

	INDEXTD[playerid][2] = CreatePlayerTextDraw(playerid, 465.000000, 260.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, INDEXTD[playerid][2], 4);
	PlayerTextDrawLetterSize(playerid, INDEXTD[playerid][2], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, INDEXTD[playerid][2], 56.500000, 56.000000);
	PlayerTextDrawSetOutline(playerid, INDEXTD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, INDEXTD[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, INDEXTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, INDEXTD[playerid][2], -741092455);
	PlayerTextDrawBackgroundColor(playerid, INDEXTD[playerid][2], 255);
	PlayerTextDrawBoxColor(playerid, INDEXTD[playerid][2], 50);
	PlayerTextDrawUseBox(playerid, INDEXTD[playerid][2], 1);
	PlayerTextDrawSetProportional(playerid, INDEXTD[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, INDEXTD[playerid][2], 1);

	INDEXTD[playerid][3] = CreatePlayerTextDraw(playerid, 543.000000, 260.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, INDEXTD[playerid][3], 4);
	PlayerTextDrawLetterSize(playerid, INDEXTD[playerid][3], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, INDEXTD[playerid][3], 56.500000, 56.000000);
	PlayerTextDrawSetOutline(playerid, INDEXTD[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, INDEXTD[playerid][3], 0);
	PlayerTextDrawAlignment(playerid, INDEXTD[playerid][3], 1);
	PlayerTextDrawColor(playerid, INDEXTD[playerid][3], -741092455);
	PlayerTextDrawBackgroundColor(playerid, INDEXTD[playerid][3], 255);
	PlayerTextDrawBoxColor(playerid, INDEXTD[playerid][3], 50);
	PlayerTextDrawUseBox(playerid, INDEXTD[playerid][3], 1);
	PlayerTextDrawSetProportional(playerid, INDEXTD[playerid][3], 1);
	PlayerTextDrawSetSelectable(playerid, INDEXTD[playerid][3], 1);

	INDEXTD[playerid][4] = CreatePlayerTextDraw(playerid, 465.000000, 327.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, INDEXTD[playerid][4], 4);
	PlayerTextDrawLetterSize(playerid, INDEXTD[playerid][4], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, INDEXTD[playerid][4], 56.500000, 56.000000);
	PlayerTextDrawSetOutline(playerid, INDEXTD[playerid][4], 1);
	PlayerTextDrawSetShadow(playerid, INDEXTD[playerid][4], 0);
	PlayerTextDrawAlignment(playerid, INDEXTD[playerid][4], 1);
	PlayerTextDrawColor(playerid, INDEXTD[playerid][4], -741092455);
	PlayerTextDrawBackgroundColor(playerid, INDEXTD[playerid][4], 255);
	PlayerTextDrawBoxColor(playerid, INDEXTD[playerid][4], 50);
	PlayerTextDrawUseBox(playerid, INDEXTD[playerid][4], 1);
	PlayerTextDrawSetProportional(playerid, INDEXTD[playerid][4], 1);
	PlayerTextDrawSetSelectable(playerid, INDEXTD[playerid][4], 1);

	INDEXTD[playerid][5] = CreatePlayerTextDraw(playerid, 543.000000, 327.000000, "ld_dual:white");
	PlayerTextDrawFont(playerid, INDEXTD[playerid][5], 4);
	PlayerTextDrawLetterSize(playerid, INDEXTD[playerid][5], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, INDEXTD[playerid][5], 56.500000, 56.000000);
	PlayerTextDrawSetOutline(playerid, INDEXTD[playerid][5], 1);
	PlayerTextDrawSetShadow(playerid, INDEXTD[playerid][5], 0);
	PlayerTextDrawAlignment(playerid, INDEXTD[playerid][5], 1);
	PlayerTextDrawColor(playerid, INDEXTD[playerid][5], -741092455);
	PlayerTextDrawBackgroundColor(playerid, INDEXTD[playerid][5], 255);
	PlayerTextDrawBoxColor(playerid, INDEXTD[playerid][5], 50);
	PlayerTextDrawUseBox(playerid, INDEXTD[playerid][5], 1);
	PlayerTextDrawSetProportional(playerid, INDEXTD[playerid][5], 1);
	PlayerTextDrawSetSelectable(playerid, INDEXTD[playerid][5], 1);

	INVTD[playerid][0] = CreatePlayerTextDraw(playerid, 409.000000, 308.000000, "CLOSE");
	PlayerTextDrawFont(playerid, INVTD[playerid][0], 2);
	PlayerTextDrawLetterSize(playerid, INVTD[playerid][0], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, INVTD[playerid][0], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, INVTD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, INVTD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, INVTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, INVTD[playerid][0], 255);
	PlayerTextDrawBackgroundColor(playerid, INVTD[playerid][0], 255);
	PlayerTextDrawBoxColor(playerid, INVTD[playerid][0], 50);
	PlayerTextDrawUseBox(playerid, INVTD[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid, INVTD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, INVTD[playerid][0], 0);

	INVTD[playerid][1] = CreatePlayerTextDraw(playerid, 414.000000, 339.000000, "USE");
	PlayerTextDrawFont(playerid, INVTD[playerid][1], 2);
	PlayerTextDrawLetterSize(playerid, INVTD[playerid][1], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, INVTD[playerid][1], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, INVTD[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, INVTD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, INVTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, INVTD[playerid][1], 255);
	PlayerTextDrawBackgroundColor(playerid, INVTD[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, INVTD[playerid][1], 50);
	PlayerTextDrawUseBox(playerid, INVTD[playerid][1], 0);
	PlayerTextDrawSetProportional(playerid, INVTD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, INVTD[playerid][1], 0);

	INVTD[playerid][2] = CreatePlayerTextDraw(playerid, 413.000000, 371.000000, "GIVE");
	PlayerTextDrawFont(playerid, INVTD[playerid][2], 2);
	PlayerTextDrawLetterSize(playerid, INVTD[playerid][2], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, INVTD[playerid][2], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, INVTD[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, INVTD[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, INVTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, INVTD[playerid][2], 255);
	PlayerTextDrawBackgroundColor(playerid, INVTD[playerid][2], 255);
	PlayerTextDrawBoxColor(playerid, INVTD[playerid][2], 50);
	PlayerTextDrawUseBox(playerid, INVTD[playerid][2], 0);
	PlayerTextDrawSetProportional(playerid, INVTD[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, INVTD[playerid][2], 0);

	MODELTD[playerid][0] = CreatePlayerTextDraw(playerid, 470.000000, 200.000000, "Preview_Model");
	PlayerTextDrawFont(playerid, MODELTD[playerid][0], 5);
	PlayerTextDrawLetterSize(playerid, MODELTD[playerid][0], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, MODELTD[playerid][0], 42.500000, 41.500000);
	PlayerTextDrawSetOutline(playerid, MODELTD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, MODELTD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, MODELTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, MODELTD[playerid][0], -1);
	PlayerTextDrawBackgroundColor(playerid, MODELTD[playerid][0], 0);
	PlayerTextDrawBoxColor(playerid, MODELTD[playerid][0], 255);
	PlayerTextDrawUseBox(playerid, MODELTD[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid, MODELTD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, MODELTD[playerid][0], 0);
	PlayerTextDrawSetPreviewModel(playerid, MODELTD[playerid][0], 18875);
	PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][0], -16.000000, 0.000000, -55.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, MODELTD[playerid][0], 1, 1);

	MODELTD[playerid][1] = CreatePlayerTextDraw(playerid, 546.000000, 200.000000, "Preview_Model");
	PlayerTextDrawFont(playerid, MODELTD[playerid][1], 5);
	PlayerTextDrawLetterSize(playerid, MODELTD[playerid][1], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, MODELTD[playerid][1], 42.500000, 41.500000);
	PlayerTextDrawSetOutline(playerid, MODELTD[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, MODELTD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, MODELTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, MODELTD[playerid][1], -1);
	PlayerTextDrawBackgroundColor(playerid, MODELTD[playerid][1], 0);
	PlayerTextDrawBoxColor(playerid, MODELTD[playerid][1], 255);
	PlayerTextDrawUseBox(playerid, MODELTD[playerid][1], 0);
	PlayerTextDrawSetProportional(playerid, MODELTD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, MODELTD[playerid][1], 0);
	PlayerTextDrawSetPreviewModel(playerid, MODELTD[playerid][1], 18875);
	PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][1], -16.000000, 0.000000, -55.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, MODELTD[playerid][1], 1, 1);

	MODELTD[playerid][2] = CreatePlayerTextDraw(playerid, 470.000000, 264.000000, "Preview_Model");
	PlayerTextDrawFont(playerid, MODELTD[playerid][2], 5);
	PlayerTextDrawLetterSize(playerid, MODELTD[playerid][2], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, MODELTD[playerid][2], 42.500000, 41.500000);
	PlayerTextDrawSetOutline(playerid, MODELTD[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, MODELTD[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, MODELTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, MODELTD[playerid][2], -1);
	PlayerTextDrawBackgroundColor(playerid, MODELTD[playerid][2], 0);
	PlayerTextDrawBoxColor(playerid, MODELTD[playerid][2], 255);
	PlayerTextDrawUseBox(playerid, MODELTD[playerid][2], 0);
	PlayerTextDrawSetProportional(playerid, MODELTD[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, MODELTD[playerid][2], 0);
	PlayerTextDrawSetPreviewModel(playerid, MODELTD[playerid][2], 18875);
	PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][2], -16.000000, 0.000000, -55.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, MODELTD[playerid][2], 1, 1);

	MODELTD[playerid][3] = CreatePlayerTextDraw(playerid, 547.000000, 264.000000, "Preview_Model");
	PlayerTextDrawFont(playerid, MODELTD[playerid][3], 5);
	PlayerTextDrawLetterSize(playerid, MODELTD[playerid][3], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, MODELTD[playerid][3], 42.500000, 41.500000);
	PlayerTextDrawSetOutline(playerid, MODELTD[playerid][3], 0);
	PlayerTextDrawSetShadow(playerid, MODELTD[playerid][3], 0);
	PlayerTextDrawAlignment(playerid, MODELTD[playerid][3], 1);
	PlayerTextDrawColor(playerid, MODELTD[playerid][3], -1);
	PlayerTextDrawBackgroundColor(playerid, MODELTD[playerid][3], 0);
	PlayerTextDrawBoxColor(playerid, MODELTD[playerid][3], 255);
	PlayerTextDrawUseBox(playerid, MODELTD[playerid][3], 0);
	PlayerTextDrawSetProportional(playerid, MODELTD[playerid][3], 1);
	PlayerTextDrawSetSelectable(playerid, MODELTD[playerid][3], 0);
	PlayerTextDrawSetPreviewModel(playerid, MODELTD[playerid][3], 18875);
	PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][3], -16.000000, 0.000000, -55.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, MODELTD[playerid][3], 1, 1);

	MODELTD[playerid][4] = CreatePlayerTextDraw(playerid, 470.000000, 332.000000, "Preview_Model");
	PlayerTextDrawFont(playerid, MODELTD[playerid][4], 5);
	PlayerTextDrawLetterSize(playerid, MODELTD[playerid][4], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, MODELTD[playerid][4], 42.500000, 41.500000);
	PlayerTextDrawSetOutline(playerid, MODELTD[playerid][4], 0);
	PlayerTextDrawSetShadow(playerid, MODELTD[playerid][4], 0);
	PlayerTextDrawAlignment(playerid, MODELTD[playerid][4], 1);
	PlayerTextDrawColor(playerid, MODELTD[playerid][4], -1);
	PlayerTextDrawBackgroundColor(playerid, MODELTD[playerid][4], 0);
	PlayerTextDrawBoxColor(playerid, MODELTD[playerid][4], 255);
	PlayerTextDrawUseBox(playerid, MODELTD[playerid][4], 0);
	PlayerTextDrawSetProportional(playerid, MODELTD[playerid][4], 1);
	PlayerTextDrawSetSelectable(playerid, MODELTD[playerid][4], 0);
	PlayerTextDrawSetPreviewModel(playerid, MODELTD[playerid][4], 18875);
	PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][4], -16.000000, 0.000000, -55.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, MODELTD[playerid][4], 1, 1);

	MODELTD[playerid][5] = CreatePlayerTextDraw(playerid, 548.000000, 332.000000, "Preview_Model");
	PlayerTextDrawFont(playerid, MODELTD[playerid][5], 5);
	PlayerTextDrawLetterSize(playerid, MODELTD[playerid][5], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, MODELTD[playerid][5], 42.500000, 41.500000);
	PlayerTextDrawSetOutline(playerid, MODELTD[playerid][5], 0);
	PlayerTextDrawSetShadow(playerid, MODELTD[playerid][5], 0);
	PlayerTextDrawAlignment(playerid, MODELTD[playerid][5], 1);
	PlayerTextDrawColor(playerid, MODELTD[playerid][5], -1);
	PlayerTextDrawBackgroundColor(playerid, MODELTD[playerid][5], 0);
	PlayerTextDrawBoxColor(playerid, MODELTD[playerid][5], 255);
	PlayerTextDrawUseBox(playerid, MODELTD[playerid][5], 0);
	PlayerTextDrawSetProportional(playerid, MODELTD[playerid][5], 1);
	PlayerTextDrawSetSelectable(playerid, MODELTD[playerid][5], 0);
	PlayerTextDrawSetPreviewModel(playerid, MODELTD[playerid][5], 18875);
	PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][5], -16.000000, 0.000000, -55.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, MODELTD[playerid][5], 1, 1);

	AMOUNTTD[playerid][0] = CreatePlayerTextDraw(playerid, 469.000000, 233.000000, "0");
	PlayerTextDrawFont(playerid, AMOUNTTD[playerid][0], 2);
	PlayerTextDrawLetterSize(playerid, AMOUNTTD[playerid][0], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, AMOUNTTD[playerid][0], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, AMOUNTTD[playerid][0], 0);
	PlayerTextDrawSetShadow(playerid, AMOUNTTD[playerid][0], 0);
	PlayerTextDrawAlignment(playerid, AMOUNTTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, AMOUNTTD[playerid][0], 255);
	PlayerTextDrawBackgroundColor(playerid, AMOUNTTD[playerid][0], 255);
	PlayerTextDrawBoxColor(playerid, AMOUNTTD[playerid][0], 50);
	PlayerTextDrawUseBox(playerid, AMOUNTTD[playerid][0], 0);
	PlayerTextDrawSetProportional(playerid, AMOUNTTD[playerid][0], 1);
	PlayerTextDrawSetSelectable(playerid, AMOUNTTD[playerid][0], 0);

	AMOUNTTD[playerid][1] = CreatePlayerTextDraw(playerid, 547.000000, 233.000000, "0");
	PlayerTextDrawFont(playerid, AMOUNTTD[playerid][1], 2);
	PlayerTextDrawLetterSize(playerid, AMOUNTTD[playerid][1], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, AMOUNTTD[playerid][1], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, AMOUNTTD[playerid][1], 0);
	PlayerTextDrawSetShadow(playerid, AMOUNTTD[playerid][1], 0);
	PlayerTextDrawAlignment(playerid, AMOUNTTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, AMOUNTTD[playerid][1], 255);
	PlayerTextDrawBackgroundColor(playerid, AMOUNTTD[playerid][1], 255);
	PlayerTextDrawBoxColor(playerid, AMOUNTTD[playerid][1], 50);
	PlayerTextDrawUseBox(playerid, AMOUNTTD[playerid][1], 0);
	PlayerTextDrawSetProportional(playerid, AMOUNTTD[playerid][1], 1);
	PlayerTextDrawSetSelectable(playerid, AMOUNTTD[playerid][1], 0);

	AMOUNTTD[playerid][2] = CreatePlayerTextDraw(playerid, 469.000000, 301.000000, "0");
	PlayerTextDrawFont(playerid, AMOUNTTD[playerid][2], 2);
	PlayerTextDrawLetterSize(playerid, AMOUNTTD[playerid][2], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, AMOUNTTD[playerid][2], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, AMOUNTTD[playerid][2], 0);
	PlayerTextDrawSetShadow(playerid, AMOUNTTD[playerid][2], 0);
	PlayerTextDrawAlignment(playerid, AMOUNTTD[playerid][2], 1);
	PlayerTextDrawColor(playerid, AMOUNTTD[playerid][2], 255);
	PlayerTextDrawBackgroundColor(playerid, AMOUNTTD[playerid][2], 255);
	PlayerTextDrawBoxColor(playerid, AMOUNTTD[playerid][2], 50);
	PlayerTextDrawUseBox(playerid, AMOUNTTD[playerid][2], 0);
	PlayerTextDrawSetProportional(playerid, AMOUNTTD[playerid][2], 1);
	PlayerTextDrawSetSelectable(playerid, AMOUNTTD[playerid][2], 0);

	AMOUNTTD[playerid][3] = CreatePlayerTextDraw(playerid, 547.000000, 301.000000, "0");
	PlayerTextDrawFont(playerid, AMOUNTTD[playerid][3], 2);
	PlayerTextDrawLetterSize(playerid, AMOUNTTD[playerid][3], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, AMOUNTTD[playerid][3], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, AMOUNTTD[playerid][3], 0);
	PlayerTextDrawSetShadow(playerid, AMOUNTTD[playerid][3], 0);
	PlayerTextDrawAlignment(playerid, AMOUNTTD[playerid][3], 1);
	PlayerTextDrawColor(playerid, AMOUNTTD[playerid][3], 255);
	PlayerTextDrawBackgroundColor(playerid, AMOUNTTD[playerid][3], 255);
	PlayerTextDrawBoxColor(playerid, AMOUNTTD[playerid][3], 50);
	PlayerTextDrawUseBox(playerid, AMOUNTTD[playerid][3], 0);
	PlayerTextDrawSetProportional(playerid, AMOUNTTD[playerid][3], 1);
	PlayerTextDrawSetSelectable(playerid, AMOUNTTD[playerid][3], 0);

	AMOUNTTD[playerid][4] = CreatePlayerTextDraw(playerid, 469.000000, 367.000000, "0");
	PlayerTextDrawFont(playerid, AMOUNTTD[playerid][4], 2);
	PlayerTextDrawLetterSize(playerid, AMOUNTTD[playerid][4], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, AMOUNTTD[playerid][4], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, AMOUNTTD[playerid][4], 0);
	PlayerTextDrawSetShadow(playerid, AMOUNTTD[playerid][4], 0);
	PlayerTextDrawAlignment(playerid, AMOUNTTD[playerid][4], 1);
	PlayerTextDrawColor(playerid, AMOUNTTD[playerid][4], 255);
	PlayerTextDrawBackgroundColor(playerid, AMOUNTTD[playerid][4], 255);
	PlayerTextDrawBoxColor(playerid, AMOUNTTD[playerid][4], 50);
	PlayerTextDrawUseBox(playerid, AMOUNTTD[playerid][4], 0);
	PlayerTextDrawSetProportional(playerid, AMOUNTTD[playerid][4], 1);
	PlayerTextDrawSetSelectable(playerid, AMOUNTTD[playerid][4], 0);

	AMOUNTTD[playerid][5] = CreatePlayerTextDraw(playerid, 547.000000, 367.000000, "0");
	PlayerTextDrawFont(playerid, AMOUNTTD[playerid][5], 2);
	PlayerTextDrawLetterSize(playerid, AMOUNTTD[playerid][5], 0.208333, 1.250000);
	PlayerTextDrawTextSize(playerid, AMOUNTTD[playerid][5], 380.500000, -2.000000);
	PlayerTextDrawSetOutline(playerid, AMOUNTTD[playerid][5], 0);
	PlayerTextDrawSetShadow(playerid, AMOUNTTD[playerid][5], 0);
	PlayerTextDrawAlignment(playerid, AMOUNTTD[playerid][5], 1);
	PlayerTextDrawColor(playerid, AMOUNTTD[playerid][5], 255);
	PlayerTextDrawBackgroundColor(playerid, AMOUNTTD[playerid][5], 255);
	PlayerTextDrawBoxColor(playerid, AMOUNTTD[playerid][5], 50);
	PlayerTextDrawUseBox(playerid, AMOUNTTD[playerid][5], 0);
	PlayerTextDrawSetProportional(playerid, AMOUNTTD[playerid][5], 1);
	PlayerTextDrawSetSelectable(playerid, AMOUNTTD[playerid][5], 0);

}

stock PlayerHasWeapon(playerid, weaponid)
{
	new
	    weapon,
	    ammo;

	for (new i = 0; i < 13; i ++) if (PlayerData[playerid][pGuns][i] == weaponid) {
	    GetPlayerWeaponData(playerid, i, weapon, ammo);

	    if (weapon == weaponid && ammo > 0) return 1;
	}
	return 0;
}

static Inventory_Show(playerid)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	new str[256], string[256];
	forex(i, 3)
	{
		PlayerTextDrawShow(playerid, INVTD[playerid][i]);
	}
	PlayerTextDrawShow(playerid, GIVETD[playerid]);
	PlayerTextDrawShow(playerid, USETD[playerid]);
	PlayerTextDrawShow(playerid, CLOSETD[playerid]);
	PlayerTextDrawShow(playerid, INVBOX[playerid]);
	PlayerTextDrawShow(playerid, OPTIONBOX[playerid]);
	SelectTextDraw(playerid, 0xAFAFAFFF);
	forex(i, MAX_INVENTORY)
	{
		PlayerTextDrawShow(playerid, INDEXTD[playerid][i]);
		PlayerTextDrawShow(playerid, AMOUNTTD[playerid][i]);
		if(InventoryData[playerid][i][invExists])
		{
			PlayerTextDrawShow(playerid, NAMETD[playerid][i]);
			PlayerTextDrawSetPreviewModel(playerid, MODELTD[playerid][i], InventoryData[playerid][i][invModel]);
			if(IsModelWeapon(InventoryData[playerid][i][invModel]))
			{
				PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][i], -20, 0.0, 349.0);
			}
			else
			{
				PlayerTextDrawSetPreviewRot(playerid, MODELTD[playerid][i], -16.0000, 0.0000, -55.0000);
			}
			PlayerTextDrawShow(playerid, MODELTD[playerid][i]);
			strunpack(string, InventoryData[playerid][i][invItem]);
			format(str, sizeof(str), "%s", string);
			PlayerTextDrawSetString(playerid, NAMETD[playerid][i], str);
			format(str, sizeof(str), "%d", InventoryData[playerid][i][invQuantity]);
			PlayerTextDrawSetString(playerid, AMOUNTTD[playerid][i], str);
		}
		else
		{
			format(str, sizeof(str), "%d", InventoryData[playerid][i][invQuantity]);
			PlayerTextDrawSetString(playerid, AMOUNTTD[playerid][i], str);			
		}

	}
	return 1;
}

static Inventory_Close(playerid)
{
	forex(i, 3)
	{
		PlayerTextDrawHide(playerid, INVTD[playerid][i]);
	}
	PlayerTextDrawHide(playerid, GIVETD[playerid]);
	PlayerTextDrawHide(playerid, USETD[playerid]);
	PlayerTextDrawHide(playerid, CLOSETD[playerid]);
	PlayerTextDrawHide(playerid, INVBOX[playerid]);
	PlayerTextDrawHide(playerid, OPTIONBOX[playerid]);
	CancelSelectTextDraw(playerid);
	PlayerData[playerid][pSelectItem] = -1;
	forex(i, MAX_INVENTORY)
	{
		PlayerTextDrawHide(playerid, INDEXTD[playerid][i]);
		PlayerTextDrawHide(playerid, AMOUNTTD[playerid][i]);
		PlayerTextDrawHide(playerid, NAMETD[playerid][i]);
		PlayerTextDrawHide(playerid, MODELTD[playerid][i]);
	}
	return 1;	
}
static SendClientMessageEx(playerid, color, const text[], {Float, _}:...)
{
	static
	    args,
	    str[144];

	/*
     *  Custom function that uses #emit to format variables into a string.
     *  This code is very fragile; touching any code here will cause crashing!
	*/
	if ((args = numargs()) == 3)
	{
	    SendClientMessage(playerid, color, text);
	}
	else
	{
		while (--args >= 3)
		{
			#emit LCTRL 5
			#emit LOAD.alt args
			#emit SHL.C.alt 2
			#emit ADD.C 12
			#emit ADD
			#emit LOAD.I
			#emit PUSH.pri
		}
		#emit PUSH.S text
		#emit PUSH.C 144
		#emit PUSH.C str
		#emit PUSH.S 8
		#emit SYSREQ.C format
		#emit LCTRL 5
		#emit SCTRL 4

		SendClientMessage(playerid, color, str);

		#emit RETN
	}
	return 1;
}

main() 
{

}


#if defined FILTERSCRIPT

public OnFilterScriptInit()
{
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

#endif

public OnGameModeInit()
{
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	forex(i, MAX_INVENTORY)
	{
	    InventoryData[playerid][i][invExists] = false;
	    InventoryData[playerid][i][invModel] = 0;
	    InventoryData[playerid][i][invQuantity] = 0;
	}
	CreatePlayerInventory(playerid);
	PlayerData[playerid][pSelectItem] = -1;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	forex(i, MAX_INVENTORY)
	{
		if(playertextid == INDEXTD[playerid][i])
		{
			if(InventoryData[playerid][i][invExists])
			{
				PlayerData[playerid][pSelectItem] = i;
			}
			else
			{
				SendClientMessage(playerid, -1, "ERROR: There is no item on selected index!");
				Inventory_Close(playerid);
			}
		}
	}
	if(playertextid == USETD[playerid])
	{
		new id = PlayerData[playerid][pSelectItem];

		if(id == -1)
		{
			SendClientMessage(playerid, -1, "ERROR: You aren't selecting any item!");
			Inventory_Close(playerid);
		}
		else
		{
			new string[64];

		    strunpack(string, InventoryData[playerid][id][invItem]);
			CallLocalFunction("OnPlayerUseItem", "dds", playerid, id, string);
		}
	}
	if(playertextid == CLOSETD[playerid])
	{
		Inventory_Close(playerid);
	}
	if(playertextid == GIVETD[playerid])
	{
		new id = PlayerData[playerid][pSelectItem];
		if(id == -1)
		{
			Inventory_Close(playerid);
			SendClientMessage(playerid, -1, "ERROR: You aren't selecting any item!");
		}
		else
		{
			if(IsModelWeapon(InventoryData[playerid][id][invModel]))
				return SendClientMessage(playerid, -1, "ERROR: Use {FFFF00}/weapon give");

			ShowPlayerDialog(playerid, DIALOG_GIVETO, DIALOG_STYLE_INPUT, "Give Item", "Please enter the name or the ID of the player:", "Submit", "Cancel");
		}
	}
	return 1;
}

static IsPlayerNearPlayer(playerid, targetid, Float:radius)
{
	static
		Float:fX,
		Float:fY,
		Float:fZ;

	GetPlayerPos(targetid, fX, fY, fZ);

	return (GetPlayerInterior(playerid) == GetPlayerInterior(targetid) && GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(targetid)) && IsPlayerInRangeOfPoint(playerid, radius, fX, fY, fZ);
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_GIVETO)
	{
		if(response)
		{
		    static
		        userid = INVALID_PLAYER_ID,
				itemid = -1,
				string[32];

			if (sscanf(inputtext, "u", userid))
			    return ShowPlayerDialog(playerid, DIALOG_GIVETO, DIALOG_STYLE_INPUT, "Give Item", "Please enter the name or the ID of the player:", "Submit", "Cancel");

			if (userid == INVALID_PLAYER_ID)
			    return ShowPlayerDialog(playerid, DIALOG_GIVETO, DIALOG_STYLE_INPUT, "Give Item", "ERROR: Invalid player specified.\n\nPlease enter the name or the ID of the player:", "Submit", "Cancel");

		    if (!IsPlayerNearPlayer(playerid, userid, 6.0))
				return ShowPlayerDialog(playerid, DIALOG_GIVETO, DIALOG_STYLE_INPUT, "Give Item", "ERROR: You are not near that player.\n\nPlease enter the name or the ID of the player:", "Submit", "Cancel");

			itemid = PlayerData[playerid][pSelectItem];

			if (itemid == -1)
			    return 0;

			strunpack(string, InventoryData[playerid][itemid][invItem]);

			if (InventoryData[playerid][itemid][invQuantity] == 1)
			{
			    new id = Inventory_Add(userid, string, InventoryData[playerid][itemid][invModel]);

			    if (id == -1)
					return SendClientMessage(playerid, -1, "ERROR: That player doesn't have anymore inventory slots.");

			    SendClientMessageEx(userid, -1, "ITEM: %s has given you \"%s\" (added to inventory).", GetName(playerid), string);

				Inventory_Remove(playerid, string);
	  		}
			else
			{
				new str[152];
				format(str, sizeof(str), "Item: %s (Amount: %d)\n\nPlease enter the amount of this item you wish to give %s:", string, InventoryData[playerid][itemid][invQuantity], GetName(userid));
			    ShowPlayerDialog(playerid, DIALOG_GIVEAMOUNT, DIALOG_STYLE_INPUT, "Give Item", str, "Give", "Cancel");
			    PlayerData[playerid][pTarget] = userid;
			}			
		}
	}
	if(dialogid == DIALOG_GIVEAMOUNT)
	{
		if (response && PlayerData[playerid][pTarget] != INVALID_PLAYER_ID)
		{
		    new
		        userid = PlayerData[playerid][pTarget],
		        itemid = PlayerData[playerid][pSelectItem],
				string[32],
				str[352];

			strunpack(string, InventoryData[playerid][itemid][invItem]);

			if (isnull(inputtext))
				return format(str, sizeof(str), "Item: %s (Amount: %d)\n\nPlease enter the amount of this item you wish to give %s:", string, InventoryData[playerid][itemid][invQuantity], GetName(userid)),
				ShowPlayerDialog(playerid, DIALOG_GIVEAMOUNT, DIALOG_STYLE_INPUT, "Give Item", str, "Give", "Cancel");

			if (strval(inputtext) < 1 || strval(inputtext) > InventoryData[playerid][itemid][invQuantity])
			    return format(str, sizeof(str), "ERROR: You don't have that much.\n\nItem: %s (Amount: %d)\n\nPlease enter the amount of this item you wish to give %s:", string, InventoryData[playerid][itemid][invQuantity], GetName(userid)),
				ShowPlayerDialog(playerid, DIALOG_GIVEAMOUNT, DIALOG_STYLE_INPUT, "Give Item", str, "Give", "Cancel");

	        new id = Inventory_Add(userid, string, InventoryData[playerid][itemid][invModel], strval(inputtext));

		    if (id == -1)
				return SendClientMessage(playerid, -1, "ERROR: That player doesn't have anymore inventory slots.");

		    SendClientMessageEx(userid, -1, "ITEM: %s has given you \"%s\" (added to inventory).", GetName(playerid), string);

			Inventory_Remove(playerid, string, strval(inputtext));
		}
	}
	return 1;
}

forward OnPlayerUseItem(playerid, itemid, name[]);
public OnPlayerUseItem(playerid, itemid, name[])
{
	if(!strcmp(name, "Shotgun", true))
	{
		if(PlayerHasWeapon(playerid, 25))
			return SendClientMessage(playerid, -1, "ERROR: You've already have this weapon!");

		GiveWeaponToPlayer(playerid, 25, InventoryData[playerid][itemid][invQuantity]);
		SendClientMessageEx(playerid, -1, "{00FFFF}ITEM: {FFFFFF}You've equipped your {FFFF00}Shotgun {FFFFFF}with {FF0000}%d ammo", InventoryData[playerid][itemid][invQuantity]);
		
		Inventory_Remove(playerid, "Shotgun", -1);
		Inventory_Close(playerid);
	}
	else if(!strcmp(name, "Desert Eagle", true))
	{
		if(PlayerHasWeapon(playerid, 24))
			return SendClientMessage(playerid, -1, "ERROR: You've already have this weapon!");


		GiveWeaponToPlayer(playerid, 24, InventoryData[playerid][itemid][invQuantity]);
		SendClientMessageEx(playerid, -1, "{00FFFF}ITEM: {FFFFFF}You've equipped your {FFFF00}Desert Eagle {FFFFFF}with {FF0000}%d ammo", InventoryData[playerid][itemid][invQuantity]);
		Inventory_Remove(playerid, "Desert Eagle", -1);
		Inventory_Close(playerid);
	}
	else if(!strcmp(name, "MP5", true))
	{
		if(PlayerHasWeapon(playerid, 29))
			return SendClientMessage(playerid, -1, "ERROR: You've already have this weapon!");


		GiveWeaponToPlayer(playerid, 29, InventoryData[playerid][itemid][invQuantity]);
		SendClientMessageEx(playerid, -1, "{00FFFF}ITEM: {FFFFFF}You've equipped your {FFFF00}MP-5 {FFFFFF}with {FF0000}%d ammo", InventoryData[playerid][itemid][invQuantity]);
		Inventory_Remove(playerid, "MP5", -1);
		Inventory_Close(playerid);
	}
	else if(!strcmp(name, "AK-47", true))
	{
		if(PlayerHasWeapon(playerid, 30))
			return SendClientMessage(playerid, -1, "ERROR: You've already have this weapon!");


		GiveWeaponToPlayer(playerid, 30, InventoryData[playerid][itemid][invQuantity]);
		SendClientMessageEx(playerid, -1, "{00FFFF}ITEM: {FFFFFF}You've equipped your {FFFF00}AK-47 {FFFFFF}with {FF0000}%d ammo", InventoryData[playerid][itemid][invQuantity]);
		Inventory_Remove(playerid, "AK-47", -1);
		Inventory_Close(playerid);		
	}
	else  if(!strcmp(name, "Cellphone", true))
	{
		SendClientMessage(playerid, -1, "{00FFFF}ITEM: {FFFFFF}You've successfully equipped your cellphone!");
		Inventory_Close(playerid);
	}
	return 1;
}

stock ShowWeapon(playerid, targetid)
{
	new mstr[512], lstr[1024], weaponid, ammo, weapon[22];
	format(mstr, sizeof(mstr), "%s Weapon List", GetName(targetid));
	strcat(lstr, "Weapon\tAmmo\n");
	for(new i = 0; i < 13; i ++)
    {
        GetPlayerWeaponData(targetid, i, weaponid, ammo);
        GetWeaponName(weaponid, weapon, sizeof(weapon));
        if(weaponid > 0)
			format(lstr, sizeof(lstr), "%s\n%s\t%d", lstr, weapon, ammo);
    }
    ShowPlayerDialog(playerid, 27142, DIALOG_STYLE_TABLIST_HEADERS, mstr, lstr,"Close","");
    return 1;
}

static IsStoredWeapon(weaponid)
{
	if(weaponid == 24 || weaponid == 25 || weaponid == 30 || weaponid == 29)
		return 1;

	return 0;
}

static StoreWeapon(playerid, weaponid, ammo)
{
	if(weaponid == 24)
	{
		new id = Inventory_Add(playerid, "Desert Eagle", 348, ammo);
		if(id == -1)
			return SendClientMessage(playerid, -1,"ERROR: You don't have any inventory slot left!");

		ResetWeapon(playerid, 24);
		SendClientMessageEx(playerid, -1, "{00FFFF}WEAPON: {FFFFFF}You've successfully stored your {FF0000}Desert Eagle {FFFFFF}with {FFFF00}%d ammo", ammo);
	}
	else if(weaponid == 25)
	{
		new id = Inventory_Add(playerid, "Shotgun", 349, ammo);
		if(id == -1)
			return SendClientMessage(playerid, -1,"ERROR: You don't have any inventory slot left!");

		ResetWeapon(playerid, 25);
		SendClientMessageEx(playerid, -1, "{00FFFF}WEAPON: {FFFFFF}You've successfully stored your {FF0000}Shotgun {FFFFFF}with {FFFF00}%d ammo", ammo);
	}
	else if(weaponid == 30)
	{
		new id = Inventory_Add(playerid, "AK-47", 355, ammo);
		if(id == -1)
			return SendClientMessage(playerid, -1,"ERROR: You don't have any inventory slot left!");

		ResetWeapon(playerid, 30);
		SendClientMessageEx(playerid, -1, "{00FFFF}WEAPON: {FFFFFF}You've successfully stored your {FF0000}AK-47 {FFFFFF}with {FFFF00}%d ammo", ammo);
	}
	else if(weaponid == 29)
	{
		new id = Inventory_Add(playerid, "MP5", 353, ammo);
		if(id == -1)
			return SendClientMessage(playerid, -1,"ERROR: You don't have any inventory slot left!");

		ResetWeapon(playerid, 29);
		SendClientMessageEx(playerid, -1, "{00FFFF}WEAPON: {FFFFFF}You've successfully stored your {FF0000}MP-5 {FFFFFF}with {FFFF00}%d ammo", ammo);
	}
	return 1;
}

CMD:weapon(playerid, params[])
{
	new
	    type[24],
	    string[128];

	if (sscanf(params, "s[24]S()[128]", type, string))
	{
	    SendClientMessage(playerid, -1, "USAGE: /weapon [name]");
	    SendClientMessage(playerid, -1, "{FFFF00}NAME:{FFFFFF} give, store, view");
	    return 1;
	}
	if(!strcmp(type, "give", true))
	{
		new targetid;
		new
		    weaponid = GetWeapon(playerid),
		    ammo = GetPlayerAmmo(playerid);

		if (!weaponid)
		    return SendClientMessage(playerid, -1, "ERROR: You are not holding any weapon to give.");
		    
		if(sscanf(string, "u", targetid))
			return SendClientMessage(playerid, -1, "USAGE: /weapon give [playerid/name]");

		if(targetid == INVALID_PLAYER_ID)
			return SendClientMessage(playerid, -1, "ERROR: You're not close to that player!");

		if(!IsPlayerNearPlayer(playerid, targetid, 7.0))
			return SendClientMessage(playerid, -1, "ERROR: You're not close to that player!");

		if (targetid == playerid)
			return SendClientMessage(playerid, -1, "ERROR: You can't give yourself a weapon.");

		if (PlayerData[targetid][pGuns][g_aWeaponSlots[weaponid]] != 0)
		    return SendClientMessage(playerid, -1, "ERROR: That player has a weapon in the same slot already.");

		    
		new weaponname[18];
		GetWeaponName(weaponid, weaponname, sizeof(weaponname));
		ResetWeapon(playerid, weaponid);
		GiveWeaponToPlayer(targetid, weaponid, ammo);
		SendClientMessageEx(targetid, -1, "{00FFFF}WEAPON: {FFFFFF}You've received {FF0000}%s {FFFFFF}from {FFFF00}%s", weaponid, GetName(playerid));
	}	
	else if(!strcmp(type, "view", true))
	{
		new targetid;
		if(sscanf(string, "u", targetid))
		{
		    ShowWeapon(playerid, playerid);
		    return 1;
		}
		if(targetid == INVALID_PLAYER_ID)
			return SendClientMessage(playerid, -1, "ERROR: You're not close to that player!");
			
		if(!IsPlayerNearPlayer(playerid, targetid, 7.0))
			return SendClientMessage(playerid, -1, "ERROR: You're not close to that player!");

		ShowWeapon(targetid, playerid);	
	}
	else if(!strcmp(type, "store", true))
	{
		new weaponid = GetWeapon(playerid), ammo = GetPlayerAmmo(playerid);
		if(!weaponid)
			return SendClientMessage(playerid, -1, "ERROR: You aren't holding any weapons!");

		if(!IsStoredWeapon(weaponid))
			return SendClientMessage(playerid, -1, "ERROR: This weapon can't be stored!");

		StoreWeapon(playerid, weaponid, ammo);
	}
	return 1;
}
CMD:inventory(playerid)
{
	Inventory_Show(playerid);
	return 1;
}

CMD:setitem(playerid, params[])
{
	new
		item[32],
		amount;

	if (sscanf(params, "ds[32]", amount, item))
	    return SendClientMessage(playerid, -1, "USAGE: /setitem [amount] [item name]");

	for (new i = 0; i < sizeof(g_aInventoryItems); i ++) if (!strcmp(g_aInventoryItems[i][e_InventoryItem], item, true))
	{
        Inventory_Set(playerid, g_aInventoryItems[i][e_InventoryItem], g_aInventoryItems[i][e_InventoryModel], amount);

		return SendClientMessageEx(playerid, -1, "INFO: You have set your \"%s\" to %d.", item, amount);
	}
	SendClientMessage(playerid, -1, "ERROR: Invalid item name!.");
	return 1;
}

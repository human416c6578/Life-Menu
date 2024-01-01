#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <fun>
#include <cromchat>

#define PLUGIN "Life-System"	
#define VERSION "1.0"
#define AUTHOR "MrShark45"

#pragma tabsize 0

new g_cvar_life;
new g_cvar_alive_players;

public plugin_init(){
	
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_cvar_life = register_cvar("life_enable", "1");
	g_cvar_alive_players = register_cvar("life_players", "2");

	register_concmd("amx_revive", "cmd_revive",ADMIN_IMMUNITY,"- <player/@T/@CT>");
	register_clcmd("say", "say_handle");
	register_clcmd("say /lifemenu", "lifemenu");

	//Chat prefix
	CC_SetPrefix("&x04[DR]");
}

public say_handle(id){
	if(get_pcvar_num(g_cvar_life) == 0 || !is_user_alive(id) || cs_get_user_team(id) != CS_TEAM_CT)
		return PLUGIN_CONTINUE;

	new message[64], cmd[15], name[33];

	read_args(message,charsmax(message));
	remove_quotes(message);

	parse(message, cmd, 14, name, 32);

	if(!equali(cmd, "/life")) return PLUGIN_CONTINUE;

	find_target(id, name);

	return PLUGIN_CONTINUE;
}

public cmd_life(sender_id, receiver_id)
{
	if(cs_get_user_team(receiver_id) != CS_TEAM_CT || is_user_alive(receiver_id))
		return PLUGIN_HANDLED

	new info[6];
	format(info, charsmax(info), "%d", sender_id);

	new menu = menu_create("\yOferta Life:", "life_handler", 0 )
	menu_additem( menu, "Accepta", info, 0, -1 )
	menu_additem( menu, "Refuza", info, 0, -1 )
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_NEVER )
	menu_display( receiver_id, menu, 0)

	set_task( 5.0, "remove_offer", receiver_id )

	return PLUGIN_CONTINUE
}

public life_handler(receiver_id, menu, item)
{
	new sender_id, access;
	new info[6];

	menu_item_getinfo(menu, item, access, info, charsmax(info));
	sender_id = str_to_num(info);

	switch(item)
	{
		case 0:
		{
			receive_life(receiver_id, sender_id);
			menu_destroy(menu );
			return PLUGIN_HANDLED;
		}
		case 1:
		{
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
	}
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public receive_life(receiver_id, sender_id){
	if(!is_user_connected(sender_id) || !is_user_connected(sender_id) || !is_user_alive(sender_id))
		return;

	new origin[3], sender_name[32], receiver_name[32];

	get_user_origin(sender_id, origin, 0);
	origin[2] += 20;
	
	ExecuteHamB(Ham_CS_RoundRespawn, receiver_id);

	user_silentkill(sender_id);
	
	set_user_origin(receiver_id, origin);

	get_user_name(sender_id, sender_name, charsmax(sender_name));
	get_user_name(receiver_id, receiver_name, charsmax(receiver_name));

	CC_SendMessage(0, "&x04%s &x06a primit viata lui &x04%s!", receiver_name, sender_name);
}

public remove_offer(id)
{	
	client_cmd( id, "slot2;slot1" )
}

public cmd_revive(id)
{
	if(!(get_user_flags(id) & ADMIN_IMMUNITY)){
		console_print(id,"Nu ai acces la aceasta comanda!");
		return PLUGIN_CONTINUE;
	}

	new arg[32];
	read_argv(1,arg,31);
	if(equali(arg, "@CT")){
		revive_team(CS_TEAM_CT);
		return PLUGIN_CONTINUE;
	}
		
	if(equali(arg, "@T")){
		revive_team(CS_TEAM_T);
		return PLUGIN_CONTINUE;
	}
		

	if(get_alive_players()<=get_pcvar_num(g_cvar_alive_players)){
		console_print(id,"Nu sunt destui jucatori in viata!");
		return PLUGIN_CONTINUE;
	}
	
	new player = find_player("bghl", arg);
	if(!player)
		return PLUGIN_HANDLED;

	ExecuteHamB( Ham_CS_RoundRespawn, player );

	return PLUGIN_HANDLED;
}

public revive_team(CsTeams:team){
	for(new i = 0;i<33;i++){
		if(is_user_connected(i)){
			if(cs_get_user_team(i) == team && !is_user_alive(i)){
				ExecuteHamB( Ham_CS_RoundRespawn, i )
			}
		}
	}
}

public get_alive_players(){
	return get_playersnum_ex(GetPlayers_ExcludeDead | GetPlayers_MatchTeam, "CT");
}

public find_target(id, const str[]){
	new name[33],name2[33];

	get_user_name(id,name, 32);

	new player = find_player("bghl", str);

	if(!player || cs_get_user_team(player) != CS_TEAM_CT){
		CC_SendMessage(id, "&x06Playerul nu se afla pe server!");
		return PLUGIN_HANDLED;
	} 

	get_user_name(player, name2, 32);

	CC_SendMessage(0, "&x04%s &x06vrea sa-i ofere viata lui &x04%s!", name, name2);

	cmd_life(id, player);

	return PLUGIN_HANDLED;
}

public lifemenu(id){
	if(!is_user_alive(id)){
		CC_SendMessage(0, "&x06Trebuie sa fii in viata pentru a folosi aceasta comanda!");
		return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) != CS_TEAM_CT){
		CC_SendMessage(0, "&x06Trebuie sa fii CT pentru a folosi aceasta comanda!");
		return PLUGIN_HANDLED;
	}

	new name[33], players[MAX_PLAYERS], num, info[6];
	get_players(players, num, "bceh", "CT");
		
	new menu = menu_create("Life Menu", "menu_handler");
	for(new i;i<num;i++){
		format(info, charsmax(info), "%d", players[i]);
		get_user_name(players[i], name, charsmax(name));
		menu_additem(menu, name, info);
	}
	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item){
	if(!is_user_alive(id)){
		CC_SendMessage(0, "&x06Trebuie sa fii in viata pentru a folosi aceasta comanda!");
		return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) != CS_TEAM_CT){
		CC_SendMessage(0, "&x06Trebuie sa fii CT pentru a folosi aceasta comanda!");
		return PLUGIN_HANDLED;
	}

	new name[33], name2[33];

	new info[6], access;
	menu_item_getinfo(menu, item, access, info, charsmax(info));

	new target = str_to_num(info);

	get_user_name(id, name2, 32);
	get_user_name(target, name, 32);
	CC_SendMessage(0, "&x04%s &x06vrea sa-i ofere viata lui &x04%s!", name2, name);
	cmd_life(id, target);

	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}
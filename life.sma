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
new lifeSender;
new life_system;
new gAlivePlayers;

new players[33];

public plugin_init(){
	
	register_plugin(PLUGIN, VERSION, AUTHOR);

	life_system = register_cvar("life_system", "1");
	gAlivePlayers = register_cvar("min_alivePlayers", "2");
	register_concmd("amx_revive","cmd_revive",ADMIN_IMMUNITY,"- <player/@T/@CT>");
	register_clcmd("say", "say_handle");
	register_clcmd("say /lifemenu", "lifemenu");
	//Chat prefix
	CC_SetPrefix("&x04[DR]")  
}

public say_handle(id){
	if(get_pcvar_num(life_system) == 0 || !is_user_alive(id))
		return PLUGIN_CONTINUE;
	new msg[256]
	read_args(msg,charsmax(msg))
	remove_quotes(msg)
	new Arg0[15], Arg1[33];
	parse(msg,Arg0,14,Arg1,32)
	if(strcmp(Arg0,"/life") == 0){
		if(cs_get_user_team(id) == CS_TEAM_CT)
			find_target(id,Arg1);
	}
	return PLUGIN_CONTINUE;
}

public cmd_life(id, target)
{
	if(cs_get_user_team(target) != CS_TEAM_CT || is_user_alive(target))
		return PLUGIN_HANDLED

	new menu = menu_create("\yOferta Life:", "life_handler", 0 )
	menu_additem( menu, "Accepta", "1", 0, -1 )
	menu_additem( menu, "Refuza", "2", 0, -1 )
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_NEVER )
	menu_display( target, menu, 0)

	lifeSender = id;

	set_task( 5.0, "remove_offer", target )

	return PLUGIN_CONTINUE
}

public life_handler(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			receive_life( lifeSender, id )
			menu_destroy( menu )
			return PLUGIN_HANDLED
		}
		case 1:
		{
			menu_destroy( menu )
			return PLUGIN_HANDLED
		}
	}
	menu_destroy(menu)
	return PLUGIN_CONTINUE
}

public receive_life( id, target ){
	if( !is_user_connected( target ) || !is_user_connected( id ) || !is_user_alive(id) )
		return;
		
	new origin[ 3 ], name[ 32 ], target_name[ 32 ]
	
	ExecuteHamB( Ham_CS_RoundRespawn, target )

	user_silentkill( id )
		
	get_user_origin( id, origin, 0 )
	origin[ 2 ] += 20
	
	set_user_origin( target, origin )

	get_user_name( id, name, 31 )
	get_user_name( target, target_name, 31 )

	CC_SendMessage(0, "&x04%s &x06a primit viata lui &x04%s!", target_name, name);
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
		

	if(checkPlayersAlive()<=get_pcvar_num(gAlivePlayers)){
		console_print(id,"Nu sunt destui jucatori in viata!");
		return PLUGIN_CONTINUE;
	}
	new target = cmd_target(id,arg,3);
	if(!target)
		return PLUGIN_HANDLED;
	if(is_user_alive(target)){
		console_print(id,"Player is already alive !");
		return PLUGIN_HANDLED;
	}

	ExecuteHamB( Ham_CS_RoundRespawn, target )

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

public checkPlayersAlive(){
	new playersAlive;
	new i;
	for(i = 0 ;i<=33;i++)
		if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_CT)
			playersAlive++;
	return playersAlive;
}

public find_target(id, const str[]){
	new Name[33],Name2[33], j = 0;
	get_user_name(id,Name, 32);
	for(new i = 1;i<33;i++){
		if(!is_user_connected(i))
			continue;
		get_user_name(i,Name2, 32);
		if(containi(Name2, str) > -1){
			if(cs_get_user_team(i) == CS_TEAM_CT && !is_user_alive(i) && id != i){
				players[j] = i;
				j++;
			}
		}
	}
	//J is number of players found
	if(j==0){
		CC_SendMessage(id, "&x06Playerul nu se afla pe server sau este inca in viata!");
	}
	//if there's only one , it'll pop up a menu for that player to receive the life
	else if(j==1){
		if(players[0] < 0 || is_user_alive(players[0]) || cs_get_user_team(players[0]) != CS_TEAM_CT)
			return PLUGIN_HANDLED;
		get_user_name(players[0], Name2, 32);
		CC_SendMessage(0, "&x04%s &x06vrea sa-i ofere viata lui &x04%s!", Name, Name2);
		cmd_life(id, players[0]);
	}
	//if there are more players found , a menu will pop out with all the results found for you to choose
	else{
		new menu = menu_create("Life Menu", "menu_handler2");
		for(new i=0;i<j;i++){
			get_user_name(players[i],Name2, 32);
			menu_additem(menu, Name2, "")
		}
		menu_display(id, menu, 0);
	}

	return PLUGIN_HANDLED;
}
public menu_handler2(id, menu, item){
	new Name[33], Name2[33];
	get_user_name(id,Name2, 32);
	get_user_name(players[item], Name, 32);
	CC_SendMessage(0, "&x04%s &x06vrea sa-i ofere viata lui &x04%s!", Name2, Name);
	cmd_life(id, players[item]);

	menu_destroy(menu);
	return PLUGIN_CONTINUE;
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
		
	new Name[33],j = 0;
	new menu = menu_create("Life Menu", "menu_handler");
	for(new i=1;i<33;i++){
		if(!is_user_connected(i))
			continue;
		if(cs_get_user_team(i) == CS_TEAM_CT && !is_user_alive(i) && id != i){
			get_user_name(i,Name, 32);
			menu_additem(menu, Name, "")
			players[j] = i;
			j++;
		}
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
	new Name[33], Name2[33];
	get_user_name(id,Name2, 32);
	get_user_name(players[item], Name, 32);
	CC_SendMessage(0, "&x04%s &x06vrea sa-i ofere viata lui &x04%s!", Name2, Name);
	cmd_life(id, players[item]);

	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}
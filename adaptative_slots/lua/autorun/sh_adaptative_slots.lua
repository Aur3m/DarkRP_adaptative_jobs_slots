AddCSLuaFile()

AdaptativeSlots = AdaptativeSlots or {}
AdaptativeSlots.Config = AdaptativeSlots.Config or {}
AdaptativeSlots.Config.Groups = AdaptativeSlots.Config.Groups or {}

local groups = AdaptativeSlots.Config.Groups

AdaptativeSlots.Config.NotLimitedGroups = {
	'vip'
}

groups[ 'TueursAGages' ] = {
	jobs = {
		'Tueur a gages'
	},
	min = 1,
	max = 4
}

groups[ 'Gendarmerie' ] = {
	jobs = {
		'Gendarme 2nd classe',
		'Brigadier',
		'Gendarme',
		'Adjudant',
		'Adjudant-Chef',
		'Sous-Lieutenant',
		'Lieutenant',
		'Commandant',
		'Lieutenant-Colonel',
		'Colonel',
		'GIGN',
		'Sous-Officier du GIGN',
		'Officier du GIGN',
		'Co-Gérant du GIGN',
		'Gerant du GIGN',
		'Sniper du GIGN',
		'PSIG'
	},
	min = 4,
	max = 28
}

groups[ 'Cuisinier' ] = {
	jobs = {
		'Cuisinier'
		},
	min = 1,
	max = 4
}

groups[ 'Contrebandier' ] = {
	jobs = {
		'Contrebandier',
		},
	min = 2,
	max = 5
}

groups[ 'Taxi' ] = {
	jobs = {
		'Chauffeur de Ferry / Taxi',
		'Banquier'
		},
	min = 4,
	max = 8
}


groups[ 'Concessionaire' ] = {
	jobs = {
		'Concessionaire'
		},
	min = 1,
	max = 2
}

groups[ 'chaumage' ] = {
	jobs = {
		'Agent Municipal'
		'Apiculteur'
		},
	min = 3,
	max = 5
}

groups[ 'Livreur' ] = {
	jobs = {
		'Livreur UPS'
		},
	min = 1,
	max = 2
}

groups[ 'Securiforce' ] = {
	jobs = {
		'Agent de securite'
		},
	min = 4,
	max = 10
}

groups[ 'PDG Verisure' ] = {
	jobs = {
		'PDG Verisure'
		},
	min = 1,
	max = 2
}

groups[ 'Fermier' ] = {
	jobs = {
		'Fermier'
	min = 2,
	max = 2
}

groups[ 'Garagiste' ] = {
	jobs = {
		'Garagiste'
		},
	min = 2,
	max = 4
}


local function GetJobGroup( iTeamNumber )
	local sTeamName = team.GetName( iTeamNumber )

	local group, min, max
	for groupname, groupinfos in pairs( groups ) do
		if table.HasValue( groupinfos.jobs, sTeamName ) then
			group = groupname
			max = groupinfos.max
			min = groupinfos.min
			break
		end
	end

	return group, min, max
end

local function GetPlayersInGroup( sGroup )
	if not groups[ sGroup ] then return end

	local iTotal = 0

	for iTeamNumber, tTeamInfos in pairs( team.GetAllTeams() ) do
		if table.HasValue( groups[sGroup].jobs, team.GetName( iTeamNumber ) ) then
			iTotal = iTotal + team.NumPlayers( iTeamNumber )
		end
	end

	return iTotal
end

local function RecalculateSlots( change )
	local iTotalPlayers = player.GetCount() + ( change or 0 )
	local iMaxPlayers = game.MaxPlayers()

	local fPercentage = iTotalPlayers / iMaxPlayers

	for iTeamNumber, tInfos in pairs( RPExtraTeams ) do 
		local group, min, max = GetJobGroup( iTeamNumber )
		if group then
			local diff = max - min
			local newslotsTh = math.Round( diff * fPercentage + min )

			newslotsMax = math.Clamp( newslotsTh, min, max )
		
			local iPlayerInGroup = GetPlayersInGroup( group )

			newslots = newslotsMax - iPlayerInGroup + team.NumPlayers( iTeamNumber )
			tInfos.max = newslots
		end
	end
end

hook.Add( "PlayerConnect", "PlayerConnect.Adaptative_Slots", function()
	RecalculateSlots( 1 )
end)

hook.Add( "PostGamemodeLoaded", "PostGamemodeLoaded.Adaptative_Slots", function()
	RecalculateSlots()
end)

if SERVER then
	util.AddNetworkString( "Adaptative_Slots:RecalculateSlots" )

	hook.Add( "PlayerDisconnected", "PlayerDisconnected.Adaptative_Slots", function()
		RecalculateSlots( -1 )

		net.Start( "Adaptative_Slots:RecalculateSlots" )
		net.Broadcast()
	end)

	hook.Add( "playerCanChangeTeam", "playerCanChangeTeam.Adaptative_Slots", function( ply, newTeam )
		if table.HasValue( AdaptativeSlots.Config.NotLimitedGroups, ply:GetUserGroup() ) then
			return true
		end

		local sGroup, iMin, iMax = GetJobGroup( newTeam )

		if not sGroup then
			local sOldGroup = GetJobGroup( ply:Team() )
			
			if sOldGroup then
				RecalculateSlots()

				net.Start( "Adaptative_Slots:RecalculateSlots" )
				net.Broadcast()
			end

			return true
		end

		local iPlayerInGroup = GetPlayersInGroup( sGroup )

		if iPlayerInGroup >= iMax then
			return false, "Il n'y a plus de slots disponibles dans le groupe de métier " .. sGroup
		end

		RecalculateSlots()

		net.Start( "Adaptative_Slots:RecalculateSlots" )
		net.Broadcast()

		return true
	end )
end

if CLIENT then
	net.Receive("Adaptative_Slots:RecalculateSlots", function()
		timer.Simple( 0.2, function() RecalculateSlots() end )
	end )
end
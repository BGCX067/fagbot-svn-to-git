--[[=======================================-

 * fagBOT

-=======================================]]--
local fag					= {}
local version				= "3.4.0"

if not CLIENT then return end
if C then _G.C = nil end 
local _R = debug.getregistry()

white		= Color(255,255,255,255)
black		= Color(0,0,0,255)
orange		= Color(255,165,0,255)
red			= Color(255,0,0,255)
green		= Color(0,255,0,255)
blue		= Color(0,0,255,255)
yellow		= Color(255,255,0,255)

local math 					= _G.math
local string 				= _G.string
local hook 					= _G.hook
local table 				= _G.table
local timer 				= _G.timer
local surface 				= _G.surface
local concommand 			= _G.concommand
local cvars 				= _G.cvars
local ents 					= _G.ents
local player 				= _G.player
local team 					= _G.team
local util 					= _G.util
local draw 					= _G.draw
local usermessage 			= _G.usermessage
local vgui 					= _G.vgui
local http 					= _G.http
local cam 					= _G.cam
local render 				= _G.render

local local_rcc				= RunConsoleCommand
local local_gcvn			= GetConVarNumber
local local_cc				= _R.Player.ConCommand
local local_hadd			= hook.Add
local local_hrem			= hook.Remove
local local_ccadd			= concommand.Add
local local_ccrem			= concommand.Remove

local safeview = debug.getregistry().CUserCmd.SetViewAngles

fag.friends					= {}
fag.traitors				= {}
fag.spectators				= {}
fag.recoils					= {}

fag.hooks					= {}

function fag:rand()
	local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local rand = ""
	for i = 1, 32 do
		rand = rand..string.char(string.byte(chars, math.random(1, string.len(chars))))
	end
	return tostring(rand)
end

surface.CreateFont("faggot", {font = "Arial", size = 14, weight = 1000, antialias = false, outline = true})

TTT = string.find(GAMEMODE.Name, "Terror")

Mat = CreateMaterial(string.lower(fag:rand()), "VertexLitGeneric", {["$basetexture"] = "models/debug/debugwhite", ["$model"] = 1, ["$ignorez"] = 1})

function fag:IsTraitor(v)
	if TTT and v != LocalPlayer() and table.HasValue(fag.traitors, v) then return true end
	return false
end

function fag:chat(col, msg)
	chat.AddText(orange, "[fag] ", col, msg)
end
function fag:print(col, msg)
	MsgC(orange, "[fag] ", msg, "\n")
end

function fag:ahook(event, func)
	name = fag:rand()
	fag:print(green, "[+] Hook | "..event.." | "..name)
	table.insert(fag.hooks, name)
	return local_hadd(event, name, func)
end
function fag:rhook(event, func)
	fag:print(red, "[-] Hook | "..event)
	return local_hrem(event, func)
end

function fag:acmd(cmd, func, desc)
	fag:print(green, "[+] Command | "..cmd.." | "..desc)
	return local_ccadd(cmd, func)
end
function fag:rcmd(cmd)
	fag:print(red, "[-] Command | "..cmd)
	return local_ccrem(cmd)
end

function fag:acvar(name)
	CreateClientConVar("fag_"..name, 0)
end

fag:acvar("aim_fov")
fag:acvar("aim_los")
fag:acvar("aim_mode")
fag:acvar("aim_trigger")
fag:acvar("aim_prediction")
fag:acvar("aim_smooth")
fag:acvar("aim_glow")
fag:acvar("norecoil")
fag:acvar("novisualrecoil")
fag:acvar("esp")
fag:acvar("esp_dist")
fag:acvar("esp_team")
fag:acvar("esp_target")
fag:acvar("esp_box")
fag:acvar("esp_tracer")
fag:acvar("esp_name")
fag:acvar("esp_health")
fag:acvar("esp_weapon")
fag:acvar("esp_distance")
fag:acvar("wallhack")
fag:acvar("wallhack_player")
fag:acvar("wallhack_entity")
fag:acvar("wallhack_entity_ttt")
fag:acvar("wallhack_entity_ttt_ragdoll")
fag:acvar("wallhack_entity_darkrp")
fag:acvar("bunnyhop")
fag:acvar("freecam_speed")
fag:acvar("infvoice")

function fag:cvar(cvar)
	return local_gcvn("fag_"..cvar) >= 1
end

function fag:alive(v)
	if v:IsValid() and v:Alive() and v:Health() > 0 and v:Health() != 0 and v:Team() != 1002 and v != LocalPlayer() and LocalPlayer():Alive() then return true end
	return false
end

function fag:IsCloseEnough(ent)
	local dist = ent:GetPos():Distance(LocalPlayer():GetPos())
	if (dist <= local_gcvn("fag_esp_dist")) and (ent:GetPos() != Vector(0, 0, 0)) then return true end
	return false
end

function fag:taters()
	local fag_spectators = ""
	local fag_admins = ""
	local fag_superadmins = ""
	local fag_moderators = ""
	for _,v in pairs(player.GetAll()) do
		if v:IsPlayer() then
			if v != LocalPlayer() and v:GetObserverMode() == OBS_MODE_IN_EYE or v:GetObserverMode() == OBS_MODE_CHASE and v:GetObserverTarget() == LocalPlayer() then
				fag_spectators = fag_spectators..", "..v:Nick()
			end
			if v:IsAdmin() and !v:IsSuperAdmin() then
				fag_admins = fag_admins..", "..v:Nick()
			end
			if v:IsSuperAdmin() then
				fag_superadmins = fag_superadmins..", "..v:Nick()
			end
			if v:IsUserGroup("operator") or v:IsUserGroup("moderator") then
				fag_moderators = fag_moderators..", "..v:Nick()
			end 
		end
		if IsValid(v:GetObserverTarget()) and v:GetObserverTarget():IsPlayer() and v:GetObserverTarget() == LocalPlayer() then
			if !table.HasValue(fag.spectators, v) then
				table.insert(fag.spectators, v)
				fag:chat(red, v:Nick().." is currently spectating you")
			end
		end
	end
	for k,v in pairs(fag.spectators) do
		if !IsValid(v) or !IsValid(v:GetObserverTarget()) or !v:GetObserverTarget():IsPlayer() or v:GetObserverTarget() != LocalPlayer() then
			table.remove(fag.spectators, k)
			fag:chat(green, v:Nick().." is no longer spectating you")
		end
	end
	if TTT and LocalPlayer():Alive() and LocalPlayer():Health() != 0 and LocalPlayer():Health() > 0 and LocalPlayer():Team() != 1002 then
		if (fag_spectators != "") then
			fag_spectators = string.sub(fag_spectators, 3, string.len(fag_spectators))
			draw.DrawText("Spectators: "..fag_spectators, "faggot", 5, 35, orange, 0)
		else
			draw.DrawText("No one is spectating you", "faggot", 5, 35, green, 0)
		end
	end
	if (fag_admins != "") then
		fag_admins = string.sub(fag_admins, 3, string.len(fag_admins))
		draw.DrawText("[A]: "..fag_admins, "faggot", 5, 57, red, 0)
	else
		draw.DrawText("[A]: None", "faggot", 5, 57, green, 0)
	end
	if (fag_superadmins != "") then
		fag_superadmins = string.sub(fag_superadmins, 3, string.len(fag_superadmins))
		draw.DrawText("[SA]: "..fag_superadmins, "faggot", 5, 68, red, 0)
	else
		draw.DrawText("[SA]: None", "faggot", 5, 68, green, 0)
	end
	if (fag_moderators != "") then
		fag_moderators = string.sub(fag_moderators, 3, string.len(fag_moderators))
		draw.DrawText("[M]: "..fag_moderators, "faggot", 5, 79, red, 0)
	else
		draw.DrawText("[M]: None", "faggot", 5, 79, green, 0)
	end
end

function ShowNotifi()
        -- now spectating
        for k, v in pairs(player.GetAll()) do
                if (IsValid(v:GetObserverTarget()) and v:GetObserverTarget():IsPlayer() and v:GetObserverTarget() == LocalPlayer()) then
                        if(not table.HasValue(Hera.spectators, v)) then
                                table.insert(Hera.spectators, v);
                                if GetConVarNumber("Hera_MISC_ShowSpec") == 1 then
                                        Hera.Notify(true,red,""..v:Nick().." is now spectating you!")
                                        surface.PlaySound("buttons/blip1.wav")
                                end
                        end
                end
        end
        -- no longer spectating
        for k, v in pairs(Hera.spectators) do
                if (not IsValid(v) or not IsValid(v:GetObserverTarget()) or not v:GetObserverTarget():IsPlayer() or (v:GetObserverTarget() ~= LocalPlayer())) then
                        table.remove(Hera.spectators, k);
                        if GetConVarNumber("Hera_MISC_ShowSpec") == 1 then
                                Hera.Notify(true,green,""..v:Nick().." is no longer spectating you!")
                        end
                end
        end
        -- admin join
        if GetConVarNumber("Hera_MISC_ShowAdmins") == 1 then
                for k, v in pairs(player.GetAll()) do
                        if (v:IsAdmin() and not table.HasValue(Hera.admins, v)) then
                                table.insert(Hera.admins, v);
                                Hera.Notify(true,white,"Admin " .. v:Nick() .. " has joined!")
                                surface.PlaySound("buttons/blip1.wav");
                        end
                end
        end
end
--[[=======================================-

 * Aimbot

-=======================================]]--
local aimbot = nil

fag.prediction = {
["weapon_crossbow"] = 3485,
["weapon_pistol"] = 40000,
["weapon_357"] = 20500,
["weapon_smg"] = 39000,
["weapon_ar2"] = 39000,
["weapon_shotgun"] = 35000,
["weapon_rpg"] = 0,	
}

function fag.nr()
	if fag:cvar("norecoil") and IsValid(LocalPlayer()) and LocalPlayer():Alive() and LocalPlayer():Health() > 0 and IsValid(LocalPlayer():GetActiveWeapon()) then
		if LocalPlayer():GetActiveWeapon().Primary and LocalPlayer():GetActiveWeapon().Primary.Recoil then
			fag.recoils[LocalPlayer():GetActiveWeapon():EntIndex()] = LocalPlayer():GetActiveWeapon().Primary.Recoil
			LocalPlayer():GetActiveWeapon().Primary.Recoil = 0
		end
	end
end

function fag.nvr(ply, pos, angles, fov)
   if fag:cvar("novisualrecoil") and LocalPlayer():Alive() and LocalPlayer():Health() > 0 and LocalPlayer():Team() != 1002 then
	   return GAMEMODE:CalcView( ply, LocalPlayer():EyePos(), LocalPlayer():EyeAngles(), fov, 0.1 )
   end
end

function InFov(v)
	local fov = local_gcvn("fag_aim_fov")
	if fov != 180 then
		local lpang = LocalPlayer():GetAngles()
		local ang = (v:GetAttachment(v:LookupAttachment("eyes")).Pos - LocalPlayer():EyePos()):Angle()
		local ady = math.abs(math.NormalizeAngle(lpang.y - ang.y))
		local adp = math.abs(math.NormalizeAngle(lpang.p - ang.p))
		if( ady > fov or adp > fov ) then return false end
	end
	return true
end

function HasLOS(ent)
	if !fag:cvar("aim_los") then return true end
	local trace = util.TraceLine( {
		startp = LocalPlayer():GetShootPos(),
		endp = ent:GetAttachment(ent:LookupAttachment("eyes")).Pos,
		filter = {LocalPlayer(), fag.friends, e},
		mask = MASK_SHOT + CONTENTS_WINDOW
	} )
	if (( trace.Fraction >= 0.99 )) then return true end
	return false
end

function AimPrediction(pos, pl)
	if IsValid(pl) and type(pl:GetVelocity()) == "Vector" and pl.GetPos and type(pl:GetPos()) == "Vector" then
		local distance = LocalPlayer():GetPos():Distance(pl:GetPos())
		local weapon = (LocalPlayer().GetActiveWeapon and (IsValid( LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass()))	
		if weapon and fag.prediction[weapon] then
			local time = distance / fag.prediction[weapon]
			return pos + pl:GetVelocity() * time
		end
	end
	return pos
end

function Targets()
	local target
	local distance = math.huge
	if target == nil then target = LocalPlayer() else target = target end
	for k,v in pairs(player.GetAll()) do
		if fag:alive(v) and InFov(v) and HasLOS(v) and !table.HasValue(fag.friends, v) then
			local ePos, oldPos, myAngV = v:EyePos():ToScreen(), target:EyePos():ToScreen(), LocalPlayer():GetAngles()
			local x, y = ScrW(), ScrH()
			local angA, angB = 0			
			local thedist = v:GetPos():DistToSqr(LocalPlayer():GetPos())
			angA = math.Dist(x / 2, y / 2, oldPos.x, oldPos.y)
			angB = math.Dist(x / 2, y / 2, ePos.x, ePos.y)
			if fag:cvar("aim_mode") then
				if (angB <= angA) then
					target = v
				elseif target == LocalPlayer() then
					target = v
				end
			else
				if (thedist < distance) then
					distance = thedist
					target = v
				end					
			end
		end
	end
	return target
end

function fag.aim(ucmd)
	if aimbot then
		local target = Targets()
			
		if target and fag:alive(target) and target != LocalPlayer() then
			local ang = Angle(0,0,0)
			local initial = nil
			
			if fag:cvar("aim_prediction") then
				initial = AimPrediction(target:GetAttachment(target:LookupAttachment("eyes")).Pos)
				initial = initial + target:GetVelocity() * ( 1 / 66 ) - LocalPlayer():GetVelocity() * ( 1 / 66 )
			else
				initial = target:GetAttachment(target:LookupAttachment("eyes")).Pos
				initial = initial + target:GetVelocity() / 50 - LocalPlayer():GetVelocity() / 50
			end
			
			final = (initial - LocalPlayer():GetShootPos()):GetNormal():Angle()
			final.p = math.NormalizeAngle(final.p)
			final.y = math.NormalizeAngle(final.y)
			
			eyes = LocalPlayer():EyeAngles()
			if fag:cvar("aim_smooth") then
				local x = math.Approach(eyes.p, final.p, local_gcvn("fag_aim_smooth") / 10)
				local y = math.Approach(eyes.y , final.y, local_gcvn("fag_aim_smooth") / 10)
				ang = Angle(x, y, 0)
			else
				ang = Angle(final.p, final.y, 0)
			end
		
			if fag:alive(target) then
				safeview(ucmd, ang)
				if fag:cvar("aim_trigger") and LocalPlayer():GetActiveWeapon():IsValid() then local_rcc("+attack") end
				if fag:cvar("aim_glow") then halo.Add({target}, yellow, 2, 2, 1, true, true) end
			end
		end
	end
end

function fag:aon()
	aimbot = true
end

function fag:aoff()
	aimbot = false
	target = nil
	local_rcc("-attack")
	shooting = false
end

--[[=======================================-

 * ESP

-=======================================]]--
function fag:esp()
	if fag:cvar("esp") then
		draw.DrawText("ESP Distance: "..local_gcvn("fag_esp_dist"), "faggot", 5, 2, white, 0)
		for k,v in pairs(player.GetAll()) do
			if fag:IsCloseEnough(v) and fag:alive(v) then
				local pos = v:GetPos():ToScreen()
				local dist = v:GetPos():Distance(LocalPlayer():GetPos())
				if (pos.visible and v != LocalPlayer() and v.Nick and v.Health and v.GetActiveWeapon and v:GetActiveWeapon().GetPrintName) then
				
				if fag:cvar("esp_target") then
					if player.GetByID(local_gcvn("fag_esp_target")):IsValid() then
						v = player.GetByID(local_gcvn("fag_esp_target"))
						draw.DrawText("Targeting "..v:Name().." ("..v:EntIndex()..")", "faggot", 5, 13, white, 0)
					else
						GetConVar("fag_esp_target"):SetValue(0)
						fag:print(red, "There is no one with the ID "..local_gcvn("fag_esp_target")..". fag_esp_target has been set back to 0.")
					end
				end
				
				local alpha = math.Clamp((local_gcvn("fag_esp_dist")/2 - v:GetPos():Distance(LocalPlayer():GetShootPos())) * (255 / (local_gcvn("fag_esp_dist")/2 - 100)), 30, 255)
				local tcol = white
				if (v:Health() >= 91) then tcol = Color(0, 255, 0, alpha)
				elseif (v:Health() <= 90 and v:Health() >= 71) then tcol = Color(223, 255, 0, alpha)					
				elseif (v:Health() <= 70 and v:Health() >= 46) then tcol = Color(255, 255, 0, alpha)		
				elseif (v:Health() <= 45 and v:Health() >= 21) then tcol = Color(255, 165, 0, alpha)					
				elseif (v:Health() <= 20 and v:Health() >= 1) then tcol = Color(255, 0, 0, alpha)
				end
				
				local function coords(v)
					local min, max = v:OBBMins(), v:OBBMaxs()
					local corners = {
						Vector(min.x, min.y, min.z),
						Vector(min.x, min.y, max.z),
						Vector(min.x, max.y, min.z),
						Vector(min.x, max.y, max.z),
						Vector(max.x, min.y, min.z),
						Vector(max.x, min.y, max.z),
						Vector(max.x, max.y, min.z),
						Vector(max.x, max.y, max.z)
					}
					local minX, minY, maxX, maxY = ScrW() * 2, ScrH() * 2, 0, 0
					for _, corner in pairs(corners) do
						local onScreen = v:LocalToWorld(corner):ToScreen()
						minX, minY = math.min(minX, onScreen.x), math.min(minY, onScreen.y)
						maxX, maxY = math.max(maxX, onScreen.x), math.max(maxY, onScreen.y)
					end
					
					local ang = Angle( 0, LocalPlayer():EyeAngles().y, 0 )
					local nom = v:GetPos()
					local mon = nom + Vector( 0, 0, LocalPlayer():OBBMaxs()[3] )			
					local BOXPOS1 = Vector( 16, 16, 0 )
					BOXPOS1:Rotate( ang )
					BOXPOS1 = ( nom + BOXPOS1 ):ToScreen()
					local BOXPOS2 = Vector( 16, -16, 0 )
					BOXPOS2:Rotate( ang )
					BOXPOS2 = ( nom + BOXPOS2 ):ToScreen()
					local BOXPOS3 = Vector( -16, -16, 0 )
					BOXPOS3:Rotate( ang )
					BOXPOS3 = ( nom + BOXPOS3 ):ToScreen()
					local BOXPOS4 = Vector( -16, 16, 0 )
					BOXPOS4:Rotate( ang )
					BOXPOS4 = ( nom + BOXPOS4 ):ToScreen()
					local BOXPOS5 = Vector( 16, 16, 0 )
					BOXPOS5:Rotate( ang )
					BOXPOS5 = ( mon + BOXPOS5 ):ToScreen()
					local BOXPOS6 = Vector( 16, -16, 0 )
					BOXPOS6:Rotate( ang )
					BOXPOS6 = ( mon + BOXPOS6 ):ToScreen()
					local BOXPOS7 = Vector( -16, -16, 0 )
					BOXPOS7:Rotate( ang )
					BOXPOS7 = ( mon + BOXPOS7 ):ToScreen()
					local BOXPOS8 = Vector( -16, 16, 0 )
					BOXPOS8:Rotate( ang )
					BOXPOS8 = ( mon + BOXPOS8 ):ToScreen()
					return minX, minY, maxX, maxY, BOXPOS1, BOXPOS2, BOXPOS3, BOXPOS4, BOXPOS5, BOXPOS6, BOXPOS7, BOXPOS8
				end
				local Box1x, Box1y, Box2x, Box2y, BOXPOS1, BOXPOS2, BOXPOS3, BOXPOS4, BOXPOS5, BOXPOS6, BOXPOS7, BOXPOS8 = coords(v)
				surface.SetDrawColor(tcol)
				if fag:cvar("esp_box") then
					surface.DrawLine(BOXPOS1.x, BOXPOS1.y, BOXPOS2.x, BOXPOS2.y)
					surface.DrawLine(BOXPOS2.x, BOXPOS2.y, BOXPOS3.x, BOXPOS3.y)
					surface.DrawLine(BOXPOS3.x, BOXPOS3.y, BOXPOS4.x, BOXPOS4.y)
					surface.DrawLine(BOXPOS4.x, BOXPOS4.y, BOXPOS1.x, BOXPOS1.y)
				
					surface.DrawLine(BOXPOS5.x, BOXPOS5.y, BOXPOS6.x, BOXPOS6.y)
					surface.DrawLine(BOXPOS6.x, BOXPOS6.y, BOXPOS7.x, BOXPOS7.y)
					surface.DrawLine(BOXPOS7.x, BOXPOS7.y, BOXPOS8.x, BOXPOS8.y)
					surface.DrawLine(BOXPOS8.x, BOXPOS8.y, BOXPOS5.x, BOXPOS5.y)
				
					surface.DrawLine(BOXPOS1.x, BOXPOS1.y, BOXPOS5.x, BOXPOS5.y)
					surface.DrawLine(BOXPOS2.x, BOXPOS2.y, BOXPOS6.x, BOXPOS6.y)
					surface.DrawLine(BOXPOS3.x, BOXPOS3.y, BOXPOS7.x, BOXPOS7.y)
					surface.DrawLine(BOXPOS4.x, BOXPOS4.y, BOXPOS8.x, BOXPOS8.y)
				else
					surface.DrawLine(Box1x, Box1y, Box2x, Box1y)
					surface.DrawLine(Box1x, Box2y, Box2x, Box2y)
					surface.DrawLine(Box1x, Box1y, Box1x, Box2y)
  					surface.DrawLine(Box2x, Box1y, Box2x, Box2y)
				end
				local eyes = v:GetAttachment(v:LookupAttachment("eyes")).Pos:ToScreen()
				if fag:cvar("esp_tracer") and InFov(v) then
					surface.DrawLine(ScrW() / 2, ScrH() / 2, eyes.x, eyes.y)
				end
				
				if fag:cvar("esp_name") then draw.SimpleTextOutlined(v:Nick().." ("..v:EntIndex( )..")", "faggot", Box2x + 5, Box1y + 13, tcol, 0, 4, 1, tcol) end
				if not TTT then
					draw.DrawText(team.GetName(v:Team()), "faggot", Box2x + 5, Box1y + 24, tcol, 0)
				elseif fag:IsTraitor(v) then
					draw.DrawText("TRAITOR", "faggot", Box2x + 5, Box1y + 24, Color(255, 0, 0, alpha), 0)
				elseif v:IsDetective() then
					draw.DrawText("DETECTIVE", "faggot", Box2x + 5, Box1y + 24, Color(0, 0, 255, alpha), 0)
				end
				if fag:cvar("esp_health") then draw.DrawText("HP: "..tostring(v:Health()).." ("..tostring(v:Armor())..")", "faggot", Box2x + 5, Box1y + 46, tcol, 0) end
				if fag:cvar("esp_weapon") then draw.DrawText("WEAPON: "..v:GetActiveWeapon():GetPrintName(), "faggot", Box2x + 5, Box1y + 57, tcol, 0) end
				if fag:cvar("esp_distance") then draw.DrawText("DISTANCE: "..math.Round(dist), "faggot", Box2x + 5, Box1y + 68, tcol, 0) end
				end
			end
		end
	end
end

function fag:raiseesp()
	local_rcc("fag_esp_dist", local_gcvn("fag_esp_dist") + 1000)
end

function fag:loweresp()
	if fag:cvar("esp_dist") then
		local_rcc("fag_esp_dist", local_gcvn("fag_esp_dist") - 1000)
	else
		fag:chat(red, "Cannot lower ESP distance, already 0 or lower")
	end
end

function fag:raisetarget()
	local_rcc("fag_esp_target", local_gcvn("fag_esp_target") + 1)
end

function fag:lowertarget()
	if fag:cvar("esp_target") then
		local_rcc("fag_esp_target", local_gcvn("fag_esp_target") - 1)
	else
		fag:chat(red, "Cannot lower ESP target, already 0")
	end
end

function fag:id()
	fag.print("List of players and IDs:")
	for _,v in pairs(player.GetAll()) do
		if v != LocalPlayer() then
			fag:Print(yellow, v:Nick().." ("..v:EntIndex()..")")
		end
	end
end

--[[=====================================-

 * Wallhack

-=====================================]]--
function TableSortByDistance(former, latter) return latter:GetPos():Distance(LocalPlayer():GetPos()) > former:GetPos():Distance(LocalPlayer():GetPos()) end

function GetPlayersByDistance()
	local players = player.GetAll()
	table.sort(players, TableSortByDistance)
	return players
end

function fag:add3D(prop, text, r, g, b, col)
	for _,ent in pairs(ents.FindByClass(prop)) do
		if IsValid(ent) then
			cam.Start3D(EyePos(), EyeAngles())
				render.SuppressEngineLighting(true)
				render.SetColorModulation(r, g, b, 1)
				render.MaterialOverride(Mat)
				ent:DrawModel()
				
				render.SetColorModulation(1, 1, 1, 1)
				render.MaterialOverride()
				render.SetModelLighting(BOX_TOP, 1, 1, 1)
				ent:DrawModel()
			
				render.SuppressEngineLighting(false)
			cam.End3D()
			local pos = ent:GetPos():ToScreen()
			local width, height = surface.GetTextSize(text.." ("..math.Round(ent:GetPos():Distance(LocalPlayer():GetPos()))..")")
			draw.DrawText(text.." ("..math.Round(ent:GetPos():Distance(LocalPlayer():GetPos()))..")", "faggot", pos.x, pos.y, col, 1)
		end
	end
end

function fag:walnuts()
	if fag:cvar("wallhack") then
		if fag:cvar("wallhack_player") then
			for k,v in pairs(GetPlayersByDistance()) do
				if fag:alive(v) and !table.HasValue(fag.traitors, v) then
					cam.Start3D(EyePos(), EyeAngles())
						render.SuppressEngineLighting(true)
						render.SetColorModulation(0, 1, 0, 1)
						render.MaterialOverride(Mat)
						v:DrawModel()
						
						render.SetColorModulation(1, 1, 1, 1)
						render.MaterialOverride()
						render.SetModelLighting(BOX_TOP, 1, 1, 1)
						v:DrawModel()
						
						render.SuppressEngineLighting(false)
					cam.End3D()
				elseif fag:alive(v) and TTT then
					if table.HasValue(fag.traitors, v) then 
						cam.Start3D(EyePos(), EyeAngles())
							render.SuppressEngineLighting(true)
							render.SetColorModulation(1, 0, 0, 1)
							render.MaterialOverride(Mat)
							v:DrawModel()
							
							render.SetColorModulation(1, 1, 1, 1)
							render.MaterialOverride()
							render.SetModelLighting(BOX_TOP, 1, 1, 1)
							v:DrawModel()
							
							render.SuppressEngineLighting(false)
						cam.End3D()
					end
					if v:IsDetective() then
						cam.Start3D(EyePos(), EyeAngles())
							render.SuppressEngineLighting(true)
							render.SetColorModulation(0, 0, 1, 1)
							render.MaterialOverride(Mat)
							v:DrawModel()
							
							render.SetColorModulation(1, 1, 1, 1)
							render.MaterialOverride()
							render.SetModelLighting(BOX_TOP, 1, 1, 1)
							v:DrawModel()
							
							render.SuppressEngineLighting(false)
						cam.End3D()
					end
				end
			end
			for _,fags in pairs(fag.friends) do
				if fag:alive(fags) then
					cam.Start3D(EyePos(), EyeAngles())
						render.SuppressEngineLighting(true)
						render.SetColorModulation(0, 1, 0, 1)
						render.MaterialOverride(Mat)
						v:DrawModel()
						
						--[[render.SuppressEngineLighting(true)
						render.SetColorModulation(0, 1, 0, 1)
						render.MaterialOverride(Mat)
						v:DrawModel()]]--
					cam.End3D()
				end
			end
		end
		if fag:cvar("wallhack_entity") then
			if TTT and fag:cvar("wallhack_entity_ttt") then
				if fag:cvar("wallhack_entity_ttt_ragdoll") then
					for _,ent in pairs(ents.FindByClass("prop_ragdoll")) do
						if ent:IsValid() then
							cam.Start3D(EyePos(), EyeAngles())
								render.SuppressEngineLighting(true)
								render.SetColorModulation(1, 1, 0, 1)
								render.MaterialOverride(Mat)
								ent:DrawModel()
					
								render.SetColorModulation(1, 1, 1, 1)
								render.MaterialOverride()
								render.SetModelLighting(BOX_TOP, 1, 1, 1)
								ent:DrawModel()
				
								render.SuppressEngineLighting( false)
							cam.End3D()
							local name = CORPSE.GetPlayerNick(ent, false)
							if name then
								local pos = ent:GetPos():ToScreen()
								local width, height = surface.GetTextSize(name)
								draw.DrawText(name.." ("..math.Round(ent:GetPos():Distance(LocalPlayer():GetPos()))..")", "faggot", pos.x, pos.y-height/2, Color(255, 215, 0, 255), 1)
								if (!CORPSE.GetFound(ent, false)) then
									draw.DrawText("Unidentified", "faggot", pos.x, pos.y-height/2+12, Color(255, 215, 0, 255), 1)
								end
							end
						end
					end
				end				
				for _,ent in pairs(ents.FindByClass("ttt_c4")) do
					if ent:IsValid() then
						cam.Start3D(EyePos(), EyeAngles())
							render.SuppressEngineLighting(true)
							render.SetColorModulation(1, 0, 0, 1)
							render.MaterialOverride(Mat)
							ent:DrawModel()
				
							render.SetColorModulation(1, 1, 1, 1)
							render.MaterialOverride()
							render.SetModelLighting(BOX_TOP, 1, 1, 1)
							ent:DrawModel()
				
							render.SuppressEngineLighting( false)
						cam.End3D()
						local pos = ent:GetPos():ToScreen()
						local width, height = surface.GetTextSize("C4")
						if ent:GetArmed() then
							draw.DrawText("C4 - "..string.FormattedTime(ent:GetExplodeTime() - CurTime(), "%02i:%02i").." ("..math.Round(ent:GetPos():Distance(LocalPlayer():GetPos()))..")", "faggot", pos.x, pos.y-height/2, red, 1)
						else
							draw.DrawText("C4 - Unarmed ("..math.Round(ent:GetPos():Distance(LocalPlayer():GetPos()))..")", "faggot", pos.x, pos.y-height/2, red, 1)
						end
					end
				end				
				fag:add3D("ttt_health_station", "HEALTH STATION", 0, 0, 1, blue)
				fag:add3D("ttt_death_station", "DEATH STATION", 1, 0, 0, red)
			end			
			if fag:cvar("wallhack_entity_darkrp") then 
				fag:add3D("money_printer", "MONEY PRINTER", 0, 0, 1, blue)
				fag:add3D("spawned_shipment", "SHIPMENT", 0, 0, 1, blue)
			end
		end
	end
end

--[[=====================================-

 * Traitor finder (TTT)

-=====================================]]--
function fag:negro()
	if TTT then
		if GetRoundState() == ROUND_PREP then
			for k,v in pairs(fag.traitors) do
				table.remove(fag.traitors, k)
				fag.traitors = {}
			end
		end
		for _, ent in pairs(ents.GetAll()) do
			local owner = ent:GetOwner()
			if ent.CanBuy and fag:alive(owner) and owner:IsPlayer() then
				if !ent.Traitor then
					if owner:IsDetective() then
						ent.Traitor = true
					else
						ent.Traitor = true
						table.insert(fag.traitors, owner)
						fag:chat(red, tostring(owner).." obtained a "..ent:GetClass())
					end
				end
			end
		end
	end
end

--[[=====================================-

 * Bunnyhop

-=====================================]]--
function fag.bunny(cmd)
	if fag:cvar("bunnyhop") and bit.band(cmd:GetButtons(), IN_JUMP) != 0 then
		if !LocalPlayer():IsOnGround() then
			cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot( IN_JUMP)))
		end
	end
end
--[[=====================================-

 * Freecam

-=====================================]]--
local Freecam = false
local holding = {}
local FCpos = Vector(0,0,0)
local FCAng = Angle(0,0,0)
local speed = 1

function FCBind(ply, bind, pressed)
	local use = LocalPlayer():KeyDown(IN_USE)
	if (string.find(bind, "forward") or string.find(bind, "moveleft") or string.find(bind, "moveright") or string.find(bind, "back") or string.find(bind, "jump") or string.find(bind, "duck")) and not use then
		holding[string.sub(bind, 2)] = pressed
		return true
	elseif string.find(bind, "speed") and pressed and not use then
		if speed <= 1 then speed = 5
		elseif speed == 5 then speed = 1
		end
		return true
	end
end

function FCMove(what)
	if string.find(what, "forward") then
		FCpos = FCpos + FCAng:Forward() * 100 * RealFrameTime() * local_gcvn("fag_freecam_speed") * speed
	elseif string.find(what, "back") then
		FCpos = FCpos - FCAng:Forward() * 100 * RealFrameTime() * local_gcvn("fag_freecam_speed") * speed
	elseif string.find(what, "moveleft") then
		FCpos = FCpos - FCAng:Right() * 100 * RealFrameTime() * local_gcvn("fag_freecam_speed") * speed
	elseif string.find(what, "moveright") then
		FCpos = FCpos + FCAng:Right() * 100 * RealFrameTime() * local_gcvn("fag_freecam_speed") * speed
	elseif string.find(what, "jump") then
		FCpos = FCpos + Vector(0,0,100 * RealFrameTime() * local_gcvn("fag_freecam_speed") * speed)
	elseif string.find(what, "duck") then
		FCpos = FCpos - Vector(0,0,100 * RealFrameTime() * local_gcvn("fag_freecam_speed") * speed)
	end
end

function FCThink()
	for k,v in pairs(holding) do
		if v then
			FCMove(k)
		end
	end
end

local function FCCalcViews(ply, origin, angles, fov)
	local view = {}
	view.vm_origin = Vector(0,0,-13000)
	view.angles = FCAng
	view.origin = FCpos
	view.vm_origin = FCpos
	return view
end

function FCMouse(u)
	local trace = {}
	trace.start = FCpos
	trace.endpos = FCpos + FCAng:Forward() * 100000
	trace.filter = LocalPlayer()
	local traceline = util.TraceLine(trace)
	local pos = traceline.HitPos
	FCAng.p = math.Clamp(FCAng.p + u:GetMouseY() * 0.025, -90, 90)
	FCAng.y = FCAng.y + u:GetMouseX() * -0.025
	safeview(u, (pos - LocalPlayer():GetShootPos()):Angle())
end

function FCText()
	draw.SimpleTextOutlined("YOU", "faggot", LocalPlayer():GetPos():ToScreen().x, LocalPlayer():GetPos():ToScreen().y, white, 0, 4, 1, white)
	draw.DrawText("Freecam", "faggot", 5, 24, white, 0)
end


function fag:freecam()
	if Freecam then
		Freecam = false
		holding = {}
		hook.Remove("CreateMove", "Cameron")
		hook.Remove("CalcView", "Cameron")
		hook.Remove("Think", "Cameron")
		hook.Remove("PlayerBindPress", "Cameron")
		hook.Remove("RenderScreenspaceEffects", "Cameron")
		hook.Remove("ShouldDrawLocalPlayer", "Cameron")
	else
		Freecam = true
		local obs = LocalPlayer():GetObserverTarget()
		FCpos = IsValid(obs) and (obs:IsPlayer() and obs:GetShootPos() or obs:GetPos()) or LocalPlayer():GetShootPos()
		hook.Add("CreateMove", "Cameron", FCMouse)
		hook.Add("CalcView", "Cameron", FCCalcViews)
		hook.Add("Think", "Cameron", FCThink)
		hook.Add("PlayerBindPress", "Cameron", FCBind)
		hook.Add("RenderScreenspaceEffects", "Cameron", FCText)
		hook.Add("ShouldDrawLocalPlayer", "Cameron", function() return true end)
	end
end

--[[=====================================-

 * Infinite voice battery (TTT)

-=====================================]]--
function fag:infvoice()
	if fag:cvar("infvoice") and TTT then
		LocalPlayer().voice_battery = 98
	end
end

--[[=====================================-

 * Anti-cheat bypasses

-=====================================]]--
fag:rcmd("oac_scanme")
fag:print(green, "[BYPASS] Onion Anti-cheat")

for i = 100, 100000 do
	hook.Remove("Think", tostring(i))
end
fag:print(green, "[BYPASS] Daz's Anti-cheat")

hook.Remove("Think", "PlayerInfoThing")
fag:print(green, "[BYPASS] F2S:Stronghold's Anti-cheat")

hook.Add( "Think", "sh_menu", function() return true end)
hook.Remove( "Think", "sh_menu" )
fag:print(green, "[BYPASS] Cherry's Anti-cheat")

--[[=====================================-

 * Detour commands

-=====================================]]--
fag.badcmds = {
"__ac",
"__imacheater",
"gm_possess",
"__uc_", -- RIOT
"_____b__c",
"___m",
"sc",
"bg",
"bm",
"kickme",
"gw_iamacheater",
"imafaggot",
"birdcage_browse",
"reportmod",
"_fuckme",
"st_openmenu",
"_NOPENOPE",
"__ping",
"ar_check",
"GForceRecoil", -- Fake cmd, but fuck you RIOT servers
"~__ac_auth",
"blade_client_check",
"blade_client_detected_message",
"disconnect",
"exit",
"retry",
"kill",
"dac_imcheating", -- fuck u bich
"dac_pleasebanme", -- fuck u bich
"excl_banme", -- fuck u bitch
}

function RunConsoleCommand(cmd, ...)
	if !table.HasValue(fag.badcmds, cmd) then 
		return local_rcc(cmd, ...)
	else
		fag:chat(red, "BLOCKED CMD: "..cmd.." ["..debug.getinfo(2).short_src.."]")
		return
	end
end
function _R.Player.ConCommand(pl,cmd)
	if !table.HasValue(fag.cmds, cmd) and !table.HasValue(fag.badcmds, cmd) then
		fag:print(red, "CMD: "..cmd.." ["..debug.getinfo(2).short_src.."]")
		return local_cc(pl, cmd)
	else
		fag:chat(red, "BLOCKED CMD: "..cmd.." ["..debug.getinfo(2).short_src.."]")
		return
	end
end

--[[=====================================-

 * Menu

-=====================================]]--



--[[=====================================-

 * other shit

-=====================================]]--
function fag_think()
	fag.infvoice()
end
function fag_createmove(ucmd)
	fag.aim(ucmd)
	fag.nr()
	fag.bunny(cmd)
end
function fag_calcview(ply, pos, angles, fov)
	fag.nvr(ply, pos, angles, fov)
end
function fag_renderscreenspaceeffects()
	fag.esp()
	fag.taters()
	fag.walnuts()
end
function fag_postdrawopaquerenderables()
	fag.negro()
end
function fag:load()
	fag:acmd("+fag", fag.aon, "Aims at the first target's head")
	fag:acmd("-fag", fag.aoff, "+fag")
	fag:acmd("fag_esp_dist_raise", fag.raiseesp, "Raises ESP distance by 1000")
	fag:acmd("fag_esp_dist_lower", fag.loweresp, "Lowers ESP distance by 1000")
	fag:acmd("fag_esp_target_raise", fag.raisetarget, "Raises ESP target by 1")
	fag:acmd("fag_esp_target_lower", fag.lowertarget, "Lowers ESP target by 1")
	fag:acmd("fag_id", fag.id, "Prints a list of players and their entity index in console")
	fag:acmd("fag_freecam", fag.freecam, "Allows the player to noclip in client")
	fag:acmd("fag_unload", fag.unload, "Unloads hooks and commands")
	fag:acmd("fag_reload", fag.reload, "Reloads hooks and commands")
	fag.hooks:load()
	fag:chat(green, "fagBOT loaded")
end
function fag.hooks:load()
	fag:ahook("Think", fag_think)
	fag:ahook("CreateMove", fag_createmove)
	fag:ahook("CalcView", fag_calcview)
	fag:ahook("RenderScreenspaceEffects", fag_renderscreenspaceeffects)
	fag:ahook("PostDrawOpaqueRenderables", fag_postdrawopaquerenderables)
end
function fag.hooks:unload()
	fag:rhook("Think", fag_think)
	fag:rhook("CreateMove", fag_createmove)
	fag:rhook("CalcView", fag_calcview)
	fag:rhook("RenderScreenspaceEffects", fag_renderscreenspaceeffects)
	fag:rhook("PostDrawOpaqueRenderables", fag_postdrawopaquerenderables)
end
function fag.hooks:reload()
	fag.hooks:unload()
	fag.hooks:load()
	fag:chat(green, "Hooks reloaded")
end
function fag:unload()
	fag:rcmd("+fag", fag.aon)
	fag:rcmd("-fag", fag.aoff)
	fag:rcmd("fag_esp_dist_raise", fag.raiseesp)
	fag:rcmd("fag_esp_dist_lower", fag.loweresp)
	fag:rcmd("fag_esp_target_raise", fag.raisetarget)
	fag:rcmd("fag_esp_target_lower", fag.lowertarget)
	fag:rcmd("fag_id", fag.id)
	fag:rcmd("fag_freecam", fag.freecam)
	fag:rcmd("fag_unload", fag.unload)
	fag:rcmd("fag_reload", fag.reload)
	fag.hooks:unload()
	fag:chat(red, "fagBOT unloaded")
end

if CLIENT then fag.load() end
-- EOF


--[[=======================================-

 * Aimbot

-=======================================]]--
local fag.aimbot = false
local fag.headpos = nil
local fag.target = nil
local players = player.GetAll()

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

function fag.fov(v)
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

function fag.visible(ent)
	if !fag:cvar("aim_visible") then return true end
	local trace = util.TraceLine( {
		startp = LocalPlayer():GetShootPos(),
		endp = ent:GetAttachment(ent:LookupAttachment("eyes")).Pos,
		filter = {LocalPlayer(), e},
		mask = MASK_SHOT + CONTENTS_WINDOW
	} )
	if trace.Entity:IsPlayer() then return true end
	return false
end

function fag.velocity(v) return v:GetAbsVelocity() * 0.012 end


function fag.closest(players)
	local flAngleDifference = nil
	local ang = nil
	local viewAngles = LocalPlayer():EyeAngles()	
	for _,v in pairs(players) do
		local vec, ang1 = v:GetAttachment(v:LookupAttachment("eyes")).Pos
		local old = vec
		vec = vec - fag.velocity(LocalPlayer()) + fag.velocity(v)
		local ang2 = (vec - LocalPlayer():EyePos()):Angle()
		local angD = math.abs(math.AngleDifference(ang2.p, viewAngles.p)) + math.abs(math.AngleDifference(ang2.y, viewAngles.y))
		
		if (!flAngleDifference or angD < flAngleDifference) and fag.fov(v) then
			fag.target = v
			flAngleDifference = angD
			ang = ang2
		end
	end
	return ang
end

function fag.validply()
	local players = {}
	for _,v in pairs(player.GetAll()) do
		if fag:alive(v) then
			table.insert(players, v)
		end
	end
	return players
end

function fag.aim(ucmd)
	fag.headpos = nil
	fag.aimbot = false
	
	local players = {}
	
	for _,v in pairs(fag.validply()) do
		if fag.visible(v) then
			table.insert(players, v)
		end
	end
	
	if !#players then 
		fag.target = nil;
		return
	end
	
	local ang = fag.closest(players)
	
	if ang then 
		safeview(ucmd, ang)
		fag.aimbot = true
	end
end

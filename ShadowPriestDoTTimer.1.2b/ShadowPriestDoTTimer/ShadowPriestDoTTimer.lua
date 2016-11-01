-- Author      : Kressilac /Duskwood
-- UI elements borrowed from Shadow Timer and extended for better use.
-- Create Date : 10/5/2011 6pm

ShadowPriestDoTTimerFrame_Default_X = 0
ShadowPriestDoTTimerFrame_Default_Y = 0
ShadowPriestDoTTimerFrame_Default_Size = 100
ShadowPriestDoTTimerFrame_Default_Scale = 1

MyAddon_UpdateInterval = 0.05; -- How often the OnUpdate code will run (in seconds)

WarningTime = 600; -- WarningTime (in milliseconds)
local buffscorecurrent = 0

--Used to keep track of the DoTs on a Mob.
local moblist = {}
local isincombat = false;
local currentmob = nil;
local maxmoblist = 10;

----------------------------------------------
local nameWordPain, rankWordPain, IconWordPain = GetSpellInfo(589);
--"Interface\\ICONS\\Spell_Shadow_ShadowWordPain.blp";
----------------------------------------------
local VTID = 34914
local nameVT, rankVT, IconVT, costVT, isFunnelVT, powerTypeVT, castTimeVT, minRangeVT, maxRangeVT = GetSpellInfo(VTID)	
--"Interface\\ICONS\\Spell_Holy_Stoicism.blp";
----------------------------------------------
local PlagueID = 2944
local namePlague, rankPlague, IconPlague = GetSpellInfo(PlagueID);
--"Interface\\ICONS\\Spell_Shadow_DevouringPlague.blp";
----------------------------------------------
local nameShadowOrbs, rankShadowOrbs, IconShadowOrbs = GetSpellInfo(77487);	
--"Interface\\ICONS\\spell_priest_shadoworbs.blp";
----------------------------------------------
local nameEmpShadow, rankEmpShadow, IconEmpShadow = GetSpellInfo(95799);
--"Interface\\ICONS\\inv_chaos_orb.blp";
----------------------------------------------
local MindBlastID = 8092;
local nameMindBlast, rankMindBlast, IconMindBlast = GetSpellInfo(MindBlastID);
----------------------------------------------
local nameDarkEvan, rankDarkEvan, IconDarkEvan = GetSpellInfo(87118);
--"Interface\\ICONS\\spell_holy_divineillumination.blp";
----------------------------------------------
local DarkArchangelID = 87153;
local nameArchangel, rankArchangel, IconArchangel = GetSpellInfo(DarkArchangelID);

function round(num) 
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end

function ShadowPriestDoTTimerFrame_OnLoad(self)
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_LOGOUT");
	ShadowPriestDoTTimerFrame:RegisterEvent("ADDON_LOADED");
	ShadowPriestDoTTimerFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	ShadowPriestDoTTimerFrame:RegisterEvent("PLAYER_REGEN_DISABLED");

	DEFAULT_CHAT_FRAME:AddMessage("---Shadow Priest DoT Timer Loaded---");
	Texture1:SetTexture(IconVT);
	Texture2:SetTexture(IconPlague);
	Texture3:SetTexture(IconWordPain);
	Texture5:SetTexture(IconMindBlast);
	Texture6:SetTexture(IconShadowOrbs);
	Texture7:SetTexture(IconDarkEvan);
	Texture8:SetTexture(IconArchangel);
	
	Texture1:Hide();
	Texture2:Hide();
	Texture3:Hide();
	Texture4:Hide();
	TEXT4:Show();
	TEXT5:Hide();
	Texture5:Hide();
	Texture6:Hide();
	Texture7:Hide();
	Texture8:Hide();
	TEXT1Above:Show();
	TEXT2Above:Show();
	TimeSinceLastUpdate = 0

	ShadowPriestDoTTimerFrame:RegisterForDrag("LeftButton", "RightButton");
	ShadowPriestDoTTimerFrame:EnableMouse(false);
end

function ShadowPriestDoTTimerFrame_OnUpdate(elapsed)
	TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed; 	
	while (TimeSinceLastUpdate > MyAddon_UpdateInterval) do
		CheckCurrentTargetDeBuffs();
		CheckPlayerBuffs();

		if (buffscorecurrent > 0) then
			TEXT4:SetText(string.format("%d", buffscorecurrent));
			TEXT4:Show();
		else
			TEXT4:Hide();
		end
		TimeSinceLastUpdate = TimeSinceLastUpdate - MyAddon_UpdateInterval;
	end
end

function ShadowPriestDoTTimerFrame_OnEvent(self, event, ...)
	local arg1 = ...;

	if (event == "UNIT_SPELLCAST_SUCCEEDED") then
		local unit, _, _, _, spellid = ...;
		if (unit == "player") then
			if (spellid == VTID) then
				TEXT1Above:Show();
				TEXT1Above:SetText(string.format("%d", buffscorecurrent));

				FindOrCreateCurrentMob();
				if (currentmob) then
					currentmob[2] = buffscorecurrent;
					currentmob[4] = GetTime();
				end
			elseif (spellid == PlagueID) then
				TEXT2Above:Show();
				TEXT2Above:SetText(string.format("%d", buffscorecurrent));

				FindOrCreateCurrentMob();
				if (currentmob) then
					currentmob[3] = buffscorecurrent;
					currentmob[4] = GetTime();
				end
			end
		end
	elseif (event == "ADDON_LOADED" and arg1 == "ShadowPriestDoTTimer") then
 		if (not ShadowPriestDoTTimerFrameScaleFrame) then
			ShadowPriestDoTTimerFrameScaleFrame = 1.0
		end
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerFrameScaleFrame);
		SetCooldownOffsets();
	elseif (event == "PLAYER_LOGOUT") then
		ShadowPriestDoTTimerFrameScaleFrame = ShadowPriestDoTTimerFrame:GetScale();
		point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint(1);
		ShadowPriestDoTTimerxPosiFrame = xOffset;
	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (maxmoblist < #moblist) then
			--DP and VT don't last more than a minute so once we've been ooc for a minute, clear up the list.
			for i = 1, #moblist do
				if (moblist[i][4]-GetTime() > 60000 and moblist[i][1] ~= currentmob[1]) then
					table.remove(moblist, i);
				end
			end
		end
		isincombat = false;
	elseif (event == "PLAYER_REGEN_DISABLED") then
		isincombat = true;
	end
end

function SetCooldownOffsets()
	point, relativeTo, relativePoint, xOfs, yOfs = TEXT1:GetPoint();
	TEXT1:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = TEXT2:GetPoint();
	TEXT2:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = TEXT3:GetPoint();
	TEXT3:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = TEXT5:GetPoint();
	TEXT5:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = TEXT6:GetPoint();
	TEXT6:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = TEXT7:GetPoint();
	TEXT7:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
	point, relativeTo, relativePoint, xOfs, yOfs = TEXT8:GetPoint();
	TEXT8:SetPoint(point, relativeTo, relativePoint, xOfs, CooldownOffset);
end

function FindCurrentMob()
	local targetguid = UnitGUID("playertarget");
	currentmob = nil;
	if (targetguid) then
		local i = 1;
		while not currentmob and i <= #moblist do
			if (moblist[i][1] == targetguid) then
				currentmob = moblist[i];
			end
			i = i + 1;
		end
	end
end

function FindOrCreateCurrentMob()
	local targetguid = UnitGUID("playertarget");
	currentmob = nil;

	if (targetguid) then
		--DEFAULT_CHAT_FRAME:AddMessage("SPDT Player Target: " .. targetguid);
		local i = 1;
		while not currentmob and i <= #moblist do
			if (moblist[i][1] == targetguid) then
				currentmob = moblist[i];
			end
			i = i + 1;
		end

		if (not currentmob) then
			currentmob = {targetguid, 0, 0, GetTime()};
			table.insert(moblist, currentmob);
			--DEFAULT_CHAT_FRAME:AddMessage("SPDT New mob: " .. currentmob[1]);
		else
			--DEFAULT_CHAT_FRAME:AddMessage("SPDT Found mob: " .. currentmob[1]);
		end
	end
end

function ClearMobList()
	for i = 1, #moblist do
		table.remove(moblist, i);
	end
	currentmob = nil;
end

function CheckCurrentTargetDeBuffs()
	local finished = false
	local count = 0
	local VTFound = 0
	local VTLeft = 0
	local VTlefttime = 0
	local VTlasttickTime = 0
	local VTlasttickcastTime = 0
	local VTleftMS = 0
	local PlagueFound = 0
	local PlagueLeft = 0
	local PlaguelasttickTime = 0
	local PlaguelasttickCastTime = 0
	local WordPainFound = 0
	local WordPainLeft = 0
	local CastTime = 0

	PseudoGCD = castTimeVT
	PseudoGCD2 = castTimeVT*2
	PseudoGCDWarn = castTimeVT+WarningTime
	VTlasttickTime = castTimeVT*3+WarningTime 
	VTlasttickcastTime = castTimeVT*3 
	PlaguelasttickTime = castTimeVT*2+WarningTime
	PlaguelasttickCastTime = castTimeVT*2  

	while not finished do
		count = count+1

		local bn,brank,bicon,bcount,bType,bduration,bexpirationTime,bisMine,bisStealable,bshouldConsolidate,bspellId =  UnitDebuff("target", count, 0)
		if not bn then
			finished = true
		else
			--DEFAULT_CHAT_FRAME:AddMessage("testing debuff");
			if bisMine == "player" then
				--DEFAULT_CHAT_FRAME:AddMessage("ismine debuff");
				
				if bn == nameVT then 
					VTFound = 1 
					VTlefttime = floor((((bexpirationTime-GetTime())*10)+ 0.5))/10				
					VTLeft = string.format("%1.1f",VTlefttime)							
					VTleftMS = VTlefttime*1000
					CastTime = castTimeVT	
					VTleftMSSafe = VTleftMS-WarningTime
				end
				if bn == namePlague then 
					PlagueFound = 1
					Plaguelefttime = floor((((bexpirationTime-GetTime())*10)+ 0.5))/10				
					PlagueLeft = string.format("%1.1f",Plaguelefttime)	 
					PlagueleftMS = Plaguelefttime*1000
				end
				if bn == nameWordPain then 
					WordPainFound = 1
					WordPainlefttime = floor((((bexpirationTime-GetTime())*10)+ 0.5))/10
					WordPainLeft = string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10)  
				end
			end
		end
	end

	if VTFound == 1 then
		Texture1:Show()
		if  VTleftMS < VTlasttickTime then
			if VTleftMS < VTlasttickcastTime then
				Texture1:SetVertexColor(0.1, 0.6, 0.1);
			else 
				Texture1:SetVertexColor(0.9, 0.2, 0.2);
			end
		else
			Texture1:SetVertexColor(1.0, 1.0, 1.0);
		end
		TEXT1Above:Show();

		FindCurrentMob();
		if (currentmob) then
			TEXT1Above:SetText(string.format("%d", currentmob[2]));
		end

		TEXT1:SetText(VTLeft);
		TEXT1:Show();
	else
		TEXT1Above:Hide();
		TEXT1:Hide();
		Texture1:Hide();
	end

	if PlagueFound == 1 then
		Texture2:Show();
		if  PlagueleftMS < PlaguelasttickTime then
			if PlagueleftMS < PlaguelasttickCastTime  then
				Texture2:SetVertexColor(0.1, 0.6, 0.1);
			else 
				Texture2:SetVertexColor(0.9, 0.2, 0.2);
			end
		else
			Texture2:SetVertexColor(1.0, 1.0, 1.0);
		end
		TEXT2Above:Show();

		FindCurrentMob();
		if (currentmob) then
			TEXT2Above:SetText(string.format("%d", currentmob[3]));
		end

		TEXT2:SetText(PlagueLeft);
		TEXT2:Show();	
	else
		TEXT2Above:Hide();
		Texture2:Hide();
		TEXT2:Hide();
	end

	if WordPainFound == 1 then
		Texture3:Show();
		TEXT3:SetText(WordPainLeft);
		TEXT3:Show();
	else
		Texture3:Hide();
		TEXT3:Hide();
	end

return 
end

function CheckPlayerBuffs()
	local finished = false;
	local count = 0;
	local ShadowOrbsFound = 0;
	local ShadowOrbsStacks = 0;
	local ShadowOrbsLeft = 0;
	local EmpShadowFound = 0;
	local EmpShadowLeft = 0;
	local DarkEvanFound = 0;
	local DarkEvanStacks = 0;
	local DarkEvanLeft = 0;
	local AAFound = 0;
	local AALeft = 0;
	local MBLeft = 0;

	buffscorecurrent = 0;
	local base, stat, posBuff, negBuff = UnitStat("player",4);

	while not finished do
		count = count+1;
		local bn,brank,bicon,bcount,bType,bduration,bexpirationTime,bisMine,bisStealable,bshouldConsolidate,bspellId =  UnitBuff("player", count, 0);

		local modifiedint = base + buffscorecurrent;
		
		if not bn then
			finished = true;
		else
			if bn == nameShadowOrbs then
				ShadowOrbsFound	= 1;
				ShadowOrbsStacks	= bcount;
				ShadowOrbsLeft	= string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10);
			end
			if bn == nameEmpShadow then
				EmpShadowFound	= 1;
				EmpShadowLeft	= string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10); 
			end	
			if bn == nameDarkEvan then 
				DarkEvanFound	= 1;
              	DarkEvanStacks	= bcount;
				DarkEvanLeft	= string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10);  
			end
			if (bn == nameArchangel) then
				AAFound			= 1;
				AALeft			= string.format("%1.1f",floor((((bexpirationTime-GetTime())*10)+ 0.5))/10);
			end

			-------------------------------------
			--loop the buffs in the list until we find a match.
			found = false;
			i = 1;
			while found == false and i <= #BuffList do
				local entry = BuffList[i];
				if (entry) then
					if (bn == entry[1]) then
						found = true;

						if (bcount <= 0) then
							bcount = entry[4];
						end

						if (string.lower(entry[2]) == "int") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount);
						elseif (string.lower(entry[2]) == "mastery") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * MasteryWeight);
						elseif (string.lower(entry[2]) == "crit") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * CritWeight);
						elseif (string.lower(entry[2]) == "haste") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * HasteWeight);
						elseif (string.lower(entry[2]) == "damage") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * modifiedint * DamageWeight);
						elseif (string.lower(entry[2]) == "spellpower") then
							buffscorecurrent = buffscorecurrent + (entry[3] * bcount * SpellpowerWeight);
						end
					end
				end

				i = i + 1;
			end
		end
	end
	
	MBstart, MBduration, MBenabled = GetSpellCooldown(MindBlastID);	--MB CD
	MBLeft = MBduration - (floor((((GetTime()-MBstart)*10)+ 0.5))/10);
	if (HideMB == 0 and MBstart > 0 and MBduration > 1.5) then
		TEXT5:SetText(string.format("%1.1f", MBLeft));
		TEXT5:Show();
		Texture5:Show();
	else
		TEXT5:Hide();
		Texture5:Hide();
	end

	if (ShadowOrbsFound == 1 and HideOrbs == 0) then
		Texture6:SetTexture(IconShadowOrbs);
		Texture6:Show();
		TEXT6Above:SetText(ShadowOrbsStacks);
		TEXT6Above:Show();	
		
		if (EmpShadowFound == 1) then
			TEXT6:SetText(EmpShadowLeft);
			TEXT6:Show();	
		else
			TEXT6:Hide();
		end

		if ShadowOrbsStacks == 3 then
			if  (MBLeft <= PseudoGCD and MBstart > 0 and MBduration > 1.5) then
				Texture6:SetVertexColor(0.1, 0.6, 0.1);		--green
			elseif (MBLeft <= PseudoGCDWarn and MBstart > 0 and MBduration > 1.5) then
				Texture6:SetVertexColor(0.9, 0.2, 0.2);		--red
			end
		else								-- not 3 orbs
			Texture6:SetVertexColor(1.0, 1.0, 1.0);		--no colour
		end
	elseif (EmpShadowFound == 1 and HideES == 0) then
		Texture6:SetVertexColor(1.0, 1.0, 1.0);		--no colour
		TEXT6Above:Hide();
		Texture6:SetTexture(IconEmpShadow);
		Texture6:Show();
		TEXT6:SetText(EmpShadowLeft);
		TEXT6:Show();	
	else
		Texture6:Hide();
		TEXT6:Hide();	
		TEXT6Above:Hide();
	end
	
	if (DarkEvanFound == 1 and HideEvangelism == 0) then
		Texture7:Show();
		TEXT7:SetText(DarkEvanLeft);
		TEXT7Above:SetText(DarkEvanStacks);
		TEXT7:Show();
		TEXT7Above:Show();
	else
		Texture7:Hide();
		TEXT7:Hide();
		TEXT7Above:Hide();
	end

	if (AAFound == 1 and HideAA == 0) then
		Texture8:Show();
		TEXT8:SetText(AALeft);
		TEXT8:Show();	
	else
		Texture8:Hide();
		TEXT8:Hide();
	end


return 
end

SLASH_SHADOWPRIESTDOTTIMER1, SLASH_SHADOWPRIESTDOTTIMER2 = '/spdt', '/ShadowPriestDoTTimer';

local function SLASH_SHADOWPRIESTDOTTIMERhandler(msg, editbox)
	if msg == 'show' then
		ShadowPriestDoTTimerFrame:Show();
	elseif  msg == 'hide' then
		ShadowPriestDoTTimerFrame:Hide();
	elseif  msg == 'reset' then
		ShadowPriestDoTTimerFrame:Hide();
		ShadowPriestDoTTimerFrame:Show();
		ClearMobList();
	elseif  msg == 'clear' then
		ClearMobList();
	elseif  msg == 'noconfigmode' then	
		ShadowPriestDoTTimerFrame:EnableMouse(false);
		ShadowPriestDoTTimerFrame:SetBackdrop(nil);
		SetCooldownOffsets();
		STmode = 1
	elseif  msg == 'configmode' then
		ShadowPriestDoTTimerFrame:EnableMouse(true);
		ShadowPriestDoTTimerFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile= "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 4, tile = false, tileSize =16, insets = { left = 0, right = 0, top = 0, bottom = 0 }});
		STmode = 2
	elseif  msg == 'options' then
		InterfaceOptionsFrame_OpenToCategory("Shadow Priest DoT Timer");
	elseif  msg == 'scale1' then
		ShadowPriestDoTTimerScaleFrame = 0.5
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale2' then
		ShadowPriestDoTTimerScaleFrame = 0.6
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale3' then
		ShadowPriestDoTTimerScaleFrame = 0.7
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale4' then
		ShadowPriestDoTTimerScaleFrame = 0.8
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale5' then
		ShadowPriestDoTTimerScaleFrame = 0.9
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	elseif  msg == 'scale6' then
		ShadowPriestDoTTimerScaleFrame = 1.0
		ShadowPriestDoTTimerFrame:SetScale(ShadowPriestDoTTimerScaleFrame);
	else
		print("Syntax: /spdt (show | hide | reset | configmode | noconfigmode | options | clearmoblist )");
		print("Syntax: /spdt (scale1 | scale2 | scale3 | scale4 | scale5 | scale6)");
	end
end

SlashCmdList["SHADOWPRIESTDOTTIMER"] = SLASH_SHADOWPRIESTDOTTIMERhandler;








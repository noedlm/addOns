-- Author      : derek
-- Create Date : 10/6/2011 7:35:21 PM

local defaultdamageweight = .01
local defaultmasteryweight = .48
local defaultcritweight = .48
local defaulthasteweight = .51
local defaultspellpowerweight = .79
local maxentries = 6
local defaulthidees = 0;
local defaulthideaa = 0;
local defaulthideevangelism = 0;
local defaulthideorbs = 0;
local defaulthidemb = 0;
local defaultcooldownoffset = 0;

local defaultbufftable = {}

table.insert(defaultbufftable, {"Dark Evangelism", "Damage", 2, 5});
table.insert(defaultbufftable, {"Empowered Shadow", "Damage", 10, 1});
table.insert(defaultbufftable, {"Volcanic Power", "Int", 1200, 1});
table.insert(defaultbufftable, {"Heroism", "Haste", 3840, 1});
table.insert(defaultbufftable, {"Power Torrent", "Int", 500, 1});
table.insert(defaultbufftable, {"Time Warp", "Haste", 3840, 1});
table.insert(defaultbufftable, {"Ancient Hysteria", "Haste", 3840, 1});
table.insert(defaultbufftable, {"Volcanic Destruction", "Int", 1600, 1});
table.insert(defaultbufftable, {"Fiery Quintessence", "Int", 1149, 1});
table.insert(defaultbufftable, {"Velocity", "Haste", 3278, 1});
table.insert(defaultbufftable, {"Soul Fragment", "Mastery", 39, 10});
table.insert(defaultbufftable, {"Combat Mind", "Int", 88, 10});

function CancelButton_OnClick()
end

function SaveButton_OnClick()
	--Save the dialog's variables here.
	HasteWeight = EditBoxHaste:GetNumber();
	CritWeight = EditBoxCrit:GetNumber();
	MasteryWeight = EditBoxMastery:GetNumber();
	DamageWeight = EditBoxDamage:GetNumber();
	SpellpowerWeight = EditBoxSpellPower:GetNumber();
	CooldownOffset = EditBoxCooldownOffset:GetNumber();
	SetCooldownOffsets();

	if (CheckButtonHideEvangelism:GetChecked() == 1) then
		HideEvangelism = 1;
	else
		HideEvangelism = 0;
	end		
	if (CheckButtonHideOrbs:GetChecked() == 1) then
		HideOrbs = 1;
	else
		HideOrbs = 0;
	end		
	if (CheckButtonHideES:GetChecked() == 1) then
		HideES = 1;
	else
		HideES = 0;
	end		
	if (CheckButtonHideAA:GetChecked() == 1) then
		HideAA = 1;
	else
		HideAA = 0;
	end		
	if (CheckButtonHideMB:GetChecked() == 1) then
		HideMB = 1;
	else
		HideMB = 0;
	end		
	DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer Options Saved...");
end

function OptionsFrame_OnLoad(panel)
    -- Set the name for the Category for the Panel
    --
	panel:RegisterEvent("ADDON_LOADED");
	panel:RegisterEvent("PLAYER_LOGOUT");
    panel.name = "Shadow Priest DoT Timer";

    -- When the player clicks okay, run this function.
    --
    panel.okay = function (self) SaveButton_OnClick(); end;

    -- When the player clicks cancel, run this function.
    --
    panel.cancel = function (self) CancelButton_OnClick();  end;

	--Build the list of buttons in the table.
		
	--DEFAULT_CHAT_FRAME:AddMessage("Building Entry Frames");
	local entry = CreateFrame("Button", "$parentEntry1", BuffListTable, "BuffListEntry");
	entry:SetID(1);
	entry:SetPoint("TOPLEFT", 4, -32);

	for i = 2, maxentries do
		local entry = CreateFrame("Button", "$parentEntry" .. i, BuffListTable, "BuffListEntry");
		entry:SetID(i);
		entry:SetPoint("TOP", "$parentEntry" .. (i - 1), "BOTTOM");
	end
	--DEFAULT_CHAT_FRAME:AddMessage("Done Building Entry Frames");

    -- Add the panel to the Interface Options
    --
    InterfaceOptions_AddCategory(panel);
	OptionsFrame:Hide();
end

function OptionsFrame_OnEvent(self, event, ...)
	local arg1 = ...;
	if (event == "ADDON_LOADED" and arg1 == "ShadowPriestDoTTimer") then
		if (not HasteWeight or not CritWeight or not MasteryWeight or not DamageWeight or not SpellpowerWeight or not BuffList
				or not HideAA or not HideES or not HideEvangelism or not HideOrbs or not HideMB or not CooldownOffset) then
			HasteWeight = defaulthasteweight;
			CritWeight = defaultcritweight;
			MasteryWeight = defaultmasteryweight;
			DamageWeight = defaultdamageweight;
			SpellpowerWeight = defaultspellpowerweight;
			BuffList = defaultbufftable;
			HideEvangelism = defaulthideevangelism;
			HideOrbs = defaulthideorbs;
			HideAA = defaulthideaa;
			HideES = defaulthidees;
			HideMB = defaulthidemb;
			CooldownOffset = defaultcooldownoffset;
			DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer Default Stat Weights Loaded...");
		end

		EditBoxHaste:SetText(string.format("%1.2f", HasteWeight));
		EditBoxCrit:SetText(string.format("%1.2f", CritWeight));
		EditBoxMastery:SetText(string.format("%1.2f", MasteryWeight));
		EditBoxDamage:SetText(string.format("%1.2f", DamageWeight));
		EditBoxSpellPower:SetText(string.format("%1.2f", SpellpowerWeight));
		EditBoxCooldownOffset:SetText(string.format("%d", CooldownOffset));

		if (HideAA == 1) then
			--DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer: Hide Dark Archangel");
			CheckButtonHideAA:SetChecked(true);
		end
		if (HideEvangelism == 1) then
			--DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer: Hide Evangelism");
			CheckButtonHideEvangelism:SetChecked(true);
		end
		if (HideES == 1) then
			--DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer: Hide Empowered Shadow");
			CheckButtonHideES:SetChecked(true);
		end
		if (HideOrbs == 1) then
			--DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer: Hide Shadow Orbs");
			CheckButtonHideOrbs:SetChecked(true);
		end

		if (HideMB == 1) then
			--DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer: Hide Mind Blast");
			CheckButtonHideMB:SetChecked(true);
		end

		BuffListBoxUpdate();

		DEFAULT_CHAT_FRAME:AddMessage("Shadow Priest DoT Timer Stat Weights Loaded...");
	elseif (event == "PLAYER_LOGOUT") then
		HasteWeight = EditBoxHaste:GetNumber();
		CritWeight = EditBoxCrit:GetNumber();
		MasteryWeight = EditBoxMastery:GetNumber();
		DamageWeight = EditBoxDamage:GetNumber();
		SpellpowerWeight = EditBoxSpellPower:GetNumber();
		CooldownOffset = EditBoxCooldownOffset:GetNumber();

		if (CheckButtonHideEvangelism:GetChecked() == 1) then
			HideEvangelism = 1;
		else
			HideEvangelism = 0;
		end		
		if (CheckButtonHideOrbs:GetChecked() == 1) then
			HideOrbs = 1;
		else
			HideOrbs = 0;
		end		
		if (CheckButtonHideES:GetChecked() == 1) then
			HideES = 1;
		else
			HideES = 0;
		end		
		if (CheckButtonHideAA:GetChecked() == 1) then
			HideAA = 1;
		else
			HideAA = 0;
		end		
		if (CheckButtonHideMB:GetChecked() == 1) then
			HideMB = 1;
		else
			HideMB = 0;
		end		
	end
end

function ButtonAddBuff_OnClick()
	-- Find the buff in the list
	local selection = nil;

	for i = 1, #BuffList do
		local entry = BuffList[i]
		if (entry) then
			if (entry[1] == EditBoxAddBuffName:GetText()) then
				selection = entry;
			end
		end
	end

	if (not selection) then
		-- If we have data, add the buff to the list.
		local stat = EditBoxAddStat:GetText();
		local buff = EditBoxAddBuffName:GetText();
		local modifier = EditBoxAddModifier:GetNumber();
		local maxstacks = EditBoxAddMaxStacks:GetNumber();

		if (stat and buff and modifier and maxstacks) then
			if (string.lower(stat) == "int" or
				string.lower(stat) == "mastery" or
				string.lower(stat) == "haste" or
				string.lower(stat) == "crit" or
				string.lower(stat) == "spellpower" or
				string.lower(stat) == "damage") then
				table.insert(BuffList, {buff, stat, modifier, maxstacks});
				FontStringError:SetText("Added...");
			else
				FontStringError:SetText("Stat must be one of: int, mastery, haste, crit, spellpower or damage.");
			end
		else
			FontStringError:SetText("All fields are required to add a buff. Modifier and maxstacks must be numeric.");
		end
	else
		FontStringError:SetText("Buff already exists.  Remove it first.");
	end

	EditBoxAddStat:SetText("");
	EditBoxAddBuffName:SetText("");
	EditBoxAddModifier:SetText("");
	EditBoxAddMaxStacks:SetText("");
	BuffListBoxUpdate();
end
 
function BuffListBoxUpdate(self)
	--DEFAULT_CHAT_FRAME:AddMessage("Updating frames with data");
	for i = 1, maxentries do
		local entry = BuffList[i + BuffListScrollFrame.offset];
		local frame = getglobal("BuffListTableEntry" .. i);

		if (entry) then
			frame:Show();
			getglobal(frame:GetName() .. "Name"):SetText(entry[1]);
			getglobal(frame:GetName() .. "Stat"):SetText(entry[2]);
			if (entry[2] == "Damage") then
				getglobal(frame:GetName() .. "Modifier"):SetText(entry[3] .. "%");
			else
				getglobal(frame:GetName() .. "Modifier"):SetText(entry[3]);
			end
			getglobal(frame:GetName() .. "MaxStacks"):SetText(entry[4]);
		else
			frame:Hide();
		end
	end
	
	--DEFAULT_CHAT_FRAME:AddMessage("Updating scroll bar");
	FauxScrollFrame_Update(BuffListScrollFrame, #BuffList, maxentries, 24, "BuffListTableEntry", 464, 480, BuffListTableHeaderMaxStacks, 88, 104);
	--DEFAULT_CHAT_FRAME:AddMessage("Done Updating scroll bar");
end

function BuffListScrollFrame_OnVerticalScroll(self, value, itemHeight, updateFunction)
	local scrollbar = getglobal(self:GetName() .. "ScrollBar");
	scrollbar:SetValue(value);
	self.offset = floor((value / itemHeight) + 0.5);
	BuffListBoxUpdate(self);
end

function ScrollFrameTemplate_OnMouseWheel(self, value, scrollBar)
	scrollBar = scrollBar or getglobal(self:GetName() .. "ScrollBar");
	if (value > 0) then
		scrollBar:SetValue(scrollBar:GetValue() - (scrollBar:GetHeight() /2));
	else
		scrollBar:SetValue(scrollBar:GetValue() + (scrollBar:GetHeight() /2));
	end
end

function BuffListEntry_OnClick(self)

	local id = self:GetID();
	local entry = BuffList[id + BuffListScrollFrame.offset];

	if (entry) then
		table.remove(BuffList, id + BuffListScrollFrame.offset);
		FontStringError:SetText("Removed...");
	end

	BuffListBoxUpdate();
end

function ResetDefaultBuffsButton_OnClick()
	DEFAULT_CHAT_FRAME:AddMessage("Resetting Buff List");
	ClearBuffList();

	BuffList = defaultbufftable;

	BuffListBoxUpdate();
	FontStringError:SetText("Buff List reset to defaults.");
end

function ClearBuffList()
	for i = 1, #BuffList do
		table.remove(BuffList, i);
	end
end

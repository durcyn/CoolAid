local _G = getfenv(0)
local LibStub = _G.LibStub
local CoolAid = LibStub("AceAddon-3.0"):NewAddon("CoolAid", "AceEvent-3.0")
local candy = LibStub("LibCandyBar-3.0")
local media = LibStub("LibSharedMedia-3.0")
local anchor, db

local ipairs = _G.ipairs
local pairs = _G.pairs
local unpack = _G.unpack
local wipe = _G.wipe
local bitband = _G.bit.band
local format = _G.string.format
local find = _G.string.find
local random = _G.math.random
local tinsert = _G.table.insert
local tsort = _G.table.sort
local join = _G.string.join
local outsider = _G.COMBATLOG_OBJECT_AFFILIATION_OUTSIDER
local CreateFrame = _G.CreateFrame
local GetSpellInfo = _G.GetSpellInfo
local GetSpellTexture = _G.GetSpellTexture

local defaults = {
	profile = {
		growup = true,
		texture = "Blizzard",
		font = "ABF",
		fontsize = 10,
		justify = "CENTER",
		width = 250,
		height = 14,
		scale = 1,
		brief = false,
		pos = {
			p = "CENTER",
			rp = "CENTER",
			x = 0,
			y = 0,
		},
		color = {
			bg = { 0.5, 0.5, 0.5, 0.3 },
			text = { 1, 1, 1 },
			bar = { 0.25, 0.33, 0.68, 1 },
		},
		allinterrupts = true,
		alldispels = true,
		interrupts = {},
		dispels = {},
	},
}

local interrupts = {
	[57994] = 12, -- Wind Shear (Shaman)
	[1766] = 15, -- Kick (Rogue)
	[80964] = 15, -- Skull Bash (Bea)
	[80965] = 15, -- Skull Bash (Cat)
	[47528] = 15, -- Mind Freeze (Deathknight)
	[6552] = 15, -- Pummel (Warrior)
	[96231] = 15, -- Rebuke (Paladin)
	[31935] = 15, -- Avenger's Shield (Paladin)
	[116705] = 15, -- Spear Hand Strike (Monk)
	[34490] = 20, -- Silencing Shot (Hunter)
	[2139] = 24, -- Counterspell (Mage)
	[19647] = 24, -- Spell Lock (Felhunter)
	[132409] = 24, -- Spell Lock (Command Demon)
	[115782] = 24, -- Optical Blast (Observer) 
	[119911] = 24, -- Optical Blast (Command Demon)
	[15487] = 45 -- Silence (Priest)
	}

local dispels = {
	[475] = 8,     -- Remove Curse
	[2782] = 8,    -- Remove Corruption
	[4987] = 8,    -- Cleanse
	[28133] = 8,   -- Cure Disease
	[51886] = 8,   -- Cleanse Spirit
	[115450] = 8,  -- Detox
	[89808] = 10,  -- Singe Magic
	[132411] = 10, -- Singe Magic (Grimoire of Sacrifice/Command Demon)
	[32375] = 15   -- Mass Dispel
	}

local options = {
	type = "group",
	args = {
		toggle = {
			type = "execute",
			name = "Toggle anchor",
			desc = "Toggle the bar anchor frame",
			func = function()
					CoolAid:ToggleAnchor()
				end,
			order = 1,
		},
		bars = {
			type = "group",
			name = "Bar settings",
			desc = "Bar settings",
			order = 10,
			args = {
				brief = {
					type = "toggle",
					name = "Brief Text",
					desc = "Toggle showing caster name only on bars", 
					get = function() return db.brief end,
					set = function (info, v)
						db.brief = v
						CoolAid:UpdateAnchor()
					end,
					order = 1,
				},
				growth = {
					type = "toggle",
					name = "Grow upwards",
					desc = "Toggle bars grow upwards/downwards from anchor",
					get = function () return db.growth end,
					set = function (info, v)
						db.growth = v
						CoolAid:UpdateAnchor()
					end,
					order = 2,
				},
				height = {
					type = "range",
					name = "Height",
					desc = "Set the height of the bars",
					get = function() return db.height end,
					set = function(info, v)
							db.height = v
							CoolAid:UpdateAnchor()
						end,
					min = 10,
					max = 100,
					step = 1,
					isPercent = false,
					order = 3,
				},
				scale = {
					type = "range",
					name = "Scale",
					desc = "Set the scale of the bars",
					get = function() return db.scale end,
					set = function(info, v)
							db.scale = v
							CoolAid:UpdateAnchor()
						end,
					min = 0.1,
					max = 5,
					step = 0.01,
					isPercent = true,
					order = 4,
				},
				texture = {
					type = "select",
					dialogControl = 'LSM30_Statusbar',
					order = 6,
					name = "Texture",
					desc = "Set the texture for the timer bars",
					values = AceGUIWidgetLSMlists.statusbar,
					get = function() return db.texture end,
					set = function(i,v)
							db.texture = v
							CoolAid:UpdateAnchor()
						end,
				},
				font = {
					type = "select",
					dialogControl = 'LSM30_Font',
					order = 6,
					name = "Font",
					desc = "Set the bar font",
					values = AceGUIWidgetLSMlists.font,
					get = function() return db.font end,
					set = function(i, v)
							db.font = v
							CoolAid:UpdateAnchor()
						end,
					order = 7,
				},
				fontsize = {
					type = "range",
					name = "Font Size",
					desc = "Set the bar font size",
					min = 7,
					max = 48,
					step = 1,
					get = function(info) return db.fontsize end,
					set = function(info, value)
							db.fontsize = value
							CoolAid:UpdateAnchor()
						end,
					order = 8,
				},
			},
		},
		interrupts = {
			type = 'group',
			name = 'Interrupts',
			desc = 'Toggle interrupt timer displays',
			order = 20,
			args = {
				global = {
					type = "toggle",
					name = "All Interrupts",
					desc = "Completely enable or disable all interrupt handling",
					order = 1,
					get = function() return db.allinterrupts end,
					set = function(info,value)
						db.allinterrupts = value
					end,
				},
				header = {
					type = "header",
					name = "Interrupts",
					order = 2,
				},
			},
		},
		dispels = {
			type = 'group',
			name = 'Dispels',
			desc = 'Toggle dispel timer displays',
			order = 30,
			args = {
				global = {
					type = "toggle",
					name = "All Dispels",
					desc = "Completely enable or disable all dispel handling",
					order = 1,
					get = function() return db.alldispels end,
					set = function(info, value)
						db.alldispels = value
					end,
				},
				header = {
					type = "header",
					name = "Dispels",
					order = 2,
				},
			},
		},
	},
}

for k in pairs(interrupts) do
	local spell = (GetSpellInfo(k))
	if not spell then return end
	defaults.profile.interrupts[k] = true
	options.args.interrupts.args[spell] = {
		type = "toggle",
		name = spell, 
		get = function () return db.interrupts[k] end,
		set = function (i,v) db.interrupts[k] = v end,
		disabled = function() return db.allinterrupts end,
	}
end

for k in pairs(dispels) do
	local spell = (GetSpellInfo(k))
	if not spell then return end
	defaults.profile.dispels[k] = true
	options.args.dispels.args[spell] = {
		type = "toggle",
		name = spell, 
		get = function () return db.dispels[k] end,
		set = function (i,v) db.dispels[k] = v end,
		disabled = function() return db.alldispels end,
	}
end

-- Credit to the BigWigs team (Rabbit, Ammo, et al) for the anchor code 
local function sortBars(a, b)
	return (a.remaining > b.remaining and db.growup) and true or false
end

local function rearrangeBars(anchor)
	local tmp = {}
	for bar in pairs(anchor.running) do
		tinsert(tmp, bar)
	end
	tsort(tmp, sortBars)
	local lastBar = nil
	for i, bar in ipairs(tmp) do
		bar:ClearAllPoints()
		if db.growup then
			bar:SetPoint("BOTTOMLEFT", lastBar or anchor, "TOPLEFT")
			bar:SetPoint("BOTTOMRIGHT", lastBar or anchor, "TOPRIGHT")
		else
			bar:SetPoint("TOPLEFT", lastBar or anchor, "BOTTOMLEFT")
			bar:SetPoint("TOPRIGHT", lastBar or anchor, "BOTTOMRIGHT")
		end
		lastBar = bar
	end
	wipe(tmp)
end

local function onDragHandleMouseDown(self)
	self:GetParent():StartSizing("BOTTOMRIGHT")
end

local function onDragHandleMouseUp(self, button)
	self:GetParent():StopMovingOrSizing()
end

local function onResize(self, width)
	db.width = width
	rearrangeBars(self)
end

local function onDragStart(self)
	self:StartMoving()
end

local function onDragStop(self)
	self:StopMovingOrSizing()
	local p, _, rp, x, y = self:GetPoint()
	db.pos.p = p
	db.pos.rp = rp
	db.pos.x = x
	db.pos.y = y
end

local function onControlEnter(self)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:AddLine(self.tooltipHeader)
	GameTooltip:AddLine(self.tooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end

local function onControlLeave()
	GameTooltip:Hide()
end

local function getBar(id)
	local bar
	for k in pairs(anchor.running) do
		if k:Get("id") == id then
			bar = true
			break
		end
	end
	return bar
end

local function stopBar(id)
	local bar
	for k in pairs(anchor.running) do
		if (not id or k:Get("id") == id) then
			k:Stop()
			bar = true
		end
	end
	if bar then rearrangeBars(anchor) end
	return bar
end

local function startBar(id, text, duration, icon, override)
	if getBar(id) and not override then return end
	stopBar(id)
	local bar = candy:New(media:Fetch("statusbar", db.texture), db.width, db.height)
	bar:Set("anchor", anchor)
	bar:Set("id", id)
	anchor.running[bar] = true
	bar.candyBarBackground:SetVertexColor(unpack(db.color.bg))
	bar:SetColor(unpack(db.color.bar))
	bar.candyBarLabel:SetJustifyH(db.justify)
	bar.candyBarLabel:SetTextColor(unpack(db.color.text))
	bar.candyBarLabel:SetFont(media:Fetch("font", db.font), db.fontsize)
	bar.candyBarDuration:SetFont(media:Fetch("font", db.font), db.fontsize)
	bar:SetLabel(text)
	bar:SetDuration(duration)
	bar:SetTimeVisibility(true)
	bar:SetIcon(icon)
	bar:SetScale(db.scale)
	bar:Start()
	rearrangeBars(anchor)
end

local function toggleAnchor(anchor)
	if anchor:IsShown() then
		anchor:Hide()
	else
		anchor:Show()
	end
end

local function createAnchor(frameName, title)
	local display = CreateFrame("Frame", frameName, UIParent)
	display:EnableMouse(true)
	display:SetMovable(true)
	display:SetResizable(true)
	display:RegisterForDrag("LeftButton")
	display:SetWidth(db.width)
	display:SetHeight(20)
	display:SetMinResize(80, 20)
	display:SetMaxResize(1920, 20)
	display:ClearAllPoints()
	display:SetPoint(db.pos.p, UIParent, db.pos.rp, db.pos.x, db.pos.y)

	local bg = display:CreateTexture(nil, "PARENT")
	bg:SetAllPoints(display)
	bg:SetBlendMode("BLEND")
	bg:SetTexture(0, 0, 0, 0.3)

	local header = display:CreateFontString(nil, "OVERLAY")
	header:SetFontObject(GameFontNormal)
	header:SetText(title)
	header:SetAllPoints(display)
	header:SetJustifyH("CENTER")
	header:SetJustifyV("MIDDLE")

	local drag = CreateFrame("Frame", nil, display)
	drag:SetFrameLevel(display:GetFrameLevel() + 10)
	drag:SetWidth(16)
	drag:SetHeight(16)
	drag:SetPoint("BOTTOMRIGHT", display, -1, 1)
	drag:EnableMouse(true)
	drag:SetScript("OnMouseDown", onDragHandleMouseDown)
	drag:SetScript("OnMouseUp", onDragHandleMouseUp)
	drag:SetAlpha(0.5)

	local tex = drag:CreateTexture(nil, "BACKGROUND")
	tex:SetTexture("Interface\\AddOns\\CoolAid\\Textures\\draghandle")
	tex:SetWidth(16)
	tex:SetHeight(16)
	tex:SetBlendMode("ADD")
	tex:SetPoint("CENTER", drag)

	local close = CreateFrame("Button", nil, display)
	close:SetPoint("BOTTOMLEFT", nil, "BOTTOMRIGHT", 4, 0)
	close:SetHeight(14)
	close:SetWidth(14)
	close.tooltipHeader = "Hide"
	close.tooltipText = "Hides the anchor"
	close:SetScript("OnEnter", onControlEnter)
	close:SetScript("OnLeave", onControlLeave)
	close:SetScript("OnClick", function() toggleAnchor(anchor) end)
	close:SetNormalTexture("Interface\\AddOns\\CoolAid\\Textures\\close")

	display:SetScript("OnSizeChanged", onResize)
	display:SetScript("OnDragStart", onDragStart)
	display:SetScript("OnDragStop", onDragStop)
	display.running = {}
	display:Hide()
	return display
end

local function updateAnchor(anchor)
	anchor:SetWidth(db.width)
	for bar in pairs(anchor.running) do
		bar.candyBarBar:SetStatusBarTexture(media:Fetch("statusbar", db.texture))
		bar.candyBarBackground:SetTexture(media:Fetch("statusbar", db.texture))
		bar.candyBarBackground:SetVertexColor(unpack(db.color.bg))
		bar.candyBarBar:SetStatusBarColor(unpack(db.color.bar))
		bar.candyBarLabel:SetJustifyH(db.justify)
		bar.candyBarLabel:SetTextColor(unpack(db.color.text))
		bar.candyBarLabel:SetFont(media:Fetch("font", db.font), 10)
		bar.candyBarDuration:SetFont(media:Fetch("font", db.font), 10)
		bar:SetScale(db.scale)
		bar:SetWidth(db.width)
		bar:SetHeight(db.height)
	end	
	rearrangeBars(anchor)
end

function CoolAid:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("CoolAidDB", defaults, "Default")
	db = self.db.profile
	self.db.RegisterCallback(self, "OnProfileChanged", "UpdateProfile")
	self.db.RegisterCallback(self, "OnProfileCopied", "UpdateProfile")
	self.db.RegisterCallback(self, "OnProfileReset", "UpdateProfile")
	anchor = createAnchor("CoolAidAnchor", "CoolAid")
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("CoolAid", options)
	local optFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("CoolAid", "CoolAid")
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(CoolAid.db)
	LibStub("AceConsole-3.0"):RegisterChatCommand( "coolaid", function() InterfaceOptionsFrame_OpenToCategory("CoolAid") end )

	-- database upgrade
	if self.db.profile.spells then
		self.db.profile.interrupts = self.db.profile.interrupts or {}
		for k,v in pairs(self.db.profile.spells) do
			self.db.profile.interrupts[k] = v
		end
		wipe(self.db.profile.spells)
		self.db.profile.spells = nil
	end

	-- clean up removed spells so the CLEU handler doesn't explode
	if self.db.profile.interrupts then
		for k,v in pairs(self.db.profile.interrupts) do
			if not interrupts[k] then self.db.profile.interrupts[k] = nil end
		end
	end
	if self.db.profile.dispels then
		for k,v in pairs(self.db.profile.dispels) do
			if not dispels[k] then self.db.profile.dispels[k] = nil end
		end

	end
end

function CoolAid:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	candy.RegisterCallback(self, "LibCandyBar_Stop")
end

function CoolAid:OnDisable()
	self:UnregisterAllEvents()
end

function CoolAid:UpdateProfile()
	db = self.db.profile
	updateAnchor(anchor)
end

function CoolAid:ToggleAnchor()
	toggleAnchor(anchor)
end

function CoolAid:UpdateAnchor()
	updateAnchor(anchor)
end

function CoolAid:LibCandyBar_Stop(callback, bar)
	local a = bar:Get("anchor")
	if a == anchor and anchor.running and anchor.running[bar] then
		anchor.running[bar] = nil
	end
end

function CoolAid:COMBAT_LOG_EVENT_UNFILTERED(callback,timestamp,event,...)
	if event == "SPELL_CAST_SUCCESS" then
		local hideCaster,srcGUID,srcName,srcFlags,srcRaidFlags,dstGUID,dstName,dstFlags,dstRaidFlags,spellID,spellName,_,extraID,extraName = ...
		if bitband(srcFlags, outsider) == 0 then
			if db.allinterrupts and db.interrupts[spellID] then
				srcName = strsplit("-", srcName, 2)
				dstName = strsplit("-", dstName, 2)
				local id = join("-", srcGUID, spellID)
				local icon = GetSpellTexture(spellID)
				local time = interrupts[spellID]
				local text = db.brief and srcName or format("%s: %s", srcName, dstName)
				startBar(id, text, time, icon)
			elseif db.alldispels and db.dispels[spellID] then
				srcName = strsplit("-", srcName, 2)
				dstName = strsplit("-", dstName, 2)
				local id = join("-", srcGUID, spellID)
				local icon = GetSpellTexture(spellID)
				local time = dispels[spellID]
				local text = db.brief and srcName or format("%s: %s", srcName, dstName == srcName and spellName or dstName)
				startBar(id, text, time, icon, false)
			end
		end
	elseif event == "SPELL_INTERRUPT" then
		local hideCaster,srcGUID,srcName,srcFlags,srcRaidFlags,dstGUID,dstName,dstFlags,dstRaidFlags,spellID,spellName,_,extraID,extraName = ...
		if bitband(srcFlags, outsider) == 0 then
			if db.allinterrupts and db.interrupts[spellID] then
				srcName = strsplit("-", srcName, 2)
				dstName = strsplit("-", dstName, 2)
				local id = join("-", srcGUID, spellID)
				local icon = GetSpellTexture(spellID)
				local time = interrupts[spellID]
				local text = db.brief and srcName or format("%s: %s (%s)", srcName, dstName, extraName)
				startBar(id, text, time, icon, true)
			end
		end
	elseif event == "SPELL_DISPEL" then
		local hideCaster,srcGUID,srcName,srcFlags,srcRaidFlags,dstGUID,dstName,dstFlags,dstRaidFlags,spellID,spellName,_,extraID,extraName = ...
		if bitband(srcFlags, outsider) == 0 then
			if db.alldispels and db.dispels[spellID] then
				srcName = strsplit("-", srcName, 2)
				dstName = strsplit("-", dstName, 2)
				local id = join("-", srcGUID, spellID)
				local icon = GetSpellTexture(spellID)
				local time = dispels[spellID]
				local text = db.brief and srcName or format("%s: %s (%s)", srcName, dstName, extraName)
				startBar(id, text, time, icon, true)
			end
		end
	end
end

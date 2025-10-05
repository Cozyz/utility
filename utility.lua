--[[ =========================
      OrionMini (single-file) v2
      ========================= ]]
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k,v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function makeDraggable(frame, dragBar)
	local UIS = game:GetService("UserInputService")
	local dragging, startPos, startInputPos
	dragBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startPos = frame.Position
			startInputPos = i.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - startInputPos
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local OrionLib = {}
OrionLib._rootGuis = {}

function OrionLib:MakeNotification(opts)
	local gui = mk("ScreenGui",{ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, pg)
	table.insert(self._rootGuis, gui)
	local toast = mk("Frame",{
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,-20,0,20),
		Size = UDim2.new(0,320,0,80),
		BackgroundColor3 = Color3.fromRGB(24,24,24)
	}, gui)
	mk("UICorner",{CornerRadius = UDim.new(0,10)}, toast)
	mk("TextLabel",{
		BackgroundTransparency = 1,
		Text = tostring(opts.Name or "Notice"),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255,255,255),
		Position = UDim2.new(0,12,0,8),
		Size = UDim2.new(1,-24,0,22),
		TextXAlignment = Enum.TextXAlignment.Left
	}, toast)
	mk("TextLabel",{
		BackgroundTransparency = 1,
		Text = tostring(opts.Content or ""),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(230,230,230),
		Position = UDim2.new(0,12,0,30),
		Size = UDim2.new(1,-24,0,40),
		TextXAlignment = Enum.TextXAlignment.Left
	}, toast)
	task.spawn(function()
		task.wait(tonumber(opts.Time or 4))
		gui:Destroy()
	end)
end

function OrionLib:MakeWindow(opts)
	local name = (opts and opts.Name) or "Window"
	local sg = mk("ScreenGui",{ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, pg)
	table.insert(self._rootGuis, sg)

	local win = mk("Frame",{
		BackgroundColor3 = Color3.fromRGB(22,22,22),
		Position = UDim2.new(0, 60, 0, 60),
		Size = UDim2.new(0, 640, 0, 420)
	}, sg)
	mk("UICorner",{CornerRadius = UDim.new(0,12)}, win)

	local top = mk("Frame",{BackgroundColor3 = Color3.fromRGB(28,28,28), Size = UDim2.new(1,0,0,42)}, win)
	mk("UICorner",{CornerRadius = UDim.new(0,12)}, top)
	mk("TextLabel",{
		BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = Color3.fromRGB(235,235,235), Position = UDim2.new(0,14,0,0), Size = UDim2.new(1,-28,1,0),
		TextXAlignment = Enum.TextXAlignment.Left
	}, top)
	makeDraggable(win, top)

	local left = mk("Frame",{BackgroundColor3 = Color3.fromRGB(26,26,26), Position = UDim2.new(0,0,0,42), Size = UDim2.new(0,170,1,-42)}, win)
	local right = mk("Frame",{BackgroundColor3 = Color3.fromRGB(18,18,18), Position = UDim2.new(0,170,0,42), Size = UDim2.new(1,-170,1,-42)}, win)

	local navList = mk("Frame",{BackgroundTransparency = 1, Size = UDim2.new(1,-12,1,-12), Position = UDim2.new(0,6,0,6)}, left)
	local navLayout = mk("UIListLayout",{Padding = UDim.new(0,6)}, navList)
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local tabHolder = mk("Frame",{BackgroundTransparency = 1, Size = UDim2.new(1,-16,1,-16), Position = UDim2.new(0,8,0,8)}, right)

	local windowApi = {}
	local activeTab -- {page=ScrollingFrame, btn=Button}

	function windowApi:MakeTab(topts)
		local tabName = tostring(topts.Name or "Tab")
		local btn = mk("TextButton",{
			Size = UDim2.new(1,0,0,34),
			Text = tabName,
			BackgroundColor3 = Color3.fromRGB(34,34,34),
			TextColor3 = Color3.fromRGB(235,235,235),
			Font = Enum.Font.Gotham,
			TextSize = 14,
			AutoButtonColor = true
		}, navList)
		mk("UICorner",{CornerRadius = UDim.new(0,8)}, btn)

		local page = mk("ScrollingFrame",{
			Active = true,
			Visible = false,
			Size = UDim2.new(1,0,1,0),
			CanvasSize = UDim2.new(0,0,0,0),
			ScrollBarThickness = 6,
			BackgroundTransparency = 1
		}, tabHolder)
		local stack = mk("UIListLayout",{Padding = UDim.new(0,8)}, page)
		stack:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0,0,0,stack.AbsoluteContentSize.Y+12)
		end)

		local function activate()
			if activeTab then activeTab.page.Visible = false end
			activeTab = {page = page, btn = btn}
			page.Visible = true
		end
		btn.MouseButton1Click:Connect(activate)

		-- AUTO-SELECT FIRST TAB (this was the issue)
		if not activeTab then activate() end

		local function addCard(height)
			local holder = mk("Frame",{BackgroundColor3 = Color3.fromRGB(30,30,30), Size = UDim2.new(1,-8,0,height or 38)}, page)
			mk("UICorner",{CornerRadius = UDim.new(0,8)}, holder)
			return holder
		end

		local tabApi = {}

		function tabApi:AddButton(bopts)
			local b = mk("TextButton",{
				Size = UDim2.new(1, -8, 0, 38),
				Text = tostring(bopts.Name or "Button"),
				BackgroundColor3 = Color3.fromRGB(35,35,35),
				TextColor3 = Color3.fromRGB(235,235,235),
				Font = Enum.Font.Gotham, TextSize = 14, AutoButtonColor = true
			}, page)
			mk("UICorner",{CornerRadius = UDim.new(0,8)}, b)
			b.MouseButton1Click:Connect(function()
				local cb = bopts.Callback
				if cb then task.spawn(cb) end
			end)
			return { Click = function() b:Fire() end }
		end

		function tabApi:AddToggle(topts)
			local holder = addCard(40)
			mk("TextLabel",{
				BackgroundTransparency = 1, Text = tostring(topts.Name or "Toggle"),
				Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(230,230,230),
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,12,0,0), Size = UDim2.new(1,-120,1,0)
			}, holder)
			local btn = mk("TextButton",{Text="", BackgroundColor3 = Color3.fromRGB(70,70,70), Size = UDim2.new(0,56,0,24), Position = UDim2.new(1,-68,0.5,-12)}, holder)
			mk("UICorner",{CornerRadius = UDim.new(1,0)}, btn)
			local knob = mk("Frame",{BackgroundColor3 = Color3.fromRGB(240,240,240), Size = UDim2.new(0,20,0,20), Position = UDim2.new(0,4,0.5,-10)}, btn)
			mk("UICorner",{CornerRadius = UDim.new(1,0)}, knob)

			local state = (topts.Default == true)
			local function apply(val)
				state = val and true or false
				btn.BackgroundColor3 = state and Color3.fromRGB(70,200,120) or Color3.fromRGB(70,70,70)
				knob.Position = state and UDim2.new(1,-24,0.5,-10) or UDim2.new(0,4,0.5,-10)
				local cb = topts.Callback
				if cb then task.spawn(cb, state) end
			end
			btn.MouseButton1Click:Connect(function() apply(not state) end)
			if state then apply(true) end
			return { Set = function(v) apply(v) end }
		end

		function tabApi:AddDropdown(dopts)
			local holder = addCard(40)
			mk("TextLabel",{
				BackgroundTransparency = 1, Text = tostring(dopts.Name or "Dropdown"),
				Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(230,230,230),
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,12,0,0), Size = UDim2.new(1,-180,1,0)
			}, holder)
			local sel = mk("TextButton",{
				Text = tostring(dopts.Default or "Select"),
				Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(235,235,235),
				BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(0,160,0,26),
				Position = UDim2.new(1,-172,0.5,-13), AutoButtonColor = true
			}, holder)
			mk("UICorner",{CornerRadius = UDim.new(0,6)}, sel)
			local listHolder = mk("Frame",{
				BackgroundColor3 = Color3.fromRGB(25,25,25), Size = UDim2.new(0,160,0,0),
				Position = UDim2.new(1,-172,0,40), Visible = false, ClipsDescendants = true, ZIndex = 5
			}, holder)
			mk("UICorner",{CornerRadius = UDim.new(0,6)}, listHolder)
			local uiList = mk("UIListLayout",{Padding = UDim.new(0,4)}, listHolder)
			uiList.SortOrder = Enum.SortOrder.LayoutOrder

			local function rebuild(opts)
				for _,c in ipairs(listHolder:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				for _,opt in ipairs(opts or {}) do
					local b = mk("TextButton",{
						Size = UDim2.new(1, 0, 0, 30),
						Text = tostring(opt),
						BackgroundColor3 = Color3.fromRGB(35,35,35),
						TextColor3 = Color3.fromRGB(235,235,235),
						Font = Enum.Font.Gotham, TextSize = 14, AutoButtonColor = true, ZIndex = 6
					}, listHolder)
					b.MouseButton1Click:Connect(function()
						sel.Text = tostring(opt)
						local cb = dopts.Callback
						if cb then task.spawn(cb, opt) end
						listHolder.Visible = false
					end)
				end
				listHolder.Size = UDim2.new(0,160,0, (#(opts or {}))*34 + 4)
			end
			rebuild(dopts.Options or {})
			sel.MouseButton1Click:Connect(function()
				listHolder.Visible = not listHolder.Visible
			end)

			return {
				Set = function(v)
					sel.Text = tostring(v)
					local cb = dopts.Callback
					if cb then task.spawn(cb, v) end
				end,
				Refresh = rebuild
			}
		end

		return tabApi
	end

	function OrionLib:Init() end
	return windowApi
end

--[[ =========================
      Your original script (unchanged)
      ========================= ]]

local getAsset = syn and getsynasset or getcustomasset

if not isfile("AmbrosiaAlert.mp3") then
	local request = syn and syn.request or request
	local raw = request({
		Url = "https://cdn.discordapp.com/attachments/752654393211486309/1012085895127650324/asddads.mp3",
		Method = "GET",
	})
	writefile("AmbrosiaAlert.mp3", raw.Body)
end

game.Workspace.Terrain:ClearAllChildren()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Plr = Players.LocalPlayer
local Characters = workspace:FindFirstChild("Players")
local Mine = workspace:FindFirstChild("Mine")

local Window = OrionLib:MakeWindow({Name = "End's Azure Mines Utility"})

-- Keep it simple: controls are visible on load
local Main = Window:MakeTab({ Name = "Main" })
local Misc = Window:MakeTab({ Name = "Misc" })

local Ore
local Raygun
local farming = false
local count
local fbcheck = 0
local deposit
local ESPtoggle
local AmbrosiaTP
local SafeMode = true
local skip
local zobies
local Noclip, Clip
local floatName

local function noclip()
	Clip = false
	if Noclip then Noclip:Disconnect() end
	Noclip = game:GetService('RunService').Stepped:Connect(function()
		if Clip == false and game.Players.LocalPlayer.Character ~= nil then
			for _,v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
				if v:IsA('BasePart') and v.CanCollide and v.Name ~= floatName then
					v.CanCollide = false
				end
			end
		end
	end)
end
local function clip() if Noclip then Noclip:Disconnect() end Clip = true end

if game.Workspace:FindFirstChild("Mine") and game.Workspace.Mine:FindFirstChild("Ambrosia") then
	OrionLib:MakeNotification({ Name = "OH MA GAWD", Content = "Ambrosia just spawned!", Time = 13 })
	local sound = Instance.new("Sound")
	sound.SoundId = getAsset("AmbrosiaAlert.mp3")
	sound.Parent = game.Workspace
	sound.Volume = 3.5
	sound.Playing = true
end

local function addUi(part)
	local partgui = Instance.new("BillboardGui")
	local frame = Instance.new("Frame")
	local namegui = Instance.new("BillboardGui")
	local text = Instance.new("TextLabel")
	partgui.Size = UDim2.new(1,0,1,0)
	partgui.AlwaysOnTop = true
	partgui.Name = "ESP"
	frame.BackgroundColor3 = Color3.fromRGB(255,80,60)
	frame.BackgroundTransparency = 0.75
	frame.Size = UDim2.new(1,0,1,0)
	frame.BorderSizePixel = 0
	frame.Parent = partgui
	namegui.Size = UDim2.new(3,0,1.5,0)
	namegui.SizeOffset = Vector2.new(0,1)
	namegui.AlwaysOnTop = true
	namegui.Name = "Namee"
	namegui.Parent = part
	text.Text = part.Name
	text.TextColor3 = Color3.fromRGB(255,80,60)
	text.TextTransparency = 0.25
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Size = UDim2.new(1,0,1,0)
	text.Font = Enum.Font.GothamSemibold
	text.Name = "Text"
	text.Parent = namegui
	partgui.Parent = part
end

-- ===== Main Tab: simple, all core controls =====
Main:AddDropdown({
	Name = "Select Ore",
	Default = "Ambrosia",
	Options = {"Ambrosia","Amethyst","Antimatter","Azure","Baryte","Boomite","Coal","Copper","Constellatium","Darkmatter","Diamond","Dragonglass","Dragonstone","Emerald","Firecrystal","Frightstone","Frostarium","Garnet","Gold","Illuminunium","Iron","Kappa","Mithril","Moonstone","Newtonium","Nightmarium","Opal","Painite","Platinum","Plutonium","Pumpkinite","Promethium","Rainbonite","Ruby","Sapphire","Silver","Serendibite","Sinistyte L","Sinistyte M","Sinistyte S","Stellarite","Stone","Sulfur","Symmetrium","Topaz","Twitchite","Unobtainium","Uranium"},
	Callback = function(Value) Ore = Value end
})

Main:AddButton({
	Name = "Teleport to Selected Ore",
	Callback = function()
		if not Mine or not Ore then return end
		for _,v in pairs(Mine:GetChildren()) do
			if v.Name == Ore then
				v.CanCollide = false
				local hrp = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = v.CFrame end
				break
			end
		end
	end
})

local susfarm -- forward declare to allow Set(false)
susfarm = Main:AddToggle({
	Name = "Enable Autofarm (Safe Mode on Misc)",
	Default = false,
	Callback = function(toggled)
		farming = toggled
		while farming do
			workspace.Gravity = 0
			noclip()
			local hrp = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.CFrame = CFrame.new(310, 4979, -152) end

			if Characters and Characters[Plr.Name] and not Characters[Plr.Name]:FindFirstChild("Pickaxe") then
				if Plr.Backpack:FindFirstChild("Pickaxe") then
					Plr.Backpack.Pickaxe.Parent = Characters[Plr.Name]; task.wait(0.1)
				end
			end
			if Characters and Characters[Plr.Name] and Characters[Plr.Name]:FindFirstChild("Pickaxe") and Characters[Plr.Name].Pickaxe:FindFirstChild("PickaxeScript") then
				Characters[Plr.Name].Pickaxe.PickaxeScript.Disabled = true
			end
			task.wait(0.5)
			if not Mine then break end

			for _,v in pairs(Mine:GetChildren()) do
				if not farming then break end
				if v.Name == Ore and v.Anchored == true then
					for _,p in pairs(Players:GetPlayers()) do
						if SafeMode and p ~= Plr and p.Character and p.Character:FindFirstChild("Head") then
							local d = (v.Position - p.Character.Head.Position).Magnitude
							if d <= 200 then skip = true break end
						end
					end
					if skip then skip = false; continue end

					local hrp2 = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp2 then hrp2.CFrame = v.CFrame; task.wait(0.1); hrp2.Anchored = true end

					if Raygun and Plr.Backpack:FindFirstChild("RayGun") and Plr.Backpack.RayGun:FindFirstChild("Gun") then
						local f = Plr.Backpack.RayGun.Gun:FindFirstChild("Func")
						if f and f:IsA("RemoteFunction") then
							pcall(function()
								f:InvokeServer("Fire", {v.Position, 661203044677.2754, v.Position + Vector3.new(0,-4,0)})
							end)
						end
					end

					if not (Characters and Characters[Plr.Name] and Characters[Plr.Name]:FindFirstChild("Pickaxe")) then
						susfarm:Set(false); farming = false; break
					end

					pcall(function() Characters[Plr.Name].Pickaxe.SetTarget:InvokeServer(v) end)
					task.wait(0.25)
					pcall(function() Characters[Plr.Name].Pickaxe.Activation:FireServer(true) end)

					count = 0
					repeat
						if not (Characters and Characters[Plr.Name] and Characters[Plr.Name]:FindFirstChild("Pickaxe")) then
							susfarm:Set(false); farming = false; break
						end
						if count >= 10 then break end
						task.wait(0.4)

						local char = Plr.Character
						local leg = char and char:FindFirstChild("Left Leg")
						if leg then
							local nearPlatform = false
							for _,s in pairs(workspace.Terrain:GetChildren()) do
								if s:IsA("BasePart") and (s.Position - leg.Position).Magnitude <= 6 then
									nearPlatform = true; break
								end
							end
							if nearPlatform then
								count = 0
								local hrp3 = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
								if hrp3 then hrp3.CFrame = v.CFrame end
							else
								count = count + 1
								local hrp3 = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
								if hrp3 then hrp3.CFrame = v.CFrame end
							end
						else
							count = count + 1
						end
					until not v or v.Parent ~= Mine or not farming

					local hrp4 = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
					if hrp4 then hrp4.Anchored = false end
					pcall(function() Characters[Plr.Name].Pickaxe.Activation:FireServer(false) end)
					if hrp4 then hrp4.CFrame = CFrame.new(310, 4979, -152) end
				end
			end

			if not farming then
				workspace.Gravity = 192
				clip()
				local hrp5 = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp5 then hrp5.Anchored = false end
				if Characters and Characters[Plr.Name] and Characters[Plr.Name]:FindFirstChild("Pickaxe") then
					local s = Characters[Plr.Name].Pickaxe:FindFirstChild("PickaxeScript")
					if s then s.Disabled = false end
				elseif Plr.Backpack:FindFirstChild("Pickaxe") then
					local s = Plr.Backpack.Pickaxe:FindFirstChild("PickaxeScript")
					if s then s.Disabled = false end
				end
			end
		end
	end
})

Main:AddToggle({
	Name = "Raygun Autofire (needs gamepass)",
	Default = false,
	Callback = function(v)
		Raygun = v
		if v then
			if not Plr.Backpack:FindFirstChild("RayGun") and not (Plr.Character and Plr.Character:FindFirstChild("RayGun")) then
				return print("no gp")
			end
			if Characters and Characters[Plr.Name] and not Characters[Plr.Name]:FindFirstChild("RayGun") then
				Plr.Backpack:FindFirstChild("RayGun").Parent = Characters[Plr.Name]
				task.wait(0.1)
				Characters[Plr.Name]:FindFirstChild("RayGun").Parent = Plr.Backpack
			end
		end
	end
})

Main:AddToggle({
	Name = "Ore ESP",
	Default = false,
	Callback = function(v)
		ESPtoggle = v
		if v then
			task.spawn(function()
				while ESPtoggle do
					task.wait(1.5)
					if not Mine or not Ore then break end
					for _,inst in pairs(Mine:GetChildren()) do
						if inst.Name == Ore and not inst:FindFirstChild("ESP") then
							addUi(inst)
						end
					end
				end
			end)
		else
			if not Mine then return end
			for _,inst in pairs(Mine:GetChildren()) do
				if inst:FindFirstChild("ESP") then inst.ESP:Destroy() end
				if inst:FindFirstChild("Namee") then inst.Namee:Destroy() end
			end
		end
	end
})

-- ===== Misc Tab: simple toggles =====
Misc:AddToggle({
	Name = "Safe Mode (skip ores near players)",
	Default = true,
	Callback = function(v) SafeMode = v end
})

Misc:AddToggle({
	Name = "Ghost-Collect Ambrosia",
	Default = false,
	Callback = function(v) AmbrosiaTP = v end
})

Misc:AddToggle({
	Name = "No Zombies",
	Default = false,
	Callback = function(v)
		zobies = v
		if zobies and workspace:FindFirstChild("Mine") then
			for _,n in pairs(workspace.Mine:GetChildren()) do
				if n.Name == "Zombie" or n.Name == "Zwambie" then n:Destroy() end
			end
		end
	end
})

Misc:AddButton({
	Name = "FullBright",
	Callback = function()
		fbcheck += 1
		if fbcheck >= 2 then return end
		local stuff = {Lighting:FindFirstChild("GameBlur"), Lighting:FindFirstChild("ColorCorrection"), Lighting:FindFirstChild("Blur"), Lighting:FindFirstChild("Bloom")}
		Lighting.FogEnd, Lighting.FogStart = 100000, 0
		if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Parent = ReplicatedStorage end
		for _,v in pairs(stuff) do if typeof(v)=="Instance" then v.Enabled=false end end
		task.spawn(function()
			while true do task.wait(); Lighting.Brightness=2; Lighting.ClockTime=13 end
		end)
	end
})

Misc:AddToggle({
	Name = "Auto Deposit",
	Default = false,
	Callback = function(v)
		deposit = v
		task.spawn(function()
			while deposit do
				pcall(function() ReplicatedStorage.MoveAllItems:InvokeServer() end)
				task.wait(5)
			end
		end)
	end
})

-- Ambrosia spawn listener
if workspace:FindFirstChild("Mine") then
	workspace.Mine.ChildAdded:Connect(function(child)
		task.wait(0.1)
		if child.Name == "Ambrosia" then
			OrionLib:MakeNotification({ Name = "OH MA GAWD", Content="Ambrosia just spawned!", Time=13 })
			local s = Instance.new("Sound")
			s.SoundId = getAsset("AmbrosiaAlert.mp3")
			s.Parent = workspace
			s.Volume = 3.5
			s.Playing = true
			if AmbrosiaTP then
				workspace.Gravity = 0
				if Characters and Characters[Plr.Name] and not Characters[Plr.Name]:FindFirstChild("Pickaxe") then
					if Plr.Backpack:FindFirstChild("Pickaxe") then Plr.Backpack.Pickaxe.Parent = Characters[Plr.Name] end
				end
				if Characters and Characters[Plr.Name] and Characters[Plr.Name]:FindFirstChild("Pickaxe") and Characters[Plr.Name].Pickaxe:FindFirstChild("PickaxeScript") then
					Characters[Plr.Name].Pickaxe.PickaxeScript.Disabled = true
				end
				child.CanCollide = false
				local hrp = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = child.CFrame; task.wait(0.1); hrp.Anchored = true end
				pcall(function() Characters[Plr.Name].Pickaxe.SetTarget:InvokeServer(child) end)
				task.wait(0.2)
				pcall(function() Characters[Plr.Name].Pickaxe.Activation:FireServer(true) end)
				repeat task.wait(0.1) until child.Parent ~= Mine
				task.wait(0.1)
				pcall(function() Characters[Plr.Name].Pickaxe.Activation:FireServer(false) end)
				workspace.Gravity = 192
				if hrp then hrp.Anchored = false end
				if Characters and Characters[Plr.Name] and Characters[Plr.Name]:FindFirstChild("Pickaxe") and Characters[Plr.Name].Pickaxe:FindFirstChild("PickaxeScript") then
					Characters[Plr.Name].Pickaxe.PickaxeScript.Disabled = false
				end
				pcall(function() game.ReplicatedStorage.ToSurface:InvokeServer() end)
			end
		elseif (child.Name == "Zombie" or child.Name == "Zwambie") and zobies then
			child:Destroy()
		end
	end)
end

OrionLib:Init()
print("UI ready.")

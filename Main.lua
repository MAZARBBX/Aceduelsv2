        mainOuter.Visible = State.guiVisible
        if _G.GreenDuelsQAHide then pcall(_G.GreenDuelsQAHide, not State.guiVisible) end
        requestSave()
    end)

    cloverBtn.MouseEnter:Connect(function() TweenService:Create(cloverBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(20,32,24)}):Play() end)
    cloverBtn.MouseLeave:Connect(function() TweenService:Create(cloverBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(14,24,18)}):Play() end)

    -- ============================================================
    -- SAVE / LOAD (ROBUST VERSION)
    -- ============================================================
    saveConfig = function()
        local success = false
        pcall(function()
            -- Create backup of existing config before overwriting
            if _isfile(CONFIG_FILE) then
                local oldRaw = _readfile(CONFIG_FILE)
                if oldRaw and oldRaw ~= "" then
                    pcall(function() _writefile(CONFIG_BACKUP, oldRaw) end)
                end
            end
            
            local btnPositions = {}
            for key, wrapper in pairs(stackWrappers) do
                if wrapper and wrapper.Position then
                    btnPositions[key] = { X = wrapper.Position.X.Offset, Y = wrapper.Position.Y.Offset }
                end
            end
            local cloverPos = cloverBtn and cloverBtn.Position and { X = cloverBtn.Position.X.Offset, Y = cloverBtn.Position.Y.Offset } or nil
            local cfg = {
                version = CONFIG_VERSION,
                normalSpeed = State.normalSpeed,
                carrySpeed = State.carrySpeed,
                laggerSpeed = State.laggerSpeed,
                laggerCarrySpeed = State.laggerCarrySpeed,
                speedToggled = State.speedToggled,
                laggerMode = State.laggerMode,
                stealRadius = Steal.StealRadius,
                stealDuration = Steal.StealDuration,
                uiScale = uiScaleObj and uiScaleObj.Scale or 1.0,
                stackButtonsHidden = State.stackButtonsHidden,
                stackButtonsLocked = State.stackButtonsLocked,
                speedKey = Keys.speed and Keys.speed.Name or "Q",
                autoLeftKey = Keys.autoLeft and Keys.autoLeft.Name or "L",
                autoRightKey = Keys.autoRight and Keys.autoRight.Name or "R",
                guiHideKey = Keys.guiHide and Keys.guiHide.Name or "LeftControl",
                dropKey = Keys.drop and Keys.drop.Name or "H",
                laggerKey = Keys.lagger and Keys.lagger.Name or "Unknown",
                tpDownKey = Keys.tpDown and Keys.tpDown.Name or "Unknown",
                aimbotKey = Keys.aimbot and Keys.aimbot.Name or "Unknown",
                infJump = State.infJumpEnabled,
                antiRagdoll = State.antiRagdollEnabled,
                medusaCounter = State.medusaCounterEnabled,
                batCounter = State.batCounterEnabled,
                autoStealEnabled = Steal.AutoStealEnabled,
                autoSwing = State.autoSwingEnabled,
                batAimbot = State.batAimbotToggled,
                antiLagEnabled = State.antiLagEnabled,
                stretchedResEnabled = State.stretchedResEnabled,
                stretchFOV = State.stretchFOV,
                normalFOV = _G._VezyFOV or 70,
                activeSky = State.activeSky,
                nukeOptimizer = State.nukeOpt,
                removeAccessories = State.removeAcc,
                tryardAnimEnabled = State.tryardAnimEnabled,
                introEnabled = State.introEnabled,
                guiVisible = State.guiVisible,
                buttonPositions = btnPositions,
                cloverPosition = cloverPos,
                autoTPEnabled = State.autoTPEnabled,
                autoTPHeight = State.autoTPHeight,
                dropType = currentDropType,
            }
            local encoded = HttpService:JSONEncode(cfg)
            _writefile(CONFIG_FILE, encoded)
            -- Verify write succeeded
            local verify = _readfile(CONFIG_FILE)
            if verify == encoded then success = true end
        end)
        if not success then
            pcall(_G._VezyFlashSave, false)
            warn("[Green Duels] Config save FAILED!")
        else
            pcall(_G._VezyFlashSave, true)
        end
        return success
    end

    loadConfig = function()
        -- Try to load from main file
        local raw = nil
        if _isfile(CONFIG_FILE) then
            raw = _readfile(CONFIG_FILE)
        end
        -- If main file missing or corrupt, try backup
        if not raw or raw == "" then
            if _isfile(CONFIG_BACKUP) then
                raw = _readfile(CONFIG_BACKUP)
                if raw and raw ~= "" then
                    print("[Green Duels] Loaded config from backup")
                end
            end
        end
        if not raw or raw == "" then
            print("[Green Duels] No valid config file found, using defaults")
            return false
        end
        
        local ok, decErr = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok or not decErr then
            -- Corrupt config â€“ delete it and use defaults
            pcall(function() _delfile(CONFIG_FILE) end)
            pcall(function() _delfile(CONFIG_BACKUP) end)
            warn("[Green Duels] Corrupt config deleted, using defaults")
            return false
        end

        local function applyNumber(key, targetVar, uiBox)
            if decErr[key] then
                targetVar = decErr[key]
                if uiBox and uiBox.Text then uiBox.Text = tostring(decErr[key]) end
            end
            return targetVar
        end

        State.normalSpeed = applyNumber("normalSpeed", State.normalSpeed, normalBox)
        State.carrySpeed = applyNumber("carrySpeed", State.carrySpeed, carryBox)
        State.laggerSpeed = applyNumber("laggerSpeed", State.laggerSpeed, laggerBox)
        State.laggerCarrySpeed = applyNumber("laggerCarrySpeed", State.laggerCarrySpeed, laggerCarryBox)
        Steal.StealRadius = applyNumber("stealRadius", Steal.StealRadius, stealRadBox)
        Steal.StealDuration = applyNumber("stealDuration", Steal.StealDuration, stealDurBox)
        if decErr.uiScale and uiScaleObj then
            uiScaleObj.Scale = decErr.uiScale
            if uiScaleBox then uiScaleBox.Text = tostring(decErr.uiScale) end
        end
        if decErr.normalFOV then
            _G._VezyFOV = decErr.normalFOV
            pcall(function() workspace.CurrentCamera.FieldOfView = _G._VezyFOV end)
        end
        if decErr.autoTPEnabled ~= nil then State.autoTPEnabled = decErr.autoTPEnabled end
        if decErr.autoTPHeight then
            State.autoTPHeight = decErr.autoTPHeight
            if autoTPHeightBox then autoTPHeightBox.Text = tostring(State.autoTPHeight) end
        end

        if decErr.dropType and (decErr.dropType == DROP_TYPES.STAND or decErr.dropType == DROP_TYPES.JUMP) then
            currentDropType = decErr.dropType
            if standDropBtn and jumpDropBtn then
                if currentDropType == DROP_TYPES.STAND then
                    standDropBtn.BackgroundColor3 = C.accent
                    standDropBtn.TextColor3 = Color3.fromRGB(0,20,8)
                    jumpDropBtn.BackgroundColor3 = C.inputBg
                    jumpDropBtn.TextColor3 = C.inputTxt
                else
                    jumpDropBtn.BackgroundColor3 = C.accent
                    jumpDropBtn.TextColor3 = Color3.fromRGB(0,20,8)
                    standDropBtn.BackgroundColor3 = C.inputBg
                    standDropBtn.TextColor3 = C.inputTxt
                end
            end
        end

        local bools = {
            stackButtonsHidden="stackButtonsHidden", stackButtonsLocked="stackButtonsLocked",
            infJump="infJumpEnabled", antiRagdoll="antiRagdollEnabled",
            medusaCounter="medusaCounterEnabled", batCounter="batCounterEnabled",
            autoStealEnabled="autoStealEnabled", autoSwing="autoSwingEnabled",
            batAimbot="batAimbotToggled", antiLagEnabled="antiLagEnabled",
            stretchedResEnabled="stretchedResEnabled", nukeOptimizer="nukeOpt",
            removeAccessories="removeAcc", tryardAnimEnabled="tryardAnimEnabled",
            introEnabled="introEnabled", guiVisible="guiVisible",
            speedToggled="speedToggled", autoTPEnabled="autoTPEnabled",
        }
        for cfgKey, stateKey in pairs(bools) do
            if decErr[cfgKey] ~= nil then State[stateKey] = decErr[cfgKey] end
        end
        if decErr.laggerMode ~= nil then State.laggerMode = decErr.laggerMode end
        if decErr.stretchFOV then State.stretchFOV = decErr.stretchFOV end
        if decErr.activeSky then State.activeSky = decErr.activeSky end

        local keyMap = {
            speedKey="speed", autoLeftKey="autoLeft", autoRightKey="autoRight",
            guiHideKey="guiHide", dropKey="drop", laggerKey="lagger",
            tpDownKey="tpDown", aimbotKey="aimbot"
        }
        for cfgKey, stateKey in pairs(keyMap) do
            if decErr[cfgKey] then
                local kc = Enum.KeyCode[decErr[cfgKey]]
                if kc then
                    Keys[stateKey] = kc
                    if keybindBtnRefs[stateKey] then keybindBtnRefs[stateKey].Text = getKeyDisplayName(kc) end
                end
            end
        end

        mainOuter.Visible = State.guiVisible
        if _G.GreenDuelsQAHide then pcall(_G.GreenDuelsQAHide, not State.guiVisible) end
        for _, wrapper in pairs(stackWrappers) do wrapper.Visible = not State.stackButtonsHidden end
        if hideButtonsSetter then hideButtonsSetter(State.stackButtonsHidden) end
        if lockButtonsSetter then lockButtonsSetter(State.stackButtonsLocked) end

        if State.laggerMode == 0 then
            if carryBox then carryBox.Text = tostring(State.speedToggled and State.carrySpeed or State.normalSpeed) end
        elseif State.laggerMode == 1 then
            if carryBox then carryBox.Text = tostring(State.laggerSpeed) end
        elseif State.laggerMode == 2 then
            if carryBox then carryBox.Text = tostring(State.laggerCarrySpeed) end
        end
        if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
        if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(State.laggerMode == 1) end
        if stackBtnRefs.laggerCarry then stackBtnRefs.laggerCarry.setOn(State.laggerMode == 2) end
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(State.batAimbotToggled) end
        if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(State.autoLeftEnabled) end
        if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(State.autoRightEnabled) end

        if State.antiLagEnabled then enableAntiLag() else disableAntiLag() end
        if State.stretchedResEnabled then enableStretchRez() else disableStretchRez() end
        if State.activeSky then applySky(State.activeSky) else applySky(nil) end
        if State.nukeOpt then _G._nukeStart() else _G._nukeStop() end
        if State.removeAcc then _G._removeAccStart() else _G._removeAccStop() end
        if State.tryardAnimEnabled then startTryardAnim() else stopTryardAnim() end
        if State.batAimbotToggled then startBatAimbot() else stopBatAimbot() end
        if State.batCounterEnabled then startBatCounter() else stopBatCounter() end
        if State.medusaCounterEnabled then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
        if State.antiRagdollEnabled then startAntiRagdoll() else stopAntiRagdoll() end
        if Steal.AutoStealEnabled then startAutoSteal() else stopAutoSteal() end
        if State.autoTPEnabled then startAutoTP() else stopAutoTP() end

        for key, setter in pairs(toggleSetters) do
            local stateValue = nil
            if key=="autoSteal" then stateValue=Steal.AutoStealEnabled
            elseif key=="infJump" then stateValue=State.infJumpEnabled
            elseif key=="antiRagdoll" then stateValue=State.antiRagdollEnabled
            elseif key=="medusaCounter" then stateValue=State.medusaCounterEnabled
            elseif key=="batCounter" then stateValue=State.batCounterEnabled
            elseif key=="autoSwing" then stateValue=State.autoSwingEnabled
            elseif key=="antiLag" then stateValue=State.antiLagEnabled
            elseif key=="stretchedRes" then stateValue=State.stretchedResEnabled
            elseif key=="nukeOpt" then stateValue=State.nukeOpt
            elseif key=="removeAcc" then stateValue=State.removeAcc
            elseif key=="tryardAnim" then stateValue=State.tryardAnimEnabled
            elseif key=="introEnabled" then stateValue=State.introEnabled
            elseif key=="hideButtons" then stateValue=State.stackButtonsHidden
            elseif key=="lockButtons" then stateValue=State.stackButtonsLocked
            elseif key=="autoTP" then stateValue=State.autoTPEnabled
            end
            if stateValue ~= nil then pcall(setter, stateValue) end
        end

        refreshAllKeybindButtons()

        if decErr.buttonPositions then
            for key, posData in pairs(decErr.buttonPositions) do
                local wrapper = stackWrappers[key]
                if wrapper and posData.X and posData.Y then
                    wrapper.Position = UDim2.new(wrapper.Position.X.Scale, posData.X, wrapper.Position.Y.Scale, posData.Y)
                end
            end
        end
        if decErr.cloverPosition and cloverBtn then
            cloverBtn.Position = UDim2.new(0, decErr.cloverPosition.X, 0, decErr.cloverPosition.Y)
        end

        print("[Green Duels] Config loaded successfully")
        return true
    end

    requestSave = function()
        local ok = saveConfig()
        if ok then
            if _G._VezyFlashSave then _G._VezyFlashSave(true) end
        else
            if _G._VezyFlashSave then _G._VezyFlashSave(false) end
        end
    end

    -- ============================================================
    -- INIT
    -- ============================================================
    loadPresetsFile()
    rebuildPresetList()
    local _lastPresetName = loadLastPresetName()
    if _lastPresetName and _lastPresetName~="" then
        for _,preset in ipairs(Presets) do
            if preset.name==_lastPresetName then
                pcall(function()
                    local d=preset.data or {}
                    if d.normalSpeed then State.normalSpeed=d.normalSpeed; if normalBox then normalBox.Text=tostring(d.normalSpeed) end end
                    if d.carrySpeed then State.carrySpeed=d.carrySpeed; if carryBox then carryBox.Text=tostring(d.carrySpeed) end end
                    if d.laggerSpeed then State.laggerSpeed=d.laggerSpeed; if laggerBox then laggerBox.Text=tostring(d.laggerSpeed) end end
                    if d.laggerCarrySpeed then State.laggerCarrySpeed=d.laggerCarrySpeed; if laggerCarryBox then laggerCarryBox.Text=tostring(d.laggerCarrySpeed) end end
                    if d.stealRadius then Steal.StealRadius=d.stealRadius; if stealRadBox and not stealRadBox:IsFocused() then stealRadBox.Text=tostring(Steal.StealRadius) end end
                    if d.stealDuration then Steal.StealDuration=d.stealDuration; if stealDurBox then stealDurBox.Text=tostring(Steal.StealDuration) end end
                    if d.autoTP ~= nil then State.autoTPEnabled=d.autoTP; if toggleSetters["autoTP"] then toggleSetters["autoTP"](d.autoTP) end end
                    if d.autoTPHeight then State.autoTPHeight=d.autoTPHeight; if autoTPHeightBox then autoTPHeightBox.Text=tostring(d.autoTPHeight) end end
                end)
                break
            end
        end
    end
    loadConfig()
    -- DO NOT force AutoSteal to true here â€“ keep saved value
    startAutoSteal()
    print("[Green Duels] Ready. Stand drop = Brainrot fling (safe). Jump drop = ascend.")
end

-- ============================================================
-- SAFE MAIN EXECUTION
-- ============================================================
if not _G.GreenDuelsV2_MainExecuted then
    if LP and LP:FindFirstChild("PlayerGui") then
        Main()
    else
        LP = LP or Players:WaitForChild("LocalPlayer")
        LP:WaitForChild("PlayerGui")
        Main()
    end
end

-- ============================================================
-- OTHER PLAYERS SPEED DISPLAY
-- ============================================================
;(function()
local function setupOtherPlayerSpeed(player)
    if player == LP then return end
    local function onCharacterAdded(char)
        task.wait(0.2)
        local head = char:FindFirstChild("Head")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end
        local oldBB = head:FindFirstChild("GreenDuelsBB_Other")
        if oldBB then oldBB:Destroy() end
        local bb = Instance.new("BillboardGui", head)
        bb.Name = "GreenDuelsBB_Other"
        bb.Size = UDim2.new(0, 160, 0, 24)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        local speedLbl = Instance.new("TextLabel", bb)
        speedLbl.Name = "SpeedBillLbl"
        speedLbl.Size = UDim2.new(1, 0, 1, 0)
        speedLbl.Position = UDim2.new(0, 0, 0, 0)
        speedLbl.BackgroundTransparency = 1
        speedLbl.Text = "0.0"
        speedLbl.TextColor3 = Color3.fromRGB(38, 240, 125)
        speedLbl.Font = Enum.Font.GothamBlack
        speedLbl.TextScaled = true
        speedLbl.TextStrokeTransparency = 0
        speedLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        task.spawn(function()
            while char and char.Parent and hrp and hrp.Parent and speedLbl and speedLbl.Parent do
                pcall(function()
                    local hspd = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
                    speedLbl.Text = string.format("%.1f", hspd)
                end)
                task.wait(0.1)
            end
        end)
    end
    if player.Character then task.spawn(function() onCharacterAdded(player.Character) end) end
    player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LP then task.spawn(function() setupOtherPlayerSpeed(player) end) end
end
Players.PlayerAdded:Connect(function(player)
    task.spawn(function() setupOtherPlayerSpeed(player) end)
end)
end)()

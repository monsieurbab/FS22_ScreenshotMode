-- Author: Monsieur Bab
-- Version: 1.0.0.0
-- Date: 2022-04

ScreenshotModeOverlay = {
    CONTROLS = {
        "colorGradingPreset",
        "seasonPeriod",
        "weather",
        "dayTime"
    }
}

ScreenshotModeOverlay.COLOR_GRADING_PRESET = {
    [1] = g_i18n:getText("button_no"),
    [2] = "Preset 1",
    [3] = "Preset 2",
    [4] = "Preset 3",
    [5] = "Preset 4",
    [6] = "Preset 5",
    [7] = "Preset 6",
    [8] = "Preset 7",
    [9] = "Preset 8",
    [10] = "Preset 9"
}
ScreenshotModeOverlay.SEASON_PERIOD = {
    [1] = g_i18n:getText("earlySpring"),
    [2] = g_i18n:getText("midSpring"),
    [3] = g_i18n:getText("lateSpring"),
    [4] = g_i18n:getText("earlySummer"),
    [5] = g_i18n:getText("midSummer"),
    [6] = g_i18n:getText("lateSummer"),
    [7] = g_i18n:getText("earlyAutumn"),
    [8] = g_i18n:getText("midAutumn"),
    [9] = g_i18n:getText("lateAutumn"),
    [10] = g_i18n:getText("earlyWinter"),
    [11] = g_i18n:getText("midWinter"),
    [12] = g_i18n:getText("lateWinter")
}
ScreenshotModeOverlay.WEATHER = {
    [1] = g_i18n:getText("sun") .. " 1",
    [2] = g_i18n:getText("sun") .. " 2",
    [3] = g_i18n:getText("sun") .. " 3",
    [4] = g_i18n:getText("sun") .. " 4",
    [5] = g_i18n:getText("rain") .. " 1",
    [6] = g_i18n:getText("rain") .. " 2",
    [7] = g_i18n:getText("rain") .. " 3",
    [8] = g_i18n:getText("rain") .. " 4",
    [9] = g_i18n:getText("cloudy") .. " 1",
    [10] = g_i18n:getText("cloudy") .. " 2",
    [11] = g_i18n:getText("cloudy") .. " 3",
    [12] = g_i18n:getText("cloudy") .. " 4"
}
ScreenshotModeOverlay.DAY_TIME = {
    [0] = "00:00",
    [1] = "01:00",
    [2] = "02:00",
    [3] = "03:00",
    [4] = "04:00",
    [5] = "05:00",
    [6] = "06:00",
    [7] = "07:00",
    [8] = "08:00",
    [9] = "09:00",
    [10] = "10:00",
    [11] = "11:00",
    [12] = "12:00",
    [13] = "13:00",
    [14] = "14:00",
    [15] = "15:00",
    [16] = "16:00",
    [17] = "17:00",
    [18] = "18:00",
    [19] = "19:00",
    [20] = "20:00",
    [21] = "21:00",
    [22] = "22:00",
    [23] = "23:00"
}
ScreenshotModeOverlay.WEATHER_DATA = {
    { typeName = "SUN", variation = 1 },
    { typeName = "SUN", variation = 2 },
    { typeName = "SUN", variation = 3 },
    { typeName = "SUN", variation = 4 },
    { typeName = "RAIN", variation = 1 },
    { typeName = "RAIN", variation = 2 },
    { typeName = "RAIN", variation = 3 },
    { typeName = "RAIN", variation = 4 },
    { typeName = "CLOUDY", variation = 1 },
    { typeName = "CLOUDY", variation = 2 },
    { typeName = "CLOUDY", variation = 3 },
    { typeName = "CLOUDY", variation = 4 }
}

local ScreenshotModeOverlay_mt = Class(ScreenshotModeOverlay, ScreenElement)

function ScreenshotModeOverlay.new(target, customMt)
    local self = ScreenElement.new(target, customMt or ScreenshotModeOverlay_mt)

    self:registerControls(ScreenshotModeOverlay.CONTROLS)

    return self
end

function ScreenshotModeOverlay:onOpen()
    self.setupCompleted = false

    -- Save previous vars values
    self.previousColorGradingDayFilename = g_currentMission.environment.lighting.colorGradingDay
    self.previousFovY = math.deg(getFovY(getCamera()))
    self.previousCamera = getCamera()
    self.previousEnvironmentXmlFile = loadXMLFile("environmentXML", ScreenshotMode.dir .. "xml/environment.xml")
    g_currentMission.environment:saveToXMLFile(self.previousEnvironmentXmlFile, "environment")

    -- Set up new camera
    self.camera = createTransformGroup("ScreenshotModeCameraTarget")
    local cam = createCamera("ScreenshotModeCamera", getFovY(self.previousCamera), 1, 10000)
    link(getRootNode(), self.camera)
    link(self.camera, cam)
    setWorldTranslation(self.camera, getWorldTranslation(self.previousCamera))
    setWorldRotation(self.camera, getWorldRotation(self.previousCamera))
    setCamera(cam)

    -- Camera Rotation by mouse click vars
    self.mouseDragActive = false
    self.lastMousePosX = 0
    self.lastMousePosY = 0
    self.invertCamRotY = self:isCamRotYInverted()

    -- Capture vars
    self.captureCooldown = 0
    self.captureSound = ScreenshotMode:loadSound("captureSound", "sounds/capture-sound.ogg")

    -- Set multiTextOption texts
    self.colorGradingPreset:setTexts(self.COLOR_GRADING_PRESET)
    self.seasonPeriod:setTexts(self.SEASON_PERIOD)
    self.weather:setTexts(self.WEATHER)
    self.dayTime:setTexts(self.DAY_TIME)

    -- Set multiTextOption values
    self.colorGradingPreset:setState(1, true)
    self.seasonPeriod:setState(g_currentMission.environment.currentPeriod, true)
    self.weather:setState(1, true)
    self.dayTime:setState(g_currentMission.environment.currentHour, true)

    g_currentMission:setManualPause(true)

    self.setupCompleted = true
    ScreenshotModeOverlay:superClass().onOpen(self)
end

function ScreenshotModeOverlay:onClose()
    ScreenshotModeOverlay:superClass().onClose(self)
end

function ScreenshotModeOverlay:onClickBack()
    g_currentMission:setManualPause(false)

    -- Reset environment
    g_currentMission.environment:loadFromXMLFile(self.previousEnvironmentXmlFile, "environment")

    -- Unload ambient sounds to avoid WARNING from consoleCommandWeatherReloadData() method
    self:unloadAmbientSound("sun")
    self:unloadAmbientSound("rain")
    self:unloadAmbientSound("cloudy")
    self:unloadAmbientSound("snow")

    g_currentMission.environment.weather:consoleCommandWeatherReloadData()
    g_currentMission.environment:update(1, true)

    -- Reset season visuals
    g_currentMission.environment:setFixedPeriod(nil)

    -- Reset lighting
    g_currentMission.environment:setCustomLighting(nil)

    -- Reset camera
    setCamera(self.previousCamera)
    delete(self.camera)

    -- Reset FOV
    g_currentMission:consoleCommandSetFOV(self.previousFovY)
    
    self:changeScreen()
end

function ScreenshotModeOverlay:mouseEvent(posX, posY, isDown, isUp, button)
    if isDown then
        local isOnGuiElement = false

        for i = 1, #self:getRootElement().elements do
            local child = self:getRootElement().elements[i]
    
            local clipX1 = child.absPosition[1]
            local clipY1 = child.absPosition[2]
            local clipX2 = child.absPosition[1] + child.absSize[1]
            local clipY2 = child.absPosition[2] + child.absSize[2]

            if posX >= clipX1 and posX <= clipX2 and posY >= clipY1 and posY <= clipY2 then
                isOnGuiElement = true
            end
        end

        if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_LEFT) and not isOnGuiElement then
            self.mouseDragActive = true
            self.lastMousePosX = posX
            self.lastMousePosY = posY
            self.draw = self.drawFocusOverlay
        end

        -- Reset FOV
        if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_MIDDLE) then
            setFovY(getChildAt(self.camera, 0), math.rad(self.previousFovY))
            --Log:debug("FOV reset to " .. self.previousFovY)
        end

        local fovY = math.deg(getFovY(getChildAt(self.camera, 0)))

        -- Increase / Decrease FOV
        if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
            fovY = MathUtil.clamp(fovY - 1, 1, 100)
        elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
            fovY = MathUtil.clamp(fovY + 1, 1, 100)
        end
        
        if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) or Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
            setFovY(getChildAt(self.camera, 0), math.rad(fovY))
            --Log:debug("FOV changed to " .. fovY)
        end
    end

    if isUp then
        if button == Input.MOUSE_BUTTON_LEFT then
            self.mouseDragActive = false
            self.draw = ScreenshotModeOverlay:superClass().draw
        end
    end

    if self.mouseDragActive then
        local speed = 5
        local x, y, z = getRotation(self.camera)
        local dragX = posX - self.lastMousePosX
        local dragY = posY - self.lastMousePosY
        self.lastMousePosX = posX
        self.lastMousePosY = posY

        if self.invertCamRotY then
            setRotation(self.camera, x + (dragY * speed), y - (dragX * speed), z)
        else
            setRotation(self.camera, x + (dragY * speed), y + (dragX * speed), z)
        end
    end
end

function ScreenshotModeOverlay:drawFocusOverlay()
    local imageOverlay = createImageOverlay(ScreenshotMode.dir .. "images/focus-overlay.dds")
    local x, y = (0.5 - ((1024 / g_screenWidth) / 2)), (0.5 - ((1024 / g_screenHeight) / 2))
    local w, h = (1024 / g_screenWidth), (1024 / g_screenHeight)
    renderOverlay(imageOverlay, x, y, w, h)
end

function ScreenshotModeOverlay:update(dt)
    self:translateCam()
    self:rotateCam()

    if (Input.isKeyPressed(Input.KEY_return) or Input.isKeyPressed(Input.KEY_f12) or Input.isKeyPressed(Input.KEY_print)) and self.captureCooldown == 0 then
        self.captureCooldown = 10

        if self.getIsVisible(self) then
            self.setVisible(self, false)
            self.setAlpha(self, 0)
        end
    end

    if self.captureCooldown > 0 then
        if self.captureCooldown == 5 then
            if g_screenshotsDirectory ~= nil then
	            playSample(self.captureSound, 1, 1, 0, 0, 0)
                local screenshotName = g_screenshotsDirectory .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. "_ScreenshotMode.png"
                saveScreenshot(screenshotName)
                --Log:debug("Saving screenshot: " .. screenshotName)
            else
                --Log:debug("Unable to find screenshot directory!")
            end
        end

        self.captureCooldown = self.captureCooldown - 1
    end

    if not self.getIsVisible(self) and self.captureCooldown == 0 then
        self.setVisible(self, true)
        self.setAlpha(self, 1)
    end
end

function ScreenshotModeOverlay:translateCam()
    local speed = 0.1
    local x, y, z = getTranslation(self.camera)
    local dirX, dirY, dirZ = 0, 0, 0

    -- Forward / Backward
    if Input.isKeyPressed(Input.KEY_w) then
        dirZ = -1
    elseif Input.isKeyPressed(Input.KEY_s) then
        dirZ = 1
    end

    -- Left / Right
    if Input.isKeyPressed(Input.KEY_a) then
        dirX = -1
    elseif Input.isKeyPressed(Input.KEY_d) then
        dirX = 1
    end

    -- Up / Down
    if Input.isKeyPressed(Input.KEY_q) then
        dirY = 1
    elseif Input.isKeyPressed(Input.KEY_e) then
        dirY = -1
    end

    local lDirX, lDirY, lDirZ = localDirectionToWorld(self.camera, dirX, dirY, dirZ)
    setTranslation(self.camera, x + (lDirX * speed), y + (lDirY * speed), z + (lDirZ * speed))
end

function ScreenshotModeOverlay:rotateCam()
    local speed = 0.01
    local x, y, z = getRotation(getChildAt(self.camera, 0))
    local rotX, rotY, rotZ = 0, 0, 0

    -- Left / Right
    if Input.isKeyPressed(Input.KEY_z) then
        rotZ = 1
    elseif Input.isKeyPressed(Input.KEY_c) then
        rotZ = -1
    end

    setRotation(getChildAt(self.camera, 0), x + (rotX * speed), y + (rotY * speed), z + (rotZ * speed))
end

function ScreenshotModeOverlay:isCamRotYInverted()
    local x, y, z = getWorldRotation(self.previousCamera)

    if x <= 0 then
        return true
    else
        return false
    end
end

function ScreenshotModeOverlay:unloadAmbientSound(xmlAttributeName)
    for key, modifier in ipairs(g_currentMission.ambientSoundSystem.modifiers) do
        if modifier.xmlAttributeName == xmlAttributeName then
            table.remove(g_currentMission.ambientSoundSystem.modifiers, key)
        end
    end
end

function ScreenshotModeOverlay:onColorGradingPresetChanged(selection)
    local env = g_currentMission.environment

    local xmlFile = XMLFile.load("Environment", env.xmlFilename)
    local lighting = Lighting.new(env)
    lighting:load(xmlFile, "environment.lighting")

    if selection ~= 1 then
        lighting.colorGradingDay = ScreenshotMode.dir .. "xml/color-grading-presets/preset-" .. selection-1 .. ".xml"
    else
        lighting.colorGradingDay = self.previousColorGradingDayFilename
    end

    -- Reset then set the custom lighting
    env:setCustomLighting(nil)
    env:setCustomLighting(lighting)

    self.currentColorGradingPreset = selection
    --Log:debug("Color Grading Preset changed to " .. selection)
end

function ScreenshotModeOverlay:onSeasonPeriodChanged(selection)
    g_currentMission.environment:setFixedPeriod(selection)
    g_currentMission.environment:update(1, true)

    if self.setupCompleted then
        self:onWeatherChanged(self.currentWeather)

        -- Increase hour by 1 then decrease it by 1
        -- because environment time is not updated if current day-time is equal to new day-time
        self:onDayTimeChanged(self.currentDayTime + 1)
        self:onDayTimeChanged(self.currentDayTime - 1)
    end

    self.currentSeasonPeriod = selection
    --Log:debug("Season Period changed to " .. selection)
end

-- Todo: Manually activate weather objects to not be restricted to current season weather
-- and be able to set our own weathers via custom /maps/environment.xml file
function ScreenshotModeOverlay:onWeatherChanged(selection)
    g_currentMission.environment.weather:consoleCommandWeatherSet(self.WEATHER_DATA[selection].typeName, self.WEATHER_DATA[selection].variation)
    g_currentMission.environment:update(1, true)
    self.currentWeather = selection

    --Log:debug("Weather changed to " .. self.WEATHER_DATA[selection].typeName .. " (variation " .. self.WEATHER_DATA[selection].variation .. ")")
end

-- Note: Don't use consoleCommandSetDayTime() because it increments days if we decrease the time and this make clouds buggy
function ScreenshotModeOverlay:onDayTimeChanged(selection)
    local env = g_currentMission.environment

    env:setEnvironmentTime(env.currentMonotonicDay, env.currentDay, math.floor(selection * 1000 * 60 * 60), env.daysPerPeriod, false)
    env:update(1, true)
    self.currentDayTime = selection

    --Log:debug("Day Time changed to " .. selection .. ":00")
end

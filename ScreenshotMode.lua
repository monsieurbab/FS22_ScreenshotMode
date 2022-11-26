-- Author: Monsieur Bab
-- Version: 1.0.0.0
-- Date: 2022-04

ScreenshotMode = Mod:init()

FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, function()
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
    local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.OPEN_SCREENSHOT_MODE_OVERLAY, ScreenshotMode, ScreenshotMode.showScreenshotModeOverlay, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(actionEventId, true)
end)

function ScreenshotMode:showScreenshotModeOverlay()
    if self.gui == nil then
        self.gui = {}
        self.gui["screenshotModeOverlay"] = ScreenshotModeOverlay.new(nil, nil)

        g_gui:loadGui(ScreenshotMode.dir .. "gui/ScreenshotModeOverlay.xml", "ScreenshotModeOverlayGUI", self.gui.screenshotModeOverlay) 
    end

    g_gui:showGui("ScreenshotModeOverlayGUI")
end

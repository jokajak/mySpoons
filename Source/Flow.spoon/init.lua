-- Inspired by Ki.spoon (https://github.com/andweeb/ki)

local Flow = {}
Flow.name = "Flow"
Flow.version = "0.1.0"
Flow.author = "Jokajak"
Flow.homepage = "https://github.com/jokajak/mySpoons/Source/Flow.spoon/"

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

local _log = hs.logger.new('Flow', 'debug')

Flow.spoonPath = script_path()
dofile(Flow.spoonPath.."/simple_stack.lua")
local defaultModes = dofile(Flow.spoonPath.."/defaults.lua")
Flow.history = Stack:Create()

-- TODO: Convert trayColor to proper format automatically
function Flow:start()
    local config_modes = self.config or defaultModes
    self.config = config_modes
    local history = self.history
    for mode, config in pairs(config_modes) do
        spoon.ModalMgr:new(mode)
        local cmodal = spoon.ModalMgr.modal_list[mode]
        for _, hotkeys in pairs(config.hotkeys) do
            _log.d(hs.inspect.inspect(hotkeys))
            local modifiers = hotkeys[1] or ''
            local keycode = hotkeys[2]
            local exitModal = hotkeys[3]
            local handler = hotkeys[4]
            local description = hotkeys[5]
            if handler == 'exit' then
                handler = function() spoon.ModalMgr:deactivate({mode}) end
            elseif handler == 'previous' then
                handler = function()
                    local prev_mode = spoon.Flow.history:pop()
                    spoon.ModalMgr:deactivate({mode})
                    if prev_mode then
                        local trayColor = spoon.Flow.config[prev_mode]['trayColor']
                        spoon.ModalMgr:activate({prev_mode}, trayColor)
                    end
                end
            elseif type(handler) == 'string' and config_modes[handler] then
                local next_mode = handler
                local trayColor = config_modes[next_mode]['trayColor']
                _log.d('Creating transition from '..mode..' to '.. next_mode)
                _log.d('Traycolor: '..hs.inspect.inspect(trayColor))
                handler = function()
                    local nmodal = spoon.ModalMgr.modal_list[next_mode]
                    if nmodal then
                        history:push(mode)
                        spoon.ModalMgr:deactivate({mode})
                        spoon.ModalMgr:activate({next_mode}, trayColor)
                    else
                        hs.alert.show('Unknown transition from '..hs.inspect.inspect(mode)..' to '..hs.inspect.inspect(next_mode))
                    end
                end
            end
            if exitModal then
                local old_handler = handler
                handler = function()
                    spoon.ModalMgr:deactivate({mode})
                    old_handler()
                end
            end
            -- _log.d(hs.inspect.inspect(hotkeys))
            -- _log.d('Modifiers: '..hs.inspect.inspect(modifiers))
            -- _log.d('Keycode: '..hs.inspect.inspect(keycode))
            -- _log.d(description)
            -- _log.d(handler)
            cmodal:bind(modifiers, keycode, description, handler)
        end
        if config['activate'] then
            local activate_modifiers = config['activate'][1] or ''
            local activate_hotkeys = config['activate'][2]
            spoon.ModalMgr.supervisor:bind(activate_modifiers, activate_hotkeys, "Enter "..mode.." Environment", function()
                spoon.ModalMgr:deactivateAll()
                spoon.ModalMgr:activate({mode}, config.trayColor)
            end)
        end
    end
end

function Flow:bindHotkeys(hotkeys)
    for action, hotkey in pairs(hotkeys) do
    end
end

function Flow:init()
end

function Flow:stop()
end

return Flow

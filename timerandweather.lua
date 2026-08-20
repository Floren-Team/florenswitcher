script_name("Local Time & Weather Fix")
script_author("Developer")
script_description("Forced local time and weather changer with Debugger")
script_version("3.8")

local vkeys = require 'vkeys'
local sampevents = require 'samp.events'

local locked_hour = nil
local locked_weather = nil
local debug_timer = 0

function main()
    if not isSampLoaded() then return end
    while not isSampAvailable() do
        wait(200)
    end
    wait(1000)

    sampAddChatMessage("{00FF00}[FlorenSwitcher]: {FFFFFF}Загружен! Нажмите {FFFF00}[Z]{FFFFFF} для меню.", 0xFFFFFF)
    sampAddChatMessage("{00FF00}[FlorenSwitcher]: {FFFFFF}GitHub: ", 0xFFFFFF)
    while true do
        wait(0)
        
        -- 1. Удержание времени
        if locked_hour ~= nil then
            setTimeOfDay(locked_hour, 0)
        end
        
        -- 2. Удержание погоды через нативный forceWeather и запись в память
        if locked_weather ~= nil then
            forceWeather(locked_weather)
            writeMemory(0xC81320, 4, locked_weather, false) -- текущая погода
            writeMemory(0xC81324, 4, locked_weather, false) -- целевая погода для переходов
        end

     

        -- Открытие главного меню по клавише Z
        if isKeyJustPressed(vkeys.VK_Z) and not sampIsChatInputActive() and not sampIsDialogActive() then
            showMenuDialog()
        end

        -- 3. Обработка главного меню (ID 10001)
        local result1, button1, listitem1, input1 = sampHasDialogRespond(10001)
        if result1 then
            if button1 == 1 then
                if listitem1 == 0 then
                    locked_weather = 0
                    sampAddChatMessage("{00FF00}[Скрипт]: {FFFFFF}Погода зафиксирована: Ясно (ID 0)", 0xFFFFFF)
                elseif listitem1 == 1 then
                    locked_weather = 1
                    sampAddChatMessage("{00FF00}[Скрипт]: {FFFFFF}Погода зафиксирована: Солнце (ID 1)", 0xFFFFFF)
                elseif listitem1 == 2 then
                    locked_weather = 9
                    sampAddChatMessage("{00FF00}[Скрипт]: {FFFFFF}Погода зафиксирована: Туман (ID 9)", 0xFFFFFF)
                elseif listitem1 == 3 then
                    locked_weather = 16
                    sampAddChatMessage("{00FF00}[Скрипт]: {FFFFFF}Погода зафиксирована: Дождь (ID 16)", 0xFFFFFF)
                elseif listitem1 == 4 then
                    locked_hour = 12
                    sampAddChatMessage("{00FF00}[Скрипт]: {FFFFFF}Время зафиксировано на 12:00", 0xFFFFFF)
                elseif listitem1 == 5 then
                    locked_hour = 0
                    sampAddChatMessage("{00FF00}[Скрипт]: {FFFFFF}Время зафиксировано на 00:00", 0xFFFFFF)
                elseif listitem1 == 6 then
                    showTimeInputDialog()
                elseif listitem1 == 7 then
                    showWeatherInputDialog()
                elseif listitem1 == 8 then
                    locked_hour = nil
                    locked_weather = nil
                    sampAddChatMessage("{00FF00}[Скрипт]: {FFFFFF}Фиксация снята, возвращены серверные значения", 0xFFFFFF)
                end
            end
        end

        -- 4. Обработка ввода времени (ID 10002)
        local result2, button2, listitem2, input2 = sampHasDialogRespond(10002)
        if result2 then
            if button2 == 1 then
                local hour = tonumber(input2)
                if hour and hour >= 0 and hour <= 23 then
                    locked_hour = hour
                    sampAddChatMessage(string.format("{00FF00}[Скрипт]: {FFFFFF}Время зафиксировано: %02d:00", hour), 0xFFFFFF)
                else
                    sampAddChatMessage("{FF0000}[Скрипт]: {FFFFFF}Ошибка! Введите число от 0 до 23.", 0xFFFFFF)
                end
            end
        end

        -- 5. Обработка ввода погоды (ID 10003)
        local result3, button3, listitem3, input3 = sampHasDialogRespond(10003)
        if result3 then
            if button3 == 1 then
                local w_id = tonumber(input3)
                if w_id then
                    locked_weather = w_id
                    sampAddChatMessage(string.format("{00FF00}[Скрипт]: {FFFFFF}Погода зафиксирована на ID: %d", w_id), 0xFFFFFF)
                else
                    sampAddChatMessage("{FF0000}[Скрипт]: {FFFFFF}Ошибка! Введите ID погоды.", 0xFFFFFF)
                end
            end
        end
    end
end

-- Хуки с логированием перехватов
function sampevents.onSetWeather(weatherId)
    if locked_weather ~= nil then
        sampAddChatMessage(string.format("{FF0000}[DEBUG HOOK]: {FFFFFF}Сервер попытался сменить погоду на ID %d. Заблокировано!", weatherId), 0xFFFFFF)
        return false
    end
end

function sampevents.onSetWorldTime(hour)
    if locked_hour ~= nil then
        sampAddChatMessage(string.format("{FF0000}[DEBUG HOOK]: {FFFFFF}Сервер попытался сменить время на %02d:00. Заблокировано!", hour), 0xFFFFFF)
        return false
    end
end

function showMenuDialog()
    local text = "1. Включить ясно (ID 0)\n" ..
                 "2. Включить солнце (ID 1)\n" ..
                 "3. Включить туман (ID 9)\n" ..
                 "4. Включить дождь (ID 16)\n" ..
                 "5. Установить день (12:00)\n" ..
                 "6. Установить ночь (00:00)\n" ..
                 "7. Ввести свое время...\n" ..
                 "8. Выбрать погоду сам (по ID)...\n" ..
                 "{FF0000}9. Вернуть серверные значения"

    sampShowDialog(10001, "Локальное управление погодой", text, "Выбрать", "Закрыть", 2)
end

function showTimeInputDialog()
    sampShowDialog(10002, "Ввод времени", "Введите час от 0 до 23:", "Принять", "Назад", 1)
end

function showWeatherInputDialog()
    sampShowDialog(10003, "Выбор погоды", "Введите ID погоды:", "Принять", "Назад", 1)
end
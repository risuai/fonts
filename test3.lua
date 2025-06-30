-- 변수 설정
local tgAgeUnixY
local tgUnix
local lastcharmsg
local lastusermsg

-- 토글 값 가져오기
-- 시작 나이 변수
local tgAge = getGlobalVar(triggerId, "toggle_mnp_age") or "24"
local tgBdY = getGlobalVar(triggerId, "toggle_mnp_bd_y")
local tgBdM = getGlobalVar(triggerId, "toggle_mnp_bd_m")
local tgBdD = getGlobalVar(triggerId, "toggle_mnp_bd_d")
-- 생리 변수(기간마다 작용됨)
local tgCycle = getGlobalVar(triggerId, "toggle_mnp_cycle")
local tgCycleT = getGlobalVar(triggerId, "toggle_mnp_cycle_t") or "28"
-- 임신 확률 변수(매번 적용됨)
local tgFert = getGlobalVar(triggerId, "toggle_mnp_fert")
-- 임신 변수(기간마다 적용됨)
local tgPregT = getGlobalVar(triggerId, "toggle_mnp_preg_t") or "37"
-- 상태창 인터페이스 변수
local tgInterface = getGlobalVar(triggerId, "toggle_mnp_interface")

-- 함수들
-- 랜덤
math.randomseed(os.time())

-- 랜덤실수
function randomReal(min, max)
    return min + math.random() * (max - min)
end

-- 랜덤정수
function randomInt(min, max)
    return math.floor(randomReal(min, max + 1))
end

local function nulltonil(value)
    return (value ~= "null") and value or nil
end

function unixMatch(y, m, d, hr, min, ampm)
    local dateStr = y .. "-" .. m .. "-" .. d .. " " .. hr .. ":" .. min .. " " .. ampm
    return dateStr
end

function unixRaw(datetime)
    local y, m, d, hr, min, ampm = datetime:match("(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d) ([AP]M)")

    if not y or not m or not d or not hr or not min or not ampm then
        alertError(triggerId, "오류! 개발자에게 연락하세요.")
    end
    
    if ampm == "PM" then
        if hr ~= 12 then hr = hr + 12 end
    elseif ampm == "AM" then
        if hr == 12 then hr = 0 end
    end
    
    local t = {
        year = tonumber(y),
        month = tonumber(m),
        day = tonumber(d),
        hour = tonumber(hr),
        min = tonumber(min),
        sec = 0,
        isdst = false
    }
    
    local unix = os.time(t)
    return unix
end

-- function unixDay(datetime)
--     local unix = unixRaw(datetime)
--     if unix then return unix / 86400
--     else return nil
--     end
-- end

-- function unixWeek(datetime)
--     local unix = unixRaw(datetime)
--     if unix then return unix / 604800
--     else return nil
--     end
-- end

function unixYear(datetime)
    local unix = unixRaw(datetime)
    if unix then return unix / 31556952
    else return nil
    end
end

if tgBdY then
    local tgBdDatetime = unixMatch(tgBdY, tgBdM, tgBdD, "12", "00", "PM")
    local tgBdUnixY = unixYear(tgBdDatetime)
    tgAgeUnixY = (tgUnixY - tgBdUnixY)
else
    tgAgeUnixY = tonumber(tgAge)
end

local dayMap = {
    [0] = "일",
    [1] = "월",
    [2] = "화",
    [3] = "수",
    [4] = "목",
    [5] = "금",
    [6] = "토",
    [7] = "일"
}
if tgWeek == "0" then
    tgWeek = os.date("%w", tgUnix)
end
tgWeek = dayMap[tonumber(tgWeek)]

local seasonMap = {
    [1] = "겨울",
    [2] = "겨울",
    [3] = "봄",
    [4] = "봄",
    [5] = "봄",
    [6] = "여름",
    [7] = "여름",
    [8] = "여름",
    [9] = "가을",
    [10] = "가을",
    [11] = "가을",
    [12] = "겨울"
}
tgSeason = seasonMap[tonumber(tgMonth)]

tgHour = tonumber(tgHour)
if tgAmpm == "PM" then
    if tgHour < 12 then
        tgHour = tgHour + 12
    end
elseif tgAmpm == "AM" then
    if tgHour == 12 then
        tgHour = 0
    end
end

function cycle(age, cycle, cyclet)
    if age < 12 then
        age = 12
    elseif age > 50 then
        age = 50
    end
    if cyclet < 4 then
        cyclet = 4
    end

    local basecycle
    if age >= 12 and age <= 42 then
        basecycle = cyclet + 0.00431 * (age - 42)^2 + 0.0000324 * (age - 42)^3
    elseif age > 42 and age <= 50 then
        basecycle = 0.0098 * (age - 42)^3 + 0.031 * (age - 42)^2 + cyclet
    end

    local cycle = tonumber(cycle)
    local range = {min = 0, max = 0}
    if cycle == 0 then
        range.min = 0
        range.max = 6
    elseif cycle == 1 then
        range.min = 0
        range.max = 0
    elseif cycle == 2 then
        range.min = 0
        range.max = 3
    elseif cycle == 3 then
        range.min = 3
        range.max = 10
    elseif cycle == 4 then
        range.min = 6
        range.max = 15
    else
        range.min = 0
        range.max = 6
    end 
    
    if range.min == 0 and range.max == 0 then
        return basecycle
    end
    local randomValue = randomReal(range.min, range.max)
    local operation = math.random(1, 2)
    if operation == 1 then
        return basecycle + randomValue
    else
        return math.max(4, basecycle - randomValue)
    end
end

function calculateCyclesPeriod(mensperiod, currunix, prevunix, age, tgcycle, cyclet, tgunix, cycle)
    local unixdiff = currunix - prevunix
    local cyclestartday = prevunix / 86400 - tgunix / 86400 - mensperiod + age * 365.2425
    local current_age_year = cyclestartday / 365.2425

    local fullcycleday = 0
    local iteration = 0
    local cycles = {}

    local currentcycle
    while unixdiff >= 0 do
        if iteration == 0 then
            currentcycle = cycle
        else
            currentcycle = cycle(age, tgcycle, cyclet)
        end

        table.insert(cycles, currentcycle)

        local remaincycleday = currentcycle - mensperiod

        if unixdiff < remaincycleday then
            mensperiod = (mensperiod + unixdiff) % currentcycle
            break
        else
            unixdiff = unixdiff - remaincycleday
            fullcycleday = fullcycleday + currentcycle

            cyclestartday = cyclestartday + fullcycleday
            mensperiod = 0
            iteration = iteration + 1
        end
    end
    return mensperiod, cycles
end

function pregChanceCc(cc, sex, cp)
    if sex == "0" then
        return 0
    elseif cc == "0" and cp == "1" then
        return 0.5
    elseif cc == "0" and cp == "0" then
        return 0.15
    elseif cc == "1" then
        return 0.01
    elseif cc == "2" and cp == "1" then
        return 0.01
    elseif cc == "2" and cp == "0" then
        return 0.005
    else
        return 0
    end
end

function pregChancePeriod(mensperiod, cycle)
    -- Updated data points for days 0-28 (index 1-29 in Lua's 1-based array)
    local points = {
        0.01, 0.01, 0.01, 0.01, 0.01,  -- Days 0-4
        0.02, 0.03, 0.06, 0.16, 0.26,  -- Days 5-9
        0.36, 0.47, 0.58, 0.68, 0.60,  -- Days 10-14
        0.26, 0.13, 0.06, 0.03, 0.02,  -- Days 15-19
        0.01, 0.01, 0.01, 0.01, 0.01,  -- Days 20-24
        0.01, 0.01, 0.01, 0.01         -- Days 25-28
    }
    
    local adjustedCycle = (mensperiod / cycle) * 28
    
    if adjustedCycle >= 13 and adjustedCycle <= 15 then
        if adjustedCycle <= 13.75 then
            return -0.21 * (adjustedCycle - 13) * (adjustedCycle - 13.75) * (adjustedCycle - 12.7) + 0.68
        elseif adjustedCycle <= 14 then
            -- Linear interpolation
            local t = (adjustedCycle - 13.75) / 0.25
            return 0.68 + (0.60 - 0.68) * t
        elseif adjustedCycle <= 14.5 then
            local t = (adjustedCycle - 14) / 0.5
            return 0.60 + (0.37 - 0.60) * t
        else
            local t = (adjustedCycle - 14.5) / 0.5
            return 0.37 + (0.26 - 0.37) * t
        end
    end
    
    -- Linear interpolation for other segments
    local lower = math.floor(adjustedCycle)
    local upper = math.ceil(adjustedCycle)
    
    if lower == upper then
        return points[lower + 1]  -- +1 for Lua's 1-based indexing
    end
    
    local fraction = adjustedCycle - lower
    return points[lower + 1] * (1 - fraction) + points[upper + 1] * fraction
end

function binary(prob)
    prob = math.max(0, math.min(1, prob))
    
    local r = math.random()
    
    if r <= prob then
        return 1
    else
        return 0
    end
end

listenEdit("editInput", function(triggerId, data)
    lastcharmsg = getChat(-1).data
    lastusermsg = data
    local prevdata = getGlobalVar(triggerId, "mnp_datatable")
    if not lastcharmsg and not prevdata then
        -- 토글값 가져오기
        -- 시작 시간 변수
        local tgYear = getGlobalVar(triggerId, "toggle_mnp_year") or "2024"
        local tgMonth = getGlobalVar(triggerId, "toggle_mnp_month") or "03"
        local tgDay = getGlobalVar(triggerId, "toggle_mnp_day") or "04"
        local tgHour = getGlobalVar(triggerId, "toggle_mnp_hour") or "08"
        local tgMinute = getGlobalVar(triggerId, "toggle_mnp_minute") or "00"
        local tgWeek = getGlobalVar(triggerId, "toggle_mnp_week")
        local tgAmpm = getGlobalVar(triggerId, "toggle_mnp_ampm")
        -- 시작 생리 변수
        local tgStart = getGlobalVar(triggerId, "toggle_mnp_start")
        local tgStartT = getGlobalVar(triggerId, "toggle_mnp_start_t")
        -- 시작 임신 변수
        local tgPreg = getGlobalVar(triggerId, "toggle_mnp_preg")
        local tgBaby = getGlobalVar(triggerId, "toggle_mnp_baby") or "20"
        -- 추후 LLM 판단 변수
        local tgCc = getGlobalVar(triggerId, "toggle_mnp_cc")
        local tgSex = getGlobalVar(triggerId, "toggle_mnp_sex")
        local tgCp = getGlobalVar(triggerId, "toggle_mnp_cp")
        local tgBirth = getGlobalVar(triggerId, "toggle_mnp_birth")

        -- 변수 확인
        if string.match(tgYear, "^%d+$") and
            string.match(tgMonth, "^%d+$") and
            string.match(tgDay, "^%d+$") and
            string.match(tgHour, "^%d+$") and
            string.match(tgMinute, "^%d+$") and
            string.match(tgAge, "^%d+$") and
            string.match(tgBaby, "^%d+$") and
            string.match(tgCycleT, "^%d+$") and
            string.match(tgPregT, "^%d+$") then
        else
            alertError(triggerId, "숫자만 입력하세요.")
            stopChat(triggerId)
        end

        if tgBdY then
            if tgBdM and tgBdD then
                if string.match(tgBdY, "^%d+$") and
                    string.match(tgBdM, "^%d+$") and
                    string.match(tgBdD, "^%d+$") then
                else
                    alertError(triggerId, "생일은 숫자만 입력하세요.")
                    stopChat(triggerId)
                end
            else
                tgBdM = randomInt(1, 12)
                tgBdD = randomInt(1, 28)
            end
        end

        if tgStartT then
            if not string.match(tgStartT, "^%d+$") then
                alertError(triggerId, "생리 시작일은 숫자만 입력하세요.")
                stopChat(triggerId)
            elseif tonumber(tgStartT) < 0 or tonumber(tgStartT) > 28 then
                alertError(triggerId, "생리 시작일은 0~28 사이의 숫자로 입력하세요.")
                stopChat(triggerId)
            end
        end

        if tonumber(tgCycleT) < 4 then
            alertError(triggerId, "생리 주기가 4일 이하인 경우, 자동으로 4일로 설정됩니다.")
        end

        -- 퍼메 상태창 생성
        if tgAmpm == "0" then
            tgAmpm = "AM"
        else
            tgAmpm = "PM"
        end

        local tgDate = tgYear .. "-" .. tgMonth .. "-" .. tgDay
        local tgTime = tgHour .. ":" .. tgMinute .. " " .. tgAmpm

        local tgDatetime = unixMatch(tgYear, tgMonth, tgDay, tgHour, tgMinute, tgAmpm)
        tgUnix = unixRaw(tgDatetime)
        local tgUnixY = unixYear(tgDatetime)

        local firstinterface, firstinterface1, firstinterface2, firstinterface3, unixMatch
        if tgInterface == "0" then
            firstinterface1 = string.format("{date: %s, time: %s, location: , characters: }",
                tgDate, tgTime)
            firstinterface2 = string.format("{contraception: %s, sex: %s, ejac: %s, birth: %s}",
                tgCc, tgSex, tgCp, tgBirth)
            firstinterface3 = "{others: }"
            firstinterface = firstinterface1 .. "\n" ..
                firstinterface2 .. "\n" ..
                firstinterface3
            unixMatch = "{date:%s*(%d%d%d%d)-(%d%d)-(%d%d),%s*time:%s*(%d%d):(%d%d)%s*([AP]M)"
        elseif tgInterface == "1" then
            firstinterface1 = string.format("[Date: %s | Season: %s | Time: %s | Location: | Characters: | Others: ]",
                tgDate, tgSeason, tgTime)
            firstinterface2 = string.format("{contraception: %s, sex: %s, ejac: %s, birth: %s}",
                tgCc, tgSex, tgCp, tgBirth)
            firstinterface = firstinterface1 .. "\n" ..
                firstinterface2
            unixMatch = "%[Date:%s*(%d%d%d%d)-(%d%d)-(%d%d),%s*Time:%s*(%d%d):(%d%d)%s*([AP]M)"
        elseif tgInterface == "2" then
            alertError(triggerId, "커스텀 상태창 호환은 아직 개발 중입니다.")
            stopChat(triggerId)
        end

        lastcharmsg = firstinterface .. "\n" ..
            lastcharmsg
        setCharacterFirstMessage(triggerId, lastcharmsg)

        function mensStart(start, start_t, cycle)
            if start_t then
                return start_t / 28 * cycle
            end
        
            if cycle >= 21 then
                if start == "0" then
                    return randomReal(0, cycle)
                elseif start == "1" then
                    return 0
                elseif start == "2" then
                    return 5.25
                elseif start == "3" then
                    return cycle - 15.88
                elseif start == "4" then
                    return cycle - 14.88
                else
                    return randomReal(0, cycle)
                end
            elseif cycle >= 14 and cycle < 21 then
                if start == "0" then
                    return randomReal(0, cycle)
                elseif start == "1" then
                    return 0
                elseif start == "2" then
                    return 3.5
                elseif start == "3" then
                    return cycle - 8.88
                elseif start == "4" then
                    return cycle - 7.88
                else
                    return randomReal(0, cycle)
                end
            elseif cycle >= 7 and cycle < 14 then
                if start == "0" then
                    return randomReal(0, cycle)
                elseif start == "1" then
                    return 0
                elseif start == "2" then
                    return 2
                elseif start == "3" then
                    return cycle - 4
                elseif start == "4" then
                    return cycle - 3
                else
                    return randomReal(0, cycle)
                end
            else
                if start == "0" then
                    return randomReal(0, cycle)
                elseif start == "1" then
                    return 0
                elseif start == "2" then
                    return 1
                elseif start == "3" then
                    return cycle - 2
                elseif start == "4" then
                    return cycle - 1
                else
                    return randomReal(0, cycle)
                end
            end
        end

        local Cycle = cycle(tgAgeUnixY, tgCycle, tgCycleT)
        setChatVar(triggerId, "mnp_cycle", Cycle)

        local Mensperiod = mensStart(tgStart, tgStartT, Cycle)
        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)

        setChatVar(triggerId, "mnp_preg", tgPreg)
    else
        lastcharmsg = getCharacterLastMessage(triggerId)
    end

    if tgInterface == "0" then
        if getChat(-2).role == "char" then
            local secondlastchat = getChat(-2).data
            secondlastchat = string.gsub(secondlastchat, "{others:[^}]+}%s*\n{contraception:[^}]+}%s*\n", "", 1)
        else
            local secondlastchat = getChat(-3).data
            secondlastchat = string.gsub(secondlastchat, "{others:[^}]+}%s*\n{contraception:[^}]+}%s*\n", "", 1)
        end
    elseif tgInterface == "1" then
        if getChat(-2).role == "char" then
            local secondlastchat = getChat(-2).data
            secondlastchat = string.gsub(secondlastchat, "{contraception:[^}]+}%s*\n", "", 1)
        else
            local secondlastchat = getChat(-3).data
            secondlastchat = string.gsub(secondlastchat, "{contraception:[^}]+}%s*\n", "", 1)
        end
    end
end)

onOutput = async(function(triggerId)
    local output = getCharacterLastMessage(triggerId)
    local input, prompt, response
    if tgInterface == "0" then
        output = string.gsub(output, "{date:[^}]+}%s*\n{contraception:[^}]+}%s*\n", "", 1)
        input = "#Input" .. lastcharmsg .. "\n" .. lastusermsg .. "\n" .. "#Output:" .. output
        prompt = {
            {
                role = "user",
                content = input
            },
            {
                role = "user",
                content = "Create two character status interfaces for #Output. #Output is the scene following #Input. The interfaces must be in the following format:" .. "\n" ..
                "{date: (YYYY-MM-DD), time: (HH:MM TT), location: (location of the scene), characters: (characters in the scene, their actions, and their outfits)}" .. "\n" ..
                "{contraception: (contraceptive methods currently used in the scene), sex: (if the character is having sex with vaginal penetration), ejac: (if the character is pregnant or not), birth: (if the character is giving birth or not)}"
            }
        }
        response = axLLM(triggerId, prompt)
    elseif tgInterface == "1" then
        output = string.gsub(output, "{contraception:[^}]+}%s*\n", "", 1)
        input = "#Input" .. lastcharmsg .. "\n" .. lastusermsg .. "\n" .. "#Output:" .. output
        prompt = {
            {
                role = "user",
                content = input
            },
            {
                role = "user",
                content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                "{contraception: (contraceptive methods currently used in the scene), sex: (if the character is having sex with vaginal penetration), ejac: (if the character is pregnant or not), birth: (if the character is giving birth or not)}"
            }
        }
        response = axLLM(triggerId, prompt)
    end
    
    if response.success then
    else
        alertError(triggerId, "보조모델 응답 오류")
    end

    local y, m, d, hr, min, ampm = string.match(response.data, unixMatch)
    local datetime = unixMatch(y, m, d, hr, min, ampm)
    local currunix = unixRaw(datetime)

    y, m, d, hr, min, ampm = string.match(lastcharmsg, unixMatch)
    datetime = unixMatch(y, m, d, hr, min, ampm)
    local prevunix = unixRaw(datetime)

    local Week = os.date("%w", currunix)
    Week = dayMap[Week]
    local Season = seasonMap[tonumber(m)]

    local unixdiff = currunix - prevunix

    local Cc, Sex, Cp, Birth = string.match(response.data, "{contraception:%s*([^,]+),%s*sex:%s*([^,]+),%s*ejac:%s*([^,]+),%s*birth:%s*([^}]+)}")
    local Preg = getChatVar(triggerId, "mnp_preg")
    if Preg == "1" and Birth == "0" then
        Baby = Baby + unixdiff/604800
    elseif Preg == "1" and Birth == "1" then
        Preg = "0"
        Baby = "-1"
    elseif Preg == "0" then
        local Mensperiod = getChatVar(triggerId, "mnp_mensperiod")
        local Cycle = getChatVar(triggerId, "mnp_cycle")
        Mensperiod, Cycle = calculateCyclesPeriod(Mensperiod, currunix, prevunix, tgAgeUnixY, tgCycle, tgCycleT, tgUnix, Cycle)

        local pregChance
        if tgFert == "0" then
            pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, Cycle)
        elseif tgFert == "1" then
            pregChance = 0
        elseif tgFert == "2" then
            pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, Cycle) * 1.5
        elseif tgFert == "3" then
            pregChance = 1
        end
        local Preg = binary(pregChance)

        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)
        setChatVar(triggerId, "mnp_cycle", Cycle)
        setChatVar(triggerId, "mnp_preg", Preg)
    end

    setChat(triggerId, -1, output)
end)
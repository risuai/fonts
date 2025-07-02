-- 변수 설정
local unixMatch

-- 토글 값 가져오기
local function nulltonil(value)
    return (value ~= "null") and value or nil
end
-- 시작 나이 변수
local tgAge = nulltonil(getGlobalVar(triggerId, "toggle_mnp_age")) or "24"
local tgBdY = nulltonil(getGlobalVar(triggerId, "toggle_mnp_bd_y"))
local tgBdM = nulltonil(getGlobalVar(triggerId, "toggle_mnp_bd_m"))
local tgBdD = nulltonil(getGlobalVar(triggerId, "toggle_mnp_bd_d"))
-- 생리 변수(기간마다 작용됨)
local tgCycle = nulltonil(getGlobalVar(triggerId, "toggle_mnp_cycle"))
local tgCycleT = nulltonil(getGlobalVar(triggerId, "toggle_mnp_cycle_t")) or "28"
-- 임신 확률 변수(매번 적용됨)
local tgFert = nulltonil(getGlobalVar(triggerId, "toggle_mnp_fert"))
-- 임신 변수(기간마다 적용됨)
local tgPregT = nulltonil(getGlobalVar(triggerId, "toggle_mnp_preg_t")) or "37"
-- 상태창 인터페이스 변수
local tgInterface = nulltonil(getGlobalVar(triggerId, "toggle_mnp_interface"))

if tgBdY and tgBdM and tgBdD then
    if not tonumber(tgBdY) or
    not tonumber(tgBdM) or
    not tonumber(tgBdD) then
        alertError(triggerId, "생일은 숫자만 입력하세요.")
        stopChat(triggerId)
        return
    end
elseif tgBdY then
    tgBdM = randomInt(1, 12)
    tgBdD = randomInt(1, 28)
end

if tonumber(tgCycleT) < 4 then
    alertError(triggerId, "생리 주기가 4일 이하인 경우, 자동으로 4일로 설정됩니다.")
end

-- 상태창 파싱
if tgInterface == "0" then
    unixMatch = "%[date:%s*(%d%d%d%d)-(%d%d)-(%d%d),%s*time:%s*(%d%d):(%d%d)%s*([AP]M)"
elseif tgInterface == "1" then
    unixMatch = "%[Date:%s*(%d%d%d%d)-(%d%d)-(%d%d),%s*Time:%s*(%d%d):(%d%d)%s*([AP]M)"
elseif tgInterface == "2" then
end

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

function FunixMatch(y, m, d, hr, min, ampm)
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

function Fcycle(age, cycle, cyclet)
    cyclet = tonumber(cyclet)
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

    cycle = tonumber(cycle)
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
    local unixdiff = (currunix - prevunix)/ 86400
    local cyclestartday = prevunix / 86400 - tgunix / 86400 - mensperiod + age * 365.2425
    local current_age_year = cyclestartday / 365.2425
    print("Current Age Year: " .. current_age_year .. " Unix Diff: " .. unixdiff)

    local fullcycleday = 0
    local iteration = 0
    local cycles = {}

    local currentcycle
    while unixdiff >= 0 do
        if iteration == 0 then
            currentcycle = cycle
        else
            currentcycle = Fcycle(age, tgcycle, cyclet)
        end
        print("Current Cycle: " .. currentcycle .. " Iteration: " .. iteration)

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

    if #cycles > 2 then
        cycles = { cycles[1], cycles[#cycles] }
    elseif #cycles == 1 then
        cycles = { cycles[1], cycles[1] }
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

onOutput = async(function(triggerId)
    print("============== onOutput ===============")

    local datatable = getState(triggerId, "mnp_datatable") or {}
    local before1msg = before1msg
    local before2msg = getChat(triggerId, -3)
    local nodata = next(datatable) == nil
    local newchat = false

    if not before2msg then
        if not before1msg then
            newchat = true
        elseif before1msg.role == "user" then
            newchat = true
        end
    end

    if nodata then
        -- 토글값 가져오기
        -- 시작 시간 변수
        local tgYear = nulltonil(getGlobalVar(triggerId, "toggle_mnp_year")) or "2024"
        local tgMonth = nulltonil(getGlobalVar(triggerId, "toggle_mnp_month")) or "03"
        local tgDay = nulltonil(getGlobalVar(triggerId, "toggle_mnp_day")) or "04"
        local tgHour = nulltonil(getGlobalVar(triggerId, "toggle_mnp_hour")) or "08"
        local tgMinute = nulltonil(getGlobalVar(triggerId, "toggle_mnp_minute")) or "00"
        local tgWeek = nulltonil(getGlobalVar(triggerId, "toggle_mnp_week"))
        local tgAmpm = nulltonil(getGlobalVar(triggerId, "toggle_mnp_ampm"))
        -- 시작 생리 변수
        local tgStart = nulltonil(getGlobalVar(triggerId, "toggle_mnp_start"))
        local tgStartT = nulltonil(getGlobalVar(triggerId, "toggle_mnp_start_t"))
        -- 시작 임신 변수
        local tgPreg = nulltonil(getGlobalVar(triggerId, "toggle_mnp_preg"))
        local tgBaby = nulltonil(getGlobalVar(triggerId, "toggle_mnp_baby")) or "20"
        -- 추후 LLM 판단 변수
        local tgCc = nulltonil(getGlobalVar(triggerId, "toggle_mnp_cc"))
        local tgSex = nulltonil(getGlobalVar(triggerId, "toggle_mnp_sex"))
        local tgCp = nulltonil(getGlobalVar(triggerId, "toggle_mnp_cp"))
        local tgBirth = nulltonil(getGlobalVar(triggerId, "toggle_mnp_birth"))

        -- 변수 확인
        if not tonumber(tgYear) or
        not tonumber(tgMonth) or
        not tonumber(tgDay) or
        not tonumber(tgHour) or
        not tonumber(tgMinute) or
        not tonumber(tgAge) or
        not tonumber(tgBaby) or
        not tonumber(tgCycleT) or
        not tonumber(tgPregT) then
            alertError(triggerId, "숫자만 입력하세요.")
            stopChat(triggerId)
        end

        if tgStartT ~= nil then
            local num = tonumber(tgStartT)
            if num == nil then
                alertError(triggerId, "생리 시작일은 숫자만 입력하세요.")
                stopChat(triggerId)
            elseif num < 0 or num > 28 then
                alertError(triggerId, "생리 시작일은 0~28 사이의 숫자로 입력하세요.")
                stopChat(triggerId)
            end
        end

        -- 퍼메 상태창 생성
        if tgAmpm == "0" then
            tgAmpm = "AM"
        else
            tgAmpm = "PM"
        end

        local tgDate = tgYear .. "-" .. tgMonth .. "-" .. tgDay
        local tgTime = tgHour .. ":" .. tgMinute .. " " .. tgAmpm

        local tgDatetime = FunixMatch(tgYear, tgMonth, tgDay, tgHour, tgMinute, tgAmpm)
        local tgUnix = unixRaw(tgDatetime)
        local tgUnixY = unixYear(tgDatetime)

        local tgAgeUnixY
        if tgBdY then
            local tgBdDatetime = FunixMatch(tgBdY, tgBdM, tgBdD, "12", "00", "PM")
            local tgBdUnixY = unixYear(tgBdDatetime)
            tgAgeUnixY = (tgUnixY - tgBdUnixY)
        else
            tgAgeUnixY = tonumber(tgAge)
        end

        if tgWeek == "0" then
            tgWeek = os.date("%w", tgUnix)
        end
        tgWeek = dayMap[tonumber(tgWeek)]
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

        local firstinterface, firstinterface1, firstinterface2, firstinterface3
        if tgInterface == "0" then
            firstinterface1 = string.format("[date: %s, time: %s, location: , characters: ]",
                tgDate, tgTime)
            firstinterface2 = string.format("[contraception: %s, sex: %s, ejac: %s, birth: %s]",
                tgCc, tgSex, tgCp, tgBirth)
            firstinterface3 = string.format("[week: %s, season: %s]",
                tgWeek, tgSeason)
            firstinterface4 = "[others: ]"
            firstinterface = firstinterface1 .. "\n" ..
                firstinterface2 .. "\n" ..
                firstinterface3 .. "\n" ..
                firstinterface4
        elseif tgInterface == "1" then
            firstinterface1 = string.format("[Date: %s | Season: %s | Time: %s | Location: | Characters: | Others: ]",
                tgDate, tgSeason, tgTime)
            firstinterface2 = string.format("[contraception: %s, sex: %s, ejac: %s, birth: %s]",
                tgCc, tgSex, tgCp, tgBirth)
            firstinterface = firstinterface2 .. "\n" ..
                firstinterface1
        elseif tgInterface == "2" then
            alertError(triggerId, "커스텀 상태창 호환은 아직 개발 중입니다.")
            stopChat(triggerId)
        end

        function mensStart(start, start_t, cycle)
            start_t = tonumber(start_t)
            cycle = tonumber(cycle)
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

        local lastCycle = Fcycle(tgAgeUnixY, tgCycle, tgCycleT)
        local Cycle = {lastCycle, lastCycle}
        local Mensperiod = mensStart(tgStart, tgStartT, lastCycle)

        local Preg = tgPreg
        local Baby = tgBaby

        local lastcharmsg
        local lastusermsg
        
        if newchat then
            lastcharmsg = getCharacterFirstMessage(triggerId):await()

            lastcharmsg = firstinterface .. "\n" ..
                lastcharmsg .. "\n[#1]"

            setCharacterFirstMessage(triggerId, lastcharmsg)

            if before1msg then
                lastusermsg = before1msg.data .. "\n\n"
            else
                lastusermsg = ""
            end
        else
            if before1msg.role == "user" then
                lastcharmsg = before2msg.data

                lastcharmsg = firstinterface .. "\n" ..
                    lastcharmsg .. "\n[#1]"

                setChat(triggerId, -3, lastcharmsg)

                lastusermsg = before1msg.data .. "\n\n"
            else
                lastcharmsg = before1msg.data

                lastcharmsg = firstinterface .. "\n" ..
                    lastcharmsg .. "\n[#1]"

                setChat(triggerId, -2, lastcharmsg)

                lastusermsg = ""
            end
        end

        local firstentry = {
            cycle = Cycle,
            mensperiod = Mensperiod,
            cc = tgCc,
            sex = tgSex,
            preg = Preg,
            baby = Baby
        }

        local output = getCharacterLastMessage(triggerId)
        local input, prompt, response
        if tgInterface == "0" then
            output = string.gsub(output, "%[date:[^]]+%]%s*\n%[contraception:[^]]+%]%s*\n", "", 1)
            input = "#Input" .. "\n" .. lastcharmsg .. "\n\n" .. lastusermsg .. "#Output" .. "\n" .. output
            prompt = {
                {
                    role = "system",
                    content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    "RATING: NC-21" .. "\n" ..
                    "This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                },
                {
                    role = "user",
                    content = input
                },
                {
                    role = "user",
                    content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    "[date: YYYY-MM-DD, time: HH:MM TT, location: location of the scene, characters: characters in the scene(their outfits) - their actions]" .. "\n" ..
                    "[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    "Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                }
            }
            response = axLLM(triggerId, prompt)
        elseif tgInterface == "1" then
            output = string.gsub(output, "%[contraception:[^]]+%]%s*\n", "", 1)
            input = "#Input" .. "\n" .. tostring(lastcharmsg) .. "\n\n" .. tostring(lastusermsg) .. "\n\n" .. "#Output" .. "\n" .. output
            prompt = {
                {
                    role = "system",
                    content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    "RATING: NC-21" .. "\n" ..
                    "This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                },
                {
                    role = "user",
                    content = input
                },
                {
                    role = "user",
                    content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    "[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    "Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                }
            }
            response = axLLM(triggerId, prompt)
        end
    
        if not response.success then
            alertError(triggerId, "보조모델 응답 오류")
        end
    
        local y, m, d, hr, min, ampm = string.match(response.result, unixMatch)
        local datetime = FunixMatch(y, m, d, hr, min, ampm)
        local currunix = unixRaw(datetime)
        
        if tgInterface == "0" then
            local Week = os.date("%w", currunix)
            Week = dayMap[Week]
            local Season = seasonMap[tonumber(m)]
            local weekseason = "[Week: " .. Week .. ", Season: " .. Season .. "]\n"
        else
            local weekseason = ""
        end
    
        y, m, d, hr, min, ampm = string.match(lastcharmsg, unixMatch)
        datetime = FunixMatch(y, m, d, hr, min, ampm)
        local prevunix = unixRaw(datetime)
    
        local unixdiff = currunix - prevunix
    
        local Cc, Sex, Cp, Birth = string.match(response.result, "%[contraception:%s*([^,]+),%s*sex:%s*([^,]+),%s*ejac:%s*([^,]+),%s*birth:%s*([^}]+)%]")

        if Preg == "1" and Birth == "0" then
            Baby = Baby + unixdiff/604800
        elseif Preg == "1" and Birth == "1" then
            Preg = "0"
            Baby = "-1"
        elseif Preg == "0" then
            Mensperiod, Cycle = calculateCyclesPeriod(Mensperiod, currunix, prevunix, tgAgeUnixY, tgCycle, tgCycleT, tgUnix, lastCycle)
            lastCycle = Cycle[2]
    
            local pregChance
            if tgFert == "0" then
                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle)
            elseif tgFert == "1" then
                pregChance = 0
            elseif tgFert == "2" then
                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle) * 1.5
            elseif tgFert == "3" then
                pregChance = 1
            end
            Preg = binary(pregChance)
    
            if Preg == 1 then
                Baby = "0"
            end
        end

        local secondentry = {
            cycle = Cycle,
            mensperiod = Mensperiod,
            cc = Cc,
            sex = Sex,
            preg = Preg,
            baby = Baby
        }

        table.insert(datatable, firstentry)
        table.insert(datatable, secondentry)

        output = response.result .. "\n" .. weekseason .. output .. "\n[#2]"

        setChat(triggerId, -1, output)
        setChatVar(triggerId, "mnp_cycle", lastCycle)
        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)
        setChatVar(triggerId, "mnp_preg", Preg)
        setChatVar(triggerId, "mnp_baby", Baby)
        setState(triggerId, "mnp_datatable", datatable)
    elseif not nodata and newchat then
        -- 토글값 가져오기
        -- 시작 시간 변수
        local tgYear = nulltonil(getGlobalVar(triggerId, "toggle_mnp_year")) or "2024"
        local tgMonth = nulltonil(getGlobalVar(triggerId, "toggle_mnp_month")) or "03"
        local tgDay = nulltonil(getGlobalVar(triggerId, "toggle_mnp_day")) or "04"
        local tgHour = nulltonil(getGlobalVar(triggerId, "toggle_mnp_hour")) or "08"
        local tgMinute = nulltonil(getGlobalVar(triggerId, "toggle_mnp_minute")) or "00"
        local tgWeek = nulltonil(getGlobalVar(triggerId, "toggle_mnp_week"))
        local tgAmpm = nulltonil(getGlobalVar(triggerId, "toggle_mnp_ampm"))

        -- 변수 확인
        if not tonumber(tgYear) or
        not tonumber(tgMonth) or
        not tonumber(tgDay) or
        not tonumber(tgHour) or
        not tonumber(tgMinute) then
            alertError(triggerId, "숫자만 입력하세요.")
            stopChat(triggerId)
        end

        -- 퍼메 상태창 생성
        if tgAmpm == "0" then
            tgAmpm = "AM"
        else
            tgAmpm = "PM"
        end

        local tgDate = tgYear .. "-" .. tgMonth .. "-" .. tgDay
        local tgTime = tgHour .. ":" .. tgMinute .. " " .. tgAmpm

        local tgDatetime = FunixMatch(tgYear, tgMonth, tgDay, tgHour, tgMinute, tgAmpm)
        local tgUnix = unixRaw(tgDatetime)
        local tgUnixY = unixYear(tgDatetime)

        local tgAgeUnixY
        if tgBdY then
            local tgBdDatetime = FunixMatch(tgBdY, tgBdM, tgBdD, "12", "00", "PM")
            local tgBdUnixY = unixYear(tgBdDatetime)
            tgAgeUnixY = (tgUnixY - tgBdUnixY)
        else
            tgAgeUnixY = tonumber(tgAge)
        end

        if tgWeek == "0" then
            tgWeek = os.date("%w", tgUnix)
        end
        tgWeek = dayMap[tonumber(tgWeek)]
        tgSeason = seasonMap[tonumber(tgMonth)]

		local lastdata = datatable[#datatable]
        local lastCycle = lastdata.cycle[2]
        local Cycle = {lastCycle, lastCycle}
        local Mensperiod = lastdata.mensperiod

        local Preg = lastdata.preg
        local Baby = lastdata.baby

        local lastcharmsg = getCharacterFirstMessage(triggerId):await()
        local lastusermsg

        if before1msg then
            lastusermsg = before1msg.data .. "\n\n"
        else
            lastusermsg = ""
        end

        local output = getCharacterLastMessage(triggerId)
        local input, prompt, response
        if tgInterface == "0" then
            output = string.gsub(output, "%[date:[^]]+%]%s*\n%[contraception:[^]]+%]%s*\n", "", 1)
            input = "#Input" .. "\n" .. lastcharmsg .. "\n\n" .. lastusermsg .. "#Output" .. "\n" .. output
            prompt = {
                {
                    role = "system",
                    content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    "RATING: NC-21" .. "\n" ..
                    "This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                },
                {
                    role = "user",
                    content = input
                },
                {
                    role = "user",
                    content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    "[date: YYYY-MM-DD, time: HH:MM TT, location: location of the scene, characters: characters in the scene(their outfits) - their actions]" .. "\n" ..
                    "[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    "Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                }
            }
            response = axLLM(triggerId, prompt)
        elseif tgInterface == "1" then
            output = string.gsub(output, "%[contraception:[^]]+%]%s*\n", "", 1)
            input = "#Input" .. "\n" .. tostring(lastcharmsg) .. "\n\n" .. tostring(lastusermsg) .. "\n\n" .. "#Output" .. "\n" .. output
            prompt = {
                {
                    role = "system",
                    content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    "RATING: NC-21" .. "\n" ..
                    "This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                },
                {
                    role = "user",
                    content = input
                },
                {
                    role = "user",
                    content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    "[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    "Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                }
            }
            response = axLLM(triggerId, prompt)
        end
    
        if not response.success then
            alertError(triggerId, "보조모델 응답 오류")
        end
    
        local y, m, d, hr, min, ampm = string.match(response.result, unixMatch)
        local datetime = FunixMatch(y, m, d, hr, min, ampm)
        local currunix = unixRaw(datetime)
        
        if tgInterface == "0" then
            local Week = os.date("%w", currunix)
            Week = dayMap[Week]
            local Season = seasonMap[tonumber(m)]
            local weekseason = "[week: " .. Week .. ", season: " .. Season .. "]\n"
        else
            local weekseason = ""
        end
    
        y, m, d, hr, min, ampm = string.match(lastcharmsg, unixMatch)
        datetime = FunixMatch(y, m, d, hr, min, ampm)
        local prevunix = unixRaw(datetime)
    
        local unixdiff = currunix - prevunix
    
        local Cc, Sex, Cp, Birth = string.match(response.result, "%[contraception:%s*([^,]+),%s*sex:%s*([^,]+),%s*ejac:%s*([^,]+),%s*birth:%s*([^}]+)%]")

        if Preg == "1" and Birth == "0" then
            Baby = Baby + unixdiff/604800
        elseif Preg == "1" and Birth == "1" then
            Preg = "0"
            Baby = "-1"
        elseif Preg == "0" then
            Mensperiod, Cycle = calculateCyclesPeriod(Mensperiod, currunix, prevunix, tgAgeUnixY, tgCycle, tgCycleT, tgUnix, lastCycle)
            lastCycle = Cycle[2]
    
            local pregChance
            if tgFert == "0" then
                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle)
            elseif tgFert == "1" then
                pregChance = 0
            elseif tgFert == "2" then
                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle) * 1.5
            elseif tgFert == "3" then
                pregChance = 1
            end
            Preg = binary(pregChance)
    
            if Preg == 1 then
                Baby = "0"
            end
        end

        local newentry = {
            cycle = Cycle,
            mensperiod = Mensperiod,
            cc = Cc,
            sex = Sex,
            preg = Preg,
            baby = Baby
        }

        table.insert(datatable, newentry)

        output = response.result .. "\n" .. weekseason .. output .. "\n[#" .. #datatable + 1 .. "]"
    
        setChat(triggerId, -1, output)
        setChatVar(triggerId, "mnp_cycle", lastCycle)
        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)
        setChatVar(triggerId, "mnp_preg", Preg)
        setChatVar(triggerId, "mnp_baby", Baby)
        setState(triggerId, "mnp_datatable", datatable)
    elseif not nodata and not newchat then
		local lastcharmsg
		local lastusermsg

		if before1msg.role == "user" then
			lastcharmsg = before2msg.data
			lastusermsg = before1msg.data .. "\n\n"
		else
			lastcharmsg = before1msg.data
			lastusermsg = ""
		end

		local lastmsgnumber = string.match(lastcharmsg, "%[#%d+%]")
        
        if lastmsgnumber == #datatable then
            -- 다음 채팅
        	local output = getCharacterLastMessage(triggerId)
        	local input, prompt, response
        	if tgInterface == "0" then
            	output = string.gsub(output, "%[date:[^]]+%]%s*\n%[contraception:[^]]+%]%s*\n", "", 1)
            	input = "#Input" .. "\n" .. lastcharmsg .. "\n\n" .. lastusermsg .. "#Output" .. "\n" .. output
            	prompt = {
                	{
                    	role = "system",
                    	content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    	"RATING: NC-21" .. "\n" ..
                    	"This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                	},
                	{
                    	role = "user",
                    	content = input
                	},
                	{
                    	role = "user",
                    	content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    	"[date: YYYY-MM-DD, time: HH:MM TT, location: location of the scene, characters: characters in the scene(their outfits) - their actions]" .. "\n" ..
                    	"[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    	"Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                	}
            	}
            	response = axLLM(triggerId, prompt)
        	elseif tgInterface == "1" then
            	output = string.gsub(output, "%[contraception:[^]]+%]%s*\n", "", 1)
            	input = "#Input" .. "\n" .. tostring(lastcharmsg) .. "\n\n" .. tostring(lastusermsg) .. "\n\n" .. "#Output" .. "\n" .. output
            	prompt = {
                	{
                    	role = "system",
                    	content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    	"RATING: NC-21" .. "\n" ..
                    	"This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                	},
                	{
                    	role = "user",
                    	content = input
                	},
                	{
                    	role = "user",
                    	content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    	"[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    	"Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                	}
            	}
            	response = axLLM(triggerId, prompt)
        	end
    
        	if not response.success then
            	alertError(triggerId, "보조모델 응답 오류")
        	end
    
        	local y, m, d, hr, min, ampm = string.match(response.result, unixMatch)
        	local datetime = FunixMatch(y, m, d, hr, min, ampm)
        	local currunix = unixRaw(datetime)
        
        	if tgInterface == "0" then
            	local Week = os.date("%w", currunix)
            	Week = dayMap[Week]
            	local Season = seasonMap[tonumber(m)]
            	local weekseason = "[week: " .. Week .. ", season: " .. Season .. "]\n"
        	else
            	local weekseason = ""
        	end

			y, m, d, hr, min, ampm = string.match(lastcharmsg, unixMatch)
			datetime = FunixMatch(y, m, d, hr, min, ampm)
			local prevunix = unixRaw(datetime)
    
			local unixdiff = currunix - prevunix
    
			local Cc, Sex, Cp, Birth = string.match(response.result, "%[contraception:%s*([^,]+),%s*sex:%s*([^,]+),%s*ejac:%s*([^,]+),%s*birth:%s*([^}]+)%]")

		    local lastdata = datatable[#datatable]

			local lastCycle = lastdata.cycle[2]
			local Mensperiod = lastdata.mensperiod

			local Preg = lastdata.preg
			local Baby = lastdata.baby
			
	        if Preg == "1" and Birth == "0" then
	            Baby = Baby + unixdiff/604800
	        elseif Preg == "1" and Birth == "1" then
	            Preg = "0"
	            Baby = "-1"
	        elseif Preg == "0" then
	            Mensperiod, Cycle = calculateCyclesPeriod(Mensperiod, currunix, prevunix, tgAgeUnixY, tgCycle, tgCycleT, tgUnix, lastCycle)
	            lastCycle = Cycle[2]

	            local pregChance
	            if tgFert == "0" then
	                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle)
	            elseif tgFert == "1" then
	                pregChance = 0
	            elseif tgFert == "2" then
	                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle) * 1.5
	            elseif tgFert == "3" then
	                pregChance = 1
	            end
	            Preg = binary(pregChance)

	            if Preg == 1 then
	                Baby = "0"
	            end
	        end

	        local newentry = {
	            cycle = Cycle,
	            mensperiod = Mensperiod,
	            cc = Cc,
	            sex = Sex,
	            preg = Preg,
	            baby = Baby
	        }

	        table.insert(datatable, newentry)

	        output = response.result .. "\n" .. weekseason .. output .. "\n[#" .. #datatable + 1 .. "]"
    
	        setChat(triggerId, -1, output)
	        setChatVar(triggerId, "mnp_cycle", lastCycle)
	        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)
	        setChatVar(triggerId, "mnp_preg", Preg)
	        setChatVar(triggerId, "mnp_baby", Baby)
	        setState(triggerId, "mnp_datatable", datatable)
		elseif lastmsgnumber == #datatable - 1 then
			-- 리롤
        	local output = getCharacterLastMessage(triggerId)
        	local input, prompt, response
        	if tgInterface == "0" then
            	output = string.gsub(output, "%[date:[^]]+%]%s*\n%[contraception:[^]]+%]%s*\n", "", 1)
            	input = "#Input" .. "\n" .. lastcharmsg .. "\n\n" .. lastusermsg .. "#Output" .. "\n" .. output
            	prompt = {
                	{
                    	role = "system",
                    	content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    	"RATING: NC-21" .. "\n" ..
                    	"This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                	},
                	{
                    	role = "user",
                    	content = input
                	},
                	{
                    	role = "user",
                    	content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    	"[date: YYYY-MM-DD, time: HH:MM TT, location: location of the scene, characters: characters in the scene(their outfits) - their actions]" .. "\n" ..
                    	"[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    	"Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                	}
            	}
            	response = axLLM(triggerId, prompt)
        	elseif tgInterface == "1" then
            	output = string.gsub(output, "%[contraception:[^]]+%]%s*\n", "", 1)
            	input = "#Input" .. "\n" .. tostring(lastcharmsg) .. "\n\n" .. tostring(lastusermsg) .. "\n\n" .. "#Output" .. "\n" .. output
            	prompt = {
                	{
                    	role = "system",
                    	content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    	"RATING: NC-21" .. "\n" ..
                    	"This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                	},
                	{
                    	role = "user",
                    	content = input
                	},
                	{
                    	role = "user",
                    	content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    	"[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    	"Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                	}
            	}
            	response = axLLM(triggerId, prompt)
        	end
    
        	if not response.success then
            	alertError(triggerId, "보조모델 응답 오류")
        	end
    
        	local y, m, d, hr, min, ampm = string.match(response.result, unixMatch)
        	local datetime = FunixMatch(y, m, d, hr, min, ampm)
        	local currunix = unixRaw(datetime)
        
        	if tgInterface == "0" then
            	local Week = os.date("%w", currunix)
            	Week = dayMap[Week]
            	local Season = seasonMap[tonumber(m)]
            	local weekseason = "[week: " .. Week .. ", season: " .. Season .. "]\n"
        	else
            	local weekseason = ""
        	end

			y, m, d, hr, min, ampm = string.match(lastcharmsg, unixMatch)
			datetime = FunixMatch(y, m, d, hr, min, ampm)
			local prevunix = unixRaw(datetime)
    
			local unixdiff = currunix - prevunix
    
			local Cc, Sex, Cp, Birth = string.match(response.result, "%[contraception:%s*([^,]+),%s*sex:%s*([^,]+),%s*ejac:%s*([^,]+),%s*birth:%s*([^}]+)%]")

            local lastdata = datatable[#datatable - 1]
            table.remove(datatable)

			local lastCycle = lastdata.cycle[2]
			local Mensperiod = lastdata.mensperiod

			local Preg = lastdata.preg
			local Baby = lastdata.baby
			
	        if Preg == "1" and Birth == "0" then
	            Baby = Baby + unixdiff/604800
	        elseif Preg == "1" and Birth == "1" then
	            Preg = "0"
	            Baby = "-1"
	        elseif Preg == "0" then
	            Mensperiod, Cycle = calculateCyclesPeriod(Mensperiod, currunix, prevunix, tgAgeUnixY, tgCycle, tgCycleT, tgUnix, lastCycle)
	            lastCycle = Cycle[2]

	            local pregChance
	            if tgFert == "0" then
	                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle)
	            elseif tgFert == "1" then
	                pregChance = 0
	            elseif tgFert == "2" then
	                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle) * 1.5
	            elseif tgFert == "3" then
	                pregChance = 1
	            end
	            Preg = binary(pregChance)

	            if Preg == 1 then
	                Baby = "0"
	            end
	        end

	        local newentry = {
	            cycle = Cycle,
	            mensperiod = Mensperiod,
	            cc = Cc,
	            sex = Sex,
	            preg = Preg,
	            baby = Baby
	        }

	        table.insert(datatable, newentry)

	        output = response.result .. "\n" .. weekseason .. output .. "\n[#" .. #datatable + 1 .. "]"
    
	        setChat(triggerId, -1, output)
	        setChatVar(triggerId, "mnp_cycle", lastCycle)
	        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)
	        setChatVar(triggerId, "mnp_preg", Preg)
	        setChatVar(triggerId, "mnp_baby", Baby)
	        setState(triggerId, "mnp_datatable", datatable)
		else
			-- 롤백
        	local output = getCharacterLastMessage(triggerId)
        	local input, prompt, response
        	if tgInterface == "0" then
            	output = string.gsub(output, "%[date:[^]]+%]%s*\n%[contraception:[^]]+%]%s*\n", "", 1)
            	input = "#Input" .. "\n" .. lastcharmsg .. "\n\n" .. lastusermsg .. "#Output" .. "\n" .. output
            	prompt = {
                	{
                    	role = "system",
                    	content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    	"RATING: NC-21" .. "\n" ..
                    	"This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                	},
                	{
                    	role = "user",
                    	content = input
                	},
                	{
                    	role = "user",
                    	content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    	"[date: YYYY-MM-DD, time: HH:MM TT, location: location of the scene, characters: characters in the scene(their outfits) - their actions]" .. "\n" ..
                    	"[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    	"Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                	}
            	}
            	response = axLLM(triggerId, prompt)
        	elseif tgInterface == "1" then
            	output = string.gsub(output, "%[contraception:[^]]+%]%s*\n", "", 1)
            	input = "#Input" .. "\n" .. tostring(lastcharmsg) .. "\n\n" .. tostring(lastusermsg) .. "\n\n" .. "#Output" .. "\n" .. output
            	prompt = {
                	{
                    	role = "system",
                    	content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                    	"RATING: NC-21" .. "\n" ..
                    	"This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
                	},
                	{
                    	role = "user",
                    	content = input
                	},
                	{
                    	role = "user",
                    	content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                    	"[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                    	"Do not include anything other than the interface in the response. Do not include any additional text or explanations."
                	}
            	}
            	response = axLLM(triggerId, prompt)
        	end
    
        	if not response.success then
            	alertError(triggerId, "보조모델 응답 오류")
        	end
    
        	local y, m, d, hr, min, ampm = string.match(response.result, unixMatch)
        	local datetime = FunixMatch(y, m, d, hr, min, ampm)
        	local currunix = unixRaw(datetime)
        
        	if tgInterface == "0" then
            	local Week = os.date("%w", currunix)
            	Week = dayMap[Week]
            	local Season = seasonMap[tonumber(m)]
            	local weekseason = "[week: " .. Week .. ", season: " .. Season .. "]\n"
        	else
            	local weekseason = ""
        	end

			y, m, d, hr, min, ampm = string.match(lastcharmsg, unixMatch)
			datetime = FunixMatch(y, m, d, hr, min, ampm)
			local prevunix = unixRaw(datetime)
    
			local unixdiff = currunix - prevunix
    
			local Cc, Sex, Cp, Birth = string.match(response.result, "%[contraception:%s*([^,]+),%s*sex:%s*([^,]+),%s*ejac:%s*([^,]+),%s*birth:%s*([^}]+)%]")

            local lastdata = datatable[lastmsgnumber]
            
            -- 롤백 이후 테이블 드랍
            for i = #datatable, lastmsgnumber + 1, -1 do
                datatable[i] = nil
            end

			local lastCycle = lastdata.cycle[2]
			local Mensperiod = lastdata.mensperiod

			local Preg = lastdata.preg
			local Baby = lastdata.baby
			
	        if Preg == "1" and Birth == "0" then
	            Baby = Baby + unixdiff/604800
	        elseif Preg == "1" and Birth == "1" then
	            Preg = "0"
	            Baby = "-1"
	        elseif Preg == "0" then
	            Mensperiod, Cycle = calculateCyclesPeriod(Mensperiod, currunix, prevunix, tgAgeUnixY, tgCycle, tgCycleT, tgUnix, lastCycle)
	            lastCycle = Cycle[2]

	            local pregChance
	            if tgFert == "0" then
	                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle)
	            elseif tgFert == "1" then
	                pregChance = 0
	            elseif tgFert == "2" then
	                pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle) * 1.5
	            elseif tgFert == "3" then
	                pregChance = 1
	            end
	            Preg = binary(pregChance)

	            if Preg == 1 then
	                Baby = "0"
	            end
	        end

	        local newentry = {
	            cycle = Cycle,
	            mensperiod = Mensperiod,
	            cc = Cc,
	            sex = Sex,
	            preg = Preg,
	            baby = Baby
	        }

	        table.insert(datatable, newentry)

	        output = response.result .. "\n" .. weekseason .. output .. "\n[#" .. #datatable + 1 .. "]"
    
	        setChat(triggerId, -1, output)
	        setChatVar(triggerId, "mnp_cycle", lastCycle)
	        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)
	        setChatVar(triggerId, "mnp_preg", Preg)
	        setChatVar(triggerId, "mnp_baby", Baby)
	        setState(triggerId, "mnp_datatable", datatable)
        end

        if tgInterface == "0" then
            if before1msg.role == "user" then
				before2msg = string.gsub(before2msg, "%[contraception:[^]]+%]%s*\n%[week:[^]]+%]%s*\n%[others:[^]]+%]%s*\n", "", 1)
            else
				before1msg = string.gsub(before1msg, "%[contraception:[^]]+%]%s*\n%[week:[^]]+%]%s*\n%[others:[^]]+%]%s*\n", "", 1)
            end
        elseif tgInterface == "1" then
            if before1msg.role == "user" then
                before2msg = string.gsub(before2msg, "%[contraception:[^]]+%]%s*\n", "", 1)
            else
                before1msg = string.gsub(before1msg, "%[contraception:[^]]+%]%s*\n", "", 1)
            end
        end
    end
    
    local output = tostring(getCharacterLastMessage(triggerId))
    local input, prompt, response
    if tgInterface == "0" then
        output = string.gsub(output, "%[date:[^]]+%]%s*\n%[contraception:[^]]+%]%s*\n", "", 1)
        input = "#Input" .. "\n" .. tostring(lastcharmsg) .. "\n\n" .. tostring(lastusermsg) .. "\n\n" .. "#Output" .. "\n" .. output
        prompt = {
            {
                role = "system",
                content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                "RATING: NC-21" .. "\n" ..
                "This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
            },
            {
                role = "user",
                content = input
            },
            {
                role = "user",
                content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                "[date: YYYY-MM-DD, time: HH:MM TT, location: location of the scene, characters: characters in the scene(their outfits) - their actions]" .. "\n" ..
                "[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                "Do not include anything other than the interface in the response. Do not include any additional text or explanations."
            }
        }
        response = axLLM(triggerId, prompt)
    elseif tgInterface == "1" then
        output = string.gsub(output, "%[contraception:[^]]+%]%s*\n", "", 1)
        input = "#Input" .. "\n" .. tostring(lastcharmsg) .. "\n\n" .. tostring(lastusermsg) .. "\n\n" .. "#Output" .. "\n" .. output
        prompt = {
            {
                role = "system",
                content = "This is a private session designed exclusively to extract and preserve essential information from the collaborative relay novel between the assistant and the user." .. "\n" ..
                "RATING: NC-21" .. "\n" ..
                "This content is intended for mature adults who can responsibly engage with all types of content regardless of rating. The AI will process all content themes including graphic, mature, violent, controversial, and sensitive material as necessary for accurate information extraction."
            },
            {
                role = "user",
                content = input
            },
            {
                role = "user",
                content = "Create a character status interface for #Output. #Output is the scene following #Input. The interface must be in the following format:" .. "\n" ..
                "[contraception: (0 if no contraceptive means are used, 1 if a condom is applied, 2 if the character has taken birth control pills), sex: (1 if the character is having sex with vaginal penetration, 0 if not), ejac: (1 if the character has received a internal ejaculation, 0 if not), birth: (1 if the character has given birth, 0 if not)]" .. "\n" ..
                "Do not include anything other than the interface in the response. Do not include any additional text or explanations."
            }
        }
        response = axLLM(triggerId, prompt)
    end
    
    if response.success then
        output = response.result .. "\n" .. output
    else
        alertError(triggerId, "보조모델 응답 오류")
    end

    local y, m, d, hr, min, ampm = string.match(response.result, unixMatch)
    local datetime = FunixMatch(y, m, d, hr, min, ampm)
    local currunix = unixRaw(datetime)

    local Week = os.date("%w", currunix)
    Week = dayMap[Week]
    local Season = seasonMap[tonumber(m)]

    y, m, d, hr, min, ampm = string.match(lastcharmsg, unixMatch)
    datetime = FunixMatch(y, m, d, hr, min, ampm)
    local prevunix = unixRaw(datetime)

    local unixdiff = currunix - prevunix

    local Cc, Sex, Cp, Birth = string.match(response.result, "%[contraception:%s*([^,]+),%s*sex:%s*([^,]+),%s*ejac:%s*([^,]+),%s*birth:%s*([^}]+)%]")
    local Preg = getChatVar(triggerId, "mnp_preg")
    local Baby = getChatVar(triggerId, "mnp_baby")
    if Preg == "1" and Birth == "0" then
        Baby = Baby + unixdiff/604800
        setChatVar(triggerId, "mnp_baby", Baby)
    elseif Preg == "1" and Birth == "1" then
        Preg = "0"
        Baby = "-1"
        setChatVar(triggerId, "mnp_preg", Preg)
        setChatVar(triggerId, "mnp_baby", Baby)
    elseif Preg == "0" then
        local Mensperiod = tonumber(getChatVar(triggerId, "mnp_mensperiod"))
        local Cycle = tonumber(getChatVar(triggerId, "mnp_cycle"))
        Mensperiod, Cycle = calculateCyclesPeriod(Mensperiod, currunix, prevunix, tgAgeUnixY, tgCycle, tgCycleT, tgUnix, Cycle)
        setChatVar(triggerId, "mnp_mensperiod", Mensperiod)
        setState(triggerId, "mnp_cycle", Cycle)
        local lastCycle = Cycle[#Cycle]
        setChatVar(triggerId, "mnp_cycle", lastCycle)

        local pregChance
        if tgFert == "0" then
            pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle)
        elseif tgFert == "1" then
            pregChance = 0
        elseif tgFert == "2" then
            pregChance = pregChanceCc(Cc, Sex, Cp) * pregChancePeriod(Mensperiod, lastCycle) * 1.5
        elseif tgFert == "3" then
            pregChance = 1
        end
        Preg = binary(pregChance)

        if Preg == 1 then
            Baby = "0"
            setChatVar(triggerId, "mnp_baby", Baby)
        end

        setChatVar(triggerId, "mnp_preg", Preg)
    end

    setChat(triggerId, -1, output)
end)
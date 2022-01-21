-- MIT https://github.com/kikito/ansicolors.lua/blob/master/ansicolors.lua
local a={reset=0,bright=1,dim=2,underline=4,blink=5,reverse=7,hidden=8,black=30,red=31,green=32,yellow=33,blue=34,magenta=35,cyan=36,white=37,blackbg=40,redbg=41,greenbg=42,yellowbg=43,bluebg=44,magentabg=45,cyanbg=46,whitebg=47}local b=string.char(27)..'[%dm'local function c(d)return b:format(d)end;local function e(f)local g={}local d;for h in f:gmatch("%w+")do d=a[h]assert(d,"Unknown key: "..h)table.insert(g,c(d))end;return table.concat(g)end;local function i(f)f=string.gsub(f,"(%%{(.-)})",function(j,f)return e(f)end)return f end;local function ansicolors(f)f=tostring(f or'')return i('%{reset}'..f..'%{reset}')end

local fs = require("fs")
local json = require("json")
local timer = require("timer")
local http = require("coro-http")

local log = ""

local function Log(str)
	print(ansicolors(str))
	log = log .. str:gsub("(%%{(.-)})", "") .."\n"
end

local function WriteLog()
	local data = log:sub(1, #log - 1) -- remove last \n
	fs.writeFileSync("console.log", data)
end

local function Round(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function FormatTime(seconds, format)
    if seconds == nil then return string.format(format or "%s:%s", "00", "00") end

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds / 60) % 60)
    seconds = Round(seconds % 60)

    if minutes < 10 then minutes = "0".. minutes end
    if seconds < 10 then seconds = "0".. seconds end

    if hours < 1 then
        return string.format(format or "%s:%s", minutes, seconds)
    end

    if hours < 10 then hours = "0".. hours end

    return string.format(format or "%s:%s:%s", hours, minutes, seconds)
end

fs.mkdirSync("addons")

local downloaded = 0
local function Download(addon, cback)
	Log(" - Downloading %{bright yellow}#".. addon.index .." %{reset yellow}".. addon.title .." %{bright}(".. addon.id ..")...")
	local download_start_time = os.time()

	local succ, res, response = pcall(http.request, "POST", "https://node05.steamworkshopdownloader.io/prod/api/download/request", {
		{"Content-Type", "application/json"}
	}, '{"publishedFileId":'.. addon.id ..', "collectionId":null, "hidden":false, "downloadFormat":"gmaextract", "autodownload":true}')

	if succ then
		if res.code == 200 then
			local uuid = (json.decode(response) or {}).uuid
			if uuid then
				local i, timer_id = 0

				timer_id = timer.setInterval(2000, function()
					coroutine.wrap(function()
						--i = i + 1

						local succ, res, response = pcall(http.request, "POST", "https://node05.steamworkshopdownloader.io/prod/api/download/status", {
							{"Content-Type", "application/json"}
						}, '{"uuids": ["'.. uuid ..'"]}')

						if succ == false then
							Log(" - %{red}Error!%{reset} It looks like the server has down.")
							timer.clearInterval(timer_id)
							return cback()
						end

						local data = (json.decode(response) or {})[uuid]
						if not data then
							Log(" - %{red}Error!%{reset} Got no data from the server! It looks like the server has down.\n".. response)
							timer.clearInterval(timer_id)
							return cback()
						end

						if data.status == "prepared" then
							Log(" - %{yellow}".. addon.title .." %{reset}is %{green}ready%{reset}! Downloading...")
							timer.clearInterval(timer_id)


							local succ, res, response = pcall(http.request, "GET", "https://".. data.storageNode .."/prod//storage/".. data.storagePath .."?uuid=".. uuid)

							if succ then
								if res.code == 200 then
									Log(" - Download %{green}finished %{reset}in %{bright yellow}".. FormatTime(os.time() - download_start_time) .." %{reset}second(s)!")
									fs.writeFileSync("addons/".. addon.id ..".zip", response)
									downloaded = downloaded + 1
								else
									Log("- %{red}Error!%{reset} Node: %{bright yellow}".. data.storageNode .." %{reset}is down!\nResponse: ".. response .."\nResponse-code: ".. res.code)
								end
							else
								Log("- %{red}Error!%{reset} Node: %{bright yellow}".. data.storageNode .." %{reset}is down!")
							end

							cback()
						elseif data.status == "error" then
							Log("- %{red}Error!%{reset} Status: ".. data.progressText)
							timer.clearInterval(timer_id)
							cback()
						--elseif i == 60 then
						--	Log(" - %{red}Error!%{reset} The file was prepared for more than a two minutes! It looks like the server has down.\n".. response)
						--	timer.clearInterval(timer_id)
						--	cback()
						else
							Log(" - w8 for the server job done...\nprogress: ".. data.progress .."% status: ".. data.status)
						end
					end)()
				end)
			else
				Log(" - %{red}Error!%{reset} Cant get uuid!\nResponse:".. response)
				cback()
			end
		else
			Log(" - %{red}Error!%{reset} Game is not available or server is down!\nResponse: ".. response .."\nResponse-code: ".. res.code)
			cback()
		end
	else
		Log(" - %{red}Error!%{reset} Cant connect to the server!")
		cback()
	end
end

if not fs.existsSync("addons.json") then return Log(" - %{red}Error!%{reset} addons.json not found! Use this scraper to get your addons list:\n%{blue}https://gist.github.com/BrynM/c1b49804e53d7c406143a9ae40ed65ad") end
local addons = json.decode(fs.readFileSync("addons.json"))

local len, i, start_time = #addons, 0, os.time()

local function Main()
	i = i + 1
	if i > len then
		Log(" - %{green}Done!%{reset} ".. downloaded .." of ".. len .." addons succfullied downloaded!")
		WriteLog()
		return
	end

	local addon = addons[i]
	addon.index = i
	addon.id = addon.link:match("[&?]id=([^&]*)")

	if fs.existsSync("addons/".. addon.id ..".zip") then
		downloaded = downloaded + 1
		Main()
	else
		Download(addon, function()
			Log(" - total elapsed time: ".. FormatTime(os.time() - start_time))
			Log(" - w8 for 5 seconds to not hit the rate limits")
			timer.setTimeout(5000, coroutine.wrap(Main))
		end)
	end
end

Log(" - Addons count %{bright yellow} ".. len)

coroutine.wrap(Main)()

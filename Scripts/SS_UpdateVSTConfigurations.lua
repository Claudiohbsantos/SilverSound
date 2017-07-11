-- -- REAPER.ini
-- def_fx_filt64=NOT ( obsolete )

-- -- reaper-vstrenames64.ini
-- WaveShell_VST_9.6_x64.dll<1431454541=RCompressor Mono (obsolete)(Waves)
-- WaveShell_VST_9.6_x64.dll<1431454547=RCompressor Stereo (obsolete)(Waves)

function msg(msg)
	reaper.ShowConsoleMsg(tostring(msg).."\n")
end

function modifyINIEntry(iniPath,keyValueArray)

	for line in io.lines(iniPath) do 
		local section = string.match(line,"^([.+)")
		if section then 
			currentSection = section
		else
			local lineIniKey = string.match(line,"^([^=]+)=")
			for iniKey in pairs(keyValueArray) do
				if iniKey.section == currentSection then
					if lineIniKey == iniKey then
						iniTable[n] = 
					end
				end
			end
		end

	end

end

-- function writeINIFileFromTable(iniTable,masterINISection)

-- 	local reaperINIpath = reaper.get_ini_file()

-- 	file = io.open(reaperINIpath,"w")

-- 	file:write(iniTable.head)
-- 	file:write(iniTable.hideVSTs.."\n")
-- 	file:write(iniTable.tail)

-- 	file:close()

-- end

function checkOS()
	os = reaper.GetOS()

	if os == "OSX32" or os == "OSX64" then
		pathDiv = "/"
	else --windows
		pathDiv = "\\"
	end
	
end

checkOS()

local warning = "This script will update the common VST settings for configurations used in the Studio Computers."

local userOption = reaper.ShowMessageBox(warning,"Silver Sound VST Configuration Updater",1)

if userOption == 1 then
	local reaperINIpath = reaper.get_ini_file()

	iniMods = {def_fx_filt64 = {newValue = "NOT ( obsolete )",section = "[reaper]"}}

	modifyINIEntry(reaperINIpath,iniMods) 

end
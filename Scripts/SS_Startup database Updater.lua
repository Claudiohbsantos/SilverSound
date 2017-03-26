
-----------
local masterDB = {}
local localDBInfo = {}
local pathDivider = "\\"

function msg(msg)
	reaper.ShowConsoleMsg(tostring(msg).."\n")
end

function msgBox(msg)
	reaper.ShowMessageBox(msg,"Title",0)
end


function storeINIFileInTable()

	local reaperINIpath = reaper.get_ini_file()
	local iniFileTable = {}

	local n = 0
	for line in io.lines(reaperINIpath) do 
		n = n+1

		for key,value in line:gmatch("([^=]+)=(.*)") do
			iniFileTable[key] = value
			iniFileTable[n] = key
		end

		if not iniFileTable[n] then
			iniFileTable[n] = line
		end

	end

	return iniFileTable
end

function writeINIFileFromTable(iniTable)

	local reaperINIpath = reaper.get_ini_file()

	file = io.open(reaperINIpath,"w")
	for i=1,#iniTable,1 do
		file:write(iniTable[i])
		if iniTable[iniTable[i]] then
			file:write("="..iniTable[iniTable[i]])
		end
		file:write("\n")
	end
	file:close()

end

function getlocalDBInfo(iniTable,localDBInfo) -- localDBInfo must have localDBInfo.name filled for search

	for k,v in pairs(iniTable) do
		if v == localDBInfo.name then
			localDBInfo.nameKey = k
			localDBInfo.filenameKey = "Shortcut"..k:match("(%d+)$")
			localDBInfo.filename = iniTable[localDBInfo.filenameKey]
			localDBInfo.path = reaper.GetResourcePath()..pathDivider.."MediaDB"..pathDivider..localDBInfo.filename			
			break
		end
	end

	return localDBInfo
end

function getlocalDBLastModifiedDate(localDBInfo)
	local cmd = [[cmd.exe /C "for %a in ("]]..localDBInfo.path..[[") do set FileDate=%~ta"]]
	local cmdReturn = reaper.ExecProcess(cmd,0)
	localDBInfo.modifiedDate = cmdReturn:match("set FileDate=(.+)")

	return localDBInfo
end

function getMasterDBinfo(masterPath)
	
	if reaper.file_exists(masterPath) then
		local cmd = [[cmd.exe /C "for %a in ("]]..masterDBInfo.path..[[") do set FileDate=%~ta"]]
		local cmdReturn = reaper.ExecProcess(cmd,0)
		masterDBInfo.modifiedDate = cmdReturn:match("set FileDate=(.+)")
	end

	return masterDBInfo
end

function isMasterDBNewerthanLocalDB(masterDBInfo,localDBInfo)


	local localModDate = {}

	for mon,day,year,hour,min,ampm in localDBInfo.modifiedDate:gmatch("(%d%d)/(%d%d)/(%d%d%d%d) (%d%d):(%d%d) (%a%a)") do
		localModDate.month = mon
		localModDate.day = day
		localModDate.year = year
		if ampm == "PM" then hour = hour + 12 end
		localModDate.hour = hour
		localModDate.min = min
		localModDate.ampm = ampm
	end

	local masterModDate = {}

	for mon,day,year,hour,min,ampm in masterDBInfo.modifiedDate:gmatch("(%d%d)/(%d%d)/(%d%d%d%d) (%d%d):(%d%d) (%a%a)") do
		masterModDate.month = mon
		masterModDate.day = day
		masterModDate.year = year
		if ampm == "PM" then hour = hour + 12 end
		masterModDate.hour = hour
		masterModDate.min = min
		masterModDate.ampm = ampm
	end

	local localOSTime = os.time(localModDate)
	local masterOSTime = os.time(masterModDate)

	local timeDifference = os.difftime(localOSTime,masterOSTime) -- positive result means local database is newer

	if timeDifference < 0 then 
		return true
	else
		return false
	end

end

function updateLocalDB(localDBInfo,masterDBInfo)

	local backupCmd = [[cmd.exe /C "copy /Y "]]..localDBInfo.path..[[" "]]..localDBInfo.name..[[BACKUP"]]
	reaper.ExecProcess(backupCmd,0)

	local updateCmd = [[cmd.exe /C "copy /Y "]]..masterDBInfo.path..[[" "]]..localDBInfo.path..[["]]
	reaper.ExecProcess(updateCmd,0)

	reaper.ShowMessageBox("The Local SilverSound Database was updated. The previous database was copied as a Backup.","Sound Library Updater",0)
end

function checkOS()
	local os = reaper.GetOS()

	if os == "OSX32" or gui_OS == "OSX64" then
		pathDiv = "/"
		masterDB.path = "/Volumes/Public/SFXLibrary/Reaper Media Explorer Databases"
	else --windows
		pathDiv = "\\"
		masterDB.path = "Y:\\SFXLibrary\\Reaper Media Explorer Databases"
	end

end

---------------------------------------------

checkOS()

local iniTable = storeINIFileInTable()
getlocalDBInfo(iniTable,localDBInfo)
getlocalDBLastModifiedDate(localDBInfo)
getMasterDBinfo(masterDBInfo.path)

if isMasterDBNewerthanLocalDB(masterDBInfo,localDBInfo) then
	updateLocalDB(localDBInfo,masterDBInfo)
	-- writeINIFileFromTable(tempTable)
end	


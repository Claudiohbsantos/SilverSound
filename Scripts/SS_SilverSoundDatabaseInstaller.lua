-- @description SS_SilverSoundDatabaseInstaller
-- @version 2.0
-- @author Claudiohbsantos
-- @link http://claudiohbsantos.com
-- @date 2017 03 26
-- @about
--   # SS_SilverSoundDatabaseInstaller
--   Installer for the sound effects databases located in the DroboFS. Make sure you are connected to the network before running the script
-- @changelog
--   - Fix after auto updater implementation
-----------
local masterDB = {}

function msg(msg)
	reaper.ShowConsoleMsg(tostring(msg).."\n")
end

function msgBox(msg)
	reaper.ShowMessageBox(msg,"Title",0)
end


function storeINIFileInTable()

	local reaperINIpath = reaper.get_ini_file()
	local iniFileTable = {}
	iniFileTable.head = ""
	iniFileTable.explorer = ""
	iniFileTable.tail = ""

	local n = 0
	local explorerAlreadyCopied
	local explorerSection
	for line in io.lines(reaperINIpath) do 
		n = n+1

		if line:match("^%[") then
			explorerSection = false
		end

		if line:match("%[reaper_explorer%]") or line:match("%[reaper_sexplorer%]") then
			explorerSection = true
		end

		if not explorerSection then
			iniFileTable.head = iniFileTable.head..line.."\n"
		end

		if explorerSection then
			iniFileTable.explorer = iniFileTable.explorer..line.."\n"
		end


	end

	return iniFileTable
end

function loadMasterDatabaseConfig(masterDB)

	local masterConfig
	if os == "OSX32" or os == "OSX64" then
		masterConfig = masterDB.path..pathDiv.."Mac_Media Explorer Config.txt"
	else
		masterConfig = masterDB.path..pathDiv.."Win_Media Explorer Config.txt"
	end

	local f = io.open(masterConfig, "r")
	local content = f:read("a")
	f:close()

	return content
end

function writeINIFileFromTable(iniTable,masterINISection)

	local reaperINIpath = reaper.get_ini_file()

	file = io.open(reaperINIpath,"w")

	file:write(iniTable.head)
	file:write(masterINISection.."\n")

	file:close()

end

function backupINIFile()

	local reaperINIpath = reaper.get_ini_file()

	local backupCmd
	if os == "OSX32" or os == "OSX64" then
		backupCmd = [[cp "]]..reaperINIpath..[[" "]]..reaperINIpath..[[BKP"]]
	else
		backupCmd = [[cmd.exe /C "copy /Y "]]..reaperINIpath..[[" "]]..reaperINIpath..[[BACKUP"]]
	end
	
	reaper.ExecProcess(backupCmd,0)

end

function copyDBFiles(masterDB)

	local localdbfiles = reaper.GetResourcePath()..pathDiv.."MediaDB"

	local updateCmd
	if os == "OSX32" or os == "OSX64" then
		updateCmd = [[rsync -r "]]..masterDB.dbfiles..[[" "]]..localdbfiles..[["]]
	else
		updateCmd = [[cmd.exe /C "robocopy "]]..masterDB.dbfiles..[[" "]]..localdbfiles..[["]]
	end
	reaper.ExecProcess(updateCmd,0)

    local copyLastMod
	if os == "OSX32" or os == "OSX64" then
		copyLastMod = [[rsync -r "]]..masterDB.path..pathDiv..[[lastMod.txt" "]]..localdbfiles..pathDiv..[[lastMod.txt"]]
	else
		copyLastMod = [[cmd.exe /C "robocopy "]]..masterDB.path..pathDiv..[[lastMod.txt" "]]..localdbfiles..pathDiv..[[lastMod.txt"]]
	end
	reaper.ExecProcess(copyLastMod,0)

	reaper.ShowMessageBox("The Local SilverSound Database was installed. If You're on Windows the previous .ini file was copied as a Backup.","Sound Library Installer",0)
end

function checkOS()
	os = reaper.GetOS()

	if os == "OSX32" or os == "OSX64" then
		pathDiv = "/"
		masterDB.path = "/Volumes/Public/SFXLibrary/Reaper Media Explorer Databases"
		masterDB.dbfiles = "/Volumes/Public/SFXLibrary/Reaper Media Explorer Databases/Mac MediaDB"
	else --windows
		pathDiv = "\\"
		masterDB.path = "Y:\\SFXLibrary\\Reaper Media Explorer Databases"
		masterDB.dbfiles = "Y:\\SFXLibrary\\Reaper Media Explorer Databases\\Windows MediaDB"
		-- masterDB.path = "D:\\Reaper Media Explorer Databases" --DEBUG Path
		-- masterDB.dbfiles = "D:\\Reaper Media Explorer Databases\\Windows MediaDB"
	end
	
end

---------------------------------------------

checkOS()

local warning = "This script will install the SilverSound Database and copy all necessary files to this computer. Make sure you are connected to the network before starting. Beware: this will overwrite any media explorer databases you already have set up."

local userOption = reaper.ShowMessageBox(warning,"Silver Sound Library Installer",1)

if userOption == 1 then
	local iniFile = storeINIFileInTable()
	local masterConfig = loadMasterDatabaseConfig(masterDB)
	backupINIFile()
	writeINIFileFromTable(iniFile,masterConfig)
	copyDBFiles(masterDB)
end

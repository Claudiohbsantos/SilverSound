-- @description SS_SilverSoundDatabaseInstaller
-- @version 4.8beta
-- @author Claudiohbsantos
-- @link http://claudiohbsantos.com
-- @date 2017 03 26
-- @about
--   # SS_SilverSoundDatabaseInstaller
--   Installer for the sound effects databases located in the DroboFS. Make sure you are connected to the network before running the script
-- @changelog
--   - Fixed typo on line 93
-----------
local masterDB = {}

local function loadCSLibrary()
	local function get_script_path()
		local info = debug.getinfo(1,'S');
		local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
		return script_path
	end 

	local scriptPath = get_script_path()
	package.path = package.path .. ";" .. scriptPath .. "?.lua"
	local library = "CS_Library"
	require(library)
end

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
	if opSys == "OSX32" or opSys == "OSX64" then
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
	if opSys == "OSX32" or opSys == "OSX64" then
		backupCmd = [[rsync "]]..reaperINIpath..[[" "]]..reaperINIpath..[[BKP"]]
        os.execute(backupCmd)
	else
		backupCmd = [[cmd.exe /C "copy /Y "]]..reaperINIpath..[[" "]]..reaperINIpath..[[BACKUP"]]
        reaper.ExecProcess(backupCmd,0)
	end

end

function copyDBFiles(masterDB)

	local localdbfiles = reaper.GetResourcePath()..pathDiv.."MediaDB"

	local updateCmd
	if opSys == "OSX32" or opSys== "OSX64" then
		updateCmd = [[rsync -av "]]..masterDB.dbfiles..[[/" "]]..localdbfiles..[["]]
        os.execute(updateCmd)
	else
		updateCmd = [[cmd.exe /C "robocopy "]]..masterDB.dbfiles..[[" "]]..localdbfiles..[["]]
        reaper.ExecProcess(updateCmd,0)
	end
	

    local copyLastMod
	if opSys == "OSX32" or opSys == "OSX64" then
		copyLastMod = [[rsync -r "]]..masterDB.path..pathDiv..[[lastMod.txt" "]]..localdbfiles..pathDiv..[[lastMod.txt"]]
        os.execute(copyLastMod)
	else
		copyLastMod = [[cmd.exe /C "robocopy "]]..masterDB.path..pathDiv..[[lastMod.txt" "]]..localdbfiles..pathDiv..[[lastMod.txt"]]
        reaper.ExecProcess(copyLastMod,0)
	end
	
	closeWarnUserWait()
	reaper.ShowMessageBox("The Local SilverSound Database was installed. If You're on Windows the previous .ini file was copied as a Backup.","Sound Library Installer",0)
end

function checkOS()
	opSys = reaper.GetOS()

	if opSys == "OSX32" or opSys == "OSX64" then
		pathDiv = "/"
		masterDB.path = "/Volumes/Public/SFXLibrary/ReaperMediaExplorerDatabases"
		masterDB.dbfiles = "/Volumes/Public/SFXLibrary/ReaperMediaExplorerDatabases/MacMediaDB"
	else --windows
		pathDiv = "\\"
		masterDB.path = "Y:\\SFXLibrary\\ReaperMediaExplorerDatabases"
-- masterDB.path = [[\\drobofs\Public\SFXLibrary\ReaperMediaExplorerDatabases]]
		masterDB.dbfiles = "Y:\\SFXLibrary\\ReaperMediaExplorerDatabases\\WindowsMediaDB"
-- masterDB.dbfiles = [[\\drobofs\Public\SFXLibrary\ReaperMediaExplorerDatabases\WindowsMediaDB]]
		-- masterDB.path = "D:\\Reaper Media Explorer Databases" --DEBUG Path
		-- masterDB.dbfiles = "D:\\Reaper Media Explorer Databases\\Windows MediaDB"
	end

end

function warnUserWait()
	obj_mainW = 800	
	obj_mainH = 200
	obj_offs = 10
	
	gui_aa = 1
	gui_fontname = 'Calibri'
	gui_fontsize = 40     
	local gui_OS = reaper.GetOS()
	if gui_OS == "OSX32" or gui_OS == "OSX64" then gui_fontsize = gui_fontsize - 7 end

	local l, t, r, b = 0, 0, obj_mainW,obj_mainH   
	local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
	local x, y = (screen_w - obj_mainW) / 2, (screen_h - obj_mainH) / 2    
	gfx.init("Please Wait", obj_mainW,obj_mainH, 0, x, y)  
	gfx.x = 50
	gfx.y = 100

	gfx.drawstr("Please Wait Until the process is finished. Do not close reaper.\n\nAnd trust me, even if windows is saying I'm not responding, I'm still here.")
	gfx.update()
end

function closeWarnUserWait()
	gfx.quit()
end

---------------------------------------------
loadCSLibrary()
checkOS()


local warning = "This script will install the SilverSound Database and copy all necessary files to this computer. Make sure you are connected to the network before starting. Beware: this will overwrite any media explorer databases you already have set up."

local userOption = reaper.ShowMessageBox(warning,"Silver Sound Library Installer",1)

if userOption == 1 then
	local iniFile = storeINIFileInTable()
	local masterConfig = loadMasterDatabaseConfig(masterDB)
	warnUserWait()
	backupINIFile()
	writeINIFileFromTable(iniFile,masterConfig)
	copyDBFiles(masterDB)
end

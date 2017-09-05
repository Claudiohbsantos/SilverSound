--[[
@description SS_Startup database Updater
@version 1.1
@author Claudiohbsantos
@link http://claudiohbsantos.com
@date 2017 07 11
@about
  # SS_Startup database Updater
  Set this script to check for updates on every startup so it automatically updates the media explorer. 
@changelog
  - Fixed error "SS_Startup database Updater.lua179:attempt to concatenate a nil value (local 'user')"
--]]

local masterDB = {}
local localDB = {}

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
		masterConfig = masterDB.dir..pathDiv.."Mac_Media Explorer Config.txt"
	else
		masterConfig = masterDB.dir..pathDiv.."Win_Media Explorer Config.txt"
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

function readLastModFile(lastModFile)
	if reaper.file_exists(lastModFile) then

		file = io.open(lastModFile,"r")
			local lastModTime = file:read()
			local lastModTimeHumandReadable = file:read()
			local userWhoModded = file:read()
		file:close()
		return lastModTime, lastModTimeHumandReadable, userWhoModded
	else
		return 0,"Never","No One"	
	end
end

function getMasterLastModifiedDate(masterDBpath)
	local lastModFile = masterDBpath..pathDiv.."lastMod.txt"
	local lastModTime, prettyLastModTime, userWhoModded = readLastModFile(lastModFile)

	return lastModTime, prettyLastModTime, userWhoModded
end

function getLocalLastModifiedDate()
	local lastModFile = localDB.path..pathDiv.."lastMod.txt"
	local lastModTime, userWhoModded = readLastModFile(lastModFile)

	return lastModTime, userWhoModded
end

function isMasterDBNewer(masterLastMod,localLastMod)
	local timeDifference = os.difftime(masterLastMod,localLastMod) -- positive result means master database is newer
	if timeDifference <= 0 then 
		return false
	else
		return true
	end
end

function copyFilesFromMaster()
	local os = getOS()

	local winCopyCmd = [[cmd.exe /C "robocopy "]]
	local macCopyCmd = [[rsync -r "]]

	local cmd = ""
	if os == "mac" then cmd = macCopyCmd else cmd = winCopyCmd end

	local updateCmd = cmd..masterDB.path..[[" "]]..localDB.path..[["]]
	reaper.ExecProcess(updateCmd,0)

	local updateLastMod = cmd..masterDB.dir..pathDiv..[[lastMod.txt" "]]..localDB.path..pathDiv..[[lastMod.txt"]]
	reaper.ExecProcess(updateLastMod,0)
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

function updateLocalDB()
	warnUserWait()
	copyFilesFromMaster()

	local iniFile = storeINIFileInTable()
	local masterConfig = loadMasterDatabaseConfig(masterDB)
	writeINIFileFromTable(iniFile,masterConfig)

	closeWarnUserWait()
	reaper.ShowMessageBox("The Local SilverSound Database was updated. Please close and reopen the media explorer","Sound Library Updater",0)
end

function askIfWantToUpdate(date,user)
	local userOpt = reaper.ShowMessageBox("There is an update for the Silver Sound Database in the drobo.\nThe latest version was updated on "..date.." by "..user.."\nWould you like to update now?","Sound Library Updater",4)
	return userOpt
end

function getLocalDBPath(pathDivisor)
	local iniPath = reaper.get_ini_file()
	local resourcesDir = string.match(iniPath,"(.+)"..pathDivisor.."REAPER.ini$")
	local localDBPath = resourcesDir..pathDivisor.."MediaDB"
	return localDBPath
end

function getOS()
	local opsys = reaper.GetOS()

	if opsys == "OSX32" or gui_OS == "OSX64" then
		local os = "mac"
	else --windows
		local os = "win"
	end
	return os
end

function getPathsAccordingToOS()
	local os = getOS()

	if os == "mac" then
		pathDiv = "/"
		masterDB.dir = "/Volumes/Public/SFXLibrary/Reaper Media Explorer Databases"
		masterDB.path = masterDB.dir..pathDiv.."Mac MediaDB"
	else --windows
		pathDiv = "\\"
		masterDB.dir = "Y:\\SFXLibrary\\Reaper Media Explorer Databases"
		masterDB.path = masterDB.dir..pathDiv.."Windows MediaDB"
	end

	localDB.path = getLocalDBPath(pathDiv)
end

---------------------------------------------

getPathsAccordingToOS()

masterDB.lastMod,masterDB.prettyLastMod, masterDB.lastModUser = getMasterLastModifiedDate(masterDB.path)
localDB.lastMod = getLocalLastModifiedDate()

if isMasterDBNewer(masterDB.lastMod,localDB.lastMod) then
	local update = askIfWantToUpdate(masterDB.prettyLastMod, masterDB.lastModUser) 
	if update == 6 then 
		updateLocalDB(masterDB.path,localDB.path)
	end	
end

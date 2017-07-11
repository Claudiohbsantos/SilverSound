--[[
@description SS_Update Master Database
@version 1.0
@author Claudiohbsantos
@link http://claudiohbsantos.com
@date 2017 07 11
@about
  # SS_Startup database Updater
  Use this script to push your current media database to the drobofs master database.
@changelog
  - Initial release
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

		if explorerSection and not (line:match("%[reaper_explorer%]") or line:match("%[reaper_sexplorer%]")) then
			iniFileTable.explorer = iniFileTable.explorer..line.."\n"
		end
	end

	return iniFileTable
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

function askIfWantToUpdate()
	local userOpt = reaper.ShowMessageBox("Would you like to update the master database now?\nThe database in the server will be overwritten with the current database in this computer.","Sound Library Updater",4)
	return userOpt
end

function writeConfigFile(path,head)
	file = io.open(path,"w")
		file:write(head.."\n")
		file:write(iniFileTable.explorer.."\n")
	file:close()
end

function updateConfigFiles()
	iniFileTable = storeINIFileInTable()


	writeConfigFile(masterDB.dir..[[/Mac_Media Explorer Config.txt]],"[reaper_sexplorer]")
	writeConfigFile(masterDB.dir..[[/Win_Media Explorer Config.txt]],"[reaper_explorer]")

end

function copyFilesToMaster()
	local os = getOS()

	local winCopyCmd = [[cmd.exe /C "robocopy "]]
	local macCopyCmd = [[rsync -r "]]

	local cmd = ""
	if os == "mac" then cmd = macCopyCmd else cmd = winCopyCmd end

	local updateCmd = cmd..localDB.path..[[" "]]..masterDB.path..[["]]
	reaper.ExecProcess(updateCmd,0)
end

function getLocalDBPath(pathDivisor)
	local iniPath = reaper.get_ini_file()
	local resourcesDir = string.match(iniPath,"(.+)"..pathDivisor.."REAPER.ini$")
	local localDBPath = resourcesDir..pathDivisor.."MediaDB"
	return localDBPath
end

function getCurrentReaperUser()
	local iniPath = reaper.get_ini_file()
	local currentUser = string.match(iniPath,pathDiv.."(%a+)"..pathDiv.."REAPER.ini$")
	return currentUser
end

function writeLastModFile()
	local lastMod = os.time()
	local prettyLastMod = os.date("%m-%d-%y -- %H:%M",lastMod)
	local user = getCurrentReaperUser()

	local lastModFile = localDB.path..pathDiv.."lastMod.txt"

	file = io.open(lastModFile,"w")
		file:write(lastMod.."\n")
		file:write(prettyLastMod.."\n")
		file:write(user.."\n")
	file:close()
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
if askIfWantToUpdate() == 6 then
	warnUserWait()
	getPathsAccordingToOS()
	writeLastModFile()
	copyFilesToMaster()
	updateConfigFiles()
	closeWarnUserWait()
end
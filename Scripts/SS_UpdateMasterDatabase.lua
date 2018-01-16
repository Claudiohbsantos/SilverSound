--[[
@description SS_Update Master Database
@version 2.2
@author Claudiohbsantos
@link http://claudiohbsantos.com
@date 2017 07 11
@about
  # SS_Startup database Updater
  Use this script to push your current media database to the drobofs master database.
@changelog
  - Initial release
@provides
  ./fart.exe > ./fart.exe    
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

function wrongOSError()
	reaper.ShowMessageBox("This Script can currently only be run on Windows. Please use one of the Windows Machines to make the update and this computer will automatically update it's databases.","Error",0)
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

function copyFilesToMaster(origin,destination)

	local os = reaper.GetOS()

	local winCopyCmd = [[cmd.exe /C "robocopy "]]
	local macCopyCmd = [[rsync -r "]]

	if os == "OSX32" or os == "OSX64" then cmd = macCopyCmd else cmd = winCopyCmd end

	local updateCmd = cmd..origin..[[" "]]..destination..[["]]
	reaper.ExecProcess(updateCmd,0)
end

local function get_script_path()
	local info = debug.getinfo(1,'S');
	local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
	return script_path
end 

function updateOtherOSVersions()

	if os == "OSX32" or os == "OSX64" then
		local cmd = [[cp "]]..localDB.path..pathDiv..[[*" "]]..localDB.conversion..[["]]
		reaper.ExecProcess(cmd,0)
		cmd = [[cd "]]..localDB.conversion..[[" ; sed -i 's/\/Volumes\/Public/Y:\\/g' *]]
		reaper.ExecProcess(cmd,0)
		updateOtherOSVersions(localDB.conversion,masterDB.win)
		CMD = [[rm -rf "]]..localDB.conversion..[[""]]
		reaper.ExecProcess(cmd,0)
	else
		local cmd = [[cmd.exe /C "cp "]]..localDB.path..pathDiv..[[*" "]]..localDB.conversion..[[""]]
		reaper.ExecProcess(cmd,0)
		cmd = [[cmd.exe /C "]]..get_script_path()..pathDiv..[[fart.exe -r -i -C "]]..localDB.conversion..[["\*" "y:\\" "\/Volumes\/Public""]]
		reaper.ExecProcess(cmd,0)
		updateOtherOSVersions(localDB.conversion,masterDB.mac)
		cmd = [[cmd.exe /C "rm -rf "]]..localDB.conversion..[[""]]
		reaper.ExecProcess(cmd,0)
	end

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

function getPathsAccordingToOS()
	local os = reaper.GetOS()

	
	if os == "OSX32" or os == "OSX64" then
		pathDiv = "/"
		masterDB.dir = "/Volumes/Public/SFXLibrary/ReaperMediaExplorerDatabases"
		masterDB.path = masterDB.dir..pathDiv.."MacMediaDB"
	else --windows
		pathDiv = "\\"
		masterDB.dir = "Y:\\SFXLibrary\\ReaperMediaExplorerDatabases"
		masterDB.path = masterDB.dir..pathDiv.."WindowsMediaDB"
	end
	masterDB.mac = masterDB.dir..pathDiv.."MacMediaDB"
	masterDB.win == masterDB.dir..pathDiv.."WindowsMediaDB"

	localDB.path = getLocalDBPath(pathDiv)
	localDB.conversion = localDB.path.."conversion"
end

---------------------------------------------
local os = reaper.GetOS()

-- if os == "OSX32" or os == "OSX64" then
	-- wrongOSError()	
-- else 
	if askIfWantToUpdate() == 6 then
		warnUserWait()
		getPathsAccordingToOS()
		writeLastModFile()
		copyFilesToMaster(localDB.path,masterDB.path)
		updateOtherOSVersions()
		updateConfigFiles()
		closeWarnUserWait()
	end
-- end
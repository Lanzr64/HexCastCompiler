remoteroot = "https://raw.githubusercontent.com/Lanzr64/HexCastCompiler/feature/cc-hex-plugin-compat/"
-- 整个项目的下载器
files = {
    "hexMap",
    "hex.lua",
    "hedit.lua",
    "iotaTools.lua",
    "iotaDecompiler.lua",
    "iotaBridge.lua",
    "hccConfig.lua",
    "startup.lua"}
function download(filename,url)
    local data = http.get(url)
    if not data then error("download failed: " .. url) end
    local file = fs.open(filename, "w")
    file.write(data.readAll())
    file.close()
    data.close()
end

function downloadFolder(url)
    local data = http.get(url)
    local file = fs.open(url, "w")
    file.write(data.readAll())
    file.close()
    data.close()
end
for _, file in pairs(files) do
    repeat
        if file == "hexMap" or file == "hccConfig.lua" then
            if fs.exists(file) then
                term.setTextColor(colors.red)
                print(file .. " already exists")
                term.setTextColor(colors.white)
                break
            end
        end
        download(file,remoteroot .. file)
        print("download "..file.." success")
    until true
end
term.setTextColor(colors.lime)
print("all file download success!, reboot in 2s")
sleep(2)
os.reboot()

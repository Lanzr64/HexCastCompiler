remoteroot = "https://raw.githubusercontent.com/Lanzr64/HexCastCompiler/main/"
-- 整个项目的下载器
files = {
    "hexMap",
    "hex.lua",
    "hedit.lua",
    "iotaTools.lua",
    "startup.lua"}
function download(filename,url)
    local data = http.get(url)
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
    download(file,remoteroot .. file)
    print("download "..file.." success")
end
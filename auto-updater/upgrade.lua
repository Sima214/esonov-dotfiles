#!/usr/bin/env lua

local lfs = require("lfs")
USERNAME = "sima"
local self_dir = lfs.currentdir()

-- Utilities
function os.userexec(cmd)
  return os.execute("sudo --user="..USERNAME.." "..cmd)
end

function io.upopen(c, o)
  return io.popen("sudo --user="..USERNAME.." "..c, o)
end

function table.contains(t, v)
  for tk, tv in pairs(t) do
    if tv == v then
      return true, tk
    end
  end
  return false
end

function version_cmp(pattern, a, b)
  _, _, a = a:find(pattern)
  _, _, b = b:find(pattern)
  local at = {}
  local bt = {}
  for sv in a:gmatch("%d+") do
    table.insert(at, tonumber(sv))
  end
  for sv in b:gmatch("%d+") do
    table.insert(bt, tonumber(sv))
  end
  for i=1, math.max(#at, #bt) do
    ac = at[i] or 0
    bc = bt[i] or 0
    if ac~=bc then
      return ac<bc
    end
  end
  return false
end

function configure(input, output, options)
  os.execute("pwd")
  local f = assert(io.open(input, "r"))
  local s = f:read("*all")
  f:close()
  s = s:gsub("%%(%w+)%%", options)
  local f = assert(io.open(output, "w"))
  f:write(s)
  f:close()
  assert(os.execute("chown "..USERNAME..":"..USERNAME.." "..output))
end

function getInstalledVersion(pacname)
  local f = assert(io.popen("pacman -Qi "..pacname.." 2>/dev/null | grep Version | cut -d: -f2", "r"))
  local s = f:read("*all")
  local _, _, v = s:find("^%s*([^%s%-]+)")
  f:close()
  if v then
    return v
  else
    return false, "Package "..pacname.." is not installed."
  end
end

function getLatestGitVersion(force, pattern, ...)
  assert(lfs.chdir("src"))
  assert(os.userexec("git fetch --recurse-submodules"))
  local versions = {}
  local exclude = table.pack(...)
  f = io.upopen("git tag", "r")
  for l in f:lines() do
    continue = false
    for _, exp in ipairs(exclude) do
      if l:match(exp) then
        continue = true
        break
      end
    end
    if not continue and l:match(pattern) then
      table.insert(versions, l)
    end
  end
  f:close()
  local function local_version_cmp(a, b)
    return version_cmp(pattern, a, b)
  end
  table.sort(versions, local_version_cmp)
  print("Parsed "..#versions.." releases.")
  -- Checkout new version if needed.
  local latest = versions[#versions]
  local f = io.upopen("git describe --tags")
  local c = f:read("*all"):sub(1, -2)
  f:close()
  if c~=latest then
    print("Checking out latest git release["..c.."->"..latest.."]...")
    assert(os.userexec("git reset --hard"))
    assert(os.userexec("git clean -xdf"))
    assert(os.userexec("git checkout -f "..latest))
    assert(os.userexec("git submodule update --init --recursive --quiet"))
    assert(os.userexec("git gc --auto"))
  elseif force then
    assert(os.userexec("git reset --hard"))
  end
  assert(lfs.chdir(".."))
  return select(-1, latest:find(pattern))
end

function save4laptop(path)
  assert(os.userexec("cp --reflink '"..path.."' '../laptop/'"))
end

function generic_upgrade(name, arch, version_pattern, ...)
  local installed = getInstalledVersion(name)
  local latest = getLatestGitVersion(false, version_pattern, ...)
  if latest ~= installed then
    local configuration = {VERSION=latest}
    local package_name = name.."-"..latest.."-1-"..arch..".pkg.tar.zst"
    configure("PKGBUILD.template", "PKGBUILD", configuration)
    print("Upgrading "..name.." to "..latest)
    assert(os.userexec("makepkg -f -s --skippgpcheck"))
    save4laptop(package_name)
    assert(os.execute("pacman -U "..package_name))
    assert(os.remove(package_name))
    assert(os.execute("rm -r pkg"))
  else
    print(name.." is already the latest version.")
  end
end

function aur_upgrade(name)
  assert(os.userexec("git pull"))
  local f = assert(io.upopen("makepkg --packagelist"))
  local outpath = f:read("*all"):sub(1, -2)
  f:close()
  if lfs.attributes(outpath, "mode")=="file" then
    print(name.." is already the latest version.")
  else
    assert(os.userexec("makepkg -s --skippgpcheck"))
    save4laptop(outpath)
    assert(os.execute("pacman -U "..outpath))
    assert(os.userexec("truncate -s 0 "..outpath))
    assert(os.execute("rm -r pkg"))
    assert(os.execute("rm -r src"))
  end
end

-- Generic system upgrade.
assert(os.execute("exit $EUID"), "Please run this script as root.")
-- print("Beginning full system upgrade!")
-- assert(os.execute("scripts/generic-upgrade.sh"))

-- Upgrade custom packages.
local subfolder_order = {
  "ffmpeg",
  -- "linux",
  "dxvk",
  "python-av",
  "python-pytorchaudio",
  -- "python-pytorchvision",
  "mingw-w64-binutils",
  "mingw-w64-winpthreads",
  "mingw-w64-crt",
  "mingw-w64-headers",
  "mingw-w64-gcc",
  "mingw-w64-environment",
  "mingw-w64-pkg-config",
  "mingw-w64-configure",
  "c++utilities",
  "reflective-rapidjson",
  "qtutilities-qt6",
  "tagparser",
  "tageditor-qt6"
}

-- Find packages.
for subfolder in lfs.dir(self_dir) do
  local script_file = subfolder.."/supgrade.lua"
  local name = subfolder:match("([^/]+)$")
  local in_order_table, index_order_table = table.contains(subfolder_order, subfolder)
  local got_script_file = lfs.attributes(script_file, "mode") == "file"
  if in_order_table and not got_script_file then
    print("Removed "..name)
    table.remove(subfolder_order, index_order_table)
  elseif not in_order_table and got_script_file then
    print("Added "..name)
    table.insert(subfolder_order, subfolder)
  end
end

-- Execute update scripts.
for _, subfolder in ipairs(subfolder_order) do
  local script_file = subfolder.."/supgrade.lua"
  local name = subfolder:match("([^/]+)$")
  -- Load sub script.
  local script_chunk = assert(loadfile(script_file))
  local script = script_chunk()
  assert(type(script) == "function", "Sub script "..name.." is not a function!")
  -- Execute sub script.
  print("Handling "..name.."...")
  assert(lfs.chdir(subfolder))
  script(name)
  assert(lfs.chdir(self_dir))
end

-- Finish up.
print("Cleaning up packager cache...")
assert(os.execute("scripts/cleanup.sh"))
print("All done!")

-- oclint
--[[print("Handling oclint...")
assert(lfs.chdir("oclint"))
local installed = getInstalledVersion("oclint")
local latest = "0.0.0"
-- Kind of hardcoded, but better than full manual.
local f = assert(io.upopen("git ls-remote --tags --refs https://github.com/oclint/oclint"))
for l in f:lines() do
  local v = select(-1, l:find("refs/tags/v([%d]+%.[%d]+%.?[%d]*)"))
  if version_cmp("([%d]+%.[%d]+%.?[%d]*)", latest, v) then
    latest = v
  end
end
if latest~=installed then
  local oclint = {VERSION=latest}
  configure("PKGBUILD.template", "PKGBUILD", oclint)
  print("Upgrading oclint to "..latest)
  assert(os.userexec("makepkg"))
  assert(os.execute("pacman -U oclint-"..latest.."-1-x86_64.pkg.tar"))
  assert(os.remove("oclint-"..latest.."-1-x86_64.pkg.tar"))
  assert(os.execute("rm -r pkg"))
else
  print("oclint is already the latest version.")
end
assert(lfs.chdir(".."))]]

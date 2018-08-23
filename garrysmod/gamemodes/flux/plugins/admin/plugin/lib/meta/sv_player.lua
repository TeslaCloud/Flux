local player_meta = FindMetaTable("Player")

function player_meta:SaveUsergroup()
  fl.db:easy_write("fl_players", {"steam_id", self:SteamID()}, {
    name = self:Name(),
    userGroup = self:GetUserGroup()
  })
end

function player_meta:SaveAllUsergroups()
  fl.db:easy_write("fl_players", {"steam_id", self:SteamID()}, {
    steam_id = self:SteamID(),
    name = self:Name(),
    userGroup = self:GetUserGroup(),
    secondaryGroups = fl.serialize(self:GetSecondaryGroups()),
    customPermissions = fl.serialize(self:GetCustomPermissions())
  })
end

function player_meta:SetPermissions(permTable)
  self:SetNetVar("flPermissions", permTable)
end

function player_meta:SetUserGroup(group)
  group = group or "user"

  local groupObj = fl.admin:FindGroup(group)
  local oldGroupObj = fl.admin:FindGroup(self:GetUserGroup())

  self:SetNetVar("flUserGroup", group)

  if (oldGroupObj and groupObj and oldGroupObj:OnGroupTake(self, groupObj) == nil) then
    if (groupObj:OnGroupSet(self, oldGroupObj) == nil) then
      self:SaveUsergroup()
    end
  end

  fl.admin:CompilePermissions(self)
end

function player_meta:SetSecondaryGroups(groups)
  self:SetNetVar("flSecondaryGroups", groups)

  fl.admin:CompilePermissions(self)
end

function player_meta:AddSecondaryGroup(group)
  if (group == "root" or group == "") then return end

  local groups = self:GetSecondaryGroups()

  table.insert(groups, group)

  self:SetNetVar("flSecondaryGroups", groups)

  fl.admin:CompilePermissions(self)
end

function player_meta:RemoveSecondaryGroup(group)
  local groups = self:GetSecondaryGroups()

  for k, v in ipairs(groups) do
    if (v == group) then
      table.remove(groups, k)

      break
    end
  end

  self:SetNetVar("flSecondaryGroups", groups)

  fl.admin:CompilePermissions(self)
end

function player_meta:SetCustomPermissions(data)
  self:SetNetVar("flCustomPermissions", data)

  fl.admin:CompilePermissions(self)
end

function player_meta:RunCommand(cmd)
  return fl.command:Interpret(self, cmd)
end

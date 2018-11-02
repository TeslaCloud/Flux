﻿local PANEL = {}
PANEL.chars = {}

function PANEL:Init()
  local scrw, scrh = ScrW(), ScrH()

  self:SetPos(0, 0)
  self:SetSize(scrw, scrh)

  self.button_close:safe_remove()

  self.list = vgui.Create('fl_horizontalbar', self)
  self.list:SetSize(scrw * 0.5, scrh * 0.5)
  self.list:SetPos(scrw * 0.5 - self.list:GetWide() * 0.5, scrh * 0.5 - self.list:GetTall() * 0.5)
  self.list:set_centered(true)

  self:rebuild()

  self.back = vgui.Create('fl_button', self)
  self.back:SetSize(self.list:GetWide() * 0.25, theme.get_option('menu_sidebar_button_height'))
  self.back:SetPos(scrw * 0.5 + self.list:GetWide() * 0.5 - self.back:GetWide(), scrh * 0.5 + self.list:GetTall() * 0.5 + self.back:GetTall())
  self.back:SetFont(theme.get_font('main_menu_normal'))
  self.back:SetTitle(t'char_create.main_menu')
  self.back:SetDrawBackground(false)
  self.back:set_icon('fa-chevron-right', true)
  self.back:set_icon_size(16)
  self.back:set_centered(true)

  self.back.DoClick = function(btn)
    surface.PlaySound(theme.get_sound('button_click_success_sound'))

    self:GetParent():to_main_menu(true)
  end
end

function PANEL:Paint(w, h)
  if self:IsVisible() then
    theme.hook('PaintCharCreationLoadPanel', self, w, h)
  end
end

function PANEL:rebuild()
  self.list:Clear()

  for k, v in ipairs(fl.client:get_all_characters()) do
    self.chars[k] = vgui.Create('fl_character_panel', self)
    self.chars[k]:SetSize(self.list:GetWide() * 0.25, self.list:GetTall())
    self.chars[k]:set_character(v)
    self.chars[k]:SetParent(self)

    self.list:AddPanel(self.chars[k])
  end
end

function PANEL:close(callback)
  self:SetVisible(false)
  self:Remove()

  if callback then
    callback()
  end
end

vgui.Register('fl_character_load', PANEL, 'fl_frame')

local PANEL = {}

function PANEL:Init()
  self:SetPaintBackground(false)

  self.model = vgui.Create('DModelPanel', self)
  self.model:SetFOV(50)
  self.model:SetCamPos(Vector(50, 0, 35))
  self.model:SetLookAt(Vector(0, 0, 35))
  self.model:SetAnimated(true)
  self.model.LayoutEntity = function(entity) end

  self.select = vgui.Create('fl_button', self)
  self.select:SetFont(theme.get_font('main_menu_normal'))
  self.select:SetTitle(t'char_create.select')
  self.select:SetDrawBackground(false)
  self.select:set_text_color(Color('lightgreen'))
  self.select:set_icon('fa-check')
  self.select:set_icon_size(16)
  self.select:set_centered(true)
  self.select.DoClick = function(btn)
    local cur_time = CurTime()

    if !self.next_click or self.next_click <= cur_time then
      cable.send('fl_player_select_character', self.char_data.character_id)

      self.next_click = cur_time + 1
    end
  end

  self.delete = vgui.Create('fl_button', self)
  self.delete:SetFont(theme.get_font('main_menu_normal'))
  self.delete:SetDrawBackground(false)
  self.delete:set_text_color(Color('red'))
  self.delete:set_icon('fa-trash')
  self.delete:set_icon_size(32)
  self.delete:set_centered(true)
  self.delete.DoClick = function(btn)
    surface.PlaySound('vo/npc/male01/answer37.wav')

    Derma_StringRequest(t'char_create.delete_confirm', t('char_create.delete_confirm_msg', { self.char_data.name }), '',
    function(text)
      if text == self.char_data.name then
        local char_id = self.char_data.character_id

        table.remove(fl.client.characters, char_id)
        cable.send('fl_player_delete_character', char_id)

        fl.intro_panel.menu:rebuild()
      end
    end,
    nil, t'char_create.delete')
  end
end

function PANEL:Paint(w, h)
  if self:IsVisible() then
    theme.hook('PaintCharPanel', self, w, h)
  end
end

function PANEL:PerformLayout(w, h)
  self.model:SetPos(4, 28)
  self.model:SetSize(w - 4, h * .80)

  self.select:SetPos(4, h - theme.get_option('menu_sidebar_button_height'))
  self.select:SetSize(w / 3 * 2 - 4, theme.get_option('menu_sidebar_button_height'))

  self.delete:SetPos(w / 3 * 2, h - theme.get_option('menu_sidebar_button_height'))
  self.delete:SetSize(w / 3 - 4, theme.get_option('menu_sidebar_button_height'))
end

function PANEL:set_character(char_data)
  self.char_data = char_data

  self.model:SetModel(char_data.model)
  self.model.Entity:SetSequence(ACT_IDLE)

  if fl.client:get_active_character_id() == char_data.character_id then
    self.select:SetVisible(false)
    self.delete:SetVisible(false)
  end

  hook.run('PanelCharacterSet', self, char_data)
end

vgui.Register('fl_character_panel', PANEL, 'DPanel')

local mod = get_mod("crosshair_hud")
local mod_utils = mod.utils
local _shadows_enabled = mod_utils.shadows_enabled

local UIWorkspaceSettings = mod:original_require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = mod:original_require("scripts/managers/ui/ui_widget")
local UIHudSettings = mod:original_require("scripts/settings/ui/ui_hud_settings")

local WeaponTemplate = mod:original_require("scripts/utilities/weapon/weapon_template")
local ReloadStates = mod:original_require("scripts/extension_systems/weapon/utilities/reload_states")

local global_scale = mod:get("global_scale")
local reload_scale = mod:get("reload_scale") * global_scale

local global_offset = {
  mod:get("global_x_offset"),
  mod:get("global_y_offset")
}
local reload_offset = {
  mod:get("reload_x_offset"),
  mod:get("reload_y_offset")
}

local template = {
  name = "reload_indicator"
}

template.scenegraph_definition = {
  screen = UIWorkspaceSettings.screen,
  [template.name] = {
    parent = "screen",
    vertical_alignment = "center",
    horizontal_alignment = "center",
    size = { 28 * reload_scale, 20 * reload_scale },
    position = {
      global_offset[1] + reload_offset[1],
      global_offset[2] + reload_offset[2],
      55
    }
  }
}

function template.create_widget_definitions()
  return {
    [template.name] = UIWidget.create_definition({
      {
        pass_type = "rect",
        style_id = "reload_bar",
        style = {
          size = { 28 * reload_scale, 4 * reload_scale },
          max_height = 28 * reload_scale,
          vertical_alignment = "bottom",
          horizontal_alignment = "center",
          color = UIHudSettings.color_tint_1,
          offset = { 0, 0, 2 }
        },
        visibility_function = function(content, style)
          local only_during_reload = mod:get("only_during_reload")
          local has_reload_time = mod.reload_time and mod.reload_time > 0

          return (only_during_reload and has_reload_time) or not only_during_reload
        end
      },
      {
        pass_type = "rect",
        style_id = "reload_bar_bg",
        style = {
          rect_style_id = "reload_bar",
          size = { 30 * reload_scale, 6 * reload_scale },
          vertical_alignment = "bottom",
          horizontal_alignment = "left",
          color = UIHudSettings.color_tint_0,
          offset = { -1 * reload_scale, 1 * reload_scale, 1 }
        },
        visibility_function = function(content, style)
          local only_during_reload = mod:get("only_during_reload")
          local has_reload_time = mod.reload_time and mod.reload_time > 0

          return (only_during_reload and has_reload_time) or not only_during_reload
        end
      },
      {
        pass_type = "text",
        value = "0.00",
        value_id = "reload_time",
        style_id = "reload_time",
        style = {
          font_size = 14 * reload_scale,
          font_type = "machine_medium",
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",
          text_color = UIHudSettings.color_tint_1,
          offset = { 0, 0, 2 }
        },
        visibility_function = function(content, style)
          local only_during_reload = mod:get("only_during_reload")
          local has_reload_time = mod.reload_time and mod.reload_time > 0

          return (only_during_reload and has_reload_time) or not only_during_reload
        end
      },
      {
        pass_type = "text",
        value = "0.00",
        value_id = "reload_time",
        style_id = "reload_time_shadow",
        style = {
          text_style_id = "reload_time",
          font_size = 14 * reload_scale,
          font_type = "machine_medium",
          text_vertical_alignment = "top",
          text_horizontal_alignment = "center",
          text_color = UIHudSettings.color_tint_0,
          offset = { 2 * reload_scale, 2 * reload_scale, 1 }
        },
        visibility_function = function(content, style)
          local enable_shadows = _shadows_enabled("reload")
          local only_during_reload = mod:get("only_during_reload")
          local has_reload_time = mod.reload_time and mod.reload_time > 0

          return enable_shadows and (only_during_reload and has_reload_time) or not only_during_reload
        end
      }
    }, template.name)
  }
end

local _reload_actions = {
  reload_state = true,
  reload_shotgun = true
}
function template.update(parent)
  local reload_widget = parent._widgets_by_name.reload_indicator
  if not reload_widget then
    return
  end

  local display_reload_indicator = mod:get("display_reload_indicator")
  reload_widget.content.visible = display_reload_indicator

  if not display_reload_indicator then
    return
  end

  local player_extensions = parent._parent:player_extensions()
  local unit_data_extension = player_extensions and player_extensions.unit_data
  local weapon_action_component = unit_data_extension and unit_data_extension:read_component("weapon_action")
  local weapon_template = weapon_action_component and WeaponTemplate.weapon_template(weapon_action_component.template_name)
  local reload_template = weapon_template and weapon_template.reload_template
  local current_action_name = weapon_action_component and weapon_action_component.current_action_name
  local current_action_settings = weapon_template and weapon_template.actions[current_action_name]
  local is_reload_action = current_action_settings and _reload_actions[current_action_settings.kind]

  if reload_template then
    local time_scale = weapon_action_component.time_scale
    local total_time = is_reload_action and current_action_settings.total_time or 0
    local scaled_time = total_time / time_scale
    local time_in_action = mod.time_in_action or scaled_time

    local inventory_component = unit_data_extension:read_component("slot_secondary")
    local started_reload = inventory_component and ReloadStates.started_reload(reload_template, inventory_component)
    if started_reload then
      local reload_state_time = ReloadStates.get_total_time(reload_template, inventory_component)
      scaled_time = (reload_state_time and reload_state_time / time_scale) or scaled_time
    end

    mod.reload_percent = math.min(1, time_in_action / scaled_time)
    mod.reload_time = math.max(0, scaled_time - time_in_action)

  elseif mod:get("only_during_reload") then
    reload_widget.content.visible = false
    return
  end

  local reload_style = reload_widget.style
  local reload_bar = reload_style.reload_bar
  reload_widget.content.reload_time = mod.reload_time and string.format("%.2f", mod.reload_time) or ""
  reload_bar.size[1] = reload_bar.max_height * (mod.reload_percent or 0)
end

return template

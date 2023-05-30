local mod = get_mod("crosshair_hud")
local mod_utils = mod.utils
local _shadows_enabled = mod_utils.shadows_enabled

local UIWidget = mod:original_require("scripts/managers/ui/ui_widget")
local UIHudSettings = mod:original_require("scripts/settings/ui/ui_hud_settings")

local global_scale = mod:get("global_scale")
local warp_charge_scale = mod:get("warp_charge_scale") * global_scale

local global_offset = {
  mod:get("global_x_offset"),
  mod:get("global_y_offset")
}
local warp_charge_offset = {
  mod:get("warp_charge_x_offset") + global_offset[1],
  mod:get("warp_charge_y_offset") + global_offset[2]
}

local feature_name = "warp_charge"
local feature = {
  name = feature_name
}

feature.scenegraph_definition = {
  [feature_name] = {
    parent = "screen",
    vertical_alignment = "center",
    horizontal_alignment = "center",
    size = {
      140 * warp_charge_scale,
      20 * warp_charge_scale
    },
    position = {
      warp_charge_offset[1],
      warp_charge_offset[2],
      55
    }
  }
}

function feature.create_widget_definitions(parent)
  local ui_hud = parent._parent
  local hud_player = ui_hud and ui_hud:player()
  local profile = hud_player and hud_player:profile()
  local archetype = profile and profile.archetype
  local archetype_name = archetype and archetype.name

  if not (archetype_name and archetype_name == "psyker") then
    return
  end

  local passes = {
    {
      pass_type = "text",
      value = "",
      value_id = "warp_charge_duration",
      style_id = "warp_charge_duration",
      style = {
        font_type = "machine_medium",
        font_size = 14 * warp_charge_scale,
        text_vertical_alignment = "center",
        text_horizontal_alignment = "left",
        text_color = UIHudSettings.color_tint_main_1,
        offset = { 0, 20 * warp_charge_scale, 3 }
      }
    }
  }

  for i = 1, 6 do
    local circle_style_id = string.format("circle_%s", i)
    local frame_style_id = string.format("frame_%s", i)

    table.insert(passes, {
      pass_type = "texture",
      value = "content/ui/materials/icons/talents/talent_icon_container",
      style_id = circle_style_id,
      style = {
        parent_style_id = frame_style_id,
        vertical_alignment = "center",
        horizontal_alignment = "left",
        size = { 28 * warp_charge_scale, 28 * warp_charge_scale },
        color = Color.white(255, true),
        material_values = {
          icon_texture = "content/ui/textures/icons/talents/psyker_2/psyker_2_tactical"
          --icon_texture = "content/ui/textures/icons/talents/psyker_2/psyker_2_base_1"
        },
        offset = { 0, 0, 0 }
      },
      visibility_function = function(content, style)
        return style.parent[style.parent_style_id].visible
      end
    })

    table.insert(passes, {
      value = "content/ui/vector_textures/hud/circle_full",
      value_id = frame_style_id,
      pass_type = "slug_icon",
      style_id = frame_style_id,
      style = {
        vertical_alignment = "center",
        horizontal_alignment = "left",
        size = { 20 * warp_charge_scale, 20 * warp_charge_scale },
        color = Color.steel_blue(255, true),
        offset = { 0, 0, 1 },
      }
    })

  end

  return {
    [feature_name] = UIWidget.create_definition(passes, feature_name),
  }
end

function feature.update(parent, dt, t)
  local widget = parent._widgets_by_name[feature_name]
  local widget_content = widget.content
  local widget_style = widget.style

  local ui_hud = parent._parent
  local hud_player = ui_hud:player()
  local profile = hud_player and hud_player:profile()
  local talents = profile.talents
  local player_extensions = ui_hud:player_extensions()
  local buff_extension = player_extensions.buff
  local unit_data_extension = player_extensions.unit_data
  local specialization_resource_component = unit_data_extension:read_component("specialization_resource")

  if not specialization_resource_component then
    return
  end

  local buffs = buff_extension:buffs()
  local warp_charge_duration_progress = 0
  local warp_charge_duration = ""

  for i = 1, #buffs do
    local buff = buffs[i]
    local buff_name = buff:template_name()
    if buff_name == "psyker_biomancer_souls" or buff_name == "psyker_biomancer_souls_increased_max_stacks" then
      local duration = buff:duration()
      warp_charge_duration_progress = buff:duration_progress()
      warp_charge_duration = string.format(":%02d", duration * warp_charge_duration_progress)

      break
    end
  end

  --local max_resource = specialization_resource_component.max_resource   -- Always returns 6; use when fixed
  local max_resource = talents.psyker_2_tier_5_name_1 and 6 or 4
  local current_resource = specialization_resource_component.current_resource
  local offset_modifier = max_resource == 4 and (24 * warp_charge_scale) or 0
  local display_warp_charge_indicator = mod:get("display_warp_charge_indicator")

  for i = 1, max_resource do
    local is_visible = i <= current_resource
    local circle_id = string.format("circle_%s", i)
    local frame_id = string.format("frame_%s", i)
    local circle_style = widget_style[circle_id]
    local frame_style = widget_style[frame_id]
    local offset = warp_charge_offset[1] + ((i - 1) * 24) * warp_charge_scale + offset_modifier

    circle_style.offset[1] = offset - 4 * warp_charge_scale
    circle_style.visible = display_warp_charge_indicator and is_visible
    circle_style.material_values.saturation = i < current_resource and 1 or (i == current_resource and warp_charge_duration_progress) or 0
    circle_style.color[1] = 200 * (i < current_resource and 1 or (i == current_resource and warp_charge_duration_progress) or 0) + 55

    frame_style.offset[1] = offset
    frame_style.visible = display_warp_charge_indicator
  end

  for i = max_resource + 1, 6 do
    local style_id = string.format("frame_%s", i)
    widget_style[style_id].visible = false
  end

  widget_content.warp_charge_duration = warp_charge_duration
  widget_style.warp_charge_duration.offset[1] = (current_resource - 1) * 24 * warp_charge_scale + offset_modifier
  widget_style.warp_charge_duration.visible = display_warp_charge_indicator and current_resource > 0
end

return feature

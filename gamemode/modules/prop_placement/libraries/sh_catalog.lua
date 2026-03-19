local MODULE = MODULE

MODULE.catalog = MODULE.catalog or {}
local catalog = MODULE.catalog

local function prettyLabel(modelPath)
    local fileName = string.GetFileFromFilename(modelPath or "") or modelPath or ""
    fileName = string.StripExtension(fileName or "")
    fileName = fileName:gsub("[_%-]+", " ")
    fileName = fileName:gsub("%s+", " ")
    fileName = fileName:Trim()
    if (fileName == "") then return "Prop" end
    fileName = fileName:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest:lower()
    end)
    return fileName
end

local function buildCategory(id, name, priceBase, priceStep, modelList)
    local items = {}
    for index, model in ipairs(modelList) do
        local itemId = string.format("%s_%02d", id, index)
        local price = math.floor(priceBase + priceStep * (index - 1))
        table.insert(items, {
            id = itemId,
            category = id,
            name = prettyLabel(model),
            model = model,
            price = price
        })
    end
    return {
        id = id,
        name = name,
        items = items
    }
end

local categories = {
    buildCategory("technology", "Technology", 45000, 2500, {
        "models/props_lab/server_rack.mdl",
        "models/props_lab/terminal_left.mdl",
        "models/props_lab/terminal_middle.mdl",
        "models/props_lab/terminal_right.mdl",
        "models/props_lab/console01a.mdl",
        "models/props_lab/console01b.mdl",
        "models/props_lab/console01c.mdl",
        "models/props_lab/console02a.mdl",
        "models/props_lab/console02b.mdl",
        "models/props_lab/console02c.mdl",
        "models/props_am/ion_console.mdl",
        "models/props_lab/console03c.mdl",
        "models/props_lab/console03b.mdl",
        "models/props_lab/console03a.mdl",
        "models/props_blackmesa/console01.mdl",
        "models/props_industrial/desk_console1.mdl",
        "models/props_industrial/desk_console1a.mdl",
        "models/props_industrial/desk_console2.mdl",
        "models/props_industrial/desk_console2_wgh.mdl",
        "models/props_industrial/desk_console3.mdl",
        "models/props_questionableethics/qe_auxconsole.mdl",
        "models/props_powerup/pu_gargkill_console.mdl",
        "models/props_residue/c2a4a_console01.mdl",
        "models/props_questionableethics/snark_pen_console.mdl",
        "models/props_questionableethics/aquaticsconsole.mdl",
        "models/props_industrial/wall_console1.mdl",
        "models/props_industrial/wall_console2.mdl",
        "models/props_industrial/wall_console_sm.mdl",
        "models/props_lambda/c3a2e_containment_console.mdl",
        "models/props_powerup/lowerconsole01.mdl",
        "models/props_questionableethics/console_large_01.mdl",
        "models/props_questionableethics/console_wide.mdl",
        "models/props_questionableethics/qe_console_large.mdl",
        "models/props_questionableethics/qe_console_tall.mdl",
        "models/props_questionableethics/qe_console_wide.mdl",
        "models/props_questionableethics/qe_console_wide2.mdl",
        "models/props_questionableethics/qe_console_wide3.mdl",
        "models/props_st/st_drain_topconsole.mdl",
        "models/props_questionableethics/qe_eht_console.mdl",
        "models/props_powerup/controlconsole01.mdl",
        "models/props_questionableethics/qe_primeconsole.mdl",
        "models/props_lab/temmicroscope.mdl",
        "models/props_lab/sterilizer.mdl"
    }),

    buildCategory("containers", "Containers", 12000, 600, {
        "models/props_blackmesa/tarp_crate.mdl",
        "models/props_blackmesa/bms_pushable_crate.mdl",
        "models/props_blackmesa/bms_metalcrate_64x96.mdl",
        "models/props_blackmesa/bms_metalcrate_tarp.mdl",
        "models/props_blackmesa/bms_metalcrate_48x48.mdl",
        "models/props_blackmesa/c1a1c_crate.mdl",
        "models/props_blackmesa/metalcrate01.mdl",
        "models/props_stalkyard/sy_plankcrate.mdl",
        "models/props_stalkyard/sy_plankcrate_long.mdl",
        "models/props_stalkyard/sy_plankcrate_short.mdl",
        "models/props_stalkyard/sy_plankcrate_side.mdl",
        "models/props_stalkyard/sy_plankcrate_small_48.mdl",
        "models/props_stalkyard/sy_plankcrate_small_64.mdl",
        "models/props_stalkyard/sy_plankcrate_tall.mdl",
        "models/props_stalkyard/sy_plankcrate_tall_tarp.mdl",
        "models/props_stalkyard/sy_plankcrate_tarp.mdl",
        "models/props_stalkyard/sy_plywoodcrate.mdl",
        "models/props_stalkyard/sy_plywoodcrate_tall.mdl",
        "models/props_stalkyard/sy_plywoodcrate_tall_tarp.mdl",
        "models/props_stalkyard/sy_plywoodcrate_tarp.mdl",
        "models/props_blackmesa/barrel01.mdl"
    }),

    buildCategory("furniture", "Furniture", 18000, 800, {
        "models/props_blackmesa/stackingchair01.mdl",
        "models/props_office/office_chair.mdl",
        "models/props_lab/lab_stool.mdl",
        "models/props_office/chair_casual.mdl",
        "models/props_office/sofa_casual.mdl",
        "models/props_office/furniture_sofa01.mdl",
        "models/props_blackmesa/seating01.mdl",
        "models/props_canteen/canteentable01b.mdl",
        "models/props_canteen/canteentable01_seat.mdl",
        "models/props_canteen/canteentable01a.mdl",
        "models/props_office/desk01_static.mdl",
        "models/props_office/desk_cantilever01a.mdl",
        "models/props_office/desk_corner01.mdl",
        "models/props_office/table_l_static.mdl",
        "models/props_office/table_rounded_static.mdl",
        "models/props_office/table_square.mdl",
        "models/props_office/desk_corner01_cupboard.mdl",
        "models/props_am/am_front_desk.mdl",
        "models/props_am/tcguarddesk.mdl",
        "models/props_office/oc_shelf01.mdl",
        "models/props_office/oc_shelf_short.mdl",
        "models/props_office/oc_shelf03.mdl",
        "models/props_questionableethics/qe_kitchen_right.mdl",
        "models/props_questionableethics/qe_kitchen_bar.mdl",
        "models/props_canteen/canteensink.mdl",
        "models/props_questionableethics/qe_kitchen_left.mdl"
    }),

    buildCategory("electronics", "Electronics", 9500, 500, {
        "models/props_office/computer_monitor01.mdl",
        "models/props_office/computer_monitor03.mdl",
        "models/props_office/computer_monitor02.mdl",
        "models/props_office/computer_monitor04.mdl",
        "models/props_office/television_office.mdl",
        "models/props_office/tv_small.mdl",
        "models/props_office/open_laptop.mdl",
        "models/props_office/computer_desktop03.mdl",
        "models/props_office/computer_desktop02.mdl",
        "models/props_office/computer_desktop01.mdl",
        "models/props_blackmesa/wallcomputer.mdl",
        "models/props_office/computer_keyboard01.mdl",
        "models/props_office/computer_keyboard02.mdl",
        "models/props_office/computer_mouse01.mdl",
        "models/props_office/office_phone.mdl",
        "models/props_office/stereosystem.mdl",
        "models/props_office/copy_machine.mdl"
    }),

    buildCategory("accessories", "Accessories", 6000, 350, {
        "models/props_office/waterdispencer.mdl",
        "models/props_canteen/microwave01.mdl",
        "models/props_office/coffe_machine.mdl",
        "models/props_office/coffe_pot.mdl",
        "models/props_lab/beaker01a.mdl",
        "models/props_lab/beaker01b.mdl",
        "models/props_office/partition_48x48.mdl",
        "models/props_office/partition_36x48.mdl",
        "models/props_office/metalbin01.mdl",
        "models/props_office/paper_box.mdl",
        "models/props_office/holepunch.mdl",
        "models/props_canteen/canteenbin.mdl"
    })
}

catalog.categories = categories

function catalog:GetCategories()
    return self.categories or {}
end

function catalog:FindItem(itemId)
    if (not itemId) then return end
    for _, category in ipairs(self:GetCategories()) do
        for _, item in ipairs(category.items or {}) do
            if (item.id == itemId) then
                return item, category
            end
        end
    end
end

function catalog:GetCategory(id)
    for _, category in ipairs(self:GetCategories()) do
        if (category.id == id) then
            return category
        end
    end
end
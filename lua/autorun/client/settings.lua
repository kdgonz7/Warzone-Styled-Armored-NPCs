hook.Add( "AddToolMenuCategories", "CustomCategory", function()
	spawnmenu.AddToolCategory( "Utilities", "Armored NPCs", "#armorednpcs" )
end )

hook.Add( "PopulateToolMenu", "CustomMenuSettings", function()

	spawnmenu.AddToolMenuOption( "Utilities", "Armored NPCs", "ArmoredNPCSettings", "#Settings", "", "", function( panel )
		local super = LocalPlayer():IsSuperAdmin()

		panel:ClearControls()

		if not super then
			panel:Help( "Only super admins can change Armored NPC settings." )
			return
		end

		panel:CheckBox( "Enabled", "gk_armor_enabled" )
		panel:CheckBox( "Send Messages To Server Console", "gk_send_messages" )

		panel:Help( "The type of protection. nodmg is more like blast protection, deplete just lessens the damage." )
		local cbox = panel:ComboBox("Protection Type", "gk_protection_type")
		cbox:AddChoice("nodmg")
		cbox:AddChoice("deplete")

		cbox:ChooseOptionID(1)

		panel:NumSlider( "Super Soldier Modifier", "gk_super_soldier_modifier", 0, 1, 2, "%" )
	end )
end )
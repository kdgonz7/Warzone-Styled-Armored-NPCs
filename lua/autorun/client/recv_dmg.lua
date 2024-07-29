net.Receive("npc_took_damage", function()
	local ent = net.ReadEntity()

	local emitter = ParticleEmitter( ent:GetPos() + Vector( 0, 0, -1 ) )
	local part = emitter:Add( "effects/spark", ent:GetPos() + Vector( 0, 0, 50 ) ) -- Create a new particle at pos

	if ( part ) then
		part:SetDieTime( 1 ) -- How long the particle should "live"

		part:SetStartAlpha( 255 ) -- Starting alpha of the particle
		part:SetEndAlpha( 0 ) -- Particle size at the end if its lifetime

		part:SetStartSize( 5 ) -- Starting size
		part:SetEndSize( 0 ) -- Size when removed

		part:SetGravity( Vector( 0, 0, -250 ) ) -- Gravity of the particle
		part:SetVelocity( VectorRand() * 50 ) -- Initial velocity of the particle
	end

	emitter:Finish()
end)

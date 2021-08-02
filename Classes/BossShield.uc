class BossShield extends Emitter;

simulated event BaseChange()
{
	if(Base == None)
	{
		Kill();
	}
	super.BaseChange();
}

simulated function TurnOff()
{
	local int i;

	for(i=0;i<5;i++)
	{
		Emitters[i].Disabled = true;
	}
}

simulated function TurnOn()
{
	local int i;

	for(i=0;i<5;i++)
	{
		Emitters[i].Disabled = false;
	}
}

defaultproperties
{
     Begin Object Class=MeshEmitter Name=MeshEmitter0
         StaticMesh=StaticMesh'AW-2004Particles.Weapons.PlasmaSphere'
         UseParticleColor=True
         SpawnOnlyInDirectionOfNormal=True
         Opacity=0.300000
         CoordinateSystem=PTCS_Relative
         MaxParticles=1
         SpinsPerSecondRange=(X=(Min=100.000000,Max=100.000000),Y=(Min=100.000000,Max=100.000000),Z=(Min=100.000000,Max=100.000000))
         StartSpinRange=(X=(Min=5.000000,Max=10.000000),Z=(Min=1000.000000,Max=10.000000))
         RotationNormal=(X=100.000000,Y=10.000000,Z=100.000000)
         LifetimeRange=(Min=0.100000,Max=0.100000)
     End Object
     Emitters(0)=MeshEmitter'DEKBossMonsters208AE.BossShield.MeshEmitter0'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UniformSize=True
         Opacity=0.100000
         CoordinateSystem=PTCS_Relative
         MaxParticles=1
         SpinsPerSecondRange=(X=(Min=-5.000000,Max=5.000000))
         StartSpinRange=(X=(Min=-2.000000,Max=2.000000),Y=(Min=-2.000000,Max=2.000000))
         StartSizeRange=(X=(Min=243.750000,Max=243.750000))
         Texture=Texture'AW-2004Particles.Energy.EclipseCircle'
         LifetimeRange=(Min=0.100000,Max=0.100000)
     End Object
     Emitters(1)=SpriteEmitter'DEKBossMonsters208AE.BossShield.SpriteEmitter0'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         UniformSize=True
         ColorMultiplierRange=(X=(Min=0.000000,Max=0.000000),Y=(Min=0.200000,Max=0.200000))
         Opacity=0.300000
         CoordinateSystem=PTCS_Relative
         MaxParticles=2
         StartSizeRange=(X=(Min=131.250000,Max=131.250000))
         Texture=Texture'AW-2004Particles.Energy.SmoothRing'
         LifetimeRange=(Min=0.100000,Max=0.100000)
     End Object
     Emitters(2)=SpriteEmitter'DEKBossMonsters208AE.BossShield.SpriteEmitter1'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter3
         UniformSize=True
         Opacity=0.200000
         CoordinateSystem=PTCS_Relative
         MaxParticles=1
         Texture=Texture'AW-2k4XP.Weapons.ShockTankEffectCore2'
         LifetimeRange=(Min=0.100000,Max=0.100000)
     End Object
     Emitters(3)=SpriteEmitter'DEKBossMonsters208AE.BossShield.SpriteEmitter3'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter4
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         AutoReset=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Opacity=0.100000
         FadeOutFactor=(W=0.000000)
         FadeOutStartTime=0.700000
         FadeInEndTime=0.500000
         CoordinateSystem=PTCS_Relative
         MaxParticles=5
         SpinsPerSecondRange=(X=(Min=-1.000000,Max=1.000000))
         SizeScale(0)=(RelativeSize=6.500000)
         SizeScale(1)=(RelativeTime=0.900000,RelativeSize=7.500000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=9.000000)
         StartSizeRange=(X=(Min=18.750000,Max=18.750000))
         Texture=Texture'AW-2004Particles.Energy.SmoothRing'
         LifetimeRange=(Min=1.000000,Max=1.000000)
     End Object
     Emitters(4)=SpriteEmitter'DEKBossMonsters208AE.BossShield.SpriteEmitter4'

     bNoDelete=False
     RemoteRole=ROLE_SimulatedProxy
     bNotOnDedServer=False
}

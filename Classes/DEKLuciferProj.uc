class DEKLuciferProj extends LuciferProj placeable
	config(DEKBossMonsters);

simulated function Explode(vector HitLocation,vector HitNormal)
{
    if ( Role == ROLE_Authority )
    {
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    }
	PlaySound(Sound'LuciferProjExplode',SLOT_Misc,100);

	Spawn(class'DEKLuciferProjExplode',,,);
    SetCollisionSize(0.0, 0.0);
    Destroy();
}

defaultproperties
{
     Speed=1170.000000
     MaxSpeed=1300.000000
     Damage=100.000000
     DamageRadius=500.000000
     MyDamageType=Class'DEKBossMonsters208AB.DamTypeDEKLucifer'
}

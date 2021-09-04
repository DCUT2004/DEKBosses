class DEKLuciferSmallProj extends LuciferSmallProj placeable;

simulated function Explode(vector HitLocation,vector HitNormal)
{
    if ( Role == ROLE_Authority )
    {
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    }
	PlaySound(Sound'LuciferProjExplode',SLOT_Misc,1);

	Spawn(class'DEKLuciferSmallProjExplode',,,);
    SetCollisionSize(0.0, 0.0);
    Destroy();
}

defaultproperties
{
     Damage=60.000000
     DamageRadius=375.000000
     MyDamageType=Class'DEKBossMonsters209A.DamTypeDEKLucifer'
}

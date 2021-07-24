class GaiaProjectile extends NatureProjectile placeable;

simulated function ProcessTouch (Actor Other, Vector HitLocation)
{
	if (Other != None && Other == Instigator)
		return;
    if ( (Other != instigator) && (!Other.IsA('Projectile') || Other.bProjTarget) )
    {
        Explode(HitLocation, vect(0,0,1));
    }
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
	local GaiaPoison Poison;
	
	if (Instigator != None)
		Poison = Instigator.Spawn(Class'GaiaPoison', Instigator, , Self.Location);
	Super.Explode(HitLocation, HitNormal);
}

defaultproperties
{
	Speed=2000.000000
	MaxSpeed=2300.000000
	Damage=100.000000
    DamageRadius=400.000000
    ExplodeClass=Class'DEKBossMonsters208AA.GaiaProjectileExplode'
    MyDamageType=Class'DEKBossMonsters208AA.DamTypeGaiaPoison'
}

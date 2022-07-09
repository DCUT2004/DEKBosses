class DamTypeDEKLucifer extends WeaponDamageType
	abstract;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictemHealth )
{
    HitEffects[0] = class'HitSmoke';
}

defaultproperties
{
     WeaponClass=Class'DEKBossMonsters209F.WeaponLucifer'
     DeathString="%o was sent to Hell by Lucifer."
     FemaleSuicide="Lucifer destroyed herself."
     MaleSuicide="Lucifer destroyed himself."
     bDetonatesGoop=True
     bCauseConvulsions=True
     GibPerterbation=0.250000
     VehicleDamageScaling=0.850000
}
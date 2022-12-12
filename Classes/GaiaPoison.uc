class GaiaPoison extends Actor
	config(DEKBossMonsters);

var GaiaPoisonFX FX;
var PlagueFatalDeathSmoke FX1;
var config float PoisonRadius;
var config int PoisonLifespan;
var config int PoisonModifier;
var config bool bDispellable, bStackable;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(1, true);
}

simulated function Timer()
{
	local StatusEffectManager StatusManager;
	local Controller C, NextC;
	
	C = Level.ControllerList;
	
	while (C != None)
	{
		NextC = C.NextController;
		if (C != None && C.Pawn != None && C.Pawn.Health > 0 && Instigator != None && C.Pawn != Instigator && C.Pawn.GetTeamNum() != Instigator.GetTeamNum() && VSize(C.Pawn.Location - Self.Location) <= PoisonRadius)
		{
			StatusManager = Class'StatusEffectManager'.static.GetStatusEffectManager(C.Pawn);
			if (StatusManager != None)
				StatusManager.AddStatusEffect(Class'DEKRPG999X.StatusEffect_Poison', PoisonModifier, True, PoisonLifespan, bDispellable, bStackable);
		}
		C = NextC;
	}
	
	if (FX == None)
	{
		FX = Spawn(Class'GaiaPoisonFX', Self, , Self.Location);
		if (FX != None)
		{
			FX.Lifespan = PoisonLifespan;
			FX.SetBase(Self);
		}
	}
}

simulated function Destroyed()
{
	if (FX != None)
		FX.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     PoisonRadius=400.000000
	 PoisonLifespan=10
	 PoisonModifier=-3
	 bDispellable=False
	 bStackable=False
     Lifespan=10.000000
     DrawType=DT_None
     Texture=Texture'XEffectMat.Shock.shock_core'
     DrawScale=0.080000
}

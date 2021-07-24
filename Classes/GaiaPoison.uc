class GaiaPoison extends Actor
	config(DEKBossMonsters);

var GaiaPoisonFX FX;
var PlagueFatalDeathSmoke FX1;
var config float PoisonRadius;
var config int PoisonLifespan;
var config int PoisonModifier;
var config int PoisonLifespanAdd;
var config int MaxPoisonLifespan;
var RPGRules RPGRules;

simulated function PostBeginPlay()
{
	local GameRules G;
	
	Super.PostBeginPlay();

	for(G = Level.Game.GameRulesModifiers; G != None; G = G.NextGameRules)
	{
		if(G.isA('RPGRules'))
		{
			RPGRules = RPGRules(G);
			break;
		}
	}
   SetTimer(1, true);
}

simulated function Timer()
{
	local DruidPoisonInv Inv;
	local Controller C, NextC;
	
	C = Level.ControllerList;
	
	while (C != None)
	{
		NextC = C.NextController;
		if (C != None && C.Pawn != None && C.Pawn.Health > 0 && Instigator != None && C.Pawn != Instigator && C.Pawn.GetTeamNum() != Instigator.GetTeamNum() && VSize(C.Pawn.Location - Self.Location) <= PoisonRadius)
		{
			Inv = DruidPoisonInv(C.Pawn.FindInventoryType(class'DruidPoisonInv'));
			if (Inv == None)
			{
				Inv = C.Pawn.Spawn(class'DruidPoisonInv', C.Pawn);
				Inv.Lifespan = PoisonLifespan;
				Inv.Modifier = PoisonModifier;
				Inv.RPGRules = RPGRules;
				Inv.GiveTo(C.Pawn);
			}
			else
			{
				Inv.Lifespan += PoisonLifespanAdd;
				if (Inv.Lifespan > MaxPoisonLifespan)
					Inv.Lifespan = MaxPoisonLifespan;
			}
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
	 PoisonModifier=3
	 PoisonLifespanAdd=1
	 MaxPoisonLifespan=18
     Lifespan=10.000000
     DrawType=DT_None
     Texture=Texture'XEffectMat.Shock.shock_core'
     DrawScale=0.080000
}

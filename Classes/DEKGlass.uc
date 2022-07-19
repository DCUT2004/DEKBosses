class DEKGlass extends GlassINIv3
	config(DEKBossMonsters);

//Boss variables
var BossInv BInv;
var config float DamageReductionMultiplier;
var config int XPReward;
var config class<Monster> MinionClass;

//Combo variables
var ComboInv Combo;
var config int AdrenDripAmount;
var config Array < class < ComboEffectInv > > ComboClass;
var config bool bComboDamage;
var config bool bComboDamageAll, bComboDamageMulti, bComboDamageSingle;
var config int ComboDamage;
var config class<DamageType> ComboDamageType;
struct ComboInfo
{
	var int Lifespan;
	var bool bBuff;
	var float Multiplier;
	var bool bDispellable;
	var bool bAll;
	var bool bMulti;
	var bool bSingle;
};
var config Array<ComboInfo> ComboData;

//Adrenaline steal variables
var config float AdrenStealPercent;
var config bool bStealSingle, bStealMulti, bStealAll;

//Teleport variables
var vector TelepDest;
var byte AChannel;
var float LastTelepoTime;
var bool bTeleporting;
var config float TeleportRange;

//Discoverable Materials
var config int MaterialChance;
var config int LowMaterialChance, MediumMaterialChance, HighMaterialChance;
var config Array < class < AbilityMaterial > > LowMaterials, MediumMaterials, HighMaterials, VeryHighMaterials;

//Other
var() config float ScreamInterval;
var() float LastScreamTime;
var config int ScreamDamage;
var config float ScreamRadius;
var() config float CloneInterval;
var() float LastCloneTime;
var int numChildren;
var config int maxChildren;
var() vector ShakeRotMag;           // how far to rot view
var() vector ShakeRotRate;          // how fast to rot view
var() float  ShakeRotTime;          // how much time to rot the instigator's view
var() vector ShakeOffsetMag;        // max view offset vertically
var() vector ShakeOffsetRate;       // how fast to offset view vertically
var() float  ShakeOffsetTime;       // how much time to offset view

#exec  AUDIO IMPORT NAME="SirenScream" FILE="Sounds\SirenScream.WAV" GROUP="MonsterSounds"
#exec  AUDIO IMPORT NAME="Kiss" FILE="Sounds\GiveUsAKiss.WAV" GROUP="MonsterSounds"

replication
{
	reliable if(Role==ROLE_Authority )
         bTeleporting;
}

function PostBeginPlay()
{
	local IceInv Inv;
	
	//ScoringValue *= class'ElementalConfigure'.default.FireScoreMultiplier;
	//GroundSpeed *= class'ElementalConfigure'.default.FireGroundSpeedMultiplier;
	//AirSpeed *= class'ElementalConfigure'.default.FireAirSpeedMultiplier;
	//WaterSpeed *= class'ElementalConfigure'.default.FireWaterSpeedMultiplier;
	Mass *= class'ElementalConfigure'.default.BossMassMultiplier;
	//SetLocation(Instigator.Location+vect(0,0,1)*(Instigator.CollisionHeight*class'ElementalConfigure'.default.FireDrawscaleMultiplier/2));
	//SetDrawScale(Drawscale*class'ElementalConfigure'.default.FireDrawscaleMultiplier);
	//SetCollisionSize(CollisionRadius*class'ElementalConfigure'.default.FireDrawscaleMultiplier, CollisionHeight*class'ElementalConfigure'.default.FireDrawscaleMultiplier);
	
	if (Instigator != None)
	{
		Inv = IceInv(Instigator.FindInventoryType(class'IceInv'));
		BInv = BossInv(Instigator.FindInventoryType(class'BossInv'));
		Combo = ComboInv(Instigator.FindInventoryType(class'ComboInv'));
		if (Inv == None)
		{
			Inv = Instigator.Spawn(class'IceInv');
			Inv.GiveTo(Instigator);
		}
		if (BInv == None)
		{
			BInv = Instigator.Spawn(class'BossInv');
			BInv.AdrenDripAmount = AdrenDripAmount;
			BInv.MinionClass = MinionClass;
			BInv.GiveTo(Instigator);
		}
		if (Combo == None)
		{
			Combo = Instigator.Spawn(class'ComboInv');
			Combo.GiveTo(Instigator);
		}
	}
	
	if (!bComboDamage)
		ComboDamage = 0;
	
	if (bComboDamageAll)
	{
		bComboDamageMulti = False;
		bComboDamageSingle = False;
	}
	else if (bComboDamageMulti)
	{
		bComboDamageAll = False;
		bComboDamageSingle = False;
	}
	else if (bComboDamageSingle)
	{
		bComboDamageAll = False;
		bComboDamageMulti = False;
	}
	numChildren = 0;
	
	Super.PostBeginPlay();
}

function bool SameSpeciesAs(Pawn P)
{
		return ( P.class == MinionClass);
}

function RangedAttack(Actor A)
{
	local float decision;
	
	decision = FRand();
	
	if (VSize(A.Location - Location) <= ScreamRadius && Level.TimeSeconds - LastScreamTime > ScreamInterval)
	{
		LastScreamTime = Level.TimeSeconds;
		Scream();
	}
	if (Level.TimeSeconds - LastCloneTime > CloneInterval && numChildren < maxChildren)
	{
		LastCloneTime = Level.TimeSeconds;
		Clone();
	}
	
	if(VSize(A.Location-Location) > TeleportRange && (decision < 0.70))
	{
		PlaySound(sound'BWeaponSpawn1', SLOT_Interface);
		GotoState('Teleporting');
	}
	if (Instigator != None && Instigator.Controller != None)
	{
		if (Instigator.Controller.Adrenaline >= 100 && Combo != None)
		{
			StartCombo();
		}
	}
	if (numChildren < 0)
		numChildren = 0;
	
	Super.RangedAttack(A);
}

function Scream()
{
	local Controller C;
	
	C = Level.ControllerList;
	
	Instigator.PlaySound(Sound'SirenScream', , Instigator.TransientSoundVolume*0.8);
	GotoState('Screaming');
}

state Screaming
{
    function BeginState()
    {
		ShakeView();
    }

    simulated function ShakeView()
    {
        local Controller C;
        local PlayerController PC;
        local float Dist, Scale;

        for ( C=Level.ControllerList; C!=None; C=C.NextController )
        {
            PC = PlayerController(C);
            if ( PC != None && PC.ViewTarget != None )
            {
                Dist = VSize(Location - PC.ViewTarget.Location);
                if ( Dist < ScreamRadius * 2.0)
                {
                    if (Dist < ScreamRadius)
                        Scale = 1.0;
                    else
                        Scale = (ScreamRadius*2.0 - Dist) / (ScreamRadius);
                    C.ShakeView(ShakeRotMag*Scale, ShakeRotRate, ShakeRotTime, ShakeOffsetMag*Scale, ShakeOffsetRate, ShakeOffsetTime);
                }
            }
        }
    }
Begin:
    HurtRadius(ScreamDamage, ScreamRadius*0.500, Class'DamTypeGlassScream', 0.0, Location);
    Sleep(0.2);
    HurtRadius(ScreamDamage*0.70, ScreamRadius*0.75, Class'DamTypeGlassScream', 0.0, Location);
    Sleep(0.2);
    HurtRadius(ScreamDamage*0.50, ScreamRadius, Class'DamTypeGlassScream', 0.0, Location);
}

function PlaySoundINI()
{
	return;
	//PlaySound(Sound'GlassINIv3.Wraithsfire');
}

function Clone()
{
	local NavigationPoint N;
	local DEKGlassClone P;
	
	if (numChildren >= MaxChildren)
		return;

	For ( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
	{
		if(numChildren>=default.MaxChildren)
			return;
		else if(vsize(N.Location-Location)<2000 && FastTrace(N.Location,Location))
		{
			P=spawn(class 'DEKGlassClone' ,self,,N.Location);
		    if(P!=none)
		    {
				numChildren++;
				P.PlaySound(Sound'Kiss');
			}
		}
	}
	Instigator.PlaySound(Sound'Kiss');
}

function StartCombo()
{
	local int x;
	local int AdrenReward;
	local int EffectInt;
	
	if (BInv != None)
		BInv.AdrenCounter = 0;
	Instigator.Controller.Adrenaline = 0;
	
	//Glass steals adren as part of combo
	AdrenReward = Combo.StealAdrenaline(Instigator, bStealAll, bStealMulti, bStealSingle, AdrenStealPercent);
	if (Instigator != None && Instigator.Controller != None)
		Instigator.Controller.AwardAdrenaline(AdrenReward);
	EffectInt = AdrenStealPercent*100;
	Level.Game.Broadcast(Self, "Glass steals " $ EffectInt $ "% adrenaline from top 3 level players");
	
	if (bComboDamage && ComboDamage > 0)
		Combo.ComboDamage(ComboDamage, bComboDamageAll, bComboDamageMulti, bComboDamageSingle, ComboDamageType, class'RocketExplosion', True);
	
	for ( x = 0; x < ComboClass.Length; x++)
	{
		if (ComboData[x].bBuff)
			Combo.AddBuff(Self, ComboData[x].bAll, ComboData[x].bMulti, ComboData[x].bSingle, ComboData[x].Lifespan, ComboClass[x], ComboData[x].Multiplier, ComboData[x].bDispellable);
		else
			Combo.AddAilment(Self, ComboData[x].bAll, ComboData[x].bMulti, ComboData[x].bSingle, ComboData[x].Lifespan, ComboClass[x], ComboData[x].Multiplier, ComboData[x].bDispellable);
	}
	
	Instigator.PlaySound(Sound'DEKBossMonsters999X.Boss.BossComboActivate', SLOT_None, 800.0,,2000.00);
}


function Teleport()
{
	local rotator EnemyRot;

	if ( Role == ROLE_Authority )
		ChooseDestination();
	SetLocation(TelepDest+vect(0,0,1)*CollisionHeight/2);
	AChannel=0;
	if(Controller.Enemy!=none)
		EnemyRot = rotator(Controller.Enemy.Location - Location);
	EnemyRot.Pitch = 0;
	setRotation(EnemyRot);
	Spawn(class'OrangeTransEffect',Self,,Location);
	Spawn(class'OrangeTransDeres',Self,,Location);
	PlaySound(sound'BWeaponSpawn1', SLOT_Interface);
}

function ChooseDestination()
{
	local NavigationPoint N;
	local vector ViewPoint, Best;
	local float rating, newrating;
	local Actor jActor;
	
	Best = Location;
	TelepDest = Location;
	rating = 0;
	if(Controller.Enemy==none)
		return;
	for ( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
	{
		newrating = 0;

		ViewPoint = N.Location +vect(0,0,1)*CollisionHeight/2;
		if (FastTrace( Controller.Enemy.Location,ViewPoint))
			newrating += 20000;
		newrating -= VSize(N.Location - Controller.Enemy.Location) + 1000 * FRand();
		foreach N.VisibleCollidingActors(class'Actor',jActor,CollisionRadius,ViewPoint)
			newrating -= 30000;
		if ( newrating > rating )
		{
			rating = newrating;
			Best = N.Location;
		}
   	}
	TelepDest = Best;
}

simulated function Tick(float DeltaTime)
{
	if(bTeleporting)
	{
		AChannel-=300 *DeltaTime;
	}
	else
		AChannel=255;

	if(MonsterController(Controller)!=none && Controller.Enemy==none)
	{
		if(MonsterController(Controller).FindNewEnemy())
		{
			GotoState('Teleporting');
	    }
	}
	super.Tick(DeltaTime);
}

state Teleporting
{
	function Tick(float DeltaTime)
	{
		if(AChannel<20)
		{
            if (ROLE == ROLE_Authority)
				Teleport();
			GotoState('');
		}
		global.Tick(DeltaTime);
	}


	function RangedAttack(Actor A)
	{
		return;
	}
	function BeginState()
	{
		if(Controller.Enemy==none)
		{
			GotoState('');
			return;
		}
		bTeleporting=true;
		Acceleration = Vect(0,0,0);
		bUnlit = true;
		AChannel=255;
		PlaySound(sound'BWeaponSpawn1', SLOT_Interface);
	}

	function EndState()
	{
        bTeleporting=false;
		bUnlit = true;
		AChannel=255;

		LastTelepoTime=Level.TimeSeconds;
	}
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	local FireInv Inv;
	
	if (Damage > 0)
	{
		if (ClassIsChildOf(damageType, class'DamTypeRoadkill'))	//No damage by vehicle crushing
			return;
		if (ClassIsChildOf(damageType, class'SMPDamTypeTitanRock'))	//No damage by Titan pets
			return;
		if (ClassIsChildOf(damagetype, class'DamTypeONSRVBlade'))
			return;
		if (ClassIsChildOf(damagetype, class'DamTypeLynxBlade'))
			return;
		Damage *= DamageReductionMultiplier;
	}
	
	if (Damage > 0 && instigatedBy != None && instigatedBy.IsA('Monster') && instigatedBy.Controller != None && !instigatedBy.Controller.SameTeamAs(Self.Controller))
	{
		Inv = FireInv(instigatedBy.FindInventoryType(class'FireInv'));
		if (Inv != None)
		{
			Damage *= class'ElementalConfigure'.default.FireonIceDamageMultiplier;
		}
	}
	Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damagetype);
}

event EncroachedBy( actor Other )
{
	// do nothing. Adding this stub stops telefragging
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local Mutator M;
	local MutEndGameTimer EndTimer;
	
	PlayDirectionalDeath(HitLocation);
	if (Invasion(Level.Game) != None)
		Invasion(Level.Game).NumMonsters = 0;
	RewardXP();
	RewardMaterial();
	Level.Game.Broadcast(self, "Glass is defeated!");
	if (Invasion(Level.Game) != None)
	{
		for (m = Level.Game.BaseMutator; m != None; m = m.NextMutator)
			if (MutEndGameTimer(m) != None)
			{
				EndTimer = MutEndGameTimer(m);
				break;
			}
		if (EndTimer != None)
		{
			Invasion(Level.Game).SetTimer(0, False);
			EndTimer.SetTimer(EndTimer.EndTimer, False);
			Level.game.Broadcast(self, "The game will end in " $ EndTimer.EndTimer $ " seconds. Take the time now to purchase materials.");
		}
	}
	Super.Died(Killer, damageType, HitLocation);
}

function RewardXP()
{
	local Controller C;
	local MutUT2004RPG RPG;
	local Mutator m;
	local RPGStatsInv StatsInv;
	local RPGRules Rules;
	Local GameRules G;
	
	if (Level.Game != None)
	{
		for(G = Level.Game.GameRulesModifiers; G != None; G = G.NextGameRules)
		{
			if(G.isA('RPGRules'))
			{
				Rules = RPGRules(G);
				break;
			}
		}
		
		for (m = Level.Game.BaseMutator; m != None; m = m.NextMutator)
			if (MutUT2004RPG(m) != None)
			{
				RPG = MutUT2004RPG(m);
				break;
			}
	}
	
	if(Rules == None)
		Log("WARNING: Unable to find RPGRules in GameRules. EXP will not be properly awarded");
		
	if (RPG != None && Rules != None && RPG.EXPForWin > 0)
	{
		for (C = Level.ControllerList; C != None; C = C.NextController)
			if (C.PlayerReplicationInfo != None && C.bIsPlayer)
			{
				StatsInv = Rules.GetStatsInvFor(C);
				if (StatsInv != None)
				{
					StatsInv.DataObject.Experience += XPReward;
					RPG.CheckLevelUp(StatsInv.DataObject, C.PlayerReplicationInfo);
				}
			}
	}
}

function RewardMaterial()
{
	local Controller C;
	local GiveItemsInv GInv;
	local int MaterialRank;
	local int RandIndex;
	
	for (C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (Rand(100) <= MaterialChance)
		{
			if (C.PlayerReplicationInfo != None && C.bIsPlayer)
			{
				GInv = class'GiveItemsInv'.static.GetGiveItemsInv(C);
				if (GInv != None)
				{
					MaterialRank = Rand(100);
					if (MaterialRank <= LowMaterialChance)
					{
						RandIndex = RandRange(0, LowMaterials.Length);
						GInv.AddMaterial(LowMaterials[RandIndex]);
					}
					else if (MaterialRank <= MediumMaterialChance)
					{
						RandIndex = RandRange(0, MediumMaterials.Length);
						GInv.AddMaterial(MediumMaterials[RandIndex]);
					}
					else if (MaterialRank <= HighMaterialChance)
					{
						RandIndex = RandRange(0, HighMaterials.Length);
						GInv.AddMaterial(HighMaterials[RandIndex]);
					}
					else
					{
						RandIndex = RandRange(0, VeryHighMaterials.Length);
						GInv.AddMaterial(VeryHighMaterials[RandIndex]);
					}
				}
			}
		}
	}
}

defaultproperties
{
	ScreamDamage=70
	ScreamRadius=400.0000
	ScreamInterval=10.0000
	ShakeRotMag=(Z=375.000000)
	ShakeRotRate=(Z=2125.000000)
	ShakeRotTime=6.000000
	ShakeOffsetMag=(Z=20.000000)
	ShakeOffsetRate=(Z=250.000000)
	ShakeOffsetTime=10.000000
	CloneInterval=30.0000
	MaxChildren=2
	DamageReductionMultiplier=0.500000
	XPReward=200
	MinionClass=Class'DEKBossMonsters999X.MinionTechSniper'
	AdrenDripAmount=5
	bComboDamage=True
	bComboDamageMulti=True
	ComboDamage=150
	ComboDamageType=Class'DEKRPG999X.DamTypeCombo'
	AChannel=255
	TeleportRange=7000.000000
	AmmunitionClass=Class'DEKBossMonsters999X.DEKGlassAmmo'
	OwnerName="Glass"
	Mass=1000.00
	fHealth=35000.00
	HealthMax=35000.000000
	Health=35000
	AdrenStealPercent=0.2000
	bStealAll=False
	bStealMulti=True
	bStealSingle=False
	MaterialChance=30
	LowMaterialChance=25
	MediumMaterialChance=50
	HighMaterialChance=85
	LowMaterials(0)=Class'DEKRPG999X.AbilityMaterialLumber'
	LowMaterials(1)=Class'DEKRPG999X.AbilityMaterialCombatBoots'
	LowMaterials(2)=Class'DEKRPG999X.AbilityMaterialTarydiumShards'
	LowMaterials(3)=Class'DEKRPG999X.AbilityMaterialSteel'
	LowMaterials(4)=Class'DEKRPG999X.AbilityMaterialNaliFruit'
	LowMaterials(5)=Class'DEKRPG999X.AbilityMaterialGloves'
	MediumMaterials(0)=Class'DEKRPG999X.AbilityMaterialLeather'
	MediumMaterials(1)=Class'DEKRPG999X.AbilityMaterialPlatedArmor'
	MediumMaterials(2)=Class'DEKRPG999X.AbilityMaterialHoneysuckleVine'
	MediumMaterials(3)=Class'DEKRPG999X.AbilityMaterialEmbers'
	MediumMaterials(4)=Class'DEKRPG999X.AbilityMaterialArcticSuit'
	HighMaterials(0)=Class'DEKRPG999X.AbilityMaterialMoss'
	HighMaterials(1)=Class'DEKRPG999X.AbilityMaterialDust'
	HighMaterials(2)=Class'DEKRPG999X.AbilityMaterialNanite'
	HighMaterials(3)=Class'DEKRPG999X.AbilityMaterialPumice'
	HighMaterials(4)=Class'DEKRPG999X.AbilityMaterialIcicle'
	VeryHighMaterials(0)=Class'DEKRPG999X.AbilityMaterialStarChart'
}

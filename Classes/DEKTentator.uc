class DEKTentator extends Tentator
	config(DEKBossMonsters);

//Boss variables
var BossInv BInv;
var config float DamageReductionMultiplier;
var config int XPReward;
var config class<Monster> MinionClass;
var config float ScaleMultiplier;

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

replication
{
	reliable if(Role==ROLE_Authority )
         bTeleporting;
}

function PostBeginPlay()
{
	local IceInv Inv;
	
	Mass *= class'ElementalConfigure'.default.BossMassMultiplier;
	SetLocation(Instigator.Location+vect(0,0,1)*(Instigator.CollisionHeight*ScaleMultiplier/2));
	SetDrawScale(Drawscale*ScaleMultiplier);
	SetCollisionSize(CollisionRadius*ScaleMultiplier, CollisionHeight*ScaleMultiplier);
	
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
	
	Super.PostBeginPlay();
}

function bool SameSpeciesAs(Pawn P)
{
		return ( P.class == MinionClass);
}

function RangedAttack(Actor A)
{
	local float decision;
	local vector adjust;
	
	decision = FRand();
	Target = A;
	
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

	if(A != None && VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
	{
		adjust = vect(0,0,0);
		adjust.Z = A.CollisionHeight;
        Acceleration = AccelRate * Normal(A.Location - Location + adjust);
		SetAnimAction(MeleeAnims[Rand(4)]);
		bShotAnim = true;
	}
	else if(Level.TimeSeconds - LastRangedAttackTime > RangedAttackInterval)
	{
		LastRangedAttackTime = Level.TimeSeconds;
		SetAnimAction(RangedAttackAnims[Rand(4)]);
		bShotAnim = true;
	}
}

function StartCombo()
{
	local int x;
	
	if (bComboDamage && ComboDamage > 0)
		Combo.ComboDamage(ComboDamage, bComboDamageAll, bComboDamageMulti, bComboDamageSingle, ComboDamageType, class'RocketExplosion');
	
	if (Combo != None)
	{
		for ( x = 0; x < ComboClass.Length; x++)
		{
			if (ComboData[x].bBuff)
				Combo.AddBuff(Self, ComboData[x].bAll, ComboData[x].bMulti, ComboData[x].bSingle, ComboData[x].Lifespan, ComboClass[x], ComboData[x].Multiplier, ComboData[x].bDispellable);
			else
				Combo.AddAilment(Self, ComboData[x].bAll, ComboData[x].bMulti, ComboData[x].bSingle, ComboData[x].Lifespan, ComboClass[x], ComboData[x].Multiplier, ComboData[x].bDispellable);
		}
	}
	
	if (BInv != None)
		BInv.AdrenCounter = 0;
	Instigator.Controller.Adrenaline = 0;
	
	Instigator.PlaySound(Sound'DEKBossMonsters208AG.Boss.BossComboActivate', SLOT_None, 800.0,,2000.00);
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
	local SuperHeatInv Inv;
	
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
		Inv = SuperHeatInv(instigatedBy.FindInventoryType(class'SuperHeatInv'));
		if (Inv != None)
		{
			Damage *= class'ElementalConfigure'.default.FireonIceDamageMultiplier;
		}
	}
	Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damagetype);
}

//function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
//{
//	return;
//}

//function PlayDirectionalHit(Vector HitLoc)
//{
//	return;		//do nothing. This function stuns the boss
//}

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
	Level.Game.Broadcast(self, "Tentator is defeated!");
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

event GainedChild(Actor Other)
{
	if(DEKTentatorProj(Other) != None)
	{
		if(bUseDamageConfig)
		{
			DEKTentatorProj(Other).Damage = ProjectileDamage;
		}

		if(bProjCanLock && Target != None)
		{
			DEKTentatorProj(Other).bSeeking = true;
			DEKTentatorProj(Other).Seeking = Target;
		}
	}


    Super.GainedChild(Other);
}

function FireLowerProjectileL()
{
	local Vector FireStart;
	local Projectile Proj;

	if ( Controller != None )
	{
		FireStart = GetBoneCoords('lprojbottom').Origin;
		Proj = Spawn(class'DEKTentatorProj',self,,FireStart,Controller.AdjustAim(SavedFireProperties,FireStart,10));
		if(Proj != None)
		{
			PlaySound(FireSound,SLOT_Interact);
		}
	}
}

function FireLowerProjectileR()
{
	local Vector FireStart;
	local Projectile Proj;

	if ( Controller != None )
	{
		FireStart = GetBoneCoords('rprojbottom').Origin;
		Proj = Spawn(class'DEKTentatorProj',self,,FireStart,Controller.AdjustAim(SavedFireProperties,FireStart,10));
		if(Proj != None)
		{
			PlaySound(FireSound,SLOT_Interact);
		}
	}
}

function FireProjectileR()
{
	local Vector FireStart;
	local Projectile Proj;

	if ( Controller != None )
	{
		FireStart = GetBoneCoords('rprojtop').Origin;
		Proj = Spawn(class'DEKTentatorProj',self,,FireStart,Controller.AdjustAim(SavedFireProperties,FireStart,10));
		if(Proj != None)
		{
			PlaySound(FireSound,SLOT_Interact);
		}
	}
}

function FireProjectileL()
{
	local Vector FireStart;
	local Projectile Proj;

	if ( Controller != None )
	{
		FireStart = GetBoneCoords('lprojtop').Origin;
		Proj = Spawn(class'DEKTentatorProj',self,,FireStart,Controller.AdjustAim(SavedFireProperties,FireStart,10));
		if(Proj != None)
		{
			PlaySound(FireSound,SLOT_Interact);
		}
	}
}

defaultproperties
{
	DamageReductionMultiplier=0.500000
	XPReward=200
	MinionClass=Class'DEKBossMonsters208AG.MinionIceSkaarj'
	AdrenDripAmount=7
	ComboClass(0)=Class'DEKRPG208AG.ComboLifeDrainInv'
	ComboClass(1)=Class'DEKRPG208AG.ComboMisfortuneInv'
	bComboDamage=False
	ComboDamage=0
	ComboDamageType=Class'DEKRPG208AG.DamTypeCombo'
	ComboData(0)=(LifeSpan=20,Multiplier=0.100000,bDispellable=True,bSingle=True,bBuff=False)
	ComboData(1)=(LifeSpan=20,Multiplier=400.00,bDispellable=True,bSingle=True,bBuff=False)
	OwnerName="Tentator"
	HealthMax=35000.000000
	Health=35000
	NewHealth=35000
	bHealthRegen=False
	bCanHurtNearbyTargets=True
	ControllerClass=Class'DEKMonsters208AG.DCMonsterController'
	AChannel=255
	TeleportRange=7000.000000
	ScaleMultiplier=2.000
	ProjectileDamage=50
	AirSpeed=700.000000
	MaterialChance=30
	LowMaterialChance=40
	MediumMaterialChance=60
	HighMaterialChance=90
	LowMaterials(0)=Class'DEKRPG208AG.AbilityMaterialLumber'
	LowMaterials(1)=Class'DEKRPG208AG.AbilityMaterialCombatBoots'
	LowMaterials(2)=Class'DEKRPG208AG.AbilityMaterialTarydiumShards'
	LowMaterials(3)=Class'DEKRPG208AG.AbilityMaterialSteel'
	LowMaterials(4)=Class'DEKRPG208AG.AbilityMaterialNaliFruit'
	LowMaterials(5)=Class'DEKRPG208AG.AbilityMaterialGloves'
	MediumMaterials(0)=Class'DEKRPG208AG.AbilityMaterialLeather'
	MediumMaterials(1)=Class'DEKRPG208AG.AbilityMaterialPlatedArmor'
	MediumMaterials(2)=Class'DEKRPG208AG.AbilityMaterialHoneysuckleVine'
	MediumMaterials(3)=Class'DEKRPG208AG.AbilityMaterialEmbers'
	MediumMaterials(4)=Class'DEKRPG208AG.AbilityMaterialArcticSuit'
	HighMaterials(0)=Class'DEKRPG208AG.AbilityMaterialMoss'
	HighMaterials(1)=Class'DEKRPG208AG.AbilityMaterialDust'
	HighMaterials(2)=Class'DEKRPG208AG.AbilityMaterialNanite'
	HighMaterials(3)=Class'DEKRPG208AG.AbilityMaterialPumice'
	HighMaterials(4)=Class'DEKRPG208AG.AbilityMaterialIcicle'
	VeryHighMaterials(0)=Class'DEKRPG208AG.AbilityMaterialHourglass'
}

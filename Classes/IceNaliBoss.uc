class IceNaliBoss extends Monster
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

//Magic weapon resistance
var config Array <class <RPGWeapon> > RetaliateMagicClass;
var config float RetaliationPercent;
var Class<DamageType> DamTypeRetaliationClass;

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


var name DeathAnim[4];

replication
{
	reliable if(Role==ROLE_Authority )
         bTeleporting;
}

simulated function PostBeginPlay()
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
	
	Super.PostBeginPlay();
}

function bool SameSpeciesAs(Pawn P)
{
		return ( P.class == MinionClass);
}

function RangedAttack(Actor A)
{
	local float decision;
	
	Super.RangedAttack(A);

	decision = FRand();

	if ( bShotAnim )
		return;

	if ( Physics == PHYS_Swimming )
	{
		SetAnimAction('Tread');
		FireProjectile();;
	}
	else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
	{
		SetAnimAction('Bow2');
		if ( MeleeDamageTarget(45, (45000.0 * Normal(Controller.Target.Location - Location))) )
			PlaySound(sound'mn_hit10', SLOT_Talk); 
	}
	else if(VSize(A.Location-Location)>7000 && (decision < 0.70))
	{
		SetAnimAction('spell');
		PlaySound(sound'BWeaponSpawn1', SLOT_Interface);
		GotoState('Teleporting');
	}
	else
	{
		SetAnimAction('spell');
		FireProjectile();;
	}
	if (Instigator != None && Instigator.Controller != None)
	{
		if (Instigator.Controller.Adrenaline >= 100 && Combo != None)
		{
			StartCombo();
		}
	}
	Controller.bPreparingMove = true;
	Acceleration = vect(0,0,0);
	bShotAnim = true;
}

function StartCombo()
{
	local int x;
	
	if (bComboDamage && ComboDamage > 0)
		Combo.ComboDamage(ComboDamage, bComboDamageAll, bComboDamageMulti, bComboDamageSingle, ComboDamageType, class'RocketExplosion', True);
	
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

function vector GetFireStart(vector X, vector Y, vector Z)
{
    return Location + 0.9*X - 0.5*Y;
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
	Spawn(class'WhiteTransEffect',Self,,Location);
	Spawn(class'WhiteTransDeres',Self,,Location);
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
			SetAnimAction('Levitate');
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
		bUnlit = false;
		AChannel=255;

		LastTelepoTime=Level.TimeSeconds;
	}
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	local FireInv Inv;
	local RPGWeapon MagicWeapon;
	local int x;
	
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
		//Retaliation
		if (instigatedBy != None && RPGWeapon(instigatedBy.Weapon) != None)
		{
			MagicWeapon = RPGWeapon(instigatedBy.Weapon);
			for (x = 0; x < RetaliateMagicClass.Length; x++)
			{
				if (MagicWeapon.Class == RetaliateMagicClass[x])
				{
					instigatedBy.TakeDamage(Damage * RetaliationPercent, Self, instigatedBy.Location, vect(0,0,0), DamTypeRetaliationClass);
					break;
				}
			}
		}
		Damage *= DamageReductionMultiplier;
	}
	
	if (Damage > 0 && instigatedBy != None && instigatedBy.IsA('Monster') && instigatedBy.Controller != None && !instigatedBy.Controller.SameTeamAs(Self.Controller))
	{
		Inv = FireInv(instigatedBy.FindInventoryType(class'FireInv'));
		if (Inv != None)
		{
			Damage *= class'ElementalConfigure'.default.FireOnIceDamageMultiplier;
		}
	}
	Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damagetype);
}

event EncroachedBy( actor Other )
{
	// do nothing. Adding this stub stops telefragging
}

simulated function PlayDirectionalHit(Vector HitLoc)
{
	return;
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	AmbientSound = None;
    bCanTeleport = false; 
    bReplicateMovement = false;
    bTearOff = true;
    bPlayedDeath = true;
		
	HitDamageType = DamageType;
    TakeHitLocation = HitLoc;
	LifeSpan = RagdollLifeSpan;

    GotoState('Dying');
		
	Velocity += TearOffMomentum;
    BaseEyeHeight = Default.BaseEyeHeight;
    SetPhysics(PHYS_Falling);
    
    if ( (DamageType == class'DamTypeSniperHeadShot')
		|| ((HitLoc.Z > Location.Z + 0.75 * CollisionHeight) && (FRand() > 0.5) 
			&& (DamageType != class'DamTypeAssaultBullet') && (DamageType != class'DamTypeMinigunBullet') && (DamageType != class'DamTypeFlakChunk')) )
    {
		PlayAnim('Dead3',1,0.05);
		CreateGib('head',DamageType,Rotation);
		return;
	}
	else
		PlayAnim(DeathAnim[Rand(4)],1.2,0.05);		
}

function PlayVictory()
{
	Controller.bPreparingMove = true;
	Acceleration = vect(0,0,0);
	bShotAnim = true;
	SetAnimAction('Victory1');
	Controller.Destination = Location;
	Controller.GotoState('TacticalMove','WaitForAnim');
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
	Level.Game.Broadcast(self, "Arctic Nali is defeated!");
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
	AmmunitionClass=Class'DEKBossMonsters208AG.IceNaliBossAmmo'
	DamageReductionMultiplier=0.500000
	XPReward=200
	MinionClass=Class'DEKBossMonsters208AG.MinionIceSlith'
	AdrenDripAmount=7
	ComboClass(0)=Class'DEKRPG208AG.ComboFreezeInv'
	bComboDamage=True
	bComboDamageAll=True
	ComboDamage=100
	ComboDamageType=Class'DEKRPG208AG.DamTypeCombo'
	ComboData(0)=(LifeSpan=10,Multiplier=5.000000,bDispellable=True,bAll=True,bBuff=False)
	RetaliationPercent=0.5000
	DamTypeRetaliationClass=Class'DEKBossMonsters208AG.DamTypeIceNaliRetaliation'
	OwnerName="Arctic Nali"
	HealthMax=10000.000000
	Health=35000
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
	VeryHighMaterials(0)=Class'DEKRPG208AG.AbilityMaterialMoonlitStone'
	AChannel=255
	DeathAnim(0)="Dead"
	DeathAnim(1)="Dead2"
	DeathAnim(2)="Dead3"
	DeathAnim(3)="Dead4"
	bMeleeFighter=False
	HitSound(0)=Sound'satoreMonsterPackv120.Nali.injur1n'
	HitSound(1)=Sound'satoreMonsterPackv120.Nali.injur2n'
	HitSound(2)=Sound'satoreMonsterPackv120.Nali.injur1n'
	HitSound(3)=Sound'satoreMonsterPackv120.Nali.injur2n'
	DeathSound(0)=Sound'satoreMonsterPackv120.Nali.death1n'
	DeathSound(1)=Sound'satoreMonsterPackv120.Nali.death2n'
    GibGroupClass=Class'DEKMonsters208AG.IceGibGroup'
	WallDodgeAnims(0)="levitate"
	WallDodgeAnims(1)="levitate"
	WallDodgeAnims(2)="levitate"
	WallDodgeAnims(3)="levitate"
	IdleHeavyAnim="Breath"
	IdleRifleAnim="Breath"
	FireHeavyRapidAnim="spell"
	FireHeavyBurstAnim="spell"
	FireRifleRapidAnim="spell"
	FireRifleBurstAnim="spell"
	MeleeRange=60.000000
	ControllerClass=Class'DEKMonsters208AG.DCMonsterController'
	MovementAnims(0)="levitate"
	MovementAnims(1)="levitate"
	MovementAnims(2)="levitate"
	MovementAnims(3)="levitate"
	SwimAnims(0)="Swim"
	SwimAnims(1)="Swim"
	SwimAnims(2)="Swim"
	SwimAnims(3)="Swim"
	CrouchAnims(0)="Cringe"
	CrouchAnims(1)="Cringe"
	CrouchAnims(2)="Cringe"
	CrouchAnims(3)="Cringe"
	WalkAnims(0)="Walk"
	WalkAnims(1)="Walk"
	WalkAnims(2)="Walk"
	WalkAnims(3)="Walk"
	AirAnims(0)="levitate"
	AirAnims(1)="levitate"
	AirAnims(2)="levitate"
	AirAnims(3)="levitate"
	TakeoffAnims(0)="levitate"
	TakeoffAnims(1)="levitate"
	TakeoffAnims(2)="levitate"
	TakeoffAnims(3)="levitate"
	LandAnims(0)="Landed"
	LandAnims(1)="Landed"
	LandAnims(2)="Landed"
	LandAnims(3)="Landed"
	DoubleJumpAnims(0)="levitate"
	DoubleJumpAnims(1)="levitate"
	DoubleJumpAnims(2)="levitate"
	DoubleJumpAnims(3)="levitate"
	DodgeAnims(0)="levitate"
	DodgeAnims(1)="levitate"
	DodgeAnims(2)="levitate"
	DodgeAnims(3)="levitate"
	AirStillAnim="levitate"
	TakeoffStillAnim="levitate"
	CrouchTurnRightAnim="Cringe"
	CrouchTurnLeftAnim="Cringe"
	IdleCrouchAnim="Cringe"
	IdleSwimAnim="Tread"
	IdleWeaponAnim="Breath"
	IdleRestAnim="Breath"
	IdleChatAnim="Breath"
	Mesh=VertMesh'satoreMonsterPackv120.Nali2'
	Skins(0)=Shader'DEKMonstersTexturesMaster208.IceMonsters.IceNaliShader'
	Skins(1)=Shader'DEKMonstersTexturesMaster208.IceMonsters.IceNaliShader'
	DrawScale=2.000000
	CollisionRadius=40.000000
	CollisionHeight=110.000000
}

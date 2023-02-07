class Gaia extends NatureDragon
	config(DEKBossMonsters);

//Boss variables
var BossInv BInv;
var config float DamageReductionMultiplier;
var config int XPReward;
var config class<Monster> MinionClass;
var config float ScaleMultiplier;

//Combo variables
var StatusEffectInventory_Player StatusManager;
var config int AdrenDripAmount;

struct ComboInfo
{
	var Class<StatusEffectData> StatusEffectClass;
	var int Modifier;
	var int StatusLifespan;
	var bool bDispellable;
	var bool bStackable;
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
	local EarthInv Inv;
	local PoisonShieldInv PInv;
	local int x;
	
	Mass *= class'ElementalConfigure'.default.BossMassMultiplier;
	SetLocation(Instigator.Location+vect(0,0,1)*(Instigator.CollisionHeight*ScaleMultiplier/2));
	SetDrawScale(Drawscale*ScaleMultiplier);
	SetCollisionSize(CollisionRadius*ScaleMultiplier, CollisionHeight*ScaleMultiplier);
	
	if (Instigator != None)
	{
		Inv = EarthInv(Instigator.FindInventoryType(class'EarthInv'));
		BInv = BossInv(Instigator.FindInventoryType(class'BossInv'));
		StatusManager = StatusEffectInventory_Player(Class'StatusEffectManager'.static.GetStatusEffectManager(Instigator));
		PInv = PoisonShieldInv(Instigator.FindInventoryType(class'PoisonShieldInv'));
		if (Inv == None)
		{
			Inv = Instigator.Spawn(class'EarthInv');
			Inv.GiveTo(Instigator);
		}
		if (BInv == None)
		{
			BInv = Instigator.Spawn(class'BossInv');
			BInv.AdrenDripAmount = AdrenDripAmount;
			BInv.MinionClass = MinionClass;
			BInv.GiveTo(Instigator);
		}
		if (StatusManager == None)
		{
			StatusManager = Instigator.Spawn(Class'StatusEffectInventory_Player');
			StatusManager.GiveTo(Instigator);
		}
		if (StatusManager != None)
			for (x = 0; x < ComboData.Length; x++)
				StatusManager.AddCombo(ComboData[x].StatusEffectClass, ComboData[x].Modifier, ComboData[x].StatusLifespan, ComboData[x].bDispellable, ComboData[x].bStackable);
		if (PInv == None)
		{
			PInv = Instigator.Spawn(class'PoisonShieldInv');
			PInv.GiveTo(Instigator);
		}
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
	
	decision = FRand();
	
	if(VSize(A.Location-Location) > TeleportRange && (decision < 0.70))
	{
		PlaySound(sound'BWeaponSpawn1', SLOT_Interface);
		GotoState('Teleporting');
	}
	if (Instigator != None && Instigator.Controller != None && Instigator.Controller.Adrenaline >= 100)
		StartCombo();
	
	decision = FRand();
	
	if (decision < 0.30)
	{
		if(GetStateName() != 'Dying')
		{
			GoToState('FlameAttackSequence');
		}
	}
	
	Super.RangedAttack(A);
}

function StartCombo()
{
	if (StatusManager != None)
		StatusManager.ExecuteCombos();
	
	if (BInv != None)
		BInv.AdrenCounter = 0;
	Instigator.Controller.Adrenaline = 0;
	
	Instigator.PlaySound(Sound'DEKBossMonsters999X.Boss.BossComboActivate', SLOT_None, 800.0,,2000.00);
}

function FlameAttack()
{
	local vector FireStart,X,Y,Z;
	local GaiaFlameProj Proj;
	
	GetAxes(Rotation,X,Y,Z);
	FireStart = GetFireStart(X,Y,Z);
	Proj = Instigator.Spawn(class'GaiaFlameProj', Instigator,  , FireStart, Controller.AdjustAim(SavedFireProperties,FireStart,600));
}

State FlameAttackSequence
{

Begin:

	FlameAttack();
	Sleep(0.4);
	FlameAttack();
	Sleep(0.4);
	FlameAttack();
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
	local IceInv Inv;
	
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
		Inv = IceInv(instigatedBy.FindInventoryType(class'IceInv'));
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
	Level.Game.Broadcast(self, "Gaia is defeated!");
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
    ProjectileClass=Class'DEKBossMonsters999X.GaiaProjectile'
	DamageReductionMultiplier=0.500000
	XPReward=200
	MinionClass=Class'DEKBossMonsters999X.MinionEarthMercenary'
	AdrenDripAmount=7
	ComboData(0)=(StatusEffectClass=Class'DEKRPG999X.StatusEffect_ChanceHit',Modifier=4,StatusLifespan=20,bDispellable=True,bStackable=False)
	AChannel=255
	TeleportRange=7000.000000
	OwnerName="Gaia"
    ScoringValue=50
	Mass=1000.00
    bMeleeFighter=False
	FireBreathDamage=100
	AttackInterval=0.750000
	HealthMax=35000.000000
	Health=35000
    AirSpeed=800.000000
	ScaleMultiplier=2.00
	MaterialChance=30
	LowMaterialChance=40
	MediumMaterialChance=60
	HighMaterialChance=90
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
	VeryHighMaterials(0)=Class'DEKRPG999X.AbilityMaterialTranslator'
    ControllerClass=Class'DEKRPG999X.DCMonsterController'
}

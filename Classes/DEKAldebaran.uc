class DEKAldebaran extends Aldebaran
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

replication
{
	reliable if(Role==ROLE_Authority )
         bTeleporting;
}

function PostBeginPlay()
{
	local EarthInv Inv;

	Mass *= class'ElementalConfigure'.default.BossMassMultiplier;
	SetLocation(Instigator.Location+vect(0,0,1)*(Instigator.CollisionHeight*ScaleMultiplier/2));
	SetDrawScale(Drawscale*ScaleMultiplier);
	SetCollisionSize(CollisionRadius*ScaleMultiplier, CollisionHeight*ScaleMultiplier);
	
	if (Instigator != None)
	{
		Inv = EarthInv(Instigator.FindInventoryType(class'EarthInv'));
		BInv = BossInv(Instigator.FindInventoryType(class'BossInv'));
		Combo = ComboInv(Instigator.FindInventoryType(class'ComboInv'));
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
	if(VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
	{
		SetAnimAction(MeleeAnims[Rand(4)]);
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
		bShotAnim = true;
	}
	else if(Level.TimeSeconds - LastRangedAttackTime > RangedAttackInterval)
	{
		LastRangedAttackTime = Level.TimeSeconds;
		SetAnimAction(RangedAttackAnims[Rand(4)]);
		bShotAnim = true;
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
	}
}

function StartCombo()
{
	local int x;
	
	if (bComboDamage && ComboDamage > 0)
		Combo.ComboDamage(ComboDamage, bComboDamageAll, bComboDamageMulti, bComboDamageSingle, ComboDamageType, class'RocketExplosion', True);
	
	for ( x = 0; x < ComboClass.Length; x++)
	{
		if (ComboData[x].bBuff)
			Combo.AddBuff(Self, ComboData[x].bAll, ComboData[x].bMulti, ComboData[x].bSingle, ComboData[x].Lifespan, ComboClass[x], ComboData[x].Multiplier, ComboData[x].bDispellable);
		else
			Combo.AddAilment(Self, ComboData[x].bAll, ComboData[x].bMulti, ComboData[x].bSingle, ComboData[x].Lifespan, ComboClass[x], ComboData[x].Multiplier, ComboData[x].bDispellable);
	}
	
	if (BInv != None)
		BInv.AdrenCounter = 0;
	Instigator.Controller.Adrenaline = 0;
	
	Instigator.PlaySound(Sound'DEKBossMonsters209E.Boss.BossComboActivate', SLOT_None, 800.0,,2000.00);
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
			Damage *= class'ElementalConfigure'.default.IceOnEarthDamageMultiplier;
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
	PlayDirectionalDeath(HitLocation);
	if (Invasion(Level.Game) != None)
		Invasion(Level.Game).NumMonsters = 0;
	RewardXP();
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

function FireProjectile()
{
	local Vector FireStart;
	local Projectile Proj;

	if ( Controller != None )
	{
		FireStart = GetBoneCoords('rhand').Origin;
		Proj = Spawn(class'DEKAldebaranProj',self,,FireStart,Controller.AdjustAim(SavedFireProperties,FireStart,10));

		FireStart = GetBoneCoords('lhand').Origin;
		Proj = Spawn(class'DEKAldebaranProj',self,,FireStart,Controller.AdjustAim(SavedFireProperties,FireStart,10));
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
     MinionClass=Class'DEKBossMonsters209E.MinionPhantom'
     AdrenDripAmount=5
     ComboClass(0)=Class'DEKRPG209E.ComboHealthMaxInv'
     bComboDamage=True
     bComboDamageMulti=True
     ComboDamage=200
     ComboDamageType=Class'DEKRPG209E.DamTypeCombo'
     ComboData(0)=(LifeSpan=25,Multiplier=0.600000,bDispellable=True,bAll=False,bMulti=True,bSingle=False)
     AChannel=255
     TeleportRange=7000.000000
     OwnerName="Aldebaran"
     HealthMax=35000.000000
     Health=35000
     RangedAttackInterval=3.000000
     NewHealth=35000
     ProjectileDamage=50
     Mass=1000.000000
	 ScaleMultiplier=2.00
     ControllerClass=Class'DEKMonsters209E.DCMonsterController'
}

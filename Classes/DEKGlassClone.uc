class DEKGlassClone extends DEKGlass
	config(satoreMonsterPack);
	
var DEKGlass ParentGlass;
var config int HPDamage;

#exec  AUDIO IMPORT NAME="GlassBreak" FILE="Sounds\GlassBreak.WAV" GROUP="MonsterSounds"

simulated function PreBeginPlay()
{
	ParentGlass=DEKGlass(Owner);
	if(ParentGlass==none)
		Destroy();
	Super.PreBeginPlay();
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
}

simulated function Destroyed()
{
	if ( ParentGlass != None )
		ParentGlass.numChildren--;
	if (ParentGlass.numChildren < 0)
		ParentGlass.numChildren = 0;
	Super.Destroyed();
}

function StartCombo()
{
	return;
}

function Clone()
{
	return;
}

simulated function Tick(float DeltaTime)
{
	if (BInv != None)
		BInv.Destroy();
	if (Controller != None && BossMonsterController(Controller).StatusManager != None)
		BossMonsterController(Controller).StatusManager.Destroy();
	if(ParentGlass==none || ParentGlass.Controller==none || ParentGlass.Controller.Enemy==self)
	{
		Destroy();
		return;
	}
	super.Tick(DeltaTime);
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	Self.PlaySound(Sound'fLaugh1',,TransientSoundVolume*2.0);
	if (Killer != None && Killer.Pawn != None && Killer.Pawn.Health > 0 && ParentGlass != None)
	{
		Killer.Pawn.PlaySound(Sound'GlassBreak',,TransientSoundVolume*1.5);
		Killer.Pawn.TakeDamage(HPDamage, ParentGlass, Killer.Pawn.Location, vect(0,0,0), class'DamTypeGlassClone');
	}
	Destroy();
}

defaultproperties
{
	bCanTeleport=False
	fHealth=150.00
	HealthMax=150.000000
	Health=150
	HPDamage=30
	AdrenDripAmount=0
	MinionClass=None
	MaxChildren=0
	ScoringValue=0
}

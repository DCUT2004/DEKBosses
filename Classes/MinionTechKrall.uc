class MinionTechKrall extends TechKrall;

var Monster Parent;

simulated function PreBeginPlay()
{
	Parent = Monster(Owner);
	if(Parent == None)
		Destroy();
	Super.PreBeginPlay();
}

function bool SameSpeciesAs(Pawn P)
{
		return ( P.class == class'DEKGlass' || P.Class == class'MinionTechKrall');
}

function Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	
	if(Parent == None || Parent.Health <= 0)
	{
		KilledBy(Self);
	}
	if(Parent.Controller!=none && Controller!=none && Health>=0)
	{
		Controller.Enemy=Parent.Controller.Enemy;
		Controller.Target=Parent.Controller.Target;
	}
}

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local BossInv Inv;
	
	if ( Parent != None )
	{
		Inv = BossInv(Parent.FindInventoryType(class'BossInv'));
		if (Inv != None)
			Inv.NumMinions--;
	}
	Super.Died(Killer, damageType, HitLocation);
}

defaultproperties
{
}

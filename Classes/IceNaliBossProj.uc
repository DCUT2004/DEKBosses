class IceNaliBossProj extends ONSShockTankProjectile;

var IceNaliBossProjEffect IceBallEffect;

var() vector ShakeRotMag;           // how far to rot view
var() vector ShakeRotRate;          // how fast to rot view
var() float  ShakeRotTime;          // how much time to rot the instigator's view
var() vector ShakeOffsetMag;        // max view offset vertically
var() vector ShakeOffsetRate;       // how fast to offset view vertically
var() float  ShakeOffsetTime;       // how much time to offset view

simulated function PostBeginPlay()
{
	Super(Projectile).PostBeginPlay();
	
	if (ONSShockBallEffect != None)
	{
		if ( bNoFX )
			ONSShockBallEffect.Destroy();
		else
			ONSShockBallEffect.Kill();
	}

    if ( Level.NetMode != NM_DedicatedServer )
	{
        IceBallEffect = Spawn(class'IceNaliBossProjEffect', self);
        IceBallEffect.SetBase(self);
	}

	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

    tempStartLoc = Location;
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if (ONSShockBallEffect != None)
	{
		if ( bNoFX )
			ONSShockBallEffect.Destroy();
		else
			ONSShockBallEffect.Kill();
	}	
}


function SuperExplosion()
{
	local actor HitActor;
	local vector HitLocation, HitNormal;

	HurtRadius(ComboDamage, ComboRadius, class'DamTypeIceNali', ComboMomentumTransfer, Location );

	Spawn(class'IceNaliBossProjExplosion');
	if ( (Level.NetMode != NM_DedicatedServer) && EffectIsRelevant(Location,false) )
	{
		HitActor = Trace(HitLocation, HitNormal,Location - Vect(0,0,120), Location,false);
		if ( HitActor != None )
			Spawn(class'ComboDecal',self,,HitLocation, rotator(vect(0,0,-1)));
	}
	ShakeView();
	PlaySound(Sound'VehicleExplosion02', SLOT_None,1.0,,800);
    DestroyTrails();
    Destroy();
}

function ShakeView()
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
            if ( Dist < DamageRadius * 2.0)
            {
                if (Dist < DamageRadius * 1.5)
                    Scale = 1.0;
                else
                    Scale = (DamageRadius*2.0 - Dist) / (DamageRadius);
                C.ShakeView(ShakeRotMag*Scale, ShakeRotRate, ShakeRotTime, ShakeOffsetMag*Scale, ShakeOffsetRate, ShakeOffsetTime);
            }
        }
    }
}

simulated function DestroyTrails()
{
    if (ONSShockBallEffect != None)
        ONSShockBallEffect.Destroy();
	if (IceBallEffect != None)
		IceBallEffect.Destroy();
}

simulated function Destroyed()
{
    if (ONSShockBallEffect != None)
    {
		if ( bNoFX )
			ONSShockBallEffect.Destroy();
		else
			ONSShockBallEffect.Kill();
	}
    if (IceBallEffect != None)
    {
		if ( bNoFX )
			IceBallEffect.Destroy();
		else
			IceBallEffect.Kill();
	}

	Super.Destroyed();
}

defaultproperties
{
     ShakeRotMag=(Z=300.000000)
     ShakeRotRate=(Z=2500.000000)
     ShakeRotTime=6.000000
     ShakeOffsetMag=(Z=10.000000)
     ShakeOffsetRate=(Z=200.000000)
     ShakeOffsetTime=10.000000
     ComboRadius=400.000000
     ComboMomentumTransfer=235000.000000
     Speed=1700.000000
     MaxSpeed=1700.000000
     Damage=60.000000
     MyDamageType=Class'DEKBossMonsters208AC.DamTypeIceNali'
}

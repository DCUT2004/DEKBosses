class MinionEarthWarlord extends EarthWarlord;

function bool SameSpeciesAs(Pawn P)
{
		return ( P.class == class'MinionEarthWarlord' || P.Class == class'MinionEarthMercenary' || P.Class == Class'EarthQueen');
}

function Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	
	if(Invasion(Level.Game) != None && !Invasion(Level.Game).bWaveInProgress)
	{
		KilledBy(Self);
	}
}

defaultproperties
{
}
